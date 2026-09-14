import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'taste_profile.dart';

/// 🍷 8 Enological Dimensions for Taste Radar Spider Charts
///
/// Refined orthogonal axes that avoid palate-clone artifacts:
/// 1. tannin: Structure Tannique (Astringency, firmness, grain of tannin)
/// 2. body: Densité & Puissance (Alcohol, weight, concentration)
/// 3. oak: Boisé & Élevage (Cask influence, toast, vanilla, lactones)
/// 4. ripeFruit: Fruit Solaire & Confit (Dark ripe berries, jammy, plum, fig)
/// 5. spice: Épices & Sauvage (Black pepper/rotundone, garrigue, leather, scrubland)
/// 6. freshFruit: Fruit Croquant & Frais (Acidic red berries, citrus, green apple)
/// 7. minerality: Minéralité & Terroir (Salinity, chalk, flint, slate, volcanic stone)
/// 8. acidity: Tension & Vivacité (Direct acidity, salivation, electric freshness)
class WineTasteRadarMetrics {
  final double tannin; // 1. Structure Tannique (0.0 to 10.0)
  final double body; // 2. Densité & Puissance (0.0 to 10.0)
  final double oak; // 3. Boisé & Élevage (0.0 to 10.0)
  final double ripeFruit; // 4. Fruit Solaire & Confit (0.0 to 10.0)
  final double spice; // 5. Épices & Sauvage (0.0 to 10.0)
  final double freshFruit; // 6. Fruit Croquant & Frais (0.0 to 10.0)
  final double minerality; // 7. Minéralité & Terroir (0.0 to 10.0)
  final double acidity; // 8. Tension & Vivacité (0.0 to 10.0)

  const WineTasteRadarMetrics({
    required this.tannin,
    required this.body,
    required this.oak,
    required this.ripeFruit,
    required this.spice,
    required this.freshFruit,
    required this.minerality,
    required this.acidity,
  });

  /// Backwards-compatibility getters for legacy components
  double get fruit => (freshFruit + ripeFruit) / 2;
  double get sweetness => 2.0;

  /// Default balanced profile
  static const balanced = WineTasteRadarMetrics(
    tannin: 5.0,
    body: 5.5,
    oak: 4.0,
    ripeFruit: 5.5,
    spice: 4.5,
    freshFruit: 6.0,
    minerality: 5.5,
    acidity: 6.0,
  );

  List<double> toList() => [
        tannin,
        body,
        oak,
        ripeFruit,
        spice,
        freshFruit,
        minerality,
        acidity,
      ];

  static List<String> get axisLabels => localizedAxisLabels('fr');

