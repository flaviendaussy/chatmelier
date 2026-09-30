import 'package:shared_preferences/shared_preferences.dart';

/// Quand montrer une vidéo récompensée (V2.3 · G2, décision du 30/09 : « moins de pub »).
///
/// La vidéo tombait au pire moment : à chacun des 150 scans d'une première mise en cave,
/// avant un import Excel, au lancement de l'app. Elle reste là où elle finance ce qu'elle
/// coûte et où elle ne gêne personne : pendant l'analyse d'une carte par l'hôte, et sur les
/// scans d'étiquette au-delà de l'inventaire de départ.
class PolitiquePub {
  /// Le premier inventaire se fait sans vidéo.
  static const scansDInventaireSansPub = 30;

  static bool doitMontrer({
    required String emplacement,
    required bool premium,
    int scansEtiquetteDejaFaits = 0,
  }) {
    if (premium) return false;
    switch (emplacement) {
      case 'scan_etiquette':
        return scansEtiquetteDejaFaits >= scansDInventaireSansPub;
      case 'scan_carte':
        return true;
      case 'import_excel':
        return false;
      default:
        return false;
    }
  }

  static String _cle(String? uid) => 'scans_etiquette_${uid ?? 'appareil'}';

  /// Combien d'étiquettes ce compte a déjà scannées sur cet appareil.
  static Future<int> scansEtiquette(String? uid) async {
    try {
      return (await SharedPreferences.getInstance()).getInt(_cle(uid)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> compterUnScanEtiquette(String? uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cle(uid), (prefs.getInt(_cle(uid)) ?? 0) + 1);
    } catch (_) {
      // Sans stockage, on ne compte pas : au pire, une vidéo de moins.
    }
  }
}
