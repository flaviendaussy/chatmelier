import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';
import 'package:chatmelier/features/cellar/domain/cellar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineStorageService Tests', () {
    late OfflineStorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = OfflineStorageService(prefs);
    });

    test('Initial queue should be empty', () {
      expect(service.getQueue(), isEmpty);
      expect(service.pendingActionCount, 0);
    });

    test('Enqueue and retrieve actions in queue', () async {
      final action1 = OfflineAction(
        id: 'action-1',
        type: OfflineActionType.addBottle,
        data: {'name': 'Château Margaux', 'vintage': 2015, 'quantity': 2},
        createdAt: DateTime.now(),
      );

      final action2 = OfflineAction(
        id: 'action-2',
        type: OfflineActionType.consumeBottle,
        data: {'bottle_id': 'b-123', 'rating': 5},
        createdAt: DateTime.now(),
      );

      await service.enqueueAction(action1);
      await service.enqueueAction(action2);

      final queue = service.getQueue();
      expect(queue.length, 2);
      expect(queue.first.id, 'action-1');
      expect(queue.first.type, OfflineActionType.addBottle);
      expect(queue.last.id, 'action-2');
      expect(service.pendingActionCount, 2);
    });

    test('Remove specific action from queue', () async {
      final action1 = OfflineAction(
        id: 'action-1',
        type: OfflineActionType.addBottle,
        data: {},
        createdAt: DateTime.now(),
      );
      final action2 = OfflineAction(
        id: 'action-2',
        type: OfflineActionType.consumeBottle,
        data: {},
        createdAt: DateTime.now(),
      );

      await service.enqueueAction(action1);
      await service.enqueueAction(action2);

      await service.removeAction('action-1');

      final queue = service.getQueue();
      expect(queue.length, 1);
      expect(queue.first.id, 'action-2');
    });

    test('Update action status and clear completed actions', () async {
      final action = OfflineAction(
        id: 'action-1',
        type: OfflineActionType.addBottle,
        data: {},
        createdAt: DateTime.now(),
      );

      await service.enqueueAction(action);

      final updated = action.copyWith(status: OfflineActionStatus.completed);
      await service.updateAction(updated);

      expect(service.getQueue().first.status, OfflineActionStatus.completed);

      await service.clearCompletedActions();
      expect(service.getQueue(), isEmpty);
    });

    test('Cache cellars and retrieve them offline', () async {
      final cellars = [
        Cellar(
          id: 'c1',
          name: 'Cave Vosges',
          nickname: 'Maison de campagne',
          locationName: 'Épinal',
          description: 'Cave fraîche voutée',
          ownerId: 'u1',
          createdAt: DateTime.now(),
        ),
        Cellar(
          id: 'c2',
          name: 'Cave Londres',
          nickname: 'Appartement',
          locationName: 'London',
          description: 'EuroCave tempérée',
          ownerId: 'u1',
          createdAt: DateTime.now(),
        ),
      ];

      await service.saveCachedCellars(cellars);

      final cached = service.getCachedCellars();
      expect(cached.length, 2);
      expect(cached.first.name, 'Cave Vosges');
      expect(cached.last.name, 'Cave Londres');
    });

    test('clearFailedActions removes only failed actions', () async {
      final action1 = OfflineAction(
        id: 'action-1',
        type: OfflineActionType.consumeBottle,
        data: {'bottle_id': null, 'is_external': true},
        status: OfflineActionStatus.failed,
        errorMessage: "type 'Null' is not a subtype of type 'String'",
      );
      final action2 = OfflineAction(
        id: 'action-2',
        type: OfflineActionType.addBottle,
        data: {'wine_name': 'Pétrus'},
        status: OfflineActionStatus.pending,
      );

      await service.enqueueAction(action1);
      await service.enqueueAction(action2);

      expect(service.getQueue().length, 2);
      await service.clearFailedActions();

      final remaining = service.getQueue();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'action-2');
      expect(remaining.first.status, OfflineActionStatus.pending);
    });

    test('retryFailedActions resets failed actions to pending and clears error', () async {
      final action = OfflineAction(
        id: 'action-failed',
        type: OfflineActionType.consumeBottle,
        cellarId: 'cellar-1',
        data: {'rating': 4.5},
        status: OfflineActionStatus.failed,
        errorMessage: 'Connection failed',
      );

      await service.enqueueAction(action);
      expect(service.getQueue().first.status, OfflineActionStatus.failed);

      await service.retryFailedActions();

      final queue = service.getQueue();
      expect(queue.first.status, OfflineActionStatus.pending);
      expect(queue.first.errorMessage, isNull);
    });

    test('OfflineAction copyWith supports all fields including cellarId and data', () {
      final original = OfflineAction(
        id: 'orig-id',
        type: OfflineActionType.addBottle,
        cellarId: 'temp_cellar_123',
        data: {'wine_name': 'Margaux'},
        status: OfflineActionStatus.pending,
      );

      final updated = original.copyWith(
        cellarId: 'real-cellar-uuid',
        status: OfflineActionStatus.completed,
      );

      expect(updated.id, 'orig-id');
      expect(updated.cellarId, 'real-cellar-uuid');
      expect(updated.status, OfflineActionStatus.completed);
      expect(updated.data['wine_name'], 'Margaux');
    });
  });
}
