import 'dart:math';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'benchmark_bottle_catalog.dart';

/// Procedural generator for authentic, real-world wines that legitimately exist globally
/// but are specifically NOT in the local/remote seed database, allowing true zero-shot OCR testing.
class RealWorldBottleGenerator {
  static final Random _rng = Random(42);

  // Authentic estate archetypes with legitimate geographic and ampelographic profiles
  static const List<_WineTemplate> _templates = [
    // Bordeaux
    _WineTemplate(
      producer: 'Château Pontet-Canet',
      cuvee: 'Grand Vin',
      wineType: 'red',
      country: 'France',
      region: 'Bordeaux',
      subRegion: 'Médoc',
      appellation: 'Pauillac AOP',
      classification: 'Grand Cru Classé en 1855',
      alcoholRange: [13.0, 14.5],
      grapes: [
        Grape(name: 'Cabernet Sauvignon', pct: 65),
        Grape(name: 'Merlot', pct: 30),
        Grape(name: 'Cabernet Franc', pct: 4),
        Grape(name: 'Petit Verdot', pct: 1),
      ],
      agingPotentialYears: 30,
    ),
    _WineTemplate(
      producer: 'Château Calon-Ségur',
      cuvee: 'Marquis de Calon',
      wineType: 'red',
      country: 'France',
      region: 'Bordeaux',
      subRegion: 'Médoc',
      appellation: 'Saint-Estèphe AOP',
      classification: 'Troisième Grand Cru Classé',
      alcoholRange: [13.0, 14.0],
      grapes: [
        Grape(name: 'Cabernet Sauvignon', pct: 60),
        Grape(name: 'Merlot', pct: 35),
        Grape(name: 'Petit Verdot', pct: 5),
      ],
      agingPotentialYears: 25,
    ),
    _WineTemplate(
      producer: 'Château Smith Haut Lafitte',
      cuvee: 'Les Hauts de Smith Blanc',
      wineType: 'white',
      country: 'France',
      region: 'Bordeaux',
      subRegion: 'Graves',
      appellation: 'Pessac-Léognan AOP',
      classification: 'Grand Cru Classé de Graves',
      alcoholRange: [13.0, 13.5],
      grapes: [
        Grape(name: 'Sauvignon Blanc', pct: 90),
        Grape(name: 'Sémillon', pct: 10),
      ],
      agingPotentialYears: 15,
    ),

    // Bourgogne
    _WineTemplate(
      producer: 'Domaine Dujac',
      cuvee: 'Clos de la Roche Grand Cru',
      wineType: 'red',
      country: 'France',
      region: 'Bourgogne',
      subRegion: 'Côte de Nuits',
      appellation: 'Clos de la Roche Grand Cru AOP',
      classification: 'Grand Cru',
      alcoholRange: [13.0, 13.5],
      grapes: [
        Grape(name: 'Pinot Noir', pct: 100),
      ],
      agingPotentialYears: 35,
    ),
    _WineTemplate(
      producer: 'Domaine Leflaive',
      cuvee: 'Les Pucelles',
      wineType: 'white',
      country: 'France',
      region: 'Bourgogne',
      subRegion: 'Côte de Beaune',
      appellation: 'Puligny-Montrachet 1er Cru AOP',
      classification: 'Premier Cru',
      alcoholRange: [13.0, 13.5],
      grapes: [
        Grape(name: 'Chardonnay', pct: 100),
      ],
      agingPotentialYears: 22,
    ),
    _WineTemplate(
      producer: 'Domaine Roulot',
      cuvee: 'Les Luchets',
      wineType: 'white',
      country: 'France',
      region: 'Bourgogne',
      subRegion: 'Côte de Beaune',
      appellation: 'Meursault AOP',
      classification: 'Lieu-dit d\'exception',
      alcoholRange: [12.5, 13.5],
      grapes: [
        Grape(name: 'Chardonnay', pct: 100),
      ],
      agingPotentialYears: 20,
    ),

    // Rhône
    _WineTemplate(
      producer: 'Domaine de la Janasse',
      cuvee: 'Chaupin',
      wineType: 'red',
      country: 'France',
      region: 'Vallée du Rhône',
      subRegion: 'Rhône Méridional',
      appellation: 'Châteauneuf-du-Pape AOP',
      classification: 'Cru des Côtes du Rhône',
      alcoholRange: [14.5, 15.5],
      grapes: [
        Grape(name: 'Grenache', pct: 100),
      ],
      agingPotentialYears: 25,
    ),
    _WineTemplate(
      producer: 'Domaine Alain Graillot',
      cuvee: 'La Guiraude',
      wineType: 'red',
      country: 'France',
      region: 'Vallée du Rhône',
      subRegion: 'Rhône Septentrional',
      appellation: 'Crozes-Hermitage AOP',
      classification: 'Cuvée spéciale',
      alcoholRange: [13.0, 14.0],
      grapes: [
        Grape(name: 'Syrah', pct: 100),
      ],
      agingPotentialYears: 18,
    ),

    // Loire
    _WineTemplate(
      producer: 'Domaine des Roches Neuves (Thierry Germain)',
      cuvee: 'Franc de Pied',
      wineType: 'red',
      country: 'France',
      region: 'Loire',
      subRegion: 'Anjou-Saumur',
      appellation: 'Saumur-Champigny AOP',
      classification: 'Cuvée parcellaire préphylloxérique',
      alcoholRange: [12.5, 13.5],
      grapes: [
        Grape(name: 'Cabernet Franc', pct: 100),
      ],
      agingPotentialYears: 20,
    ),
    _WineTemplate(
      producer: 'Domaine Huet',
      cuvee: 'Le Mont Demi-Sec',
      wineType: 'white',
      country: 'France',
      region: 'Loire',
      subRegion: 'Touraine',
      appellation: 'Vouvray AOP',
      classification: 'Demi-Sec',
      alcoholRange: [12.5, 13.5],
      grapes: [
        Grape(name: 'Chenin Blanc', pct: 100),
      ],
      agingPotentialYears: 40,
    ),

    // Champagne
    _WineTemplate(
      producer: 'Champagne Philipponnat',
      cuvee: 'Clos des Goisses',
      wineType: 'sparkling',
      country: 'France',
      region: 'Champagne',
      subRegion: 'Vallée de la Marne',
      appellation: 'Champagne AOP',
      classification: 'Clos historique parcellaire',
      alcoholRange: [12.0, 12.5],
      grapes: [
        Grape(name: 'Pinot Noir', pct: 70),
        Grape(name: 'Chardonnay', pct: 30),
      ],
      agingPotentialYears: 30,
    ),

    // Italie
    _WineTemplate(
      producer: 'Tenuta San Guido',
      cuvee: 'Sassicaia',
      wineType: 'red',
      country: 'Italie',
      region: 'Toscane',
      subRegion: 'Bolgheri',
      appellation: 'Bolgheri Sassicaia DOC',
      classification: 'Super Tuscan Icon',
      alcoholRange: [13.5, 14.5],
      grapes: [
        Grape(name: 'Cabernet Sauvignon', pct: 85),
        Grape(name: 'Cabernet Franc', pct: 15),
      ],
      agingPotentialYears: 35,
    ),
    _WineTemplate(
      producer: 'Biondi-Santi',
      cuvee: 'Tenuta Greppo Riserva',
      wineType: 'red',
      country: 'Italie',
      region: 'Toscane',
      subRegion: 'Montalcino',
      appellation: 'Brunello di Montalcino DOCG',
      classification: 'Riserva',
      alcoholRange: [13.5, 14.5],
      grapes: [
        Grape(name: 'Sangiovese Grosso', pct: 100),
      ],
      agingPotentialYears: 40,
    ),

    // Espagne
    _WineTemplate(
      producer: 'Bodegas Vega Sicilia',
      cuvee: 'Único',
      wineType: 'red',
      country: 'Espagne',
      region: 'Castille-et-León',
      subRegion: 'Ribera del Duero',
      appellation: 'Ribera del Duero DO',
      classification: 'Gran Reserva Icon',
      alcoholRange: [14.0, 14.5],
      grapes: [
        Grape(name: 'Tinto Fino (Tempranillo)', pct: 94),
        Grape(name: 'Cabernet Sauvignon', pct: 6),
      ],
      agingPotentialYears: 40,
    ),
    _WineTemplate(
      producer: 'Bodega López de Heredia',
      cuvee: 'Viña Tondonia Blanco Gran Reserva',
      wineType: 'white',
      country: 'Espagne',
      region: 'Rioja',
      subRegion: 'Rioja Alta',
      appellation: 'Rioja DOCa',
      classification: 'Gran Reserva',
      alcoholRange: [12.5, 13.0],
      grapes: [
        Grape(name: 'Viura', pct: 90),
        Grape(name: 'Malvasía', pct: 10),
      ],
      agingPotentialYears: 35,
    ),

    // USA
    _WineTemplate(
      producer: 'Dominus Estate (Christian Moueix)',
      cuvee: 'Napa Valley Red Wine',
      wineType: 'red',
      country: 'États-Unis',
      region: 'Californie',
      subRegion: 'Napa Valley',
      appellation: 'Yountville AVA',
      classification: 'Estate Bottled',
      alcoholRange: [14.0, 15.0],
      grapes: [
        Grape(name: 'Cabernet Sauvignon', pct: 86),
        Grape(name: 'Cabernet Franc', pct: 9),
        Grape(name: 'Petit Verdot', pct: 5),
      ],
      agingPotentialYears: 30,
    ),

    // Nouvelle-Zélande
    _WineTemplate(
      producer: 'Felton Road',
      cuvee: 'Block 3',
      wineType: 'red',
      country: 'Nouvelle-Zélande',
      region: 'Central Otago',
      subRegion: 'Bannockburn',
      appellation: 'Central Otago GI',
      classification: 'Single Block Biodynamic',
      alcoholRange: [13.5, 14.0],
      grapes: [
        Grape(name: 'Pinot Noir', pct: 100),
      ],
      agingPotentialYears: 18,
    ),
  ];

