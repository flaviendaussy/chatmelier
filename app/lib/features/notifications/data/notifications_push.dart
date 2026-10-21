import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../domain/notification_anti_spam_policy.dart';
import 'notification_preferences_service.dart';

/// Les notifications push (lot N, version 86).
///
/// Décision de Flavien (16/10) : « des notifications push réelles », à commencer par
/// « Caro a ajouté des bouteilles à votre cave », au moment exact. Le serveur fait tout le
/// reste (migration 075, fonction `envoyer-push`) : l'app inscrit le téléphone, avec sa
/// langue, son décalage horaire et ce que la personne a coupé, et ouvre le bon écran au
/// toucher.
///
/// Rien n'est demandé au lancement : le téléphone ne s'inscrit que si les notifications sont
/// déjà permises (la même permission que les rappels de dégustation), ou dès qu'elles le
/// deviennent ([activer]). Sans les identifiants Firebase passés au build (`--dart-define`,
/// voir `build_bundle.sh`) et sur le web, tout reste éteint.
class NotificationsPush {
  static const _projet = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _expediteur = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _stockage = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _androidAppli = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const _androidCle = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const _iosAppli = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosCle = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosBundle = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.chatmelier.chatmelier');

  static bool _demarre = false;
  static String? _jeton;
  static void Function(String ouvrir, String? caveId)? _ouvrir;
  static void Function(String titre, String texte, String ouvrir, String? caveId)? _alerte;

