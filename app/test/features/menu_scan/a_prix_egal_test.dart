import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/menu_scan/domain/a_prix_egal.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/enriched_menu_screen.dart';

MenuWine vin(String nom,
        {double? prix, double? accord, String type = 'Rouge', List<MenuWineGlassPrice> verres = const []}) =>
    MenuWine(
      id: nom,
      name: nom,
      producer: '',
      wineType: type,
      bottlePrice: prix,
      userMatchScore: accord,
      glassPrices: verres,
    );

void main() {
  test('à prix égal, le vin qui va nettement mieux au palais est désigné', () {
    final choix = APrixEgal.choisir([
      vin('Morgon', prix: 42, accord: 71),
      vin('Chablis', prix: 42, accord: 92),
      vin('Fleurie', prix: 42, accord: 80),
      vin('Cornas', prix: 60, accord: 95),
    ]);
    expect(choix.keys, ['Chablis']);
    expect(choix['Chablis']!.autres.map((w) => w.name), ['Fleurie', 'Morgon']);
    expect(choix['Chablis']!.ecart, 12);
    expect(choix['Chablis']!.prix, 42);
  });

  test('à trois points près, les vins se valent : rien n\'est désigné', () {
    expect(APrixEgal.choisir([vin('A', prix: 30, accord: 80), vin('B', prix: 30, accord: 78)]), isEmpty);
    expect(APrixEgal.choisir([vin('A', prix: 30, accord: 81), vin('B', prix: 30, accord: 78)]).keys, ['A']);
  });

  test('sans palais connu, sans prix ou seul à son prix : rien', () {
    expect(APrixEgal.choisir([vin('A', prix: 30), vin('B', prix: 30)]), isEmpty);
    expect(APrixEgal.choisir([vin('A', accord: 90), vin('B', accord: 60)]), isEmpty);
    expect(APrixEgal.choisir([vin('A', prix: 30, accord: 90), vin('B', prix: 31, accord: 60)]), isEmpty);
  });

  test('on ne compare que des vins de même couleur', () {
    final choix = APrixEgal.choisir([
      vin('Morgon', prix: 42, accord: 90),
      vin('Chablis', prix: 42, accord: 60, type: 'Blanc'),
      vin('Crémant', prix: 42, accord: 50, type: 'Crémant de Loire brut'),
      vin('Saint-Joseph', prix: 42, accord: 80),
    ]);
    expect(choix.keys, ['Morgon']);
    expect(choix['Morgon']!.autres.map((w) => w.name), ['Saint-Joseph']);
    expect(choix['Morgon']!.couleur, 'rouge');
  });

  test('sur une ardoise, on compare le prix du verre, à format égal', () {
    const verre12 = [MenuWineGlassPrice(format: '12cl', price: 8)];
    const verre15 = [MenuWineGlassPrice(format: '15cl', price: 8)];
    final choix = APrixEgal.choisir([
      vin('A', prix: 40, accord: 90, verres: verre12),
      vin('B', prix: 48, accord: 70, verres: verre12),
      vin('C', prix: 40, accord: 60, verres: verre15),
    ], ardoise: true);
    expect(choix.keys, ['A']);
    expect(choix['A']!.auVerre, isTrue);
    expect(choix['A']!.autres.map((w) => w.name), ['B']);
    // Hors ardoise, A et C sont au même prix à la bouteille.
    expect(APrixEgal.choisir([vin('A', prix: 40, accord: 90), vin('C', prix: 40, accord: 60)]).keys, ['A']);
  });

  group('sur la carte', () {
    final carte = ScannedMenu(
      id: 'carte_robin',
      restaurantName: 'Chez Robin',
      scannedAt: DateTime(2026, 10, 8),
      pagePhotoPaths: const [],
      currency: 'EUR',
      wines: [
        vin('Morgon Côte du Py 2021', prix: 42, accord: 71),
        vin('Saint-Joseph 2020', prix: 42, accord: 92),
        vin('Chablis 2022', prix: 42, accord: 60, type: 'Blanc'),
      ],
    );

    Future<void> ouvrir(WidgetTester tester, List<TasteProfile> palais) async {
      SharedPreferences.setMockInitialValues({});
      // Assez haut pour que la suggestion « pour mieux vous connaître » laisse voir les vins.
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [tasteProfilesListProvider.overrideWith((ref) async => palais)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('fr'), Locale('en')],
          home: EnrichedMenuScreen(menu: carte),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('le sommelier désigne le vin, et dit pourquoi', (tester) async {
      final connu = TasteProfile(
        id: 'p',
        name: 'Moi',
        isPrimary: true,
        axisObservations: {for (final k in TasteProfile.axisKeys) k: 12},
      );
      await ouvrir(tester, [connu]);
      expect(find.textContaining('À prix égal, je prendrais celui-ci'), findsOneWidget);
      expect(find.textContaining('plus proche de vos goûts que Morgon Côte du Py 2021 (71 %), au même prix'),
          findsOneWidget);
      expect(find.text('92 % pour vous'), findsOneWidget);
      expect(find.textContaining('% Match'), findsNothing);
    });

    testWidgets('un palais encore deviné : « sans doute » et ≈', (tester) async {
      await ouvrir(tester, [const TasteProfile(id: 'p', name: 'Moi', isPrimary: true)]);
      // La suggestion « pour mieux vous connaître » le dit aussi.
      expect(find.textContaining('chances de vous plaire (≈71 %)'), findsOneWidget);
      expect(find.textContaining('À prix égal, je prendrais sans doute celui-ci'), findsOneWidget);
      expect(find.text('≈92 % pour vous'), findsOneWidget);
    });
  });
}
