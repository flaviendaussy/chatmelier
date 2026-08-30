import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/cellar_filter_state.dart';
import 'package:chatmelier/shared/widgets/grape_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Cellar Filters & Blend Resolution Tests', () {
    test('CellarFilterState accurately tracks active filters and vintage', () {
      const emptyFilter = CellarFilterState();
      expect(emptyFilter.isActive, isFalse);
      expect(emptyFilter.activeFilterCount, 0);

      final filterWithVintageAndGrape = emptyFilter.copyWith(
        grape: () => 'Mourvèdre',
        vintage: () => 2019,
      );

      expect(filterWithVintageAndGrape.isActive, isTrue);
      expect(filterWithVintageAndGrape.activeFilterCount, 2);
      expect(filterWithVintageAndGrape.grape, 'Mourvèdre');
      expect(filterWithVintageAndGrape.vintage, 2019);

      final cleared = filterWithVintageAndGrape.clear();
      expect(cleared.isActive, isFalse);
    });

    test('Dynamic grape extraction gathers all grapes including blend expansions', () {
      final bottles = [
        Bottle(
          id: 'b1',
          cellarId: 'c1',
          wineId: 'w1',
          ownerId: 'user1',
          addedBy: 'user1',
          createdAt: DateTime(2023, 1, 1),
          wine: const Wine(
            id: 'w1',
            name: 'Domaine de Terrebrune Rouge 2019',
            producer: 'Domaine de Terrebrune',
            appellation: 'Bandol',
            region: 'Provence',
            country: 'France',
            vintage: 2019,
            type: 'red',
            grapes: [], // empty, relies on blend resolver
          ),
          quantity: 3,
        ),
        Bottle(
          id: 'b2',
          cellarId: 'c1',
          wineId: 'w2',
          ownerId: 'user1',
          addedBy: 'user1',
          createdAt: DateTime(2023, 1, 1),
          wine: const Wine(
            id: 'w2',
            name: 'Laroche Chablis Premier Cru',
            producer: 'Domaine Laroche',
            appellation: 'Chablis Premier Cru',
            region: 'Bourgogne',
            country: 'France',
            vintage: 2021,
            type: 'white',
            grapes: [Grape(name: 'Chardonnay', pct: 100)],
          ),
          quantity: 2,
        ),
        Bottle(
          id: 'b3',
          cellarId: 'c1',
          wineId: 'w3',
          ownerId: 'user1',
          addedBy: 'user1',
          createdAt: DateTime(2023, 1, 1),
          wine: const Wine(
            id: 'w3',
            name: 'El Nido Clio',
            producer: 'Bodegas El Nido',
            appellation: 'Jumilla',
            region: 'Murcia',
            country: 'Espagne',
            vintage: 2020,
            type: 'red',
            grapes: [Grape(name: 'Monastrell', pct: 70), Grape(name: 'Cabernet Sauvignon', pct: 30)],
          ),
          quantity: 1,
        ),
      ];

      // Verify grape extraction logic
      final Set<String> extractedGrapes = {};
      final Set<String> extractedAppellations = {};
      final Set<String> extractedCountries = {};
      final Set<int> extractedVintages = {};

      for (final b in bottles) {
        final wine = b.wine!;
        final resolved = GrapeBlendResolver.resolveGrapes(
          existingGrapes: wine.grapes,
          wineType: wine.type,
          appellation: wine.appellation,
          region: wine.region,
          wineName: wine.name,
          producer: wine.producer,
          cuveeParcel: wine.cuveeParcel,
        );

        for (final g in resolved) {
          extractedGrapes.add(g.name.trim());
        }
        for (final g in wine.grapes) {
          extractedGrapes.add(g.name.trim());
        }
        if (wine.appellation != null) extractedAppellations.add(wine.appellation!);
        extractedAppellations.add(wine.region);
        extractedCountries.add(wine.country);
        if (wine.vintage != null) extractedVintages.add(wine.vintage!);
      }

      // Bandol resolution must have extracted Mourvèdre, Grenache, Cinsault
      expect(extractedGrapes.any((g) => g.contains('Mourvèdre')), isTrue);
      expect(extractedGrapes.any((g) => g.contains('Grenache')), isTrue);
      expect(extractedGrapes.any((g) => g.contains('Cinsault')), isTrue);
      // Chablis has Chardonnay
      expect(extractedGrapes.contains('Chardonnay'), isTrue);
      // Clio has Monastrell & Cabernet Sauvignon
      expect(extractedGrapes.contains('Monastrell'), isTrue);
      expect(extractedGrapes.contains('Cabernet Sauvignon'), isTrue);

      // Appellations and regions
      expect(extractedAppellations.contains('Bandol'), isTrue);
      expect(extractedAppellations.contains('Chablis Premier Cru'), isTrue);
      expect(extractedAppellations.contains('Jumilla'), isTrue);
      expect(extractedAppellations.contains('Bourgogne'), isTrue);
      expect(extractedAppellations.contains('Provence'), isTrue);

      // Countries
      expect(extractedCountries.contains('France'), isTrue);
      expect(extractedCountries.contains('Espagne'), isTrue);

      // Vintages
      expect(extractedVintages.contains(2019), isTrue);
      expect(extractedVintages.contains(2021), isTrue);
      expect(extractedVintages.contains(2020), isTrue);
    });
  });

  group('Taste Profile Clean State & Full Customization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial profile has NO pre-attributed hardcoded mock tastes for Flavien & Caro', () async {
      final service = TasteProfileService();
      final profiles = await service.getProfiles();

      expect(profiles.length, equals(1));
      final primary = profiles.first;
      expect(primary.isPrimary, isTrue);
      // Must start clean without pre-seeded preferences
      expect(primary.favoriteTypes, isEmpty);
      expect(primary.favoriteRegions, isEmpty);
      expect(primary.favoriteGrapes, isEmpty);
      expect(primary.dislikedCharacteristics, isEmpty);
    });

    test('User can fully update all preference fields, sliders and reset anytime', () async {
      final service = TasteProfileService();
      final profiles = await service.getProfiles();
      final primary = profiles.first;

      final customized = primary.copyWith(
        favoriteTypes: ['Rouge puissant & structuré', 'Champagne & Effervescents'],
        favoriteRegions: ['Bandol & Provence', 'Vallée du Rhône'],
        favoriteGrapes: ['Mourvèdre', 'Syrah'],
        dislikedCharacteristics: ['Tanins trop astringents / râpeux'],
        avgTanninPreference: 0.85,
        avgAcidityPreference: 0.50,
        avgBodyPreference: 0.90,
        notes: 'Amateur de grands rouges sudistes.',
      );

      await service.updateProfile(customized);

      final updatedList = await service.getProfiles();
      final loaded = updatedList.firstWhere((p) => p.id == primary.id);

      expect(loaded.favoriteTypes.length, 2);
      expect(loaded.favoriteRegions.contains('Bandol & Provence'), isTrue);
      expect(loaded.favoriteGrapes.contains('Mourvèdre'), isTrue);
      expect(loaded.dislikedCharacteristics.contains('Tanins trop astringents / râpeux'), isTrue);
      expect(loaded.avgTanninPreference, 0.85);
      expect(loaded.notes, 'Amateur de grands rouges sudistes.');

      // Reset profile
      await service.resetProfile(primary.id);
      final resetList = await service.getProfiles();
      final resetPrimary = resetList.firstWhere((p) => p.id == primary.id);

      expect(resetPrimary.favoriteTypes, isEmpty);
      expect(resetPrimary.favoriteRegions, isEmpty);
      expect(resetPrimary.favoriteGrapes, isEmpty);
      expect(resetPrimary.dislikedCharacteristics, isEmpty);
      expect(resetPrimary.avgTanninPreference, isNull);
    });
  });
}
