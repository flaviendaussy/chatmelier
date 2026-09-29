import 'menu_wine.dart';

enum FlightFormat {
  threeGlasses(3, 'Flight Express (3 verres)', '3 verres progressifs pour une dégustation équilibrée',
      'Express Flight (3 glasses)', '3 progressive glasses for a balanced tasting'),
  fiveGlasses(5, 'Grand Flight Sommelier (5 verres)', 'Un parcours complet en cinq verres',
      'Grand Sommelier Flight (5 glasses)', 'A complete journey in five glasses');

  final int glassCount;
  final String labelFr;
  final String descriptionFr;
  final String labelEn;
  final String descriptionEn;

  const FlightFormat(this.glassCount, this.labelFr, this.descriptionFr, this.labelEn, this.descriptionEn);

  String label(bool isFr) => isFr ? labelFr : labelEn;
  String description(bool isFr) => isFr ? descriptionFr : descriptionEn;
}

enum FlightWineColor {
  mix('Mix (Harmonie)', 'Blanc, rosé et rouge, du plus vif au plus intense', '🍷🥂',
      'Mix (Harmony)', 'White, rosé and red, from the crispest to the most intense'),
  white('100% Blanc', 'Du plus vif au plus ample', '🥂', '100% White', 'From the crispest to the fullest'),
  rose('100% Rosé', 'Du plus aérien au plus vineux', '🌸', '100% Rosé', 'From the most delicate to the most vinous'),
  red('100% Rouge', 'Du plus souple au plus structuré', '🍷', '100% Red', 'From the silkiest to the most structured');

  final String labelFr;
  final String descriptionFr;
  final String icon;
  final String labelEn;
  final String descriptionEn;

  const FlightWineColor(this.labelFr, this.descriptionFr, this.icon, this.labelEn, this.descriptionEn);

  String label(bool isFr) => isFr ? labelFr : labelEn;
  String description(bool isFr) => isFr ? descriptionFr : descriptionEn;
}

enum FlightTheme {
  progressive('Progressif & Équilibré', 'De la fraîcheur à la puissance', 'Progressive & Balanced', 'From freshness to power'),
  terroirDiscovery('Focus Terroirs & Pépites', 'Les plus beaux terroirs de la carte', 'Terroirs & Gems', 'The finest terroirs on the list'),
  redLovers('Grands Rouges d\'Auteur', 'Évolution et texture des rouges', 'Signature Reds', 'How reds evolve in texture'),
  whiteLovers('Blancs & Minéralité', 'Des bulles aux blancs les plus amples', 'Whites & Minerality', 'From bubbles to the fullest whites');

  final String labelFr;
  final String descriptionFr;
  final String labelEn;
  final String descriptionEn;

  const FlightTheme(this.labelFr, this.descriptionFr, this.labelEn, this.descriptionEn);

  String label(bool isFr) => isFr ? labelFr : labelEn;
  String description(bool isFr) => isFr ? descriptionFr : descriptionEn;
}

class FlightGlassStep {
  final int stepIndex; // 1 to 5
  final String stepTitle;
  final MenuWine wine;
  final String sommelierRole; // e.g. "Ouverture & Tension", "Cœur de Dégustation", "Climax & Profondeur"
  final String tastingNotesSummary;
  final double? glassPrice;

  /// Le prix du verre n'est pas sur la carte : il est estimé (un cinquième de la
  /// bouteille). L'écran le dit — afficher « 22 £ / verre » pour un vin que le
  /// restaurant ne sert peut-être pas au verre serait affirmer un prix qui n'existe pas.
  final bool prixEstime;

