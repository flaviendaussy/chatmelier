import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/shared/providers/premium_provider.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';
import 'package:chatmelier/features/scan/presentation/rewarded_video_ad_sheet.dart';
import 'package:chatmelier/features/monetization/admob_config.dart';
import 'package:chatmelier/features/monetization/admob_service.dart';

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

    testWidgets('RewardedVideoAdSheet renders cleanly without crash in Free Mode', (tester) async {
      bool rewardEarned = false;
      bool cancelled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RewardedVideoAdSheet(
                onRewardEarned: () => rewardEarned = true,
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        ),
      );

      // Verify header, title and progress indicator are present
      expect(find.text('Vidéo Sponsorisée Requise'), findsOneWidget);
      expect(find.text('Analyse IA par Chatmelier'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Verify timer countdown works
      await tester.pump(const Duration(seconds: 2));
      expect(rewardEarned, isFalse);
      expect(cancelled, isFalse);
    });
  });

  group('AdMobConfig & Monetization Tests', () {
    test('Official Google Test Rewarded Ad Unit ID is properly set', () {
      expect(AdMobConfig.testAndroidRewardedUnitId, 'ca-app-pub-3940256099942544/5224354917');
      expect(AdMobConfig.testIosRewardedUnitId, 'ca-app-pub-3940256099942544/1712485313');
    });

    test('AdMobConfig switches to production IDs when useTestAds is false', () {
      AdMobConfig.useTestAds = false;
      AdMobConfig.productionAndroidRewardedUnitId = 'ca-app-pub-1234567890/9876543210';
      expect(AdMobConfig.rewardedAdUnitId, 'ca-app-pub-1234567890/9876543210');

      // Reset
      AdMobConfig.useTestAds = true;
      AdMobConfig.productionAndroidRewardedUnitId = null;
      expect(AdMobConfig.rewardedAdUnitId, AdMobConfig.testAndroidRewardedUnitId);
    });

    test('AdMobService gracefully reports false when not loaded / in mock test environment', () async {
      final service = AdMobService();
      bool rewardEarned = false;
      bool dismissed = false;

      final showed = await service.showRewardedAd(
        onRewardEarned: () => rewardEarned = true,
        onAdDismissed: () => dismissed = true,
      );

      // In unit test environment without real native ad, showed must be false to allow fallback
      expect(showed, isFalse);
      expect(rewardEarned, isFalse);
      expect(dismissed, isFalse);
    });
  });
}
