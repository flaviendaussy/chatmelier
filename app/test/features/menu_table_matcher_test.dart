import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';

void main() {
  group('🍽️ Menu Table Consensus Matcher Engine Tests', () {
    const balancedWhite = MenuWine(
      id: 'mw_1',
      name: 'Chablis Domaine Billaud-Simon',
      producer: 'Domaine Billaud-Simon',
      appellation: 'Chablis',
      region: 'Bourgogne',
      wineType: 'Blanc',
      vintage: 2021,
      bottlePrice: 48.0,
      grapes: ['Chardonnay'],
      metrics: MenuWineRadarMetrics(
        tannins: 0.0,
        acidity: 7.0,
        body: 5.5,
        fruit: 6.5,
        oak: 2.0,
        minerality: 8.0,
      ),
    );

    const heavyTannicRed = MenuWine(
      id: 'mw_2',
      name: 'Madiran Château Bouscassé',
      producer: 'Château Bouscassé',
      appellation: 'Madiran',
      region: 'Sud-Ouest',
      wineType: 'Rouge',
      vintage: 2017,
      bottlePrice: 42.0,
      grapes: ['Tannat', 'Cabernet Sauvignon'],
      metrics: MenuWineRadarMetrics(
        tannins: 9.0, // Tanins massifs
        acidity: 5.0,
        body: 8.5,
        fruit: 6.0,
        oak: 7.0,
        minerality: 4.0,
      ),
    );

    const silkyRed = MenuWine(
      id: 'mw_3',
      name: 'Fleurie Domaine Chignard',
      producer: 'Domaine Chignard',
      appellation: 'Fleurie',
      region: 'Beaujolais',
      wineType: 'Rouge',
      vintage: 2022,
      bottlePrice: 39.0,
      grapes: ['Gamay'],
      metrics: MenuWineRadarMetrics(
        tannins: 3.5, // Tanins très soyeux
        acidity: 6.0,
        body: 5.0,
        fruit: 8.5,
        oak: 1.0,
        minerality: 6.0,
      ),
    );

    const grandBordeaux = MenuWine(
      id: 'mw_4',
      name: 'Saint-Émilion Grand Cru',
      producer: 'Château Figeac',
      appellation: 'Saint-Émilion',
      region: 'Bordeaux',
      wineType: 'Rouge',
      vintage: 2018,
      bottlePrice: 65.0,
      grapes: ['Merlot', 'Cabernet Franc'],
      metrics: MenuWineRadarMetrics(
        tannins: 6.5,
        acidity: 5.5,
        body: 7.0,
        fruit: 7.0,
        oak: 5.5,
        minerality: 5.0,
      ),
    );

    test('Consensus ranking penalizes heavy tannins when a guest has strict tannin aversion', () {
      final guest1 = const GuestProfile(
        id: 'g1',
        name: 'Alice',
        favoriteTypes: ['Blanc', 'Rouge'],
        dislikedCharacteristics: ['tanin dur', 'astringence'],
        archetype: 'Aversion Tanins Durs',
      );

      final guest2 = const GuestProfile(
        id: 'g2',
        name: 'Bob',
        favoriteTypes: ['Rouge'],
        archetype: 'Curieux & Éclectique',
      );

      final top3 = MenuTableMatcherEngine.rankTop3WinesForTable(
        menuWines: [balancedWhite, heavyTannicRed, silkyRed, grandBordeaux],
        guests: [guest1, guest2],
      );

      expect(top3.length, equals(3));
      // Heavy tannic red should NOT be #1 due to Alice's aversion penalty
      expect(top3.first.menuWine.id, isNot(equals('mw_2')));

      // Check that heavy tannic red generated aversion alert for Alice
      final madiranResult = MenuTableMatcherEngine.rankTop3WinesForTable(
        menuWines: [heavyTannicRed],
        guests: [guest1, guest2],
      ).first;

      expect(madiranResult.aversionAlerts.isNotEmpty, isTrue);
      expect(madiranResult.aversionAlerts.first, contains('Alice'));
    });

    test('Consensus ranking returns top 3 best matching wines with matching score', () {
      final guest1 = const GuestProfile(
        id: 'g1',
        name: 'Thomas',
        favoriteTypes: ['Blanc'],
        archetype: 'Blancs Minéraux & Frais',
      );

      final guest2 = const GuestProfile(
        id: 'g2',
        name: 'Sophie',
        favoriteTypes: ['Blanc'],
        archetype: 'Curieux & Éclectique',
      );

      final top3 = MenuTableMatcherEngine.rankTop3WinesForTable(
        menuWines: [balancedWhite, heavyTannicRed, silkyRed, grandBordeaux],
        guests: [guest1, guest2],
      );

      expect(top3.length, equals(3));
      // Chablis is the top mutual match for two white lovers
      expect(top3.first.menuWine.id, equals('mw_1'));
      expect(top3.first.harmonyScore, greaterThan(80.0));
      expect(top3.first.guestScores['g1'], isNotNull);
      expect(top3.first.guestScores['g2'], isNotNull);
    });
  });
}
