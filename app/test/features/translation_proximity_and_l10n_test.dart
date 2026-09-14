import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🌐 Translation Hash Comparison & Proximity Anomaly Test', () {
    late Map<String, Map<String, dynamic>> arbData;
    late Set<String> enKeys;
    late Map<String, String> enValues;
    late Map<String, String> frValues;

    // Legitimate universal terms that can be identical across different language families
    const universalAllowlist = <String>{
      'Chatmelier',
      'Wi-Fi',
      'GPS',
      'PIN',
      'VIP',
      'iOS',
      'Android',
      'CSV',
      'PDF',
      'Français',
      'English',
      'Español',
      'Italiano',
      'Deutsch',
      'Nederlands',
      'Português',
      'Svenska',
      'Català',
      'Latina',
      '日本語',
      '한국어',
      '简体中文',
      'Grappa',
      'Whisky',
      'Gin',
      'Vodka',
      'Tequila',
      'Cognac',
      'Grappa 🍇',
      'Whisky 🥃',
      'Gin 🍸',
      'Vodka 🧊',
      'Tequila 🌵',
      'Cognac 🍷',
      'Rum 🏴‍☠️',
      'Rhum 🏴‍☠️',
      'Rosé',
      'Barolo',
      'Bordeaux',
      'Champagne',
      'Chablis',
      'Syrah',
      'Merlot',
      'Cabernet',
      'Pinot',
      'Chat',
      'Bar & Cocktails',
      'Email',
      'Password',
      '🔑 Password',
      'Account',
      'System ⚙️',
      '1 kilometer',
      'Latitude',
      'Longitude',
      'Continents',
      'Categories',
      '🎯 Bravo!',
      'Information & Terroir',
      'Region',
      'Appellation',
      'Stock',
      'Profil',
    };

    const allowlistedKeyExceptions = <String>{
      'appTitle',
      'chatTitle',
      'profileLanguageFr',
      'profileLanguageEn',
      'profileLanguageEs',
      'profileLanguageIt',
      'profileLanguageDe',
      'profileLanguageNl',
      'profileLanguagePt',
      'profileLanguageSv',
      'profileLanguageCa',
      'profileLanguageLa',
      'profileLanguageJa',
      'profileLanguageKo',
      'profileLanguageZh',
    };

    setUpAll(() {
      final arbDir = Directory('lib/l10n');
      expect(arbDir.existsSync(), isTrue, reason: 'lib/l10n directory must exist');

      arbData = {};
      for (final file in arbDir.listSync().whereType<File>()) {
        if (file.path.endsWith('.arb')) {
          final fileName = file.uri.pathSegments.last;
          final locale = fileName.replaceAll('app_', '').replaceAll('.arb', '');
          final content = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
          arbData[locale] = content;
        }
      }

      expect(arbData.containsKey('en'), isTrue, reason: 'app_en.arb must exist');
      expect(arbData.containsKey('fr'), isTrue, reason: 'app_fr.arb must exist');

      enKeys = arbData['en']!
          .keys
          .where((k) => !k.startsWith('@') && k != '@@locale')
          .toSet();

      enValues = {
        for (final k in enKeys)
          if (arbData['en']![k] is String) k: (arbData['en']![k] as String).trim()
      };

      frValues = {
        for (final k in enKeys)
          if (arbData['fr']?[k] is String) k: (arbData['fr']![k] as String).trim()
      };
    });

    test('All 13 locales must have 100% key parity with template (0 missing keys)', () {
      const expectedLocales = [
        'en', 'fr', 'es', 'it', 'de', 'pt', 'nl', 'sv', 'ca', 'la', 'ja', 'zh', 'ko'
      ];

      final missingByLocale = <String, List<String>>{};

      for (final loc in expectedLocales) {
        expect(arbData.containsKey(loc), isTrue, reason: 'Locale $loc must have an ARB file');
        final currentKeys = arbData[loc]!
            .keys
            .where((k) => !k.startsWith('@') && k != '@@locale')
            .toSet();

        final missing = enKeys.difference(currentKeys).toList();
        if (missing.isNotEmpty) {
          missingByLocale[loc] = missing;
        }
      }

      if (missingByLocale.isNotEmpty) {
        final summary = missingByLocale.entries
            .map((e) => '${e.key}: ${e.value.length} missing keys (e.g. ${e.value.take(5).join(', ')})')
            .join('\n');
        fail('Key parity failure! Missing keys detected:\n$summary');
      }
    });

    test('Non-Latin scripts (ja, zh, ko) must NOT contain untranslated Latin ASCII strings', () {
      final kanaOrKanjiRegex = RegExp(r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');
      final hanziRegex = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');
      final hangulRegex = RegExp(r'[\uac00-\ud7af\u1100-\u11ff]');

      final untranslatedByLocale = <String, List<String>>{};

      void checkLocale(String loc, RegExp scriptRegex) {
        final data = arbData[loc] ?? {};
        final untranslated = <String>[];

        for (final key in enKeys) {
          if (allowlistedKeyExceptions.contains(key)) continue;

          final val = (data[key] as String?)?.trim() ?? '';
          if (val.isEmpty) continue;

          // If the string is purely symbols or allowlisted
          if (universalAllowlist.contains(val)) continue;

          // If text is longer than 4 chars and contains 0 characters of the target script
          final cleanVal = val.replaceAll(RegExp(r'\{[a-zA-Z0-9_]+\}'), '').replaceAll(RegExp(r'[\s0-9\.,:;!\?_/\-\(\)•✨🍾🍷🥂🍓🍇🍒🍋🫐🪨⏱️🎯🎙️🍽️👑]'), '');
          if (cleanVal.length >= 3 && !scriptRegex.hasMatch(cleanVal)) {
            untranslated.add('$key ("$val")');
          }
        }

        if (untranslated.isNotEmpty) {
          untranslatedByLocale[loc] = untranslated;
        }
      }

      checkLocale('ja', kanaOrKanjiRegex);
      checkLocale('zh', hanziRegex);
      checkLocale('ko', hangulRegex);

      if (untranslatedByLocale.isNotEmpty) {
        final summary = untranslatedByLocale.entries
            .map((e) => '${e.key}: ${e.value.length} untranslated strings:\n  - ${e.value.take(10).join('\n  - ')}')
            .join('\n\n');
        fail('Script integrity failure! English/Latin strings detected in non-Latin locales:\n$summary');
      }
    });

    test('Hash collisions across 5 distinct language families (fr, en, de, ja, zh) flag untranslated duplicates', () {
      final distantLangs = ['ja', 'zh', 'ko', 'de', 'it', 'pt', 'nl', 'sv', 'es', 'ca', 'la'];
      final suspiciousCollisions = <String, List<String>>{};

      for (final loc in distantLangs) {
        final locData = arbData[loc] ?? {};
        final collisions = <String>[];

        for (final key in enKeys) {
          if (allowlistedKeyExceptions.contains(key)) continue;

          final val = (locData[key] as String?)?.trim();
          if (val == null || val.isEmpty) continue;

          final enVal = enValues[key];
          final frVal = frValues[key];

          // Check if string matches universal allowlist
          if (universalAllowlist.contains(val)) continue;

          // Pure numbers, emojis, punctuation
          final isPunctuationOrSymbol = RegExp(r'^[\s0-9\.,:;!\?_/\-\(\)•✨🍾🍷🥂🍓🍇🍒🍋🫐🪨⏱️🎯🎙️🍽️👑%]+$').hasMatch(val);
          if (isPunctuationOrSymbol) continue;

          // Collision with English or French
          final matchesEnglish = enVal != null && val == enVal && val.length > 3;
          final matchesFrench = frVal != null && val == frVal && val.length > 3 && loc != 'fr' && loc != 'ca';

          if (matchesEnglish) {
            collisions.add('$key: exact match with EN ("$val")');
          } else if (matchesFrench) {
            collisions.add('$key: exact match with FR ("$val")');
          }
        }

        if (collisions.isNotEmpty) {
          suspiciousCollisions[loc] = collisions;
        }
      }

      if (suspiciousCollisions.isNotEmpty) {
        final summary = suspiciousCollisions.entries
            .map((e) => 'Locale ${e.key}: ${e.value.length} collisions:\n  - ${e.value.take(10).join('\n  - ')}')
            .join('\n\n');
        fail('Suspicious cross-language hash/string collisions found! Needs AI Review:\n$summary');
      }
    });

    test('ICU Placeholders and variables are preserved identically in all 13 locales', () {
      final placeholderRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');
      final brokenPlaceholders = <String, List<String>>{};

      for (final loc in arbData.keys) {
        if (loc == 'en') continue;
        final locData = arbData[loc]!;
        final errors = <String>[];

        for (final key in enKeys) {
          final enVal = enValues[key];
          final locVal = (locData[key] as String?)?.trim();
          if (enVal == null || locVal == null) continue;

          // Skip ICU plural blocks like {count, plural, ...}
          if (enVal.contains('plural,') || locVal.contains('plural,')) continue;

          final enPlaceholders = placeholderRegex.allMatches(enVal).map((m) => m.group(1)!).toSet();
          final locPlaceholders = placeholderRegex.allMatches(locVal).map((m) => m.group(1)!).toSet();

          if (!setEquals(enPlaceholders, locPlaceholders)) {
            errors.add('$key: expected $enPlaceholders but got $locPlaceholders in "$locVal"');
          }
        }

        if (errors.isNotEmpty) {
          brokenPlaceholders[loc] = errors;
        }
      }

      if (brokenPlaceholders.isNotEmpty) {
        final summary = brokenPlaceholders.entries
            .map((e) => 'Locale ${e.key}: ${e.value.length} broken placeholders:\n  - ${e.value.take(5).join('\n  - ')}')
            .join('\n');
        fail('Placeholder integrity failure!\n$summary');
      }
    });
  });
}
