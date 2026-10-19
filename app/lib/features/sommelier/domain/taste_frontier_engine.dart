import '../../auth/domain/taste_profile.dart';
import '../../auth/domain/palais.dart';
import 'profil_du_vin.dart';
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
/// Les six axes du palais (V2.6), chacun dans la famille du vin : un rouge renseigne le
/// palais des rouges, un blanc celui des blancs.
class TasteFrontierEngine {
  /// À partir de là, un axe est observé : il ne motive plus de suggestion.
  static const double seuilObserve = 0.5;

  /// Plaisir prédit minimal (score de 0 à 100) pour proposer un vin.
  static const double plaisirMinimal = 60;

  /// En dessous, le vin n'apprendrait rien qui vaille une bouteille.
  static const double gainMinimal = 0.35;

  /// La présence d'un trait renseigne plus que son absence. Sur les axes qui vont d'un
  /// pôle à l'autre (tanins, corps, vivacité), le côté bas compte pour moitié : un vin
  /// léger dit si l'on aime la légèreté. Le bois et la minéralité, eux, sont là ou pas :
  /// aimer un vin sans bois ne dit rien de ce qu'on pense du bois. Leur côté bas ne compte
  /// pas — sans quoi la carte proposait « ce Muscadet, sans bois, me dirait ce que vous
  /// pensez du boisé » (relevé le 02/10).
  static double nettete(double v, {String? axe}) {
    if (v >= 5) return ((v - 5) / 5).clamp(0.0, 1.0);
    // Le bois et la douceur sont là ou pas : un vin sec ne dit rien de ce qu'on pense d'un
    // vin tendre. L'âge, lui, va d'un pôle à l'autre : un vin tout jeune renseigne aussi.
    if (axe == 'oak' || axe == 'minerality' || axe == 'sweetness') return 0;
    return (0.5 * (5 - v) / 5).clamp(0.0, 1.0);
  }

  /// Le gain d'un vin pour un profil, et l'axe qui y pèse le plus.
  static (double, String)? evaluer(ProfilDeVin vin, TasteProfile profil) {
    var total = 0.0;
    String? meilleurAxe;
    var meilleur = 0.0;
    final famille = vin.famille;
    if (famille == null) return null;
    for (final e in vin.axes.entries) {
      final confiance = profil.confianceSur(famille, e.key);
      final part = (1 - confiance) * nettete(e.value, axe: e.key);
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
      if (p.famille == null || profil.confianceSur(p.famille!, axe) >= seuilObserve) continue;
      final score = plaisir?.call(c);
      if (score != null && score < plaisirMinimal) continue;
      if (_heurteUneAversion(p, profil)) continue;
      retenus.add((SuggestionDeFrontiere(c, axe, gain, score, p.axes[axe]!, famille: p.famille), prix?.call(c)));
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
      if ((d.contains('sucr') || d.contains('doux')) && (vin.axes['sweetness'] ?? 0) >= 4.5) return true;
    }
    return false;
  }

  /// Les axes que le moteur sait trancher, dans l'ordre du radar.
  static const axesJugeables = ['tannin', 'body', 'oak', 'acidity', 'sweetness', 'evolution'];

  /// Assez net pour trancher un axe : 7 sur 10 au moins (ou 1 au plus sur les axes qui
  /// vont d'un pôle à l'autre).
  static const double netteteMinimale = 0.4;

  /// Axe par axe, la bouteille qui trancherait le mieux ce que [profils] ignorent encore :
  /// un palais seul (« les bouteilles de votre cave qui m'apprendraient le plus », V2.5 ·
  /// F3), ou deux à la fois (« pour mieux vous connaître tous les deux », F2).
  ///
  /// Le 11/10, Flavien : « ça serait bien de pouvoir savoir vite quelles bouteilles en cave
  /// pourraient améliorer les axes encore inconnus ». Seuls les axes encore devinés pour
  /// l'un au moins des palais ; seulement un vin net sur cet axe ; jamais un vin qui heurte
  /// une aversion de l'un d'eux. Les axes ignorés de tous d'abord, puis les moins connus.
  static List<AxeAApprendre<T>> parAxe<T>(
    List<T> candidats,
    List<TasteProfile> profils, {
    required ProfilDeVin Function(T) profilDe,
  }) {
    if (profils.isEmpty) return const [];
    final profilsDesVins = [for (final c in candidats) (c, profilDe(c))];
    final sortie = <AxeAApprendre<T>>[];
    for (final famille in FamillesDeVins.toutes) {
      for (final axe in axesJugeables) {
        if (!AxesDuPalais.deLaFamille(famille, axe)) continue;
        final ignorants = [for (final p in profils) if (p.confianceSur(famille, axe) < seuilObserve) p];
        if (ignorants.isEmpty) continue;
        (T, double)? meilleur;
        for (final (c, vin) in profilsDesVins) {
          if (vin.famille != famille) continue;
          final v = vin.axes[axe];
          if (v == null) continue;
          final n = nettete(v, axe: axe);
          if (n < netteteMinimale) continue;
          if (profils.any((p) => _heurteUneAversion(vin, p))) continue;
          if (meilleur == null || n > nettete(meilleur.$2, axe: axe)) meilleur = (c, v);
        }
        if (meilleur == null) continue;
        sortie.add(AxeAApprendre(
          axe: axe,
          famille: famille,
          ignorants: ignorants,
          ignorance: profils.fold(0.0, (s, p) => s + (1 - p.confianceSur(famille, axe))),
          bouteille: meilleur.$1,
          valeurDuVin: meilleur.$2,
        ));
      }
    }
    sortie.sort((a, b) => a.ignorants.length != b.ignorants.length
        ? b.ignorants.length.compareTo(a.ignorants.length)
        : b.ignorance.compareTo(a.ignorance));
    return sortie;
  }

