import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine_food_matcher.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

void main() {
  group('WineFoodMatcher Unit Tests', () {
    final bordeauxBottle = Bottle(
      id: 'b1',
      cellarId: 'c1',
      wineId: 'w1',
      addedBy: 'user1',
      ownerId: 'user1',
      status: 'in_cellar',
      quantity: 3,
      createdAt: DateTime.now(),
      wine: const Wine(
        id: 'w1',
        name: 'Château Margaux',
        appellation: 'Margaux',
        region: 'Bordeaux',
        country: 'France',
        type: 'red',
        vintage: 2015,
        drinkStart: 2022,
        drinkEnd: 2045,
        grapes: [Grape(name: 'Cabernet Sauvignon'), Grape(name: 'Merlot')],
      ),
    );

    final chablisBottle = Bottle(
      id: 'b2',
      cellarId: 'c1',
      wineId: 'w2',
      addedBy: 'user1',
      ownerId: 'user1',
      status: 'in_cellar',
      quantity: 2,
      createdAt: DateTime.now(),
      wine: const Wine(
        id: 'w2',
        name: 'Domaine Laroche Chablis Grand Cru',
        appellation: 'Chablis Grand Cru',
        region: 'Bourgogne',
        country: 'France',
        type: 'white',
        vintage: 2020,
        drinkStart: 2023,
        drinkEnd: 2035,
        grapes: [Grape(name: 'Chardonnay')],
      ),
    );

    final sancerreBottle = Bottle(
      id: 'b3',
      cellarId: 'c1',
      wineId: 'w3',
      addedBy: 'user1',
      ownerId: 'user1',
      status: 'in_cellar',
      quantity: 4,
      createdAt: DateTime.now(),
      wine: const Wine(
        id: 'w3',
        name: 'Domaine Vacheron Sancerre',
        appellation: 'Sancerre',
        region: 'Vallée de la Loire',
        country: 'France',
        type: 'white',
        vintage: 2022,
        drinkStart: 2023,
        drinkEnd: 2028,
        grapes: [Grape(name: 'Sauvignon Blanc')],
      ),
    );

    final sauternesBottle = Bottle(
      id: 'b4',
      cellarId: 'c1',
      wineId: 'w4',
      addedBy: 'user1',
      ownerId: 'user1',
      status: 'in_cellar',
      quantity: 1,
      createdAt: DateTime.now(),
      wine: const Wine(
        id: 'w4',
        name: 'Château d\'Yquem',
        appellation: 'Sauternes',
        region: 'Bordeaux',
        country: 'France',
        type: 'dessert',
        vintage: 2016,
        drinkStart: 2021,
        drinkEnd: 2060,
        grapes: [Grape(name: 'Sémillon'), Grape(name: 'Sauvignon Blanc')],
      ),
    );

    final savoieBottle = Bottle(
      id: 'b5',
      cellarId: 'c1',
      wineId: 'w5',
      addedBy: 'user1',
      ownerId: 'user1',
      status: 'in_cellar',
      quantity: 6,
      createdAt: DateTime.now(),
      wine: const Wine(
        id: 'w5',
        name: 'Domaine Jean Perrier Apremont',
        appellation: 'Apremont',
        region: 'Savoie',
        country: 'France',
        type: 'white',
        vintage: 2023,
        drinkStart: 2023,
        drinkEnd: 2026,
        grapes: [Grape(name: 'Jacquère')],
      ),
    );

    final List<Bottle> allBottles = [
      bordeauxBottle,
      chablisBottle,
      sancerreBottle,
      sauternesBottle,
      savoieBottle,
    ];

    test('Côte de bœuf query should rank Bordeaux at top with ideal score', () {
      final matches = WineFoodMatcher.findMatches(
        bottles: allBottles,
        dishQuery: 'Côte de bœuf grillée aux sarments',
      );

      expect(matches, isNotEmpty);
      expect(matches.first.bottle.id, equals('b1'));
      expect(matches.first.matchLevel, equals(FoodMatchLevel.ideal));
      expect(matches.first.score, greaterThanOrEqualTo(85));
      expect(matches.first.sommelierComment.toLowerCase(), contains('bordeaux'));
    });

    test('Huîtres / Fruits de mer query should rank Chablis at top', () {
      final matches = WineFoodMatcher.findMatches(
        bottles: allBottles,
        dishQuery: 'Plateau d\'huîtres et fruits de mer',
      );

      expect(matches, isNotEmpty);
      expect(matches.first.bottle.id, equals('b2'));
      expect(matches.first.matchLevel, equals(FoodMatchLevel.ideal));
      expect(matches.first.score, greaterThanOrEqualTo(85));
      expect(matches.first.sommelierComment.toLowerCase(), contains('salin'));
    });

    test('Fromage de chèvre query should rank Sancerre at top', () {
      final matches = WineFoodMatcher.findMatches(
        bottles: allBottles,
        dishQuery: 'Crottin de Chavignol et fromage de chèvre',
      );

      expect(matches, isNotEmpty);
      expect(matches.first.bottle.id, equals('b3'));
      expect(matches.first.matchLevel, equals(FoodMatchLevel.ideal));
      expect(matches.first.sommelierComment.toLowerCase(), contains('sauvignon'));
    });

    test('Roquefort query should rank Sauternes as ideal contrast pairing', () {
      final matches = WineFoodMatcher.findMatches(
        bottles: allBottles,
        dishQuery: 'Roquefort et fromage bleu',
      );

      expect(matches, isNotEmpty);
      expect(matches.first.bottle.id, equals('b4'));
      expect(matches.first.matchLevel, equals(FoodMatchLevel.ideal));
      expect(matches.first.sommelierComment.toLowerCase(), contains('moelleux'));
    });

    test('Raclette query should rank Savoie Apremont at top with ideal score', () {
      final matches = WineFoodMatcher.findMatches(
        bottles: allBottles,
        dishQuery: 'Raclette traditionnelle savoyarde',
      );

      expect(matches, isNotEmpty);
      expect(matches.first.bottle.id, equals('b5'));
      expect(matches.first.matchLevel, equals(FoodMatchLevel.ideal));
      expect(matches.first.sommelierComment.toLowerCase(), contains('alpine'));
    });

    test('Foie gras query should rank Sauternes at top', () {
      final matches = WineFoodMatcher.findMatches(
        bottles: allBottles,
        dishQuery: 'Foie gras mi-cuit sur toast',
      );

      expect(matches, isNotEmpty);
      expect(matches.first.bottle.id, equals('b4'));
      expect(matches.first.matchLevel, equals(FoodMatchLevel.ideal));
      expect(matches.first.sommelierComment.toLowerCase(), contains('foie gras'));
    });

    test('16 categories are all loaded with rich sample dishes and keywords', () {
      expect(WineFoodMatcher.categories.length, equals(16));
      for (final cat in WineFoodMatcher.categories) {
        expect(cat.sampleDishes, isNotEmpty);
        expect(cat.keywords, isNotEmpty);
        expect(cat.icon, isNotEmpty);
      }
    });

    test('Strict threshold rejects incompatible wines (no weak ~10-15% matches)', () {
      // Searching for oysters: Bordeaux red should NOT be returned even as fallback
      final matches = WineFoodMatcher.findMatches(
        bottles: [bordeauxBottle],
        dishQuery: 'Huîtres fraîches du bassin d\'Arcachon',
      );

      // Score must be below minQualityScore (60), so matches must be completely empty!
      expect(matches, isEmpty);
    });

    test('Sommelier advice provides high-value recommendations on unmatched dishes', () {
      final adviceOysters = WineFoodMatcher.getSommelierAdviceForDish('Huîtres chaudes');
      expect(adviceOysters.toLowerCase(), contains('chablis'));

      final adviceRaclette = WineFoodMatcher.getSommelierAdviceForDish('Raclette valaisanne');
      expect(adviceRaclette.toLowerCase(), contains('savoie'));

      final adviceChocolate = WineFoodMatcher.getSommelierAdviceForDish('Fondant au chocolat');
      expect(adviceChocolate.toLowerCase(), contains('banyuls'));
    });

    test('"roast leg of lamb with thyme" matches Bordeaux red with ideal score and thyme notes', () {
      final matches = WineFoodMatcher.findMatches(
        bottles: allBottles,
        dishQuery: 'roast leg of lamb with thyme',
      );

      expect(matches, isNotEmpty);
      expect(matches.first.bottle.id, equals('b1'));
      expect(matches.first.matchLevel, equals(FoodMatchLevel.ideal));
      expect(matches.first.score, greaterThanOrEqualTo(90));
      expect(matches.first.sommelierComment.toLowerCase(), contains('thym'));
    });

    test('Score differentiation across diverse red wines on lamb query', () {
      final rhoneBottle = Bottle(
        id: 'b_rhone',
        cellarId: 'c1',
        wineId: 'w_rhone',
        addedBy: 'user1',
        ownerId: 'user1',
        status: 'in_cellar',
        quantity: 2,
        createdAt: DateTime.now(),
        wine: const Wine(
          id: 'w_rhone',
          name: 'Jean-Louis Chave Hermitage',
          appellation: 'Hermitage',
          region: 'Vallée du Rhône',
          country: 'France',
          type: 'red',
          vintage: 2017,
          drinkStart: 2022,
          drinkEnd: 2040,
          grapes: [Grape(name: 'Syrah')],
        ),
      );

      final bandolBottle = Bottle(
        id: 'b_bandol',
        cellarId: 'c1',
        wineId: 'w_bandol',
        addedBy: 'user1',
        ownerId: 'user1',
        status: 'in_cellar',
        quantity: 2,
        createdAt: DateTime.now(),
        wine: const Wine(
          id: 'w_bandol',
          name: 'Domaine Tempier Bandol Rouge',
          appellation: 'Bandol',
          region: 'Provence',
          country: 'France',
          type: 'red',
          vintage: 2018,
          drinkStart: 2022,
          drinkEnd: 2038,
          grapes: [Grape(name: 'Mourvèdre'), Grape(name: 'Grenache')],
        ),
      );

      final burgundyBottle = Bottle(
        id: 'b_burgundy',
        cellarId: 'c1',
        wineId: 'w_burgundy',
        addedBy: 'user1',
        ownerId: 'user1',
        status: 'in_cellar',
        quantity: 1,
        createdAt: DateTime.now(),
        wine: const Wine(
          id: 'w_burgundy',
          name: 'Domaine Armand Rousseau Gevrey-Chambertin',
          appellation: 'Gevrey-Chambertin',
          region: 'Bourgogne',
          country: 'France',
          type: 'red',
          vintage: 2019,
          drinkStart: 2024,
          drinkEnd: 2035,
          grapes: [Grape(name: 'Pinot Noir')],
        ),
      );

      final cellarReds = [bordeauxBottle, rhoneBottle, bandolBottle, burgundyBottle];
      final matches = WineFoodMatcher.findMatches(
        bottles: cellarReds,
        dishQuery: 'roast leg of lamb with thyme',
      );

      expect(matches.length, equals(4));

      // Check scores are discriminated and distinct
      final scores = matches.map((m) => m.score).toList();
      expect(scores.toSet().length, greaterThanOrEqualTo(3), reason: 'Scores should not all be identical flat numbers');

      // The top 3 should be high matches (Bordeaux, Bandol, Rhône) >= 90
      final topMatch = matches.first;
      expect(topMatch.score, greaterThanOrEqualTo(93));

      // Burgundy Pinot Noir should have a lower score than Bandol/Bordeaux/Rhône for roast lamb with thyme
      final burgundyMatch = matches.firstWhere((m) => m.bottle.id == 'b_burgundy');
      expect(burgundyMatch.score, lessThan(matches.first.score));
      expect(burgundyMatch.score, inInclusiveRange(70, 85));
    });

    test('Multilingual sommelier advice for roast leg of lamb with thyme', () {
      final adviceEn = WineFoodMatcher.getSommelierAdviceForDish('roast leg of lamb with thyme', 'en');
      expect(adviceEn.toLowerCase(), contains('lamb'));
      expect(adviceEn.toLowerCase(), contains('pauillac'));

      final adviceFr = WineFoodMatcher.getSommelierAdviceForDish('gigot d\'agneau au thym', 'fr');
      expect(adviceFr.toLowerCase(), contains('agneau'));
      expect(adviceFr.toLowerCase(), contains('pauillac'));
    });
  });
}
