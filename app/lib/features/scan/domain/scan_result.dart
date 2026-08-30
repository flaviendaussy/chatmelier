import '../../cellar/domain/wine.dart';

class ScanResult {
  final String name;
  final String? producer;
  final String? cuveeParcel;
  final int? vintage;
  final String wineType;
  final String country;
  final String region;
  final String? subRegion;
  final String? appellation;
  final String? classification;
  final double? alcoholPct;
  final List<Grape> grapes;
  final String? tastingNotes;
  final int? idealDrinkingStart;
  final int? idealDrinkingEnd;
  final int? peakDrinkingStart;
  final int? peakDrinkingEnd;
  final List<String> foodPairings;
  final String? summary;
  final List<CriticScore> criticScores;
  final double? estimatedMarketValue;
  final String estimatedValueCurrency;
  final List<String> sourcesVerified;
  final bool fromCache;
  final int detectedQuantity;
  final String? packagingType;

  const ScanResult({
    required this.name,
    this.producer,
    this.cuveeParcel,
    this.vintage,
    required this.wineType,
    required this.country,
    required this.region,
    this.subRegion,
    this.appellation,
    this.classification,
    this.alcoholPct,
    this.grapes = const [],
    this.tastingNotes,
    this.idealDrinkingStart,
    this.idealDrinkingEnd,
    this.peakDrinkingStart,
    this.peakDrinkingEnd,
    this.foodPairings = const [],
    this.summary,
    this.criticScores = const [],
    this.estimatedMarketValue,
    this.estimatedValueCurrency = 'EUR',
    this.sourcesVerified = const [],
    this.fromCache = false,
    this.detectedQuantity = 1,
    this.packagingType,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    name: json['name'] as String? ?? 'Vin sans nom',
    producer: json['producer'] as String?,
    cuveeParcel: json['cuvee_parcel'] as String?,
    vintage: (json['vintage'] as num?)?.toInt() ?? int.tryParse(json['vintage']?.toString() ?? ''),
    wineType: json['wine_type'] as String? ?? 'red',
    country: json['country'] as String? ?? '',
    region: json['region'] as String? ?? '',
    subRegion: json['sub_region'] as String?,
    appellation: json['appellation'] as String?,
    classification: json['classification'] as String?,
    alcoholPct: (json['alcohol_pct'] as num?)?.toDouble(),
    grapes: (json['grapes'] as List<dynamic>?)
        ?.map((g) => Grape.fromJson(g))
        .toList() ?? const [],
    tastingNotes: json['tasting_notes'] as String?,
    idealDrinkingStart: (json['ideal_drinking_start'] as num?)?.toInt(),
    idealDrinkingEnd: (json['ideal_drinking_end'] as num?)?.toInt(),
    peakDrinkingStart: (json['peak_drinking_start'] as num?)?.toInt(),
    peakDrinkingEnd: (json['peak_drinking_end'] as num?)?.toInt(),
    foodPairings: (json['food_pairings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    summary: json['ai_summary'] as String? ?? json['summary'] as String?,
    criticScores: (json['critic_scores'] as List<dynamic>?)
        ?.map((s) => CriticScore.fromJson(s as Map<String, dynamic>))
        .toList() ?? const [],
    estimatedMarketValue: (json['estimated_market_value'] as num?)?.toDouble(),
    estimatedValueCurrency: json['estimated_value_currency'] as String? ?? 'EUR',
    sourcesVerified: (json['sources_verified'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    fromCache: json['from_cache'] as bool? ?? false,
    detectedQuantity: (json['detected_quantity'] as num?)?.toInt() ?? 1,
    packagingType: json['packaging_type'] as String?,
  );
}
