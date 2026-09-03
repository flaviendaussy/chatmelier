import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cellar/data/cellar_repository.dart';
import '../../features/cellar/domain/bottle.dart';
import '../../features/offline/presentation/sync_provider.dart';
import '../../features/offline/data/offline_storage_service.dart';
import 'supabase_provider.dart';

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
final currentCellarRoleProvider = StateProvider<String>((ref) => 'admin');

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
  }
  ref.invalidate(bottlesProvider(null));
  ref.invalidate(userCellarsProvider);
}

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