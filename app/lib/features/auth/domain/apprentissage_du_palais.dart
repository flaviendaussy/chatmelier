import 'palais.dart';
import 'taste_profile.dart';
import '../../sommelier/domain/profil_du_vin.dart';

/// Un axe qui bouge après une dégustation : de quoi l'enregistrer, l'expliquer et le défaire.
class ChangementDAxe {
  final String famille;
  final String axe;

  /// La valeur propre à la famille avant (nulle : l'axe reposait sur le palais d'avant ou
  /// n'était pas connu). C'est elle qu'une annulation remet.
  final double? avant;
  final double apres;

  /// Une observation de plus : la personne l'a dit, ou le vin le disait sûrement.
  final bool compte;

  /// `jugement` (un « pour vous » ou un défaut nommé), `mesure` (la bouche décrite),
  /// `sur` (l'âge du vin, sa douceur écrite), `aime` (déduit d'un vin aimé), `deception`.
  final String motif;

  /// `trop`, `juste` ou `pas_assez` quand [motif] est `jugement`.
  final String? jugement;

  const ChangementDAxe({
    required this.famille,
    required this.axe,
    required this.avant,
    required this.apres,
    required this.compte,
    required this.motif,
    this.jugement,
  });
}

/// Ce qu'une dégustation apprend au palais d'une famille (V2.6 · P4).
///
/// Un « pour vous » (trop / juste / pas assez) vaut plus qu'une mesure du vin : il dit
/// directement de quel côté est la préférence. Ce que la personne n'a pas dit, le vin le dit
/// par ses données, mais ce n'est qu'une déduction : un vin aimé tire alors l'axe d'un
/// demi-pas sans compter comme observation — sauf ce qui est sûr, son âge, une douceur écrite.
class ApprentissageDuPalais {
  ApprentissageDuPalais._();

  /// Le pas de la moyenne exponentielle (`kAxisSmoothing`).
  static const double pas = 0.25;

  /// Ce que « trop » et « pas assez » placent de part et d'autre du vin goûté.
  static const double ecartDuJugement = 0.2;

  /// Une déception déjà expliquée par un axe (aussi loin du palais) n'apprend rien.
  static const double seuilExplique = 0.5;

  /// Une déception qu'aucun axe n'explique (tous à moins de ça) n'apprend rien non plus :
  /// la cause est ailleurs — un défaut, l'humeur, une bouteille fatiguée.
  static const double seuilSansCause = 0.1;

  /// Le pas d'éloignement d'une déception, partagé entre les axes selon leur écart.
  static const double pasDeDeception = 0.0625;

  /// À partir de quelle note un vin dont la bouche n'a pas été décrite tire les axes.
  static const double noteAimeeDeduite = 7.0;

  /// À partir de quelle note une bouche décrite tire les axes (celle de Q5).
  static const double noteAimeeDecrite = 5.0;

  static const double noteDecevante = 4.0;

  /// Les défauts que le questionnaire laisse nommer, lus comme des « pour vous ».
  static const Map<String, (String, String)> defautsNommes = {
    'trop_acide': (AxesDuPalais.fraicheur, 'trop'),
    'trop_tannique': (AxesDuPalais.tanins, 'trop'),
    'trop_boise': (AxesDuPalais.boise, 'trop'),
    'trop_alcoolise': (AxesDuPalais.corps, 'trop'),
    'trop_leger': (AxesDuPalais.corps, 'pas_assez'),
    'trop_sucre': (AxesDuPalais.douceur, 'trop'),
  };

  /// Les jugements d'une dégustation : ceux du « pour vous », complétés par les défauts
  /// nommés (le « pour vous » l'emporte sur le même axe).
  static Map<String, String> jugementsDe(Map<String, String> pourVous, Iterable<String> defauts) => {
        for (final d in defauts)
          if (defautsNommes[d] case (final axe, final sens)) axe: sens,
        ...pourVous,
      };

