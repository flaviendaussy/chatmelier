import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocalePrefKey = 'user_selected_locale';

/// Manages app locale state: defaults to French (Locale('fr')), unless explicitly changed
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(const Locale('fr')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_kLocalePrefKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        if (savedCode == 'fr' || savedCode == 'en') {
          state = Locale(savedCode);
        }
      } else {
        state = const Locale('fr');
      }
    } catch (_) {
      state = const Locale('fr');
    }
  }

  Future<void> setLocale(Locale? newLocale) async {
    state = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (newLocale == null) {
        await prefs.remove(_kLocalePrefKey);
      } else {
        await prefs.setString(_kLocalePrefKey, newLocale.languageCode);
      }
    } catch (_) {}
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});
