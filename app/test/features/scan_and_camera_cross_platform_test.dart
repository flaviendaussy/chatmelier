import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatmelier/features/scan/data/scan_service.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';
import 'package:chatmelier/features/scan/presentation/review_screen.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

void main() {
  group('ScanService & JSON Extraction Tests', () {
    test('extractJsonFromText handles markdown code blocks and raw JSON', () {
      const rawWithMarkdown = '''
      Here is your analysis:
      ```json
      {
        "name": "Château Margaux",
        "producer": "Château Margaux",
        "vintage": 2015,
        "wine_type": "red",
        "country": "France",
        "region": "Bordeaux",
        "appellation": "Margaux",
        "detected_quantity": 1
      }
      ```
      ''';

      final parsed = ScanService.extractJsonFromText(rawWithMarkdown);
      expect(parsed, isNotNull);
      expect(parsed!['name'], equals('Château Margaux'));
      expect(parsed['vintage'], equals(2015));
      expect(parsed['detected_quantity'], equals(1));
    });

    test('ScanResult.fromJson handles full enological and quantity attributes', () {
      final json = {
        'name': 'Domaine de Terrebrune Rouge',
        'producer': 'Domaine de Terrebrune',
        'vintage': 2019,
        'wine_type': 'red',
        'country': 'France',
        'region': 'Provence',
        'sub_region': 'Bandol',
        'appellation': 'Bandol AOP',
        'classification': 'AOC Bandol',
        'alcohol_pct': 14.0,
        'grapes': [
          {'name': 'Mourvèdre', 'pct': 85},
          {'name': 'Grenache', 'pct': 10},
          {'name': 'Cinsault', 'pct': 5},
        ],
        'tasting_notes': 'Fruits noirs, garrigue, épices et superbe fraîcheur minérale.',
        'food_pairings': ['Gigot d\'agneau', 'Daube provençale'],
        'ideal_drinking_start': 2024,
        'ideal_drinking_end': 2044,
        'peak_drinking_start': 2027,
        'peak_drinking_end': 2037,
        'estimated_market_value': 38.0,
        'detected_quantity': 6,
        'packaging_type': 'carton_6',
      };

      final result = ScanResult.fromJson(json);
      expect(result.name, equals('Domaine de Terrebrune Rouge'));
      expect(result.producer, equals('Domaine de Terrebrune'));
      expect(result.vintage, equals(2019));
      expect(result.grapes.length, equals(3));
      expect(result.grapes.first.name, equals('Mourvèdre'));
      expect(result.grapes.first.pct, equals(85));
      expect(result.detectedQuantity, equals(6));
      expect(result.packagingType, equals('carton_6'));
    });
  });

  group('ReviewScreen Widget Tests', () {
    testWidgets('ReviewScreen renders manual entry form cleanly without error', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ReviewScreen(
              imagePath: '',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fiche de la Bouteille'), findsOneWidget);
      expect(find.text('Informations Générales'), findsOneWidget);
      expect(find.text('Nom du vin *'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
    });
  });
}
