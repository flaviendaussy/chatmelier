import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/presentation/widgets/wine_taste_radar_chart.dart';
import 'package:chatmelier/features/auth/presentation/taste_profile_radar_screen.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Wine Taste Radar Calculator Tests', () {
    test('Calculates balanced default metrics for neutral profile', () {
      const profile = TasteProfile(
        id: 'p1',
        name: 'Moi',
        isPrimary: true,
      );

      final metrics = WineTasteRadarCalculator.compute(profile);
      expect(metrics.body, inInclusiveRange(1.0, 10.0));
      expect(metrics.acidity, inInclusiveRange(1.0, 10.0));
      expect(metrics.fruit, inInclusiveRange(1.0, 10.0));
      expect(metrics.oak, inInclusiveRange(1.0, 10.0));
      expect(metrics.minerality, inInclusiveRange(1.0, 10.0));
      expect(metrics.sweetness, inInclusiveRange(0.5, 10.0));
    });

    test('Bordeaux and Syrah lover gets higher body and oak scores', () {
      const bordeauxProfile = TasteProfile(
        id: 'papa',
        name: 'Papa',
        favoriteTypes: ['Rouge'],
        favoriteRegions: ['Bordeaux', 'Vallée du Rhône'],
        favoriteGrapes: ['Cabernet Sauvignon', 'Syrah'],
      );

      final metrics = WineTasteRadarCalculator.compute(bordeauxProfile);
      expect(metrics.body, greaterThan(7.0));
      expect(metrics.oak, greaterThan(5.5));
    });

    test('Chablis and Champagne lover gets higher acidity and minerality', () {
      const freshProfile = TasteProfile(
        id: 'camille',
        name: 'Camille',
        favoriteTypes: ['Blanc sec', 'Champagne'],
        favoriteRegions: ['Bourgogne', 'Chablis'],
        favoriteGrapes: ['Chardonnay', 'Sauvignon Blanc'],
      );

      final metrics = WineTasteRadarCalculator.compute(freshProfile);
      expect(metrics.acidity, greaterThan(7.5));
      expect(metrics.minerality, greaterThan(7.0));
    });

    test('Disliked characteristics penalize specific axes', () {
      const antiOakProfile = TasteProfile(
        id: 'sophie',
        name: 'Sophie',
        favoriteTypes: ['Rouge'],
        dislikedCharacteristics: ['Trop boisé', 'Trop acide'],
      );

      final metrics = WineTasteRadarCalculator.compute(antiOakProfile);
      expect(metrics.oak, lessThanOrEqualTo(2.5));
      expect(metrics.acidity, lessThanOrEqualTo(3.5));
    });

    test('Taste affinity comparison between two profiles produces affinity score and sommelier advice', () {
      const papa = TasteProfile(
        id: 'p1',
        name: 'Papa',
        favoriteTypes: ['Rouge'],
        favoriteRegions: ['Vallée du Rhône'],
        favoriteGrapes: ['Syrah', 'Grenache'],
      );

      const maman = TasteProfile(
        id: 'p2',
        name: 'Maman',
        favoriteTypes: ['Rouge', 'Blanc'],
        favoriteRegions: ['Vallée du Rhône', 'Provence'],
        favoriteGrapes: ['Grenache', 'Viognier'],
      );

      final affinity = WineTasteRadarCalculator.compare(papa, maman);
      expect(affinity.affinityPercentage, inInclusiveRange(50.0, 99.0));
      expect(affinity.commonGroundsSummary, isNotEmpty);
      expect(affinity.idealWineRecommendation, isNotEmpty);
    });
  });

  group('TasteProfileService Guest & Companion Management', () {
    test('addOrGetProfileByName finds existing profile or creates guest profile', () async {
      final service = TasteProfileService();

      // Create Papa
      final papa = await service.addOrGetProfileByName('Papa');
      expect(papa.name, 'Papa');
      expect(papa.id, isNotEmpty);

      // Call again with same name
      final samePapa = await service.addOrGetProfileByName('papa');
      expect(samePapa.id, papa.id);

      final profiles = await service.getProfiles();
      expect(profiles.any((p) => p.name == 'Papa'), isTrue);
    });

    test('recordTastingExperience enriches profile preferences on high rating', () async {
      final service = TasteProfileService();
      final papa = await service.addOrGetProfileByName('Papa');

      const wine = Wine(
        id: 'w1',
        name: 'Châteauneuf-du-Pape',
        producer: 'Domaine du Pégau',
        vintage: 2019,
        country: 'France',
        region: 'Vallée du Rhône',
        type: 'red',
        grapes: [Grape(name: 'Grenache', pct: 80)],
      );

      await service.recordTastingExperience(
        nameOrId: papa.id,
        wine: wine,
        rating: 9.0,
      );

      final updatedProfiles = await service.getProfiles();
      final updatedPapa = updatedProfiles.firstWhere((p) => p.id == papa.id);
      expect(updatedPapa.favoriteRegions, contains('Vallée du Rhône'));
      expect(updatedPapa.favoriteGrapes, contains('Grenache'));
    });
  });

  group('Wine Taste Radar Widget Tests', () {
    testWidgets('WineTasteRadarChart paints without throwing exceptions', (tester) async {
      final dataset = RadarChartDataset(
        label: 'Papa',
        metrics: WineTasteRadarMetrics.balanced,
        color: const Color(0xFF8B1E3F),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WineTasteRadarChart(
                datasets: [dataset],
                size: 250,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(WineTasteRadarChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('TasteProfileRadarScreen displays segmented modes and switches between them', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TasteProfileRadarScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spider Chart des Goûts 🕸️🍷'), findsOneWidget);
      expect(find.text('Individuel'), findsOneWidget);
      expect(find.text('Overlay'), findsOneWidget);
      expect(find.text('Comparaison'), findsOneWidget);

      // Switch to Overlay mode
      await tester.tap(find.text('Overlay'));
      await tester.pumpAndSettle();
      expect(find.text('Overlay'), findsOneWidget);

      // Switch to Comparison mode
      await tester.tap(find.text('Comparaison'));
      await tester.pumpAndSettle();
      expect(find.text('Comparaison'), findsOneWidget);
    });
  });
}
