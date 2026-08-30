import 'package:latlong2/latlong.dart';

class TerroirGISNode {
  final String id;
  final String name;
  final String region;
  final String country;
  final String countryCode;
  final String flag;
  final LatLng center;
  final double defaultZoom;
  final List<String> aliases;
  final String description;
  final String soilType;
  final String climate;
  final String keyGrapes;
  final String classification;

  const TerroirGISNode({
    required this.id,
    required this.name,
    required this.region,
    required this.country,
    required this.countryCode,
    required this.flag,
    required this.center,
    this.defaultZoom = 9.5,
    required this.aliases,
    required this.description,
    required this.soilType,
    required this.climate,
    required this.keyGrapes,
    this.classification = 'AOC / Cru',
  });
}

class TerroirGISCatalog {
  static const List<TerroirGISNode> nodes = [
    // ==========================================
    // 🇫🇷 FRANCE
    // ==========================================
    TerroirGISNode(
      id: 'fr_bordeaux_left_bank',
      name: 'Bordeaux — Rive Gauche (Médoc & Graves)',
      region: 'Bordeaux',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.1970, -0.7420), // Pauillac / Margaux
      defaultZoom: 10.0,
      aliases: [
        'bordeaux', 'médoc', 'medoc', 'haut-médoc', 'haut medoc', 'margaux', 'pauillac',
        'saint-julien', 'saint julien', 'saint-estèphe', 'saint estephe', 'moulis',
        'listrac', 'graves', 'pessac-léognan', 'pessac leognan', 'pessac'
      ],
      description: 'Terres d\'élection du Cabernet Sauvignon sur croupes de graves garonnaises profondes, abritant les Grands Crus Classés 1855.',
      soilType: 'Graves garonnaises profondes, galets quartzeux, sous-sol argileux',
      climate: 'Océanique tempéré régulé par l\'estuaire de la Gironde et la forêt des Landes',
      keyGrapes: 'Cabernet Sauvignon (dominant), Merlot, Cabernet Franc, Petit Verdot',
      classification: 'Grands Crus Classés 1855, Crus Bourgeois, AOC Communales',
    ),
    TerroirGISNode(
      id: 'fr_bordeaux_right_bank',
      name: 'Bordeaux — Rive Droite (Saint-Émilion & Pomerol)',
      region: 'Bordeaux',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(44.9180, -0.1980), // Libourne / Pomerol / Saint-Emilion
      defaultZoom: 11.0,
      aliases: [
        'saint-émilion', 'saint emilion', 'pomerol', 'lalande-de-pomerol', 'lalande de pomerol',
        'fronsac', 'canon-fronsac', 'canon fronsac', 'castillon', 'francs', 'côtes de bordeaux',
        'montagne saint-émilion', 'lussac saint-émilion', 'puisseguin'
      ],
      description: 'Royaume du Merlot soyeux et du Cabernet Franc sur plateau calcaire à astéries et crasse de fer renommée.',
      soilType: 'Plateau calcaire à astéries, argiles bleues profondes, crasse de fer (Pomerol)',
      climate: 'Océanique à nuances continentales avec influence de la Dordogne et de l\'Isle',
      keyGrapes: 'Merlot (dominant), Cabernet Franc (Bouchet), Cabernet Sauvignon',
      classification: 'Classement Saint-Émilion (Premiers Grands Crus Classés), Pomerol',
    ),
    TerroirGISNode(
      id: 'fr_bordeaux_sauternes',
      name: 'Bordeaux — Sauternes & Barsac',
      region: 'Bordeaux',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(44.5350, -0.3400),
      defaultZoom: 11.5,
      aliases: ['sauternes', 'barsac', 'cerons', 'cérons', 'loupiac', 'sainte-croix-du-mont', 'cadillac'],
      description: 'L\'or liquide de Bordeaux, né de la pourriture noble (Botrytis Cinerea) favorisée par les brumes du Ciron.',
      soilType: 'Graves fines sur sous-sol argilo-calcaire et marnes',
      climate: 'Microclimat unique brumeux matinal et ensoleillé l\'après-midi',
      keyGrapes: 'Sémillon, Sauvignon Blanc, Muscadelle',
      classification: 'Grands Crus Classés 1855 (Château d\'Yquem Premier Cru Supérieur)',
    ),
    TerroirGISNode(
      id: 'fr_bourgogne_cote_de_nuits',
      name: 'Bourgogne — Côte de Nuits',
      region: 'Bourgogne',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(47.1650, 4.9550), // Nuits-Saint-Georges / Vosne
      defaultZoom: 11.0,
      aliases: [
        'bourgogne', 'burgundy', 'côte de nuits', 'cote de nuits', 'gevrey-chambertin', 'gevrey chambertin',
        'vosne-romanée', 'vosne romanee', 'chambolle-musigny', 'chambolle musigny', 'nuits-saint-georges',
        'nuits saint georges', 'morey-saint-denis', 'morey saint denis', 'vougeot', 'clos de vougeot',
        'flagey-échézeaux', 'marsannay', 'fixin', 'romanee-conti', 'chambertin', 'musigny'
      ],
      description: 'Les Champs-Élysées du Pinot Noir. Une bande étroite de coteaux calcaires orientés levant produisant les rouges les plus recherchés au monde.',
      soilType: 'Calcaires bajociens et bathoniens, éboulis caillouteux et marnes oxfordiennes',
      climate: 'Semi-continental à influences océaniques modérées',
      keyGrapes: 'Pinot Noir (99%), Chardonnay',
      classification: 'Grands Crus (24 Grands Crus rouges), Premiers Crus, Climats UNESCO',
    ),
    TerroirGISNode(
      id: 'fr_bourgogne_cote_de_beaune',
      name: 'Bourgogne — Côte de Beaune',
      region: 'Bourgogne',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(46.9950, 4.7850), // Beaune / Meursault / Puligny
      defaultZoom: 10.5,
      aliases: [
        'côte de beaune', 'cote de beaune', 'meursault', 'puligny-montrachet', 'puligny montrachet',
        'chassagne-montrachet', 'chassagne montrachet', 'pommard', 'volnay', 'corton', 'corton-charlemagne',
        'beaune', 'savigny-lès-beaune', 'aloxe-corton', 'saint-aubin', 'auxey-duresses', 'monthelie', 'santenay'
      ],
      description: 'L\'apogée mondial du Chardonnay (Montrachet, Meursault) et des Pinots Noirs d\'une infinie noblesse (Volnay, Pommard, Corton).',
      soilType: 'Marnes blanches kimméridgiennes, calcaires oolithiques et argiles ferrugineuses',
      climate: 'Semi-continental ensoleillé en coteaux doux',
      keyGrapes: 'Chardonnay (dominant), Pinot Noir',
      classification: 'Grands Crus (Montrachet, Corton-Charlemagne...), Premiers Crus d\'exception',
    ),
    TerroirGISNode(
      id: 'fr_bourgogne_chablis',
      name: 'Bourgogne — Chablis & Grand Auxerrois',
      region: 'Bourgogne',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(47.8150, 3.8000), // Chablis
      defaultZoom: 11.0,
      aliases: ['chablis', 'petit chablis', 'chablis premier cru', 'chablis grand cru', 'irancy', 'saint-bris', 'vézelay', 'auxerrois'],
      description: 'Pureté minérale absolue : des Chardonnays vifs et iodés sculptés par le fameux sous-sol kimméridgien riche en fossiles d\'huîtres.',
      soilType: 'Calcaire kimméridgien compact truffé de fossiles d\'Exogyra virgula',
      climate: 'Semi-continental frais et septentrional, sujet aux gelées printanières',
      keyGrapes: 'Chardonnay (100% Chablis), Pinot Noir / César (Irancy), Sauvignon (Saint-Bris)',
      classification: '7 Climats Grands Crus (Les Clos, Vaudésir, Blanchot...), 40 Premiers Crus',
    ),
    TerroirGISNode(
      id: 'fr_bourgogne_chalonnaise_macon',
      name: 'Bourgogne — Côte Chalonnaise & Mâconnais',
      region: 'Bourgogne',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(46.5500, 4.7500),
      defaultZoom: 10.0,
      aliases: [
        'côte chalonnaise', 'cote chalonnaise', 'mâcon', 'macon', 'mercurey', 'givry', 'rully',
        'montagny', 'bouzeron', 'pouilly-fuissé', 'pouilly fuisse', 'saint-véran', 'viré-clessé'
      ],
      description: 'L\'élégance bourguignonne accessible : superbes Chardonnays de Pouilly-Fuissé, Aligoté doré de Bouzeron et Pinots Noirs friands de Mercurey/Givry.',
      soilType: 'Argilo-calcaire jurassique et grès',
      climate: 'Semi-continental aux influences méridionales douces',
      keyGrapes: 'Chardonnay, Pinot Noir, Aligoté (Bouzeron)',
      classification: 'Premiers Crus (Pouilly-Fuissé, Mercurey, Givry, Rully, Montagny)',
    ),
    TerroirGISNode(
      id: 'fr_champagne',
      name: 'Champagne (Montagne de Reims, Côte des Blancs, Aube)',
      region: 'Champagne',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(49.0400, 4.0200), // Epernay / Reims
      defaultZoom: 9.8,
      aliases: [
        'champagne', 'reims', 'épernay', 'epernay', 'ay', 'aÿ', 'avize', 'cramant', 'le mesnil-sur-oger',
        'bouzy', 'ambonnay', 'vallée de la marne', 'côte des blancs', 'montagne de reims', 'côte des bar', 'aube'
      ],
      description: 'Le sommet mondial des vins effervescents. Des sols de craie pure agissant comme régulateurs thermiques et hydriques parfaits.',
      soilType: 'Craie blanche belemnite et marnes campaniennes poreuses',
      climate: 'Océanique froid à double influence continentale (septentrional)',
      keyGrapes: 'Chardonnay, Pinot Noir, Pinot Meunier',
      classification: '17 villages 100% Grand Cru, 42 villages Premier Cru',
    ),
    TerroirGISNode(
      id: 'fr_rhone_nord',
      name: 'Vallée du Rhône Septentrionale',
      region: 'Vallée du Rhône',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(45.2400, 4.8200), // Tain l'Hermitage / Côte-Rôtie
      defaultZoom: 10.5,
      aliases: [
        'côte-rôtie', 'cote-rotie', 'cote rotie', 'hermitage', 'crozes-hermitage', 'crozes hermitage',
        'saint-joseph', 'saint joseph', 'cornas', 'condrieu', 'château-grillet', 'chateau grillet', 'saint-péray'
      ],
      description: 'Coteaux vertigineux en terrasses plongeant dans le Rhône. Berceau mythique de la Syrah poivrée et du Viognier opulent de Condrieu.',
      soilType: 'Granits micacés, schistes métamorphiques, terrasses arides de loess',
      climate: 'Continental modéré avec influence du vent Mistral assainissant',
      keyGrapes: 'Syrah (unique rouge), Viognier, Marsanne, Roussanne',
      classification: '8 Crus légendaires du Rhône Nord',
    ),
    TerroirGISNode(
      id: 'fr_rhone_sud',
      name: 'Vallée du Rhône Méridionale',
      region: 'Vallée du Rhône',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(44.1500, 4.8800), // Chateauneuf-du-Pape / Gigondas
      defaultZoom: 10.0,
      aliases: [
        'rhône', 'rhone', 'châteauneuf-du-pape', 'chateauneuf-du-pape', 'chateauneuf', 'gigondas',
        'vacqueyras', 'beaumes-de-venise', 'rasteau', 'lirac', 'tavel', 'cairanne', 'côtes du rhône',
        'cotes du rhone', 'luberon', 'ventoux', 'costières de nîmes'
      ],
      description: 'Terres baignées de soleil aux célèbres galets roulés qui restituent la chaleur la nuit. Grenache somptueux et généreux.',
      soilType: 'Galets roulés quartzeux villafranchiens, terrasses argilo-calcaires, safres',
      climate: 'Méditerranéen chaud, sec et très venteux (Mistral)',
      keyGrapes: 'Grenache Noir (roi), Syrah, Mourvèdre, Cinsault, Clairette, Roussanne',
      classification: 'Crus majeurs (Châteauneuf-du-Pape, Gigondas...), Côtes du Rhône Villages',
    ),
    TerroirGISNode(
      id: 'fr_loire',
      name: 'Vallée de la Loire',
      region: 'Vallée de la Loire',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(47.3800, 0.4500), // Tours / Sancerre / Anjou
      defaultZoom: 9.0,
      aliases: [
        'loire', 'sancerre', 'pouilly-fumé', 'pouilly fume', 'chinon', 'vouvray', 'saumur',
        'saumur-champigny', 'muscadet', 'anjou', 'bourgueil', 'saint-nicolas-de-bourgueil',
        'menetou-salon', 'savennières', 'coteaux du layon', 'cheverny', 'touraine'
      ],
      description: 'Le Jardin de la France étiré sur 1000 km. Chenin Blanc aux mille facettes, Sauvignon minéral de Sancerre et Cabernets Francs de tuffeau.',
      soilType: 'Tuffeau calcaire blanc, silex kimméridgiens, schistes ardoisiers et argiles à silex',
      climate: 'Océanique doux devenant semi-continental vers l\'est',
      keyGrapes: 'Chenin Blanc, Sauvignon Blanc, Cabernet Franc, Melon de Bourgogne',
      classification: 'AOC Communales d\'excellence (Sancerre, Vouvray, Chinon, Savennières...)',
    ),
    TerroirGISNode(
      id: 'fr_alsace',
      name: 'Alsace & Grands Crus',
      region: 'Alsace',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(48.0800, 7.3600), // Colmar / Riquewihr
      defaultZoom: 10.2,
      aliases: ['alsace', 'alsace grand cru', 'riesling', 'gewurztraminer', 'pinot gris', 'sylvaner', 'colmar', 'riquewihr', 'ribeauvillé'],
      description: 'Une des plus riches mosaïques géologiques du monde, protégée par le massif vosgien qui en fait l\'une des régions les plus sèches de France.',
      soilType: 'Mosaïque géologique (granit, grès rose, calcaire coquillier, marnes, volcanique)',
      climate: 'Semi-continental très ensoleillé grâce à l\'effet de foehn vosgien',
      keyGrapes: 'Riesling, Gewurztraminer, Pinot Gris, Muscat, Pinot Blanc, Pinot Noir',
      classification: '51 terroirs d\'Alsace Grand Cru, Vendanges Tardives, SGN',
    ),
    TerroirGISNode(
      id: 'fr_provence_corse',
      name: 'Provence & Corse',
      region: 'Provence & Corse',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(43.3500, 5.9500), // Bandol / Aix / Corse
      defaultZoom: 9.0,
      aliases: [
        'provence', 'bandol', 'cassis', 'coteaux d\'aix', 'palette', 'bellet', 'côtes de provence',
        'corse', 'corsica', 'patrimonio', 'ajaccio', 'calvi', 'sartène', 'porto-vecchio'
      ],
      description: 'Mourvèdre puissant de Bandol bercé par la mer Méditerranée, grands blancs calcaires de Cassis et cépages autochtones insulaires corses (Sciaccarellu, Niellucciu).',
      soilType: 'Restanques calcaires arides, marnes triasiques, granits et schistes corses',
      climate: 'Méditerranéen d\'un ensoleillement maximal (plus de 2800 h/an)',
      keyGrapes: 'Mourvèdre, Grenache, Cinsault, Tibouren, Rolle/Vermentinu, Sciaccarellu, Niellucciu',
      classification: 'AOC d\'exception (Bandol, Cassis, Palette, Patrimonio, Ajaccio)',
    ),
    TerroirGISNode(
      id: 'fr_languedoc_roussillon',
      name: 'Languedoc & Roussillon',
      region: 'Languedoc-Roussillon',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(43.4000, 3.2500),
      defaultZoom: 9.2,
      aliases: [
        'languedoc', 'roussillon', 'pic saint-loup', 'pic saint loup', 'terrasses du larzac',
        'corbières', 'corbieres', 'minervois', 'faugères', 'saint-chinian', 'collioure', 'banyuls',
        'limoux', 'la clape', 'fitou', 'côtes du roussillon'
      ],
      description: 'Le renouveau des grands terroirs du Sud : fraîcheur d\'altitude du Larzac et du Pic Saint-Loup, schistes de Faugères et grands effervescents de Limoux.',
      soilType: 'Schistes métamorphiques, calcaires lacustres fissurés, galets de grès',
      climate: 'Méditerranéen aride avec fraîcheur nocturne descendue des Cévennes',
      keyGrapes: 'Syrah, Grenache, Mourvèdre, Carignan, Cinsault, Mauzac, Grenache Blanc',
      classification: 'Grands Vins du Languedoc, Crus du Roussillon, Vins Doux Naturels',
    ),
    TerroirGISNode(
      id: 'fr_beaujolais_jura_savoie',
      name: 'Beaujolais, Jura & Savoie',
      region: 'Beaujolais & Alpes',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(46.3000, 5.3000),
      defaultZoom: 9.0,
      aliases: [
        'beaujolais', 'morgon', 'fleurie', 'moulin-à-vent', 'moulin a vent', 'brouilly',
        'jura', 'arbois', 'château-chalon', 'chateau chalon', 'vin jaune', 'étoile',
        'savoie', 'bugey', 'apremont', 'chignin-bergeron', 'mondeuse'
      ],
      description: 'Du Gamay sur schistes bleus aux Vins Jaunes jurassiens élevés 6 ans sous voile de levures, et aux cépages rares alpins (Savagnin, Poulsard, Mondeuse).',
      soilType: 'Granits roses, arènes schisteuses, marnes bleues et éboulis calcaires alpins',
      climate: 'Semi-continental à montagnard',
      keyGrapes: 'Gamay (Beaujolais), Savagnin, Poulsard, Trousseau (Jura), Mondeuse, Jacquère (Savoie)',
      classification: '10 Crus du Beaujolais, AOC Arbois, Château-Chalon',
    ),
    TerroirGISNode(
      id: 'fr_sud_ouest',
      name: 'Sud-Ouest (Cahors, Madiran, Jurançon)',
      region: 'Sud-Ouest',
      country: 'France',
      countryCode: 'FR',
      flag: '🇫🇷',
      center: LatLng(43.7000, 0.4000),
      defaultZoom: 9.0,
      aliases: [
        'sud-ouest', 'sud ouest', 'cahors', 'madiran', 'jurançon', 'jurancon', 'bergerac',
        'monbazillac', 'gaillac', 'irouléguy', 'fronton', 'pacherenc'
      ],
      description: 'Vignobles de caractère et cépages ancestraux : le Malbec obscur de Cahors sur causse calcaire, le Tannat puissant de Madiran et le Petit Manseng pyrénéen.',
      soilType: 'Causses calcaires kimméridgiens, terrasses graveleuses du Lot, poudingues pyrénéens',
      climate: 'Océanique à influences pyrénéennes fraîches',
      keyGrapes: 'Malbec (Côt), Tannat, Petit Manseng, Gros Manseng, Négrette, Fer Servadou',
      classification: 'AOC Historiques du Sud-Ouest',
    ),

