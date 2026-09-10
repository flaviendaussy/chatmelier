import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../shared/services/gemini_model_registry.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/cellar_furniture.dart';

class DetectedFurnitureLayout {
  final String name;
  final String shapeType;
  final int columns;
  final int rows;
  final List<List<bool>> slotsMatrix;

  const DetectedFurnitureLayout({
    required this.name,
    required this.shapeType,
    required this.columns,
    required this.rows,
    required this.slotsMatrix,
  });

  factory DetectedFurnitureLayout.fallback() {
    return DetectedFurnitureLayout(
      name: 'Casier à vin (détecté)',
      shapeType: 'rectangle',
      columns: 6,
      rows: 6,
      slotsMatrix: CellarFurniture.generateMatrix(
        shapeType: 'rectangle',
        columns: 6,
        rows: 6,
      ),
    );
  }
}

class FurnitureVisionService {
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static Future<Uint8List> _readImageBytes(String imagePath) async {
    if (kIsWeb || imagePath.startsWith('blob:') || imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      try {
        final xfile = XFile(imagePath);
        return await xfile.readAsBytes();
      } catch (_) {
        final uri = Uri.parse(imagePath);
        final res = await http.get(uri);
        if (res.statusCode == 200) return res.bodyBytes;
        throw Exception('Impossible de charger l\'image: HTTP ${res.statusCode}');
      }
    } else {
      try {
        final xfile = XFile(imagePath);
        return await xfile.readAsBytes();
      } catch (_) {
        return await File(imagePath).readAsBytes();
      }
    }
  }

  /// Analyzes a photo of wine rack / furniture to detect layout, shape and active slots.
  Future<DetectedFurnitureLayout> analyzeFurnitureImage({
    String? imagePath,
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    try {
      Uint8List bytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        bytes = imageBytes;
      } else if (imageFile != null) {
        bytes = await imageFile.readAsBytes();
      } else if (imagePath != null && imagePath.isNotEmpty) {
        bytes = await _readImageBytes(imagePath);
      } else {
        throw ArgumentError('Aucune image fournie pour la détection de meuble');
      }

      final base64Image = base64Encode(bytes);
      final mimeType = bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50 ? 'image/png' : 'image/jpeg';

      const prompt = '''
Tu es un architecte et sommelier expert en aménagement de cave à vin.
Analyse cette photo de meuble, casier, étagère ou croisillon de rangement de vin.

Détecte la géométrie exacte du meuble :
1. "shape_type": choisis parmi:
   - "rectangle": meuble rectangulaire ou carré classique avec grille complète
   - "triangle": casier triangulaire / pyramide
   - "staggered_4_2": meuble ou croisillon avec rangées décalées ou alternées
   - "custom": disposition irrégulière
2. "columns": nombre estimé de colonnes ou de bouteilles en largeur (ex: 4, 6, 8, max 15).
3. "rows": nombre estimé de rangées / étages en hauteur (ex: 4, 6, 8, max 15).
4. "name": un nom élégant et concis (ex: "Casier chêne 6x6", "Étagère murale 5 niveaux", "Casier pyramide").
5. "slots_matrix": une matrice 2D booléenne de taille [rows][columns] où true = emplacement où une bouteille peut être posée, false = vide / absence de casier (comme dans les coins d'un triangle).

Retourne STRICTEMENT un JSON valide sans markdown additionnel :
{
  "name": "...",
  "shape_type": "rectangle",
  "columns": 6,
  "rows": 6,
  "slots_matrix": [
    [true, true, true, true, true, true],
    ...
  ]
}''';

      final requestBody = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                }
              },
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.2,
        }
      });

      final activeModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.standardFlashPreferred);

      for (final model in activeModels) {
        try {
          final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey');
          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          ).timeout(const Duration(seconds: 12));

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
                  final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

                  final cols = (parsed['columns'] as num?)?.toInt().clamp(2, 20) ?? 6;
                  final rws = (parsed['rows'] as num?)?.toInt().clamp(2, 20) ?? 6;
                  final shape = parsed['shape_type'] as String? ?? 'rectangle';
                  final name = parsed['name'] as String? ?? 'Meuble détecté';

                  List<List<bool>> matrix = [];
                  final rawMatrix = parsed['slots_matrix'];
                  if (rawMatrix is List) {
                    for (final r in rawMatrix) {
                      if (r is List) {
                        matrix.add(r.map((c) => c == true).toList());
                      }
                    }
                  }

                  if (matrix.isEmpty || matrix.length != rws || (matrix.isNotEmpty && matrix[0].length != cols)) {
                    matrix = CellarFurniture.generateMatrix(shapeType: shape, columns: cols, rows: rws);
                  }

                  return DetectedFurnitureLayout(
                    name: name,
                    shapeType: shape,
                    columns: cols,
                    rows: rws,
                    slotsMatrix: matrix,
                  );
                }
              }
            }
          }
        } catch (e) {
          AppLogger.warning('FURNITURE_AI', 'Model $model scan failed: $e');
        }
      }
    } catch (e) {
      AppLogger.error('FURNITURE_AI', 'analyzeFurnitureImage error', e);
    }

    return DetectedFurnitureLayout.fallback();
  }
}
