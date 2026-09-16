import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';

/// Une seule correspondance note → émoji dans toute l'app.
///
/// Remonté par un utilisateur le 2026-09-08 : « on a mis la même note mais on a des
/// emoji différents ». Capture à l'appui — deux personnes à 7,0/10, l'une avec 😐,
/// l'autre avec 😊.
///
/// Il existait deux tables de correspondance qui se contredisaient : le curseur du
/// questionnaire plaçait le seuil de 😊 à 7,5, le parseur de commentaires en langage
/// naturel à 7,0. Selon qu'on bougeait le curseur ou qu'on dictait son avis, la même
/// note donnait un émoji différent.
void main() {
  group('😐 Correspondance note → émoji', () {
    test('les seuils du curseur font foi', () {
      expect(TastingQuestionnaireResult.emojiIndexForRating(9.5), equals(4)); // 😍
      expect(TastingQuestionnaireResult.emojiIndexForRating(8.0), equals(3)); // 😊
      expect(TastingQuestionnaireResult.emojiIndexForRating(6.5), equals(2)); // 😐
      expect(TastingQuestionnaireResult.emojiIndexForRating(4.5), equals(1)); // 😕
      expect(TastingQuestionnaireResult.emojiIndexForRating(2.5), equals(0)); // 😖
    });

    test('la bande de divergence signalée est refermée', () {
      // L'ancienne table du parseur IA rendait 3 (😊) sur tout cet intervalle, là où le
      // curseur rendait 2 (😐). 7,0 est exactement la note du rapport utilisateur.
      for (final note in [7.0, 7.2, 7.4]) {
        expect(TastingQuestionnaireResult.emojiIndexForRating(note), equals(2),
            reason: '$note doit donner 😐 partout, pas seulement côté curseur.');
      }
      // Seconde divergence, plus haut sur l'échelle : 😊 contre 😍.
      for (final note in [8.5, 8.7, 8.9]) {
        expect(TastingQuestionnaireResult.emojiIndexForRating(note), equals(3));
      }
    });

    test('chaque émoji reste cohérent avec la note qu\'il pose', () {
      // Choisir un émoji positionne le curseur sur cette valeur
      // (`tasting_questionnaire_sheet.dart`). L'aller-retour doit être stable, sinon
      // toucher un émoji puis relâcher en changerait l'affichage.
      const notesParDefaut = [2.5, 4.5, 6.5, 8.0, 9.5];
      for (var i = 0; i < notesParDefaut.length; i++) {
        expect(TastingQuestionnaireResult.emojiIndexForRating(notesParDefaut[i]),
            equals(i),
            reason: 'L\'émoji $i pose la note ${notesParDefaut[i]}, qui doit le redonner.');
      }
    });

    test('les bornes ne laissent aucun trou', () {
      for (var n = 0.0; n <= 10.0; n += 0.1) {
        final idx = TastingQuestionnaireResult.emojiIndexForRating(n);
        expect(idx, inInclusiveRange(0, 4), reason: 'note $n');
      }
    });
  });
}
