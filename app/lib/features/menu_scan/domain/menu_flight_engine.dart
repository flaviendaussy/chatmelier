import 'menu_wine.dart';

enum FlightFormat {
  threeGlasses(3, 'Flight Express (3 verres)', '3 verres progressifs pour une dégustation équilibrée'),
  fiveGlasses(5, 'Grand Flight Sommelier (5 verres)', 'Parcours oenologique complet de 5 verres d\'auteur');

  final int glassCount;
  final String labelFr;
  final String descriptionFr;

  const FlightFormat(this.glassCount, this.labelFr, this.descriptionFr);
}

enum FlightWineColor {
  mix('Mix (Harmonie)', 'Parcours panaché de blanc, rosé et rouge', '🍷🥂'),
  white('100% Blanc', 'De la minéralité à la richesse aromatique', '🥂'),
  rose('100% Rosé', 'De la fraîcheur florale au rosé de gastronomie', '🌸'),
  red('100% Rouge', 'Du fruit croquant aux grands rouges de caractère', '🍷');

  final String labelFr;
  final String descriptionFr;
  final String icon;

  const FlightWineColor(this.labelFr, this.descriptionFr, this.icon);
}

enum FlightTheme {
  progressive('Progressif & Équilibré', 'De la fraîcheur à la puissance'),
  terroirDiscovery('Focus Terroirs & Pépites', 'Les plus beaux terroirs de la carte'),
  redLovers('Grands Rouges d\'Auteur', 'Évolution et texture des rouges'),
  whiteLovers('Blancs & Minéralité', 'Des bulles à la richesse aromatique');

  final String labelFr;
  final String descriptionFr;

  const FlightTheme(this.labelFr, this.descriptionFr);
}

class FlightGlassStep {
  final int stepIndex; // 1 to 5
  final String stepTitle;
  final MenuWine wine;
  final String sommelierRole; // e.g. "Ouverture & Tension", "Cœur de Dégustation", "Climax & Profondeur"
  final String tastingNotesSummary;
  final double? glassPrice;

  const FlightGlassStep({
    required this.stepIndex,
    required this.stepTitle,
    required this.wine,
    required this.sommelierRole,
    required this.tastingNotesSummary,
    this.glassPrice,
  });
}

class TastingFlightProposal {
  final String title;
  final String storyline;
  final FlightFormat format;
  final FlightWineColor color;
  final FlightTheme theme;
  final List<FlightGlassStep> steps;
  final double totalEstimatedPrice;

  const TastingFlightProposal({
    required this.title,
    required this.storyline,
    required this.format,
    this.color = FlightWineColor.mix,
    required this.theme,
    required this.steps,
    required this.totalEstimatedPrice,
  });
}

