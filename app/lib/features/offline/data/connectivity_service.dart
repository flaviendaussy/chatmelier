import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../presentation/sync_provider.dart';

class ConnectivityService {
  final Ref _ref;
  Timer? _timer;
  bool _isChecking = false;

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
      return online;
    } catch (_) {
      // If probe fails, check Supabase or fallback offline
      _ref.read(isOnlineProvider.notifier).state = false;
      return false;
    } finally {
      _isChecking = false;
    }
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService(ref);
  service.startMonitoring();
  ref.onDispose(() => service.stopMonitoring());
  return service;
});
