import '../../../shared/utils/langue.dart';

/// Le rapport qualité-prix d'une bouteille (V2.3, « plus tard », fait le 08/10) : le prix
/// payé comparé à une cote SOURCÉE, relevée sur une page par la recherche (B3).
///
/// Sans cote sourcée, pas de verdict : rien d'affirmé sans preuve. Une valeur saisie par la
/// personne elle-même ne juge pas son propre achat.
enum VerdictQualitePrix {
  bonneAffaire,
  justePrix,
  auDessus;

  /// Au moins 20 % sous la cote : une bonne affaire ; au moins 15 % au-dessus : payée
  /// au-dessus de sa cote ; entre les deux, le juste prix.
  static VerdictQualitePrix? depuis({double? prixPaye, double? cote, required bool coteSourcee}) {
    if (!coteSourcee || prixPaye == null || cote == null || prixPaye <= 0 || cote <= 0) return null;
    final rapport = cote / prixPaye;
    if (rapport >= 1.25) return bonneAffaire;
    if (rapport <= 1 / 1.15) return auDessus;
    return justePrix;
  }

  /// [prix] met un montant en forme, dans la devise de la bouteille.
  String phrase(double prixPaye, double cote, String Function(double) prix) {
    final v = {'paye': prix(prixPaye), 'cote': prix(cote)};
    return switch (this) {
      VerdictQualitePrix.bonneAffaire =>
        tr('Bonne affaire : payée {paye}, cotée {cote}.', 'Good deal: paid {paye}, valued at {cote}.', v),
      VerdictQualitePrix.justePrix =>
        tr('Payée au juste prix : {paye}, cotée {cote}.', 'Paid a fair price: {paye}, valued at {cote}.', v),
      VerdictQualitePrix.auDessus =>
        tr('Payée au-dessus de sa cote : {paye}, cotée {cote}.', 'Paid above its value: {paye}, valued at {cote}.', v),
    };
  }
}