  static List<ChangementDAxe> apprendre({
    required TasteProfile profil,
    required String famille,
    required double note,
    Map<String, String> jugements = const {},
    Map<String, double> mesures = const {},
    required ProfilDuVin vin,
  }) {
    final changements = <ChangementDAxe>[];
    // Ce dont part un axe : ce que la famille en sait (appris, ou hérité du palais d'avant).
    double? base(String axe) => profil.valeurPalais(famille, axe);
    // Ce dont part une observation : sans observation, la valeur en place n'est qu'une
    // déduction, et la première vraie mesure la remplace au lieu de s'y mêler (Q5).
    double? baseObservee(String axe) => profil.observationsSur(famille, axe) > 0 ? base(axe) : null;

    double vers(double? de, double cible, double poids) => de == null ? cible : de * (1 - poids) + cible * poids;

    final axes = AxesDuPalais.de(famille);
    for (final axe in axes) {
      final jugement = jugements[axe];
      final mesure = mesures[axe];
      final estime = vin.valeur(axe);
      final valeurDuVin = mesure ?? estime;
      final avant = profil.valeurPropre(famille, axe);
      if (jugement != null) {
        if (valeurDuVin == null) continue;
        final decalage = switch (jugement) { 'trop' => -ecartDuJugement, 'pas_assez' => ecartDuJugement, _ => 0.0 };
        final cible = (valeurDuVin + decalage).clamp(0.0, 1.0).toDouble();
        changements.add(ChangementDAxe(
          famille: famille,
          axe: axe,
          avant: avant,
          apres: vers(baseObservee(axe), cible, pas),
          compte: true,
          motif: 'jugement',
          jugement: jugement,
        ));
        continue;
      }
      if (mesure != null && note >= noteAimeeDecrite) {
        changements.add(ChangementDAxe(
          famille: famille,
          axe: axe,
          avant: avant,
          apres: vers(baseObservee(axe), mesure, pas),
          compte: true,
          motif: 'mesure',
        ));
        continue;
      }
      if (mesure == null && estime != null && note >= noteAimeeDeduite) {
        final sur = vin.surs.contains(axe);
        final apres = sur ? vers(baseObservee(axe), estime, pas) : vers(base(axe), estime, pas / 2);
        if (sur || apres != base(axe)) {
          changements.add(ChangementDAxe(
            famille: famille,
            axe: axe,
            avant: avant,
            apres: apres,
            compte: sur,
            motif: sur ? 'sur' : 'aime',
          ));
        }
      }
    }

    if (note <= noteDecevante) changements.addAll(_deception(profil, famille, jugements, mesures, vin, base));
    return changements;
  }

  /// Une déception éloigne le palais du vin sur les axes qui peuvent l'expliquer, et
  /// seulement eux : rien si un axe l'explique déjà, rien si aucun ne l'explique (V2.6 ·
  /// correctif de Q5, qui poussait chaque axe proche, et d'autant plus qu'il était proche).
  static List<ChangementDAxe> _deception(
    TasteProfile profil,
    String famille,
    Map<String, String> jugements,
    Map<String, double> mesures,
    ProfilDuVin vin,
    double? Function(String) base,
  ) {
    final ecarts = <String, ({double base, double vin})>{};
    for (final axe in AxesDuPalais.de(famille)) {
      if (jugements.containsKey(axe)) continue;
      final b = base(axe);
      final v = mesures[axe] ?? vin.valeur(axe);
      if (b == null || v == null) continue;
      ecarts[axe] = (base: b, vin: v);
    }
    if (ecarts.isEmpty) return const [];
    final distances = {for (final e in ecarts.entries) e.key: (e.value.base - e.value.vin).abs()};
    final plusLoin = distances.values.reduce((a, b) => a > b ? a : b);
    if (plusLoin >= seuilExplique || plusLoin < seuilSansCause) return const [];
    return [
      for (final e in ecarts.entries)
        if (distances[e.key]! >= seuilSansCause)
          ChangementDAxe(
            famille: famille,
            axe: e.key,
            avant: profil.valeurPropre(famille, e.key),
            apres: (e.value.base + (e.value.base > e.value.vin ? 1 : -1) * pasDeDeception * distances[e.key]! / plusLoin)
                .clamp(0.0, 1.0)
                .toDouble(),
            compte: mesures.containsKey(e.key) || vin.surs.contains(e.key),
            motif: 'deception',
          ),
    ];
  }
}
