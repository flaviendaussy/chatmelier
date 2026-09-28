import 'dart:math' as math;
import '../../sommelier/domain/guest_matcher_engine.dart';
import 'menu_wine.dart';

class MenuTableMatchResult {
  final MenuWine menuWine;
  final double harmonyScore; // 0 à 100%
  final String consensusRationale;
  final Map<String, double> guestScores; // guestId -> score
  final List<String> aversionAlerts;

  const MenuTableMatchResult({
    required this.menuWine,
    required this.harmonyScore,
    required this.consensusRationale,
    required this.guestScores,
    this.aversionAlerts = const [],
  });
}

class MenuTableMatcherEngine {
  /// « Rouge », « red », « Vins rouges »… face à la couleur lue par le scan.
  ///
  /// Le scan écrit `wineType` en anglais (`red`, `white`…) : l'ancien test
  /// `wineType.contains('rouge')` n'était jamais vrai, et la couleur préférée d'un convive
  /// francophone ne comptait pour rien dans le consensus.
  static bool correspondALaCouleur(MenuWine vin, String preference) {
    final p = preference.toLowerCase();
    if (p.contains('roug') || p.contains('red')) return vin.isRed;
    if (p.contains('blanc') || p.contains('white')) return vin.isWhite;
    if (p.contains('ros')) return vin.isRose;
    if (p.contains('bull') || p.contains('champ') || p.contains('spark') || p.contains('efferv')) {
      return vin.isSparkling;
    }
    return vin.wineType.toLowerCase().contains(p);
  }

  /// Calcule et classe les 3 meilleures bouteilles de la carte du restaurant pour le consensus de la table.
  static List<MenuTableMatchResult> rankTop3WinesForTable({
    required List<MenuWine> menuWines,
    required List<GuestProfile> guests,
    bool isFr = true,
  }) {
    if (menuWines.isEmpty || guests.isEmpty) return [];

    // Ceux qui n'ont rien dit de leurs goûts ne votent pas : leur prêter un palais moyen
    // tirerait la table vers des vins tièdes. S'ils sont seuls, on classe quand même.
    final votants = [for (final g in guests) if (!g.sansPreferences) g];
    final jury = votants.isEmpty ? guests : votants;

    final results = <MenuTableMatchResult>[];

    for (final wine in menuWines) {
      final guestScores = <String, double>{};
      final alerts = <String>[];
      final scoresList = <double>[];

      for (final guest in jury) {
        final score = _calculateGuestWineHarmony(wine, guest, alerts, isFr);
        guestScores[guest.id] = score;
        scoresList.add(score);
      }

      // Moyenne arithmétique
      final mean = scoresList.reduce((a, b) => a + b) / scoresList.length;

      // Variance / écart-type pour pénaliser les profils trop clivants
      double varianceSum = 0.0;
      for (final s in scoresList) {
        varianceSum += math.pow(s - mean, 2);
      }
      final variance = varianceSum / scoresList.length;
      final stdDev = math.sqrt(variance);

      // Pénalité d'aversion sévère
      final aversionPenalty = alerts.length * 18.0;

      // Score final d'harmonie collective (0 à 100)
      final consensusScore = (mean - (stdDev * 0.45) - aversionPenalty).clamp(10.0, 100.0);

      results.add(MenuTableMatchResult(
        menuWine: wine,
        harmonyScore: double.parse(consensusScore.toStringAsFixed(1)),
        // Rédigée plus bas, une fois les finalistes connus : une raison dit aussi ce qui
        // distingue un vin des autres, ce qui ne se sait qu'après le classement.
        consensusRationale: '',
        guestScores: guestScores,
        aversionAlerts: alerts,
      ));
    }

    // Tri décroissant par harmonie collective
    results.sort((a, b) => b.harmonyScore.compareTo(a.harmonyScore));

    final finalistes = results.take(3).toList();
    final raisons = RedactionDesRaisons.rediger(finalistes, guests, isFr: isFr);
    return [
      for (var i = 0; i < finalistes.length; i++)
        MenuTableMatchResult(
          menuWine: finalistes[i].menuWine,
          harmonyScore: finalistes[i].harmonyScore,
          consensusRationale: raisons[i],
          guestScores: finalistes[i].guestScores,
          aversionAlerts: finalistes[i].aversionAlerts,
        ),
    ];
  }

