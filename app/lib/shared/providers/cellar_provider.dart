import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cellar/data/cellar_repository.dart';
import '../../features/cellar/domain/bottle.dart';
import '../../features/cellar/domain/cellar_furniture.dart';
import '../../features/offline/presentation/sync_provider.dart';
import '../../features/offline/data/offline_storage_service.dart';
import 'supabase_provider.dart';
import 'package:flutter/foundation.dart';
import '../../features/cellar/domain/apogee_backfill.dart';
import '../../features/cellar/domain/wine.dart';
import '../utils/app_logger.dart';

final cellarRepositoryProvider = Provider<CellarRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final offlineStorage = ref.watch(offlineStorageServiceProvider);
  return CellarRepository(supabase, offlineStorage);
});

class CurrentCellarNotifier extends StateNotifier<String?> {
  final OfflineStorageService _storage;

  CurrentCellarNotifier(this._storage) : super(_storage.getLastSelectedCellarId());

  @override
  set state(String? value) {
    super.state = value;
    _storage.saveLastSelectedCellarId(value);
  }

  void selectCellar(String? cellarId) {
    state = cellarId;
  }
}

final currentCellarIdProvider = StateNotifierProvider<CurrentCellarNotifier, String?>((ref) {
  final storage = ref.watch(offlineStorageServiceProvider);
  return CurrentCellarNotifier(storage);
});
final currentCellarRoleProvider = Provider<String>((ref) {
  final currentCellarId = ref.watch(currentCellarIdProvider);
  final cellars = ref.watch(userCellarsProvider).value;

  if (cellars == null || cellars.isEmpty) {
    return 'admin';
  }

  if (currentCellarId != null && currentCellarId.isNotEmpty) {
    for (final item in cellars) {
      final cMap = item['cellars'];
      final id = cMap is Map ? cMap['id']?.toString() : item['cellar_id']?.toString();
      if (id == currentCellarId) {
        final role = item['role']?.toString().toLowerCase();
        if (role != null && role.isNotEmpty) {
          return role;
        }
      }
    }
  }

  final firstRole = cellars.first['role']?.toString().toLowerCase();
  return firstRole ?? 'admin';
});

final userCellarsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(cellarRepositoryProvider);
  return repo.getUserCellarsWithRole();
});

final cellarVersionProvider = StateProvider<int>((ref) => 0);

/// Helper to immediately invalidate all cellar bottles and stats across the app
void notifyCellarChanged(WidgetRef ref, [String? cellarId]) {
  ref.read(cellarVersionProvider.notifier).state++;
  if (cellarId != null) {
    ref.invalidate(bottlesProvider(cellarId));
    ref.invalidate(cellarFurnitureProvider(cellarId));
  }
  ref.invalidate(bottlesProvider(null));
  ref.invalidate(userCellarsProvider);
}

final cellarFurnitureProvider = FutureProvider.family<List<CellarFurniture>, String>((ref, cellarId) async {
  ref.watch(cellarVersionProvider);
  final repo = ref.watch(cellarRepositoryProvider);
  return repo.getCellarFurniture(cellarId);
});

final bottlesProvider = FutureProvider.family<List<Bottle>, String?>((ref, cellarId) async {
  // Automatically reload whenever cellarVersion changes
  ref.watch(cellarVersionProvider);
  final repo = ref.watch(cellarRepositoryProvider);
  if (cellarId == null) {
    final storage = ref.watch(offlineStorageServiceProvider);
    final lastCellarId = storage.getLastSelectedCellarId();
    if (lastCellarId != null && lastCellarId.isNotEmpty) {
      return repo.getBottles(lastCellarId);
    }
    final cellars = await repo.getUserCellarsWithRole();
    if (cellars.isNotEmpty) {
      final firstCellar = cellars.first['cellars'];
      final id = firstCellar is Map ? firstCellar['id']?.toString() : cellars.first['cellar_id']?.toString();
      if (id != null) return repo.getBottles(id);
    }
    return [];
  }
  return repo.getBottles(cellarId);
});

