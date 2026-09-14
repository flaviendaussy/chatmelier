import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';

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
  });
}
