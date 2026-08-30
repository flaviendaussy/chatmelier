import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/bottle.dart';
import '../domain/cellar.dart';
import '../domain/wine.dart';
import '../../offline/data/offline_storage_service.dart';
import '../../offline/domain/offline_action.dart';
import '../../../shared/utils/app_logger.dart';

class CellarRepository {
  final SupabaseClient _client;
  final OfflineStorageService? _offlineStorage;

  CellarRepository(this._client, [this._offlineStorage]);

  // ---------------------------------------------------------------------------
  // Cellars Management
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getUserCellarsWithRole() async {
    try {
      final res = await _client
          .from('cellar_members')
          .select('cellar_id, role, cellars(id, name, nickname, location_name, latitude, longitude, description, owner_id, created_at)')
          .order('invited_at');

      final list = List<Map<String, dynamic>>.from(res as List);
      
      // Save cellars in local cache
      final cellars = list.map((item) {
        final cMap = Map<String, dynamic>.from(item['cellars'] as Map);
        return Cellar.fromJson(cMap);
      }).toList();

      await _offlineStorage?.saveCachedCellars(cellars);
      return list;
    } catch (e) {
      debugPrint('CellarRepository.getUserCellars error, falling back to cache: $e');
      final cached = _offlineStorage?.getCachedCellars() ?? [];
      return cached.map((c) => {
        'cellar_id': c.id,
        'role': 'admin',
        'cellars': {
          'id': c.id,
          'name': c.name,
          'nickname': c.nickname,
          'location_name': c.locationName,
          'latitude': c.latitude,
          'longitude': c.longitude,
          'description': c.description,
          'owner_id': c.ownerId,
          'created_at': c.createdAt.toIso8601String(),
        },
      }).toList();
    }
  }

  Future<Cellar> createCellar({
    required String name,
    String? nickname,
    String? locationName,
    String? description,
    double? latitude,
    double? longitude,
    String? wifiSsid,
    int radiusMeters = 300,
  }) async {
    final user = _client.auth.currentUser;
    final userId = user?.id ?? const Uuid().v4();

    try {
      final res = await _client.from('cellars').insert({
        'name': name,
        if (nickname != null) 'nickname': nickname,
        if (locationName != null) 'location_name': locationName,
        if (description != null) 'description': description,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (wifiSsid != null) 'wifi_ssid': wifiSsid,
        'radius_meters': radiusMeters,
        'owner_id': userId,
      }).select().single();

      final cellarId = res['id'] as String;

      try {
        await _client.from('cellar_members').insert({
          'cellar_id': cellarId,
          'user_id': userId,
          'role': 'admin',
        });
      } catch (_) {}

      final newCellar = Cellar.fromJson(res);

      // Add to local cache
      final cached = _offlineStorage?.getCachedCellars() ?? [];
      cached.add(newCellar);
      await _offlineStorage?.saveCachedCellars(cached);

      return newCellar;
    } catch (e) {
      debugPrint('Create cellar offline fallback: $e');
      final tempId = const Uuid().v4();
      final tempCellar = Cellar(
        id: tempId,
        name: name,
        nickname: nickname,
        locationName: locationName,
        description: description,
        latitude: latitude,
        longitude: longitude,
        wifiSsid: wifiSsid,
        radiusMeters: radiusMeters,
        ownerId: userId,
        createdAt: DateTime.now(),
      );

      final cached = _offlineStorage?.getCachedCellars() ?? [];
      cached.add(tempCellar);
      await _offlineStorage?.saveCachedCellars(cached);

      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.createCellar,
        cellarId: tempId,
        data: {
          'name': name,
          'nickname': nickname,
          'location_name': locationName,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'wifi_ssid': wifiSsid,
          'radius_meters': radiusMeters,
        },
      ));