  /// Comment le vin montre l'axe : « très charpenté », « nettement boisé »…
  static String commentLeVinLeMontre(String axe, double valeur) => _commentLeVinLeMontre(axe, valeur, Langue.estFr);

  /// Une bouteille de la cave : « ouvrez votre… ». Elle est prête à boire (l'appelant ne
  /// propose jamais une bouteille en garde).
  static String phraseCave(SuggestionDeFrontiere<Object?> s, String nomDuVin, bool fr) {
    final quoi = _quoi(s.axe, fr, famille: s.famille);
    final comment = _commentLeVinLeMontre(s.axe, s.valeurDuVin, fr);
    return trSi(fr, 'Pour mieux vous connaître : ouvrez votre {nomDuVin} ({comment}, prêt à boire) — il me dirait ce que vous pensez {quoi}.', 'To get to know you better: open your {nomDuVin} ({comment}, ready to drink) — it would tell me how you feel about {quoi}.', {'nomDuVin': nomDuVin, 'comment': comment, 'quoi': quoi});
  }

  /// « du boisé », « des tanins »… : ce qu'un axe permet de juger, dans la langue de
  /// l'écran (« Je ne sais pas encore ce que vous pensez du boisé »).
  static String ceQueJugeLAxe(String axe, {String? famille}) => _quoi(axe, Langue.estFr, famille: famille);

  static String _quoi(String axe, bool fr, {String? famille}) {
    final rouge = famille == FamillesDeVins.rouge;
    final blanc = famille == FamillesDeVins.blanc;
    return switch (axe) {
      'tannin' => trSi(fr, 'des tanins', 'tannins'),
      'body' when rouge => trSi(fr, 'des rouges amples', 'full-bodied reds'),
      'body' when blanc => trSi(fr, 'des blancs amples', 'full-bodied whites'),
      'body' => trSi(fr, 'des vins amples', 'full-bodied wines'),
      'oak' when rouge => trSi(fr, 'du boisé sur un rouge', 'oak in a red'),
      'oak' when blanc => trSi(fr, 'du boisé sur un blanc', 'oak in a white'),
      'oak' => trSi(fr, 'du boisé', 'oak'),
      'acidity' when rouge => trSi(fr, 'des rouges vifs', 'crisp reds'),
      'acidity' when blanc => trSi(fr, 'des blancs vifs', 'crisp whites'),
      'acidity' => trSi(fr, 'de la vivacité', 'crisp acidity'),
      'sweetness' => trSi(fr, 'des vins tendres ou doux', 'off-dry and sweet wines'),
      'evolution' when rouge => trSi(fr, 'des rouges évolués', 'mature reds'),
      'evolution' when blanc => trSi(fr, 'des blancs évolués', 'mature whites'),
      'evolution' => trSi(fr, 'des vins évolués', 'mature wines'),
      'minerality' => trSi(fr, 'de la minéralité', 'minerality'),
      _ => trSi(fr, 'de ce style', 'this style'),
    };
  }

  /// La phrase qui accompagne la suggestion. Un palais encore deviné lit sa chance de plaisir
  /// « ≈ 71 % », comme partout ailleurs (V2.3 · K5).
  static String phrase(SuggestionDeFrontiere<Object?> s, String nomDuVin, bool fr, {bool palaisDevine = false}) {
    final quoi = _quoi(s.axe, fr, famille: s.famille);
    final comment = _commentLeVinLeMontre(s.axe, s.valeurDuVin, fr);
    final risque = s.plaisir == null
        ? ''
        : (trSi(fr, ', et il a de bonnes chances de vous plaire ({v1} %)', ', and there is a good chance you will enjoy it ({v1}%)', {'v1': '${palaisDevine ? '≈' : ''}${s.plaisir!.round()}'}));
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
      'sweetness' => haut ? (trSi(fr, 'tendre ou doux', 'off-dry or sweet')) : (trSi(fr, 'bien sec', 'bone dry')),
      'evolution' => haut ? (trSi(fr, 'déjà évolué', 'already mature')) : (trSi(fr, 'tout jeune', 'very young')),
      _ => '',
    };
  }
}

