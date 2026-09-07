import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TastingQuestionnaireResult & Tannins Logic', () {
    test('TastingQuestionnaireResult supports null tannins for non-red wines', () {
      const whiteResult = TastingQuestionnaireResult(
        emojiImpression: 4,
        noteOutOf10: 9.0,
        perceivedAromas: {'fleurs_blanches', 'agrumes', 'mineral'},
        aromaIntensity: 0.7,
        acidity: 0.8,
        tannins: null, // White wines have no tannins
        body: 0.5,
        length: 0.7,
        wouldBuyAgain: 'yes',
        idealMoment: 'diner_romantique',
        whatLikedMost: {'fraicheur', 'mineralite'},
        whatDislikedMost: {'rien'},
        profileId: 'user_1',
        profileName: 'Flavien',
      );

      final json = whiteResult.toJson();
      expect(json['tannins'], isNull);
      expect(json['ideal_moment'], 'diner_romantique');
      expect((json['aromas'] as List).contains('agrumes'), isTrue);
    });

    test('White wine questionnaire does not affect avgTanninPreference', () async {
      SharedPreferences.setMockInitialValues({});
      final service = TasteProfileService();
      final primary = await service.getPrimaryProfile();
      final initialTanninPref = primary.avgTanninPreference;

      // Submit white wine tasting
      final whiteResult = TastingQuestionnaireResult(
        emojiImpression: 4,
        noteOutOf10: 8.5,
        perceivedAromas: const {'agrumes', 'fleurs_blanches'},
        aromaIntensity: 0.6,
        acidity: 0.7,
        tannins: null,
        body: 0.5,
        length: 0.6,
        wouldBuyAgain: 'yes',
        idealMoment: 'apero',
        whatLikedMost: const {'fraicheur'},
        whatDislikedMost: const {'rien'},
        profileId: primary.id,
        profileName: 'Flavien',
      );

      await service.applyQuestionnaireResult(
        result: whiteResult,
        wineRegion: 'Bourgogne',
        wineGrapes: ['Chardonnay'],
        wineType: 'white',
      );

      final updated = await service.getPrimaryProfile();
      // avgTanninPreference must be unchanged because white wine has no tannins
      expect(updated.avgTanninPreference, equals(initialTanninPref));
      expect(updated.favoriteRegions.contains('Bourgogne'), isTrue);
    });

    test('Red wine questionnaire updates avgTanninPreference', () async {
      SharedPreferences.setMockInitialValues({});
      final service = TasteProfileService();
      final primary = await service.getPrimaryProfile();

      final redResult = TastingQuestionnaireResult(
        emojiImpression: 4,
        noteOutOf10: 9.0,
        perceivedAromas: const {'fruits_rouges', 'epices_douces'},
        aromaIntensity: 0.8,
        acidity: 0.5,
        tannins: 0.85,
        body: 0.8,
        length: 0.7,
        wouldBuyAgain: 'yes',
        idealMoment: 'grand_diner',
        whatLikedMost: const {'structure'},
        whatDislikedMost: const {'rien'},
        profileId: primary.id,
        profileName: 'Flavien',
      );

      await service.applyQuestionnaireResult(
        result: redResult,
        wineRegion: 'Bordeaux',
        wineGrapes: ['Cabernet Sauvignon'],
        wineType: 'red',
      );

      final updated = await service.getPrimaryProfile();
      expect(updated.avgTanninPreference, isNotNull);
      expect(updated.avgTanninPreference! > 0.5, isTrue);
    });
  });

  group('TasteProfile Friend Sync & App Detection', () {
    test('TasteProfile model serialization with friendUserId', () {
      final profileWithApp = TasteProfile(
        id: 'caro_123',
        name: 'Caro',
        isPrimary: false,
        friendUserId: 'uuid-caro-456',
      );

      expect(profileWithApp.hasApp, isTrue);

      final json = profileWithApp.toJson();
      expect(json['friend_user_id'], 'uuid-caro-456');

      final deserialized = TasteProfile.fromJson(json);
      expect(deserialized.friendUserId, 'uuid-caro-456');
      expect(deserialized.hasApp, isTrue);

      final profileWithoutApp = profileWithApp.copyWith(clearFriendUserId: true);
      expect(profileWithoutApp.hasApp, isFalse);
    });
  });

  group('Primary Profile Purge & Display Name', () {
    test('getProfiles never returns a phantom primary profile', () async {
      SharedPreferences.setMockInitialValues({});
      final service = TasteProfileService();
      final profiles = await service.getProfiles();

      // No profile should have id or name == 'primary'
      expect(profiles.any((p) => p.id == 'primary'), isFalse);
      expect(profiles.any((p) => p.name.toLowerCase() == 'primary'), isFalse);
      expect(profiles.where((p) => p.isPrimary).length, 1);
    });

    test('Routing primary queries routes to actual primary profile', () async {
      SharedPreferences.setMockInitialValues({});
      final service = TasteProfileService();
      final primaryBefore = await service.getPrimaryProfile();

      // Calling recordTastingExperience with 'primary' should update primary profile and not create a dummy
      await service.recordTastingExperience(
        nameOrId: 'primary',
        wine: Wine.fromJson({
          'id': 'w_1',
          'name': 'Chablis',
          'type': 'white',
          'region': 'Bourgogne',
          'appellation': 'Chablis',
        }),
        rating: 9.0,
      );

      final profiles = await service.getProfiles();
      expect(profiles.any((p) => p.id == 'primary'), isFalse);
      expect(profiles.any((p) => p.name == 'primary'), isFalse);

      final primaryAfter = await service.getPrimaryProfile();
      expect(primaryAfter.id, equals(primaryBefore.id));
      expect(primaryAfter.favoriteRegions.contains('Bourgogne'), isTrue);
    });

    test('Sommelier profile prompt never hallucinates preferences for single-tasting companions', () async {
      SharedPreferences.setMockInitialValues({});
      final service = TasteProfileService();
      await service.addOrGetProfileByName('Caro');
      final profiles = await service.getProfiles();
      final caro = profiles.firstWhere((p) => p.name == 'Caro');

      // Caro has no registered tastings yet, so she should have no favorite regions or reds
      expect(caro.favoriteRegions, isEmpty);
      expect(caro.favoriteTypes, isEmpty);

      final sommelierPrompt = service.formatProfilesForSommelier(profiles);
      // Prompt must include strict anti-hallucination instruction for Caro
      expect(sommelierPrompt.contains('INTERDICTION FORMELLE'), isTrue);
    });
  });
}
