import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils/app_logger.dart';

/// Les photos d'étiquettes, gardées un an sur l'appareil.
///
/// Le cache par défaut de `cached_network_image` oublie une image au bout de trente
/// jours : une bouteille couchée depuis deux mois s'affichait sans photo dès qu'on ouvrait
/// la cave sans réseau. La cave doit se consulter hors ligne — seule l'IA a besoin du
/// réseau (retour du 28/09).
class CacheDesEtiquettes {
  static final CacheManager instance = CacheManager(
    Config(
      'chatmelier_etiquettes',
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 4000,
    ),
  );

  /// Les adresses déjà vérifiées pendant cette session : la cave se recharge souvent, la
  /// vérification ne doit pas se refaire à chaque fois.
  static final Set<String> _dejaVues = {};

  /// Télécharge d'avance les photos qui ne sont pas encore sur l'appareil, une à une pour
  /// ne pas saturer une connexion faible. Rend le nombre de photos téléchargées.
  static Future<int> precharger(Iterable<String> adresses) async {
    var telechargees = 0;
    for (final url in adresses) {
      if (!(url.startsWith('http://') || url.startsWith('https://')) || !_dejaVues.add(url)) continue;
      try {
        if (await instance.getFileFromCache(url) == null) {
          await instance.downloadFile(url);
          telechargees++;
        }
      } catch (e) {
        // Hors ligne ou photo disparue : on réessaiera à la prochaine session.
        _dejaVues.remove(url);
      }
    }
    if (telechargees > 0) {
      AppLogger.info('OFFLINE_CACHE', '$telechargees photo(s) d\'étiquette gardée(s) pour le hors-ligne');
    }
    return telechargees;
  }
}
