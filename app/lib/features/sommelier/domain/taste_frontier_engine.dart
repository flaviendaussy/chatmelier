import '../../auth/domain/taste_profile.dart';
import '../../cellar/domain/wine.dart';
import '../../menu_scan/domain/cellar_bridge.dart';
import '../../menu_scan/domain/menu_wine.dart';
import '../../../shared/utils/langue.dart';

/// Le moteur de frontière (plan V2, S4) : quelle bouteille apprendrait le plus sur un
/// palais, sans faire boire à personne un vin qu'il détesterait.
///
/// Le radar dit ce qu'il ignore (observé / deviné) ; ce moteur dit **comment l'apprendre**.
/// Pour un vin candidat :
///
///   gain = Σ sur les axes plausibles (1 − confiance de l'axe) × netteté du vin sur l'axe
///
/// La netteté mesure à quel point le vin « montre » l'axe : un vin moyen (5/10) ne dit
/// rien de ce qu'on pense du boisé, un vin à 9 ou à 1 tranche. Un axe déjà observé
/// (confiance ≥ 0,5, soit cinq dégustations) ne rapporte presque plus rien.
///
/// Cinq axes seulement, ceux qu'un vin permet de juger : tanins (rouges), corps, boisé,
/// vivacité, minéralité (blancs et bulles). Le fruit se partage mal entre « mûr » et
/// « frais », les épices n'ont pas de mesure : on se tait plutôt que d'inventer.
class TasteFrontierEngine {
  /// À partir de là, un axe est observé : il ne motive plus de suggestion.
  static const double seuilObserve = 0.5;

  /// Plaisir prédit minimal (score de 0 à 100) pour proposer un vin.
  static const double plaisirMinimal = 60;

  /// En dessous, le vin n'apprendrait rien qui vaille une bouteille.
  static const double gainMinimal = 0.35;

  /// La présence d'un trait renseigne plus que son absence : aimer un vin sans bois ne
  /// dit pas qu'on fuit le bois, aimer un vin très boisé dit qu'on le supporte. Le côté
  /// bas compte donc pour moitié.
  static double nettete(double v) =>
      (v >= 5 ? (v - 5) / 5 : 0.5 * (5 - v) / 5).clamp(0.0, 1.0);

  /// Le gain d'un vin pour un profil, et l'axe qui y pèse le plus.
  static (double, String)? evaluer(ProfilDeVin vin, TasteProfile profil) {
    var total = 0.0;
    String? meilleurAxe;
    var meilleur = 0.0;
    for (final e in vin.axes.entries) {
      final confiance = profil.axisConfidence(e.key);
      final part = (1 - confiance) * nettete(e.value);
      total += part;
      if (part > meilleur) {
        meilleur = part;
        meilleurAxe = e.key;
      }
    }
    if (meilleurAxe == null) return null;
    return (total, meilleurAxe);
  }

