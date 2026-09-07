import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/cocktails/domain/cocktail.dart';
import 'package:chatmelier/features/cocktails/domain/bar_equipment.dart';
import 'package:chatmelier/features/cocktails/domain/cocktail_kitchen_converter.dart';
import 'package:chatmelier/features/cocktails/data/bar_equipment_service.dart';
import 'package:chatmelier/features/cocktails/data/bar_pantry_service.dart';
import 'package:chatmelier/features/cocktails/data/custom_cocktail_service.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';
import 'package:chatmelier/features/cocktails/presentation/cocktail_detail_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CocktailKitchenConverter - Unit Tests', () {
    test('converts liquid cl doses into friendly kitchen approximations', () {
      expect(CocktailKitchenConverter.getKitchenEquivalent(0.5, 'cl'), contains('1 c.à.café'));
      expect(CocktailKitchenConverter.getKitchenEquivalent(1.0, 'cl'), contains('2 c.à.café'));
      expect(CocktailKitchenConverter.getKitchenEquivalent(1.5, 'cl'), contains('1 c.à.soupe'));
      expect(CocktailKitchenConverter.getKitchenEquivalent(3.0, 'cl'), contains('2 c.à.soupe'));
      expect(CocktailKitchenConverter.getKitchenEquivalent(4.5, 'cl'), contains('3 c.à.soupe'));
      expect(CocktailKitchenConverter.getKitchenEquivalent(6.0, 'cl'), contains('4 c.à.soupe'));
      expect(CocktailKitchenConverter.getKitchenEquivalent(20.0, 'cl'), contains('verre d\'eau'));
    });

    test('converts ml doses into kitchen equivalents', () {
      expect(CocktailKitchenConverter.getKitchenEquivalent(15, 'ml'), contains('1 c.à.soupe'));
      expect(CocktailKitchenConverter.getKitchenEquivalent(30, 'ml'), contains('2 c.à.soupe'));
      expect(CocktailKitchenConverter.getKitchenEquivalent(60, 'ml'), contains('4 c.à.soupe'));
    });

    test('ignores non-liquid units like zeste, rondelle, feuille', () {
      expect(CocktailKitchenConverter.getKitchenEquivalent(1, 'zeste'), isEmpty);
      expect(CocktailKitchenConverter.getKitchenEquivalent(6, 'feuilles'), isEmpty);
      expect(CocktailKitchenConverter.getKitchenEquivalent(null, 'cl'), isEmpty);
    });

    test('adapts shaker steps into kitchen jar DIY steps', () {
      final proSteps = [
        'Verser le gin et le citron dans un shaker rempli de glaçons.',
        'Frapper au shaker vigoureusement pendant 12 secondes.',
        'Filtrer à travers une passoire à cocktail dans une coupette.',
      ];

      final diySteps = CocktailKitchenConverter.adaptShakerInstructionsForKitchenJar(proSteps);

      expect(diySteps[0], contains('bocal hermétique'));
      expect(diySteps[1], contains('bocal hermétique'));
      expect(diySteps[2], contains('passoire à thé'));
    });
  });

  group('BarEquipment - Domain & Persistence Tests', () {
    test('default equipment and serialization', () {
      const defaultEq = BarEquipment();
      expect(defaultEq.hasShaker, isTrue);
      expect(defaultEq.hasJigger, isFalse);

      final json = defaultEq.toJson();
      final restored = BarEquipment.fromJson(json);

      expect(restored.hasShaker, isTrue);
      expect(restored.hasJigger, isFalse);
    });

    test('BarEquipmentService loads and saves equipment preferences', () async {
      final service = BarEquipmentService();
      const customEq = BarEquipment(
        hasShaker: false,
        hasJigger: true,
        hasStrainer: true,
        hasMuddler: true,
        hasBarSpoon: false,
      );

      await service.saveEquipment(customEq);
      final loaded = await service.loadEquipment();

      expect(loaded.hasShaker, isFalse);
      expect(loaded.hasJigger, isTrue);
      expect(loaded.hasMuddler, isTrue);
    });
  });

  group('CocktailDetailSheet - Widget Tests', () {
    const shakenCocktail = Cocktail(
      id: 'daiquiri_test',
      name: 'Daiquiri Traditionnel',
      baseSpirit: 'rhum',
      category: 'Les Incontournables',
      glass: 'Coupette',
      method: 'Au shaker',
      garnish: 'Rondelle de citron vert',
      description: 'L\'équilibre parfait entre rhum, fraîcheur et acidité.',
      ingredients: [
        CocktailIngredient(name: 'Rhum blanc', amount: 5, unit: 'cl', isSpirit: true),
        CocktailIngredient(name: 'Jus de citron vert', amount: 2.5, unit: 'cl'),
        CocktailIngredient(name: 'Sirop de sucre', amount: 1.5, unit: 'cl'),
      ],
      instructions: [
        'Verser le rhum, le citron et le sucre dans un shaker.',
        'Remplir de glaçons et secouer 12 secondes.',
        'Filtrer dans une coupette rafraîchie.',
      ],
    );

    testWidgets('renders portions selector and kitchen DIY toggle', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesInstanceProvider.overrideWithValue(prefs),
            barPantryServiceProvider.overrideWithValue(BarPantryService(prefs)),
            customCocktailServiceProvider.overrideWithValue(CustomCocktailService(prefs)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => CocktailDetailSheet.show(context, shakenCocktail),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Check title and basic cocktail info
      expect(find.text('Daiquiri Traditionnel'), findsOneWidget);
      expect(find.text('Ingrédients & Dosages'), findsOneWidget);

      // Check portions selector chips
      expect(find.text('1 verre'), findsOneWidget);
      expect(find.text('2 verres'), findsOneWidget);
      expect(find.text('4 verres'), findsOneWidget);
      expect(find.text('6 (Pichet)'), findsOneWidget);

      // Switch to 2 verres
      await tester.tap(find.text('2 verres'));
      await tester.pumpAndSettle();

      // Rhum (5 cl * 2 = 10 cl)
      expect(find.text('10 cl'), findsOneWidget);

      // Switch to Moyens du bord (Bocal)
      expect(find.text('🫙 Bocal'), findsOneWidget);
      await tester.tap(find.text('🫙 Bocal'));
      await tester.pumpAndSettle();

      // Verify pedagogical advice appears
      expect(find.text('Le mot du mixologue Chatmelier :'), findsOneWidget);
      expect(find.textContaining('pot de confiture'), findsWidgets);
    });
  });
}
