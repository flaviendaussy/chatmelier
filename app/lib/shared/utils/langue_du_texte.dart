/// La langue d'un texte de fiche (description, accords), sans appel à personne (V2.4 · R6).
///
/// Des mots outils propres à chaque langue, comptés : « the », « and », « with » ne sont
/// qu'anglais ; « les », « avec », « dans » que français. Les mots partagés (« la », « de »,
/// « con », « una ») ne comptent pour personne. Trop peu d'indices : on ne dit rien, et la
/// fiche reste telle quelle.
class LangueDuTexte {
  static const Map<String, Set<String>> _motsOutils = {
    'fr': {
      'les', 'des', 'du', 'et', 'avec', 'est', 'sur', 'dans', 'pour', 'aux', 'au', 'son', 'ses', 'qui', 'très',
      'bouche', 'nez', 'une', 'mais', 'notes', 'arômes', 'fruits',
    },
    'en': {
      'the', 'and', 'with', 'of', 'is', 'on', 'to', 'its', 'this', 'that', 'by', 'for', 'palate', 'nose',
      'finish', 'an', 'aromas', 'fruit', 'hints', 'roasted', 'grilled', 'cheese', 'cheeses',
    },
    'es': {
      'los', 'las', 'y', 'el', 'es', 'por', 'para', 'sus', 'que', 'muy', 'boca', 'nariz', 'como', 'aromas',
      'frutas', 'asado', 'queso', 'quesos',
    },
    'it': {
      'il', 'gli', 'e', 'di', 'della', 'dei', 'è', 'per', 'sua', 'suo', 'che', 'molto', 'bocca', 'naso', 'alla',
      'sono', 'frutta', 'arrosto', 'formaggi', 'formaggio', 'profumi',
    },
  };

  /// `fr`, `en`, `es` ou `it` ; nul si le texte est trop court ou trop mêlé pour le dire.
  static String? detecter(String? texte) {
    if (texte == null || texte.trim().isEmpty) return null;
    final mots = texte.toLowerCase().split(RegExp(r"[^a-zàâäáãçéèêëíìîïñóòôöõúùûüœ]+"));
    final scores = {for (final l in _motsOutils.keys) l: 0};
    for (final m in mots) {
      if (m.isEmpty) continue;
      for (final e in _motsOutils.entries) {
        if (e.value.contains(m)) scores[e.key] = scores[e.key]! + 1;
      }
    }
    final classes = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final premier = classes[0];
    final second = classes[1];
    if (premier.value < 2) return null;
    if (premier.value < 2 * second.value) return null;
    return premier.key;
  }
}
