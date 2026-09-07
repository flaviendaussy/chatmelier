import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cellar/domain/bottle.dart';
import '../../journal/domain/tasting_entry.dart';
import '../domain/badge.dart';
import 'badge_evaluator.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../cocktails/data/bar_pantry_service.dart';

final userBadgesProgressProvider = Provider<List<BadgeProgress>>((ref) {
  // Aggregate bottles across all cellars belonging to user, falling back to current cellar
  final allBottlesAsync = ref.watch(statsBottlesProvider);
  final currentCellarId = ref.watch(currentCellarIdProvider);
  final currentBottles = ref.watch(bottlesProvider(currentCellarId)).value ?? const <Bottle>[];
  final bottles = (allBottlesAsync.value != null && allBottlesAsync.value!.isNotEmpty)
      ? allBottlesAsync.value!
      : currentBottles;
  final tastings = ref.watch(tastingLogProvider).value ?? const <TastingEntry>[];
  final pantry = ref.watch(barPantryProvider);

  return BadgeEvaluator.evaluate(
    bottles: bottles,
    tastings: tastings,
    pantry: pantry,
  );
});

final unlockedBadgesCountProvider = Provider<({int unlocked, int total})>((ref) {
  final badges = ref.watch(userBadgesProgressProvider);
  final unlocked = badges.where((b) => b.isUnlocked).length;
  return (unlocked: unlocked, total: badges.length);
});