/// Réécrit en base les apogées que la correction juge fausses.
///
/// Déclenché au chargement de la cave, une fois par ouverture. Volontairement silencieux
/// et sans blocage : si le réseau manque ou qu'une écriture échoue, on réessaiera à la
/// prochaine ouverture. Rien dans l'affichage n'en dépend — l'app lit déjà tout à travers
/// la correction ; cette écriture sert les AUTRES lecteurs de la base (version web,
/// versions installées plus anciennes, exports, contexte du sommelier IA).
///
/// `wines` étant un catalogue partagé, une fiche corrigée pour une personne l'est pour
/// toutes celles qui scanneront le même vin.
final apogeeBackfillProvider = FutureProvider<int>((ref) async {
  final bottles = await ref.watch(bottlesProvider(null).future);
  final vins = <String, Wine>{};
  for (final b in bottles) {
    final w = b.wine;
    if (w != null && w.id.isNotEmpty) vins[w.id] = w;
  }
  if (vins.isEmpty) return 0;

  final corrections = ApogeeBackfill.aCorriger(vins.values.toList());
  if (corrections.isEmpty) return 0;

  final client = ref.watch(supabaseProvider);
  var ecrites = 0;
  for (final c in corrections) {
    try {
      await client.from('wines').update(c.payload).eq('id', c.wineId);
      ecrites++;
    } catch (e) {
      // Une fiche non corrigée reste affichée juste dans l'app : l'échec n'a pas de
      // conséquence visible, il sera retenté au prochain chargement.
      debugPrint('Backfill apogée ignoré pour ${c.wineId} : $e');
    }
  }
  AppLogger.info('APOGEE_BACKFILL',
      '$ecrites fenêtre(s) corrigée(s) sur ${corrections.length} détectée(s)');
  return ecrites;
});

final bottleDetailProvider = FutureProvider.family<Bottle, String>((ref, id) async {
  ref.watch(cellarVersionProvider);
  return ref.watch(cellarRepositoryProvider).getBottleById(id);
});

/// Provider to select a specific cellar or 'overall' (all cellars aggregated) for Statistics
final statsSelectedCellarIdProvider = StateProvider<String?>((ref) => 'overall');

final statsBottlesProvider = FutureProvider<List<Bottle>>((ref) async {
  ref.watch(cellarVersionProvider);
  final repo = ref.watch(cellarRepositoryProvider);
  final selected = ref.watch(statsSelectedCellarIdProvider);

  // If a specific cellar is selected (and not 'overall')
  if (selected != null && selected != 'overall') {
    return repo.getBottles(selected);
  }

  // Overall: aggregate bottles from ALL cellars belonging to the user
  final cellars = await ref.watch(userCellarsProvider.future);
  if (cellars.isEmpty) {
    final currentCellarId = ref.watch(currentCellarIdProvider);
    if (currentCellarId != null) {
      return repo.getBottles(currentCellarId);
    }
    return [];
  }

  final Set<String> loadedCellarIds = {};
  final List<Bottle> allBottles = [];
  for (final item in cellars) {
    final cMap = item['cellars'] as Map<String, dynamic>?;
    final id = (cMap != null && cMap['id'] != null)
        ? cMap['id'].toString()
        : item['cellar_id']?.toString();
    if (id != null && id.isNotEmpty && !loadedCellarIds.contains(id)) {
      loadedCellarIds.add(id);
      final bottles = await repo.getBottles(id);
      allBottles.addAll(bottles);
    }
  }

  // Deduplicate bottles by id if present in multiple cellar memberships
  final Map<String, Bottle> uniqueBottles = {};
  for (final b in allBottles) {
    uniqueBottles[b.id] = b;
  }
  return uniqueBottles.values.toList();
});