import 'dart:math' as math;

import '../../../shared/utils/langue.dart';
import 'mots_du_palais.dart';
import 'palais.dart';
import 'taste_profile.dart';

/// Deux palais face à face, dans une famille (V2.6 · P2).
///
/// Seuls les axes que l'on connaît des deux se comparent : deux palais encore devinés
/// sont tous deux « neutres », et les dire « à 99 % d'affinité » serait inventer. Le
/// palais d'avant comparait huit axes toutes couleurs confondues.
class AffiniteDesPalais {
  final String famille;

  /// De 30 à 99, ou nul quand aucun axe n'est connu des deux.
  final double? pourcentage;

  /// Les axes comparés : connus des deux.
  final int axesCompares;

  /// Les goûts partagés (« les rouges puissants »).
  final List<String> enCommun;

  /// Les écarts, chacun une phrase (« Vous aimez les rouges plus puissants que Caro »).
  final List<String> ecarts;

  /// Le vin qui irait aux deux.
  final String vinIdeal;

  final bool aEstVous;
  final bool bEstVous;
  final String nomA;
  final String nomB;

  const AffiniteDesPalais({
    required this.famille,
    required this.pourcentage,
    required this.axesCompares,
    required this.enCommun,
    required this.ecarts,
    required this.vinIdeal,
    required this.nomA,
    required this.nomB,
    this.aEstVous = false,
    this.bEstVous = false,
  });

  /// Deux valeurs à moins de ça partagent le goût.
  static const double ecartCommun = 1.5;

  /// Deux valeurs à plus de ça divergent.
  static const double ecartNotable = 3.0;

  static AffiniteDesPalais comparer(TasteProfile a, TasteProfile b, String famille) {
    final pa = a.palaisPour(famille);
    final pb = b.palaisPour(famille);
    final axes = [for (final axe in AxesDuPalais.de(famille)) if (pa.connait(axe) && pb.connait(axe)) axe];

    double? pourcentage;
    if (axes.isNotEmpty) {
      final somme = axes.fold<double>(0, (s, axe) => s + math.pow(pa.valeur(axe) - pb.valeur(axe), 2));
      final distance = math.sqrt(somme);
      final distanceMax = math.sqrt(axes.length * 100.0);
      pourcentage = ((1 - distance / distanceMax) * 100).clamp(30.0, 99.0).toDouble();
    }

    final enCommun = <String>[];
    final ecarts = <String>[];
    for (final axe in axes) {
      final va = pa.valeur(axe);
      final vb = pb.valeur(axe);
      final ecart = (va - vb).abs();
      if (ecart <= ecartCommun) {
        final g = MotsDuPalais.gout(famille, axe, (va + vb) / 2);
        if (g != null) enCommun.add(g);
      } else if (ecart >= ecartNotable) {
        final aPlus = va > vb;
        ecarts.add(_ecart(
          famille,
          axe,
          plus: aPlus ? a : b,
          moins: aPlus ? b : a,
        ));
      }
    }

    return AffiniteDesPalais(
      famille: famille,
      pourcentage: pourcentage,
      axesCompares: axes.length,
      enCommun: enCommun,
      ecarts: ecarts,
      vinIdeal: MotsDuPalais.vinPour(famille, {
        for (final axe in AxesDuPalais.de(famille)) axe: (pa.valeur(axe) + pb.valeur(axe)) / 2,
      }),
      nomA: a.name,
      nomB: b.name,
      aEstVous: a.isPrimary,
      bEstVous: b.isPrimary,
    );
  }

  /// L'app parle à la personne : « Vous aimez… que Caro », jamais « Moi aime… »
  /// (Flavien, 13/10).
  static String _ecart(String famille, String axe, {required TasteProfile plus, required TasteProfile moins}) {
    final params = {
      'famille': MotsDuPalais.familleAuPluriel(famille),
      'adj': MotsDuPalais.plus(famille, axe),
      'a': plus.name,
      'b': moins.name,
    };
    if (plus.isPrimary) return tr('Vous aimez les {famille} plus {adj} que {b}', 'You like {adj} {famille} than {b}', params);
    if (moins.isPrimary) return tr('{a} aime les {famille} plus {adj} que vous', '{a} likes {adj} {famille} than you', params);
    return tr('{a} aime les {famille} plus {adj} que {b}', '{a} likes {adj} {famille} than {b}', params);
  }

  String get phraseEnCommun {
    if (axesCompares == 0) {
      return tr('Pas encore assez de dégustations des {famille} pour vous comparer.',
          'Not enough tastings of {famille} yet to compare you.', {'famille': MotsDuPalais.familleAuPluriel(famille)});
    }
    if (enCommun.isEmpty) {
      return tr('Pas de goût franc en commun sur les {famille} : vos palais se complètent.',
          'No strong shared taste in {famille}: your palates complement each other.',
          {'famille': MotsDuPalais.familleAuPluriel(famille)});
    }
    final liste = MotsDuPalais.liste(enCommun);
    if (aEstVous || bEstVous) return tr('Vous aimez tous les deux {liste}.', 'You both like {liste}.', {'liste': liste});
    return tr('{a} et {b} aiment tous les deux {liste}.', '{a} and {b} both like {liste}.', {'a': nomA, 'b': nomB, 'liste': liste});
  }

  String get phraseEcarts => ecarts.isEmpty
      ? tr('Très peu de divergences notables entre vos deux palais.', 'Very few notable differences between your two palates.')
      : '${ecarts.join('. ')}.';
}
