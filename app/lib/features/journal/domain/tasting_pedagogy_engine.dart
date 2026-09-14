import '../../cellar/domain/wine.dart';

enum FlavorOriginCategory { grape, oak, terroir, age }

class FlavorOriginCard {
  final String title;
  final String icon;
  final FlavorOriginCategory category;
  final String sensoryContribution;
  final String detailedWhy;
  final String? badgeText;

  const FlavorOriginCard({
    required this.title,
    required this.icon,
    required this.category,
    required this.sensoryContribution,
    required this.detailedWhy,
    this.badgeText,
  });
}

class NuanceItem {
  final String name;
  final String origin; // e.g. 'Cépage', 'Élevage barrique', 'Vieillissement', 'Terroir'
  final String explanation;

  const NuanceItem({
    required this.name,
    required this.origin,
    required this.explanation,
  });
}

class ScientificPillar {
  final String title;
  final String icon;
  final String chemicalKey;
  final String summary;
  final String detailedExplanation;

  const ScientificPillar({
    required this.title,
    required this.icon,
    required this.chemicalKey,
    required this.summary,
    required this.detailedExplanation,
  });
}

class TastingPedagogyReport {
  final Wine wine;
  final String? userAppearance;
  final List<String> userAromas;
  final String? userStructure;
  final int userCaudalies;
  final double userRating;

  final String archetypeAppearance;
  final List<String> archetypeAromas;
  final String archetypePalate;

  final List<String> matchingAromas;
  final List<NuanceItem> hiddenNuancesToDiscover;
  final int acuityScore; // 0 - 100%
  final String sommelierPraise;
  final List<ScientificPillar> scientificPillars;
  final List<FlavorOriginCard> flavorOrigins;

  const TastingPedagogyReport({
    required this.wine,
    this.userAppearance,
    required this.userAromas,
    this.userStructure,
    required this.userCaudalies,
    required this.userRating,
    required this.archetypeAppearance,
    required this.archetypeAromas,
    required this.archetypePalate,
    required this.matchingAromas,
    required this.hiddenNuancesToDiscover,
    required this.acuityScore,
    required this.sommelierPraise,
    required this.scientificPillars,
    this.flavorOrigins = const [],
  });
}

