import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_flagging_engine.dart';

void main() {
  group('MenuFlaggingEngine - Quota Logic', () {
    test('computeMaxFlags enforces soft caps based on menu size', () {
      expect(MenuFlaggingEngine.computeMaxFlags(0), 0);
      expect(MenuFlaggingEngine.computeMaxFlags(3), 2);
      expect(MenuFlaggingEngine.computeMaxFlags(6), 2);
      expect(MenuFlaggingEngine.computeMaxFlags(10), 3);
      expect(MenuFlaggingEngine.computeMaxFlags(14), 3);
      expect(MenuFlaggingEngine.computeMaxFlags(18), 4);
      expect(MenuFlaggingEngine.computeMaxFlags(22), 4);
      expect(MenuFlaggingEngine.computeMaxFlags(25), 5);
      expect(MenuFlaggingEngine.computeMaxFlags(60), 5);
    });

    test('respects max flags on small menu (<= 14 wines)', () {
      final wines = List.generate(12, (i) {
        return MenuWine(
          id: 'wine_$i',
          name: 'Cuvée $i',
          producer: 'Domaine $i',
          wineType: 'red',
          isGem: true,
          gemReason: 'Pépite artisanale $i',
        );
      });

      final flagged = MenuFlaggingEngine.applyFlags(wines, null);
      final flaggedCount = flagged.where((w) => w.flag != null).length;

      // Small menu has max 3 flags
      expect(flaggedCount, equals(3));
      expect(flagged.every((w) => w.flag == null || w.flag!.type == MenuWineFlagType.gem), isTrue);
    });

    test('respects max flags on large menu (> 22 wines)', () {
      final wines = List.generate(28, (i) {
        return MenuWine(
          id: 'wine_$i',
          name: 'Cuvée $i',
          producer: 'Domaine $i',
          wineType: 'white',
          isDeal: i % 2 == 0,
          dealReason: 'Super affaire',
          isGem: i % 2 != 0,
          gemReason: 'Pépite star',
        );
      });

      final flagged = MenuFlaggingEngine.applyFlags(wines, null);
      final flaggedCount = flagged.where((w) => w.flag != null).length;

      // Large menu has max 5 flags
      expect(flaggedCount, equals(5));
    });

    test('soft cap does not invent flags if no genuine candidates exist', () {
      final ordinaryWines = List.generate(15, (i) {
        return MenuWine(
          id: 'wine_$i',
          name: 'Vin standard $i',
          producer: 'Maison standard',
          wineType: 'red',
          isDeal: false,
          isGem: false,
        );
      });

      final flagged = MenuFlaggingEngine.applyFlags(ordinaryWines, null);
      expect(flagged.where((w) => w.flag != null).length, 0);
    });
  });

  group('TasteProfile.isWellProvided & TasteMatch Flagging', () {
    test('new or incomplete user profile is not well provided', () {
      const emptyProfile = TasteProfile(
        id: 'p1',
        name: 'Novice',
        questionnairesCompleted: 0,
      );
      expect(emptyProfile.isWellProvided, isFalse);

      const oneQProfile = TasteProfile(
        id: 'p2',
        name: 'Débutant',
        questionnairesCompleted: 1,
      );
      expect(oneQProfile.isWellProvided, isFalse);
    });

    test('mature profile with >= 3 questionnaires is well provided', () {
      const matureProfile = TasteProfile(
        id: 'p3',
        name: 'Passionné',
        questionnairesCompleted: 3,
      );
      expect(matureProfile.isWellProvided, isTrue);
    });

    test('NEVER flags tasteMatch if userProfile is null or not well provided', () {
      const incompleteProfile = TasteProfile(
        id: 'p_incomplete',
        name: 'Incomplet',
        questionnairesCompleted: 1,
      );

      final wines = [
        const MenuWine(
          id: 'w1',
          name: 'Pomerol 2018',
          producer: 'Château Gazin',
          wineType: 'red',
          userMatchScore: 98.0, // Extremely high score
        ),
        const MenuWine(
          id: 'w2',
          name: 'Chablis 2020',
          producer: 'Domaine Raveneau',
          wineType: 'white',
          userMatchScore: 95.0,
        ),
      ];

      // Test with null profile
      final flaggedNull = MenuFlaggingEngine.applyFlags(wines, null);
      expect(flaggedNull.any((w) => w.flag?.type == MenuWineFlagType.tasteMatch), isFalse);

      // Test with incomplete profile
      final flaggedIncomplete = MenuFlaggingEngine.applyFlags(wines, incompleteProfile);
      expect(flaggedIncomplete.any((w) => w.flag?.type == MenuWineFlagType.tasteMatch), isFalse);
    });

    test('FLAGS tasteMatch when userProfile.isWellProvided is true and match score >= 78%', () {
      const wellProvidedProfile = TasteProfile(
        id: 'p_expert',
        name: 'Connaisseur',
        questionnairesCompleted: 4,
      );

      final wines = [
        const MenuWine(
          id: 'w1',
          name: 'Côte-Rôtie 2019',
          producer: 'Domaine Jamet',
          wineType: 'red',
          userMatchScore: 94.0,
        ),
        const MenuWine(
          id: 'w2',
          name: 'Vin Ordinaire',
          producer: 'Coopérative',
          wineType: 'red',
          userMatchScore: 50.0,
        ),
      ];

      final flagged = MenuFlaggingEngine.applyFlags(wines, wellProvidedProfile);
      final matchWine = flagged.firstWhere((w) => w.id == 'w1');

      expect(matchWine.flag, isNotNull);
      expect(matchWine.flag!.type, equals(MenuWineFlagType.tasteMatch));
      expect(matchWine.flag!.label, contains('94%'));
      expect(matchWine.flag!.iconEmoji, equals('🎯'));
    });
  });

  group('Category Diversity & Fair Allocation', () {
    test('allocates balanced flags across gems, deals, and profile matches', () {
      const matureProfile = TasteProfile(
        id: 'p_mature',
        name: 'Adepte',
        questionnairesCompleted: 5,
      );

      final wines = [
        const MenuWine(
          id: 'w_deal_1',
          name: 'Bourgogne Rouge',
          producer: 'Domaine Trapet',
          wineType: 'red',
          bottlePrice: 38.0,
          estimatedRetailPrice: 32.0, // Low markup deal
          isDeal: true,
          dealReason: 'Très faible coefficient',
        ),
        const MenuWine(
          id: 'w_gem_1',
          name: 'Saumur-Champigny Clos Rougeard',
          producer: 'Clos Rougeard',
          wineType: 'red',
          isGem: true,
          gemReason: 'Légende absolue de la Loire',
        ),
        const MenuWine(
          id: 'w_match_1',
          name: 'Hermitage',
          producer: 'Jean-Louis Chave',
          wineType: 'red',
          userMatchScore: 96.0,
        ),
        const MenuWine(
          id: 'w_other_1',
          name: 'Générique 1',
          producer: 'Inconnu',
          wineType: 'white',
        ),
        const MenuWine(
          id: 'w_other_2',
          name: 'Générique 2',
          producer: 'Inconnu',
          wineType: 'white',
        ),
        const MenuWine(
          id: 'w_other_3',
          name: 'Générique 3',
          producer: 'Inconnu',
          wineType: 'white',
        ),
        const MenuWine(
          id: 'w_other_4',
          name: 'Générique 4',
          producer: 'Inconnu',
          wineType: 'white',
        ),
      ];

      final flagged = MenuFlaggingEngine.applyFlags(wines, matureProfile);

      final deal = flagged.firstWhere((w) => w.id == 'w_deal_1');
      final gem = flagged.firstWhere((w) => w.id == 'w_gem_1');
      final match = flagged.firstWhere((w) => w.id == 'w_match_1');
      final other = flagged.firstWhere((w) => w.id == 'w_other_1');

      expect(deal.flag?.type, equals(MenuWineFlagType.deal));
      expect(gem.flag?.type, equals(MenuWineFlagType.gem));
      expect(match.flag?.type, equals(MenuWineFlagType.tasteMatch));
      expect(other.flag, isNull);
    });
  });

  group('MenuWineFlag Serialization', () {
    test('toJson and fromJson preserve flag metadata and colors', () {
      const flag = MenuWineFlag(
        type: MenuWineFlagType.deal,
        label: 'Grosse Affaire',
        reason: 'Prix domaine exceptionnel',
      );

      final json = flag.toJson();
      final restored = MenuWineFlag.fromJson(json);

      expect(restored.type, equals(MenuWineFlagType.deal));
      expect(restored.label, equals('Grosse Affaire'));
      expect(restored.reason, equals('Prix domaine exceptionnel'));
      expect(restored.iconEmoji, equals('💎'));
    });
  });
}
