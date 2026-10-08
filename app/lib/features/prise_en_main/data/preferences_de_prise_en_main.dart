import 'package:shared_preferences/shared_preferences.dart';

import '../domain/astuces.dart';

/// Ce que le téléphone retient de la prise en main (R10) : rien ne part au serveur.
class PreferencesDePriseEnMain {
  static const _cleGuideVu = 'prise_en_main_guide_vu_v1';
  static const _cleAstucesActives = 'prise_en_main_astuces_actives_v1';
  static const _cleAstucesVues = 'prise_en_main_astuces_vues_v1';

  static Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> guideVu() async => (await _prefs())?.getBool(_cleGuideVu) ?? false;

  static Future<void> marquerLeGuideVu() async => (await _prefs())?.setBool(_cleGuideVu, true);

  /// « Le saviez-vous ? » à l'ouverture : oui par défaut ; « Ne plus afficher » d'un geste,
  /// réactivable dans Profil → Réglages.
  static Future<bool> astucesActives() async => (await _prefs())?.getBool(_cleAstucesActives) ?? true;

  static Future<void> activerLesAstuces(bool oui) async => (await _prefs())?.setBool(_cleAstucesActives, oui);

  /// L'astuce à montrer maintenant, et sa rotation retenue : jamais la même deux fois tant
  /// que le tour n'est pas fini.
  static Future<Astuce> prochaineAstuce() async {
    final prefs = await _prefs();
    final r = Astuces.suivante(prefs?.getStringList(_cleAstucesVues) ?? const []);
    await prefs?.setStringList(_cleAstucesVues, r.vues);
    return r.astuce;
  }
}