  /// Le candidat qui apprendrait le plus, ou rien si aucun ne vaut une bouteille.
  ///
  /// [plaisir] : score prédit (0–100) du candidat, ou nul s'il est inconnu — seules les
  /// aversions déclarées filtrent alors.
  ///
  /// [prix] : pour apprendre, une bouteille du milieu de la carte au plus (prix médian,
  /// dès quatre prix connus), puis, à gain presque égal (au moins [partDuMeilleurGain] du
  /// meilleur), la moins chère. Le gain additionne les axes : les grands crus, marqués sur
  /// tout à la fois (tanins, corps, bois), passaient donc devant. Sur une carte écossaise,
  /// le moteur envoyait apprendre « ce que vous pensez des vins corsés » avec le Léoville
  /// Las Cases 2012 à 420 £ (01/10).
  static SuggestionDeFrontiere<T>? choisir<T>(
    List<T> candidats,
    TasteProfile profil, {
    required ProfilDeVin Function(T) profilDe,
    double? Function(T)? plaisir,
    double? Function(T)? prix,
  }) {
    final retenus = <(SuggestionDeFrontiere<T>, double?)>[];
    for (final c in candidats) {
      final p = profilDe(c);
      final r = evaluer(p, profil);
      if (r == null) continue;
      final (gain, axe) = r;
      if (gain < gainMinimal) continue;
      if (profil.axisConfidence(axe) >= seuilObserve) continue;
      final score = plaisir?.call(c);
      if (score != null && score < plaisirMinimal) continue;
      if (_heurteUneAversion(p, profil)) continue;
      retenus.add((SuggestionDeFrontiere(c, axe, gain, score, p.axes[axe]!), prix?.call(c)));
    }
    if (retenus.isEmpty) return null;

    final prixConnus = [
      for (final c in candidats)
        if (prix?.call(c) case final p?) p,
    ]..sort();
    final plafond = prixConnus.length >= 4 ? prixConnus[(prixConnus.length - 1) ~/ 2] : null;
    final abordables =
        plafond == null ? retenus : [for (final r in retenus) if (r.$2 == null || r.$2! <= plafond) r];
    final parmi = abordables.isNotEmpty ? abordables : retenus;

    var meilleurGain = 0.0;
    for (final r in parmi) {
      if (r.$1.gain > meilleurGain) meilleurGain = r.$1.gain;
    }
    final proches = parmi.where((r) => r.$1.gain >= meilleurGain * partDuMeilleurGain).toList()
      ..sort((a, b) {
        final pa = a.$2;
        final pb = b.$2;
        if (pa != null && pb != null && pa != pb) return pa.compareTo(pb);
        if (pa != null && pb == null) return -1;
        if (pa == null && pb != null) return 1;
        return b.$1.gain.compareTo(a.$1.gain);
      });
    // Sans prix connu, l'ordre est celui du gain : le plus instructif d'abord.
    return proches.any((r) => r.$2 != null) ? proches.first.$1 : _plusInstructif(retenus);
  }

  /// Les vins de la carte qui peuvent apprendre quelque chose au restaurant : ni ceux
  /// qu'on a déjà goûtés (le palais les connaît), ni ceux qu'on a en cave (ils s'ouvrent à
  /// la maison, au prix payé, pas à celui de la carte).
  static List<MenuWine> candidatsDeLaCarte(List<MenuWine> carte) => [
        for (final w in carte)
          if (w.pontDeCave?.type != TypeDeLien.enCave && w.pontDeCave?.type != TypeDeLien.dejaGoute) w,
      ];

  /// La part du meilleur gain en deçà de laquelle un vin moins cher n'est plus proposé.
  static const double partDuMeilleurGain = 0.85;

  static SuggestionDeFrontiere<T> _plusInstructif<T>(List<(SuggestionDeFrontiere<T>, double?)> retenus) {
    var meilleur = retenus.first.$1;
    for (final r in retenus) {
      if (r.$1.gain > meilleur.gain) meilleur = r.$1;
    }
    return meilleur;
  }

  /// On ne propose pas un vin très marqué sur ce que la personne a dit ne pas aimer.
  static bool heurteUneAversion(ProfilDeVin vin, TasteProfile profil) => _heurteUneAversion(vin, profil);

  static bool _heurteUneAversion(ProfilDeVin vin, TasteProfile profil) {
    for (final a in profil.dislikedCharacteristics) {
      final d = a.toLowerCase();
      if ((d.contains('tann') || d.contains('tanin')) && (vin.axes['tannin'] ?? 0) >= 6.5) return true;
      if ((d.contains('bois') || d.contains('oak') || d.contains('chêne')) && (vin.axes['oak'] ?? 0) >= 6) return true;
      if ((d.contains('acid') || d.contains('acide')) && (vin.axes['acidity'] ?? 0) >= 8) return true;
    }
    return false;
  }

