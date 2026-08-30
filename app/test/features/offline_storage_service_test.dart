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
  });
}
