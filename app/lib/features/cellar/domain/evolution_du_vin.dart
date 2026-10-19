import 'wine_service_advisor.dart';

/// Où en était un vin le jour où on l'a goûté, de 0 (tout jeune, sur le fruit) à 1 (très
/// évolué : cuir, sous-bois, fruits secs) (V2.6 · P3).
///
/// Lu sur sa fenêtre de garde — celle que dessine la courbe de la fiche — plutôt que sur
/// son seul âge : un Beaujolais de cinq ans est mûr, un Barolo du même âge encore jeune.
/// Sans millésime, on ne sait pas : nul.
class EvolutionDuVin {
  static double? estimer({
    required int? millesime,
    required int annee,
    String? type,
    String? pays,
    String? region,
    String? appellation,
    String? classification,
    String? nom,
    String? producteur,
    List<String> cepages = const [],
    int? debut,
    int? fin,
    int? apogeeDebut,
    int? apogeeFin,
  }) {
    if (millesime == null || millesime <= 0) return null;
    final f = WineOenologyAdvisor.computeDrinkingWindow(
      wineType: type,
      vintage: millesime,
      country: pays,
      region: region,
      appellation: appellation,
      classification: classification,
      wineName: nom,
      producer: producteur,
      grapes: cepages,
      explicitDrinkStart: debut,
      explicitDrinkEnd: fin,
      explicitPeakStart: apogeeDebut,
      explicitPeakEnd: apogeeFin,
    );
    return surLaFenetre(annee: annee, millesime: millesime, debut: f.drinkStart, apogeeDebut: f.peakStart, apogeeFin: f.peakEnd, fin: f.drinkEnd);
  }

  /// La même lecture, la fenêtre étant connue : avant d'être prêt 0,05 à 0,25 ; en montée
  /// vers l'apogée 0,25 à 0,45 ; à l'apogée 0,45 à 0,65 ; sur le déclin 0,65 à 0,85 ;
  /// au-delà 0,85 à 1.
  static double surLaFenetre({
    required int annee,
    required int millesime,
    required int debut,
    required int apogeeDebut,
    required int apogeeFin,
    required int fin,
  }) {
    double part(num x, num a, num b) => b <= a ? 1.0 : ((x - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    if (annee <= debut) return 0.05 + 0.20 * part(annee, millesime, debut);
    if (annee <= apogeeDebut) return 0.25 + 0.20 * part(annee, debut, apogeeDebut);
    if (annee <= apogeeFin) return 0.45 + 0.20 * part(annee, apogeeDebut, apogeeFin);
    if (annee <= fin) return 0.65 + 0.20 * part(annee, apogeeFin, fin);
    final demiVie = ((fin - millesime) / 2).clamp(2, 40);
    return (0.85 + 0.15 * part(annee, fin, fin + demiVie)).clamp(0.0, 1.0).toDouble();
  }
}
