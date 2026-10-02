import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/sommelier/domain/profil_du_vin_de_cave.dart';

void main() {
  group('👫 Guest Matcher Consensus & Aversion Tests', () {
    final flavienProfile = TasteProfile(
      id: 'flavien',
      name: 'Flavien',
      favoriteTypes: const ['Rouge'],
      favoriteGrapes: const ['Syrah', 'Mourvèdre'],
      avgTanninPreference: 0.8,
      avgBodyPreference: 0.8,
      avgSpicePreference: 0.9,
    );

    final caroProfile = TasteProfile(
      id: 'caro',
      name: 'Caro',
      favoriteTypes: const ['Blanc sec', 'Champagne'],
      favoriteGrapes: const ['Chardonnay', 'Sauvignon Blanc', 'Pinot Noir'],
      dislikedCharacteristics: const ['Trop tannique', 'Trop lourd'],
      avgAcidityPreference: 0.9,
      avgMineralityPreference: 0.85,
      avgFreshFruitPreference: 0.8,
      avgTanninPreference: 0.25,
    );

    final guests = [
      GuestProfile.fromTasteProfile(flavienProfile),
      GuestProfile.fromTasteProfile(caroProfile),
    ];

    // Bottle 1: Powerful tannic Cornas
    final cornasWine = Wine(
      id: 'wine_cornas',
      name: 'Cornas Les Ruchets',
      producer: 'Jean-Luc Colombo',
      type: 'Rouge',
      region: 'Vallée du Rhône',
      country: 'France',
      grapes: const [Grape(name: 'Syrah', pct: 100)],
      vintage: 2019,
    );
    final cornasBottle = Bottle(
      id: 'b1',
      cellarId: 'c1',
      wineId: 'wine_cornas',
      addedBy: 'user1',
      ownerId: 'user1',
      createdAt: DateTime.now(),
      wine: cornasWine,
    );

    // Bottle 2: Balanced, elegant Bourgogne Pinot Noir (Passerelle / Consensus)
    final pinotWine = Wine(
      id: 'wine_pinot',
      name: 'Chambolle-Musigny 1er Cru',
      producer: 'Domaine de la Pousse d\'Or',
      type: 'Rouge',
      region: 'Bourgogne',
      country: 'France',
      grapes: const [Grape(name: 'Pinot Noir', pct: 100)],
      vintage: 2020,
    );
    final pinotBottle = Bottle(
      id: 'b2',
      cellarId: 'c1',
      wineId: 'wine_pinot',
      addedBy: 'user1',
      ownerId: 'user1',
      createdAt: DateTime.now(),
      wine: pinotWine,
    );

    // Bottle 3: Tension Chablis 1er Cru (white)
    final chablisWine = Wine(
      id: 'wine_chablis',
      name: 'Chablis 1er Cru Montée de Tonnerre',
      producer: 'Louis Michel',
      type: 'Blanc sec',
      region: 'Bourgogne',
      country: 'France',
      grapes: const [Grape(name: 'Chardonnay', pct: 100)],
      vintage: 2021,
    );
    final chablisBottle = Bottle(
      id: 'b3',
      cellarId: 'c1',
      wineId: 'wine_chablis',
      addedBy: 'user1',
      ownerId: 'user1',
      createdAt: DateTime.now(),
      wine: chablisWine,
    );

    test('Identifies balanced consensus wine (Pinot Noir) above divisive high-tannin wine', () {
      final ranked = GuestMatcherEngine.rankBottlesForGuests(
        bottles: [cornasBottle, pinotBottle, chablisBottle],
        guests: guests,
      );

      expect(ranked.isNotEmpty, isTrue);

      // Cornas triggers Caro\'s strict aversion to tannins
      final cornasResult = ranked.firstWhere((r) => r.bottle.wineId == 'wine_cornas');
      expect(cornasResult.aversionAlerts.isNotEmpty, isTrue);
      expect(cornasResult.aversionAlerts.first, contains('Caro'));

      // Chambolle-Musigny should rank high as the elegant red consensus
      final pinotResult = ranked.firstWhere((r) => r.bottle.wineId == 'wine_pinot');
      expect(pinotResult.consensusScore, greaterThan(cornasResult.consensusScore));
      expect(pinotResult.aversionAlerts, isEmpty);
    });

    test('Consensus score is penalized when guests have opposing feelings', () {
      final ranked = GuestMatcherEngine.rankBottlesForGuests(
        bottles: [cornasBottle, pinotBottle],
        guests: guests,
      );

      final cornas = ranked.firstWhere((r) => r.bottle.wineId == 'wine_cornas');
      final pinot = ranked.firstWhere((r) => r.bottle.wineId == 'wine_pinot');

      expect(pinot.consensusScore, greaterThan(60.0));
      expect(cornas.consensusScore, lessThan(pinot.consensusScore));
    });
      test('le pourquoi dit qui l\'aimera, sans rien inventer sur le vin', () {
      final ranked = GuestMatcherEngine.rankBottlesForGuests(
        bottles: [cornasBottle, pinotBottle, chablisBottle],
        guests: guests,
        idLecteur: 'flavien',
      );
      final raisons = ranked.map((r) => r.sommelierRationale).toList();
      for (final r in raisons) {
        // Les phrases fixes d'avant : « l'élégance de… », « ouverture préalable de 30 minutes ».
        expect(r, isNot(contains('élégance')));
        expect(r, isNot(contains('30 minutes')));
        // Le lecteur se lit « vous », jamais par son nom.
        expect(r, isNot(contains('Flavien')));
        expect(r, contains('Caro'));
      }
      final cornas = ranked.firstWhere((r) => r.bottle.wineId == 'wine_cornas');
      expect(cornas.sommelierRationale, contains('Caro n\'aime pas les tanins fermes'));
      expect(cornas.sommelierRationale, startsWith('Vous allez l\'adorer'));
    });
  });

  group('🍷 À la maison, les fiches départagent (V2.3 · J8)', () {
    final annee = DateTime.now().year;
    Bottle bouteille(Wine w) => Bottle(
        id: 'b_${w.id}', cellarId: 'cave', wineId: w.id, addedBy: 'moi', ownerId: 'moi', createdAt: DateTime.now(), wine: w);
    Wine bourgogne(String id, String nom, int millesime, {double? degre, String? notes, String? elevage, int? mois}) => Wine(
          id: id,
          name: nom,
          type: 'red',
          region: 'Bourgogne',
          country: 'France',
          grapes: const [Grape(name: 'Pinot Noir')],
          vintage: millesime,
          alcoholPct: degre,
          tastingNotes: notes,
          elevageType: elevage,
          elevageMois: mois,
        );

    final convives = [
      GuestProfile.fromTasteProfile(const TasteProfile(
          id: 'p', name: 'Paul', favoriteTypes: ['Rouge'], avgTanninPreference: 0.7, avgBodyPreference: 0.7)),
      GuestProfile.fromTasteProfile(const TasteProfile(
          id: 'c', name: 'Caro', avgAcidityPreference: 0.8, avgFreshFruitPreference: 0.8, avgTanninPreference: 0.3)),
    ];

    test('trois Bourgognes ne sont plus ex æquo : la fiche dit ce qui les distingue', () {
      final vins = [
        bourgogne('chambolle', 'Chambolle-Musigny', annee - 9, degre: 13.0, notes: 'Soyeux, fruits rouges, cerise.'),
        bourgogne('pommard', 'Pommard 1er Cru', annee - 5,
            degre: 13.5, notes: 'Tanins fermes, fruits noirs.', elevage: 'barrique', mois: 20),
        bourgogne('bourgogne', 'Bourgogne Pinot Noir', annee - 3, degre: 12.5),
      ];
      final classement = GuestMatcherEngine.rankBottlesForGuests(
          bottles: [for (final w in vins) bouteille(w)], guests: convives);
      expect(classement.map((r) => r.consensusScore).toSet(), hasLength(3),
          reason: classement.map((r) => '${r.bottle.wine!.name} ${r.consensusScore}').join(' · '));

      final pommard = ProfilDuVinDeCave.estimer(vins[1], annee: annee);
      final chambolle = ProfilDuVinDeCave.estimer(vins[0], annee: annee);
      expect(pommard.tannin, greaterThan(chambolle.tannin), reason: 'tanins fermes, jeune, élevé en barrique');
      expect(pommard.oak, greaterThan(chambolle.oak));
    });

    test('la couleur aimée compte : « Rouge » au profil, « red » sur la fiche', () {
      final rouge = Wine(id: 'r', name: 'Cuvée', type: 'red', region: 'Languedoc', country: 'France', vintage: annee - 4);
      // Deux palais identiques ; seule la couleur aimée diffère.
      const amateur = GuestProfile(id: 'a', name: 'Aude', favoriteTypes: ['Rouge']);
      const neutre = GuestProfile(id: 'n', name: 'Noé');
      final r = GuestMatcherEngine.rankBottlesForGuests(bottles: [bouteille(rouge)], guests: [amateur, neutre]).single;
      expect(r.guestScores['a']! - r.guestScores['n']!, closeTo(8.0, 0.01));
    });

    test('ce soir, la bouteille à son apogée passe devant la plus jeune, et la phrase le dit', () {
      Wine cornas(String id, int millesime) => Wine(
            id: id,
            name: 'Cornas',
            type: 'red',
            region: 'Vallée du Rhône',
            appellation: 'Cornas',
            country: 'France',
            grapes: const [Grape(name: 'Syrah')],
            vintage: millesime,
          );
      final jeune = cornas('jeune', annee - 1);
      final mur = cornas('mur', annee - 14);
      expect(jeune.windowStatus, DrinkWindowStatus.tooYoung);
      final classement = GuestMatcherEngine.rankBottlesForGuests(
          bottles: [bouteille(jeune), bouteille(mur)], guests: convives);
      expect(classement.first.bottle.wine!.id, 'mur');
      expect(classement.last.sommelierRationale, contains('Encore jeune'));
    });
  });
}
