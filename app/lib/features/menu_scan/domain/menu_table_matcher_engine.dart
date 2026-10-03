import 'dart:math' as math;
import '../../sommelier/domain/guest_matcher_engine.dart';
import 'menu_wine.dart';
import 'table_matchmaker.dart';
import '../../../shared/utils/langue.dart';

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

  /// Toute la carte, classée pour la table (sans les raisons, rédigées pour le podium).
  static List<MenuTableMatchResult> classerLaCarte({
    required List<MenuWine> menuWines,
    required List<GuestProfile> guests,
    bool isFr = true,
  }) {
    if (menuWines.isEmpty || guests.isEmpty) return [];

    // Qui ne boit pas ce soir est à table, sans vin à choisir : il ne vote pas (E3).
    final buveurs = [for (final g in guests) if (!g.neBoitPas) g];
    // Ceux qui n'ont rien dit de leurs goûts ne votent pas : leur prêter un palais moyen
    // tirerait la table vers des vins tièdes. S'ils sont seuls, on classe quand même. Un
    // avis donné au matchmaker de table, lui, fait voter.
    final votants = [for (final g in buveurs) if (!g.sansPreferences || g.avis.isNotEmpty) g];
    final jury = votants.isNotEmpty ? votants : (buveurs.isNotEmpty ? buveurs : guests);

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
    return results;
  }

  /// Les trois meilleures bouteilles pour la table, avec leurs raisons.
  ///
  /// [idLecteur] : le convive qui lit l'écran. Seul à table, c'est à lui qu'on parle
  /// (« dans vos goûts ») ; si le seul convive est quelqu'un d'autre — l'hôte, vu par un
  /// invité qui ne s'est pas encore assis — on le nomme. Nul : on parle au convive seul.
  static List<MenuTableMatchResult> rankTop3WinesForTable({
    required List<MenuWine> menuWines,
    required List<GuestProfile> guests,
    bool isFr = true,
    String? idLecteur,
  }) {
    final finalistes = classerLaCarte(menuWines: menuWines, guests: guests, isFr: isFr).take(3).toList();
    final raisons = RedactionDesRaisons.rediger(finalistes, guests, isFr: isFr, idLecteur: idLecteur);
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

  /// Le score à partir duquel un vin plaît à un convive : « l'appréciera » dans les raisons
  /// (65). À 60, un amateur de grands rouges comptait pour satisfait d'un Grüner Veltliner
  /// qu'il ne ferait que supporter (« s'en accommodera »), et la table ne voyait jamais
  /// qu'une seule bouteille la laissait à moitié contente (rejeu du 01/10).
  static const double seuilDeCouverture = 65;

  /// Combien de buveurs ce vin satisfait.
  static int couverture(MenuTableMatchResult r) =>
      r.guestScores.values.where((s) => s >= seuilDeCouverture).length;

  /// Deux bouteilles quand une seule laisse trop de monde de côté (V2.3 · E4).
  ///
  /// Le meilleur vin seul doit satisfaire moins de 70 % des buveurs, et la paire au moins
  /// deux buveurs de plus : sinon une bouteille suffit, et la paire est nulle. Parmi les
  /// [candidats] premiers du classement, la paire qui satisfait le plus de buveurs, puis
  /// la plus haute somme des meilleurs scores de chacun.
  static PaireDeBouteilles? meilleurePaire(List<MenuTableMatchResult> classement, {int candidats = 12}) {
    if (classement.length < 2) return null;
    final premier = classement.first;
    final buveurs = premier.guestScores.keys.toList();
    final seul = couverture(premier);
    if (buveurs.length < 3 || seul >= 0.7 * buveurs.length) return null;

    final lot = classement.take(candidats).toList();
    PaireDeBouteilles? meilleure;
    var meilleureSomme = -1.0;
    for (var i = 0; i < lot.length; i++) {
      for (var j = i + 1; j < lot.length; j++) {
        var couverts = 0;
        var somme = 0.0;
        for (final id in buveurs) {
          final s = math.max(lot[i].guestScores[id] ?? 0, lot[j].guestScores[id] ?? 0);
          somme += s;
          if (s >= seuilDeCouverture) couverts++;
        }
        if (meilleure == null ||
            couverts > meilleure.couverts ||
            (couverts == meilleure.couverts && somme > meilleureSomme)) {
          meilleure = PaireDeBouteilles(lot[i], lot[j],
              couverts: couverts, couvertsParLePremier: seul, buveurs: buveurs.length);
          meilleureSomme = somme;
        }
      }
    }
    if (meilleure == null || meilleure.couverts < seul + 2) return null;
    return meilleure;
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
          alerts.add(trSi(isFr, '{guest_name} a une aversion pour les tanins durs : ce vin est très charpenté ({v1}/10).', '{guest_name} dislikes firm tannins: this wine is very structured ({v1}/10).', {'guest_name': guest.name, 'v1': radar.tannins.toStringAsFixed(1)}));
        }
      }
      if (dl.contains('acid') || dl.contains('acide') || dl.contains('vert')) {
        if (radar.acidity >= 8.5) {
          score -= 30.0;
          alerts.add(trSi(isFr, '{guest_name} redoute la forte acidité : ce vin est très tranchant ({v1}/10).', '{guest_name} avoids high acidity: this wine is very sharp ({v1}/10).', {'guest_name': guest.name, 'v1': radar.acidity.toStringAsFixed(1)}));
        }
      }
      if (dl.contains('bois') || dl.contains('chêne') || dl.contains('vanill')) {
        if (radar.oak >= 7.5) {
          score -= 25.0;
          alerts.add(trSi(isFr, '{guest_name} n\'apprécie pas le boisé marqué : élevage puissant ({v1}/10).', '{guest_name} dislikes heavy oak: strong barrel ageing ({v1}/10).', {'guest_name': guest.name, 'v1': radar.oak.toStringAsFixed(1)}));
        }
      }
    }

    // 3. Proximité des axes sensoriels. Chaque écart pèse selon ce qu'on sait de l'axe :
    // plein s'il est observé ou déclaré ; deviné, il tranche moins sans flatter (V2.3 · K1, K5).
    double ecart(double vin, double convive, String axe, double facteur) =>
        facteur * guest.ecartSurLAxe(axe, vin - convive);

    // Les tanins jugent les rouges ; la minéralité, les blancs, les rosés et les bulles.
    if (!wine.isWhite && radar.tannins > 0.0) {
      score -= ecart(radar.tannins, guestRadar.tannin, 'tannin', 1.5);
    }
    if (!wine.isRed) {
      score -= ecart(radar.minerality, guestRadar.minerality, 'minerality', 1.0);
    }

    // Corps / Puissance
    score -= ecart(radar.body, guestRadar.body, 'body', 1.5);

    // Vivacité / Acidité
    score -= ecart(radar.acidity, guestRadar.acidity, 'acidity', 1.5);

    // Fruit
    score -= ecart(radar.fruit, guestRadar.freshFruit, 'freshFruit', 1.0);

    // Bois : il se goûte dans toutes les couleurs.
    score -= ecart(radar.oak, guestRadar.oak, 'oak', 1.0);

    // Bonus si le cépage est dans les favoris du convive
    if (wine.grapes.isNotEmpty && guest.favoriteGrapes.isNotEmpty) {
      for (final fg in guest.favoriteGrapes) {
        if (wine.grapes.any((g) => g.toLowerCase().contains(fg.toLowerCase()))) {
          score += 10.0;
          break;
        }
      }
    }

    // Son avis au matchmaker de table pèse plus que ce que le moteur devine.
    final avis = AvisDeTable.depuis(guest.avis[wine.cacheKey]);
    return TableMatchmaker.avecAvis(score.clamp(10.0, 100.0), avis).clamp(10.0, 100.0);
  }
}

