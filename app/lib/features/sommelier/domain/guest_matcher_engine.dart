import 'dart:math' as math;
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/domain/wine_taste_radar.dart';

/// Représente un convive pour la recherche d'accord partagé.
class GuestProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final TasteProfile? tasteProfile;
  final List<String> favoriteTypes;
  final List<String> favoriteGrapes;
  final List<String> dislikedCharacteristics;
  final String archetype;

  const GuestProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.tasteProfile,
    this.favoriteTypes = const [],
    this.favoriteGrapes = const [],
    this.dislikedCharacteristics = const [],
    this.archetype = 'Curieux & Éclectique',
  });

  factory GuestProfile.fromTasteProfile(TasteProfile tp, {String? avatarUrl}) {
    return GuestProfile(
      id: tp.id,
      name: tp.name,
      avatarUrl: avatarUrl,
      tasteProfile: tp,
      favoriteTypes: tp.favoriteTypes,
      favoriteGrapes: tp.favoriteGrapes,
      dislikedCharacteristics: tp.dislikedCharacteristics,
      archetype: _detectArchetype(tp),
    );
  }

  static String _detectArchetype(TasteProfile tp) {
    final radar = tp.radarMetrics;
    if (radar.tannin >= 7.0 && radar.body >= 7.0) {
      return 'Amateur de Grands Rouges Puissants';
    } else if (radar.acidity >= 7.0 && radar.minerality >= 6.5) {
      return 'Adepte de Minéralité & Fraîcheur Droite';
    } else if (radar.freshFruit >= 7.0) {
      return 'Palais Friand & Fruit Croquant';
    } else if (radar.spice >= 7.0) {
      return 'Amateur de Vins Épicés & Singuliers';
    }
    return 'Curieux & Éclectique';
  }

  WineTasteRadarMetrics get radar {
    if (tasteProfile != null) {
      return tasteProfile!.radarMetrics;
    }
    if (archetype.contains('Minéral') || archetype.contains('Blanc')) {
      return const WineTasteRadarMetrics(
        tannin: 0.0,
        body: 5.0,
        oak: 2.0,
        ripeFruit: 4.5,
        spice: 3.0,
        freshFruit: 7.0,
        minerality: 7.5,
        acidity: 7.0,
      );
    }
    if (archetype.contains('Puissant') || archetype.contains('Tannique')) {
      return const WineTasteRadarMetrics(
        tannin: 8.0,
        body: 8.0,
        oak: 6.0,
        ripeFruit: 7.0,
        spice: 6.5,
        freshFruit: 5.0,
        minerality: 5.0,
        acidity: 4.5,
      );
    }
    // Fallback radar selon archétype
    return const WineTasteRadarMetrics(
      tannin: 4.0,
      body: 5.0,
      oak: 3.5,
      ripeFruit: 5.0,
      spice: 4.5,
      freshFruit: 6.0,
      minerality: 5.5,
      acidity: 5.5,
    );
  }
}

/// Résultat du calcul d'accord pour une bouteille donnée.
class GuestMatchResult {
  final Bottle bottle;
  final double consensusScore; // 0 à 100 %
  final Map<String, double> guestScores; // guestId -> score
  final List<String> aversionAlerts; // Liste des alertes d'aversions détectées
  final String sommelierRationale;

  const GuestMatchResult({
    required this.bottle,
    required this.consensusScore,
    required this.guestScores,
    required this.aversionAlerts,
    required this.sommelierRationale,
  });
}

