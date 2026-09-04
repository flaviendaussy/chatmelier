import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine_reverse_pairing_engine.dart';

void main() {
  group('V4 PDF, Extensions & Reverse Food Pairing Tests', () {
    const sampleRedWine = Wine(
      id: 'wine-bandol-001',
      name: 'Bandol Rouge Classique',
      producer: 'Domaine de Terrebrune',
      vintage: 2019,
      type: 'red',
      country: 'France',
      region: 'Provence',
      appellation: 'Bandol AOC',
      grapes: [
        Grape(name: 'Mourvèdre', pct: 85),
        Grape(name: 'Grenache', pct: 10),
        Grape(name: 'Cinsault', pct: 5),
      ],
      tastingNotes: 'Robe grenat intense, fruits noirs, garrigue, épices et tannins nobles.',
      foodPairings: ['Gigot d\'agneau', 'Côte de bœuf'],
      drinkStart: 2024,
      drinkEnd: 2039,
      peakStart: 2027,
      peakEnd: 2034,
      estimatedMarketValue: 38.0,
    );

    const sampleChampagne = Wine(
      id: 'wine-champagne-002',
      name: 'Cuvée Royale Brut',
      producer: 'Maison Pol Roger',
      vintage: 2015,
      type: 'sparkling',
      country: 'France',
      region: 'Champagne',
      appellation: 'Champagne AOC',
      grapes: [
        Grape(name: 'Chardonnay', pct: 60),
        Grape(name: 'Pinot Noir', pct: 40),
      ],
      tastingNotes: 'Bulle crémeuse, brioche, noisette et agrumes confits.',
      foodPairings: ['Huîtres', 'Ris de veau'],
      drinkStart: 2022,
      drinkEnd: 2032,
      peakStart: 2024,
      peakEnd: 2028,
      estimatedMarketValue: 65.0,
    );

    const sampleWhiteWine = Wine(
      id: 'wine-chablis-003',
      name: 'Chablis Grand Cru Les Clos',
      producer: 'Domaine Laroche',
      vintage: 2020,
      type: 'white',
      country: 'France',
      region: 'Bourgogne',
      appellation: 'Chablis Grand Cru AOC',
      grapes: [Grape(name: 'Chardonnay', pct: 100)],
      tastingNotes: 'Minéralité saline, coquille d\'huître, agrumes et tension.',
      foodPairings: ['Bar de ligne', 'Homard'],
      drinkStart: 2023,
      drinkEnd: 2035,
      estimatedMarketValue: 95.0,
    );

    test('WineReversePairingEngine generates gastronomic pairings for Red Wine (Bandol / Mourvèdre)', () {
      final pairings = WineReversePairingEngine.getPairingsForWine(sampleRedWine);
      expect(pairings, isNotEmpty);
      expect(pairings.any((p) => p.dishName.toLowerCase().contains('bœuf') || p.dishName.toLowerCase().contains('agneau')), isTrue);
      expect(pairings.first.affinityPct, greaterThanOrEqualTo(90));
      expect(pairings.first.molecularRationale, isNotEmpty);
      expect(pairings.first.cookingAdvice, isNotEmpty);
      expect(pairings.first.keyIngredients, isNotEmpty);
    });

    test('WineReversePairingEngine generates gastronomic pairings for Champagne', () {
      final pairings = WineReversePairingEngine.getPairingsForWine(sampleChampagne);
      expect(pairings, isNotEmpty);
      expect(pairings.any((p) => p.dishName.toLowerCase().contains('huître') || p.dishName.toLowerCase().contains('veau')), isTrue);
      expect(pairings.first.molecularRationale, contains('craie'));
    });

    test('WineReversePairingEngine generates gastronomic pairings for White Mineral Wine (Chablis)', () {
      final pairings = WineReversePairingEngine.getPairingsForWine(sampleWhiteWine);
      expect(pairings, isNotEmpty);
      expect(pairings.any((p) => p.dishName.toLowerCase().contains('bar') || p.dishName.toLowerCase().contains('chavignol')), isTrue);
    });

    test('Cellar Summary valuation and bottle grouping for PDF generation', () {
      final bottles = [
        Bottle(
          id: 'b1',
          cellarId: 'c1',
          wineId: sampleRedWine.id,
          wine: sampleRedWine,
          quantity: 3,
          purchasePrice: 35.0,
          currency: 'EUR',
          rack: 'B3',
          shelf: '1',
          status: 'in_cellar',
          ownerId: 'user-001',
          addedBy: 'user-001',
          createdAt: DateTime.now(),
        ),
        Bottle(
          id: 'b2',
          cellarId: 'c1',
          wineId: sampleChampagne.id,
          wine: sampleChampagne,
          quantity: 2,
          purchasePrice: 60.0,
          currency: 'EUR',
          rack: 'A1',
          shelf: '2',
          status: 'in_cellar',
          ownerId: 'user-001',
          addedBy: 'user-001',
          createdAt: DateTime.now(),
        ),
      ];

      final totalCount = bottles.fold<num>(0, (sum, b) => sum + b.quantity).toInt();
      expect(totalCount, equals(5));

      final totalEst = bottles.fold<num>(0.0, (sum, b) => sum + ((b.wine?.estimatedMarketValue ?? 0.0) * b.quantity)).toDouble();
      expect(totalEst, equals((38.0 * 3) + (65.0 * 2))); // 114 + 130 = 244
    });
  });
}
