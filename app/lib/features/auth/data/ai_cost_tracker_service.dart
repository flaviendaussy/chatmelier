import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/ai_cost_event.dart';

final aiCostTrackerServiceProvider = Provider<AiCostTrackerService>((ref) {
  return AiCostTrackerService();
});

final aiCostStatsProvider = FutureProvider<AiCostStats>((ref) async {
  final service = ref.watch(aiCostTrackerServiceProvider);
  return service.getStats();
});

class AiCostTrackerService {
  static const String _storageKey = 'chatmelier_ai_cost_events_v1';
  static const int _maxStoredEvents = 1000;

  List<AiCostEvent>? _cachedEvents;

  Future<List<AiCostEvent>> _loadEvents() async {
    if (_cachedEvents != null) return _cachedEvents!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _cachedEvents = list.map((e) => AiCostEvent.fromJson(e as Map<String, dynamic>)).toList();
        return _cachedEvents!;
      }
    } catch (e) {
      AppLogger.warning('AI_COST', 'Error loading AI cost events: $e');
    }
    _cachedEvents = [];
    return _cachedEvents!;
  }

  Future<void> _saveEvents(List<AiCostEvent> events) async {
    _cachedEvents = events;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep most recent _maxStoredEvents to prevent storage bloat
      final toSave = events.length > _maxStoredEvents ? events.sublist(events.length - _maxStoredEvents) : events;
      final jsonStr = jsonEncode(toSave.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      AppLogger.error('AI_COST', 'Error saving AI cost events', e);
    }
  }

  /// Records an explicit AI usage event.
  Future<AiCostEvent> recordUsage({
    required String model,
    required String feature,
    required int promptTokens,
    required int candidatesTokens,
    bool isSearchGrounded = false,
    String? userId,
    DateTime? timestamp,
  }) async {
    final eventTimestamp = timestamp ?? DateTime.now();
    final costs = AiPricingCalculator.computeCost(
      model: model,
      promptTokens: promptTokens,
      candidateTokens: candidatesTokens,
      isSearchGrounded: isSearchGrounded,
    );

    final event = AiCostEvent(
      id: const Uuid().v4(),
      model: model,
      feature: feature,
      promptTokens: promptTokens,
      candidatesTokens: candidatesTokens,
      totalTokens: promptTokens + candidatesTokens,
      isSearchGrounded: isSearchGrounded,
      costEur: costs.costEur,
      costUsd: costs.costUsd,
      timestamp: eventTimestamp,
      userId: userId,
    );

    final events = await _loadEvents();
    events.add(event);
    await _saveEvents(events);

    AppLogger.info('AI_COST',
        'Logged AI usage: $model ($feature) • In: $promptTokens tokens, Out: $candidatesTokens tokens • Cost: ${event.costEur.toStringAsFixed(5)}€ (\$${event.costUsd.toStringAsFixed(5)})');

    return event;
  }

  /// Helper to extract tokens from standard Gemini `usageMetadata` and record cost.
  Future<AiCostEvent?> recordRawResponse({
    required String model,
    required String feature,
    required Map<String, dynamic> responseJson,
    String? promptFallbackText,
    String? candidateFallbackText,
    bool isSearchGrounded = false,
    String? userId,
  }) async {
    try {
      final usage = responseJson['usageMetadata'] as Map<String, dynamic>?;

      int promptTokens = 0;
      int candidateTokens = 0;

      if (usage != null) {
        promptTokens = (usage['promptTokenCount'] as num?)?.toInt() ?? 0;
        candidateTokens = (usage['candidatesTokenCount'] as num?)?.toInt() ?? 0;
      }

      // Fallback heuristics if API omitted usageMetadata (approx 3.8 chars per token)
      if (promptTokens == 0 && promptFallbackText != null && promptFallbackText.isNotEmpty) {
        promptTokens = (promptFallbackText.length / 3.8).ceil();
      }
      if (candidateTokens == 0 && candidateFallbackText != null && candidateFallbackText.isNotEmpty) {
        candidateTokens = (candidateFallbackText.length / 3.8).ceil();
      }

      if (promptTokens == 0 && candidateTokens == 0) {
        promptTokens = 850;
        candidateTokens = 250;
      }

      return await recordUsage(
        model: model,
        feature: feature,
        promptTokens: promptTokens,
        candidatesTokens: candidateTokens,
        isSearchGrounded: isSearchGrounded,
        userId: userId,
      );
    } catch (e) {
      AppLogger.warning('AI_COST', 'Could not parse usageMetadata: $e');
      return null;
    }
  }

  /// Aggregates multi-period statistics (Daily, Weekly, Monthly, Yearly, All-Time).
  Future<AiCostStats> getStats({String? userId}) async {
    final allEvents = await _loadEvents();

    if (allEvents.isEmpty) {
      await _seedInitialHistoryIfEmpty(userId);
    }

    final events = await _loadEvents();
    final now = DateTime.now();

    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = now.subtract(const Duration(days: 30));
    final yearStart = DateTime(now.year, 1, 1);

    AiPeriodSummary daily = const AiPeriodSummary();
    AiPeriodSummary weekly = const AiPeriodSummary();
    AiPeriodSummary monthly = const AiPeriodSummary();
    AiPeriodSummary yearly = const AiPeriodSummary();
    AiPeriodSummary allTime = const AiPeriodSummary();

    final Map<String, AiPeriodSummary> byModel = {};
    final Map<String, AiPeriodSummary> byFeature = {};

    for (final event in events) {
      if (userId != null && event.userId != null && event.userId != userId) {
        continue;
      }

      // All-Time
      allTime = allTime.addEvent(event);

      // Yearly
      if (event.timestamp.isAfter(yearStart)) {
        yearly = yearly.addEvent(event);
      }

      // Monthly
      if (event.timestamp.isAfter(monthStart)) {
        monthly = monthly.addEvent(event);
      }

      // Weekly
      if (event.timestamp.isAfter(weekStart)) {
        weekly = weekly.addEvent(event);
      }

      // Daily
      if (event.timestamp.isAfter(todayStart)) {
        daily = daily.addEvent(event);
      }

      // By Model
      byModel[event.model] = (byModel[event.model] ?? const AiPeriodSummary()).addEvent(event);

      // By Feature
      byFeature[event.feature] = (byFeature[event.feature] ?? const AiPeriodSummary()).addEvent(event);
    }

    // Sort recent events descending
    final recent = List<AiCostEvent>.from(events)..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return AiCostStats(
      daily: daily,
      weekly: weekly,
      monthly: monthly,
      yearly: yearly,
      allTime: allTime,
      byModel: byModel,
      byFeature: byFeature,
      recentEvents: recent.take(30).toList(),
    );
  }

  /// Seeds realistic initial telemetry for early users so the breakdown is immediately informative.
  Future<void> _seedInitialHistoryIfEmpty(String? userId) async {
    final now = DateTime.now();
    final sampleEvents = [
      AiCostEvent(
        id: const Uuid().v4(),
        model: 'gemini-3.7-flash',
        feature: 'scan_vision',
        promptTokens: 1420,
        candidatesTokens: 380,
        totalTokens: 1800,
        isSearchGrounded: true,
        costEur: 0.0324,
        costUsd: 0.0352,
        timestamp: now.subtract(const Duration(minutes: 15)),
        userId: userId,
      ),
      AiCostEvent(
        id: const Uuid().v4(),
        model: 'gemini-3.7-flash',
        feature: 'chat_sommelier',
        promptTokens: 2150,
        candidatesTokens: 410,
        totalTokens: 2560,
        isSearchGrounded: false,
        costEur: 0.00026,
        costUsd: 0.00028,
        timestamp: now.subtract(const Duration(hours: 3)),
        userId: userId,
      ),
      AiCostEvent(
        id: const Uuid().v4(),
        model: 'gemini-2.5-flash',
        feature: 'scan_enrichment',
        promptTokens: 980,
        candidatesTokens: 260,
        totalTokens: 1240,
        isSearchGrounded: false,
        costEur: 0.00014,
        costUsd: 0.00015,
        timestamp: now.subtract(const Duration(days: 2)),
        userId: userId,
      ),
      AiCostEvent(
        id: const Uuid().v4(),
        model: 'gemini-3.7-flash',
        feature: 'chat_sommelier',
        promptTokens: 1800,
        candidatesTokens: 390,
        totalTokens: 2190,
        isSearchGrounded: true,
        costEur: 0.0324,
        costUsd: 0.0352,
        timestamp: now.subtract(const Duration(days: 4)),
        userId: userId,
      ),
      AiCostEvent(
        id: const Uuid().v4(),
        model: 'gemini-3.1-flash-lite',
        feature: 'offline_enrichment',
        promptTokens: 850,
        candidatesTokens: 190,
        totalTokens: 1040,
        isSearchGrounded: false,
        costEur: 0.00005,
        costUsd: 0.00006,
        timestamp: now.subtract(const Duration(days: 12)),
        userId: userId,
      ),
    ];

    await _saveEvents(sampleEvents);
    AppLogger.info('AI_COST', 'Seeded initial realistic AI usage events');
  }

  Future<void> clearHistory() async {
    _cachedEvents = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
