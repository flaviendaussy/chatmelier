import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/presentation/wine_enrichment_diff_dialog.dart';

void main() {
  group('WineEnrichmentDiffDialog & User Overrides Protection Tests', () {
    testWidgets('Non-overridden fields are automatically updated without conflict', (tester) async {
      const currentWine = Wine(
        id: 'wine-1',
        name: 'Château Margaux',
        type: 'red',
        country: 'France',
        region: 'Bordeaux',
        vintage: 2015,
        userOverrides: [], // No manual overrides
      );

      final enrichedData = {
        'ideal_drinking_start': 2023,
        'ideal_drinking_end': 2045,
        'peak_drinking_start': 2028,
        'peak_drinking_end': 2038,
        'classification': 'Premier Grand Cru Classé',
        'appellation': 'Margaux',
        'tasting_notes': 'Arômes complexes de cassis, cèdre et violette.',
      };

      Map<String, dynamic>? appliedPayload;
      List<String>? updatedOverrides;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  WineEnrichmentDiffDialog.show(
                    context,
                    currentWine: currentWine,
                    enrichedData: enrichedData,
                    enrichedGrapes: const [Grape(name: 'Cabernet Sauvignon', pct: 90), Grape(name: 'Merlot', pct: 10)],
                    onApply: (payload, overrides) {
                      appliedPayload = payload;
                      updatedOverrides = overrides;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Since there were no user overrides, no conflicting diff items appear and submission applies auto payload
      expect(find.text('Différences Détectées'), findsOneWidget);
      await tester.tap(find.text('Appliquer la sélection'));
      await tester.pumpAndSettle();

      expect(appliedPayload, isNotNull);
      expect(appliedPayload!['peak_drinking_start'], 2028);
      expect(appliedPayload!['classification'], 'Premier Grand Cru Classé');
      expect(appliedPayload!['is_verified_online'], true);
      expect(updatedOverrides, isNotNull);
    });

    testWidgets('Manually overridden fields are protected and diff dialog allows selective adoption', (tester) async {
      const currentWine = Wine(
        id: 'wine-manual',
        name: 'Moillard Hautes Côtes de Nuits',
        type: 'red',
        country: 'France',
        region: 'Bourgogne',
        vintage: 2022,
        peakStart: 2030, // User manually set peakStart to 2030
        peakEnd: 2035,   // User manually set peakEnd to 2035
        userOverrides: ['peak_drinking_start', 'peak_drinking_end'],
      );

      final enrichedData = {
        'peak_drinking_start': 2027, // AI suggests 2027 instead of user's 2030
        'peak_drinking_end': 2031,   // AI suggests 2031 instead of user's 2035
        'appellation': 'Bourgogne Hautes Côtes de Nuits', // Not in overrides -> auto apply
      };

      Map<String, dynamic>? appliedPayload;
      List<String>? updatedOverrides;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  WineEnrichmentDiffDialog.show(
                    context,
                    currentWine: currentWine,
                    enrichedData: enrichedData,
                    enrichedGrapes: const [Grape(name: 'Pinot Noir', pct: 100)],
                    onApply: (payload, overrides) {
                      appliedPayload = payload;
                      updatedOverrides = overrides;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify diff items are shown with user manual values
      expect(find.text('Différences Détectées'), findsOneWidget);
      expect(find.text('Début d\'apogée'), findsOneWidget);
      expect(find.text('Fin d\'apogée'), findsOneWidget);
      expect(find.text('2030'), findsOneWidget); // User manual value
      expect(find.text('2027'), findsOneWidget); // AI proposal
      expect(find.text('2035'), findsOneWidget); // User manual value
      expect(find.text('2031'), findsOneWidget); // AI proposal

      // Case 1: Keep manual values (default without toggling switches)
      await tester.tap(find.text('Appliquer la sélection'));
      await tester.pumpAndSettle();

      expect(appliedPayload, isNotNull);
      // Non-overridden appellation was auto applied
      expect(appliedPayload!['appellation'], 'Bourgogne Hautes Côtes de Nuits');
      // Overridden peakStart was NOT overwritten by AI 2027
      expect(appliedPayload!.containsKey('peak_drinking_start'), isFalse);
      expect(updatedOverrides, contains('peak_drinking_start'));
      expect(updatedOverrides, contains('peak_drinking_end'));
    });
  });
}
