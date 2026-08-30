import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../domain/terroir_catalog.dart';
import '../domain/terroir_node.dart';

final scratchcardRepositoryProvider = Provider<ScratchcardRepository>((ref) {
  return ScratchcardRepository(ref);
});

final unlockedTerroirsProvider = FutureProvider<List<TerroirNode>>((ref) async {
  final repo = ref.watch(scratchcardRepositoryProvider);
  return repo.getEvaluatedTerroirs();
});

class ScratchcardRepository {
  final Ref _ref;

  ScratchcardRepository(this._ref);

  Future<List<TerroirNode>> getEvaluatedTerroirs() async {
    final supabase = _ref.watch(supabaseProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return TerroirCatalog.defaultNodes;

    final tastedKeywords = <String, List<String>>{};

    // 1. Fetch consumed tastings from tasting_log
    try {
      final List<dynamic> resTastings = await supabase
          .from('tasting_log')
          .select('*, wines(*)');

      for (final item in resTastings) {
        final wine = (item as Map<String, dynamic>)['wines'] as Map<String, dynamic>? ?? {};
        final name = (wine['name'] ?? item['wine_name'] ?? 'Vin').toString();
        final region = (wine['region'] ?? '').toString();
        final country = (wine['country'] ?? '').toString();
        final appellation = (wine['appellation'] ?? '').toString();
        final producer = (wine['producer'] ?? '').toString();

        final key = '$name $producer $region $country $appellation'.toLowerCase();
        tastedKeywords.putIfAbsent(key, () => []).add(name);
      }
    } catch (_) {}

    // 2. Fetch cellar bottles
    try {
      final List<dynamic> resBottles = await supabase
          .from('bottles')
          .select('*, wines(*)');

      for (final item in resBottles) {
        final wine = (item as Map<String, dynamic>)['wines'] as Map<String, dynamic>? ?? {};
        final name = (wine['name'] ?? 'Vin').toString();
        final region = (wine['region'] ?? '').toString();
        final country = (wine['country'] ?? '').toString();
        final appellation = (wine['appellation'] ?? '').toString();
        final producer = (wine['producer'] ?? '').toString();

        final key = '$name $producer $region $country $appellation'.toLowerCase();
        tastedKeywords.putIfAbsent(key, () => []).add(name);
      }
    } catch (_) {}

    final List<TerroirNode> evaluated = [];

    for (final node in TerroirCatalog.defaultNodes) {
      final nodeName = node.name.toLowerCase();
      int count = 0;
      final matchedWines = <String>{};

      tastedKeywords.forEach((wineMeta, names) {
        bool matches = false;

        if (node.level == TerroirLevel.continent) {
          if (node.name == 'Europe' &&
              (wineMeta.contains('france') ||
                  wineMeta.contains('italie') ||
                  wineMeta.contains('italy') ||
                  wineMeta.contains('espagne') ||
                  wineMeta.contains('spain') ||
                  wineMeta.contains('bordeaux') ||
                  wineMeta.contains('bourgogne') ||
                  wineMeta.contains('margaux') ||
                  wineMeta.contains('vigneron'))) {
            matches = true;
          } else if (node.name == 'Amériques' &&
              (wineMeta.contains('usa') ||
                  wineMeta.contains('napa') ||
                  wineMeta.contains('argentin') ||
                  wineMeta.contains('chili') ||
                  wineMeta.contains('kai-simone') ||
                  wineMeta.contains('californi'))) {
            matches = true;
          }
        } else {
          // Direct or partial match
          if (wineMeta.contains(nodeName)) {
            matches = true;
          } else if (node.name == 'Margaux' && wineMeta.contains('margaux')) {
            matches = true;
          } else if (node.name == 'Pauillac' && wineMeta.contains('pauillac')) {
            matches = true;
          } else if (node.name == 'Bordeaux' && (wineMeta.contains('bordeaux') || wineMeta.contains('margaux'))) {
            matches = true;
          } else if (node.name == 'France' && (wineMeta.contains('france') || wineMeta.contains('margaux') || wineMeta.contains('bordeaux') || wineMeta.contains('vigneron'))) {
            matches = true;
          } else if (node.name == 'États-Unis' && (wineMeta.contains('kai-simone') || wineMeta.contains('napa') || wineMeta.contains('californi') || wineMeta.contains('usa'))) {
            matches = true;
          }
        }

        if (matches) {
          count += names.length;
          matchedWines.addAll(names);
        }
      });

      evaluated.add(
        node.copyWith(
          tastedCount: count,
          isUnlocked: count > 0,
          bottleNames: matchedWines.toList(),
        ),
      );
    }

    return evaluated;
  }
}
