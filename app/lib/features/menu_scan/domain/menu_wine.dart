import 'package:flutter/material.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/domain/wine_taste_radar.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';

/// Pricing entry for wine by the glass (e.g. "125ml", "175ml", "150ml", "Verre")
class MenuWineGlassPrice {
  final String format; // e.g. "125ml", "175ml", "Verre"
  final double price;

  const MenuWineGlassPrice({
    required this.format,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'format': format,
        'price': price,
      };

  factory MenuWineGlassPrice.fromJson(Map<String, dynamic> json) {
    return MenuWineGlassPrice(
      format: (json['format'] ?? 'Verre').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Flags / Badges for highlighting exceptional wines on restaurant menus
enum MenuWineFlagType {
  deal, // Bon plan / Grosse affaire
  gem, // Vin pépite
  tasteMatch, // Accord parfait avec le profil utilisateur
}

class MenuWineFlag {
  final MenuWineFlagType type;
  final String label;
  final String? reason;

  const MenuWineFlag({
    required this.type,
    required this.label,
    this.reason,
  });

  String get iconEmoji {
    switch (type) {
      case MenuWineFlagType.deal:
        return '💎';
      case MenuWineFlagType.gem:
        return '✨';
      case MenuWineFlagType.tasteMatch:
        return '🎯';
    }
  }

  Color get color {
    switch (type) {
      case MenuWineFlagType.deal:
        return const Color(0xFF00897B); // Emerald / Teal
      case MenuWineFlagType.gem:
        return const Color(0xFFD4AF37); // Gold
      case MenuWineFlagType.tasteMatch:
        return const Color(0xFF8B1E3F); // Wine Burgundy
    }
  }

  Color get backgroundColor {
    switch (type) {
      case MenuWineFlagType.deal:
        return const Color(0xFF00897B).withValues(alpha: 0.12);
      case MenuWineFlagType.gem:
        return const Color(0xFFD4AF37).withValues(alpha: 0.16);
      case MenuWineFlagType.tasteMatch:
        return const Color(0xFF8B1E3F).withValues(alpha: 0.12);
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'label': label,
        'reason': reason,
      };

  factory MenuWineFlag.fromJson(Map<String, dynamic> json) {
    final typeName = (json['type'] ?? 'gem').toString();
    final type = MenuWineFlagType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => MenuWineFlagType.gem,
    );
    return MenuWineFlag(
      type: type,
      label: (json['label'] ?? '').toString(),
      reason: json['reason'] as String?,
    );
  }
}

/// 🍷 8 Sensory Dimensions for Menu Wines (encompassing both Red and White profiles)
class MenuWineRadarMetrics {
  final double tannins; // 0.0 for whites, 1.0-10.0 for reds (Tannicité & Structure)
  final double acidity; // 1.0-10.0 (Fraîcheur & Vivacité)
  final double body; // 1.0-10.0 (Puissance & Corps)
  final double fruit; // 1.0-10.0 (Fruit & Gourmandise)
  final double oak; // 1.0-10.0 (Boisé & Élevage)
  final double minerality; // 1.0-10.0 (Minéralité & Terroir / Tension)
  final double butteriness; // 0.0-10.0 (Caractère Beurré & Brioché pour les blancs)
  final double sweetness; // 1.0-10.0 (Sucre résiduel / Douceur)

  const MenuWineRadarMetrics({
    this.tannins = 0.0,
    this.acidity = 5.0,
    this.body = 5.0,
    this.fruit = 5.5,
    this.oak = 3.0,
    this.minerality = 5.0,
    this.butteriness = 0.0,
    this.sweetness = 1.5,
  });

  Map<String, dynamic> toJson() => {
        'tannins': tannins,
        'acidity': acidity,
        'body': body,
        'fruit': fruit,
        'oak': oak,
        'minerality': minerality,
        'butteriness': butteriness,
        'sweetness': sweetness,
      };

  factory MenuWineRadarMetrics.fromJson(Map<String, dynamic> json) {
    return MenuWineRadarMetrics(
      tannins: (json['tannins'] as num?)?.toDouble() ?? 0.0,
      acidity: (json['acidity'] as num?)?.toDouble() ?? 5.0,
      body: (json['body'] as num?)?.toDouble() ?? 5.0,
      fruit: (json['fruit'] as num?)?.toDouble() ?? 5.5,
      oak: (json['oak'] as num?)?.toDouble() ?? 3.0,
      minerality: (json['minerality'] as num?)?.toDouble() ?? 5.0,
      butteriness: (json['butteriness'] as num?)?.toDouble() ?? 0.0,
      sweetness: (json['sweetness'] as num?)?.toDouble() ?? 1.5,
    );
  }

  /// 7-axis dynamic values for Red Wine Comparison
  List<double> toRedValues() => [
        tannins.clamp(1.0, 10.0), // Axe 1: Tannins & Structure
        body.clamp(1.0, 10.0), // Axe 2: Puissance & Corps
        acidity.clamp(1.0, 10.0), // Axe 3: Fraîcheur & Acidité
        fruit.clamp(1.0, 10.0), // Axe 4: Fruit & Baies
        oak.clamp(1.0, 10.0), // Axe 5: Boisé & Élevage
        minerality.clamp(1.0, 10.0), // Axe 6: Minéralité & Épices
        sweetness.clamp(1.0, 10.0), // Axe 7: Persistance & Rondeur
      ];

  /// 7-axis dynamic values for White Wine Comparison
  List<double> toWhiteValues() => [
        minerality.clamp(1.0, 10.0), // Axe 1: Minéralité & Tension
        acidity.clamp(1.0, 10.0), // Axe 2: Fraîcheur & Vivacité
        fruit.clamp(1.0, 10.0), // Axe 3: Fruit & Fleurs
        butteriness.clamp(1.0, 10.0), // Axe 4: Beurré & Rondeur
        oak.clamp(1.0, 10.0), // Axe 5: Boisé & Toasté
        sweetness.clamp(1.0, 10.0), // Axe 6: Douceur & Sucre
        body.clamp(1.0, 10.0), // Axe 7: Corps & Puissance
      ];

  /// Convert to standard 6-axis metrics for Red Wine Comparison (compat)
  WineTasteRadarMetrics toRedRadarMetrics() {
    return WineTasteRadarMetrics(
      body: tannins.clamp(1.0, 10.0),
      acidity: body.clamp(1.0, 10.0),
      fruit: acidity.clamp(1.0, 10.0),
      oak: fruit.clamp(1.0, 10.0),
      minerality: oak.clamp(1.0, 10.0),
      sweetness: minerality.clamp(1.0, 10.0),
    );
  }

  /// Convert to standard 6-axis metrics for White Wine Comparison (compat)
  WineTasteRadarMetrics toWhiteRadarMetrics() {
    return WineTasteRadarMetrics(
      body: minerality.clamp(1.0, 10.0),
      acidity: acidity.clamp(1.0, 10.0),
      fruit: fruit.clamp(1.0, 10.0),
      oak: butteriness.clamp(1.0, 10.0),
      minerality: oak.clamp(1.0, 10.0),
      sweetness: body.clamp(1.0, 10.0),
    );
  }

  static List<String> get redAxisLabels => [
        'Tannins &\nStructure',
        'Puissance\n& Corps',
        'Fraîcheur\n& Acidité',
        'Fruit &\nBaies',
        'Boisé &\nÉlevage',
        'Minéralité\n& Épices',
        'Persistance\n& Rondeur',
      ];

  static List<String> get whiteAxisLabels => [
        'Minéralité\n& Tension',
        'Fraîcheur\n& Vivacité',
        'Fruit &\nFleurs',
        'Beurré &\nRondeur',
        'Boisé &\nToasté',
        'Douceur &\nSucre',
        'Corps &\nPuissance',
      ];
}

/// A Wine recognized from a restaurant wine menu
class MenuWine {
  final String id;
  final String name;
  final String producer;
  final int? vintage;
  final String wineType; // 'red', 'white', 'rose', 'sparkling', 'dessert', 'fortified'
  final String? appellation;
  final String? region;
  final String? country;
  final List<String> grapes;
  final double? bottlePrice;
  final List<MenuWineGlassPrice> glassPrices;
  final MenuWineRadarMetrics metrics;
  final List<String> tags; // e.g. "minéral", "beurré", "tannique", "fruité", "léger", "puissant", "boisé"
  final String? sommelierComment;
  final List<String> foodPairings;
  final double? userMatchScore; // 0 to 100%
  final bool isGem; // Remarkable wine from cult/artisan star or insider gem
  final String? gemReason;
  final bool isDeal; // Outstanding quality-to-price ratio or unusually low markup
  final String? dealReason;
  final double? estimatedRetailPrice; // Approx wine merchant/caviste price
  final MenuWineFlag? flag; // Active badge computed by MenuFlaggingEngine

  const MenuWine({
    required this.id,
    required this.name,
    required this.producer,
    this.vintage,
    required this.wineType,
    this.appellation,
    this.region,
    this.country,
    this.grapes = const [],
    this.bottlePrice,
    this.glassPrices = const [],
    this.metrics = const MenuWineRadarMetrics(),
    this.tags = const [],
    this.sommelierComment,
    this.foodPairings = const [],
    this.userMatchScore,
    this.isGem = false,
    this.gemReason,
    this.isDeal = false,
    this.dealReason,
    this.estimatedRetailPrice,
    this.flag,
  });

  /// Normalized unique lookup key to prevent re-searching in Gemini
  String get cacheKey {
    final cleanName = name.trim().toLowerCase();
    final cleanProd = producer.trim().toLowerCase();
    final v = vintage ?? 0;
    final type = wineType.trim().toLowerCase();
    return '${cleanName}__${cleanProd}__${v}__$type';
  }

  bool get isRed => wineType.toLowerCase() == 'red' || wineType.toLowerCase().contains('rouge');
  bool get isWhite => wineType.toLowerCase() == 'white' || wineType.toLowerCase().contains('blanc');
  bool get isRose => wineType.toLowerCase() == 'rose' || wineType.toLowerCase().contains('rosé');
  bool get isSparkling =>
      wineType.toLowerCase().contains('sparkling') ||
      wineType.toLowerCase().contains('champ') ||
      wineType.toLowerCase().contains('bulles') ||
      wineType.toLowerCase().contains('effervescent');

  bool get hasGlassPrice => glassPrices.isNotEmpty;
  double? get primaryGlassPrice => glassPrices.isNotEmpty ? glassPrices.first.price : null;

  String get countryFlag {
    final c = (country ?? '').toLowerCase().trim();
    if (c.contains('france') || c == 'fr') return '🇫🇷';
    if (c.contains('ital') || c == 'it') return '🇮🇹';
    if (c.contains('espag') || c.contains('spain') || c == 'es') return '🇪🇸';
    if (c.contains('portug') || c == 'pt') return '🇵🇹';
    if (c.contains('allemag') || c.contains('german') || c == 'de') return '🇩🇪';
    if (c.contains('usa') || c.contains('état') || c.contains('etat') || c.contains('state') || c == 'us') return '🇺🇸';
    if (c.contains('argentin') || c == 'ar') return '🇦🇷';
    if (c.contains('chili') || c.contains('chile') || c == 'cl') return '🇨🇱';
    if (c.contains('austral') || c == 'au') return '🇦🇺';
    if (c.contains('zélande') || c.contains('zealand') || c == 'nz') return '🇳🇿';
    if (c.contains('afrique') || c.contains('south africa') || c == 'za') return '🇿🇦';
    if (c.contains('suisse') || c.contains('switzer') || c == 'ch') return '🇨🇭';
    if (c.contains('autrich') || c.contains('austria') || c == 'at') return '🇦🇹';
    if (c.contains('grèce') || c.contains('greece') || c == 'gr') return '🇬🇷';
    if (c.contains('géorgie') || c.contains('georgia') || c == 'ge') return '🇬🇪';
    if (c.contains('liban') || c.contains('lebanon') || c == 'lb') return '🇱🇧';
    return '🌍';
  }

  String get countryWithFlag {
    if (country == null || country!.trim().isEmpty) return '';
    return '$countryFlag ${country!.trim()}';
  }

  String get priceDisplay {
    final parts = <String>[];
    if (bottlePrice != null && bottlePrice! > 0) {
      parts.add('${CurrencyHelper.formatPrice(bottlePrice!)} / bt');
    }
    if (glassPrices.isNotEmpty) {
      final g = glassPrices.first;
      parts.add('${CurrencyHelper.formatPrice(g.price)} (${g.format})');
    }
    if (parts.isEmpty) return 'Prix non indiqué';
    return parts.join(' • ');
  }

  Color get colorIndicator {
    if (isRed) return const Color(0xFF8B1E3F);
    if (isWhite) return const Color(0xFFE8D08D);
    if (isRose) return const Color(0xFFF48FB1);
    if (isSparkling) return const Color(0xFFD4AF37);
    return Colors.amber.shade700;
  }

  RadarChartDataset toRadarDataset({required Color color}) {
    final radarMetrics = isWhite ? metrics.toWhiteRadarMetrics() : metrics.toRedRadarMetrics();
    return RadarChartDataset(
      label: vintage != null ? '$name ($vintage)' : name,
      metrics: radarMetrics,
      color: color,
    );
  }

  MenuWine copyWith({
    String? id,
    String? name,
    String? producer,
    int? vintage,
    String? wineType,
    String? appellation,
    String? region,
    String? country,
    List<String>? grapes,
    double? bottlePrice,
    List<MenuWineGlassPrice>? glassPrices,
    MenuWineRadarMetrics? metrics,
    List<String>? tags,
    String? sommelierComment,
    List<String>? foodPairings,
    double? userMatchScore,
    bool? isGem,
    String? gemReason,
    bool? isDeal,
    String? dealReason,
    double? estimatedRetailPrice,
    MenuWineFlag? flag,
  }) {
    return MenuWine(
      id: id ?? this.id,
      name: name ?? this.name,
      producer: producer ?? this.producer,
      vintage: vintage ?? this.vintage,
      wineType: wineType ?? this.wineType,
      appellation: appellation ?? this.appellation,
      region: region ?? this.region,
      country: country ?? this.country,
      grapes: grapes ?? this.grapes,
      bottlePrice: bottlePrice ?? this.bottlePrice,
      glassPrices: glassPrices ?? this.glassPrices,
      metrics: metrics ?? this.metrics,
      tags: tags ?? this.tags,
      sommelierComment: sommelierComment ?? this.sommelierComment,
      foodPairings: foodPairings ?? this.foodPairings,
      userMatchScore: userMatchScore ?? this.userMatchScore,
      isGem: isGem ?? this.isGem,
      gemReason: gemReason ?? this.gemReason,
      isDeal: isDeal ?? this.isDeal,
      dealReason: dealReason ?? this.dealReason,
      estimatedRetailPrice: estimatedRetailPrice ?? this.estimatedRetailPrice,
      flag: flag ?? this.flag,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'producer': producer,
        'vintage': vintage,
        'wine_type': wineType,
        'appellation': appellation,
        'region': region,
        'country': country,
        'grapes': grapes,
        'bottle_price': bottlePrice,
        'glass_prices': glassPrices.map((g) => g.toJson()).toList(),
        'metrics': metrics.toJson(),
        'tags': tags,
        'sommelier_comment': sommelierComment,
        'food_pairings': foodPairings,
        'user_match_score': userMatchScore,
        'is_gem': isGem,
        'gem_reason': gemReason,
        'is_deal': isDeal,
        'deal_reason': dealReason,
        'estimated_retail_price': estimatedRetailPrice,
        'flag': flag?.toJson(),
      };

  factory MenuWine.fromJson(Map<String, dynamic> json) {
    return MenuWine(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Vin sans nom').toString(),
      producer: (json['producer'] ?? 'Domaine inconnu').toString(),
      vintage: json['vintage'] as int?,
      wineType: (json['wine_type'] ?? 'red').toString(),
      appellation: json['appellation'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      grapes: (json['grapes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      bottlePrice: (json['bottle_price'] as num?)?.toDouble(),
      glassPrices: (json['glass_prices'] as List?)
              ?.map((e) => MenuWineGlassPrice.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      metrics: json['metrics'] != null
          ? MenuWineRadarMetrics.fromJson(Map<String, dynamic>.from(json['metrics'] as Map))
          : const MenuWineRadarMetrics(),
      tags: (json['tags'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [],
      sommelierComment: json['sommelier_comment'] as String?,
      foodPairings: (json['food_pairings'] as List?)?.map((e) => e.toString()).toList() ?? [],
      userMatchScore: (json['user_match_score'] as num?)?.toDouble(),
      isGem: json['is_gem'] as bool? ?? false,
      gemReason: json['gem_reason'] as String?,
      isDeal: json['is_deal'] as bool? ?? false,
      dealReason: json['deal_reason'] as String?,
      estimatedRetailPrice: (json['estimated_retail_price'] as num?)?.toDouble(),
      flag: json['flag'] != null
          ? MenuWineFlag.fromJson(Map<String, dynamic>.from(json['flag'] as Map))
          : null,
    );
  }
}

/// Represents a full scanned restaurant menu
class ScannedMenu {
  final String id;
  final String restaurantName;
  final DateTime scannedAt;
  final List<String> pagePhotoPaths;
  final List<MenuWine> wines;

  const ScannedMenu({
    required this.id,
    required this.restaurantName,
    required this.scannedAt,
    required this.pagePhotoPaths,
    required this.wines,
  });

  List<MenuWine> get redWines => wines.where((w) => w.isRed).toList();
  List<MenuWine> get whiteWines => wines.where((w) => w.isWhite).toList();
  List<MenuWine> get roseWines => wines.where((w) => w.isRose).toList();
  List<MenuWine> get sparklingWines => wines.where((w) => w.isSparkling).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurant_name': restaurantName,
        'scanned_at': scannedAt.toIso8601String(),
        'page_photo_paths': pagePhotoPaths,
        'wines': wines.map((w) => w.toJson()).toList(),
      };

  factory ScannedMenu.fromJson(Map<String, dynamic> json) {
    return ScannedMenu(
      id: (json['id'] ?? '').toString(),
      restaurantName: (json['restaurant_name'] ?? 'Restaurant').toString(),
      scannedAt: json['scanned_at'] != null
          ? DateTime.tryParse(json['scanned_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      pagePhotoPaths: (json['page_photo_paths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      wines: (json['wines'] as List?)
              ?.map((e) => MenuWine.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

/// 🎯 Calculator to compute Affinity Score between a [MenuWine] and a [TasteProfile]
class MenuWineMatchCalculator {
  static double? calculateMatch(MenuWine wine, TasteProfile? profile) => computeMatchScore(wine, profile);

  static double? computeMatchScore(MenuWine wine, TasteProfile? profile) {
    if (profile == null || !profile.isWellProvided) return null;

    double score = 70.0; // Base score for personalized evaluation

    // 1. Color / Type affinity (+15 or -25)
    final favTypes = profile.favoriteTypes.map((t) => t.toLowerCase()).toList();
    if (favTypes.isNotEmpty) {
      final matchesColor = favTypes.any((t) =>
          (wine.isRed && t.contains('rouge')) ||
          (wine.isWhite && t.contains('blanc')) ||
          (wine.isRose && t.contains('rosé')) ||
          (wine.isSparkling && (t.contains('bulles') || t.contains('champ'))));
      if (matchesColor) {
        score += 15.0;
      } else {
        score -= 20.0;
      }
    }

    // 2. Region / Appellation affinity (+12)
    final favRegions = profile.favoriteRegions.map((r) => r.toLowerCase()).toList();
    final wineRegion = (wine.region ?? '').toLowerCase();
    final wineAppell = (wine.appellation ?? '').toLowerCase();
    if (favRegions.any((r) => wineRegion.contains(r) || wineAppell.contains(r))) {
      score += 12.0;
    }

    // 3. Grape Variety affinity (+10)
    final favGrapes = profile.favoriteGrapes.map((g) => g.toLowerCase()).toList();
    if (wine.grapes.any((wg) => favGrapes.any((fg) => wg.toLowerCase().contains(fg)))) {
      score += 10.0;
    }

    // 4. Disliked characteristics penalty (-30)
    final dislikes = profile.dislikedCharacteristics.map((d) => d.toLowerCase()).toList();
    for (final d in dislikes) {
      if (d.contains('tann') && wine.metrics.tannins > 7.0) score -= 25.0;
      if (d.contains('bois') && wine.metrics.oak > 7.0) score -= 25.0;
      if (d.contains('acid') && wine.metrics.acidity > 7.5) score -= 20.0;
      if (d.contains('sucr') && wine.metrics.sweetness > 4.0) score -= 20.0;
    }

    // 5. Tannin & Body preference alignment
    if (profile.avgTanninPreference != null && wine.isRed) {
      final diff = (profile.avgTanninPreference! * 10 - wine.metrics.tannins).abs();
      score += (5.0 - diff).clamp(-10.0, 8.0);
    }
    if (profile.avgBodyPreference != null) {
      final diff = (profile.avgBodyPreference! * 10 - wine.metrics.body).abs();
      score += (5.0 - diff).clamp(-10.0, 8.0);
    }

    return score.clamp(35.0, 99.0).roundToDouble();
  }
}
