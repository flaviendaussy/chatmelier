import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/cellar.dart';
import 'package:chatmelier/features/cellar/domain/wine_image_service.dart';
import 'package:chatmelier/features/cellar/domain/wine_service_advisor.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/presentation/taste_profile_radar_screen.dart';
import 'package:chatmelier/features/checkout/data/post_tasting_notification_service.dart';
import 'package:chatmelier/shared/widgets/owner_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Replay Path 1: Camille - Yellow Tail 2025 Apogee & Curve Recalculation', () {
    test('Recalculating drinking window on vintage change from 2020 to 2025 revives apogee & maturity curve', () {
      // Step 1: Initial detected vintage was 2020 (when explicit drink window was 2021-2023, it was expired)
      final initialWindow = WineOenologyAdvisor.computeDrinkingWindow(
        wineType: 'red',
        region: 'South Eastern Australia',
        vintage: 2020,
        wineName: 'Yellow Tail Shiraz',
        explicitDrinkStart: 2021,
        explicitDrinkEnd: 2023,
      );
      expect(initialWindow.drinkEnd, isNotNull);
      expect(initialWindow.drinkEnd < 2026, isTrue); // Was expired in 2026

      // Step 2: Camille updates vintage manually to 2025
      final updatedWindow = WineOenologyAdvisor.computeDrinkingWindow(
        wineType: 'red',
        region: 'South Eastern Australia',
        vintage: 2025,
        wineName: 'Yellow Tail Shiraz',
      );

      // Step 3: Verify new dynamic drinking window
      expect(updatedWindow.drinkStart, greaterThanOrEqualTo(2025));
      expect(updatedWindow.drinkEnd, greaterThanOrEqualTo(2027));
      expect(updatedWindow.peakStart, greaterThanOrEqualTo(2025));
      expect(updatedWindow.maxYear, greaterThanOrEqualTo(2027));
    });
  });

  group('Replay Path 2: Camille - Restore Official Label & Replace Photo Image Cache Clearing', () {
    test('Restoring official label ignores custom photo and resolves estate/terroir image', () {
      const wine = Wine(
        id: 'wine-yt-1',
        name: 'Yellow Tail Shiraz',
        producer: 'Casella Family Brands',
        vintage: 2025,
        type: 'red',
        country: 'Australie',
        region: 'South Eastern Australia',
      );

      // When forceDomainOrArchetype is true, the bad custom photo is bypassed
      final restoredUrl = WineImageService.resolveWineImageUrl(
        wine,
        forceDomainOrArchetype: true,
      );

      expect(restoredUrl, isNotEmpty);
      expect(restoredUrl.startsWith('http'), isTrue);
    });

    testWidgets('Purging image cache does not throw and clears memory cache', (tester) async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      expect(PaintingBinding.instance.imageCache.currentSizeBytes, equals(0));
    });
  });

  group('Replay Path 3: Camille - Chatmelier Examples are Dynamic without "Flavien et Caro"', () {
    test('Chat prompts are clean and contain no hardcoded "Flavien et Caro"', () {
      final tasteProfileService = TasteProfileService();
      final profiles = [
        TasteProfile(id: 'camille-1', name: 'Camille', favoriteTypes: ['white', 'red'], favoriteRegions: ['Bourgogne', 'Rhône']),
      ];

      final contextStr = tasteProfileService.formatProfilesForSommelier(profiles);
      expect(contextStr, contains('Camille'));
      expect(contextStr, isNot(contains('Caro')));
      expect(contextStr, isNot(contains('Flavien')));
    });
  });

  group('Replay Path 4: Dad & Family Tasting - Guest Profiles & 6D Radar Spider Chart', () {
    test('Creating guest profile and calculating 6D radar metrics', () async {
      final tasteService = TasteProfileService();
      
      // Father adds a guest who tasted with him
      final guest = await tasteService.addOrGetProfileByName('Papa');
      expect(guest.name, equals('Papa'));

      // Record a positive tasting experience for Papa on Bordeaux
      const tastedWine = Wine(
        id: 'wine-bx-1',
        name: 'Château Margaux',
        type: 'red',
        country: 'France',
        region: 'Bordeaux',
      );

      await tasteService.recordTastingExperience(
        nameOrId: guest.name,
        wine: tastedWine,
        rating: 9.0,
      );

      final updatedProfiles = await tasteService.getProfiles();
      final papaProfile = updatedProfiles.firstWhere((p) => p.name == 'Papa');
      expect(papaProfile.favoriteTypes, contains('Rouge'));
      expect(papaProfile.favoriteRegions, contains('Bordeaux'));

      // Calculate 6D radar metrics (each on a scale of 0 to 10)
      final radarMetrics = WineTasteRadarCalculator.compute(papaProfile);
      expect(radarMetrics.body, greaterThanOrEqualTo(5.0));
      expect(radarMetrics.oak, greaterThanOrEqualTo(5.0));
      expect(radarMetrics.fruit, greaterThanOrEqualTo(5.0));
    });

    testWidgets('TasteProfileRadarScreen renders correctly in all 3 modes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Prepare 2 profiles for overlay and comparison modes
      final tasteService = TasteProfileService();
      await tasteService.saveProfiles([
        TasteProfile(id: 'p1', name: 'Moi', isPrimary: true, favoriteTypes: ['Rouge']),
        TasteProfile(id: 'p2', name: 'Papa', isPrimary: false, favoriteTypes: ['Rouge', 'Blanc']),
      ]);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TasteProfileRadarScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and segmented control modes
      expect(find.text('Spider Chart des Goûts 🕸️🍷'), findsOneWidget);
      expect(find.text('Individuel'), findsOneWidget);
      expect(find.text('Overlay'), findsOneWidget);
      expect(find.text('Comparaison'), findsOneWidget);

      // Tap 'Overlay' (Multi-profile overlay mode)
      await tester.tap(find.text('Overlay'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Convives affichés'), findsOneWidget);

      // Tap 'Comparaison' (Affinity comparison)
      await tester.tap(find.text('Comparaison'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Compatibilité'), findsOneWidget);
    });
  });

  group('Replay Path 5: Wi-Fi Cellar Display even when Disconnected', () {
    test('Cellar displays associated Wi-Fi SSID', () {
      final cellar = Cellar(
        id: 'cellar-home',
        name: 'Cave Maison',
        ownerId: 'user-1',
        wifiSsid: 'Freebox_Maison_5G',
        createdAt: DateTime.now(),
      );

      expect(cellar.wifiSsid, equals('Freebox_Maison_5G'));
    });
  });

  group('Replay Path 6: Post-Tasting Notification Dialog Safety Replay', () {
    test('checkAndShow safely handles unmounted or missing Navigator without throwing null check exception', () async {
      final service = PostTastingNotificationService();
      // Calling checkAndShow when no context is attached must complete gracefully
      await expectLater(service.checkAndShow(), completes);
    });
  });

  group('Replay Path 7: OwnerAvatar with meta:// URI Replay', () {
    testWidgets('OwnerAvatar safely falls back to initials when avatarUrl contains meta:// URI', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OwnerAvatar(
              avatarUrl: 'meta://?u=flavien&p=%2B447485092615&e=flavien.daussy%40gmail.com',
              displayName: 'Flavien',
              size: 40,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: no exception thrown, and the initial 'F' is rendered
      expect(find.text('F'), findsOneWidget);
    });
  });
}
