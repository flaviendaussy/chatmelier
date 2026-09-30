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

/// Tarifs Gemini (offre payante standard), relevés sur la page officielle le 30/09/2026 :
/// https://ai.google.dev/gemini-api/docs/pricing. Prix en dollars par million de jetons ; la
/// sortie inclut les jetons de réflexion.
///
/// Jusqu'au 29/09, l'app comptait 0,10 $ / 0,40 $ pour tous les Flash — le tarif d'un ancien
/// 2.0 Flash —, soit environ neuf fois moins que ce que coûte `gemini-3.8-flash`.
class AiPricingCalculator {
  static const double usdToEurRate = 0.92;

  /// Les Flash 3.6 à 3.8 doublent le 1er janvier 2027.
  static final DateTime doublementDesFlash = DateTime(2027, 1, 1);

  /// Recherche Google pour les modèles 3.x : 5 000 requêtes offertes par mois, puis 14 $ les
  /// 1 000. Un événement isolé ne sait pas où en est le mois : on compte le prix marginal,
  /// et la console (migration 051) applique la franchise mensuelle.
  static const double rechercheParRequeteUsd = 0.014;
  static const int rechercheFranchiseMensuelle = 5000;

  /// Ancien nom, gardé pour les appelants : le prix d'une requête de recherche.
  static const double searchGroundingPerQueryUsd = rechercheParRequeteUsd;

  /// (entrée, sortie) en dollars par million de jetons, pour ce modèle à cette date.
  /// Les alias (`gemini-flash-latest`, `gemini-flash-lite-latest`) suivent le modèle le plus
  /// récent de leur famille. Un modèle inconnu est compté au tarif Flash courant : mieux vaut
  /// surestimer que l'inverse.
  static ({double entree, double sortie}) tarif(String model, {DateTime? le}) {
    final m = model.toLowerCase();
    final date = le ?? DateTime.now();
    if (m.contains('pro') && !m.contains('flash')) return (entree: 1.25, sortie: 5.00);
    if (m.contains('lite')) {
      if (m.contains('2.0-flash-lite') || m.contains('2.5-flash-lite')) return (entree: 0.10, sortie: 0.40);
      if (m.contains('3.1-flash-lite')) return (entree: 0.25, sortie: 1.50);
      return (entree: 0.30, sortie: 2.50); // 3.5-flash-lite, flash-lite-latest
    }
    if (m.contains('2.0-flash')) return (entree: 0.10, sortie: 0.40);
    if (m.contains('2.5-flash')) return (entree: 0.30, sortie: 2.50);
    if (m.contains('3.5-flash')) return (entree: 1.50, sortie: 9.00);
    // 3.6, 3.7, 3.8-flash, flash-latest, préversions 3.x.
    return date.isBefore(doublementDesFlash) ? (entree: 0.75, sortie: 3.75) : (entree: 1.50, sortie: 7.50);
  }

  static ({double costUsd, double costEur}) computeCost({
    required String model,
    required int promptTokens,
    required int candidateTokens,
    bool isSearchGrounded = false,
    int requetesDeRecherche = 1,
    DateTime? le,
  }) {
    final t = tarif(model, le: le);
    final promptCostUsd = (promptTokens / 1000000.0) * t.entree;
    final candidateCostUsd = (candidateTokens / 1000000.0) * t.sortie;
    final searchCostUsd = isSearchGrounded ? rechercheParRequeteUsd * (requetesDeRecherche < 1 ? 1 : requetesDeRecherche) : 0.0;

    final totalUsd = promptCostUsd + candidateCostUsd + searchCostUsd;
    return (costUsd: totalUsd, costEur: totalUsd * usdToEurRate);
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
