import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/fonctions_ia.dart';
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
    this.country,
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
      country: json['country'] as String?,
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
  ExcelImportService({FonctionsIa? ia}) : _iaInjecte = ia;

  /// Depuis la V2.3, la lecture passe par la fonction `taches-ia` : l'app n'a plus de clé.
  final FonctionsIa? _iaInjecte;

  FonctionsIa? get _ia {
    if (_iaInjecte != null) return _iaInjecte;
    try {
      return FonctionsIa(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  /// Vrai si le dernier lot n'a pas pu être lu faute de serveur : l'écran le dit, au lieu
  /// d'annoncer « aucun vin trouvé » (c'était le cas depuis le retrait de la clé, 14/09).
  String? derniereErreur;


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

    final ia = _ia;
    if (ia == null) {
      derniereErreur = 'reseau';
      return [];
    }
    final r = await ia.appeler('taches-ia', {'tache': 'import_cave', 'lignes': textRows},
        delai: const Duration(seconds: 75));
    if (!r.ok) {
      derniereErreur = r.limiteAtteinte ? 'limite_du_jour' : (r.erreur ?? 'serveur');
      AppLogger.warning('EXCEL_IMPORT', 'Lot non lu : $derniereErreur');
      return [];
    }
    derniereErreur = null;
    final brut = r.donnees!['resultat'];
    final liste = brut is List ? brut : (brut is Map && brut['wines'] is List ? brut['wines'] as List : const []);
    return liste
        .whereType<Map>()
        .map((item) => ImportedWineCandidate.fromJson(Map<String, dynamic>.from(item)))
        .where((c) => c.name.trim().isNotEmpty)
        .toList();
  }
}
