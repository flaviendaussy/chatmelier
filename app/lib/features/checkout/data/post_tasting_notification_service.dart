import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/router.dart';
import '../../../shared/utils/app_logger.dart';
import '../../journal/presentation/tasting_questionnaire_sheet.dart';

/// A pending post-tasting notification stored in SharedPreferences.
class PendingTastingNotification {
  final String bottleId;
  final String wineName;
  final int? vintage;
  final String? producer;
  final String? region;
  final String? wineType;
  final DateTime scheduledAt; // When to show the notification
  final DateTime checkedOutAt; // When the bottle was checked out

  PendingTastingNotification({
    required this.bottleId,
    required this.wineName,
    this.vintage,
    this.producer,
    this.region,
    this.wineType,
    required this.scheduledAt,
    required this.checkedOutAt,
  });

  Map<String, dynamic> toJson() => {
    'bottleId': bottleId,
    'wineName': wineName,
    'vintage': vintage,
    'producer': producer,
    'region': region,
    'wineType': wineType,
    'scheduledAt': scheduledAt.toIso8601String(),
    'checkedOutAt': checkedOutAt.toIso8601String(),
  };

  factory PendingTastingNotification.fromJson(Map<String, dynamic> json) =>
      PendingTastingNotification(
        bottleId: json['bottleId'] as String,
        wineName: json['wineName'] as String,
        vintage: (json['vintage'] as num?)?.toInt() ?? int.tryParse(json['vintage']?.toString() ?? ''),
        producer: json['producer'] as String?,
        region: json['region'] as String?,
        wineType: json['wineType'] as String?,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        checkedOutAt: DateTime.parse(json['checkedOutAt'] as String),
      );

  bool get isDue => DateTime.now().isAfter(scheduledAt);
}

/// Manages scheduling and displaying post-tasting feedback notifications.
///
/// When a bottle is checked out, a notification is scheduled for 1 hour after
/// the estimated tasting time. The notification prompts the user to rate and
/// comment on the wine. Snooze options allow deferring by +1h, +2h, or "ce soir" (9 PM).
class PostTastingNotificationService {
  static const _storageKey = 'pending_tasting_notifications';

  Timer? _checkTimer;
  BuildContext? _appContext;

  /// Initialize the service with the app's root context. Call once at app startup.
  void init(BuildContext context) {
    _appContext = context;
    _startPeriodicCheck();
  }

  void dispose() {
    _checkTimer?.cancel();
  }

  /// Schedule a notification 1 hour after checkout for a given bottle.
  Future<void> schedulePostCheckout({
    required String bottleId,
    required String wineName,
    int? vintage,
    String? producer,
    String? region,
    String? wineType,
    Duration delayAfterCheckout = const Duration(hours: 1),
  }) async {
    final now = DateTime.now();
    final notification = PendingTastingNotification(
      bottleId: bottleId,
      wineName: wineName,
      vintage: vintage,
      producer: producer,
      region: region,
      wineType: wineType,
      scheduledAt: now.add(delayAfterCheckout),
      checkedOutAt: now,
    );

    final prefs = await SharedPreferences.getInstance();
    final existing = _loadAll(prefs);
    // Don't duplicate for same bottle
    existing.removeWhere((n) => n.bottleId == bottleId);
    existing.add(notification);
    await _saveAll(prefs, existing);
  }

  /// Snooze a notification by a given duration.
  Future<void> snooze(String bottleId, Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final all = _loadAll(prefs);
    final idx = all.indexWhere((n) => n.bottleId == bottleId);
    if (idx >= 0) {
      final old = all[idx];
      all[idx] = PendingTastingNotification(
        bottleId: old.bottleId,
        wineName: old.wineName,
        vintage: old.vintage,
        producer: old.producer,
        region: old.region,
        wineType: old.wineType,
        scheduledAt: DateTime.now().add(duration),
        checkedOutAt: old.checkedOutAt,
      );
      await _saveAll(prefs, all);
    }
  }

  /// Snooze until tonight at 9 PM (or tomorrow 9 PM if already past 9 PM).
  Future<void> snoozeToCeSoir(String bottleId) async {
    final now = DateTime.now();
    var tonight = DateTime(now.year, now.month, now.day, 21, 0);
    if (now.isAfter(tonight)) {
      tonight = tonight.add(const Duration(days: 1));
    }
    final duration = tonight.difference(now);
    await snooze(bottleId, duration);
  }

  /// Dismiss / remove a notification permanently (after user gives feedback).
  Future<void> dismiss(String bottleId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = _loadAll(prefs);
    all.removeWhere((n) => n.bottleId == bottleId);
    await _saveAll(prefs, all);
  }

