import 'wine.dart';

class ReverseFoodPairing {
  final String dishName;
  final String category; // 'viande', 'poisson', 'fromage', 'vegetarien', 'mijoté'
  final String categoryIcon;
  final int affinityPct; // e.g. 98
  final String affinityLevel; // 'Accord Majeur 🌟', 'Accord Sublime ✨', 'Harmonie Parfaite 🍷'
  final List<String> keyIngredients;
  final String cookingAdvice;
  final String molecularRationale;

  const ReverseFoodPairing({
    required this.dishName,
    required this.category,
    required this.categoryIcon,
    required this.affinityPct,
    required this.affinityLevel,
    required this.keyIngredients,
    required this.cookingAdvice,
    required this.molecularRationale,
  });
}

class WineReversePairingEngine {
  static List<ReverseFoodPairing> getPairingsForWine(Wine wine) {
    final nameLower = '${wine.name} ${wine.producer} ${wine.region} ${wine.appellation ?? ""} ${wine.grapes.map((g) => g.name).join(" ")}'.toLowerCase();
    final type = (wine.type).toLowerCase();

    final pairings = <ReverseFoodPairing>[];

    // 1. CHAMPAGNE & EFFERVESCENTS
    if (type.contains('spark') || nameLower.contains('champagne') || nameLower.contains('crémant') || nameLower.contains('cava')) {
      pairings.addAll([
        const ReverseFoodPairing(
          dishName: 'Plateau d\'Huîtres Gillardeau & Carpaccio de Saint-Jacques au Citron Caviar',
          category: 'poisson',
          categoryIcon: '🦪',
          affinityPct: 98,
          affinityLevel: 'Accord Majeur 🌟',
          keyIngredients: ['Huîtres spéciales', 'Noix de Saint-Jacques', 'Citron caviar', 'Fleur de sel'],
          cookingAdvice: 'Servir cru à 8-10°C avec une émulsion d\'huile d\'olive et zestes d\'agrumes sans vinaigre excessif.',
          molecularRationale: 'L\'acidité vive et la salinité de la craie tranchent avec l\'iode et subliment la texture soyeuse des coquillages.',
        ),
        const ReverseFoodPairing(
          dishName: 'Ris de Veau Croustillant aux Morilles et Crème Réduite',
          category: 'viande',
          categoryIcon: '🥩',
          affinityPct: 95,
          affinityLevel: 'Accord Sublime ✨',
          keyIngredients: ['Ris de veau', 'Morilles fraîches', 'Crème crue', 'Beurre noisette'],
          cookingAdvice: 'Braiser au beurre moussant pour obtenir un extérieur doré et croquant et un cœur fondant.',
          molecularRationale: 'L\'effervescence fine et les notes briochées (diacétyle et autolyse des levures) nettoient le palais du gras noble des morilles et de la crème.',
        ),
        const ReverseFoodPairing(
          dishName: 'Comté Affiné 24 Mois & Gougères au Beurre AOP',
          category: 'fromage',
          categoryIcon: '🧀',
          affinityPct: 94,
          affinityLevel: 'Harmonie Parfaite 🍷',
          keyIngredients: ['Comté 24 mois', 'Pâte à choux', 'Gruyère suisse', 'Poivre de Sichuan'],
          cookingAdvice: 'Servir les gougères tièdes au sortir du four avec des lamelles de Comté chambré.',
          molecularRationale: 'Les cristaux de tyrosine du Comté résonnent avec la bulle crémeuse et la complexité oxydative.',
        ),
      ]);
    }

    // 2. VINS ROUGES PUISSANTS & TANNIQUES (Bordeaux, Bandol, Rhône Sud, Cahors, Madiran, Rioja, Ribera)
    else if (type.contains('red') && (nameLower.contains('bordeaux') || nameLower.contains('bandol') || nameLower.contains('terrebrune') || nameLower.contains('tempier') || nameLower.contains('mourvèdre') || nameLower.contains('cabernet') || nameLower.contains('syrah') || nameLower.contains('rioja') || nameLower.contains('ribera') || nameLower.contains('cahors'))) {
      pairings.addAll([
        const ReverseFoodPairing(
          dishName: 'Côte de Bœuf Maturée 45 jours au Feu de Bois & Beurre Maître d\'Hôtel',
          category: 'viande',
          categoryIcon: '🥩',
          affinityPct: 99,
          affinityLevel: 'Accord Majeur 🌟',
          keyIngredients: ['Bœuf de race Simmental ou Black Angus', 'Sel de Guérande', 'Thym frais', 'Moelle'],
          cookingAdvice: 'Saisir à feu très vif pour caraméliser la surface (réaction de Maillard), cœur saignant à 52°C.',
          molecularRationale: 'Les protéines et le persillage de la viande désactivent l\'astringence des tannins en se liant à la proline salivaire, libérant le fruit.',
        ),
        const ReverseFoodPairing(
          dishName: 'Gigot d\'Agneau de 7 Heures Confit au Romarin, Ail Noir et Jus Corsé',
          category: 'mijoté',
          categoryIcon: '🍲',
          affinityPct: 97,
          affinityLevel: 'Accord Sublime ✨',
          keyIngredients: ['Agneau de Sisteron', 'Romarin frais', 'Ail noir confit', 'Fond brun réduit'],
          cookingAdvice: 'Cuire à couvert à 120°C pendant 7h. La gélatine fondue enrobe le palais.',
          molecularRationale: 'La rotundone et les pyrazines du vin épousent à la perfection les molécules aromatiques de la garrigue et du romarin.',
        ),
        const ReverseFoodPairing(
          dishName: 'Magret de Canard Rôti aux Cerises Noires et Réduction de Poivre de Sichuan',
          category: 'viande',
          categoryIcon: '🦆',
          affinityPct: 94,
          affinityLevel: 'Harmonie Parfaite 🍷',
          keyIngredients: ['Magret du Sud-Ouest', 'Cerises griottes', 'Poivre concassé', 'Vinaigre balsamique vieux'],
          cookingAdvice: 'Quadriller la peau, dégraisser à feu moyen, puis cuire côté chair 3 minutes.',
          molecularRationale: 'L\'acidité naturelle du fruit noir équilibre la richesse lipidique du canard.',
        ),
      ]);
    }

    // 3. VINS ROUGES ÉLÉGANTS & FINITUDES (Bourgogne, Pinot Noir, Loire Rouge, Etna, Barolo)
    else if (type.contains('red')) {
      pairings.addAll([
        const ReverseFoodPairing(
          dishName: 'Pigeon Rôti sur Coffre, Mousseline de Céleri-Rave et Jus à la Truffe',
          category: 'viande',
          categoryIcon: '🕊️',
          affinityPct: 98,
          affinityLevel: 'Accord Majeur 🌟',
          keyIngredients: ['Pigeon fermier', 'Céleri-rave', 'Beurre doux', 'Truffe noire du Périgord'],
          cookingAdvice: 'Cuisson rosée précise. Glacer au jus réduit monté au beurre.',
          molecularRationale: 'La délicatesse soyeuse des tannins et les arômes sous-bois (esters & lactones) exaltent la chair noble du gibier à plumes.',
        ),
        const ReverseFoodPairing(
          dishName: 'Filet Mignon de Porc Fermier aux Girolles Sautées et Noisettes Torréfiées',
          category: 'viande',
          categoryIcon: '🍄',
          affinityPct: 95,
          affinityLevel: 'Accord Sublime ✨',
          keyIngredients: ['Filet mignon', 'Girolles fraîches', 'Persil plat', 'Noisettes concassées'],
          cookingAdvice: 'Cuisson douce à 58°C à cœur, poêler les girolles à sec puis beurrer en fin de cuisson.',
          molecularRationale: 'Les notes de sous-bois et de fruits rouges acidulés s\'harmonisent sans écraser la finesse de la viande blanche.',
        ),
        const ReverseFoodPairing(
          dishName: 'Tataki de Thon Rouge au Sésame Noir & Jus de Canard aux Baies Roses',
          category: 'poisson',
          categoryIcon: '🐟',
          affinityPct: 92,
          affinityLevel: 'Harmonie Parfaite 🍷',
          keyIngredients: ['Thon rouge frais', 'Graines de sésame', 'Sauce soja réduite', 'Baie rose'],
          cookingAdvice: 'Aller-retour de 30 secondes par face sur plancha brûlante. Cœur cru et soyeux.',
          molecularRationale: 'Un rouge fluide sans tannins excessifs permet un accord audacieux terre-mer sans goût métallique.',
        ),
      ]);
    }

    // 4. VINS BLANCS SECS & MINÉRAUX (Chablis, Sancerre, Riesling, Muscadet, Rías Baixas)
    else if (type.contains('white') && (nameLower.contains('chablis') || nameLower.contains('sancerre') || nameLower.contains('sauvignon') || nameLower.contains('riesling') || nameLower.contains('albarino') || nameLower.contains('muscadet'))) {
      pairings.addAll([
        const ReverseFoodPairing(
          dishName: 'Dos de Bar Sauvage Rôti, Fenouil Braisé et Beurre Blanc Émulsionné',
          category: 'poisson',
          categoryIcon: '🐟',
          affinityPct: 98,
          affinityLevel: 'Accord Majeur 🌟',
          keyIngredients: ['Bar de ligne', 'Fenouil sauvage', 'Échalote grise', 'Vin blanc sec'],
          cookingAdvice: 'Cuisson sur peau croustillante. Monter le beurre blanc hors du feu au fouet.',
          molecularRationale: 'L\'acide tartrique vif tranche la richesse onctueuse du beurre blanc tout en révélant la minéralité iodée du poisson.',
        ),
        const ReverseFoodPairing(
          dishName: 'Crottin de Chavignol Chaud sur Pain de Campagne & Salade de Mâche aux Noix',
          category: 'fromage',
          categoryIcon: '🧀',
          affinityPct: 96,
          affinityLevel: 'Accord Sublime ✨',
          keyIngredients: ['Chavignol affiné', 'Pain au levain', 'Mâche fraîche', 'Huile de noix'],
          cookingAdvice: 'Gratiner 4 minutes sous le grill jusqu\'à ce que le dôme du fromage dore.',
          molecularRationale: 'Accord de terroir absolu : la fraîcheur végétale et minérale sublime la texture lactique caprine.',
        ),
        const ReverseFoodPairing(
          dishName: 'Tartare de Bar aux Fruits de la Passion et Coriandre Fraîche',
          category: 'poisson',
          categoryIcon: '🍋',
          affinityPct: 93,
          affinityLevel: 'Harmonie Parfaite 🍷',
          keyIngredients: ['Chair de bar', 'Fruit de la passion', 'Coriandre', 'Échalote'],
          cookingAdvice: 'Dresser minute très frais pour conserver le croquant et la vivacité.',
          molecularRationale: 'Les thiols aromatiques du cépage (3-mercaptohexanol) entrent en résonance directe avec les notes de maracuja.',
        ),
      ]);
    }

    // 5. VINS BLANCS GRAS & ONCTUEUX (Bourgogne Blanc, Meursault, Rhône Blanc, Viognier, Chardonnay sous bois)
    else if (type.contains('white')) {
      pairings.addAll([
        const ReverseFoodPairing(
          dishName: 'Homard Bleu Rôti au Beurre de Noisette & Émulsion aux Morilles',
          category: 'poisson',
          categoryIcon: '🦞',
          affinityPct: 99,
          affinityLevel: 'Accord Majeur 🌟',
          keyIngredients: ['Homard breton', 'Morilles fraîches', 'Beurre salé', 'Crème double'],
          cookingAdvice: 'Poêler la chair du homard délicatement et napper d\'un jus corsé de carcasse crémé.',
          molecularRationale: 'Les lactones de chêne et le diacétyle beurré du vin enveloppent la sucrosité naturelle du crustacé.',
        ),
        const ReverseFoodPairing(
          dishName: 'Poularde de Bresse Rôtie au Vin Jaune et Morilles',
          category: 'viande',
          categoryIcon: '🍗',
          affinityPct: 97,
          affinityLevel: 'Accord Sublime ✨',
          keyIngredients: ['Poularde fermière AOP', 'Morilles', 'Crème d\'Isigny', 'Échalotes'],
          cookingAdvice: 'Pocher puis rôtir doucement pour une chair ultra-moelleuse.',
          molecularRationale: 'La puissance et la trame grasse du vin soutiennent la sauce riche sans faiblir.',
        ),
        const ReverseFoodPairing(
          dishName: 'Ravioles de Langoustines au Bouillon Thaï Citronnelle et Lait de Coco',
          category: 'poisson',
          categoryIcon: '🥟',
          affinityPct: 92,
          affinityLevel: 'Harmonie Parfaite 🍷',
          keyIngredients: ['Langoustines', 'Lait de coco', 'Citronnelle', 'Gingembre doux'],
          cookingAdvice: 'Servir le bouillon fumant autour des ravioles délicates.',
          molecularRationale: 'Les terpènes floraux du vin répondent aux arômes exotiques de la citronnelle et du coco.',
        ),
      ]);
    }

    // 6. VINS ROSÉS GASTRONOMIQUES
    else if (type.contains('ros')) {
      pairings.addAll([
        const ReverseFoodPairing(
          dishName: 'Rougets Barbets Grillés au Romarin et Écrasé de Pommes de Terre à l\'Huile d\'Olive',
          category: 'poisson',
          categoryIcon: '🐟',
          affinityPct: 98,
          affinityLevel: 'Accord Majeur 🌟',
          keyIngredients: ['Rougets frais', 'Romarin', 'Huile d\'olive AOP', 'Fleur de sel'],
          cookingAdvice: 'Cuisson ultra-rapide côté peau sur plancha très chaude.',
          molecularRationale: 'La texture phénolique légère et la salinité du rosé soutiennent le goût prononcé et iodé du rouget.',
        ),
        const ReverseFoodPairing(
          dishName: 'Petits Farcis Provençaux Traditionnels & Agneau Haché aux Herbes',
          category: 'mijoté',
          categoryIcon: '🫑',
          affinityPct: 95,
          affinityLevel: 'Accord Sublime ✨',
          keyIngredients: ['Courgettes rondes', 'Tomates', 'Chair d\'agneau', 'Sarriette'],
          cookingAdvice: 'Confir au four à 160°C pendant 45 minutes pour concentrer les sucs.',
          molecularRationale: 'L\'acidité fruitée désaltère le palais après chaque bouchée de légumes fondants et de farce.',
        ),
        const ReverseFoodPairing(
          dishName: 'Tataki de Bœuf aux Graines de Coriandre et Huile Pimentée Douce',
          category: 'viande',
          categoryIcon: '🥩',
          affinityPct: 91,
          affinityLevel: 'Harmonie Parfaite 🍷',
          keyIngredients: ['Filet de bœuf', 'Coriandre', 'Piment doux d\'Espelette', 'Ciboulette'],
          cookingAdvice: 'Servir frais en fines lamelles avec une vinaigrette légère aux agrumes.',
          molecularRationale: 'Le caractère épicé du rosé s\'associe à la fraîcheur de la viande crue sans l\'alourdir.',
        ),
      ]);
    }

    // Fallback general pairings
    if (pairings.isEmpty) {
      pairings.add(
        const ReverseFoodPairing(
          dishName: 'Planche de Charcuteries Artisanales & Fromages Affinés du Terroir',
          category: 'fromage',
          categoryIcon: '🧀',
          affinityPct: 92,
          affinityLevel: 'Harmonie Universelle 🍷',
          keyIngredients: ['Jambon affiné', 'Fromage au lait cru', 'Pain au levain', 'Cornichons'],
          cookingAdvice: 'Sortir les fromages et charcuteries 30 minutes avant dégustation à température ambiante.',
          molecularRationale: 'L\'équilibre entre le sel, le gras et la texture résonne avec la structure du vin.',
        ),
      );
    }

    return pairings;
  }
}
