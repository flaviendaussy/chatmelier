import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../auth/domain/wine_taste_radar.dart';
import '../domain/wine.dart';
import '../../../shared/utils/langue.dart';

class AgingSnapshot {
  final int additionalYears;
  final int targetYear;
  final WineTasteRadarMetrics simulatedRadar;
  final String phaseName; // 'Jeunesse fougueuse', 'Maturité montante', 'Pleine Apogée', 'Déclin noble'
  final Color robeColor;
  final String robeDescription;
  final String primaryAromas;
  final String tertiaryAromas;
  final String palateTexture;
  final double peakSatisfactionPercent; // 0 to 100%

  const AgingSnapshot({
    required this.additionalYears,
    required this.targetYear,
    required this.simulatedRadar,
    required this.phaseName,
    required this.robeColor,
    required this.robeDescription,
    required this.primaryAromas,
    required this.tertiaryAromas,
    required this.palateTexture,
    required this.peakSatisfactionPercent,
  });
}

class AgingSimulatorEngine {
  /// Simule l'évolution cinétique d'un vin sur un horizon de 0 à 15 ans.
  static AgingSnapshot simulateAging({
    required Wine wine,
    required int additionalYears,
  }) {
    final currentYear = DateTime.now().year;
    final vintage = wine.vintage ?? (currentYear - 3);
    final currentAge = currentYear - vintage;
    final totalAgeAtSim = currentAge + additionalYears;
    final targetYear = currentYear + additionalYears;

    final type = wine.type.toLowerCase();
    // Tout ce qui n'est pas rouge se lit comme un blanc : pas de tanins, pas de cassis.
    // Avant, un Champagne (type « sparkling ») ou un rosé recevaient « tanins vifs et
    // mordants » et « cassis éclatant » (29/09).
    final isRed = type.contains('red') || type.contains('rouge') || type.contains('fortified');
    final isWhite = !isRed;
    final isChampagne = type.contains('champ') || type.contains('efferv') || type.contains('spark');

    // Potentiel de garde estimé (ex: 8 ans pour rouge standard, 20 ans pour Grand Cru Bordeaux)
    int guardPotential = 10;
    final regionLower = wine.region.toLowerCase();
    final nameLower = wine.name.toLowerCase();
    final appLower = (wine.appellation ?? '').toLowerCase();

    if (nameLower.contains('grand cru') || appLower.contains('pauillac') || appLower.contains('margaux') || appLower.contains('barolo') || appLower.contains('hermitage')) {
      guardPotential = 22;
    } else if (nameLower.contains('premier cru') || appLower.contains('saint-julien') || appLower.contains('châteauneuf')) {
      guardPotential = 16;
    } else if (isWhite && (regionLower.contains('alsace') || appLower.contains('chablis') || appLower.contains('meursault'))) {
      guardPotential = 14;
    } else if (isChampagne) {
      guardPotential = 12;
    }

    final peakStart = (guardPotential * 0.45).round();
    final peakEnd = (guardPotential * 0.85).round();

    // 1. Déformation cinétique du radar
    // Tanins : polymérisent et s'arrondissent (baisse de 30% sur 15 ans pour devenir soyeux)
    final tanninDecay = math.exp(-0.04 * additionalYears);
    final simTannin = isWhite ? 0.0 : (7.5 * tanninDecay).clamp(2.0, 10.0);

    // Fruit frais primaire : décline exponentiellement
    final fruitDecay = math.exp(-0.07 * additionalYears);
    final simFreshFruit = (8.0 * fruitDecay).clamp(1.5, 10.0);

    // Fruit mûr / confit : monte puis décline
    final simRipeFruit = (4.0 + 3.5 * math.sin((additionalYears / 15) * math.pi)).clamp(2.0, 8.5);

    // Tertiaire (Sous-bois, cuir, truffe, tabac) : croît de façon logistique
    final simTertiary = (1.5 + (8.0 / (1.0 + math.exp(-0.35 * (additionalYears - 6))))).clamp(1.5, 9.5);

    // Acidité : s'adoucit légèrement
    final simAcidity = (6.5 * math.exp(-0.015 * additionalYears)).clamp(3.5, 8.5);

    // Corps : se fond
    final simBody = (7.0 * math.exp(-0.02 * additionalYears)).clamp(4.0, 9.0);

    final simulatedRadar = WineTasteRadarMetrics(
      tannin: double.parse(simTannin.toStringAsFixed(1)),
      body: double.parse(simBody.toStringAsFixed(1)),
      oak: double.parse((5.0 * math.exp(-0.03 * additionalYears)).toStringAsFixed(1)),
      ripeFruit: double.parse(simRipeFruit.toStringAsFixed(1)),
      spice: double.parse(simTertiary.toStringAsFixed(1)),
      freshFruit: double.parse(simFreshFruit.toStringAsFixed(1)),
      minerality: double.parse((5.5 * math.exp(-0.01 * additionalYears)).toStringAsFixed(1)),
      acidity: double.parse(simAcidity.toStringAsFixed(1)),
    );

    // 2. Détermination de la Phase & Satisfaction
    String phaseName;
    double satisfaction;
    if (totalAgeAtSim < peakStart) {
      phaseName = tr('Jeunesse fougueuse (En développement)', 'Lively youth (still developing)');
      satisfaction = 65.0 + (totalAgeAtSim / peakStart) * 25.0;
    } else if (totalAgeAtSim <= peakEnd) {
      phaseName = tr('Pleine Apogée (Plateau idéal)', 'At its peak (ideal plateau)');
      satisfaction = 95.0 + (5.0 * math.sin(((totalAgeAtSim - peakStart) / (peakEnd - peakStart)) * math.pi));
    } else if (totalAgeAtSim <= guardPotential * 1.3) {
      phaseName = tr('Maturité noble & Tertiaire', 'Noble maturity & tertiary notes');
      satisfaction = 82.0 - ((totalAgeAtSim - peakEnd) / (guardPotential * 0.45)) * 20.0;
    } else {
      phaseName = tr('Déclin oenologique (Passé d\'apogée)', 'Declining (past its peak)');
      satisfaction = 45.0;
    }

    // 3. Robe & Teinte visuelle
    Color robeColor;
    String robeDesc;
    if (isWhite) {
      if (additionalYears <= 2) {
        robeColor = const Color(0xFFE8F5E9); // Or pâle reflets verts
        robeDesc = tr('Or pâle brillant aux reflets argentés', 'Bright pale gold with silver glints');
      } else if (additionalYears <= 7) {
        robeColor = const Color(0xFFFFD54F); // Doré intense
        robeDesc = tr('Or paille lumineux, belle brillance', 'Luminous straw gold, lovely brilliance');
      } else {
        robeColor = const Color(0xFFFFB300); // Ambré / Topaze
        robeDesc = tr('Or cuivré intense aux nuances de topaze', 'Deep coppery gold with topaz hints');
      }
    } else {
      if (additionalYears <= 2) {
        robeColor = const Color(0xFF6B0E23); // Pourpre / Rubis jeune
        robeDesc = tr('Robe pourpre sombre, frange violacée éclatante', 'Dark purple with a bright violet rim');
      } else if (additionalYears <= 7) {
        robeColor = const Color(0xFF8B1E3F); // Rubis noble
        robeDesc = tr('Grenat profond avec un disque rubis chatoyant', 'Deep garnet with a shimmering ruby rim');
      } else {
        robeColor = const Color(0xFF793822); // Tuilé / Acajou
        robeDesc = tr('Teinte tuilée, reflets brique et acajou élégants', 'Brick-tinted, with elegant brick and mahogany glints');
      }
    }

    // 4. Arômes & Texture en bouche
    String primary;
    String tertiary;
    String palate;

    if (additionalYears <= 3) {
      primary = isWhite ? tr('Citron jaune, pomme croquante, pêche de vigne', 'Lemon, crisp apple, vine peach') : tr('Cassis éclatant, cerise noire fraîche, framboise', 'Bright blackcurrant, fresh black cherry, raspberry');
      tertiary = tr('Encore très discret, pointe discrète de vanille', 'Still very discreet, a hint of vanilla');
      palate = isWhite ? tr('Vive, droite, tranchante et désaltérante', 'Lively, straight, sharp and refreshing') : tr('Tanins vifs et mordants, belle tension athlétique', 'Lively, grippy tannins, athletic tension');
    } else if (additionalYears <= 8) {
      primary = isWhite ? tr('Poire beurrée, abricot sec, zestes confits', 'Buttery pear, dried apricot, candied zest') : tr('Cerise noire compotée, coulis de mûre, pruneau', 'Stewed black cherry, blackberry coulis, prune');
      tertiary = isWhite ? tr('Miel d\'acacia, amande grillée, noisette', 'Acacia honey, toasted almond, hazelnut') : tr('Sous-bois naissant, tabac blond, épices douces', 'Early forest floor, blond tobacco, sweet spice');
      palate = isWhite ? tr('Rondeur onctueuse soutenue par une minéralité patinée', 'Luscious roundness held up by mellow minerality') : tr('Tanins soyeux et fondus, velouté de texture superbe', 'Silky, melted tannins, a superb velvety texture');
    } else {
      primary = isWhite ? tr('Coing, pâte de fruits, écorce d\'orange', 'Quince, fruit jellies, orange peel') : tr('Figue sèche, pruneau d\'Agen, cerise à l\'eau-de-vie', 'Dried fig, Agen prune, brandied cherry');
      tertiary = isWhite ? tr('Cire d\'abeille, truffe blanche, pain d\'épices', 'Beeswax, white truffle, gingerbread') : tr('Truffe noire, cuir noble, boîte à cigares, humus', 'Black truffle, fine leather, cigar box, humus');
      palate = isWhite ? tr('Matière patinée, finale longue et saline', 'Mellow texture, a long saline finish') : tr('Toucher de velours absolu, tanins dissous dans l\'alcool', 'Pure velvet, tannins melted into the wine');
    }

    return AgingSnapshot(
      additionalYears: additionalYears,
      targetYear: targetYear,
      simulatedRadar: simulatedRadar,
      phaseName: phaseName,
      robeColor: robeColor,
      robeDescription: robeDesc,
      primaryAromas: primary,
      tertiaryAromas: tertiary,
      palateTexture: palate,
      peakSatisfactionPercent: double.parse(satisfaction.clamp(20.0, 100.0).toStringAsFixed(0)),
    );
  }
}