/// Deux bouteilles pour la table, et ce qu'elles couvrent ensemble (V2.3 · E4).
class PaireDeBouteilles {
  final MenuTableMatchResult premiere;
  final MenuTableMatchResult seconde;

  /// Les buveurs à qui l'une des deux plaît.
  final int couverts;

  /// Ceux que le meilleur vin seul aurait satisfaits.
  final int couvertsParLePremier;

  final int buveurs;

  const PaireDeBouteilles(
    this.premiere,
    this.seconde, {
    required this.couverts,
    required this.couvertsParLePremier,
    required this.buveurs,
  });

  /// Un blanc (ou des bulles) et un rouge : l'un pour l'entrée, l'autre pour le plat.
  bool get entreeEtPlat => (_clair(premiere.menuWine) && seconde.menuWine.isRed) ||
      (_clair(seconde.menuWine) && premiere.menuWine.isRed);

  /// Dans l'ordre du repas : le blanc ou les bulles d'abord.
  (MenuWine, MenuWine) get dansLOrdre => _clair(seconde.menuWine) && premiere.menuWine.isRed
      ? (seconde.menuWine, premiere.menuWine)
      : (premiere.menuWine, seconde.menuWine);

  static bool _clair(MenuWine w) => w.isSparkling || (w.isWhite && !w.isRed && !w.isRose);
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
    String? idLecteur,
  }) {
    final tous = [for (final f in finalistes) f.menuWine];
    final raisons = <String>[];
    for (var i = 0; i < finalistes.length; i++) {
      final r = finalistes[i];
      final autres = [for (var j = 0; j < tous.length; j++) if (j != i) tous[j]];
      var distinction = ceQuiLeDistingue(r.menuWine, autres, isFr);
      // Le premier sans trait saillant est premier pour une raison : l'équilibre.
      if (distinction.isEmpty && i == 0 && convives.length > 1) {
        distinction = trSi(isFr, 'le meilleur compromis de la table', 'the best compromise for the table');
      }
      final prix = placeEnPrix(r.menuWine, tous, isFr);

      final seconde = [
        if (distinction.isNotEmpty) distinction,
        if (prix.isNotEmpty) prix,
      ].join(', ');
      var raison = _majuscule(_pourQui(r, convives, isFr, idLecteur));
      if (seconde.isNotEmpty) raison = '$raison. ${_majuscule(seconde)}.';
      if (r.aversionAlerts.isNotEmpty) {
        raison = '$raison ${trSi(isFr, 'Attention', 'Heads-up')} : ${r.aversionAlerts.first}';
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

  /// « Le Sancerre pour l'entrée, le Morgon pour le plat : 6 convives sur 7 y trouvent leur
  /// compte, contre 3 avec une seule bouteille. »
  static String phraseDeLaPaire(PaireDeBouteilles p, {bool isFr = true}) {
    String nom(MenuWine w) => '${w.name}${w.vintage != null ? ' ${w.vintage}' : ''}';
    final (a, b) = p.dansLOrdre;
    final valeurs = {
      'v1': nom(a),
      'v2': nom(b),
      'n': p.couverts,
      'm': p.buveurs,
      'k': p.couvertsParLePremier,
    };
    return p.entreeEtPlat
        ? trSi(isFr, '{v1} pour l\'entrée, {v2} pour le plat : {n} convives sur {m} y trouvent leur compte, contre {k} avec une seule bouteille.',
            '{v1} with the starter, {v2} with the main: {n} of {m} guests are happy, against {k} with a single bottle.', valeurs)
        : trSi(isFr, '{v1} et {v2} : {n} convives sur {m} y trouvent leur compte, contre {k} avec une seule bouteille.',
            '{v1} and {v2}: {n} of {m} guests are happy, against {k} with a single bottle.', valeurs);
  }

  static String _liste(List<String> noms, bool fr) {
    if (noms.length <= 1) return noms.join();
    return '${noms.sublist(0, noms.length - 1).join(', ')} ${trSi(fr, 'et', 'and')} ${noms.last}';
  }

  /// Qui l'aimera, qui l'appréciera, et qui risque d'être déçu — avec la raison.
  static String _pourQui(MenuTableMatchResult r, List<GuestProfile> convives, bool fr, String? idLecteur) {
    if (convives.isEmpty) return trSi(fr, 'Un vin pour la table', 'A wine for the table');
    // Seuls ceux qui ont voté sont cités : un convive « juste son prénom » n'a pas
    // d'avis, il n'est ni fan ni réticent.
    final notes = [
      for (final g in convives)
        if (r.guestScores.containsKey(g.id)) (g, r.guestScores[g.id]!)
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (notes.isEmpty) return trSi(fr, 'Un vin pour la table', 'A wine for the table');

    // « Vos goûts » seulement si c'est à ce convive qu'on parle : l'invité qui arrive à
    // une table où l'hôte est seul lisait « Dans vos goûts » des goûts de l'hôte (29/09).
    // Sinon, la phrase nominative ci-dessous : « Flavien l'appréciera ».
    if (convives.length == 1 && (idLecteur == null || convives.single.id == idLecteur)) {
      final s = notes.first.$2;
      if (s >= 85) return trSi(fr, 'Taillé pour vos goûts', 'Made for your taste');
      if (s >= 65) return trSi(fr, 'Dans vos goûts', 'Close to your taste');
      return trSi(fr, 'Un pas de côté par rapport à vos goûts', 'A step away from your usual taste');
    }

    // Celui qui lit se lit « vous », en dernier : « Caro et vous l'apprécierez ». L'hôte,
    // qui s'appelle « Moi » sur son téléphone, lisait « Test Claude et Moi l'apprécieront »
    // (29/09). Le verbe s'accorde avec « vous » dès qu'il en fait partie.
    bool estLecteur(GuestProfile g) => idLecteur != null && g.id == idLecteur;
    (List<String>, bool) groupe(bool Function(double) dedans) {
      final autres = [for (final n in notes) if (dedans(n.$2) && !estLecteur(n.$1)) n.$1.name];
      final lecteur = notes.any((n) => dedans(n.$2) && estLecteur(n.$1));
      return ([...autres, if (lecteur) trSi(fr, 'vous', 'you')], lecteur);
    }

    String verbe((List<String>, bool) g, FormesDuVerbe formes) =>
        '${_liste(g.$1, fr)} ${formes.pour(fr: fr, lecteur: g.$2, plusieurs: g.$1.length > 1)}';
    final fans = groupe((s) => s >= 85);
    final contents = groupe((s) => s >= 65 && s < 85);
    final tiedes = groupe((s) => s >= 55 && s < 65);
    final reticents = [for (final n in notes) if (n.$2 < 55) n.$1];
    final parts = <String>[
      if (fans.$1.isNotEmpty) verbe(fans, FormesDuVerbe.adorer),
      if (contents.$1.isNotEmpty) verbe(contents, FormesDuVerbe.apprecier),
      if (tiedes.$1.isNotEmpty) verbe(tiedes, FormesDuVerbe.sAccommoder),
      for (final g in reticents.take(2))
        estLecteur(g)
            ? (trSi(fr, 'vous le trouverez {v1}', 'you may find it {v1}', {'v1': _ecart(r.menuWine, g, fr)}))
            : (trSi(fr, '{g_name} le trouvera {v1}', '{g_name} may find it {v1}', {'g_name': g.name, 'v1': _ecart(r.menuWine, g, fr)})),
    ];
    if (parts.isEmpty) return trSi(fr, 'Un compromis pour toute la table', 'A compromise for the whole table');
    return parts.join(trSi(fr, ' ; ', '; '));
  }

  /// L'axe sur lequel ce vin s'éloigne le plus du palais de ce convive.
  static String _ecart(MenuWine vin, GuestProfile g, bool fr) {
    final m = vin.metrics;
    final p = g.radar;
    final ecarts = <(double, String, String)>[
      if (vin.isRed)
        (m.tannins - p.tannin, trSi(fr, 'un peu tannique', 'a little tannic'), trSi(fr, 'trop souple', 'too soft')),
      (m.body - p.body, trSi(fr, 'un peu puissant', 'a little powerful'), trSi(fr, 'un peu léger', 'a little light')),
      (m.acidity - p.acidity, trSi(fr, 'un peu vif', 'a little sharp'), trSi(fr, 'un peu mou', 'a little flat')),
      (m.oak - p.oak, trSi(fr, 'un peu boisé', 'a little oaky'), trSi(fr, 'un peu simple', 'a little plain')),
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
    final lot = autres.length == 1 ? trSi(fr, 'des deux', 'of the two') : trSi(fr, 'des trois', 'of the three');

    String couleur(MenuWine w) => w.isSparkling
        ? (trSi(fr, 'effervescent', 'sparkling wine'))
        : w.isRose
            ? (trSi(fr, 'rosé', 'rosé'))
            : w.isWhite
                ? (trSi(fr, 'blanc', 'white'))
                : w.isRed
                    ? (trSi(fr, 'rouge', 'red'))
                    : '';
    final c = couleur(vin);
    if (c.isNotEmpty && autres.every((a) => couleur(a).isNotEmpty && couleur(a) != c)) {
      return trSi(fr, 'le seul {c} {lot}', 'the only {c} {lot}', {'c': c, 'lot': lot});
    }

    // Chaque axe ne se compare que là où il a un sens en dégustation, et seulement dans
    // le sens qui dit quelque chose d'utile. « Le moins minéral » d'un rouge ne veut rien
    // dire (retour du 29/09) : la minéralité se dit des blancs et des bulles — Chablis,
    // Sancerre, craie de Champagne. « Le plus doux » d'un vin sec serait faux, « le moins
    // fruité » n'aide personne à choisir.
    final tous = [vin, ...autres];
    bool blancOuBulles(MenuWine w) => w.isSparkling || (w.isWhite && !w.isRose && !w.isRed);
    // Un superlatif doit aussi être vrai dans l'absolu : un Chablis à 3/10 de bois n'est
    // pas « le plus boisé » parce que les deux autres en ont moins (consensus du 29/09,
    // lu par un convive qui fuit le bois). D'où un seuil par trait.
    bool auMoins(double v, List<double> _, double seuil) => v >= seuil;
    bool auPlus(double v, List<double> _, double seuil) => v <= seuil;
    final axes = <_Axe>[
      if (tous.every((w) => w.isRed))
        _Axe((w) => w.metrics.tannins,
            plus: Phrase('le plus charpenté', 'the most structured'),
            moins: Phrase('le plus souple', 'the silkiest'),
            plusSi: (v, a) => auMoins(v, a, 6),
            moinsSi: (v, a) => auPlus(v, a, 5)),
      _Axe((w) => w.metrics.acidity,
          plus: Phrase('le plus frais', 'the freshest'),
          moins: Phrase('le plus rond', 'the roundest'),
          plusSi: (v, a) => auMoins(v, a, 6),
          moinsSi: (v, a) => auPlus(v, a, 5)),
      _Axe((w) => w.metrics.body,
          plus: Phrase('le plus ample', 'the fullest'),
          moins: Phrase('le plus léger', 'the lightest'),
          plusSi: (v, a) => auMoins(v, a, 6),
          moinsSi: (v, a) => auPlus(v, a, 5)),
      _Axe((w) => w.metrics.fruit, plus: Phrase('le plus fruité', 'the fruitiest'), plusSi: (v, a) => auMoins(v, a, 6)),
      _Axe((w) => w.metrics.oak,
          plus: Phrase('le plus boisé', 'the oakiest'),
          moins: Phrase('le moins boisé', 'the least oaky'),
          plusSi: (v, a) => auMoins(v, a, 5),
          moinsSi: (v, a) => auPlus(v, a, 3),
          sansBois: true),
      if (tous.every(blancOuBulles))
        _Axe((w) => w.metrics.minerality, plus: Phrase('le plus minéral', 'the most mineral'), plusSi: (v, a) => auMoins(v, a, 6)),
      // Doux : seulement un vin qui l'est (demi-sec et au-delà) ; sec : seulement face à
      // des vins qui ne le sont pas.
      _Axe((w) => w.metrics.sweetness,
          plus: Phrase('le plus doux', 'the sweetest'),
          moins: Phrase('le seul sec', 'the only dry one'),
          plusSi: (v, _) => v >= 4,
          moinsSi: (_, autres) => autres.every((o) => o >= 3)),
    ];

    (double, String)? meilleur;
    for (final axe in axes) {
      final v = axe.valeur(vin);
      final vals = autres.map(axe.valeur).toList();
      final moyenne = vals.reduce((a, b) => a + b) / vals.length;
      final ecart = v - moyenne;
      final estMax = vals.every((o) => v > o);
      final estMin = vals.every((o) => v < o);
      if (ecart.abs() < 1.0) continue;
      final Phrase? libelle;
      if (estMax && axe.plus != null && axe.plusSi(v, vals)) {
        libelle = axe.plus;
      } else if (estMin && axe.moins != null && axe.moinsSi(v, vals)) {
        // Le seul sans bois se dit tel quel.
        libelle = axe.sansBois && v <= 2.0 ? const Phrase('le seul sans bois', 'the only unoaked one') : axe.moins;
      } else {
        continue;
      }
      final phrase = libelle!.dans(fr);
      if (meilleur == null || ecart.abs() > meilleur.$1) meilleur = (ecart.abs(), phrase);
    }
    if (meilleur == null) return '';
    // « Le seul sec » porte déjà sa comparaison : pas de « des trois » derrière.
    return meilleur.$2.startsWith(trSi(fr, 'le seul', 'the only')) ? meilleur.$2 : '${meilleur.$2} $lot';
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
      if (min < max && p == min) return trSi(fr, 'le moins cher ({affiche})', 'the cheapest ({affiche})', {'affiche': affiche});
      if (min < max && p == max) return trSi(fr, 'le plus cher ({affiche})', 'the priciest ({affiche})', {'affiche': affiche});
    }
    return trSi(fr, 'à {affiche}', 'at {affiche}', {'affiche': affiche});
  }
}

/// Un axe de comparaison entre finalistes, et ce qu'on a le droit d'en dire.
class _Axe {
  final double Function(MenuWine) valeur;

  /// Le libellé (fr, en) de l'extrême haut, ou nul s'il ne dit rien d'utile.
  final Phrase? plus;

  /// Le libellé (fr, en) de l'extrême bas, ou nul.
  final Phrase? moins;

  /// Conditions supplémentaires : la valeur du vin, celles des autres finalistes.
  final bool Function(double, List<double>) plusSi;
  final bool Function(double, List<double>) moinsSi;

  /// « Le seul sans bois » plutôt que « le moins boisé » quand il n'en a pas.
  final bool sansBois;

  const _Axe(
    this.valeur, {
    this.plus,
    this.moins,
    this.plusSi = _toujours,
    this.moinsSi = _toujours,
    this.sansBois = false,
  });

  static bool _toujours(double _, List<double> __) => true;
}
