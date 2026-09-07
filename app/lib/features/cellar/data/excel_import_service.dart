import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../shared/services/gemini_model_registry.dart';
import '../../../shared/utils/app_logger.dart';

class ImportedWineCandidate {
  String name;
  String? producer;
  int? vintage;
  String type;
  String? region;
  String? country;
  String? appellation;
  int quantity;
  String bottleSize;
  double? purchasePrice;
  String currency;
  String? rack;
  String? shelf;
  bool isSelected;

  ImportedWineCandidate({
    required this.name,
    this.producer,
    this.vintage,
    this.type = 'red',
    this.region,
    this.country = 'France',
    this.appellation,
    this.quantity = 1,
    this.bottleSize = '75cl',
    this.purchasePrice,
    this.currency = 'EUR',
    this.rack,
    this.shelf,
    this.isSelected = true,
  });

  factory ImportedWineCandidate.fromJson(Map<String, dynamic> json) {
    return ImportedWineCandidate(
      name: json['name'] as String? ?? 'Vin importé',
      producer: json['producer'] as String?,
      vintage: (json['vintage'] as num?)?.toInt(),
      type: json['type'] as String? ?? 'red',
      region: json['region'] as String?,
      country: json['country'] as String? ?? 'France',
      appellation: json['appellation'] as String?,
      quantity: (json['quantity'] as num?)?.toInt().clamp(1, 1000) ?? 1,
      bottleSize: json['bottle_size'] as String? ?? '75cl',
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      rack: json['rack'] as String?,
      shelf: json['shelf'] as String?,
      isSelected: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'producer': producer,
      'vintage': vintage,
      'type': type,
      'region': region,
      'country': country,
      'appellation': appellation,
      'quantity': quantity,
      'bottle_size': bottleSize,
      'purchase_price': purchasePrice,
      'currency': currency,
      'rack': rack,
      'shelf': shelf,
    };
  }
}

