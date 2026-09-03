import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Sync Resilience Tests', () {
    late OfflineStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = OfflineStorageService(prefs);
    });

    test('External tasting action serialization without bottle_id', () async {
      final action = OfflineAction(
        id: 'ext-tasting-1',
        type: OfflineActionType.consumeBottle,
        cellarId: null,
        data: {
          'tasting_id': 'ext-tasting-1',
          'wine_id': 'wine-uuid-123',
          'wine_name': 'Château Haut-Brion',
          'vintage': 2010,
          'rating': 4.5,
          'is_external': true,
          'occasion': 'Dîner chez des amis',
          'bottle_id': null,
        },
      );

      await storage.enqueueAction(action);
      final retrieved = storage.getQueue().first;

      expect(retrieved.id, 'ext-tasting-1');
      expect(retrieved.type, OfflineActionType.consumeBottle);
      expect(retrieved.cellarId, isNull);
      expect(retrieved.data['bottle_id'], isNull);
      expect(retrieved.data['is_external'], isTrue);
      expect(retrieved.data['rating'], 4.5);
    });

    test('Temporary cellar ID remapping across queued actions', () async {
      final cellarAction = OfflineAction(
        id: 'cellar-action',
        type: OfflineActionType.createCellar,
        cellarId: 'temp_cellar_999',
        data: {'name': 'Ma nouvelle cave'},
      );

      final bottleAction1 = OfflineAction(
        id: 'bottle-1',
        type: OfflineActionType.addBottle,
        cellarId: 'temp_cellar_999',
        data: {'cellar_id': 'temp_cellar_999', 'wine_name': 'Chablis'},
      );

      final bottleAction2 = OfflineAction(
        id: 'bottle-2',
        type: OfflineActionType.consumeBottle,
        cellarId: 'temp_cellar_999',
        data: {'cellar_id': 'temp_cellar_999', 'bottle_id': 'temp_bottle_1'},
      );

      await storage.enqueueAction(cellarAction);
      await storage.enqueueAction(bottleAction1);
      await storage.enqueueAction(bottleAction2);

      // Simulate remapping when cellar is created on server
      const realCellarId = 'real-cellar-uuid-888';
      final queue = storage.getQueue();
      for (int i = 0; i < queue.length; i++) {
        final a = queue[i];
        if (a.cellarId == 'temp_cellar_999') {
          final updatedData = Map<String, dynamic>.from(a.data);
          if (updatedData['cellar_id'] == 'temp_cellar_999') {
            updatedData['cellar_id'] = realCellarId;
          }
          queue[i] = a.copyWith(cellarId: realCellarId, data: updatedData);
        }
      }
      await storage.saveQueue(queue);

      final remappedQueue = storage.getQueue();
      expect(remappedQueue[0].cellarId, realCellarId);
      expect(remappedQueue[1].cellarId, realCellarId);
      expect(remappedQueue[1].data['cellar_id'], realCellarId);
      expect(remappedQueue[2].cellarId, realCellarId);
    });

    test('Handling partial delete quantity action', () async {
      final deleteAction = OfflineAction(
        id: 'del-1',
        type: OfflineActionType.deleteBottle,
        cellarId: 'cellar-1',
        data: {
          'bottle_id': 'bottle-uuid-456',
          'quantity_to_remove': 2,
        },
      );

      await storage.enqueueAction(deleteAction);
      final item = storage.getQueue().first;

      expect(item.type, OfflineActionType.deleteBottle);
      expect(item.data['quantity_to_remove'], 2);
    });
  });
}