  /// Une bouteille de la cave : « ouvrez votre… ». Elle est prête à boire (l'appelant ne
  /// propose jamais une bouteille en garde).
  static String phraseCave(SuggestionDeFrontiere<Object?> s, String nomDuVin, bool fr) {
    final quoi = _quoi(s.axe, fr);
    final comment = _commentLeVinLeMontre(s.axe, s.valeurDuVin, fr);
    return trSi(fr, 'Pour mieux vous connaître : ouvrez votre {nomDuVin} ({comment}, prêt à boire) — il me dirait ce que vous pensez {quoi}.', 'To get to know you better: open your {nomDuVin} ({comment}, ready to drink) — it would tell me how you feel about {quoi}.', {'nomDuVin': nomDuVin, 'comment': comment, 'quoi': quoi});
  }

  /// « du boisé », « des tanins »… : ce qu'un axe permet de juger, dans la langue de
  /// l'écran (« Je ne sais pas encore ce que vous pensez du boisé »).
  static String ceQueJugeLAxe(String axe) => _quoi(axe, Langue.estFr);

  static String _quoi(String axe, bool fr) => switch (axe) {
        'tannin' => trSi(fr, 'des tanins', 'tannins'),
        'body' => trSi(fr, 'des vins amples', 'full-bodied wines'),
        'oak' => trSi(fr, 'du boisé', 'oak'),
        'acidity' => trSi(fr, 'de la vivacité', 'crisp acidity'),
        'minerality' => trSi(fr, 'de la minéralité', 'minerality'),
        _ => trSi(fr, 'de ce style', 'this style'),
      };

  /// La phrase qui accompagne la suggestion.
  static String phrase(SuggestionDeFrontiere<Object?> s, String nomDuVin, bool fr) {
    final quoi = switch (s.axe) {
      'tannin' => trSi(fr, 'des tanins', 'tannins'),
      'body' => trSi(fr, 'des vins amples', 'full-bodied wines'),
      'oak' => trSi(fr, 'du boisé', 'oak'),
      'acidity' => trSi(fr, 'de la vivacité', 'crisp acidity'),
      'minerality' => trSi(fr, 'de la minéralité', 'minerality'),
      _ => trSi(fr, 'de ce style', 'this style'),
    };
    final comment = _commentLeVinLeMontre(s.axe, s.valeurDuVin, fr);
    final risque = s.plaisir == null
        ? ''
        : (trSi(fr, ', et il a de bonnes chances de vous plaire ({v1} %)', ', and there is a good chance you will enjoy it ({v1}%)', {'v1': s.plaisir!.round()}));
    return trSi(fr, 'Je ne sais pas encore ce que vous pensez {quoi}. {nomDuVin}, {comment}, me le dirait{risque}.', 'I don\'t know yet how you feel about {quoi}. {nomDuVin}, {comment}, would tell me{risque}.', {'quoi': quoi, 'nomDuVin': nomDuVin, 'comment': comment, 'risque': risque});
  }

  static String _commentLeVinLeMontre(String axe, double v, bool fr) {
    final haut = v >= 5;
    return switch (axe) {
      'tannin' => haut ? (trSi(fr, 'très charpenté', 'firmly structured')) : (trSi(fr, 'tout en souplesse', 'silky')),
      'body' => haut ? (trSi(fr, 'ample', 'full-bodied')) : (trSi(fr, 'léger', 'light')),
      'oak' => haut ? (trSi(fr, 'nettement boisé', 'clearly oaked')) : (trSi(fr, 'sans bois', 'unoaked')),
      'acidity' => haut ? (trSi(fr, 'très vif', 'very crisp')) : (trSi(fr, 'tout en rondeur', 'soft and round')),
      'minerality' => haut ? (trSi(fr, 'très minéral', 'very mineral')) : (trSi(fr, 'plus sur le fruit', 'more fruit-driven')),
      _ => '',
    };
  }
}

/// Ce qu'un vin permet de juger, axe par axe (clés de `TasteProfile.axisKeys`, sur 10).
class ProfilDeVin {
  final Map<String, double> axes;

