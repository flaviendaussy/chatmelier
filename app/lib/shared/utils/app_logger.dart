import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  bool isSyncedToServer;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
    this.isSyncedToServer = false,
  });

  String get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '🚨';
    }
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() {
    final errStr = error != null ? '\nError: $error' : '';
    return '[$formattedTime] ${level.name.toUpperCase()} [$tag] $message$errStr';
  }
}

class AppLogger {
  static final List<LogEntry> _logs = [];
  static const int _maxLogs = 600;
  static final ValueNotifier<int> logChangeNotifier = ValueNotifier<int>(0);
  
  static SupabaseClient? _supabaseClient;
  static final List<LogEntry> _pendingServerQueue = [];
  static bool _isSyncing = false;
  static Timer? _autoSyncTimer;

  static List<LogEntry> get logs => List.unmodifiable(_logs);
  static int get pendingCount => _pendingServerQueue.length;

  /// Initialize Supabase client for centralized remote logging
  static void init(SupabaseClient client) {
    _supabaseClient = client;
    _autoSyncTimer?.cancel();
    // Auto-flush pending logs to server every 20 seconds
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_pendingServerQueue.isNotEmpty) {
        flushToServer();
      }
    });
  }

  static void _add(LogLevel level, String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);
    _pendingServerQueue.add(entry);

    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    logChangeNotifier.value++;

    final formatted = entry.toString();
    debugPrint(formatted);

    // If critical error or warning, trigger an immediate push to server in background
    if ((level == LogLevel.error || level == LogLevel.warning) && _supabaseClient != null) {
      Future.delayed(const Duration(milliseconds: 300), () => flushToServer());
    }
  }

  static void debug(String tag, String message) {
    _add(LogLevel.debug, tag, message);
  }

  static void info(String tag, String message) {
    _add(LogLevel.info, tag, message);
  }

  static void warning(String tag, String message, [Object? error]) {
    _add(LogLevel.warning, tag, message, error);
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _add(LogLevel.error, tag, message, error, stackTrace);
  }

  static void clear() {
    _logs.clear();
    _pendingServerQueue.clear();
    logChangeNotifier.value++;
  }

  /// Manually or automatically push unsynced logs to central Supabase backend
  static Future<int> flushToServer() async {
    final client = _supabaseClient;
    if (client == null || _isSyncing || _pendingServerQueue.isEmpty) return 0;

    _isSyncing = true;
    final batch = List<LogEntry>.from(_pendingServerQueue);

    try {
      final user = client.auth.currentUser;
      final payload = batch.map((e) {
        return {
          'user_id': user?.id,
          'device_id': kIsWeb ? 'Web Browser' : defaultTargetPlatform.name,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'app_version': '1.2.0',
          'tag': e.tag,
          'level': e.level.name,
          'message': e.message,
          'error_details': e.error != null ? '${e.error}${e.stackTrace != null ? "\n${e.stackTrace}" : ""}' : null,
          'created_at': e.timestamp.toIso8601String(),
        };
      }).toList();

      await client.from('app_diagnostic_logs').insert(payload).timeout(const Duration(seconds: 5));

      for (final item in batch) {
        item.isSyncedToServer = true;
      }
      _pendingServerQueue.removeWhere((item) => batch.contains(item));
      logChangeNotifier.value++;
      return batch.length;
    } catch (e) {
      debugPrint('AppLogger central sync notice: $e');
      return 0;
    } finally {
      _isSyncing = false;
    }
  }

  /// Retrieve central logs across all devices from Supabase
  static Future<List<Map<String, dynamic>>> fetchServerLogs({int limit = 150}) async {
    final client = _supabaseClient;
    if (client == null) return [];

    try {
      final res = await client
          .from('app_diagnostic_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 5));
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('Error fetching remote central logs: $e');
      return [];
    }
  }

  static String exportDiagnosticReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== CHATMELIER DIAGNOSTIC REPORT ===');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total local logs: ${_logs.length}');
    buffer.writeln('Pending server sync: ${_pendingServerQueue.length}');
    buffer.writeln('====================================\n');

    for (final entry in _logs) {
      buffer.writeln('${entry.toString()} ${entry.isSyncedToServer ? "☁️ [SYNCED]" : "⏳ [LOCAL]"}');
      if (entry.stackTrace != null) {
        buffer.writeln('StackTrace: ${entry.stackTrace}');
      }
    }

    return buffer.toString();
  }
}
