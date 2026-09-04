import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/friends/data/friends_repository.dart';
import 'package:chatmelier/features/friends/domain/friend.dart';
import 'package:chatmelier/features/friends/domain/cellar_access_request.dart';
import 'package:chatmelier/features/friends/domain/user_notification.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/notifications/presentation/notifications_inbox_sheet.dart';
import 'package:chatmelier/shared/widgets/notification_bell_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Friends & Notifications Providers Tests', () {
    test('Unread notifications count calculates total and excludes dismissed', () async {
      final container = ProviderContainer(
        overrides: [
          pendingIncomingRequestsProvider.overrideWith(
            (ref) => Future.value([
              const Friend(
                id: 'req-caro-1',
                friendUserId: 'user-caro',
                displayName: 'Caro',
                username: 'caro',
                tasteProfile: TasteProfile(id: 'user-caro', name: 'Caro'),
                status: 'pending',
              ),
            ]),
          ),
          incomingCellarRequestsProvider.overrideWith(
            (ref) => Future.value([
              CellarAccessRequest(
                id: 'cellar-req-caro-1',
                cellarId: 'cellar-1',
                ownerId: 'my-user-id',
                requesterId: 'user-caro',
                requesterName: 'Caro',
                requesterUsername: 'caro',
                createdAt: DateTime.now(),
              ),
            ]),
          ),
          userNotificationsProvider.overrideWith(
            (ref) => Future.value([
              UserNotification(
                id: 'notif-1',
                userId: 'my-user-id',
                type: 'cellar_granted',
                title: 'Nouveau partage',
                body: 'Caro a partagé sa cave',
                isRead: false,
                createdAt: DateTime.now(),
              ),
              UserNotification(
                id: 'notif-2',
                userId: 'my-user-id',
                type: 'system',
                title: 'Lu',
                body: 'Déjà lu',
                isRead: true,
                createdAt: DateTime.now(),
              ),
            ]),
          ),
        ],
      );

      addTearDown(container.dispose);

      // Await future providers to populate the cache
      await container.read(pendingIncomingRequestsProvider.future);
      await container.read(incomingCellarRequestsProvider.future);
      await container.read(userNotificationsProvider.future);

      final count = container.read(unreadNotificationsCountProvider);
      expect(count, equals(3));

      // Dismiss one item for later ("Pour plus tard")
      await container.read(dismissedNotificationIdsProvider.notifier).dismiss('req-caro-1');
      final newCount = container.read(unreadNotificationsCountProvider);
      expect(newCount, equals(2));

      // Clear dismissed items
      await container.read(dismissedNotificationIdsProvider.notifier).clearAll();
      final restoredCount = container.read(unreadNotificationsCountProvider);
      expect(restoredCount, equals(3));
    });
  });

  group('NotificationBellButton Widget Tests', () {
    testWidgets('NotificationBellButton displays badge when count > 0', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pendingIncomingRequestsProvider.overrideWith(
            (ref) => Future.value([
              const Friend(
                id: 'req-caro-1',
                friendUserId: 'user-caro',
                displayName: 'Caro',
                username: 'caro',
                tasteProfile: TasteProfile(id: 'user-caro', name: 'Caro'),
                status: 'pending',
              ),
            ]),
          ),
          incomingCellarRequestsProvider.overrideWith((ref) => Future.value([])),
          userNotificationsProvider.overrideWith((ref) => Future.value([])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: AppBar(
                  actions: const [
                    NotificationBellButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NotificationBellButton), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      container.dispose();
    });
  });

  group('NotificationsInboxSheet Widget Tests', () {
    testWidgets('NotificationsInboxSheet renders sections and handles dismiss for later', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pendingIncomingRequestsProvider.overrideWith(
            (ref) => Future.value([
              const Friend(
                id: 'req-caro-1',
                friendUserId: 'user-caro',
                displayName: 'Caro',
                username: 'caro',
                tasteProfile: TasteProfile(id: 'user-caro', name: 'Caro'),
                status: 'pending',
              ),
            ]),
          ),
          incomingCellarRequestsProvider.overrideWith(
            (ref) => Future.value([
              CellarAccessRequest(
                id: 'cellar-req-1',
                cellarId: 'cellar-1',
                ownerId: 'my-user',
                requesterId: 'user-caro',
                requesterName: 'Caro',
                requesterUsername: 'caro',
                requestedRole: 'editor',
                cellarName: 'Cave Principale',
                createdAt: DateTime.now(),
              ),
            ]),
          ),
          userNotificationsProvider.overrideWith((ref) => Future.value([])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationsInboxSheet(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check header and sections
      expect(find.text('Boîte de réception'), findsOneWidget);
      expect(find.textContaining('Demandes d\'amis'), findsOneWidget);
      expect(find.textContaining('Demandes d\'accès à votre Cave'), findsOneWidget);

      // Verify Snooze / Pour plus tard button exists
      final snoozeButtons = find.byIcon(Icons.snooze);
      expect(snoozeButtons, findsWidgets);

      // Tap snooze on first item
      await tester.tap(snoozeButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      container.dispose();
    });
  });
}