  const FlightGlassStep({
    required this.stepIndex,
    required this.stepTitle,
    required this.wine,
    required this.sommelierRole,
    required this.tastingNotesSummary,
    this.glassPrice,
    this.prixEstime = false,
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
    bool isFr = true,
  }) {
    final fr = isFr;
    final wines = List<MenuWine>.from(menu.wines);
    if (wines.isEmpty) {
      return TastingFlightProposal(
        title: 'Flight Sommelier',
        storyline: fr ? 'Aucun vin détecté sur cette carte.' : 'No wine found on this list.',
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

    // Un flight « 100 % » d'une couleur ne se complète jamais avec une autre : mieux vaut
    // deux verres annoncés comme tels qu'un blanc au milieu d'un flight de rouges.
    final uneSeuleCouleur = color != FlightWineColor.mix;
    bool deLaCouleur(MenuWine w) => switch (color) {
          FlightWineColor.white => _isWhite(w) || (_isSparkling(w) && !_isRose(w)),
          FlightWineColor.rose => _isRose(w),
          FlightWineColor.red => _isRed(w),
          FlightWineColor.mix => true,
        };
    final secours = uneSeuleCouleur ? wines.where(deLaCouleur).toList() : wines;

    MenuWine? pickWine(List<MenuWine> pool, {bool fromEnd = false}) {
      final libres = pool.where((w) => !usedIds.contains(w.name)).toList();
      // Un flight se commande au verre : à style égal, un vin servi au verre passe
      // devant, dans l'ordre de progression déjà établi.
      final auVerre = libres.where((w) => w.hasGlassPrice).toList();
      final available = auVerre.isNotEmpty ? auVerre : libres;
      if (available.isEmpty) return null;
      final picked = fromEnd ? available.last : available.first;
      usedIds.add(picked.name);
      return picked;
    }

    final List<MenuWine> selectedWines;
    final String flightTitle;
    final String restName = menu.restaurantName.isNotEmpty
        ? menu.restaurantName
        : (fr ? 'ce restaurant' : 'this restaurant');
    final String storyline;
    final verresFr = format == FlightFormat.threeGlasses ? '(3 Verres)' : '(5 Verres)';
    final verresEn = format == FlightFormat.threeGlasses ? '(3 Glasses)' : '(5 Glasses)';

    switch (color) {
      case FlightWineColor.white:
        flightTitle = fr
            ? '${format == FlightFormat.threeGlasses ? '' : 'Grand '}Flight 100% Blancs $verresFr'
            : '${format == FlightFormat.threeGlasses ? '' : 'Grand '}100% White Flight $verresEn';
        storyline = fr
            ? 'Les blancs de $restName, du plus vif et minéral au plus ample.'
            : 'The whites of $restName, from the crispest and most mineral to the fullest.';

        if (targetCount == 3) {
          final w1 = pickWine(sparkling) ?? pickWine(whites) ?? pickWine(secours);
          final w2 = pickWine(whites) ?? pickWine(secours);
          final w3 = pickWine(whites, fromEnd: true) ?? pickWine(sweetOrSpirit) ?? pickWine(secours);
          selectedWines = [w1, w2, w3].whereType<MenuWine>().toList();
        } else {
          final w1 = pickWine(sparkling) ?? pickWine(whites) ?? pickWine(secours);
          final w2 = pickWine(whites) ?? pickWine(secours);
          final w3 = pickWine(whites) ?? pickWine(secours);
          final w4 = pickWine(whites, fromEnd: true) ?? pickWine(whites) ?? pickWine(secours);
          final w5 = pickWine(sweetOrSpirit) ?? pickWine(whites, fromEnd: true) ?? pickWine(secours);
          selectedWines = [w1, w2, w3, w4, w5].whereType<MenuWine>().toList();
        }
        break;

      case FlightWineColor.rose:
        flightTitle = fr
            ? '${format == FlightFormat.threeGlasses ? '' : 'Grand '}Flight 100% Rosés $verresFr'
            : '${format == FlightFormat.threeGlasses ? '' : 'Grand '}100% Rosé Flight $verresEn';
        storyline = fr
            ? 'Les rosés de $restName, du plus aérien au plus vineux.'
            : 'The rosés of $restName, from the most delicate to the most vinous.';

        final sparklingRose = sparkling.where((w) => _isRose(w)).toList();
        if (targetCount == 3) {
          final w1 = pickWine(sparklingRose) ?? pickWine(roses) ?? pickWine(secours);
          final w2 = pickWine(roses) ?? pickWine(secours);
          final w3 = pickWine(roses, fromEnd: true) ?? pickWine(secours);
          selectedWines = [w1, w2, w3].whereType<MenuWine>().toList();
        } else {
          final w1 = pickWine(sparklingRose) ?? pickWine(roses) ?? pickWine(secours);
          final w2 = pickWine(roses) ?? pickWine(secours);
          final w3 = pickWine(roses) ?? pickWine(secours);
          final w4 = pickWine(roses, fromEnd: true) ?? pickWine(roses) ?? pickWine(secours);
          final w5 = pickWine(roses, fromEnd: true) ?? pickWine(secours);
          selectedWines = [w1, w2, w3, w4, w5].whereType<MenuWine>().toList();
        }
        break;

      case FlightWineColor.red:
        flightTitle = fr
            ? '${format == FlightFormat.threeGlasses ? '' : 'Grand '}Flight 100% Rouges $verresFr'
            : '${format == FlightFormat.threeGlasses ? '' : 'Grand '}100% Red Flight $verresEn';
        // « Aux flacons de noble garde » promettait un vin de garde au bout, fût-il un
        // Côtes-du-Rhône de l'année : on ne promet que ce que l'ordre garantit.
        storyline = fr
            ? 'Les rouges de $restName, du plus souple au plus structuré.'
            : 'The reds of $restName, from the silkiest to the most structured.';

        if (targetCount == 3) {
          final w1 = pickWine(reds) ?? pickWine(secours);
          final w2 = pickWine(reds) ?? pickWine(secours);
          final w3 = pickWine(reds, fromEnd: true) ?? pickWine(secours);
          selectedWines = [w1, w2, w3].whereType<MenuWine>().toList();
        } else {
          final w1 = pickWine(reds) ?? pickWine(secours);
          final w2 = pickWine(reds) ?? pickWine(secours);
          final w3 = pickWine(reds) ?? pickWine(secours);
          final w4 = pickWine(reds, fromEnd: true) ?? pickWine(reds) ?? pickWine(secours);
          final w5 = pickWine(reds, fromEnd: true) ?? pickWine(sweetOrSpirit) ?? pickWine(secours);
          selectedWines = [w1, w2, w3, w4, w5].whereType<MenuWine>().toList();
        }
        break;

      case FlightWineColor.mix:
        flightTitle = fr
            ? (format == FlightFormat.threeGlasses ? 'Flight Découverte $verresFr' : 'Grand Flight de la Carte $verresFr')
            : (format == FlightFormat.threeGlasses ? 'Discovery Flight $verresEn' : 'Grand Flight of the List $verresEn');
        storyline = fr
            ? (format == FlightFormat.threeGlasses
                ? 'Trois verres de la carte de $restName, en montant en intensité.'
                : 'Cinq temps sur la carte de $restName, du plus vif au plus intense.')
            : (format == FlightFormat.threeGlasses
                ? 'Three glasses from the list at $restName, rising in intensity.'
                : 'Five movements across the list at $restName, from the crispest to the most intense.');

        if (targetCount == 3) {
          final w1 = pickWine(sparkling) ?? pickWine(whites) ?? pickWine(secours);
          final w2 = pickWine(roses) ?? pickWine(whites, fromEnd: true) ?? pickWine(reds) ?? pickWine(secours);
          final w3 = pickWine(reds, fromEnd: true) ?? pickWine(sweetOrSpirit) ?? pickWine(secours);
          selectedWines = [w1, w2, w3].whereType<MenuWine>().toList();
        } else {
          final w1 = pickWine(sparkling) ?? pickWine(whites) ?? pickWine(secours);
          final w2 = pickWine(whites, fromEnd: true) ?? pickWine(whites) ?? pickWine(secours);
          final w3 = pickWine(roses) ?? pickWine(reds) ?? pickWine(secours);
          final w4 = pickWine(reds, fromEnd: true) ?? pickWine(reds) ?? pickWine(secours);
          final w5 = pickWine(sweetOrSpirit) ?? pickWine(reds, fromEnd: true) ?? pickWine(secours);
          selectedWines = [w1, w2, w3, w4, w5].whereType<MenuWine>().toList();
        }
        break;
    }

    // Remplissage de secours si la carte est très restreinte — pour un flight mélangé
    // seulement, et sans servir deux fois le même vin (l'ancien `orElse: wines.first`
    // le faisait dès que la carte était épuisée).
    if (!uneSeuleCouleur) {
      for (final w in wines) {
        if (selectedWines.length >= targetCount) break;
        if (!selectedWines.contains(w)) selectedWines.add(w);
      }
    }
    final verres = selectedWines.length < targetCount ? selectedWines.length : targetCount;
    final flightCourt = uneSeuleCouleur && verres < targetCount;
    final nomCouleur = switch (color) {
      FlightWineColor.white => fr ? (verres > 1 ? 'blancs' : 'blanc') : (verres > 1 ? 'whites' : 'white'),
      FlightWineColor.rose => fr ? (verres > 1 ? 'rosés' : 'rosé') : (verres > 1 ? 'rosés' : 'rosé'),
      _ => fr ? (verres > 1 ? 'rouges' : 'rouge') : (verres > 1 ? 'reds' : 'red'),
    };

    final titres = _titresDesVerres(targetCount, fr);
    for (int i = 0; i < selectedWines.length && i < targetCount; i++) {
      final w = selectedWines[i];
      final (prix, estime) = _prixDuVerre(w);
      selectedSteps.add(FlightGlassStep(
        stepIndex: i + 1,
        stepTitle: titres[i],
        wine: w,
        sommelierRole: caractere(w, fr),
        tastingNotesSummary: _note(w, fr),
        glassPrice: prix,
        prixEstime: estime,
      ));
    }

    final totalPrice = selectedSteps.fold<double>(0.0, (sum, step) => sum + (step.glassPrice ?? 0.0));

    return TastingFlightProposal(
      title: flightCourt
          ? flightTitle.replaceFirst(
              RegExp(r'\(\d (Verres|Glasses)\)'),
              fr ? '($verres ${verres > 1 ? 'Verres' : 'Verre'})' : '($verres ${verres > 1 ? 'Glasses' : 'Glass'})')
          : flightTitle,
      storyline: !flightCourt
          ? storyline
          : fr
              ? switch (verres) {
                  0 => 'Cette carte ne propose aucun $nomCouleur.',
                  1 => '$storyline La carte ne propose qu\'un seul $nomCouleur : pas de quoi composer un vrai flight.',
                  _ => '$storyline La carte ne propose que $verres $nomCouleur : le flight en compte $verres.',
                }
              : switch (verres) {
                  0 => 'This list has no $nomCouleur.',
                  1 => '$storyline The list has only one $nomCouleur: not enough for a real flight.',
                  _ => '$storyline The list has only $verres $nomCouleur: the flight has $verres.',
                },
      format: format,
      color: color,
      theme: theme,
      steps: selectedSteps,
      totalEstimatedPrice: double.parse(totalPrice.toStringAsFixed(1)),
    );
  }

  /// Les titres des verres disent leur PLACE dans le parcours, pas le vin : « L'Apogée
  /// Gastronomique · Volume & Élevage Noble » s'écrivait sur n'importe quel troisième
  /// blanc, qu'il ait vu le bois ou non (29/09).
  static List<String> _titresDesVerres(int n, bool fr) => n == 3
      ? (fr
          ? const ['1. L\'Ouverture', '2. Le Cœur', '3. Le Final']
          : const ['1. The Opening', '2. The Heart', '3. The Finale'])
      : (fr
          ? const ['1. L\'Éveil', '2. La Montée', '3. Le Cœur', '4. L\'Apogée', '5. Le Final']
          : const ['1. The Awakening', '2. The Build-up', '3. The Heart', '4. The Peak', '5. The Finale']);

  /// Ce qui caractérise CE vin, lu dans son profil analysé — jamais un arôme fixé
  /// d'avance. Deux traits au plus, les plus saillants, et seulement ceux qui ont un sens
  /// pour sa couleur : la minéralité et le gras pour les blancs et les bulles, la
  /// charpente et la souplesse pour les rouges (mêmes règles que le consensus).
  static String caractere(MenuWine w, bool fr) {
    final m = w.metrics;
    final blancOuBulles = w.isSparkling || (w.isWhite && !w.isRose && !w.isRed);
    final traits = <(double, String, String)>[
      if (w.isSparkling) (20, 'Bulles', 'Bubbles'),
      if (m.sweetness >= 4) (m.sweetness + 3, 'Douceur', 'Sweetness'),
      if (m.acidity >= 7.5) (m.acidity, 'Vivacité', 'Crispness'),
      if (blancOuBulles && m.minerality >= 7.5) (m.minerality, 'Minéralité', 'Minerality'),
      if (w.isRed && m.tannins >= 7.5) (m.tannins, 'Charpente', 'Structure'),
      if (w.isRed && m.tannins > 0 && m.tannins <= 4.5) (10 - m.tannins, 'Souplesse', 'Silkiness'),
      if (m.body >= 7.5) (m.body, 'Ampleur', 'Fullness'),
      if (m.body > 0 && m.body <= 4.5) (10 - m.body, 'Légèreté', 'Lightness'),
      if (m.oak >= 6) (m.oak, 'Boisé', 'Oak'),
      if (blancOuBulles && m.butteriness >= 6) (m.butteriness, 'Gras', 'Creaminess'),
      if (m.fruit >= 7.5) (m.fruit, 'Fruit', 'Fruit'),
    ];
    if (traits.isEmpty) return fr ? 'Équilibre' : 'Balance';
    // Le tri de Dart n'est pas stable : à saillance égale, l'ordre de déclaration tranche,
    // sinon un même vin changerait de description d'un affichage à l'autre.
    final ordre = [for (var i = 0; i < traits.length; i++) i]
      ..sort((i, j) {
        final c = traits[j].$1.compareTo(traits[i].$1);
        return c != 0 ? c : i.compareTo(j);
      });
    return ordre.take(2).map((i) => fr ? traits[i].$2 : traits[i].$3).join(' & ');
  }

  /// La note du verre : ce que le scan a écrit de CE vin, sinon son profil en chiffres.
  static String _note(MenuWine w, bool fr) {
    final c = w.sommelierComment?.trim();
    if (c != null && c.isNotEmpty) return c;
    final m = w.metrics;
    String n(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return [
      '${fr ? 'Acidité' : 'Acidity'} ${n(m.acidity)}/10',
      '${fr ? 'Corps' : 'Body'} ${n(m.body)}/10',
      if (w.isRed) '${fr ? 'Tanins' : 'Tannins'} ${n(m.tannins)}/10',
      '${fr ? 'Bois' : 'Oak'} ${n(m.oak)}/10',
    ].join(' · ');
  }

  // La couleur vient d'abord du type lu par le scan (`MenuWine.isRed`…). Le nom et les
  // cépages ne servent qu'en dernier recours, quand le type est inconnu : lus en premier,
  // « pinot » classait rouge un Pinot Grigio, « sauvignon » classait blanc un Cabernet
  // Sauvignon, et « red » se trouvait dans « Sacred » — « flights rouges mais il y a des
  // blancs !! » (25/09).
  static bool _typeConnu(MenuWine w) => w.isRed || w.isWhite || w.isRose || w.isSparkling;

  static bool _nomContient(MenuWine w, List<String> indices, {bool avecAppellation = false}) {
    final t = '${w.name} ${avecAppellation ? w.appellation ?? '' : ''}'.toLowerCase();
    return indices.any(t.contains);
  }

  static bool _isSparkling(MenuWine w) => _typeConnu(w)
      ? w.isSparkling
      : _nomContient(w, ['champagne', 'prosecco', 'crémant', 'cremant', 'cava', 'spumante', 'sekt'],
          avecAppellation: true);

  static bool _isWhite(MenuWine w) => _typeConnu(w)
      ? w.isWhite
      : _nomContient(w, ['chardonnay', 'chenin', 'riesling', 'viognier', 'sauvignon blanc', 'chablis']);

  static bool _isRose(MenuWine w) =>
      _typeConnu(w) ? w.isRose : _nomContient(w, ['rosé', 'tavel', 'clairet'], avecAppellation: true);

  static bool _isRed(MenuWine w) => _typeConnu(w)
      ? w.isRed
      : _nomContient(w, ['pinot noir', 'syrah', 'merlot', 'cabernet', 'grenache', 'nebbiolo']);

  static bool _isSweetOrSpirit(MenuWine w) {
    final t = '${w.wineType} ${w.name}'.toLowerCase();
    return t.contains('dessert') || t.contains('fortified') || t.contains('porto') || t.contains('sauternes') || t.contains('moelleux') || t.contains('liqueur') || t.contains('whisky') || t.contains('cognac') || t.contains('rhum') || t.contains('digestif');
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

  /// Le prix du verre : celui de la carte, sinon une estimation (un cinquième de la
  /// bouteille), sinon aucun — plus de verre à 8 inventé pour un vin sans prix.
  static (double?, bool) _prixDuVerre(MenuWine w) {
    if (w.glassPrices.isNotEmpty && w.glassPrices.first.price > 0) {
      return (w.glassPrices.first.price, false);
    }
    if (w.bottlePrice != null && w.bottlePrice! > 0) {
      return (double.parse((w.bottlePrice! * 0.20).toStringAsFixed(1)), true);
    }
    return (null, false);
  }
}
