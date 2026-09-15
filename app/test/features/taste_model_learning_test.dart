import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';

/// Verrouille les trois corrections du modèle de goût (S2).
///
/// Chacune portait sur un défaut silencieux : l'app compilait, les tests passaient, et le
/// profil apprenait simplement n'importe quoi. D'où ces tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Wine wineFrom({
    required String region,
    required String grape,
    String type = 'Rouge',
  }) =>
      Wine(
        id: 'w_$region$grape',
        name: 'Cuvée de test',
        type: type,
        country: 'France',
        region: region,
        grapes: [Grape(name: grape)],
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('⚖️ Apprentissage symétrique', () {
    test('une note basse retire ce qu\'une note haute avait ajouté', () async {
      final service = TasteProfileService();
      final profile = await service.getPrimaryProfile();

      await service.recordTastingExperience(
        nameOrId: profile.id,
        wine: wineFrom(region: 'Madiran', grape: 'Tannat'),
        rating: 9.0,
      );
      var updated = await service.getPrimaryProfile();
      expect(updated.favoriteRegions, contains('Madiran'),
          reason: 'Une note de 9/10 doit enrichir les régions favorites.');
      expect(updated.favoriteGrapes, contains('Tannat'));

      await service.recordTastingExperience(
        nameOrId: profile.id,
        wine: wineFrom(region: 'Madiran', grape: 'Tannat'),
        rating: 2.0,
      );
      updated = await service.getPrimaryProfile();
      expect(updated.favoriteRegions, isNot(contains('Madiran')),
          reason: 'Une note de 2/10 doit retirer la région. Avant, tout le corps de la '
              'méthode était dans un if (rating >= 7.5) : la déception ne faisait RIEN.');
      expect(updated.favoriteGrapes, isNot(contains('Tannat')));
    });

    test('le compteur d\'expérience avance même sur une déception', () async {
      final service = TasteProfileService();
      final before = (await service.getPrimaryProfile()).questionnairesCompleted;

      await service.recordTastingExperience(
        nameOrId: 'primary',
        wine: wineFrom(region: 'Beaujolais', grape: 'Gamay'),
        rating: 3.0,
      );

      final after = (await service.getPrimaryProfile()).questionnairesCompleted;
      expect(after, greaterThan(before),
          reason: 'Le compteur mesure l\'expérience accumulée, pas les bons souvenirs.');
    });

    test('une note intermédiaire ne tranche ni dans un sens ni dans l\'autre', () async {
      final service = TasteProfileService();
      await service.recordTastingExperience(
        nameOrId: 'primary',
        wine: wineFrom(region: 'Chablis', grape: 'Chardonnay', type: 'Blanc'),
        rating: 6.0,
      );
      final updated = await service.getPrimaryProfile();
      expect(updated.favoriteRegions, isNot(contains('Chablis')),
          reason: 'Un 6/10 n\'est ni un goût ni un dégoût.');
    });

    test('une bouteille défectueuse est ignorée', () async {
      final service = TasteProfileService();
      await service.recordTastingExperience(
        nameOrId: 'primary',
        wine: wineFrom(region: 'Saint-Émilion', grape: 'Merlot'),
        rating: 1.5,
        hadFault: true,
      );
      final updated = await service.getPrimaryProfile();
      expect(updated.questionnairesCompleted, equals(0),
          reason: 'Un vin bouchonné n\'apprend rien sur le palais — il apprendrait même '
              'le contraire de la vérité, à savoir que la personne déteste la région.');
    });
  });

  group('📉 Moyenne exponentielle plutôt que cumulative', () {
    // Réplique du mécanisme de _runningAvg, qui est privé. Le but n'est pas de tester la
    // méthode mais la PROPRIÉTÉ qu'elle doit avoir : suivre un palais qui change.
    double ewma(double? current, double value) =>
        current == null ? value : current * (1 - kAxisSmoothing) + value * kAxisSmoothing;

    double cumulative(double? current, double value, int n) =>
        current == null || n == 0 ? value : (current * n + value) / (n + 1);

    test('un palais qui bascule est suivi en une dizaine de dégustations', () {
      double? axis;
      for (var i = 0; i < 24; i++) {
        axis = ewma(axis, 0.80); // 24 rouges puissants
      }
      expect(axis, closeTo(0.80, 0.01));

      var steps = 0;
      while ((axis! - 0.32).abs() > 0.05 && steps < 100) {
        axis = ewma(axis, 0.32); // le palais bascule vers des vins tendus
        steps++;
      }
      expect(steps, lessThan(15),
          reason: 'L\'exponentielle doit converger vite. Mesuré : 8 dégustations.');
    });

    test('la moyenne cumulative, elle, ne converge jamais', () {
      double? axis;
      for (var i = 0; i < 24; i++) {
        axis = cumulative(axis, 0.80, i);
      }
      for (var i = 24; i < 144; i++) {
        axis = cumulative(axis, 0.32, i); // 120 dégustations contradictoires
      }
      expect(axis, greaterThan(0.37),
          reason: 'Après 120 dégustations contraires, la cumulative reste bloquée vers 0,40 '
              'au lieu de 0,32. C\'est le gel que l\'exponentielle corrige.');
    });

    test('le poids marginal ne s\'effondre pas avec l\'ancienneté', () {
      // Exponentielle : le poids d'une nouvelle observation est constant.
      const poidsExp = kAxisSmoothing;
      // Cumulative : 1/(n+1), soit 0,33 % après 300 dégustations.
      final poidsCumul300 = 1 / 301;
      expect(poidsExp, greaterThan(poidsCumul300 * 50),
          reason: 'Après 300 dégustations, la cumulative n\'écoutait plus (0,33 %).');
    });
  });

  group('🎯 Confiance par axe', () {
    test('un axe jamais observé a une confiance nulle', () {
      const profile = TasteProfile(id: 'p', name: 'Test');
      for (final axis in TasteProfile.axisKeys) {
        expect(profile.axisConfidence(axis), equals(0.0),
            reason: '\$axis ne devrait rien affirmer sans observation.');
      }
      expect(profile.overallConfidence, equals(0.0));
    });

    test('la confiance croît vite au début puis sature', () {
      double conf(int n) =>
          TasteProfile(id: 'p', name: 'T', axisObservations: {'tannin': n})
              .axisConfidence('tannin');

      expect(conf(1), closeTo(0.17, 0.01), reason: 'Une dégustation donne déjà une idée grossière.');
      expect(conf(5), closeTo(0.50, 0.01));
      expect(conf(20), closeTo(0.80, 0.01));
      // Strictement croissante, jamais 1 : on ne prétend jamais tout savoir.
      expect(conf(50), lessThan(1.0));
      expect(conf(50), greaterThan(conf(20)));
    });

    test('l\'axe le moins connu est celui où une dégustation apprendrait le plus', () {
      const profile = TasteProfile(
        id: 'p',
        name: 'T',
        axisObservations: {
          'tannin': 12, 'body': 15, 'oak': 1, 'ripeFruit': 9,
          'spice': 7, 'freshFruit': 14, 'minerality': 11, 'acidity': 16,
        },
      );
      expect(profile.leastKnownAxis, equals('oak'),
          reason: 'C\'est l\'entrée du moteur de frontière : où envoyer la personne.');
    });

    test('la confiance globale reflète un profil inégal', () {
      const profile = TasteProfile(
        id: 'p',
        name: 'T',
        axisObservations: {'tannin': 30, 'body': 30},
      );
      // Deux axes bien connus sur huit : la moyenne doit rester basse.
      expect(profile.overallConfidence, lessThan(0.3),
          reason: 'Bien connaître deux axes ne veut pas dire connaître le palais.');
    });
  });

  group('🔢 Échelle de notation explicite', () {
    TastingEntry entry({required double rating, required int scale}) => TastingEntry(
          id: 't1',
          wineId: 'w1',
          rating: rating,
          ratingScale: scale,
          consumedAt: DateTime(2026, 9, 15),
        );

    test('une note sur 10 est lue telle quelle', () {
      expect(entry(rating: 3.5, scale: 10).displayRating, equals(3.5),
          reason: 'L\'ancienne heuristique doublait toute note ≤ 5 : un 3,5 « décevant » '
              'était lu 7,0 « aimé ».');
      expect(entry(rating: 5.0, scale: 10).displayRating, equals(5.0),
          reason: 'Un 5/10 quelconque était lu 10/10, soit une note parfaite.');
      expect(entry(rating: 8.5, scale: 10).displayRating, equals(8.5));
    });

    test('une note héritée de l\'échelle sur 5 est ramenée sur 10', () {
      expect(entry(rating: 4.0, scale: 5).displayRating, equals(8.0));
      expect(entry(rating: 2.5, scale: 5).displayRating, equals(5.0));
    });

    test('une ligne sans rating_scale est lue sur 5, pas sur 10', () {
      // Convention non évidente, et c'est précisément pourquoi elle est testée.
      // L'absence de la colonne n'est pas une information manquante : c'est la preuve que
      // la migration 032 n'a pas tourné, donc que la contrainte `rating <= 5` tient encore,
      // donc que le client a divisé la note par deux pour réussir l'insert. Reprendre 10
      // par défaut afficherait tout l'historique deux fois trop bas.
      final heritee = TastingEntry.fromJson(const {
        'id': 't1',
        'wine_id': 'w1',
        'rating': 2.8, // curseur à 5,5/10, divisé puis arrondi par NUMERIC(2,1)
        'consumed_at': '2026-08-27T20:00:00Z',
      });
      expect(heritee.ratingScale, equals(5));
      expect(heritee.displayRating, closeTo(5.6, 0.001),
          reason: 'Observé en production : 2,8 en base correspond à un curseur à 5,5/10.');
    });

    test('une ligne écrite après 032 porte son échelle et n\'est pas doublée', () {
      final moderne = TastingEntry.fromJson(const {
        'id': 't2',
        'wine_id': 'w1',
        'rating': 3.5,
        'rating_scale': 10,
        'consumed_at': '2026-09-15T20:00:00Z',
      });
      expect(moderne.displayRating, equals(3.5),
          reason: 'Une fois l\'échelle explicite, un 3,5 décevant reste un 3,5.');
    });

    test('le défaut exclut la dégustation du modèle', () {
      final sain = TastingEntry(
          id: 'a', wineId: 'w', consumedAt: DateTime(2026, 9, 15), rating: 8.0);
      final bouchonne = TastingEntry(
          id: 'b',
          wineId: 'w',
          consumedAt: DateTime(2026, 9, 15),
          rating: 2.0,
          fault: 'cork');
      expect(sain.isUsableForTasteModel, isTrue);
      expect(bouchonne.isUsableForTasteModel, isFalse);
    });
  });
}
