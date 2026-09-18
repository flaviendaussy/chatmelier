import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/admin/domain/admin_metrics.dart';

/// Ce que la console lit, et ce qu'elle refuse de lire.
void main() {
  Map<String, dynamic> jourBrut({
    String jour = '2026-09-18',
    int actifs = 0,
    int nouveaux = 0,
    int degustations = 0,
    int bouteilles = 0,
    int messages = 0,
    int vins = 0,
  }) =>
      {
        'jour': jour,
        'actifs': actifs,
        'nouveaux': nouveaux,
        'degustations': degustations,
        'bouteilles': bouteilles,
        'messages': messages,
        'vins_decouverts': vins,
      };

  group('📈 Les chiffres arrivent entiers', () {
    test('un jour se relit champ par champ', () {
      final j = JourDUsage.fromJson(jourBrut(
          actifs: 12, nouveaux: 3, degustations: 7, bouteilles: 5, messages: 9, vins: 4));
      expect(j.actifs, equals(12));
      expect(j.jour, equals(DateTime(2026, 9, 18)));
      expect(j.gestes, equals(25), reason: '7 + 5 + 9 + 4');
    });

    test('un champ absent vaut zéro, pas une exception', () {
      // Les fonctions SQL peuvent gagner des colonnes ; une console qui plante à la
      // première divergence de schéma ne sert à rien.
      final j = JourDUsage.fromJson({'jour': '2026-09-18'});
      expect(j.actifs, equals(0));
      expect(j.gestes, equals(0));
    });

    test('la part d\'anonymes se calcule sans diviser par zéro', () {
      expect(ResumeDUsage.vide.partAnonymes, equals(0));
      final r = ResumeDUsage.fromJson(
          {'utilisateurs_total': 40, 'anonymes': 10});
      expect(r.partAnonymes, closeTo(0.25, 0.001));
    });
  });

  group('🥧 Les répartitions', () {
    final t = TableauDeBord(
      resume: ResumeDUsage.vide,
      jours: [JourDUsage.fromJson(jourBrut())],
      parts: [
        const Part(famille: 'geste', libelle: 'Dégustations', valeur: 12),
        const Part(famille: 'geste', libelle: 'Messages', valeur: 30),
        const Part(famille: 'geste', libelle: 'Vide', valeur: 0),
        const Part(famille: 'plateforme', libelle: 'android', valeur: 8),
      ],
    );

    test('chaque famille ne rend que la sienne', () {
      expect(t.famille('plateforme').map((p) => p.libelle), equals(['android']));
    });

    test('les parts nulles ne sont pas dessinées', () {
      // Une tranche à zéro dans un camembert est un trait invisible avec une légende.
      expect(t.famille('geste').map((p) => p.libelle), isNot(contains('Vide')));
    });

    test('les parts sont triées par taille', () {
      expect(t.famille('geste').first.libelle, equals('Messages'));
    });
  });

  group('🫥 Une période sans rien ne se dessine pas', () {
    test('aucun geste, aucun actif : la console le dit', () {
      final t = TableauDeBord(
        resume: ResumeDUsage.vide,
        jours: [jourBrut(), jourBrut()].map(JourDUsage.fromJson).toList(),
        parts: const [],
      );
      expect(t.estVide, isTrue,
          reason: 'des courbes plates valent moins qu\'une phrase');
    });

    test('un seul actif suffit à dessiner', () {
      final t = TableauDeBord(
        resume: ResumeDUsage.vide,
        jours: [jourBrut(), jourBrut(actifs: 1)].map(JourDUsage.fromJson).toList(),
        parts: const [],
      );
      expect(t.estVide, isFalse);
    });
  });
}
