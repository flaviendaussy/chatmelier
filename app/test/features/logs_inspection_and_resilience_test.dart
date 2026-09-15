import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/cellar_group_by.dart';
import 'package:chatmelier/shared/services/nearby_places_service.dart';
import 'package:chatmelier/shared/services/cellar_location_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Tasting Log Cache Merging (Prevent Disappearing Tastings Bug)', () {
    test('Remote sync merges with local-only cached tastings without erasing them', () async {
      final prefs = await SharedPreferences.getInstance();
      final offlineStorage = OfflineStorageService(prefs);

      // 1. User records a tasting locally (e.g. external tasting or offline)
      await offlineStorage.addCachedTasting({
        'id': 'local_tasting_yesterday',
        'wine_id': 'w_local_1',
        'wine_name': 'Meursault Les Narvaux',
        'vintage': 2020,
        'rating': 9.2,
        'consumed_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'is_external': true,
      });

      expect(offlineStorage.getCachedTastings().length, 1);

      // 2. Next day: remote fetch returns records from Supabase (which doesn't have local_tasting_yesterday yet)
      final remoteMaps = [
        {
          'id': 'remote_tasting_older',
          'wine_id': 'w_remote_2',
          'wine_name': 'Château Margaux',
          'vintage': 2015,
          'rating': 9.8,
          'consumed_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          'is_external': false,
        }
      ];

      // Merge logic: preserve local-only tastings whose id is not on server
      final existingCached = offlineStorage.getCachedTastings();
      final remoteIds = remoteMaps.map((m) => m['id']?.toString()).whereType<String>().toSet();
      final localOnly = existingCached.where((m) {
        final id = m['id']?.toString();
        return id != null && id.isNotEmpty && !remoteIds.contains(id);
      }).toList();

      final mergedMaps = [...remoteMaps, ...localOnly];
      await offlineStorage.saveCachedTastings(mergedMaps);

      // Verify that local tasting was NOT wiped out
      final cachedAfterSync = offlineStorage.getCachedTastings();
      expect(cachedAfterSync.length, 2);
      expect(cachedAfterSync.any((t) => t['id'] == 'local_tasting_yesterday'), isTrue);
      expect(cachedAfterSync.any((t) => t['id'] == 'remote_tasting_older'), isTrue);
    });
  });

  group('Spirits Apogee & Categorization Resilience', () {
    test('Spirits do not have apogee curves and are grouped strictly in spirit_no_apogee', () {
      const spiritWine = Wine(
        id: 'spirit_gin_1',
        name: 'Monkey 47 Schwarzwald Dry Gin',
        type: 'gin',
        country: 'Allemagne',
        region: 'Forêt-Noire',
        producer: 'Black Forest Distillers',
      );

      expect(spiritWine.isSpirit, isTrue);
      expect(spiritWine.tracksFillLevel, isTrue);

      // Grouping by maturity: spirits must never be marked as 'peak', 'aging' or 'past_peak'
      final bottle = Bottle(
        id: 'b_spirit_1',
        cellarId: 'c1',
        wineId: spiritWine.id,
        addedBy: 'user_1',
        ownerId: 'user_1',
        wine: spiritWine,
        quantity: 1,
        createdAt: DateTime.now(),
      );

      final sections = CellarGroupEngine.partitionBottles([bottle], CellarGroupBy.maturity);
      expect(sections.length, 1);
      expect(sections.first.key, 'spirit_no_apogee');
      expect(sections.first.title, 'Spiritueux & Vins Mutés (Sans apogée)');
    });

    test('Regular wines are placed into legitimate apogee buckets, not spirit_no_apogee', () {
      const redWine = Wine(
        id: 'red_1',
        name: 'Châteauneuf-du-Pape',
        type: 'red',
        country: 'France',
        region: 'Vallée du Rhône',
        vintage: 2018,
        drinkStart: 2020,
        peakStart: 2024,
        peakEnd: 2028,
        drinkEnd: 2035,
      );

      expect(redWine.isSpirit, isFalse);
      expect(redWine.tracksFillLevel, isFalse);

      final bottle = Bottle(
        id: 'b_red_1',
        cellarId: 'c1',
        wineId: redWine.id,
        addedBy: 'user_1',
        ownerId: 'user_1',
        wine: redWine,
        quantity: 1,
        createdAt: DateTime.now(),
      );

      final sections = CellarGroupEngine.partitionBottles([bottle], CellarGroupBy.maturity);
      expect(sections.length, 1);
      expect(sections.first.key, 'peak'); // Explicit peak window [2024-2028] contains 2026
      expect(sections.first.title, 'À l\'apogée (Idéal à boire)');
    });
  });

  group('NearbyPlacesService Custom Places & Sorting', () {
    test('Custom user places are stored, retrievable, and prioritized', () async {
      final service = NearbyPlacesService();

      // Add a custom restaurant place
      final customPlace = await service.rememberPlace(
        name: 'Bistrot Paul Bert',
        latitude: 48.853,
        longitude: 2.385,
      );

      expect(customPlace.name, 'Bistrot Paul Bert');
      final places = await service.getCustomPlaces();
      expect(places.length, 1);
      expect(places.first.name, 'Bistrot Paul Bert');

      // Check distance calculation
      final dist = CellarLocationService.calculateDistanceMeters(
        48.853, 2.385, 48.854, 2.386,
      );
      expect(dist, inInclusiveRange(50.0, 250.0));
    });
  });
}
