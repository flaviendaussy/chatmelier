import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/chat/domain/cellar_macro_summary.dart';
import 'package:chatmelier/features/chat/domain/cellar_rag_retriever.dart';
import 'package:chatmelier/features/scan/data/label_image_optimizer.dart';
import 'package:chatmelier/features/scan/data/scan_cache_service.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LabelImageOptimizer Tests', () {
    test('Crops central ROI, bounds to max 1024px, and outputs deterministic SHA-256', () {
      final testImg = img.Image(width: 2000, height: 1200);
      img.fill(testImg, color: img.ColorRgb8(180, 50, 50));
      final rawJpeg = Uint8List.fromList(img.encodeJpg(testImg, quality: 90));

      final optimized = LabelImageOptimizer.optimize(rawJpeg);

      expect(optimized.bytes, isNotEmpty);
      expect(optimized.mimeType, 'image/jpeg');
      expect(optimized.sha256Hash.length, 64);

      final decoded = img.decodeImage(optimized.bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(1024));
      expect(decoded.height, lessThanOrEqualTo(1024));

      final optimizedAgain = LabelImageOptimizer.optimize(rawJpeg);
      expect(optimizedAgain.sha256Hash, equals(optimized.sha256Hash));
    });

    test('Fallback gracefully handles invalid image bytes without crashing', () {
      final invalidBytes = Uint8List.fromList(utf8.encode('not-an-image-data-payload'));
      final optimized = LabelImageOptimizer.optimize(invalidBytes);

      expect(optimized.bytes, equals(invalidBytes));
      expect(optimized.sha256Hash.length, 64);
    });
  });

  group('ScanCacheService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ScanCacheService().clear();
    });

    test('Returns null on cache miss', () async {
      final cache = ScanCacheService();
      final result = await cache.getCachedResult('non_existent_hash');
      expect(result, isNull);
    });

    test('Stores and retrieves ScanResult by SHA-256 fingerprint', () async {
      final cache = ScanCacheService();
      const testResult = ScanResult(
        name: 'Château Latour',
        producer: 'Domaine Latour',
        vintage: 2015,
        cuveeParcel: 'Grand Vin',
        wineType: 'red',
        country: 'France',
        region: 'Bordeaux',
        appellation: 'Pauillac',
        classification: '1er Grand Cru Classé',
        alcoholPct: 13.5,
        grapes: [
          Grape(name: 'Cabernet Sauvignon', pct: 90),
          Grape(name: 'Merlot', pct: 10),
        ],
        tastingNotes: 'Cassis, cèdre, tannins structurés.',
        foodPairings: ['Côte de boeuf', 'Agneau de Pauillac'],
        idealDrinkingStart: 2025,
        idealDrinkingEnd: 2045,
        peakDrinkingStart: 2028,
        peakDrinkingEnd: 2038,
        estimatedMarketValue: 650.0,
        detectedQuantity: 1,
      );

      const hash = 'a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0';
      await cache.cacheResult(hash, testResult);

      final retrieved = await cache.getCachedResult(hash);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Château Latour');
      expect(retrieved.vintage, 2015);
      expect(retrieved.appellation, 'Pauillac');
      expect(retrieved.foodPairings, contains('Côte de boeuf'));
      expect(retrieved.grapes.length, 2);
    });
  });

  group('CellarMacroSummary Tests', () {
    test('Synthesizes cellar into high-density hierarchical metadata', () {
      const wines = [
        Wine(
          id: 'w1',
          name: 'Chablis Premier Cru',
          producer: 'Domaine Laroche',
          vintage: 2020,
          type: 'white',
          country: 'France',
          region: 'Bourgogne',
          appellation: 'Chablis',
          estimatedMarketValue: 40.0,
          drinkStart: 2022,
          drinkEnd: 2028,
          peakStart: 2024,
          peakEnd: 2027,
        ),
        Wine(
          id: 'w2',
          name: 'Sancerre Blanc',
          producer: 'Henri Bourgeois',
          vintage: 2022,
          type: 'white',
          country: 'France',
          region: 'Vallée de la Loire',
          appellation: 'Sancerre',
          estimatedMarketValue: 25.0,
          drinkStart: 2023,
          drinkEnd: 2026,
        ),
        Wine(
          id: 'w3',
          name: 'Pauillac',
          producer: 'Château Lynch-Bages',
          vintage: 2016,
          type: 'red',
          country: 'France',
          region: 'Bordeaux',
          appellation: 'Pauillac',
          estimatedMarketValue: 160.0,
          drinkStart: 2024,
          drinkEnd: 2040,
          peakStart: 2026,
          peakEnd: 2035,
        ),
      ];

      final now = DateTime(2025, 1, 1);
      final List<Bottle> bottles = [
        Bottle(id: 'b1', wineId: 'w1', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[0], status: 'in_cellar'),
        Bottle(id: 'b2', wineId: 'w1', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[0], status: 'in_cellar'),
        Bottle(id: 'b3', wineId: 'w1', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[0], status: 'in_cellar'),
        Bottle(id: 'b4', wineId: 'w2', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[1], status: 'in_cellar'),
        Bottle(id: 'b5', wineId: 'w2', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[1], status: 'in_cellar'),
        Bottle(id: 'b6', wineId: 'w3', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[2], status: 'in_cellar'),
        Bottle(id: 'b7', wineId: 'w3', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[2], status: 'in_cellar'),
        Bottle(id: 'b8', wineId: 'w3', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[2], status: 'in_cellar'),
        Bottle(id: 'b9', wineId: 'w3', cellarId: 'c1', addedBy: 'user1', ownerId: 'user1', createdAt: now, wine: wines[2], status: 'in_cellar'),
      ];

      final summary = CellarMacroSummary.generate(bottles);

      expect(summary, contains('Total en cave : 9 bouteilles'));
      expect(summary, contains('Valeur estimée'));
      expect(summary, contains('Blancs (5)'));
      expect(summary, contains('Chablis (3)'));
      expect(summary, contains('Sancerre (2)'));
      expect(summary, contains('Rouges (4)'));
      expect(summary, contains('Pauillac (4)'));
      expect(summary, contains('apogée'));
    });
  });

  group('CellarRagRetriever Tests', () {
    const wineRed = Wine(
      id: 'w_red',
      name: 'Château Pontet-Canet',
      producer: 'Pontet-Canet',
      vintage: 2015,
      type: 'red',
      country: 'France',
      region: 'Bordeaux',
      appellation: 'Pauillac',
      tastingNotes: 'Cassis puissant, cèdre, épices douces, tanins soyeux.',
      foodPairings: ['Côte de boeuf grillée', 'Gigot d\'agneau', 'Gibier'],
      grapes: [
        Grape(name: 'Cabernet Sauvignon', pct: 65),
        Grape(name: 'Merlot', pct: 30),
      ],
      drinkStart: 2022,
      drinkEnd: 2038,
    );

    const wineWhite = Wine(
      id: 'w_white',
      name: 'Chablis Grand Cru Les Clos',
      producer: 'William Fèvre',
      vintage: 2020,
      type: 'white',
      country: 'France',
      region: 'Bourgogne',
      appellation: 'Chablis Grand Cru',
      tastingNotes: 'Minéralité saline, agrumes frais, silex, grande pureté.',
      foodPairings: ['Huîtres', 'Fruits de mer', 'Poisson grillé', 'Sole meunière'],
      grapes: [
        Grape(name: 'Chardonnay', pct: 100),
      ],
      drinkStart: 2024,
      drinkEnd: 2035,
    );

    final now = DateTime(2025, 1, 1);
    final List<Bottle> bottles = [
      Bottle(
        id: 'b_red_1',
        wineId: 'w_red',
        cellarId: 'c1',
        addedBy: 'user1',
        ownerId: 'user1',
        createdAt: now,
        wine: wineRed,
        status: 'in_cellar',
        rack: 'A',
        shelf: '2',
        position: '4',
      ),
      Bottle(
        id: 'b_white_1',
        wineId: 'w_white',
        cellarId: 'c1',
        addedBy: 'user1',
        ownerId: 'user1',
        createdAt: now,
        wine: wineWhite,
        status: 'in_cellar',
        rack: 'Cave principale',
        shelf: 'Étagère 1',
        position: 'B3',
      ),
    ];

    test('Retrieves red wine when asked for côte de boeuf with coordinates', () {
      final result = CellarRagRetriever.retrieveRelevantBottles(
        userMessage: 'Quel vin de ma cave pour accompagner une côte de boeuf ce soir ?',
        bottles: bottles,
      );

      expect(result.formattedContext, isNotEmpty);
      expect(result.formattedContext, contains('Château Pontet-Canet'));
      expect(result.formattedContext, contains('Pauillac'));
      expect(result.formattedContext, contains('Casier A, Étagère 2, Pos 4'));
    });

    test('Retrieves white wine when asked for huîtres ou poisson', () {
      final result = CellarRagRetriever.retrieveRelevantBottles(
        userMessage: 'Je prépare des huîtres et des fruits de mer, que me conseilles-tu ?',
        bottles: bottles,
      );

      expect(result.formattedContext, isNotEmpty);
      expect(result.formattedContext, contains('Chablis Grand Cru Les Clos'));
      expect(result.formattedContext, contains('Étagère 1, Pos B3'));
    });
  });
}
