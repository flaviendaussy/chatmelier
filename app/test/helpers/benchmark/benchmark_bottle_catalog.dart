import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';

/// Represents a canonical ground-truth bottle used for automated regression testing and OCR accuracy benchmarking.
class BenchmarkBottle {
  final String id;
  final String category;
  final String name;
  final String producer;
  final String? cuveeParcel;
  final int? vintage;
  final String wineType; // 'red', 'white', 'rose', 'sparkling', 'dessert', 'spirit'
  final String country;
  final String region;
  final String? subRegion;
  final String appellation;
  final String? classification;
  final double alcoholPct;
  final List<Grape> grapes;
  final int? idealDrinkingStart;
  final int? idealDrinkingEnd;
  final List<String> simulatedLabelLines;

  const BenchmarkBottle({
    required this.id,
    required this.category,
    required this.name,
    required this.producer,
    this.cuveeParcel,
    this.vintage,
    required this.wineType,
    required this.country,
    required this.region,
    this.subRegion,
    required this.appellation,
    this.classification,
    required this.alcoholPct,
    required this.grapes,
    this.idealDrinkingStart,
    this.idealDrinkingEnd,
    required this.simulatedLabelLines,
  });

  ScanResult toExpectedScanResult() {
    return ScanResult(
      name: name,
      producer: producer,
      cuveeParcel: cuveeParcel,
      vintage: vintage,
      wineType: wineType,
      country: country,
      region: region,
      subRegion: subRegion,
      appellation: appellation,
      classification: classification,
      alcoholPct: alcoholPct,
      grapes: grapes,
      idealDrinkingStart: idealDrinkingStart,
      idealDrinkingEnd: idealDrinkingEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'producer': producer,
      'cuvee_parcel': cuveeParcel,
      'vintage': vintage,
      'wine_type': wineType,
      'country': country,
      'region': region,
      'sub_region': subRegion,
      'appellation': appellation,
      'classification': classification,
      'alcohol_pct': alcoholPct,
      'grapes': grapes.map((g) => {'name': g.name, 'pct': g.pct}).toList(),
      'ideal_drinking_start': idealDrinkingStart,
      'ideal_drinking_end': idealDrinkingEnd,
    };
  }

  String toOcrRawText() => simulatedLabelLines.join('\n');
}

