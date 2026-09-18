import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';

/// « La note inscrite est 9 alors que j'ai mis 7,5. »
///
/// Goûté à trois, noté 7,5, et le journal affichait le 9 d'un convive. Le questionnaire
/// guidé se remplit à plusieurs, mais une seule ligne part au journal — celle du maître
/// de cave, puisque c'est son journal. Le code prenait « le premier qui a répondu ».
void main() {
  TastingQuestionnaireResult note(double n) => TastingQuestionnaireResult(
        emojiImpression: TastingQuestionnaireResult.emojiIndexForRating(n),
        noteOutOf10: n,
        perceivedAromas: const {},
        aromaIntensity: 0.5,
        length: 0.5,
        wouldBuyAgain: 'yes',
        idealMoment: 'repas',
        whatLikedMost: const {},
        whatDislikedMost: const {},
        profileId: 'x',
        profileName: 'x',
      );

  group('📓 À qui appartient la ligne de journal', () {
    test('le maître de cave, même s\'il a répondu en dernier', () {
      final reponses = {
        'paul': note(9.0),
        'aude': note(8.0),
        'moi': note(7.5),
      };
      final r = resultatDuMaitreDeCave(reponses, (id) => id == 'moi');
      expect(r!.noteOutOf10, equals(7.5),
          reason: 'c\'est son journal, pas celui du plus rapide');
    });

    test('le maître de cave, quand il a répondu en premier', () {
      final reponses = {'moi': note(7.5), 'paul': note(9.0)};
      expect(resultatDuMaitreDeCave(reponses, (id) => id == 'moi')!.noteOutOf10,
          equals(7.5));
    });

    test('sans profil principal, la première réponse fait la ligne', () {
      // Une dégustation lancée sans « moi » identifié vaut mieux avec une note qu'avec
      // aucune ligne du tout.
      final reponses = {'invite': note(6.0), 'autre': note(9.0)};
      expect(resultatDuMaitreDeCave(reponses, (_) => false)!.noteOutOf10,
          equals(6.0));
    });

    test('aucune réponse, aucune ligne', () {
      expect(resultatDuMaitreDeCave({}, (_) => true), isNull);
    });

    test('seul, la note reste la sienne', () {
      final reponses = {'moi': note(7.5)};
      expect(resultatDuMaitreDeCave(reponses, (id) => id == 'moi')!.noteOutOf10,
          equals(7.5));
    });
  });
}
