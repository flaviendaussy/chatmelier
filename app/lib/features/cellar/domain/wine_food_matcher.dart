import 'bottle.dart';
import 'wine.dart';

enum FoodMatchLevel {
  ideal('Accord Idéal', 0xFFD4AF37),
  harmonious('Accord Harmonieux', 0xFF4CAF50),
  gourmet('Accord Gourmand', 0xFF2196F3),
  subtle('Accord Délicat', 0xFF9C27B0);

  final String label;
  final int colorValue;
  const FoodMatchLevel(this.label, this.colorValue);
}

class FoodPairingCategory {
  final String id;
  final String label;
  final String icon;
  final List<String> sampleDishes;
  final List<String> keywords;

  const FoodPairingCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.sampleDishes,
    required this.keywords,
  });
}

class FoodPairingMatch {
  final Bottle bottle;
  final int score; // 0 to 100
  final FoodMatchLevel matchLevel;
  final String sommelierComment;
  final String servingAdvice;

  const FoodPairingMatch({
    required this.bottle,
    required this.score,
    required this.matchLevel,
    required this.sommelierComment,
    required this.servingAdvice,
  });
}

class WineFoodMatcher {
  static const List<FoodPairingCategory> categories = [
    // 1. Red meat
    FoodPairingCategory(
      id: 'red_meat',
      label: 'Viandes Rouges & Grillades',
      icon: '🥩',
      sampleDishes: [
        'Côte de bœuf grillée',
        'Entrecôte persillée',
        'Magret de canard',
        'Tournedos Rossini',
        'Tartare de bœuf',
        'Gigot d\'agneau au thym',
        'Picanha au barbecue',
        'Bavette à l\'échalote',
      ],
      keywords: [
        'boeuf', 'bœuf', 'cote de boeuf', 'côte de bœuf', 'entrecote', 'entrecôte',
        'magret', 'canard', 'grillade', 'steak', 'agneau', 'bavette', 'tartare',
        'tournedos', 'picanha', 'onglet', 'brochette', 'faux-filet', 'chateaubriand',
        'rumsteak', 'carré d\'agneau', 't-bone', 'ribeye', 'barbecue', 'bbq', 'filet mignon de boeuf',
      ],
    ),

    // 2. Game & Stew
    FoodPairingCategory(
      id: 'game_stew',
      label: 'Gibier & Plats Mijotés',
      icon: '🦌',
      sampleDishes: [
        'Bœuf Bourguignon',
        'Daube provençale',
        'Civet de sanglier',
        'Lièvre à la royale',
        'Chevreuil aux airelles',
        'Pot-au-feu',
        'Carbonnade flamande',
        'Goulash hongrois',
      ],
      keywords: [
        'bourguignon', 'daube', 'gibier', 'sanglier', 'chevreuil', 'civet',
        'tajine agneau', 'lièvre', 'lievre', 'biche', 'goulash', 'goulasch',
        'pot-au-feu', 'pot au feu', 'carbonnade', 'joue de boeuf', 'joue de bœuf',
        'cerf', 'faisan', 'palombe', 'ragoût', 'ragout', 'navarin', 'mijoté',
      ],
    ),

    // 3. Poultry & Veal
    FoodPairingCategory(
      id: 'poultry_veal',
      label: 'Volailles Nobles & Veau',
      icon: '🍗',
      sampleDishes: [
        'Poulet rôti fermier',
        'Blanquette de veau',
        'Chapon aux marrons',
        'Quasi de veau aux morilles',
        'Escalope milanaise',
        'Pintade aux herbes',
        'Canard à l\'orange',
        'Coq au vin',
      ],
      keywords: [
        'poulet', 'volaille', 'chapon', 'dinde', 'veau', 'quasi de veau', 'quasi',
        'pintade', 'caille', 'roti', 'rôti', 'ris de veau', 'blanquette', 'escalope',
        'coq au vin', 'canard a l\'orange', 'poularde', 'supreme de volaille', 'suprême de volaille',
        'caille farcie', 'foie de veau',
      ],
    ),

    // 4. Delicate Fish & Butter sauce
    FoodPairingCategory(
      id: 'delicate_fish',
      label: 'Poissons Fins & Beurre Blanc',
      icon: '🐟',
      sampleDishes: [
        'Sole meunière',
        'Bar de ligne au four',
        'Turbot au beurre blanc',
        'Dos de cabillaud vapeur',
        'Saint-Pierre poêlé',
        'Dorade royale grillée',
        'Lotte à l\'armoricaine',
        'Truite aux amandes',
      ],
      keywords: [
        'sole', 'meuniere', 'meunière', 'bar', 'loup de mer', 'turbot', 'cabillaud',
        'saint-pierre', 'dorade', 'daurade', 'lotte', 'beurre blanc', 'truite',
        'lieu jaune', 'merlan', 'poisson blanc', 'papillote', 'poisson vapeur', 'flétan',
        'poisson au four', 'poisson', 'lotte à l\'armoricaine',
      ],
    ),

    // 5. Fatty fish, Sushi & Ceviche
    FoodPairingCategory(
      id: 'fatty_fish_sushi',
      label: 'Poissons Gras, Sushis & Ceviche',
      icon: '🍣',
      sampleDishes: [
        'Saumon grillé unilatéral',
        'Tataki de thon rouge',
        'Sushis & Sashimis variés',
        'Ceviche péruvien',
        'Saumon fumé d\'Écosse',
        'Sardines grillées',
        'Poke bowl au saumon',
        'Tartare de thon avocat',
      ],
      keywords: [
        'saumon', 'thon', 'tataki', 'sushi', 'sashimi', 'ceviche', 'poke bowl',
        'saumon fume', 'saumon fumé', 'maquereau', 'sardine', 'anchois', 'tartare de saumon',
        'thon mi-cuit', 'hareng', 'anguille', 'tartare de thon', 'gravlax', 'saumon gravlax',
      ],
    ),

    // 6. Seafood & Shellfish
    FoodPairingCategory(
      id: 'seafood_shellfish',
      label: 'Fruits de Mer, Huîtres & Crustacés',
      icon: '🦞',
      sampleDishes: [
        'Plateau d\'huîtres fraîches',
        'Homard breton grillé',
        'Noix de Saint-Jacques snackées',
        'Langoustines rôties',
        'Gambas flambées à l\'ail',
        'Moules marinières',
        'Tourteau mayonnaise',
        'Couteaux persillés',
      ],
      keywords: [
        'huitre', 'huître', 'crevette', 'homard', 'langouste', 'langoustine',
        'saint-jacques', 'st-jacques', 'fruits de mer', 'crustaces', 'crustacés',
        'gambas', 'moule', 'moules marinières', 'coquillage', 'bulot', 'bigorneau',
        'tourteau', 'crabe', 'couteau', 'palourde', 'ecrevisse', 'écrevisse',
        'plateau de fruits de mer', 'coquilles saint-jacques',
      ],
    ),

    // 7. Goat & Sheep Cheese
    FoodPairingCategory(
      id: 'goat_sheep_cheese',
      label: 'Fromages de Chèvre & Brebis',
      icon: '🐐',
      sampleDishes: [
        'Crottin de Chavignol',
        'Sainte-Maure de Touraine',
        'Banon en feuille de châtaignier',
        'Roquefort AOP',
        'Ossau-Iraty au piment d\'Espelette',
        'Manchego affiné',
        'Feta grecque',
      ],
      keywords: [
        'chevre', 'chèvre', 'crottin', 'chavignol', 'sainte-maure', 'valençay',
        'valencay', 'banon', 'pelardon', 'pélardon', 'rocamadour', 'brebis',
        'ossau-iraty', 'ossau iraty', 'manchego', 'feta', 'brocciu', 'pecorino',
        'roquefort', 'bleu', 'fromage persille', 'fourme d\'ambert', 'gorgonzola',
      ],
    ),

    // 8. Cow Milk & Pressed Cheese
    FoodPairingCategory(
      id: 'cow_pressed_cheese',
      label: 'Fromages de Vache & Pâtes Affinées',
      icon: '🧀',
      sampleDishes: [
        'Comté 18-24 mois',
        'Beaufort d\'alpage',
        'Brie de Meaux fermier',
        'Camembert de Normandie',
        'Saint-Nectaire fermier',
        'Époisses au marc de Bourgogne',
        'Reblochon de Savoie',
        'Munster alsacien',
      ],
      keywords: [
        'comte', 'comté', 'beaufort', 'gruyere', 'gruyère', 'brie', 'camembert',
        'saint-nectaire', 'saint nectaire', 'epoisses', 'époisses', 'reblochon',
        'munster', 'maroilles', 'morbier', 'cantal', 'salers', 'gouda', 'parmesan',
        'parmigiano', 'fromage', 'plateau de fromages', 'chaource', 'livarot', 'pont-l\'évêque',
      ],
    ),

    // 9. Winter melted cheese
    FoodPairingCategory(
      id: 'winter_melted_cheese',
      label: 'Raclette, Fondue & Plats d\'Hiver',
      icon: '🫕',
      sampleDishes: [
        'Raclette traditionnelle',
        'Fondue savoyarde aux 3 fromages',
        'Tartiflette au Reblochon',
        'Mont d\'Or chaud au four',
        'Croziflette aux lardons',
        'Aligot saucisse de l\'Aveyron',
        'Fondue bourguignonne',
      ],
      keywords: [
        'raclette', 'fondue', 'fondue savoyarde', 'tartiflette', 'croziflette',
        'mont d\'or', 'mont-d\'or', 'boite chaude', 'aligot', 'truffade',
        'fondue bourguignonne', 'fondue vigneronne', 'fromage fondu', 'hiver',
        'repas savoyard', 'reblochonade', 'berthoud',
      ],
    ),

    // 10. Mushrooms & Truffle
    FoodPairingCategory(
      id: 'mushrooms_truffle',
      label: 'Champignons, Risottos & Truffes',
      icon: '🍄',
      sampleDishes: [
        'Risotto crémeux aux cèpes',
        'Pâtes fraîches à la truffe noire',
        'Poêlée de morilles fraîches',
        'Omelette aux truffes',
        'Girolles sautées au persil',
        'Velouté de châtaignes et cèpes',
        'Risotto au safran et morilles',
      ],
      keywords: [
        'champignon', 'truffe', 'cepe', 'cèpe', 'morille', 'risotto', 'girolle',
        'sous-bois', 'pates aux truffes', 'pâtes aux truffes', 'omelette truffe',
        'trompette de la mort', 'chanterelle', 'bolet', 'pleurote', 'champignons',
        'risotto aux morilles', 'truffe noire', 'truffe blanche',
      ],
    ),

    // 11. Italian Pasta & Pizza
    FoodPairingCategory(
      id: 'italian_pasta_pizza',
      label: 'Pâtes, Pizzas & Saveurs Italiennes',
      icon: '🍕',
      sampleDishes: [
        'Pizza Margherita au feu de bois',
        'Lasagnes bolognaises maison',
        'Spaghetti Carbonara tradizionale',
        'Spaghetti alle Vongole',
        'Carpaccio de bœuf au parmesan',
        'Burrata di Bufala & tomates confites',
        'Arancini siciliens',
      ],
      keywords: [
        'pizza', 'margherita', 'lasagne', 'bolognaise', 'carbonara', 'vongole',
        'amatriciana', 'carpaccio', 'burrata', 'mozzarella', 'pesto', 'gnocchi',
        'ravioli', 'osso buco', 'italien', 'arancini', 'tortellini', 'cannelloni',
        'pasta', 'pâtes', 'spaghetti', 'tagliatelle', 'penne', 'calzone',
      ],
    ),

    // 12. French Terroir & Tradition
    FoodPairingCategory(
      id: 'french_terroir',
      label: 'Terroir Français & Tradition',
      icon: '🥘',
      sampleDishes: [
        'Cassoulet de Castelnaudary',
        'Choucroute royale garnie',
        'Petit salé aux lentilles du Puy',
        'Boudin noir aux pommes caramélisées',
        'Andouillette de Troyes grillée',
        'Baeckeoffe alsacien',
        'Tripes à la mode de Caen',
      ],
      keywords: [
        'cassoulet', 'choucroute', 'petit sale', 'petit salé', 'lentilles', 'boudin',
        'boudin noir', 'boudin blanc', 'andouillette', 'baeckeoffe', 'tripes',
        'poule au pot', 'garbure', 'tripoux', 'saucisse de toulouse', 'saucisse de morteau',
        'terroir', 'quenelles', 'bouchée à la reine', 'hachis parmentier',
      ],
    ),

    // 13. Spicy & Oriental
    FoodPairingCategory(
      id: 'spicy_oriental',
      label: 'Cuisine Épicée, Couscous & Tajines',
      icon: '🌶️',
      sampleDishes: [
        'Couscous royal 3 viandes',
        'Tajine de poulet aux citrons confits',
        'Butter Chicken indien',
        'Curry d\'agneau madras',
        'Poulet Colombo antillais',
        'Rougail saucisse réunionnais',
        'Chili con carne',
      ],
      keywords: [
        'couscous', 'tajine', 'curry', 'butter chicken', 'tikka masala', 'colombo',
        'rougail', 'chili', 'chili con carne', 'epice', 'épice', 'indien', 'oriental',
        'harissa', 'tandoori', 'masala', 'dahl', 'samossa', 'samoussa', 'massale',
        'cuisine mexicaine', 'fajitas', 'tacos', 'pastilla',
      ],
    ),

    // 14. Asian, Wok & Street Food
    FoodPairingCategory(
      id: 'asian_street_food',
      label: 'Cuisine Asiatique, Wok & Canard Laqué',
      icon: '🥢',
      sampleDishes: [
        'Canard laqué pékinois',
        'Pad Thaï aux crevettes',
        'Bo Bun vietnamien au bœuf',
        'Ramen japonais au porc chashu',
        'Dim Sum & Gyozas vapeur',
        'Porc aigre-doux',
        'Wok de bœuf aux oignons',
      ],
      keywords: [
        'canard laque', 'canard laqué', 'pad thai', 'pad thaï', 'bo bun', 'ramen',
        'dim sum', 'gyoza', 'porc aigre-doux', 'wok', 'nem', 'vietnamien', 'chinois',
        'japonais', 'coreen', 'coréen', 'bibimbap', 'poulet kung pao', 'yakitori',
        'bao', 'bao burger', 'street food', 'rouleau de printemps', 'tom yum',
      ],
    ),

    // 15. Tapas, Aperitif & Foie Gras
    FoodPairingCategory(
      id: 'tapas_aperitif',
      label: 'Tapas, Charcuterie & Foie Gras',
      icon: '🌮',
      sampleDishes: [
        'Planche de jambon Pata Negra',
        'Foie gras mi-cuit sur toast',
        'Tapenade & anchoïade provençale',
        'Gougères chaudes au fromage',
        'Pintxos basques variés',
        'Empanadas argentins',
        'Pissaladière niçoise',
      ],
      keywords: [
        'charcuterie', 'jambon ibérique', 'jambon iberique', 'jambon de parme',
        'pata negra', 'foie gras', 'tapenade', 'anchoiade', 'anchoïade', 'gougere',
        'gougère', 'tapas', 'pintxos', 'empanadas', 'aperitif', 'apéritif', 'rillettes',
        'pate en croute', 'pâté en croûte', 'saucisson', 'pissaladiere', 'pissaladière',
        'planche aurore', 'amuse-bouche',
      ],
    ),

    // 16. Desserts & Chocolate
    FoodPairingCategory(
      id: 'dessert',
      label: 'Desserts, Tartes & Chocolat',
      icon: '🍰',
      sampleDishes: [
        'Fondant au chocolat cœur coulant',
        'Tarte Tatin tiède à la crème',
        'Tarte au citron meringuée',
        'Crème brûlée vanille bourbon',
        'Tiramisu italien au café',
        'Soufflé au Grand Marnier',
        'Profiteroles au chocolat chaud',
      ],
      keywords: [
        'dessert', 'chocolat', 'fondant', 'moelleux chocolat', 'tarte tatin',
        'tarte', 'tarte citron', 'creme brulee', 'crème brûlée', 'tiramisu',
        'fruit', 'fraise', 'framboise', 'pomme', 'poire', 'souffle', 'soufflé',
        'profiteroles', 'eclair', 'éclair', 'île flottante', 'ile flottante',
        'opera', 'millefeuille', 'baba au rhum', 'paris-brest',
      ],
    ),
  ];

