import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  /// Fixé sur l'appareil : une ligne renvoyée alors qu'elle était déjà arrivée bute sur la
  /// clé primaire au lieu de s'enregistrer une seconde fois (T3).
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  bool isSyncedToServer;

  LogEntry({
    String? id,
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
    this.isSyncedToServer = false,
  }) : id = id ?? const Uuid().v4();

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


/// La version de l'app, telle qu'elle part avec chaque remontée.
///
/// Elle était écrite en dur — « 1.2.0 » — et ne bougeait plus depuis longtemps : toutes
/// les remontées d'utilisateurs portaient le même numéro, y compris celles venues de
/// builds séparés par des mois. Impossible, en dépouillant, de savoir si un bug était
/// déjà corrigé.
///
/// Les scripts de build la passent en `--dart-define` depuis `pubspec.yaml`. Le repli
/// nomme franchement le cas où personne ne l'a passée, plutôt que d'inventer un numéro.
const String versionApp = String.fromEnvironment(
  'CHATMELIER_VERSION',
  defaultValue: 'dev',
);

/// La version portée par les journaux : suffixée hors release (T3). Un build de profil sur
/// l'émulateur, la vraie version passée en `--dart-define`, se faisait passer pour des
/// lancements de la version publiée (52 « lancements de la 83 » le 17/10, un démarrage de 43 s
/// qui n'était que le rendu logiciel de l'émulateur).
const String versionDesJournaux = kReleaseMode ? versionApp : '$versionApp-${kProfileMode ? 'profile' : 'debug'}';

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
    // Le niveau « debug » reste sur l'appareil (rapport de diagnostic) : il ne part plus au
    // serveur, où il faisait du bruit (799 lignes en 21 jours, V2.3 · D4).
    if (level != LogLevel.debug) _pendingServerQueue.add(entry);

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

  static final Map<String, DateTime> _dernieresFois = {};
  static final Map<String, int> _tus = {};

  /// Vrai si cette erreur n'a pas été journalisée dans les [fenetre] dernières minutes
  /// (V2.3 · D3). Une même panne qui se répète — un renouvellement de session qui échoue en
  /// boucle hors réseau — produisait 216 lignes pour une seule personne. La signature ignore
  /// les chiffres, pour regrouper les répétitions qui ne diffèrent que par un compteur.
  static bool premiereFois(Object erreur, {Duration fenetre = const Duration(minutes: 10)}) {
    final signature = '${erreur.runtimeType}:${erreur.toString().replaceAll(RegExp(r'[0-9]+'), '#')}';
    final cle = signature.length > 160 ? signature.substring(0, 160) : signature;
    final maintenant = DateTime.now();
    final derniere = _dernieresFois[cle];
    if (derniere != null && maintenant.difference(derniere) < fenetre) {
      _tus[cle] = (_tus[cle] ?? 0) + 1;
      return false;
    }
    final tues = _tus.remove(cle);
    _dernieresFois[cle] = maintenant;
    if (tues != null && tues > 0) info('LOGGER', '$tues répétition(s) tue(s) de : ${cle.length > 80 ? cle.substring(0, 80) : cle}');
    return true;
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

  /// Envoie au serveur les lignes en attente ; rend le nombre de lignes rangées.
  ///
  /// Chaque ligne part avec son identifiant (T3). Le délai de 5 s n'annule pas la requête :
  /// un lot « expiré » arrivait souvent quand même, restait en file et repartait — chaque
  /// ligne enregistrée deux ou trois fois, aux mêmes millisecondes. Désormais, un lot qui
  /// bute sur une clé déjà présente (23505) repart ligne à ligne, et celles qui butent encore
  /// sont tenues pour rangées. `upsert(ignoreDuplicates)` n'est pas possible : il demande la
  /// lecture de la table, que les comptes n'ont pas.
  static Future<int> flushToServer() async {
    final client = _supabaseClient;
    if (client == null || _isSyncing || _pendingServerQueue.isEmpty) return 0;

    _isSyncing = true;
    final batch = List<LogEntry>.from(_pendingServerQueue);

    try {
      final userId = client.auth.currentUser?.id;
      Future<void> envoyer(List<LogEntry> lignes) =>
          client.from('app_diagnostic_logs').insert([for (final e in lignes) _ligne(e, userId)]).timeout(const Duration(seconds: 5));

      final ranges = <LogEntry>[];
      try {
        await envoyer(batch);
        ranges.addAll(batch);
      } on PostgrestException catch (e) {
        if (e.code != _dejaEnregistree) rethrow;
        for (final ligne in batch) {
          try {
            await envoyer([ligne]);
            ranges.add(ligne);
          } on PostgrestException catch (e) {
            if (e.code == _dejaEnregistree) {
              ranges.add(ligne);
            } else {
              rethrow;
            }
          }
        }
      }
      _marquerRangees(ranges);
      return ranges.length;
    } catch (e) {
      debugPrint('AppLogger central sync notice: $e');
      return 0;
    } finally {
      _isSyncing = false;
    }
  }

  /// Violation d'unicité : la ligne est déjà sur le serveur.
  static const String _dejaEnregistree = '23505';

  static void _marquerRangees(List<LogEntry> ranges) {
    if (ranges.isEmpty) return;
    for (final item in ranges) {
      item.isSyncedToServer = true;
    }
    final ids = {for (final e in ranges) e.id};
    _pendingServerQueue.removeWhere((item) => ids.contains(item.id));
    logChangeNotifier.value++;
  }

  static Map<String, dynamic> _ligne(LogEntry e, String? userId) => {
        'id': e.id,
        'user_id': userId,
        'device_id': kIsWeb ? 'Web Browser' : defaultTargetPlatform.name,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'app_version': versionDesJournaux,
        'tag': e.tag,
        'level': e.level.name,
        'message': e.message,
        'error_details': e.error != null ? '${e.error}${e.stackTrace != null ? "\n${e.stackTrace}" : ""}' : null,
        // Heure locale de l'appareil, sans fuseau : c'est elle que citent les testeurs
        // (« 19h07 »), et toute la table est dans cette convention. Le décalage permet de
        // retrouver l'instant UTC pour croiser avec les journaux du serveur — en Écosse
        // (UTC+1) comme en France (UTC+2), l'heure seule ne suffisait pas.
        'created_at': e.timestamp.toIso8601String(),
        'metadata': {'utc_offset_min': e.timestamp.timeZoneOffset.inMinutes},
      };

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
