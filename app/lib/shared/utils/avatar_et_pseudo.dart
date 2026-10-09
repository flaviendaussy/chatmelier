/// Le pseudo et l'image d'un profil, rangés ensemble dans `profiles.avatar_url`.
///
/// La table de production n'a pas de colonne `username` : le pseudo voyage dans
/// `meta://?u=<pseudo>`, que la recherche des membres lit (`pseudo_du_profil`, 062). L'image
/// l'accompagne en `&avatar=` : jusqu'au 09/10, une vraie photo remplaçait le pseudo (on ne
/// trouvait plus la personne par son pseudo), et choisir son pseudo effaçait la photo.
/// Jamais le téléphone ni l'e-mail : `profiles` est lisible par tous.
class AvatarEtPseudo {
  const AvatarEtPseudo._();

  /// L'image à afficher (adresse http, `emoji:`, `data:image`), ou nulle.
  static String? image(String? brut) {
    final b = brut?.trim();
    if (b == null || b.isEmpty) return null;
    if (!b.startsWith('meta://')) return b;
    final image = _parametres(b)['avatar']?.trim();
    return (image == null || image.isEmpty || image.startsWith('meta://')) ? null : image;
  }

  /// Le pseudo rangé dans `meta://`, ou nul.
  static String? pseudo(String? brut) {
    final b = brut?.trim();
    if (b == null || !b.startsWith('meta://')) return null;
    final p = _parametres(b)['u']?.trim();
    return (p == null || p.isEmpty) ? null : p;
  }

  /// Ce qu'on écrit dans `avatar_url` : le pseudo et l'image ensemble, l'image seule sans
  /// pseudo, ou rien du tout.
  static String? composer({String? pseudo, String? image}) {
    final p = pseudo?.replaceAll('@', '').trim().toLowerCase();
    final i = AvatarEtPseudo.image(image);
    if (p == null || p.isEmpty) return i;
    return 'meta://?u=${Uri.encodeComponent(p)}${i == null ? '' : '&avatar=${Uri.encodeComponent(i)}'}';
  }

  static Map<String, String> _parametres(String meta) {
    try {
      final requete = meta.contains('?') ? meta.substring(meta.indexOf('?') + 1) : meta.substring('meta://'.length);
      return Uri.splitQueryString(requete);
    } catch (_) {
      return const {};
    }
  }
}