  /// Vrai si les valeurs sont estimées (cépages, région, élevage) plutôt que mesurées.
  final bool estime;

  const ProfilDeVin(this.axes, {this.estime = false});

  /// Un vin de la carte : les mesures du scan, sur les seuls axes plausibles pour sa couleur.
  factory ProfilDeVin.depuisLaCarte(MenuWine w) {
    final m = w.metrics;
    final blancOuBulles = w.isSparkling || (w.isWhite && !w.isRose && !w.isRed);
    return ProfilDeVin({
      if (w.isRed) 'tannin': m.tannins,
      'body': m.body,
      'oak': m.oak,
      'acidity': m.acidity,
      if (blancOuBulles) 'minerality': m.minerality,
    });
  }

  /// Un vin de la cave : pas de mesures, une estimation par cépages, région et élevage.
  /// Seuls les axes que ces données tranchent vraiment sont renseignés : un rouge dont
  /// on ignore les cépages ne dit rien de ses tanins.
  factory ProfilDeVin.depuisLaCave(Wine w) {
    final type = w.type.toLowerCase();
    final rouge = type.contains('rouge') || type.contains('red');
    final bulles = type.contains('effervescent') || type.contains('sparkling') || type.contains('champagne');
    final blanc = type.contains('blanc') || type.contains('white');
    final cepages = w.grapes.map((g) => g.name.toLowerCase()).join(' ');
    final lieu = '${w.region} ${w.appellation ?? ''} ${w.subRegion ?? ''}'.toLowerCase();
    final elevage = '${w.elevageType ?? ''} ${w.barrelAging ?? ''}'.toLowerCase();
    bool a(List<String> mots, String t) => mots.any(t.contains);

    final axes = <String, double>{};
    if (rouge) {
      if (a(['cabernet', 'syrah', 'nebbiolo', 'tannat', 'mourv', 'malbec', 'sagrantino'], cepages) ||
          a(['bandol', 'madiran', 'barolo', 'cahors', 'pauillac', 'saint-estèphe', 'hermitage', 'cornas'], lieu)) {
        axes['tannin'] = 8;
        axes['body'] = 7.5;
      } else if (a(['pinot noir', 'gamay'], cepages) || a(['beaujolais', 'morgon', 'fleurie', 'bourgogne'], lieu)) {
        axes['tannin'] = 3.5;
        axes['body'] = 4.5;
      }
    }
    if (blanc || bulles) {
      if (a(['sauvignon', 'riesling', 'melon', 'chenin'], cepages) ||
          a(['chablis', 'sancerre', 'muscadet', 'pouilly-fumé', 'champagne'], lieu) ||
          bulles) {
        axes['acidity'] = 8.5;
        axes['minerality'] = 8;
      }
      if (a(['meursault', 'puligny', 'chassagne'], lieu)) {
        axes['body'] = 7;
      }
    }
    // L'élevage renseigné tranche le boisé, dans les deux sens.
    if (a(['barrique', 'fût', 'fut ', 'bois', 'oak', 'chêne'], elevage)) {
      axes['oak'] = elevage.contains('neuf') || elevage.contains('new') ? 8 : 6.5;
    } else if (a(['inox', 'cuve', 'béton', 'beton', 'amphore', 'steel'], elevage)) {
      axes['oak'] = 1.5;
    }
    if ((w.alcoholPct ?? 0) >= 14.5) {
      axes['body'] = (axes['body'] ?? 6) + 1;
    }
    return ProfilDeVin(axes, estime: true);
  }
}

class SuggestionDeFrontiere<T> {
  final T vin;

  /// L'axe que le vin trancherait (clé de `TasteProfile.axisKeys`).
  final String axe;
  final double gain;

  /// Plaisir prédit (0–100), ou nul s'il est inconnu.
  final double? plaisir;

  /// La valeur du vin sur cet axe, sur 10.
  final double valeurDuVin;

  const SuggestionDeFrontiere(this.vin, this.axe, this.gain, this.plaisir, this.valeurDuVin);
}
