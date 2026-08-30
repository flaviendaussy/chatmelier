import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'taste_profile.dart';

/// 🍷 6 Enological Dimensions for Taste Radar Spider Charts
class WineTasteRadarMetrics {
  final double body; // 1. Puissance & Corps (0.0 to 10.0)
  final double acidity; // 2. Fraîcheur & Acidité (0.0 to 10.0)
  final double fruit; // 3. Fruit & Rondeur (0.0 to 10.0)
  final double oak; // 4. Boisé & Élevage (0.0 to 10.0)
  final double minerality; // 5. Minéralité & Terroir (0.0 to 10.0)
  final double sweetness; // 6. Douceur & Sucres (0.0 to 10.0)

  const WineTasteRadarMetrics({
    required this.body,
    required this.acidity,
    required this.fruit,
    required this.oak,
    required this.minerality,
    required this.sweetness,
  });

  /// Default balanced profile
  static const balanced = WineTasteRadarMetrics(
    body: 5.5,
    acidity: 5.5,
    fruit: 6.0,
    oak: 4.5,
    minerality: 5.0,
    sweetness: 2.0,
  );

  List<double> toList() => [body, acidity, fruit, oak, minerality, sweetness];

  static List<String> get axisLabels => [
        'Puissance\n& Corps',
        'Fraîcheur\n& Acidité',
        'Fruit &\nGourmandise',
        'Boisé &\nÉlevage',
        'Minéralité\n& Terroir',
        'Douceur &\nMoelleux',
      ];

  static List<IconData> get axisIcons => [
        Icons.fitness_center_rounded,
        Icons.wb_sunny_outlined,
        Icons.eco_rounded,
        Icons.forest_rounded,
        Icons.landscape_rounded,
        Icons.water_drop_rounded,
      ];
}

/// Helper & Matching Insights for Profile Comparisons
class TasteAffinityResult {
  final double affinityPercentage; // 0 to 100%
  final String commonGroundsSummary;
  final String divergencesSummary;
  final String idealWineRecommendation;

  const TasteAffinityResult({
    required this.affinityPercentage,
    required this.commonGroundsSummary,
    required this.divergencesSummary,
    required this.idealWineRecommendation,
  });
}

