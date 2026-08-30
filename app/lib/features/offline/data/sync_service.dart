import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/offline_action.dart';
import 'offline_storage_service.dart';
import '../../cellar/domain/bottle.dart';
import '../../../config/constants.dart';
import '../../../shared/services/gemini_model_registry.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/data/ai_cost_tracker_service.dart';

class SyncResult {
  final int totalProcessed;
  final int succeeded;
  final int failed;
  final List<String> errors;
  final List<Map<String, dynamic>> winesNeedingVintage;

  const SyncResult({
    required this.totalProcessed,
    required this.succeeded,
    required this.failed,
    required this.errors,
    required this.winesNeedingVintage,
  });
}

class SyncService {
  final SupabaseClient _supabase;
  final OfflineStorageService _offlineStorage;
  final String _geminiApiKey;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncService({
    required SupabaseClient supabase,
    required OfflineStorageService offlineStorage,
    String? geminiApiKey,
  })  : _supabase = supabase,
        _offlineStorage = offlineStorage,
        _geminiApiKey = geminiApiKey ?? AppConstants.geminiApiKey;

  /// Check whether we currently have internet access to Supabase
  Future<bool> checkOnlineStatus() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.supabaseUrl}/rest/v1/'),
        headers: {'apikey': AppConstants.supabaseAnonKey},
      ).timeout(const Duration(seconds: 4));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Process all pending actions in the offline queue
  Future<SyncResult> processPendingActions() async {
    if (_isSyncing) {
      return const SyncResult(
        totalProcessed: 0,
        succeeded: 0,
        failed: 0,
        errors: ['Synchronisation déjà en cours'],
        winesNeedingVintage: [],
      );
    }

    final isOnline = await checkOnlineStatus();
    if (!isOnline) {
      return const SyncResult(
        totalProcessed: 0,
        succeeded: 0,
        failed: 0,
        errors: ['Appareil hors ligne — vérifiez votre connexion'],
        winesNeedingVintage: [],
      );
    }

    _isSyncing = true;
    int succeeded = 0;
    int failed = 0;
    final errors = <String>[];
    final winesNeedingVintage = <Map<String, dynamic>>[];

    final queue = _offlineStorage.getQueue();

    try {
      for (final action in queue) {
        if (action.status == OfflineActionStatus.completed) continue;

        try {
          await _offlineStorage.updateAction(
            action.copyWith(status: OfflineActionStatus.syncing),
          );

          switch (action.type) {
            case OfflineActionType.addBottle:
              final needingVintage = await _syncAddBottle(action);
              if (needingVintage != null) {
                winesNeedingVintage.add(needingVintage);
              }
              break;

            case OfflineActionType.consumeBottle:
              await _syncConsumeBottle(action);
              break;

            case OfflineActionType.updateBottle:
              await _syncUpdateBottle(action);
              break;

            case OfflineActionType.updateWine:
              await _syncUpdateWine(action);
              break;

            case OfflineActionType.deleteBottle:
              await _syncDeleteBottle(action);
              break;

            case OfflineActionType.createCellar:
              await _syncCreateCellar(action);
              break;

            case OfflineActionType.updateCellar:
              await _syncUpdateCellar(action);
              break;

            case OfflineActionType.moveBottle:
              await _syncMoveBottle(action);
              break;
          }

          await _offlineStorage.updateAction(
            action.copyWith(status: OfflineActionStatus.completed),
          );
          succeeded++;
        } catch (e) {
          failed++;
          final errorMsg = e.toString();
          errors.add(errorMsg);
          await _offlineStorage.updateAction(
            action.copyWith(
              status: OfflineActionStatus.failed,
              errorMessage: errorMsg,
            ),
          );
          debugPrint('Sync action failed: $action, error: $e');
        }
      }

      await _offlineStorage.clearCompletedActions();
    } finally {
      _isSyncing = false;
    }

    return SyncResult(
      totalProcessed: queue.length,
      succeeded: succeeded,
      failed: failed,
      errors: errors,
      winesNeedingVintage: winesNeedingVintage,
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _syncAddBottle(OfflineAction action) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    final data = action.data;
    final cellarId = action.cellarId ?? data['cellar_id'] as String;

    String wineName = data['wine_name'] as String? ?? 'Vin Sans Nom';
    int? vintage = (data['vintage'] as num?)?.toInt() ?? int.tryParse(data['vintage']?.toString() ?? '');
    String? producer = data['producer'] as String?;
    String wineType = data['wine_type'] as String? ?? 'red';
    String? country = data['country'] as String?;
    String? region = data['region'] as String?;
    String? appellation = data['appellation'] as String?;
    String? notes = data['notes'] as String?;
    int quantity = (data['quantity'] as num?)?.toInt() ?? 1;
    double? purchasePrice = (data['purchase_price'] as num?)?.toDouble();
    String currency = data['currency'] as String? ?? 'EUR';
    String? rack = data['rack'] as String?;
    String? shelf = data['shelf'] as String?;
    String? position = data['position'] as String?;
    String? subRegion = data['sub_region'] as String?;
    String? classification = data['classification'] as String?;
    String? cuveeParcel = data['cuvee_parcel'] as String?;
    double? alcoholPct = (data['alcohol_pct'] as num?)?.toDouble();
    String? aiSummary = data['ai_summary'] as String?;
    List<dynamic>? foodPairings = data['food_pairings'] as List<dynamic>?;
    int? idealDrinkingStart = (data['ideal_drinking_start'] as num?)?.toInt();
    int? idealDrinkingEnd = (data['ideal_drinking_end'] as num?)?.toInt();
    int? peakDrinkingStart = (data['peak_drinking_start'] as num?)?.toInt();
    int? peakDrinkingEnd = (data['peak_drinking_end'] as num?)?.toInt();
    double? estimatedMarketValue = (data['estimated_market_value'] as num?)?.toDouble();
    List<dynamic>? grapes = data['grapes'] as List<dynamic>?;

    // If added offline without full info, attempt Gemini enrichment
    bool needsVintageResolution = false;
    if (vintage == null || region == null || region.isEmpty) {
      try {
        final enriched = await _enrichWineWithGemini(wineName, vintage);
        if (enriched != null) {
          wineName = enriched['name'] as String? ?? wineName;
          producer = enriched['producer'] as String? ?? producer;
          vintage = vintage ?? enriched['vintage'] as int?;
          country = country ?? enriched['country'] as String?;
          region = region ?? enriched['region'] as String?;
          appellation = appellation ?? enriched['appellation'] as String?;
          wineType = enriched['wine_type'] as String? ?? wineType;
        }
      } catch (e) {
        debugPrint('Gemini enrichment failed during sync: $e');
      }

      if (vintage == null) {
        needsVintageResolution = true;
      }
    }

    // 1. Insert Wine
    final wineInsert = await _supabase.from('wines').insert({
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
      if (data['tasting_notes'] != null) 'tasting_notes': data['tasting_notes'] as String,
      if (aiSummary != null) 'ai_summary': aiSummary,
      if (foodPairings != null) 'ai_food_pairings': foodPairings,
      if (idealDrinkingStart != null) 'ideal_drinking_start': idealDrinkingStart,
      if (idealDrinkingEnd != null) 'ideal_drinking_end': idealDrinkingEnd,
      if (peakDrinkingStart != null) 'peak_drinking_start': peakDrinkingStart,
      if (peakDrinkingEnd != null) 'peak_drinking_end': peakDrinkingEnd,
      if (estimatedMarketValue != null) 'estimated_market_value': estimatedMarketValue,
      if (grapes != null && grapes.isNotEmpty) 'grapes': grapes,
    }).select().single();

    final wineId = wineInsert['id'] as String;

    // 2. Insert Bottle
    final bottleInsert = await _supabase.from('bottles').insert({
      'cellar_id': cellarId,
      'wine_id': wineId,
      'added_by': userId,
      'owner_id': userId,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'currency': currency,
      'rack': rack,
      'shelf': shelf,
      'position': position,
      'notes': notes,
      'status': 'in_cellar',
    }).select('*, wines(*)').single();

    final bottle = Bottle.fromJson(bottleInsert);

    // 3. Deferred photo upload if local photo was queued
    if (!kIsWeb && action.localPhotoPath != null && action.localPhotoPath!.isNotEmpty) {
      try {
        final photoFile = File(action.localPhotoPath!);
        if (await photoFile.exists()) {
          final fileExt = photoFile.path.split('.').last;
          final fileName = '$userId/${bottle.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          final bytes = await photoFile.readAsBytes();
          await _supabase.storage.from('labels').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: fileExt == 'png' ? 'image/png' : 'image/jpeg',
              upsert: true,
            ),
          );
          final publicUrl = _supabase.storage.from('labels').getPublicUrl(fileName);
          await _supabase.from('bottle_photos').insert({
            'bottle_id': bottle.id,
            'storage_path': publicUrl,
            'photo_type': 'front',
          });
        }
      } catch (photoErr) {
        debugPrint('Deferred photo upload notice: $photoErr');
      }
    }

    // Replace temporary offline bottle with synced real bottle in local cache
    final cached = _offlineStorage.getCachedBottles(cellarId);
    final tempId = action.data['temp_bottle_id'] as String?;
    if (tempId != null) {
      cached.removeWhere((b) => b.id == tempId);
    }
    cached.removeWhere((b) => b.id == bottle.id);
    cached.insert(0, bottle);
    await _offlineStorage.saveCachedBottles(cellarId, cached);

    if (needsVintageResolution) {
      final item = {
        'bottle_id': bottle.id,
        'wine_id': wineId,
        'wine_name': wineName,
        'producer': producer,
        'cellar_id': cellarId,
      };
      await _offlineStorage.addPendingResolutionWine(item);
      return item;
    }

    return null;
  }

  Future<void> _syncConsumeBottle(OfflineAction action) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    final data = action.data;
    final bottleId = data['bottle_id'] as String;
    final rating = (data['rating'] as num?)?.toInt() ?? 5;
    final notes = data['notes'] as String?;
    final foodPaired = data['food_paired'] as String?;

    // Fetch current bottle
    final bottleRes = await _supabase
        .from('bottles')
        .select('*, wines(*)')
        .eq('id', bottleId)
        .maybeSingle();

    if (bottleRes != null) {
      final currentQuantity = (bottleRes['quantity'] as num?)?.toInt() ?? 1;
      if (currentQuantity > 1) {
        await _supabase.from('bottles').update({
          'quantity': currentQuantity - 1,
        }).eq('id', bottleId);
      } else {
        await _supabase.from('bottles').update({
          'status': 'consumed',
          'consumed_at': DateTime.now().toIso8601String(),
        }).eq('id', bottleId);
      }

      if (userId != null && bottleRes['wine_id'] != null) {
        await _supabase.from('tasting_log').insert({
          'wine_id': bottleRes['wine_id'],
          'bottle_id': bottleId,
          'user_id': userId,
          'rating': rating,
          'tasting_notes': notes,
          'food_paired': foodPaired,
          'consumed_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> _syncUpdateBottle(OfflineAction action) async {
    final data = action.data;
    if (data['action'] == 'move') {
      await _syncMoveBottle(action);
      return;
    }
    final bottleId = data['bottle_id'] as String?;
    if (bottleId == null) {
      if (data.containsKey('wine_id')) {
        await _syncUpdateWine(action);
      }
      return;
    }
    final updates = Map<String, dynamic>.from(data)..remove('bottle_id');
    if (updates.containsKey('quantity')) {
      updates['quantity'] = (updates['quantity'] as num?)?.toInt();
    }
    if (updates.containsKey('purchase_price')) {
      updates['purchase_price'] = (updates['purchase_price'] as num?)?.toDouble();
    }
    if (updates.isNotEmpty) {
      await _supabase.from('bottles').update(updates).eq('id', bottleId);
    }
  }

  Future<void> _syncMoveBottle(OfflineAction action) async {
    final data = action.data;
    final bottleId = data['bottle_id'] as String?;
    final targetCellarId = (data['target_cellar_id'] ?? action.cellarId) as String?;
    final quantityToMove = (data['quantity_to_move'] as num?)?.toInt() ?? 1;

    if (bottleId == null || targetCellarId == null) return;

    final bottleRes = await _supabase
        .from('bottles')
        .select('*, wines(*)')
        .eq('id', bottleId)
        .maybeSingle();

    if (bottleRes == null) return;
    final currentQty = (bottleRes['quantity'] as num?)?.toInt() ?? 1;
    final user = _supabase.auth.currentUser;

    if (quantityToMove >= currentQty) {
      await _supabase.from('bottles').update({
        'cellar_id': targetCellarId,
      }).eq('id', bottleId);
    } else {
      await _supabase.from('bottles').update({
        'quantity': currentQty - quantityToMove,
      }).eq('id', bottleId);

      await _supabase.from('bottles').insert({
        'cellar_id': targetCellarId,
        'wine_id': bottleRes['wine_id'],
        'added_by': bottleRes['added_by'] ?? user?.id,
        'owner_id': bottleRes['owner_id'] ?? user?.id,
        'quantity': quantityToMove,
        'purchase_price': bottleRes['purchase_price'],
        'currency': bottleRes['currency'] ?? 'EUR',
        'purchase_location': bottleRes['purchase_location'],
        'status': 'in_cellar',
        'notes': bottleRes['notes'],
      });
    }
  }

  Future<void> _syncUpdateWine(OfflineAction action) async {
    final data = action.data;
    final wineId = data['wine_id'] as String?;
    if (wineId == null) return;
    final updates = Map<String, dynamic>.from(data)..remove('wine_id');
    if (updates.isNotEmpty) {
      await _supabase.from('wines').update(updates).eq('id', wineId);
    }
  }

  Future<void> _syncDeleteBottle(OfflineAction action) async {
    final bottleId = action.data['bottle_id'] as String;
    await _supabase.from('bottles').delete().eq('id', bottleId);
  }

  Future<void> _syncCreateCellar(OfflineAction action) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    if (userId == null) return;

    final data = action.data;
    final res = await _supabase.from('cellars').insert({
      'name': data['name'],
      'nickname': data['nickname'],
      'location_name': data['location_name'],
      'description': data['description'],
      'owner_id': userId,
    }).select().single();

    final cellarId = res['id'] as String;
    try {
      await _supabase.from('cellar_members').insert({
        'cellar_id': cellarId,
        'user_id': userId,
        'role': 'admin',
      });
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Gemini 3.6 Flash Wine Enrichment
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _enrichWineWithGemini(String wineName, int? vintage) async {
    if (_geminiApiKey.isEmpty) return null;

    final prompt = '''
Tu es un sommelier expert. Identifie ce vin et renvoie EXCLUSIVEMENT un objet JSON valide avec les clés suivantes :
{
  "name": "Nom complet du vin",
  "producer": "Nom du domaine / producteur",
  "vintage": ${vintage ?? "null ou entier estimé"},
  "wine_type": "red|white|rosé|sparkling|dessert|fortified|orange",
  "country": "Pays",
  "region": "Région",
  "appellation": "Appellation",
  "grapes": ["Cépage 1", "Cépage 2"],
  "ideal_drinking_start": 2024,
  "ideal_drinking_end": 2032
}

Vin à analyser : "$wineName" ${vintage != null ? "Millésime : $vintage" : ""}
Réponds UNIQUEMENT avec le JSON strict, sans markdown ni texte additionnel.
''';

    final activeModels = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.litePreferred);

    for (final model in activeModels) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );

        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {'temperature': 0.1, 'responseMimeType': 'application/json'}
          }),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          final text = json['candidates']?[0]?['content']?[0]?['text'] ??
              json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null) {
            AiCostTrackerService().recordRawResponse(
              model: model,
              feature: 'offline_enrichment',
              responseJson: json,
              promptFallbackText: prompt,
              candidateFallbackText: text,
              userId: _supabase.auth.currentUser?.id,
            );
            return jsonDecode(text.trim()) as Map<String, dynamic>;
          }
        } else if (res.statusCode == 429) {
          GeminiModelRegistry.recordRateLimit(model);
          AppLogger.warning('SYNC_AI', 'Model $model hit 429 during sync enrichment, trying next');
        }
      } catch (e) {
        AppLogger.warning('SYNC_AI', 'Model $model sync enrichment error: $e');
      }
    }
    return null;
  }

  Future<void> _syncUpdateCellar(OfflineAction action) async {
    final cellarId = action.cellarId;
    if (cellarId == null) return;
    try {
      await _supabase.from('cellars').update(action.data).eq('id', cellarId);
    } catch (_) {
      final safe = Map<String, dynamic>.from(action.data);
      safe.remove('wifi_ssid');
      safe.remove('radius_meters');
      try {
        await _supabase.from('cellars').update(safe).eq('id', cellarId);
      } catch (_) {
        if (safe.containsKey('name')) {
          await _supabase.from('cellars').update({'name': safe['name']}).eq('id', cellarId);
        }
      }
    }
  }
}