class MenuFlightEngine {
  /// Compose un flight cohérent de 3 ou 5 verres à partir des vins scannés sur la carte.
  static TastingFlightProposal buildFlight({
    required ScannedMenu menu,
    FlightFormat format = FlightFormat.threeGlasses,
    FlightWineColor color = FlightWineColor.mix,
    FlightTheme theme = FlightTheme.progressive,
  }) {
    final wines = List<MenuWine>.from(menu.wines);
    if (wines.isEmpty) {
      return TastingFlightProposal(
        title: 'Flight Sommelier',
        storyline: 'Aucun vin détecté sur cette carte.',
        format: format,
        color: color,
        theme: theme,
        steps: [],
        totalEstimatedPrice: 0.0,
      );
    }

    final selectedSteps = <FlightGlassStep>[];
    final targetCount = format.glassCount;

    // Catégorisation des vins par familles
    final sparkling = wines.where((w) => _isSparkling(w)).toList();
    final whites = wines.where((w) => _isWhite(w)).toList();
    final roses = wines.where((w) => _isRose(w)).toList();
    final reds = wines.where((w) => _isRed(w)).toList();
    final sweetOrSpirit = wines.where((w) => _isSweetOrSpirit(w)).toList();

    // Tri interne par fraîcheur / minéralité / puissance
    whites.sort((a, b) => _mineralRank(b).compareTo(_mineralRank(a)));
    roses.sort((a, b) => _freshnessRank(b).compareTo(_freshnessRank(a)));
    reds.sort((a, b) => _powerRank(a).compareTo(_powerRank(b)));

    final usedIds = <String>{};

    MenuWine? pickWine(List<MenuWine> pool, {bool fromEnd = false}) {
      final available = pool.where((w) => !usedIds.contains(w.name)).toList();
      if (available.isEmpty) return null;
      final picked = fromEnd ? available.last : available.first;
      usedIds.add(picked.name);
      return picked;
    }

    final List<MenuWine> selectedWines;
    final List<(String, String, String)> descriptors;
    final String flightTitle;
    final String restName = menu.restaurantName.isNotEmpty ? menu.restaurantName : 'ce restaurant';
    final String storyline;

    switch (color) {
      case FlightWineColor.white:
        flightTitle = format == FlightFormat.threeGlasses
            ? 'Flight 100% Blancs (3 Verres)'
            : 'Grand Flight 100% Blancs (5 Verres)';
        storyline = 'Une traversée lumineuse des cépages blancs de $restName, de la vivacité minérale aux textures les plus riches.';

        if (targetCount == 3) {
          final w1 = pickWine(sparkling) ?? pickWine(whites) ?? pickWine(wines);
          final w2 = pickWine(whites) ?? pickWine(wines);
          final w3 = pickWine(whites, fromEnd: true) ?? pickWine(sweetOrSpirit) ?? pickWine(wines);
          selectedWines = [w1, w2, w3].whereType<MenuWine>().toList();
          descriptors = [
            ('1. L\'Ouverture Minérale', 'Tension & Salinité', 'Éveille le palais avec vivacité et pureté cristalline.'),
            ('2. Le Cœur Aromatique', 'Fleurs & Fruits Mûrs', 'Déploie une texture soyeuse, pêche blanche et fruits à noyau.'),
            ('3. L\'Apogée Gastronomique', 'Volume & Élevage Noble', 'Grand blanc de repas, texture beurrée et finale profonde.'),
          ];
        } else {
          final w1 = pickWine(sparkling) ?? pickWine(whites) ?? pickWine(wines);
          final w2 = pickWine(whites) ?? pickWine(wines);
          final w3 = pickWine(whites) ?? pickWine(wines);
          final w4 = pickWine(whites, fromEnd: true) ?? pickWine(whites) ?? pickWine(wines);
          final w5 = pickWine(sweetOrSpirit) ?? pickWine(whites, fromEnd: true) ?? pickWine(wines);
          selectedWines = [w1, w2, w3, w4, w5].whereType<MenuWine>().toList();
          descriptors = [
            ('1. L\'Éveil Pétillant', 'Bulles & Salinité', 'Fraîcheur éclatante et bulles fines pour ouvrir la dégustation.'),
            ('2. La Tension Minérale', 'Pureté & Vivacité', 'Arômes d\'agrumes ciselés et belle tension calcaire.'),
            ('3. L\'Éclat Aromatique', 'Fleurs & Fruits d\'Arbre', 'Richesse florale et toucher de bouche soyeux.'),
            ('4. La Plénitude Gastronomique', 'Grand Blanc d\'Élevage', 'Complexité beurrée, boisé délicat et grand terroir.'),
            ('5. La Quintessence', 'Douceur ou Haute Garde', 'Finale magistrale d\'une longue persistance aromatique.'),
          ];
        }
        break;

      case FlightWineColor.rose:
        flightTitle = format == FlightFormat.threeGlasses
            ? 'Flight 100% Rosés (3 Verres)'
            : 'Grand Flight 100% Rosés (5 Verres)';
        storyline = 'L\'art des nuances rosées de $restName, de l\'aérien pétale de rose au grand rosé vineux de gastronomie.';

        final sparklingRose = sparkling.where((w) => _isRose(w)).toList();
        if (targetCount == 3) {
          final w1 = pickWine(sparklingRose) ?? pickWine(roses) ?? pickWine(whites) ?? pickWine(wines);
          final w2 = pickWine(roses) ?? pickWine(wines);
          final w3 = pickWine(roses, fromEnd: true) ?? pickWine(reds) ?? pickWine(wines);
          selectedWines = [w1, w2, w3].whereType<MenuWine>().toList();
          descriptors = [
            ('1. La Fraîcheur Saline', 'Agrumes & Pétale de Rose', 'Rosé aérien, groseille croquante et vivacité désaltérante.'),
            ('2. La Gourmandise Fruitée', 'Petits Fruits & Épices', 'Texture veloutée, framboise fraîche et épices douces.'),
            ('3. Le Rosé de Gastronomie', 'Structure & Vin de Repas', 'Matière généreuse et racée, idéal pour accompagner les mets.'),
          ];
        } else {
          final w1 = pickWine(sparklingRose) ?? pickWine(roses) ?? pickWine(whites) ?? pickWine(wines);
          final w2 = pickWine(roses) ?? pickWine(wines);
          final w3 = pickWine(roses) ?? pickWine(wines);
          final w4 = pickWine(roses, fromEnd: true) ?? pickWine(roses) ?? pickWine(wines);
          final w5 = pickWine(roses, fromEnd: true) ?? pickWine(reds) ?? pickWine(wines);
          selectedWines = [w1, w2, w3, w4, w5].whereType<MenuWine>().toList();
          descriptors = [
            ('1. L\'Éveil Rosé', 'Bulles Fines & Baies Rouges', 'Effervescence délicate et notes de framboise sauvage.'),
            ('2. La Clarté Cristalline', 'Minéralité & Pamplemousse', 'Tension saline et fraîcheur printanière.'),
            ('3. L\'Épanouissement Aromatique', 'Fraise des Bois & Pêche', 'Gourmandise ronde et texture caressante.'),
            ('4. La Matière Sommelière', 'Rosé de Terroir & Fût', 'Complexité d\'un grand rosé structuré et racé.'),
            ('5. L\'Accord Sommet', 'Rosé de Saignée & Puissance', 'Rondeur vineuse et finale persistante.'),
          ];
        }
        break;

      case FlightWineColor.red:
        flightTitle = format == FlightFormat.threeGlasses
            ? 'Flight 100% Rouges (3 Verres)'
            : 'Grand Flight 100% Rouges (5 Verres)';
        storyline = 'Une ascension sensorielle à travers les grands cépages rouges de $restName, du fruit croquant aux flacons de noble garde.';

        if (targetCount == 3) {
          final w1 = pickWine(reds) ?? pickWine(wines);
          final w2 = pickWine(reds) ?? pickWine(wines);
          final w3 = pickWine(reds, fromEnd: true) ?? pickWine(wines);
          selectedWines = [w1, w2, w3].whereType<MenuWine>().toList();
          descriptors = [
            ('1. Le Fruit Croquant', 'Finesse & Tanins Soyeux', 'Arômes de cerise fraîche, tanins fins et pureté désaltérante.'),
            ('2. L\'Assise Épicée', 'Rondeur & Fruits Noirs', 'Matière enveloppante, mûre sauvage, épices douces et équilibre.'),
            ('3. La Puissance Noble', 'Grand Vin de Garde', 'Charpente tannique affirmée, boisé noble et finale persistante.'),
          ];
        } else {
          final w1 = pickWine(reds) ?? pickWine(wines);
          final w2 = pickWine(reds) ?? pickWine(wines);
          final w3 = pickWine(reds) ?? pickWine(wines);
          final w4 = pickWine(reds, fromEnd: true) ?? pickWine(reds) ?? pickWine(wines);
          final w5 = pickWine(reds, fromEnd: true) ?? pickWine(sweetOrSpirit) ?? pickWine(wines);
          selectedWines = [w1, w2, w3, w4, w5].whereType<MenuWine>().toList();
          descriptors = [
            ('1. L\'Innocence du Fruit', 'Pureté & Fraîcheur Croquante', 'Cerise griotte, tanins aériens et grande buvabilité.'),
            ('2. L\'Élégance Florale', 'Finesse & Épices Douces', 'Violette, sous-bois délicat et grain soyeux.'),
            ('3. La Densité Solaire', 'Fruits Noirs & Garrigue', 'Matière généreuse, thym sauvage et volume en bouche.'),
            ('4. La Structure Magistrale', 'Grand Rouge d\'Élevage', 'Tanins patinés par le bois noble, cassis et tabac blond.'),
            ('5. L\'Apothéose', 'Haute Garde & Persistance', 'Profondeur remarquable et grande rémanence.'),
          ];
        }
        break;

      case FlightWineColor.mix:
        flightTitle = format == FlightFormat.threeGlasses
            ? 'Flight Découverte (3 Verres)'
            : 'Grand Flight de la Carte (5 Verres)';
        storyline = format == FlightFormat.threeGlasses
            ? 'Un triptyque harmonieux sélectionné sur la carte de $restName, guidé par une montée progressive en intensité.'
            : 'Un parcours sommelier en 5 mouvements explorant les contrastes et les grandes expressions de la cave de $restName.';

        if (targetCount == 3) {
          final w1 = pickWine(sparkling) ?? pickWine(whites) ?? pickWine(wines);
          final w2 = pickWine(roses) ?? pickWine(whites, fromEnd: true) ?? pickWine(reds) ?? pickWine(wines);
          final w3 = pickWine(reds, fromEnd: true) ?? pickWine(sweetOrSpirit) ?? pickWine(wines);
          selectedWines = [w1, w2, w3].whereType<MenuWine>().toList();
          descriptors = [
            ('1. L\'Ouverture', 'Éveil & Fraîcheur', 'Prépare le palais avec vivacité et pureté minérale.'),
            ('2. Le Corps & La Nuance', 'Texture & Équilibre', 'Apporte texture, volume et complexité aromatique.'),
            ('3. L\'Apogée & La Puissance', 'Caractère & Profondeur', 'Clôture la séquence sur une structure mûre et intense.'),
          ];
        } else {
          final w1 = pickWine(sparkling) ?? pickWine(whites) ?? pickWine(wines);
          final w2 = pickWine(whites, fromEnd: true) ?? pickWine(whites) ?? pickWine(wines);
          final w3 = pickWine(roses) ?? pickWine(reds) ?? pickWine(wines);
          final w4 = pickWine(reds, fromEnd: true) ?? pickWine(reds) ?? pickWine(wines);
          final w5 = pickWine(sweetOrSpirit) ?? pickWine(reds, fromEnd: true) ?? pickWine(wines);
          selectedWines = [w1, w2, w3, w4, w5].whereType<MenuWine>().toList();
          descriptors = [
            ('1. L\'Éveil', 'Bulles & Vivacité', 'Mise en bouche saline et tranchante.'),
            ('2. La Rondeur', 'Blanc Gastronomique', 'Expression florale, fruits mûrs et texture soyeuse.'),
            ('3. La Transition', 'Rouge Fruit & Finesse', 'Tanins fins, fraîcheur croquante pour la liaison.'),
            ('4. La Structure', 'Grand Rouge d\'Assise', 'Plénitude, épices nobles et longueur en bouche.'),
            ('5. La Conclusion', 'Élixir ou Fin de Bouche', 'Point d\'orgue de la dégustation.'),
          ];
        }
        break;
    }

    // Remplissage de secours si la carte est très restreinte
    while (selectedWines.length < targetCount && wines.isNotEmpty) {
      final fallback = wines.firstWhere((w) => !selectedWines.contains(w), orElse: () => wines.first);
      selectedWines.add(fallback);
    }

    for (int i = 0; i < selectedWines.length && i < targetCount; i++) {
      final w = selectedWines[i];
      final (title, role, pitch) = descriptors[i];
      selectedSteps.add(FlightGlassStep(
        stepIndex: i + 1,
        stepTitle: title,
        wine: w,
        sommelierRole: role,
        tastingNotesSummary: pitch,
        glassPrice: _resolveGlassPrice(w),
      ));
    }

    final totalPrice = selectedSteps.fold<double>(0.0, (sum, step) => sum + (step.glassPrice ?? 0.0));

    return TastingFlightProposal(
      title: flightTitle,
      storyline: storyline,
      format: format,
      color: color,
      theme: theme,
      steps: selectedSteps,
      totalEstimatedPrice: double.parse(totalPrice.toStringAsFixed(1)),
    );
  }

