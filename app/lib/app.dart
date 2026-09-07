import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'features/checkout/data/post_tasting_notification_service.dart';
import 'features/offline/data/connectivity_service.dart';
import 'features/monetization/admob_service.dart';
import 'shared/providers/premium_provider.dart';

import 'features/feedback/data/shake_feedback_service.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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
        // Initialize post-tasting notification checker and App Open Ads
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
        });
        return RepaintBoundary(
          key: ShakeFeedbackService.rootRepaintBoundaryKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
