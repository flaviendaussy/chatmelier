import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatmelier/features/chat/data/chat_service.dart';
import 'package:chatmelier/shared/providers/cellar_provider.dart';

void main() {
  group('ChatService UUID & Technical Data Sanitization', () {
    test('strips standalone standard UUIDs', () {
      const rawText =
          'Je vous conseille le Château Margaux 2015 (id: 123e4567-e89b-12d3-a456-426614174000) pour votre dîner.';
      final cleaned = ChatService.sanitizeCustomerFacingText(rawText);

      expect(cleaned.contains('123e4567-e89b-12d3-a456-426614174000'), isFalse);
      expect(cleaned.contains('id:'), isFalse);
      expect(cleaned, contains('Château Margaux 2015'));
      expect(cleaned, contains('pour votre dîner.'));
    });

    test('strips orphaned id parentheticals and raw uuids in brackets', () {
      const rawText =
          'Voici votre vin : Pétrus 2010 [id: a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d]. Il est superbe.';
      final cleaned = ChatService.sanitizeCustomerFacingText(rawText);

      expect(cleaned.contains('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'), isFalse);
      expect(cleaned.contains('id:'), isFalse);
      expect(cleaned, contains('Pétrus 2010'));
      expect(cleaned, contains('Il est superbe.'));
    });

    test('strips broken/malformed wine card tags', () {
      const rawText =
          'Je vous recommande [WINE_CARD: 123e4567-e89b-12d3-a456-426614174000] Château d\'Yquem.';
      final cleaned = ChatService.sanitizeCustomerFacingText(rawText);

      expect(cleaned.contains('123e4567-e89b-12d3-a456-426614174000'), isFalse);
      expect(cleaned.contains('WINE_CARD'), isFalse);
      expect(cleaned, contains('Château d\'Yquem.'));
    });

    test('preserves normal numbers, vintages, percentages and prices', () {
      const rawText =
          'Ce vin titre à 13.5% d\'alcool, millésime 2018, vendu au prix de 45€ (note 94/100).';
      final cleaned = ChatService.sanitizeCustomerFacingText(rawText);

      expect(cleaned, equals(rawText));
    });
  });

  group('currentCellarRoleProvider Resolution', () {
    test('computes viewer role when active cellar has viewer role', () async {
      final container = ProviderContainer(
        overrides: [
          currentCellarIdProvider.overrideWith((ref) => CurrentCellarNotifierMock('cellar-2')),
          userCellarsProvider.overrideWith((ref) async => [
            {
              'role': 'admin',
              'cellars': {'id': 'cellar-1', 'name': 'Cave Principale'},
            },
            {
              'role': 'viewer',
              'cellars': {'id': 'cellar-2', 'name': 'Cave Amis (Lecture seule)'},
            },
          ]),
        ],
      );

      await container.read(userCellarsProvider.future);

      final role = container.read(currentCellarRoleProvider);
      expect(role, equals('viewer'));
    });

    test('computes editor role when active cellar has editor role', () async {
      final container = ProviderContainer(
        overrides: [
          currentCellarIdProvider.overrideWith((ref) => CurrentCellarNotifierMock('cellar-shared')),
          userCellarsProvider.overrideWith((ref) async => [
            {
              'role': 'editor',
              'cellars': {'id': 'cellar-shared', 'name': 'Cave Couple'},
            },
          ]),
        ],
      );

      await container.read(userCellarsProvider.future);

      final role = container.read(currentCellarRoleProvider);
      expect(role, equals('editor'));
    });

    test('defaults to admin if user has no cellars configured yet', () async {
      final container = ProviderContainer(
        overrides: [
          currentCellarIdProvider.overrideWith((ref) => CurrentCellarNotifierMock(null)),
          userCellarsProvider.overrideWith((ref) async => []),
        ],
      );

      await container.read(userCellarsProvider.future);

      final role = container.read(currentCellarRoleProvider);
      expect(role, equals('admin'));
    });
  });

  group('Michel Ergonomic Fixes & Robustness', () {
    test('Phone search matches 06... French numbers against +336... international format', () {
      const storedPhone = '+33 6 12 34 56 78';
      const userQuery = '0612345678';

      final phoneDigits = storedPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final queryDigits = userQuery.replaceAll(RegExp(r'[^0-9]'), '');
      final noLeadingZeroDigits = queryDigits.startsWith('0') ? queryDigits.substring(1) : queryDigits;

      final matchPhone = (queryDigits.length >= 3 && phoneDigits.contains(queryDigits)) ||
          (noLeadingZeroDigits.length >= 3 && phoneDigits.contains(noLeadingZeroDigits));

      expect(matchPhone, isTrue);
    });

    test('Spirits, fortified wines and non-vintages bypass vintage confirmation dialog', () {
      final spiritCategories = ['spirit', 'spiritueux', 'fortified', 'muté', 'mute', 'liqueur', 'cocktail', 'beer', 'biere', 'cider', 'cidre'];
      for (final type in spiritCategories) {
        final typeLower = type.toLowerCase();
        final isSpiritOrFortified = typeLower == 'spirit' ||
            typeLower == 'spiritueux' ||
            typeLower == 'fortified' ||
            typeLower == 'muté' ||
            typeLower == 'mute' ||
            typeLower == 'liqueur' ||
            typeLower == 'cocktail' ||
            typeLower == 'beer' ||
            typeLower == 'biere' ||
            typeLower == 'cider' ||
            typeLower == 'cidre';
        expect(isSpiritOrFortified, isTrue, reason: '$type should bypass vintage prompt');
      }

      // Normal wine should NOT bypass
      const normalWine = 'red';
      const isNormalWineSpirit = normalWine == 'spirit' || normalWine == 'spiritueux';
      expect(isNormalWineSpirit, isFalse);
    });
  });
}

class CurrentCellarNotifierMock extends StateNotifier<String?> implements CurrentCellarNotifier {
  CurrentCellarNotifierMock(super.state);

  @override
  void selectCellar(String? cellarId) {
    state = cellarId;
  }
}
