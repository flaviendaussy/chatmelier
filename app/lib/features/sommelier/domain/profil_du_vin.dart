import '../../auth/domain/palais.dart';
import '../../auth/domain/taste_profile.dart';
import '../../cellar/domain/douceur_du_vin.dart';
import '../../cellar/domain/evolution_du_vin.dart';
import '../../cellar/domain/wine.dart';
import '../../menu_scan/domain/menu_wine.dart';
import 'profil_du_vin_de_cave.dart';

/// Un vin sur les six axes du palais, de 0 à 1 (V2.6 · P3).
///
/// Ce que la personne n'a pas à mesurer elle-même : le vin le dit par ses données — ses
/// cépages, son lieu, son élevage, son degré pour la cave ; ses métriques pour une carte —,
/// sa douceur par son étiquette et son âge le jour où on le boit. Un axe absent n'est pas
/// connu.
class ProfilDuVin {
  /// `rouge`, `blanc`, ou nulle (muté, spiritueux) : rien à comparer à un palais.
  final String? famille;
  final Map<String, double> valeurs;

  /// Les axes dont la valeur est sûre : l'âge d'un vin millésimé, une douceur écrite.
  /// Le reste est estimé.
  final Set<String> surs;

  const ProfilDuVin({required this.famille, required this.valeurs, this.surs = const {}});

  double? valeur(String axe) => valeurs[axe];

  /// Le même vin sur l'échelle du radar (0–10).
  double? sur10(String axe) => valeurs[axe] == null ? null : valeurs[axe]! * 10;

  /// Un vin de cave (ou bu dehors, saisi comme tel), le jour [le] (aujourd'hui sinon).
  ///
  /// Gardé par vin et par année (20/10) : le profil, la frontière et l'angle mort le
  /// recalculaient pour toute la cave à chaque affichage.
  static ProfilDuVin deLaCave(Wine wine, {DateTime? le}) {
    final annee = (le ?? DateTime.now()).year;
    final parAnnee = _deLaCave[wine] ??= <int, ProfilDuVin>{};
    return parAnnee[annee] ??= _calculerDeLaCave(wine, annee);
  }

  static final Expando<Map<int, ProfilDuVin>> _deLaCave = Expando('ProfilDuVin.deLaCave');

  static ProfilDuVin _calculerDeLaCave(Wine wine, int annee) {
    final famille = TasteProfile.familleDe(wine.type);
    if (famille == null) return const ProfilDuVin(famille: null, valeurs: {});
    final r = ProfilDuVinDeCave.estimer(wine, annee: annee);
    final cepages = [for (final g in wine.grapes) g.name];
    final douceur = DouceurDuVin.estimer(
      type: wine.type,
      nom: wine.name,
      appellation: wine.appellation,
      region: wine.region,
      pays: wine.country,
      classification: wine.classification,
      cepages: cepages,
    );
    final evolution = EvolutionDuVin.estimer(
      millesime: wine.vintage,
      annee: annee,
      type: wine.type,
      pays: wine.country,
      region: wine.region,
      appellation: wine.appellation,
      classification: wine.classification,
      nom: wine.name,
      producteur: wine.producer,
      cepages: cepages,
      debut: wine.drinkStart,
      fin: wine.drinkEnd,
      apogeeDebut: wine.peakStart,
      apogeeFin: wine.peakEnd,
    );
    return ProfilDuVin(
      famille: famille,
      valeurs: {
        AxesDuPalais.fraicheur: _sur1(r.acidity),
        AxesDuPalais.douceur: douceur.valeur,
        AxesDuPalais.corps: _sur1(r.body),
        if (famille == FamillesDeVins.rouge) AxesDuPalais.tanins: _sur1(r.tannin),
        AxesDuPalais.boise: _sur1(r.oak),
        if (evolution != null) AxesDuPalais.evolution: evolution,
      },
      surs: {
        if (douceur.sure) AxesDuPalais.douceur,
        if (evolution != null) AxesDuPalais.evolution,
      },
    );
  }

  /// Un vin de carte : ses métriques lues au scan, sa douceur écrite si elle l'est, son âge.
  static ProfilDuVin deLaCarte(MenuWine w, {DateTime? le}) {
    final famille = TasteProfile.familleDe(w.wineType);
    if (famille == null) return const ProfilDuVin(famille: null, valeurs: {});
    final annee = (le ?? DateTime.now()).year;
    final m = w.metrics;
    final ecrite = DouceurDuVin.estimer(
      type: w.wineType,
      nom: w.name,
      appellation: w.appellation,
      region: w.region,
      pays: w.country,
      cepages: w.grapes,
    );
    final evolution = EvolutionDuVin.estimer(
      millesime: w.vintage,
      annee: annee,
      type: w.wineType,
      pays: w.country,
      region: w.region,
      appellation: w.appellation,
      nom: w.name,
      producteur: w.producer,
      cepages: w.grapes,
    );
    return ProfilDuVin(
      famille: famille,
      valeurs: {
        AxesDuPalais.fraicheur: _sur1(m.acidity),
        // L'étiquette d'abord quand elle dit sa douceur ; la lecture du scan sinon.
        AxesDuPalais.douceur: ecrite.sure ? ecrite.valeur : _sur1(m.sweetness),
        AxesDuPalais.corps: _sur1(m.body),
        if (famille == FamillesDeVins.rouge && m.tannins > 0) AxesDuPalais.tanins: _sur1(m.tannins),
        AxesDuPalais.boise: _sur1(m.oak),
        if (evolution != null) AxesDuPalais.evolution: evolution,
      },
      surs: {
        if (ecrite.sure) AxesDuPalais.douceur,
        if (evolution != null) AxesDuPalais.evolution,
      },
    );
  }

  static double _sur1(double sur10) => (sur10 / 10).clamp(0.0, 1.0).toDouble();
}
