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
      emoji: '🍾',
      assetImagePath: 'assets/badges/milestone_bottles_50.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.silver,
      description: 'Avoir au moins 50 bouteilles en stock dans sa cave.',
      chatmelierLore:
          '« Avec cinquante bouteilles, votre cave commence véritablement à respirer : vous avez des vins de plaisir immédiat pour les tablées spontanées, des cuvées de garde qui s\'affinent patiemment dans l\'obscurité, et une palette de terroirs adaptée à chaque accord mets-vins. »',
      requiredCount: 50,
    ),
    WineBadge(
      id: 'milestone_bottles_100',
      title: 'Cave de Passionné (100 vins)',
      emoji: '🏰',
      assetImagePath: 'assets/badges/milestone_bottles_100.webp',
      category: BadgeCategory.milestones,
      tier: BadgeTier.gold,
      description: 'Avoir au moins 100 bouteilles en stock dans sa cave.',
      chatmelierLore:
          '« Le cap du siècle de flacons ! Votre cave devient une collection vivante où se côtoient grands crus, pépites d\'artisans vignerons et millésimes d\'anthologie. Le Chatmelier salue une gestion rigoureuse et une passion affirmée pour les beaux terroirs. »',
      requiredCount: 100,
    ),
    WineBadge(
      id: 'milestone_bottles_500',
      title: 'Cave Patrimoniale (500 vins)',
      emoji: '🏛️',
      category: BadgeCategory.milestones,
      tier: BadgeTier.diamond,
      description: 'Avoir au moins 500 bouteilles en stock dans sa cave.',
      chatmelierLore:
          '« Cinq cents flacons sous surveillance hygrométrique constante. Vous possédez une réserve digne des plus belles cartes de sommellerie. Vos grands vins de longue garde traverseront les décennies pour offrir des moments d\'émotion inoubliables. »',
      requiredCount: 500,
    ),
    WineBadge(
      id: 'milestone_bottles_1000',
      title: 'Grande Réserve Historique (1000 vins)',
      emoji: '👑',
      category: BadgeCategory.milestones,
      tier: BadgeTier.diamond,
      description: 'Atteindre le sommet prestigieux des 1000 bouteilles en cave.',
      chatmelierLore:
          '« Mille flacons ! Vous êtes le conservateur d\'une véritable bibliothèque œnologique vivante. Chaque bouteille y témoigne d\'un climat, d\'un millésime et du travail d\'une vie de vigneron. Un accomplissement magistral salué par le Chatmelier ! »',
      requiredCount: 1000,
    ),

    // --- Paliers de Dégustation ---
    WineBadge(
      id: 'milestone_tastings_5',
      title: 'Première Goulée (5 notes)',
      emoji: '🍷',
      category: BadgeCategory.milestones,
      tier: BadgeTier.bronze,
      description: 'Avoir enregistré au moins 5 fiches de dégustation.',
      chatmelierLore:
          '« L\'apprentissage du vin commence par la première note attentive. En consignant vos 5 premières dégustations, vous commencez à structurer votre mémoire sensorielle : appréciation de la robe, intensité olfactive, équilibre des tanins et persistance en bouche. »',
      requiredCount: 5,
    ),
    WineBadge(
      id: 'milestone_tastings_25',
      title: 'Palais Affûté (25 notes)',
      emoji: '👃',
      category: BadgeCategory.milestones,
      tier: BadgeTier.silver,
      description: 'Avoir enregistré au moins 25 fiches de dégustation.',
      chatmelierLore:
          '« Vingt-cinq cuvées passées au crible ! Votre vocabulaire s\'enrichit. Vous distinguez désormais avec aisance les arômes primaires (le cépage), secondaires (la fermentation et les levures) et tertiaires (l\'élevage en barrique et le vieillissement en bouteille). »',
      requiredCount: 25,
    ),
    WineBadge(
      id: 'milestone_tastings_50',
      title: 'Sommelier Amateur (50 notes)',
      emoji: '📜',
      category: BadgeCategory.milestones,
      tier: BadgeTier.gold,
      description: 'Avoir consigné au moins 50 dégustations dans son carnet.',
      chatmelierLore:
          '« Cinquante dégustations documentées avec méthode ! Votre esprit critique est affûté : vous décelez les défauts comme les éclats de génie, et vos proches se tournent volontiers vers vos recommandations pour choisir les bouteilles à table. »',
      requiredCount: 50,
    ),
    WineBadge(
      id: 'milestone_tastings_100',
      title: 'Grand Dégustateur (100 notes)',
      emoji: '🏆',
      category: BadgeCategory.milestones,
      tier: BadgeTier.diamond,
      description: 'Avoir consigné au moins 100 dégustations dans son carnet.',
      chatmelierLore:
          '« Cent dégustations enregistrées ! Votre journal est un carnet de route précieux. De l\'attaque en bouche à la longueur mesurée en caudalies, vous décryptez le vin avec l\'assurance d\'un sommelier chevronné. »',
      requiredCount: 100,
    ),
    WineBadge(
      id: 'milestone_tastings_250',
      title: 'Maître de Dégustation (250 notes)',
      emoji: '🔮',
      category: BadgeCategory.milestones,
      tier: BadgeTier.diamond,
      description: 'Avoir franchi le palier remarquable des 250 dégustations.',
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
      emoji: '🏰',
      category: BadgeCategory.continents,
      tier: BadgeTier.bronze,
      description: 'Déguster au moins 3 vins européens (France, Italie, Espagne, Portugal, etc.).',
      chatmelierLore:
          '« L\'Europe a forgé le concept moderne de "terroir" : l\'alchimie indissoluble entre géologie, microclimat et savoir-faire vigneron ancestral. Des coteaux du Rhin aux terrasses du Douro, c\'est ici que la vigne Vitis vinifera a écrit ses lettres de noblesse. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'continent_new_world',
      title: 'Le Nouveau Monde',
      emoji: '🌎',
      category: BadgeCategory.continents,
      tier: BadgeTier.silver,
      description: 'Déguster au moins 2 vins hors-Europe (USA, Chili, Argentine, Australie, Afrique du Sud...).',
      chatmelierLore:
          '« Des brumes marines de la Napa Valley aux contreforts des Andes argentines, le Nouveau Monde a renouvelé les approches traditionnelles par l\'éclat du fruit mûr, la précision technologique et une liberté variétale sans complexe. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'continent_globe_trotter',
      title: 'Tour du Monde en 80 Verres',
      emoji: '✈️',
      category: BadgeCategory.continents,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté des vins provenant d\'au moins 5 pays différents.',
      chatmelierLore:
          '« La vigne s\'épanouit aujourd\'hui du 30e au 50e parallèle dans les deux hémisphères. Déguster cinq pays différents démontre une curiosité sans frontières, toujours prêt à découvrir un cépage méconnu et un terroir singulier. »',
      requiredCount: 5,
    ),
    WineBadge(
      id: 'continent_explorer',
      title: 'Explorateur des Terroirs',
      emoji: '🧭',
      category: BadgeCategory.continents,
      tier: BadgeTier.gold,
      description: 'Avoir dégusté des vins provenant d\'au moins 10 pays différents.',
      chatmelierLore:
          '« Dix nations viticoles explorées ! Du Liban à la Nouvelle-Zélande en passant par la Géorgie et l\'Afrique du Sud, vous expérimentez la diversité des styles et des cultures viticoles à travers le monde. »',
      requiredCount: 10,
    ),
    WineBadge(
      id: 'continent_universal',
      title: 'Atlas Universel des Vins',
      emoji: '🌌',
      category: BadgeCategory.continents,
      tier: BadgeTier.diamond,
      description: 'Avoir dégusté des vins issus d\'au moins 20 pays différents.',
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
      emoji: '🇫🇷',
      assetImagePath: 'assets/badges/country_france.webp',
      category: BadgeCategory.countries,
      tier: BadgeTier.bronze,
      description: 'Avoir au moins 3 vins français dans sa cave ou son carnet.',
      chatmelierLore:
          '« Avec plus de 360 Appellations d\'Origine Contrôlée (AOC), la France est une mosaïque géologique sans équivalent : craie de Champagne, galets roulés du Rhône, schistes d\'Anjou ou calcaires bourguignons. Une référence incontournable de la gastronomie mondiale. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'country_italy',
      title: 'La Dolce Vita',
      emoji: '🇮🇹',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou possédé au moins 2 vins d\'Italie (Chianti, Barolo, Prosecco...).',
      chatmelierLore:
          '« Les Grecs anciens la baptisèrent "Oenotria", la terre du vin. L\'Italie abrite plus de 500 cépages autochtones jalousement préservés, du Sangiovese toscan au Nebbiolo piémontais, offrant une acidité gastronomique inimitable taillée pour la table. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'country_spain',
      title: 'Ferveur Ibérique',
      emoji: '🇪🇸',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou possédé au moins 2 vins espagnols (Rioja, Priorat, Ribera del Duero...).',
      chatmelierLore:
          '« L\'Espagne possède le plus vaste vignoble de la planète par sa surface. Ses élevages patients en fûts de chêne (Crianza, Reserva, Gran Reserva) et ses terroirs de schiste (Llicorella du Priorat) offrent des vins profonds, complexes et élégants. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'country_usa',
      title: 'Rêve Californien',
      emoji: '🇺🇸',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou possédé au moins 1 vin des États-Unis (Napa, Sonoma, Oregon, Washington...).',
      chatmelierLore:
          '« Le Jugement de Paris de 1976 a marqué l\'histoire moderne : lors d\'une dégustation à l\'aveugle mythique, les Cabernets et Chardonnays de Californie rivalisèrent avec les plus prestigieux Premiers Grands Crus, propulsant le vignoble américain sur le devant de la scène mondiale. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_portugal',
      title: 'Légende du Douro',
      emoji: '🇵🇹',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou possédé au moins 1 vin du Portugal (Douro, Alentejo, Porto, Dão...).',
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
      emoji: '👑',
      assetImagePath: 'assets/badges/region_bourgogne.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 3 vins de Bourgogne.',
      chatmelierLore:
          '« En Bourgogne, le sol change tous les cinquante mètres. Les "Climats", ces parcelles minutieusement délimitées depuis un millénaire et inscrites au patrimoine de l\'UNESCO, subliment le Pinot Noir et le Chardonnay avec une finesse inégalée. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'region_bordeaux',
      title: 'Seigneur de Bordeaux',
      emoji: '🏛️',
      assetImagePath: 'assets/badges/region_bordeaux.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 3 vins de Bordeaux (Médoc, Saint-Émilion, Pomerol, Graves...).',
      chatmelierLore:
          '« Le classement impérial de 1855, commandé par Napoléon III, régit toujours la hiérarchie des Premiers Grands Crus du Médoc et de Sauternes. Entre graves garonnaises et argiles bleues de Pomerol, Bordeaux incarne l\'art souverain de l\'assemblage millimétré. »',
      requiredCount: 3,
    ),
    WineBadge(
      id: 'region_rhone',
      title: 'Chevalier du Rhône',
      emoji: '⚔️',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de la Vallée du Rhône.',
      chatmelierLore:
          '« Du granite escarpé de Côte-Rôtie jusqu\'aux galets roulés gorgés de chaleur à Châteauneuf-du-Pape, le Rhône allie la tension poivrée de la Syrah septentrionale à la générosité solaire du Grenache méridional. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_champagne',
      title: 'Chasseur d\'Étoiles',
      emoji: '🍾',
      assetImagePath: 'assets/badges/region_champagne.webp',
      category: BadgeCategory.regions,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 2 champagnes ou vins effervescents de méthode traditionnelle.',
      chatmelierLore:
          '« "Venez vite, je bois des étoiles !" La tradition attribue cette formule à Dom Pérignon à l\'abbaye d\'Hautvillers. L\'effervescence naturelle née de la prise de mousse en bouteille et la fraîcheur des craies jurassiques signent le vin de fête absolu. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_loire',
      title: 'Poète du Val de Loire',
      emoji: '🌿',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de la Loire (Sancerre, Chinon, Saumur, Vouvray...).',
      chatmelierLore:
          '« Fleuve royal bordé de châteaux Renaissance, la Loire déploie des vins d\'une fraîcheur cristalline grâce à la pierre de tuffeau blanc et son climat tempéré. Chenin blanc et Cabernet franc y trouvent leur expression la plus pure et digeste. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_alsace',
      title: 'Sentinelle Rhénane',
      emoji: '🥨',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins d\'Alsace.',
      chatmelierLore:
          '« Abrité des pluies océaniques par les Vosges, le vignoble d\'Alsace bénéficie d\'un climat sec et ensoleillé propice à une remarquable maturité phénolique. La pureté de ses cépages nobles (Riesling, Gewurztraminer, Pinot Gris) s\'exprime sur des terroirs géologiques d\'une grande diversité. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_provence',
      title: 'Soleil de Provence',
      emoji: '🌸',
      category: BadgeCategory.regions,
      tier: BadgeTier.bronze,
      description: 'Posséder ou avoir dégusté au moins 2 vins de Provence ou Corse (Bandol, Cassis, Bellet, Patrimonio...).',
      chatmelierLore:
          '« C\'est ici que les Phocéens fondèrent Marseille en 600 av. J.-C. et développèrent la viticulture. Des grands rouges de garde de Bandol dominés par le noble Mourvèdre aux rosés salins et pâles de gastronomie, la Provence respire le terroir méditerranéen. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_jura_savoie',
      title: 'L\'Or Jaune & Alpin',
      emoji: '🏔️',
      category: BadgeCategory.regions,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 vin du Jura ou de Savoie (Vin Jaune, Savagnin, Mondeuse, Chignin...).',
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
      emoji: '🍒',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 cuvées à dominante Pinot Noir.',
      chatmelierLore:
          '« Cépage délicat et exigeant à la pellicule fine, le Pinot Noir demande un soin méticuleux à la vigne et au chai. Sur les coteaux calcaires, il livre des arômes subtils de griotte, de rose séchée et de sous-bois d\'une élégance rare. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_cabernet',
      title: 'Maître du Cabernet',
      emoji: '🍇',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 cuvées à dominante Cabernet Sauvignon.',
      chatmelierLore:
          '« Issu d\'un croisement historique entre le Cabernet Franc et le Sauvignon Blanc, le Cabernet Sauvignon est l\'épine dorsale des grands vins de longue garde grâce à sa trame tannique ferme et ses notes nobles de cassis, cèdre et boîte à cigares. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_chardonnay',
      title: 'Reine du Chardonnay',
      emoji: '🥂',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 cuvées à dominante Chardonnay.',
      chatmelierLore:
          '« Véritable caméléon de la viticulture mondiale : tendu, minéral et salin sur les calcaires kimméridgiens de Chablis, il se révèle riche, beurré et brioché lorsqu\'il est élevé sur lies en fûts de chêne à Meursault ou dans les vallées californiennes. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_syrah',
      title: 'Mystique de la Syrah',
      emoji: '🌶️',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 cuvées à dominante Syrah (Shiraz).',
      chatmelierLore:
          '« Sa signature aromatique provient de la molécule de rotondone présente dans la pellicule du raisin. C\'est elle qui confère à la Syrah cette note reconnaissable de poivre noir fraîchement moulu, mêlée à la violette et à l\'olive noire. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_chenin',
      title: 'Alchimiste du Chenin',
      emoji: '🍯',
      category: BadgeCategory.grapes,
      tier: BadgeTier.gold,
      description: 'Déguster ou avoir en cave au moins 1 vin issu du cépage Chenin Blanc.',
      chatmelierLore:
          '« L\'un des cépages blancs les plus complets au monde. Du blanc sec minéral et tranchant aux fines bulles, jusqu\'aux grands liquoreux centenaires de Loire, le Chenin traverse les décennies soutenu par une remarquable acidité naturelle. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'grape_riesling',
      title: 'Cristal de Riesling',
      emoji: '💎',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 1 Riesling.',
      chatmelierLore:
          '« Le Riesling exprime la typicité de son sol sans artifice de bois neuf. En évoluant, il développe des nuances aromatiques fascinantes (TDN) d\'agrumes confits, de fleurs blanches et de fines notes minérales très appréciées des connaisseurs. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'grape_nebbiolo',
      title: 'Seigneur des Brumes',
      emoji: '🌫️',
      category: BadgeCategory.grapes,
      tier: BadgeTier.gold,
      description: 'Déguster ou posséder au moins 1 vin à base de Nebbiolo (Barolo, Barbaresco...).',
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
      emoji: '🎯',
      assetImagePath: 'assets/badges/aging_peak.webp',
      category: BadgeCategory.aging,
      tier: BadgeTier.gold,
      description: 'Avoir dégusté un vin exactement dans sa fenêtre d\'apogée optimale.',
      chatmelierLore:
          '« Déguster un vin à son apogée, c\'est saisir l\'équilibre idéal où les tanins se sont veloutés tandis que le bouquet tertiaire exhale toute sa complexité. Félicitations pour ce sens du timing exemplaire ! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'aging_venerable',
      title: 'Flacon Vénérable',
      emoji: '🕰️',
      category: BadgeCategory.aging,
      tier: BadgeTier.diamond,
      description: 'Déguster ou posséder en cave une bouteille âgée de 25 ans ou plus.',
      chatmelierLore:
          '« Ouvrir une bouteille de plus d\'un quart de siècle, c\'est découvrir un pan d\'histoire liquide. La robe s\'est parée de reflets ambrés, le fruit s\'est mué en cuir noble, thé noir et sous-bois. Un grand moment de dégustation. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'aging_infanticide',
      title: 'Infanticide Œnologique',
      emoji: '👶',
      category: BadgeCategory.aging,
      tier: BadgeTier.bronze,
      description: 'Avoir bu un grand vin de garde avec plus de 5 ans d\'avance sur son apogée.',
      chatmelierLore:
          '« Les tanins étaient encore un peu fermes et serrés, n\'est-ce pas ? Goûter un grand vin dans sa prime jeunesse est une expérience instructive que tout amateur réalise un jour pour appréhender le potentiel d\'évolution. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🍸 MIXOLOGIE & COCKTAILS
    // ==========================================
    WineBadge(
      id: 'cocktail_apprentice',
      title: 'Apprenti Shaker',
      emoji: '🍸',
      assetImagePath: 'assets/badges/cocktail_apprentice.webp',
      category: BadgeCategory.cocktails,
      tier: BadgeTier.bronze,
      description: 'Avoir dégusté ou réalisé au moins 1 cocktail dans l\'application.',
      chatmelierLore:
          '« La mixologie partage avec la sommellerie la quête de l\'équilibre précis entre acidité, sucres, amertume et dilution pour mettre en valeur les arômes des spiritueux. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'cocktail_master',
      title: 'Maître Mixologue',
      emoji: '🍹',
      category: BadgeCategory.cocktails,
      tier: BadgeTier.silver,
      description: 'Avoir dégusté ou préparé au moins 5 cocktails différents.',
      chatmelierLore:
          '« Negroni, Old Fashioned, Daiquiri, Dry Martini, Manhattan... Vous maîtrisez les proportions classiques qui font la renommée des grands bars du monde entier. »',
      requiredCount: 5,
    ),
    WineBadge(
      id: 'cocktail_expert',
      title: 'Grand Alchimiste du Shaker',
      emoji: '🧪',
      category: BadgeCategory.cocktails,
      tier: BadgeTier.gold,
      description: 'Avoir dégusté ou préparé au moins 15 cocktails différents.',
      chatmelierLore:
          '« Quinze recettes maîtrisées ! Des cocktails sours émulsionnés aux créations plus complexes associant bitters et spiritueux vieillis, vous manipulez jigger et cuillère à mélange avec dextérité. »',
      requiredCount: 15,
    ),
    WineBadge(
      id: 'cocktail_legend',
      title: 'Légende du Comptoir',
      emoji: '🌟',
      category: BadgeCategory.cocktails,
      tier: BadgeTier.diamond,
      description: 'Avoir exploré ou conçu au moins 30 cocktails différents.',
      chatmelierLore:
          '« Trente cocktails variés à votre répertoire ! Vous associez les saveurs avec une créativité remarquable et maîtrisez l\'art des accords et des présentations soignées. »',
      requiredCount: 30,
    ),
    WineBadge(
      id: 'cocktail_pantry',
      title: 'Barman Prévoyant',
      emoji: '🧊',
      category: BadgeCategory.cocktails,
      tier: BadgeTier.silver,
      description: 'Avoir au moins 5 ingrédients en stock dans la Réserve du Bar (Bar Pantry).',
      chatmelierLore:
          '« Bitters réputés, vermouth de qualité, agrumes frais et beaux glaçons : une réserve bien constituée est la clé d\'un accueil réussi pour toutes les occasions. »',
      requiredCount: 5,
    ),

    // ==========================================
    // 🥃 SPIRITUEUX & ALCOOLS FORTS
    // ==========================================
    WineBadge(
      id: 'spirit_whisky',
      title: 'Gentleman du Malt',
      emoji: '🥃',
      assetImagePath: 'assets/badges/spirit_whisky.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 Whisky (Single Malt, Bourbon, Tourbé...).',
      chatmelierLore:
          '« De la tourbe fumée des distilleries d\'Islay aux fûts de chêne neuf brûlés du Kentucky, le whisky illustre le mariage séculaire entre le grain malté, l\'eau pure et le temps passé sous bois. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_gin',
      title: 'Botaniste de l\'Alambic',
      emoji: '🌿',
      assetImagePath: 'assets/badges/spirit_gin.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.bronze,
      description: 'Posséder ou avoir dégusté au moins 1 Gin.',
      chatmelierLore:
          '« Né aux Pays-Bas sous le nom de Genever comme remède médicinal, le gin distille les baies de genièvre (Juniperus communis), la graine de coriandre et les écorces d\'agrumes par infusion vapeur. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_rhum',
      title: 'Élixir de Canne',
      emoji: '🦜',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 Rhum (agricole ou mélasse).',
      chatmelierLore:
          '« Pur jus de canne fraîche en Martinique (AOC Rhum Agricole) ou distillation de mélasse en alambics à repasse en Jamaïque : le rhum offre une palette aromatique chaleureuse de fruits exotiques et de vanille. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_brandy',
      title: 'Noblesse Charentaise',
      emoji: '🍇',
      category: BadgeCategory.spirits,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 Cognac ou Armagnac.',
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
      emoji: '⚰️',
      assetImagePath: 'assets/badges/looser_past_peak.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.silver,
      description: 'Avoir bu un vin bien après son apogée (statut Passé).',
      chatmelierLore:
          '« Oublié pendant une décennie au fond d\'un placard tiède... La robe tirait sur le madère sombre et le nez évoquait la pomme blette, mais vous l\'avez goûté par curiosité ! La science œnologique progresse aussi par l\'expérience. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_masochist',
      title: 'Masochiste du Terroir 🤢',
      emoji: '🦨',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Avoir attribué une note assassine (inférieure ou égale à 2/10 ou 1/5).',
      chatmelierLore:
          '« Vin déviant ou jus sans âme ? Votre palais a été mis à rude épreuve, mais votre honnêteté critique évitera sans doute à vos proches une mauvaise surprise. Bravo pour votre franchise de dégustateur ! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_bouchonne',
      title: 'Bouchonné mais Vaillant 🪵',
      emoji: '🌳',
      assetImagePath: 'assets/badges/looser_bouchonne.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.silver,
      description: 'Avoir mentionné "bouchon" ou "bouchonné" dans une note de dégustation.',
      chatmelierLore:
          '« La redoutée molécule de 2,4,6-trichloroanisole (TCA) ! Cette odeur caractéristique de carton mouillé et de cave humide capable d\'altérer même le plus grand flacon à des concentrations infinitésimales. L\'aléa classique du bouchon de liège. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_solo',
      title: 'Le Fond de Bouteille 🍷',
      emoji: '🕯️',
      assetImagePath: 'assets/badges/looser_solo.webp',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Avoir enregistré une dégustation en tête-à-tête avec vous-même sans co-dégustateurs.',
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
      emoji: '📜',
      assetImagePath: 'assets/badges/savant_cistercien.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Posséder ou déguster un vin blanc ou rouge de Bourgogne issu d\'un sol calcaire.',
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
      emoji: '🔬',
      assetImagePath: 'assets/badges/savant_phylloxera.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Avoir au moins 5 bouteilles en cave issues de vignes greffées.',
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
      emoji: '🎩',
      assetImagePath: 'assets/badges/savant_napoleon.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin de Gevrey-Chambertin ou de Bourgogne Grand Cru.',
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
      emoji: '🌋',
      assetImagePath: 'assets/badges/savant_volcan.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin de terroir volcanique (Sicile/Etna, Canaries, Santorin, Auvergne, Campanie...).',
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
      emoji: '✨',
      assetImagePath: 'assets/badges/savant_biodynamie.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Déguster ou posséder un vin certifié Demeter, Biodyvin ou cultivé en biodynamie.',
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
      emoji: '🏺',
      assetImagePath: 'assets/badges/savant_amphore.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin élevé en amphore, jarre de terre cuite, Qvevri géorgien ou un vin orange.',
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
      emoji: '🍯',
      assetImagePath: 'assets/badges/savant_botrytis.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin liquoreux d\'exception issu de pourriture noble (Sauternes, Tokaj, Grains Nobles...).',
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
      emoji: '🍒',
      assetImagePath: 'assets/badges/savant_maceration_carbonique.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Déguster un vin issu de macération carbonique ou semi-carbonique (Beaujolais, Gamay primeur...).',
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
      emoji: '🦪',
      assetImagePath: 'assets/badges/savant_kimmeridgien.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un Chablis, Sancerre Terres Blanches ou vin issu de marne calcaire kimméridgienne.',
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
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins d\'Allemagne (Mosel, Rheingau...).',
      chatmelierLore:
          '« Les coteaux vertigineux de schiste de la Moselle et les méandres du Rhin enfantent des Rieslings d\'une tension acide et d\'une minéralité cristalline sans équivalent dans le monde. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'country_switzerland',
      title: 'Altitude Helvétique',
      titleEn: 'Swiss High Altitude',
      emoji: '🇨🇭',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Suisse (Valais, Vaud, Lavaux...).',
      chatmelierLore:
          '« Des terrasses de Lavaux plongeant dans le lac Léman aux coteaux de Visperterminen, la Suisse façonne le Chasselas (Fendant), la Petite Arvine et le Cornalin avec une précision d\'orfèvre. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_argentina',
      title: 'L\'Âme des Andes',
      titleEn: 'Soul of the Andes',
      emoji: '🇦🇷',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin d\'Argentine (Mendoza, Cafayate...).',
      chatmelierLore:
          '« Perché à plus de 1000 mètres d\'altitude au pied des neiges éternelles de la Cordillère des Andes, le vignoble de Mendoza magnifie le Malbec en nectars profonds, soyeux et solaires. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_chile',
      title: 'Sous l\'Ombre des Cordillères',
      titleEn: 'Shadow of the Cordilleras',
      emoji: '🇨🇱',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin du Chili (Maipo, Colchagua...).',
      chatmelierLore:
          '« Isolé par l\'océan Pacifique et la barrière des Andes, le Chili est un sanctuaire préservant des vignes franches de pied et le mythique cépage bordelais Carménère, sauvé de l\'oubli. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_australia',
      title: 'Terre Rouge d\'Oz',
      titleEn: 'Red Soil of Oz',
      emoji: '🇦🇺',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin d\'Australie (Barossa, Margaret River...).',
      chatmelierLore:
          '« Des ceps centenaires de Shiraz de Barossa Valley ancrés dans la terre rouge aux Cabernets racés de Margaret River, l\'Australie concilie tradition séculaire et viticulture de pointe. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_new_zealand',
      title: 'Le Bout du Monde',
      titleEn: 'The Edge of the World',
      emoji: '🇳🇿',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Nouvelle-Zélande (Marlborough, Central Otago...).',
      chatmelierLore:
          '« Les brises du Pacifique sculptent l\'éclat aromatique vif du Sauvignon Blanc de Marlborough et la pureté éclatante du Pinot Noir de Central Otago. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_south_africa',
      title: 'Le Cap des Bonnes Espérances',
      titleEn: 'Cape of Good Hope',
      emoji: '🇿🇦',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin d\'Afrique du Sud (Stellenbosch, Swartland...).',
      chatmelierLore:
          '« Fondé dès 1685 à Constantia, le vignoble sud-africain s\'épanouit entre deux océans. Le Chenin Blanc (Steen) et le Pinotage autochtone y signent des vins de haute distinction. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_greece',
      title: 'L\'Héritage de Dionysos',
      titleEn: 'Heritage of Dionysus',
      emoji: '🇬🇷',
      category: BadgeCategory.countries,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Grèce (Santorin, Naoussa, Némée...).',
      chatmelierLore:
          '« Sur l\'île volcanique de Santorin, les vignes d\'Assyrtiko sont tressées en paniers protecteurs au sol (Kouloura) pour braver les vents égéens, offrant une acidité minérale et saline unique. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_austria',
      title: 'L\'Élégance Danubienne',
      titleEn: 'Danubian Elegance',
      emoji: '🇦🇹',
      category: BadgeCategory.countries,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin d\'Autriche (Wachau, Kamptal, Burgenland...).',
      chatmelierLore:
          '« Sur les terrasses de gneiss surplombant le Danube en Wachau, le Grüner Veltliner livre ses notes incomparables de poivre blanc et de pomme fraîche dans une pureté cristalline. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_georgia',
      title: 'Le Berceau Mondial',
      titleEn: 'The World\'s Cradle',
      emoji: '🇬🇪',
      category: BadgeCategory.countries,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Géorgie (Kakhétie, Saperavi...).',
      chatmelierLore:
          '« 8000 ans de viticulture ininterrompue ! La Géorgie est la terre originelle du vin. Ses élevages en Qvevri et ses cépages ancestraux Saperavi et Rkatsiteli font partie du trésor de l\'humanité. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'country_uk',
      title: 'Le Renouveau Britannique',
      titleEn: 'The British Revival',
      emoji: '🇬🇧',
      category: BadgeCategory.countries,
      tier: BadgeTier.bronze,
      description: 'Posséder ou avoir dégusté au moins 1 vin ou effervescent du Royaume-Uni (Sussex, Kent...).',
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
      emoji: '🦆',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins du Sud-Ouest (Cahors, Madiran, Jurançon...).',
      chatmelierLore:
          '« Des vins noirs de Cahors bâtis sur le Malbec aux blancs parfumés de Jurançon nés du Petit Manseng au pied des Pyrénées, le Sud-Ouest célèbre la noblesse et l\'authenticité gasconne. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_languedoc_roussillon',
      title: 'Garrigue & Méditerranée',
      emoji: '🌿',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins du Languedoc ou Roussillon (Pic Saint-Loup, Collioure...).',
      chatmelierLore:
          '« Le plus vaste laboratoire viticole de France ! Entre calcaires battus par les vents et schistes de Collioure, les vignerons signent des cuvées vibrantes aux arômes de thym, ciste et romarin. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_corse',
      title: 'L\'Île de Beauté',
      emoji: '🏝️',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Corse (Patrimonio, Ajaccio, Calvi...).',
      chatmelierLore:
          '« Arènes granitiques, schistes et soleil insulaire : les cépages autochtones corses (le poivré Sciaccarello et le noble Nielluccio) offrent des vins méditerranéens d\'un équilibre saisissant. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'region_beaujolais',
      title: 'Les Dix Crus du Beaujolais',
      emoji: '🍇',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins du Beaujolais (Morgon, Moulin-à-Vent, Fleurie...).',
      chatmelierLore:
          '« Sur les arènes granitiques et les roches bleues de la Côte du Py, le Gamay engendre de superbes vins de garde aux accents de cerise noire, épices douces et pivoine sauvage. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_toscana',
      title: 'Renaissance Toscane',
      emoji: '🏛️',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de Toscane (Chianti, Brunello, Bolgheri...).',
      chatmelierLore:
          '« Entre collines de cyprès et abbayes médiévales, la Toscane magnifie le Sangiovese sur les sols de Galestro et a conquis la planète avec les légendaires Super-Toscans de Bolgheri. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_piemonte',
      title: 'Noblesse Piémontaise',
      emoji: '👑',
      category: BadgeCategory.regions,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 2 vins du Piémont (Barolo, Barbaresco, Langhe...).',
      chatmelierLore:
          '« "Le vin des rois et le roi des vins" : Barolo et Barbaresco règnent sur les collines embrumées des Langhe. Leurs marnes argilo-calcaires offrent au Nebbiolo une profondeur aromatique unique. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_veneto',
      title: 'Sérénissime Vénétie',
      emoji: '🎭',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de Vénétie (Amarone, Valpolicella, Soave...).',
      chatmelierLore:
          '« L\'art noble de l\'Appassimento ! Les raisins passerillés sur claies de bois pendant les mois d\'hiver concentrent leurs sucs pour donner naissance à l\'Amarone della Valpolicella, vin monumental. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_rioja',
      title: 'Chêne & Rioja',
      emoji: '🍷',
      category: BadgeCategory.regions,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 2 vins de la Rioja (Crianza, Reserva...).',
      chatmelierLore:
          '« Berceau historique de la viticulture espagnole sur l\'Èbre, la Rioja excelle dans les élevages sous bois où le Tempranillo acquiert des nuances suaves de cuir, vanille et tabac blond. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'region_napa',
      title: 'L\'Or de Napa Valley',
      emoji: '🌉',
      category: BadgeCategory.regions,
      tier: BadgeTier.gold,
      description: 'Posséder ou avoir dégusté au moins 1 vin de Napa Valley (Rutherford, Oakville...).',
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
      emoji: '🫐',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins à dominante Merlot (Pomerol, Saint-Émilion...).',
      chatmelierLore:
          '« Cépage emblématique de la rive droite bordelaise, le Merlot séduit par sa chair pulpeuse, sa texture veloutée et ses arômes gourmands de prune noire, mûre et chocolat noir. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_sauvignon_blanc',
      title: 'L\'Éclat du Sauvignon Blanc',
      emoji: '🍋',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins de Sauvignon Blanc (Sancerre, Pouilly-Fumé...).',
      chatmelierLore:
          '« Réputé pour son acidité vivifiante et sa fraîcheur aromatique ! Sur le silex, il offre une note minérale de pierre à fusil ; sur le calcaire, il exhale les agrumes et le buis. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_grenache',
      title: 'Le Généreux Grenache',
      emoji: '☀️',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins à dominante Grenache (Rhône sud, Priorat...).',
      chatmelierLore:
          '« Roi du pourtour méditerranéen bravant le vent et la sécheresse, le Grenache offre une texture ronde et soyeuse, accompagnée de notes de fraise confite, poivre et garrigue. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_cabernet_franc',
      title: 'La Finesse du Cabernet Franc',
      emoji: '🪨',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins de Cabernet Franc (Chinon, Bourgueil, Saumur...).',
      chatmelierLore:
          '« Père génétique du Cabernet Sauvignon et du Merlot, le Cabernet Franc charme par son élégance ligérienne : parfums de framboise sauvage, touche de graphite et note florale de violette. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_sangiovese',
      title: 'Le Sang de Jupiter',
      emoji: '🦁',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins issus du Sangiovese (Chianti, Brunello...).',
      chatmelierLore:
          '« Son nom latin "Sanguis Jovis" évoque le roi des dieux romains. Robe rubis étincelante, acidité tonique et arômes de cerise griotte et thé noir : le partenaire gastronomique parfait. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_malbec',
      title: 'La Nuit Noire du Malbec',
      emoji: '🖤',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins à dominante Malbec / Côt (Cahors, Mendoza...).',
      chatmelierLore:
          '« Le "vin noir" du Moyen Âge ! Le Malbec possède une robe d\'encre pourpre et tapisse la bouche d\'arômes denses de mûre sauvage, cassis, réglisse noire et violette. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_tempranillo',
      title: 'L\'Âme du Tempranillo',
      emoji: '🇪🇸',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 2 vins issus du Tempranillo (Rioja, Ribera del Duero...).',
      chatmelierLore:
          '« Mûrissant tôt ("temprano") sous le soleil ibérique, le Tempranillo allie une trame tannique soyeuse à des notes nobles de cerise noire, cuir, boîte à cigares et vanille bourbon. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_gamay',
      title: 'La Fraîcheur du Gamay',
      emoji: '🍓',
      category: BadgeCategory.grapes,
      tier: BadgeTier.bronze,
      description: 'Déguster ou avoir en cave au moins 2 vins issus du Gamay (Beaujolais, Loire...).',
      chatmelierLore:
          '« Banni de Bourgogne en 1395 par Philippe le Hardi, le Gamay a trouvé sur les granites du Beaujolais son sanctuaire pour offrir des jus gouleyants débordant de fruits rouges frais. »',
      requiredCount: 2,
    ),
    WineBadge(
      id: 'grape_viognier',
      title: 'L\'Arôme du Viognier',
      emoji: '🍑',
      category: BadgeCategory.grapes,
      tier: BadgeTier.gold,
      description: 'Déguster ou avoir en cave au moins 1 vin issu du cépage Viognier (Condrieu...).',
      chatmelierLore:
          '« Sauvé in extremis de la disparition dans les années 1960, le Viognier envoûte par son profil suave et son bouquet opulent d\'abricot mûr, pêche de vigne et fleur de violette. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'grape_gewurztraminer',
      title: 'L\'Épice du Gewurztraminer',
      emoji: '🌹',
      category: BadgeCategory.grapes,
      tier: BadgeTier.silver,
      description: 'Déguster ou avoir en cave au moins 1 Gewurztraminer (Alsace...).',
      chatmelierLore:
          '« "Gewürz" signifie épicé en allemand : ce cépage à la robe dorée séduit par son intensité phénoménale de pétale de rose fraîche, litchi, gingembre confit et poivre blanc. »',
      requiredCount: 1,
    ),

    // ==========================================
    // 🍸 NOUVEAUX BADGES MIXOLOGIE & SPIRITUEUX
    // ==========================================
    WineBadge(
      id: 'cocktail_diy_shaker',
      title: 'Système D & Shaker Maison',
      emoji: '🫙',
      category: BadgeCategory.cocktails,
      tier: BadgeTier.bronze,
      description: 'Avoir préparé un cocktail avec la méthode shaker maison ou bocal hermétique.',
      chatmelierLore:
          '« Pas besoin d\'équipement de bar étoilé pour réussir un cocktail harmonieux ! Un bocal de confiture bien fermé fait un shaker d\'exception. L\'ingéniosité au service du goût. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'cocktail_spritz',
      title: 'L\'Heure de l\'Apéritivo',
      emoji: '🍹',
      category: BadgeCategory.cocktails,
      tier: BadgeTier.bronze,
      description: 'Avoir préparé ou dégusté un cocktail de style Spritz, Negroni ou Americano.',
      chatmelierLore:
          '« Né à Venise au XIXe siècle lorsque les soldats allongeaient le vin blanc d\'eau gazeuse ("spritzen"), le Spritz est devenu le rituel mondial de l\'amitié et du soleil couchant. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_tequila_mezcal',
      title: 'L\'Or Sacré de l\'Agave',
      emoji: '🌵',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 Tequila 100% Agave ou Mezcal artisanal.',
      chatmelierLore:
          '« Les cœurs d\'agave cuits dans des fosses en pierre souterraines à Oaxaca révèlent des arômes minéraux, fumés et terreux d\'une complexité captivante. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_vodka',
      title: 'La Pureté du Grain',
      emoji: '❄️',
      assetImagePath: 'assets/badges/spirit_vodka.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.bronze,
      description: 'Posséder ou avoir dégusté au moins 1 Vodka de tradition (blé, seigle...).',
      chatmelierLore:
          '« Distillée avec une pureté rigoureuse et filtrée lentement, la grande vodka révèle la rondeur soyeuse du blé ou le piquant poivré du seigle slave. »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'spirit_liqueurs',
      title: 'L\'Élixir des Herboristes',
      emoji: '🌿',
      assetImagePath: 'assets/badges/spirit_liqueurs.webp',
      category: BadgeCategory.spirits,
      tier: BadgeTier.silver,
      description: 'Posséder ou avoir dégusté au moins 1 liqueur de plantes, Amaro, Pastis ou Chartreuse.',
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
      emoji: '🕸️',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Posséder une bouteille entrée en cave depuis plus de 3 ans sans jamais l\'ouvrir.',
      chatmelierLore:
          '« Elle dort sagement au fond de la cave sous une noble couche de poussière... On guette la fameuse "grande occasion", alors que chaque soir peut devenir une fête ! »',
      requiredCount: 1,
    ),
    WineBadge(
      id: 'looser_tache_etiquette',
      title: 'La Goutte Rebelle 🍷',
      emoji: '🩸',
      category: BadgeCategory.looser,
      tier: BadgeTier.bronze,
      description: 'Avoir consigné une tache sur étiquette, une coulure ou une maladresse de service.',
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
      emoji: '📜',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un grand cru historique d\'Hermitage, Sauternes (Yquem) ou Montepulciano.',
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
      emoji: '🪨',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin de terroir de schiste (Priorat, Côte-Rôtie, Collioure, Douro, Faugères...).',
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
      emoji: '💨',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.silver,
      description: 'Déguster un vin de la Vallée du Rhône ou de Provence balayé par le Mistral.',
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
      emoji: '👑',
      assetImagePath: 'assets/badges/savant_alienor.webp',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.gold,
      description: 'Déguster un vin de Bordeaux (Graves, Médoc, Clairet) en hommage au vignoble bordelais.',
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
      emoji: '🧀',
      category: BadgeCategory.chatmelierSavant,
      tier: BadgeTier.diamond,
      description: 'Déguster un Vin Jaune du Jura ou un Sherry Jerez Fino / Manzanilla sous voile de levures.',
      chatmelierLore:
          '« 🧀 LA MERVEILLE DE L\'ÉLEVAGE OXYDATIF BIOLOGIQUE :\n\n'
          'En fût non ouillé, un voile protecteur de levures vivantes (Saccharomyces beticus) se forme à la surface du vin. Il bloque l\'oxydation brutale tout en créant la molécule de sotolon aux arômes fascinants de noix fraîche, curry doux, amande amère et pomme verte séchée.\n\n'
          '🍷 LE MOT DU CHATMELIER :\n'
          'L\'une des plus grandes énigmes œnologiques : confier le vin au temps et à l\'air pour engendrer un chef-d\'œuvre immortel. »',
      requiredCount: 1,
    ),
  ];
}
