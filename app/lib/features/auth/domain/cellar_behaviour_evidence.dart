import '../../cellar/domain/bottle.dart';

/// Signaux de préférence déjà présents en base, et que rien ne lisait.
///
/// Le modèle de goût n'apprenait jusqu'ici que de ce que les gens **déclarent** : une
/// note, des arômes cochés. Or une cave enregistre aussi ce qu'ils **font** — ce qu'ils
/// rachètent, ce qu'ils ouvrent tout de suite, ce qu'ils gardent. Ces gestes sont plus
/// coûteux que cocher une case, donc plus crédibles.
class CellarBehaviourEvidence {
  /// Origines qui ne disent rien du goût de la personne : voir
  /// `TasteProfileService.cellarGrapeStock`, qui applique la même exclusion.
  static const Set<String> _originesExclues = {'gift', 'supermarket'};

  /// Vins rachetés — le signal de préférence le plus fort qu'une cave puisse contenir.
  ///
  /// **Un rachat n'est pas une quantité.** Acheter six bouteilles d'un coup est UNE
  /// décision, prise avant d'avoir goûté ; y revenir six mois plus tard en est une
  /// seconde, prise en connaissance de cause. C'est cette seconde qui vaut quelque
  /// chose, et c'est pourquoi on compte des **actes d'achat distincts** et non des
  /// bouteilles.
  ///
  /// Deux lignes créées le même jour pour le même vin comptent donc pour un seul acte :
  /// c'est une saisie fractionnée, pas un rachat.
  static Set<String> vinsRachetes(List<Bottle> bottles) {
    final datesParVin = <String, Set<String>>{};

    for (final b in bottles) {
      if (_originesExclues.contains(b.sourceType)) continue;
      if (b.wineId.isEmpty) continue;
      // `purchaseDate` quand elle est renseignée, sinon la date de saisie : une cave
      // saisie au fil de l'eau garde l'information même sans date d'achat explicite.
      final d = b.purchaseDate ?? b.createdAt;
      final jour = '${d.year}-${d.month}-${d.day}';
      datesParVin.putIfAbsent(b.wineId, () => <String>{}).add(jour);
    }

    return datesParVin.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .toSet();
  }

  /// Délai entre l'acquisition d'une bouteille et son ouverture.
  static Duration? delaiAvantOuverture(Bottle b) {
    if (!b.isConsumed || b.consumedAt == null) return null;
    final acquise = b.purchaseDate ?? b.createdAt;
    final d = b.consumedAt!.difference(acquise);
    return d.isNegative ? null : d;
  }

  /// En deçà de ce délai, ouvrir une bouteille traduit une envie, pas un hasard.
  static const Duration seuilImpatience = Duration(days: 14);

  /// La bouteille a-t-elle été ouverte avec empressement ?
  ///
  /// Le signal inverse n'existe pas ici, et c'est délibéré : une bouteille gardée
  /// longtemps est **ambiguë**. Elle peut attendre son apogée — ce qui est une marque
  /// d'estime — ou être évitée. Rien dans les données ne permet de trancher, donc on
  /// n'en tire rien plutôt que d'inventer un dégoût.
  static bool ouverteAvecEmpressement(Bottle b) {
    final d = delaiAvantOuverture(b);
    return d != null && d <= seuilImpatience;
  }

  /// Les cépages que la personne a **rachetés**, avec leur nombre d'actes d'achat.
  static Map<String, int> cepagesRachetes(List<Bottle> bottles) {
    final rachetes = vinsRachetes(bottles);
    final compte = <String, int>{};
    final vinsVus = <String>{};

    for (final b in bottles) {
      if (!rachetes.contains(b.wineId)) continue;
      // Un vin racheté ne compte qu'une fois par cépage, quel que soit le nombre de
      // lignes : sinon une grosse commande ferait double emploi avec le rachat.
      if (!vinsVus.add(b.wineId)) continue;
      for (final g in b.wine?.grapes ?? const []) {
        final nom = g.name.trim();
        if (nom.isEmpty) continue;
        compte[nom] = (compte[nom] ?? 0) + 1;
      }
    }
    return compte;
  }

  /// Les régions rachetées, même logique.
  static Map<String, int> regionsRachetees(List<Bottle> bottles) {
    final rachetes = vinsRachetes(bottles);
    final compte = <String, int>{};
    final vinsVus = <String>{};

    for (final b in bottles) {
      if (!rachetes.contains(b.wineId)) continue;
      if (!vinsVus.add(b.wineId)) continue;
      final r = b.wine?.region.trim() ?? '';
      if (r.isEmpty || r == 'Autre') continue;
      compte[r] = (compte[r] ?? 0) + 1;
    }
    return compte;
  }
}
