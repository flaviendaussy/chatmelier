import 'dart:math' as math;
import '../../sommelier/domain/guest_matcher_engine.dart';
import 'menu_wine.dart';

class MenuTableMatchResult {
  final MenuWine menuWine;
  final double harmonyScore; // 0 à 100%
  final String consensusRationale;
  final Map<String, double> guestScores; // guestId -> score
  final List<String> aversionAlerts;

  const MenuTableMatchResult({
    required this.menuWine,
    required this.harmonyScore,
    required this.consensusRationale,
    required this.guestScores,
    this.aversionAlerts = const [],
  });
}

class MenuTableMatcherEngine {
  /// Calcule et classe les 3 meilleures bouteilles de la carte du restaurant pour le consensus de la table.
  static List<MenuTableMatchResult> rankTop3WinesForTable({
    required List<MenuWine> menuWines,
    required List<GuestProfile> guests,
  }) {
    if (menuWines.isEmpty || guests.isEmpty) return [];

    final results = <MenuTableMatchResult>[];

    for (final wine in menuWines) {
      final guestScores = <String, double>{};
      final alerts = <String>[];
      final scoresList = <double>[];

      for (final guest in guests) {
        final score = _calculateGuestWineHarmony(wine, guest, alerts);
        guestScores[guest.id] = score;
        scoresList.add(score);
      }

      // Moyenne arithmétique
      final mean = scoresList.reduce((a, b) => a + b) / scoresList.length;

      // Variance / écart-type pour pénaliser les profils trop clivants
      double varianceSum = 0.0;
      for (final s in scoresList) {
        varianceSum += math.pow(s - mean, 2);
      }
      final variance = varianceSum / scoresList.length;
      final stdDev = math.sqrt(variance);

      // Pénalité d'aversion sévère
      final aversionPenalty = alerts.length * 18.0;

      // Score final d'harmonie collective (0 à 100)
      final consensusScore = (mean - (stdDev * 0.45) - aversionPenalty).clamp(10.0, 100.0);

      final rationale = _generateTableRationale(wine, guests, consensusScore, alerts);

      results.add(MenuTableMatchResult(
        menuWine: wine,
        harmonyScore: double.parse(consensusScore.toStringAsFixed(1)),
        consensusRationale: rationale,
        guestScores: guestScores,
        aversionAlerts: alerts,
      ));
    }

    // Tri décroissant par harmonie collective
    results.sort((a, b) => b.harmonyScore.compareTo(a.harmonyScore));

    return results.take(3).toList();
  }

  static double _calculateGuestWineHarmony(
    MenuWine wine,
    GuestProfile guest,
    List<String> alerts,
  ) {
    double score = 70.0; // Base de départ

    final radar = wine.metrics;
    final guestRadar = guest.radar;

    // 1. Concordance de couleur
    final wineType = wine.wineType.toLowerCase();
    if (guest.favoriteTypes.isNotEmpty) {
      final matchesFavorite = guest.favoriteTypes.any((t) {
        final tl = t.toLowerCase();
        return wineType.contains(tl);
      });
      if (matchesFavorite) {
        score += 15.0;
      }
    }

    // 2. Vérification des aversions strictes
    for (final disliked in guest.dislikedCharacteristics) {
      final dl = disliked.toLowerCase();
      if (dl.contains('tanin') || dl.contains('tannin') || dl.contains('dur')) {
        if (radar.tannins >= 7.5) {
          score -= 35.0;
          alerts.add('${guest.name} a une aversion pour les tanins durs : ce vin est très charpenté (${radar.tannins.toStringAsFixed(1)}/10).');
        }
      }
      if (dl.contains('acid') || dl.contains('acide') || dl.contains('vert')) {
        if (radar.acidity >= 8.5) {
          score -= 30.0;
          alerts.add('${guest.name} redoute la forte acidité : ce flacon est très tranchant (${radar.acidity.toStringAsFixed(1)}/10).');
        }
      }
      if (dl.contains('bois') || dl.contains('chêne') || dl.contains('vanill')) {
        if (radar.oak >= 7.5) {
          score -= 25.0;
          alerts.add('${guest.name} n\'apprécie pas le boisé marqué : élevage puissant (${radar.oak.toStringAsFixed(1)}/10).');
        }
      }
    }

    // 3. Proximité des axes sensoriels
    // Tannins (uniquement pour les rouges)
    if (!wine.isWhite && radar.tannins > 0.0) {
      final tanninDiff = (radar.tannins - guestRadar.tannin).abs();
      score -= (tanninDiff * 1.5);
    }

    // Corps / Puissance
    final bodyDiff = (radar.body - guestRadar.body).abs();
    score -= (bodyDiff * 1.5);

    // Vivacité / Acidité
    final acidDiff = (radar.acidity - guestRadar.acidity).abs();
    score -= (acidDiff * 1.5);

    // Fruit
    final fruitDiff = (radar.fruit - guestRadar.freshFruit).abs();
    score -= (fruitDiff * 1.0);

    // Bonus si le cépage est dans les favoris du convive
    if (wine.grapes.isNotEmpty && guest.favoriteGrapes.isNotEmpty) {
      for (final fg in guest.favoriteGrapes) {
        if (wine.grapes.any((g) => g.toLowerCase().contains(fg.toLowerCase()))) {
          score += 10.0;
          break;
        }
      }
    }

    return score.clamp(10.0, 100.0);
  }

  static String _generateTableRationale(
    MenuWine wine,
    List<GuestProfile> guests,
    double consensusScore,
    List<String> alerts,
  ) {
    final wineName = wine.name;
    final typeDesc = wine.wineType;

    if (alerts.isNotEmpty) {
      return '$wineName offre une belle opportunité mais présente une vigilance pour certains convives (${alerts.first.split(':').first}).';
    }

    if (consensusScore >= 90.0) {
      return 'Accord parfait pour la table ! $typeDesc allie un équilibre remarquable qui séduit aussi bien les amateurs de rondeur que de fraîcheur, sans aucun désaccord.';
    } else if (consensusScore >= 80.0) {
      return 'Excellent compromis de table : $wineName concilie le plaisir immédiat du fruit avec une trame souple qui fédère les palais présents.';
    } else {
      return 'Option intéressante de la carte, offrant un profil accessible pour le groupe.';
    }
  }
}
