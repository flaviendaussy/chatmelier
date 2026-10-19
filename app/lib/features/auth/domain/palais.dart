import '../../../shared/utils/langue.dart';

/// Les six axes du palais (V2.6 · P2), dans l'ordre du radar.
///
/// Le radar en avait huit : le fruit frais doublait la fraîcheur, le fruit mûr le corps,
/// les épices et la minéralité ne s'apprenaient presque jamais et ne servaient à rien pour
/// choisir. Il manquait en revanche ce qui partage le plus les gens : la douceur et l'âge.
class AxesDuPalais {
  AxesDuPalais._();

  static const fraicheur = 'acidity';
  static const douceur = 'sweetness';
  static const corps = 'body';
  static const tanins = 'tannin';
  static const boise = 'oak';
  static const evolution = 'evolution';

  static const tous = [fraicheur, douceur, corps, tanins, boise, evolution];

  /// Les axes que l'on demande à la personne ; l'évolution se lit sur le millésime.
  static const demandables = [douceur, fraicheur, corps, tanins, boise];

  /// Les tanins ne se jugent que sur un rouge.
  static bool deLaFamille(String famille, String axe) => axe != tanins || famille == 'rouge';

  static List<String> de(String famille) => [for (final a in tous) if (deLaFamille(famille, a)) a];

  /// Les axes que montre le radar d'une famille : cinq chacune. La douceur d'un rouge
  /// reste apprise et comparée (un lambrusco amabile n'ira pas à qui fuit le sucre), mais
  /// presque tous les rouges sont secs : sur le radar, ce ne serait qu'un creux.
  static List<String> duRadar(String famille) =>
      [for (final a in de(famille)) if (a != douceur || famille != 'rouge') a];

  static String nom(String axe) => switch (axe) {
        fraicheur => tr('Fraîcheur', 'Freshness'),
        douceur => tr('Douceur', 'Sweetness'),
        corps => tr('Corps', 'Body'),
        tanins => tr('Tanins', 'Tannins'),
        boise => tr('Boisé', 'Oak'),
        evolution => tr('Évolution', 'Maturity'),
        _ => axe,
      };

  /// Les deux bouts de l'axe, en mots de tous les jours : bas, haut.
  static (String, String) bouts(String axe) => switch (axe) {
        fraicheur => (tr('Rond', 'Soft'), tr('Vif', 'Crisp')),
        douceur => (tr('Sec', 'Dry'), tr('Doux', 'Sweet')),
        corps => (tr('Léger', 'Light'), tr('Puissant', 'Full')),
        tanins => (tr('Souples', 'Supple'), tr('Fermes', 'Firm')),
        boise => (tr('Sans bois', 'Unoaked'), tr('Boisé', 'Oaky')),
        evolution => (tr('Jeune', 'Young'), tr('Évolué', 'Mature')),
        _ => ('', ''),
      };

  /// Le « pour vous » d'un axe : pas assez, juste, trop — dans l'ordre de l'axe.
  static (String, String, String) jugements(String axe) => switch (axe) {
        fraicheur => (tr('Trop mou', 'Too flat'), tr('Juste', 'Just right'), tr('Trop vif', 'Too sharp')),
        douceur => (tr('Trop sec', 'Too dry'), tr('Juste', 'Just right'), tr('Trop doux', 'Too sweet')),
        corps => (tr('Trop léger', 'Too light'), tr('Juste', 'Just right'), tr('Trop puissant', 'Too heavy')),
        tanins => (tr('Trop souple', 'Too soft'), tr('Juste', 'Just right'), tr('Trop tannique', 'Too tannic')),
        boise => (tr('Pas assez boisé', 'Not oaky enough'), tr('Juste', 'Just right'), tr('Trop boisé', 'Too oaky')),
        _ => ('', '', ''),
      };

