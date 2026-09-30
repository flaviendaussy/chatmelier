import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';
import 'envoi_par_lots.dart';

/// Ce qui mène un invité web jusqu'à l'app (V2.3 · J6) : table `evenements_croissance`
/// (migration 053), sans donnée personnelle. La console en fait le compte et le rapporte au
/// coût de l'IA sur le web (admin_croissance).
class Croissance {
  static const _clePremiereOuverture = 'croissance_premiere_ouverture_notee';

  static Future<void> noter(String type, {String? source, String? tableCode}) async {
    try {
      if (!Supabase.instance.isInitialized) return;
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) return;
      await client.from('evenements_croissance').insert({
        'type': type,
        if (source != null) 'source': source,
        if (tableCode != null) 'table_code': tableCode,
        'plateforme': EnvoiParLots.plateforme,
        'app_version': versionApp,
      });
    } catch (e) {
      // Migration 053 absente, réseau coupé : la mesure ne doit rien empêcher.
      AppLogger.debug('CROISSANCE', '$type non noté : $e');
    }
  }

  /// Une fois par installation, dès qu'une session existe.
  static Future<void> noterPremiereOuvertureSiBesoin() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_clePremiereOuverture) == true) return;
      if (!Supabase.instance.isInitialized || Supabase.instance.client.auth.currentUser == null) return;
      await noter('premiere_ouverture');
      await prefs.setBool(_clePremiereOuverture, true);
    } catch (e) {
      AppLogger.debug('CROISSANCE', 'première ouverture non notée : $e');
    }
  }

  /// Le lien du Play Store, avec d'où vient la personne : le Play Store le transmet à l'app
  /// installée (Install Referrer), que l'app pourra lire une fois la dépendance ajoutée.
  static String lienPlayStore({required String source, String? tableCode}) {
    final referrer = Uri.encodeComponent('utm_source=$source&utm_campaign=${tableCode ?? ''}');
    return 'https://play.google.com/store/apps/details?id=com.chatmelier.chatmelier&referrer=$referrer';
  }
}
