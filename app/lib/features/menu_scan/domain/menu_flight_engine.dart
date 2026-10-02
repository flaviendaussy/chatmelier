import '../../../shared/utils/langue.dart';
import '../../auth/domain/taste_profile.dart';
import '../../sommelier/domain/taste_frontier_engine.dart';
import 'menu_wine.dart';

enum FlightFormat {
  threeGlasses(3, Phrase('Flight Express (3 verres)', 'Express Flight (3 glasses)'),
      Phrase('3 verres progressifs pour une dégustation équilibrée', '3 progressive glasses for a balanced tasting')),
  fiveGlasses(5, Phrase('Grand Flight Sommelier (5 verres)', 'Grand Sommelier Flight (5 glasses)'),
      Phrase('Un parcours complet en cinq verres', 'A complete journey in five glasses'));

  final int glassCount;
  final Phrase libelle;
  final Phrase detail;

  const FlightFormat(this.glassCount, this.libelle, this.detail);

  String label(bool isFr) => libelle.dans(isFr);
  String description(bool isFr) => detail.dans(isFr);
}

enum FlightWineColor {
  mix(Phrase('Mix (Harmonie)', 'Mix (Harmony)'),
      Phrase('Blanc, rosé et rouge, du plus vif au plus intense', 'White, rosé and red, from the crispest to the most intense'), '🍷🥂'),
  white(Phrase('100% Blanc', '100% White'), Phrase('Du plus vif au plus ample', 'From the crispest to the fullest'), '🥂'),
  rose(Phrase('100% Rosé', '100% Rosé'), Phrase('Du plus aérien au plus vineux', 'From the most delicate to the most vinous'), '🌸'),
  red(Phrase('100% Rouge', '100% Red'), Phrase('Du plus souple au plus structuré', 'From the silkiest to the most structured'), '🍷');

  final Phrase libelle;
  final Phrase detail;
  final String icon;

  const FlightWineColor(this.libelle, this.detail, this.icon);

  String label(bool isFr) => libelle.dans(isFr);
  String description(bool isFr) => detail.dans(isFr);
}

enum FlightTheme {
  progressive(Phrase('Progressif & Équilibré', 'Progressive & Balanced'), Phrase('De la fraîcheur à la puissance', 'From freshness to power')),
  terroirDiscovery(Phrase('Focus Terroirs & Pépites', 'Terroirs & Gems'), Phrase('Les plus beaux terroirs de la carte', 'The finest terroirs on the list')),
  redLovers(Phrase('Grands Rouges d\'Auteur', 'Signature Reds'), Phrase('Évolution et texture des rouges', 'How reds evolve in texture')),
  whiteLovers(Phrase('Blancs & Minéralité', 'Whites & Minerality'), Phrase('Des bulles aux blancs les plus amples', 'From bubbles to the fullest whites'));

  final Phrase libelle;
  final Phrase detail;

  const FlightTheme(this.libelle, this.detail);

