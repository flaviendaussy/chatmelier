import '../../../shared/utils/langue.dart';
import '../../auth/domain/taste_profile.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/cellar_gap_engine.dart';
import 'profil_du_vin_de_cave.dart';
import 'taste_frontier_engine.dart';

/// L'angle mort de la cave (V2.3 · J2) : ce qui lui manque pour mieux connaître un palais.
///
/// Le moteur de frontière dit quel axe du palais est le moins connu ; la cave dit si une
/// de ses bouteilles le trancherait. Quand aucune ne le montre, c'est une lacune d'un
/// genre que l'analyse des couleurs ne voit pas : « Ce qui vous manque pour mieux vous
/// connaître : un blanc boisé. Un Meursault ou un Rioja blanc de garde vous le dirait. »
class AngleMortDeLaCave {
  /// L'axe du palais (clé de `TasteProfile.axisKeys`).
  final String axe;
  final double confiance;

  const AngleMortDeLaCave(this.axe, this.confiance);

  /// Les axes qu'une bouteille permet de juger (ceux du moteur de frontière), dans l'ordre
  /// où ils départagent deux axes aussi peu connus.
  static const axesJugeables = ['oak', 'minerality', 'tannin', 'acidity', 'body'];

  /// À partir de quelle valeur estimée (sur 10) une bouteille « montre » l'axe. Le côté
  /// haut seulement : aimer un vin sans bois ne dit pas qu'on fuit le bois.
  static const seuils = {'oak': 6.0, 'minerality': 7.5, 'tannin': 7.5, 'acidity': 8.0, 'body': 7.5};

  /// L'axe le moins connu que rien dans la cave ne trancherait, ou rien.
  ///
  /// Un axe déjà observé (confiance ≥ [TasteFrontierEngine.seuilObserve]) ne motive rien ;
  /// une aversion déclarée non plus : on ne conseille pas d'acheter du bois à qui l'a fui.
  static AngleMortDeLaCave? trouver(TasteProfile profil, List<Bottle> bouteilles, {int? annee}) {
    final candidats = axesAApprendre(profil);
    if (candidats.isEmpty) return null;

    final profils = [
      for (final b in bouteilles)
        if (b.quantity > 0 && b.wine != null) ProfilDuVinDeCave.estimer(b.wine!, annee: annee),
    ];
    for (final axe in candidats) {
      final seuil = seuils[axe]!;
      final dejaLa = profils.any((p) => switch (axe) {
            'oak' => p.oak >= seuil,
            'minerality' => p.minerality >= seuil,
            'tannin' => p.tannin >= seuil,
            'acidity' => p.acidity >= seuil,
            _ => p.body >= seuil,
          });
      if (!dejaLa) return AngleMortDeLaCave(axe, profil.axisConfidence(axe));
    }
    return null;
  }

  /// Les axes qu'une bouteille apprendrait encore, du moins connu au mieux connu : ni
  /// observés, ni fuis.
  /// À confiance égale, l'ordre de [axesJugeables] : le tri de Dart n'est pas stable.
  static List<String> axesAApprendre(TasteProfile profil) => [
        for (final a in axesJugeables)
          if (profil.axisConfidence(a) < TasteFrontierEngine.seuilObserve && !_fuit(profil, a)) a,
      ]..sort((x, y) {
          final c = profil.axisConfidence(x).compareTo(profil.axisConfidence(y));
          return c != 0 ? c : axesJugeables.indexOf(x).compareTo(axesJugeables.indexOf(y));
        });

  static bool _fuit(TasteProfile profil, String axe) {
    final mots = switch (axe) {
      'oak' => const ['bois', 'vanill', 'oak'],
      'tannin' => const ['tann', 'tanin', 'astringen'],
      'acidity' => const ['acid', 'acide'],
      _ => const <String>[],
    };
    return profil.dislikedCharacteristics.any((d) => mots.any(d.toLowerCase().contains));
  }

