import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/offline_action.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/cellar.dart';

class OfflineStorageService {
  static const String _kSyncQueueKey = 'chatmelier_offline_sync_queue';
  static const String _kCellarsCacheKey = 'chatmelier_cached_cellars';
  static const String _kBottlesPrefix = 'chatmelier_cached_bottles_';
  static const String _kPendingResolutionWinesKey = 'chatmelier_pending_resolution_wines';
  static const String _kLastSelectedCellarIdKey = 'chatmelier_last_selected_cellar_id';

  final SharedPreferences _prefs;

  OfflineStorageService(this._prefs);

  // ---------------------------------------------------------------------------
  // Active Cellar Persistence
  // ---------------------------------------------------------------------------

  String? getLastSelectedCellarId() {
    return _prefs.getString(_kLastSelectedCellarIdKey);
  }

  Future<void> saveLastSelectedCellarId(String? cellarId) async {
    if (cellarId == null) {
      await _prefs.remove(_kLastSelectedCellarIdKey);
    } else {
      await _prefs.setString(_kLastSelectedCellarIdKey, cellarId);
    }
  }

  // ---------------------------------------------------------------------------
  // Sync Queue Management
  // ---------------------------------------------------------------------------

  List<OfflineAction> getQueue() {
    final raw = _prefs.getString(_kSyncQueueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => OfflineAction.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> enqueueAction(OfflineAction action) async {
    final queue = getQueue();
    queue.add(action);
    await _saveQueue(queue);
  }

  Future<void> queueAction(OfflineAction action) => enqueueAction(action);

  Future<void> removeAction(String actionId) async {
    final queue = getQueue();
    queue.removeWhere((a) => a.id == actionId);
    await _saveQueue(queue);
  }

  Future<void> updateAction(OfflineAction updated) async {
    final queue = getQueue();
    final index = queue.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      queue[index] = updated;
      await _saveQueue(queue);
    }
  }

  Future<void> clearCompletedActions() async {
    final queue = getQueue();
    queue.removeWhere((a) => a.status == OfflineActionStatus.completed);
    await _saveQueue(queue);
  }

  int get pendingActionCount => getQueue().length;

  Future<void> _saveQueue(List<OfflineAction> queue) async {
    final raw = jsonEncode(queue.map((a) => a.toJson()).toList());
    await _prefs.setString(_kSyncQueueKey, raw);
  }

  // ---------------------------------------------------------------------------
  // Cellars Cache
  // ---------------------------------------------------------------------------

  List<Cellar> getCachedCellars() {
    final raw = _prefs.getString(_kCellarsCacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Cellar.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedCellars(List<Cellar> cellars) async {
    final raw = jsonEncode(
      cellars.map((c) => {
        'id': c.id,
        'name': c.name,
        'nickname': c.nickname,
        'location_name': c.locationName,
        'latitude': c.latitude,
        'longitude': c.longitude,
        'description': c.description,
        'owner_id': c.ownerId,
        'created_at': c.createdAt.toIso8601String(),
      }).toList(),
    );
    await _prefs.setString(_kCellarsCacheKey, raw);
  }

  // ---------------------------------------------------------------------------
  // Bottles Cache per Cellar
  // ---------------------------------------------------------------------------

  List<Bottle> getCachedBottles(String cellarId) {
    final raw = _prefs.getString('$_kBottlesPrefix$cellarId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Bottle.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedBottles(String cellarId, List<Bottle> bottles) async {
    final raw = jsonEncode(bottles.map((b) => b.toJson()).toList());
    await _prefs.setString('$_kBottlesPrefix$cellarId', raw);
  }

  /// Apply offline modification directly to cached bottles
  Future<void> applyOfflineConsume(String cellarId, String bottleId) async {
    final bottles = getCachedBottles(cellarId);
    final index = bottles.indexWhere((b) => b.id == bottleId);
    if (index != -1) {
      final current = bottles[index];
      if (current.quantity > 1) {
        bottles[index] = current.copyWith(quantity: current.quantity - 1);
      } else {
        bottles[index] = current.copyWith(status: 'consumed');
      }
      await saveCachedBottles(cellarId, bottles);
    }
  }

  Future<void> applyOfflineAddBottle(String cellarId, Bottle bottle) async {
    final bottles = getCachedBottles(cellarId);
    bottles.insert(0, bottle);
    await saveCachedBottles(cellarId, bottles);
  }

  Future<void> applyOfflineDeleteBottle(String cellarId, String bottleId, {int? quantityToRemove}) async {
    final bottles = getCachedBottles(cellarId);
    final index = bottles.indexWhere((b) => b.id == bottleId);
    if (index != -1) {
      final current = bottles[index];
      if (quantityToRemove != null && quantityToRemove < current.quantity) {
        bottles[index] = current.copyWith(quantity: current.quantity - quantityToRemove);
      } else {
        bottles.removeAt(index);
      }
      await saveCachedBottles(cellarId, bottles);
    }
  }

  Future<void> applyOfflineUpdateQuantity(String cellarId, String bottleId, int newQuantity) async {
    final bottles = getCachedBottles(cellarId);
    final index = bottles.indexWhere((b) => b.id == bottleId);
    if (index != -1) {
      if (newQuantity <= 0) {
        bottles.removeAt(index);
      } else {
        bottles[index] = bottles[index].copyWith(quantity: newQuantity);
      }
      await saveCachedBottles(cellarId, bottles);
    }
  }

  Future<void> applyOfflineUpdateBottle(String bottleId, Map<String, dynamic> updates) async {
    final cellars = getCachedCellars();
    for (final c in cellars) {
      final bottles = getCachedBottles(c.id);
      final index = bottles.indexWhere((b) => b.id == bottleId);
      if (index != -1) {
        final current = bottles[index];
        bottles[index] = current.copyWith(
          quantity: updates.containsKey('quantity')
              ? (updates['quantity'] as num?)?.toInt() ?? current.quantity
              : current.quantity,
          purchasePrice: updates.containsKey('purchase_price')
              ? (updates['purchase_price'] as num?)?.toDouble()
              : current.purchasePrice,
          currency: updates['currency'] is String ? updates['currency'] as String : current.currency,
          purchaseLocation: updates.containsKey('purchase_location') ? updates['purchase_location'] as String? : current.purchaseLocation,
          sourceType: updates.containsKey('source_type') ? updates['source_type'] as String? : current.sourceType,
          sourceDetails: updates.containsKey('source_details') ? updates['source_details'] as String? : current.sourceDetails,
          rack: updates.containsKey('rack') ? updates['rack'] as String? : current.rack,
          shelf: updates.containsKey('shelf') ? updates['shelf'] as String? : current.shelf,
          position: updates.containsKey('position') ? updates['position'] as String? : current.position,
          notes: updates.containsKey('notes') ? updates['notes'] as String? : current.notes,
        );
        await saveCachedBottles(c.id, bottles);
        break;
      }
    }
  }

  Future<void> applyOfflineMoveBottle({
    required String sourceCellarId,
    required String targetCellarId,
    required String bottleId,
    int quantityToMove = 1,
  }) async {
    final sourceBottles = getCachedBottles(sourceCellarId);
    final index = sourceBottles.indexWhere((b) => b.id == bottleId);
    if (index != -1) {
      final bottle = sourceBottles[index];
      if (quantityToMove >= bottle.quantity) {
        sourceBottles.removeAt(index);
        final movedBottle = bottle.copyWith(cellarId: targetCellarId);
        final targetBottles = getCachedBottles(targetCellarId);
        targetBottles.insert(0, movedBottle);
        await saveCachedBottles(targetCellarId, targetBottles);
      } else {
        sourceBottles[index] = bottle.copyWith(quantity: bottle.quantity - quantityToMove);
        final movedBottle = bottle.copyWith(
          id: '${bottle.id}_moved_${DateTime.now().millisecondsSinceEpoch}',
          cellarId: targetCellarId,
          quantity: quantityToMove,
        );
        final targetBottles = getCachedBottles(targetCellarId);
        targetBottles.insert(0, movedBottle);
        await saveCachedBottles(targetCellarId, targetBottles);
      }
      await saveCachedBottles(sourceCellarId, sourceBottles);
    }
  }

  // ---------------------------------------------------------------------------
  // Pending Vintage / Year Resolutions
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> getPendingResolutionWines() {
    final raw = _prefs.getString(_kPendingResolutionWinesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  Future<void> addPendingResolutionWine(Map<String, dynamic> item) async {
    final list = getPendingResolutionWines();
    list.removeWhere((w) => w['bottle_id'] == item['bottle_id']);
    list.add(item);
    await _prefs.setString(_kPendingResolutionWinesKey, jsonEncode(list));
  }

  Future<void> removePendingResolutionWine(String bottleId) async {
    final list = getPendingResolutionWines();
    list.removeWhere((w) => w['bottle_id'] == bottleId);
    await _prefs.setString(_kPendingResolutionWinesKey, jsonEncode(list));
  }
}
