import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../presentation/sync_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';

class ConnectivityService {
  final Ref _ref;
  Timer? _timer;
  bool _isChecking = false;
  bool _isAutoSyncing = false;

  ConnectivityService(this._ref);

  void startMonitoring() {
    _check();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<bool> checkConnection() async {
    return _check();
  }

  Future<bool> _check() async {
    if (_isChecking) return _ref.read(isOnlineProvider);
    _isChecking = true;

    try {
      // Light probe to 1.1.1.1 or Google DNS
      final response = await http
          .get(Uri.parse('https://1.1.1.1/cdn-cgi/trace'))
          .timeout(const Duration(seconds: 4));
      final online = response.statusCode == 200;
      _ref.read(isOnlineProvider.notifier).state = online;

      if (online) {
        _triggerAutoSyncIfPending();
      }

      return online;
    } catch (_) {
      // If probe fails, fallback offline
      _ref.read(isOnlineProvider.notifier).state = false;
      return false;
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _triggerAutoSyncIfPending() async {
    if (_isAutoSyncing) return;

    final storage = _ref.read(offlineStorageServiceProvider);
    if (storage.pendingActionCount == 0) return;

    final supabase = _ref.read(supabaseProvider);
    if (supabase.auth.currentUser == null) return;

    _isAutoSyncing = true;
    try {
      _ref.read(isSyncingStateProvider.notifier).state = true;
      final syncService = _ref.read(syncServiceProvider);
      final result = await syncService.processPendingActions();

      _ref.read(pendingSyncCountProvider.notifier).state = storage.pendingActionCount;
      _ref.read(pendingResolutionWinesProvider.notifier).state = storage.getPendingResolutionWines();

      if (result.succeeded > 0) {
        _ref.invalidate(userCellarsProvider);
        final currentCellarId = _ref.read(currentCellarIdProvider);
        if (currentCellarId != null) {
          _ref.invalidate(bottlesProvider(currentCellarId));
        }
      }
    } catch (_) {
    } finally {
      _ref.read(isSyncingStateProvider.notifier).state = false;
      _isAutoSyncing = false;
    }
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService(ref);
  service.startMonitoring();
  ref.onDispose(() => service.stopMonitoring());
  return service;
});
