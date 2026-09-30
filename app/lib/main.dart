import 'shared/services/croissance.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'features/offline/presentation/sync_provider.dart';
import 'features/auth/data/ai_cost_tracker_service.dart';
import 'features/auth/data/palais_distant.dart';
import 'features/monetization/admob_service.dart';
import 'features/monetization/mesure_des_pubs.dart';
import 'shared/utils/app_logger.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Publie l'arbre sémantique en build de test, sans attendre un lecteur d'écran.
  //
  // Sans ça, `adb shell uiautomator dump` ne voit qu'un canevas vide : Flutter dessine
  // tout lui-même et ne décrit son contenu que si un client d'accessibilité écoute.
  // Conséquence pratique : vérifier un écran imposait une CAPTURE D'IMAGE, coûteuse, et
  // naviguer à l'aveugle par coordonnées — avec les erreurs que ça entraîne.
  //
  // Avec la sémantique publiée, l'écran devient du TEXTE : lisible, greppable, et
  // surtout assertable par un script plutôt que par un œil humain.
  //
  // Jamais en release : c'est un coût de performance pour un bénéfice de test.
  assert(() {
    binding.ensureSemantics();
    return true;
  }());
  if (const bool.fromEnvironment('dart.vm.product') == false &&
      const String.fromEnvironment('CHATMELIER_SEMANTICS', defaultValue: 'off') == 'on') {
    binding.ensureSemantics();
  }
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  
  final prefs = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://fvnybncauhbpsnikzeeq.supabase.co',
    ),
    publishableKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_P3P36VFswbjyOXxplwniPg_D_NuGYNF',
    ),
  );

  AppLogger.init(Supabase.instance.client);
  // Ce qui n'a pas pu partir lors de la dernière session (S5) : coûts IA, pubs.
  unawaited(AiCostTrackerService.envoyerEnAttente());
  unawaited(MesureDesPubs.envoyerEnAttente());
  // Le palais suit le compte (P6) : copie au serveur à chaque sauvegarde, rapatriement sur
  // un appareil vierge — au lancement, et à chaque connexion (nouvel appareil, reprise).
  PalaisDistant.actif = true;
  unawaited(PalaisDistant.recuperer().then((rapatrie) {
    // Rien à rapatrier : c'est ce téléphone qui sait, il envoie sa copie.
    if (!rapatrie) PalaisDistant.planifierEnvoi();
  }));
  Supabase.instance.client.auth.onAuthStateChange.listen((etat) {
    if (etat.event == AuthChangeEvent.signedIn) {
      unawaited(PalaisDistant.recuperer());
      unawaited(Croissance.noterPremiereOuvertureSiBesoin());
    }
  });
  unawaited(Croissance.noterPremiereOuvertureSiBesoin());
  AppLogger.info('SYSTEM', 'Chatmelier app launched and centralized logging initialized');

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (!AppLogger.premiereFois(details.exception)) return;
    AppLogger.error('FLUTTER_UI', details.exceptionAsString(), details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    // Une police Google non téléchargée (premier lancement sans réseau) : l'app retombe
    // sur la police système, rien n'est cassé. 153 « erreurs » de ce genre en septembre,
    // surtout sur les appareils de pré-lancement du Play Store, noyaient les vraies.
    if (error.toString().contains('Failed to load font')) {
      AppLogger.warning('FONTS', error.toString());
      return true;
    }
    if (!AppLogger.premiereFois(error)) return true;
    // Un renouvellement de session qui échoue faute de réseau n'est pas un bogue : le SDK
    // réessaie seul. On le note, sans le compter parmi les erreurs.
    if (error is AuthRetryableFetchException) {
      AppLogger.warning('AUTH_RESEAU', error.toString());
      return true;
    }
    AppLogger.error('ASYNC_UNCAUGHT', error.toString(), error, stack);
    return true;
  };

  // Initialize Google Mobile Ads (AdMob) on supported mobile devices
  try {
    await AdMobService().initialize();
  } catch (e) {
    AppLogger.warning('ADMOB_INIT', 'Failed to initialize AdMob SDK: $e', e);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesInstanceProvider.overrideWithValue(prefs),
      ],
      child: const ChatmelierApp(),
    ),
  );
}