    // ==========================================
    // 🇮🇹 ITALIE
    // ==========================================
    TerroirGISNode(
      id: 'it_piemonte',
      name: 'Italie — Piémont (Barolo & Barbaresco)',
      region: 'Piemonte',
      country: 'Italie',
      countryCode: 'IT',
      flag: '🇮🇹',
      center: LatLng(44.6200, 7.9800), // Langhe / Alba / Barolo
      defaultZoom: 10.5,
      aliases: [
        'piemonte', 'piémont', 'barolo', 'barbaresco', 'langhe', 'nebbiolo', 'alba',
        'barbera d\'alba', 'barbera d\'asti', 'dogliani', 'dolcetto', 'roero', 'gavi'
      ],
      description: 'La noblesse du cépage Nebbiolo sur les collines embrumées des Langhe. Vins de très longue garde d\'une complexité aromatique légendaire.',
      soilType: 'Marnes de Sant\'Agata (tortoniens) et grès de Diano (helvétiens)',
      climate: 'Continental tempéré par les Alpes avec brumes automnales mythiques (nebbia)',
      keyGrapes: 'Nebbiolo, Barbera, Dolcetto, Cortese, Arneis',
      classification: 'DOCG Barolo, DOCG Barbaresco (MGA - Mentions Géographiques Ajoutées)',
    ),
    TerroirGISNode(
      id: 'it_toscana',
      name: 'Italie — Toscane (Chianti, Brunello, Bolgheri)',
      region: 'Toscana',
      country: 'Italie',
      countryCode: 'IT',
      flag: '🇮🇹',
      center: LatLng(43.2500, 11.3500), // Siena / Montalcino / Chianti
      defaultZoom: 9.8,
      aliases: [
        'toscana', 'toscane', 'chianti', 'chianti classico', 'brunello di montalcino', 'brunello',
        'montalcino', 'vino nobile di montepulciano', 'bolgheri', 'sassicaia', 'ornellaia', 'super tuscan', 'maremma'
      ],
      description: 'Le cœur battant du Sangiovese (Gallo Nero de Chianti et Brunello di Montalcino) et la révolution des Super Toscans bordelais de Bolgheri.',
      soilType: 'Galestro (schistes argileux friables), Alberese (calcaire dur), sables et argiles côtières',
      climate: 'Méditerranéen vallonné avec nuits fraîches sur les hauteurs',
      keyGrapes: 'Sangiovese (Grosso), Cabernet Sauvignon, Merlot, Trebbiano',
      classification: 'DOCG Brunello di Montalcino, DOCG Chianti Classico Gran Selezione, DOC Bolgheri Sassicaia',
    ),
    TerroirGISNode(
      id: 'it_veneto_trentino',
      name: 'Italie — Vénétie & Trentin-Haut-Adige',
      region: 'Veneto & Dolomiti',
      country: 'Italie',
      countryCode: 'IT',
      flag: '🇮🇹',
      center: LatLng(45.5000, 11.2000), // Verona / Valpolicella / Soave
      defaultZoom: 9.8,
      aliases: [
        'veneto', 'vénétie', 'valpolicella', 'amarone', 'ripasso', 'soave', 'prosecco',
        'valdobbiadene', 'trentino', 'alto adige', 'südtirol', 'bardolino', 'lugana'
      ],
      description: 'L\'art du passerillage (Appassimento) pour l\'incomparable Amarone della Valpolicella, la minéralité volcanique de Soave et les blancs purs des Dolomites.',
      soilType: 'Coteaux calcaires, terrasses volcaniques basaltiques et moraines glaciaires alpines',
      climate: 'Tempéré par le lac de Garde et la barrière protectrice des Alpes',
      keyGrapes: 'Corvina, Rondinella, Garganega, Pinot Grigio, Lagrein, Gewürztraminer',
      classification: 'DOCG Amarone della Valpolicella, DOCG Conegliano Valdobbiadene Prosecco',
    ),
    TerroirGISNode(
      id: 'it_sud_isole',
      name: 'Italie — Sicile (Etna) & Italie du Sud',
      region: 'Sud & Isole',
      country: 'Italie',
      countryCode: 'IT',
      flag: '🇮🇹',
      center: LatLng(37.7500, 15.0000), // Etna / Sicilia / Puglia
      defaultZoom: 8.5,
      aliases: [
        'sicilia', 'sicile', 'etna', 'nerello mascalese', 'nero d\'avola', 'puglia', 'pouilles',
        'primitivo di manduria', 'salice salentino', 'campania', 'taurasi', 'aglianico', 'fiano', 'greco di tufo', 'sardegna', 'cannonau'
      ],
      description: 'La viticulture héroïque volcanique sur les pentes actives de l\'Etna (vignes centenaires franches de pied), Aglianico magistral de Taurasi et Primitivo des Pouilles.',
      soilType: 'Laves et sables volcaniques riches en minéraux (Etna), terres rouges calcaires',
      climate: 'Méditerranéen intense tempéré par l\'altitude volcanique (jusqu\'à 1000m)',
      keyGrapes: 'Nerello Mascalese, Carricante, Nero d\'Avola, Aglianico, Primitivo, Negroamaro, Fiano',
      classification: 'DOC Etna Contrade, DOCG Taurasi, DOC Primitivo di Manduria',
    ),

