import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_evidence.dart';
import 'package:chatmelier/features/auth/domain/taste_undo.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/data/tasting_deletion_service.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';

/// Supprimer doit vouloir dire quelque chose de vrai.
///
/// « Tout doit être supprimable » ne se satisfait pas d'effacer une ligne : la dégustation
/// a nourri un profil de goût, et laisser cette influence derrière serait une suppression
/// de façade. Mais la moyenne exponentielle est irréversible — d'où une règle qui vaut pour
/// tout ce fichier : **exact là où l'exactitude est possible, explicite là où elle ne l'est
/// pas.**
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Wine vin(String region, String cepage) => Wine(
        id: 'w_${region}_$cepage',
        name: 'Cuvée $region',
        type: 'Rouge',
        country: 'France',
        region: region,
        grapes: [Grape(name: cepage)],
      );

  TastingQuestionnaireResult reponse({
    required String profileId,
    required double note,
    double? acidite,
  }) =>
      TastingQuestionnaireResult(
        emojiImpression: TastingQuestionnaireResult.emojiIndexForRating(note),
        noteOutOf10: note,
        perceivedAromas: const {},
        aromaIntensity: 0.5,
        acidity: acidite,
        body: null,
        length: 0.5,
        wouldBuyAgain: 'yes',
        idealMoment: 'repas',
        whatLikedMost: const {},
        whatDislikedMost: const {},
        profileId: profileId,
        profileName: 'Moi',
      );

  group('🗑️ Ce qu\'une suppression doit défaire', () {
    test('une dégustation porte désormais son identité jusqu\'au registre', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.recordTastingExperience(
        nameOrId: p.id,
        wine: vin('Madiran', 'Tannat'),
        rating: 9.0,
        tastingId: 'deg-1',
      );

      final traces = (await TasteEvidenceLedger.ouvrir()).pourDegustation('deg-1');
      expect(traces, isNotEmpty,
          reason: 'sans identité commune, la suppression ne saurait pas quoi défaire');
      expect(traces.map((e) => e.cible), contains('region:Madiran'));
      expect(traces.map((e) => e.cible), contains('cepage:Tannat'));
    });

    test('annuler retire exactement la région et le cépage ajoutés', () async {
      final service = TasteProfileService();
      var p = await service.getPrimaryProfile();

      await service.recordTastingExperience(
        nameOrId: p.id,
        wine: vin('Madiran', 'Tannat'),
        rating: 9.0,
        tastingId: 'deg-1',
      );
      p = await service.getPrimaryProfile();
      expect(p.favoriteRegions, contains('Madiran'));

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(
        profil: p,
        contributions: registre.pourDegustation('deg-1'),
        registre: registre,
      );

      expect(r.profil.favoriteRegions, isNot(contains('Madiran')));
      expect(r.profil.favoriteGrapes, isNot(contains('Tannat')));
      expect(r.complete, isTrue, reason: 'un ensemble s\'annule exactement');
    });

    test('un axe revient à sa valeur d\'avant quand rien ne l\'a bougé depuis', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.applyQuestionnaireResult(
        result: reponse(profileId: p.id, note: 8.0, acidite: 0.9),
        tastingId: 'deg-a',
      );
      final avant = (await service.getPrimaryProfile()).avgAcidityPreference;

      await service.applyQuestionnaireResult(
        result: reponse(profileId: p.id, note: 8.0, acidite: 0.2),
        tastingId: 'deg-b',
      );
      final apres = await service.getPrimaryProfile();
      expect(apres.avgAcidityPreference, isNot(equals(avant)));

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(
        profil: apres,
        contributions: registre.pourDegustation('deg-b'),
        registre: registre,
      );

      expect(r.profil.avgAcidityPreference, closeTo(avant!, 0.0001),
          reason: 'l\'avant a été noté au moment du changement, donc il se retrouve');
      expect(r.complete, isTrue);
    });

    test('un axe modifié depuis n\'est PAS écrasé, et la limite est dite', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.applyQuestionnaireResult(
        result: reponse(profileId: p.id, note: 8.0, acidite: 0.9),
        tastingId: 'deg-a',
      );
      // La dégustation qu'on supprimera.
      await service.applyQuestionnaireResult(
        result: reponse(profileId: p.id, note: 8.0, acidite: 0.2),
        tastingId: 'deg-b',
      );
      // Puis une autre, plus récente, sur le même axe.
      await service.applyQuestionnaireResult(
        result: reponse(profileId: p.id, note: 8.0, acidite: 0.7),
        tastingId: 'deg-c',
      );
      final courant = await service.getPrimaryProfile();

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(
        profil: courant,
        contributions: registre.pourDegustation('deg-b'),
        registre: registre,
      );

      expect(r.profil.avgAcidityPreference, equals(courant.avgAcidityPreference),
          reason: 'restaurer une valeur périmée écraserait une observation plus récente');
      expect(r.nonDefaites, contains('axe:acidity'));
      expect(r.complete, isFalse);
      expect(TastingDeletionService.phraseDesRestes(r.nonDefaites), contains('acidité'),
          reason: 'la limite doit être dite en français, pas en clés techniques');
    });

    test('annuler décompte l\'observation, donc la confiance affichée', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.applyQuestionnaireResult(
        result: reponse(profileId: p.id, note: 8.0, acidite: 0.9),
        tastingId: 'deg-a',
      );
      final courant = await service.getPrimaryProfile();
      expect(courant.axisObservations['acidity'], equals(1));

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(
        profil: courant,
        contributions: registre.pourDegustation('deg-a'),
        registre: registre,
      );

      expect(r.profil.axisObservations.containsKey('acidity'), isFalse,
          reason: 'la confiance doit refléter ce qui reste, pas ce qui a été');
    });

    test('le registre oublie la dégustation supprimée', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();
      await service.recordTastingExperience(
        nameOrId: p.id,
        wine: vin('Madiran', 'Tannat'),
        rating: 9.0,
        tastingId: 'deg-1',
      );
      await service.recordTastingExperience(
        nameOrId: p.id,
        wine: vin('Jura', 'Savagnin'),
        rating: 9.0,
        tastingId: 'deg-2',
      );

      final registre = await TasteEvidenceLedger.ouvrir();
      await registre.retirer('deg-1');

      expect(registre.pourDegustation('deg-1'), isEmpty);
      expect(registre.pourDegustation('deg-2'), isNotEmpty,
          reason: 'supprimer une dégustation n\'en efface pas une autre');
    });

    test('le compteur d\'expérience recule, sans passer sous zéro', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();
      await service.recordTastingExperience(
        nameOrId: p.id,
        wine: vin('Madiran', 'Tannat'),
        rating: 9.0,
        tastingId: 'deg-1',
      );
      final courant = await service.getPrimaryProfile();
      final n = courant.questionnairesCompleted;

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(
        profil: courant,
        contributions: registre.pourDegustation('deg-1'),
        registre: registre,
      );
      expect(r.profil.questionnairesCompleted, equals(n - 1));

      // Deuxième annulation sur un profil déjà à zéro : pas de compteur négatif.
      final vide = TasteUndo.annuler(
        profil: r.profil.copyWith(questionnairesCompleted: 0),
        contributions: registre.pourDegustation('deg-1'),
        registre: registre,
      );
      expect(vide.profil.questionnairesCompleted, equals(0));
    });
  });
}
