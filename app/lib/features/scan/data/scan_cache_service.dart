import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/scan_result.dart';

/// Local SHA-256 fingerprint cache for scanned wine labels.
/// Ensures identical photos never query Gemini API twice within the TTL window.
class ScanCacheService {
  static const String _prefKey = 'chatmelier_scan_hash_cache_v1';
  static const int _maxCachedEntries = 200;
  static const Duration defaultTtl = Duration(days: 30);

  static final ScanCacheService _instance = ScanCacheService._internal();
  factory ScanCacheService() => _instance;
  ScanCacheService._internal();

  final Map<String, Map<String, dynamic>> _memoryCache = {};
  bool _isLoaded = false;

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            _memoryCache[entry.key] = entry.value as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('SCAN_CACHE', 'Failed to load local scan cache: $e');
    }
    _isLoaded = true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep most recent entries
      if (_memoryCache.length > _maxCachedEntries) {
        final sortedKeys = _memoryCache.keys.toList()
          ..sort((a, b) {
            final dateA = DateTime.tryParse(_memoryCache[a]?['timestamp'] as String? ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(_memoryCache[b]?['timestamp'] as String? ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });
        final pruned = <String, Map<String, dynamic>>{};
        for (final k in sortedKeys.take(_maxCachedEntries)) {
          pruned[k] = _memoryCache[k]!;
        }
        _memoryCache
          ..clear()
          ..addAll(pruned);
      }
      await prefs.setString(_prefKey, jsonEncode(_memoryCache));
    } catch (e) {
      AppLogger.warning('SCAN_CACHE', 'Failed to persist scan cache: $e');
    }
  }

  /// Retrieves a cached scan result if present and not expired.
  Future<ScanResult?> getCachedResult(String sha256Hash) async {
    await _ensureLoaded();
    final entry = _memoryCache[sha256Hash];
    if (entry == null) return null;

    final timestampStr = entry['timestamp'] as String?;
    if (timestampStr != null) {
      final cachedAt = DateTime.tryParse(timestampStr);
      if (cachedAt != null && DateTime.now().difference(cachedAt) > defaultTtl) {
        _memoryCache.remove(sha256Hash);
        await _persist();
        return null;
      }
    }

    final rawJson = entry['result'] as Map<String, dynamic>?;
    if (rawJson == null) return null;

    try {
      AppLogger.info('SCAN_CACHE', '⚡ Cache HIT for image hash: ${sha256Hash.substring(0, 10)}... Zero Gemini API cost!');
      return ScanResult.fromJson(rawJson);
    } catch (e) {
      AppLogger.warning('SCAN_CACHE', 'Failed to deserialize cached ScanResult: $e');
      return null;
    }
  }

  /// Stores a newly scanned result under its SHA-256 fingerprint.
  Future<void> cacheResult(String sha256Hash, ScanResult result) async {
    await _ensureLoaded();
    _memoryCache[sha256Hash] = {
      'timestamp': DateTime.now().toIso8601String(),
      'result': result.toJson(),
    };
    await _persist();
    AppLogger.info('SCAN_CACHE', 'Cached scan result for image hash: ${sha256Hash.substring(0, 10)}...');
  }

  /// Clears in-memory and persistent cache (useful for testing or manual cache clear).
  Future<void> clear() async {
    _memoryCache.clear();
    _isLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
