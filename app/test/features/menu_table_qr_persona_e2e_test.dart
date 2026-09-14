import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/l10n/fallback_localizations_delegates.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/data/menu_table_session_manager.dart';
import 'package:chatmelier/features/menu_scan/presentation/menu_table_consensus_guest_screen.dart';

void main() {
  group('👥 Menu Table QR Code & Multi-Persona E2E Flow', () {
    const testSessionId = 'TABLE77';
    final hostMenu = ScannedMenu(
      id: 'menu_chez_graziano',
      restaurantName: 'Osteria di Graziano',
      scannedAt: DateTime(2026, 9, 13, 19, 30),
      pagePhotoPaths: const ['/tmp/menu_page1.jpg'],
      wines: const [
        MenuWine(
          id: 'w_chablis',
          name: 'Chablis 1er Cru Montée de Tonnerre',
          producer: 'Billaud-Simon',
          wineType: 'Blanc',
          appellation: 'Chablis',
          region: 'Bourgogne',
          vintage: 2021,
          bottlePrice: 58.0,
          metrics: MenuWineRadarMetrics(
            tannins: 0.0,
            acidity: 8.0,
            body: 5.5,
            fruit: 6.5,
            minerality: 8.5,
          ),
        ),
        MenuWine(
          id: 'w_madiran',
          name: 'Madiran Château Bouscassé Vieilles Vignes',
          producer: 'Alain Brumont',
          wineType: 'Rouge',
          appellation: 'Madiran',
          region: 'Sud-Ouest',
          vintage: 2016,
          bottlePrice: 52.0,
          metrics: MenuWineRadarMetrics(
            tannins: 9.5, // Très tannique et astringent
            acidity: 5.0,
            body: 9.0,
            oak: 7.5,
          ),
        ),
        MenuWine(
          id: 'w_fleurie',
          name: 'Fleurie Clos de la Roilette',
          producer: 'Coudert',
          wineType: 'Rouge',
          appellation: 'Beaujolais',
          region: 'Beaujolais',
          vintage: 2022,
          bottlePrice: 42.0,
          metrics: MenuWineRadarMetrics(
            tannins: 2.5, // Tanins fondus et soyeux
            acidity: 6.5,
            body: 5.0,
            fruit: 8.5,
          ),
        ),
      ],
    );

    test('Host step: Generates valid QR URL containing session and compressed menu data', () {
      MenuTableSessionManager.registerSession(testSessionId, hostMenu);

      final qrUrl = MenuTableSessionManager.buildQrUrl(
        sessionId: testSessionId,
        menu: hostMenu,
      );

      expect(qrUrl, startsWith('https://chatmelier.github.io/table-consensus'));
      expect(qrUrl, contains('session=TABLE77'));
      expect(qrUrl, contains('&data='));

      final uri = Uri.parse(qrUrl);
      expect(uri.queryParameters['session'], equals('TABLE77'));
      final rawData = uri.queryParameters['data'];
      expect(rawData, isNotNull);
      expect(rawData!.isNotEmpty, isTrue);

      // Verify payload can be decompressed back to restaurant menu
      final decodedMenu = MenuTableSessionManager.decodeMenuPayload(rawData);
      expect(decodedMenu, isNotNull);
      expect(decodedMenu!.restaurantName, equals('Osteria di Graziano'));
      expect(decodedMenu.wines.length, equals(3));
      expect(decodedMenu.wines[0].name, contains('Chablis'));
      expect(decodedMenu.wines[1].name, contains('Madiran'));
    });

    testWidgets('Persona 1 (Webapp guest): Scans QR on mobile web, views menu without auth, and joins table', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Host builds QR link
      final qrUrl = MenuTableSessionManager.buildQrUrl(
        sessionId: testSessionId,
        menu: hostMenu,
      );
      final uri = Uri.parse(qrUrl);
      final sessionId = uri.queryParameters['session'];
      final dataPayload = uri.queryParameters['data'];

      // 2. Persona 1 opens web route without logging in
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: kAppLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MenuTableConsensusGuestScreen(
            initialSessionId: sessionId,
            initialData: dataPayload,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Verify screen rendered menu content immediately
      expect(find.text('Osteria di Graziano'), findsOneWidget);
      expect(find.textContaining('Consensus de Table Multi-Palais'), findsOneWidget);
      expect(find.text('Hôte de la table (Curieux & Éclectique)'), findsOneWidget);

      // 4. Verify initial top 3 list is visible
      expect(find.text('LES 3 MEILLEURES BOUTEILLES POUR LA TABLE'), findsOneWidget);

      // 5. Persona 1 inputs name and sets aversion to heavy tannins
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Camille');
      await tester.pumpAndSettle();

      // Submit preferences
      final joinButton = find.text('Valider mes goûts pour la table');
      expect(joinButton, findsOneWidget);
      await tester.tap(joinButton);
      await tester.pumpAndSettle();

      // 6. Verify Camille is added to guest list
      expect(find.textContaining('Camille'), findsWidgets);
      expect(find.textContaining('Aversion aux tanins durs'), findsWidgets);

      // 7. Verify consensus update: Chablis or Fleurie (low tannin) is recommended,
      // and Madiran (tannins: 9.5) triggers aversion warning for Camille
      expect(find.textContaining('Chablis 1er Cru'), findsWidgets);
      expect(find.textContaining('Fleurie Clos de la Roilette'), findsWidgets);
      expect(find.textContaining('a une aversion pour les tanins durs'), findsOneWidget);
    });

    testWidgets('Persona 2 (App user): Scans QR deep link inside app and instantly joins session', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Clear in-memory session to ensure full independence on data payload fallback
      final qrUrl = MenuTableSessionManager.buildQrUrl(
        sessionId: 'STANDALONE_SESSION',
        menu: hostMenu,
      );
      final uri = Uri.parse(qrUrl);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: kAppLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MenuTableConsensusGuestScreen(
            initialSessionId: uri.queryParameters['session'],
            initialData: uri.queryParameters['data'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and top 3 bottles
      expect(find.text('Osteria di Graziano'), findsOneWidget);
      expect(find.textContaining('3 vins analysés pour 1 convives'), findsOneWidget);
      expect(find.text('Chablis 1er Cru Montée de Tonnerre'), findsOneWidget);
    });
  });
}
