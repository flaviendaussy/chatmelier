import 'menu_wine.dart';

/// « À prix égal, je prendrais celui-ci » (idée de Robin, 08/10).
///
/// Devant deux vins au même prix, la carte ne dit pas lequel prendre. Le sommelier le dit,
/// d'après le palais de la personne : celui qui lui va le mieux, s'il devance nettement les
/// autres. À trois points près, les vins se valent pour elle, et dire « celui-ci » serait une
/// préférence inventée : rien ne s'affiche.
///
/// On ne compare que des vins de même couleur : entre un rouge et un champagne au même prix,
/// le choix tient au plat et au moment, pas au prix.
class ChoixAPrixEgal {
  /// Le vin que le sommelier prendrait.
  final MenuWine vin;

  /// Les vins au même prix qu'il devance, du plus proche au plus lointain.
  final List<MenuWine> autres;

  /// Le prix commun, et s'il s'agit du prix au verre (une ardoise) ou à la bouteille.
  final double prix;
  final bool auVerre;

  /// La couleur commune : `rouge`, `blanc`, `rose`, `bulles` ou `autre` (liquoreux, mutés,
  /// type illisible).
  final String couleur;

  const ChoixAPrixEgal({
    required this.vin,
    required this.autres,
    required this.prix,
    required this.auVerre,
    required this.couleur,
  });

  /// L'avance, en points d'accord, sur le second.
  int get ecart => ((vin.userMatchScore ?? 0) - (autres.first.userMatchScore ?? 0)).round();
}

class APrixEgal {
  /// En dessous, deux vins se valent pour ce palais.
  static const ecartMinimal = 3;

  static String couleurDe(MenuWine w) => w.isSparkling
      ? 'bulles'
      : w.isRose
          ? 'rose'
          : w.isRed
              ? 'rouge'
              : w.isWhite
                  ? 'blanc'
                  : 'autre';

  /// Les vins que le sommelier prendrait à prix égal, par identifiant.
  ///
  /// Sur une ardoise, on commande au verre : les vins se comparent au prix du verre, à
  /// format égal ; ailleurs, au prix de la bouteille. Un vin sans prix ou sans accord calculé
  /// (palais inconnu) n'entre dans aucune comparaison.
  static Map<String, ChoixAPrixEgal> choisir(List<MenuWine> vins, {bool ardoise = false}) {
    final groupes = <String, List<MenuWine>>{};
    final prixDuGroupe = <String, double>{};
    final verre = <String, bool>{};
    for (final w in vins) {
      if (w.userMatchScore == null) continue;
      final auVerre = ardoise && w.glassPrices.isNotEmpty;
      final prix = auVerre ? w.glassPrices.first.price : w.bottlePrice;
      if (prix == null || prix <= 0) continue;
      final cle = '${couleurDe(w)}:'
          '${auVerre ? 'verre:${w.glassPrices.first.format.trim().toLowerCase()}' : 'bouteille'}:'
          '${(prix * 100).round()}';
      (groupes[cle] ??= []).add(w);
      prixDuGroupe[cle] = prix;
      verre[cle] = auVerre;
    }
    final choix = <String, ChoixAPrixEgal>{};
    groupes.forEach((cle, membres) {
      if (membres.length < 2) return;
      final tries = [...membres]..sort((a, b) => b.userMatchScore!.compareTo(a.userMatchScore!));
      final premier = tries.first;
      final second = tries[1];
      if (premier.userMatchScore! - second.userMatchScore! < ecartMinimal) return;
      choix[premier.id] = ChoixAPrixEgal(
        vin: premier,
        autres: tries.sublist(1),
        prix: prixDuGroupe[cle]!,
        auVerre: verre[cle]!,
        couleur: couleurDe(premier),
      );
    });
    return choix;
  }
}