  /// 🌐 Multilingual 8-Axis Labels for Radar / Spider Charts across 13 locales
  static List<String> localizedAxisLabels([dynamic lang]) {
    final code = _extractLangCode(lang);
    switch (code) {
      case 'en':
        return const [
          'Tannins\n& Grip',
          'Body\n& Power',
          'Oak\n& Aging',
          'Ripe Fruit\n& Richness',
          'Spice\n& Character',
          'Fresh Fruit\n& Crisp',
          'Minerality\n& Terroir',
          'Tension\n& Acidity',
        ];
      case 'es':
        return const [
          'Estructura\n& Taninos',
          'Cuerpo\n& Potencia',
          'Roble\n& Crianza',
          'Fruta Madura\n& Confitada',
          'Especias\n& Carácter',
          'Fruta Fresca\n& Viva',
          'Mineralidad\n& Terruño',
          'Tensión\n& Acidez',
        ];
      case 'ca':
        return const [
          'Estructura\n& Tanins',
          'Cos\n& Potència',
          'Roure\n& Criança',
          'Fruita Madura\n& Confitada',
          'Espècies\n& Caràcter',
          'Fruita Fresca\n& Cruixent',
          'Mineralitat\n& Terrer',
          'Tensió\n& Acidesa',
        ];
      case 'la':
        return const [
          'Tannina\n& Firmitas',
          'Robur\n& Corpus',
          'Robur\n& Vetustas',
          'Fructus Mat.\n& Conditus',
          'Aromata\n& Robur',
          'Fructus Rec.\n& Crispans',
          'Mineralitas\n& Terroir',
          'Novitas\n& Aciditas',
        ];
      case 'it':
        return const [
          'Struttura\n& Tannini',
          'Corpo\n& Struttura',
          'Legno\n& Affinamento',
          'Frutto Maturo\n& Denso',
          'Spezie\n& Carattere',
          'Frutto Fresco\n& Fragrante',
          'Mineralità\n& Terroir',
          'Tensione\n& Acidità',
        ];
      case 'de':
        return const [
          'Tannin\n& Struktur',
          'Körper\n& Kraft',
          'Holz\n& Ausbau',
          'Reife Frucht\n& Konfitüre',
          'Würze\n& Würzigkeit',
          'Frische Frucht\n& Knackig',
          'Mineralität\n& Terroir',
          'Spannung\n& Frische',
        ];
      case 'nl':
        return const [
          'Tannines\n& Grip',
          'Body\n& Kracht',
          'Hout\n& Rijping',
          'Rijp Fruit\n& Rijkdom',
          'Kruidigheid\n& Karakter',
          'Vers Fruit\n& Frisheid',
          'Mineraliteit\n& Terroir',
          'Spanning\n& Zuren',
        ];
      case 'pt':
        return const [
          'Estrutura\n& Taninos',
          'Corpo\n& Potência',
          'Carvalho\n& Estágio',
          'Fruta Madura\n& Compota',
          'Especiarias\n& Raça',
          'Fruta Fresca\n& Crocante',
          'Mineralidade\n& Terroir',
          'Tensão\n& Acidez',
        ];
      case 'ja':
        return const [
          '渋み\n& 骨格',
          'ボディ\n& コク',
          '樽熟成\n& 深み',
          '熟した果実\n& 凝縮感',
          'スパイス\n& 個性',
          'フレッシュ\n& 果実味',
          'ミネラル\n& 風土',
          'キレ\n& 酸味',
        ];
      case 'ko':
        return const [
          '타닌\n& 구조감',
          '바디감\n& 힘',
          '오크\n& 숙성',
          '익은 과실\n& 농밀함',
          '스파이스\n& 야생미',
          '신선한 과실\n& 상큼함',
          '미네랄\n& 테루아',
          '텐션\n& 산도',
        ];
      case 'zh':
        return const [
          '单宁\n与骨架',
          '酒体\n与浓郁',
          '橡木\n与陈酿',
          '成熟果香\n与浓郁',
          '香料\n与风味',
          '鲜果\n与爽脆',
          '矿物感\n与风土',
          '张力\n与酸度',
        ];
      case 'sv':
        return const [
          'Tanniner\n& Grepp',
          'Fyllighet\n& Kraft',
          'Ekfat\n& Lagring',
          'Mogen Frukt\n& Koncentration',
          'Kryddor\n& Karaktär',
          'Frisk Frukt\n& Spritsig',
          'Mineralitet\n& Terroir',
          'Spänning\n& Syra',
        ];
      case 'fr':
      default:
        return const [
          'Structure\n& Tanins',
          'Puissance\n& Corps',
          'Boisé\n& Élevage',
          'Fruit Mûr\n& Confit',
          'Épices\n& Sauvage',
          'Fruit Frais\n& Croquant',
          'Minéralité\n& Terroir',
          'Tension\n& Vivacité',
        ];
    }
  }

  static String _extractLangCode(dynamic lang) {
    if (lang == null) return 'en';
    if (lang is String) {
      final s = lang.trim().toLowerCase();
      if (s.contains('-')) return s.split('-').first;
      if (s.contains('_')) return s.split('_').first;
      return s;
    }
    if (lang is Locale) {
      return lang.languageCode.toLowerCase();
    }
    return 'en';
  }

