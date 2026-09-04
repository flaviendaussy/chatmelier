import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/menu_wine.dart';

final wineKnowledgeCacheServiceProvider = Provider<WineKnowledgeCacheService>((ref) {
  return WineKnowledgeCacheService();
});

/// 📚 Persistent Wine Knowledge Database
/// Caches each wine (specific vintage & cuvée) once recognized,
/// so it never needs to be re-researched from scratch by Gemini.
class WineKnowledgeCacheService {
  static const String _kStorageKey = 'chatmelier_wine_knowledge_db_v1';
  Map<String, Map<String, dynamic>>? _memoryCache;

  /// Generate normalized key: "name__producer__vintage__type"
  static String buildCacheKey(String name, [String producer = '', int? vintage, String type = '']) {
    final cleanName = name.trim().toLowerCase();
    final cleanProd = producer.trim().toLowerCase();
    final v = vintage ?? 0;
    final t = type.trim().toLowerCase();
    return '${cleanName}__${cleanProd}__${v}__$t';
  }

  Future<void> _ensureLoaded() async {
    if (_memoryCache != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        _memoryCache = decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
      } else {
        _memoryCache = {};
      }
    } catch (e) {
      debugPrint('WineKnowledgeCacheService load error: $e');
      _memoryCache = {};
    }
  }

  /// Lookup a known wine profile from database
  Future<MenuWineRadarMetrics?> findSensoryMetrics(
    String name, [
    String producer = '',
    int? vintage,
    String type = '',
  ]) async {
    await _ensureLoaded();
    final key = buildCacheKey(name, producer, vintage, type);
    final data = _memoryCache?[key];
    if (data != null && data['metrics'] != null) {
      return MenuWineRadarMetrics.fromJson(Map<String, dynamic>.from(data['metrics'] as Map));
    }
    // Fallback: search by name and vintage if exact key didn't match
    if (_memoryCache != null) {
      final cleanName = name.trim().toLowerCase();
      for (final entry in _memoryCache!.entries) {
        if (entry.key.startsWith('${cleanName}__')) {
          if (vintage == null || entry.key.contains('__${vintage}__')) {
            if (entry.value['metrics'] != null) {
              return MenuWineRadarMetrics.fromJson(Map<String, dynamic>.from(entry.value['metrics'] as Map));
            }
          }
        }
      }
    }
    return null;
  }

  /// Lookup full cached wine
  Future<MenuWine?> findWine(
    String name, [
    String producer = '',
    int? vintage,
    String type = '',
  ]) async {
    await _ensureLoaded();
    final key = buildCacheKey(name, producer, vintage, type);
    final data = _memoryCache?[key];
    if (data != null) {
      return MenuWine.fromJson(data);
    }
    if (_memoryCache != null) {
      final cleanName = name.trim().toLowerCase();
      for (final entry in _memoryCache!.entries) {
        if (entry.key.startsWith('${cleanName}__')) {
          if (vintage == null || entry.key.contains('__${vintage}__')) {
            return MenuWine.fromJson(entry.value);
          }
        }
      }
    }
    return null;
  }

  /// Save wine knowledge into persistent database
  Future<void> cacheWine(MenuWine wine) async {
    await _ensureLoaded();
    final key = wine.cacheKey;
    _memoryCache?[key] = wine.toJson();
    await _persist();
  }

  /// Bulk cache multiple wines from a scanned menu
  Future<void> bulkCache(List<MenuWine> wines) async {
    await _ensureLoaded();
    for (final w in wines) {
      _memoryCache?[w.cacheKey] = w.toJson();
    }
    await _persist();
  }

  /// Retrieve all known wines in the database
  Future<List<MenuWine>> getAllKnownWines() async {
    await _ensureLoaded();
    final list = <MenuWine>[];
    _memoryCache?.forEach((_, data) {
      try {
        list.add(MenuWine.fromJson(data));
      } catch (_) {}
    });
    return list;
  }

  /// Total count of wines indexed
  Future<int> count() async {
    await _ensureLoaded();
    return _memoryCache?.length ?? 0;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_memoryCache != null) {
        final jsonStr = jsonEncode(_memoryCache);
        await prefs.setString(_kStorageKey, jsonStr);
      }
    } catch (e) {
      debugPrint('WineKnowledgeCacheService persist error: $e');
    }
  }
}