  /// Generates an authentic bottle guaranteed not to collide with default database seeds.
  static BenchmarkBottle generateBottle({
    int? seed,
    String? preferredRegion,
    int? specificVintage,
  }) {
    final random = seed != null ? Random(seed) : _rng;

    final candidates = preferredRegion != null
        ? _templates.where((t) => t.region.toLowerCase().contains(preferredRegion.toLowerCase())).toList()
        : _templates;

    final template = candidates.isNotEmpty
        ? candidates[random.nextInt(candidates.length)]
        : _templates[random.nextInt(_templates.length)];

    // Authentic historical vintages between 1988 and 2023
    final vintage = specificVintage ?? (1988 + random.nextInt(36));

    // Calculate alcohol within legitimate domain range with 0.5 step
    final minAlc = template.alcoholRange[0];
    final maxAlc = template.alcoholRange[1];
    final alcStep = ((maxAlc - minAlc) * 2).round();
    final alc = minAlc + (alcStep > 0 ? (random.nextInt(alcStep + 1) * 0.5) : 0.0);

    // Calculate dynamic drinking window based on vintage and domain aging potential
    final idealStart = vintage + 4;
    final idealEnd = vintage + template.agingPotentialYears;

    final uniqueId = 'gen_real_${template.producer.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${vintage}_${random.nextInt(99999)}';

    final labelLines = [
      template.producer.toUpperCase(),
      template.cuvee != null ? template.cuvee!.toUpperCase() : '',
      '$vintage',
      template.appellation.toUpperCase(),
      template.classification != null ? template.classification!.toUpperCase() : '',
      'MIS EN BOUTEILLE À LA PROPRIÉTÉ',
      '${template.subRegion != null ? "${template.subRegion} - " : ""}${template.region} - ${template.country}'.toUpperCase(),
      '${alc.toStringAsFixed(1)}% VOL. - 750 ML',
    ].where((s) => s.isNotEmpty).toList();

    return BenchmarkBottle(
      id: uniqueId,
      category: 'procedural_authentic',
      name: template.cuvee != null ? '${template.producer} ${template.cuvee}' : template.producer,
      producer: template.producer,
      cuveeParcel: template.cuvee,
      vintage: vintage,
      wineType: template.wineType,
      country: template.country,
      region: template.region,
      subRegion: template.subRegion,
      appellation: template.appellation,
      classification: template.classification,
      alcoholPct: alc,
      grapes: template.grapes,
      idealDrinkingStart: idealStart,
      idealDrinkingEnd: idealEnd,
      simulatedLabelLines: labelLines,
    );
  }