  static List<FoodPairingMatch> findMatches({
    required List<Bottle> bottles,
    required String dishQuery,
  }) {
    if (bottles.isEmpty) return [];
    final query = _normalize(dishQuery);
    if (query.isEmpty) return [];

    final List<FoodPairingMatch> matches = [];

    for (final bottle in bottles) {
      final wine = bottle.wine;
      if (wine == null) continue;

      final match = _evaluatePairing(bottle, wine, query);
      if (match != null) {
        matches.add(match);
      }
    }

    // Sort matches by descending score
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  static FoodPairingMatch? _evaluatePairing(Bottle bottle, Wine wine, String query) {
    final type = _normalize(wine.type);
    final region = _normalize(wine.region);
    final appellation = _normalize(wine.appellation ?? '');
    final grapes = wine.grapes.map((g) => _normalize(g.name)).toList();
    final isMature = wine.windowStatus == DrinkWindowStatus.inPeak || wine.windowStatus == DrinkWindowStatus.drinkSoon;

    int score = 40;
    String comment = '';
    String serving = 'Servir à bonne température selon le cépage.';

    // 1. Foie Gras (Special highlight)
    if (query.contains('foie gras')) {
      if (type.contains('dessert') || type.contains('moell') || type.contains('sauternes') || appellation.contains('sauternes') || appellation.contains('monbazillac')) {
        score += 55;
        comment = 'L\'accord noble par excellence : la texture fondante du foie gras et la richesse liquoreuse du Sauternes s\'épousent dans une harmonie parfaite.';
        serving = 'Servir frais entre 8°C et 10°C.';
      } else if (type.contains('champ') || type.contains('sparkling')) {
        score += 48;
        comment = 'Accord moderne et vivifiant : les fines bulles et la fraîcheur du Champagne tranchent avec le gras onctueux du foie gras.';
        serving = 'Servir en flûte rafraîchie à 8-9°C.';
      } else if (grapes.contains('pinot noir') && isMature) {
        score += 42;
        comment = 'Accord d\'esthète : un vieux Pinot Noir aux tanins fondus apporte des notes de sous-bois et de truffe idéales sur un foie gras poêlé.';
        serving = 'Servir chambré à 15-16°C.';
      } else if (grapes.contains('gewurztraminer') || region.contains('alsace')) {
        score += 50;
        comment = 'L\'exubérance épicée et la rondeur du Gewurztraminer d\'Alsace subliment le foie gras mi-cuit avec éclat.';
        serving = 'Servir à 10°C.';
      }
    }

    // 2. Raclette, Fondue & Plats Fromage Fondu
    else if (_matchesKeywords(query, ['raclette', 'fondue', 'tartiflette', 'croziflette', 'mont d\'or', 'mont-d\'or', 'aligot', 'truffade', 'fromage fondu', 'reblochonade'])) {
      if (type.contains('blanc') || type.contains('white')) {
        if (region.contains('savoie') || region.contains('jura') || appellation.contains('apremont') || appellation.contains('chignin') || appellation.contains('arbois')) {
          score += 56;
          comment = 'Accord régional roi : la vivacité minérale et la fraîcheur alpine (Jacquère, Altesse, Savagnin) coupent le gras du fromage fondu et favorisent la digestion.';
          serving = 'Servir très frais à 8-10°C.';
        } else if (region.contains('alsace') || region.contains('loire') || appellation.contains('riesling') || appellation.contains('sancerre') || appellation.contains('chablis')) {
          score += 44;
          comment = 'Un blanc sec et tendu avec une belle acidité nettoie le palais face à l\'onctuosité du fromage et des charcuteries.';
          serving = 'Servir à 9-11°C.';
        } else {
          score += 35;
          comment = 'Un vin blanc sec est le compagnon idéal des fromages fondus pour conserver légèreté et gourmandise.';
          serving = 'Servir frais à 9-10°C.';
        }
      } else if (type.contains('red') || type.contains('rouge')) {
        if (grapes.contains('gamay') || grapes.contains('pinot noir') || region.contains('beaujolais') || region.contains('jura')) {
          score += 28;
          comment = 'Pour les amateurs de rouge sur la raclette : ce rouge léger, fruité et peu tannique n\'alourdit pas le fromage et accompagne bien la charcuterie.';
          serving = 'Servir légèrement rafraîchi à 14-15°C.';
        } else {
          score -= 15;
          comment = 'Attention : les tanins appuyés de ce vin rouge risquent de durcir au contact du fromage fondu.';
          serving = 'Préférer un blanc sec vif ou aérer généreusement.';
        }
      }
    }

    // 3. Red meat & Grillades
    else if (_matchesKeywords(query, ['boeuf', 'bœuf', 'cote de boeuf', 'entrecote', 'entrecôte', 'magret', 'canard', 'grillade', 'steak', 'agneau', 'bavette', 'tartare', 'tournedos', 'picanha', 'onglet', 'brochette', 'faux-filet', 'chateaubriand', 'ribeye', 'barbecue', 'bbq'])) {
      if (type == 'red' || type == 'rouge') {
        score += 30;
        if (region.contains('bordeaux') || region.contains('medoc') || region.contains('médoc') || region.contains('saint-emilion') || region.contains('saint-émilion') || region.contains('pauillac') || region.contains('pomerol') || region.contains('graves') || appellation.contains('margaux') || appellation.contains('saint-julien')) {
          score += 16;
          comment = 'La structure tannique noble et les notes de cèdre / cassis de ce Bordeaux s\'harmonisent superbement avec les sucs et le persillé de la viande.';
          serving = isMature ? 'Déboucher 1h avant sans carafage brusque (16-17°C).' : 'Carafer 2 heures pour assouplir les tanins jeunes (16-18°C).';
        } else if (region.contains('rhone') || region.contains('rhône') || appellation.contains('hermitage') || appellation.contains('cornas') || appellation.contains('chateauneuf') || appellation.contains('châteauneuf') || appellation.contains('saint-joseph') || appellation.contains('lirac')) {
          score += 17;
          comment = 'La générosité solaire et les notes poivrées / épicées de la Syrah et du Grenache subliment la viande grillée ou l\'agneau avec puissance.';
          serving = 'Servir entre 16°C et 17°C en grand verre tulipe.';
        } else if (region.contains('provence') || appellation.contains('bandol') || grapes.contains('mourvedre') || grapes.contains('mourvèdre')) {
          score += 16;
          comment = 'La race du Mourvèdre et ses arômes de garrigue, cuir et fruits noirs créent un accord magistral sur une belle viande grillée aux sarments.';
          serving = 'Servir à 16-17°C après une légère aération.';
        } else if (region.contains('espagne') || region.contains('ribera') || region.contains('jumilla') || region.contains('rioja') || region.contains('chili') || grapes.contains('carmenere')) {
          score += 15;
          comment = 'L\'intensité chaleureuse, les tanins mûrs et les notes grillées du vin résonnent parfaitement avec les saveurs du barbecue et de la viande saisie.';
          serving = 'Servir à 16-17°C.';
        } else if (region.contains('bourgogne') || grapes.contains('pinot noir')) {
          score += 9;
          comment = 'Pour une pièce tendre (filet de bœuf, magret poêlé), le soyeux et la cerise noire du Pinot Noir offrent un accord raffiné.';
          serving = 'Servir à 15-16°C dans un verre ballon.';
        } else {
          score += 6;
          comment = 'Ce vin rouge possède la vivacité et la charpente nécessaires pour soutenir ce plat.';
          serving = 'Servir chambré à 16-17°C.';
        }
      } else {
        score -= 25;
        comment = 'Les vins blancs manquent généralement de tanins pour soutenir des viandes rouges persillées.';
        serving = 'Privilégiez un rouge structuré.';
      }
    }

    // 4. Game & Stew (Bourguignon, Daube, Cassoulet, etc.)
    else if (_matchesKeywords(query, ['bourguignon', 'daube', 'gibier', 'sanglier', 'chevreuil', 'civet', 'tajine agneau', 'lievre', 'lièvre', 'biche', 'goulash', 'pot-au-feu', 'carbonnade', 'joue de boeuf', 'cerf', 'cassoulet', 'ragout', 'ragoût'])) {
      if (type == 'red' || type == 'rouge') {
        score += 32;
        if (query.contains('bourguignon') && (region.contains('bourgogne') || grapes.contains('pinot noir'))) {
          score += 18;
          comment = 'Accord régional par symbiose : le Pinot Noir cuit dans la sauce et sublimé dans le verre crée une continuité aromatique exceptionnelle.';
          serving = 'Servir à 16°C en grand verre Bourgogne.';
        } else if (query.contains('cassoulet') && (region.contains('sud-ouest') || region.contains('languedoc') || region.contains('rhone') || region.contains('cahors') || region.contains('madiran'))) {
          score += 18;
          comment = 'Accord terrien magistral : les tanins vigoureux et le fruité noir franc contrebalancent la richesse confite des haricots et du canard.';
          serving = 'Servir chambré à 17°C.';
        } else if (isMature) {
          score += 15;
          comment = 'Un vin rouge patiné par l\'âge aux notes de sous-bois, truffe et cuir se fond à merveille dans les sauces longues et le gibier.';
          serving = 'Déboucher délicatement sans brusquer les sédiments (16-17°C).';
        } else {
          score += 10;
          comment = 'La concentration et les épices de ce vin rouge enveloppent les saveurs denses de ce plat mijoté.';
          serving = 'Carafer 1h pour ouvrir le bouquet.';
        }
      } else {
        score -= 20;
        comment = 'Les sauces réduites et la puissance du gibier effaceraient ce vin blanc.';
      }
    }

    // 5. Poultry & Veal
    else if (_matchesKeywords(query, ['poulet', 'volaille', 'chapon', 'dinde', 'veau', 'quasi', 'pintade', 'caille', 'roti', 'rôti', 'ris de veau', 'blanquette', 'escalope', 'coq au vin', 'poularde'])) {
      if (type == 'white' || type == 'blanc') {
        if (region.contains('bourgogne') || region.contains('rhone') || grapes.contains('chardonnay') || appellation.contains('meursault')) {
          score += 34;
          comment = 'Un grand blanc riche, beurré et boisé enrobe magnifiquement la chair délicate et les sauces crémées (morilles, blanquette, poularde).';
          serving = 'Servir à 11-13°C sans excès de fraîcheur.';
        } else {
          score += 20;
          comment = 'La rondeur de ce blanc accompagne avec finesse la tendreté de la viande blanche.';
          serving = 'Servir à 10-12°C.';
        }
      } else if (type == 'red' || type == 'rouge') {
        if (region.contains('bourgogne') || region.contains('loire') || grapes.contains('pinot noir') || grapes.contains('gamay')) {
          score += 33;
          comment = 'Des tanins soyeux et un fruit croquant (framboise, cerise) valorisent parfaitement le rôti de veau ou le poulet du dimanche sans dominer.';
          serving = 'Servir frais à 15-16°C.';
        } else {
          score += 12;
          comment = 'Un vin rouge équilibré et fondu pour accompagner la volaille rôtie.';
          serving = 'Servir à 15-16°C.';
        }
      }
    }

    // 6. Delicate Fish (Sole, Bar, Turbot, Beurre blanc)
    else if (_matchesKeywords(query, ['sole', 'meuniere', 'meunière', 'bar', 'loup de mer', 'turbot', 'cabillaud', 'saint-pierre', 'dorade', 'daurade', 'lotte', 'beurre blanc', 'truite', 'lieu jaune', 'poisson blanc', 'papillote'])) {
      if (type == 'white' || type == 'blanc') {
        score += 35;
        if (appellation.contains('chablis') || region.contains('loire') || appellation.contains('sancerre') || appellation.contains('pouilly') || appellation.contains('muscadet')) {
          score += 16;
          comment = 'La pureté minérale, la vivacité saline et la tension d\'agrumes subliment la chair nacrée du poisson sans jamais la saturer.';
          serving = 'Servir frais à 9-11°C.';
        } else if (region.contains('bourgogne') || appellation.contains('meursault') || grapes.contains('chardonnay')) {
          score += 15;
          comment = 'L\'onctuosité beurrée et la texture satinée du vin font écho à la sauce au beurre blanc ou à la sole meunière poêlée.';
          serving = 'Servir à 11-12°C.';
        } else {
          score += 10;
          comment = 'Fraîcheur et équilibre pour respecter la délicatesse des saveurs marines.';
          serving = 'Servir bien frais (8-10°C).';
        }
      } else if (type.contains('champ') || type.contains('sparkling')) {
        score += 30;
        comment = 'L\'effervescence crémeuse et la droiture du Champagne exaltent les poissons nobles au beurre blanc.';
        serving = 'Servir à 8-10°C.';
      } else {
        score -= 25;
        comment = 'Les tanins rouges s\'entrechoquent avec les poissons délicats et laissent une amertume désagréable.';
      }
    }

    // 7. Fatty Fish, Sushi & Ceviche (Saumon, Thon, Tataki)
    else if (_matchesKeywords(query, ['saumon', 'thon', 'tataki', 'sushi', 'sashimi', 'ceviche', 'poke bowl', 'saumon fume', 'saumon fumé', 'maquereau', 'sardine', 'tartare de saumon', 'gravlax'])) {
      if (type == 'white' || type == 'blanc') {
        score += 34;
        if (query.contains('ceviche') && (grapes.contains('sauvignon') || region.contains('loire') || region.contains('alsace') || grapes.contains('riesling'))) {
          score += 16;
          comment = 'La vivacité tranchante et les notes de citron vert du vin s\'accordent à merveille avec l\'acidité de la marinade du ceviche.';
          serving = 'Servir à 8-10°C.';
        } else if (appellation.contains('chablis') || grapes.contains('riesling')) {
          score += 14;
          comment = 'La droiture minérale coupe le gras savoureux du saumon ou du thon cru tout en respectant les sauces soja et wasabi.';
          serving = 'Servir frais à 9-11°C.';
        }
      } else if (type == 'rose' || type == 'rosé') {
        score += 32;
        comment = 'Un rosé gastronomique de Provence ou Bandol offre le compromis rêvé entre fraîcheur iodée et rondeur fruitée sur les sushis et le thon mi-cuit.';
        serving = 'Servir à 9-10°C.';
      } else if (type == 'red' || type == 'rouge') {
        if (grapes.contains('pinot noir') || region.contains('bourgogne')) {
          score += 28;
          comment = 'Accord d\'audace plébiscité par les sommeliers : la souplesse et le fruit rouge frais du Pinot Noir sur un pavé de thon rouge ou un saumon grillé.';
          serving = 'Servir légèrement frais à 14°C.';
        } else {
          score -= 15;
          comment = 'Un rouge tannique écraserait les saveurs brutes du poisson cru ou gras.';
        }
      }
    }

    // 8. Seafood & Shellfish (Huîtres, Homard, Saint-Jacques)
    else if (_matchesKeywords(query, ['huitre', 'huître', 'crevette', 'homard', 'langouste', 'langoustine', 'saint-jacques', 'st-jacques', 'fruits de mer', 'crustaces', 'crustacés', 'gambas', 'moule', 'moules marinières', 'tourteau', 'ecrevisse', 'écrevisse'])) {
      if (type == 'white' || type == 'blanc') {
        score += 38;
        if (query.contains('huitre') || query.contains('huître')) {
          if (appellation.contains('chablis') || appellation.contains('muscadet')) {
            score += 22;
            comment = 'L\'accord absolu de la mer : le terroir kimméridgien, la salinité éclatante et la vivacité iodée s\'unissent divinement aux huîtres.';
            serving = 'Servir très frais à 8-10°C sans attendre.';
          } else if (appellation.contains('sancerre') || appellation.contains('picpoul')) {
            score += 16;
            comment = 'La vivacité tranchante et les notes d\'agrumes apportent une belle fraîcheur sur les huîtres.';
            serving = 'Servir à 8-10°C.';
          }
        } else if (query.contains('saint-jacques') || query.contains('homard') || query.contains('langoust')) {
          if (region.contains('bourgogne') || grapes.contains('chardonnay') || region.contains('rhone')) {
            score += 16;
            comment = 'La texture beurrée et la minéralité de ce grand blanc subliment la douceur iodée et la chair noble des crustacés et coquilles Saint-Jacques.';
            serving = 'Servir à 10-12°C.';
          }
        } else {
          score += 10;
          comment = 'Fraîcheur désaltérante idéale sur un plateau de fruits de mer.';
          serving = 'Servir à 9-10°C.';
        }
      } else if (type.contains('champ') || type.contains('sparkling')) {
        score += 36;
        comment = 'L\'effervescence pure et crayeuse du Champagne réveille les papilles et magnifie la chair raffinée du homard et des huîtres.';
        serving = 'Servir à 8-9°C en verre tulipe.';
      } else {
        score -= 28;
        comment = 'L\'iode des crustacés transforme les tanins des vins rouges en un goût ferreux et amer.';
      }
    }

    // 9. Goat & Sheep Cheese
    else if (_matchesKeywords(query, ['chevre', 'chèvre', 'crottin', 'chavignol', 'sainte-maure', 'valençay', 'banon', 'pelardon', 'rocamadour', 'brebis', 'ossau-iraty', 'manchego', 'feta', 'roquefort', 'bleu'])) {
      if (query.contains('roquefort') || query.contains('bleu') || query.contains('fourme')) {
        if (type.contains('dessert') || type.contains('moell') || type.contains('sauternes')) {
          score += 45;
          comment = 'Accord légendaire de contraste : le sel puissant et le piquant du fromage bleu sont magnifiés par l\'onctuosité liquoreuse du grand vin blanc moelleux.';
          serving = 'Servir à 8-10°C.';
        } else if (region.contains('rhone') || region.contains('banyuls') || region.contains('porto')) {
          score += 35;
          comment = 'Un vin rouge doux ou puissant épicé tient tête au caractère affirmé du persillé.';
          serving = 'Servir à 15°C.';
        }
      } else if (type == 'white' || type == 'blanc') {
        score += 35;
        if (region.contains('loire') || appellation.contains('sancerre') || appellation.contains('pouilly') || grapes.contains('sauvignon')) {
          score += 18;
          comment = 'L\'accord parfait : les notes de buis et la vivacité d\'agrumes du Sauvignon de Loire épousent intimement le gras caprin du Crottin de Chavignol ou Sainte-Maure.';
          serving = 'Servir à 9-11°C.';
        } else {
          score += 12;
          comment = 'La fraîcheur du vin blanc respecte les ferments du fromage sans laisser d\'amertume.';
          serving = 'Servir à 10°C.';
        }
      } else if (type == 'red' || type == 'rouge' && (query.contains('ossau') || query.contains('brebis'))) {
        if (region.contains('sud-ouest') || region.contains('madiran') || region.contains('bordeaux')) {
          score += 26;
          comment = 'La douceur de la pâte de brebis et la confiture de cerises noires s\'accordent merveilleusement avec un rouge du Sud-Ouest.';
          serving = 'Servir à 16°C.';
        }
      }
    }

    // 10. Cow milk & Pressed Cheese (Comté, Beaufort, Brie)
    else if (_matchesKeywords(query, ['comte', 'comté', 'beaufort', 'gruyere', 'gruyère', 'brie', 'camembert', 'saint-nectaire', 'epoisses', 'époisses', 'reblochon', 'munster', 'morbier', 'cantal', 'fromage', 'chaource'])) {
      if (type == 'white' || type == 'blanc') {
        score += 34;
        if (region.contains('jura') || region.contains('bourgogne') || grapes.contains('savagnin') || grapes.contains('chardonnay')) {
          score += 18;
          comment = 'L\'accord absolu du Comté ou Beaufort : les arômes de noisette, de beurre et la minéralité d\'un grand blanc de gastronomie créent une harmonie sublime.';
          serving = 'Servir à 11-13°C.';
        } else {
          score += 12;
          comment = 'Les grands blancs secs sont les meilleurs alliés des fromages à pâte pressée pour révéler toute leur complexité.';
          serving = 'Servir à 10-12°C.';
        }
      } else if (type == 'red' || type == 'rouge') {
        if (region.contains('bourgogne') || grapes.contains('pinot noir') || region.contains('loire')) {
          score += 22;
          comment = 'Un rouge délicat et peu tannique comme un Pinot Noir respecte le crémeux du Saint-Nectaire ou du Brie de Meaux.';
          serving = 'Servir à 15-16°C.';
        } else {
          score += 8;
          comment = 'Attention aux tanins trop puissants avec les croûtes de fromages : privilégier un fromage doux.';
        }
      }
    }

    // 11. Mushrooms & Truffle
    else if (_matchesKeywords(query, ['champignon', 'truffe', 'cepe', 'cèpe', 'morille', 'risotto', 'girolle', 'sous-bois', 'pates aux truffes', 'pâtes aux truffes', 'omelette truffe'])) {
      if (type == 'red' || type == 'rouge') {
        if (region.contains('bourgogne') || grapes.contains('pinot noir') || region.contains('piemont') || region.contains('barolo') || region.contains('italie')) {
          score += 38;
          comment = 'Les arômes tertiaires d\'humus, de truffe et de sous-bois du Pinot Noir ou du Nebbiolo résonnent magistralement avec les champignons.';
          serving = 'Servir à 15-16°C en grand verre ballon.';
        } else if (region.contains('bordeaux') && isMature) {
          score += 32;
          comment = 'Un grand Bordeaux parvenu à maturité déploie des notes de cèdre et de truffe noire idéales sur ce plat.';
          serving = 'Déboucher avec soin à 16-17°C.';
        } else {
          score += 15;
          comment = 'L\'élégance du vin rouge accompagne bien la texture charnue des champignons.';
        }
      } else if (type == 'white' || type == 'blanc') {
        if (region.contains('jura') || region.contains('bourgogne') || appellation.contains('meursault') || grapes.contains('savagnin') || grapes.contains('chardonnay')) {
          score += 36;
          comment = 'L\'onctuosité et les notes de fruits secs / noisette grillée d\'un grand blanc de gastronomie subliment un risotto aux morilles ou cèpes.';
          serving = 'Servir à 12-13°C.';
        }
      }
    }

    // 12. Italian Pasta & Pizza
    else if (_matchesKeywords(query, ['pizza', 'margherita', 'lasagne', 'bolognaise', 'carbonara', 'vongole', 'amatriciana', 'carpaccio', 'burrata', 'mozzarella', 'pesto', 'gnocchi', 'pasta', 'pâtes', 'spaghetti'])) {
      if (query.contains('vongole') || query.contains('pesto') || query.contains('burrata')) {
        if (type == 'white' || type == 'blanc' || type == 'rose' || type == 'rosé') {
          score += 34;
          comment = 'La fraîcheur vive d\'un blanc sec ou d\'un rosé méditerranéen équilibre l\'iode des palourdes ou le crémeux de la Burrata.';
          serving = 'Servir à 9-11°C.';
        }
      } else if (type == 'red' || type == 'rouge') {
        score += 30;
        if (region.contains('italie') || region.contains('toscane') || region.contains('rhone') || region.contains('languedoc') || region.contains('provence')) {
          score += 16;
          comment = 'L\'acidité naturelle et les arômes de cerise et d\'herbes méditerranéennes coupent la richesse du fromage fondu et de la sauce tomate.';
          serving = 'Servir à 15-16°C.';
        } else {
          score += 10;
          comment = 'Un vin rouge convivial et gourmand parfait pour les saveurs transalpines.';
          serving = 'Servir à 16°C.';
        }
      }
    }

    // 13. French Terroir (Choucroute, Boudin noir, Andouillette, Baeckeoffe)
    else if (_matchesKeywords(query, ['choucroute', 'petit sale', 'petit salé', 'boudin', 'boudin noir', 'boudin blanc', 'andouillette', 'baeckeoffe', 'tripes', 'poule au pot'])) {
      if (query.contains('choucroute') || query.contains('baeckeoffe')) {
        if (region.contains('alsace') || grapes.contains('riesling') || grapes.contains('pinot blanc') || grapes.contains('sylvaner')) {
          score += 42;
          comment = 'Accord alsacien traditionnel incontournable : la droiture tranchante du Riesling ou du Pinot Blanc nettoie les graisses de la charcuterie et du chou fermenté.';
          serving = 'Servir frais à 9-11°C.';
        }
      } else if (query.contains('boudin noir') || query.contains('andouillette')) {
        if (type == 'red' || type == 'rouge') {
          if (region.contains('loire') || region.contains('beaujolais') || grapes.contains('gamay') || grapes.contains('cabernet franc')) {
            score += 38;
            comment = 'La fraîcheur gouleyante et le fruit croquant du Gamay ou Cabernet Franc de Loire épousent à merveille le moelleux du boudin et des pommes.';
            serving = 'Servir frais à 14-15°C.';
          }
        }
      } else if (type == 'white' || type == 'blanc') {
        score += 25;
        comment = 'Un blanc sec structuré apporte l\'acidité requise face aux plats traditionnels riches.';
        serving = 'Servir à 10°C.';
      }
    }

    // 14. Spicy & Oriental (Couscous, Tajines, Curry, Butter Chicken)
    else if (_matchesKeywords(query, ['couscous', 'tajine', 'curry', 'butter chicken', 'tikka masala', 'colombo', 'rougail', 'chili', 'epice', 'épice', 'indien', 'oriental', 'harissa', 'tandoori'])) {
      if (grapes.contains('gewurztraminer') || region.contains('alsace') || grapes.contains('viognier')) {
        score += 36;
        comment = 'L\'exubérance aromatique (rose, litchi, épices douces) et la texture soyeuse domptent le piment et valorisent les currys et tajines.';
        serving = 'Servir frais à 9-11°C.';
      } else if (type == 'rose' || type == 'rosé') {
        score += 30;
        comment = 'Un rosé charpenté et vineux (Tavel, Bandol, Côtes de Provence) apporte une fraîcheur bienvenue face aux plats très épicés et au couscous.';
        serving = 'Servir à 9-10°C.';
      } else if (type == 'red' || type == 'rouge') {
        if (region.contains('rhone') || region.contains('languedoc') || region.contains('provence') || grapes.contains('syrah') || grapes.contains('grenache')) {
          score += 28;
          comment = 'Les tanins enrobés et les notes de garrigue et poivre noir du Sud complètent harmonieusement l\'agneau et les épices orientales.';
          serving = 'Servir à 16°C.';
        } else {
          score -= 10;
          comment = 'Les tanins trop stricts peuvent accentuer la sensation de brûlure des piments.';
        }
      }
    }

    // 15. Asian Street Food & Wok (Canard laqué, Pad Thaï, Ramen, Bo Bun)
    else if (_matchesKeywords(query, ['canard laque', 'canard laqué', 'pad thai', 'pad thaï', 'bo bun', 'ramen', 'dim sum', 'gyoza', 'porc aigre-doux', 'wok', 'nem', 'asiatique', 'chinois', 'coreen'])) {
      if (query.contains('canard laque') || query.contains('canard laqué')) {
        if (grapes.contains('pinot noir') || region.contains('bourgogne') || grapes.contains('gamay')) {
          score += 38;
          comment = 'Accord sommelier exceptionnel : la douceur caramélisée de la sauce hoisin et la peau croustillante du canard s\'accordent divinement au fruit soyeux du Pinot Noir.';
          serving = 'Servir à 15-16°C.';
        } else if (grapes.contains('riesling') || region.contains('alsace')) {
          score += 34;
          comment = 'Un Riesling avec une pointe de sucre résiduel fait scintiller les épices douces et le laquage du canard.';
          serving = 'Servir à 10°C.';
        }
      } else if (type == 'white' || type == 'blanc') {
        score += 30;
        if (grapes.contains('riesling') || grapes.contains('chenin') || region.contains('alsace') || region.contains('loire')) {
          score += 15;
          comment = 'La minéralité ciselée et le fruit blanc éclatant répondent parfaitement aux herbes fraîches (coriandre, menthe), au gingembre et à la citronnelle.';
          serving = 'Servir à 9-10°C.';
        }
      } else if (type == 'rose' || type == 'rosé') {
        score += 26;
        comment = 'Un rosé fruité et gouleyant apporte légèreté et gourmandise aux dim sums et nouilles sautées.';
        serving = 'Servir à 9°C.';
      }
    }

    // 16. Tapas, Charcuterie & Aperitif (Pata Negra, Tapenade, Rillettes)
    else if (_matchesKeywords(query, ['charcuterie', 'jambon', 'pata negra', 'tapenade', 'anchoiade', 'anchoïade', 'gougere', 'gougère', 'tapas', 'pintxos', 'empanadas', 'aperitif', 'apéritif', 'rillettes', 'saucisson'])) {
      if (type.contains('champ') || type.contains('sparkling')) {
        score += 35;
        comment = 'L\'apéritif par excellence : les bulles fines aiguisent l\'appétit et contrastent avec la texture fondante des gougères et charcuteries nobles.';
        serving = 'Servir frais à 8-9°C.';
      } else if (type == 'rose' || type == 'rosé') {
        score += 32;
        comment = 'L\'âme de l\'apéritif estival : un rosé de Provence frais, floral et croquant sublime la tapenade et les tapas.';
        serving = 'Servir à 8-10°C.';
      } else if (type == 'red' || type == 'rouge') {
        if (region.contains('beaujolais') || region.contains('loire') || grapes.contains('gamay') || region.contains('espagne') || region.contains('ribera') || region.contains('rioja')) {
          score += 30;
          comment = 'Un rouge digeste et fruité ou un beau vin espagnol pour mettre en valeur le gras noble du jambon Pata Negra et des rillettes.';
          serving = 'Servir à 14-16°C.';
        }
      }
    }

    // 17. Desserts & Chocolate
    else if (_matchesKeywords(query, ['dessert', 'chocolat', 'tarte', 'fruit', 'fraise', 'framboise', 'tiramisu', 'creme brulee', 'crème brûlée', 'pomme', 'poire', 'fondant', 'moelleux chocolat', 'souffle', 'soufflé', 'profiteroles'])) {
      if (query.contains('chocolat') || query.contains('cacao')) {
        if (region.contains('banyuls') || region.contains('maury') || region.contains('porto') || region.contains('roussillon') || type.contains('fortified') || (type == 'red' && grapes.contains('grenache') && isMature)) {
          score += 42;
          comment = 'Accord magique au sommet : les notes de cacao, cerise noire confite et pruneau d\'un Vin Doux Naturel ou Porto subliment le chocolat noir corsé.';
          serving = 'Servir à 14-16°C.';
        } else if (type.contains('dessert') || type.contains('moell')) {
          score += 20;
          comment = 'Un blanc liquoreux s\'accordera mieux sur un chocolat blanc ou aux fruits que sur un chocolat noir très amer.';
        } else {
          score -= 20;
          comment = 'Un vin sec paraîtrait agressif et métallique après le sucre du chocolat.';
        }
      } else {
        // Fruit desserts, Tatin, Crème brûlée
        if (type.contains('dessert') || type.contains('moell') || type.contains('liquor') || type.contains('sauternes') || region.contains('sauternes') || region.contains('layon') || region.contains('alsace')) {
          score += 44;
          comment = 'L\'onctuosité confite, les notes de miel, d\'abricot sec et de vanille épousent admirablement les tartes aux fruits, la Tatin et la crème brûlée.';
          serving = 'Servir frais à 8-10°C.';
        } else if (type.contains('champ') || type.contains('sparkling')) {
          score += 28;
          comment = 'Les fines bulles apportent une conclusion festive et légère sur des desserts aux fruits frais ou fraises.';
          serving = 'Servir à 8-9°C.';
        } else {
          score -= 25;
          comment = 'Un vin sec manquera de rondeur face au sucre d\'un dessert.';
        }
      }
    }

    // Generic fallback if no specific category matched
    else {
      if (type == 'red' || type == 'rouge') {
        score += 15;
        comment = 'Vin rouge équilibré pour accompagner ce plat selon vos goûts.';
      } else if (type == 'white' || type == 'blanc') {
        score += 15;
        comment = 'Vin blanc offrant une belle fraîcheur sur ce plat.';
      }
    }

    // Bonus points for ideal drinking window (bottle ready to drink)
    if (isMature) {
      score += 5;
    }

    // Normalize score to 15..99
    score = score.clamp(15, 99);

    final matchLevel = score >= 85
        ? FoodMatchLevel.ideal
        : (score >= 70 ? FoodMatchLevel.harmonious : (score >= 55 ? FoodMatchLevel.gourmet : FoodMatchLevel.subtle));

    return FoodPairingMatch(
      bottle: bottle,
      score: score,
      matchLevel: matchLevel,
      sommelierComment: comment.isNotEmpty ? comment : 'Accord équilibré selon le profil aromatique du vin.',
      servingAdvice: serving,
    );
  }

  static bool _matchesKeywords(String query, List<String> keywords) {
    for (final kw in keywords) {
      final normalizedKw = _normalize(kw);
      if (query.contains(normalizedKw)) return true;
    }
    return false;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûüù]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .trim();
  }
}
