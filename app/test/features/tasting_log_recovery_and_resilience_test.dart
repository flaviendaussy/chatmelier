import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tasting Log Recovery & Resilience Tests', () {
    late OfflineStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = OfflineStorageService(prefs);
    });

    test('TastingEntry.fromJson gracefully parses flat attributes when nested wines map is missing', () {
      final flatJson = {
        'id': 'action-1788547581151',
        'wine_id': 'wine-chablis-2020',
        'wine_name': 'Chablis Grand Cru',
        'vintage': 2020,
        'region': 'Bourgogne',
        'country': 'France',
        'appellation': 'Chablis Grand Cru',
        'wine_type': 'white',
        'rating': 9.5,
        'occasion': 'Poissons et fruits de mer',
        'food_paired': 'Fruits de mer',
        'tasting_notes': 'Superbe minéralité et fraîcheur',
        'photo_url': 'https://example.com/chablis.jpg',
        'co_tasters': ['Caro', 'Moi'],
        'bottle_owner_name': 'Flavien',
        'is_external': false,
        'consumed_at': '2026-09-04T19:46:21.000Z',
      };

      final entry = TastingEntry.fromJson(flatJson);

      expect(entry.id, 'action-1788547581151');
      expect(entry.wineName, 'Chablis Grand Cru');
      expect(entry.vintage, 2020);
      expect(entry.region, 'Bourgogne');
      expect(entry.country, 'France');
      expect(entry.appellation, 'Chablis Grand Cru');
      expect(entry.wineType, 'white');
      expect(entry.rating, 9.5);
      expect(entry.foodPaired, 'Fruits de mer');
      expect(entry.tastingNotes, 'Superbe minéralité et fraîcheur');
      expect(entry.photoUrl, 'https://example.com/chablis.jpg');
      expect(entry.coTasters, ['Caro', 'Moi']);
      expect(entry.bottleOwnerName, 'Flavien');
      expect(entry.isExternal, isFalse);
      expect(entry.consumedAt.year, 2026);
    });

    test('TastingEntry.fromJson prioritizes nested wines map when present', () {
      final nestedJson = {
        'id': 'tasting-remote-1',
        'wine_id': 'wine-chablis-2020',
        'rating': 9.0,
        'consumed_at': '2026-09-04T19:46:21.000Z',
        'wines': {
          'name': 'Chablis Grand Cru Domaine William Fèvre',
          'vintage': 2020,
          'region': 'Bourgogne',
          'country': 'France',
          'appellation': 'Chablis Grand Cru',
          'type': 'white',
        },
      };

      final entry = TastingEntry.fromJson(nestedJson);

      expect(entry.wineName, 'Chablis Grand Cru Domaine William Fèvre');
      expect(entry.vintage, 2020);
      expect(entry.region, 'Bourgogne');
      expect(entry.wineType, 'white');
    });

    test('Offline queue preserves pending consumeBottle action without data loss', () async {
      final action = OfflineAction(
        id: '1788547581151',
        type: OfflineActionType.consumeBottle,
        cellarId: '634f4977-ff3a-4c08-a4cd-63d12052ddd5',
        status: OfflineActionStatus.pending,
        data: {
          'bottle_id': 'bottle-uuid-999',
          'wine_id': 'aff9060a-4ca4-4bbf-8bf8-2789a058b4d2',
          'wine_name': 'Chablis Grand Cru 2020',
          'vintage': 2020,
          'region': 'Bourgogne',
          'rating': 9.5,
          'food_paired': 'Fruits de mer',
          'tasting_notes': 'Excellente dégustation',
          'co_tasters': ['Caro'],
          'bottle_owner_name': 'Moi',
          'is_external': false,
        },
      );

      await storage.enqueueAction(action);
      final queue = storage.getQueue();

      expect(queue.length, 1);
      final saved = queue.first;
      expect(saved.id, '1788547581151');
      expect(saved.type, OfflineActionType.consumeBottle);
      expect(saved.data['wine_name'], 'Chablis Grand Cru 2020');
      expect(saved.data['rating'], 9.5);
      expect(saved.data['food_paired'], 'Fruits de mer');
    });

    test('addCachedTasting replaces existing entry with same id or inserts at beginning', () async {
      await storage.addCachedTasting({
        'id': '1788547581151',
        'wine_name': 'Chablis Grand Cru',
        'rating': 9.5,
      });

      var cached = storage.getCachedTastings();
      expect(cached.length, 1);
      expect(cached.first['rating'], 9.5);

      // Updating with enriched data preserves unique entry
      await storage.addCachedTasting({
        'id': '1788547581151',
        'wine_name': 'Chablis Grand Cru Domaine William Fèvre',
        'rating': 9.5,
        'tasting_notes': 'Arômes minéraux et agrumes',
      });

      cached = storage.getCachedTastings();
      expect(cached.length, 1);
      expect(cached.first['wine_name'], 'Chablis Grand Cru Domaine William Fèvre');
      expect(cached.first['tasting_notes'], 'Arômes minéraux et agrumes');
    });
  });
}
