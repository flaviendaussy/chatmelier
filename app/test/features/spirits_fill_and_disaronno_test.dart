import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';
import 'package:chatmelier/shared/widgets/spirit_fill_bar.dart';

void main() {
  group('🥃 Disaronno & Spirit Classification Tests', () {
    test('Disaronno Originale is classified as liqueur, NEVER as gin', () {
      final wine = Wine.fromJson({
        'id': 'test_disaronno',
        'name': 'Disaronno Originale',
        'producer': 'Illva Saronno',
        'region': 'Lombardie',
        'country': 'Italie',
      });

      expect(wine.type, equals('liqueur'));
      expect(wine.type, isNot(equals('gin')));
      expect(wine.isSpirit, isTrue);
    });

    test('Disaronno Velvet is classified as liqueur', () {
      final wine = Wine.fromJson({
        'id': 'test_disaronno_velvet',
        'name': 'Disaronno Velvet Cream Liqueur',
        'producer': 'Illva Saronno',
      });

      expect(wine.type, equals('liqueur'));
      expect(wine.isSpirit, isTrue);
    });

    test('Amaretto di Saronno is classified as liqueur', () {
      final wine = Wine.fromJson({
        'id': 'test_amaretto',
        'name': 'Amaretto di Saronno Classico',
        'producer': 'Saronno',
      });

      expect(wine.type, equals('liqueur'));
      expect(wine.isSpirit, isTrue);
    });

    test('ScanResult parses Disaronno Originale as liqueur', () {
      final scanResult = ScanResult.fromJson({
        'name': 'Disaronno Originale Amaretto',
        'producer': 'Illva Saronno',
        'region': 'Lombardy',
        'country': 'Italy',
      });

      expect(scanResult.wineType, equals('liqueur'));
      expect(scanResult.wineType, isNot(equals('gin')));
    });

    test('Authentic Gin with boundary match is classified as gin', () {
      final wine = Wine.fromJson({
        'id': 'test_gin',
        'name': 'Tanqueray London Dry Gin',
        'producer': 'Tanqueray',
      });

      expect(wine.type, equals('gin'));
      expect(wine.isSpirit, isTrue);
    });

    test('Words containing "gin" inside other words do NOT trigger gin classification', () {
      final wine = Wine.fromJson({
        'id': 'test_virginia',
        'name': 'Virginia Highland Red Wine',
        'producer': 'Virginia Estate',
        'type': 'red',
      });

      expect(wine.type, equals('red'));
      expect(wine.type, isNot(equals('gin')));
    });

    test('Ginger Liqueur is classified as liqueur, not gin', () {
      final wine = Wine.fromJson({
        'id': 'test_ginger_liqueur',
        'name': 'Domaine de Canton French Ginger Liqueur',
        'producer': 'Domaine de Canton',
      });

      expect(wine.type, equals('liqueur'));
      expect(wine.type, isNot(equals('gin')));
    });
  });

  group('📊 SpiritFillBar Widget Tests', () {
    testWidgets('Renders 75% fill level with correct percentage label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: SpiritFillBar(
                  fillLevel: 75,
                  spiritType: 'whisky',
                  showLabel: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('75%'), findsOneWidget);
      expect(find.byType(SpiritFillBar), findsOneWidget);
    });

    testWidgets('Renders compact mode without percentage label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: SpiritFillBar(
                  fillLevel: 30,
                  spiritType: 'liqueur',
                  compact: true,
                  showLabel: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('30%'), findsNothing);
      expect(find.byType(SpiritFillBar), findsOneWidget);
    });

    testWidgets('Clamps fill level between 0 and 100 safely', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: SpiritFillBar(
                  fillLevel: 100,
                  spiritType: 'gin',
                  showLabel: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('100%'), findsOneWidget);
    });
  });
}
