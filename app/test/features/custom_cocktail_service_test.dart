import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/cocktails/data/cocktail_catalog.dart';
import 'package:chatmelier/features/cocktails/data/custom_cocktail_service.dart';
import 'package:chatmelier/features/cocktails/domain/cocktail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomCocktailService Tests', () {
    late CustomCocktailService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = CustomCocktailService(prefs);
    });

    test('Loads empty list when no custom cocktails saved', () {
      final list = service.getCustomCocktails();
      expect(list, isEmpty);
      expect(service.isSaved('Mojito Maison'), isFalse);
    });

    test('saveCocktail saves with suggested name by default', () async {
      final cocktail = Cocktail(
        id: 'chat_creation_1',
        name: 'Gin Basilic Givré',
        baseSpirit: 'gin',
        category: 'Création Chatmelier',
        glass: 'Coupe',
        method: 'Au shaker',
        garnish: 'Feuille de basilic',
        description: 'Recette rafraîchissante au basilic',
        ingredients: const [CocktailIngredient(name: 'Gin', amount: 5, unit: 'cl')],
        instructions: const ['Shaker et servir.'],
      );

      final saved = await service.saveCocktail(cocktail);
      expect(saved.length, 1);
      expect(saved.first.name, 'Gin Basilic Givré');
      expect(saved.first.isCustom, isTrue);
      expect(service.isSaved('Gin Basilic Givré'), isTrue);
      expect(service.isSaved('gin basilic givré'), isTrue);
    });

    test('saveCocktail saves with user preferred custom name', () async {
      final cocktail = Cocktail(
        id: 'chat_creation_2',
        name: 'Cocktail Méditerranéen Chatmelier',
        baseSpirit: 'vodka',
        category: 'Création Chatmelier',
        glass: 'Verre Highball',
        method: 'Direct au verre',
        garnish: 'Zeste de citron',
        description: 'Création aux agrumes',
        ingredients: const [CocktailIngredient(name: 'Vodka', amount: 4, unit: 'cl')],
        instructions: const ['Mélanger avec des glaçons.'],
      );

      final saved = await service.saveCocktail(
        cocktail,
        preferredName: 'Le Soleil de Nice',
      );

      expect(saved.length, 1);
      expect(saved.first.name, 'Le Soleil de Nice');
      expect(saved.first.isCustom, isTrue);
      expect(service.isSaved('Le Soleil de Nice'), isTrue);
      expect(service.isSaved('Cocktail Méditerranéen Chatmelier'), isFalse);
    });

    test('saveCocktail updates existing cocktail when re-saved with new preferred name', () async {
      final cocktail = Cocktail(
        id: 'custom_fixed_id',
        name: 'Mon Sour',
        baseSpirit: 'whisky',
        category: 'Création',
        glass: 'Old Fashioned',
        method: 'Au shaker',
        garnish: 'Cerise amarena',
        description: 'Sour équilibré',
        ingredients: const [CocktailIngredient(name: 'Bourbon', amount: 5, unit: 'cl')],
        instructions: const ['Shaker 15s.'],
      );

      await service.saveCocktail(cocktail);
      expect(service.getCustomCocktails().first.name, 'Mon Sour');

      // Re-save with edited preferred name
      await service.saveCocktail(cocktail, preferredName: 'Bourbon Sour Prestige');
      final list = service.getCustomCocktails();
      expect(list.length, 1);
      expect(list.first.name, 'Bourbon Sour Prestige');
    });

    test('deleteCocktail removes the custom cocktail', () async {
      final cocktail = Cocktail(
        id: 'custom_to_delete',
        name: 'Cocktail Éphémère',
        baseSpirit: 'rhum',
        category: 'Test',
        glass: 'Verre',
        method: 'Shaker',
        garnish: 'Menthe',
        description: 'Test',
        ingredients: const [],
        instructions: const [],
      );

      await service.saveCocktail(cocktail);
      expect(service.isSaved('Cocktail Éphémère'), isTrue);

      final remaining = await service.deleteCocktail('custom_to_delete');
      expect(remaining, isEmpty);
      expect(service.isSaved('Cocktail Éphémère'), isFalse);
    });
  });
}
