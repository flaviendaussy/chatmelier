import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/features/cellar/domain/cellar.dart';
import 'package:chatmelier/shared/services/cellar_location_service.dart';
import 'package:chatmelier/shared/widgets/wine_type_badge.dart';
import 'package:chatmelier/features/cellar/presentation/cellar_proximity_banner.dart';
import 'package:chatmelier/shared/providers/cellar_provider.dart';
import 'package:chatmelier/shared/l10n/fallback_localizations_delegates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cellar Proximity & Distant Warning Localization Tests', () {
    testWidgets('CellarProximityMatch formats explanation in English and French', (tester) async {
      final testCellar = Cellar(
        id: 'c1',
        name: 'Château Margaux Cellar',
        ownerId: 'u1',
        createdAt: DateTime(2026, 1, 1),
      );

      final gpsMatch = CellarProximityMatch(
        cellar: testCellar,
        matchType: ProximityMatchType.gps,
        distanceMeters: 9,
        explanation: 'Position GPS détectée à 9 m',
      );

      final wifiMatch = CellarProximityMatch(
        cellar: testCellar,
        matchType: ProximityMatchType.wifi,
        wifiSsid: 'Margaux-WiFi',
        explanation: 'Connecté au Wi-Fi "Margaux-WiFi"',
      );

      // 1. Test in English
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: kAppLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx);
              expect(gpsMatch.formatExplanation(l10n), 'GPS location detected at 9 m');
              expect(wifiMatch.formatExplanation(l10n), 'Connected to Wi-Fi "Margaux-WiFi"');
              return const SizedBox();
            },
          ),
        ),
      );

      // 2. Test in French
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: kAppLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx);
              expect(gpsMatch.formatExplanation(l10n), 'Position GPS détectée à 9 m');
              expect(wifiMatch.formatExplanation(l10n), 'Connecté au Wi-Fi "Margaux-WiFi"');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('DistantCellarCheck formats warnings in English and French', (tester) async {
      const check = DistantCellarCheck(
        isDistant: true,
        distanceKm: 9.0,
        otherCellarName: 'Cave Principale',
        targetCellarName: 'Cave de Bordeaux',
        warningMessage: 'Vous êtes actuellement situé à environ 9.0 km de "Cave de Bordeaux".',
      );

      // English
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: kAppLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx);
              final warning = check.formatWarning(l10n);
              expect(warning, 'You are currently located approximately 9.0 km from "Cave de Bordeaux".');
              return const SizedBox();
            },
          ),
        ),
      );

      // French
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: kAppLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx);
              final warning = check.formatWarning(l10n);
              expect(warning, 'Vous êtes actuellement situé à environ 9.0 km de "Cave de Bordeaux".');
              return const SizedBox();
            },
          ),
        ),
      );
    });

    test('WineTypeBadge respects languageCode', () {
      expect(WineTypeBadge.getLabel('red', 'en'), 'RED');
      expect(WineTypeBadge.getLabel('red', 'fr'), 'ROUGE');

      expect(WineTypeBadge.getLabel('white', 'en'), 'WHITE');
      expect(WineTypeBadge.getLabel('white', 'fr'), 'BLANC');

      expect(WineTypeBadge.getLabel('sparkling', 'en'), 'SPARKLING');
      expect(WineTypeBadge.getLabel('sparkling', 'fr'), 'BULLES');

      expect(WineTypeBadge.getLabel('dessert', 'en'), 'DESSERT');
      expect(WineTypeBadge.getLabel('dessert', 'fr'), 'MOELLEUX');

      expect(WineTypeBadge.getLabel('fortified', 'en'), 'FORTIFIED');
      expect(WineTypeBadge.getLabel('fortified', 'fr'), 'FORTIFIÉ');

      expect(WineTypeBadge.getLabel('whiskey', 'en'), 'WHISKEY');
      expect(WineTypeBadge.getLabel('whiskey', 'fr'), 'WHISKY');
    });

    testWidgets('CellarProximityBanner renders in English when app language is English', (tester) async {
      final detectedCellar = Cellar(
        id: 'cellar_nearby',
        name: 'Home Cellar',
        ownerId: 'u1',
        createdAt: DateTime(2026, 1, 1),
      );

      final proximityMatch = CellarProximityMatch(
        cellar: detectedCellar,
        matchType: ProximityMatchType.gps,
        distanceMeters: 9,
        explanation: 'Position GPS détectée à 9 m',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userCellarsProvider.overrideWith((ref) async => [
                  {'id': 'cellar_other', 'name': 'Country Cellar', 'role': 'owner'},
                  {'id': 'cellar_nearby', 'name': 'Home Cellar', 'role': 'owner'},
                ]),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: kAppLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CellarProximityBanner(
                initialMatch: proximityMatch,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check English banner contents
      expect(find.text('Cellar detected: '), findsOneWidget);
      expect(find.text('Home Cellar'), findsOneWidget);
      expect(find.text('GPS location detected at 9 m'), findsOneWidget);
      expect(find.text('Switch'), findsOneWidget);
      expect(find.byTooltip('Ignore'), findsOneWidget);

      // Verify no French remains in English view
      expect(find.text('Cave détectée : '), findsNothing);
      expect(find.text('Position GPS détectée à 9 m'), findsNothing);
      expect(find.text('Basculer'), findsNothing);
      expect(find.byTooltip('Ignorer'), findsNothing);
    });

    testWidgets('CellarProximityBanner renders in French when app language is French', (tester) async {
      final detectedCellar = Cellar(
        id: 'cellar_nearby',
        name: 'Cave Maison',
        ownerId: 'u1',
        createdAt: DateTime(2026, 1, 1),
      );

      final proximityMatch = CellarProximityMatch(
        cellar: detectedCellar,
        matchType: ProximityMatchType.gps,
        distanceMeters: 9,
        explanation: 'Position GPS détectée à 9 m',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userCellarsProvider.overrideWith((ref) async => [
                  {'id': 'cellar_other', 'name': 'Cave Campagne', 'role': 'owner'},
                  {'id': 'cellar_nearby', 'name': 'Cave Maison', 'role': 'owner'},
                ]),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: kAppLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CellarProximityBanner(
                initialMatch: proximityMatch,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check French banner contents
      expect(find.text('Cave détectée : '), findsOneWidget);
      expect(find.text('Cave Maison'), findsOneWidget);
      expect(find.text('Position GPS détectée à 9 m'), findsOneWidget);
      expect(find.text('Basculer'), findsOneWidget);
      expect(find.byTooltip('Ignorer'), findsOneWidget);
    });
  });
}