      return tempCellar;
    }
  }

  Future<void> updateCellar(
    String cellarId, {
    required String name,
    String? nickname,
    String? locationName,
    String? description,
    double? latitude,
    double? longitude,
    String? wifiSsid,
    int? radiusMeters,
    Map<String, dynamic>? rawUpdates,
  }) async {
    final cleanName = name.trim().isEmpty ? 'Cave' : name.trim();
    final updates = rawUpdates != null
        ? Map<String, dynamic>.from(rawUpdates)
        : <String, dynamic>{
            'name': cleanName,
            if (nickname != null) 'nickname': nickname,
            if (locationName != null) 'location_name': locationName,
            if (description != null) 'description': description,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (wifiSsid != null) 'wifi_ssid': wifiSsid,
            if (radiusMeters != null) 'radius_meters': radiusMeters,
          };

    bool updatedRemote = false;

    // Stage 1: Try with full payload
    try {
      await _client.from('cellars').update(updates).eq('id', cellarId);
      updatedRemote = true;
    } catch (e1) {
      debugPrint('updateCellar Stage 1 notice: $e1. Retrying without wifi/radius...');
      
      // Stage 2: Retry without wifi_ssid / radius_meters (which might not exist in remote DB)
      try {
        final safeUpdates = <String, dynamic>{
          'name': cleanName,
          if (nickname != null) 'nickname': nickname,
          if (locationName != null) 'location_name': locationName,
          if (description != null) 'description': description,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        };
        await _client.from('cellars').update(safeUpdates).eq('id', cellarId);
        updatedRemote = true;
      } catch (e2) {
        debugPrint('updateCellar Stage 2 notice: $e2. Retrying minimal name update...');
        
        // Stage 3: Retry minimal update with name & nickname
        try {
          await _client.from('cellars').update({
            'name': cleanName,
            if (nickname != null) 'nickname': nickname,
          }).eq('id', cellarId);
          updatedRemote = true;
        } catch (e3) {
          debugPrint('updateCellar Stage 3 notice: $e3. Retrying name only...');
          
          // Stage 4: Retry pure name update
          try {
            await _client.from('cellars').update({
              'name': cleanName,
            }).eq('id', cellarId);
            updatedRemote = true;
          } catch (e4) {
            debugPrint('updateCellar Stage 4 notice: $e4');
          }
        }
      }
    }

    // Always update local cache immediately so UI is 100% updated in 0ms
    final cached = _offlineStorage?.getCachedCellars() ?? [];
    bool found = false;
    final updated = cached.map((c) {
      if (c.id == cellarId) {
        found = true;
        return c.copyWith(
          name: cleanName,
          nickname: nickname,
          locationName: locationName,
          description: description,
          latitude: latitude,
          longitude: longitude,
          wifiSsid: wifiSsid,
          radiusMeters: radiusMeters,
        );
      }
      return c;
    }).toList();

    if (!found) {
      updated.add(Cellar(
        id: cellarId,
        name: cleanName,
        nickname: nickname,
        locationName: locationName,
        description: description,
        latitude: latitude,
        longitude: longitude,
        wifiSsid: wifiSsid,
        radiusMeters: radiusMeters ?? 300,
        ownerId: _client.auth.currentUser?.id ?? '',
        createdAt: DateTime.now(),
      ));
    }
    await _offlineStorage?.saveCachedCellars(updated);

    if (!updatedRemote) {
      // Enqueue offline action if remote could not be reached
      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.updateCellar,
        cellarId: cellarId,
        data: updates,
      ));
    }
  }

  Future<void> deleteCellar(String cellarId) async {
    try {
      await _client.from('cellars').delete().eq('id', cellarId);

      // Clean local cache
      final cached = _offlineStorage?.getCachedCellars() ?? [];
      cached.removeWhere((c) => c.id == cellarId);
      await _offlineStorage?.saveCachedCellars(cached);
    } catch (e) {
      debugPrint('deleteCellar error: $e');
      final cached = _offlineStorage?.getCachedCellars() ?? [];
      cached.removeWhere((c) => c.id == cellarId);
      await _offlineStorage?.saveCachedCellars(cached);
    }
  }

  // ---------------------------------------------------------------------------
  // Bottles Listing & Retrieval
  // ---------------------------------------------------------------------------

  Future<List<Bottle>> getBottles(String cellarId) async {
    final cached = _offlineStorage?.getCachedBottles(cellarId) ?? [];
    try {
      final res = await _client
          .from('bottles')
          .select('*, wines(*), bottle_photos(storage_path)')
          .eq('cellar_id', cellarId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 12));

      final serverBottles = (res as List).map((json) => Bottle.fromJson(json as Map<String, dynamic>)).toList();
      
      // Preserve any pending offline additions (starting with 'temp_') that haven't synced to server yet
      final pendingOfflineBottles = cached.where((b) => b.id.startsWith('temp_')).toList();
      final mergedBottles = [...pendingOfflineBottles, ...serverBottles];

      // Save in cache
      await _offlineStorage?.saveCachedBottles(cellarId, mergedBottles);
      return mergedBottles;
    } catch (e) {
      debugPrint('CellarRepository.getBottles offline fallback: $e');
      return cached;
    }
  }

  Future<Bottle> getBottleById(String id) async {
    // Check cache first for rapid offline return
    final cellars = _offlineStorage?.getCachedCellars() ?? [];
    Bottle? cachedMatch;
    for (final c in cellars) {
      final cached = _offlineStorage?.getCachedBottles(c.id) ?? [];
      for (final b in cached) {
        if (b.id == id) {
          cachedMatch = b;
          break;
        }
      }
      if (cachedMatch != null) break;
    }

    try {
      final res = await _client
          .from('bottles')
          .select('*, wines(*)')
          .eq('id', id)
          .single()
          .timeout(const Duration(seconds: 10));
      return Bottle.fromJson(res);
    } catch (e) {
      if (cachedMatch != null) return cachedMatch;
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Add Bottle (Online & Offline Buffered)
  // ---------------------------------------------------------------------------

  Future<Bottle> addBottle({
    required String cellarId,
    required String wineName,
    int? vintage,
    String? producer,
    String wineType = 'red',
    String? country,
    String? region,
    String? subRegion,
    String? appellation,
    String? classification,
    String? cuveeParcel,
    double? alcoholPct,
    int quantity = 1,
    double? purchasePrice,
    String currency = 'EUR',
    String? purchaseLocation,
    String? imageUrl,
    String? rack,
    String? shelf,
    String? position,
    String? notes,
    String? tastingNotes,
    String? aiSummary,
    List<String>? foodPairings,
    int? idealDrinkingStart,
    int? idealDrinkingEnd,
    int? peakDrinkingStart,
    int? peakDrinkingEnd,
    double? estimatedMarketValue,
    String? localPhotoPath,
  }) async {
    final user = _client.auth.currentUser;
    final userId = user?.id ?? const Uuid().v4();

    try {
      // 1. Create or match canonical Wine
      final winePayload = <String, dynamic>{
        'name': wineName,
        'vintage': vintage,
        'producer': producer,
        'wine_type': wineType,
        'country': country ?? 'France',
        'region': region ?? 'Bordeaux',
        if (subRegion != null) 'sub_region': subRegion,
        if (appellation != null) 'appellation': appellation,
        if (classification != null) 'classification': classification,
        if (cuveeParcel != null) 'cuvee_parcel': cuveeParcel,
        if (alcoholPct != null) 'alcohol_pct': alcoholPct,
        if (imageUrl != null) 'image_url': imageUrl,
        if (imageUrl != null) 'external_links': {'image_url': imageUrl},
        if (tastingNotes != null) 'tasting_notes': tastingNotes,
        if (aiSummary != null) 'ai_summary': aiSummary,
        if (foodPairings != null) 'ai_food_pairings': foodPairings,
        if (idealDrinkingStart != null) 'ideal_drinking_start': idealDrinkingStart,
        if (idealDrinkingEnd != null) 'ideal_drinking_end': idealDrinkingEnd,
        if (peakDrinkingStart != null) 'peak_drinking_start': peakDrinkingStart,
        if (peakDrinkingEnd != null) 'peak_drinking_end': peakDrinkingEnd,
        if (estimatedMarketValue != null) 'estimated_market_value': estimatedMarketValue,
      };

      Map<String, dynamic> wineInsert;
      try {
        wineInsert = await _client.from('wines').insert(winePayload).select().single();
      } catch (insertErr) {
        if (insertErr.toString().contains('image_url')) {
          final fallbackPayload = Map<String, dynamic>.from(winePayload)..remove('image_url');
          wineInsert = await _client.from('wines').insert(fallbackPayload).select().single();
        } else {
          rethrow;
        }
      }

      final wineId = wineInsert['id'] as String;

      // 2. Insert Bottle in cellar
      final bottleInsert = await _client.from('bottles').insert({
        'cellar_id': cellarId,
        'wine_id': wineId,
        'added_by': userId,
        'owner_id': userId,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'currency': currency,
        if (purchaseLocation != null) 'purchase_location': purchaseLocation,
        'rack': rack,
        'shelf': shelf,
        'position': position,
        'notes': notes,
        'status': 'in_cellar',
      }).select('*, wines(*)').single();

      final bottle = Bottle.fromJson(bottleInsert);
      await _offlineStorage?.applyOfflineAddBottle(cellarId, bottle);
      AppLogger.info('CELLAR_REPO', 'Successfully added bottle online: ${bottle.id} ("$wineName")');
      return bottle;
    } catch (e, stack) {
      AppLogger.error('CELLAR_REPO', 'Online addBottle failed: $e, switching to offline buffering', e, stack);
      debugPrint('addBottle offline buffering: $e');

      final tempWineId = const Uuid().v4();
      final tempBottleId = 'temp_${const Uuid().v4()}';

      final offlineWine = Wine(
        id: tempWineId,
        name: wineName,
        producer: producer,
        vintage: vintage,
        type: wineType,
        country: country ?? 'France',
        region: region ?? 'Bordeaux',
        subRegion: subRegion,
        appellation: appellation,
        classification: classification,
        cuveeParcel: cuveeParcel,
        alcoholPct: alcoholPct,
        imageUrl: imageUrl,
        tastingNotes: tastingNotes,
        summary: aiSummary,
        foodPairings: foodPairings ?? const [],
        drinkStart: idealDrinkingStart,
        drinkEnd: idealDrinkingEnd,
        peakStart: peakDrinkingStart,
        peakEnd: peakDrinkingEnd,
        estimatedMarketValue: estimatedMarketValue,
      );

      final offlineBottle = Bottle(
        id: tempBottleId,
        cellarId: cellarId,
        wineId: tempWineId,
        addedBy: userId,
        ownerId: userId,
        quantity: quantity,
        purchasePrice: purchasePrice,
        currency: currency,
        purchaseLocation: purchaseLocation,
        rack: rack,
        shelf: shelf,
        position: position,
        notes: notes,
        status: 'in_cellar',
        createdAt: DateTime.now(),
        wine: offlineWine,
      );

      await _offlineStorage?.applyOfflineAddBottle(cellarId, offlineBottle);

      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.addBottle,
        cellarId: cellarId,
        localPhotoPath: localPhotoPath,
        data: {
          'temp_bottle_id': tempBottleId,
          'cellar_id': cellarId,
          'wine_name': wineName,
          'vintage': vintage,
          'producer': producer,
          'wine_type': wineType,
          'country': country,
          'region': region,
          'sub_region': subRegion,
          'appellation': appellation,
          'classification': classification,
          'cuvee_parcel': cuveeParcel,
          'alcohol_pct': alcoholPct,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'currency': currency,
          'rack': rack,
          'shelf': shelf,
          'position': position,
          'notes': notes,
          if (tastingNotes != null) 'tasting_notes': tastingNotes,
          if (aiSummary != null) 'ai_summary': aiSummary,
          if (foodPairings != null) 'food_pairings': foodPairings,
          if (idealDrinkingStart != null) 'ideal_drinking_start': idealDrinkingStart,
          if (idealDrinkingEnd != null) 'ideal_drinking_end': idealDrinkingEnd,
          if (peakDrinkingStart != null) 'peak_drinking_start': peakDrinkingStart,
          if (peakDrinkingEnd != null) 'peak_drinking_end': peakDrinkingEnd,
          if (estimatedMarketValue != null) 'estimated_market_value': estimatedMarketValue,
        },
      ));

      return offlineBottle;
    }
  }

  // ---------------------------------------------------------------------------
  // Check-Out / Consume Bottle (Online & Offline Buffered)
  // ---------------------------------------------------------------------------

  Future<void> consumeBottle(
    String bottleId, {
    String? cellarId,
    int? rating,
    String? notes,
    String? foodPaired,
  }) async {
    final user = _client.auth.currentUser;
    final userId = user?.id;

    if (cellarId != null) {
      await _offlineStorage?.applyOfflineConsume(cellarId, bottleId);
    }

    try {
      final bottle = await getBottleById(bottleId);

      if (bottle.quantity > 1) {
        await _client.from('bottles').update({
          'quantity': bottle.quantity - 1,
        }).eq('id', bottleId);
      } else {
        await _client.from('bottles').update({
          'status': 'consumed',
          'consumed_at': DateTime.now().toIso8601String(),
        }).eq('id', bottleId);
      }

      if (userId != null && bottle.wineId.isNotEmpty) {
        await _client.from('tasting_log').insert({
          'wine_id': bottle.wineId,
          'bottle_id': bottle.id,
          'user_id': userId,
          'rating': rating,
          'tasting_notes': notes,
          'food_paired': foodPaired,
          'consumed_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('consumeBottle offline buffering: $e');
      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.consumeBottle,
        cellarId: cellarId,
        data: {
          'bottle_id': bottleId,
          'rating': rating,
          'tasting_notes': notes,
          'food_paired': foodPaired,
        },
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Update & Delete
  // ---------------------------------------------------------------------------

  Future<void> updateBottle(
    String bottleId, {
    int? quantity,
    double? purchasePrice,
    String? currency,
    String? purchaseLocation,
    String? rack,
    String? shelf,
    String? position,
    String? notes,
    String? photoUrl,
    Map<String, dynamic>? rawUpdates,
  }) async {
    final updates = rawUpdates != null
        ? Map<String, dynamic>.from(rawUpdates)
        : <String, dynamic>{
            if (quantity != null) 'quantity': quantity,
            if (purchasePrice != null) 'purchase_price': purchasePrice,
            if (currency != null) 'currency': currency,
            if (purchaseLocation != null) 'purchase_location': purchaseLocation,
            if (rack != null) 'rack': rack,
            if (shelf != null) 'shelf': shelf,
            if (position != null) 'position': position,
            if (notes != null) 'notes': notes,
            if (photoUrl != null) 'photo_url': photoUrl,
          };

    try {
      if (updates.isNotEmpty) {
        await _client.from('bottles').update(updates).eq('id', bottleId);
        await _offlineStorage?.applyOfflineUpdateBottle(bottleId, updates);
      }
    } catch (e) {
      await _offlineStorage?.applyOfflineUpdateBottle(bottleId, updates);
      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.updateBottle,
        data: {'bottle_id': bottleId, ...updates},
      ));
    }
  }

  Future<void> updateWine(
    String wineId, {
    String? name,
    String? producer,
    int? vintage,
    String? wineType,
    String? country,
    String? region,
    String? subRegion,
    String? appellation,
    String? classification,
    String? cuveeParcel,
    double? alcoholPct,
    int? idealDrinkingStart,
    int? idealDrinkingEnd,
    int? peakDrinkingStart,
    int? peakDrinkingEnd,
    double? estimatedMarketValue,
    String? tastingNotes,
    List<String>? foodPairings,
    List<Grape>? grapes,
    List<String>? userOverrides,
    String? imageUrl,
    Map<String, dynamic>? rawUpdates,
  }) async {
    final updates = rawUpdates != null
        ? Map<String, dynamic>.from(rawUpdates)
        : <String, dynamic>{
            if (name != null) 'name': name,
            if (producer != null) 'producer': producer,
            if (vintage != null) 'vintage': vintage,
            if (wineType != null) 'wine_type': wineType,
            if (country != null) 'country': country,
            if (region != null) 'region': region,
            if (subRegion != null) 'sub_region': subRegion,
            if (appellation != null) 'appellation': appellation,
            if (classification != null) 'classification': classification,
            if (cuveeParcel != null) 'cuvee_parcel': cuveeParcel,
            if (alcoholPct != null) 'alcohol_pct': alcoholPct,
            if (idealDrinkingStart != null) 'ideal_drinking_start': idealDrinkingStart,
            if (idealDrinkingEnd != null) 'ideal_drinking_end': idealDrinkingEnd,
            if (peakDrinkingStart != null) 'peak_drinking_start': peakDrinkingStart,
            if (peakDrinkingEnd != null) 'peak_drinking_end': peakDrinkingEnd,
            if (estimatedMarketValue != null) 'estimated_market_value': estimatedMarketValue,
            if (tastingNotes != null) 'tasting_notes': tastingNotes,
            if (foodPairings != null) 'ai_food_pairings': foodPairings,
            if (grapes != null) 'grapes': grapes.map((g) => g.toJson()).toList(),
            if (userOverrides != null) 'user_overrides': userOverrides,
            if (userOverrides != null) 'external_links': {'user_overrides': userOverrides},
            if (imageUrl != null) 'image_url': imageUrl,
            if (imageUrl != null) 'external_links': {'image_url': imageUrl},
          };

    try {
      if (updates.isNotEmpty) {
        try {
          await _client.from('wines').update(updates).eq('id', wineId);
        } catch (updateErr) {
          if (updateErr.toString().contains('image_url')) {
            final fallbackUpdates = Map<String, dynamic>.from(updates)..remove('image_url');
            if (fallbackUpdates.isNotEmpty) {
              await _client.from('wines').update(fallbackUpdates).eq('id', wineId);
            }
          } else {
            rethrow;
          }
        }
        AppLogger.info('CELLAR_REPO', 'Updated wine $wineId with ${updates.keys.join(", ")}');
      }
    } catch (e) {
      AppLogger.warning('CELLAR_REPO', 'updateWine offline fallback: $e');
      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.updateWine,
        data: {'wine_id': wineId, ...updates},
      ));
    }
  }

  Future<void> deleteBottle(String id) async {
    try {
      await _client.from('bottles').delete().eq('id', id);
    } catch (e) {
      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.deleteBottle,
        data: {'bottle_id': id},
      ));
    }
  }

  /// Permanent hard deletion with clear separation from checkout/consumption
  Future<void> deleteBottlePermanently({
    required String bottleId,
    required String cellarId,
    int? quantityToRemove,
  }) async {
    // 1. Update offline cache immediately
    await _offlineStorage?.applyOfflineDeleteBottle(cellarId, bottleId, quantityToRemove: quantityToRemove);

    try {
      final bottle = await getBottleById(bottleId);
      if (quantityToRemove != null && quantityToRemove < bottle.quantity) {
        await _client.from('bottles').update({
          'quantity': bottle.quantity - quantityToRemove,
        }).eq('id', bottleId);
      } else {
        await _client.from('bottles').delete().eq('id', bottleId);
      }
    } catch (e) {
      debugPrint('deleteBottlePermanently offline fallback: $e');
      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.deleteBottle,
        cellarId: cellarId,
        data: {
          'bottle_id': bottleId,
          'quantity_to_remove': quantityToRemove,
        },
      ));
    }
  }

  /// Add quantity to an existing bottle in cellar
  Future<void> addBottleQuantity({
    required String bottleId,
    required String cellarId,
    int quantityToAdd = 1,
  }) async {
    final cached = _offlineStorage?.getCachedBottles(cellarId) ?? [];
    final idx = cached.indexWhere((b) => b.id == bottleId);
    final currentQty = idx != -1 ? cached[idx].quantity : 1;
    final newQty = currentQty + quantityToAdd;
    await _offlineStorage?.applyOfflineUpdateQuantity(cellarId, bottleId, newQty);

    try {
      await _client.from('bottles').update({'quantity': newQty}).eq('id', bottleId);
    } catch (e) {
      debugPrint('addBottleQuantity offline fallback: $e');
      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.updateBottle,
        cellarId: cellarId,
        data: {'bottle_id': bottleId, 'quantity': newQty},
      ));
    }
  }

  /// Set exact quantity for an existing bottle in cellar
  Future<void> updateBottleQuantity(String bottleId, int newQuantity, {String? cellarId}) async {
    if (cellarId != null) {
      await _offlineStorage?.applyOfflineUpdateQuantity(cellarId, bottleId, newQuantity);
    }

    try {
      await _client.from('bottles').update({'quantity': newQuantity}).eq('id', bottleId);
    } catch (e) {
      debugPrint('updateBottleQuantity offline fallback: $e');
      if (cellarId != null) {
        await _offlineStorage?.enqueueAction(OfflineAction(
          type: OfflineActionType.updateBottle,
          cellarId: cellarId,
          data: {'bottle_id': bottleId, 'quantity': newQuantity},
        ));
      }
    }
  }

  /// Move bottle or partial quantity to another cellar
  Future<void> moveBottleToCellar({
    required String bottleId,
    required String sourceCellarId,
    required String targetCellarId,
    int quantityToMove = 1,
  }) async {
    // 1. Update offline cache immediately for instantaneous UI response
    await _offlineStorage?.applyOfflineMoveBottle(
      sourceCellarId: sourceCellarId,
      targetCellarId: targetCellarId,
      bottleId: bottleId,
      quantityToMove: quantityToMove,
    );

    try {
      final bottle = await getBottleById(bottleId);
      final currentUserId = _client.auth.currentUser?.id;
      final addedBy = bottle.addedBy.isNotEmpty ? bottle.addedBy : currentUserId;
      final ownerId = bottle.ownerId.isNotEmpty ? bottle.ownerId : currentUserId;

      if (quantityToMove >= bottle.quantity) {
        // Move entire bottle record to new cellar
        await _client.from('bottles').update({
          'cellar_id': targetCellarId,
        }).eq('id', bottleId);
      } else {
        // Split: reduce source and insert new bottle in target cellar
        await _client.from('bottles').update({
          'quantity': bottle.quantity - quantityToMove,
        }).eq('id', bottleId);

        await _client.from('bottles').insert({
          'cellar_id': targetCellarId,
          'wine_id': bottle.wineId,
          'added_by': addedBy,
          'owner_id': ownerId,
          'quantity': quantityToMove,
          'purchase_price': bottle.purchasePrice,
          'currency': bottle.currency,
          'purchase_location': bottle.purchaseLocation,
          'status': 'in_cellar',
          'notes': bottle.notes,
        });
      }
      AppLogger.info('CELLAR', 'Moved $quantityToMove bottle(s) of "${bottle.wine?.name ?? bottle.wineId}" from $sourceCellarId to $targetCellarId');
    } catch (e) {
      AppLogger.warning('CELLAR', 'moveBottleToCellar offline fallback: $e');
      await _offlineStorage?.enqueueAction(OfflineAction(
        type: OfflineActionType.moveBottle,
        cellarId: sourceCellarId,
        data: {
          'action': 'move',
          'bottle_id': bottleId,
          'source_cellar_id': sourceCellarId,
          'target_cellar_id': targetCellarId,
          'quantity_to_move': quantityToMove,
        },
      ));
    }
  }

  /// Check out / consume multiple bottles
  Future<void> consumeBottles({
    required String bottleId,
    String? cellarId,
    int quantity = 1,
    int rating = 5,
    String? notes,
    String? foodPaired,
  }) async {
    for (int i = 0; i < quantity; i++) {
      await consumeBottle(
        bottleId,
        cellarId: cellarId,
        rating: rating,
        notes: notes,
        foodPaired: foodPaired,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Resolve Missing Vintage
  // ---------------------------------------------------------------------------

  Future<void> resolveMissingVintage({
    required String bottleId,
    required String wineId,
    required int vintage,
  }) async {
    try {
      await _client.from('wines').update({
        'vintage': vintage,
      }).eq('id', wineId);
      await _offlineStorage?.removePendingResolutionWine(bottleId);
    } catch (e) {
      debugPrint('Failed to resolve missing vintage: $e');
    }
  }
}
