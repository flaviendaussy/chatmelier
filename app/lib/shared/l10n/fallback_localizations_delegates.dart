import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../l10n/app_localizations.dart';

/// Fallback Material localizations delegate for locales not natively supported
/// by Flutter's GlobalMaterialLocalizations (e.g. Latin 'la').
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'la' ||
      !GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

/// Fallback Cupertino localizations delegate for locales not natively supported
/// by Flutter's GlobalCupertinoLocalizations (e.g. Latin 'la').
class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'la' ||
      !GlobalCupertinoLocalizations.delegate.isSupported(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

/// Fallback Widgets localizations delegate for locales not natively supported
/// by Flutter's GlobalWidgetsLocalizations (e.g. Latin 'la').
class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'la' ||
      !GlobalWidgetsLocalizations.delegate.isSupported(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return GlobalWidgetsLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}

/// Full list of fallback delegates for custom languages (like Latin).
const List<LocalizationsDelegate<dynamic>> kFallbackLocalizationsDelegates = [
  FallbackMaterialLocalizationsDelegate(),
  FallbackCupertinoLocalizationsDelegate(),
  FallbackWidgetsLocalizationsDelegate(),
];

/// Complete list of delegates to provide to MaterialApp:
/// Includes AppLocalizations.delegate, fallbacks for non-system locales (e.g. Latin),
/// and Flutter's global delegates.
const List<LocalizationsDelegate<dynamic>> kAppLocalizationsDelegates = [
  AppLocalizations.delegate,
  FallbackMaterialLocalizationsDelegate(),
  FallbackCupertinoLocalizationsDelegate(),
  FallbackWidgetsLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

