/// Model representing an individual Gemini API call and its token/monetary cost.
class AiCostEvent {
  final String id;
  final String model;
  final String feature; // 'scan_vision', 'scan_enrichment', 'chat_sommelier', 'offline_enrichment'
  final int promptTokens;
  final int candidatesTokens;
  final int totalTokens;
  final bool isSearchGrounded;
  final double costEur;
  final double costUsd;
  final DateTime timestamp;
  final String? userId;

  const AiCostEvent({
    required this.id,
    required this.model,
    required this.feature,
    required this.promptTokens,
    required this.candidatesTokens,
    required this.totalTokens,
    this.isSearchGrounded = false,
    required this.costEur,
    required this.costUsd,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'model': model,
        'feature': feature,
        'prompt_tokens': promptTokens,
        'candidates_tokens': candidatesTokens,
        'total_tokens': totalTokens,
        'is_search_grounded': isSearchGrounded,
        'cost_eur': costEur,
        'cost_usd': costUsd,
        'timestamp': timestamp.toIso8601String(),
        'user_id': userId,
      };

  factory AiCostEvent.fromJson(Map<String, dynamic> json) => AiCostEvent(
        id: json['id'] as String,
        model: json['model'] as String? ?? 'gemini-flash-latest',
        feature: json['feature'] as String? ?? 'general',
        promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
        candidatesTokens: (json['candidates_tokens'] as num?)?.toInt() ?? 0,
        totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
        isSearchGrounded: json['is_search_grounded'] == true,
        costEur: (json['cost_eur'] as num?)?.toDouble() ?? 0.0,
        costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        userId: json['user_id'] as String?,
      );

  String get featureDisplayName {
    switch (feature) {
      case 'scan_vision':
        return '📷 Vision Étiquette';
      case 'scan_enrichment':
        return '🍇 Enrichissement Vin';
      case 'chat_sommelier':
        return '🍷 Chat Sommelier';
      case 'offline_enrichment':
        return '⚡ Sync Hors-Ligne';
      default:
        return '✨ IA Générale';
    }
  }
}

/// Official Gemini API Pricing Calculator (USD + EUR conversion ~1.08 USD/EUR)
class AiPricingCalculator {
  static const double usdToEurRate = 0.92;

  // Flash Tier (2.0 Flash, 2.5 Flash, 3.x Flash, flash-latest)
  // $0.10 / 1M prompt tokens, $0.40 / 1M output tokens (including thoughts)
  static const double flashPromptPerMillionUsd = 0.10;
  static const double flashCandidatePerMillionUsd = 0.40;

  // Flash-Lite Tier (2.0 Flash-Lite, 2.5 Flash-Lite, 3.x Flash-Lite, flash-lite-latest)
  // $0.075 / 1M prompt tokens, $0.30 / 1M output tokens
  static const double flashLitePromptPerMillionUsd = 0.075;
  static const double flashLiteCandidatePerMillionUsd = 0.30;

  // Pro Tier (1.5 Pro, 2.0 Pro, 2.5 Pro, pro-latest)
  // $1.25 / 1M prompt tokens, $5.00 / 1M output tokens
  static const double proPromptPerMillionUsd = 1.25;
  static const double proCandidatePerMillionUsd = 5.00;

  // Google Search Grounding: $35 per 1,000 search queries = $0.035 / query
  static const double searchGroundingPerQueryUsd = 0.035;

  static ({double costUsd, double costEur}) computeCost({
    required String model,
    required int promptTokens,
    required int candidateTokens,
    bool isSearchGrounded = false,
  }) {
    final m = model.toLowerCase();

    double promptRateUsd;
    double candidateRateUsd;

    if (m.contains('lite')) {
      promptRateUsd = flashLitePromptPerMillionUsd;
      candidateRateUsd = flashLiteCandidatePerMillionUsd;
    } else if (m.contains('pro') && !m.contains('flash')) {
      promptRateUsd = proPromptPerMillionUsd;
      candidateRateUsd = proCandidatePerMillionUsd;
    } else {
      // Default standard Flash tier
      promptRateUsd = flashPromptPerMillionUsd;
      candidateRateUsd = flashCandidatePerMillionUsd;
    }

    final promptCostUsd = (promptTokens / 1000000.0) * promptRateUsd;
    final candidateCostUsd = (candidateTokens / 1000000.0) * candidateRateUsd;
    final searchCostUsd = isSearchGrounded ? searchGroundingPerQueryUsd : 0.0;

    final totalUsd = promptCostUsd + candidateCostUsd + searchCostUsd;
    final totalEur = totalUsd * usdToEurRate;

    return (costUsd: totalUsd, costEur: totalEur);
  }
}

/// Aggregated metrics for a given time period.
class AiPeriodSummary {
  final int requestCount;
  final int promptTokens;
  final int candidatesTokens;
  final int totalTokens;
  final int searchQueriesCount;
  final double costEur;
  final double costUsd;

  const AiPeriodSummary({
    this.requestCount = 0,
    this.promptTokens = 0,
    this.candidatesTokens = 0,
    this.totalTokens = 0,
    this.searchQueriesCount = 0,
    this.costEur = 0.0,
    this.costUsd = 0.0,
  });

  AiPeriodSummary copyWith({
    int? requestCount,
    int? promptTokens,
    int? candidatesTokens,
    int? totalTokens,
    int? searchQueriesCount,
    double? costEur,
    double? costUsd,
  }) =>
      AiPeriodSummary(
        requestCount: requestCount ?? this.requestCount,
        promptTokens: promptTokens ?? this.promptTokens,
        candidatesTokens: candidatesTokens ?? this.candidatesTokens,
        totalTokens: totalTokens ?? this.totalTokens,
        searchQueriesCount: searchQueriesCount ?? this.searchQueriesCount,
        costEur: costEur ?? this.costEur,
        costUsd: costUsd ?? this.costUsd,
      );

  AiPeriodSummary addEvent(AiCostEvent event) => AiPeriodSummary(
        requestCount: requestCount + 1,
        promptTokens: promptTokens + event.promptTokens,
        candidatesTokens: candidatesTokens + event.candidatesTokens,
        totalTokens: totalTokens + event.totalTokens,
        searchQueriesCount: searchQueriesCount + (event.isSearchGrounded ? 1 : 0),
        costEur: costEur + event.costEur,
        costUsd: costUsd + event.costUsd,
      );
}

/// Comprehensive multi-period statistical breakdown.
class AiCostStats {
  final AiPeriodSummary daily; // Today
  final AiPeriodSummary weekly; // Last 7 days
  final AiPeriodSummary monthly; // Last 30 days
  final AiPeriodSummary yearly; // Current year
  final AiPeriodSummary allTime; // Total
  final Map<String, AiPeriodSummary> byModel;
  final Map<String, AiPeriodSummary> byFeature;
  final List<AiCostEvent> recentEvents;

  const AiCostStats({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.yearly,
    required this.allTime,
    required this.byModel,
    required this.byFeature,
    required this.recentEvents,
  });

  factory AiCostStats.empty() => const AiCostStats(
        daily: AiPeriodSummary(),
        weekly: AiPeriodSummary(),
        monthly: AiPeriodSummary(),
        yearly: AiPeriodSummary(),
        allTime: AiPeriodSummary(),
        byModel: {},
        byFeature: {},
        recentEvents: [],
      );
}
