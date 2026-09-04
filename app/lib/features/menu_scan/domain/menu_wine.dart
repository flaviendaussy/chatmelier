import 'package:flutter/material.dart';
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

  /// Convert to standard 6-axis metrics for Red Wine Comparison
  /// Axes: Tannicité & Structure, Puissance & Corps, Fraîcheur & Acidité, Fruit & Rondeur, Boisé & Élevage, Minéralité & Épices
  WineTasteRadarMetrics toRedRadarMetrics() {
    return WineTasteRadarMetrics(
      body: tannins.clamp(1.0, 10.0), // Axe 1: Tannins & Structure
      acidity: body.clamp(1.0, 10.0), // Axe 2: Puissance & Corps
      fruit: acidity.clamp(1.0, 10.0), // Axe 3: Fraîcheur & Acidité
      oak: fruit.clamp(1.0, 10.0), // Axe 4: Fruit & Gourmandise
      minerality: oak.clamp(1.0, 10.0), // Axe 5: Boisé & Élevage
      sweetness: minerality.clamp(1.0, 10.0), // Axe 6: Minéralité & Épices
    );
  }

  /// Convert to standard 6-axis metrics for White Wine Comparison
  /// Axes: Minéralité & Tension, Fraîcheur & Vivacité, Fruit & Arômes, Beurré & Rondeur, Boisé & Élevage, Corps & Puissance
  WineTasteRadarMetrics toWhiteRadarMetrics() {
    return WineTasteRadarMetrics(
      body: minerality.clamp(1.0, 10.0), // Axe 1: Minéralité & Tension
      acidity: acidity.clamp(1.0, 10.0), // Axe 2: Fraîcheur & Vivacité
      fruit: fruit.clamp(1.0, 10.0), // Axe 3: Fruit & Arômes
      oak: butteriness.clamp(1.0, 10.0), // Axe 4: Beurré & Rondeur
      minerality: oak.clamp(1.0, 10.0), // Axe 5: Boisé & Élevage
      sweetness: body.clamp(1.0, 10.0), // Axe 6: Corps & Puissance
    );
  }

  static List<String> get redAxisLabels => [
        'Tannins &\nStructure',
        'Puissance\n& Corps',
        'Fraîcheur\n& Acidité',
        'Fruit &\nGourmandise',
        'Boisé &\nÉlevage',
        'Minéralité\n& Épices',
      ];

  static List<String> get whiteAxisLabels => [
        'Minéralité\n& Tension',
        'Fraîcheur\n& Vivacité',
        'Fruit &\nArômes',
        'Beurré &\nRondeur',
        'Boisé &\nÉlevage',
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

  double? get primaryGlassPrice => glassPrices.isNotEmpty ? glassPrices.first.price : null;

  String get priceDisplay {
    final parts = <String>[];
    if (bottlePrice != null && bottlePrice! > 0) {
      parts.add('${bottlePrice!.toStringAsFixed(bottlePrice! % 1 == 0 ? 0 : 2)} € / bt');
    }
    if (glassPrices.isNotEmpty) {
      final g = glassPrices.first;
      parts.add('${g.price.toStringAsFixed(g.price % 1 == 0 ? 0 : 2)} € (${g.format})');
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
  static double calculateMatch(MenuWine wine, TasteProfile? profile) => computeMatchScore(wine, profile);

  static double computeMatchScore(MenuWine wine, TasteProfile? profile) {
    if (profile == null) return 72.0;

    double score = 70.0; // Base score

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
