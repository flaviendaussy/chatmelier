import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocalePrefKey = 'user_selected_locale';

/// Supported language codes in Chatmelier
const kSupportedLanguageCodes = [
  'fr',
  'en',
  'it',
  'es',
  'ca',
  'pt',
  'nl',
  'de',
  'ja',
  'zh',
  'ko',
  'sv',
];

/// Manages app locale state:
/// - null: follows the user's phone / device system language
/// - explicit Locale(code): forces the user-selected language across the entire app
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_kLocalePrefKey);
      if (savedCode != null && savedCode.isNotEmpty && savedCode != 'system') {
        if (kSupportedLanguageCodes.contains(savedCode)) {
          state = Locale(savedCode);
          return;
        }
      }
      // If null or 'system', leave state as null so MaterialApp automatically uses device locale
      state = null;
    } catch (_) {
      state = null;
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