    // ==========================================
    // 🇪🇸 ESPAGNE & 🇵🇹 PORTUGAL
    // ==========================================
    TerroirGISNode(
      id: 'es_rioja_ribera',
      name: 'Espagne — Rioja & Ribera del Duero',
      region: 'Castilla y Rioja',
      country: 'Espagne',
      countryCode: 'ES',
      flag: '🇪🇸',
      center: LatLng(42.1500, -2.8000), // Rioja & Duero
      defaultZoom: 9.0,
      aliases: [
        'rioja', 'ribera del duero', 'ribera', 'tempranillo', 'tinto fino', 'toro', 'rueda',
        'rioja alta', 'rioja alavesa', 'rioja oriental', 'haro', 'peñafiel', 'castilla y león'
      ],
      description: 'L\'aristocratie viticole espagnole. L\'équilibre noble du Tempranillo élevé en fûts de chêne et la puissance concentrée des hauts plateaux de la Ribera del Duero.',
      soilType: 'Argilo-calcaire blanc, terrasses alluviales ferrugineuses et galets siliceux',
      climate: 'Continental extrême aux hivers rudes et étés torrides à nuits fraîches (700-900m)',
      keyGrapes: 'Tempranillo (Tinto Fino), Graciano, Mazuelo, Garnacha, Verdejo',
      classification: 'DOCa Rioja (Gran Reserva / Viñedos Singulares), DO Ribera del Duero',
    ),
    TerroirGISNode(
      id: 'es_priorat_catalunya',
      name: 'Espagne — Priorat & Catalogne',
      region: 'Catalunya & Levante',
      country: 'Espagne',
      countryCode: 'ES',
      flag: '🇪🇸',
      center: LatLng(41.2000, 0.8500), // Priorat / Gratallops
      defaultZoom: 10.5,
      aliases: [
        'priorat', 'priorato', 'montsant', 'penedès', 'penedes', 'cava', 'corpinnat',
        'costers del segre', 'terra alta', 'empordà', 'garnacha', 'cariñena'
      ],
      description: 'Les terrasses vertigineuses de schistes noirs (Llicorella) du Priorat forgeant des vins rouges d\'une intensité minérale hors du commun, et berceau des grands effervescents de Cava / Corpinnat.',
      soilType: 'Llicorella (schistes noirs ardoisiers étincelants de quartz)',
      climate: 'Méditerranéen chaud et très aride abrité par la chaîne de Montsant',
      keyGrapes: 'Garnacha Tinta (Grenache), Cariñena (Carignan), Xarel-lo, Macabeo, Parellada',
      classification: 'DOCa Priorat (Vins de Finca / Vins de Vila), DO Cava / Corpinnat',
    ),
    TerroirGISNode(
      id: 'pt_douro_porto',
      name: 'Portugal — Vallée du Douro & Grands Terroirs',
      region: 'Douro & Portugal',
      country: 'Portugal',
      countryCode: 'PT',
      flag: '🇵🇹',
      center: LatLng(41.1500, -7.5500), // Pinhão / Douro
      defaultZoom: 9.8,
      aliases: [
        'douro', 'porto', 'port', 'touriga nacional', 'alentejo', 'vinho verde', 'dão', 'dao',
        'bairrada', 'madeira', 'madère', 'açores', 'acores', 'colares'
      ],
      description: 'Première région délimitée de l\'histoire viticole (1756). Terrasses spectaculaires de schistes taillées à la main au-dessus du fleuve Douro pour des Portos Vintage et grands vins secs.',
      soilType: 'Schistes métamorphiques feuilletés verticaux forçant les racines à 20 mètres',
      climate: 'Méditerranéen continental torride en été (Cima Corgo et Douro Superior)',
      keyGrapes: 'Touriga Nacional, Touriga Franca, Tinta Roriz, Alvarinho, Baga',
      classification: 'DOC Douro / DOC Porto, Patrimoine Mondial UNESCO',
    ),