  String label(bool isFr) => libelle.dans(isFr);
  String description(bool isFr) => detail.dans(isFr);
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
  /// Le parcours qui vous apprend quelque chose (V2.3 · J4) : un verre dans un style que
  /// vous aimez, ceux qui en apprendraient le plus sur votre palais — un axe différent
  /// chacun quand la carte le permet —, et une valeur sûre.
  ///
  /// Le plaisir prédit (`userMatchScore`) désigne le verre aimé et la valeur sûre ; le
  /// moteur de frontière choisit les autres, parmi les vins qu'on n'a ni goûtés ni en
  /// cave, sans heurter une aversion déclarée. Au verre d'abord, comme tout flight.
  ///
  /// Les verres se servent ensuite du plus léger au plus intense, chacun avec son rôle :
  /// un Chablis bu juste après un rouge tannique dirait mal sa minéralité — précisément
  /// ce qu'on voulait apprendre. À intensité égale, l'ordre des rôles est gardé.
  static TastingFlightProposal buildFrontierFlight({
    required ScannedMenu menu,
    required TasteProfile palais,
    FlightFormat format = FlightFormat.threeGlasses,
    FlightWineColor color = FlightWineColor.mix,
    bool isFr = true,
  }) {
    final fr = isFr;
    final n = format.glassCount;
    bool deLaCouleur(MenuWine w) => switch (color) {
          FlightWineColor.white => _isWhite(w) || (_isSparkling(w) && !_isRose(w)),
          FlightWineColor.rose => _isRose(w),
          FlightWineColor.red => _isRed(w),
          FlightWineColor.mix => true,
        };
    final deCouleur = menu.wines.where(deLaCouleur).toList();
    final auVerre = deCouleur.where((w) => w.hasGlassPrice).toList();
    final pool = auVerre.length >= n ? auVerre : deCouleur;
    final pris = <MenuWine>{};

    double plaisir(MenuWine w) => w.userMatchScore ?? 0;
    MenuWine? leMieuxAime() {
      final libres = pool.where((w) => !pris.contains(w)).toList()
        ..sort((a, b) {
          final c = plaisir(b).compareTo(plaisir(a));
          if (c != 0) return c;
          return (_prixDuVerre(a).$1 ?? double.infinity).compareTo(_prixDuVerre(b).$1 ?? double.infinity);
        });
      return libres.firstOrNull;
    }

    final premier = leMieuxAime();
    if (premier != null) pris.add(premier);

    // Les verres du milieu : les plus instructifs, un axe chacun tant que possible.
    final instructifs = <(MenuWine, String)>[];
    final axesVus = <String>{};
    while (instructifs.length < n - 2) {
      final libres = TasteFrontierEngine.candidatsDeLaCarte(pool).where((w) => !pris.contains(w)).toList();
      SuggestionDeFrontiere<MenuWine>? choix(List<MenuWine> parmi) => TasteFrontierEngine.choisir<MenuWine>(
            parmi,
            palais,
            profilDe: ProfilDeVin.depuisLaCarte,
            plaisir: (w) => w.userMatchScore,
            prix: prixPourApprendre,
          );
      final nouveaux = libres.where((w) {
        final r = TasteFrontierEngine.evaluer(ProfilDeVin.depuisLaCarte(w), palais);
        return r != null && !axesVus.contains(r.$2);
      }).toList();
      final s = choix(nouveaux) ?? choix(libres);
      if (s == null) break;
      instructifs.add((s.vin, s.axe));
      axesVus.add(s.axe);
      pris.add(s.vin);
    }

    final dernier = leMieuxAime();
    if (dernier != null) pris.add(dernier);
    // Une carte trop courte pour apprendre : le milieu se remplit de vins aimés.
    final milieu = [
      for (final (w, axe) in instructifs) (w, trSi(fr, 'Pour savoir ce que vous pensez {quoi}', 'To find out how you feel about {quoi}', {'quoi': TasteFrontierEngine.ceQueJugeLAxe(axe)})),
    ];
    while (milieu.length < n - 2) {
      final w = leMieuxAime();
      if (w == null) break;
      pris.add(w);
      milieu.add((w, caractere(w, fr)));
    }

    final roles = [
      if (premier != null) (premier, trSi(fr, 'Un style que vous aimez', 'A style you enjoy')),
      ...milieu,
      if (dernier != null) (dernier, trSi(fr, 'Une valeur sûre', 'A safe bet')),
    ];
    final verres = [
      for (final (i, v) in roles.indexed) (i, v),
    ]..sort((a, b) {
        final c = _rangDeService(a.$2.$1).compareTo(_rangDeService(b.$2.$1));
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    final titres = _titresDesVerres(n, fr);
    final steps = <FlightGlassStep>[
      for (var i = 0; i < verres.length && i < n; i++)
        FlightGlassStep(
          stepIndex: i + 1,
          stepTitle: titres[i],
          wine: verres[i].$2.$1,
          sommelierRole: verres[i].$2.$2,
          tastingNotesSummary: _note(verres[i].$2.$1, fr),
          glassPrice: _prixDuVerre(verres[i].$2.$1).$1,
          prixEstime: _prixDuVerre(verres[i].$2.$1).$2,
        ),
    ];
    final total = steps.fold<double>(0.0, (sum, s) => sum + (s.glassPrice ?? 0.0));
    return TastingFlightProposal(
      title: trSi(fr, 'Pour mieux vous connaître ({verres})', 'To know you better ({verres})', {'verres': _verres(steps.length, fr)}),
      storyline: steps.isEmpty
          ? trSi(fr, 'Aucun vin détecté sur cette carte.', 'No wine found on this list.')
          : trSi(fr, 'Un verre que vous aimerez, ceux qui m\'apprendront le plus sur votre palais, et une valeur sûre — servis du plus léger au plus intense.',
              'A glass you will enjoy, the ones that will teach me most about your palate, and a safe bet — served from the lightest to the most intense.'),
      format: format,
      color: color,
      theme: FlightTheme.progressive,
      steps: steps,
      totalEstimatedPrice: double.parse(total.toStringAsFixed(1)),
    );
  }

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
        storyline: trSi(fr, 'Aucun vin détecté sur cette carte.', 'No wine found on this list.'),
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
    // Le titre dépend du nombre de verres réellement servis : calculé à la fin.
    final String Function(int verres) titreDuFlight;
    final String restName = menu.restaurantName.isNotEmpty
        ? menu.restaurantName
        : (trSi(fr, 'ce restaurant', 'this restaurant'));
    final String storyline;
    final grand = format != FlightFormat.threeGlasses;

    switch (color) {
      case FlightWineColor.white:
        titreDuFlight = (n) => grand
            ? trSi(fr, 'Grand Flight 100% Blancs ({verres})', 'Grand 100% White Flight ({verres})', {'verres': _verres(n, fr)})
            : trSi(fr, 'Flight 100% Blancs ({verres})', '100% White Flight ({verres})', {'verres': _verres(n, fr)});
        storyline = trSi(fr, 'Les blancs de {restName}, du plus vif et minéral au plus ample.', 'The whites of {restName}, from the crispest and most mineral to the fullest.', {'restName': restName});

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
        titreDuFlight = (n) => grand
            ? trSi(fr, 'Grand Flight 100% Rosés ({verres})', 'Grand 100% Rosé Flight ({verres})', {'verres': _verres(n, fr)})
            : trSi(fr, 'Flight 100% Rosés ({verres})', '100% Rosé Flight ({verres})', {'verres': _verres(n, fr)});
        storyline = trSi(fr, 'Les rosés de {restName}, du plus aérien au plus vineux.', 'The rosés of {restName}, from the most delicate to the most vinous.', {'restName': restName});

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
        titreDuFlight = (n) => grand
            ? trSi(fr, 'Grand Flight 100% Rouges ({verres})', 'Grand 100% Red Flight ({verres})', {'verres': _verres(n, fr)})
            : trSi(fr, 'Flight 100% Rouges ({verres})', '100% Red Flight ({verres})', {'verres': _verres(n, fr)});
        // « Aux flacons de noble garde » promettait un vin de garde au bout, fût-il un
        // Côtes-du-Rhône de l'année : on ne promet que ce que l'ordre garantit.
        storyline = trSi(fr, 'Les rouges de {restName}, du plus souple au plus structuré.', 'The reds of {restName}, from the silkiest to the most structured.', {'restName': restName});

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
        titreDuFlight = (n) => grand
            ? trSi(fr, 'Grand Flight de la Carte ({verres})', 'Grand Flight of the List ({verres})', {'verres': _verres(n, fr)})
            : trSi(fr, 'Flight Découverte ({verres})', 'Discovery Flight ({verres})', {'verres': _verres(n, fr)});
        storyline = grand
            ? trSi(fr, 'Cinq temps sur la carte de {restName}, du plus vif au plus intense.',
                'Five movements across the list at {restName}, from the crispest to the most intense.', {'restName': restName})
            : trSi(fr, 'Trois verres de la carte de {restName}, en montant en intensité.',
                'Three glasses from the list at {restName}, rising in intensity.', {'restName': restName});

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
      FlightWineColor.white => verres > 1 ? trSi(fr, 'blancs', 'whites') : trSi(fr, 'blanc', 'white'),
      FlightWineColor.rose => verres > 1 ? trSi(fr, 'rosés', 'rosés') : trSi(fr, 'rosé', 'rosé'),
      _ => verres > 1 ? trSi(fr, 'rouges', 'reds') : trSi(fr, 'rouge', 'red'),
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
      title: titreDuFlight(flightCourt ? verres : targetCount),
      storyline: !flightCourt
          ? storyline
          : switch (verres) {
              0 => trSi(fr, 'Cette carte ne propose aucun {couleur}.', 'This list has no {couleur}.', {'couleur': nomCouleur}),
              1 => trSi(fr, '{recit} La carte ne propose qu\'un seul {couleur} : pas de quoi composer un vrai flight.',
                  '{recit} The list has only one {couleur}: not enough for a real flight.', {'recit': storyline, 'couleur': nomCouleur}),
              _ => trSi(fr, '{recit} La carte ne propose que {verres} {couleur} : le flight en compte {verres}.',
                  '{recit} The list has only {verres} {couleur}: the flight has {verres}.',
                  {'recit': storyline, 'verres': verres, 'couleur': nomCouleur}),
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
  static List<String> _titresDesVerres(int n, bool fr) => [
        for (final p in n == 3 ? _titresEnTrois : _titresEnCinq) p.dans(fr),
      ];

  static const _titresEnTrois = [
    Phrase('1. L\'Ouverture', '1. The Opening'),
    Phrase('2. Le Cœur', '2. The Heart'),
    Phrase('3. Le Final', '3. The Finale'),
  ];

  static const _titresEnCinq = [
    Phrase('1. L\'Éveil', '1. The Awakening'),
    Phrase('2. La Montée', '2. The Build-up'),
    Phrase('3. Le Cœur', '3. The Heart'),
    Phrase('4. L\'Apogée', '4. The Peak'),
    Phrase('5. Le Final', '5. The Finale'),
  ];

  /// « 1 Verre », « 3 Verres » : l'accord se fait dans chaque langue.
  static String _verres(int n, bool fr) =>
      n == 1 ? trSi(fr, '1 Verre', '1 Glass') : trSi(fr, '{n} Verres', '{n} Glasses', {'n': n});

  /// Ce qui caractérise CE vin, lu dans son profil analysé — jamais un arôme fixé
  /// d'avance. Deux traits au plus, les plus saillants, et seulement ceux qui ont un sens
  /// pour sa couleur : la minéralité et le gras pour les blancs et les bulles, la
  /// charpente et la souplesse pour les rouges (mêmes règles que le consensus).
  static String caractere(MenuWine w, bool fr) {
    final m = w.metrics;
    final blancOuBulles = w.isSparkling || (w.isWhite && !w.isRose && !w.isRed);
    final traits = <(double, Phrase)>[
      if (w.isSparkling) (20, Phrase('Bulles', 'Bubbles')),
      if (m.sweetness >= 4) (m.sweetness + 3, Phrase('Douceur', 'Sweetness')),
      if (m.acidity >= 7.5) (m.acidity, Phrase('Vivacité', 'Crispness')),
      if (blancOuBulles && m.minerality >= 7.5) (m.minerality, Phrase('Minéralité', 'Minerality')),
      if (w.isRed && m.tannins >= 7.5) (m.tannins, Phrase('Charpente', 'Structure')),
      if (w.isRed && m.tannins > 0 && m.tannins <= 4.5) (10 - m.tannins, Phrase('Souplesse', 'Silkiness')),
      if (m.body >= 7.5) (m.body, Phrase('Ampleur', 'Fullness')),
      if (m.body > 0 && m.body <= 4.5) (10 - m.body, Phrase('Légèreté', 'Lightness')),
      if (m.oak >= 6) (m.oak, Phrase('Boisé', 'Oak')),
      if (blancOuBulles && m.butteriness >= 6) (m.butteriness, Phrase('Gras', 'Creaminess')),
      if (m.fruit >= 7.5) (m.fruit, Phrase('Fruit', 'Fruit')),
    ];
    if (traits.isEmpty) return trSi(fr, 'Équilibre', 'Balance');
    // Le tri de Dart n'est pas stable : à saillance égale, l'ordre de déclaration tranche,
    // sinon un même vin changerait de description d'un affichage à l'autre.
    final ordre = [for (var i = 0; i < traits.length; i++) i]
      ..sort((i, j) {
        final c = traits[j].$1.compareTo(traits[i].$1);
        return c != 0 ? c : i.compareTo(j);
      });
    return ordre.take(2).map((i) => traits[i].$2.dans(fr)).join(' & ');
  }

  /// La note du verre : ce que le scan a écrit de CE vin, sinon son profil en chiffres.
  static String _note(MenuWine w, bool fr) {
    final c = w.sommelierComment?.trim();
    if (c != null && c.isNotEmpty) return c;
    final m = w.metrics;
    String n(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return [
      '${trSi(fr, 'Acidité', 'Acidity')} ${n(m.acidity)}/10',
      '${trSi(fr, 'Corps', 'Body')} ${n(m.body)}/10',
      if (w.isRed) '${trSi(fr, 'Tanins', 'Tannins')} ${n(m.tannins)}/10',
      '${trSi(fr, 'Bois', 'Oak')} ${n(m.oak)}/10',
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

  /// L'ordre de service : bulles, blancs du plus vif au plus ample, rosés, rouges du plus
  /// souple au plus puissant, vins doux en dernier.
  static double _rangDeService(MenuWine w) {
    if (_isSweetOrSpirit(w)) return 5000;
    if (_isSparkling(w)) return 0;
    if (_isRose(w)) return 2000;
    if (_isWhite(w)) return 1000 + (200 - _mineralRank(w)).clamp(0, 999);
    if (_isRed(w)) return 3000 + _powerRank(w);
    return 2500;
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
  /// Le prix qui borne « pour mieux vous connaître », sur la carte comme dans le parcours :
  /// celui du verre, ou son estimation depuis la bouteille. Une ardoise n'a que des prix au
  /// verre : lue à la bouteille, elle n'avait aucun plafond, et la carte proposait le verre
  /// le plus cher quand le parcours en choisissait un autre (relevé le 02/10).
  static double? prixPourApprendre(MenuWine w) => _prixDuVerre(w).$1 ?? w.bottlePrice;

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
