import 'wine.dart';
import 'wine_service_advisor.dart';

/// Une correction d'apogée à réécrire en base.
class CorrectionApogee {
  final String wineId;
  final int? ancienDebut;
  final int? ancienneFin;
  final int nouveauDebut;
  final int nouvelleFin;
  final int nouveauPicDebut;
  final int nouveauPicFin;

  const CorrectionApogee({
    required this.wineId,
    required this.ancienDebut,
    required this.ancienneFin,
    required this.nouveauDebut,
    required this.nouvelleFin,
    required this.nouveauPicDebut,
    required this.nouveauPicFin,
  });

  /// De combien d'années la durée de vie change.
  int get ecartAnnees =>
      ((nouvelleFin - nouveauDebut) - ((ancienneFin ?? 0) - (ancienDebut ?? 0))).abs();

  Map<String, dynamic> get payload => {
        'ideal_drinking_start': nouveauDebut,
        'ideal_drinking_end': nouvelleFin,
        'peak_drinking_start': nouveauPicDebut,
        'peak_drinking_end': nouveauPicFin,
      };

  @override
  String toString() => '$wineId : $ancienDebut-$ancienneFin → '
      '$nouveauDebut-$nouvelleFin (pic $nouveauPicDebut-$nouveauPicFin)';
}

/// Corrige les apogées déjà écrites en base par l'enrichissement.
///
/// POURQUOI PAS UNE MIGRATION SQL
///
/// La logique de correction vit en Dart — quatre-vingt-dix régions, deux cent
/// soixante-dix-huit domaines, les rangs, l'enveloppe de plausibilité. La porter en SQL
/// créerait une seconde implémentation à maintenir, et les deux divergeraient dès la
/// première amélioration de la table. C'est exactement la dette qu'on vient de retirer
/// en unifiant les trois calculs de fenêtre.
///
/// La correction est donc appliquée **par l'app, au chargement de la cave**, avec le vrai
/// code. Elle profite à tout le monde : `wines` est un catalogue partagé, une fiche
/// corrigée pour l'un l'est pour tous ceux qui scanneront le même vin.
///
/// POURQUOI RÉÉCRIRE PLUTÔT QUE CORRIGER À LA LECTURE
///
/// L'app lit désormais tout à travers la correction, donc l'affichage est déjà juste sans
/// toucher à la base. Mais d'autres clients lisent ces colonnes directement — la version
/// web, les versions installées plus anciennes, les exports, le contexte envoyé au
/// sommelier IA. Tant que la donnée stockée est fausse, ils affichent faux.
class ApogeeBackfill {
  /// En deçà, l'écart ne justifie pas une écriture : on ne réécrit pas la base pour
  /// gagner un an sur une estimation qui reste une estimation.
  static const int ecartMinimalAnnees = 3;

  /// Ce qu'il faudrait corriger dans ce lot de vins.
  ///
  /// Ne renvoie que les écarts significatifs, et jamais les vins sans millésime — leur
  /// fenêtre n'a pas de sens à être figée.
  static List<CorrectionApogee> aCorriger(List<Wine> vins) {
    final corrections = <CorrectionApogee>[];
    for (final w in vins) {
      if (w.vintage == null) continue;
      // Les spiritueux et vins mutés ne suivent pas une apogée mais un niveau.
      if (w.tracksFillLevel) continue;

      final f = WineOenologyAdvisor.computeDrinkingWindow(
        wineType: w.type,
        vintage: w.vintage,
        country: w.country,
        region: w.region,
        appellation: w.appellation,
        classification: w.classification,
        wineName: w.name,
        producer: w.producer,
        grapes: w.grapes.map((g) => g.name).toList(),
        explicitDrinkStart: w.drinkStart,
        explicitDrinkEnd: w.drinkEnd,
        explicitPeakStart: w.peakStart,
        explicitPeakEnd: w.peakEnd,
      );

      // Rien à faire si la valeur stockée a été retenue telle quelle.
      if (w.drinkStart == f.drinkStart && w.drinkEnd == f.drinkEnd) continue;

      final c = CorrectionApogee(
        wineId: w.id,
        ancienDebut: w.drinkStart,
        ancienneFin: w.drinkEnd,
        nouveauDebut: f.drinkStart,
        nouvelleFin: f.drinkEnd,
        nouveauPicDebut: f.peakStart,
        nouveauPicFin: f.peakEnd,
      );

      // Une fenêtre absente est toujours corrigée : on passe de « rien » à « quelque
      // chose », ce qui vaut quel que soit l'écart.
      final absente = w.drinkStart == null || w.drinkEnd == null;
      if (absente || c.ecartAnnees >= ecartMinimalAnnees) {
        corrections.add(c);
      }
    }
    return corrections;
  }
}