class GuestMatcherEngine {
  /// Calcule et classe les bouteilles de la cave pour maximiser le plaisir de l'ensemble des convives.
  static List<GuestMatchResult> rankBottlesForGuests({
    required List<Bottle> bottles,
    required List<GuestProfile> guests,
    int maxResults = 10,
  }) {
    if (bottles.isEmpty || guests.isEmpty) return const [];

    final results = <GuestMatchResult>[];

    for (final bottle in bottles) {
      final wine = bottle.wine;
      if (wine == null) continue;

      final wineRadar = _estimateWineRadar(wine);
      final guestScores = <String, double>{};
      final aversionAlerts = <String>[];

      for (final guest in guests) {
        double score = _calculateCompatibility(wine, wineRadar, guest);

        // Détection des aversions critiques
        for (final disliked in guest.dislikedCharacteristics) {
          final dLower = disliked.toLowerCase();
          if (dLower.contains('tannique') && wineRadar.tannin >= 7.2) {
            score *= 0.4;
            aversionAlerts.add('${guest.name} : aversion aux tanins fermes');
          } else if (dLower.contains('acide') && wineRadar.acidity >= 7.5) {
            score *= 0.45;
            aversionAlerts.add('${guest.name} : aversion aux acidités vives');
          } else if (dLower.contains('bois') && wineRadar.oak >= 6.5) {
            score *= 0.45;
            aversionAlerts.add('${guest.name} : aversion au boisé dominant');
          }
        }

        guestScores[guest.id] = score.clamp(10.0, 100.0);
      }

      // Calcul du consensus global :
      // Utilisation d'une moyenne pondérée qui pénalise fortement les désaccords (écart-type)
      // pour favoriser un vin que TOUT LE MONDE apprécie plutôt qu'un vin 100% pour l'un et 20% pour l'autre.
      final scores = guestScores.values.toList();
      final mean = scores.reduce((a, b) => a + b) / scores.length;
      final variance = scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
      final stdDev = math.sqrt(variance);

      // Pénalité proportionnelle à l'hétérogénéité des avis
      final consensusScore = (mean - (stdDev * 0.45)).clamp(5.0, 99.0);

      final rationale = _generateSommelierRationale(wine, guests, guestScores, aversionAlerts, consensusScore);

      results.add(GuestMatchResult(
        bottle: bottle,
        consensusScore: double.parse(consensusScore.toStringAsFixed(1)),
        guestScores: guestScores,
        aversionAlerts: aversionAlerts.toSet().toList(),
        sommelierRationale: rationale,
      ));
    }

    results.sort((a, b) => b.consensusScore.compareTo(a.consensusScore));
    return results.take(maxResults).toList();
  }

  static double _calculateCompatibility(Wine wine, WineTasteRadarMetrics wineRadar, GuestProfile guest) {
    final guestRadar = guest.radar;

    // Distance euclidienne normalisée sur les 8 axes
    final dist = math.sqrt(
      math.pow(wineRadar.tannin - guestRadar.tannin, 2) +
      math.pow(wineRadar.body - guestRadar.body, 2) +
      math.pow(wineRadar.oak - guestRadar.oak, 2) +
      math.pow(wineRadar.ripeFruit - guestRadar.ripeFruit, 2) +
      math.pow(wineRadar.spice - guestRadar.spice, 2) +
      math.pow(wineRadar.freshFruit - guestRadar.freshFruit, 2) +
      math.pow(wineRadar.minerality - guestRadar.minerality, 2) +
      math.pow(wineRadar.acidity - guestRadar.acidity, 2),
    );

    // Max theoretical distance on 8 axes with scale 0-10 is sqrt(8 * 10^2) = 28.28
    double baseScore = (1.0 - (dist / 22.0)) * 100.0;

    // Bonus de cépages favoris
    if (guest.favoriteGrapes.isNotEmpty && wine.grapes.isNotEmpty) {
      final hasFavGrape = wine.grapes.any((g) =>
          guest.favoriteGrapes.any((fav) => fav.toLowerCase() == g.name.toLowerCase()));
      if (hasFavGrape) baseScore += 12.0;
    }

    // Bonus de type favori (ex: Rouge, Blanc sec, Champagne)
    if (guest.favoriteTypes.isNotEmpty && wine.type != null) {
      final matchesType = guest.favoriteTypes.any((t) =>
          t.toLowerCase().contains(wine.type!.toLowerCase()) || wine.type!.toLowerCase().contains(t.toLowerCase()));
      if (matchesType) baseScore += 8.0;
    }

    return baseScore.clamp(15.0, 100.0);
  }

