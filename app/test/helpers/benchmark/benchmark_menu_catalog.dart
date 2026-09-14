import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:uuid/uuid.dart';

/// Represents a single wine on a ground-truth benchmark menu.
class BenchmarkMenuWine {
  final String name;
  final String producer;
  final int? vintage;
  final String wineType;
  final String appellation;
  final String region;
  final String country;
  final double? bottlePrice;
  final List<MenuWineGlassPrice> glassPrices;
  final bool isGem;
  final String? gemReason;
  final bool isDeal;
  final String? dealReason;

  const BenchmarkMenuWine({
    required this.name,
    required this.producer,
    this.vintage,
    required this.wineType,
    required this.appellation,
    required this.region,
    required this.country,
    this.bottlePrice,
    this.glassPrices = const [],
    this.isGem = false,
    this.gemReason,
    this.isDeal = false,
    this.dealReason,
  });

  MenuWine toMenuWine({String? id}) {
    return MenuWine(
      id: id ?? const Uuid().v4(),
      name: name,
      producer: producer,
      vintage: vintage,
      wineType: wineType,
      appellation: appellation,
      region: region,
      country: country,
      bottlePrice: bottlePrice,
      glassPrices: glassPrices,
      isGem: isGem,
      gemReason: gemReason,
      isDeal: isDeal,
      dealReason: dealReason,
    );
  }
}

/// Represents a canonical restaurant wine menu (carte des vins) for OCR and sommelier reasoning tests.
class BenchmarkMenu {
  final String id;
  final String title;
  final String restaurantName;
  final String category;
  final String rawMenuText;
  final List<BenchmarkMenuWine> expectedWines;

  const BenchmarkMenu({
    required this.id,
    required this.title,
    required this.restaurantName,
    required this.category,
    required this.rawMenuText,
    required this.expectedWines,
  });
}

