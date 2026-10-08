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

    // Français, anglais, espagnol depuis la V2.3 (H6), italien depuis le 08/10. Les autres
    // `.arb` attendent dans `l10n_plus_tard/`, hors génération : ils ne sont plus tenus à jour
    // ni vérifiés ici.
    test('Les quatre langues de l\'app ont toutes les clés du modèle', () {
      const expectedLocales = ['en', 'fr', 'es', 'it'];
      expect(arbData.keys.toSet(), expectedLocales.toSet(),
          reason: 'lib/l10n ne contient que les langues de l\'app');

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

    test('L\'espagnol et l\'italien ne recopient ni l\'anglais ni le français', () {
      final distantLangs = ['es', 'it'];
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

    test('ICU Placeholders and variables are preserved identically in every language', () {
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
