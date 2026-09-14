import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🍷 8-Axis Taste Radar Metrics & Calculator Tests', () {
    test('WineTasteRadarMetrics contains 8 orthogonal enological dimensions', () {
      const metrics = WineTasteRadarMetrics(
        tannin: 7.5,
        body: 8.0,
        oak: 6.0,
        ripeFruit: 7.0,
        spice: 8.5,
        freshFruit: 4.0,
        minerality: 6.5,
        acidity: 5.5,
      );

      final list = metrics.toList();
      expect(list.length, equals(8));
      expect(list[0], equals(7.5)); // tannin
      expect(list[1], equals(8.0)); // body
      expect(list[2], equals(6.0)); // oak
      expect(list[3], equals(7.0)); // ripeFruit
      expect(list[4], equals(8.5)); // spice
      expect(list[5], equals(4.0)); // freshFruit
      expect(list[6], equals(6.5)); // minerality
      expect(list[7], equals(5.5)); // acidity

      // Backwards compatibility getters
      expect(metrics.fruit, equals((7.0 + 4.0) / 2));
      expect(metrics.sweetness, equals(2.0));
    });

    test('All 13 locales provide exactly 8 localized axis labels', () {
      const locales = [
        'fr', 'en', 'es', 'ca', 'la', 'it', 'de', 'nl', 'pt', 'ja', 'ko', 'zh', 'sv'
      ];

      for (final loc in locales) {
        final labels = WineTasteRadarMetrics.localizedAxisLabels(loc);
        expect(labels.length, equals(8), reason: 'Locale $loc should have 8 labels');
        for (final label in labels) {
          expect(label.isNotEmpty, isTrue);
          expect(label.contains('\n'), isTrue, reason: 'Label "$label" in $loc should have 2 lines');
        }
      }

      // Check 8 icons
      expect(WineTasteRadarMetrics.axisIcons.length, equals(8));
    });
  });

  group('👫 Flavien vs Caro Palate Divergence Tests', () {
    test('Flavien and Caro produce distinctly non-identical radar profiles', () {
      // Flavien: Rhône/Cornas lover, loves Syrah, spicy, structured, high tannin/body
      const flavienProfile = TasteProfile(
        id: 'flavien',
        name: 'Flavien',
        favoriteTypes: ['Rouge'],
        favoriteRegions: ['Vallée du Rhône', 'Cornas'],
        favoriteGrapes: ['Syrah'],
        dislikedCharacteristics: ['Trop sucré'],
        likedTraits: {'tanin': 3, 'épicé': 4, 'puissant': 2},
        cellarGrapes: {'Syrah': 6, 'Cabernet': 3},
      );

      // Caro: Burgundy & Loire lover, loves delicate Pinot Noir & Chenin, high freshness & minerality
      const caroProfile = TasteProfile(
        id: 'caro',
        name: 'Caro',
        favoriteTypes: ['Blanc sec', 'Champagne'],
        favoriteRegions: ['Bourgogne', 'Loire', 'Chablis'],
        favoriteGrapes: ['Pinot Noir', 'Chenin', 'Chardonnay'],
        dislikedCharacteristics: ['Trop boisé', 'Trop tannique'],
        likedTraits: {'fraîcheur': 4, 'minéral': 3, 'croquant': 2},
      );

      final mFlavien = WineTasteRadarCalculator.compute(flavienProfile);
      final mCaro = WineTasteRadarCalculator.compute(caroProfile);

      // 1. Flavien has much higher tannins and spice
      expect(mFlavien.tannin, greaterThan(mCaro.tannin + 3.0),
          reason: 'Flavien tannin (${mFlavien.tannin}) vs Caro (${mCaro.tannin})');
      expect(mFlavien.spice, greaterThan(mCaro.spice + 3.0),
          reason: 'Flavien spice (${mFlavien.spice}) vs Caro (${mCaro.spice})');
      expect(mFlavien.body, greaterThan(mCaro.body + 1.5));

      // 2. Caro has much higher acidity and fresh fruit
      expect(mCaro.acidity, greaterThan(mFlavien.acidity + 2.0),
          reason: 'Caro acidity (${mCaro.acidity}) vs Flavien (${mFlavien.acidity})');
      expect(mCaro.freshFruit, greaterThan(mFlavien.freshFruit + 1.5));
      expect(mCaro.minerality, greaterThanOrEqualTo(mFlavien.minerality));

      // 3. Compare affinity: confirms distinct profiles with identified divergences
      final affinity = WineTasteRadarCalculator.compare(flavienProfile, caroProfile, 'fr');
      expect(affinity.divergencesSummary.isNotEmpty, isTrue);
      expect(affinity.affinityPercentage, lessThan(95.0));
      expect(affinity.idealWineRecommendation.isNotEmpty, isTrue);
    });
  });

  group('⚡ Fast-Tasting (3 Micro-Taps) & Implicit Auto-Enrichment Tests', () {
    late TasteProfileService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = TasteProfileService();
    });

    test('3 Micro-Taps (Texture & Fruit Profile) adjust taste preferences', () async {
      const initialProfile = TasteProfile(
        id: 'taster_1',
        name: 'Camille',
        isPrimary: true,
      );
      await service.saveProfiles([initialProfile]);

      const expressResult = TastingQuestionnaireResult(
        emojiImpression: 4, // 😍
        noteOutOf10: 9.0,
        perceivedAromas: {'agrumes', 'mineral'},
        aromaIntensity: 0.8,
        acidity: 0.85,
        body: 0.5,
        length: 0.8,
        wouldBuyAgain: 'yes',
        idealMoment: 'apero',
        whatLikedMost: {'fraicheur', 'minerale'},
        whatDislikedMost: {'rien'},
        mouthfeelTexture: 'crisp_salivating', // Micro-Tap 1
        fruitProfile: 'crunchy_tart', // Micro-Tap 2
        isExpressMode: true,
        profileId: 'taster_1',
        profileName: 'Camille',
      );

      await service.applyQuestionnaireResult(
        result: expressResult,
        wineRegion: 'Chablis',
        wineGrapes: ['Chardonnay'],
        wineType: 'white',
      );

      final updatedProfiles = await service.getProfiles();
      final updated = updatedProfiles.firstWhere((p) => p.id == 'taster_1');

      // High acidity & minerality learned from micro-taps and bottle
      expect(updated.avgAcidityPreference, isNotNull);
      expect(updated.avgAcidityPreference!, greaterThan(0.70));
      expect(updated.avgFreshFruitPreference, isNotNull);
      expect(updated.avgFreshFruitPreference!, greaterThan(0.70));
      expect(updated.avgMineralityPreference, isNotNull);
      expect(updated.avgMineralityPreference!, greaterThan(0.65));

      // Auto-enriched favorites from rated bottle (note 9.0 >= 7.5)
      expect(updated.favoriteRegions, contains('Chablis'));
      expect(updated.favoriteGrapes, contains('Chardonnay'));
    });

    test('Wishlist intent (+4.5) and Cellar stock (+5.0) are recorded and weighted', () async {
      const userProfile = TasteProfile(
        id: 'user_cellar',
        name: 'Alex',
        isPrimary: true,
      );
      await service.saveProfiles([userProfile]);

      // Wishlist addition
      await service.recordWishlistGrape('user_cellar', 'Syrah');
      await service.recordWishlistGrape('user_cellar', 'Syrah');

      // Cellar inventory sync (multi-bottle stock)
      await service.syncCellarGrapes('user_cellar', {'Syrah': 4, 'Cabernet': 2});

      final profiles = await service.getProfiles();
      final alex = profiles.firstWhere((p) => p.id == 'user_cellar');

      expect(alex.wishlistGrapes['Syrah'], equals(2));
      expect(alex.cellarGrapes['Syrah'], equals(4));
      expect(alex.cellarGrapes['Cabernet'], equals(2));

      // Computed radar incorporates cellar stock & wishlist intent into spice & tannin
      final metrics = WineTasteRadarCalculator.compute(alex);
      expect(metrics.spice, greaterThan(6.0));
      expect(metrics.tannin, greaterThan(5.5));
    });

    test('Hard negative filtering: low rating flags aversions', () async {
      const initial = TasteProfile(
        id: 'aversion_test',
        name: 'Jordan',
        isPrimary: true,
      );
      await service.saveProfiles([initial]);

      const badResult = TastingQuestionnaireResult(
        emojiImpression: 0, // 😖
        noteOutOf10: 2.5,
        perceivedAromas: {},
        aromaIntensity: 0.9,
        acidity: 0.2,
        body: 0.9,
        length: 0.2,
        wouldBuyAgain: 'no',
        idealMoment: 'repas',
        whatLikedMost: {},
        whatDislikedMost: {'trop_boise', 'trop_tannique'},
        profileId: 'aversion_test',
        profileName: 'Jordan',
      );

      await service.applyQuestionnaireResult(
        result: badResult,
        wineRegion: 'Napa Valley',
        wineGrapes: ['Cabernet Sauvignon'],
        wineType: 'red',
      );

      final profiles = await service.getProfiles();
      final jordan = profiles.firstWhere((p) => p.id == 'aversion_test');

      // Hard negative recorded: disliked characteristics registered
      expect(jordan.dislikedCharacteristics.isNotEmpty, isTrue);
      expect(jordan.dislikedTraits['trop_boise'], equals(1));
    });

    test('TextureOption & FruitProfileOption localized across 13 locales', () {
      const locales = [
        'fr', 'en', 'es', 'ca', 'la', 'it', 'de', 'nl', 'pt', 'ja', 'ko', 'zh', 'sv'
      ];

      for (final opt in TastingQuestionnaireResult.textureOptions) {
        for (final loc in locales) {
          final label = opt.localizedLabel(loc);
          expect(label.isNotEmpty, isTrue, reason: 'Texture ${opt.id} empty in $loc');
        }
      }

      for (final opt in TastingQuestionnaireResult.fruitProfileOptions) {
        for (final loc in locales) {
          final label = opt.localizedLabel(loc);
          expect(label.isNotEmpty, isTrue, reason: 'Fruit ${opt.id} empty in $loc');
        }
      }

      for (final loc in locales) {
        expect(TastingQuestionnaireResult.fastTastingTitle(loc).isNotEmpty, isTrue);
        expect(TastingQuestionnaireResult.mouthfeelTitle(loc).isNotEmpty, isTrue);
        expect(TastingQuestionnaireResult.fruitProfileTitle(loc).isNotEmpty, isTrue);
      }
    });
  });
}
