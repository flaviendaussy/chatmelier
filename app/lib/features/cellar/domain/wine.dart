import 'package:flutter/material.dart';

enum DrinkWindowStatus { tooYoung, aging, inPeak, drinkSoon, pastPeak }

extension DrinkWindowStatusX on DrinkWindowStatus {
  String get labelFr {
    switch (this) {
      case DrinkWindowStatus.tooYoung:
        return 'Trop jeune';
      case DrinkWindowStatus.aging:
        return 'En garde';
      case DrinkWindowStatus.inPeak:
        return 'À l\'apogée';
      case DrinkWindowStatus.drinkSoon:
        return 'À boire vite';
      case DrinkWindowStatus.pastPeak:
        return 'Passé';
    }
  }

  String get labelEn {
    switch (this) {
      case DrinkWindowStatus.tooYoung:
        return 'Too Young';
      case DrinkWindowStatus.aging:
        return 'Aging';
      case DrinkWindowStatus.inPeak:
        return 'At Peak';
      case DrinkWindowStatus.drinkSoon:
        return 'Drink Soon';
      case DrinkWindowStatus.pastPeak:
        return 'Past Peak';
    }
  }

  Color get color {
    switch (this) {
      case DrinkWindowStatus.tooYoung:
        return const Color(0xFF64B5F6); // Soft blue
      case DrinkWindowStatus.aging:
        return const Color(0xFF4FC3F7); // Cyan/sky blue
      case DrinkWindowStatus.inPeak:
        return const Color(0xFF81C784); // Vibrant sommelier green
      case DrinkWindowStatus.drinkSoon:
        return const Color(0xFFFFB74D); // Warm orange
      case DrinkWindowStatus.pastPeak:
        return const Color(0xFFE53935); // Crimson red
    }
  }
}

class Grape {
  final String name;
  final double? pct;

  const Grape({required this.name, this.pct});

  factory Grape.fromJson(dynamic json) {
    if (json is String) return Grape(name: json);
    if (json is Map) {
      final name = (json['name'] ?? json['grape'] ?? json['variety'] ?? 'Cépage').toString();
      double? pct;
      final rawPct = json['pct'] ?? json['percentage'] ?? json['percent'];
      if (rawPct is num) {
        pct = rawPct.toDouble();
      } else if (rawPct is String) {
        final clean = rawPct.replaceAll('%', '').trim();
        pct = double.tryParse(clean);
      }
      return Grape(
        name: name,
        pct: pct,
      );
    }
    return const Grape(name: 'Inconnu');
  }

  Map<String, dynamic> toJson() => {'name': name, if (pct != null) 'pct': pct};
}

class CriticScore {
  final String source;
  final String score;
  final String? reviewer;
  final int? year;
  final String? notes;

  const CriticScore({
    required this.source,
    required this.score,
    this.reviewer,
    this.year,
    this.notes,
  });

  factory CriticScore.fromJson(Map<String, dynamic> json) => CriticScore(
    source: json['source'] as String? ?? 'Guide Sommelier',
    score: json['score'] as String? ?? '',
    reviewer: json['reviewer'] as String?,
    year: (json['year'] as num?)?.toInt(),
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'source': source,
    'score': score,
    if (reviewer != null) 'reviewer': reviewer,
    if (year != null) 'year': year,
    if (notes != null) 'notes': notes,
  };
}

class ValuationPoint {
  final DateTime date;
  final double value;
  final String currency;
  final String? source;

  const ValuationPoint({
    required this.date,
    required this.value,
    this.currency = 'EUR',
    this.source,
  });

