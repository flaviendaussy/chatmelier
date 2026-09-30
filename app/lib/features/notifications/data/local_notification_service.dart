import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';

/// Channels used on Android. Noms et descriptions suivent la langue de l'app : Android
/// les affiche dans les réglages de notifications.
class NotificationChannels {
  static const String tastingsId = 'chatmelier_tastings';
  static String get tastingsName => tr('Rappels de dégustation', 'Tasting reminders');
  static String get tastingsDesc => tr('Notifications pour noter un vin dégusté récemment', 'Reminders to rate a wine you just tasted');

  static const String apogeeId = 'chatmelier_apogee';
  static String get apogeeName => tr('Apogée & Maturité', 'Peak & maturity');
  static String get apogeeDesc => tr('Alertes lorsque vos vins atteignent leur apogée', 'Alerts when your wines reach their peak');

  static const String sharedCellarId = 'chatmelier_shared_cellar';
  static String get sharedCellarName => tr('Activité Cave Partagée', 'Shared cellar activity');
  static String get sharedCellarDesc => tr('Activité de vos co-éditeurs et déstockages', 'What others do in your shared cellars');

  static const String socialId = 'chatmelier_social';
  static String get socialName => tr('Amis & Invitations', 'Friends & invitations');
  static String get socialDesc => tr('Demandes d\'amis et accès aux caves', 'Friend requests and cellar access');

  static const String sommelierId = 'chatmelier_sommelier';
  static String get sommelierName => tr('Conseils Sommelier du Week-end', 'Weekend sommelier tips');
  static String get sommelierDesc => tr('Recommandations hebdomadaires pour vos repas', 'Weekly ideas for your meals');

  static const String liveAerationId = 'chatmelier_live_aeration';
  static String get liveAerationName => tr('Aération & Chrono en Direct', 'Live aeration timer');
  static String get liveAerationDesc => tr('Affichage en direct sur l\'écran de verrouillage du temps restant avant dégustation', 'Time left before tasting, live on the lock screen');
}

