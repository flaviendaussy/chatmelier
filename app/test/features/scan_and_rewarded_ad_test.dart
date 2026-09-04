import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/shared/providers/premium_provider.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';
import 'package:chatmelier/features/scan/presentation/rewarded_video_ad_sheet.dart';

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
}
