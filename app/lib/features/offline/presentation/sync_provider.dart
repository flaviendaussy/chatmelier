import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/offline_storage_service.dart';
import '../data/sync_service.dart';
import '../../../shared/providers/supabase_provider.dart';

final sharedPreferencesInstanceProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final offlineStorageServiceProvider = Provider<OfflineStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesInstanceProvider);
  return OfflineStorageService(prefs);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final storage = ref.watch(offlineStorageServiceProvider);
  return SyncService(
    supabase: supabase,
    offlineStorage: storage,
  );
});

final isOnlineProvider = StateProvider<bool>((ref) => true);

final pendingSyncCountProvider = StateProvider<int>((ref) {
  final storage = ref.watch(offlineStorageServiceProvider);
  return storage.pendingActionCount;
});

final pendingResolutionWinesProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  final storage = ref.watch(offlineStorageServiceProvider);
  return storage.getPendingResolutionWines();
});

final isSyncingStateProvider = StateProvider<bool>((ref) => false);
