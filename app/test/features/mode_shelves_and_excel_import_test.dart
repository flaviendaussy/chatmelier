import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/cellar_furniture.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/bottle_size.dart';
import 'package:chatmelier/features/cellar/data/excel_import_service.dart';

void main() {
  group('Mode Shelves - Sommelier Coordinates & Matrix Presets', () {
    test('Coordinate encoding and decoding matches sommelier standard (e.g. A7 = Col 1, Row 7)', () {
      // User requirement: "donner un code (A7 pour premiere col 7e rangée)"
      // Col 1 (index 0), Row 7 (index 6)
      final codeA7 = CellarFurniture.slotCode(0, 6);
      expect(codeA7, 'A7');

      final parsedA7 = CellarFurniture.parseSlotCode('A7');
      expect(parsedA7, isNotNull);
      expect(parsedA7!.col, 0);
      expect(parsedA7.row, 6);

      final descA7 = CellarFurniture.describeSlotCode('A7');
      expect(descA7, 'A7 (1ère colonne, 7e rangée)');

      // Another position: B1 (2nd col, 1st row)
      final codeB1 = CellarFurniture.slotCode(1, 0);
      expect(codeB1, 'B1');
      final descB1 = CellarFurniture.describeSlotCode('B1');
      expect(descB1, 'B1 (2e colonne, 1ère rangée)');

      // High values: C12
      final codeC12 = CellarFurniture.slotCode(2, 11);
      expect(codeC12, 'C12');
      final descC12 = CellarFurniture.describeSlotCode('C12');
      expect(descC12, 'C12 (3e colonne, 12e rangée)');
    });

    test('Matrix generator presets create appropriate active slot configurations', () {
      // 1. Rectangle: 4 cols x 6 rows = 24 slots, all active
      final rectMatrix = CellarFurniture.generateMatrix(
        shapeType: 'rectangle',
        columns: 4,
        rows: 6,
      );
      expect(rectMatrix.length, 6);
      expect(rectMatrix[0].length, 4);
      expect(rectMatrix.every((r) => r.every((c) => c == true)), isTrue);

      final rectFurniture = CellarFurniture(
        id: 'f-rect',
        cellarId: 'c1',
        name: 'Casier Rectangulaire',
        shapeType: 'rectangle',
        columns: 4,
        rows: 6,
        slotsMatrix: rectMatrix,
      );
      expect(rectFurniture.totalCapacity, 24);
      expect(rectFurniture.isSlotActive(0, 5), isTrue);
      expect(rectFurniture.isSlotActive(4, 5), isFalse); // Out of bounds

      // 2. Triangle / Pyramide: Top row has fewer active slots than bottom row
      final triMatrix = CellarFurniture.generateMatrix(
        shapeType: 'triangle',
        columns: 6,
        rows: 6,
      );
      final triFurniture = CellarFurniture(
        id: 'f-tri',
        cellarId: 'c1',
        name: 'Meuble Pyramidal',
        shapeType: 'triangle',
        columns: 6,
        rows: 6,
        slotsMatrix: triMatrix,
      );
      final topActive = triMatrix.first.where((c) => c).length;
      final bottomActive = triMatrix.last.where((c) => c).length;
      expect(topActive <= bottomActive, isTrue);
      expect(triFurniture.totalCapacity < 36, isTrue);

      // 3. Staggered 4+2: Alternating row pattern
      final stagMatrix = CellarFurniture.generateMatrix(
        shapeType: 'staggered_4_2',
        columns: 6,
        rows: 4,
      );
      final stagFurniture = CellarFurniture(
        id: 'f-stag',
        cellarId: 'c1',
        name: 'Casier 4+2',
        shapeType: 'staggered_4_2',
        columns: 6,
        rows: 4,
        slotsMatrix: stagMatrix,
      );
      // Row 0 (even) has full active width
      expect(stagMatrix[0].where((c) => c).length, 6);
      // Row 1 (odd) has 2 active slots
      expect(stagMatrix[1].where((c) => c).length, 2);
      expect(stagFurniture.totalCapacity, 16);
    });
  });

  group('BottleSize - Standard Formats & Badges', () {
    test('Recognizes standard volumes and formats correctly', () {
      final std75 = BottleSize.fromCode('75cl');
      expect(std75.isStandard75cl, isTrue);
      expect(std75.volumeLiters, 0.75);
      expect(std75.label, contains('75 cl'));

      final magnum = BottleSize.fromCode('1.5L');
      expect(magnum.isStandard75cl, isFalse);
      expect(magnum.volumeLiters, 1.5);
      expect(magnum.shortName, contains('Magnum'));

      final demi = BottleSize.fromCode('37.5cl');
      expect(demi.volumeLiters, 0.375);
      expect(demi.shortName, '37.5 cl');

      final jero = BottleSize.fromCode('3L');
      expect(jero.volumeLiters, 3.0);
      expect(jero.shortName, contains('Jéroboam'));

      // Unknown custom format falls back cleanly
      final custom = BottleSize.fromCode('70cl');
      expect(custom.code, '70cl');
      expect(custom.isStandard75cl, isFalse);
    });
  });

  group('Excel & CSV Import Service', () {
    test('Extracts rows from semicolon-delimited CSV', () {
      final csvContent = '''
Nom du Vin;Producteur;Millésime;Type;Région;Quantité;Format;Prix
Château Margaux;Château Margaux;2015;Rouge;Bordeaux;3;75cl;450
Meursault Les Charmes;Domaine des Comtes Lafon;2020;Blanc;Bourgogne;2;75cl;180
'''.trim();

      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final rows = ExcelImportService.extractRawRows(bytes: bytes, fileName: 'cave_export.csv');

      expect(rows.length, 3);
      expect(rows[1], contains('Château Margaux'));
      expect(rows[1], contains('2015'));
      expect(rows[2], contains('Meursault'));
    });

    test('Extracts rows from comma-delimited CSV', () {
      final csvContent = '''
Wine,Producer,Vintage,Color,Quantity
Barolo Cannubi,Vietti,2016,red,2
Brunello di Montalcino,Biondi-Santi,2015,red,1
'''.trim();

      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final rows = ExcelImportService.extractRawRows(bytes: bytes, fileName: 'italian_wines.csv');

      expect(rows.length, 3);
      expect(rows[1], contains('Barolo Cannubi'));
      expect(rows[2], contains('Brunello di Montalcino'));
    });

    test('Extracts rows from tab-delimited TSV', () {
      final tsvContent = "Wine\tVintage\tQty\nPétrus\t2010\t1\n";
      final bytes = Uint8List.fromList(utf8.encode(tsvContent));
      final rows = ExcelImportService.extractRawRows(bytes: bytes, fileName: 'prestige.tsv');

      expect(rows.length, 2);
      expect(rows[1], contains('Pétrus'));
      expect(rows[1], contains('2010'));
    });

    test('ImportedWineCandidate JSON model round-trip handles all wine attributes', () {
      final candidate = ImportedWineCandidate(
        name: 'Château Cheval Blanc',
        producer: 'Cheval Blanc',
        vintage: 2018,
        type: 'red',
        region: 'Bordeaux',
        country: 'France',
        appellation: 'Saint-Émilion Grand Cru',
        quantity: 6,
        bottleSize: '1.5L',
        purchasePrice: 850.0,
        currency: 'EUR',
        rack: 'Grand Cru',
        shelf: 'A1',
      );

      final json = candidate.toJson();
      expect(json['name'], 'Château Cheval Blanc');
      expect(json['bottle_size'], '1.5L');
      expect(json['quantity'], 6);
      expect(json['purchase_price'], 850.0);

      final restored = ImportedWineCandidate.fromJson(json);
      expect(restored.name, 'Château Cheval Blanc');
      expect(restored.vintage, 2018);
      expect(restored.bottleSize, '1.5L');
      expect(restored.quantity, 6);
      expect(restored.isSelected, isTrue);
    });
  });

  group('Cupboard / Loose Storage (Placard / Rangement libre) & Bottle Location State', () {
    test('CellarFurniture cupboard configuration and shape naming', () {
      final cupboard = CellarFurniture(
        id: 'cupboard-1',
        cellarId: 'cellar-1',
        name: 'Placard Cuisine',
        shapeType: CellarFurniture.shapeCupboard,
        columns: 1,
        rows: 3,
        slotsMatrix: CellarFurniture.generateMatrix(
          shapeType: CellarFurniture.shapeCupboard,
          columns: 1,
          rows: 3,
        ),
      );

      expect(cupboard.isCupboard, isTrue);
      expect(cupboard.shapeTypeName, 'Placard / Rangement libre');
      expect(cupboard.slotsMatrix.length, 3);
      expect(cupboard.slotsMatrix[0].length, 1);
      expect(cupboard.isSlotActive(0, 0), isTrue);
      expect(cupboard.isSlotActive(0, 2), isTrue);
      expect(cupboard.isSlotActive(0, 3), isFalse); // Out of bounds
    });

    test('CellarFurniture.describeSlotCode formats cupboard and loose storage codes nicely', () {
      expect(CellarFurniture.describeSlotCode('Placard'), 'Rangement libre (sans case fixe)');
      expect(CellarFurniture.describeSlotCode('Vrac'), 'Rangement libre (sans case fixe)');
      expect(CellarFurniture.describeSlotCode('Étagère 1'), 'Étagère 1');
      expect(CellarFurniture.describeSlotCode('Niveau 3'), 'Niveau 3');
      expect(CellarFurniture.describeSlotCode('A7'), 'A7 (1ère colonne, 7e rangée)');
    });

    test('Bottle hasLocation and locationSummary reflect cupboard, slot, or legacy coordinates', () {
      final now = DateTime.now();

      // 1. Bottle with no location
      final unassigned = Bottle(
        id: 'b-0',
        cellarId: 'cellar-1',
        wineId: 'w-1',
        addedBy: 'user-1',
        ownerId: 'user-1',
        createdAt: now,
      );
      expect(unassigned.hasLocation, isFalse);
      expect(unassigned.locationSummary, 'Emplacement non défini');

      // 2. Bottle in Cupboard with slot code
      final inCupboard = Bottle(
        id: 'b-1',
        cellarId: 'cellar-1',
        wineId: 'w-1',
        addedBy: 'user-1',
        ownerId: 'user-1',
        createdAt: now,
        furnitureId: 'cupboard-1',
        furnitureSlot: 'Étagère 2',
      );
      expect(inCupboard.hasLocation, isTrue);
      expect(inCupboard.locationSummary, 'Étagère 2');

      // 3. Bottle in Cupboard with bulk keyword
      final inBulkCupboard = Bottle(
        id: 'b-2',
        cellarId: 'cellar-1',
        wineId: 'w-1',
        addedBy: 'user-1',
        ownerId: 'user-1',
        createdAt: now,
        furnitureId: 'cupboard-1',
        furnitureSlot: 'Placard',
      );
      expect(inBulkCupboard.hasLocation, isTrue);
      expect(inBulkCupboard.locationSummary, 'Placard');

      // 4. Bottle in rigid rack (slot A7)
      final inRack = Bottle(
        id: 'b-3',
        cellarId: 'cellar-1',
        wineId: 'w-1',
        addedBy: 'user-1',
        ownerId: 'user-1',
        createdAt: now,
        furnitureId: 'rack-1',
        furnitureSlot: 'A7',
      );
      expect(inRack.hasLocation, isTrue);
      expect(inRack.locationSummary, 'A7');

      // 5. Bottle with manual rack/shelf/pos
      final manualCoords = Bottle(
        id: 'b-4',
        cellarId: 'cellar-1',
        wineId: 'w-1',
        addedBy: 'user-1',
        ownerId: 'user-1',
        createdAt: now,
        rack: '1',
        shelf: '2',
        position: '3',
      );
      expect(manualCoords.hasLocation, isTrue);
      expect(manualCoords.locationSummary, 'Casier 1 • Tablette 2 • Pos 3');

      // 6. Bottle instantiated from Supabase response payload (BottleDetailScreen bug fix verification)
      final supabaseBottleData = {
        'id': '00000000-0000-0000-0000-000000000001',
        'cellar_id': 'cellar-uuid',
        'wine_id': 'wine-uuid',
        'added_by': 'user-uuid',
        'owner_id': 'user-uuid',
        'quantity': 2,
        'purchase_price': 45.0,
        'currency': 'EUR',
        'status': 'in_cellar',
        'furniture_id': 'furniture-uuid-123',
        'furniture_slot': 'A7',
        'bottle_size': '75cl',
        'purchase_location': 'Domaine Test',
        'source_type': 'estate',
        'source_details': 'Domaine Test',
        'created_at': now.toIso8601String(),
      };

      final reconstructedBottle = Bottle(
        id: supabaseBottleData['id'] as String,
        cellarId: supabaseBottleData['cellar_id'] as String,
        wineId: supabaseBottleData['wine_id'] as String,
        addedBy: supabaseBottleData['added_by'] as String,
        ownerId: supabaseBottleData['owner_id'] as String,
        quantity: supabaseBottleData['quantity'] as int,
        purchasePrice: (supabaseBottleData['purchase_price'] as num).toDouble(),
        currency: supabaseBottleData['currency'] as String,
        status: supabaseBottleData['status'] as String,
        furnitureId: supabaseBottleData['furniture_id'] as String?,
        furnitureSlot: supabaseBottleData['furniture_slot'] as String?,
        bottleSize: supabaseBottleData['bottle_size'] as String? ?? '75cl',
        purchaseLocation: supabaseBottleData['purchase_location'] as String?,
        sourceType: supabaseBottleData['source_type'] as String?,
        sourceDetails: supabaseBottleData['source_details'] as String?,
        createdAt: now,
      );

      expect(reconstructedBottle.furnitureId, 'furniture-uuid-123');
      expect(reconstructedBottle.furnitureSlot, 'A7');
      expect(reconstructedBottle.hasLocation, isTrue);
      expect(reconstructedBottle.locationSummary, 'A7');
      expect(reconstructedBottle.provenanceDisplay, contains('Domaine Test'));

      // 7. Unassigning clears location
      final unassignedFromFurniture = Bottle(
        id: reconstructedBottle.id,
        cellarId: reconstructedBottle.cellarId,
        wineId: reconstructedBottle.wineId,
        addedBy: reconstructedBottle.addedBy,
        ownerId: reconstructedBottle.ownerId,
        createdAt: now,
        furnitureId: null,
        furnitureSlot: null,
      );
      expect(unassignedFromFurniture.hasLocation, isFalse);
      expect(unassignedFromFurniture.locationSummary, 'Emplacement non défini');
    });
  });
}
