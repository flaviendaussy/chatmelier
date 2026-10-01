import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/friends/domain/friend.dart';
import 'package:chatmelier/features/journal/domain/questionnaire_de_degustation.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// La logique du questionnaire de dégustation, sortie de l'écran (V2.3 · I4).
void main() {
  setUp(() => Langue.code = 'fr');

  group('ce qu\'on demande selon la couleur', () {
    test('la couleur se lit en français comme en anglais', () {
      expect(couleurDuQuestionnaire('Rouge'), 'red');
      expect(couleurDuQuestionnaire('white'), 'white');
      expect(couleurDuQuestionnaire('Blanc de blancs'), 'white', reason: 'un blanc avant d\'être une bulle');
      expect(couleurDuQuestionnaire('Crémant rosé'), 'rose');
      expect(couleurDuQuestionnaire('Champagne'), 'sparkling');
      expect(couleurDuQuestionnaire('Moelleux'), 'dessert');
      expect(couleurDuQuestionnaire(null), '');
    });

    test('tanins aux rouges, minéralité aux blancs et rosés, bulles aux effervescents', () {
      final rouge = QuestionnaireDuVin('red');
      final blanc = QuestionnaireDuVin('white');
      final rose = QuestionnaireDuVin('rose');
      final bulles = QuestionnaireDuVin('sparkling');
      expect([rouge, blanc, rose, bulles].map((v) => v.demandeLesTanins), [true, false, false, false]);
      expect([rouge, blanc, rose, bulles].map((v) => v.demandeLaMineralite), [false, true, true, false]);
      expect([rouge, blanc, rose, bulles].map((v) => v.demandeLEffervescence), [false, false, false, true]);
    });
  });

  group('les réponses d\'un convive', () {
    test('un visage donne sa note, une note emmène son visage', () {
      final r = ReponsesDuConvive();
      for (var i = 0; i < 5; i++) {
        r.choisirLeVisage(i);
        expect(r.note, TastingQuestionnaireResult.notesDesVisages[i]);
        expect(TastingQuestionnaireResult.emojiIndexForRating(r.note), i, reason: 'la note retombe sur son visage');
      }
      r.reglerLaNote(3.0);
      expect(r.visage, 0);
      r.reglerLaNote(9.2);
      expect(r.visage, 4);
    });

    test('le toucher soyeux suppose des tanins fondus ; le retoucher retire le choix', () {
      final r = ReponsesDuConvive()..basculerLaTexture('silky_lacy');
      expect((r.texture, r.tanins, r.acidite), ('silky_lacy', 0.40, 0.55));
      r.basculerLaTexture('silky_lacy');
      expect(r.texture, isNull);
      expect(r.tanins, 0.40, reason: 'retirer le choix ne défait pas les curseurs');
      r.basculerLaTexture('crisp_salivating');
      expect((r.acidite, r.mineralite), (0.80, 0.75));
    });

    test('l\'éclat du fruit ajoute l\'arôme qu\'il nomme', () {
      final r = ReponsesDuConvive()..basculerLeFruit('deep_ripe');
      expect(r.aromes, {'fruits_noirs'});
      expect(r.corps, 0.70);
      r.basculerLeFruit('spicy_herbal');
      expect(r.fruit, 'spicy_herbal');
      expect(r.aromes, {'fruits_noirs', 'epices_vives'});
    });

    test('une dictée ne donne ni tanins à un blanc ni minéralité à un rouge', () {
      void dicter(ReponsesDuConvive r, String type) => r.appliquerLaDictee(
            vin: QuestionnaireDuVin(type),
            note: 8.5,
            visage: 3,
            aromes: {'agrumes'},
            acidite: 0.8,
            tanins: 0.9,
            mineralite: 0.9,
            corps: 0.4,
            longueur: 0.7,
          );
      final blanc = ReponsesDuConvive();
      dicter(blanc, 'white');
      expect((blanc.tanins, blanc.mineralite, blanc.note), (0.5, 0.9, 8.5));
      final rouge = ReponsesDuConvive();
      dicter(rouge, 'red');
      expect((rouge.tanins, rouge.mineralite), (0.9, 0.5));
    });

    test('le résultat : rien que ce qui a été demandé', () {
      final r = ReponsesDuConvive()
        ..choisirLeVisage(3)
        ..aromes = {'agrumes'}
        ..accordAvecLePlat = 'sublime'
        ..tanins = 0.9
        ..effervescence = 0.8;

      final blanc = r.resultat(
          profileId: 'moi', profileName: 'Moi', vin: QuestionnaireDuVin('white'), express: false, avecUnPlat: false);
      expect(blanc.tannins, isNull);
      expect(blanc.effervescence, isNull);
      expect(blanc.foodPairingSynergy, isNull, reason: 'pas d\'accord sans plat');
      expect(blanc.platAccorde, isNull);

      final avecPlat = r.resultat(
          profileId: 'moi',
          profileName: 'Moi',
          vin: QuestionnaireDuVin('Champagne'),
          express: true,
          avecUnPlat: true,
          plat: '  huîtres  ');
      expect(avecPlat.effervescence, 0.8);
      expect(avecPlat.foodPairingSynergy, 'sublime');
      expect(avecPlat.platAccorde, 'huîtres');
      expect(avecPlat.isExpressMode, isTrue);

      // Le résultat ne bouge plus quand le formulaire continue de changer.
      r.aromes.add('floral');
      expect(blanc.perceivedAromas, {'agrumes'});
    });
  });

  group('qui peut répondre', () {
    Friend ami(String id, String nom) => Friend(
          id: 'amitie-$id',
          friendUserId: id,
          displayName: nom,
          username: nom.toLowerCase(),
          tasteProfile: TasteProfile(id: id, name: nom),
          status: 'accepted',
          isOutgoing: false,
          cellarAccessRole: 'none',
        );

    test('un ami et un profil du même nom ne font qu\'un ; un ami sans profil en reçoit un', () {
      final tous = ConvivesDuQuestionnaire.rassembler(
        const [TasteProfile(id: 'moi', name: 'Moi', isPrimary: true), TasteProfile(id: 'p-caro', name: 'Caro')],
        [ami('u-caro', 'caro'), ami('u-paul', 'Paul')],
      );
      expect(tous.map((p) => (p.id, p.friendUserId)), [('moi', null), ('p-caro', 'u-caro'), ('u-paul', 'u-paul')]);
    });

    test('le maître de cave, plus les convives annoncés par leur nom', () {
      const tous = [
        TasteProfile(id: 'p-caro', name: 'Caro'),
        TasteProfile(id: 'moi', name: 'Moi', isPrimary: true),
        TasteProfile(id: 'p-paul', name: 'Paul'),
      ];
      expect(ConvivesDuQuestionnaire.selectionInitiale(tous, ['PAUL', 'Inconnu']), {'moi', 'p-paul'});
      expect(ConvivesDuQuestionnaire.selectionInitiale(const [], ['Paul']), isEmpty);
    });
  });

  group('ce qui part au journal', () {
    const idDegustation = '2b6b1f8e-6f53-4c55-9d1e-3c1c2f3a4b5c';
    const idVin = '9f1d2c3b-4a5e-4f60-8a7b-1c2d3e4f5a6b';
    const idBouteille = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d';
    final quand = DateTime.utc(2026, 10, 2, 20);

    TastingQuestionnaireResult resultat({double note = 7.5, String? plat}) => TastingQuestionnaireResult(
          emojiImpression: TastingQuestionnaireResult.emojiIndexForRating(note),
          noteOutOf10: note,
          perceivedAromas: const {'agrumes'},
          aromaIntensity: 0.5,
          length: 0.5,
          wouldBuyAgain: 'yes',
          idealMoment: 'repas',
          whatLikedMost: const {},
          whatDislikedMost: const {},
          platAccorde: plat,
          profileId: 'moi',
          profileName: 'Moi',
        );

    test('la ligne entière : le maître de cave n\'est pas son propre convive', () {
      final ligne = LigneDuQuestionnaire(
        id: idDegustation,
        wineId: idVin,
        userId: 'u1',
        bottleId: idBouteille,
        cellarId: 'cave-locale', // pas un identifiant de la base : il ne part pas
        resultat: resultat(plat: 'Sole meunière'),
        convives: const [TasteProfile(id: 'moi', name: 'Moi', isPrimary: true), TasteProfile(id: 'c', name: 'Caro')],
        defaut: 'cork',
        quand: quand,
      );
      final c = ligne.complete();
      expect(c['rating'], 7.5);
      expect(c['rating_scale'], 10);
      expect(c['co_tasters'], ['Caro']);
      expect(c['bottle_id'], idBouteille);
      expect(c.containsKey('cellar_id'), isFalse);
      expect(c['fault'], 'cork');
      expect(c['food_paired'], 'Sole meunière');
      expect(c['occasion'], 'repas');
      expect(c['tasting_notes'], 'Dégustation guidée. Arômes : 🍋 Agrumes',
          reason: 'des arômes lisibles, pas leurs identifiants');
      expect(c['consumed_at'], '2026-10-02T20:00:00.000Z');
    });

    test('les replis : le noyau sans colonnes récentes, puis l\'ancienne échelle sur 5', () {
      final ligne = LigneDuQuestionnaire(id: idDegustation, wineId: idVin, userId: 'u1', resultat: resultat(note: 9), quand: quand);
      final noyau = ligne.essentielle();
      for (final cle in ['co_tasters', 'is_external', 'rating_scale', 'is_blind', 'fault', 'food_paired']) {
        expect(noyau.containsKey(cle), isFalse, reason: cle);
      }
      expect(ligne.ancienneEchelle()['rating'], 4.5);
      expect(ligne.ancienneEchelle().containsKey('rating_scale'), isFalse);
    });

    test('sans réponse, pas de note inventée', () {
      final ligne = LigneDuQuestionnaire(id: idDegustation, wineId: idVin, userId: 'u1', resultat: null, quand: quand);
      expect(ligne.complete()['rating'], isNull);
      expect(ligne.ancienneEchelle()['rating'], isNull);
      expect(ligne.complete()['tasting_notes'], 'Dégustation guidée.');
    });

    test('la dégustation envoyée à un ami porte ses réponses', () {
      final p = degustationPartagee(
        wineId: idVin,
        amiId: 'u-caro',
        resultat: resultat(),
        convives: const ['Moi', 'Caro'],
        bottleId: 'locale',
      );
      expect(p['p_rating'], 7.5);
      expect(p.containsKey('p_bottle_id'), isFalse);
      expect(p['p_notes'], 'Dégustation partagée. Arômes : 🍋 Agrumes');
      expect((p['p_questionnaire_data'] as Map)['profile_id'] ?? (p['p_questionnaire_data'] as Map)['profileId'], 'moi');
    });
  });

  test('la bouteille : la quantité baisse, ou elle sort de la cave avec la dernière', () {
    final quand = DateTime.utc(2026, 10, 2);
    expect(bouteilleApresDegustation(quantite: 3, bues: 1, quand: quand), {'quantity': 2});
    expect(bouteilleApresDegustation(quantite: 1, bues: 1, quand: quand),
        {'quantity': 0, 'status': 'consumed', 'consumed_at': '2026-10-02T00:00:00.000Z'});
    expect(bouteilleApresDegustation(quantite: 1, bues: 2, quand: quand)['status'], 'consumed');
  });

  test('un identifiant local ne part pas en base', () {
    expect(estUnUuid('0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d'), isTrue);
    expect(estUnUuid('TABLE-12'), isFalse);
    expect(estUnUuid(''), isFalse);
    expect(estUnUuid(null), isFalse);
  });
}
