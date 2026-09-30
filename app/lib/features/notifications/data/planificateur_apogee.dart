import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/app_logger.dart';
import '../../cellar/domain/bottle.dart';
import '../domain/digest_apogee.dart';
import 'local_notification_service.dart';
import 'notification_preferences_service.dart';

/// Programme le rendez-vous d'apogée de la semaine (V2.3 · D5), une fois par jour au plus.
///
/// Un identifiant fixe : la nouvelle programmation remplace la précédente, si bien que la
/// personne ne reçoit jamais qu'une notification par semaine, qui reflète sa cave du moment.
class PlanificateurApogee {
  static const idNotification = 424242;
  static const _cleDernierCalcul = 'digest_apogee_calcule_le';

  static Future<void> planifier(List<Bottle> bouteilles, LocalNotificationService notifications,
      {DateTime? maintenant}) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ici = maintenant ?? DateTime.now();
      final aujourdHui = '${ici.year}-${ici.month}-${ici.day}';
      if (prefs.getString(_cleDernierCalcul) == aujourdHui) return;
      await prefs.setString(_cleDernierCalcul, aujourdHui);

      if (!NotificationPreferencesService(prefs).loadPreferences().apogeeAlertsEnabled) {
        await notifications.cancelReminder(idNotification);
        return;
      }
      final message = DigestApogee.message(DigestApogee.aBoire(bouteilles));
      await notifications.cancelReminder(idNotification);
      if (message == null) return;
      final quand = DigestApogee.prochainRendezVous(ici);
      await notifications.scheduleNotification(
        id: idNotification,
        title: message.$1,
        body: message.$2,
        delay: quand.difference(ici),
        channelId: NotificationChannels.apogeeId,
        channelName: NotificationChannels.apogeeName,
        payload: 'apogee_digest',
      );
    } catch (e) {
      AppLogger.warning('NOTIF', 'Rendez-vous d\'apogée non programmé : $e');
    }
  }
}