/// Ce qu'un vin permet de juger, axe par axe (clés de `TasteProfile.axisKeys`, sur 10).
class ProfilDeVin {
  /// Clés de [AxesDuPalais], sur 10.
  final Map<String, double> axes;

  /// La famille du vin (`rouge`, `blanc`), nulle pour un muté ou un spiritueux : il
  /// n'apprend rien au palais des vins de table.
  final String? famille;

  /// Vrai si les valeurs sont estimées (cépages, région, élevage) plutôt que mesurées.
  final bool estime;

  const ProfilDeVin(this.axes, {this.famille, this.estime = false});

  /// Un vin de la carte : les mesures du scan, sa douceur écrite, son âge.
  factory ProfilDeVin.depuisLaCarte(MenuWine w) => _depuis(ProfilDuVin.deLaCarte(w), estime: false);

  /// Un vin de la cave : pas de mesures, une estimation par cépages, région et élevage.
  /// Seuls les axes que ces données tranchent vraiment sont renseignés : un rouge dont on
  /// ignore les cépages ne dit rien de ses tanins. S'y ajoutent ce qui est sûr (V2.6) : une
  /// douceur écrite sur l'étiquette, l'âge d'un vin millésimé.
  factory ProfilDeVin.depuisLaCave(Wine w, {DateTime? le}) {
    final type = w.type.toLowerCase();
    final famille = TasteProfile.familleDe(w.type);
    if (famille == null || w.tracksFillLevel) return ProfilDeVin(const {}, famille: famille, estime: true);
    final complet = ProfilDuVin.deLaCave(w, le: le);
    final surs = {
      for (final a in complet.surs)
        if (complet.valeur(a) case final v?) a: v * 10,
    };
    // Un moelleux est ample par son sucre, pas par ce qu'on aime d'un vin sec : il dit sa
    // douceur et son âge, rien d'autre. Le radar proposait le Velhotes 10 ans pour apprendre
    // « ce que vous pensez des vins amples » (17/10).
    if (RegExp(r'dessert|moelleux|liquoreux|sweet|dulce|dolce').hasMatch(type) ||
        (surs[AxesDuPalais.douceur] ?? 0) >= 6) {
      return ProfilDeVin(surs, famille: famille, estime: true);
    }
    final rouge = famille == FamillesDeVins.rouge;
    final bulles = type.contains('effervescent') || type.contains('sparkling') || type.contains('champagne');
    final blanc = !rouge;
    final cepages = w.grapes.map((g) => g.name.toLowerCase()).join(' ');
    final lieu = '${w.region} ${w.appellation ?? ''} ${w.subRegion ?? ''}'.toLowerCase();
    final elevage = '${w.elevageType ?? ''} ${w.barrelAging ?? ''}'.toLowerCase();
    bool a(List<String> mots, String t) => mots.any(t.contains);

    final axes = <String, double>{...surs};
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
    return ProfilDeVin(axes, famille: famille, estime: true);
  }

  static ProfilDeVin _depuis(ProfilDuVin p, {required bool estime, bool sansCorps = false}) => ProfilDeVin(
        {
          for (final e in p.valeurs.entries)
            if (!(sansCorps && e.key == AxesDuPalais.corps)) e.key: e.value * 10,
        },
        famille: p.famille,
        estime: estime,
      );
}

/// Un axe encore deviné, et la bouteille qui le trancherait.
class AxeAApprendre<T> {
  /// Clé de [AxesDuPalais].
  final String axe;

  /// La famille du palais que la bouteille renseignerait.
  final String famille;

  /// Les palais qui l'ignorent encore (confiance sous `seuilObserve`).
  final List<TasteProfile> ignorants;

  /// Ce qui reste à apprendre, tous palais confondus : Σ (1 − confiance).
  final double ignorance;
  final T bouteille;

  /// La valeur du vin sur cet axe, sur 10.
  final double valeurDuVin;

  const AxeAApprendre({
    required this.axe,
    required this.famille,
    required this.ignorants,
    required this.ignorance,
    required this.bouteille,
    required this.valeurDuVin,
  });
}

class SuggestionDeFrontiere<T> {
  final T vin;

  /// L'axe que le vin trancherait (clé de [AxesDuPalais]).
  final String axe;
  final double gain;

  /// La famille du palais qu'il renseignerait.
  final String? famille;

  /// Plaisir prédit (0–100), ou nul s'il est inconnu.
  final double? plaisir;

  /// La valeur du vin sur cet axe, sur 10.
  final double valeurDuVin;

  const SuggestionDeFrontiere(this.vin, this.axe, this.gain, this.plaisir, this.valeurDuVin, {this.famille});
}
