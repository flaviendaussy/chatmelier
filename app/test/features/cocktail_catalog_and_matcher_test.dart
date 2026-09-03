import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cocktails/data/cocktail_catalog.dart';
import 'package:chatmelier/features/cocktails/domain/bar_pantry_item.dart';
import 'package:chatmelier/features/cocktails/domain/cocktail_matcher.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cocktail Catalog & Matcher Tests', () {
    test('Catalog contains at least 45 cocktails across spirits', () {
      expect(CocktailCatalog.all.length, greaterThanOrEqualTo(45));

      final ginCocktails = CocktailCatalog.all.where((c) => c.baseSpirit == 'gin');
      final rumCocktails = CocktailCatalog.all.where((c) => c.baseSpirit == 'rhum');
      final whiskyCocktails = CocktailCatalog.all.where((c) => c.baseSpirit == 'whisky');
      final vodkaCocktails = CocktailCatalog.all.where((c) => c.baseSpirit == 'vodka');
      final tequilaCocktails = CocktailCatalog.all.where((c) => c.baseSpirit == 'tequila' || c.baseSpirit == 'mezcal');

      expect(ginCocktails.length, greaterThanOrEqualTo(8));
      expect(rumCocktails.length, greaterThanOrEqualTo(8));
      expect(whiskyCocktails.length, greaterThanOrEqualTo(7));
      expect(vodkaCocktails.length, greaterThanOrEqualTo(6));
      expect(tequilaCocktails.length, greaterThanOrEqualTo(5));
    });

    test('CocktailMatcher identifies 100% ready cocktail when all spirits and pantry in stock', () {
      final mojito = CocktailCatalog.all.firstWhere((c) => c.id == 'mojito');

      // Setup cellar with Cuban Rum
      final rumBottle = Bottle(
        id: 'bottle-rum-1',
        cellarId: 'cellar-1',
        wineId: 'wine-rum-1',
        addedBy: 'user-1',
        ownerId: 'user-1',
        createdAt: DateTime(2025, 1, 1),
        quantity: 1,
        wine: const Wine(
          id: 'wine-rum-1',
          name: 'Havana Club Añejo 3 Años',
          producer: 'Havana Club',
          type: 'rhum',
          country: 'Cuba',
          region: 'Cuba',
        ),
      );

      // Setup pantry with lime, mint, sugar, and soda water
      final pantry = [
        const BarPantryItem(id: 'lime', name: 'Citron vert', category: PantryCategory.fruits, quantity: 4),
        const BarPantryItem(id: 'mint', name: 'Menthe fraîche', category: PantryCategory.herbs, quantity: 2),
        const BarPantryItem(id: 'sugar_syrup', name: 'Sirop de sucre', category: PantryCategory.syrups, quantity: 1),
        const BarPantryItem(id: 'soda_water', name: 'Eau gazeuse', category: PantryCategory.mixers, quantity: 3),
      ];

      final match = CocktailMatcher.matchCocktail(
        cocktail: mojito,
        cellarBottles: [rumBottle],
        pantryItems: pantry,
      );

      expect(match.isReady, isTrue);
      expect(match.isAlmostReady, isFalse);
      expect(match.missingIngredients, isEmpty);
      expect(match.matchedBottles.containsKey('rum'), isTrue);
    });

    test('CocktailMatcher identifies almost ready cocktail when exactly 1 ingredient missing', () {
      final ginTonic = CocktailCatalog.all.firstWhere((c) => c.id == 'gin_tonic');

      // Gin in cellar
      final ginBottle = Bottle(
        id: 'bottle-gin-1',
        cellarId: 'cellar-1',
        wineId: 'wine-gin-1',
        addedBy: 'user-1',
        ownerId: 'user-1',
        createdAt: DateTime(2025, 1, 1),
        quantity: 1,
        wine: const Wine(
          id: 'wine-gin-1',
          name: 'Hendrick\'s Gin',
          type: 'gin',
          country: 'Scotland',
          region: 'Girvan',
        ),
      );

      // Pantry has lime, but NO tonic
      final pantry = [
        const BarPantryItem(id: 'lime', name: 'Citron vert', category: PantryCategory.fruits, quantity: 2),
        const BarPantryItem(id: 'tonic', name: 'Tonic Water', category: PantryCategory.mixers, quantity: 0),
      ];

      final match = CocktailMatcher.matchCocktail(
        cocktail: ginTonic,
        cellarBottles: [ginBottle],
        pantryItems: pantry,
      );

      expect(match.isReady, isFalse);
      expect(match.isAlmostReady, isTrue);
      expect(match.missingCount, 1);
      expect(match.missingIngredients.any((i) => i.contains('Tonic')), isTrue);
    });

    test('CocktailMatcher identifies cocktail with missing base spirit', () {
      final margarita = CocktailCatalog.all.firstWhere((c) => c.id == 'margarita');

      // Pantry has lime and salt, but NO tequila in cellar
      final pantry = [
        const BarPantryItem(id: 'lime', name: 'Citron vert', category: PantryCategory.fruits, quantity: 3),
        const BarPantryItem(id: 'salt', name: 'Fleur de sel', category: PantryCategory.syrups, quantity: 1),
      ];

      final match = CocktailMatcher.matchCocktail(
        cocktail: margarita,
        cellarBottles: [],
        pantryItems: pantry,
      );

      expect(match.isReady, isFalse);
      expect(match.missingIngredients.any((i) => i.contains('Tequila')), isTrue);
    });
  });
}