    // ==========================================
    // 🌎 NOUVEAU MONDE
    // ==========================================
    TerroirGISNode(
      id: 'us_california_oregon',
      name: 'USA — Californie (Napa, Sonoma) & Oregon',
      region: 'West Coast USA',
      country: 'États-Unis',
      countryCode: 'US',
      flag: '🇺🇸',
      center: LatLng(38.4500, -122.3500), // Napa / Oakville / Sonoma
      defaultZoom: 9.2,
      aliases: [
        'napa', 'napa valley', 'sonoma', 'oakville', 'rutherford', 'stags leap', 'carneros',
        'russian river', 'alexander valley', 'willamette', 'willamette valley', 'oregon',
        'columbia valley', 'washington', 'paso robles', 'santa barbara'
      ],
      description: 'L\'icône mondiale des Cabernets opulents de Napa Valley et la finesse bourguignonne des Pinots Noirs de Willamette Valley en Oregon.',
      soilType: 'Sédiments alluviaux de fond de vallée, cendres volcaniques de collines et graves',
      climate: 'Méditerranéen tempéré par les brouillards matinaux venus du Pacifique (San Pablo Bay)',
      keyGrapes: 'Cabernet Sauvignon, Pinot Noir, Chardonnay, Zinfandel',
      classification: 'AVA (American Viticultural Area)',
    ),
    TerroirGISNode(
      id: 'ar_mendoza_andes',
      name: 'Argentine — Mendoza (Uco Valley & Luján)',
      region: 'Mendoza & Cuyo',
      country: 'Argentine',
      countryCode: 'AR',
      flag: '🇦🇷',
      center: LatLng(-33.4500, -69.0500), // Valle de Uco / Mendoza
      defaultZoom: 9.0,
      aliases: [
        'mendoza', 'valle de uco', 'uco valley', 'gualtallary', 'luján de cuyo', 'lujan de cuyo',
        'malbec', 'salta', 'cafayate', 'torrontes', 'patagonia', 'san juan'
      ],
      description: 'La viticulture de haute altitude au pied des Andes (900m à 1500m). Luminosité exceptionnelle et amplitudes thermiques forgeant des Malbecs d\'une couleur et fraîcheur incomparables.',
      soilType: 'Alluvions sableuses caillouteuses et dépôts calcaires des glaciers andins',
      climate: 'Semi-aride désertique tempéré par l\'altitude et l\'eau de fonte des glaciers',
      keyGrapes: 'Malbec (roi absolu), Cabernet Franc, Torrontés, Bonarda',
      classification: 'Indicación Geográfica (IG Gualtallary, Paraje Altamira...)',
    ),
    TerroirGISNode(
      id: 'cl_chile_valleys',
      name: 'Chili — Vallées du Maipo & Colchagua',
      region: 'Valle Central',
      country: 'Chili',
      countryCode: 'CL',
      flag: '🇨🇱',
      center: LatLng(-34.2000, -71.0000), // Colchagua / Maipo
      defaultZoom: 9.0,
      aliases: ['chile', 'chili', 'maipo', 'colchagua', 'casablanca', 'leyda', 'carménère', 'carmenere', 'aconcagua', 'maule'],
      description: 'Sanctuaire viticole indemne du phylloxéra (vignes non greffées). Berceau moderne du Carménère bordelais redécouvert et de Cabernets racés.',
      soilType: 'Alluvions graveleuses côtières et dépôts granitiques',
      climate: 'Méditerranéen régulé par le courant froid de Humboldt et la brise des Andes',
      keyGrapes: 'Carménère, Cabernet Sauvignon, Syrah, Sauvignon Blanc',
      classification: 'DO Vinos de Chile (Entre Cordilleras, Costa, Andes)',
    ),
    TerroirGISNode(
      id: 'au_nz_oceania',
      name: 'Océanie — Australie & Nouvelle-Zélande',
      region: 'Australasia',
      country: 'Australie / NZ',
      countryCode: 'AU',
      flag: '🇦🇺',
      center: LatLng(-34.5000, 139.0000), // Barossa / Adelaide
      defaultZoom: 8.0,
      aliases: [
        'australia', 'australie', 'barossa', 'barossa valley', 'mclaren vale', 'coonawarra',
        'yarra valley', 'margaret river', 'hunter valley', 'new zealand', 'nouvelle-zélande',
        'marlborough', 'central otago', 'hawke\'s bay', 'shiraz'
      ],
      description: 'Vignes centenaires de Shiraz de Barossa Valley, Cabernets raffinés de Margaret River et Sauvignons aromatiques éclatants de Marlborough.',
      soilType: 'Terres rouges sur calcaire (Terra Rossa de Coonawarra), schistes et sols alluviaux',
      climate: 'Océanique frais en Nouvelle-Zélande et Méditerranéen chaud en Australie Méridionale',
      keyGrapes: 'Shiraz (Syrah), Cabernet Sauvignon, Sauvignon Blanc, Pinot Noir',
      classification: 'GI (Geographical Indications)',
    ),
    TerroirGISNode(
      id: 'za_stellenbosch_cape',
      name: 'Afrique du Sud — Stellenbosch & Cap Occidental',
      region: 'Western Cape',
      country: 'Afrique du Sud',
      countryCode: 'ZA',
      flag: '🇿🇦',
      center: LatLng(-33.9300, 18.8600), // Stellenbosch / Franschhoek / Paarl
      defaultZoom: 10.0,
      aliases: [
        'south africa', 'afrique du sud', 'stellenbosch', 'franschhoek', 'paarl', 'swartland',
        'constantia', 'walker bay', 'hemel-en-aarde', 'pinotage', 'chenin blanc', 'steen'
      ],
      description: 'Tradition viticole tricentenaire nichée dans un amphithéâtre montagneux grandiose. Grands Chenins (Steen), Pinotage et assemblages bordelais de classe mondiale.',
      soilType: 'Granits décomposés très anciens, grès de la Montagne de la Table',
      climate: 'Méditerranéen rafraîchi par le vent marin « Cape Doctor » venu de l\'Antarctique',
      keyGrapes: 'Chenin Blanc (Steen), Pinotage, Cabernet Sauvignon, Syrah',
      classification: 'WO (Wine of Origin)',
    ),
  ];
}
