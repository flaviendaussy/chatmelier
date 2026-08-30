import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/shared/services/nearby_places_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tasting Questionnaire Domain & Static Options', () {
    test('Questionnaire result model serializes and matches fields', () {
      const result = TastingQuestionnaireResult(
        emojiImpression: 4,
        noteOutOf10: 9.0,
        perceivedAromas: {'fruits_rouges', 'mineral', 'epices_vives'},
        aromaIntensity: 0.8,
        acidity: 0.7,
        tannins: 0.6,
        body: 0.75,
        length: 0.85,
        effervescence: null,
        wouldBuyAgain: 'yes',
        idealMoment: 'grand_diner',
        whatLikedMost: {'complexite', 'elegance', 'longueur'},
        whatDislikedMost: {'rien'},
        profileId: 'flavien_main',
        profileName: 'Flavien (Moi)',
      );

      final json = result.toJson();
      expect(json['note'], 9.0);
      expect(json['emoji_impression'], 4);
      expect(json['would_buy_again'], 'yes');
      expect((json['aromas'] as List).contains('mineral'), isTrue);
      expect((json['liked_most'] as List).contains('elegance'), isTrue);
    });

    test('Static options contain emojis and proper IDs', () {
      expect(TastingQuestionnaireResult.emojiLabels.length, 5);
      expect(TastingQuestionnaireResult.aromaOptions.any((a) => a.id == 'fruits_rouges'), isTrue);
      expect(TastingQuestionnaireResult.aromaOptions.any((a) => a.id == 'mineral' && a.emoji == '⛰️'), isTrue);
      expect(TastingQuestionnaireResult.dislikedOptions.any((d) => d.id == 'rien'), isTrue);
    });
  });

  group('Taste Profile Incremental Learning Algorithm', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('High rating with wouldBuyAgain auto-adds favorite region and grapes', () async {
      final service = TasteProfileService();
      final profiles = await service.getProfiles();
      expect(profiles.isNotEmpty, isTrue);

      final initialUser = profiles.first;
      expect(initialUser.favoriteRegions.contains('Jura'), isFalse);

      // Submit questionnaire with high score (9.0) on a Jura Poulsard
      final result = TastingQuestionnaireResult(
        emojiImpression: 4,
        noteOutOf10: 9.0,
        perceivedAromas: const {'fruits_rouges', 'epices_douces'},
        aromaIntensity: 0.8,
        acidity: 0.6,
        tannins: 0.4,
        body: 0.5,
        length: 0.8,
        wouldBuyAgain: 'yes',
        idealMoment: 'repas',
        whatLikedMost: const {'fraicheur', 'elegance'},
        whatDislikedMost: const {'rien'},
        profileId: initialUser.id,
        profileName: initialUser.name,
      );

      await service.applyQuestionnaireResult(
        result: result,
        wineRegion: 'Jura',
        wineGrapes: ['Poulsard'],
        wineType: 'red',
      );

      final updatedProfiles = await service.getProfiles();
      final updatedUser = updatedProfiles.firstWhere((p) => p.id == initialUser.id);

      expect(updatedUser.favoriteRegions.contains('Jura'), isTrue);
      expect(updatedUser.favoriteGrapes.contains('Poulsard'), isTrue);
      expect(updatedUser.questionnairesCompleted, 1);
      expect(updatedUser.aromaPreferences['fruits_rouges'], 1);
      expect(updatedUser.likedTraits['elegance'], 1);
    });

    test('Disliked traits require at least 3 occurrences before becoming a known aversion', () async {
      final service = TasteProfileService();
      final profiles = await service.getProfiles();
      final targetUser = profiles.first;

      // Submit 2 questionnaires with 'trop_boise'
      for (int i = 0; i < 2; i++) {
        await service.applyQuestionnaireResult(
          result: TastingQuestionnaireResult(
            emojiImpression: 1,
            noteOutOf10: 4.0,
            perceivedAromas: const {'boise'},
            aromaIntensity: 0.9,
            acidity: 0.4,
            tannins: 0.7,
            body: 0.8,
            length: 0.5,
            wouldBuyAgain: 'no',
            idealMoment: 'repas',
            whatLikedMost: const {},
            whatDislikedMost: const {'trop_boise'},
            profileId: targetUser.id,
            profileName: targetUser.name,
          ),
        );
      }

      var currentProfiles = await service.getProfiles();
      var userCheck = currentProfiles.firstWhere((p) => p.id == targetUser.id);
      expect(userCheck.dislikedTraits['trop_boise'], 2);

      // 3rd time
      await service.applyQuestionnaireResult(
        result: TastingQuestionnaireResult(
          emojiImpression: 0,
          noteOutOf10: 3.0,
          perceivedAromas: const {'boise'},
          aromaIntensity: 0.9,
          acidity: 0.3,
          tannins: 0.8,
          body: 0.9,
          length: 0.4,
          wouldBuyAgain: 'no',
          idealMoment: 'repas',
          whatLikedMost: const {},
          whatDislikedMost: const {'trop_boise'},
          profileId: targetUser.id,
          profileName: targetUser.name,
        ),
      );

      currentProfiles = await service.getProfiles();
      userCheck = currentProfiles.firstWhere((p) => p.id == targetUser.id);
      expect(userCheck.dislikedTraits['trop_boise'], 3);
      expect(
        userCheck.dislikedCharacteristics.any((d) => d.toLowerCase().contains('boisé')),
        isTrue,
      );
    });

    test('Multi-profile formatting generates clear sommelier prompt', () async {
      final service = TasteProfileService();
      await service.addProfile(
        name: 'Caro',
        favoriteTypes: ['Blanc sec', 'Champagne'],
        favoriteRegions: ['Bourgogne', 'Chablis'],
      );
      final profiles = await service.getProfiles();
      final prompt = service.formatProfilesForSommelier(profiles);

      expect(prompt.contains('Caro'), isTrue);
      expect(prompt.contains('Couleurs/Types préférés'), isTrue);
    });
  });

  group('Nearby Places & Custom Locations Service (Chez Dimitri, etc.)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Custom place is memorized and matched by coordinates', () async {
      final service = NearbyPlacesService();

      // Memorize "Chez Dimitri" at Paris 11ème coordinates (48.8566, 2.3522)
      final dimitriPlace = await service.rememberPlace(
        name: 'Chez Dimitri',
        latitude: 48.8566,
        longitude: 2.3522,
      );

      expect(dimitriPlace.name, 'Chez Dimitri');
      expect(dimitriPlace.visitCount, 1);

      // Query nearby places from 50m away (48.8568, 2.3524)
      final nearby = await service.getNearbyPlaces(
        latitude: 48.8568,
        longitude: 2.3524,
      );

      expect(nearby.isNotEmpty, isTrue);
      expect(nearby.first.name, 'Chez Dimitri');
      expect(nearby.first.isCustom, isTrue);
      expect(nearby.first.iconEmoji, '⭐');
      expect(nearby.first.displayLabel.contains('Chez Dimitri'), isTrue);
    });

    test('Custom place visit count increments upon repeated visits', () async {
      final service = NearbyPlacesService();

      await service.rememberPlace(
        name: 'Chez Dimitri',
        latitude: 48.8566,
        longitude: 2.3522,
      );

      final secondVisit = await service.rememberPlace(
        name: 'Chez Dimitri',
        latitude: 48.8567,
        longitude: 2.3523,
      );

      expect(secondVisit.visitCount, 2);

      final allPlaces = await service.getCustomPlaces();
      expect(allPlaces.length, 1);
      expect(allPlaces.first.visitCount, 2);
    });
  });
}