  /// Check for due notifications and show a dialog if any are ready.
  Future<void> checkAndShow() async {
    final ctx = rootNavigatorKey.currentContext ?? _appContext;
    if (ctx == null || !ctx.mounted || Navigator.maybeOf(ctx) == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final all = _loadAll(prefs);
      final due = all.where((n) => n.isDue).toList();

      for (final notification in due) {
        final currentCtx = rootNavigatorKey.currentContext ?? _appContext;
        if (currentCtx == null || !currentCtx.mounted || Navigator.maybeOf(currentCtx) == null) return;
        await _showNotificationDialog(currentCtx, notification);
      }
    } catch (e) {
      AppLogger.warning('NOTIFICATION', 'Error checking post tasting notifications: $e');
    }
  }

  /// Get all pending notifications (for debugging or display).
  Future<List<PendingTastingNotification>> getPending() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadAll(prefs);
  }

  // — Private helpers —

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    // Check every 2 minutes for due notifications
    _checkTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      checkAndShow();
    });
    // Also check immediately on init
    Future.delayed(const Duration(seconds: 5), () => checkAndShow());
  }

  List<PendingTastingNotification> _loadAll(SharedPreferences prefs) {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PendingTastingNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(SharedPreferences prefs, List<PendingTastingNotification> notifications) async {
    // Purge notifications older than 48h to avoid infinite accumulation
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    notifications.removeWhere((n) => n.checkedOutAt.isBefore(cutoff));
    await prefs.setString(_storageKey, jsonEncode(notifications.map((n) => n.toJson()).toList()));
  }

  Future<void> _showNotificationDialog(BuildContext context, PendingTastingNotification notification) async {
    if (!context.mounted || Navigator.maybeOf(context) == null) return;

    final vintageStr = notification.vintage != null ? ' ${notification.vintage}' : '';
    final producerStr = notification.producer != null && notification.producer!.isNotEmpty
        ? ' — ${notification.producer}'
        : '';

    try {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🍷', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Alors, cette dégustation ?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                tooltip: 'Annuler',
                onPressed: () => Navigator.of(ctx).pop('dismiss'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(ctx).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Vous avez sorti '),
                    TextSpan(
                      text: '${notification.wineName}$vintageStr$producerStr',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' il y a ${_formatTimeSince(notification.checkedOutAt)}. ',
                    ),
                    const TextSpan(
                      text: 'Prenez 30 secondes pour noter vos impressions afin d\'affiner votre profil de goût !',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Color(0xFFD4AF37)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vos réponses permettent à l\'IA de mieux recommander vos prochaines bouteilles.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('dismiss'),
              child: const Text(
                'Ignorer',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Plus tard',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              onSelected: (val) => Navigator.of(ctx).pop(val),
              itemBuilder: (popCtx) => [
                const PopupMenuItem(
                  value: 'snooze_1h',
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Dans 1 heure'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'snooze_2h',
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Dans 2 heures'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'snooze_tonight',
                  child: Row(
                    children: [
                      Icon(Icons.nightlight_round, size: 18),
                      SizedBox(width: 8),
                      Text('Ce soir à 21h'),
                    ],
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop('feedback'),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Donner mon avis', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (result == null || result == 'dismiss') {
        await dismiss(notification.bottleId);
        return;
      }

      switch (result) {
        case 'snooze_1h':
          await snooze(notification.bottleId, const Duration(hours: 1));
        case 'snooze_2h':
          await snooze(notification.bottleId, const Duration(hours: 2));
        case 'snooze_tonight':
          await snoozeToCeSoir(notification.bottleId);
        case 'feedback':
          await dismiss(notification.bottleId);
          final targetCtx = rootNavigatorKey.currentContext ?? context;
          if (targetCtx.mounted && Navigator.maybeOf(targetCtx) != null) {
            TastingQuestionnaireSheet.show(
              targetCtx,
              wineName: notification.wineName,
              vintage: notification.vintage,
              producer: notification.producer,
              region: notification.region,
              wineType: notification.wineType,
            );
          }
      }
    } catch (e) {
      AppLogger.warning('NOTIFICATION', 'Could not show post tasting dialog: $e');
    }
  }

  String _formatTimeSince(DateTime since) {
    final diff = DateTime.now().difference(since);
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }
}

/// Riverpod provider for the PostTastingNotificationService singleton.
final postTastingNotificationProvider = Provider<PostTastingNotificationService>((ref) {
  final service = PostTastingNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});
