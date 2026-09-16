import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/domain/taste_profile_history.dart';

/// Instantanés mensuels — la condition pour parler de dérive.
///
/// La moyenne exponentielle suit un palais qui change, mais ne garde aucune mémoire de
/// ce qui précède : elle montre où vous en êtes, jamais d'où vous venez. « Votre goût
/// s'est déplacé vers la tension cette année » ne se dit qu'avec un historique.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  TasteProfile profil({double? acidite, int degustations = 4, int obs = 8}) =>
      TasteProfile(
        id: 'p',
        name: 'Moi',
        avgAcidityPreference: acidite,
        questionnairesCompleted: degustations,
        axisObservations: {'acidity': obs},
      );

  group('📅 Un instantané par mois', () {
    test('rappeler la capture dans le même mois remplace, n\'empile pas', () async {
      final h = await TasteProfileHistory.ouvrir();
      final quand = DateTime(2026, 9, 3);

      await h.capturer(profil(acidite: 0.50), maintenant: quand);
      await h.capturer(profil(acidite: 0.62), maintenant: DateTime(2026, 9, 28));

      expect(h.lire(), hasLength(1),
          reason: 'La capture se déclenche à chaque ouverture de l\'écran de profil.');
      expect(h.lire().single.axes['acidity'], closeTo(0.62, 1e-9),
          reason: 'Ce qui intéresse, c\'est où en était le palais à la fin du mois.');
    });

    test('les mois distincts s\'accumulent, du plus ancien au plus récent', () async {
      final h = await TasteProfileHistory.ouvrir();
      await h.capturer(profil(acidite: 0.40), maintenant: DateTime(2026, 7, 5));
      await h.capturer(profil(acidite: 0.55), maintenant: DateTime(2026, 8, 5));
      await h.capturer(profil(acidite: 0.80), maintenant: DateTime(2026, 9, 5));

      final snaps = h.lire();
      expect(snaps.map((s) => s.mois), equals(['2026-07', '2026-08', '2026-09']));
    });

    test('un profil encore vide n\'est pas figé', () async {
      final h = await TasteProfileHistory.ouvrir();
      await h.capturer(const TasteProfile(id: 'p', name: 'Moi'),
          maintenant: DateTime(2026, 9, 5));
      expect(h.lire(), isEmpty,
          reason: 'On ne veut pas d\'une année de zéros devant la première vraie mesure.');
    });

    test('la mémoire est bornée à trois ans', () async {
      final h = await TasteProfileHistory.ouvrir();
      for (var i = 0; i < TasteProfileHistory.moisConserves + 6; i++) {
        await h.capturer(profil(acidite: 0.5),
            maintenant: DateTime(2020 + i ~/ 12, (i % 12) + 1, 5));
      }
      expect(h.lire(), hasLength(TasteProfileHistory.moisConserves));
    });
  });

  group('📈 La dérive', () {
    test('elle n\'existe pas sur un seul point', () async {
      final h = await TasteProfileHistory.ouvrir();
      await h.capturer(profil(acidite: 0.80), maintenant: DateTime(2026, 9, 5));
      expect(h.derive('acidity'), isNull,
          reason: 'Une dérive suppose deux mesures.');
    });

    test('elle se mesure du premier au dernier instantané', () async {
      final h = await TasteProfileHistory.ouvrir();
      await h.capturer(profil(acidite: 0.40), maintenant: DateTime(2026, 3, 5));
      await h.capturer(profil(acidite: 0.60), maintenant: DateTime(2026, 6, 5));
      await h.capturer(profil(acidite: 0.82), maintenant: DateTime(2026, 9, 5));

      expect(h.derive('acidity'), closeTo(0.42, 1e-9),
          reason: 'Le palais s\'est déplacé vers la tension : +0,42 sur six mois.');
      expect(h.derive('tannin'), isNull, reason: 'Axe jamais renseigné.');
    });

    test('un historique corrompu ne fait pas tomber l\'app', () async {
      SharedPreferences.setMockInitialValues(
          {'chatmelier_taste_history_v1': '{pas une liste}'});
      final h = await TasteProfileHistory.ouvrir();
      expect(h.lire(), isEmpty);
      expect(h.derive('acidity'), isNull);
    });
  });

  test('l\'accesseur d\'axe couvre les huit clés', () {
    const p = TasteProfile(
      id: 'p',
      name: 'T',
      avgAcidityPreference: 0.1,
      avgBodyPreference: 0.2,
      avgTanninPreference: 0.3,
      avgOakPreference: 0.4,
      avgRipeFruitPreference: 0.5,
      avgSpicePreference: 0.6,
      avgFreshFruitPreference: 0.7,
      avgMineralityPreference: 0.8,
    );
    for (final k in TasteProfile.axisKeys) {
      expect(p.valeurAxe(k), isNotNull, reason: 'axe $k non couvert');
    }
    expect(p.valeurAxe('inconnu'), isNull);
  });
}
