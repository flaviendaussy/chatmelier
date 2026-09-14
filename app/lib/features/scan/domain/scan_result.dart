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

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? 'Vin sans nom';
    final rawProducer = json['producer'] as String?;
    final rawType = json['wine_type'] as String? ?? 'red';
    final rawAppellation = json['appellation'] as String?;
    final combinedLower = '$rawName ${rawProducer ?? ""} ${rawAppellation ?? ""} $rawType'.toLowerCase();

    String resolvedType = rawType;
    if (combinedLower.contains('italicus') ||
        combinedLower.contains('rosolio') ||
        combinedLower.contains('bénédictine') ||
        combinedLower.contains('benedictine') ||
        combinedLower.contains('amaretto') ||
        combinedLower.contains('disaronno') ||
        combinedLower.contains('chartreuse') ||
        combinedLower.contains('cointreau') ||
        combinedLower.contains('chambord') ||
        combinedLower.contains('pimm') ||
        combinedLower.contains('fleur de lavande') ||
        combinedLower.contains('liqueur')) {
      resolvedType = 'liqueur';
    } else if (RegExp(r'\bgin\b', caseSensitive: false).hasMatch(combinedLower)) {
      resolvedType = 'gin';
    } else if (combinedLower.contains('vodka')) {
      resolvedType = 'vodka';
    } else if (combinedLower.contains('whisky') || combinedLower.contains('whiskey') || combinedLower.contains('bourbon') || combinedLower.contains('scotch')) {
      resolvedType = 'whisky';
    } else if (combinedLower.contains('rhum') || combinedLower.contains('rum')) {
      resolvedType = 'rhum';
    } else if (combinedLower.contains('cognac') || combinedLower.contains('armagnac') || combinedLower.contains('calvados')) {
      resolvedType = 'cognac';
    } else if (combinedLower.contains('tequila') || combinedLower.contains('mezcal')) {
      resolvedType = 'tequila';
    } else if (combinedLower.contains('grappa') ||
        combinedLower.contains('vinaccia') ||
        combinedLower.contains('acquavite') ||
        combinedLower.contains('marc de ') ||
        combinedLower.contains('fine de ')) {
      resolvedType = 'grappa';
    } else if (combinedLower.contains('pisco') ||
        combinedLower.contains('aguardente') ||
        combinedLower.contains('eau de vie') ||
        combinedLower.contains('eau-de-vie') ||
        combinedLower.contains('pastis') ||
        combinedLower.contains('ricard') ||
        combinedLower.contains('absinthe')) {
      resolvedType = 'spirit';
    } else if (combinedLower.contains('porto') ||
        combinedLower.contains('port wine') ||
        combinedLower.contains('sherry') ||
        combinedLower.contains('xérès') ||
        combinedLower.contains('xeres') ||
        combinedLower.contains('banyuls') ||
        combinedLower.contains('maury') ||
        combinedLower.contains('rivesaltes') ||
        combinedLower.contains('madère') ||
        combinedLower.contains('madeira') ||
        combinedLower.contains('marsala') ||
        combinedLower.contains('vermouth')) {
      resolvedType = 'fortified';
    }

    return ScanResult(
      name: rawName,
      producer: rawProducer,
      cuveeParcel: json['cuvee_parcel'] as String?,
      vintage: (json['vintage'] as num?)?.toInt() ?? int.tryParse(json['vintage']?.toString() ?? ''),
      wineType: resolvedType,
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'producer': producer,
        'cuvee_parcel': cuveeParcel,
        'vintage': vintage,
        'wine_type': wineType,
        'country': country,
        'region': region,
        'sub_region': subRegion,
        'appellation': appellation,
        'classification': classification,
        'alcohol_pct': alcoholPct,
        'grapes': grapes.map((g) => g.toJson()).toList(),
        'tasting_notes': tastingNotes,
        'ideal_drinking_start': idealDrinkingStart,
        'ideal_drinking_end': idealDrinkingEnd,
        'peak_drinking_start': peakDrinkingStart,
        'peak_drinking_end': peakDrinkingEnd,
        'food_pairings': foodPairings,
        'ai_summary': summary,
        'critic_scores': criticScores.map((s) => s.toJson()).toList(),
        'estimated_market_value': estimatedMarketValue,
        'estimated_value_currency': estimatedValueCurrency,
        'sources_verified': sourcesVerified,
        'from_cache': fromCache,
        'detected_quantity': detectedQuantity,
        'packaging_type': packagingType,
      };

  ScanResult copyWith({
    String? name,
    String? producer,
    String? cuveeParcel,
    int? vintage,
    String? wineType,
    String? country,
    String? region,
    String? subRegion,
    String? appellation,
    String? classification,
    double? alcoholPct,
    List<Grape>? grapes,
    String? tastingNotes,
    int? idealDrinkingStart,
    int? idealDrinkingEnd,
    int? peakDrinkingStart,
    int? peakDrinkingEnd,
    List<String>? foodPairings,
    String? summary,
    List<CriticScore>? criticScores,
    double? estimatedMarketValue,
    String? estimatedValueCurrency,
    List<String>? sourcesVerified,
    bool? fromCache,
    int? detectedQuantity,
    String? packagingType,
  }) {
    return ScanResult(
      name: name ?? this.name,
      producer: producer ?? this.producer,
      cuveeParcel: cuveeParcel ?? this.cuveeParcel,
      vintage: vintage ?? this.vintage,
      wineType: wineType ?? this.wineType,
      country: country ?? this.country,
      region: region ?? this.region,
      subRegion: subRegion ?? this.subRegion,
      appellation: appellation ?? this.appellation,
      classification: classification ?? this.classification,
      alcoholPct: alcoholPct ?? this.alcoholPct,
      grapes: grapes ?? this.grapes,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      idealDrinkingStart: idealDrinkingStart ?? this.idealDrinkingStart,
      idealDrinkingEnd: idealDrinkingEnd ?? this.idealDrinkingEnd,
      peakDrinkingStart: peakDrinkingStart ?? this.peakDrinkingStart,
      peakDrinkingEnd: peakDrinkingEnd ?? this.peakDrinkingEnd,
      foodPairings: foodPairings ?? this.foodPairings,
      summary: summary ?? this.summary,
      criticScores: criticScores ?? this.criticScores,
      estimatedMarketValue: estimatedMarketValue ?? this.estimatedMarketValue,
      estimatedValueCurrency: estimatedValueCurrency ?? this.estimatedValueCurrency,
      sourcesVerified: sourcesVerified ?? this.sourcesVerified,
      fromCache: fromCache ?? this.fromCache,
      detectedQuantity: detectedQuantity ?? this.detectedQuantity,
      packagingType: packagingType ?? this.packagingType,
    );
  }
}

