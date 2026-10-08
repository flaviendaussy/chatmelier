/// Une capture jointe à un retour, telle que la console doit l'ouvrir (08/10).
///
/// Avant la migration 036 (retours du 6 au 16/09), la capture était écrite par son adresse
/// publique complète ; depuis, par son chemin dans le stockage privé `feedback`, que la
/// fonction `sign-feedback-capture` signe pour cinq minutes. La console envoyait l'adresse
/// ancienne à la fonction, qui cherchait un fichier nommé « https://… » et répondait 404 :
/// « Capture illisible … la fonction est-elle déployée ? », alors qu'elle l'était.
class CaptureDeRetour {
  /// Une adresse complète (ancien format) s'ouvre telle quelle.
  static bool estUneAdresse(String capture) =>
      capture.startsWith('https://') || capture.startsWith('http://');

  /// Pourquoi une capture ne s'ouvre pas, à partir de l'erreur de la fonction (statut,
  /// détails), en clair. La console est en français : elle n'est que pour Flavien.
  static String cause({required int? statut, Object? details}) {
    final texte = '${details ?? ''}';
    if (statut == 404 && (texte.contains('NOT_FOUND') || texte.contains('Requested function was not found'))) {
      return 'la fonction sign-feedback-capture n\'est pas déployée';
    }
    if (statut == 404) {
      return 'le fichier n\'existe plus : retiré par son auteur (« Mes retours envoyés ») ou effacé avec son compte';
    }
    if (statut == 401) return 'session expirée : reconnecte-toi';
    if (statut == 403) return 'réservé aux comptes administrateurs';
    if (statut == 400) return 'chemin de capture refusé ($texte)';
    if (statut == null) return texte.isEmpty ? 'réponse vide de la fonction' : texte;
    return 'erreur $statut${texte.isEmpty ? '' : ' : $texte'}';
  }
}