/// 🧠 Mathematical and Enological Calculator for Spider Charts
class WineTasteRadarCalculator {
  /// Computes the 6-axis taste radar metrics for a given [TasteProfile].
  static WineTasteRadarMetrics compute(TasteProfile profile) {
    double body = 5.0;
    double acidity = 5.0;
    double fruit = 5.5;
    double oak = 4.0;
    double minerality = 5.0;
    double sweetness = 1.5;

    // 1. Incorporate explicit averages if set
    if (profile.avgBodyPreference != null) {
      body = (profile.avgBodyPreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgAcidityPreference != null) {
      acidity = (profile.avgAcidityPreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgTanninPreference != null) {
      body = ((body + (profile.avgTanninPreference! * 10.0)) / 2).clamp(1.0, 10.0);
    }

    // 2. Favorite types influence
    for (final t in profile.favoriteTypes) {
      final low = t.toLowerCase();
      if (low.contains('rouge')) {
        body += 1.2;
        fruit += 0.8;
      }
      if (low.contains('blanc')) {
        acidity += 1.2;
        minerality += 0.8;
      }
      if (low.contains('champagne') || low.contains('efferv') || low.contains('sparkling')) {
        acidity += 1.5;
        minerality += 1.2;
        body -= 0.8;
      }
      if (low.contains('rosé') || low.contains('rose')) {
        fruit += 1.2;
        acidity += 0.8;
        body -= 0.6;
      }
      if (low.contains('liquor') || low.contains('moell') || low.contains('sauterne') || low.contains('dessert')) {
        sweetness += 5.0;
        fruit += 1.5;
      }
    }

    // 3. Favorite regions influence
    for (final r in profile.favoriteRegions) {
      final low = r.toLowerCase();
      if (low.contains('bordeaux') || low.contains('madiran') || low.contains('cahors')) {
        body += 1.4;
        oak += 1.2;
      }
      if (low.contains('bourgogne')) {
        acidity += 0.8;
        minerality += 1.2;
        fruit += 0.8;
      }
      if (low.contains('rhône') || low.contains('rhone')) {
        body += 1.0;
        fruit += 1.2;
      }
      if (low.contains('loire') || low.contains('alsace') || low.contains('chablis')) {
        acidity += 1.4;
        minerality += 1.4;
      }
      if (low.contains('provence') || low.contains('italie') || low.contains('espagne')) {
        fruit += 1.0;
      }
    }

    // 4. Favorite grapes influence
    for (final g in profile.favoriteGrapes) {
      final low = g.toLowerCase();
      if (low.contains('cabernet') || low.contains('syrah') || low.contains('mourvèdre') || low.contains('malbec') || low.contains('nebbiolo')) {
        body += 1.2;
        oak += 0.8;
      }
      if (low.contains('pinot noir') || low.contains('gamay')) {
        fruit += 1.2;
        acidity += 0.8;
      }
      if (low.contains('chardonnay')) {
        minerality += 0.8;
        oak += 0.6;
      }
      if (low.contains('sauvignon') || low.contains('riesling') || low.contains('chenin')) {
        acidity += 1.5;
        minerality += 1.2;
      }
      if (low.contains('grenache') || low.contains('merlot') || low.contains('viognier')) {
        fruit += 1.3;
        body += 0.6;
      }
    }

    // 5. Disliked characteristics (penalties)
    for (final d in profile.dislikedCharacteristics) {
      final low = d.toLowerCase();
      if (low.contains('boisé') || low.contains('chêne') || low.contains('bois') || low.contains('vanille')) {
        oak = math.max(1.0, oak - 2.5);
      }
      if (low.contains('acide') || low.contains('vert') || low.contains('vif')) {
        acidity = math.max(1.0, acidity - 2.5);
      }
      if (low.contains('tann') || low.contains('lourd') || low.contains('astringent') || low.contains('puissant')) {
        body = math.max(1.0, body - 2.5);
      }
      if (low.contains('sucré') || low.contains('sucre') || low.contains('doux')) {
        sweetness = math.max(0.5, sweetness - 2.0);
      }
    }

    // 6. Liked traits bonus
    profile.likedTraits.forEach((trait, count) {
      final low = trait.toLowerCase();
      final weight = math.min(count * 0.4, 2.0);
      if (low.contains('fruit') || low.contains('gourmand')) fruit += weight;
      if (low.contains('frais') || low.contains('minéral')) {
        acidity += weight * 0.8;
        minerality += weight * 0.8;
      }
      if (low.contains('puissant') || low.contains('charpenté') || low.contains('tannique')) body += weight;
      if (low.contains('boisé') || low.contains('vanille') || low.contains('épicé')) oak += weight;
      if (low.contains('doux') || low.contains('moelleux')) sweetness += weight;
    });

    return WineTasteRadarMetrics(
      body: body.clamp(1.0, 10.0),
      acidity: acidity.clamp(1.0, 10.0),
      fruit: fruit.clamp(1.0, 10.0),
      oak: oak.clamp(1.0, 10.0),
      minerality: minerality.clamp(1.0, 10.0),
      sweetness: sweetness.clamp(0.5, 10.0),
    );
  }

  /// Calculates the taste affinity score and advice between two taste profiles.
  static TasteAffinityResult compare(TasteProfile p1, TasteProfile p2) {
    final m1 = compute(p1);
    final m2 = compute(p2);

    final l1 = m1.toList();
    final l2 = m2.toList();

    // Euclidean distance normalized
    double sumDistSq = 0;
    for (int i = 0; i < l1.length; i++) {
      sumDistSq += math.pow(l1[i] - l2[i], 2);
    }
    final dist = math.sqrt(sumDistSq);
    final maxDist = math.sqrt(6 * math.pow(9.0, 2)); // ~22.0
    final affinityPct = ((1.0 - (dist / maxDist)) * 100.0).clamp(30.0, 99.0);

    // Identify shared top axes and divergences
    final commonGrounds = <String>[];
    final divergences = <String>[];

    final axes = WineTasteRadarMetrics.axisLabels;
    for (int i = 0; i < l1.length; i++) {
      final diff = (l1[i] - l2[i]).abs();
      final cleanName = axes[i].replaceAll('\n', ' ');
      if (diff <= 1.8 && (l1[i] >= 6.0 || l2[i] >= 6.0)) {
        commonGrounds.add(cleanName);
      } else if (diff >= 3.0) {
        if (l1[i] > l2[i]) {
          divergences.add('${p1.name} apprécie davantage "$cleanName" que ${p2.name}');
        } else {
          divergences.add('${p2.name} apprécie davantage "$cleanName" que ${p1.name}');
        }
      }
    }

    String commonSummary = commonGrounds.isNotEmpty
        ? 'Vous partagez une belle affinité pour : ${commonGrounds.join(', ')}.'
        : 'Vos palais sont complémentaires sur l\'ensemble des styles de vin.';

    String divSummary = divergences.isNotEmpty
        ? divergences.join('. ')
        : 'Très peu de divergences notables entre vos deux profils !';

    // Sommelier recommendation tailored for both
    final avgBody = (m1.body + m2.body) / 2;
    final avgFruit = (m1.fruit + m2.fruit) / 2;
    final avgAcid = (m1.acidity + m2.acidity) / 2;

    String recommendation;
    if (avgBody >= 7.0) {
      recommendation = '🍷 Un vin rouge structuré mais velouté : Vallée du Rhône Sud (Châteauneuf-du-Pape, Gigondas) ou un grand Bordeaux rive droite souple.';
    } else if (avgAcid >= 7.0) {
      recommendation = '🥂 Un vin blanc vif et élégant : Chablis Premier Cru, Sancerre ou un Champagne Blanc de Blancs Extra-Brut.';
    } else if (avgFruit >= 7.0) {
      recommendation = '🍇 Un vin rouge ou blanc gourmand et fruité : Côtes-du-Rhône, Crozes-Hermitage ou un Pinot Noir de Bourgogne soyeux.';
    } else {
      recommendation = '✨ Un vin équilibré et consensuel : un Bourgogne rouge délicat ou un blanc minéral de la Loire.';
    }

    return TasteAffinityResult(
      affinityPercentage: affinityPct,
      commonGroundsSummary: commonSummary,
      divergencesSummary: divSummary,
      idealWineRecommendation: recommendation,
    );
  }
}
