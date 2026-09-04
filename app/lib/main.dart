import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'features/offline/presentation/sync_provider.dart';
import 'features/monetization/admob_service.dart';
import 'shared/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  AppLogger.info('SYSTEM', 'Chatmelier app launched and centralized logging initialized');

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error('FLUTTER_UI', details.exceptionAsString(), details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('ASYNC_UNCAUGHT', error.toString(), error, stack);
    return true;
  };

  // Initialize Google Mobile Ads (AdMob) on supported mobile devices
  try {
    await AdMobService().initialize();
  } catch (e, stack) {
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
