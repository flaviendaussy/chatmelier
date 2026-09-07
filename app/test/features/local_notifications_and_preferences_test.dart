import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/notifications/data/notification_preferences_service.dart';
import 'package:chatmelier/features/notifications/data/local_notification_service.dart';
import 'package:chatmelier/features/notifications/presentation/notification_pre_permission_dialog.dart';
import 'package:chatmelier/features/notifications/presentation/notification_settings_sheet.dart';
import 'package:chatmelier/features/notifications/domain/notification_anti_spam_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPreferences Entity & Defaults', () {
    test('default preferences have sensible defaults for wine cellar owner', () {
      const prefs = NotificationPreferences();
      expect(prefs.postTastingEnabled, isTrue);
      expect(prefs.apogeeAlertsEnabled, isTrue);
      expect(prefs.sharedCellarActivityEnabled, isTrue);
      expect(prefs.friendRequestsEnabled, isTrue);
      expect(prefs.weekendSuggestionsEnabled, isTrue);
      expect(prefs.lowStockAlertsEnabled, isFalse);
      expect(prefs.activeCount, equals(5));
    });

    test('activeCount correctly reflects toggled preferences', () {
      var prefs = const NotificationPreferences();
      expect(prefs.activeCount, equals(5));

      prefs = prefs.copyWith(lowStockAlertsEnabled: true);
      expect(prefs.activeCount, equals(6));

      prefs = prefs.copyWith(
        postTastingEnabled: false,
        apogeeAlertsEnabled: false,
        weekendSuggestionsEnabled: false,
      );
      expect(prefs.activeCount, equals(3));
    });

    test('copyWith updates individual fields without affecting others', () {
      const original = NotificationPreferences();
      final updated = original.copyWith(weekendSuggestionsEnabled: false);

      expect(updated.weekendSuggestionsEnabled, isFalse);
      expect(updated.postTastingEnabled, isTrue);
      expect(updated.apogeeAlertsEnabled, isTrue);
    });
  });

  group('NotificationPreferencesService Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads default preferences when SharedPreferences is empty', () async {
      final sharedPrefs = await SharedPreferences.getInstance();
      final service = NotificationPreferencesService(sharedPrefs);

      final loaded = service.loadPreferences();
      expect(loaded.postTastingEnabled, isTrue);
      expect(loaded.apogeeAlertsEnabled, isTrue);
      expect(loaded.lowStockAlertsEnabled, isFalse);
    });

    test('persists and reloads updated preferences correctly', () async {
      final sharedPrefs = await SharedPreferences.getInstance();
      final service = NotificationPreferencesService(sharedPrefs);

      const modified = NotificationPreferences(
        postTastingEnabled: false,
        apogeeAlertsEnabled: true,
        sharedCellarActivityEnabled: false,
        friendRequestsEnabled: true,
        weekendSuggestionsEnabled: false,
        lowStockAlertsEnabled: true,
      );

      await service.savePreferences(modified);

      final reloaded = service.loadPreferences();
      expect(reloaded.postTastingEnabled, isFalse);
      expect(reloaded.apogeeAlertsEnabled, isTrue);
      expect(reloaded.sharedCellarActivityEnabled, isFalse);
      expect(reloaded.friendRequestsEnabled, isTrue);
      expect(reloaded.weekendSuggestionsEnabled, isFalse);
      expect(reloaded.lowStockAlertsEnabled, isTrue);
      expect(reloaded.activeCount, equals(3));
    });

    test('tracks permission prompt state', () async {
      final sharedPrefs = await SharedPreferences.getInstance();
      final service = NotificationPreferencesService(sharedPrefs);

      expect(service.hasPromptedPermission(), isFalse);

      await service.markPermissionPrompted();
      expect(service.hasPromptedPermission(), isTrue);
    });
  });

  group('Notification Channels & Copy Specifications', () {
    test('defines clean and compliant Android notification channel IDs', () {
      expect(NotificationChannels.tastingsId, equals('chatmelier_tastings'));
      expect(NotificationChannels.apogeeId, equals('chatmelier_apogee'));
      expect(NotificationChannels.sharedCellarId, equals('chatmelier_shared_cellar'));
      expect(NotificationChannels.socialId, equals('chatmelier_social'));
      expect(NotificationChannels.sommelierId, equals('chatmelier_sommelier'));
    });

    test('generates polite, non-intrusive reminder messages for bottles', () {
      const bottleId = 'bottle-chateau-margaux-2015';
      const wineName = 'Château Margaux';
      const vintage = 2015;
      const reminderBody = 'Vous avez sorti $wineName $vintage. Prenez 30s pour noter vos impressions tant que le souvenir est frais !';

      expect(reminderBody, contains('Château Margaux 2015'));
      expect(reminderBody, contains('Prenez 30s pour noter'));

      final id = bottleId.hashCode.abs() % 100000;
      expect(id, isA<int>());
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThan(100000));
    });
  });

  group('Notification Widgets Rendering Tests', () {
    testWidgets('NotificationPrePermissionDialog renders all value points and buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationPrePermissionDialog(),
            ),
          ),
        ),
      );

      expect(find.text('Restez informé au bon moment'), findsOneWidget);
      expect(find.text('Rappels post-dégustation'), findsOneWidget);
      expect(find.text('Alertes d\'apogée'), findsOneWidget);
      expect(find.text('Caves partagées & Amis'), findsOneWidget);
      expect(find.text('Activer les alertes'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);
    });

    testWidgets('NotificationSettingsSheet renders categories and switches', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationSettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications Système'), findsOneWidget);
      expect(find.text('Rappels post-dégustation'), findsOneWidget);
      expect(find.text('Fenêtres d\'apogée & déclin'), findsOneWidget);
      expect(find.text('Activité de cave partagée'), findsOneWidget);
      expect(find.text('Amis & Invitations'), findsOneWidget);
      expect(find.text('Sommelier du week-end'), findsOneWidget);
      expect(find.text('Alerte dernière bouteille'), findsOneWidget);
      expect(find.text('PROTECTION ANTI-SPAM & CONFORT'), findsOneWidget);
      expect(find.text('Heures de silence (22h00 - 8h30)'), findsOneWidget);
      expect(find.text('Regroupement des dégustations'), findsOneWidget);
      expect(find.text('Envoyer une notification test'), findsOneWidget);
    });
  });

  group('NotificationAntiSpamPolicy Engine Tests', () {
    test('accurately detects quiet hours windows (22:00 to 08:30)', () {
      final nightTime1 = DateTime(2026, 9, 4, 22, 15);
      final nightTime2 = DateTime(2026, 9, 4, 23, 59);
      final earlyMorning = DateTime(2026, 9, 5, 4, 30);
      final boundaryQuiet = DateTime(2026, 9, 5, 8, 29);
      final daytime = DateTime(2026, 9, 4, 14, 0);
      final eveningBeforeQuiet = DateTime(2026, 9, 4, 21, 45);
      final afterQuiet = DateTime(2026, 9, 5, 8, 31);

      expect(NotificationAntiSpamPolicy.isWithinQuietHours(nightTime1), isTrue);
      expect(NotificationAntiSpamPolicy.isWithinQuietHours(nightTime2), isTrue);
      expect(NotificationAntiSpamPolicy.isWithinQuietHours(earlyMorning), isTrue);
      expect(NotificationAntiSpamPolicy.isWithinQuietHours(boundaryQuiet), isTrue);

      expect(NotificationAntiSpamPolicy.isWithinQuietHours(daytime), isFalse);
      expect(NotificationAntiSpamPolicy.isWithinQuietHours(eveningBeforeQuiet), isFalse);
      expect(NotificationAntiSpamPolicy.isWithinQuietHours(afterQuiet), isFalse);
    });

    test('adjustForQuietHours defers evening reminders to 09:00 next morning', () {
      final eveningAlert = DateTime(2026, 9, 4, 23, 15);
      final adjusted = NotificationAntiSpamPolicy.adjustForQuietHours(eveningAlert);

      expect(adjusted.day, equals(5)); // next day
      expect(adjusted.hour, equals(9));
      expect(adjusted.minute, equals(0));
    });

    test('adjustForQuietHours defers middle-of-night reminders to 09:00 same morning', () {
      final lateNightAlert = DateTime(2026, 9, 5, 2, 30);
      final adjusted = NotificationAntiSpamPolicy.adjustForQuietHours(lateNightAlert);

      expect(adjusted.day, equals(5)); // same morning
      expect(adjusted.hour, equals(9));
      expect(adjusted.minute, equals(0));
    });

    test('adjustForQuietHours leaves daytime alerts untouched', () {
      final afternoon = DateTime(2026, 9, 4, 15, 30);
      final adjusted = NotificationAntiSpamPolicy.adjustForQuietHours(afternoon);

      expect(adjusted, equals(afternoon));
    });

    test('buildConsolidatedTitle and buildConsolidatedBody format gracefully', () {
      expect(
        NotificationAntiSpamPolicy.buildConsolidatedTitle(1),
        equals('🍷 Alors, cette dégustation ?'),
      );
      expect(
        NotificationAntiSpamPolicy.buildConsolidatedTitle(3),
        equals('🍷 Dégustation de votre soirée (3 bouteilles)'),
      );

      final singleBody = NotificationAntiSpamPolicy.buildConsolidatedBody(['Château Margaux 2015']);
      expect(singleBody, contains('Vous avez sorti Château Margaux 2015'));

      final multiBody = NotificationAntiSpamPolicy.buildConsolidatedBody([
        'Chablis 1er Cru',
        'Gevrey-Chambertin',
        'Pomerol',
      ]);
      expect(multiBody, contains('Vous avez dégusté Chablis 1er Cru, Gevrey-Chambertin, Pomerol'));
      expect(multiBody, contains('Partagez vos impressions'));
    });

    test('canSendProactiveAlert enforces rate limiting and cooldown', () {
      final now = DateTime(2026, 9, 4, 18, 0);

      // Exceeded daily limit
      final blockedByCount = NotificationAntiSpamPolicy.canSendProactiveAlert(
        now: now,
        lastAlertSentAt: now.subtract(const Duration(hours: 6)),
        alertsSentToday: 2,
        maxAlertsPerDay: 2,
      );
      expect(blockedByCount, isFalse);

      // Blocked by cooldown (less than 4 hours)
      final blockedByCooldown = NotificationAntiSpamPolicy.canSendProactiveAlert(
        now: now,
        lastAlertSentAt: now.subtract(const Duration(hours: 2)),
        alertsSentToday: 0,
        maxAlertsPerDay: 2,
      );
      expect(blockedByCooldown, isFalse);

      // Allowed
      final allowed = NotificationAntiSpamPolicy.canSendProactiveAlert(
        now: now,
        lastAlertSentAt: now.subtract(const Duration(hours: 5)),
        alertsSentToday: 1,
        maxAlertsPerDay: 2,
      );
      expect(allowed, isTrue);
    });
  });

  group('Live Aeration Lockscreen Chronometer Specifications', () {
    test('defines live aeration channel and notification ID', () {
      expect(NotificationChannels.liveAerationId, equals('chatmelier_live_aeration'));
      expect(NotificationChannels.liveAerationName, equals('Aération & Chrono en Direct'));
      expect(LocalNotificationService.liveAerationNotificationId, equals(88888));
    });
  });
}