  static FirebaseOptions? get _options {
    if (kIsWeb || _projet.isEmpty || _expediteur.isEmpty) return null;
    try {
      if (Platform.isAndroid && _androidAppli.isNotEmpty && _androidCle.isNotEmpty) {
        return FirebaseOptions(
          apiKey: _androidCle,
          appId: _androidAppli,
          messagingSenderId: _expediteur,
          projectId: _projet,
          storageBucket: _stockage.isEmpty ? null : _stockage,
        );
      }
      if (Platform.isIOS && _iosAppli.isNotEmpty && _iosCle.isNotEmpty) {
        return FirebaseOptions(
          apiKey: _iosCle,
          appId: _iosAppli,
          messagingSenderId: _expediteur,
          projectId: _projet,
          storageBucket: _stockage.isEmpty ? null : _stockage,
          iosBundleId: _iosBundle,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Les identifiants Firebase sont là, et la plateforme sait recevoir des push.
  static bool get disponible => _options != null;

  /// Au lancement, après la première image. [ouvrir] mène à l'écran d'une notification
  /// touchée ; [alerte] dit, app ouverte, ce qui vient d'arriver.
  static Future<void> demarrer({
    required void Function(String ouvrir, String? caveId) ouvrir,
    required void Function(String titre, String texte, String ouvrir, String? caveId) alerte,
  }) async {
    _ouvrir = ouvrir;
    _alerte = alerte;
    final options = _options;
    if (_demarre || options == null) return;
    _demarre = true;
    try {
      await Firebase.initializeApp(options: options);
      final m = FirebaseMessaging.instance;
      // App ouverte : pas de bannière du système (l'app le dit elle-même, avec « Voir »).
      await m.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n == null) return;
        _alerte?.call(n.title ?? '', n.body ?? '', _destination(message.data), _cave(message.data));
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) => _toucher(message.data));
      final initiale = await m.getInitialMessage();
      if (initiale != null) {
        // L'app vient d'être lancée par le toucher : le routeur doit d'abord exister.
        Future.delayed(const Duration(milliseconds: 1200), () => _toucher(initiale.data));
      }
      // Le jeton d'enregistrement classique, celui qu'attend l'API HTTP v1 de `envoyer-push`.
      // firebase_messaging 17 le dit déprécié au profit de register()/onRegistered, qui
      // rendent un identifiant d'installation (FID) pour un autre mode d'envoi : à revoir
      // avec la fonction serveur, ensemble, quand ce mode sera documenté.
      // ignore: deprecated_member_use
      m.onTokenRefresh.listen((jeton) {
        _jeton = jeton;
        unawaited(_inscrire());
      });
      final reglages = await m.getNotificationSettings();
      if (_permis(reglages.authorizationStatus)) await _inscrire();
      // Une connexion (autre compte, nouvel appareil) : le téléphone passe au compte connecté.
      Supabase.instance.client.auth.onAuthStateChange.listen((etat) {
        if (etat.event == AuthChangeEvent.signedIn) unawaited(_inscrire());
      });
      AppLogger.info('PUSH', 'Notifications push prêtes (${_permis(reglages.authorizationStatus) ? 'permises' : 'pas encore permises'})');
    } catch (e) {
      AppLogger.warning('PUSH', 'Démarrage des push impossible : $e');
    }
  }

  static bool _permis(AuthorizationStatus s) =>
      s == AuthorizationStatus.authorized || s == AuthorizationStatus.provisional;

  /// La personne vient de permettre les notifications (dialogue de l'app, réglages) : le
  /// téléphone s'inscrit. Ne montre rien de plus : la permission est déjà décidée.
  static Future<void> activer() async {
    if (!_demarre) return;
    try {
      final r = await FirebaseMessaging.instance.requestPermission();
      if (_permis(r.authorizationStatus)) await _inscrire();
    } catch (e) {
      AppLogger.info('PUSH', 'Activation des push impossible : $e');
    }
  }

  /// Les préférences de notification ont changé : le serveur doit le savoir, pour ne rien
  /// pousser de ce qui est coupé.
  static Future<void> preferencesChangees() => _demarre ? _inscrire() : Future.value();

  /// Avant la déconnexion : ce téléphone ne reçoit plus rien pour ce compte.
  static Future<void> oublier() async {
    final jeton = _jeton;
    if (!_demarre || jeton == null) return;
    try {
      await Supabase.instance.client
          .rpc('oublier_appareil_push', params: {'p_jeton': jeton})
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLogger.info('PUSH', 'Appareil non oublié : $e');
    }
  }

  static Future<void> _inscrire() async {
    final client = Supabase.instance.client;
    final moi = client.auth.currentUser;
    if (moi == null || moi.isAnonymous) return;
    try {
      // Sur l'iPhone, le jeton Apple arrive un peu après la permission.
      // ignore: deprecated_member_use
      _jeton ??= await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 10));
    } catch (e) {
      AppLogger.info('PUSH', 'Jeton pas encore disponible : $e');
      return;
    }
    final jeton = _jeton;
    if (jeton == null || jeton.isEmpty) return;
    try {
      final prefs = NotificationPreferencesService(await SharedPreferences.getInstance()).loadPreferences();
      await client.rpc('enregistrer_appareil_push', params: {
        'p_jeton': jeton,
        'p_plateforme': Platform.isIOS ? 'ios' : 'android',
        'p_langue': Langue.code,
        'p_decalage_min': DateTime.now().timeZoneOffset.inMinutes,
        'p_preferences': preferencesDuServeur(prefs),
        'p_version': versionApp,
      }).timeout(const Duration(seconds: 8));
    } catch (e) {
      // Migration 075 pas encore appliquée, ou hors ligne : pas de push, rien de cassé.
      AppLogger.info('PUSH', 'Inscription du téléphone impossible : $e');
    }
  }

  /// Ce que le serveur doit respecter : ce que la personne a coupé, ses heures calmes.
  @visibleForTesting
  static Map<String, dynamic> preferencesDuServeur(NotificationPreferences p) => {
        'activite_cave': p.sharedCellarActivityEnabled,
        'amis': p.friendRequestsEnabled,
        'degustations': p.friendRequestsEnabled,
        'heures_calmes': p.quietHoursEnabled,
        // Les mêmes heures calmes que les rappels de l'app (22 h – 8 h 30), en heures.
        'calme_debut': NotificationAntiSpamPolicy.defaultQuietStartHour,
        'calme_fin': NotificationAntiSpamPolicy.defaultQuietEndHour + NotificationAntiSpamPolicy.defaultQuietEndMinute / 60,
      };

  static String _destination(Map<String, dynamic> data) {
    final o = data['ouvrir']?.toString() ?? '';
    return o.isEmpty ? 'boite' : o;
  }

  static String? _cave(Map<String, dynamic> data) {
    final c = data['cellar_id']?.toString();
    return c == null || c.isEmpty ? null : c;
  }

  static void _toucher(Map<String, dynamic> data) => _ouvrir?.call(_destination(data), _cave(data));
}
