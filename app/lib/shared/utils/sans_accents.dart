/// Un texte en minuscules, sans accents ni signes diacritiques.
///
/// Les tables de référence écrivent leurs alias sans accents (« rias baixas »,
/// « lopez de heredia », « carinena »). Les normalisations locales ne repliaient que les
/// accents français : « Rías Baixas » devenait « r as baixas » et ne correspondait à
/// rien — aucun vin espagnol ou portugais accentué n'était reconnu (30/09).
String sansAccents(String texte) {
  final sortie = StringBuffer();
  for (final rune in texte.toLowerCase().runes) {
    final c = String.fromCharCode(rune);
    sortie.write(_replis[c] ?? c);
  }
  return sortie.toString();
}

const Map<String, String> _replis = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ñ': 'n', 'ç': 'c',
  'œ': 'oe', 'æ': 'ae', 'ß': 'ss',
  // Les apostrophes typographiques des étiquettes (« Duché d’Uzès »).
  '’': "'", 'ʼ': "'",
};
