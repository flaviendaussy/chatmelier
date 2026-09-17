import 'wine.dart';
import 'wine_world/wine_world.dart';

/// Un élevage à renseigner en base.
class CorrectionElevage {
  final String wineId;
  final String type;
  final int mois;
  final bool impose;

  const CorrectionElevage({
    required this.wineId,
    required this.type,
    required this.mois,
    required this.impose,
  });

  Map<String, dynamic> get payload => {
        'elevage_type': type,
        'elevage_months': mois,
      };

  @override
  String toString() => '$wineId : $type $mois mois${impose ? ' (imposé)' : ''}';
}

/// Renseigne l'élevage des vins déjà scannés.
///
/// **Il n'y avait rien à reprendre.** `barrel_aging` existait dans le modèle mais, sur
/// 79 vins réels, n'était renseigné aucune fois — la colonne n'était créée par aucune
/// migration et l'enrichissement ne la remplissait pas. Un backfill à partir des données
/// existantes n'avait donc aucune matière.
///
/// La source est ailleurs, et elle est meilleure : beaucoup d'appellations IMPOSENT une
/// durée d'élevage minimale. Un Barolo doit passer dix-huit mois sous bois, un Brunello
/// vingt-quatre, un Rioja Crianza douze. C'est déterministe, gratuit, et vérifiable —
/// là où une ré-interrogation de l'IA coûterait cher et resterait incertaine.
class ElevageBackfill {
  /// Ce qu'il faudrait renseigner dans ce lot.
  ///
  /// Ne touche jamais un élevage déjà renseigné : une valeur venue d'un domaine ou saisie
  /// à la main vaut mieux qu'une valeur de catégorie.
  static List<CorrectionElevage> aCompleter(List<Wine> vins) {
    final corrections = <CorrectionElevage>[];
    for (final w in vins) {
      if (w.elevageType != null && w.elevageMois != null) continue;

      final e = WineWorld.elevage(
        pays: w.country,
        region: w.region,
        appellation: w.appellation,
        nom: w.name,
        producteur: w.producer,
        type: w.type,
        cepages: w.grapes.map((g) => g.name).toList(),
      );
      if (e == null) continue;

      corrections.add(CorrectionElevage(
        wineId: w.id,
        type: e.contenant.name,
        mois: e.mois,
        impose: e.impose,
      ));
    }
    return corrections;
  }
}
