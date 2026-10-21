import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'shared/l10n/fallback_localizations_delegates.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'features/checkout/data/post_tasting_notification_service.dart';
import 'features/offline/data/connectivity_service.dart';
import 'features/monetization/admob_service.dart';
import 'shared/providers/premium_provider.dart';

import 'features/feedback/data/shake_feedback_service.dart';
import 'features/friends/data/friends_repository.dart';
import 'features/notifications/data/notifications_push.dart';
import 'features/notifications/presentation/notifications_inbox_sheet.dart';
import 'shared/providers/cellar_provider.dart';
import 'features/config/garde_de_version.dart';
import 'features/config/porte_de_l_age.dart';
import 'shared/utils/app_logger.dart';
import 'shared/utils/langue.dart';
import 'shared/widgets/clavier_qui_se_ferme.dart';

/// Ce qui ne se lance qu'une fois par démarrage (T8). Le rappel d'après-image du `builder`
/// était réinscrit à chaque reconstruction de la racine — langue, thème… — et relançait la
/// minuterie des rappels de dégustation (et un contrôle cinq secondes plus tard), l'écoute
/// de la secousse et la pub d'ouverture. Un drapeau par conteneur, pas global : chaque
/// essai qui monte l'app repart d'un démarrage.
class _Demarrage {
  bool fait = false;
}

final _demarrageProvider = Provider<_Demarrage>((ref) => _Demarrage());

class ChatmelierApp extends ConsumerWidget {
  const ChatmelierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final userLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'Chatmelier',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: userLocale,
      localizationsDelegates: kAppLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, supportedLocales) {
        if (locales == null || locales.isEmpty) {
          return const Locale('en');
        }
        for (final locale in locales) {
          // Exact match
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode &&
                (supported.countryCode == null || supported.countryCode == locale.countryCode)) {
              return supported;
            }
          }
          // Language code match
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        // Fallback for unsupported locales is English
        return const Locale('en');
      },
      routerConfig: router,
      builder: (context, child) {
        // La langue des textes écrits en dur (`tr`), à chaque changement de langue.
        Langue.definir(Localizations.localeOf(context));
        // Initialize post-tasting notification checker and App Open Ads
        final demarrage = ref.read(_demarrageProvider);
        if (!demarrage.fait) {
          demarrage.fait = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(connectivityServiceProvider);
            final notifService = ref.read(postTastingNotificationProvider);
            notifService.init(context);

            // Register App Open Ad lifecycle observation and trigger startup check
            final admob = ref.read(admobServiceProvider);
            admob.startAppLifecycleObservation(
              isPremium: () => ref.read(premiumProvider),
            );

            final isPremium = ref.read(premiumProvider);
            if (!isPremium) {
              admob.showAppOpenAdOnLaunch();
            }

            // Initialize shake-to-report feedback service for testers
            ShakeFeedbackService.instance.startListening();

            // Les notifications push (lot N) : rien n'est demandé ici, le téléphone
            // s'inscrit seulement si les notifications sont déjà permises.
            unawaited(NotificationsPush.demarrer(
              ouvrir: (ouvrir, caveId) => _ouvrirDepuisUnPush(ref, ouvrir, caveId),
              alerte: (titre, texte, ouvrir, caveId) => _alerteDuPush(ref, titre, texte, ouvrir, caveId),
            ));
          });
        }
        return RepaintBoundary(
          key: ShakeFeedbackService.rootRepaintBoundaryKey,
          // Toucher ailleurs referme le clavier (V2.4 · R3).
          child: ClavierQuiSeFerme(
            // L'âge légal, déclaré une fois (PROD_MIGRATION.md · Alcool).
            child: PorteDeLAge(
              // Pendant la phase de test : une version trop ancienne est bloquée (045).
              child: GardeDeVersion(
                versionInstallee: versionApp,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Une notification push touchée : l'écran qu'elle annonce (lot N). La cave concernée
/// devient la cave affichée ; les demandes et invitations s'ouvrent dans la boîte.
void _ouvrirDepuisUnPush(WidgetRef ref, String ouvrir, String? caveId) {
  refreshFriendsAndNotifications(ref);
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  if (caveId != null) ref.read(currentCellarIdProvider.notifier).state = caveId;
  if (ouvrir == 'boite') {
    unawaited(NotificationsInboxSheet.show(ctx));
    return;
  }
  GoRouter.of(ctx).go(ouvrir == '/cellar' ? '/' : ouvrir);
}

/// App ouverte : pas de bannière du système, un bandeau avec « Voir », et les listes à jour.
void _alerteDuPush(WidgetRef ref, String titre, String texte, String ouvrir, String? caveId) {
  refreshFriendsAndNotifications(ref);
  if (caveId != null) notifyCellarChanged(ref, caveId);
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(
    content: Text(texte.isEmpty ? titre : texte),
    duration: const Duration(seconds: 6),
    action: SnackBarAction(label: tr('Voir', 'View'), onPressed: () => _ouvrirDepuisUnPush(ref, ouvrir, caveId)),
  ));
}
