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
  });
}
