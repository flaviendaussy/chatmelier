import 'features/feedback/data/retours_en_attente.dart';
import 'shared/services/croissance.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'features/offline/presentation/sync_provider.dart';
import 'features/auth/data/ai_cost_tracker_service.dart';
import 'features/auth/data/palais_distant.dart';
import 'features/auth/domain/retour_du_lien.dart';
import 'features/monetization/admob_service.dart';
import 'features/monetization/domain/reglages_de_la_pub.dart';
import 'features/monetization/mesure_des_pubs.dart';
import 'shared/utils/app_logger.dart';

/// Gardé en vie : il relance l'envoi des retours en attente au retour au premier plan.
// ignore: unused_element
AppLifecycleListener? _auPremierPlan;

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Inter et Playfair Display sont dans l'app (assets/google_fonts) : plus de téléchargement
  // chez Google au lancement. Hors ligne, il échouait (« Failed to load font », journaux de
  // la 78), et il envoyait l'adresse IP de chacun à Google sans qu'on le lui ait demandé.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final (famille, fichier) in [('Inter', 'OFL-Inter.txt'), ('Playfair Display', 'OFL-PlayfairDisplay.txt')]) {
      yield LicenseEntryWithLineBreaks([famille], await rootBundle.loadString('assets/google_fonts/$fichier'));
    }
  });

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

  // Lue avant que le SDK ne la traite : l'adresse d'ouverture porte-t-elle un retour de
  // connexion (V2.5 · Q11) ?
  final retourDuLien = kIsWeb ? RetourDuLien.lire(Uri.base) : null;

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
  // Un lien ouvert dans un autre navigateur que celui qui l'a demandé ne connecte personne,
  // et le SDK n'en dit rien : Camille revenait à l'écran de l'adresse sans un mot (Q11).
  final apresLeLien = Supabase.instance.client.auth.currentUser;
  if (retourDuLien != null && (apresLeLien == null || apresLeLien.isAnonymous)) {
    lienSansEffet.value = retourDuLien;
    AppLogger.warning('AUTH', 'Lien de connexion sans effet sur le web (${retourDuLien.motif ?? 'aucune session ouverte'})');
  }
  // Ce qui n'a pas pu partir lors de la dernière session (S5) : coûts IA, pubs.
  unawaited(AiCostTrackerService.envoyerEnAttente());
  // Les retours « secouer pour commenter » restés sans réseau, capture comprise (16/10) :
  // au lancement, et chaque fois que l'app revient au premier plan.
  unawaited(RetoursEnAttente.envoyer());
  _auPremierPlan = AppLifecycleListener(onResume: () => unawaited(RetoursEnAttente.envoyer()));
  unawaited(MesureDesPubs.envoyerEnAttente());
  // Ce que l'IA offre chaque jour et ce qu'une vidéo débloque (modèle économique, 87).
  unawaited(ReglagesDeLaPub.charger(Supabase.instance.client));
  // Le palais suit le compte (P6) : copie au serveur à chaque sauvegarde, rapatriement sur
  // un appareil vierge — au lancement, et à chaque connexion (nouvel appareil, reprise).
  PalaisDistant.actif = true;
  unawaited(PalaisDistant.recuperer().then((rapatrie) {
    // Rien à rapatrier : c'est ce téléphone qui sait, il envoie sa copie.
    if (!rapatrie) PalaisDistant.planifierEnvoi();
  }));
  Supabase.instance.client.auth.onAuthStateChange.listen((etat) {
    if (etat.event == AuthChangeEvent.signedIn) {
      // Connecté : l'avis sur un lien et l'adresse du dernier lien n'ont plus d'objet (Q11).
      lienSansEffet.value = null;
      adresseDuDernierLien.value = null;
      unawaited(PalaisDistant.recuperer());
      unawaited(Croissance.noterPremiereOuvertureSiBesoin());
    }
  }, onError: (Object erreur, StackTrace _) {
    // Le SDK range ici l'échec d'un lien de connexion, et rien ne l'écoutait (Q11). Le
    // motif seulement : jamais de code ni de jeton dans les journaux.
    final motif = erreur is AuthException ? (erreur.code ?? erreur.message) : erreur.runtimeType.toString();
    AppLogger.warning('AUTH', 'Connexion refusée : ${motif.length > 160 ? motif.substring(0, 160) : motif}');
    if (erreur is AuthException && erreur.message.contains('Code verifier')) {
      lienSansEffet.value ??= RetourDuLien.sansMotif;
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

  // La pub ne retarde plus l'ouverture (V2.5 · E7) : son initialisation (consentement, puis
  // le SDK) faisait attendre jusqu'à trois secondes avant le premier écran, et occupait le
  // fil principal d'Android (vu le 17/10 : 222 images perdues au démarrage, 15 s avant la
  // première image sur l'émulateur). Elle part après la première image ; une pub demandée
  // avant qu'elle soit prête est simplement sautée.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(AdMobService().initialize().catchError((Object e) {
      AppLogger.warning('ADMOB_INIT', 'Failed to initialize AdMob SDK: $e', e);
    }));
  });

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesInstanceProvider.overrideWithValue(prefs),
      ],
      child: const ChatmelierApp(),
    ),
  );
}