  factory ValuationPoint.fromJson(Map<String, dynamic> json) => ValuationPoint(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    value: (json['value'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'EUR',
    source: json['source'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'value': value,
    'currency': currency,
    if (source != null) 'source': source,
  };
}

class Wine {
  final String id;
  final String name;
  final String? producer;
  final String? cuveeParcel;
  final String type;
  final String country;
  final String region;
  final String? subRegion;
  final String? appellation;
  final String? classification;
  final int? vintage;
  final double? alcoholPct;
  final List<Grape> grapes;
  final String? tastingNotes;
  final int? drinkStart;
  final int? drinkEnd;
  final int? peakStart;
  final int? peakEnd;
  final List<String> foodPairings;
  final String? summary;
  final List<CriticScore> criticScores;
  final double? estimatedMarketValue;
  final String estimatedValueCurrency;
  final DateTime? lastValuationDate;
  final List<ValuationPoint> valuationHistory;
  final List<String> sourcesVerified;
  final bool isVerifiedOnline;
  final String? barrelAging;
  final String? vinificationMethod;
  final String? malolacticFermentation;
  final String? harvestMethod;
  final String? terroirSoil;
  final bool isTechnicalDataVerified;
  final String? imageUrl;
  final List<String> userOverrides;

  const Wine({
    required this.id,
    required this.name,
    this.producer,
    this.cuveeParcel,
    required this.type,
    required this.country,
    required this.region,
    this.subRegion,
    this.appellation,
    this.classification,
    this.vintage,
    this.alcoholPct,
    this.grapes = const [],
    this.tastingNotes,
    this.drinkStart,
    this.drinkEnd,
    this.peakStart,
    this.peakEnd,
    this.foodPairings = const [],
    this.summary,
    this.criticScores = const [],
    this.estimatedMarketValue,
    this.estimatedValueCurrency = 'EUR',
    this.lastValuationDate,
    this.valuationHistory = const [],
    this.sourcesVerified = const [],
    this.isVerifiedOnline = false,
    this.barrelAging,
    this.vinificationMethod,
    this.malolacticFermentation,
    this.harvestMethod,
    this.terroirSoil,
    this.isTechnicalDataVerified = false,
    this.imageUrl,
    this.userOverrides = const [],
  });

  factory Wine.fromJson(Map<String, dynamic> json) {
    final rawType = json['wine_type'] as String? ?? json['type'] as String? ?? 'red';
    final rawName = json['name'] as String? ?? 'Unnamed Wine';
    final rawProducer = json['producer'] as String?;
    final rawAppellation = json['appellation'] as String?;
    final combinedLower = '$rawName ${rawProducer ?? ""} ${rawAppellation ?? ""}'.toLowerCase();

    // Auto-normalize spirits, liqueurs, and fortified wines misclassified in database
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
        combinedLower.contains('chartreuse') ||
        combinedLower.contains('cointreau') ||
        combinedLower.contains('grand marnier') ||
        combinedLower.contains('amaretto') ||
        combinedLower.contains('disaronno') ||
        combinedLower.contains('kahlúa') ||
        combinedLower.contains('kahlua') ||
        combinedLower.contains('limoncello') ||
        combinedLower.contains('sambuca') ||
        combinedLower.contains('chambord') ||
        combinedLower.contains('fleur de lavande') ||
        combinedLower.contains('crème de') ||
        combinedLower.contains('creme de') ||
        combinedLower.contains('pimm') ||
        combinedLower.contains('liqueur')) {
      resolvedType = 'liqueur';
    } else if (combinedLower.contains('pisco') ||
        combinedLower.contains('grappa') ||
        combinedLower.contains('eau de vie') ||
        combinedLower.contains('eau-de-vie') ||
        combinedLower.contains('aguardente') ||
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

    // Auto-fill alcohol content for famous spirits if missing from DB
    double? alcohol = (json['alcohol_pct'] as num?)?.toDouble();
    if (alcohol == null) {
      if (combinedLower.contains('bénédictine') || combinedLower.contains('benedictine')) {
        alcohol = 40.0;
      } else if (combinedLower.contains('chartreuse')) {
        alcohol = combinedLower.contains('jaune') ? 43.0 : 55.0;
      } else if (combinedLower.contains('cointreau')) {
        alcohol = 40.0;
      }
    }

    return Wine(
      id: json['id'] as String? ?? '',
      name: rawName,
      producer: rawProducer,
      cuveeParcel: json['cuvee_parcel'] as String?,
      type: resolvedType,
      country: json['country'] as String? ?? '',
      region: json['region'] as String? ?? '',
      subRegion: json['sub_region'] as String?,
      appellation: rawAppellation,
      classification: json['classification'] as String?,
      vintage: (json['vintage'] as num?)?.toInt() ?? int.tryParse(json['vintage']?.toString() ?? ''),
      alcoholPct: alcohol,
      grapes: (json['grapes'] as List<dynamic>?)
          ?.map((g) => Grape.fromJson(g as Map<String, dynamic>))
          .toList() ?? const [],
      tastingNotes: json['tasting_notes'] as String?,
      drinkStart: (json['ideal_drinking_start'] as num?)?.toInt(),
      drinkEnd: (json['ideal_drinking_end'] as num?)?.toInt(),
      peakStart: (json['peak_drinking_start'] as num?)?.toInt(),
      peakEnd: (json['peak_drinking_end'] as num?)?.toInt(),
      foodPairings: (json['ai_food_pairings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      summary: json['ai_summary'] as String?,
      criticScores: (json['critic_scores'] as List<dynamic>?)
          ?.map((s) => CriticScore.fromJson(s as Map<String, dynamic>))
          .toList() ?? const [],
      estimatedMarketValue: (json['estimated_market_value'] as num?)?.toDouble(),
      estimatedValueCurrency: json['estimated_value_currency'] as String? ?? 'EUR',
      lastValuationDate: json['last_valuation_date'] != null ? DateTime.tryParse(json['last_valuation_date'].toString()) : null,
      valuationHistory: (json['valuation_history'] as List<dynamic>?)
          ?.map((v) => ValuationPoint.fromJson(v as Map<String, dynamic>))
          .toList() ?? const [],
      sourcesVerified: (json['sources_verified'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isVerifiedOnline: json['is_verified_online'] as bool? ?? false,
      barrelAging: json['barrel_aging'] as String?,
      vinificationMethod: json['vinification_method'] as String?,
      malolacticFermentation: json['malolactic_fermentation'] as String?,
      harvestMethod: json['harvest_method'] as String?,
      terroirSoil: json['terroir_soil'] as String?,
      isTechnicalDataVerified: json['is_technical_data_verified'] as bool? ?? false,
      imageUrl: json['image_url'] as String? ??
          json['label_image_url'] as String? ??
          (json['external_links'] is Map ? (json['external_links'] as Map)['image_url'] as String? : null) ??
          json['imageUrl'] as String?,
      userOverrides: (json['user_overrides'] as List<dynamic>?)?.map((e) => e.toString()).toList()
          ?? (json['external_links'] is Map && (json['external_links'] as Map)['user_overrides'] is List
              ? ((json['external_links'] as Map)['user_overrides'] as List<dynamic>).map((e) => e.toString()).toList()
              : const []),
    );
  }

  bool get isSpirit {
    final t = type.toLowerCase().trim();
    if (t == 'spirit' ||
        t == 'spiritueux' ||
        t == 'whisky' ||
        t == 'whiskey' ||
        t == 'bourbon' ||
        t == 'scotch' ||
        t == 'rum' ||
        t == 'rhum' ||
        t == 'gin' ||
        t == 'vodka' ||
        t == 'tequila' ||
        t == 'mezcal' ||
        t == 'cognac' ||
        t == 'armagnac' ||
        t == 'calvados' ||
        t == 'pisco' ||
        t == 'grappa' ||
        t == 'eau-de-vie' ||
        t == 'eau de vie' ||
        t == 'aguardente' ||
        t == 'pastis' ||
        t == 'absinthe' ||
        t == 'liqueur' ||
        t == 'rosolio' ||
        t == 'aperitif' ||
        t == 'bitter' ||
        t == 'hard') {
      return true;
    }

    final n = '$name ${producer ?? ""} ${appellation ?? ""}'.toLowerCase();
    final words = n.split(RegExp(r'[\s,\.\-_]+')).toSet();
    if (words.contains('gin') ||
        words.contains('vodka') ||
        words.contains('whisky') ||
        words.contains('whiskey') ||
        words.contains('bourbon') ||
        words.contains('scotch') ||
        words.contains('rhum') ||
        words.contains('rum') ||
        words.contains('tequila') ||
        words.contains('mezcal') ||
        words.contains('cognac') ||
        words.contains('armagnac') ||
        words.contains('calvados') ||
        words.contains('pisco') ||
        words.contains('grappa') ||
        words.contains('pastis') ||
        words.contains('ricard') ||
        words.contains('absinthe') ||
        words.contains('italicus') ||
        words.contains('rosolio') ||
        words.contains('chambord') ||
        words.contains('disaronno') ||
        words.contains('amaretto') ||
        words.contains('aguardente') ||
        words.contains('liqueur') ||
        words.contains('spiritueux') ||
        words.contains('spirit')) {
      return true;
    }

    return n.contains('bénédictine') ||
        n.contains('benedictine') ||
        n.contains('chartreuse') ||
        n.contains('cointreau') ||
        n.contains('grand marnier') ||
        n.contains('amaretto') ||
        n.contains('disaronno') ||
        n.contains('campari') ||
        n.contains('aperol') ||
        n.contains('kahlúa') ||
        n.contains('kahlua') ||
        n.contains('sambuca') ||
        n.contains('limoncello') ||
        n.contains('pastis') ||
        n.contains('ricard') ||
        n.contains('absinthe') ||
        n.contains('grappa') ||
        n.contains('pisco') ||
        n.contains('italicus') ||
        n.contains('rosolio') ||
        n.contains('aguardente') ||
        n.contains('chambord') ||
        n.contains('pimm') ||
        n.contains('fleur de lavande') ||
        n.contains('eau de vie') ||
        n.contains('eau-de-vie') ||
        n.contains('crème de') ||
        n.contains('creme de') ||
        n.contains('amaro') ||
        n.contains('triple sec') ||
        n.contains('curacao') ||
        n.contains('curaçao') ||
        n.contains('genepi') ||
        n.contains('génépi') ||
        n.contains('ratafia');
  }

  /// True for fortified / muté wines (Porto, Sherry, Banyuls, Vermouth, VDN, Madeira).
  bool get isFortified {
    final t = type.toLowerCase().trim();
    if (t == 'fortified' || t == 'muté' || t == 'mute' || t == 'vdn' || t == 'vermouth' || t == 'porto' || t == 'sherry') return true;
    final n = '$name ${producer ?? ""} ${appellation ?? ""}'.toLowerCase();
    return n.contains('porto') ||
        n.contains('port wine') ||
        n.contains('sherry') ||
        n.contains('xérès') ||
        n.contains('xeres') ||
        n.contains('banyuls') ||
        n.contains('maury') ||
        n.contains('rivesaltes') ||
        n.contains('madère') ||
        n.contains('madeira') ||
        n.contains('marsala') ||
        n.contains('vermouth') ||
        n.contains('vin doux naturel');
  }

  /// True for spirits, liqueurs, and fortified/muté wines where bottle fill level (0-100%)
  /// is tracked instead of an oenological wine drinking window / apogée.
  bool get tracksFillLevel => isSpirit || isFortified;

  DrinkWindowStatus get windowStatus {
    final currentYear = DateTime.now().year;
    final wType = type.toLowerCase();

    // 1. Resolve or compute effective drinking window
    int? effectiveDrinkStart = drinkStart;
    int? effectiveDrinkEnd = drinkEnd;
    int? effectivePeakStart = peakStart;
    int? effectivePeakEnd = peakEnd;

    // Validate explicit drinking windows against the vintage (e.g. if user edited vintage)
    if (vintage != null) {
      if (effectiveDrinkStart != null && effectiveDrinkStart < vintage!) {
        effectiveDrinkStart = null;
      }
      if (effectiveDrinkEnd != null && (effectiveDrinkEnd < vintage! || (effectiveDrinkStart != null && effectiveDrinkEnd < effectiveDrinkStart))) {
        effectiveDrinkEnd = null;
      }
      if (effectivePeakStart != null && effectivePeakStart < vintage!) {
        effectivePeakStart = null;
      }
      if (effectivePeakEnd != null && effectivePeakEnd < vintage!) {
        effectivePeakEnd = null;
      }
    }

    // Fallback: If no valid explicit window is stored, estimate from enological properties
    if (effectiveDrinkStart == null || effectiveDrinkEnd == null) {
      if (vintage != null) {
        final v = vintage!;
        if (wType.contains('rosé') || wType.contains('rose')) {
          // Rosé: short freshness window (1 to 3 years)
          effectiveDrinkStart = v;
          effectiveDrinkEnd = v + 3;
          effectivePeakStart = v + 1;
          effectivePeakEnd = v + 2;
        } else if (wType.contains('white') || wType.contains('blanc') || wType.contains('sparkling')) {
          final isGrandBlanc = region.toLowerCase().contains('bourgogne') ||
              appellation?.toLowerCase().contains('chablis grand cru') == true ||
              appellation?.toLowerCase().contains('meursault') == true ||
              appellation?.toLowerCase().contains('montrachet') == true ||
              region.toLowerCase().contains('pessac');
          if (isGrandBlanc) {
            // Grand white: 8-15 years aging potential
            effectiveDrinkStart = v + 3;
            effectiveDrinkEnd = v + 15;
            effectivePeakStart = v + 6;
            effectivePeakEnd = v + 10;
          } else {
            // Fresh white / NV sparkling: 2-5 years
            effectiveDrinkStart = v + 1;
            effectiveDrinkEnd = v + 5;
            effectivePeakStart = v + 2;
            effectivePeakEnd = v + 3;
          }
        } else if (wType.contains('dessert') ||
            wType.contains('moelleux') ||
            wType.contains('liquoreux') ||
            wType.contains('fortified')) {
          // Sweet / Fortified: very long aging potential (15 to 40+ years)
          effectiveDrinkStart = v + 4;
          effectiveDrinkEnd = v + 35;
          effectivePeakStart = v + 10;
          effectivePeakEnd = v + 25;
        } else {
          // Red wines: differentiate by region/appellation potential
          final isGrandCru = (classification?.toLowerCase().contains('cru') == true) ||
              region.toLowerCase().contains('bordeaux') ||
              appellation?.toLowerCase().contains('bandol') == true ||
              appellation?.toLowerCase().contains('hermitage') == true ||
              appellation?.toLowerCase().contains('côte-rôtie') == true ||
              appellation?.toLowerCase().contains('cornas') == true ||
              appellation?.toLowerCase().contains('barolo') == true;
          if (isGrandCru) {
            // Long aging red (10 to 25+ years)
            effectiveDrinkStart = v + 4;
            effectiveDrinkEnd = v + 22;
            effectivePeakStart = v + 8;
            effectivePeakEnd = v + 16;
          } else {
            // Everyday / medium red (3 to 8 years)
            effectiveDrinkStart = v + 2;
            effectiveDrinkEnd = v + 8;
            effectivePeakStart = v + 4;
            effectivePeakEnd = v + 6;
          }
        }
      } else {
        return DrinkWindowStatus.inPeak;
      }
    }

    final start = effectiveDrinkStart;
    final end = effectiveDrinkEnd;
    final totalSpan = end - start;

    int pStart = effectivePeakStart ?? (start + (totalSpan * 0.35).round());
    int pEnd = effectivePeakEnd ?? (start + (totalSpan * 0.65).round());
    if (pEnd < pStart) pEnd = pStart;

    // -------------------------------------------------------------------------
    // ADAPTIVE ENOLOGICAL RULES:
    // A 2-year wine vs a 30-year wine have fundamentally different tolerances!
    // -------------------------------------------------------------------------

    if (totalSpan <= 2) {
      // Very short lifespan (1-2 years, e.g. primeur, light rosé)
      if (currentYear < start) return DrinkWindowStatus.tooYoung;
      if (currentYear >= pStart && currentYear <= pEnd) return DrinkWindowStatus.inPeak;
      if (currentYear <= end) return DrinkWindowStatus.drinkSoon;
      return DrinkWindowStatus.pastPeak;
    }

    if (totalSpan <= 5) {
      // Short lifespan (3-5 years, e.g. fresh whites, standard rosés, light reds)
      if (currentYear < start) return DrinkWindowStatus.tooYoung;
      if (currentYear < pStart) return DrinkWindowStatus.aging;
      if (currentYear >= pStart && currentYear <= pEnd) return DrinkWindowStatus.inPeak;
      if (currentYear <= end) return DrinkWindowStatus.drinkSoon;
      return DrinkWindowStatus.pastPeak;
    }

    // Medium to Long lifespan (6+ years up to 30+ years)
    if (currentYear < start) {
      if ((start - currentYear) >= 3) {
        return DrinkWindowStatus.tooYoung;
      }
      return DrinkWindowStatus.aging;
    }

    if (currentYear < pStart) {
      return DrinkWindowStatus.aging;
    }

    if (currentYear >= pStart && currentYear <= pEnd) {
      return DrinkWindowStatus.inPeak;
    }

    if (currentYear <= end) {
      return DrinkWindowStatus.drinkSoon;
    }

    return DrinkWindowStatus.pastPeak;
  }

  String get fullDisplayName {
    final buffer = StringBuffer();
    if (producer != null && producer!.isNotEmpty && !name.toLowerCase().contains(producer!.toLowerCase())) {
      buffer.write('$producer ');
    }
    buffer.write(name);
    if (cuveeParcel != null && cuveeParcel!.isNotEmpty) {
      buffer.write(' - $cuveeParcel');
    }
    if (vintage != null) {
      buffer.write(' ($vintage)');
    } else {
      buffer.write(' (NV)');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (producer != null) 'producer': producer,
    if (cuveeParcel != null) 'cuvee_parcel': cuveeParcel,
    'wine_type': type,
    'country': country,
    'region': region,
    if (subRegion != null) 'sub_region': subRegion,
    if (appellation != null) 'appellation': appellation,
    if (classification != null) 'classification': classification,
    if (vintage != null) 'vintage': vintage,
    if (alcoholPct != null) 'alcohol_pct': alcoholPct,
    'grapes': grapes.map((g) => g.toJson()).toList(),
    if (tastingNotes != null) 'tasting_notes': tastingNotes,
    if (drinkStart != null) 'ideal_drinking_start': drinkStart,
    if (drinkEnd != null) 'ideal_drinking_end': drinkEnd,
    if (peakStart != null) 'peak_drinking_start': peakStart,
    if (peakEnd != null) 'peak_drinking_end': peakEnd,
    'ai_food_pairings': foodPairings,
    if (summary != null) 'ai_summary': summary,
    'critic_scores': criticScores.map((s) => s.toJson()).toList(),
    if (estimatedMarketValue != null) 'estimated_market_value': estimatedMarketValue,
    'estimated_value_currency': estimatedValueCurrency,
    if (lastValuationDate != null) 'last_valuation_date': lastValuationDate!.toIso8601String(),
    'valuation_history': valuationHistory.map((v) => v.toJson()).toList(),
    'sources_verified': sourcesVerified,
    'is_verified_online': isVerifiedOnline,
    if (barrelAging != null) 'barrel_aging': barrelAging,
    if (vinificationMethod != null) 'vinification_method': vinificationMethod,
    if (terroirSoil != null) 'terroir_soil': terroirSoil,
    'is_technical_data_verified': isTechnicalDataVerified,
    if (imageUrl != null) 'image_url': imageUrl,
    if (userOverrides.isNotEmpty) 'user_overrides': userOverrides,
    if (userOverrides.isNotEmpty) 'external_links': {'user_overrides': userOverrides},
  };

  Wine copyWith({
    String? id,
    String? name,
    String? producer,
    String? cuveeParcel,
    String? type,
    String? country,
    String? region,
    String? subRegion,
    String? appellation,
    String? classification,
    int? vintage,
    double? alcoholPct,
    List<Grape>? grapes,
    String? tastingNotes,
    int? drinkStart,
    int? drinkEnd,
    int? peakStart,
    int? peakEnd,
    List<String>? foodPairings,
    String? summary,
    List<CriticScore>? criticScores,
    double? estimatedMarketValue,
    String? estimatedValueCurrency,
    DateTime? lastValuationDate,
    List<ValuationPoint>? valuationHistory,
    List<String>? sourcesVerified,
    bool? isVerifiedOnline,
    String? barrelAging,
    String? vinificationMethod,
    String? malolacticFermentation,
    String? harvestMethod,
    String? terroirSoil,
    bool? isTechnicalDataVerified,
    String? imageUrl,
    List<String>? userOverrides,
  }) {
    return Wine(
      id: id ?? this.id,
      name: name ?? this.name,
      producer: producer ?? this.producer,
      cuveeParcel: cuveeParcel ?? this.cuveeParcel,
      type: type ?? this.type,
      country: country ?? this.country,
      region: region ?? this.region,
      subRegion: subRegion ?? this.subRegion,
      appellation: appellation ?? this.appellation,
      classification: classification ?? this.classification,
      vintage: vintage ?? this.vintage,
      alcoholPct: alcoholPct ?? this.alcoholPct,
      grapes: grapes ?? this.grapes,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      drinkStart: drinkStart ?? this.drinkStart,
      drinkEnd: drinkEnd ?? this.drinkEnd,
      peakStart: peakStart ?? this.peakStart,
      peakEnd: peakEnd ?? this.peakEnd,
      foodPairings: foodPairings ?? this.foodPairings,
      summary: summary ?? this.summary,
      criticScores: criticScores ?? this.criticScores,
      estimatedMarketValue: estimatedMarketValue ?? this.estimatedMarketValue,
      estimatedValueCurrency: estimatedValueCurrency ?? this.estimatedValueCurrency,
      lastValuationDate: lastValuationDate ?? this.lastValuationDate,
      valuationHistory: valuationHistory ?? this.valuationHistory,
      sourcesVerified: sourcesVerified ?? this.sourcesVerified,
      isVerifiedOnline: isVerifiedOnline ?? this.isVerifiedOnline,
      barrelAging: barrelAging ?? this.barrelAging,
      vinificationMethod: vinificationMethod ?? this.vinificationMethod,
      malolacticFermentation: malolacticFermentation ?? this.malolacticFermentation,
      harvestMethod: harvestMethod ?? this.harvestMethod,
      terroirSoil: terroirSoil ?? this.terroirSoil,
      isTechnicalDataVerified: isTechnicalDataVerified ?? this.isTechnicalDataVerified,
      imageUrl: imageUrl ?? this.imageUrl,
      userOverrides: userOverrides ?? this.userOverrides,
    );
  }
}
