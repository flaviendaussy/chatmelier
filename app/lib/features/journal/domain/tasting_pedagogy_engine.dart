import '../../cellar/domain/wine.dart';

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
  }) {
    final nameLower = '${wine.name} ${wine.producer} ${wine.region} ${wine.appellation ?? ""} ${wine.grapes.map((g) => g.name).join(" ")}'.toLowerCase();
    final type = wine.type.toLowerCase();
    final currentYear = DateTime.now().year;
    final age = wine.vintage != null ? (currentYear - wine.vintage!) : 4;
    final isOld = age >= 8;

    String archetypeAppearance;
    List<String> archetypeAromas;
    String archetypePalate;
    final hiddenNuances = <NuanceItem>[];
    final pillars = <ScientificPillar>[];

    // ==========================================
    // 1. CHAMPAGNE & EFFERVESCENTS
    // ==========================================
    if (type.contains('spark') || nameLower.contains('champagne') || nameLower.contains('crémant') || nameLower.contains('cava')) {
      archetypeAppearance = isOld ? 'Doré éclatant aux reflets ambrés' : 'Or pâle cristallin à cordon de bulles très fin';
      archetypeAromas = ['🧈 Beurre / Brioche', '🍯 Miel / Cire', '🪨 Minéral / Craie', '🍋 Agrumes / Zeste', '🍒 Fruits rouges'];
      archetypePalate = 'Attaque vive et crémeuse, effervescence soyeuse, finale saline et crayeuse d\'une grande persistance.';

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
    else if (type.contains('red') && (nameLower.contains('bordeaux') || nameLower.contains('bandol') || nameLower.contains('terrebrune') || nameLower.contains('mourvèdre') || nameLower.contains('cabernet') || nameLower.contains('syrah') || nameLower.contains('rioja') || nameLower.contains('cahors') || nameLower.contains('madiran'))) {
      archetypeAppearance = isOld ? 'Grenat profond avec reflets tuilés / brique' : 'Pourpre sombre et profond, reflets violacés';
      archetypeAromas = ['🫐 Fruits noirs', '🪵 Boisé / Chêne', '🌶️ Poivre / Épices', '🌲 Sous-bois / Humus', '☕ Cacao / Torréfaction'];
      archetypePalate = 'Attaque ample et charnue, tanins denses et structurés, finale puissante imprégnée d\'épices et de bois noble.';

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

    // ==========================================
    // CALCUL DE CONCORDANCE SENSORIELLE (ACUITÉ)
    // ==========================================
    final userAromasLower = userAromas.map((a) => a.toLowerCase()).toList();
    final matchingAromas = <String>[];

    for (final arch in archetypeAromas) {
      final keyword = arch.split(' ').last.toLowerCase();
      if (userAromasLower.any((u) => u.contains(keyword) || keyword.contains(u.replaceAll(RegExp(r'[^\w\s]'), '').trim()))) {
        matchingAromas.add(arch);
      }
    }

    // Acuity score calculation
    int score = 70;
    if (userAppearance != null && userAppearance.isNotEmpty) score += 5;
    if (userStructure != null && userStructure.isNotEmpty) score += 5;
    if (matchingAromas.isNotEmpty) {
      score += (matchingAromas.length * 7).clamp(0, 20);
    }
    if (userCaudalies >= 5) score += 3;
    final finalAcuity = score.clamp(72, 98);

    String praise;
    if (finalAcuity >= 90) {
      praise = 'Nez d\'Or & Dégustateur Averti 🏆 Vous avez immédiatement identifié les marqueurs cardinaux de ce grand flacon.';
    } else if (finalAcuity >= 80) {
      praise = 'Excellente acuité sensorielle ✨ Vous avez décelé les composantes majeures du cépage et de la vinification.';
    } else {
      praise = 'Belle exploration sensorielle 🍷 Vous avez perçu le cœur aromatique du vin ; découvrez ci-dessous les subtilités moléculaires cachées.';
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
    );
  }
}
