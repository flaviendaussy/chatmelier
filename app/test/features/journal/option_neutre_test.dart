import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/journal/domain/questionnaire_de_degustation.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Une réponse neutre dans la conclusion du questionnaire (V2.4 · R3, Caro, 07/10).
///
/// « Ce que vous avez aimé » n'offrait comme « rien » que « Rien / Décevant », et « Ce qui
/// vous a déplu » que « Rien, c'était parfait ! » : deux extrêmes, pas de milieu pour un vin
/// simplement correct. Et « Décevant » était compté parmi les traits aimés du profil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les deux listes proposent « Rien de particulier » avant leur extrême', () {
    expect(TastingQuestionnaireResult.likedOptions.map((o) => o.id),
        containsAllInOrder(['rien_de_particulier', 'rien_decevant']));
    expect(TastingQuestionnaireResult.dislikedOptions.map((o) => o.id),
        containsAllInOrder(['rien_de_particulier', 'rien']));
  });

  group('une réponse « rien » exclut les traits, un trait exclut les réponses « rien »', () {
    test('ce qui a plu', () {
      final r = ReponsesDuConvive();
      r.basculerAime('fraicheur', true);
      r.basculerAime('elegance', true);
      expect(r.aime, {'fraicheur', 'elegance'});
      r.basculerAime('rien_de_particulier', true);
      expect(r.aime, {'rien_de_particulier'});
      r.basculerAime('rien_decevant', true);
      expect(r.aime, {'rien_decevant'});
      r.basculerAime('fruite', true);
      expect(r.aime, {'fruite'});
      r.basculerAime('fruite', false);
      expect(r.aime, isEmpty);
    });

    test('ce qui a déplu', () {
      final r = ReponsesDuConvive();
      r.basculerAimePas('trop_acide', true);
      r.basculerAimePas('rien_de_particulier', true);
      expect(r.aimePas, {'rien_de_particulier'});
      r.basculerAimePas('rien', true);
      expect(r.aimePas, {'rien'});
      r.basculerAimePas('trop_boise', true);
      expect(r.aimePas, {'trop_boise'});
    });
  });

  test('le profil de goût ne compte ni « Rien de particulier » ni « Décevant » comme des goûts', () async {
    SharedPreferences.setMockInitialValues({});
    final service = TasteProfileService();
    final moi = (await service.getProfiles()).first;

    TastingQuestionnaireResult reponse(Set<String> aime, Set<String> aimePas) => TastingQuestionnaireResult(
          emojiImpression: 2,
          noteOutOf10: 6.5,
          perceivedAromas: const {'agrumes'},
          aromaIntensity: 0.5,
          acidity: 0.6,
          body: 0.5,
          length: 0.5,
          wouldBuyAgain: 'maybe',
          idealMoment: 'repas',
          whatLikedMost: aime,
          whatDislikedMost: aimePas,
          profileId: moi.id,
          profileName: moi.name,
        );

    await service.applyQuestionnaireResult(
      result: reponse({'rien_de_particulier'}, {'rien_de_particulier'}),
      wineType: 'white',
    );
    await service.applyQuestionnaireResult(
      result: reponse({'rien_decevant'}, {'trop_acide'}),
      wineType: 'white',
    );

    final apres = (await service.getProfiles()).firstWhere((p) => p.id == moi.id);
    expect(apres.likedTraits.keys, isNot(contains('rien_de_particulier')));
    expect(apres.likedTraits.keys, isNot(contains('rien_decevant')));
    expect(apres.dislikedTraits.keys, isNot(contains('rien_de_particulier')));
    expect(apres.dislikedTraits['trop_acide'], 1, reason: 'un vrai défaut reste compté');
    expect(apres.questionnairesCompleted, 2, reason: 'la dégustation compte, seul le trait est ignoré');
  });
}
