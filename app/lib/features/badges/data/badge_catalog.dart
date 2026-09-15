import '../domain/badge.dart';

class BadgeCatalog {
  BadgeCatalog._();

  static const List<WineBadge> allBadges = [
    // ==========================================
    // 🏛️ PALIERS DE CAVE & PROGRESSION
    // ==========================================
    WineBadge(
      id: 'milestone_bottles_10',
      title: 'Première Réserve (10 vins)',
      titleEn: 'First Reserve (10 Wines)',
      emoji: '🍷',
      assetImagePath: 'assets/badges/milestone_bottles_10.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.bronze,
      description: 'Avoir au moins 10 bouteilles en stock dans sa cave.',
      descriptionEn: 'Have at least 10 bottles stocked in your cellar.',
      chatmelierLore:
          '« Dix flacons sélectionnés avec discernement : c\'est le premier pas officiel vers la constitution d\'une cave structurée. Vous disposez désormais de quoi improviser un beau dîner entre amis sans jamais être pris au dépourvu. »',
      chatmelierLoreEn:
          '« Ten bottles thoughtfully selected: the very first official milestone toward building a true cellar reserve. »',
      requiredCount: 10,
    ),
    WineBadge(
      id: 'milestone_bottles_50',
      title: 'Cave d\'Amateur (50 vins)',
      titleEn: 'Connoisseur Cellar (50 Wines)',
      emoji: '🍾',
      assetImagePath: 'assets/badges/milestone_bottles_50.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.silver,
      description: 'Avoir au moins 50 bouteilles en stock dans sa cave.',
      descriptionEn: 'Have at least 50 bottles stocked in your cellar.',
      chatmelierLore:
          '« Avec cinquante bouteilles, votre cave commence véritablement à respirer : vous avez des vins de plaisir immédiat pour les tablées spontanées, des cuvées de garde qui s\'affinent patiemment dans l\'obscurité, et une palette de terroirs adaptée à chaque accord mets-vins. »',
      requiredCount: 50,
    ),
    WineBadge(
      id: 'milestone_bottles_100',
      title: 'Cave de Passionné (100 vins)',
      titleEn: 'Collector Cellar (100 Wines)',
      emoji: '🏰',
      assetImagePath: 'assets/badges/milestone_bottles_100.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.gold,
      description: 'Avoir au moins 100 bouteilles en stock dans sa cave.',
      descriptionEn: 'Have at least 100 bottles stocked in your cellar.',
      chatmelierLore:
          '« Le cap du siècle de flacons ! Votre cave devient une collection vivante où se côtoient grands crus, pépites d\'artisans vignerons et millésimes d\'anthologie. Le Chatmelier salue une gestion rigoureuse et une passion affirmée pour les beaux terroirs. »',
      requiredCount: 100,
    ),
    WineBadge(
      id: 'milestone_bottles_500',
      title: 'Cave Patrimoniale (500 vins)',
      titleEn: 'Heritage Cellar (500 Wines)',
      emoji: '🏛️',
      assetImagePath: 'assets/badges/milestone_bottles_500.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.diamond,
      description: 'Avoir au moins 500 bouteilles en stock dans sa cave.',
      descriptionEn: 'Have at least 500 bottles stocked in your cellar.',
      chatmelierLore:
          '« Cinq cents flacons sous surveillance hygrométrique constante. Vous possédez une réserve digne des plus belles cartes de sommellerie. Vos grands vins de longue garde traverseront les décennies pour offrir des moments d\'émotion inoubliables. »',
      requiredCount: 500,
    ),
    WineBadge(
      id: 'milestone_bottles_1000',
      title: 'Grande Réserve Historique (1000 vins)',
      titleEn: 'Grand Historic Reserve (1000 Wines)',
      emoji: '👑',
      assetImagePath: 'assets/badges/milestone_bottles_1000.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.diamond,
      description: 'Atteindre le sommet prestigieux des 1000 bouteilles en cave.',
      descriptionEn: 'Reach the pinnacle of 1000 bottles in your cellar.',
      chatmelierLore:
          '« Mille flacons ! Vous êtes le conservateur d\'une véritable bibliothèque œnologique vivante. Chaque bouteille y témoigne d\'un climat, d\'un millésime et du travail d\'une vie de vigneron. Un accomplissement magistral salué par le Chatmelier ! »',
      requiredCount: 1000,
    ),

    // --- Paliers de Dégustation ---
    WineBadge(
      id: 'milestone_tastings_5',
      title: 'Première Goulée (5 notes)',
      titleEn: 'First Sip (5 Tastings)',
      emoji: '🍷',
      assetImagePath: 'assets/badges/milestone_tastings_5.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.bronze,
      description: 'Avoir enregistré au moins 5 fiches de dégustation.',
      descriptionEn: 'Record at least 5 tasting reviews.',
      chatmelierLore:
          '« L\'apprentissage du vin commence par la première note attentive. En consignant vos 5 premières dégustations, vous commencez à structurer votre mémoire sensorielle : appréciation de la robe, intensité olfactive, équilibre des tanins et persistance en bouche. »',
      requiredCount: 5,
    ),
    WineBadge(
      id: 'milestone_tastings_25',
      title: 'Palais Affûté (25 notes)',
      titleEn: 'Sharpened Palate (25 Tastings)',
      emoji: '👃',
      assetImagePath: 'assets/badges/milestone_tastings_25.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.silver,
      description: 'Avoir enregistré au moins 25 fiches de dégustation.',
      descriptionEn: 'Record at least 25 tasting reviews.',
      chatmelierLore:
          '« Vingt-cinq cuvées passées au crible ! Votre vocabulaire s\'enrichit. Vous distinguez désormais avec aisance les arômes primaires (le cépage), secondaires (la fermentation et les levures) et tertiaires (l\'élevage en barrique et le vieillissement en bouteille). »',
      requiredCount: 25,
    ),
    WineBadge(
      id: 'milestone_tastings_50',
      title: 'Sommelier Amateur (50 notes)',
      titleEn: 'Amateur Sommelier (50 Tastings)',
      emoji: '📜',
      assetImagePath: 'assets/badges/milestone_tastings_50.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.gold,
      description: 'Avoir consigné au moins 50 dégustations dans son carnet.',
      descriptionEn: 'Log at least 50 tastings in your journal.',
      chatmelierLore:
          '« Cinquante dégustations documentées avec méthode ! Votre esprit critique est affûté : vous décelez les défauts comme les éclats de génie, et vos proches se tournent volontiers vers vos recommandations pour choisir les bouteilles à table. »',
      requiredCount: 50,
    ),
    WineBadge(
      id: 'milestone_tastings_100',
      title: 'Grand Dégustateur (100 notes)',
      titleEn: 'Grand Taster (100 Tastings)',
      emoji: '🏆',
      assetImagePath: 'assets/badges/milestone_tastings_100.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.diamond,
      description: 'Avoir consigné au moins 100 dégustations dans son carnet.',
      descriptionEn: 'Log at least 100 tastings in your journal.',
      chatmelierLore:
          '« Cent dégustations enregistrées ! Votre journal est un carnet de route précieux. De l\'attaque en bouche à la longueur mesurée en caudalies, vous décryptez le vin avec l\'assurance d\'un sommelier chevronné. »',
      requiredCount: 100,
    ),
    WineBadge(
      id: 'milestone_tastings_250',
      title: 'Maître de Dégustation (250 notes)',
      titleEn: 'Master of Tasting (250 Tastings)',
      emoji: '🔮',
      assetImagePath: 'assets/badges/milestone_tastings_250.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.diamond,
      description: 'Avoir franchi le palier remarquable des 250 dégustations.',
      descriptionEn: 'Surpass the landmark of 250 tastings.',
      chatmelierLore:
          '« Deux cent cinquante crus analysés ! Vous appartenez au cercle des dégustateurs confirmés. À l\'aveugle ou carafé, jeune ou évolué, aucun vin ne résiste à votre sagacité sensorielle. »',
      requiredCount: 250,
    ),

    // ==========================================
    // 🌍 CONTINENTS & EXPLORATION
    // ==========================================
    WineBadge(
      id: 'continent_old_world',
      title: 'Le Vieux Monde',
      titleEn: 'The Old World',
      emoji: '🏰',
      assetImagePath: 'assets/badges/continent_old_world.webp',
      category: BadgeCategory.continents,
      tier: BadgeTier.bronze,
      description: 'Déguster au moins 3 vins européens (France, Italie, Espagne, Portugal, etc.).',
      descriptionEn: 'Taste wines from the historic European vineyard terroirs.',
      chatmelierLore:
          '« L\'Europe a forgé le concept moderne de "terroir" : l\'alchimie indissoluble entre géologie, microclimat et savoir-faire vigneron ancestral. Des coteaux du Rhin aux terrasses du Douro, c\'est ici que la vigne Vitis vinifera a écrit ses lettres de noblesse. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'continent_new_world',
      title: 'Le Nouveau Monde',
      titleEn: 'The New World',
      emoji: '🌎',
      assetImagePath: 'assets/badges/continent_new_world.webp',
      category: BadgeCategory.continents,
      tier: BadgeTier.silver,
      description: 'Déguster au moins 2 vins hors-Europe (USA, Chili, Argentine, Australie, Afrique du Sud...).',
      descriptionEn: 'Taste wines from the Americas, Oceania, or South Africa.',
      chatmelierLore:
          '« Des brumes marines de la Napa Valley aux contreforts des Andes argentines, le Nouveau Monde a renouvelé les approches traditionnelles par l\'éclat du fruit mûr, la précision technologique et une liberté variétale sans complexe. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'continent_globe_trotter',
      title: 'Tour du Monde en 80 Verres',
      titleEn: 'Around the World in 80 Glasses',
      emoji: '✈️',
      assetImagePath: 'assets/badges/continent_globe_trotter.webp',
      category: BadgeCategory.continents,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté des vins provenant d\'au moins 5 pays différents.',
      descriptionEn: 'Cellar and taste bottles from multiple diverse wine countries.',
      chatmelierLore:
          '« La vigne s\'épanouit aujourd\'hui du 30e au 50e parallèle dans les deux hémisphères. Déguster cinq pays différents démontre une curiosité sans frontières, toujours prêt à découvrir un cépage méconnu et un terroir singulier. »',
      requiredCount: 5,
    ),
    WineBadge(
      id: 'continent_explorer',
      title: 'Explorateur des Terroirs',
      titleEn: 'Terroir Explorer',
      emoji: '🧭',
      assetImagePath: 'assets/badges/continent_explorer.webp',
      category: BadgeCategory.continents,
      tier: BadgeTier.gold,
      description: 'Avoir dégusté des vins provenant d\'au moins 10 pays différents.',
      descriptionEn: 'Explore wine regions from 4 different continents.',
      chatmelierLore:
          '« Dix nations viticoles explorées ! Du Liban à la Nouvelle-Zélande en passant par la Géorgie et l\'Afrique du Sud, vous expérimentez la diversité des styles et des cultures viticoles à travers le monde. »',
      requiredCount: 10,
    ),
    WineBadge(
      id: 'continent_universal',
      title: 'Atlas Universel des Vins',
      titleEn: 'Universal Wine Atlas',
      emoji: '🌌',
      assetImagePath: 'assets/badges/continent_universal.webp',
      category: BadgeCategory.continents,
      tier: BadgeTier.diamond,
      description: 'Avoir dégusté des vins issus d\'au moins 20 pays différents.',
      descriptionEn: 'Possess bottles originating from all major winemaking continents.',
      chatmelierLore:
          '« Vingt pays ! Votre curiosité œnologique égale celle des plus grands explorateurs. Vous avez goûté des crus sous toutes les latitudes et sur tous les continents. Un exploit encyclopédique rare et inspirant ! »',
      requiredCount: 20,
    ),

    // ==========================================
    // 🏳️ PAYS
    // ==========================================
    WineBadge(
      id: 'country_france',
      title: 'Hexagone Gourmand',
      titleEn: 'Gourmet Hexagon 🇫🇷',
      emoji: '🇫🇷',
      assetImagePath: 'assets/badges/country_france.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.bronze,
      description: 'Avoir au moins 3 vins français dans sa cave ou son carnet.',
      descriptionEn: 'Stock or taste renowned wines from France.',
      chatmelierLore:
          '« Avec plus de 360 Appellations d\'Origine Contrôlée (AOC), la France est une mosaïque géologique sans équivalent : craie de Champagne, galets roulés du Rhône, schistes d\'Anjou ou calcaires bourguignons. Une référence incontournable de la gastronomie mondiale. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'country_italy',
      title: 'La Dolce Vita',
      titleEn: 'La Dolce Vita 🇮🇹',
      emoji: '🇮🇹',
      assetImagePath: 'assets/badges/country_italy.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou possédé au moins 2 vins d\'Italie (Chianti, Barolo, Prosecco...).',
      descriptionEn: 'Savor Italian wines from Piedmont, Tuscany, Veneto or Sicily.',
      chatmelierLore:
          '« Les Grecs anciens la baptisèrent "Oenotria", la terre du vin. L\'Italie abrite plus de 500 cépages autochtones jalousement préservés, du Sangiovese toscan au Nebbiolo piémontais, offrant une acidité gastronomique inimitable taillée pour la table. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'country_spain',
      title: 'Ferveur Ibérique',
      titleEn: 'Iberian Fervor 🇪🇸',
      emoji: '🇪🇸',
      assetImagePath: 'assets/badges/country_spain.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou possédé au moins 2 vins espagnols (Rioja, Priorat, Ribera del Duero...).',
      descriptionEn: 'Experience the passion of Spanish wines from Rioja, Priorat, or Ribera.',
      chatmelierLore:
          '« L\'Espagne possède le plus vaste vignoble de la planète par sa surface. Ses élevages patients en fûts de chêne (Crianza, Reserva, Gran Reserva) et ses terroirs de schiste (Llicorella du Priorat) offrent des vins profonds, complexes et élégants. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'country_usa',
      title: 'Rêve Californien',
      titleEn: 'Californian Dream 🇺🇸',
      emoji: '🇺🇸',
      assetImagePath: 'assets/badges/country_usa.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou possédé au moins 1 vin des États-Unis (Napa, Sonoma, Oregon, Washington...).',
      descriptionEn: 'Taste prominent American wines from Napa, Sonoma, or Oregon.',
      chatmelierLore:
          '« Le Jugement de Paris de 1976 a marqué l\'histoire moderne : lors d\'une dégustation à l\'aveugle mythique, les Cabernets et Chardonnays de Californie rivalisèrent avec les plus prestigieux Premiers Grands Crus, propulsant le vignoble américain sur le devant de la scène mondiale. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_portugal',
      title: 'Légende du Douro',
      titleEn: 'Douro Legend 🇵🇹',
      emoji: '🇵🇹',
      assetImagePath: 'assets/badges/country_portugal.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou possédé au moins 1 vin du Portugal (Douro, Alentejo, Porto, Dão...).',
      descriptionEn: 'Taste Port or great dry wines from Portugal.',
      chatmelierLore:
          '« Délimitée en 1756 par le marquis de Pombal, la vallée du Douro est la plus ancienne région viticole protégée au monde. Ses terrasses escarpées de schiste sculptées à flanc de colline plongent dans le fleuve pour donner des Portos de légende et des rouges d\'une grande distinction. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🏰 RÉGIONS
    // ==========================================
    WineBadge(
      id: 'region_bourgogne',
      title: 'Duc de Bourgogne',
      titleEn: 'Duke of Burgundy',
      emoji: '👑',
      assetImagePath: 'assets/badges/region_bourgogne.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 3 vins de Bourgogne.',
      descriptionEn: 'Cellar or taste fine Pinot Noir or Chardonnay from Burgundy.',
      chatmelierLore:
          '« En Bourgogne, le sol change tous les cinquante mètres. Les "Climats", ces parcelles minutieusement délimitées depuis un millénaire et inscrites au patrimoine de l\'UNESCO, subliment le Pinot Noir et le Chardonnay avec une finesse inégalée. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'region_bordeaux',
      title: 'Seigneur de Bordeaux',
      titleEn: 'Lord of Bordeaux',
      emoji: '🏛️',
      assetImagePath: 'assets/badges/region_bordeaux.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 3 vins de Bordeaux (Médoc, Saint-Émilion, Pomerol, Graves...).',
      descriptionEn: 'Taste wines from Médoc, Graves, Saint-Émilion, or Pomerol.',
      chatmelierLore:
          '« Le classement impérial de 1855, commandé par Napoléon III, régit toujours la hiérarchie des Premiers Grands Crus du Médoc et de Sauternes. Entre graves garonnaises et argiles bleues de Pomerol, Bordeaux incarne l\'art souverain de l\'assemblage millimétré. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'region_rhone',
      title: 'Chevalier du Rhône',
      titleEn: 'Knight of the Rhône',
      emoji: '⚔️',
      assetImagePath: 'assets/badges/region_rhone.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de la Vallée du Rhône.',
      descriptionEn: 'Savor northern or southern Rhône Valley crus.',
      chatmelierLore:
          '« Du granite escarpé de Côte-Rôtie jusqu\'aux galets roulés gorgés de chaleur à Châteauneuf-du-Pape, le Rhône allie la tension poivrée de la Syrah septentrionale à la générosité solaire du Grenache méridional. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_champagne',
      title: 'Chasseur d\'Étoiles',
      titleEn: 'Bubble Hunter 🍾',
      emoji: '🍾',
      assetImagePath: 'assets/badges/region_champagne.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 2 champagnes ou vins effervescents de méthode traditionnelle.',
      descriptionEn: 'Taste authentic Champagne from Montagne de Reims or Côte des Blancs.',
      chatmelierLore:
          '« "Venez vite, je bois des étoiles !" La tradition attribue cette formule à Dom Pérignon à l\'abbaye d\'Hautvillers. L\'effervescence naturelle née de la prise de mousse en bouteille et la fraîcheur des craies jurassiques signent le vin de fête absolu. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_loire',
      title: 'Poète du Val de Loire',
      titleEn: 'Loire Valley Poet',
      emoji: '🌿',
      assetImagePath: 'assets/badges/region_loire.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de la Loire (Sancerre, Chinon, Saumur, Vouvray...).',
      descriptionEn: 'Taste crystalline Chenin or Cabernet Franc from the Royal River.',
      chatmelierLore:
          '« Fleuve royal bordé de châteaux Renaissance, la Loire déploie des vins d\'une fraîcheur cristalline grâce à la pierre de tuffeau blanc et son climat tempéré. Chenin blanc et Cabernet franc y trouvent leur expression la plus pure et digeste. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_alsace',
      title: 'Sentinelle Rhénane',
      titleEn: 'Rhenish Sentinel',
      emoji: '🥨',
      assetImagePath: 'assets/badges/region_alsace.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins d\'Alsace.',
      descriptionEn: 'Taste Grand Cru Riesling, Pinot Gris, or Gewurztraminer from Alsace.',
      chatmelierLore:
          '« Abrité des pluies océaniques par les Vosges, le vignoble d\'Alsace bénéficie d\'un climat sec et ensoleillé propice à une remarquable maturité phénolique. La pureté de ses cépages nobles (Riesling, Gewurztraminer, Pinot Gris) s\'exprime sur des terroirs géologiques d\'une grande diversité. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_provence',
      title: 'Soleil de Provence',
      titleEn: 'Provence Sunshine',
      emoji: '🌸',
      assetImagePath: 'assets/badges/region_provence.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.bronze,
      description: 'Posséder ou avoir dégusté au moins 2 vins de Provence ou Corse (Bandol, Cassis, Bellet, Patrimonio...).',
      descriptionEn: 'Taste mineral rosés or aged reds from Bandol and Provence.',
      chatmelierLore:
          '« C\'est ici que les Phocéens fondèrent Marseille en 600 av. J.-C. et développèrent la viticulture. Des grands rouges de garde de Bandol dominés par le noble Mourvèdre aux rosés salins et pâles de gastronomie, la Provence respire le terroir méditerranéen. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_jura_savoie',
      title: 'L\'Or Jaune & Alpin',
      titleEn: 'Alpine Mystery',
      emoji: '🏔️',
      assetImagePath: 'assets/badges/region_jura_savoie.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 vin du Jura ou de Savoie (Vin Jaune, Savagnin, Mondeuse, Chignin...).',
      descriptionEn: 'Savor unique wines from Jura or alpine slopes of Savoie.',
      chatmelierLore:
          '« Le Vin Jaune jurassien vieillit patiemment 6 ans et 3 mois en fûts de chêne sans ouillage, sous un voile biologique naturel de levures indigènes. Cet élevage oxydatif engendre la molécule de sotolon aux arômes intenses de noix sèche, de curry et d\'épices nobles. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🍇 CÉPAGES
    // ==========================================
    WineBadge(
      id: 'grape_pinot_noir',
      title: 'Roi du Pinot Noir',
      titleEn: 'King Pinot Noir',
      emoji: '🍒',
      assetImagePath: 'assets/badges/grape_pinot_noir.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 cuvées à dominante Pinot Noir.',
      descriptionEn: 'Taste iconic Pinot Noir vintages.',
      chatmelierLore:
          '« Cépage délicat et exigeant à la pellicule fine, le Pinot Noir demande un soin méticuleux à la vigne et au chai. Sur les coteaux calcaires, il livre des arômes subtils de griotte, de rose séchée et de sous-bois d\'une élégance rare. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_cabernet',
      title: 'Maître du Cabernet',
      titleEn: 'Master of Cabernet',
      emoji: '🍇',
      assetImagePath: 'assets/badges/grape_cabernet.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 cuvées à dominante Cabernet Sauvignon.',
      descriptionEn: 'Taste robust and structured Cabernet Sauvignon wines.',
      chatmelierLore:
          '« Issu d\'un croisement historique entre le Cabernet Franc et le Sauvignon Blanc, le Cabernet Sauvignon est l\'épine dorsale des grands vins de longue garde grâce à sa trame tannique ferme et ses notes nobles de cassis, cèdre et boîte à cigares. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_chardonnay',
      title: 'Reine du Chardonnay',
      titleEn: 'Queen Chardonnay',
      emoji: '🥂',
      assetImagePath: 'assets/badges/grape_chardonnay.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 cuvées à dominante Chardonnay.',
      descriptionEn: 'Taste elegant white wines crafted from Chardonnay.',
      chatmelierLore:
          '« Véritable caméléon de la viticulture mondiale : tendu, minéral et salin sur les calcaires kimméridgiens de Chablis, il se révèle riche, beurré et brioché lorsqu\'il est élevé sur lies en fûts de chêne à Meursault ou dans les vallées californiennes. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_syrah',
      title: 'Mystique de la Syrah',
      titleEn: 'Mystic Syrah',
      emoji: '🌶️',
      assetImagePath: 'assets/badges/grape_syrah.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 cuvées à dominante Syrah (Shiraz).',
      descriptionEn: 'Taste peppery and powerful Syrah/Shiraz wines.',
      chatmelierLore:
          '« Sa signature aromatique provient de la molécule de rotondone présente dans la pellicule du raisin. C\'est elle qui confère à la Syrah cette note reconnaissable de poivre noir fraîchement moulu, mêlée à la violette et à l\'olive noire. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_chenin',
      title: 'Alchimiste du Chenin',
      titleEn: 'Chenin Alchemist',
      emoji: '🍯',
      assetImagePath: 'assets/badges/grape_chenin.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.gold,
      description: 'Déguster ou avoir en cave au moins 1 vin issu du cépage Chenin Blanc.',
      descriptionEn: 'Taste versatile, acidic, and age-worthy Chenin Blanc.',
      chatmelierLore:
          '« L\'un des cépages blancs les plus complets au monde. Du blanc sec minéral et tranchant aux fines bulles, jusqu\'aux grands liquoreux centenaires de Loire, le Chenin traverse les décennies soutenu par une remarquable acidité naturelle. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'grape_riesling',
      title: 'Cristal de Riesling',
      titleEn: 'Riesling Crystal',
      emoji: '💎',
      assetImagePath: 'assets/badges/grape_riesling.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 1 Riesling.',
      descriptionEn: 'Taste razor-sharp and mineral Riesling wines.',
      chatmelierLore:
          '« Le Riesling exprime la typicité de son sol sans artifice de bois neuf. En évoluant, il développe des nuances aromatiques fascinantes (TDN) d\'agrumes confits, de fleurs blanches et de fines notes minérales très appréciées des connaisseurs. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'grape_nebbiolo',
      title: 'Seigneur des Brumes',
      titleEn: 'Lord of the Mists',
      emoji: '🌫️',
      assetImagePath: 'assets/badges/grape_nebbiolo.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.gold,
      description: 'Déguster ou posséder au moins 1 vin à base de Nebbiolo (Barolo, Barbaresco...).',
      descriptionEn: 'Taste Barolo or Barbaresco made from tannic Nebbiolo.',
      chatmelierLore:
          '« Son nom évoque la "nebbia", la brume d\'automne qui enveloppe les collines piémontaises lors des vendanges d\'octobre. Sa robe rubis translucide cache une charpente tannique puissante et des arômes envoûtants de rose ancienne, goudron noble et truffe blanche. »',
      requiredCount: 1,
    ),

    // ==========================================
    // ⏳ GARDE & APOGÉE
    // ==========================================
    WineBadge(
      id: 'aging_peak',
      title: 'L\'Apogée Parfaite',
      titleEn: 'Golden Peak',
      emoji: '🎯',
      assetImagePath: 'assets/badges/aging_peak.webp',
      category: BadgeCategory.aging,
      tier: BadgeTier.gold,
      description: 'Avoir dégusté un vin exactement dans sa fenêtre d\'apogée optimale.',
      descriptionEn: 'Taste a bottle perfectly at its optimal drinking window.',
      chatmelierLore:
          '« Déguster un vin à son apogée, c\'est saisir l\'équilibre idéal où les tanins se sont veloutés tandis que le bouquet tertiaire exhale toute sa complexité. Félicitations pour ce sens du timing exemplaire ! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'aging_venerable',
      title: 'Flacon Vénérable',
      titleEn: 'Venerable Bottle',
      emoji: '🕰️',
      assetImagePath: 'assets/badges/aging_venerable.webp',
      category: BadgeCategory.aging,
      tier: BadgeTier.diamond,
      description: 'Déguster ou posséder en cave une bouteille âgée de 25 ans ou plus.',
      descriptionEn: 'Taste a wine aged for more than 20 years.',
      chatmelierLore:
          '« Ouvrir une bouteille de plus d\'un quart de siècle, c\'est découvrir un pan d\'histoire liquide. La robe s\'est parée de reflets ambrés, le fruit s\'est mué en cuir noble, thé noir et sous-bois. Un grand moment de dégustation. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'aging_infanticide',
      title: 'Infanticide Œnologique',
      titleEn: 'Oenological Infanticide 👶',
      emoji: '👶',
      assetImagePath: 'assets/badges/aging_infanticide.webp',
      category: BadgeCategory.aging,
      tier: BadgeTier.bronze,
      description: 'Avoir bu un grand vin de garde avec plus de 5 ans d\'avance sur son apogée.',
      descriptionEn: 'Open a grand vin far too young before its true potential awakens.',
      chatmelierLore:
          '« Les tanins étaient encore un peu fermes et serrés, n\'est-ce pas ? Goûter un grand vin dans sa prime jeunesse est une expérience instructive que tout amateur réalise un jour pour appréhender le potentiel d\'évolution. »',
      requiredCount: 1,
    ),


    // ==========================================
    // 🥃 SPIRITUEUX & ALCOOLS FORTS
    // ==========================================
    WineBadge(
      id: 'spirit_whisky',
      title: 'Gentleman du Malt',
      titleEn: 'Malt Gentleman',
      emoji: '🥃',
      assetImagePath: 'assets/badges/spirit_whisky.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 Whisky (Single Malt, Bourbon, Tourbé...).',
      descriptionEn: 'Taste Scotch single malt, Bourbon, or Rye whisky.',
      chatmelierLore:
          '« De la tourbe fumée des distilleries d\'Islay aux fûts de chêne neuf brûlés du Kentucky, le whisky illustre le mariage séculaire entre le grain malté, l\'eau pure et le temps passé sous bois. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_gin',
      title: 'Botaniste de l\'Alambic',
      titleEn: 'Botanist of the Still',
      emoji: '🌿',
      assetImagePath: 'assets/badges/spirit_gin.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.bronze,
      description: 'Posséder ou avoir dégusté au moins 1 Gin.',
      descriptionEn: 'Taste London Dry or artisanal craft gin infused with juniper.',
      chatmelierLore:
          '« Né aux Pays-Bas sous le nom de Genever comme remède médicinal, le gin distille les baies de genièvre (Juniperus communis), la graine de coriandre et les écorces d\'agrumes par infusion vapeur. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_rhum',
      title: 'Élixir de Canne',
      titleEn: 'Cane Elixir',
      emoji: '🦜',
      assetImagePath: 'assets/badges/spirit_rhum.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 Rhum (agricole ou mélasse).',
      descriptionEn: 'Taste traditional or agricultural rum distilled from sugar cane.',
      chatmelierLore:
          '« Pur jus de canne fraîche en Martinique (AOC Rhum Agricole) ou distillation de mélasse en alambics à repasse en Jamaïque : le rhum offre une palette aromatique chaleureuse de fruits exotiques et de vanille. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_amaretto_italian',
      title: 'Dolce Vita Amaretto',
      titleEn: 'Dolce Vita Amaretto',
      emoji: '🌰',
      assetImagePath: 'assets/badges/spirit_amaretto_italian.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Ajouter ou posséder une authentique liqueur d\'amaretto (ou Disaronno).',
      descriptionEn: 'Add or own an authentic amaretto liqueur (or Disaronno).',
      chatmelierLore:
          '« Né à Saronno, berceau des amandes douces et amères macérées dans l\'alcool fin. Une liqueur veloutée, réputée depuis la Renaissance italienne pour sa gourmandise inimitable. »',
      chatmelierLoreEn:
          '« Born in Saronno, home to sweet and bitter almonds steeped in fine spirits. A velvet liqueur celebrated since the Italian Renaissance. »',
    ),
    WineBadge(
      id: 'spirit_fill_vigilant',
      title: 'Le Dernier Trait',
      titleEn: 'The Final Measure',
      emoji: '🥃',
      assetImagePath: 'assets/badges/spirit_fill_vigilant.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.bronze,
      description: 'Surveiller le niveau de remplissage d\'un spiritueux arrivant au dernier quart.',
      descriptionEn: 'Monitor the fill level of a spirit bottle down to its final quarter.',
      chatmelierLore:
          '« La jauge s\'abaisse, révélant la patine du flacon. Un bon sommelier sait exactement quand son flacon touche à sa fin pour préparer le prochain réapprovisionnement. »',
      chatmelierLoreEn:
          '« The fill gauge lowers, revealing the bottle\'s age. A wise sommelier tracks every measure before the final pour. »',
    ),
    WineBadge(
      id: 'spirit_brandy',
      title: 'Noblesse Charentaise',
      titleEn: 'Charentais Nobility',
      emoji: '🍇',
      assetImagePath: 'assets/badges/spirit_brandy.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 Cognac ou Armagnac.',
      descriptionEn: 'Taste fine Cognac, Armagnac, or wine brandy.',
      chatmelierLore:
          '« La double distillation en alambic charentais à repasse concentre la finesse du vin d\'Ugni Blanc. Les longues années passées en fûts de chêne du Limousin donnent naissance à la fameuse part des anges et au bouquet de rancio. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 💩 BADGES "LOOSER" & AUTODÉRISION
    // ==========================================
    WineBadge(
      id: 'looser_piquette',
      title: 'Piquette de Compète 🏆',
      titleEn: 'Top-Tier Cheap Wine 🏆',
      emoji: '🪣',
      assetImagePath: 'assets/badges/looser_piquette.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Avoir ajouté ou dégusté un vin payé moins de 3 €.',
      descriptionEn: 'Added or tasted a bottle priced under 3 €.',
      chatmelierLore:
          '« À ce prix d\'aubaine, la bouteille en verre et le bouchon coûtent parfois plus cher que le vin lui-même ! Mais qui n\'a jamais fait ses armes sur une cuvée d\'épicerie de quartier à 2,49 € pour un barbecue improvisé ? Une dégustation sans snobisme ! »',
      chatmelierLoreEn:
          '« At that bargain price, the glass bottle and cork sometimes cost more than the wine itself! But who hasn\'t enjoyed an unpretentious €2.49 bottle at an improvised BBQ? Wine enjoyment with zero snobbery! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_past_peak',
      title: 'Vinaigre Impérial 🏺',
      titleEn: 'Imperial Vinegar 🏺',
      emoji: '⚰️',
      assetImagePath: 'assets/badges/looser_past_peak.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.silver,
      description: 'Avoir bu un vin bien après son apogée (statut Passé).',
      descriptionEn: 'Drink a bottle that stayed in the cellar decades too long.',
      chatmelierLore:
          '« Oublié pendant une décennie au fond d\'un placard tiède... La robe tirait sur le madère sombre et le nez évoquait la pomme blette, mais vous l\'avez goûté par curiosité ! La science œnologique progresse aussi par l\'expérience. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_masochist',
      title: 'Masochiste du Terroir 🤢',
      titleEn: 'Terroir Masochist 🤢',
      emoji: '🦨',
      assetImagePath: 'assets/badges/looser_masochist.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Avoir attribué une note assassine (inférieure ou égale à 2/10 ou 1/5).',
      descriptionEn: 'Finish a bottle you utterly despised out of pure stubbornness.',
      chatmelierLore:
          '« Vin déviant ou jus sans âme ? Votre palais a été mis à rude épreuve, mais votre honnêteté critique évitera sans doute à vos proches une mauvaise surprise. Bravo pour votre franchise de dégustateur ! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_bouchonne',
      title: 'Bouchonné mais Vaillant 🪵',
      titleEn: 'Corked but Gallant 🪵',
      emoji: '🌳',
      assetImagePath: 'assets/badges/looser_bouchonne.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.silver,
      description: 'Avoir mentionné "bouchon" ou "bouchonné" dans une note de dégustation.',
      descriptionEn: 'Encounter a bottle tainted with TCA cork taint.',
      chatmelierLore:
          '« La redoutée molécule de 2,4,6-trichloroanisole (TCA) ! Cette odeur caractéristique de carton mouillé et de cave humide capable d\'altérer même le plus grand flacon à des concentrations infinitésimales. L\'aléa classique du bouchon de liège. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_solo',
      title: 'Le Fond de Bouteille 🍷',
      titleEn: 'The Lonely Dregs 🍷',
      emoji: '🕯️',
      assetImagePath: 'assets/badges/looser_solo.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Avoir enregistré une dégustation en tête-à-tête avec vous-même sans co-dégustateurs.',
      descriptionEn: 'Uncork and finish a fine bottle entirely alone on a quiet night.',
      chatmelierLore:
          '« Seul face à son verre en fin de journée pour observer les reflets de la robe et apprécier l\'évolution des arômes. Déguster en solitaire permet une analyse attentive et sereine sans distraction. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🔬 LE CHATMELIER SAVANT (Histoire, Science & Terroir)
    // ==========================================
    WineBadge(
      id: 'savant_pasteur',
      title: 'Le Chatmelier Pasteur 🔬',
      titleEn: 'The Pasteur Chatmelier 🔬',
      emoji: '🧪',
      assetImagePath: 'assets/badges/savant_pasteur.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin bio, biodynamique ou naturel avec mention de fermentation.',
      descriptionEn: 'Taste an organic, biodynamic or natural wine mentioning fermentation.',
      chatmelierLore:
          '« 🔬 SCIENCE & HISTOIRE DU CHATMELIER :\n\n'
          'En 1866, l\'empereur Napoléon III chargea personnellement Louis Pasteur d\'élucider les altérations du vin (aigreur, amertume, tourne) qui pénalisaient le vignoble français. Installé dans sa vigne d\'Arbois dans le Jura, Pasteur réfuta le dogme de Justus von Liebig qui prétendait que la fermentation n\'était qu\'une dégradation chimique inerte.\n\n'
          'Pasteur démontra que la fermentation alcoolique est un processus biologique accompli par des micro-organismes vivants : les levures (principalement Saccharomyces cerevisiae). Ces cellules anaérobies transforment les sucres du raisin (glucose et fructose, C6H12O6) en éthanol (2 C2H5OH) et en gaz carbonique (2 CO2), tout en produisant du glycérol et des esters aromatiques complexes.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Sans les travaux de Pasteur, la vinification moderne n\'existerait pas sous sa forme actuelle. Déguster un vin fermenté par ses levures indigènes est le plus bel hommage à la microbiologie qui transforme le raisin en nectar d\'exception. »',
      chatmelierLoreEn:
          '« 🔬 CHATMELIER SCIENCE & HISTORY :\n\n'
          'In 1866, Emperor Napoleon III personally tasked Louis Pasteur with investigating wine spoilages. Working in his Jura vineyard in Arbois, Pasteur proved that alcoholic fermentation is not an inert chemical degradation, but a living biological process executed by yeasts (Saccharomyces cerevisiae).\n\n'
          '🍷 CHATMELIER NOTE :\n'
          'Without Pasteur, modern winemaking would not exist in its present form. Savoring a wine fermented by its native yeasts is the finest tribute to the microbiology transforming humble grapes into sublime nectar. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_cistercien',
      title: 'Le Chatmelier Cistercien ⛪',
      titleEn: 'Cistercian Chatmelier ⛪',
      emoji: '📜',
      assetImagePath: 'assets/badges/savant_cistercien.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Posséder ou déguster un vin blanc ou rouge de Bourgogne issu d\'un sol calcaire.',
      descriptionEn: 'Honor medieval monastic monks who delimited the terroirs.',
      chatmelierLore:
          '« ⛪ HISTOIRE & GÉOLOGIE DU CHATMELIER :\n\n'
          'Fondé en 1098 par Robert de Molesme à Cîteaux, l\'ordre cistercien a profondément marqué l\'agronomie européenne. Les moines de Cîteaux ont défriché les coteaux de la Côte d\'Or et fondé en 1115 le Clos de Vougeot, ceinturé d\'un mur de pierre protecteur de 50 hectares.\n\n'
          'Par une observation attentive sur plusieurs générations, ces moines ont constaté que le vin variait sensiblement selon la pente, l\'exposition solaire et la nature des calcaires jurassiques bajociens et bathoniens. C\'est ainsi qu\'est née la délimitation parcellaire des "Climats" bourguignons, inscrite aujourd\'hui au patrimoine mondial de l\'UNESCO.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Les moines cisterciens avaient la rigueur des grands observateurs de la nature : ils ont démontré que la vigne n\'exprime sa plénitude que lorsqu\'elle puise ses nutriments au cœur de la roche calcaire. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_phylloxera',
      title: 'Le Chatmelier Phylloxérique 🐛',
      titleEn: 'Phylloxeric Chatmelier 🐛',
      emoji: '🔬',
      assetImagePath: 'assets/badges/savant_phylloxera.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Avoir au moins 5 bouteilles en cave issues de vignes greffées.',
      descriptionEn: 'Celebrate the grafting renaissance overcoming phylloxera.',
      chatmelierLore:
          '« 🐛 LA CRISE PHILLOXÉRIQUE DU XIXe SIÈCLE :\n\n'
          'À l\'été 1863 dans le Gard, des vignobles commencèrent subitement à dépérir. Le phylloxéra (Daktulosphaira vitifoliae), puceron microscopique originaire d\'Amérique du Nord, avait été introduit accidentellement en Europe avec des plants botaniques transportés par bateaux à vapeur.\n\n'
          'Tandis que les vignes indigènes américaines (Vitis labrusca, Vitis riparia) résistaient naturellement au parasite, la vigne européenne (Vitis vinifera) subissait la destruction irrémédiable de son système racinaire, entraînant la perte de 2,5 millions d\'hectares en France. Les chercheurs Jules Émile Planchon, Charles Valentine Riley et Gaston Bazille découvrirent la solution salvatrice : greffer les cépages nobles européens sur des porte-greffes américains résistants.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Pratiquement tous les vins que nous dégustons aujourd\'hui proviennent de cette greffe salutaire. Une remarquable illustration de résilience viticole face aux défis environnementaux. »',
      requiredCount: 5,
    ),
    WineBadge(
      id: 'savant_napoleon',
      title: 'Le Chatmelier de l\'Empereur ⚔️',
      titleEn: 'The Emperor’s Chatmelier 🦅',
      emoji: '🎩',
      assetImagePath: 'assets/badges/savant_napoleon.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin de Gevrey-Chambertin ou de Bourgogne Grand Cru.',
      descriptionEn: 'Savor Chambertin or imperial favorites loved by Napoleon.',
      chatmelierLore:
          '« ⚔️ HISTOIRE DU CHATMELIER :\n\n'
          'Napoléon Ier affectionnait tout particulièrement le Chambertin, grand cru réputé de Gevrey en Côte de Nuits. Selon les mémoires de son entourage, des caisses de Chambertin suivaient l\'état-major de campagne à travers l\'Europe, d\'Austerlitz à la campagne de Russie.\n\n'
          'Fait notable, l\'Empereur buvait généralement son Chambertin chambré, mais coupé d\'eau claire dans son gobelet en vermeil. Ce geste lui permettait d\'apprécier les arômes du grand pinot noir bourguignon tout en conservant une concentration optimale lors des décisions stratégiques.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Allonger un grand cru d\'eau paraît impensable pour un dégustateur moderne ! Mais pour un chef d\'État en pleine campagne militaire, l\'essentiel était de concilier plaisir gustatif et lucidité tactique. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_volcan',
      title: 'Le Chatmelier des Volcans 🌋',
      titleEn: 'Volcanic Chatmelier 🌋',
      emoji: '🌋',
      assetImagePath: 'assets/badges/savant_volcan.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin de terroir volcanique (Sicile/Etna, Canaries, Santorin, Auvergne, Campanie...).',
      descriptionEn: 'Taste wine forged on volcanic basalt (Etna, Santorini, Azores).',
      chatmelierLore:
          '« 🌋 PÉDOLOGIE & TERROIRS VOLCANIQUES :\n\n'
          'Les terroirs volcaniques comptent parmi les plus singuliers de la viticulture mondiale. Sur les pentes de l\'Etna en Sicile, sur les cratères de Santorin ou dans la vallée de La Geria à Lanzarote, la vigne s\'enracine dans des couches épaisses de basalte, de lapilli et de cendres siliceuses.\n\n'
          'Les sols sablonneux et siliceux volcaniques présentent une particularité majeure : ils empêchent la progression souterraine du puceron du phylloxéra. De ce fait, plusieurs de ces régions ont conservé de très vieilles vignes franches de pied (non greffées), âgées parfois de plus d\'un siècle (comme le Nerello Mascalese ou l\'Assyrtiko). Ces terroirs riches en potassium et fer apportent une minéralité fumée et une vivacité saline caractéristiques.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Ces terroirs volcaniques confèrent aux vins une tension saline percutante et ce parfum distinctif de pierre chaude très prisé des amateurs de minéralité. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_biodynamie',
      title: 'Le Chatmelier Lunaire 🌙',
      titleEn: 'Lunar Chatmelier 🌙',
      emoji: '✨',
      assetImagePath: 'assets/badges/savant_biodynamie.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Déguster ou posséder un vin certifié Demeter, Biodyvin ou cultivé en biodynamie.',
      descriptionEn: 'Taste certified biodynamic wines tuned to lunar rhythms.',
      chatmelierLore:
          '« 🌙 AGROBIOLOGIE & CYCLES NATURELS :\n\n'
          'Théorisée en 1924 par Rudolf Steiner lors de son cours d\'agriculture à Koberwitz, puis développée par Maria Thun, la biodynamie conçoit le domaine viticole comme un écosystème autonome et diversifié en résonance avec les rythmes naturels et saisonniers.\n\n'
          'Cette pratique s\'appuie sur des préparations naturelles dynamisées (notamment la bouse de corne 500 et la silice 501) pour stimuler l\'activité biologique des sols et accompagner la photosynthèse. En éliminant tout produit de synthèse, elle encourage la vigne à développer ses propres mécanismes de défense (phytoalexines).\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Respecter les cycles du vivant et valoriser la biodiversité du sol fait partie des démarches agronomiques les plus exigeantes de la viticulture contemporaine. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_amphore',
      title: 'Le Chatmelier d\'Amphore & Qvevri 🏺',
      titleEn: 'Amphora Chatmelier 🏺',
      emoji: '🏺',
      assetImagePath: 'assets/badges/savant_amphore.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin élevé en amphore, jarre de terre cuite, Qvevri géorgien ou un vin orange.',
      descriptionEn: 'Taste skin-contact orange wine fermented in terracotta amphorae.',
      chatmelierLore:
          '« 🏺 LE BERCEAU HISTORIQUE DE LA VINIFICATION :\n\n'
          'Les découvertes archéologiques de Gadachrili Gora en Géorgie ont mis en évidence des traces de vinification remontant à 6000 av. J.-C., attestant du rôle pionnier du Caucase dans l\'histoire du vin. La tradition du Qvevri est d\'ailleurs inscrite au patrimoine immatériel de l\'UNESCO.\n\n'
          'Ces jarres d\'argile cuite sont enfouies sous le sol du chai (le Marani), garantissant une régulation thermique naturelle autour de 12 à 14°C. Les raisins blancs y macèrent plusieurs mois avec leurs peaux et pépins, produisant des vins orange aux tanins veloutés et aux arômes complexes de fruits secs et d\'épices douces, sans apport de boisé aromatique.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Ces vins illustrent la persistance d\'un savoir-faire millénaire. La macération pelliculaire des blancs révèle une matière et une texture tannique passionnantes à table. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_botrytis',
      title: 'Le Chatmelier & Botrytis 🍇',
      titleEn: 'Chatmelier & Botrytis 🍇',
      emoji: '🍯',
      assetImagePath: 'assets/badges/savant_botrytis.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin liquoreux d\'exception issu de pourriture noble (Sauternes, Tokaj, Grains Nobles...).',
      descriptionEn: 'Taste Sauternes, Tokaji, or sweet wines blessed by noble rot.',
      chatmelierLore:
          '« 🍇 LA POURRITURE NOBLE & BOTRYTIS CINEREA :\n\n'
          'Dans la plupart des situations, le champignon microscopique Botrytis cinerea cause la pourriture grise, dommageable pour la récolte. Mais dans des microclimats précis — comme à Sauternes grâce à l\'humidité du Ciron rencontrant la Garonne, ou à Tokaj en Hongrie —, l\'alternance de brumes matinales et d\'après-midis tièdes engendre la "pourriture noble".\n\n'
          'Le mycélium perfore délicatement la pellicule de la baie, permettant à l\'eau de s\'évaporer tout en concentrant les sucres et les acides. Ce métabolisme synthétise des molécules aromatiques précieuses apportant des notes de miel d\'acacia, d\'abricot confit, de pâte de coing et de safran.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'L\'élaboration de ces grands liquoreux exige des tris successifs grain par grain par des vendangeurs expérimentés. L\'un des plus beaux équilibres entre douceur et fraîcheur acide du patrimoine œnologique. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_maceration_carbonique',
      title: 'Le Chatmelier Carbonique 🍒',
      titleEn: 'Carbonic Chatmelier 🍒',
      emoji: '🍒',
      assetImagePath: 'assets/badges/savant_maceration_carbonique.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Déguster un vin issu de macération carbonique ou semi-carbonique (Beaujolais, Gamay primeur...).',
      descriptionEn: 'Taste fresh wines crafted via whole-cluster carbonic maceration.',
      chatmelierLore:
          '« 🍒 LA MACÉRATION CARBONIQUE EN GRAPPES ENTIÈRES :\n\n'
          'Étudiée par Michel Flanzy dans les années 1930, la macération carbonique est une technique emblématique du Beaujolais. Des grappes entières et intactes sont placées en cuve close saturée de gaz carbonique (CO2).\n\n'
          'En l\'absence d\'oxygène, les cellules du raisin réalisent une fermentation intracellulaire anaérobie par leurs propres enzymes, produisant une petite fraction d\'alcool et des esters aromatiques intenses (comme l\'acétate d\'isoamyle, apportant des notes de bonbon anglais et de banane mûre). Les pigments colorants de la peau diffusent rapidement sans extraire de tanins astringents.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Cette méthode donne des vins croquants, fruités et souples, parfaits pour une consommation conviviale et désaltérante. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_kimmeridgien',
      title: 'Le Chatmelier du Kimméridgien 🦪',
      titleEn: 'Kimmeridgian Chatmelier 🦪',
      emoji: '🦪',
      assetImagePath: 'assets/badges/savant_kimmeridgien.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un Chablis, Sancerre Terres Blanches ou vin issu de marne calcaire kimméridgienne.',
      descriptionEn: 'Taste fossilized oyster shell minerality in Chablis or Sancerre.',
      chatmelierLore:
          '« 🦪 LE KIMMÉRIDGIEN (-152 MILLIONS D\'ANNÉES) :\n\n'
          'L\'étage géologique du Kimméridgien remonte au Jurassique supérieur. À cette époque, une mer chaude et peu profonde recouvrait le Bassin parisien, peuplée de milliards de petites huîtres fossiles recourbées en forme de virgule : les Exogyra virgula (Nanogyra virgula).\n\n'
          'Ces sédiments marins se sont sédimentés pour former des marnes argilo-calcaires blanches que l\'on retrouve aujourd\'hui à Chablis, à Sancerre et dans la Côte des Bar. Les racines de Chardonnay et de Sauvignon y puisent une tension minérale saline et une fraîcheur iodée emblématiques.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'La présence de coquillages marins fossilisés au cœur des coteaux de Bourgogne et du Val de Loire illustre le lien direct entre l\'histoire géologique de la Terre et le profil minéral de notre verre. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🏛️ PALIERS & ÉQUILIBRE DE CAVE (ADDITIONS)
    // ==========================================
    WineBadge(
      id: 'milestone_first_bottle',
      title: 'Premier Flacon',
      titleEn: 'First Bottle',
      emoji: '🌱',
      assetImagePath: 'assets/badges/milestone_first_bottle.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.bronze,
      description: 'Avoir ajouté votre toute première bouteille dans votre cave.',
      descriptionEn: 'Have added your very first bottle to your cellar.',
      chatmelierLore:
          '« Tout grand voyage œnologique commence par un premier flacon. Cette première bouteille est la pierre fondatrice de votre collection personnelle. Le Chatmelier vous souhaite de belles dégustations à venir ! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'milestone_first_tasting',
      title: 'Premier Coup de Nez',
      titleEn: 'First Nose',
      emoji: '👃',
      assetImagePath: 'assets/badges/milestone_first_tasting.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.bronze,
      description: 'Avoir consigné votre première note de dégustation.',
      descriptionEn: 'Have recorded your first tasting note.',
      chatmelierLore:
          '« La mémoire du vin commence avec la première attention portée au verre. Robe, nez, bouche : vous voilà officiellement dégustateur dans Chatmelier ! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'milestone_cellar_rainbow',
      title: 'L\'Arc-en-Ciel de Cave',
      titleEn: 'Cellar Rainbow',
      emoji: '🌈',
      assetImagePath: 'assets/badges/milestone_cellar_rainbow.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.silver,
      description: 'Posséder en cave au moins 1 rouge, 1 blanc, 1 rosé et 1 effervescent.',
      descriptionEn: 'Own at least 1 red, 1 white, 1 rosé, and 1 sparkling wine in cellar.',
      chatmelierLore:
          '« Rouge pour les viandes mijotées, blanc pour l\'iode, rosé pour la convivialité estivale, bulles pour célébrer les grands moments : une cave parée pour toutes les tablées ! »',
      requiredCount: 4,
    ),
    WineBadge(
      id: 'milestone_grand_cru_collection',
      title: 'Collectionneur de Grands Crus',
      titleEn: 'Grand Cru Collector',
      emoji: '💎',
      assetImagePath: 'assets/badges/milestone_grand_cru_collection.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.gold,
      description: 'Posséder au moins 3 bouteilles classées Premier Cru ou Grand Cru.',
      descriptionEn: 'Own at least 3 Premier Cru or Grand Cru classified bottles.',
      chatmelierLore:
          '« Les sommets de la hiérarchie viticole : Côte d\'Or, Médoc 1855, Saint-Émilion ou Alsace Grand Cru. Trois flacons d\'exception reposent sous votre garde bienveillante. »',
      requiredCount: 3,
    ),

    // ==========================================
    // 🏳️ NOUVEAUX PAYS VITICOLES
    // ==========================================
    WineBadge(
      id: 'country_germany',
      title: 'Maître du Rhin & Moselle',
      titleEn: 'Master of Rhine & Mosel',
      emoji: '🇩🇪',
      assetImagePath: 'assets/badges/country_germany.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins d\'Allemagne (Mosel, Rheingau...).',
      descriptionEn: 'Taste German Riesling from Mosel, Rheingau, or Pfalz.',
      chatmelierLore:
          '« Les coteaux vertigineux de schiste de la Moselle et les méandres du Rhin enfantent des Rieslings d\'une tension acide et d\'une minéralité cristalline sans équivalent dans le monde. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'country_switzerland',
      title: 'Altitude Helvétique',
      titleEn: 'Swiss High Altitude',
      emoji: '🇨🇭',
      assetImagePath: 'assets/badges/country_switzerland.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Suisse (Valais, Vaud, Lavaux...).',
      descriptionEn: 'Taste Swiss alpine wines from Valais or Lavaux.',
      chatmelierLore:
          '« Des terrasses de Lavaux plongeant dans le lac Léman aux coteaux de Visperterminen, la Suisse façonne le Chasselas (Fendant), la Petite Arvine et le Cornalin avec une précision d\'orfèvre. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_argentina',
      title: 'L\'Âme des Andes',
      titleEn: 'Soul of the Andes',
      emoji: '🇦🇷',
      assetImagePath: 'assets/badges/country_argentina.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin d\'Argentine (Mendoza, Cafayate...).',
      descriptionEn: 'Taste high-altitude Malbec from Mendoza, Argentina.',
      chatmelierLore:
          '« Perché à plus de 1000 mètres d\'altitude au pied des neiges éternelles de la Cordillère des Andes, le vignoble de Mendoza magnifie le Malbec en nectars profonds, soyeux et solaires. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_chile',
      title: 'Sous l\'Ombre des Cordillères',
      titleEn: 'Shadow of the Cordilleras',
      emoji: '🇨🇱',
      assetImagePath: 'assets/badges/country_chile.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin du Chili (Maipo, Colchagua...).',
      descriptionEn: 'Taste Carmenère or Cabernet from Chile’s Maipo Valley.',
      chatmelierLore:
          '« Isolé par l\'océan Pacifique et la barrière des Andes, le Chili est un sanctuaire préservant des vignes franches de pied et le mythique cépage bordelais Carménère, sauvé de l\'oubli. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_australia',
      title: 'Terre Rouge d\'Oz',
      titleEn: 'Red Soil of Oz',
      emoji: '🇦🇺',
      assetImagePath: 'assets/badges/country_australia.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin d\'Australie (Barossa, Margaret River...).',
      descriptionEn: 'Taste bold Shiraz from Barossa or Cabernet from Coonawarra.',
      chatmelierLore:
          '« Des ceps centenaires de Shiraz de Barossa Valley ancrés dans la terre rouge aux Cabernets racés de Margaret River, l\'Australie concilie tradition séculaire et viticulture de pointe. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_new_zealand',
      title: 'Le Bout du Monde',
      titleEn: 'The Edge of the World',
      emoji: '🇳🇿',
      assetImagePath: 'assets/badges/country_new_zealand.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Nouvelle-Zélande (Marlborough, Central Otago...).',
      descriptionEn: 'Taste Marlborough Sauvignon Blanc or Central Otago Pinot Noir.',
      chatmelierLore:
          '« Les brises du Pacifique sculptent l\'éclat aromatique vif du Sauvignon Blanc de Marlborough et la pureté éclatante du Pinot Noir de Central Otago. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_south_africa',
      title: 'Le Cap des Bonnes Espérances',
      titleEn: 'Cape of Good Hope',
      emoji: '🇿🇦',
      assetImagePath: 'assets/badges/country_south_africa.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin d\'Afrique du Sud (Stellenbosch, Swartland...).',
      descriptionEn: 'Taste Pinotage or Chenin from Stellenbosch.',
      chatmelierLore:
          '« Fondé dès 1685 à Constantia, le vignoble sud-africain s\'épanouit entre deux océans. Le Chenin Blanc (Steen) et le Pinotage autochtone y signent des vins de haute distinction. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_greece',
      title: 'L\'Héritage de Dionysos',
      titleEn: 'Heritage of Dionysus',
      emoji: '🇬🇷',
      assetImagePath: 'assets/badges/country_greece.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Grèce (Santorin, Naoussa, Némée...).',
      descriptionEn: 'Taste Assyrtiko from Santorini or Xinomavro from Naoussa.',
      chatmelierLore:
          '« Sur l\'île volcanique de Santorin, les vignes d\'Assyrtiko sont tressées en paniers protecteurs au sol (Kouloura) pour braver les vents égéens, offrant une acidité minérale et saline unique. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_austria',
      title: 'L\'Élégance Danubienne',
      titleEn: 'Danubian Elegance',
      emoji: '🇦🇹',
      assetImagePath: 'assets/badges/country_austria.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin d\'Autriche (Wachau, Kamptal, Burgenland...).',
      descriptionEn: 'Taste Grüner Veltliner or Blaufränkisch from Wachau.',
      chatmelierLore:
          '« Sur les terrasses de gneiss surplombant le Danube en Wachau, le Grüner Veltliner livre ses notes incomparables de poivre blanc et de pomme fraîche dans une pureté cristalline. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_georgia',
      title: 'Le Berceau Mondial',
      titleEn: 'The World\'s Cradle',
      emoji: '🇬🇪',
      assetImagePath: 'assets/badges/country_georgia.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Géorgie (Kakhétie, Saperavi...).',
      descriptionEn: 'Taste amber wines made in buried Qvevri vessels.',
      chatmelierLore:
          '« 8000 ans de viticulture ininterrompue ! La Géorgie est la terre originelle du vin. Ses élevages en Qvevri et ses cépages ancestraux Saperavi et Rkatsiteli font partie du trésor de l\'humanité. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_uk',
      title: 'Le Renouveau Britannique',
      titleEn: 'The British Revival',
      emoji: '🇬🇧',
      assetImagePath: 'assets/badges/country_uk.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.bronze,
      description: 'Posséder ou avoir dégusté au moins 1 vin ou effervescent du Royaume-Uni (Sussex, Kent...).',
      descriptionEn: 'Taste traditional method sparkling wine from English chalk soils.',
      chatmelierLore:
          '« Les falaises et coteaux crayeux du sud de l\'Angleterre partagent le même sous-sol que la Champagne, offrant aux Sparkling Wines britanniques une fraîcheur et une distinction remarquées. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🏰 NOUVELLES RÉGIONS EMBLÉMATIQUES
    // ==========================================
    WineBadge(
      id: 'region_sud_ouest',
      title: 'Bastide du Sud-Ouest',
      titleEn: 'South-West Bastion',
      emoji: '🦆',
      assetImagePath: 'assets/badges/region_sud_ouest.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins du Sud-Ouest (Cahors, Madiran, Jurançon...).',
      descriptionEn: 'Taste wines from Cahors, Madiran, or Jurançon.',
      chatmelierLore:
          '« Des vins noirs de Cahors bâtis sur le Malbec aux blancs parfumés de Jurançon nés du Petit Manseng au pied des Pyrénées, le Sud-Ouest célèbre la noblesse et l\'authenticité gasconne. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_languedoc_roussillon',
      title: 'Garrigue & Méditerranée',
      titleEn: 'Garrigue & Mediterranean',
      emoji: '🌿',
      assetImagePath: 'assets/badges/region_languedoc_roussillon.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins du Languedoc ou Roussillon (Pic Saint-Loup, Collioure...).',
      descriptionEn: 'Taste sunny Languedoc-Roussillon terroirs.',
      chatmelierLore:
          '« Le plus vaste laboratoire viticole de France ! Entre calcaires battus par les vents et schistes de Collioure, les vignerons signent des cuvées vibrantes aux arômes de thym, ciste et romarin. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_corse',
      title: 'L\'Île de Beauté',
      titleEn: 'Isle of Beauty',
      emoji: '🏝️',
      assetImagePath: 'assets/badges/region_corse.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Corse (Patrimonio, Ajaccio, Calvi...).',
      descriptionEn: 'Taste Sciaccarellu, Niellucciu, or Vermentinu from Corsica.',
      chatmelierLore:
          '« Arènes granitiques, schistes et soleil insulaire : les cépages autochtones corses (le poivré Sciaccarello et le noble Nielluccio) offrent des vins méditerranéens d\'un équilibre saisissant. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'region_beaujolais',
      title: 'Les Dix Crus du Beaujolais',
      titleEn: 'The Ten Beaujolais Crus',
      emoji: '🍇',
      assetImagePath: 'assets/badges/region_beaujolais.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins du Beaujolais (Morgon, Moulin-à-Vent, Fleurie...).',
      descriptionEn: 'Taste Morgon, Fleurie, or Moulin-à-Vent crus.',
      chatmelierLore:
          '« Sur les arènes granitiques et les roches bleues de la Côte du Py, le Gamay engendre de superbes vins de garde aux accents de cerise noire, épices douces et pivoine sauvage. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_toscana',
      title: 'Renaissance Toscane',
      titleEn: 'Tuscan Renaissance',
      emoji: '🏛️',
      assetImagePath: 'assets/badges/region_toscana.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de Toscane (Chianti, Brunello, Bolgheri...).',
      descriptionEn: 'Taste Chianti Classico, Brunello, or Bolgheri Super Tuscans.',
      chatmelierLore:
          '« Entre collines de cyprès et abbayes médiévales, la Toscane magnifie le Sangiovese sur les sols de Galestro et a conquis la planète avec les légendaires Super-Toscans de Bolgheri. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_piemonte',
      title: 'Noblesse Piémontaise',
      titleEn: 'Piedmontese Nobility',
      emoji: '👑',
      assetImagePath: 'assets/badges/region_piemonte.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 2 vins du Piémont (Barolo, Barbaresco, Langhe...).',
      descriptionEn: 'Taste Barolo, Barbaresco, or Barbera from Langhe.',
      chatmelierLore:
          '« "Le vin des rois et le roi des vins" : Barolo et Barbaresco règnent sur les collines embrumées des Langhe. Leurs marnes argilo-calcaires offrent au Nebbiolo une profondeur aromatique unique. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_veneto',
      title: 'Sérénissime Vénétie',
      titleEn: 'Serenissima Veneto',
      emoji: '🎭',
      assetImagePath: 'assets/badges/region_veneto.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de Vénétie (Amarone, Valpolicella, Soave...).',
      descriptionEn: 'Taste Amarone della Valpolicella or Soave.',
      chatmelierLore:
          '« L\'art noble de l\'Appassimento ! Les raisins passerillés sur claies de bois pendant les mois d\'hiver concentrent leurs sucs pour donner naissance à l\'Amarone della Valpolicella, vin monumental. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_rioja',
      title: 'Chêne & Rioja',
      titleEn: 'Oak & Rioja',
      emoji: '🍷',
      assetImagePath: 'assets/badges/region_rioja.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de la Rioja (Crianza, Reserva...).',
      descriptionEn: 'Taste Reserva or Gran Reserva Tempranillo from Rioja.',
      chatmelierLore:
          '« Berceau historique de la viticulture espagnole sur l\'Èbre, la Rioja excelle dans les élevages sous bois où le Tempranillo acquiert des nuances suaves de cuir, vanille et tabac blond. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_napa',
      title: 'L\'Or de Napa Valley',
      titleEn: 'Napa Golden Valley',
      emoji: '🌉',
      assetImagePath: 'assets/badges/region_napa.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Napa Valley (Rutherford, Oakville...).',
      descriptionEn: 'Taste world-class Cabernet from Napa Valley.',
      chatmelierLore:
          '« Coincée entre les monts Mayacamas et Vaca, Napa Valley bénéficie des brumes de la baie de San Pablo. Ses Cabernets opulents aux tanins veloutés comptent parmi les plus grands crus mondiaux. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🍇 GRANDS CÉPAGES MONDIAUX
    // ==========================================
    WineBadge(
      id: 'grape_merlot',
      title: 'Le Velours du Merlot',
      titleEn: 'Merlot Velvet',
      emoji: '🫐',
      assetImagePath: 'assets/badges/grape_merlot.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins à dominante Merlot (Pomerol, Saint-Émilion...).',
      descriptionEn: 'Taste plush and opulent Merlot wines.',
      chatmelierLore:
          '« Cépage emblématique de la rive droite bordelaise, le Merlot séduit par sa chair pulpeuse, sa texture veloutée et ses arômes gourmands de prune noire, mûre et chocolat noir. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_sauvignon_blanc',
      title: 'L\'Éclat du Sauvignon Blanc',
      titleEn: 'Sauvignon Vibrance',
      emoji: '🍋',
      assetImagePath: 'assets/badges/grape_sauvignon_blanc.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins de Sauvignon Blanc (Sancerre, Pouilly-Fumé...).',
      descriptionEn: 'Taste crisp, grassy, and vibrant Sauvignon Blanc.',
      chatmelierLore:
          '« Réputé pour son acidité vivifiante et sa fraîcheur aromatique ! Sur le silex, il offre une note minérale de pierre à fusil ; sur le calcaire, il exhale les agrumes et le buis. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_grenache',
      title: 'Le Généreux Grenache',
      titleEn: 'Generous Grenache',
      emoji: '☀️',
      assetImagePath: 'assets/badges/grape_grenache.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins à dominante Grenache (Rhône sud, Priorat...).',
      descriptionEn: 'Taste warming and spiced Grenache/Garnacha.',
      chatmelierLore:
          '« Roi du pourtour méditerranéen bravant le vent et la sécheresse, le Grenache offre une texture ronde et soyeuse, accompagnée de notes de fraise confite, poivre et garrigue. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_cabernet_franc',
      title: 'La Finesse du Cabernet Franc',
      titleEn: 'Cabernet Franc Finesse',
      emoji: '🪨',
      assetImagePath: 'assets/badges/grape_cabernet_franc.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins de Cabernet Franc (Chinon, Bourgueil, Saumur...).',
      descriptionEn: 'Taste floral and graphite-noted Cabernet Franc.',
      chatmelierLore:
          '« Père génétique du Cabernet Sauvignon et du Merlot, le Cabernet Franc charme par son élégance ligérienne : parfums de framboise sauvage, touche de graphite et note florale de violette. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_sangiovese',
      title: 'Le Sang de Jupiter',
      titleEn: 'Blood of Jupiter',
      emoji: '🦁',
      assetImagePath: 'assets/badges/grape_sangiovese.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins issus du Sangiovese (Chianti, Brunello...).',
      descriptionEn: 'Taste savory, cherry-scented Italian Sangiovese.',
      chatmelierLore:
          '« Son nom latin "Sanguis Jovis" évoque le roi des dieux romains. Robe rubis étincelante, acidité tonique et arômes de cerise griotte et thé noir : le partenaire gastronomique parfait. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_malbec',
      title: 'La Nuit Noire du Malbec',
      titleEn: 'Dark Night of Malbec',
      emoji: '🖤',
      assetImagePath: 'assets/badges/grape_malbec.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins à dominante Malbec / Côt (Cahors, Mendoza...).',
      descriptionEn: 'Taste deep, inky Malbec from Cahors or Mendoza.',
      chatmelierLore:
          '« Le "vin noir" du Moyen Âge ! Le Malbec possède une robe d\'encre pourpre et tapisse la bouche d\'arômes denses de mûre sauvage, cassis, réglisse noire et violette. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_tempranillo',
      title: 'L\'Âme du Tempranillo',
      titleEn: 'Noble Tempranillo',
      emoji: '🇪🇸',
      assetImagePath: 'assets/badges/grape_tempranillo.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins issus du Tempranillo (Rioja, Ribera del Duero...).',
      descriptionEn: 'Taste Spain’s premier red grape Tempranillo.',
      chatmelierLore:
          '« Mûrissant tôt ("temprano") sous le soleil ibérique, le Tempranillo allie une trame tannique soyeuse à des notes nobles de cerise noire, cuir, boîte à cigares et vanille bourbon. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_gamay',
      title: 'La Fraîcheur du Gamay',
      titleEn: 'Freshness of Gamay',
      emoji: '🍓',
      assetImagePath: 'assets/badges/grape_gamay.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.bronze,
      description: 'Déguster ou avoir en cave au moins 2 vins issus du Gamay (Beaujolais, Loire...).',
      descriptionEn: 'Taste fruity and vibrant Gamay from Beaujolais.',
      chatmelierLore:
          '« Banni de Bourgogne en 1395 par Philippe le Hardi, le Gamay a trouvé sur les granites du Beaujolais son sanctuaire pour offrir des jus gouleyants débordant de fruits rouges frais. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_viognier',
      title: 'L\'Arôme du Viognier',
      titleEn: 'Viognier Enchantment',
      emoji: '🍑',
      assetImagePath: 'assets/badges/grape_viognier.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.gold,
      description: 'Déguster ou avoir en cave au moins 1 vin issu du cépage Viognier (Condrieu...).',
      descriptionEn: 'Taste Condrieu or aromatic Viognier with white peach notes.',
      chatmelierLore:
          '« Sauvé in extremis de la disparition dans les années 1960, le Viognier envoûte par son profil suave et son bouquet opulent d\'abricot mûr, pêche de vigne et fleur de violette. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'grape_gewurztraminer',
      title: 'L\'Épice du Gewurztraminer',
      titleEn: 'Gewurztraminer Spice',
      emoji: '🌹',
      assetImagePath: 'assets/badges/grape_gewurztraminer.webp',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 1 Gewurztraminer (Alsace...).',
      descriptionEn: 'Taste lychee-scented, exotic Gewurztraminer.',
      chatmelierLore:
          '« "Gewürz" signifie épicé en allemand : ce cépage à la robe dorée séduit par son intensité phénoménale de pétale de rose fraîche, litchi, gingembre confit et poivre blanc. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🍸 NOUVEAUX BADGES MIXOLOGIE & SPIRITUEUX
    // ==========================================
    WineBadge(
      id: 'spirit_tequila_mezcal',
      title: 'L\'Or Sacré de l\'Agave',
      titleEn: 'Agave Soul',
      emoji: '🌵',
      assetImagePath: 'assets/badges/spirit_tequila_mezcal.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 Tequila 100% Agave ou Mezcal artisanal.',
      descriptionEn: 'Taste authentic Tequila or smoky artisanal Mezcal from Mexico.',
      chatmelierLore:
          '« Les cœurs d\'agave cuits dans des fosses en pierre souterraines à Oaxaca révèlent des arômes minéraux, fumés et terreux d\'une complexité captivante. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_vodka',
      title: 'La Pureté du Grain',
      titleEn: 'Purity of the Grain',
      emoji: '❄️',
      assetImagePath: 'assets/badges/spirit_vodka.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.bronze,
      description: 'Posséder ou avoir dégusté au moins 1 Vodka de tradition (blé, seigle...).',
      descriptionEn: 'Taste crystal-clear pure grain or potato vodka.',
      chatmelierLore:
          '« Distillée avec une pureté rigoureuse et filtrée lentement, la grande vodka révèle la rondeur soyeuse du blé ou le piquant poivré du seigle slave. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_liqueurs',
      title: 'L\'Élixir des Herboristes',
      titleEn: 'Herbal Secrets',
      emoji: '🌿',
      assetImagePath: 'assets/badges/spirit_liqueurs.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 liqueur de plantes, Amaro, Pastis ou Chartreuse.',
      descriptionEn: 'Taste Chartreuse, Amaro, or Benedictine herbal liqueurs.',
      chatmelierLore:
          '« Plantes des cimes alpines, racines amères, écorces et macérations monastiques : les liqueurs traditionnelles prolongent les secrets des apothicaires médiévaux. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 💩 NOUVEAUX BADGES AUTODÉRISION & LOOSER
    // ==========================================
    WineBadge(
      id: 'looser_poussiere',
      title: 'Toiles d\'Araignée 🕸️',
      titleEn: 'Cellar Cobwebs 🕸️',
      emoji: '🕸️',
      assetImagePath: 'assets/badges/looser_poussiere.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Posséder une bouteille entrée en cave depuis plus de 3 ans sans jamais l\'ouvrir.',
      descriptionEn: 'Let a bottle gather thick cellar dust for years.',
      chatmelierLore:
          '« Elle dort sagement au fond de la cave sous une noble couche de poussière... On guette la fameuse "grande occasion", alors que chaque soir peut devenir une fête ! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_tache_etiquette',
      title: 'La Goutte Rebelle 🍷',
      titleEn: 'The Rebellious Drip 🍷',
      emoji: '🩸',
      assetImagePath: 'assets/badges/looser_tache_etiquette.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Avoir consigné une tache sur étiquette, une coulure ou une maladresse de service.',
      descriptionEn: 'Spill a stubborn drop of red wine directly onto the pristine label.',
      chatmelierLore:
          '« La légendaire goutte pourpre qui glisse le long du goulot pour baptiser l\'étiquette immaculée ou la belle nappe blanche ! La marque des tablées joyeuses et vivantes. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🔬 NOUVEAUX RÉCITS DU CHATMELIER SAVANT
    // ==========================================
    WineBadge(
      id: 'savant_jefferson',
      title: 'Le Chatmelier de Jefferson 🇺🇸',
      titleEn: 'Jefferson’s Chatmelier 🇺🇸',
      emoji: '📜',
      assetImagePath: 'assets/badges/savant_jefferson.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un grand cru historique d\'Hermitage, Sauternes (Yquem) ou Montepulciano.',
      descriptionEn: 'Savor crus once personally selected by Thomas Jefferson.',
      chatmelierLore:
          '« 🇺🇸 L\'AMBASSADEUR OENOLOGUE DES LUMIÈRES :\n\n'
          'Ambassadeur des États-Unis à Paris de 1784 à 1789, Thomas Jefferson sillonna la France et l\'Italie pour cartographier les meilleurs terroirs. Épris d\'Hermitage et d\'Yquem (qu\'il fit livrer à George Washington), il voyait dans le bon vin un garant de santé et de modération démocratique.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Déguster l\'un de ses crus de prédilection, c\'est renouer avec le premier grand amateur éclairé du Nouveau Monde. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_schiste',
      title: 'L\'Alchimie des Schistes Bleus 🪨',
      titleEn: 'Schist Revelation 🪨',
      emoji: '🪨',
      assetImagePath: 'assets/badges/savant_schiste.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin de terroir de schiste (Priorat, Côte-Rôtie, Collioure, Douro, Faugères...).',
      descriptionEn: 'Taste the flinty, dark tension of pure schist soil wines.',
      chatmelierLore:
          '« 🪨 GÉOLOGIE DU SCHISTE & ENRACINEMENT PROFOND :\n\n'
          'Sur les terrasses escarpées de la Llicorella au Priorat ou des ardoises du Douro, la roche se délite en feuillets verticaux. Privée d\'eau en surface, la vigne plonge ses racines jusqu\'à 15 mètres de profondeur pour puiser les minéraux, offrant des vins d\'une intensité tellurique fumée.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Sur le schiste, la vigne lutte pour créer des vins à la minéralité sombre et éclatante. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_vents',
      title: 'Le Maître du Mistral 💨',
      titleEn: 'Master of the Mistral 💨',
      emoji: '💨',
      assetImagePath: 'assets/badges/savant_vents.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Déguster un vin de la Vallée du Rhône ou de Provence balayé par le Mistral.',
      descriptionEn: 'Taste wines swept by the fierce Mistral and Tramontane winds.',
      chatmelierLore:
          '« 💨 LE MISTRAL, MÉDECIN NATUREL DU VIGNOBLE :\n\n'
          'Soufflant à plus de 100 km/h dans le couloir rhodanien, le Mistral assèche les vignes instantanément après chaque averse, empêchant le mildiou et la pourriture de s\'installer. Un allié écologique providentiel pour des raisins sains et gorgés de soleil.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Le vent protège la vigne et donne aux vins du sud leur énergie et leur éclat si caractéristiques. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_alienor',
      title: 'Le Traité d\'Aliénor d\'Aquitaine 👑',
      titleEn: 'Treaty of Eleanor of Aquitaine 👑',
      emoji: '👑',
      assetImagePath: 'assets/badges/savant_alienor.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin de Bordeaux (Graves, Médoc, Clairet) en hommage au vignoble bordelais.',
      descriptionEn: 'Taste fine Bordeaux wine celebrating centuries of heritage.',
      chatmelierLore:
          '« 👑 1152 : LE MARIAGE QUI FONDA LA RENOMMÉE DE BORDEAUX :\n\n'
          'Le mariage d\'Aliénor d\'Aquitaine avec Henri Plantagenêt rattacha l\'Aquitaine à la couronne anglaise. Les marchands bordelais obtinrent l\'exemption de taxes royales, ouvrant les marchés londoniens aux cargaisons de Clairet et scellant la vocation maritime mondiale de Bordeaux.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Une grande histoire d\'amour géopolitique qui a façonné pour des siècles la carte viticole mondiale. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_fleur_voile',
      title: 'L\'Élevage sous Voile 🧀',
      titleEn: 'Aging Under Flor Veil 🧀',
      emoji: '🧀',
      assetImagePath: 'assets/badges/savant_fleur_voile.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.diamond,
      description: 'Déguster un Vin Jaune du Jura ou un Sherry Jerez Fino / Manzanilla sous voile de levures.',
      descriptionEn: 'Taste Vin Jaune or Sherry aged beneath a protective yeast flor.',
      chatmelierLore:
          '« 🧀 LA MERVEILLE DE L\'ÉLEVAGE OXYDATIF BIOLOGIQUE :\n\n'
          'En fût non ouillé, un voile protecteur de levures vivantes (Saccharomyces beticus) se forme à la surface du vin. Il bloque l\'oxydation brutale tout en créant la molécule de sotolon aux arômes fascinants de noix fraîche, curry doux, amande amère et pomme verte séchée.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'L\'une des plus grandes énigmes œnologiques : confier le vin au temps et à l\'air pour engendrer un chef-d\'œuvre immortel. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_sanguis_christi',
      title: 'Sanguis Christi (In Vino Veritas) ✝️',
      titleEn: 'Sanguis Christi (In Vino Veritas) ✝️',
      titleLa: 'Sanguis Christi (In Vino Veritas) ✝️',
      emoji: '✝️',
      assetImagePath: 'assets/badges/savant_sanguis_christi.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.diamond,
      description: 'Activer la langue latine dans l\'application pour communier avec les anciens.',
      descriptionEn: 'Activate Latin language in the app to commune with ancient scholars.',
      descriptionLa: 'Linguam Latinam in apposito adhibe ut cum antiquis communices.',
      chatmelierLore:
          '« ✝️ IN VINO VERITAS, IN AQUA SANITAS :\n\n'
          'Depuis les monastères médiévaux jusqu\'aux liturgies sacrées, le vin a toujours été honoré comme le nectar de la vie et le symbole du sacrifice divin. En activant la langue de Cicéron et de saint Benoît, vous pénétrez dans le saint des saints de l\'érudition œnologique.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Fructus vitis et operis manuum hominum. »',
      chatmelierLoreEn:
          '« ✝️ IN VINO VERITAS, IN AQUA SANITAS :\n\n'
          'From medieval monastic orders to sacred liturgy, wine was venerated as the nectar of divine contemplation and life. By choosing Latin, you enter the sanctum of historical viticulture.\n\n'
          '🍷 CHATMELIER\'S WORDS :\n'
          'Fructus vitis et operis manuum hominum. »',
      chatmelierLoreLa:
          '« ✝️ IN VINO VERITAS, IN AQUA SANITAS :\n\n'
          'Ex monasteriis mediaevalibus usque ad sacras liturgias, vinum semper ut vitae nectar et divini mysterii signum colitur. Lingua Latina electa, in adytum sanctissimum eruditionis oenologicae intras.\n\n'
          '🍷 VERBUM CHATMELIER :\n'
          'Fructus vitis et operis manuum hominum. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_blind_battle',
      title: 'Maître de l\'Aveugle 🎭',
      titleEn: 'Master of Blind Tasting 🎭',
      titleLa: 'Magister Caecae Gustationis 🎭',
      emoji: '🎭',
      assetImagePath: 'assets/badges/savant_blind_battle.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.diamond,
      description: 'Déguster un vin ou participer à une session à l\'aveugle en se fiant uniquement à ses sens.',
      descriptionEn: 'Taste a wine or participate in a blind battle relying solely on your senses.',
      descriptionLa: 'Vinum caeco modo gusta solo sensuum iudicio fretus.',
      chatmelierLore:
          '« 🎭 L\'ÉPREUVE SUPRÊME DU SOMMELIER :\n\n'
          'Dépouillé de son étiquette, de son prix et de son prestige commercial, le vin se livre dans son authenticité la plus pure. Le concours du Meilleur Sommelier du Monde en a fait son épreuve reine : identifier cépage, millésime et terroir à la seule force de l\'olfaction et du palais.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Sans préjugé ni étiquette, seul le vin parle et révèle votre véritable acuité sensorielle. »',
      chatmelierLoreEn:
          '« 🎭 THE ULTIMATE SOMMELIER TEST:\n\n'
          'Stripped of prestige labels and price tags, wine reveals its raw, unfiltered soul. World-class sommeliers earn their stripes in blind tastings, deducing grape, vintage, and terroir through pure sensory acuity.\n\n'
          '🍷 CHATMELIER\'S WORDS:\n'
          'When labels vanish, only truth remains in the glass. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_thermocourbe',
      title: 'Maître du Thermomètre 🌡️',
      titleEn: 'Thermal Curve Master 🌡️',
      titleLa: 'Magister Thermometri 🌡️',
      emoji: '🌡️',
      assetImagePath: 'assets/badges/savant_thermocourbe.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Respecter ou ajuster la température de service optimale selon la thermocourbe du vin.',
      descriptionEn: 'Respect or adjust the ideal serving temperature along the wine\'s thermal curve.',
      descriptionLa: 'Temperaturam optimam ad vinum ministrandum diligenter observa.',
      chatmelierLore:
          '« 🌡️ LA THERMODYNAMIQUE DU VERRE :\n\n'
          'Deux degrés de trop et l\'alcool brûle le palais en étouffant la finesse du fruit ; deux degrés trop froids et les tanins deviennent dures et astringents. Les molécules aromatiques volatiles ont leur température précise d\'émancipation.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Un grand cru servi à mauvaise température est un violoncelle désaccordé. Maîtriser le degré, c\'est libérer la mélodie. »',
      chatmelierLoreEn:
          '« 🌡️ THE THERMODYNAMICS OF WINE:\n\n'
          'Too warm, and alcohol vapours smother delicate aromas; too cold, and tannins become harsh and unyielding. Serving at the right thermal point unleashes perfection.\n\n'
          '🍷 CHATMELIER\'S WORDS:\n'
          'Temperature is the tuning fork of great wine. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_table_consensus',
      title: 'Arbitre des Palais 🤝',
      titleEn: 'Palate Peacemaker 🤝',
      titleLa: 'Arbiter Palatorum 🤝',
      emoji: '🤝',
      assetImagePath: 'assets/badges/savant_table_consensus.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Trouver l\'accord harmonieux et le consensus unanime entre plusieurs convives à table.',
      descriptionEn: 'Achieve unanimous harmony and pairing consensus between diverse table guests.',
      descriptionLa: 'Concordiam et consensum inter diversos convivas ad mensam concilia.',
      chatmelierLore:
          '« 🤝 L\'ART DU CONSENSUS GASTRONOMIQUE :\n\n'
          'Autour d\'une même table se rencontrent l\'amateur de blancs tendus et le fervent défenseur de rouges charpentés. Le génie du sommelier réside dans sa capacité à proposer la bouteille passerelle : un cru vibrant, polyvalent et fédérateur qui transcende les clivages.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Le vin rassemble les êtres et dissout les désaccords dans une même émotion partagée. »',
      chatmelierLoreEn:
          '« 🤝 THE ART OF GASTRONOMIC DIPLOMACY:\n\n'
          'Reconciling lovers of crisp mineral whites with enthusiasts of bold tannic reds is the supreme test of a sommelier\'s repertoire.\n\n'
          '🍷 CHATMELIER\'S WORDS:\n'
          'Wine unites souls around a single unforgettable table. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_cellar_architect',
      title: 'Architecte de Cave 📐',
      titleEn: 'Cellar Architect 📐',
      titleLa: 'Architectus Cellae 📐',
      emoji: '📐',
      assetImagePath: 'assets/badges/savant_cellar_architect.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.diamond,
      description: 'Structurer une cave harmonieuse couvrant styles de soif, vins d\'apogée et cuvées de garde.',
      descriptionEn: 'Structure a harmonious cellar with ready-to-drink gems, peak wines, and long-keeping icons.',
      descriptionLa: 'Cellam sapienter instrue omnibus aetatibus et generibus vinorum.',
      chatmelierLore:
          '« 📐 L\'ÉQUILIBRE DES TEMPS ET DES TERROIRS :\n\n'
          'Une grande cave ne se mesure pas uniquement à la rareté de ses flacons, mais à son architecture vivante : un étagement judicieux entre vins de soif immédiats, cuvées à leur zénith et trésors patiemment endormis pour les décennies à venir.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Bâtir sa cave, c\'est composer une symphonie dont le temps est le chef d\'orchestre. »',
      chatmelierLoreEn:
          '« 📐 CELLAR ARCHITECTURE & BALANCE:\n\n'
          'A true collection is a dynamic living library: everyday gastronomic pleasures, wines at their peak, and slumbering treasures for future generations.\n\n'
          '🍷 CHATMELIER\'S WORDS:\n'
          'Building a cellar is composing a symphony where time is the conductor. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_storyteller',
      title: 'Barde du Terroir 📖',
      titleEn: 'Terroir Bard 📖',
      titleLa: 'Bardus Terreni 📖',
      emoji: '📖',
      assetImagePath: 'assets/badges/savant_storyteller.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Explorer la mémoire vivante, les anecdotes historiques et le terroir d\'un domaine.',
      descriptionEn: 'Explore the living memory, historical anecdotes, and terroir behind a wine estate.',
      descriptionLa: 'Historiam vivam et memoriam praediorum oenologicorum disce.',
      chatmelierLore:
          '« 📖 LE VIN COMME RÉCIT DE L\'HUMANITÉ :\n\n'
          'Chaque flacon renferme bien plus que du jus fermenté : il porte le souffle des moines bâtisseurs, la sueur des vignerons bravant le gel printanier et les secrets géologiques d\'un coteau sculpté par des millénaires.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'Boire sans connaître l\'histoire d\'un vin, c\'est écouter un poème sans en comprendre les mots. »',
      chatmelierLoreEn:
          '« 📖 WINE AS HUMAN STORYTELLING:\n\n'
          'Every vintage holds the legacy of pioneering monastic orders, the resilience of winegrowers, and prehistoric geological soils.\n\n'
          '🍷 CHATMELIER\'S WORDS:\n'
          'To drink without knowing the story is to listen to poetry without understanding the words. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'savant_bulles_royales',
      title: 'L\'Alchimiste des Bulles 🥂',
      titleEn: 'Sparkling Alchemist 🥂',
      titleLa: 'Alchemista Spumantis 🥂',
      emoji: '🥂',
      assetImagePath: 'assets/badges/savant_bulles_royales.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Posséder ou déguster au moins 3 grands vins effervescents élaborés selon la méthode traditionnelle.',
      descriptionEn: 'Stock or taste at least 3 exceptional traditional method sparkling wines.',
      descriptionLa: 'Tria vina spumantia nobili methodo tradita in cella habe vel gusta.',
      chatmelierLore:
          '« 🥂 LE MIRACLE DE LA SECONDE FERMENTATION :\n\n'
          'De Dom Pérignon aux grandes maisons de Champagne et de Crémant, emprisonner l\'effervescence dans un flacon de verre épais relève de la haute alchimie. L\'autolyse prolongée des levures sur lattes confère brioche, noisette torréfiée et une mousse crémeuse incomparable.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'La bulle fine est le rire du vin, scintillant et éternel. »',
      chatmelierLoreEn:
          '« 🥂 THE MIRACLE OF SECONDARY FERMENTATION:\n\n'
          'From Dom Pérignon to heritage houses, capturing effervescence is liquid alchemy. Extended lees aging yields brioche, roasted hazelnuts, and velvety mousse.\n\n'
          '🍷 CHATMELIER\'S WORDS:\n'
          'The fine bubble is the sparkle of wine itself. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'savant_flight_discovery',
      title: 'Flight Découverte',
      titleEn: 'Discovery Tasting Flight',
      emoji: '🍷',
      assetImagePath: 'assets/badges/savant_flight_discovery.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Explorer un enchaînement de 3 verres suggéré lors du scan d\'une carte des vins.',
      descriptionEn: 'Explore a 3-glass progression flight suggested from a scanned wine list.',
      chatmelierLore:
          '« L\'art du flight réside dans la progression : un blanc vif pour éveiller les papilles, un rosé ou rouge soyeux pour l\'ampleur, et une cuvée de caractère pour conclure avec éclat. »',
      chatmelierLoreEn:
          '« The art of the flight lies in progression: a crisp white to awaken the palate, an elegant red for depth, and a wine of distinction to crown the experience. »',
    ),
    WineBadge(
      id: 'savant_consensus_table_master',
      title: 'Maître de Table',
      titleEn: 'Master of the Table',
      emoji: '👥',
      assetImagePath: 'assets/badges/savant_consensus_table_master.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Partager le menu scanné via QR code pour choisir ensemble et trouver l\'accord parfait en groupe.',
      descriptionEn: 'Share a scanned menu via QR code to reach group consensus and find the perfect table wine.',
      chatmelierLore:
          '« Trouver le flacon qui comble simultanément les amateurs de fraîcheur minérale et les amoureux de tanins soyeux est la marque des plus grands hôtes. »',
      chatmelierLoreEn:
          '« Selecting the bottle that unites every palate around the table is the hallmark of the greatest hosts. »',
    ),

  ];
}
