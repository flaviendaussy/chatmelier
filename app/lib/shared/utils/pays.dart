import 'langue.dart';

/// Les pays du vin et des spiritueux, reconnus sous tous leurs noms et rendus dans la
/// langue de l'écran (V2.4 · R6).
///
/// Le pays d'un vin est rangé tel qu'il a été lu : « Spain » quand l'étiquette a été lue par
/// un téléphone réglé en anglais, « Espagne » par un autre. La cave de Caro, en français,
/// montrait « Spain », « Portugal », « New Zealand » (04/10), et deux bouteilles d'un même
/// pays pouvaient tomber dans deux groupes. Un nom inconnu de la table s'affiche tel quel :
/// rien n'est deviné.
class Pays {
  /// [fr, en, es, it, autres noms connus…], par code (ISO 3166, ou les nations du
  /// Royaume-Uni, qui ont leurs whiskies et leurs vins).
  static const Map<String, List<String>> _noms = {
    'FR': ['France', 'France', 'Francia', 'Francia'],
    'IT': ['Italie', 'Italy', 'Italia', 'Italia'],
    'ES': ['Espagne', 'Spain', 'España', 'Spagna', 'Espanya'],
    'PT': ['Portugal', 'Portugal', 'Portugal', 'Portogallo'],
    'DE': ['Allemagne', 'Germany', 'Alemania', 'Germania', 'Deutschland'],
    'AT': ['Autriche', 'Austria', 'Austria', 'Austria', 'Österreich'],
    'CH': ['Suisse', 'Switzerland', 'Suiza', 'Svizzera', 'Schweiz'],
    'HU': ['Hongrie', 'Hungary', 'Hungría', 'Ungheria', 'Magyarország'],
    'GR': ['Grèce', 'Greece', 'Grecia', 'Grecia', 'Hellas'],
    'GE': ['Géorgie', 'Georgia', 'Georgia', 'Georgia', 'Sakartvelo'],
    'LB': ['Liban', 'Lebanon', 'Líbano', 'Libano'],
    'IL': ['Israël', 'Israel', 'Israel', 'Israele'],
    'MA': ['Maroc', 'Morocco', 'Marruecos', 'Marocco'],
    'TN': ['Tunisie', 'Tunisia', 'Túnez', 'Tunisia'],
    'DZ': ['Algérie', 'Algeria', 'Argelia', 'Algeria'],
    'ZA': ['Afrique du Sud', 'South Africa', 'Sudáfrica', 'Sudafrica'],
    'US': ['États-Unis', 'United States', 'Estados Unidos', 'Stati Uniti', 'USA', 'US', 'U.S.A.',
        'United States of America', 'Etats Unis'],
    'CA': ['Canada', 'Canada', 'Canadá', 'Canada'],
    'MX': ['Mexique', 'Mexico', 'México', 'Messico'],
    'CL': ['Chili', 'Chile', 'Chile', 'Cile'],
    'AR': ['Argentine', 'Argentina', 'Argentina', 'Argentina'],
    'UY': ['Uruguay', 'Uruguay', 'Uruguay', 'Uruguay'],
    'BR': ['Brésil', 'Brazil', 'Brasil', 'Brasile'],
    'PE': ['Pérou', 'Peru', 'Perú', 'Perù'],
    'AU': ['Australie', 'Australia', 'Australia', 'Australia'],
    'NZ': ['Nouvelle-Zélande', 'New Zealand', 'Nueva Zelanda', 'Nuova Zelanda', 'Aotearoa'],
    'GB': ['Royaume-Uni', 'United Kingdom', 'Reino Unido', 'Regno Unito', 'UK', 'Great Britain',
        'Grande-Bretagne'],
    'GB-ENG': ['Angleterre', 'England', 'Inglaterra', 'Inghilterra'],
    'GB-SCT': ['Écosse', 'Scotland', 'Escocia', 'Scozia'],
    'GB-WLS': ['Pays de Galles', 'Wales', 'Gales', 'Galles'],
    'IE': ['Irlande', 'Ireland', 'Irlanda', 'Irlanda', 'Éire'],
    'SI': ['Slovénie', 'Slovenia', 'Eslovenia', 'Slovenia', 'Slovenija'],
    'HR': ['Croatie', 'Croatia', 'Croacia', 'Croazia', 'Hrvatska'],
    'RO': ['Roumanie', 'Romania', 'Rumanía', 'Romania', 'România'],
    'BG': ['Bulgarie', 'Bulgaria', 'Bulgaria', 'Bulgaria'],
    'MD': ['Moldavie', 'Moldova', 'Moldavia', 'Moldavia'],
    'TR': ['Turquie', 'Turkey', 'Turquía', 'Turchia', 'Türkiye'],
    'CY': ['Chypre', 'Cyprus', 'Chipre', 'Cipro'],
    'CN': ['Chine', 'China', 'China', 'Cina'],
    'JP': ['Japon', 'Japan', 'Japón', 'Giappone'],
    'IN': ['Inde', 'India', 'India', 'India'],
    'TW': ['Taïwan', 'Taiwan', 'Taiwán', 'Taiwan'],
    'LU': ['Luxembourg', 'Luxembourg', 'Luxemburgo', 'Lussemburgo'],
    'CZ': ['Tchéquie', 'Czechia', 'Chequia', 'Cechia', 'Czech Republic', 'République tchèque'],
    'SK': ['Slovaquie', 'Slovakia', 'Eslovaquia', 'Slovacchia'],
    'RS': ['Serbie', 'Serbia', 'Serbia', 'Serbia'],
    'MK': ['Macédoine du Nord', 'North Macedonia', 'Macedonia del Norte', 'Macedonia del Nord', 'Macedonia'],
    'AM': ['Arménie', 'Armenia', 'Armenia', 'Armenia'],
    'UA': ['Ukraine', 'Ukraine', 'Ucrania', 'Ucraina'],
    'BE': ['Belgique', 'Belgium', 'Bélgica', 'Belgio'],
    'NL': ['Pays-Bas', 'Netherlands', 'Países Bajos', 'Paesi Bassi', 'Holland', 'Hollande'],
    'DK': ['Danemark', 'Denmark', 'Dinamarca', 'Danimarca'],
    'SE': ['Suède', 'Sweden', 'Suecia', 'Svezia'],
    'PL': ['Pologne', 'Poland', 'Polonia', 'Polonia'],
    'RU': ['Russie', 'Russia', 'Rusia', 'Russia'],
    'JM': ['Jamaïque', 'Jamaica', 'Jamaica', 'Giamaica'],
    'CU': ['Cuba', 'Cuba', 'Cuba', 'Cuba'],
    'BB': ['Barbade', 'Barbados', 'Barbados', 'Barbados'],
    'DO': ['République dominicaine', 'Dominican Republic', 'República Dominicana', 'Repubblica Dominicana'],
    'TT': ['Trinité-et-Tobago', 'Trinidad and Tobago', 'Trinidad y Tobago', 'Trinidad e Tobago'],
    'GY': ['Guyana', 'Guyana', 'Guyana', 'Guyana'],
    'VE': ['Venezuela', 'Venezuela', 'Venezuela', 'Venezuela'],
    'GT': ['Guatemala', 'Guatemala', 'Guatemala', 'Guatemala'],
    'MQ': ['Martinique', 'Martinique', 'Martinica', 'Martinica'],
    'GP': ['Guadeloupe', 'Guadeloupe', 'Guadalupe', 'Guadalupa'],
  };

