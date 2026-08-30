import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/features/scratchcard/data/terroir_resolver_service.dart';

void main() {
  group('TerroirResolverService Tests', () {
    test('Correctly matches Margaux bottle to Bordeaux Left Bank', () {
      final bottle = Bottle(
        id: 'b1',
        cellarId: 'c1',
        wineId: 'w1',
        quantity: 3,
        addedBy: 'user1',
        ownerId: 'user1',
        createdAt: DateTime.now(),
        wine: const Wine(
          id: 'w1',
          name: 'Château Margaux Premier Grand Cru Classé',
          producer: 'Château Margaux',
          type: 'red',
          country: 'France',
          region: 'Bordeaux',
          appellation: 'Margaux',
          vintage: 2015,
        ),
      );

      final results = TerroirResolverService.resolveAll(
        bottles: [bottle],
        tastings: [],
      );

      final bdxLeft = results.firstWhere((r) => r.node.id == 'fr_bordeaux_left_bank');
      expect(bdxLeft.isOwned, isTrue);
      expect(bdxLeft.ownedCount, equals(3));
      expect(bdxLeft.isDrunk, isFalse);
      expect(bdxLeft.isUnlocked, isTrue);
    });

    test('Correctly matches Barolo tasting to Piemonte', () {
      final tasting = TastingEntry(
        id: 't1',
        wineId: 'w_barolo',
        wineName: 'Barolo Monfortino Riserva',
        vintage: 2010,
        appellation: 'Barolo',
        region: 'Piemonte',
        country: 'Italie',
        rating: 98,
        consumedAt: DateTime.now(),
      );

      final results = TerroirResolverService.resolveAll(
        bottles: [],
        tastings: [tasting],
      );

      final piemonte = results.firstWhere((r) => r.node.id == 'it_piemonte');
      expect(piemonte.isDrunk, isTrue);
      expect(piemonte.drunkCount, equals(1));
      expect(piemonte.isOwned, isFalse);
      expect(piemonte.isUnlocked, isTrue);
      expect(piemonte.topWine, contains('Barolo'));
    });

    test('Marks node as Mastered when both owned in cellar and tasted in journal', () {
      final bottle = Bottle(
        id: 'b2',
        cellarId: 'c1',
        wineId: 'w2',
        quantity: 2,
        addedBy: 'user1',
        ownerId: 'user1',
        createdAt: DateTime.now(),
        wine: const Wine(
          id: 'w2',
          name: 'Chablis Grand Cru Les Clos',
          producer: 'Domaine Laroche',
          type: 'white',
          country: 'France',
          region: 'Bourgogne',
          appellation: 'Chablis Grand Cru',
          vintage: 2020,
        ),
      );

      final tasting = TastingEntry(
        id: 't2',
        wineId: 'w2',
        wineName: 'Chablis Grand Cru Les Clos',
        vintage: 2020,
        appellation: 'Chablis Grand Cru',
        region: 'Bourgogne',
        country: 'France',
        rating: 95,
        consumedAt: DateTime.now(),
      );

      final results = TerroirResolverService.resolveAll(
        bottles: [bottle],
        tastings: [tasting],
      );

      final chablis = results.firstWhere((r) => r.node.id == 'fr_bourgogne_chablis');
      expect(chablis.isMastered, isTrue);
      expect(chablis.ownedCount, equals(2));
      expect(chablis.drunkCount, equals(1));
    });
  });
}
