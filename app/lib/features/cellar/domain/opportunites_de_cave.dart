import '../../auth/domain/palais.dart';
import '../../auth/domain/taste_profile.dart';
import '../../sommelier/domain/angle_mort_de_la_cave.dart';
import '../../sommelier/domain/taste_frontier_engine.dart';
import 'bottle.dart';
import 'styles_de_vin.dart';
import 'vins_connus/vins_connus.dart';

/// Un style que la cave n'a pas, et pourquoi le goûter.
class OpportuniteDeCave {
  final StyleDeVin style;

  /// Sa distance au style le plus proche de la cave : plus elle est grande, plus il est neuf.
  final double distance;

  /// Le style de la cave qui lui ressemble le moins mal ; nul quand la cave est vide.
  final StyleDeVin? plusProche;

  /// L'axe du palais qu'il trancherait, quand le palais l'ignore encore.
  final String? axe;

  /// Vrai quand c'est l'angle mort de la cave : ce que le palais ignore et qu'aucune
  /// bouteille ne lui apprendrait.
  final bool angleMort;

  /// Des vins de la base qui l'incarnent.
  final List<VinTrouve> exemples;

  const OpportuniteDeCave({
    required this.style,
    required this.distance,
    required this.plusProche,
    required this.axe,
    required this.angleMort,
    required this.exemples,
  });
}

/// Ce que la cave contient, style par style, et ce qu'il lui manque.
class CarteDesStyles {
  /// Les bouteilles de chaque style présent (clé : [StyleDeVin.id]).
  final Map<String, int> bouteilles;
  final List<OpportuniteDeCave> opportunites;
  final AngleMortDeLaCave? angleMort;

  const CarteDesStyles({required this.bouteilles, required this.opportunites, required this.angleMort});

  int get stylesPresents => bouteilles.length;
}

/// Les opportunités de la cave (23/10) : des types de vin très différents de ceux qu'elle
/// contient, et l'angle mort du palais.
///
/// Flavien, 23/10 : « c'est pour proposer des types de vins très différents de ceux que
/// l'utilisateur a, donc il faut voir aussi le côté "angle mort et conseils" comme on avait
/// initialement dit ». L'ancienne analyse ne voyait que les couleurs : 70 % de rouges,
/// pas de bulles. Une cave de Bandol, de Côtes-du-Rhône et de Provence passait pour
/// « harmonieuse » et recevait la même liste que toutes les autres.
///
/// Le choix est celui du point le plus éloigné : le premier style proposé est celui dont le
/// plus proche voisin en cave est le plus loin ; le deuxième, le plus loin de la cave ET du
/// premier ; et ainsi de suite. Trois propositions qui ne se ressemblent ni entre elles, ni à
/// ce que la cave contient déjà. Le palais pèse ensuite : jamais un style qui heurte une
/// aversion déclarée, et une prime à celui qui trancherait un axe encore inconnu — d'abord
/// l'angle mort, ce que le palais ignore et qu'aucune bouteille de la cave ne lui dirait.
class OpportunitesDeCave {
  OpportunitesDeCave._();

  /// Le poids du gain d'apprentissage (frontière) face à la nouveauté (distance de style).
  static const double poidsDuGain = 1.5;

  /// La prime du style qui comble l'angle mort.
  static const double primeAngleMort = 2.0;

