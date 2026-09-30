import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/services/envoi_par_lots.dart';
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

  /// Les coûts partent aussi au serveur (S5) : dans le téléphone seul, on ne pouvait pas
  /// dire si la pub paie l'IA.
  static final EnvoiParLots _envoi = EnvoiParLots(
    table: 'ai_cost_events',
    cleLocale: 'chatmelier_couts_a_envoyer_v1',
  );

  /// Au démarrage : ce qui n'a pas pu partir lors de la dernière session.
  static Future<int> envoyerEnAttente() => _envoi.envoyer();

  /// La ligne serveur d'un événement (table `ai_cost_events`, migration 047).
  @visibleForTesting
  static Map<String, dynamic> ligneServeur(AiCostEvent e) => {
        'event_id': e.id,
        'occurred_at': e.timestamp.toUtc().toIso8601String(),
        'platform': EnvoiParLots.plateforme,
        'app_version': versionApp,
        'build_mode': EnvoiParLots.modeDeBuild,
        'feature': e.feature.length > 60 ? e.feature.substring(0, 60) : e.feature,
        'model': e.model.length > 80 ? e.model.substring(0, 80) : e.model,
        'prompt_tokens': e.promptTokens,
        'output_tokens': e.candidatesTokens,
        'grounded': e.isSearchGrounded,
        'cost_usd': double.parse(e.costUsd.toStringAsFixed(6)),
        'cost_eur': double.parse(e.costEur.toStringAsFixed(6)),
      };

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

  /// Les écritures passent l'une après l'autre. Chaque appelant crée son propre service :
  /// deux enregistrements simultanés relisaient la même liste, et le second effaçait le
  /// premier (vu le 29/09 avec les deux appels payés d'un scan d'étiquette).
  static Future<void> _fileDAttente = Future.value();

  Future<void> _ajouterEnFile(AiCostEvent event) {
    final suite = _fileDAttente.then((_) async {
      _cachedEvents = null; // relire : un autre service a pu écrire entre-temps
      final events = await _loadEvents();
      events.add(event);
      await _saveEvents(events);
    });
    _fileDAttente = suite.catchError((_) {});
    return suite;
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
    int requetesDeRecherche = 1,
    String? userId,
    DateTime? timestamp,
  }) async {
    final eventTimestamp = timestamp ?? DateTime.now();
    final costs = AiPricingCalculator.computeCost(
      model: model,
      promptTokens: promptTokens,
      candidateTokens: candidatesTokens,
      isSearchGrounded: isSearchGrounded,
      requetesDeRecherche: requetesDeRecherche,
      le: eventTimestamp,
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

    await _ajouterEnFile(event);
    await _envoi.ajouter(ligneServeur(event));

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
    int requetesDeRecherche = 1,
    String? userId,
  }) async {
    try {
      final usage = responseJson['usageMetadata'] as Map<String, dynamic>?;

      int promptTokens = 0;
      int candidateTokens = 0;

      if (usage != null) {
        promptTokens = (usage['promptTokenCount'] as num?)?.toInt() ?? 0;
        final candidateCount = (usage['candidatesTokenCount'] as num?)?.toInt() ?? 0;
        final thoughtsCount = (usage['thoughtsTokenCount'] as num?)?.toInt() ?? 0;
        candidateTokens = candidateCount + thoughtsCount;
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
        requetesDeRecherche: requetesDeRecherche,
        userId: userId,
      );
    } catch (e) {
      AppLogger.warning('AI_COST', 'Could not parse usageMetadata: $e');
      return null;
    }
  }

  /// Enregistre ce qu'une fonction IA du serveur a payé (champ `couts`) : un événement par
  /// appel au modèle, avec le nombre réel de recherches Google. Une réponse sans `couts`
  /// (ancienne fonction) n'enregistre rien.
  List<Future<AiCostEvent?>> enregistrerCoutsServeur(Map<String, dynamic> reponse, String? userId) {
    final couts = reponse['couts'];
    if (couts is! List) return const [];
    return [
      for (final c in couts)
        if (c is Map && c['modele'] is String && c['usageMetadata'] is Map)
          recordRawResponse(
            model: c['modele'] as String,
            feature: (c['fonction'] as String?) ?? 'ia',
            responseJson: {'usageMetadata': Map<String, dynamic>.from(c['usageMetadata'] as Map)},
            isSearchGrounded: c['recherche'] == true,
            requetesDeRecherche: c['requetes'] is num ? (c['requetes'] as num).toInt() : 1,
            userId: userId,
          ),
    ];
  }

  /// Aggregates multi-period statistics (Daily, Weekly, Monthly, Yearly, All-Time).
  Future<AiCostStats> getStats({String? userId}) async {
    // Plus d'historique d'exemple quand il est vide : ces événements inventés s'affichaient
    // comme la consommation réelle de la personne.
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

  Future<void> clearHistory() async {
    _cachedEvents = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
