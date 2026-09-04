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
    if (combinedLower.contains('gin')) {
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
    } else if (combinedLower.contains('italicus') ||
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
    } else if (combinedLower.contains('pisco') ||
        combinedLower.contains('grappa') ||
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
}