  static double _calculateGuestWineHarmony(
    MenuWine wine,
    GuestProfile guest,
    List<String> alerts,
    bool isFr,
  ) {
    double score = 70.0; // Base de départ

    final radar = wine.metrics;
    final guestRadar = guest.radar;

    // 1. Concordance de couleur
    if (guest.favoriteTypes.isNotEmpty) {
      final matchesFavorite = guest.favoriteTypes.any((t) => correspondALaCouleur(wine, t));
      if (matchesFavorite) {
        score += 15.0;
      }
    }

    // 2. Vérification des aversions strictes
    for (final disliked in guest.dislikedCharacteristics) {
      final dl = disliked.toLowerCase();
      if (dl.contains('tanin') || dl.contains('tannin') || dl.contains('dur')) {
        if (radar.tannins >= 7.5) {
          score -= 35.0;
          alerts.add(isFr
              ? '${guest.name} a une aversion pour les tanins durs : ce vin est très charpenté (${radar.tannins.toStringAsFixed(1)}/10).'
              : '${guest.name} dislikes firm tannins: this wine is very structured (${radar.tannins.toStringAsFixed(1)}/10).');
        }
      }
      if (dl.contains('acid') || dl.contains('acide') || dl.contains('vert')) {
        if (radar.acidity >= 8.5) {
          score -= 30.0;
          alerts.add(isFr
              ? '${guest.name} redoute la forte acidité : ce vin est très tranchant (${radar.acidity.toStringAsFixed(1)}/10).'
              : '${guest.name} avoids high acidity: this wine is very sharp (${radar.acidity.toStringAsFixed(1)}/10).');
        }
      }
      if (dl.contains('bois') || dl.contains('chêne') || dl.contains('vanill')) {
        if (radar.oak >= 7.5) {
          score -= 25.0;
          alerts.add(isFr
              ? '${guest.name} n\'apprécie pas le boisé marqué : élevage puissant (${radar.oak.toStringAsFixed(1)}/10).'
              : '${guest.name} dislikes heavy oak: strong barrel ageing (${radar.oak.toStringAsFixed(1)}/10).');
        }
      }
    }

    // 3. Proximité des axes sensoriels
    // Tannins (uniquement pour les rouges)
    if (!wine.isWhite && radar.tannins > 0.0) {
      final tanninDiff = (radar.tannins - guestRadar.tannin).abs();
      score -= (tanninDiff * 1.5);
    }

    // Corps / Puissance
    final bodyDiff = (radar.body - guestRadar.body).abs();
    score -= (bodyDiff * 1.5);

    // Vivacité / Acidité
    final acidDiff = (radar.acidity - guestRadar.acidity).abs();
    score -= (acidDiff * 1.5);

    // Fruit
    final fruitDiff = (radar.fruit - guestRadar.freshFruit).abs();
    score -= (fruitDiff * 1.0);

    // Bonus si le cépage est dans les favoris du convive
    if (wine.grapes.isNotEmpty && guest.favoriteGrapes.isNotEmpty) {
      for (final fg in guest.favoriteGrapes) {
        if (wine.grapes.any((g) => g.toLowerCase().contains(fg.toLowerCase()))) {
          score += 10.0;
          break;
        }
      }
    }

    return score.clamp(10.0, 100.0);
  }
}

/// Les raisons des finalistes, rédigées ensemble.
///
/// Caro a lu trois fois « Option intéressante de la carte… » (26/09) : trois phrases
/// fixes, choisies par tranche de score, sans un prénom ni un mot sur ce qui distingue
/// un vin des deux autres. Une raison dit maintenant pour qui (et qui risque d'être
/// déçu, et pourquoi), ce qui distingue ce vin des autres finalistes, et où il se place
/// en prix — et jamais deux fois la même phrase.
class RedactionDesRaisons {
  static List<String> rediger(
    List<MenuTableMatchResult> finalistes,
    List<GuestProfile> convives, {
    bool isFr = true,
  }) {
    final tous = [for (final f in finalistes) f.menuWine];
    final raisons = <String>[];
    for (var i = 0; i < finalistes.length; i++) {
      final r = finalistes[i];
      final autres = [for (var j = 0; j < tous.length; j++) if (j != i) tous[j]];
      var distinction = ceQuiLeDistingue(r.menuWine, autres, isFr);
      // Le premier sans trait saillant est premier pour une raison : l'équilibre.
      if (distinction.isEmpty && i == 0 && convives.length > 1) {
        distinction = isFr ? 'le meilleur compromis de la table' : 'the best compromise for the table';
      }
      final prix = placeEnPrix(r.menuWine, tous, isFr);

      final seconde = [
        if (distinction.isNotEmpty) distinction,
        if (prix.isNotEmpty) prix,
      ].join(', ');
      var raison = _pourQui(r, convives, isFr);
      if (seconde.isNotEmpty) raison = '$raison. ${_majuscule(seconde)}.';
      if (r.aversionAlerts.isNotEmpty) {
        raison = '$raison ${isFr ? 'Attention' : 'Heads-up'} : ${r.aversionAlerts.first}';
      }
      // Jamais deux fois la même phrase : le nom du vin tranche.
      if (raisons.contains(raison)) {
        final v = r.menuWine;
        raison = '$raison (${v.name}${v.vintage != null ? ' ${v.vintage}' : ''})';
      }
      raisons.add(raison);
    }
    return raisons;
  }

