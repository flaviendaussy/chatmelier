import 'package:flutter/widgets.dart';

import '../langues/catalogues.dart';

/// La langue de l'écran, pour les textes écrits dans le code (V2.3 · H1).
///
/// Chaque texte de l'app est écrit en français et en anglais, au plus près de l'écran qui
/// l'affiche : `tr('Soirée retrouvée', 'Evening recovered')`. Les autres langues vivent
/// dans des catalogues indexés par la phrase française (`lib/shared/langues/`, générés
/// depuis `l10n_catalogues/<langue>.json` par `tool/langues/generer.py`) : ajouter une
/// langue, c'est ajouter un catalogue, sans toucher aux écrans. Une phrase absente d'un
/// catalogue s'affiche en anglais.
///
/// Beaucoup de ces textes vivent dans des fonctions sans `BuildContext` (messages
/// d'erreur, résumés) : `tr` lit donc une langue tenue à jour par la racine de l'app
/// (`MaterialApp.builder`, dans `app.dart`), à chaque changement de langue.
///
/// Français par défaut, comme l'app : un écran monté hors de l'app (tests) garde ses
/// textes d'origine.
class Langue {
  /// Les langues que l'app parle. Toute autre langue du téléphone reçoit l'anglais.
  static const supportees = ['fr', 'en', 'es', 'it'];

  static String code = 'fr';

  static bool get estFr => code == 'fr';

  /// Pour les essais, qui basculaient entre français et anglais avant l'espagnol.
  static set estFr(bool fr) => code = fr ? 'fr' : 'en';

  static void definir(Locale locale) =>
      code = supportees.contains(locale.languageCode) ? locale.languageCode : 'en';
}

/// Le résultat de [calcul] rédigé dans la langue [code] plutôt que dans celle de l'écran :
/// le résultat d'une table, publié pour des convives qui ne lisent pas la langue de l'hôte.
///
/// Le calcul doit être synchrone : la langue de l'app est rétablie dès qu'il rend la main.
T dansLaLangue<T>(String code, T Function() calcul) {
  final avant = Langue.code;
  Langue.code = code;
  try {
    return calcul();
  } finally {
    Langue.code = avant;
  }
}

final _marque = RegExp(r'\{(\w+)\}');

/// Remplit les {marques} d'un modèle : `remplir('{n} vins', {'n': 3})` → « 3 vins ».
/// Une marque sans valeur reste telle quelle, pour se voir plutôt que disparaître.
String remplir(String modele, Map<String, Object?> valeurs) {
  if (valeurs.isEmpty) return modele;
  return modele.replaceAllMapped(_marque, (m) => valeurs.containsKey(m[1]) ? '${valeurs[m[1]]}' : m[0]!);
}

String _horsFrancais(String fr, String en) {
  final code = Langue.code;
  if (code == 'fr' || code == 'en') return en;
  return catalogues[code]?[fr] ?? en;
}

/// Le texte dans la langue de l'écran. [fr] sert aussi de clé aux catalogues des autres
/// langues ; les {marques} du texte choisi sont remplies par [valeurs].
String tr(String fr, String en, [Map<String, Object?> valeurs = const {}]) =>
    remplir(Langue.code == 'fr' ? fr : _horsFrancais(fr, en), valeurs);

/// Pour les écrans qui reçoivent leur langue en paramètre (`isFr`) : le français si [fr],
/// sinon la langue de l'app hors du français (l'anglais par défaut).
String trSi(bool fr, String textFr, String textEn, [Map<String, Object?> valeurs = const {}]) =>
    remplir(fr ? textFr : _horsFrancais(textFr, textEn), valeurs);

/// Un texte de référentiel (terroirs, accords…) : écrit en français dans ses données, il a
/// sa version anglaise dans une table à part, et ses autres langues dans les catalogues.
/// Sans traduction, l'anglais, puis le français plutôt que rien.
String trDonnee(String fr, Map<String, String> anglais) {
  switch (Langue.code) {
    case 'fr':
      return fr;
    case 'en':
      return anglais[fr] ?? fr;
    default:
      return catalogues[Langue.code]?[fr] ?? anglais[fr] ?? fr;
  }
}

/// Une phrase déclarée d'avance en deux langues (énumérations, listes de suggestions) : le
/// français sert de clé aux catalogues, comme pour [tr]. Garder la paire côte à côte dans
/// le code permet à `tool/langues/extraire.py` de la retrouver.
/// Comme [trDonnee], mais la langue est donnée, comme pour [trSi] : `fr` choisit le
/// français ; sinon la langue de l'app si ce n'est pas le français, et l'anglais sinon.
String trDonneeSi(bool fr, String texteFr, Map<String, String> anglais) {
  if (fr) return texteFr;
  final code = Langue.code;
  if (code == 'fr' || code == 'en') return anglais[texteFr] ?? texteFr;
  return catalogues[code]?[texteFr] ?? anglais[texteFr] ?? texteFr;
}

/// Le code de langue d'un paramètre hérité, booléen (« en français ? ») ou code.
/// Un booléen faux désigne la langue de l'app quand ce n'est pas le français, sinon l'anglais.
String codeDeLangue(Object? lang) {
  if (lang is bool) return lang ? 'fr' : (Langue.code == 'fr' ? 'en' : Langue.code);
  return (lang?.toString() ?? 'en').toLowerCase();
}

class Phrase {
  final String fr;
  final String en;

  const Phrase(this.fr, this.en);

  /// Dans la langue de l'app.
  String get texte => tr(fr, en);

  /// Pour un écran qui reçoit sa langue en paramètre.
  String dans(bool enFrancais) => trSi(enFrancais, fr, en);
}
