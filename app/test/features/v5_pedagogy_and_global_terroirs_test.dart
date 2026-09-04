import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_pedagogy_engine.dart';
import 'package:chatmelier/features/scratchcard/domain/terroir_node.dart';
import 'package:chatmelier/features/scratchcard/domain/terroir_catalog.dart';

void main() {
  group('V5 Tasting Pedagogy & Global Terroirs Tests', () {
    const sampleBandol = Wine(
      id: 'wine-bandol-rouge',
      name: 'Bandol Rouge Cuvée Spéciale',
      producer: 'Domaine de Terrebrune',
      vintage: 2018,
      type: 'red',
      country: 'France',
      region: 'Provence',
      appellation: 'Bandol AOC',
      grapes: [
        Grape(name: 'Mourvèdre', pct: 85),
        Grape(name: 'Grenache', pct: 10),
        Grape(name: 'Cinsault', pct: 5),
      ],
      tastingNotes: 'Robe grenat profond, fruits noirs mûrs, garrigue, épices et cuir noble.',
      drinkStart: 2023,
      drinkEnd: 2038,
      peakStart: 2026,
      peakEnd: 2033,
    );

    const sampleChablis = Wine(
      id: 'wine-chablis-grand-cru',
      name: 'Chablis Grand Cru Les Clos',
      producer: 'Domaine Laroche',
      vintage: 2021,
      type: 'white',
      country: 'France',
      region: 'Bourgogne',
      appellation: 'Chablis Grand Cru AOC',
      grapes: [Grape(name: 'Chardonnay', pct: 100)],
      drinkStart: 2024,
      drinkEnd: 2036,
    );

    const sampleChampagne = Wine(
      id: 'wine-champagne-prestige',
      name: 'Cuvée Sir Winston Churchill',
      producer: 'Pol Roger',
      vintage: 2012,
      type: 'sparkling',
      country: 'France',
      region: 'Champagne',
      appellation: 'Champagne AOC',
      grapes: [
        Grape(name: 'Pinot Noir', pct: 60),
        Grape(name: 'Chardonnay', pct: 40),
      ],
      drinkStart: 2020,
      drinkEnd: 2035,
    );

    test('TastingPedagogyEngine accurately analyzes Red Tannic Wine (Bandol)', () {
      final report = TastingPedagogyEngine.analyze(
        wine: sampleBandol,
        userAppearance: 'Pourpre intense',
        userAromas: ['🫐 Fruits noirs', '🌶️ Poivre / Épices', '🪵 Boisé / Chêne'],
        userStructure: 'Tanins fermes et structurés',
        userCaudalies: 8,
        userRating: 9.0,
        userComment: 'Superbe puissance et épices.',
      );

      expect(report.acuityScore, greaterThanOrEqualTo(80));
      expect(report.sommelierPraise, isNotEmpty);
      expect(report.archetypeAromas, contains('🫐 Fruits noirs'));
      expect(report.archetypeAromas, contains('🌶️ Poivre / Épices'));

      // Check scientific pillars
      expect(report.scientificPillars, isNotEmpty);
      expect(report.scientificPillars.any((p) => p.chemicalKey.contains('Rotundone')), isTrue);
      expect(report.scientificPillars.any((p) => p.title.contains('Extraction') || p.title.contains('Fût')), isTrue);

      // Check hidden nuances
      expect(report.hiddenNuancesToDiscover, isNotEmpty);
    });

    test('TastingPedagogyEngine accurately analyzes White Mineral Wine (Chablis)', () {
      final report = TastingPedagogyEngine.analyze(
        wine: sampleChablis,
        userAppearance: 'Or pâle',
        userAromas: ['🍋 Agrumes / Zeste', '🪨 Minéral / Craie'],
        userStructure: 'Vivacité et fraîcheur saline',
        userCaudalies: 7,
        userRating: 8.5,
      );

      expect(report.acuityScore, greaterThanOrEqualTo(80));
      expect(report.scientificPillars.any((p) => p.chemicalKey.contains('Thiols') || p.chemicalKey.contains('Tartrique')), isTrue);
      expect(report.hiddenNuancesToDiscover.any((n) => n.name.contains('Pierre à fusil') || n.name.contains('Coquille')), isTrue);
    });

    test('TastingPedagogyEngine accurately analyzes Champagne with Autolysis', () {
      final report = TastingPedagogyEngine.analyze(
        wine: sampleChampagne,
        userAppearance: 'Doré éclatant',
        userAromas: ['🧈 Beurre / Brioche', '🍯 Miel / Cire'],
        userStructure: 'Équilibre parfait',
        userCaudalies: 9,
        userRating: 9.5,
      );

      expect(report.acuityScore, greaterThanOrEqualTo(85));
      expect(report.scientificPillars.any((p) => p.chemicalKey.contains('Diacétyle') || p.title.contains('Autolyse')), isTrue);
    });

    test('Terroir Catalog includes complete worldwide wine regions and appellations', () {
      final regions = TerroirCatalog.defaultNodes.where((n) => n.level == TerroirLevel.region).map((n) => n.name).toList();
      final apps = TerroirCatalog.defaultNodes.where((n) => n.level == TerroirLevel.appellation).map((n) => n.name).toList();

      expect(regions, contains('Vallée du Douro'));
      expect(regions, contains('Vinho Verde'));
      expect(regions, contains('Mosel (Moselle)'));
      expect(regions, contains('Wachau'));
      expect(regions, contains('Sonoma County'));
      expect(regions, contains('Willamette Valley'));
      expect(regions, contains('Valle de Uco'));
      expect(regions, contains('Valle del Maipo'));
      expect(regions, contains('Barossa Valley'));
      expect(regions, contains('Marlborough'));
      expect(regions, contains('Stellenbosch'));

      expect(apps, contains('Porto Vintage'));
      expect(apps, contains('Mosel Kabinett'));
      expect(apps, contains('Oakville AVA'));
      expect(apps, contains('Barolo DOCG'));
    });
  });
}