  static const _drapeauxParticuliers = {
    'GB-ENG': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
    'GB-SCT': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
    'GB-WLS': '🏴󠁧󠁢󠁷󠁬󠁳󠁿',
  };

  static final Map<String, String> _parNom = {
    for (final e in _noms.entries)
      for (final nom in e.value) _cle(nom): e.key,
  };

  /// Minuscules, sans accents, sans ponctuation ni espaces superflus.
  static String _cle(String brut) {
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e',
      'ë': 'e', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', 'ó': 'o', 'ò': 'o', 'ô': 'o',
      'ö': 'o', 'õ': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ș': 's', 'ş': 's', 'ț': 't',
    };
    final b = StringBuffer();
    for (final r in brut.toLowerCase().trim().runes) {
      final c = String.fromCharCode(r);
      b.write(accents[c] ?? c);
    }
    return b
        .toString()
        .replaceAll(RegExp(r'[.\-_]'), ' ')
        .replaceAll(RegExp(r'^the\s+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Le code du pays nommé [brut], dans n'importe quelle langue connue ; nul s'il est inconnu.
  static String? code(String? brut) {
    if (brut == null || brut.trim().isEmpty) return null;
    return _parNom[_cle(brut)];
  }

  /// Le nom du pays dans la langue de l'écran ; tel quel s'il est inconnu, vide s'il manque.
  static String nom(String? brut, [String? langue]) {
    final c = code(brut);
    if (c == null) return brut?.trim() ?? '';
    final noms = _noms[c]!;
    return switch (langue ?? Langue.code) {
      'fr' => noms[0],
      'es' => noms[2],
      'it' => noms[3],
      _ => noms[1],
    };
  }

  /// Le drapeau du pays, ou 🌍 s'il est inconnu.
  static String drapeau(String? brut) {
    final c = code(brut);
    if (c == null) return '🌍';
    final particulier = _drapeauxParticuliers[c];
    if (particulier != null) return particulier;
    return String.fromCharCodes(c.codeUnits.map((u) => 0x1F1E6 + u - 0x41));
  }
}
