import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../shared/utils/app_logger.dart';

/// Channels used on Android
class NotificationChannels {
  static const String tastingsId = 'chatmelier_tastings';
  static const String tastingsName = 'Rappels de dégustation';
  static const String tastingsDesc = 'Notifications pour noter un vin dégusté récemment';

  static const String apogeeId = 'chatmelier_apogee';
  static const String apogeeName = 'Apogée & Maturité';
  static const String apogeeDesc = 'Alertes lorsque vos vins atteignent leur apogée';

  static const String sharedCellarId = 'chatmelier_shared_cellar';
  static const String sharedCellarName = 'Activité Cave Partagée';
  static const String sharedCellarDesc = 'Activité de vos co-éditeurs et déstockages';

  static const String socialId = 'chatmelier_social';
  static const String socialName = 'Amis & Invitations';
  static const String socialDesc = 'Demandes d\'amis et accès aux caves';

  static const String sommelierId = 'chatmelier_sommelier';
  static const String sommelierName = 'Conseils Sommelier du Week-end';
  static const String sommelierDesc = 'Recommandations hebdomadaires pour vos repas';

  static const String liveAerationId = 'chatmelier_live_aeration';
  static const String liveAerationName = 'Aération & Chrono en Direct';
  static const String liveAerationDesc = 'Affichage en direct sur l\'écran de verrouillage du temps restant avant dégustation';
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
            const AndroidNotificationChannel(
              NotificationChannels.tastingsId,
              NotificationChannels.tastingsName,
              description: NotificationChannels.tastingsDesc,
              importance: Importance.high,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              NotificationChannels.apogeeId,
              NotificationChannels.apogeeName,
              description: NotificationChannels.apogeeDesc,
              importance: Importance.defaultImportance,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              NotificationChannels.sharedCellarId,
              NotificationChannels.sharedCellarName,
              description: NotificationChannels.sharedCellarDesc,
              importance: Importance.defaultImportance,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              NotificationChannels.socialId,
              NotificationChannels.socialName,
              description: NotificationChannels.socialDesc,
              importance: Importance.high,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              NotificationChannels.sommelierId,
              NotificationChannels.sommelierName,
              description: NotificationChannels.sommelierDesc,
              importance: Importance.low,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
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
    } catch (_) {}
    return true;
  }

  /// Show an immediate notification on-device.
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = NotificationChannels.tastingsId,
    String channelName = NotificationChannels.tastingsName,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
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
    String channelName = NotificationChannels.tastingsName,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
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
      title: '🍷 Alors, cette dégustation ?',
      body: 'Vous avez sorti $wineName$vintageStr. Prenez 30s pour noter vos impressions tant que le souvenir est frais !',
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
    } catch (_) {}
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
        subText: 'Aération en cours',
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_aeration',
            'Arrêter le chrono',
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
        title: '🍷 Aération : $wineName$vintageStr',
        body: 'Compte à rebours lockscreen. Votre vin s\'oxygène pour déployer ses arômes.',
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
    } catch (_) {}
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
        title: '✨ $wineName$vintageStr est prêt à servir !',
        body: 'L\'aération recommandée est terminée. Les arômes sont parfaitement libérés et les tanins assouplis.',
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
      body: 'Vos alertes d\'apogée et rappels de dégustation fonctionneront parfaitement sur cet appareil.',
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