  /// La question posée pour un axe.
  static String question(String axe) => switch (axe) {
        fraicheur => tr('Sa fraîcheur, pour vous ?', 'Its freshness, for you?'),
        douceur => tr('Sa douceur, pour vous ?', 'Its sweetness, for you?'),
        corps => tr('Son corps, pour vous ?', 'Its body, for you?'),
        tanins => tr('Ses tanins, pour vous ?', 'Its tannins, for you?'),
        boise => tr('Son boisé, pour vous ?', 'Its oak, for you?'),
        _ => '',
      };

  /// Ce qu'un palais neutre attend d'un axe (0–10) quand rien n'en est connu : un rouge
  /// est sec, un blanc presque, le corps d'un rouge dépasse celui d'un blanc.
  static double neutre(String famille, String axe) => switch (axe) {
        douceur => famille == 'rouge' ? 0.5 : 1.5,
        corps => famille == 'rouge' ? 6.0 : 4.5,
        fraicheur => famille == 'rouge' ? 5.0 : 6.0,
        tanins => 5.0,
        boise => 3.5,
        evolution => 4.0,
        _ => 5.0,
      };
}

/// Les familles de vins dont le palais s'apprend à part (V2.6 · P1).
class FamillesDeVins {
  FamillesDeVins._();
  static const rouge = 'rouge';
  static const blanc = 'blanc';
  static const toutes = [rouge, blanc];

  static String nom(String famille) =>
      famille == rouge ? tr('Rouges', 'Reds') : tr('Blancs, rosés, bulles', 'Whites, rosés, sparkling');

  /// Le nom court, là où la place manque (l'en-tête de l'empreinte).
  static String nomCourt(String famille) => famille == rouge ? tr('Rouges', 'Reds') : tr('Blancs', 'Whites');
}

/// Un palais tel qu'on le montre et le compare : une famille, six axes de 0 à 10, et ce
/// qu'on sait de chacun (V2.6 · P5).
class PalaisDeFamille {
  final String famille;

  /// Chaque axe de la famille, de 0 à 10 : appris, sinon déclaré, sinon neutre.
  final Map<String, double> valeurs;

  /// Ce qu'on sait de chaque axe, de 0 (deviné) à 1 (bien établi).
  final Map<String, double> confiance;

  /// Les axes dont on sait quelque chose : appris (même par déduction) ou déclarés.
  final Set<String> connus;

  const PalaisDeFamille({
    required this.famille,
    required this.valeurs,
    required this.confiance,
    this.connus = const {},
  });

  double valeur(String axe) => valeurs[axe] ?? AxesDuPalais.neutre(famille, axe);
  double confianceDe(String axe) => confiance[axe] ?? 0.0;
  bool connait(String axe) => connus.contains(axe);

  /// La moyenne de ce qu'on sait des axes que montre le radar de la famille. La douceur
  /// d'un rouge ne se demande ni ne se montre : la compter tiendrait un palais des rouges
  /// à jamais « connu à 80 % ».
  double get connaissance {
    final axes = AxesDuPalais.duRadar(famille);
    return axes.fold<double>(0, (s, a) => s + confianceDe(a)) / axes.length;
  }

  Map<String, dynamic> toJson() => {
        'valeurs': {for (final e in valeurs.entries) e.key: double.parse(e.value.toStringAsFixed(1))},
        'confiance': {for (final e in confiance.entries) e.key: double.parse(e.value.toStringAsFixed(2))},
        if (connus.isNotEmpty) 'connus': connus.toList(),
      };

  static PalaisDeFamille? fromJson(String famille, dynamic json) {
    if (json is! Map) return null;
    Map<String, double> nombres(dynamic m) => m is Map
        ? {
            for (final e in m.entries)
              if (double.tryParse(e.value.toString()) case final v?) e.key.toString(): v,
          }
        : const {};
    return PalaisDeFamille(
      famille: famille,
      valeurs: {for (final e in nombres(json['valeurs']).entries) e.key: e.value.clamp(0.0, 10.0).toDouble()},
      confiance: {for (final e in nombres(json['confiance']).entries) e.key: e.value.clamp(0.0, 1.0).toDouble()},
      connus: {for (final c in (json['connus'] as List? ?? const [])) c.toString()},
    );
  }
}