class TastingPedagogyEngine {
  static TastingPedagogyReport analyze({
    required Wine wine,
    String? userAppearance,
    List<String> userAromas = const [],
    String? userStructure,
    int userCaudalies = 6,
    double userRating = 8.0,
    String? userComment,
    double? userAcidity,
    double? userTannins,
    double? userBody,
    double? userLength,
    Set<String>? perceivedAromaIds,
    List<String> customAromas = const [],
  }) {
    final nameLower = '${wine.name} ${wine.producer ?? ""} ${wine.region} ${wine.appellation ?? ""} ${wine.grapes.map((g) => g.name).join(" ")}'.toLowerCase();
    final type = wine.type.toLowerCase();
    final currentYear = DateTime.now().year;
    final age = wine.vintage != null ? (currentYear - wine.vintage!) : 4;
    final isOld = age >= 8;

    String archetypeAppearance;
    List<String> archetypeAromas;
    String archetypePalate;
    final hiddenNuances = <NuanceItem>[];
    final pillars = <ScientificPillar>[];

    // Expected structural metrics for acuity calculation
    double expectedAcidity = 0.60;
    double? expectedTannins;
    double expectedBody = 0.60;
    double expectedLength = 0.65;
    Set<String> targetAromaIds = {};
    Set<String> discordantAromaIds = {};

    // ==========================================
    // 1. CHAMPAGNE & EFFERVESCENTS
    // ==========================================
    if (type.contains('spark') || nameLower.contains('champagne') || nameLower.contains('crémant') || nameLower.contains('cava')) {
      archetypeAppearance = isOld ? 'Doré éclatant aux reflets ambrés' : 'Or pâle cristallin à cordon de bulles très fin';
      archetypeAromas = ['🧈 Beurre / Brioche', '🍯 Miel / Cire', '🪨 Minéral / Craie', '🍋 Agrumes / Zeste', '🍒 Fruits rouges'];
      archetypePalate = 'Attaque vive et crémeuse, effervescence soyeuse, finale saline et crayeuse d\'une grande persistance.';

      expectedAcidity = 0.82;
      expectedTannins = null;
      expectedBody = 0.50;
      expectedLength = 0.75;
      targetAromaIds = {'beurre', 'mineral', 'miel', 'agrumes', 'fruits_blancs', 'fruits_rouges'};
      discordantAromaIds = {'epices_vives', 'chocolat'};

      hiddenNuances.add(const NuanceItem(
        name: 'Brioche tiède & Beurre noisette',
        origin: 'Autolyse des levures',
        explanation: 'Durant le séjour sur lattes de plusieurs années, les levures meurent et libèrent des mannoprotéines et du diacétyle.',
      ));
      hiddenNuances.add(const NuanceItem(
        name: 'Touche iodée & Craie vive',
        origin: 'Sous-sol Crétacé',
        explanation: 'Les racines plongent dans le calcaire actif de la craie champenoise, apportant cette fraîcheur saline inimitable.',
      ));

      pillars.add(const ScientificPillar(
        title: 'Prise de mousse & Autolyse des Levures',
        icon: '🍾',
        chemicalKey: 'Mannoprotéines • Diacétyle (C4H6O2)',
        summary: 'Pourquoi le Champagne sent la brioche et le pain grillé ?',
        detailedExplanation: 'La seconde fermentation en bouteille emprisonne le gaz carbonique sous 6 bars de pression. Au fil des mois, les levures s\'autolysent, enrichissant le vin en acides aminés et esters complexes qui donnent ce goût beurré, brioché et cette texture de bulle soyeuse.',
      ));

      pillars.add(const ScientificPillar(
        title: 'Terroir de Craie & Acidité Ciselée',
        icon: '🪨',
        chemicalKey: 'Acide Tartrique • Carbonate de Calcium (CaCO3)',
        summary: 'La sensation de pureté minérale et de fraîcheur tranchante.',
        detailedExplanation: 'Le sous-sol calcaire régule parfaitement l\'eau et la température des racines. Il préserve un pH très bas et une concentration exceptionnelle d\'acide tartrique qui garantit une garde de plusieurs décennies sans lourdeur.',
      ));
    }

    // ==========================================
    // 2. VINS ROUGES PUISSANTS & TANNIQUES (Bordeaux, Bandol, Rhône Sud, Cahors, Madiran, Rioja)
    // ==========================================
    else if (type.contains('red') && (nameLower.contains('bordeaux') || nameLower.contains('bandol') || nameLower.contains('terrebrune') || nameLower.contains('mourvèdre') || nameLower.contains('mourvedre') || nameLower.contains('cabernet') || nameLower.contains('syrah') || nameLower.contains('rioja') || nameLower.contains('cahors') || nameLower.contains('madiran'))) {
      archetypeAppearance = isOld ? 'Grenat profond avec reflets tuilés / brique' : 'Pourpre sombre et profond, reflets violacés';
      archetypeAromas = ['🫐 Fruits noirs', '🪵 Boisé / Chêne', '🌶️ Poivre / Épices', '🌲 Sous-bois / Humus', '☕ Cacao / Torréfaction'];
      archetypePalate = 'Attaque ample et charnue, tanins denses et structurés, finale puissante imprégnée d\'épices et de bois noble.';

      expectedAcidity = 0.52;
      expectedTannins = isOld ? 0.70 : 0.85;
      expectedBody = 0.80;
      expectedLength = isOld ? 0.80 : 0.75;
      targetAromaIds = {'fruits_noirs', 'epices_vives', 'boise', 'chocolat', 'fumee'};
      if (isOld) targetAromaIds.addAll({'mineral', 'fruits_rouges'});
      discordantAromaIds = {'agrumes', 'beurre', 'fruits_blancs'};

      hiddenNuances.add(const NuanceItem(
        name: 'Poivre noir moulu & Garrigue',
        origin: 'Molécule Rotundone',
        explanation: 'Présente dans la peau des cépages Syrah et Mourvèdre, la rotundone est détectable dès 16 nanogrammes par litre !',
      ));
      if (isOld) {
        hiddenNuances.add(const NuanceItem(
          name: 'Cuir noble & Sous-bois humide',
          origin: 'Évolution tertiaire',
          explanation: 'La lente micro-oxydation polymérise les tanins et libère des lactones et arômes de boîte à cigares.',
        ));
      } else {
        hiddenNuances.add(const NuanceItem(
          name: 'Vanille bourbon & Cacao grillé',
          origin: 'Élevage en fûts de chêne',
          explanation: 'La chauffe du bois de chêne libère de la vanilline et du gaïacol fumé au contact du vin.',
        ));
      }

      pillars.add(const ScientificPillar(
        title: 'L\'Extraction Polyphénolique & les Tanins',
        icon: '🍇',
        chemicalKey: 'Anthocyanes • Proanthocyanidines • Rotundone',
        summary: 'D\'où viennent la couleur sombre et la structure astringente ?',
        detailedExplanation: 'Durant la cuvaison (pigeages et remontages), l\'alcool extrait les anthocyanes (pigments rouges) et les tanins concentrés dans la peau et les pépins. Les tanins se lient aux protéines de votre salive, créant cette sensation tactile d\'assèchement noble qui s\'assouplit avec le temps.',
      ));

      pillars.add(const ScientificPillar(
        title: 'L\'Élevage en Fût de Chêne & Chauffe Toastée',
        icon: '🪵',
        chemicalKey: 'Vanilline (C8H8O3) • Eugénol • Gaïacol',
        summary: 'L\'alchimie entre le bois de chêne et le vin.',
        detailedExplanation: 'Le séjour de 12 à 24 mois en barriques apporte une micro-oxygénation douce à travers les pores du bois. Le toastage de la barrique caramélise les sucres du chêne, infusant des molécules de vanilline (vanille), d\'eugénol (clou de girofle) et de gaïacol (notes de grillé, café, cacao).',
      ));

      pillars.add(ScientificPillar(
        title: isOld ? 'La Polymérisation & les Arômes Tertiaires' : 'Le Potentiel de Garde & la Réduction d\'Astringence',
        icon: '⏳',
        chemicalKey: 'Polymérisation Anthocyane-Tanin • Éthers',
        summary: isOld ? 'Pourquoi le vin prend des notes de sous-bois et de cuir ?' : 'Pourquoi ce vin va se bonifier pendant 10 ans ?',
        detailedExplanation: 'Avec les années de garde en bouteille, les molécules de tanins et d\'anthocyanes s\'agrègent en longues chaînes (polymères). Ce processus adoucit l\'amertume et fait émerger les arômes tertiaires de sous-bois, truffe, cuir et tabac blond.',
      ));
    }

    // ==========================================
    // 3. VINS ROUGES ÉLÉGANTS & DÉLICATS (Bourgogne, Pinot Noir, Loire, Beaujolais, Etna)
    // ==========================================
    else if (type.contains('red')) {
      archetypeAppearance = isOld ? 'Rubis évolué avec disque tuilé translucide' : 'Rubis brillant et limpide, d\'intensité moyenne';
      archetypeAromas = ['🍒 Fruits rouges', '🌸 Floral / Violette', '🌲 Sous-bois / Humus', '🌿 Végétal noble', '🪵 Boisé / Chêne'];
      archetypePalate = 'Attaque soyeuse et dentelée, tanins fins comme de la soie, équilibre frais et finale saline très aérienne.';

      expectedAcidity = 0.72;
      expectedTannins = 0.38;
      expectedBody = 0.48;
      expectedLength = 0.68;
      targetAromaIds = {'fruits_rouges', 'floral', 'vegetal', 'boise', 'epices_douces'};
      discordantAromaIds = {'agrumes', 'fruits_blancs'};

      hiddenNuances.add(const NuanceItem(
        name: 'Cerise griotte & Framboise sauvage',
        origin: 'Esters du Pinot Noir',
        explanation: 'La fermentation douce à température contrôlée préserve les esters de fruits frais très volatils.',
      ));
      hiddenNuances.add(const NuanceItem(
        name: 'Pétale de rose fanée & Violette',
        origin: 'β-damascénone & Terpènes',
        explanation: 'Molécules florales nobles très typiques des grands terroirs calcaires de Bourgogne et de Loire.',
      ));

      pillars.add(const ScientificPillar(
        title: 'La Délicatesse du Cépage & Macération Douce',
        icon: '🍒',
        chemicalKey: 'β-Damascénone • Esters Éthyliques',
        summary: 'Pourquoi le Pinot Noir / Gamay est si soyeux et aérien ?',
        detailedExplanation: 'Ces cépages possèdent une peau fine pauvre en tanins agressifs mais gorgée de précurseurs d\'arômes floraux et fruités. Une macération en vendange entière ou pré-fermentaire à froid permet de capturer la pureté du fruit sans extraire d\'amertume végétale.',
      ));

      pillars.add(const ScientificPillar(
        title: 'Le Rôle du Terroir Calcaire & Schisteux',
        icon: '⛰️',
        chemicalKey: 'Drainage Calcaire • Équilibre Acido-Basique',
        summary: 'La sensation de verticalité minérale en bouche.',
        detailedExplanation: 'Les sols argilo-calcaires limitent la vigueur de la vigne. L\'apport régulier en minéraux soutient une acidité naturelle éclatante qui étire la finale en bouche sans sensation de lourdeur alcoolique.',
      ));
    }

    // ==========================================
    // 4. VINS BLANCS SECS & MINÉRAUX (Chablis, Sancerre, Riesling, Muscadet, Rías Baixas)
    // ==========================================
    else if (type.contains('white') && (nameLower.contains('chablis') || nameLower.contains('sancerre') || nameLower.contains('sauvignon') || nameLower.contains('riesling') || nameLower.contains('albarino') || nameLower.contains('muscadet'))) {
      archetypeAppearance = 'Or pâle aux reflets verts scintillants';
      archetypeAromas = ['🍋 Agrumes / Zeste', '🪨 Minéral / Craie', '🌸 Floral / Violette', '🌿 Végétal noble', '🍯 Miel / Cire'];
      archetypePalate = 'Attaque droite, ciselée et tranchante, tension saline magistrale, finale vibrante d\'agrumes et de pierre à fusil.';

      expectedAcidity = 0.85;
      expectedTannins = null;
      expectedBody = 0.45;
      expectedLength = 0.70;
      targetAromaIds = {'agrumes', 'mineral', 'floral', 'vegetal', 'fruits_blancs'};
      discordantAromaIds = {'fruits_noirs', 'chocolat', 'epices_vives'};

      hiddenNuances.add(const NuanceItem(
        name: 'Pierre à fusil & Coquille d\'huître',
        origin: 'Kimméridgien / Terroir',
        explanation: 'Présence de fossiles marins (Exogyra virgula) dans les marnes qui renforcent l\'impression saline et iodée.',
      ));
      hiddenNuances.add(const NuanceItem(
        name: 'Pamplemousse rose & Buis noble',
        origin: 'Thiols Variétaux',
        explanation: 'Molécules 3-mercaptohexanol (3-MH) libérées par l\'action des levures durant la fermentation.',
      ));

      pillars.add(const ScientificPillar(
        title: 'Les Thiols Variétaux & Terpènes Vifs',
        icon: '🍋',
        chemicalKey: '3-Mercaptohexanol (3-MH) • Linalol',
        summary: 'Le secret des arômes explosifs d\'agrumes et de fruits exotiques.',
        detailedExplanation: 'Le raisin blanc contient des précurseurs aromatiques liés à des acides aminés (cystéine). Durant la vinification à basse température, l\'activité enzymatique des levures rompt ces liaisons, libérant les thiols volatils responsables des notes d\'agrumes et de zeste.',
      ));

      pillars.add(const ScientificPillar(
        title: 'La Salinité & la Tension de l\'Acide Malique/Tartrique',
        icon: '⚡',
        chemicalKey: 'Acide Malique • Acide Tartrique (C4H6O6)',
        summary: 'Pourquoi le vin fait-il saliver avec une telle énergie ?',
        detailedExplanation: 'Dans les blancs septentrionaux, la fermentation malolactique est souvent évitée ou partielle pour préserver l\'acide malique vif. Cette acidité stimule directement les glandes salivaires et agit comme un exhausteur de goût naturel.',
      ));
    }

    // ==========================================
    // 5. VINS BLANCS GRAS & ÉLEVÉS SOUS BOIS (Bourgogne Blanc, Meursault, Rhône Blanc, Viognier)
    // ==========================================
    else if (type.contains('white')) {
      archetypeAppearance = 'Or doré brillant et profond';
      archetypeAromas = ['🧈 Beurre / Brioche', '🪵 Boisé / Chêne', '🍯 Miel / Cire', '🍋 Agrumes / Zeste', '🌸 Floral / Violette'];
      archetypePalate = 'Attaque ample, grasse et onctueuse, matière riche tapissant le palais, rehaussée par un boisé fin et une finale vanillée.';

      expectedAcidity = 0.58;
      expectedTannins = null;
      expectedBody = 0.75;
      expectedLength = 0.75;
      targetAromaIds = {'beurre', 'boise', 'miel', 'agrumes', 'fruits_blancs', 'floral'};
      discordantAromaIds = {'fruits_noirs', 'chocolat'};

      hiddenNuances.add(const NuanceItem(
        name: 'Beurre frais & Noisette grillée',
        origin: 'Fermentation Malolactique + Bâtonnage',
        explanation: 'Le remuage régulier des lies en fût de chêne enrichit le vin en lipides et mannoprotéines onctueuses.',
      ));

      pillars.add(const ScientificPillar(
        title: 'La Fermentation Malolactique & le Diacétyle',
        icon: '🧈',
        chemicalKey: 'Oenococcus oeni • Diacétyle (C4H6O2)',
        summary: 'Comment un vin blanc devient-il beurré et velouté ?',
        detailedExplanation: 'Les bactéries lactiques transforment l\'acide malique pointu en acide lactique doux et crémeux. Ce métabolisme produit du diacétyle, le composé aromatique qui donne au beurre frais et à la brioche leur parfum gourmand.',
      ));

      pillars.add(const ScientificPillar(
        title: 'L\'Élevage sur Lies Fines & le Bâtonnage',
        icon: '🪵',
        chemicalKey: 'Mannoprotéines • Lactones de Chêne',
        summary: 'D\'où vient cette sensation de gras enveloppant ?',
        detailedExplanation: 'Les lies fines sont remises en suspension périodiquement à l\'aide d\'une baguette de bois (bâtonnage). En se dégradant, les enveloppes des levures libèrent des macromolécules qui enrobent l\'acidité et protègent naturellement le vin de l\'oxydation.',
      ));
    }

    // ==========================================
    // 6. VINS ROSÉS GASTRONOMIQUES
    // ==========================================
    else {
      archetypeAppearance = 'Robe rose saumonée, limpide et brillante';
      archetypeAromas = ['🍒 Fruits rouges', '🍋 Agrumes / Zeste', '🌸 Floral / Violette', '🌶️ Poivre / Épices'];
      archetypePalate = 'Bouche croquante et rafraîchissante, équilibre entre fruit acidulé et fine trame saline en finale.';

      expectedAcidity = 0.65;
      expectedTannins = null;
      expectedBody = 0.42;
      expectedLength = 0.55;
      targetAromaIds = {'fruits_rouges', 'agrumes', 'floral', 'epices_douces'};
      discordantAromaIds = {'chocolat', 'boise'};

      hiddenNuances.add(const NuanceItem(
        name: 'Groseille & Zeste de pamplemousse',
        origin: 'Pressurage direct doux',
        explanation: 'Une extraction très courte limite le contact entre le jus et les peaux pour garder uniquement les arômes délicats.',
      ));

      pillars.add(const ScientificPillar(
        title: 'Le Pressurage Pneumatique & la Maîtrise des Températures',
        icon: '🌸',
        chemicalKey: 'Anthocyanes libres • Esters de Fermentation',
        summary: 'Pourquoi le rosé est-il pâle et si expressif ?',
        detailedExplanation: 'Les raisins sont pressés délicatement à froid sous atmosphère inerte pour éviter tout brunissement oxydatif. Seules les premières gouttes de jus claires sont conservées pour fermenter à 14-16°C.',
      ));
    }

    // =========================================================================
    // ORIGINE DES GOÛTS : CÉPAGE PAR CÉPAGE, TONNEAU & TERROIR
    // =========================================================================
    final flavorOrigins = _buildFlavorOrigins(wine, type, isOld, nameLower);

    // =========================================================================
    // CALCUL DE CONCORDANCE SENSORIELLE (ACUITÉ DISCRIMINANTE & AUTHENTIQUE)
    // =========================================================================
    final allUserAromas = [...userAromas, ...customAromas];
    final userAromasLower = allUserAromas.map((a) => a.toLowerCase()).toList();
    final matchingAromas = <String>[];

    for (final arch in archetypeAromas) {
      final keyword = arch.split(' ').last.toLowerCase();
      if (userAromasLower.any((u) => u.contains(keyword) || keyword.contains(u.replaceAll(RegExp(r'[^\w\s]'), '').trim()))) {
        matchingAromas.add(arch);
      }
    }

    // 1. Aroma Score (15 to 50 pts)
    int aromaScore = 25;
    final notesLower = (wine.tastingNotes ?? '').toLowerCase();
    final customMatches = customAromas.where((c) {
      final cl = c.toLowerCase().trim();
      if (cl.isEmpty) return false;
      return targetAromaIds.any((t) => cl.contains(t)) ||
          archetypeAromas.any((a) => a.toLowerCase().contains(cl)) ||
          notesLower.contains(cl);
    }).length;

    if (perceivedAromaIds != null && perceivedAromaIds.isNotEmpty) {
      final matchesCount = perceivedAromaIds.where((id) => targetAromaIds.contains(id)).length;
      final discordantCount = perceivedAromaIds.where((id) => discordantAromaIds.contains(id)).length;
      aromaScore = (25 + (matchesCount * 10) + (customMatches * 4) - (discordantCount * 6)).clamp(15, 50);
    } else if (matchingAromas.isNotEmpty) {
      aromaScore = (25 + (matchingAromas.length * 10) + (customMatches * 4)).clamp(15, 50);
    } else if (customMatches > 0) {
      aromaScore = (25 + (customMatches * 5)).clamp(15, 50);
    } else if (allUserAromas.isNotEmpty) {
      aromaScore = 22; // User picked aromas but none matched archetype
    }

    // 2. Palate Balance Score (10 to 35 pts)
    int palateScore = 25;
    if (userAcidity != null && userBody != null) {
      final errors = <double>[
        (userAcidity - expectedAcidity).abs(),
        (userBody - expectedBody).abs(),
        if (userLength != null) (userLength - expectedLength).abs() else 0.1,
      ];
      if (expectedTannins != null && userTannins != null) {
        errors.add((userTannins - expectedTannins).abs());
      }
      final avgError = errors.reduce((a, b) => a + b) / errors.length;
      palateScore = (35 * (1.0 - (avgError * 1.5))).round().clamp(10, 35);
    } else if (userStructure != null && userStructure.isNotEmpty) {
      // Legacy text evaluation
      final s = userStructure.toLowerCase();
      palateScore = s.contains('tanin') ||
              s.contains('vivac') ||
              s.contains('frais') ||
              s.contains('équilibr') ||
              s.contains('equilibr')
          ? 26
          : 18;
    }

    // 3. Details & Sensory Engagement Score (5 to 15 pts)
    int detailsScore = 5;
    if (userAppearance != null && userAppearance.isNotEmpty) detailsScore += 4;
    if (userCaudalies >= 8) {
      detailsScore += 5;
    } else if (userCaudalies >= 5) {
      detailsScore += 3;
    }
    if (userRating >= 9.0) {
      detailsScore += 4;
    } else if (userRating >= 7.0) {
      detailsScore += 2;
    }

    final rawScore = aromaScore + palateScore + detailsScore;
    final finalAcuity = rawScore.clamp(48, 98);

    String praise;
    if (finalAcuity >= 90) {
      praise = 'Nez d\'Or & Dégustateur Averti 🏆 Vous avez immédiatement identifié les marqueurs cardinaux de ce flacon.';
    } else if (finalAcuity >= 80) {
      praise = 'Excellente acuité sensorielle ✨ Vous avez décelé les composantes majeures du vin et de sa structure.';
    } else if (finalAcuity >= 65) {
      praise = 'Belle intuition sensorielle 🍷 Votre perception capte de jolis traits du vin ; explorez ci-dessous les nuances subtiles.';
    } else {
      praise = 'Exploration sensorielle prometteuse 🍇 Laissez vos sens s\'aiguiser en découvrant les secrets moléculaires ci-dessous.';
    }

    return TastingPedagogyReport(
      wine: wine,
      userAppearance: userAppearance,
      userAromas: userAromas,
      userStructure: userStructure,
      userCaudalies: userCaudalies,
      userRating: userRating,
      archetypeAppearance: archetypeAppearance,
      archetypeAromas: archetypeAromas,
      archetypePalate: archetypePalate,
      matchingAromas: matchingAromas,
      hiddenNuancesToDiscover: hiddenNuances,
      acuityScore: finalAcuity,
      sommelierPraise: praise,
      scientificPillars: pillars,
      flavorOrigins: flavorOrigins,
    );
  }

