import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
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

  /// Une fois par installation, dès qu'une session existe, avec d'où vient l'installation
  /// quand le Play Store le dit (V2.3 · K2).
  static Future<void> noterPremiereOuvertureSiBesoin() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_clePremiereOuverture) == true) return;
      if (!Supabase.instance.isInitialized || Supabase.instance.client.auth.currentUser == null) return;
      final origine = defaultTargetPlatform == TargetPlatform.android
          ? lireLeReferrer(await lireReferrerDuPlayStore())
          : (source: null, tableCode: null);
      await noter('premiere_ouverture', source: origine.source, tableCode: origine.tableCode);
      await prefs.setBool(_clePremiereOuverture, true);
    } catch (e) {
      AppLogger.debug('CROISSANCE', 'première ouverture non notée : $e');
    }
  }

  /// La chaîne que le Play Store a gardée du lien d'installation, ou rien (installation hors
  /// Play Store, service indisponible). Remplaçable dans les tests.
  @visibleForTesting
  static Future<String?> Function() lireReferrerDuPlayStore = _lireReferrer;

  static Future<String?> _lireReferrer() async {
    try {
      final details = await PlayInstallReferrer.installReferrer.timeout(const Duration(seconds: 5));
      return details.installReferrer;
    } catch (e) {
      AppLogger.debug('CROISSANCE', 'Install Referrer illisible : $e');
      return null;
    }
  }

  /// D'où vient une installation, lu dans le referrer du Play Store :
  /// « utm_source=page_invite&utm_campaign=K7M2QX » → page invité, table K7M2QX ;
  /// « utm_source=google-play&utm_medium=organic » → une recherche dans le Play Store.
  /// Bornée comme la table `evenements_croissance` : une source de 40 caractères au plus, un
  /// code de table seulement s'il en a la forme.
  static ({String? source, String? tableCode}) lireLeReferrer(String? referrer) {
    var brut = (referrer ?? '').trim();
    if (brut.isEmpty) return (source: null, tableCode: null);
    if (!brut.contains('=') && brut.contains('%3D')) {
      try {
        brut = Uri.decodeComponent(brut);
      } catch (_) {
        return (source: null, tableCode: null);
      }
    }
    Map<String, String> champs;
    try {
      champs = Uri.splitQueryString(brut);
    } catch (_) {
      return (source: null, tableCode: null);
    }
    final source = (champs['utm_source'] ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.\-]'), '');
    final code = (champs['utm_campaign'] ?? '').toUpperCase().trim();
    return (
      source: source.isEmpty ? null : (source.length > 40 ? source.substring(0, 40) : source),
      tableCode: RegExp(r'^[A-Z0-9]{6}$').hasMatch(code) ? code : null,
    );
  }

  /// Le lien du Play Store, avec d'où vient la personne : le Play Store le transmet à l'app
  /// installée (Install Referrer), qui le lit à sa première ouverture.
  static String lienPlayStore({required String source, String? tableCode}) {
    final referrer = Uri.encodeComponent('utm_source=$source&utm_campaign=${tableCode ?? ''}');
    return 'https://play.google.com/store/apps/details?id=com.chatmelier.chatmelier&referrer=$referrer';
  }
}
