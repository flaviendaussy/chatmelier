import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/question_pour_vous.dart';
import 'package:chatmelier/features/journal/domain/questionnaire_de_degustation.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/menu_scan/domain/palais_saisi.dart';
import 'package:chatmelier/features/sommelier/domain/profil_du_vin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Demander moins, mais mieux (V2.6 · P6) : une question « pour vous », sur l'axe qui
/// apprendrait le plus ; une description qu'on n'a pas donnée ne part pas.
void main() {
  final le = DateTime(2026, 10, 19);
  ProfilDuVin vin(String nom, String type, {String? appellation, int? millesime, List<String> cepages = const []}) =>
      ProfilDuVin.deLaCave(
        Wine(
          id: nom,
          name: nom,
          type: type,
          country: 'France',
          region: '',
          appellation: appellation,
          vintage: millesime,
          grapes: [for (final c in cepages) Grape(name: c)],
        ),
        le: le,
      );

  const neuf = TasteProfile(id: 'p', name: 'P', isPrimary: true);

  group('la question à poser', () {
    test('un palais neuf : là où le vin tranche le plus', () {
      expect(QuestionPourVous.aDemander(neuf, 'blanc', vin('Sauternes', 'dessert', appellation: 'Sauternes')), 'sweetness');
      expect(QuestionPourVous.aDemander(neuf, 'rouge', vin('Madiran', 'red', appellation: 'Madiran', cepages: ['Tannat'])),
          'tannin');
    });

    test('un axe déjà bien connu ne se redemande pas', () {
      const tanninsConnus = TasteProfile(
        id: 'p',
        name: 'P',
        palais: {'rouge': {'tannin': 0.8}},
        observationsPalais: {'rouge': {'tannin': 20}},
      );
      final madiran = vin('Madiran', 'red', appellation: 'Madiran', cepages: ['Tannat']);
      expect(QuestionPourVous.aDemander(tanninsConnus, 'rouge', madiran), isNot('tannin'));
    });

    test('ni la douceur d\'un rouge, ni l\'âge : celui-là se lit sur le millésime', () {
      expect(QuestionPourVous.axes('rouge'), isNot(contains('sweetness')));
      expect(QuestionPourVous.axes('rouge'), isNot(contains('evolution')));
      expect(QuestionPourVous.axes('blanc'), isNot(contains('tannin')));
      expect(QuestionPourVous.autres('blanc', 'oak'), ['sweetness', 'acidity', 'body']);
    });
  });

  group('trois questions, et pas de bois sur un rosé (22/10)', () {
    test('trois d\'emblée, les plus utiles d\'abord ; la quatrième sous « Aller plus loin »', () {
      final madiran = vin('Madiran', 'red', appellation: 'Madiran', cepages: ['Tannat']);
      final ordre = QuestionPourVous.ordre(neuf, 'rouge', madiran);
      expect(QuestionPourVous.dEmblee, 3);
      expect(ordre, hasLength(4));
      expect(ordre.first, 'tannin', reason: 'un Madiran tranche par ses tanins');
      expect(ordre.toSet(), {'tannin', 'body', 'acidity', 'oak'});
    });

    test('un rosé ou une bulle : jamais le boisé (« pas très applicable ici », Douro rosé)', () {
      expect(QuestionPourVous.sansBoisPour('rose'), isTrue);
      expect(QuestionPourVous.sansBoisPour('sparkling'), isTrue);
      expect(QuestionPourVous.sansBoisPour('white'), isFalse);
      final douro = vin('Douro Rosé', 'rose');
      final ordre = QuestionPourVous.ordre(neuf, 'blanc', douro, sansBois: true);
      expect(ordre, isNot(contains('oak')));
      expect(ordre, hasLength(3), reason: 'trois questions, sans « Aller plus loin »');
    });
  });

  group('les réponses', () {
    final rouge = QuestionnaireDuVin('red');
    TastingQuestionnaireResult resultat(ReponsesDuConvive r, {bool express = true}) =>
        r.resultat(profileId: 'p', profileName: 'P', vin: rouge, express: express);

    test('un curseur qu\'on n\'a pas touché ne dit rien ; le moment ne se suppose pas', () {
      final r = ReponsesDuConvive();
      final res = resultat(r);
      expect(res.acidity, isNull);
      expect(res.body, isNull);
      expect(res.tannins, isNull);
      expect(res.idealMoment, '', reason: '« repas » partait sans qu\'on l\'ait demandé');
    });

    test('ce qu\'on a décrit part, et le « pour vous » aussi', () {
      final r = ReponsesDuConvive()
        ..decrire('tannin', 0.8)
        ..juger('tannin', 'trop')
        ..juger('body', 'juste');
      final res = resultat(r);
      expect(res.tannins, 0.8);
      expect(res.acidity, isNull);
      expect(res.jugements, {'tannin': 'trop', 'body': 'juste'});
    });

    test('le même choix une seconde fois le retire', () {
      final r = ReponsesDuConvive()
        ..juger('oak', 'trop')
        ..juger('oak', 'trop');
      expect(r.jugements, isEmpty);
    });
  });

  group('les cinq curseurs de l\'accueil et de la table', () {
    test('seuls les curseurs touchés sont déclarés', () {
      final p = const PalaisSaisi().avec('sweetness', 6).avec('body', 3);
      expect(p.dits.keys, unorderedEquals(['sweetness', 'body']));
      final blancs = p.palaisParFamille['blanc']!;
      expect(blancs.connait('sweetness'), isTrue);
      expect(blancs.confianceDe('sweetness'), 1.0, reason: 'une déclaration compte pleinement à table');
      expect(blancs.connait('acidity'), isFalse);
      expect(p.palaisParFamille['rouge']!.connait('tannin'), isFalse);
    });

    test('un invité qui n\'a rien dit n\'envoie pas de palais', () {
      final g = const PalaisSaisi().versConvive(id: 'g', nom: 'Caro', fr: true);
      expect(g.palaisDistants, isNull);
      final dit = const PalaisSaisi().avec('tannin', 2).versConvive(id: 'g', nom: 'Caro', fr: true);
      expect(dit.palaisDistants!['rouge']!.valeur('tannin'), 2);
      expect(dit.toJson()['palais'], isNotNull, reason: 'il voyage avec le convive');
    });

    test('les points de départ ont la douceur, et plus de minéralité', () {
      expect(PalaisSaisi.prereglages['tendre']!.dits['sweetness'], greaterThanOrEqualTo(5));
      for (final p in PalaisSaisi.prereglages.values) {
        expect(p.dits.keys, isNot(contains('minerality')));
      }
    });
  });
}