  /// Builds pedagogical breakdown cards explaining where the tastes come from:
  /// grape varieties, oak aging, bottle age, and terroir.
  static List<FlavorOriginCard> _buildFlavorOrigins(Wine wine, String type, bool isOld, String nameLower) {
    final cards = <FlavorOriginCard>[];
    final isRed = type.contains('red');
    final isWhite = type.contains('white');

    // Collect all grapes mentioned either in wine.grapes or deduced from text
    final recognizedGrapes = <String>{};
    for (final g in wine.grapes) {
      recognizedGrapes.add(g.name.toLowerCase().trim());
    }

    // Deduction from appellation or wine name if grapes list is empty
    if (recognizedGrapes.isEmpty) {
      if (nameLower.contains('bandol') || nameLower.contains('terrebrune')) {
        recognizedGrapes.addAll(['mourvèdre', 'grenache', 'cinsault']);
      } else if (nameLower.contains('bordeaux') || nameLower.contains('pauillac') || nameLower.contains('médoc') || nameLower.contains('saint-émilion') || nameLower.contains('pomerol')) {
        recognizedGrapes.addAll(['cabernet sauvignon', 'merlot', 'cabernet franc']);
      } else if (nameLower.contains('bourgogne') || nameLower.contains('burgundy') || nameLower.contains('beaune') || nameLower.contains('nuits')) {
        recognizedGrapes.add(isRed ? 'pinot noir' : 'chardonnay');
      } else if (nameLower.contains('chablis')) {
        recognizedGrapes.add('chardonnay');
      } else if (nameLower.contains('sancerre') || nameLower.contains('pouilly')) {
        recognizedGrapes.add(isRed ? 'pinot noir' : 'sauvignon blanc');
      } else if (nameLower.contains('rhône') || nameLower.contains('rhone') || nameLower.contains('châteauneuf') || nameLower.contains('chateauneuf') || nameLower.contains('gigondas')) {
        recognizedGrapes.addAll(['grenache', 'syrah', 'mourvèdre']);
      } else if (nameLower.contains('beaujolais') || nameLower.contains('morgon') || nameLower.contains('fleurie')) {
        recognizedGrapes.add('gamay');
      } else if (nameLower.contains('cahors')) {
        recognizedGrapes.add('malbec');
      } else if (nameLower.contains('rioja')) {
        recognizedGrapes.addAll(['tempranillo', 'garnacha']);
      } else if (nameLower.contains('barolo') || nameLower.contains('barbaresco') || nameLower.contains('nebbiolo')) {
        recognizedGrapes.add('nebbiolo');
      } else if (nameLower.contains('chianti') || nameLower.contains('brunello') || nameLower.contains('sangiovese')) {
        recognizedGrapes.add('sangiovese');
      }
    }

    // --- 1. GRAPE VARIETY EXPLANATIONS ---
    for (final grape in recognizedGrapes) {
      final g = grape.toLowerCase();
      if (g.contains('mourvèdre') || g.contains('mourvedre')) {
        cards.add(const FlavorOriginCard(
          title: 'Mourvèdre (Cépage Roi)',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Structure & Cuir',
          sensoryContribution: 'Structure tannique puissante, notes profondes de fruits noirs sauvages (mûre, myrtille), de cuir noble, de garrigue et de sous-bois.',
          detailedWhy: 'Cépage phare de Bandol et de Méditerranée, le Mourvèdre mûrit lentement face à la mer. Sa peau très épaisse est gorgée de polyphénols nobles qui lui donnent cette mâche dense en bouche et son exceptionnel potentiel de garde.',
        ));
      } else if (g.contains('carignan')) {
        cards.add(const FlavorOriginCard(
          title: 'Carignan (Cépage de Terroir)',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Fraîcheur & Épices',
          sensoryContribution: 'Robe sombre et éclatante, vivacité acide désaltérante, notes de petits fruits noirs acidulés, thym et romarin.',
          detailedWhy: 'Issu de vieilles vignes de schistes ou de calcaire, le Carignan apporte la fraîcheur acide indispensable qui équilibre la puissance solaire des vins du Sud, avec une trame épicée racée.',
        ));
      } else if (g.contains('syrah') || g.contains('shiraz')) {
        cards.add(const FlavorOriginCard(
          title: 'Syrah (Cépage Aromatique)',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Couleur & Poivre (Rotundone)',
          sensoryContribution: 'Robe sombre aux reflets violacés intenses, arômes emblématiques de poivre noir moulu, violette fraîche, tapenade et fruits noirs.',
          detailedWhy: 'La pellicule de la Syrah concentre de la rotundone, une molécule ultra-aromatique détectable dès 16 nanogrammes/L qui donne cette signature poivrée inimitable. Elle enrichit le vin en anthocyanes violettes et en tanins soyeux.',
        ));
      } else if (g.contains('grenache') || g.contains('garnacha')) {
        cards.add(const FlavorOriginCard(
          title: 'Grenache (Cépage de Rondeur)',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Rondeur & Cerise confite',
          sensoryContribution: 'Attaque ronde et veloutée, chaleur gourmande en alcool, arômes séducteurs de cerise kirschée, pruneau confit et cannelle.',
          detailedWhy: 'Gorgé de sucres naturels qui se transforment en alcool soyeux, le Grenache enrobe les tanins plus fermes de ses partenaires d\'assemblage et apporte cette générosité chaleureuse typique des grands rouges méditerranéens.',
        ));
      } else if (g.contains('cabernet sauvignon')) {
        cards.add(const FlavorOriginCard(
          title: 'Cabernet Sauvignon',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Armature & Cassis',
          sensoryContribution: 'Armature tannique droite et ferme, cassis intense, boîte à cigares (cèdre) et fraîcheur mentholée.',
          detailedWhy: 'Ses petites baies à peau épaisse apportent une concentration polyphénolique hors du commun. Il bâtit la colonne vertébrale tannique du vin qui traverse les décennies.',
        ));
      } else if (g.contains('merlot')) {
        cards.add(const FlavorOriginCard(
          title: 'Merlot',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Velouté & Cacao',
          sensoryContribution: 'Texture suave et veloutée, tanins fondus dès l\'attaque, arômes charmeurs de prune noire mûre, cerise burlat et chocolat.',
          detailedWhy: 'Mûrissant précocement sur des sols argileux frais, le Merlot apporte la chair et la gourmandise en milieu de bouche, rendant le vin caressant.',
        ));
      } else if (g.contains('cabernet franc')) {
        cards.add(const FlavorOriginCard(
          title: 'Cabernet Franc',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Élégance & Graphite',
          sensoryContribution: 'Finesse aérienne, croquant de framboise et groseille, iris floral et touche minérale de graphite/crayon.',
          detailedWhy: 'Père génétique du Cabernet Sauvignon et du Merlot, il privilégie l\'élégance aromatique et la fraîcheur végétale noble plutôt que l\'opulence brute.',
        ));
      } else if (g.contains('pinot noir')) {
        cards.add(const FlavorOriginCard(
          title: 'Pinot Noir',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Dentelle & Griotte',
          sensoryContribution: 'Robe rubis translucide, dentelle tannique ultra-fine, cerise griotte, framboise sauvage, rose fanée et sous-bois.',
          detailedWhy: 'Cépage de grande délicatesse, sa peau fine produit des tanins doux comme de la soie et une palette d\'esters aromatiques floraux d\'une pureté inégalée.',
        ));
      } else if (g.contains('gamay')) {
        cards.add(const FlavorOriginCard(
          title: 'Gamay',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Croquant & Fruit frais',
          sensoryContribution: 'Fruit rouge croquant et juteux (fraise, framboise), pivoine florale et acidité désaltérante sans tanins agressifs.',
          detailedWhy: 'Idéal en macération semi-carbonique, il exhale des arômes de fruits frais très friands avec une teneur en tanins faible et digeste.',
        ));
      } else if (g.contains('malbec') || g.contains('côt')) {
        cards.add(const FlavorOriginCard(
          title: 'Malbec',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Densité & Mûre',
          sensoryContribution: 'Robe d\'un pourpre presque noir, bouche dense et charnue, mûre sauvage, violette et cacao amer.',
          detailedWhy: 'Très riche en polyphénols, le Malbec donne des vins sombres à la trame serrée, d\'une grande concentration en bouche.',
        ));
      } else if (g.contains('cinsault')) {
        cards.add(const FlavorOriginCard(
          title: 'Cinsault',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Légèreté & Pêche',
          sensoryContribution: 'Fraîcheur aérienne, faible astringence, notes de grenade, pêche de vigne et pétales de rose.',
          detailedWhy: 'Cépage à gros grains peu coloré, il allège les assemblages rouges et constitue la base soyeuse des plus grands rosés de Provence.',
        ));
      } else if (g.contains('chardonnay')) {
        cards.add(const FlavorOriginCard(
          title: 'Chardonnay',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Gras & Beurre noisette',
          sensoryContribution: 'Corps ample et crémeux, pomme golden, agrumes mûrs, beurre frais, noisette grillée et brioche.',
          detailedWhy: 'Caméléon de l\'œnologie, il absorbe admirablement le travail sur lies (bâtonnage) et l\'élevage en fûts pour gagner son opulence gourmande.',
        ));
      } else if (g.contains('sauvignon')) {
        cards.add(const FlavorOriginCard(
          title: 'Sauvignon Blanc',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Tension & Thiols vifs',
          sensoryContribution: 'Vivacité tranchante, pamplemousse rose, citron vert, buis noble, pierre à fusil et bourgeon de cassis.',
          detailedWhy: 'Extrêmement riche en thiols variétaux (3-mercaptohexanol), ses arômes jaillissent du verre dès l\'agitation avec une sensation de fraîcheur éclatante.',
        ));
      } else if (g.contains('chenin')) {
        cards.add(const FlavorOriginCard(
          title: 'Chenin Blanc',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Minéralité & Coing',
          sensoryContribution: 'Acidité ciselée et vibrante, minéralité crayeuse, pomme reinette, coing mûr et miel d\'acacia.',
          detailedWhy: 'L\'un des cépages blancs les plus nobles et polyvalents au monde, son acidité tartrique exceptionnelle lui confère une longévité prodigieuse.',
        ));
      } else if (g.contains('riesling')) {
        cards.add(const FlavorOriginCard(
          title: 'Riesling',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Pureté & Ciselé',
          sensoryContribution: 'Pureté cristalline, acidité tranchante, citron vert, fleurs blanches et notes minérales/pétrolées fascinantes en vieillissant.',
          detailedWhy: 'Le Riesling retranscrit la géologie du sol avec une précision chirurgicale sans jamais être masqué par l\'élevage en bois neuf.',
        ));
      } else if (g.contains('viognier')) {
        cards.add(const FlavorOriginCard(
          title: 'Viognier',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Abricot & Opulence',
          sensoryContribution: 'Texture grasse et enveloppante, faible acidité, parfum capiteux d\'abricot mûr, pêche blanche et chèvrefeuille.',
          detailedWhy: 'Ses terpènes abondants s\'expriment à pleine maturité dans la Vallée du Rhône Nord (Condrieu), créant un velouté floral en bouche.',
        ));
      } else if (g.contains('gewurztraminer')) {
        cards.add(const FlavorOriginCard(
          title: 'Gewurztraminer',
          icon: '🍇',
          category: FlavorOriginCategory.grape,
          badgeText: 'Litchi & Épices',
          sensoryContribution: 'Bouquet exubérant de litchi, eau de rose, gingembre, cannelle et zeste d\'orange confite.',
          detailedWhy: 'Ses baies rosées concentrent des précurseurs terpéniques et épicés d\'une intensité aromatique unique parmi tous les cépages blancs.',
        ));
      }
    }

    // Fallback if no specific grape was matched: add a general varietal card
    if (cards.isEmpty) {
      cards.add(FlavorOriginCard(
        title: isRed ? 'Cépages Rouges & Polyphénols' : (isWhite ? 'Cépages Blancs & Terpènes' : 'Cépages & Pressurage Doux'),
        icon: '🍇',
        category: FlavorOriginCategory.grape,
        badgeText: 'Expression Variétale',
        sensoryContribution: isRed
            ? 'Fruit rouge ou noir, structure tannique et reflets pourpres.'
            : (isWhite ? 'Fraîcheur fruitée, éclat minéral et acidité ciselée.' : 'Fraîcheur acidulée et robe saumonée délicate.'),
        detailedWhy: 'Les composants aromatiques primaires du raisin sont préservés par la fermentation à température maîtrisée.',
      ));
    }

    // --- 2. OAK BARREL / ÉLEVAGE EN TONNEAU ---
    final barrelText = '${wine.barrelAging ?? ""} ${wine.tastingNotes ?? ""}'.toLowerCase();
    final hasOak = barrelText.contains('fût') ||
        barrelText.contains('barrique') ||
        barrelText.contains('oak') ||
        barrelText.contains('bois') ||
        barrelText.contains('chêne') ||
        barrelText.contains('tonneau') ||
        nameLower.contains('barrique') ||
        nameLower.contains('chêne') ||
        nameLower.contains('fût') ||
        (isRed && (nameLower.contains('bordeaux') || nameLower.contains('bandol') || nameLower.contains('rioja') || nameLower.contains('bourgogne')));

    if (hasOak) {
      cards.add(const FlavorOriginCard(
        title: 'Élevage en Fût de Chêne (Temps en Tonneau)',
        icon: '🪵',
        category: FlavorOriginCategory.oak,
        badgeText: 'Micro-oxygénation & Vanilline',
        sensoryContribution: 'Assouplissement des tanins rugueux, apport d\'arômes de vanille bourbon, pain grillé, cacao et clou de girofle.',
        detailedWhy: 'Le temps passé en tonneau opère deux métamorphoses capitales :\n1. L\'assouplissement tactile : la porosité naturelle du chêne assure une micro-oxygénation lente qui polymérise les tanins, les rendant fondus au lieu d\'être agressifs.\n2. L\'empreinte aromatique : la chauffe du bois au feu de tonnelier libère de la vanilline (vanille), du gaïacol (notes grillées/fumées) et de l\'eugénol (épices douces).',
      ));
    } else {
      cards.add(const FlavorOriginCard(
        title: 'Élevage en Cuve Inox (Sans contact boisé)',
        icon: '✨',
        category: FlavorOriginCategory.oak,
        badgeText: 'Pureté du fruit',
        sensoryContribution: 'Préservation intégrale du fruit frais, vivacité intacte et franchise absolue du terroir.',
        detailedWhy: 'La cuve thermo-régulée protège le vin de toute oxydation et n\'apporte aucun tanin extérieur, assurant une pureté cristalline des arômes primaires du raisin.',
      ));
    }

    // --- 3. BOTTLE AGE & TERTIARY BOUQUET ---
    if (isOld) {
      cards.add(const FlavorOriginCard(
        title: 'Évolution & Garde en Cave (Arômes Tertiaires)',
        icon: '⏳',
        category: FlavorOriginCategory.age,
        badgeText: 'Bouquet tertiaire',
        sensoryContribution: 'Teinte grenat aux nuances tuilées/brique, arômes patinés de sous-bois, truffe, cuir et tabac blond.',
        detailedWhy: 'Le vieillissement en bouteille sous bouchon scellé provoque une polymérisation lente en milieu réducteur. Les arômes fruités primaires se subliment en notes tertiaires de grande complexité.',
      ));
    }

    // --- 4. TERROIR & CLIMAT ---
    final regionDisplay = wine.region.isNotEmpty ? wine.region : (wine.appellation ?? 'Terroir');
    cards.add(FlavorOriginCard(
      title: 'Empreinte du Terroir & Climat ($regionDisplay)',
      icon: '⛰️',
      category: FlavorOriginCategory.terroir,
      badgeText: regionDisplay,
      sensoryContribution: 'Équilibre subtil entre maturité solaire, concentration en sucre et fraîcheur minérale saline.',
      detailedWhy: 'La composition du sol (calcaire, argiles, galets ou schistes) régule l\'alimentation en eau de la vigne, tandis que l\'ensoleillement et les nuits fraîches forgent la vivacité et la signature aromatique du cru.',
    ));

    return cards;
  }
}