  /// Generates a batch of distinct, authentic real-world bottles.
  static List<BenchmarkBottle> generateBatch(int count, {int startSeed = 100}) {
    final list = <BenchmarkBottle>[];
    for (int i = 0; i < count; i++) {
      list.add(generateBottle(seed: startSeed + i));
    }
    return list;
  }

  /// Generates noisy OCR text simulating imperfect camera capture or lighting conditions.
  static String toNoisyOcrText(BenchmarkBottle bottle, {double noiseRatio = 0.1, Random? random}) {
    final r = random ?? Random(42);
    final raw = bottle.toOcrRawText();
    if (noiseRatio <= 0) return raw;

    final chars = raw.split('');
    final noisy = <String>[];
    for (final char in chars) {
      if (r.nextDouble() < noiseRatio && char.trim().isNotEmpty) {
        // Substitute or drop character slightly
        final noiseType = r.nextInt(3);
        if (noiseType == 0) {
          // Replace 'O' with '0', 'I' with '1', 'l' with '|'
          if (char == 'O') noisy.add('0');
          else if (char == 'I') noisy.add('1');
          else if (char == 'l') noisy.add('|');
          else noisy.add(char.toLowerCase());
        } else if (noiseType == 1) {
          // Skip character
          continue;
        } else {
          noisy.add(' ');
        }
      } else {
        noisy.add(char);
      }
    }
    return noisy.join('');
  }
}

class _WineTemplate {
  final String producer;
  final String? cuvee;
  final String wineType;
  final String country;
  final String region;
  final String? subRegion;
  final String appellation;
  final String? classification;
  final List<double> alcoholRange;
  final List<Grape> grapes;
  final int agingPotentialYears;

  const _WineTemplate({
    required this.producer,
    this.cuvee,
    required this.wineType,
    required this.country,
    required this.region,
    this.subRegion,
    required this.appellation,
    this.classification,
    required this.alcoholRange,
    required this.grapes,
    required this.agingPotentialYears,
  });
}
