import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocalePrefKey = 'user_selected_locale';

/// Une langue proposée dans l'app : son code et son nom dans cette langue.
class LangueProposee {
  final String code;
  final String nom;
  const LangueProposee(this.code, this.nom);
}

/// Les langues de l'app. En ajouter une : son catalogue (`tool/langues`), son `.arb`
/// (ramené de `l10n_plus_tard/`), puis une ligne ici et dans `Langue.supportees`.
const kLangues = [
  LangueProposee('fr', 'Français 🇫🇷'),
  LangueProposee('en', 'English 🇬🇧'),
  LangueProposee('es', 'Español 🇪🇸'),
];

final kSupportedLanguageCodes = [for (final l in kLangues) l.code];

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
