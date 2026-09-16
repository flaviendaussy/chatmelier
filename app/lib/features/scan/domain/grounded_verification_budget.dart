import 'package:shared_preferences/shared_preferences.dart';

/// Décide si l'on paie une seconde source pour lever une contradiction de région.
///
/// POURQUOI UN BUDGET, ET PAS SEULEMENT UNE CONDITION
///
/// Le `search grounding` coûte **0,035 $ forfaitaires par requête**, soit 119 fois le
/// coût en jetons de l'appel qui l'accompagne et 16 fois un scan de carte complet
/// (`ai_cost_event.dart`). C'est le premier poste de dépense du produit. Une garde qui
/// ne dépendrait que de « y a-t-il contradiction ? » suffirait en théorie, puisque la
/// détection est locale et rare — mais une régression de l'enrichissement, ou un cépage
/// dont le nom ressemble à une région, suffirait à la rendre systématique sans que rien
/// ne l'arrête.
///
/// Trois verrous, du moins cher au plus cher :
///
///  1. **La détection est locale et gratuite** (`RegionContradictionDetector`).
///  2. **Un vin déjà vérifié ne l'est jamais deux fois**, quelle que soit la réponse.
///  3. **Un plafond quotidien** borne le pire cas, même si les deux premiers cèdent.
///
/// Le plafond n'est pas là pour économiser en régime normal : il est là pour que le
/// régime anormal reste sans conséquence.
class GroundedVerificationBudget {
  static const String _clePrefixeVin = 'verif_region_vin_';
  static const String _cleJour = 'verif_region_jour';
  static const String _cleCompteur = 'verif_region_compteur';

  /// Vérifications groundées autorisées par jour et par appareil.
  ///
  /// Dimensionné sur l'usage réel : les six remontées utilisateurs reçues à ce jour
  /// contenaient **une** contradiction de région. Cinq laisse toute la marge nécessaire
  /// à un usage normal tout en plafonnant le coût à 0,175 $ par jour et par appareil
  /// dans le pire cas.
  static const int plafondQuotidien = 5;

  final SharedPreferences _prefs;
  GroundedVerificationBudget(this._prefs);

  static Future<GroundedVerificationBudget> ouvrir() async =>
      GroundedVerificationBudget(await SharedPreferences.getInstance());

  /// Clé stable d'un vin : le nom normalisé suffit, l'identifiant n'existe pas encore
  /// au moment de l'enrichissement.
  static String cleDe(String nomDuVin) =>
      '$_clePrefixeVin${nomDuVin.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

  bool dejaVerifie(String nomDuVin) => _prefs.getBool(cleDe(nomDuVin)) ?? false;

  int get consommeAujourdhui {
    if (_prefs.getString(_cleJour) != _aujourdhui()) return 0;
    return _prefs.getInt(_cleCompteur) ?? 0;
  }

  bool get plafondAtteint => consommeAujourdhui >= plafondQuotidien;

  /// Les trois verrous en une question.
  bool peutVerifier(String nomDuVin) =>
      !dejaVerifie(nomDuVin) && !plafondAtteint;

  /// À appeler une fois la vérification faite — **quelle qu'en soit l'issue**.
  ///
  /// Marquer même les échecs est délibéré : un vin dont la vérification n'a rien donné
  /// ne doit pas la relancer à chaque ouverture de sa fiche.
  Future<void> enregistrerVerification(String nomDuVin) async {
    await _prefs.setBool(cleDe(nomDuVin), true);
    final jour = _aujourdhui();
    if (_prefs.getString(_cleJour) != jour) {
      await _prefs.setString(_cleJour, jour);
      await _prefs.setInt(_cleCompteur, 1);
    } else {
      await _prefs.setInt(_cleCompteur, (_prefs.getInt(_cleCompteur) ?? 0) + 1);
    }
  }

  static String _aujourdhui() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