  /// Le style qui trancherait l'axe, et deux vins qui l'incarnent.
  ({String style, String exemples, List<String> appellations}) get conseil => switch (axe) {
        'oak' => (
            style: tr('un blanc boisé', 'an oaked white'),
            exemples: tr('Un Meursault ou un Rioja blanc de garde', 'A Meursault or an aged white Rioja'),
            appellations: const ['Meursault', 'Rioja blanco Reserva', 'Pessac-Léognan blanc'],
          ),
        'minerality' => (
            style: tr('un blanc minéral', 'a mineral white'),
            exemples: tr('Un Chablis ou un Sancerre', 'A Chablis or a Sancerre'),
            appellations: const ['Chablis', 'Sancerre', 'Assyrtiko de Santorin'],
          ),
        'tannin' => (
            style: tr('un rouge très charpenté', 'a firmly structured red'),
            exemples: tr('Un Madiran ou un Barolo', 'A Madiran or a Barolo'),
            appellations: const ['Madiran', 'Barolo', 'Cahors'],
          ),
        'acidity' => (
            style: tr('un blanc très vif', 'a very crisp white'),
            exemples: tr('Un riesling de Moselle ou un Muscadet', 'A Mosel Riesling or a Muscadet'),
            appellations: const ['Riesling (Moselle)', 'Muscadet sur lie', 'Chablis'],
          ),
        _ => (
            style: tr('un vin ample', 'a full-bodied wine'),
            exemples: tr('Un Châteauneuf-du-Pape ou un Amarone', 'A Châteauneuf-du-Pape or an Amarone'),
            appellations: const ['Châteauneuf-du-Pape', 'Amarone della Valpolicella', 'Meursault'],
          ),
      };

  /// L'analyse de la cave, avec l'angle mort du palais en tête quand il y en a un.
  ///
  /// L'analyse des couleurs et des apogées reste celle de la cave ; l'angle mort vient
  /// d'ailleurs (le palais), d'où ce complément plutôt qu'un paramètre du moteur de cave.
  static CellarGapAnalysis completer(
    CellarGapAnalysis analyse, {
    required TasteProfile? profil,
    required List<Bottle> bouteilles,
    int? annee,
  }) {
    if (profil == null || analyse.totalBottles == 0) return analyse;
    final angle = trouver(profil, bouteilles, annee: annee);
    if (angle == null) return analyse;
    return CellarGapAnalysis(
      totalBottles: analyse.totalBottles,
      redRatio: analyse.redRatio,
      whiteRatio: analyse.whiteRatio,
      roseRatio: analyse.roseRatio,
      sparklingRatio: analyse.sparklingRatio,
      readyToDrinkCount: analyse.readyToDrinkCount,
      inAgingCount: analyse.inAgingCount,
      pastPeakCount: analyse.pastPeakCount,
      gaps: [angle.lacune, ...analyse.gaps],
      shoppingWishlist: {angle.conseil.appellations.first, ...analyse.shoppingWishlist}.toList(),
    );
  }

  /// La lacune, telle que l'analyse de la cave la présente.
  CellarGapCategory get lacune {
    final c = conseil;
    return CellarGapCategory(
      title: tr('Pour mieux vous connaître', 'To get to know you better'),
      status: 'warning',
      diagnosis: tr('Je ne sais pas encore ce que vous pensez {quoi}, et aucune bouteille de votre cave ne me le dirait.',
          'I don\'t know yet how you feel about {quoi}, and no bottle in your cellar would tell me.',
          {'quoi': TasteFrontierEngine.ceQueJugeLAxe(axe)}),
      sommelierAdvice: tr('Ce qui vous manque pour mieux vous connaître : {style}. {exemples} vous le dirait.',
          'What your cellar lacks to know you better: {style}. {exemples} would tell you.',
          {'style': c.style, 'exemples': c.exemples}),
      recommendedAppellations: c.appellations,
    );
  }
}
