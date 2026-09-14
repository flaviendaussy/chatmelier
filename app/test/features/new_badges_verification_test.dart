import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/badges/data/badge_catalog.dart';
import 'package:chatmelier/features/badges/data/badge_evaluator.dart';
import 'package:chatmelier/features/badges/domain/badge.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';

void main() {
  group('🏅 New Badges & Complete Asset Catalog Verification', () {
    test('100% of badges in BadgeCatalog have an existing WebP asset on disk', () {
      expect(BadgeCatalog.allBadges.length, greaterThanOrEqualTo(115));

      for (final badge in BadgeCatalog.allBadges) {
        expect(badge.assetImagePath, isNotNull, reason: '${badge.id} has null assetImagePath');
        expect(badge.assetImagePath!.isNotEmpty, isTrue, reason: '${badge.id} has empty assetImagePath');

        final file = File(badge.assetImagePath!);
        expect(file.existsSync(), isTrue, reason: 'Asset file does not exist on disk: ${badge.assetImagePath}');
      }
    });

    test('New feature badges exist in catalog and have correct tiers', () {
      final amaretto = BadgeCatalog.allBadges.firstWhere((b) => b.id == 'spirit_amaretto_italian');
      expect(amaretto.tier, equals(BadgeTier.silver));
      expect(amaretto.category, equals(BadgeCategory.spirits));

      final fillVigilant = BadgeCatalog.allBadges.firstWhere((b) => b.id == 'spirit_fill_vigilant');
      expect(fillVigilant.tier, equals(BadgeTier.bronze));
      expect(fillVigilant.category, equals(BadgeCategory.spirits));

      final flightDiscovery = BadgeCatalog.allBadges.firstWhere((b) => b.id == 'savant_flight_discovery');
      expect(flightDiscovery.tier, equals(BadgeTier.silver));
      expect(flightDiscovery.category, equals(BadgeCategory.chatmelierSavant));

      final consensusMaster = BadgeCatalog.allBadges.firstWhere((b) => b.id == 'savant_consensus_table_master');
      expect(consensusMaster.tier, equals(BadgeTier.gold));
      expect(consensusMaster.category, equals(BadgeCategory.chatmelierSavant));
    });

    test('BadgeEvaluator unlocks spirit_amaretto_italian when Disaronno or Amaretto is in cellar', () {
      final disaronnoBottle = Bottle.fromJson({
        'id': 'b_disaronno',
        'cellar_id': 'cellar_1',
        'wine_id': 'w_disaronno',
        'added_by': 'user_1',
        'wine': {
          'id': 'w_disaronno',
          'name': 'Disaronno Originale Amaretto',
          'type': 'liqueur',
          'country': 'Italie',
          'region': 'Lombardie',
        },
      });

      final unlocked = BadgeEvaluator.evaluate(
        bottles: [disaronnoBottle],
        tastings: [],
      );

      final amarettoBadge = unlocked.firstWhere((b) => b.badge.id == 'spirit_amaretto_italian');
      expect(amarettoBadge.isUnlocked, isTrue);
    });

    test('BadgeEvaluator unlocks spirit_fill_vigilant when a spirit bottle has fillLevel <= 25%', () {
      final lowFillCognac = Bottle.fromJson({
        'id': 'b_cognac',
        'cellar_id': 'cellar_1',
        'wine_id': 'w_cognac',
        'added_by': 'user_1',
        'fill_level': 20, // 20% remaining
        'wine': {
          'id': 'w_cognac',
          'name': 'Hennessy VSOP Cognac',
          'type': 'cognac',
          'country': 'France',
          'region': 'Charentes',
        },
      });

      final unlocked = BadgeEvaluator.evaluate(
        bottles: [lowFillCognac],
        tastings: [],
      );

      final fillBadge = unlocked.firstWhere((b) => b.badge.id == 'spirit_fill_vigilant');
      expect(fillBadge.isUnlocked, isTrue);
    });
  });
}
