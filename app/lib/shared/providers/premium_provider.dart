import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's Premium subscription status with local persistence.
/// In debug/test phase, this can be toggled without restrictions.
class PremiumNotifier extends StateNotifier<bool> {
  static const _prefKey = 'chatmelier_is_premium_mode';

  PremiumNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      state = false;
    }
  }

  Future<void> setPremium(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  Future<void> togglePremium() async {
    await setPremium(!state);
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
