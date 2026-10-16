import '../../../shared/utils/app_logger.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../presentation/sync_provider.dart';
import '../../../config/constants.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';

class ConnectivityService {
  final Ref _ref;
  Timer? _timer;
  Timer? _offlineDebounceTimer;
  bool _isChecking = false;
  bool _isAutoSyncing = false;

  ConnectivityService(this._ref);

  /// Ce que l'app doit joindre : son serveur, d'abord. Le 15/10, Pascal (iPhone, en Wi-Fi)
  /// voyait « Mode Hors-Ligne » au scan pendant que ses bouteilles partaient en ligne : la
  /// seule sonde, 1.1.1.1 de Cloudflare, est bloquée sur bien des réseaux (filtres, box,
  /// entreprises). Toute réponse du serveur, même un refus, dit que le réseau passe ;
  /// Cloudflare et Google ne sont qu'un second avis.
  static final List<Uri> sondes = [
    Uri.parse('${AppConstants.supabaseUrl}/auth/v1/health'),
    Uri.parse('https://1.1.1.1/cdn-cgi/trace'),
    Uri.parse('https://www.google.com/generate_204'),
  ];

  /// Vrai dès qu'une sonde répond, quelle que soit sa réponse ; faux si aucune ne répond
  /// avant [delai]. Les sondes partent ensemble : hors ligne, on attend une fois [delai].
  static Future<bool> joignable({Duration delai = const Duration(seconds: 4), http.Client? client}) {
    final fin = Completer<bool>();
    final c = client ?? http.Client();
    var echecs = 0;
    for (final sonde in sondes) {
      c.head(sonde).timeout(delai).then((_) {
        if (!fin.isCompleted) fin.complete(true);
      }, onError: (_) {
        if (++echecs == sondes.length && !fin.isCompleted) fin.complete(false);
      });
    }
    return fin.future.whenComplete(() {
      if (client == null) c.close();
    });
  }

  void startMonitoring() {
    _check();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = null;
  }

  Future<bool> checkConnection() async {
    return _check();
  }

  Future<bool> _check() async {
    if (_isChecking) return _ref.read(isOnlineProvider);
    _isChecking = true;

    try {
      final online = await joignable();

      if (online) {
        _handleOnline();
      } else {
        _handleOfflineCandidate();
      }

      return online;
    } catch (_) {
      // If probe fails, candidate for offline (debounced)
      _handleOfflineCandidate();
      return _ref.read(isOnlineProvider);
    } finally {
      _isChecking = false;
    }
  }

  void _handleOnline() {
    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = null;
    if (!_ref.read(isOnlineProvider)) {
      AppLogger.info('CONNECTIVITE', 'De nouveau en ligne');
      _ref.read(isOnlineProvider.notifier).state = true;
    }
    _triggerAutoSyncIfPending();
  }

  void _handleOfflineCandidate() {
    // If already officially offline, nothing to debounce
    if (!_ref.read(isOnlineProvider)) return;

    // If a debounce countdown is already active, don't restart it
    if (_offlineDebounceTimer != null && _offlineDebounceTimer!.isActive) return;

    // Wait 5s before officially dropping into offline mode
    // Prevents false offline triggers when switching apps or on momentary network hiccup
    _offlineDebounceTimer = Timer(const Duration(seconds: 5), () async {
      if (await joignable(delai: const Duration(seconds: 3))) {
        _handleOnline();
        return;
      }

      // Toujours rien après 5 secondes : hors ligne, et le journal dit pourquoi (le 15/10,
      // rien ne permettait de savoir d'où venait le « Mode Hors-Ligne » de Pascal).
      AppLogger.warning('CONNECTIVITE', 'Hors ligne : ni le serveur, ni Cloudflare, ni Google ne répondent');
      _ref.read(isOnlineProvider.notifier).state = false;
    });
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