  /// Estime le profil 8 axes du vin à partir de ses cépages, de son type et de sa région.
  static WineTasteRadarMetrics _estimateWineRadar(Wine wine) {
    double tannin = 3.0;
    double body = 5.0;
    double oak = 3.0;
    double ripeFruit = 5.0;
    double spice = 3.0;
    double freshFruit = 6.0;
    double minerality = 5.0;
    double acidity = 5.5;

    final typeLower = (wine.type ?? '').toLowerCase();
    final regionLower = (wine.region ?? '').toLowerCase();
    final grapesLower = wine.grapes.map((g) => g.name.toLowerCase()).join(' ');

    if (typeLower.contains('rouge') || typeLower.contains('red')) {
      tannin = 6.0;
      body = 6.5;
      freshFruit = 5.0;
      ripeFruit = 6.5;

      if (grapesLower.contains('syrah') || regionLower.contains('rhône')) {
        spice = 8.2;
        body = 7.5;
        tannin = 7.2;
        ripeFruit = 7.0;
      } else if (grapesLower.contains('pinot') || regionLower.contains('bourgogne')) {
        tannin = 4.5;
        freshFruit = 7.8;
        acidity = 6.8;
        minerality = 6.5;
      } else if (grapesLower.contains('cabernet') || regionLower.contains('bordeaux')) {
        tannin = 7.8;
        body = 7.8;
        oak = 6.0;
        ripeFruit = 7.0;
      }
    } else if (typeLower.contains('blanc') || typeLower.contains('white')) {
      tannin = 0.5;
      freshFruit = 7.0;
      acidity = 7.0;
      body = 4.5;

      if (regionLower.contains('chablis') || grapesLower.contains('sauvignon')) {
        acidity = 8.5;
        minerality = 8.5;
        freshFruit = 7.5;
      } else if (grapesLower.contains('chardonnay') && (regionLower.contains('beaune') || regionLower.contains('meursault'))) {
        body = 6.8;
        oak = 5.8;
        ripeFruit = 6.0;
        minerality = 7.2;
      }
    } else if (typeLower.contains('champagne') || typeLower.contains('effervescent') || typeLower.contains('sparkling')) {
      tannin = 0.5;
      acidity = 8.5;
      minerality = 8.0;
      freshFruit = 7.2;
      body = 4.0;
    }

    return WineTasteRadarMetrics(
      tannin: tannin,
      body: body,
      oak: oak,
      ripeFruit: ripeFruit,
      spice: spice,
      freshFruit: freshFruit,
      minerality: minerality,
      acidity: acidity,
    );
  }

  static String _generateSommelierRationale(
    Wine wine,
    List<GuestProfile> guests,
    Map<String, double> guestScores,
    List<String> aversionAlerts,
    double consensusScore,
  ) {
    final wineName = wine.name;
    final guestNames = guests.map((g) => g.name).join(', ');

    if (aversionAlerts.isNotEmpty) {
      return '⚠️ Accord délicat pour $guestNames : ${aversionAlerts.first}. À envisager uniquement avec un plat adapté.';
    }

    if (consensusScore >= 85.0) {
      return '✨ Consensus exceptionnel pour $guestNames ! $wineName offre l\'équilibre parfait entre fruit, structure et fraîcheur sans aucune aspérité clivante.';
    } else if (consensusScore >= 70.0) {
      return '👍 Très bel accord rassembleur. L\'élégance de $wineName saura séduire les amateurs de fraîcheur tout en apportant la matière attendue.';
    } else {
      return '⚖️ Vin de compromis pour $guestNames. Une cuvée de caractère qui demandera une ouverture préalable de 30 minutes.';
    }
  }
}
