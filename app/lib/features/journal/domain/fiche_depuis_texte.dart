/// Ce qu'une identification depuis un nom a le droit d'écrire dans la fiche d'une
/// dégustation (V2.4 · R1).
///
/// Le 07/10, l'étiquette d'un vin marocain (« S de Siroua ») était bien lue ; puis
/// « Détecter » sur le nom a réécrit la fiche en Côtes du Rhône. Une étiquette lue n'est
/// donc jamais écrasée : seuls ses champs vides se complètent. Sans étiquette, une nouvelle
/// détection remplace la précédente (on corrige un nom mal tapé), et efface ce que la
/// précédente avait mis et qu'elle ne confirme pas : rien d'un autre vin ne reste.
class FicheDepuisTexte {
  /// [actuels] : chaque champ tel qu'à l'écran ; [proposes] : ce que la détection a donné ;
  /// [remplisParLeTexte] : les champs que la détection précédente avait remplis.
  /// Rend les champs à écrire (une valeur vide efface).
  static Map<String, String> aEcrire({
    required Map<String, String> actuels,
    required Map<String, String?> proposes,
    required bool etiquetteLue,
    Set<String> remplisParLeTexte = const {},
  }) {
    final ecrire = <String, String>{};
    for (final cle in proposes.keys) {
      final propose = proposes[cle]?.trim() ?? '';
      final actuel = actuels[cle]?.trim() ?? '';
      if (etiquetteLue) {
        if (actuel.isEmpty && propose.isNotEmpty) ecrire[cle] = propose;
      } else if (propose.isNotEmpty) {
        ecrire[cle] = propose;
      } else if (remplisParLeTexte.contains(cle) && actuel.isNotEmpty) {
        ecrire[cle] = '';
      }
    }
    return ecrire;
  }
}