  static bool _isSparkling(MenuWine w) {
    final t = '${w.wineType} ${w.name} ${w.appellation ?? ""}'.toLowerCase();
    return t.contains('champ') || t.contains('spark') || t.contains('efferv') || t.contains('prosecco') || t.contains('cremant') || t.contains('crémant') || t.contains('cava');
  }

  static bool _isWhite(MenuWine w) {
    final t = '${w.wineType} ${w.name}'.toLowerCase();
    return t.contains('blanc') || t.contains('white') || t.contains('chardonnay') || t.contains('sauvignon') || t.contains('chenin') || t.contains('riesling') || t.contains('viognier');
  }

  static bool _isRose(MenuWine w) {
    final t = '${w.wineType} ${w.name} ${w.appellation ?? ""}'.toLowerCase();
    return t.contains('rosé') || t.contains('rose') || t.contains('tavel') || t.contains('clairet') || t.contains('bandol rosé');
  }

  static bool _isRed(MenuWine w) {
    final t = '${w.wineType} ${w.name}'.toLowerCase();
    return t.contains('rouge') || t.contains('red') || t.contains('pinot') || t.contains('syrah') || t.contains('merlot') || t.contains('cabernet') || t.contains('grenache') || t.contains('nebbiolo');
  }

  static bool _isSweetOrSpirit(MenuWine w) {
    final t = '${w.wineType} ${w.name}'.toLowerCase();
    return t.contains('porto') || t.contains('sauternes') || t.contains('moelleux') || t.contains('liqueur') || t.contains('whisky') || t.contains('cognac') || t.contains('rhum') || t.contains('digestif');
  }

  static double _freshnessRank(MenuWine w) {
    final r = w.metrics;
    return (r.acidity * 10) + (r.minerality * 6) - (r.body * 2);
  }

  static double _mineralRank(MenuWine w) {
    final r = w.metrics;
    return (r.acidity * 10) + (r.minerality * 10);
  }

  static double _powerRank(MenuWine w) {
    final r = w.metrics;
    return (r.body * 10) + (r.tannins * 10) + (r.oak * 5);
  }

  static double _resolveGlassPrice(MenuWine w) {
    if (w.glassPrices.isNotEmpty && w.glassPrices.first.price > 0) {
      return w.glassPrices.first.price;
    }
    if (w.bottlePrice != null && w.bottlePrice! > 0) {
      return double.parse((w.bottlePrice! * 0.20).toStringAsFixed(1));
    }
    return 8.0;
  }
}