  static String _majuscule(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _liste(List<String> noms, bool fr) {
    if (noms.length <= 1) return noms.join();
    return '${noms.sublist(0, noms.length - 1).join(', ')} ${fr ? 'et' : 'and'} ${noms.last}';
  }

  /// Qui l'aimera, qui l'appréciera, et qui risque d'être déçu — avec la raison.
  static String _pourQui(MenuTableMatchResult r, List<GuestProfile> convives, bool fr) {
    if (convives.isEmpty) return fr ? 'Un vin pour la table' : 'A wine for the table';
    // Seuls ceux qui ont voté sont cités : un convive « juste son prénom » n'a pas
    // d'avis, il n'est ni fan ni réticent.
    final notes = [
      for (final g in convives)
        if (r.guestScores.containsKey(g.id)) (g, r.guestScores[g.id]!)
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (notes.isEmpty) return fr ? 'Un vin pour la table' : 'A wine for the table';

    if (convives.length == 1) {
      final s = notes.first.$2;
      if (s >= 85) return fr ? 'Taillé pour vos goûts' : 'Made for your taste';
      if (s >= 65) return fr ? 'Dans vos goûts' : 'Close to your taste';
      return fr ? 'Un pas de côté par rapport à vos goûts' : 'A step away from your usual taste';
    }

    final fans = [for (final n in notes) if (n.$2 >= 85) n.$1.name];
    final contents = [for (final n in notes) if (n.$2 >= 65 && n.$2 < 85) n.$1.name];
    final tiedes = [for (final n in notes) if (n.$2 >= 55 && n.$2 < 65) n.$1.name];
    final reticents = [for (final n in notes) if (n.$2 < 55) n.$1];
    final parts = <String>[
      if (fans.isNotEmpty)
        fr
            ? '${_liste(fans, fr)} ${fans.length > 1 ? 'vont l\'adorer' : 'va l\'adorer'}'
            : '${_liste(fans, fr)} will love it',
      if (contents.isNotEmpty)
        fr
            ? '${_liste(contents, fr)} ${contents.length > 1 ? 'l\'apprécieront' : 'l\'appréciera'}'
            : '${_liste(contents, fr)} will enjoy it',
      if (tiedes.isNotEmpty)
        fr
            ? '${_liste(tiedes, fr)} ${tiedes.length > 1 ? 's\'en accommoderont' : 's\'en accommodera'}'
            : '${_liste(tiedes, fr)} will be fine with it',
      for (final g in reticents.take(2))
        fr ? '${g.name} le trouvera ${_ecart(r.menuWine, g, fr)}' : '${g.name} may find it ${_ecart(r.menuWine, g, fr)}',
    ];
    if (parts.isEmpty) return fr ? 'Un compromis pour toute la table' : 'A compromise for the whole table';
    return parts.join(fr ? ' ; ' : '; ');
  }

  /// L'axe sur lequel ce vin s'éloigne le plus du palais de ce convive.
  static String _ecart(MenuWine vin, GuestProfile g, bool fr) {
    final m = vin.metrics;
    final p = g.radar;
    final ecarts = <(double, String, String)>[
      if (vin.isRed)
        (m.tannins - p.tannin, fr ? 'un peu tannique' : 'a little tannic', fr ? 'trop souple' : 'too soft'),
      (m.body - p.body, fr ? 'un peu puissant' : 'a little powerful', fr ? 'un peu léger' : 'a little light'),
      (m.acidity - p.acidity, fr ? 'un peu vif' : 'a little sharp', fr ? 'un peu mou' : 'a little flat'),
      (m.oak - p.oak, fr ? 'un peu boisé' : 'a little oaky', fr ? 'un peu simple' : 'a little plain'),
    ];
    ecarts.sort((a, b) => b.$1.abs().compareTo(a.$1.abs()));
    final e = ecarts.first;
    return e.$1 >= 0 ? e.$2 : e.$3;
  }

  /// Ce qui distingue ce vin des autres finalistes : sa couleur s'il est seul de sa
  /// couleur, sinon l'axe sur lequel il est le plus à l'écart — à condition d'en être
  /// l'extrême, sans quoi « le plus frais des trois » serait faux.
  static String ceQuiLeDistingue(MenuWine vin, List<MenuWine> autres, bool fr) {
    if (autres.isEmpty) return '';
    final lot = fr ? (autres.length == 1 ? 'des deux' : 'des trois') : (autres.length == 1 ? 'of the two' : 'of the three');

    String couleur(MenuWine w) => w.isSparkling
        ? (fr ? 'effervescent' : 'sparkling wine')
        : w.isRose
            ? (fr ? 'rosé' : 'rosé')
            : w.isWhite
                ? (fr ? 'blanc' : 'white')
                : w.isRed
                    ? (fr ? 'rouge' : 'red')
                    : '';
    final c = couleur(vin);
    if (c.isNotEmpty && autres.every((a) => couleur(a).isNotEmpty && couleur(a) != c)) {
      return fr ? 'le seul $c $lot' : 'the only $c $lot';
    }

    final axes = <(double Function(MenuWine), String, String, String, String)>[
      if (vin.isRed && autres.every((a) => a.isRed))
        ((w) => w.metrics.tannins, 'le plus charpenté', 'le plus souple', 'the most structured', 'the silkiest'),
      ((w) => w.metrics.acidity, 'le plus frais', 'le plus rond', 'the freshest', 'the roundest'),
      ((w) => w.metrics.body, 'le plus ample', 'le plus léger', 'the fullest', 'the lightest'),
      ((w) => w.metrics.fruit, 'le plus fruité', 'le moins fruité', 'the fruitiest', 'the least fruity'),
      ((w) => w.metrics.oak, 'le plus boisé', 'le moins boisé', 'the oakiest', 'the least oaky'),
      ((w) => w.metrics.minerality, 'le plus minéral', 'le moins minéral', 'the most mineral', 'the least mineral'),
      ((w) => w.metrics.sweetness, 'le plus doux', 'le plus sec', 'the sweetest', 'the driest'),
    ];

    (double, String)? meilleur;
    for (final (valeur, plusFr, moinsFr, plusEn, moinsEn) in axes) {
      final v = valeur(vin);
      final vals = autres.map(valeur).toList();
      final moyenne = vals.reduce((a, b) => a + b) / vals.length;
      final ecart = v - moyenne;
      final estMax = vals.every((o) => v > o);
      final estMin = vals.every((o) => v < o);
      if (ecart.abs() < 1.0 || !(estMax || estMin)) continue;
      String phrase = estMax ? (fr ? plusFr : plusEn) : (fr ? moinsFr : moinsEn);
      // Le seul sans bois se dit tel quel.
      if (!estMax && identical(valeur, axes[axes.length - 3].$1) && v <= 2.0) {
        phrase = fr ? 'le seul sans bois' : 'the only unoaked one';
      }
      if (meilleur == null || ecart.abs() > meilleur.$1) meilleur = (ecart.abs(), phrase);
    }
    if (meilleur == null) return '';
    return '${meilleur.$2} $lot';
  }

  /// Où il se place en prix parmi les finalistes.
  static String placeEnPrix(MenuWine vin, List<MenuWine> tous, bool fr) {
    final p = vin.bottlePrice;
    if (p == null) return '';
    final affiche = vin.formaterPrix(p);
    final prix = tous.map((w) => w.bottlePrice).whereType<double>().toList();
    if (prix.length == tous.length && prix.length > 1) {
      final min = prix.reduce((a, b) => a < b ? a : b);
      final max = prix.reduce((a, b) => a > b ? a : b);
      if (min < max && p == min) return fr ? 'le moins cher ($affiche)' : 'the cheapest ($affiche)';
      if (min < max && p == max) return fr ? 'le plus cher ($affiche)' : 'the priciest ($affiche)';
    }
    return fr ? 'à $affiche' : 'at $affiche';
  }
}
