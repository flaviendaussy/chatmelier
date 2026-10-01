import 'langue.dart';

/// Les valeurs rangées en français dans les profils et les fiches — couleurs, styles,
/// aversions, régions, pays, continents —, affichées dans la langue de l'écran (V2.3 · H8).
///
/// La valeur rangée ne change jamais : le moteur de consensus, les filtres, le serveur et
/// les profils déjà enregistrés la lisent telle quelle. Seul l'affichage passe par ici.
/// Une valeur inconnue (saisie libre, appellation d'une fiche) s'affiche comme rangée.
String valeurAffichee(String valeur) => trDonnee(valeur.trim(), valeursRangeesEn);

/// Les autres langues viennent des catalogues, indexés par la valeur française.
const Map<String, String> valeursRangeesEn = {
  // Couleurs : palais de départ, apprentissage, convives d'une table.
  'Rouge': 'Red',
  'Blanc': 'White',
  'Rosé': 'Rosé',
  'Bulles': 'Sparkling',

  // Styles proposés par l'éditeur du profil.
  'Rouge puissant & structuré': 'Powerful, structured red',
  'Rouge soyeux & fruité': 'Silky, fruity red',
  'Blanc sec minéral & tendu': 'Dry, taut, mineral white',
  'Blanc gras & aromatique': 'Rich, aromatic white',
  'Rosé de gastronomie': 'Food-friendly rosé',
  'Champagne & Effervescents': 'Champagne & sparkling wines',
  'Moelleux / Liquoreux': 'Sweet & dessert wines',
  'Vins Nature & Biodynamie': 'Natural & biodynamic wines',

  // Aversions : palais de départ, puis éditeur du profil.
  'Trop tannique': 'Too tannic',
  'Trop boisé': 'Too oaky',
  'Trop acide': 'Too sharp',
  'Tanins trop astringents / râpeux': 'Harsh, drying tannins',
  'Boisé ou vanille excessif': 'Too much oak or vanilla',
  'Acidité agressive': 'Aggressive acidity',
  'Alcool trop chaleureux / lourd': 'Hot, heavy alcohol',
  'Sucre résiduel / Vins trop doux': 'Residual sugar / wines too sweet',
  'Notes végétales / poivron vert': 'Green, bell-pepper notes',
  'Vins industriels standardisés': 'Mass-produced, standardised wines',

  // Régions qui portent un autre nom hors de France ; les autres (Bordeaux, Alsace,
  // Champagne…) se disent partout de même.
  'Bourgogne': 'Burgundy',
  'Vallée du Rhône': 'Rhône Valley',
  'Rhône': 'Rhône',
  'Val de Loire': 'Loire Valley',
  'Loire': 'Loire',
  'Sud-Ouest': 'South-West France',
  'Corse': 'Corsica',
  'Jura & Savoie': 'Jura & Savoy',
  'Savoie': 'Savoy',
  'Bandol & Provence': 'Bandol & Provence',
  'Languedoc-Roussillon': 'Languedoc-Roussillon',
  'Toscane (Italie)': 'Tuscany (Italy)',
  'Piémont (Italie)': 'Piedmont (Italy)',
  'Rioja (Espagne)': 'Rioja (Spain)',
  'Ribera del Duero (Espagne)': 'Ribera del Duero (Spain)',
  'Napa Valley (USA)': 'Napa Valley (USA)',
  'Mendoza (Argentine)': 'Mendoza (Argentina)',
  'Toscane': 'Tuscany',
  'Piémont': 'Piedmont',

  // Pays, tels que les fiches les rangent.
  'France': 'France',
  'Italie': 'Italy',
  'Espagne': 'Spain',
  'Portugal': 'Portugal',
  'Allemagne': 'Germany',
  'Autriche': 'Austria',
  'Suisse': 'Switzerland',
  'Grèce': 'Greece',
  'Hongrie': 'Hungary',
  'Liban': 'Lebanon',
  'États-Unis': 'United States',
  'Chili': 'Chile',
  'Argentine': 'Argentina',
  'Australie': 'Australia',
  'Nouvelle-Zélande': 'New Zealand',
  'Afrique du Sud': 'South Africa',

  // Continents (filtre de la cave).
  'Europe': 'Europe',
  'Amériques': 'Americas',
  'Océanie': 'Oceania',
  'Afrique': 'Africa',
};
