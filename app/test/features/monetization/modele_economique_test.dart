import 'package:chatmelier/features/monetization/domain/credits_ia.dart';
import 'package:chatmelier/features/monetization/domain/reglages_de_la_pub.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le modèle économique (étude du 21/10, version 87) : « la pub paie l'IA ; tout le reste
/// est gratuit et sans pub ». Quelques gestes offerts par jour, puis une vidéo choisie.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('les réglages de la console', () {
    test('sans réglage : les valeurs de l\'étude', () {
      final r = ReglagesDeLaPub.depuis(null);
      expect(r.videos, isTrue);
      expect(r.chatOfferts, 5);
      expect(r.chatParVideo, 8);
      expect(r.questionsCarteOffertes, 3);
      expect(r.soireeHeures, 4);
      expect(r.coteOffertes, 3);
      expect(r.annonceTousLes, 12);
      expect(r.uniteNativeAndroid, isNull, reason: 'pas de carte « Annonce » sans bloc AdMob');
    });

    test('une valeur illisible garde sa valeur par défaut, une unité fausse est écartée', () {
      final r = ReglagesDeLaPub.depuis({
        'videos': 'oui',
        'chat_offerts': -2,
        'chat_par_video': 0,
        'soiree_heures': 72,
        'cote_offertes': 1,
        'unite_native_android': 'ca-app-pub-6095914862192850/1234567890',
        'unite_native_ios': 'n\'importe quoi',
      });
      expect(r.videos, isTrue);
      expect(r.chatOfferts, 5);
      expect(r.chatParVideo, 1, reason: 'une vidéo ouvre au moins une question');
      expect(r.soireeHeures, 24, reason: 'une soirée dure au plus un jour');
      expect(r.coteOffertes, 1);
      expect(r.uniteNativeAndroid, 'ca-app-pub-6095914862192850/1234567890');
      expect(r.uniteNativeIos, isNull);
    });
  });

  group('ce qui est offert chaque jour', () {
    const r = ReglagesDeLaPub();
    final midi = DateTime(2026, 10, 21, 12);

    test('le sommelier : cinq questions, puis huit par vidéo', () {
      final c = CreditsIa(jour: CreditsIa.jourDe(midi));
      for (var i = 0; i < 5; i++) {
        expect(c.autorise(GesteIa.chat, r, midi), isTrue, reason: 'question ${i + 1} offerte');
        c.compter(GesteIa.chat, midi);
      }
      expect(c.autorise(GesteIa.chat, r, midi), isFalse, reason: 'la sixième demande une vidéo');
      c.crediter(GesteIa.chat, r, midi);
      for (var i = 0; i < 8; i++) {
        expect(c.autorise(GesteIa.chat, r, midi), isTrue);
        c.compter(GesteIa.chat, midi);
      }
      expect(c.autorise(GesteIa.chat, r, midi), isFalse);
    });

    test('la carte : trois questions, puis une soirée de quatre heures, qui passe minuit', () {
      final c = CreditsIa(jour: CreditsIa.jourDe(midi));
      for (var i = 0; i < 3; i++) {
        c.compter(GesteIa.questionCarte, midi);
      }
      expect(c.autorise(GesteIa.questionCarte, r, midi), isFalse);
      final soir = DateTime(2026, 10, 21, 22, 30);
      c.crediter(GesteIa.questionCarte, r, soir);
      expect(c.autorise(GesteIa.questionCarte, r, soir.add(const Duration(minutes: 50))), isTrue);
      // Le lendemain, 1 h 30 : la soirée court encore ; 3 h : elle est finie.
      final lendemain = CreditsIa.depuis(c.toJson(), DateTime(2026, 10, 22, 1, 30));
      expect(lendemain.soireeOuverte(DateTime(2026, 10, 22, 1, 30)), isTrue);
      expect(lendemain.soireeOuverte(DateTime(2026, 10, 22, 3)), isFalse);
      // Pendant une soirée, les questions ne comptent pas.
      final pendant = CreditsIa(jour: CreditsIa.jourDe(midi), soireeJusquA: midi.add(const Duration(hours: 1)));
      pendant.compter(GesteIa.questionCarte, midi);
      expect(pendant.questions, 0);
    });

    test('la cote : trois recherches, puis une par vidéo', () {
      final c = CreditsIa(jour: CreditsIa.jourDe(midi), cote: 3);
      expect(c.autorise(GesteIa.cote, r, midi), isFalse);
      c.crediter(GesteIa.cote, r, midi);
      expect(c.autorise(GesteIa.cote, r, midi), isTrue);
      c.compter(GesteIa.cote, midi);
      expect(c.autorise(GesteIa.cote, r, midi), isFalse);
    });

    test('un nouveau jour remet les compteurs à zéro', () {
      final hier = CreditsIa(jour: '2026-10-20', chat: 9, chatBonus: 8, questions: 3, cote: 3, coteBonus: 1);
      final aujourdhui = CreditsIa.depuis(hier.toJson(), midi);
      expect(aujourdhui.jour, '2026-10-21');
      expect([aujourdhui.chat, aujourdhui.chatBonus, aujourdhui.questions, aujourdhui.cote, aujourdhui.coteBonus],
          [0, 0, 0, 0, 0]);
    });

    test('rangés par compte, sur le téléphone', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await CreditsIa.lire('compte-a', maintenant: midi);
      c.compter(GesteIa.chat, midi);
      await c.ecrire('compte-a');
      expect((await CreditsIa.lire('compte-a', maintenant: midi)).chat, 1);
      expect((await CreditsIa.lire('compte-b', maintenant: midi)).chat, 0, reason: 'un autre compte a ses propres questions');
    });
  });
}
