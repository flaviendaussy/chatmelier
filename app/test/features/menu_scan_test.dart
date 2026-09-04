import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/data/wine_knowledge_cache_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('MenuWine & ScannedMenu Domain Tests', () {
    test('MenuWine deserialization and serialization round-trip', () {
      final json = {
        'id': 'wine_1',
        'name': 'Château Margaux',
        'producer': 'Château Margaux',
        'vintage': 2015,
        'wine_type': 'red',
        'region': 'Bordeaux',
        'appellation': 'Margaux',
        'country': 'France',
        'grapes': ['Cabernet Sauvignon', 'Merlot'],
        'bottle_price': 650.0,
        'glass_prices': [
          {'format': '125ml', 'price': 110.0},
          {'format': '175ml', 'price': 150.0},
        ],
        'sommelier_comment': 'Un millésime d\'anthologie, tanins soyeux et finale infinie.',
        'food_pairings': ['Filet de bœuf Rossini', 'Agneau de Pauillac'],
        'tags': ['tannique', 'boisé', 'fruité'],
        'metrics': {
          'tannins': 8.5,
          'acidity': 6.5,
          'body': 9.0,
          'fruit': 8.0,
          'oak': 7.5,
          'minerality': 5.0,
          'butteriness': 1.0,
          'sweetness': 0.5,
        },
      };

      final wine = MenuWine.fromJson(json);
      expect(wine.id, 'wine_1');
      expect(wine.name, 'Château Margaux');
      expect(wine.wineType, 'red');
      expect(wine.isRed, true);
      expect(wine.isWhite, false);
      expect(wine.bottlePrice, 650.0);
      expect(wine.glassPrices.length, 2);
      expect(wine.glassPrices[0].format, '125ml');
      expect(wine.glassPrices[0].price, 110.0);
      expect(wine.priceDisplay.contains('650 € / bt'), true);
      expect(wine.priceDisplay.contains('110 € (125ml)'), true);
      expect(wine.metrics.tannins, 8.5);

      final serialized = wine.toJson();
      expect(serialized['name'], 'Château Margaux');
      expect((serialized['glass_prices'] as List).length, 2);
      expect(serialized['bottle_price'], 650.0);
    });

    test('ScannedMenu parsing with multiple wines and type separation', () {
      final menuJson = {
        'id': 'menu_01',
        'restaurant_name': 'Le Gabriel',
        'scanned_at': '2026-09-04T12:00:00.000Z',
        'page_photo_paths': ['/tmp/page1.jpg'],
        'wines': [
          {
            'id': 'w_red',
            'name': 'Château de Beaucastel',
            'producer': 'Famille Perrin',
            'vintage': 2019,
            'wine_type': 'red',
            'bottle_price': 120.0,
            'glass_prices': [],
            'metrics': {
              'tannins': 8.0,
              'acidity': 6.0,
              'body': 8.5,
              'fruit': 7.5,
              'oak': 7.0,
              'minerality': 4.0,
              'butteriness': 1.0,
              'sweetness': 0.5,
            },
          },
          {
            'id': 'w_white',
            'name': 'Chablis Premier Cru Montée de Tonnerre',
            'producer': 'Louis Michel',
            'vintage': 2020,
            'wine_type': 'white',
            'bottle_price': 85.0,
            'glass_prices': [{'format': '125ml', 'price': 16.0}],
            'metrics': {
              'tannins': 0.5,
              'acidity': 8.5,
              'body': 5.5,
              'fruit': 6.5,
              'oak': 1.0,
              'minerality': 9.5,
              'butteriness': 2.5,
              'sweetness': 0.5,
            },
          },
        ],
      };

      final menu = ScannedMenu.fromJson(menuJson);
      expect(menu.restaurantName, 'Le Gabriel');
      expect(menu.wines.length, 2);
      expect(menu.redWines.length, 1);
      expect(menu.whiteWines.length, 1);
      expect(menu.whiteWines.first.priceDisplay.contains('85 € / bt'), true);
      expect(menu.whiteWines.first.priceDisplay.contains('16 € (125ml)'), true);
    });
  });

  group('Red vs White Radar Metrics Separation', () {
    test('Red wine maps strictly to red axes', () {
      const redMetrics = MenuWineRadarMetrics(
        tannins: 9.0,
        acidity: 6.0,
        body: 8.5,
        fruit: 7.5,
        oak: 8.0,
        minerality: 4.0,
        butteriness: 0.5,
        sweetness: 0.2,
      );

      final radar = redMetrics.toRedRadarMetrics();
      expect(radar.body, 9.0); // Axe 1: Tannins & Structure
      expect(radar.acidity, 8.5); // Axe 2: Puissance & Corps
      expect(radar.fruit, 6.0); // Axe 3: Fraîcheur & Acidité
      expect(radar.oak, 7.5); // Axe 4: Fruit & Gourmandise
      expect(radar.minerality, 8.0); // Axe 5: Boisé & Élevage
      expect(radar.sweetness, 4.0); // Axe 6: Minéralité & Épices

      final labels = MenuWineRadarMetrics.redAxisLabels;
      expect(labels.length, 6);
      expect(labels[0].contains('Tannins'), true);
      expect(labels[1].contains('Puissance'), true);
    });

    test('White wine maps strictly to white axes', () {
      const whiteMetrics = MenuWineRadarMetrics(
        tannins: 0.2,
        acidity: 7.8,
        body: 8.0,
        fruit: 7.0,
        oak: 6.5,
        minerality: 8.5,
        butteriness: 9.0,
        sweetness: 0.5,
      );

      final radar = whiteMetrics.toWhiteRadarMetrics();
      expect(radar.body, 8.5); // Axe 1: Minéralité & Tension
      expect(radar.acidity, 7.8); // Axe 2: Fraîcheur & Vivacité
      expect(radar.fruit, 7.0); // Axe 3: Fruit & Arômes
      expect(radar.oak, 9.0); // Axe 4: Beurré & Rondeur
      expect(radar.minerality, 6.5); // Axe 5: Boisé & Élevage
      expect(radar.sweetness, 8.0); // Axe 6: Corps & Puissance

      final labels = MenuWineRadarMetrics.whiteAxisLabels;
      expect(labels.length, 6);
      expect(labels[0].contains('Minéralité'), true);
      expect(labels[3].contains('Beurré'), true);
    });
  });

  group('WineKnowledgeCacheService Tests', () {
    test('Stores and retrieves wine sensory data in local database', () async {
      final cacheService = WineKnowledgeCacheService();
      expect(await cacheService.count(), 0);

      const wine = MenuWine(
        id: 'w_bourgogne',
        name: 'Meursault',
        producer: 'Coche-Dury',
        vintage: 2020,
        wineType: 'white',
        region: 'Bourgogne',
        bottlePrice: 350.0,
        tags: ['beurré', 'minéral', 'noisette'],
        metrics: MenuWineRadarMetrics(
          tannins: 0.5,
          acidity: 8.2,
          body: 8.8,
          fruit: 7.0,
          oak: 6.0,
          minerality: 9.2,
          butteriness: 8.5,
          sweetness: 0.5,
        ),
      );

      await cacheService.cacheWine(wine);
      expect(await cacheService.count(), 1);

      // Lookup by exact tuple
      final retrievedMetrics = await cacheService.findSensoryMetrics(
        'Meursault',
        'Coche-Dury',
        2020,
        'white',
      );

      expect(retrievedMetrics, isNotNull);
      expect(retrievedMetrics!.butteriness, 8.5);
      expect(retrievedMetrics.minerality, 9.2);

      // Case and accent-insensitive match
      final fuzzyMetrics = await cacheService.findSensoryMetrics(
        'meursault',
        'coche-dury',
        2020,
        'white',
      );
      expect(fuzzyMetrics, isNotNull);
      expect(fuzzyMetrics!.acidity, 8.2);

      // Fallback search with just name
      final fallbackMetrics = await cacheService.findSensoryMetrics('Meursault');
      expect(fallbackMetrics, isNotNull);
      expect(fallbackMetrics!.butteriness, 8.5);

      // Lookup unknown wine returns null
      final unknown = await cacheService.findSensoryMetrics('Inconnu', '', 1900);
      expect(unknown, isNull);
    });

    test('Bulk caching saves multiple wines efficiently', () async {
      final cacheService = WineKnowledgeCacheService();
      final wines = <MenuWine>[
        const MenuWine(
          id: '1',
          name: 'Pétrus',
          producer: 'Pétrus',
          vintage: 2015,
          wineType: 'red',
          metrics: MenuWineRadarMetrics(tannins: 9.0, acidity: 7.0, body: 9.5),
        ),
        const MenuWine(
          id: '2',
          name: 'Yquem',
          producer: 'Château d\'Yquem',
          vintage: 2017,
          wineType: 'white',
          metrics: MenuWineRadarMetrics(sweetness: 9.5, acidity: 8.5, body: 9.0),
        ),
      ];

      await cacheService.bulkCache(wines);
      expect(await cacheService.count(), 2);

      final petrus = await cacheService.findWine('Pétrus');
      expect(petrus, isNotNull);
      expect(petrus!.name, 'Pétrus');

      final yquem = await cacheService.findWine('Yquem');
      expect(yquem, isNotNull);
      expect(yquem!.name, 'Yquem');
    });
  });

  group('MenuWineMatchCalculator Tests', () {
    test('Calculates personalized match score based on user profile', () {
      const profile = TasteProfile(
        id: 'user_p1',
        name: 'Alexandre',
        favoriteTypes: ['Rouge'],
        favoriteRegions: ['Vallée du Rhône'],
        favoriteGrapes: ['Syrah'],
        dislikedCharacteristics: ['Trop acide'],
        avgTanninPreference: 0.85,
        avgBodyPreference: 0.85,
      );

      const tannicRedWine = MenuWine(
        id: 'tannic_red',
        name: 'Hermitage',
        producer: 'Jean-Louis Chave',
        vintage: 2018,
        wineType: 'red',
        region: 'Vallée du Rhône',
        grapes: ['Syrah'],
        metrics: MenuWineRadarMetrics(
          tannins: 8.8,
          oak: 8.2,
          body: 8.5,
          acidity: 6.0,
          fruit: 7.5,
          minerality: 4.0,
          butteriness: 0.5,
          sweetness: 0.5,
        ),
      );

      const sweetWhiteWine = MenuWine(
        id: 'sweet_white',
        name: 'Monbazillac',
        producer: 'Domaine de Montlong',
        vintage: 2020,
        wineType: 'white',
        region: 'Sud-Ouest',
        grapes: ['Sémillon'],
        metrics: MenuWineRadarMetrics(
          tannins: 0.2,
          oak: 2.0,
          body: 7.0,
          acidity: 3.5,
          fruit: 8.0,
          minerality: 3.0,
          butteriness: 4.0,
          sweetness: 8.5,
        ),
      );

      final redScore = MenuWineMatchCalculator.calculateMatch(tannicRedWine, profile);
      final whiteScore = MenuWineMatchCalculator.calculateMatch(sweetWhiteWine, profile);

      expect(redScore, greaterThan(whiteScore));
      expect(redScore, greaterThanOrEqualTo(80.0));
      expect(whiteScore, lessThan(80.0));
    });

    test('Score falls back gracefully when no taste profile exists', () {
      const wine = MenuWine(
        id: 'regular',
        name: 'Côtes du Rhône',
        producer: 'Guigal',
        wineType: 'red',
        metrics: MenuWineRadarMetrics(
          tannins: 6.0,
          acidity: 5.0,
          body: 6.0,
          fruit: 7.0,
        ),
      );

      final neutralScore = MenuWineMatchCalculator.calculateMatch(wine, null);
      expect(neutralScore, inInclusiveRange(35.0, 99.0));
    });
  });
}
