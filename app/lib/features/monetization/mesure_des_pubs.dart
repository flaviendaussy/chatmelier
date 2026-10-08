import 'package:uuid/uuid.dart';

import '../../shared/services/envoi_par_lots.dart';
import '../../shared/utils/app_logger.dart';

/// Chaque pub affichée, comptée côté serveur (S5).
///
/// Jusqu'ici une pub ne laissait qu'un horodatage anti-spam dans le téléphone : on ne
/// pouvait pas dire si la pub paie l'IA. Le revenu se calcule ensuite côté console, à
/// partir d'un eCPM estimé (`app_config.ecpm_eur_estime`).
class MesureDesPubs {
  static final EnvoiParLots _envoi = EnvoiParLots(
    table: 'ad_impressions',
    cleLocale: 'chatmelier_pubs_a_envoyer_v1',
  );

  /// Ce que chaque impression a rapporté, selon Google (`onPaidEvent`, migration 065) :
  /// le revenu réel remplace, dans la console, l'estimation par eCPM saisi à la main.
  static final EnvoiParLots _revenus = EnvoiParLots(
    table: 'ad_revenus',
    cleLocale: 'chatmelier_revenus_pub_a_envoyer_v1',
  );

  /// [format] : `rewarded`, `app_open`… ; [emplacement] : où la pub est apparue
  /// (`scan_carte`, `scan_etiquette`, `ouverture`…). [id] relie l'impression à son paiement.
  static Future<void> impression({required String format, required String emplacement, String? id}) =>
      _envoi.ajouter({
        'event_id': id ?? const Uuid().v4(),
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
        'platform': EnvoiParLots.plateforme,
        'app_version': versionApp,
        'build_mode': EnvoiParLots.modeDeBuild,
        'ad_format': format,
        'placement': emplacement,
      });

  /// Le paiement d'une impression : [valeurMicros] dans la [devise] du compte AdMob, avec la
  /// [precision] que Google donne (`precise`, `estimated`, `publisher_provided`, `unknown`).
  /// Un montant illisible n'est pas envoyé.
  static Future<void> revenu({
    required String impressionId,
    required String format,
    required String emplacement,
    required double valeurMicros,
    required String precision,
    required String devise,
  }) async {
    final ligne = ligneDeRevenu(
      impressionId: impressionId,
      format: format,
      emplacement: emplacement,
      valeurMicros: valeurMicros,
      precision: precision,
      devise: devise,
    );
    if (ligne == null) {
      AppLogger.info('ADMOB', 'Paiement illisible ignoré : $valeurMicros $devise ($precision)');
      return;
    }
    await _revenus.ajouter(ligne);
  }

  /// La ligne `ad_revenus`, ou nulle si le montant ou la devise sont illisibles.
  static Map<String, dynamic>? ligneDeRevenu({
    required String impressionId,
    required String format,
    required String emplacement,
    required double valeurMicros,
    required String precision,
    required String devise,
    DateTime? maintenant,
  }) {
    final code = devise.trim().toUpperCase();
    if (valeurMicros.isNaN || valeurMicros < 0 || valeurMicros >= 1e8 || !RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      return null;
    }
    return {
      'event_id': const Uuid().v4(),
      'impression_id': impressionId,
      'occurred_at': (maintenant ?? DateTime.now()).toUtc().toIso8601String(),
      'platform': EnvoiParLots.plateforme,
      'app_version': versionApp,
      'build_mode': EnvoiParLots.modeDeBuild,
      'ad_format': format,
      'placement': emplacement,
      'valeur_micros': valeurMicros.round(),
      'devise': code,
      'precision_type': precision,
    };
  }

  /// Au démarrage : ce qui n'a pas pu partir lors de la dernière session.
  static Future<int> envoyerEnAttente() async => await _envoi.envoyer() + await _revenus.envoyer();
}