/// Service managing on-device (native system) notifications via flutter_local_notifications.
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;

  /// Initialize the plugin, set up notification channels, and initialize timezone data.
  Future<void> initialize({void Function(NotificationResponse)? onSelectNotification}) async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final String localName = DateTime.now().timeZoneName;
        if (tz.timeZoneDatabase.locations.containsKey(localName)) {
          tz.setLocalLocation(tz.getLocation(localName));
        } else {
          tz.setLocalLocation(tz.getLocation('Europe/Paris'));
        }
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: onSelectNotification,
      );

      // Create channels on Android
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(
            AndroidNotificationChannel(
              NotificationChannels.tastingsId,
              NotificationChannels.tastingsName,
              description: NotificationChannels.tastingsDesc,
              importance: Importance.high,
            ),
          );
          await androidImpl.createNotificationChannel(
            AndroidNotificationChannel(
              NotificationChannels.apogeeId,
              NotificationChannels.apogeeName,
              description: NotificationChannels.apogeeDesc,
              importance: Importance.defaultImportance,
            ),
          );
          await androidImpl.createNotificationChannel(
            AndroidNotificationChannel(
              NotificationChannels.sharedCellarId,
              NotificationChannels.sharedCellarName,
              description: NotificationChannels.sharedCellarDesc,
              importance: Importance.defaultImportance,
            ),
          );
          await androidImpl.createNotificationChannel(
            AndroidNotificationChannel(
              NotificationChannels.socialId,
              NotificationChannels.socialName,
              description: NotificationChannels.socialDesc,
              importance: Importance.high,
            ),
          );
          await androidImpl.createNotificationChannel(
            AndroidNotificationChannel(
              NotificationChannels.sommelierId,
              NotificationChannels.sommelierName,
              description: NotificationChannels.sommelierDesc,
              importance: Importance.low,
            ),
          );
          await androidImpl.createNotificationChannel(
            AndroidNotificationChannel(
              NotificationChannels.liveAerationId,
              NotificationChannels.liveAerationName,
              description: NotificationChannels.liveAerationDesc,
              importance: Importance.max,
            ),
          );
        }
      }

      _isInitialized = true;
      AppLogger.info('NOTIF', 'LocalNotificationService initialized successfully');
    } catch (e) {
      AppLogger.warning('NOTIF', 'Could not initialize LocalNotificationService: $e');
    }
  }

  /// Request system notification permissions from the OS.
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final granted = await androidImpl.requestNotificationsPermission();
          return granted ?? false;
        }
      } else if (Platform.isIOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosImpl != null) {
          final granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      } else if (Platform.isMacOS) {
        final macosImpl = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        if (macosImpl != null) {
          final granted = await macosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
    } catch (e) {
      AppLogger.warning('NOTIF', 'Error requesting notifications permission: $e');
    }
    return false;
  }

  /// Check whether notification permissions are currently granted.
  Future<bool> areNotificationsEnabled() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final enabled = await androidImpl.areNotificationsEnabled();
          return enabled ?? false;
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        return true;
      }
    } catch (e) {
        AppLogger.debug('NOTIF', 'Repli : $e');
      }
    return true;
  }

  /// Show an immediate notification on-device.
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = NotificationChannels.tastingsId,
    String? channelName,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName ?? NotificationChannels.tastingsName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      AppLogger.warning('NOTIF', 'Failed to show instant notification: $e');
    }
  }

  /// Schedule a notification to fire at a specific delay from now.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
    String channelId = NotificationChannels.tastingsId,
    String? channelName,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName ?? NotificationChannels.tastingsName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      AppLogger.info('NOTIF', 'Notification $id scheduled in ${delay.inMinutes} minutes ($scheduledDate)');
    } catch (e) {
      AppLogger.warning('NOTIF', 'Failed to schedule notification: $e');
    }
  }

  /// Schedule a post-tasting reminder for a specific bottle.
  Future<void> scheduleTastingReminder({
    required String bottleId,
    required String wineName,
    int? vintage,
    Duration delay = const Duration(hours: 1, minutes: 30),
  }) async {
    final vintageStr = vintage != null ? ' $vintage' : '';
    final id = bottleId.hashCode.abs() % 100000;
    await scheduleNotification(
      id: id,
      title: tr('🍷 Alors, cette dégustation ?', '🍷 So, how was it?'),
      body: tr('Vous avez sorti {wineName}{vintageStr}. Prenez 30s pour noter vos impressions tant que le souvenir est frais !', 'You opened {wineName}{vintageStr}. Take 30 seconds to note your impressions while they\'re fresh!', {'wineName': wineName, 'vintageStr': vintageStr}),
      delay: delay,
      channelId: NotificationChannels.tastingsId,
      channelName: NotificationChannels.tastingsName,
      payload: 'tasting_reminder:$bottleId',
    );
  }

  /// Cancel a scheduled tasting reminder.
  Future<void> cancelReminder(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
        AppLogger.debug('NOTIF', 'Repli : $e');
      }
  }

  static const int liveAerationNotificationId = 88888;

  /// Show or update an ongoing live aeration chronometer notification on Android lockscreen.
  Future<void> showLiveAerationNotification({
    required String wineName,
    int? vintage,
    required int remainingSeconds,
    String? bottleId,
  }) async {
    try {
      final vintageStr = vintage != null ? ' $vintage' : '';
      final targetTimestampMs = DateTime.now().millisecondsSinceEpoch + (remainingSeconds * 1000);

      final androidDetails = AndroidNotificationDetails(
        NotificationChannels.liveAerationId,
        NotificationChannels.liveAerationName,
        channelDescription: NotificationChannels.liveAerationDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        ongoing: true,
        autoCancel: false,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.stopwatch,
        showWhen: true,
        when: targetTimestampMs,
        usesChronometer: true,
        chronometerCountDown: true,
        subText: tr('Aération en cours', 'Aerating'),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_aeration',
            tr('Arrêter le chrono', 'Stop the timer'),
            cancelNotification: true,
          ),
        ],
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

      await _plugin.show(
        id: liveAerationNotificationId,
        title: tr('🍷 Aération : {wineName}{vintageStr}', '🍷 Aerating: {wineName}{vintageStr}', {'wineName': wineName, 'vintageStr': vintageStr}),
        body: tr('Compte à rebours lockscreen. Votre vin s\'oxygène pour déployer ses arômes.', 'Your wine is breathing and opening up.'),
        notificationDetails: details,
        payload: 'live_aeration:${bottleId ?? ""}',
      );
      AppLogger.info('NOTIF', 'Live aeration notification active for $wineName ($remainingSeconds s)');
    } catch (e) {
      AppLogger.warning('NOTIF', 'Failed to show live aeration notification: $e');
    }
  }

  /// Cancel and dismiss the live lockscreen aeration chronometer.
  Future<void> stopLiveAerationNotification() async {
    try {
      await _plugin.cancel(id: liveAerationNotificationId);
      AppLogger.info('NOTIF', 'Live aeration notification stopped');
    } catch (e) {
        AppLogger.debug('NOTIF', 'Repli : $e');
      }
  }

  /// Send a completion notification when aeration finishes.
  Future<void> showAerationFinishedNotification({
    required String wineName,
    int? vintage,
  }) async {
    try {
      await stopLiveAerationNotification();
      final vintageStr = vintage != null ? ' $vintage' : '';
      await showInstantNotification(
        id: liveAerationNotificationId + 1,
        title: tr('✨ {wineName}{vintageStr} est prêt à servir !', '✨ {wineName}{vintageStr} is ready to serve!', {'wineName': wineName, 'vintageStr': vintageStr}),
        body: tr('L\'aération recommandée est terminée : le vin s\'est ouvert.', 'Aeration done: the wine has opened up.'),
        channelId: NotificationChannels.liveAerationId,
        channelName: NotificationChannels.liveAerationName,
      );
    } catch (e) {
      AppLogger.warning('NOTIF', 'Failed to show aeration finished notification: $e');
    }
  }

  /// Send a test notification to let the user immediately verify how notifications look on device.
  Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 99999,
      title: '🍷 Notification Chatmelier Active !',
      body: tr('Vos alertes d\'apogée et rappels de dégustation fonctionneront parfaitement sur cet appareil.', 'Your peak alerts and tasting reminders will work on this device.'),
      channelId: NotificationChannels.tastingsId,
      channelName: NotificationChannels.tastingsName,
    );
  }
}

/// Provider for LocalNotificationService.
final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  final service = LocalNotificationService();
  service.initialize();
  return service;
});