  static CarteDesStyles analyser(List<Bottle> bouteilles, {TasteProfile? profil, int? annee, int combien = 3}) {
    final parStyle = <String, int>{};
    for (final b in bouteilles) {
      if (b.quantity <= 0 || b.wine == null) continue;
      for (final s in StylesDeVin.de(b.wine!, annee: annee)) {
        parStyle[s.id] = (parStyle[s.id] ?? 0) + b.quantity;
      }
    }
    final angle = profil == null || parStyle.isEmpty ? null : AngleMortDeLaCave.trouver(profil, bouteilles, annee: annee);
    if (parStyle.isEmpty) return CarteDesStyles(bouteilles: parStyle, opportunites: const [], angleMort: angle);

    final presents = [for (final s in StylesDeVin.tous) if (parStyle.containsKey(s.id)) s];
    final possibles = [
      for (final s in StylesDeVin.tous)
        if (!parStyle.containsKey(s.id) && (profil == null || !TasteFrontierEngine.heurteUneAversion(_profil(s), profil))) s,
    ];

    final choisis = <OpportuniteDeCave>[];
    while (choisis.length < combien) {
      OpportuniteDeCave? meilleure;
      var meilleurScore = double.negativeInfinity;
      final unSingulier = choisis.any((o) => o.style.singulier);
      for (final s in possibles) {
        if (choisis.any((o) => o.style == s)) continue;
        if (unSingulier && s.singulier) continue;
        final o = _evaluer(s, presents, profil, angle);
        final score = _score(o, s, [for (final c in choisis) c.style], profil);
        if (score > meilleurScore) {
          meilleurScore = score;
          meilleure = o;
        }
      }
      if (meilleure == null) break;
      choisis.add(meilleure);
    }

    // L'angle mort a toujours sa proposition : s'il n'est pas déjà parmi elles, le style
    // qui le comble le mieux prend la dernière place.
    if (angle != null && choisis.isNotEmpty && !choisis.any((o) => o.angleMort)) {
      final comblants = [
        for (final s in possibles)
          if (_comble(s, angle) && !choisis.any((o) => o.style == s)) _evaluer(s, presents, profil, angle),
      ]..sort((a, b) => b.distance.compareTo(a.distance));
      if (comblants.isNotEmpty) choisis[choisis.length - 1] = comblants.first;
    }

    return CarteDesStyles(bouteilles: parStyle, opportunites: choisis, angleMort: angle);
  }

  static OpportuniteDeCave _evaluer(StyleDeVin s, List<StyleDeVin> presents, TasteProfile? profil, AngleMortDeLaCave? angle) {
    var distance = double.infinity;
    for (final c in presents) {
      final d = s.distance(c);
      if (d < distance) distance = d;
    }
    // Ce qu'on montre comme « le plus proche » se cherche d'abord dans la même couleur :
    // mathématiquement, le vin jaune est plus près d'un rosé de Bandol que d'un Sancerre,
    // mais aucun sommelier ne le dirait ainsi.
    StyleDeVin? plusProche;
    var plusPres = double.infinity;
    final memeCouleur = presents.where((c) => c.groupe == s.groupe).toList();
    for (final c in memeCouleur.isNotEmpty ? memeCouleur : presents) {
      final d = s.distance(c);
      if (d < plusPres) {
        plusPres = d;
        plusProche = c;
      }
    }
    String? axe;
    if (profil != null && s.famille != null) {
      final r = TasteFrontierEngine.evaluer(_profil(s), profil);
      if (r != null &&
          r.$1 >= TasteFrontierEngine.gainMinimal &&
          profil.confianceSur(s.famille!, r.$2) < TasteFrontierEngine.seuilObserve) {
        axe = r.$2;
      }
    }
    final comble = angle != null && _comble(s, angle);
    return OpportuniteDeCave(
      style: s,
      distance: distance,
      plusProche: plusProche,
      axe: comble ? angle.axe : axe,
      angleMort: comble,
      exemples: exemplesDe(s),
    );
  }

  static double _score(OpportuniteDeCave o, StyleDeVin s, List<StyleDeVin> dejaChoisis, TasteProfile? profil) {
    var nouveaute = o.distance;
    for (final c in dejaChoisis) {
      final d = s.distance(c);
      if (d < nouveaute) nouveaute = d;
    }
    var gain = 0.0;
    if (profil != null && s.famille != null) {
      final r = TasteFrontierEngine.evaluer(_profil(s), profil);
      if (r != null && r.$1 >= TasteFrontierEngine.gainMinimal) gain = r.$1;
    }
    return nouveaute + poidsDuGain * gain + (o.angleMort ? primeAngleMort : 0);
  }

  /// Le style montre-t-il l'axe que l'angle mort ignore, dans sa famille ?
  static bool _comble(StyleDeVin s, AngleMortDeLaCave angle) =>
      s.famille == angle.famille && (s.axes[angle.axe] ?? 0) >= AngleMortDeLaCave.seuils[angle.axe]!;

  /// Le style vu par le moteur de frontière : les axes du palais de sa famille.
  static ProfilDeVin _profil(StyleDeVin s) => ProfilDeVin(
        {
          for (final axe in AxesDuPalais.tous)
            if (s.famille != null && AxesDuPalais.deLaFamille(s.famille!, axe) && s.axes[axe] != null) axe: s.axes[axe]!,
        },
        famille: s.famille,
        estime: true,
      );

  /// Les vins de la base qui incarnent le style.
  static List<VinTrouve> exemplesDe(StyleDeVin s) => [
        for (final (nom, de) in s.exemples)
          if (VinsConnus.trouver(nom: nom, producteur: de, type: s.couleur) case final v?) v,
      ];
}