/// Catalog of 4 diverse, real-world benchmark menus for automated regression testing.
class BenchmarkMenuCatalog {
  static const List<BenchmarkMenu> menus = [
    // 1. Bistrot Moderne Parisien (prix verre 125ml + bouteille, pépites, bonnes affaires)
    BenchmarkMenu(
      id: 'menu_bistrot_parisien',
      title: 'Carte des Vins — Le Bistrot des Tournelles',
      restaurantName: 'Le Bistrot des Tournelles',
      category: 'bistrot',
      rawMenuText: '''
LE BISTROT DES TOURNELLES — CARTE DES VINS

LES BLANCS
Chablis 2022 — Domaine François Raveneau (Verre 12cl: 14€ | Bouteille: 85€)
Pouilly-Fuissé "En Buland" 2021 — Domaine Guffens-Heynen (Bouteille: 78€)
Sancerre "Silex" 2022 — Domaine Vacheron (Verre 12cl: 9€ | Bouteille: 48€)
Côtes du Jura Savagnin "Sous Voile" 2018 — Domaine Macle (Bouteille: 62€)

LES ROUGES
Morgon "Côte du Py" 2021 — Jean Foillard (Verre 12cl: 8€ | Bouteille: 42€)
Crozes-Hermitage "Silène" 2020 — Jean-Louis Chave Sélection (Verre 12cl: 7.50€ | Bouteille: 39€)
Bourgogne Rouge "Cuvée Halin" 2020 — Domaine Sylvain Pataille (Bouteille: 52€)
Saumur-Champigny "Clos Rougeard" 2017 — Clos Rougeard (Bouteille: 210€)
Saint-Joseph "Offerus" 2019 — Domaine J-L Chave (Bouteille: 65€)
Pic Saint-Loup "La Chouette du Chai" 2021 — Mas Bruguière (Verre 12cl: 6.50€ | Bouteille: 34€)
''',
      expectedWines: [
        BenchmarkMenuWine(
          name: 'Chablis',
          producer: 'Domaine François Raveneau',
          vintage: 2022,
          wineType: 'white',
          appellation: 'Chablis',
          region: 'Bourgogne',
          country: 'France',
          bottlePrice: 85.0,
          glassPrices: const [MenuWineGlassPrice(format: '12cl', price: 14.0)],
          isGem: true,
          gemReason: 'Domaine mythique ultra-convoité',
        ),
        BenchmarkMenuWine(
          name: 'Pouilly-Fuissé En Buland',
          producer: 'Domaine Guffens-Heynen',
          vintage: 2021,
          wineType: 'white',
          appellation: 'Pouilly-Fuissé',
          region: 'Bourgogne',
          country: 'France',
          bottlePrice: 78.0,
          isGem: true,
          gemReason: 'Maître incontesté du Mâconnais',
        ),
        BenchmarkMenuWine(
          name: 'Sancerre Silex',
          producer: 'Domaine Vacheron',
          vintage: 2022,
          wineType: 'white',
          appellation: 'Sancerre',
          region: 'Loire',
          country: 'France',
          bottlePrice: 48.0,
          glassPrices: const [MenuWineGlassPrice(format: '12cl', price: 9.0)],
        ),
        BenchmarkMenuWine(
          name: 'Côtes du Jura Savagnin Sous Voile',
          producer: 'Domaine Macle',
          vintage: 2018,
          wineType: 'white',
          appellation: 'Côtes du Jura',
          region: 'Jura',
          country: 'France',
          bottlePrice: 62.0,
          isGem: true,
          gemReason: 'Référence absolue d\'oxydatif jurassien',
        ),
        BenchmarkMenuWine(
          name: 'Morgon Côte du Py',
          producer: 'Jean Foillard',
          vintage: 2021,
          wineType: 'red',
          appellation: 'Morgon',
          region: 'Beaujolais',
          country: 'France',
          bottlePrice: 42.0,
          glassPrices: const [MenuWineGlassPrice(format: '12cl', price: 8.0)],
          isDeal: true,
          dealReason: 'Tarif exceptionnel pour un monument du Beaujolais',
        ),
        BenchmarkMenuWine(
          name: 'Crozes-Hermitage Silène',
          producer: 'Jean-Louis Chave Sélection',
          vintage: 2020,
          wineType: 'red',
          appellation: 'Crozes-Hermitage',
          region: 'Vallée du Rhône',
          country: 'France',
          bottlePrice: 39.0,
          glassPrices: const [MenuWineGlassPrice(format: '12cl', price: 7.5)],
          isDeal: true,
          dealReason: 'Excellent rapport qualité/prix de grande maison',
        ),
        BenchmarkMenuWine(
          name: 'Bourgogne Rouge Cuvée Halin',
          producer: 'Domaine Sylvain Pataille',
          vintage: 2020,
          wineType: 'red',
          appellation: 'Bourgogne',
          region: 'Bourgogne',
          country: 'France',
          bottlePrice: 52.0,
        ),
        BenchmarkMenuWine(
          name: 'Saumur-Champigny Le Clos',
          producer: 'Clos Rougeard',
          vintage: 2017,
          wineType: 'red',
          appellation: 'Saumur-Champigny',
          region: 'Loire',
          country: 'France',
          bottlePrice: 210.0,
          isGem: true,
          gemReason: 'Légende introuvable du Cabernet Franc',
        ),
        BenchmarkMenuWine(
          name: 'Saint-Joseph Offerus',
          producer: 'Domaine Jean-Louis Chave',
          vintage: 2019,
          wineType: 'red',
          appellation: 'Saint-Joseph',
          region: 'Vallée du Rhône',
          country: 'France',
          bottlePrice: 65.0,
        ),
        BenchmarkMenuWine(
          name: 'Pic Saint-Loup La Chouette du Chai',
          producer: 'Mas Bruguière',
          vintage: 2021,
          wineType: 'red',
          appellation: 'Pic Saint-Loup',
          region: 'Languedoc',
          country: 'France',
          bottlePrice: 34.0,
          glassPrices: const [MenuWineGlassPrice(format: '12cl', price: 6.5)],
          isDeal: true,
          dealReason: 'Prix très doux pour ce superbe domaine familial',
        ),
      ],
    ),

    // 2. Table Gastronomique 3 Étoiles (Prestige, Grands Crus, Vins de Garde)
    BenchmarkMenu(
      id: 'menu_gastronomique_3etoiles',
      title: 'L\'Arpège — Sélection du Chef Sommelier',
      restaurantName: 'L\'Arpège',
      category: 'three_stars',
      rawMenuText: '''
L'ARPÈGE — ALAIN PASSARD
SÉLECTION DU SOMMELIER

CHAMPAGNES
Dom Pérignon Vintage 2013 — Brut (420 €)
Egly-Ouriet Grand Cru "VP" Vieillissement Prolongé Extra-Brut (290 €)
Jacques Selosse "Initial" Blanc de Blancs Grand Cru Brut (550 €)

BOURGOGNE BLANC
Corton-Charlemagne Grand Cru 2018 — Domaine Bonneau du Martray (650 €)
Meursault 1er Cru "Les Perrières" 2019 — Domaine des Comtes Lafon (720 €)

BORDEAUX ROUGE
Château Pontet-Canet 2010 — 5ème Grand Cru Classé Pauillac (360 €)
Château Cheval Blanc 2005 — 1er Grand Cru Classé A Saint-Émilion (1650 €)
Château Haut-Brion 2012 — 1er Grand Cru Classé Pessac-Léognan (980 €)

RHÔNE & LOIRE
Côte-Rôtie "La Landonne" 2015 — E. Guigal (790 €)
Châteauneuf-du-Pape "Hommage à Jacques Perrin" 2014 — Château de Beaucastel (820 €)
''',
      expectedWines: [
        BenchmarkMenuWine(
          name: 'Dom Pérignon Vintage',
          producer: 'Moët & Chandon / Dom Pérignon',
          vintage: 2013,
          wineType: 'sparkling',
          appellation: 'Champagne',
          region: 'Champagne',
          country: 'France',
          bottlePrice: 420.0,
        ),
        BenchmarkMenuWine(
          name: 'Grand Cru VP Extra-Brut',
          producer: 'Egly-Ouriet',
          vintage: null,
          wineType: 'sparkling',
          appellation: 'Champagne Grand Cru',
          region: 'Champagne',
          country: 'France',
          bottlePrice: 290.0,
          isGem: true,
          gemReason: 'Grand Cru d\'Ambonnay élevage très prolongé',
        ),
        BenchmarkMenuWine(
          name: 'Initial Blanc de Blancs Grand Cru',
          producer: 'Jacques Selosse',
          vintage: null,
          wineType: 'sparkling',
          appellation: 'Champagne Grand Cru',
          region: 'Champagne',
          country: 'France',
          bottlePrice: 550.0,
          isGem: true,
          gemReason: 'Icône mondiale absolue de Champagne vigneron',
        ),
        BenchmarkMenuWine(
          name: 'Corton-Charlemagne Grand Cru',
          producer: 'Domaine Bonneau du Martray',
          vintage: 2018,
          wineType: 'white',
          appellation: 'Corton-Charlemagne Grand Cru',
          region: 'Bourgogne',
          country: 'France',
          bottlePrice: 650.0,
        ),
        BenchmarkMenuWine(
          name: 'Meursault 1er Cru Les Perrières',
          producer: 'Domaine des Comtes Lafon',
          vintage: 2019,
          wineType: 'white',
          appellation: 'Meursault 1er Cru',
          region: 'Bourgogne',
          country: 'France',
          bottlePrice: 720.0,
          isGem: true,
          gemReason: 'Le plus grand climat blanc de Meursault',
        ),
        BenchmarkMenuWine(
          name: 'Château Pontet-Canet',
          producer: 'Château Pontet-Canet',
          vintage: 2010,
          wineType: 'red',
          appellation: 'Pauillac',
          region: 'Bordeaux',
          country: 'France',
          bottlePrice: 360.0,
          isDeal: true,
          dealReason: 'Millésime d\'anthologie noté 100/100, tarif mesuré pour 3 étoiles',
        ),
        BenchmarkMenuWine(
          name: 'Château Cheval Blanc',
          producer: 'Château Cheval Blanc',
          vintage: 2005,
          wineType: 'red',
          appellation: 'Saint-Émilion Grand Cru',
          region: 'Bordeaux',
          country: 'France',
          bottlePrice: 1650.0,
          isGem: true,
        ),
        BenchmarkMenuWine(
          name: 'Château Haut-Brion',
          producer: 'Château Haut-Brion',
          vintage: 2012,
          wineType: 'red',
          appellation: 'Pessac-Léognan',
          region: 'Bordeaux',
          country: 'France',
          bottlePrice: 980.0,
        ),
        BenchmarkMenuWine(
          name: 'Côte-Rôtie La Landonne',
          producer: 'E. Guigal',
          vintage: 2015,
          wineType: 'red',
          appellation: 'Côte-Rôtie',
          region: 'Vallée du Rhône',
          country: 'France',
          bottlePrice: 790.0,
          isGem: true,
          gemReason: 'Trilogie mythique de Guigal millésime d\'exception',
        ),
        BenchmarkMenuWine(
          name: 'Châteauneuf-du-Pape Hommage à Jacques Perrin',
          producer: 'Château de Beaucastel',
          vintage: 2014,
          wineType: 'red',
          appellation: 'Châteauneuf-du-Pape',
          region: 'Vallée du Rhône',
          country: 'France',
          bottlePrice: 820.0,
        ),
      ],
    ),

    // 3. Bar à Vins Nature & Biodynamie (Orange, Pét-nat, Jura)
    BenchmarkMenu(
      id: 'menu_bar_a_vins_nature',
      title: 'La Buvette des Vignerons Naturels',
      restaurantName: 'La Buvette des Vignerons',
      category: 'natural_wine_bar',
      rawMenuText: '''
LA BUVETTE — ARDOISE DES VINS DU MOMENT
(Tous nos vins sont vinifiés sans intrant ni soufre ajouté)

BULLES & PÉT-NAT
"Festejar" Pétillant Naturel Rosé 2022 — Patrick Bouju (32 €)
"Bulles de Comptoir #11" Extra-Brut — Champagne Charles Dufour (68 €)

MACÉRATION & ORANGE
"Ribolla Gialla" Anfora 2014 — Gravner (Frioul) (115 €)
"Tinus" Macération de Pinot Gris 2021 — Jean-Pierre Rietsch (Alsace) (36 €)

ROUGES LIBRES & VIVANTS
"Chemin de Moscou" 2020 — Domaine Gayda (IGP Pays d'Oc) (38 €)
"Brimborions" Gamay 2021 — Domaine La Bohème (Patrick Bouju) (44 €)
"Cuvée Romanissa" 2019 — Domaine Matassa (Côtes Catalanes) (58 €)
"Susucaru Rosso" 2022 — Frank Cornelissen (Etna) (48 €)
''',
      expectedWines: [
        BenchmarkMenuWine(
          name: 'Festejar Rosé Pét-Nat',
          producer: 'Patrick Bouju / Domaine La Bohème',
          vintage: 2022,
          wineType: 'sparkling',
          appellation: 'Vin de France',
          region: 'Auvergne',
          country: 'France',
          bottlePrice: 32.0,
          isDeal: true,
          dealReason: 'Pét-nat star d\'Auvergne à prix très accessible',
        ),
        BenchmarkMenuWine(
          name: 'Bulles de Comptoir #11',
          producer: 'Champagne Charles Dufour',
          vintage: null,
          wineType: 'sparkling',
          appellation: 'Champagne',
          region: 'Champagne',
          country: 'France',
          bottlePrice: 68.0,
          isGem: true,
          gemReason: 'Champagne nature d\'auteur de la Côte des Bar',
        ),
        BenchmarkMenuWine(
          name: 'Ribolla Gialla Anfora',
          producer: 'Josko Gravner',
          vintage: 2014,
          wineType: 'white',
          appellation: 'Venezia Giulia IGT',
          region: 'Frioul',
          country: 'Italie',
          bottlePrice: 115.0,
          isGem: true,
          gemReason: 'Le père fondateur mondial des vins orange en qvevri',
        ),
        BenchmarkMenuWine(
          name: 'Tinus Macération Pinot Gris',
          producer: 'Jean-Pierre Rietsch',
          vintage: 2021,
          wineType: 'white',
          appellation: 'Alsace',
          region: 'Alsace',
          country: 'France',
          bottlePrice: 36.0,
          isDeal: true,
          dealReason: 'Splendide macération alsacienne très digeste',
        ),
        BenchmarkMenuWine(
          name: 'Chemin de Moscou',
          producer: 'Domaine Gayda',
          vintage: 2020,
          wineType: 'red',
          appellation: 'IGP Pays d\'Oc',
          region: 'Languedoc',
          country: 'France',
          bottlePrice: 38.0,
        ),
        BenchmarkMenuWine(
          name: 'Brimborions Gamay',
          producer: 'Patrick Bouju',
          vintage: 2021,
          wineType: 'red',
          appellation: 'Vin de France',
          region: 'Auvergne',
          country: 'France',
          bottlePrice: 44.0,
          isGem: true,
        ),
        BenchmarkMenuWine(
          name: 'Cuvée Romanissa',
          producer: 'Domaine Matassa (Tom Lubbe)',
          vintage: 2019,
          wineType: 'red',
          appellation: 'IGP Côtes Catalanes',
          region: 'Roussillon',
          country: 'France',
          bottlePrice: 58.0,
          isGem: true,
          gemReason: 'Domaine culte international du Roussillon vivant',
        ),
        BenchmarkMenuWine(
          name: 'Susucaru Rosso',
          producer: 'Frank Cornelissen',
          vintage: 2022,
          wineType: 'red',
          appellation: 'Terre Siciliane IGT',
          region: 'Sicile',
          country: 'Italie',
          bottlePrice: 48.0,
          isGem: true,
          gemReason: 'Lave et fraîcheur sur les pentes volcaniques de l\'Etna',
        ),
      ],
    ),

    // 4. Trattoria Italienne (Vins d'Italie DOCG & Régions)
    BenchmarkMenu(
      id: 'menu_trattoria_italienne',
      title: 'Osteria del Vigneto — Vini Italiani',
      restaurantName: 'Osteria del Vigneto',
      category: 'trattoria',
      rawMenuText: '''
OSTERIA DEL VIGNETO — CARTA DEI VINI

BOLLICINE
Prosecco Superiore Valdobbiadene DOCG Extra Dry — Nino Franco (Verre: 6€ | Bouteille: 30€)
Franciacorta "Cuvée Prestige" Edizione 45 — Ca\' del Bosco (Bouteille: 65€)

BIANCHI
Gavi del Comune di Gavi "La Granée" 2022 — Batasiolo (Verre: 7€ | Bouteille: 35€)
Soave Classico "Calvarino" 2021 — Pieropan (Bouteille: 46€)

ROSSI
Chianti Classico "Berardenga" 2020 — Fattoria di Fèlsina (Verre: 8€ | Bouteille: 42€)
Barolo "Castiglione" 2019 — Vietti (Bouteille: 95€)
Brunello di Montalcino 2018 — Il Poggione (Bouteille: 88€)
Etna Rosso 2021 — Tenuta delle Terre Nere (Verre: 8.50€ | Bouteille: 45€)
''',
      expectedWines: [
        BenchmarkMenuWine(
          name: 'Prosecco Superiore Valdobbiadene',
          producer: 'Nino Franco',
          vintage: null,
          wineType: 'sparkling',
          appellation: 'Valdobbiadene Prosecco Superiore DOCG',
          region: 'Vénétie',
          country: 'Italie',
          bottlePrice: 30.0,
          glassPrices: const [MenuWineGlassPrice(format: 'Verre', price: 6.0)],
        ),
        BenchmarkMenuWine(
          name: 'Franciacorta Cuvée Prestige',
          producer: 'Ca\' del Bosco',
          vintage: null,
          wineType: 'sparkling',
          appellation: 'Franciacorta DOCG',
          region: 'Lombardie',
          country: 'Italie',
          bottlePrice: 65.0,
          isGem: true,
          gemReason: 'Référence emblématique de méthode traditionnelle italienne',
        ),
        BenchmarkMenuWine(
          name: 'Gavi La Granée',
          producer: 'Batasiolo',
          vintage: 2022,
          wineType: 'white',
          appellation: 'Gavi DOCG',
          region: 'Piémont',
          country: 'Italie',
          bottlePrice: 35.0,
          glassPrices: const [MenuWineGlassPrice(format: 'Verre', price: 7.0)],
        ),
        BenchmarkMenuWine(
          name: 'Soave Classico Calvarino',
          producer: 'Pieropan',
          vintage: 2021,
          wineType: 'white',
          appellation: 'Soave Classico DOC',
          region: 'Vénétie',
          country: 'Italie',
          bottlePrice: 46.0,
          isGem: true,
          gemReason: 'Monument minéral du cru historique de Soave',
        ),
        BenchmarkMenuWine(
          name: 'Chianti Classico Berardenga',
          producer: 'Fattoria di Fèlsina',
          vintage: 2020,
          wineType: 'red',
          appellation: 'Chianti Classico DOCG',
          region: 'Toscane',
          country: 'Italie',
          bottlePrice: 42.0,
          glassPrices: const [MenuWineGlassPrice(format: 'Verre', price: 8.0)],
          isDeal: true,
          dealReason: 'Sangiovese pur de référence à prix très équilibré',
        ),
        BenchmarkMenuWine(
          name: 'Barolo Castiglione',
          producer: 'Vietti',
          vintage: 2019,
          wineType: 'red',
          appellation: 'Barolo DOCG',
          region: 'Piémont',
          country: 'Italie',
          bottlePrice: 95.0,
          isGem: true,
          gemReason: 'Assemblage magistral de grands terroirs de Barolo',
        ),
        BenchmarkMenuWine(
          name: 'Brunello di Montalcino',
          producer: 'Tenuta Il Poggione',
          vintage: 2018,
          wineType: 'red',
          appellation: 'Brunello di Montalcino DOCG',
          region: 'Toscane',
          country: 'Italie',
          bottlePrice: 88.0,
        ),
        BenchmarkMenuWine(
          name: 'Etna Rosso',
          producer: 'Tenuta delle Terre Nere (Marco de Grazia)',
          vintage: 2021,
          wineType: 'red',
          appellation: 'Etna Rosso DOC',
          region: 'Sicile',
          country: 'Italie',
          bottlePrice: 45.0,
          glassPrices: const [MenuWineGlassPrice(format: 'Verre', price: 8.5)],
          isDeal: true,
          dealReason: 'Élégance bourguignonne sur terroir volcanique',
        ),
      ],
    ),
  ];

  static BenchmarkMenu getById(String id) {
    return menus.firstWhere(
      (m) => m.id == id,
      orElse: () => throw ArgumentError('Benchmark menu with id "$id" not found'),
    );
  }
}
