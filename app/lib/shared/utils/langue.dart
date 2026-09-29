import 'package:flutter/widgets.dart';

/// La langue de l'écran, pour les textes écrits en dur en français et en anglais.
///
/// Des pans entiers de l'app n'existaient qu'en français, alors qu'une partie des
/// testeurs l'utilise en anglais (retour du 29/09). Beaucoup de ces textes vivent dans
/// des fonctions sans `BuildContext` (messages d'erreur, résumés) : `tr` lit donc une
/// langue tenue à jour par la racine de l'app (`MaterialApp.builder`, dans `app.dart`),
/// à chaque changement de langue.
///
/// Français par défaut, comme l'app : un écran monté hors de l'app (tests) garde ses
/// textes d'origine. Les autres langues de l'app retombent sur l'anglais, comme partout
/// où l'app choisit entre français et anglais.
class Langue {
  static bool estFr = true;

  static void definir(Locale locale) => estFr = locale.languageCode == 'fr';
}

/// Le texte dans la langue de l'écran.
String tr(String fr, String en) => Langue.estFr ? fr : en;

/// Un texte de référentiel (terroirs, accords…) : écrit en français dans ses données, il
/// a sa version anglaise dans une table à part, consultée seulement en anglais. Sans
/// traduction, le français plutôt que rien.
String trDonnee(String fr, Map<String, String> anglais) => Langue.estFr ? fr : (anglais[fr] ?? fr);
