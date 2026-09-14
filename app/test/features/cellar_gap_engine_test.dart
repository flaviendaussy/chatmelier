import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/cellar_gap_engine.dart';

void main() {
  group('🔍 Cellar Gap Engine Imbalance & Wishlist Tests', () {
    test('Detects red wine dominance and zero sparkling in cellar', () {
      final bottles = [
        Bottle(
          id: 'b1',
          cellarId: 'cellar_1',
          wineId: 'w1',
          ownerId: 'user_1',
          addedBy: 'user_1',
          createdAt: DateTime(2023, 1, 1),
          quantity: 10,
          wine: const Wine(
            id: 'w1',
            name: 'Pauillac Grand Cru',
            type: 'Rouge',
            region: 'Bordeaux',
            country: 'France',
            drinkStart: 2028,
            drinkEnd: 2038,
          ),
        ),
        Bottle(
          id: 'b2',
          cellarId: 'cellar_1',
          wineId: 'w2',
          ownerId: 'user_1',
          addedBy: 'user_1',
          createdAt: DateTime(2023, 1, 1),
          quantity: 2,
          wine: const Wine(
            id: 'w2',
            name: 'Bourgogne Blanc',
            type: 'Blanc',
            region: 'Bourgogne',
            country: 'France',
            drinkStart: 2022,
            drinkEnd: 2025,
          ),
        ),
      ];

      final analysis = CellarGapEngine.analyzeCellar(bottles);

      expect(analysis.totalBottles, equals(12));
      expect(analysis.redRatio, greaterThan(0.8));
      expect(analysis.sparklingRatio, equals(0.0));

      final redGap = analysis.gaps.firstWhere((g) => g.title.contains('Rouges'));
      expect(redGap.status, equals('warning'));

      final sparkGap = analysis.gaps.firstWhere((g) => g.title.contains('Effervescent'));
      expect(sparkGap.status, equals('critical'));

      expect(analysis.shoppingWishlist, contains('Champagne Blanc de Blancs'));
    });

    test('Empty cellar returns virgin cellar guidance', () {
      final analysis = CellarGapEngine.analyzeCellar([]);
      expect(analysis.totalBottles, equals(0));
      expect(analysis.gaps.first.title, contains('Vierge'));
      expect(analysis.shoppingWishlist.isNotEmpty, isTrue);
    });
  });
}
