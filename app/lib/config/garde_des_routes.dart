/// Qui va où, selon qu'il a un compte (V2.4 · R2).
///
/// L'app installée exige un vrai compte dès la première ouverture : le 07/10, des testeurs
/// l'utilisaient sans compte, par les parcours invités de l'accueil (scanner une carte,
/// rejoindre une table). La page web, elle, reste ouverte sans compte : c'est par elle
/// qu'arrivent les nouveaux. Une session anonyme n'est pas un compte.
class GardeDesRoutes {
  /// Les parcours qu'un invité sans compte peut suivre, sur le web seulement.
  static const parcoursInvites = ['/invite/', '/table', '/menu-match', '/scan/menu'];

  static bool estUneRouteDeConnexion(String chemin) => chemin == '/login' || chemin == '/register';

  static bool estUnParcoursInvite(String chemin) => parcoursInvites.any(chemin.startsWith);

  /// La redirection à faire, ou nul pour laisser passer.
  ///
  /// [chemin] : la route demandée ; [emplacement] : son adresse complète (avec ses
  /// paramètres), gardée dans `suite` pour y revenir une fois le compte créé — un invité qui
  /// ouvre le lien d'une table dans l'app retrouve sa table après s'être inscrit.
  static String? redirection({
    required bool web,
    required bool connecte,
    required String chemin,
    String? emplacement,
    String? suite,
  }) {
    final connexion = estUneRouteDeConnexion(chemin);
    if (!connecte) {
      if (connexion) return null;
      if (web && estUnParcoursInvite(chemin)) return null;
      if (!web && estUnParcoursInvite(chemin) && emplacement != null) {
        return '/login?suite=${Uri.encodeComponent(emplacement)}';
      }
      return '/login';
    }
    if (connexion) return suiteSure(suite) ?? '/';
    return null;
  }

  /// Une suite n'est suivie que vers une route de l'app, jamais vers une autre adresse.
  static String? suiteSure(String? suite) =>
      suite != null && suite.startsWith('/') && !suite.startsWith('//') ? suite : null;
}
