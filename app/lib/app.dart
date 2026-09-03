import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'features/checkout/data/post_tasting_notification_service.dart';
import 'features/offline/data/connectivity_service.dart';

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
      locale: userLocale ?? const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      routerConfig: router,
      builder: (context, child) {
        // Initialize post-tasting notification checker with a valid context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(connectivityServiceProvider);
          final notifService = ref.read(postTastingNotificationProvider);
          notifService.init(context);
        });
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
