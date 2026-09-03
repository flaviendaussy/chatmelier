import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/shared/providers/premium_provider.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Free Mode Scan & Rewarded Video Ad Enforcement', () {
    test('Default mode is Free (isPremium == false), requiring rewarded video ad for every scan', () {
      final container = ProviderContainer();
      final isPremium = container.read(premiumProvider);

      expect(isPremium, isFalse, reason: 'Zero gratuité: free mode must mandate ad view');
    });

    test('When switched to Premium mode, isPremium becomes true, bypassing ads', () async {
      final container = ProviderContainer();
      final notifier = container.read(premiumProvider.notifier);

      await notifier.setPremium(true);
      expect(container.read(premiumProvider), isTrue, reason: 'Premium users bypass ads completely');

      await notifier.setPremium(false);
      expect(container.read(premiumProvider), isFalse, reason: 'Toggling back enforces ad view');
    });
  });

  group('OfflineAction retryCount & Sync Resilience', () {
    test('OfflineAction tracks retryCount and serializes properly', () {
      final action = OfflineAction(
        type: OfflineActionType.addBottle,
        data: {'name': 'Château Margaux', 'vintage': 2015},
      );

      expect(action.retryCount, 0);

      final updated = action.copyWith(
        status: OfflineActionStatus.failed,
        errorMessage: 'Network timeout',
        retryCount: action.retryCount + 1,
      );

      expect(updated.retryCount, 1);
      expect(updated.status, OfflineActionStatus.failed);
      expect(updated.errorMessage, 'Network timeout');

      final json = updated.toJson();
      expect(json['retry_count'], 1);

      final restored = OfflineAction.fromJson(json);
      expect(restored.retryCount, 1);
      expect(restored.errorMessage, 'Network timeout');
    });

    test('syncBannerDismissedProvider defaults to false and can be dismissed', () {
      final container = ProviderContainer();
      expect(container.read(syncBannerDismissedProvider), isFalse);

      container.read(syncBannerDismissedProvider.notifier).state = true;
      expect(container.read(syncBannerDismissedProvider), isTrue);
    });
  });
}