/// Catalog of 13 canonical, diverse, real-world benchmark bottles covering major global terroirs and edge cases.
class BenchmarkBottleCatalog {
  static const List<BenchmarkBottle> bottles = [
    // 1. Bordeaux Premier Grand Cru Classé
    BenchmarkBottle(
      id: 'bt_bordeaux_margaux',
      category: 'bordeaux_blend',
      name: 'Château Margaux',
      producer: 'Château Margaux',
      cuveeParcel: null,
      vintage: 2015,
      wineType: 'red',
      country: 'France',
      region: 'Bordeaux',
      subRegion: 'Médoc',
      appellation: 'Margaux AOP',
      classification: 'Premier Grand Cru Classé (1855)',
      alcoholPct: 13.5,
      grapes: [
        Grape(name: 'Cabernet Sauvignon', pct: 87),
        Grape(name: 'Merlot', pct: 8),
        Grape(name: 'Cabernet Franc', pct: 3),
        Grape(name: 'Petit Verdot', pct: 2),
      ],
      idealDrinkingStart: 2025,
      idealDrinkingEnd: 2060,
      simulatedLabelLines: [
        'CHATEAU MARGAUX',
        'PREMIER GRAND CRU CLASSÉ',
        '2015',
        'MARGAUX',
        'APPELLATION MARGAUX CONTRÔLÉE',
        'SCA DU CHATEAU MARGAUX PROPRIÉTAIRE',
        'MIS EN BOUTEILLE AU CHATEAU',
        '750ml - 13.5% vol - PRODUIT DE FRANCE',
      ],
    ),

    // 2. Bourgogne Premier Cru with Single Parcel/Climat
    BenchmarkBottle(
      id: 'bt_bourgogne_clos_st_jacques',
      category: 'burgundy_parcel',
      name: 'Gevrey-Chambertin 1er Cru Clos Saint-Jacques',
      producer: 'Domaine Armand Rousseau',
      cuveeParcel: 'Clos Saint-Jacques',
      vintage: 2018,
      wineType: 'red',
      country: 'France',
      region: 'Bourgogne',
      subRegion: 'Côte de Nuits',
      appellation: 'Gevrey-Chambertin 1er Cru AOP',
      classification: 'Premier Cru',
      alcoholPct: 13.0,
      grapes: [
        Grape(name: 'Pinot Noir', pct: 100),
      ],
      idealDrinkingStart: 2026,
      idealDrinkingEnd: 2048,
      simulatedLabelLines: [
        'DOMAINE ARMAND ROUSSEAU',
        'GEVREY-CHAMBERTIN',
        'CLOS SAINT-JACQUES',
        'PREMIER CRU',
        'APPELLATION GEVREY-CHAMBERTIN 1ER CRU CONTRÔLÉE',
        'RÉCOLTE 2018',
        'DOMAINE ARMAND ROUSSEAU PÈRE & FILS PROPRIÉTAIRE À GEVREY-CHAMBERTIN (CÔTE-D\'OR)',
        '13% vol. - 750 ml - GRAND VIN DE BOURGOGNE',
      ],
    ),

    // 3. Champagne Non-Vintage Prestige (NM, Vintage Null)
    BenchmarkBottle(
      id: 'bt_champagne_krug',
      category: 'champagne_nv',
      name: 'Krug Grande Cuvée 170ème Édition',
      producer: 'Champagne Krug',
      cuveeParcel: '170ème Édition',
      vintage: null,
      wineType: 'sparkling',
      country: 'France',
      region: 'Champagne',
      subRegion: 'Montagne de Reims',
      appellation: 'Champagne AOP',
      classification: 'Brut Prestige',
      alcoholPct: 12.5,
      grapes: [
        Grape(name: 'Pinot Noir', pct: 51),
        Grape(name: 'Chardonnay', pct: 38),
        Grape(name: 'Pinot Meunier', pct: 11),
      ],
      idealDrinkingStart: 2022,
      idealDrinkingEnd: 2038,
      simulatedLabelLines: [
        'KRUG',
        'GRANDE CUVÉE',
        '170ÈME ÉDITION - BRUT',
        'CHAMPAGNE',
        'ÉLABORÉ PAR KRUG À REIMS - FRANCE - NM-225-001',
        '12.5% vol - 75cl - PRODUIT DE FRANCE',
      ],
    ),

    // 4. Rhône Nord (Syrah Mono-Cépage)
    BenchmarkBottle(
      id: 'bt_rhone_chave_hermitage',
      category: 'rhone_syrah',
      name: 'Hermitage Rouge',
      producer: 'Domaine Jean-Louis Chave',
      cuveeParcel: null,
      vintage: 2017,
      wineType: 'red',
      country: 'France',
      region: 'Vallée du Rhône',
      subRegion: 'Rhône Septentrional',
      appellation: 'Hermitage AOP',
      classification: 'Cru des Côtes du Rhône',
      alcoholPct: 14.5,
      grapes: [
        Grape(name: 'Syrah', pct: 100),
      ],
      idealDrinkingStart: 2027,
      idealDrinkingEnd: 2055,
      simulatedLabelLines: [
        'HERMITAGE',
        'APPELLATION HERMITAGE CONTRÔLÉE',
        '2017',
        'DOMAINE JEAN-LOUIS CHAVE',
        'PROPRIÉTAIRE-VITICULTEUR À MAUVES (ARDÈCHE) FRANCE',
        '14.5% alc./vol. - 750 ML',
      ],
    ),

    // 5. Vallée de la Loire (Blanc Minéral Silex)
    BenchmarkBottle(
      id: 'bt_loire_dagueneau_silex',
      category: 'loire_sauvignon',
      name: 'Pouilly-Fumé Silex',
      producer: 'Domaine Didier Dagueneau',
      cuveeParcel: 'Silex',
      vintage: 2020,
      wineType: 'white',
      country: 'France',
      region: 'Loire',
      subRegion: 'Centre-Loire',
      appellation: 'Pouilly-Fumé AOP',
      classification: 'AOC Pouilly-Fumé',
      alcoholPct: 13.5,
      grapes: [
        Grape(name: 'Sauvignon Blanc', pct: 100),
      ],
      idealDrinkingStart: 2024,
      idealDrinkingEnd: 2040,
      simulatedLabelLines: [
        'SILEX',
        'POUILLY-FUMÉ',
        'APPELLATION POUILLY-FUMÉ CONTRÔLÉE',
        '2020',
        'MIS EN BOUTEILLE PAR LOUIS-BENJAMIN ET CHARLOTTE DAGUENEAU',
        'SAINT-ANDELAIN - NIÈVRE - FRANCE',
        '13.5% VOL. 75 CL',
      ],
    ),

    // 6. Alsace Grand Cru (Riesling de Terroir Volcanique)
    BenchmarkBottle(
      id: 'bt_alsace_zind_rangen',
      category: 'alsace_riesling',
      name: 'Riesling Grand Cru Rangen de Thann Clos Saint Urbain',
      producer: 'Domaine Zind-Humbrecht',
      cuveeParcel: 'Clos Saint Urbain',
      vintage: 2019,
      wineType: 'white',
      country: 'France',
      region: 'Alsace',
      subRegion: 'Haut-Rhin',
      appellation: 'Alsace Grand Cru AOP',
      classification: 'Grand Cru',
      alcoholPct: 13.5,
      grapes: [
        Grape(name: 'Riesling', pct: 100),
      ],
      idealDrinkingStart: 2025,
      idealDrinkingEnd: 2050,
      simulatedLabelLines: [
        'DOMAINE ZIND-HUMBRECHT',
        'RIESLING RANGEN DE THANN',
        'CLOS SAINT URBAIN',
        'ALSACE GRAND CRU',
        'APPELLATION ALSACE GRAND CRU CONTRÔLÉE',
        '2019',
        'TURCKHEIM - ALSACE - FRANCE',
        '13.5% vol. 750 ml INDICE 1',
      ],
    ),

    // 7. Italie - Piémont DOCG (Barolo Monfortino)
    BenchmarkBottle(
      id: 'bt_italy_conterno_barolo',
      category: 'italy_barolo',
      name: 'Barolo Riserva Monfortino',
      producer: 'Giacomo Conterno',
      cuveeParcel: 'Monfortino',
      vintage: 2013,
      wineType: 'red',
      country: 'Italie',
      region: 'Piémont',
      subRegion: 'Langhe',
      appellation: 'Barolo DOCG',
      classification: 'Riserva',
      alcoholPct: 14.5,
      grapes: [
        Grape(name: 'Nebbiolo', pct: 100),
      ],
      idealDrinkingStart: 2028,
      idealDrinkingEnd: 2065,
      simulatedLabelLines: [
        'BAROLO',
        'DENOMINAZIONE DI ORIGINE CONTROLLATA E GARANTITA',
        'RISERVA MONFORTINO',
        '2013',
        'IMBOTTIGLIATO DALL\'AZIENDA VITIVINICOLA GIACOMO CONTERNO',
        'MONFORTE D\'ALBA - ITALIA',
        '14.5% vol - 750 ml e - PRODOTTO IN ITALIA',
      ],
    ),

    // 8. Espagne - Rioja Gran Reserva
    BenchmarkBottle(
      id: 'bt_spain_rioja_alta_904',
      category: 'spain_rioja',
      name: 'Gran Reserva 904',
      producer: 'La Rioja Alta, S.A.',
      cuveeParcel: null,
      vintage: 2011,
      wineType: 'red',
      country: 'Espagne',
      region: 'Rioja',
      subRegion: 'Rioja Alta',
      appellation: 'Rioja DOCa',
      classification: 'Gran Reserva',
      alcoholPct: 13.5,
      grapes: [
        Grape(name: 'Tempranillo', pct: 89),
        Grape(name: 'Graciano', pct: 11),
      ],
      idealDrinkingStart: 2022,
      idealDrinkingEnd: 2042,
      simulatedLabelLines: [
        'LA RIOJA ALTA, S.A.',
        'GRAN RESERVA 904',
        'COSECHA 2011',
        'RIOJA',
        'DENOMINACIÓN DE ORIGEN CALIFICADA',
        'EMBOTELLADO EN LA PROPIEDAD POR LA RIOJA ALTA, S.A. - HARO - ESPAÑA',
        '13.5% Vol. 75 cl.',
      ],
    ),

    // 9. USA - Californie (Santa Cruz Mountains)
    BenchmarkBottle(
      id: 'bt_usa_ridge_monte_bello',
      category: 'california_cabernet',
      name: 'Monte Bello',
      producer: 'Ridge Vineyards',
      cuveeParcel: 'Monte Bello',
      vintage: 2016,
      wineType: 'red',
      country: 'États-Unis',
      region: 'Californie',
      subRegion: 'Central Coast',
      appellation: 'Santa Cruz Mountains AVA',
      classification: 'Estate Bottled',
      alcoholPct: 13.8,
      grapes: [
        Grape(name: 'Cabernet Sauvignon', pct: 72),
        Grape(name: 'Merlot', pct: 12),
        Grape(name: 'Petit Verdot', pct: 10),
        Grape(name: 'Cabernet Franc', pct: 6),
      ],
      idealDrinkingStart: 2026,
      idealDrinkingEnd: 2055,
      simulatedLabelLines: [
        'RIDGE 2016 CALIFORNIA MONTE BELLO',
        'SANTA CRUZ MOUNTAINS',
        'ESTATE BOTTLED',
        '72% CABERNET SAUVIGNON, 12% MERLOT, 10% PETIT VERDOT, 6% CABERNET FRANC',
        'PRODUCED AND BOTTLED BY RIDGE VINEYARDS, CUPERTINO, CALIFORNIA',
        'ALCOHOL 13.8% BY VOLUME',
      ],
    ),

    // 10. Argentine - Mendoza Haute Altitude
    BenchmarkBottle(
      id: 'bt_argentina_catena_adrianna',
      category: 'argentina_malbec',
      name: 'Adrianna Vineyard River Stones Malbec',
      producer: 'Catena Zapata',
      cuveeParcel: 'River Stones',
      vintage: 2019,
      wineType: 'red',
      country: 'Argentine',
      region: 'Mendoza',
      subRegion: 'Valle de Uco',
      appellation: 'Gualtallary IG',
      classification: 'Single Vineyard',
      alcoholPct: 14.0,
      grapes: [
        Grape(name: 'Malbec', pct: 100),
      ],
      idealDrinkingStart: 2024,
      idealDrinkingEnd: 2045,
      simulatedLabelLines: [
        'CATENA ZAPATA',
        'ADRIANNA VINEYARD',
        'RIVER STONES - 2019',
        'MALBEC',
        'GUALTALLARY - VALLE DE UCO - MENDOZA',
        'ESTATE BOTTLED BY BODEGA CATENA ZAPATA',
        '14.0% alc/vol - 750ml - WINE OF ARGENTINA',
      ],
    ),

    // 11. Australie - Barossa / South Australia
    BenchmarkBottle(
      id: 'bt_australia_penfolds_grange',
      category: 'australia_shiraz',
      name: 'Grange Bin 95',
      producer: 'Penfolds',
      cuveeParcel: 'Bin 95',
      vintage: 2018,
      wineType: 'red',
      country: 'Australie',
      region: 'Australie-Méridionale',
      subRegion: 'Barossa Valley',
      appellation: 'South Australia GI',
      classification: 'Icon Heritage',
      alcoholPct: 14.5,
      grapes: [
        Grape(name: 'Syrah', pct: 97),
        Grape(name: 'Cabernet Sauvignon', pct: 3),
      ],
      idealDrinkingStart: 2028,
      idealDrinkingEnd: 2060,
      simulatedLabelLines: [
        'Penfolds',
        'GRANGE',
        'BIN 95 - VINTAGE 2018',
        'BOTTLED 2020',
        'SOUTH AUSTRALIA SHIRAZ',
        'PRODUCED BY PENFOLDS WINES, MAGILL ESTATE, SOUTH AUSTRALIA',
        '750ml - 14.5% alc/vol - WINE OF AUSTRALIA',
      ],
    ),

    // 12. Allemagne - Mosel Riesling Prädikatswein (Faible Alcool, Doux)
    BenchmarkBottle(
      id: 'bt_germany_egon_muller_spatlese',
      category: 'germany_spatlese',
      name: 'Scharzhofberger Riesling Spätlese',
      producer: 'Egon Müller - Scharzhof',
      cuveeParcel: 'Scharzhofberger',
      vintage: 2021,
      wineType: 'dessert',
      country: 'Allemagne',
      region: 'Mosel',
      subRegion: 'Saar',
      appellation: 'Mosel Prädikatswein',
      classification: 'Spätlese',
      alcoholPct: 8.5,
      grapes: [
        Grape(name: 'Riesling', pct: 100),
      ],
      idealDrinkingStart: 2026,
      idealDrinkingEnd: 2065,
      simulatedLabelLines: [
        'EGON MÜLLER - SCHARZHOF',
        '2021',
        'Scharzhofberger',
        'Riesling Spätlese',
        'Prädikatswein - Mosel',
        'Gutsabfüllung Egon Müller, Scharzhof, Wiltingen',
        'A.P.Nr. 3 567 142-03-22 - 750 ml - 8.5% vol',
      ],
    ),

    // 13. Spiritueux de Prestige (Cognac Grande Champagne)
    BenchmarkBottle(
      id: 'bt_spirit_delamain_pale_dry',
      category: 'spirit_cognac',
      name: 'Pale & Dry XO',
      producer: 'Delamain',
      cuveeParcel: null,
      vintage: null,
      wineType: 'spirit',
      country: 'France',
      region: 'Cognac',
      subRegion: 'Grande Champagne',
      appellation: 'Cognac AOP',
      classification: 'XO Premier Cru de Cognac',
      alcoholPct: 40.0,
      grapes: [
        Grape(name: 'Ugni Blanc', pct: 100),
      ],
      idealDrinkingStart: 2020,
      idealDrinkingEnd: 2050,
      simulatedLabelLines: [
        'DELAMAIN',
        'PALE & DRY',
        'CENTENAIRE',
        'XO',
        'GRANDE CHAMPAGNE',
        'COGNAC - 1ER CRU DE COGNAC',
        'APPELLATION COGNAC GRANDE CHAMPAGNE CONTRÔLÉE',
        'J. & R. DELAMAIN - JARNAC - FRANCE',
        '40% vol. - 70 cl',
      ],
    ),
  ];

  static BenchmarkBottle getById(String id) {
    return bottles.firstWhere(
      (b) => b.id == id,
      orElse: () => throw ArgumentError('Benchmark bottle with id "$id" not found'),
    );
  }

  static List<BenchmarkBottle> getByCategory(String category) {
    return bottles.where((b) => b.category == category).toList();
  }
}
