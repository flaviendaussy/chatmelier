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

  /// [format] : `rewarded`, `app_open`… ; [emplacement] : où la pub est apparue
  /// (`scan_carte`, `scan_etiquette`, `ouverture`…).
  static Future<void> impression({required String format, required String emplacement}) => _envoi.ajouter({
        'event_id': const Uuid().v4(),
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
        'platform': EnvoiParLots.plateforme,
        'app_version': versionApp,
        'build_mode': EnvoiParLots.modeDeBuild,
        'ad_format': format,
        'placement': emplacement,
      });

  /// Au démarrage : ce qui n'a pas pu partir lors de la dernière session.
  static Future<int> envoyerEnAttente() => _envoi.envoyer();
}
