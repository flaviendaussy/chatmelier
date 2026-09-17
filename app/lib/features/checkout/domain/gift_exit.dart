/// Ce qu'on fait des dégustations quand on offre une bouteille.
enum SuiteDuCadeau {
  /// La bouteille part, et on n'en reparle plus. Aucune relance, aucune note.
  aucuneSuite,

  /// Elle sera peut-être ouverte en notre présence : on redemande plus tard.
  redemanderPlusTard,
}

/// Une sortie de cave qui n'est pas une dégustation.
///
/// **Pourquoi ce n'est pas un détail.** Offrir une bouteille passait jusqu'ici par l'écran
/// de dégustation, qui réclame une note. On notait donc un vin qu'on n'avait pas bu, et
/// cette note allait nourrir le profil de goût : le modèle apprenait un palais à partir
/// d'un cadeau. Le plan prévoyait d'exclure les bouteilles REÇUES en cadeau du modèle ;
/// celles qu'on donne posaient exactement le même problème, à l'envers.
class SortieCadeau {
  /// À qui. Texte libre : le destinataire n'a pas de compte, et en exiger un ferait de
  /// l'offrande une invitation.
  final String destinataire;

  /// Combien d'exemplaires quittent la cave.
  final int quantite;

  final SuiteDuCadeau suite;

  /// Dans combien de temps redemander, quand on a choisi de redemander.
  ///
  /// Un mois : assez loin pour que l'occasion ait eu lieu, assez proche pour qu'on s'en
  /// souvienne. Relancer le lendemain d'un cadeau serait absurde ; relancer six mois plus
  /// tard ne servirait plus à rien.
  static const Duration delaiDeRelance = Duration(days: 30);

  const SortieCadeau({
    required this.destinataire,
    required this.quantite,
    required this.suite,
  });

  bool get valide => destinataire.trim().isNotEmpty && quantite >= 1;
}
