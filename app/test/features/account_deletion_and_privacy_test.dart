import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/auth/data/auth_repository.dart';
import 'package:chatmelier/features/monetization/admob_config.dart';
import 'package:chatmelier/features/monetization/admob_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Account Deletion & Store Compliance Tests', () {
    test('AuthRepository.deleteAccount() throws StateError when no user is logged in', () async {
      final client = SupabaseClient('https://example.supabase.co', 'dummy-anon-key');
      final repo = AuthRepository(client);

      expect(
        () async => await repo.deleteAccount(),
        throwsA(isA<StateError>()),
      );
    });

    test('AdMobConfig testDeviceIds list is available and configurable', () {
      expect(AdMobConfig.testDeviceIds, isNotNull);
      AdMobConfig.testDeviceIds.add('TEST_DEVICE_SAMPLE_123');
      expect(AdMobConfig.testDeviceIds.contains('TEST_DEVICE_SAMPLE_123'), isTrue);
      AdMobConfig.testDeviceIds.remove('TEST_DEVICE_SAMPLE_123');
    });

    test('AdMobService isPrivacyOptionsRequired returns false safely in test environment', () async {
      final service = AdMobService();
      final required = await service.isPrivacyOptionsRequired();
      expect(required, isFalse);
    });
  });
}