  static List<IconData> get axisIcons => [
        Icons.grain_rounded,
        Icons.fitness_center_rounded,
        Icons.forest_rounded,
        Icons.wb_sunny_rounded,
        Icons.local_fire_department_rounded,
        Icons.eco_rounded,
        Icons.landscape_rounded,
        Icons.bolt_rounded,
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
  /// Computes the 8-axis taste radar metrics for a given [TasteProfile].
  static WineTasteRadarMetrics compute(TasteProfile profile) {
    double tannin = 5.0;
    double body = 5.0;
    double oak = 3.5;
    double ripeFruit = 5.0;
    double spice = 4.0;
    double freshFruit = 5.0;
    double minerality = 5.0;
    double acidity = 5.0;

    // 1. Incorporate explicit averages if set
    if (profile.avgTanninPreference != null) {
      tannin = (profile.avgTanninPreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgBodyPreference != null) {
      body = (profile.avgBodyPreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgOakPreference != null) {
      oak = (profile.avgOakPreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgRipeFruitPreference != null) {
      ripeFruit = (profile.avgRipeFruitPreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgSpicePreference != null) {
      spice = (profile.avgSpicePreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgFreshFruitPreference != null) {
      freshFruit = (profile.avgFreshFruitPreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgMineralityPreference != null) {
      minerality = (profile.avgMineralityPreference! * 10.0).clamp(1.0, 10.0);
    }
    if (profile.avgAcidityPreference != null) {
      acidity = (profile.avgAcidityPreference! * 10.0).clamp(1.0, 10.0);
    }

    // 2. Favorite types influence
    for (final t in profile.favoriteTypes) {
      final low = t.toLowerCase();
      if (low.contains('rouge') || low.contains('red')) {
        tannin += 1.2;
        body += 1.0;
        ripeFruit += 0.8;
        spice += 0.6;
      }
      if (low.contains('blanc') || low.contains('white')) {
        acidity += 1.2;
        minerality += 1.0;
        freshFruit += 0.8;
        tannin -= 1.0;
      }
      if (low.contains('champagne') || low.contains('efferv') || low.contains('sparkling') || low.contains('crémant')) {
        acidity += 1.6;
        minerality += 1.4;
        freshFruit += 0.8;
        body -= 0.8;
        tannin -= 1.5;
      }
      if (low.contains('rosé') || low.contains('rose')) {
        freshFruit += 1.2;
        acidity += 0.8;
        ripeFruit += 0.4;
        tannin -= 0.8;
      }
      if (low.contains('liquor') || low.contains('moell') || low.contains('sauterne') || low.contains('dessert')) {
        ripeFruit += 2.5;
        body += 1.2;
      }
    }

    // 3. Favorite regions influence
    for (final r in profile.favoriteRegions) {
      final low = r.toLowerCase();
      if (low.contains('bordeaux') || low.contains('madiran') || low.contains('cahors')) {
        tannin += 1.6;
        body += 1.4;
        oak += 1.2;
        ripeFruit += 0.8;
      }
      if (low.contains('bourgogne') || low.contains('burgundy')) {
        acidity += 1.2;
        minerality += 1.3;
        freshFruit += 1.2;
        oak += 0.4;
      }
      if (low.contains('rhône') || low.contains('rhone') || low.contains('cornas') || low.contains('châteauneuf') || low.contains('hermitage')) {
        spice += 2.0;
        body += 1.3;
        ripeFruit += 1.2;
        tannin += 1.0;
      }
      if (low.contains('loire') || low.contains('alsace') || low.contains('chablis')) {
        acidity += 1.6;
        minerality += 1.6;
        freshFruit += 1.3;
        tannin -= 0.8;
      }
      if (low.contains('jura') || low.contains('savoie')) {
        minerality += 1.8;
        acidity += 1.3;
        spice += 0.8;
      }
      if (low.contains('provence') || low.contains('languedoc') || low.contains('roussillon')) {
        ripeFruit += 1.2;
        spice += 1.0;
        body += 0.8;
      }
      if (low.contains('italie') || low.contains('piémont') || low.contains('toscane') || low.contains('barolo')) {
        tannin += 1.5;
        acidity += 1.3;
        spice += 1.0;
      }
    }

    // 4. Favorite grapes influence
    for (final g in profile.favoriteGrapes) {
      final low = g.toLowerCase();
      if (low.contains('syrah') || low.contains('shiraz')) {
        spice += 2.2;
        ripeFruit += 1.3;
        tannin += 1.0;
        body += 1.0;
      }
      if (low.contains('cabernet') || low.contains('mourvèdre') || low.contains('malbec') || low.contains('nebbiolo')) {
        tannin += 1.8;
        body += 1.4;
        oak += 0.9;
        ripeFruit += 0.8;
      }
      if (low.contains('pinot noir') || low.contains('gamay')) {
        freshFruit += 1.8;
        acidity += 1.2;
        minerality += 0.8;
        tannin -= 0.6;
      }
      if (low.contains('chardonnay')) {
        minerality += 0.9;
        oak += 0.8;
        body += 0.7;
      }
      if (low.contains('sauvignon') || low.contains('riesling') || low.contains('chenin')) {
        acidity += 1.8;
        minerality += 1.5;
        freshFruit += 1.4;
        tannin -= 1.0;
      }
      if (low.contains('grenache') || low.contains('merlot') || low.contains('viognier')) {
        ripeFruit += 1.5;
        body += 0.8;
        spice += 0.5;
      }
    }

    // 5. Wishlist grapes (+4.5 intent weight)
    profile.wishlistGrapes.forEach((grape, weight) {
      final low = grape.toLowerCase();
      final factor = math.min(weight * 0.45, 1.8);
      if (low.contains('syrah') || low.contains('shiraz')) {
        spice += factor * 1.5;
        tannin += factor * 0.8;
      } else if (low.contains('cabernet') || low.contains('nebbiolo')) {
        tannin += factor * 1.5;
        body += factor * 1.2;
      } else if (low.contains('pinot') || low.contains('gamay')) {
        freshFruit += factor * 1.5;
        acidity += factor * 1.0;
      } else if (low.contains('sauvignon') || low.contains('riesling') || low.contains('chenin')) {
        acidity += factor * 1.5;
        minerality += factor * 1.3;
      }
    });

    // 6. Cellar inventory grapes (+5.0 multi-bottle intent weight)
    profile.cellarGrapes.forEach((grape, count) {
      final low = grape.toLowerCase();
      final factor = math.min(count * 0.5, 2.2);
      if (low.contains('syrah') || low.contains('shiraz')) {
        spice += factor * 1.4;
        body += factor * 1.0;
      } else if (low.contains('cabernet') || low.contains('bordeaux')) {
        tannin += factor * 1.4;
        oak += factor * 1.0;
      } else if (low.contains('chardonnay') || low.contains('bourgogne')) {
        minerality += factor * 1.2;
        oak += factor * 0.8;
      } else if (low.contains('riesling') || low.contains('chenin') || low.contains('chablis')) {
        minerality += factor * 1.5;
        acidity += factor * 1.3;
      }
    });

    // 7. Disliked characteristics (penalties)
    for (final d in profile.dislikedCharacteristics) {
      final low = d.toLowerCase();
      if (low.contains('boisé') || low.contains('chêne') || low.contains('bois') || low.contains('vanille')) {
        oak = math.max(1.0, oak - 3.0);
      }
      if (low.contains('acide') || low.contains('vert') || low.contains('vif')) {
        acidity = math.max(1.0, acidity - 3.0);
      }
      if (low.contains('tann') || low.contains('astringent') || low.contains('lourd')) {
        tannin = math.max(1.0, tannin - 3.0);
        body = math.max(1.0, body - 1.5);
      }
      if (low.contains('puissant') || low.contains('alcool') || low.contains('chaud')) {
        body = math.max(1.0, body - 3.0);
      }
      if (low.contains('minéral') || low.contains('caillou')) {
        minerality = math.max(1.0, minerality - 2.5);
      }
      if (low.contains('sucré') || low.contains('sucre') || low.contains('doux')) {
        ripeFruit = math.max(1.0, ripeFruit - 2.0);
      }
    }

    // 8. Liked traits bonus
    profile.likedTraits.forEach((trait, count) {
      final low = trait.toLowerCase();
      final weight = math.min(count * 0.4, 2.0);
      if (low.contains('tanin') || low.contains('structur') || low.contains('charpenté')) tannin += weight;
      if (low.contains('puissant') || low.contains('corps') || low.contains('dense')) body += weight;
      if (low.contains('boisé') || low.contains('vanille') || low.contains('fût') || low.contains('chêne')) oak += weight;
      if (low.contains('mûr') || low.contains('confit') || low.contains('solaire') || low.contains('cassis')) ripeFruit += weight;
      if (low.contains('épicé') || low.contains('poivre') || low.contains('garrigue') || low.contains('sauvage')) spice += weight;
      if (low.contains('frais') || low.contains('croquant') || low.contains('acidulé') || low.contains('fruit')) freshFruit += weight;
      if (low.contains('minéral') || low.contains('salin') || low.contains('silex') || low.contains('craie')) minerality += weight;
      if (low.contains('vif') || low.contains('tendu') || low.contains('salivant') || low.contains('fraîcheur')) acidity += weight;
    });

    return WineTasteRadarMetrics(
      tannin: tannin.clamp(1.0, 10.0),
      body: body.clamp(1.0, 10.0),
      oak: oak.clamp(1.0, 10.0),
      ripeFruit: ripeFruit.clamp(1.0, 10.0),
      spice: spice.clamp(1.0, 10.0),
      freshFruit: freshFruit.clamp(1.0, 10.0),
      minerality: minerality.clamp(1.0, 10.0),
      acidity: acidity.clamp(1.0, 10.0),
    );
  }

  /// Calculates the taste affinity score and advice between two taste profiles.
  static TasteAffinityResult compare(TasteProfile p1, TasteProfile p2, [dynamic lang]) {
    final code = WineTasteRadarMetrics._extractLangCode(lang);
    final m1 = compute(p1);
    final m2 = compute(p2);

    final l1 = m1.toList();
    final l2 = m2.toList();

    // Euclidean distance normalized across 8 orthogonal dimensions
    double sumDistSq = 0;
    for (int i = 0; i < l1.length; i++) {
      sumDistSq += math.pow(l1[i] - l2[i], 2);
    }
    final dist = math.sqrt(sumDistSq);
    final maxDist = math.sqrt(8 * math.pow(9.0, 2)); // ~25.45
    final affinityPct = ((1.0 - (dist / maxDist)) * 100.0).clamp(30.0, 99.0);

    // Identify shared top axes and divergences
    final commonGrounds = <String>[];
    final divergences = <String>[];

    final axes = WineTasteRadarMetrics.localizedAxisLabels(code);
    for (int i = 0; i < l1.length; i++) {
      final diff = (l1[i] - l2[i]).abs();
      final cleanName = axes[i].replaceAll('\n', ' ');
      if (diff <= 1.8 && (l1[i] >= 6.0 || l2[i] >= 6.0)) {
        commonGrounds.add(cleanName);
      } else if (diff >= 3.0) {
        if (code == 'es') {
          if (l1[i] > l2[i]) {
            divergences.add('${p1.name} aprecia más "$cleanName" que ${p2.name}');
          } else {
            divergences.add('${p2.name} aprecia más "$cleanName" que ${p1.name}');
          }
        } else if (code == 'ca') {
          if (l1[i] > l2[i]) {
            divergences.add('${p1.name} aprecia més "$cleanName" que ${p2.name}');
          } else {
            divergences.add('${p2.name} aprecia més "$cleanName" que ${p1.name}');
          }
        } else if (code == 'la') {
          if (l1[i] > l2[i]) {
            divergences.add('${p1.name} magis amat "$cleanName" quam ${p2.name}');
          } else {
            divergences.add('${p2.name} magis amat "$cleanName" quam ${p1.name}');
          }
        } else if (code == 'en') {
          if (l1[i] > l2[i]) {
            divergences.add('${p1.name} appreciates "$cleanName" more than ${p2.name}');
          } else {
            divergences.add('${p2.name} appreciates "$cleanName" more than ${p1.name}');
          }
        } else {
          if (l1[i] > l2[i]) {
            divergences.add('${p1.name} apprécie davantage "$cleanName" que ${p2.name}');
          } else {
            divergences.add('${p2.name} apprécie davantage "$cleanName" que ${p1.name}');
          }
        }
      }
    }

    String commonSummary;
    if (code == 'es') {
      commonSummary = commonGrounds.isNotEmpty
          ? 'Compartís una gran afinidad por: ${commonGrounds.join(', ')}.'
          : 'Vuestros paladares son complementarios en todos los estilos de vino.';
    } else if (code == 'ca') {
      commonSummary = commonGrounds.isNotEmpty
          ? 'Compartiu una gran afinitat per: ${commonGrounds.join(', ')}.'
          : 'Els vostres paladars són complementaris en tots els estils de vi.';
    } else if (code == 'la') {
      commonSummary = commonGrounds.isNotEmpty
          ? 'Magnam concordiam habetis in: ${commonGrounds.join(', ')}.'
          : 'Palata vestra congruunt in omnibus generibus vini.';
    } else if (code == 'en') {
      commonSummary = commonGrounds.isNotEmpty
          ? 'You share a great affinity for: ${commonGrounds.join(', ')}.'
          : 'Your palates are complementary across all wine styles.';
    } else {
      commonSummary = commonGrounds.isNotEmpty
          ? 'Vous partagez une belle affinité pour : ${commonGrounds.join(', ')}.'
          : 'Vos palais sont complémentaires sur l\'ensemble des styles de vin.';
    }

    String divSummary;
    if (code == 'es') {
      divSummary = divergences.isNotEmpty
          ? divergences.join('. ')
          : '¡Muy pocas divergencias entre vuestros dos perfiles!';
    } else if (code == 'ca') {
      divSummary = divergences.isNotEmpty
          ? divergences.join('. ')
          : 'Molt poques divergències notables entre els vostres dos perfils!';
    } else if (code == 'la') {
      divSummary = divergences.isNotEmpty
          ? divergences.join('. ')
          : 'Paucae differentiae inter habitus vestros!';
    } else if (code == 'en') {
      divSummary = divergences.isNotEmpty
          ? divergences.join('. ')
          : 'Very few notable differences between your two profiles!';
    } else {
      divSummary = divergences.isNotEmpty
          ? divergences.join('. ')
          : 'Très peu de divergences notables entre vos deux profils !';
    }

    // Sommelier recommendation tailored for both
    final avgTannin = (m1.tannin + m2.tannin) / 2;
    final avgAcid = (m1.acidity + m2.acidity) / 2;
    final avgSpice = (m1.spice + m2.spice) / 2;
    final avgMinerality = (m1.minerality + m2.minerality) / 2;

    String recommendation;
    if (code == 'es') {
      if (avgSpice >= 7.0 && avgTannin >= 6.5) {
        recommendation = '🍷 Un tinto especiado y con carácter: Valle del Ródano Norte (Cornas, Saint-Joseph) o Syrah viejo.';
      } else if (avgTannin >= 7.0) {
        recommendation = '🍷 Un tinto estructurado pero aterciopelado: Burdeos Rive Droite o Ribera del Duero elegante.';
      } else if (avgAcid >= 7.0 && avgMinerality >= 6.5) {
        recommendation = '🥂 Un blanco salino y fresco: Chablis Premier Cru, Sancerre o Champagne Extra-Brut.';
      } else {
        recommendation = '✨ Un vino equilibrado y armónico: Borgoña Pinot Noir sedoso o Chenin del Loira.';
      }
    } else if (code == 'ca') {
      if (avgSpice >= 7.0 && avgTannin >= 6.5) {
        recommendation = '🍷 Un vi negre especiat i de caràcter: Vall del Roina Nord (Cornas, Saint-Joseph) o Priorat mineral.';
      } else if (avgTannin >= 7.0) {
        recommendation = '🍷 Un vi negre estructurat però vellutat: Bordeus suau o Montsant noble.';
      } else if (avgAcid >= 7.0 && avgMinerality >= 6.5) {
        recommendation = '🥂 Un vi blanc fresc i salí: Chablis Premier Cru, Sancerre o Corpinnat Brut Nature.';
      } else {
        recommendation = '✨ Un vi equilibrat i consensuat: Borgonya Pinot Noir sedós o Chenin del Loira.';
      }
    } else if (code == 'la') {
      if (avgSpice >= 7.0) {
        recommendation = '🍷 Vinum rubrum conditum ac validum: Rhodanus Septentrionalis vel Cornas nobile.';
      } else if (avgAcid >= 7.0) {
        recommendation = '🥂 Vinum album recens ac salinum: Chablis Premier Cru vel Campania Extra-Brut.';
      } else {
        recommendation = '✨ Vinum aequatum et iucundum: Burgundia Pinot Noir vel Ligeris Chenin.';
      }
    } else if (code == 'en') {
      if (avgSpice >= 7.0 && avgTannin >= 6.5) {
        recommendation = '🍷 A spicy, terroir-driven red: Northern Rhône (Cornas, Côte-Rôtie) or peppery cool-climate Syrah.';
      } else if (avgTannin >= 7.0) {
        recommendation = '🍷 A structured yet velvety red wine: Right Bank Bordeaux or fine Tuscan Sangiovese.';
      } else if (avgAcid >= 7.0 && avgMinerality >= 6.5) {
        recommendation = '🥂 A crisp and mineral white: Chablis Premier Cru, Sancerre, or Champagne Extra-Brut.';
      } else {
        recommendation = '✨ A balanced and versatile wine: delicate Burgundy Pinot Noir or crisp Loire Chenin Blanc.';
      }
    } else {
      if (avgSpice >= 7.0 && avgTannin >= 6.5) {
        recommendation = '🍷 Un vin rouge épicé et racé : Vallée du Rhône Nord (Cornas, Côte-Rôtie) ou une belle Syrah sauvage.';
      } else if (avgTannin >= 7.0) {
        recommendation = '🍷 Un vin rouge structuré mais velouté : Grand Bordeaux rive droite souple ou Madiran patiné.';
      } else if (avgAcid >= 7.0 && avgMinerality >= 6.5) {
        recommendation = '🥂 Un vin blanc vif et salin : Chablis Premier Cru, Sancerre silex ou un Champagne Extra-Brut.';
      } else {
        recommendation = '✨ Un vin équilibré et consensuel : un Bourgogne rouge délicat ou un Chenin minéral de la Loire.';
      }
    }

    return TasteAffinityResult(
      affinityPercentage: affinityPct,
      commonGroundsSummary: commonSummary,
      divergencesSummary: divSummary,
      idealWineRecommendation: recommendation,
    );
  }
}