class ExcelImportService {
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg',
  );

  /// Extracts text lines from a CSV, TSV, or XLSX file bytes.
  static List<String> extractRawRows({
    required Uint8List bytes,
    required String fileName,
  }) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.xlsx')) {
      return _extractFromXlsx(bytes);
    } else {
      return _extractFromCsvOrText(bytes);
    }
  }

  static List<String> _extractFromCsvOrText(Uint8List bytes) {
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }

    // Detect delimiter: semicolon or comma or tab
    final firstLine = text.split('\n').firstOrNull ?? '';
    final semicolonCount = ';'.allMatches(firstLine).length;
    final commaCount = ','.allMatches(firstLine).length;
    final tabCount = '\t'.allMatches(firstLine).length;

    String fieldDelimiter = ',';
    if (semicolonCount > commaCount && semicolonCount > tabCount) {
      fieldDelimiter = ';';
    } else if (tabCount > commaCount && tabCount > semicolonCount) {
      fieldDelimiter = '\t';
    }

    try {
      final rows = CsvToListConverter(
        fieldDelimiter: fieldDelimiter,
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(text);

      final List<String> lines = [];
      for (final r in rows) {
        final lineStr = r.map((c) => c.toString().trim()).where((s) => s.isNotEmpty).join(' | ');
        if (lineStr.isNotEmpty) lines.add(lineStr);
      }
      return lines;
    } catch (e) {
      // Fallback: simple line split
      return text
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }
  }

  static List<String> _extractFromXlsx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Extract shared strings if present
      final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
      final List<String> sharedStrings = [];
      if (sharedStringsFile != null) {
        final content = utf8.decode(sharedStringsFile.content as List<int>, allowMalformed: true);
        final tagRegex = RegExp(r'<t(?:\s+[^>]*)?>([^<]*)</t>');
        for (final match in tagRegex.allMatches(content)) {
          sharedStrings.add(match.group(1) ?? '');
        }
      }

      // 2. Locate worksheet (sheet1.xml)
      ArchiveFile? sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
      if (sheetFile == null) {
        for (final f in archive.files) {
          if (f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml')) {
            sheetFile = f;
            break;
          }
        }
      }

      if (sheetFile != null) {
        final sheetXml = utf8.decode(sheetFile.content as List<int>, allowMalformed: true);
        final rowRegex = RegExp(r'<row(?:\s+[^>]*)?>([\s\S]*?)</row>');
        final cellRegex = RegExp(r'<c\s+r="([A-Z]+)(\d+)"(?:\s+t="([^"]*)")?(?:\s+[^>]*)?>([\s\S]*?)</c>');
        final valRegex = RegExp(r'<v>([^<]*)</v>');

        final List<String> extractedLines = [];

        for (final rowMatch in rowRegex.allMatches(sheetXml)) {
          final rowContent = rowMatch.group(1) ?? '';
          final List<String> cellsInRow = [];

          for (final cellMatch in cellRegex.allMatches(rowContent)) {
            final type = cellMatch.group(3);
            final inner = cellMatch.group(4) ?? '';
            final valMatch = valRegex.firstMatch(inner);
            String cellVal = valMatch?.group(1) ?? '';

            if (type == 's') {
              final idx = int.tryParse(cellVal);
              if (idx != null && idx >= 0 && idx < sharedStrings.length) {
                cellVal = sharedStrings[idx];
              }
            }

            final cleanVal = cellVal.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').trim();
            if (cleanVal.isNotEmpty) {
              cellsInRow.add(cleanVal);
            }
          }

          if (cellsInRow.isNotEmpty) {
            extractedLines.add(cellsInRow.join(' | '));
          }
        }

        if (extractedLines.isNotEmpty) {
          return extractedLines;
        }
      }
    } catch (e) {
      AppLogger.warning('EXCEL_IMPORT', 'XLSX extraction fallback: $e');
    }

    // Ultimate fallback: text decode
    return _extractFromCsvOrText(bytes);
  }

  /// Sends a batch of raw table text rows to Gemini to extract normalized wine candidates.
  Future<List<ImportedWineCandidate>> normalizeWineBatch(List<String> textRows) async {
    if (textRows.isEmpty) return [];

    final rowsSnippet = textRows.join('\n');

    final prompt = '''
Tu es un sommelier expert et ingénieur de données vinicoles.
Voici des lignes extraites d'un tableur ou fichier Excel de cave à vin :

$rowsSnippet

Ta mission :
Identifie chaque vin présent dans cette liste et extrait ses attributs :
- "name": Nom du vin / Cuvée (requis, ex: "Château Margaux", "Puligny-Montrachet Les Folatières", "Cuvée Alexandre")
- "producer": Domaine, Maison, Vignoble ou Château (ex: "Domaine Leflaive", "Château Margaux")
- "vintage": Millésime (entier ex: 2018, ou null si non millésimé)
- "type": Couleur/type parmi ["red", "white", "rosé", "sparkling", "dessert", "fortified", "spirit"]
- "region": Région viticole (ex: "Bordeaux", "Bourgogne", "Champagne", "Vallée du Rhône", "Toscane", "Napa Valley"...)
- "country": Pays (ex: "France", "Italie", "Espagne", "États-Unis"...)
- "appellation": AOC, AOP, DOCG, AVA si identifiable
- "quantity": Nombre de bouteilles indiquées sur la ligne (entier >= 1, défaut: 1)
- "bottle_size": Format de la bouteille parmi ["37.5cl", "50cl", "75cl", "1.5L", "3L", "6L"] (défaut: "75cl")
- "purchase_price": Prix unitaire d'achat si mentionné (nombre décimal ou null)
- "currency": "EUR" par défaut, ou "USD", "GBP", "CHF" si mentionné
- "rack": Casier / Rangée mentionnée (ex: "A", "Casier 1", null)
- "shelf": Étagère / Niveau mentionné (null)

RÈGLES CRITIQUES :
1. Ignore complètement les lignes d'en-tête (ex: "Nom | Producteur | Année | Prix"), totaux, ou métadonnées de fichier.
2. Déduis intelligemment le type/couleur à partir de l'appellation (ex: Meursault -> white, Pomerol -> red, Champagne -> sparkling).
3. Si un millésime figure dans le nom, extrais-le dans "vintage".

Retourne STRICTEMENT un tableau JSON d'objets vin :
[
  {
    "name": "...",
    "producer": "...",
    "vintage": 2018,
    "type": "red",
    "region": "Bordeaux",
    "country": "France",
    "appellation": "Margaux",
    "quantity": 1,
    "bottle_size": "75cl",
    "purchase_price": 45.0,
    "currency": "EUR"
  }
]''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.1,
      }
    });

    final activeModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.litePreferred);

    for (final model in activeModels) {
      try {
        final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final jsonRes = jsonDecode(response.body);
          final candidates = jsonRes['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final rawText = parts[0]['text'] as String?;
              if (rawText != null) {
                final cleaned = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
                final parsed = jsonDecode(cleaned);
                if (parsed is List) {
                  return parsed.map((item) => ImportedWineCandidate.fromJson(item as Map<String, dynamic>)).toList();
                }
              }
            }
          }
        }
      } catch (e) {
        AppLogger.warning('EXCEL_IMPORT', 'Gemini model $model failed: $e');
      }
    }

    return [];
  }
}
