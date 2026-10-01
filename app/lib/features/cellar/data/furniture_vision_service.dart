import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/fonctions_ia.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
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
  FurnitureVisionService({FonctionsIa? ia}) : _iaInjecte = ia;

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

      final ia = _ia;
      final r = ia == null
          ? null
          : await ia.appeler('taches-ia', {
              'tache': 'meuble',
              'imageBase64': base64Image,
              'mimeType': mimeType,
              'langue': Langue.code,
            }, delai: const Duration(seconds: 45));
      final parsed = r != null && r.ok && r.donnees!['resultat'] is Map
          ? Map<String, dynamic>.from(r.donnees!['resultat'] as Map)
          : null;
      if (parsed != null) {
        final cols = (parsed['columns'] as num?)?.toInt().clamp(2, 20) ?? 6;
        final rws = (parsed['rows'] as num?)?.toInt().clamp(2, 20) ?? 6;
        final shape = parsed['shape_type'] as String? ?? 'rectangle';
        final name = parsed['name'] as String? ?? tr('Meuble détecté', 'Detected furniture');

        List<List<bool>> matrix = [];
        final rawMatrix = parsed['slots_matrix'];
        if (rawMatrix is List) {
          for (final ligne in rawMatrix) {
            if (ligne is List) matrix.add(ligne.map((c) => c == true).toList());
          }
        }
        if (matrix.isEmpty || matrix.length != rws || matrix[0].length != cols) {
          matrix = CellarFurniture.generateMatrix(shapeType: shape, columns: cols, rows: rws);
        }
        return DetectedFurnitureLayout(name: name, shapeType: shape, columns: cols, rows: rws, slotsMatrix: matrix);
      }
      AppLogger.info('FURNITURE_AI', 'Lecture du meuble sans le sommelier (${r?.erreur ?? 'hors ligne'}) : gabarit par défaut');
    } catch (e) {
      AppLogger.error('FURNITURE_AI', 'analyzeFurnitureImage error', e);
    }

    return DetectedFurnitureLayout.fallback();
  }
}
