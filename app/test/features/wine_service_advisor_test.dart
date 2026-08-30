import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine_service_advisor.dart';
import 'package:chatmelier/shared/widgets/grape_chart.dart';

void main() {
  group('WineServiceAdvisor Tests', () {
    test('Young powerful Bordeaux should require 2 hours in carafe at 16-17°C', () {
      final currentYear = DateTime.now().year;
      final advice = WineServiceAdvisor.computeAdvice(
        wineType: 'red',
        vintage: currentYear - 3,
        region: 'Bordeaux',
        appellation: 'Margaux',
        producer: 'Château Margaux',
        wineName: 'Grand Vin',
      );

      expect(advice.minTemp, 16);
      expect(advice.maxTemp, 17);
      expect(advice.carafeMinutes, 120);
      expect(advice.carafeLabel, contains('2h'));
      expect(advice.glasswareType, contains('Bordeaux'));
    });

    test('Old mature Bordeaux (25 years) should NOT be carafed', () {
      final currentYear = DateTime.now().year;
      final advice = WineServiceAdvisor.computeAdvice(
        wineType: 'red',
        vintage: currentYear - 25,
        region: 'Bordeaux',
        appellation: 'Pauillac',
        producer: 'Château Latour',
        wineName: 'Premier Grand Cru',
      );

      expect(advice.minTemp, 17);
      expect(advice.maxTemp, 18);
      expect(advice.carafeMinutes, 0);
      expect(advice.carafeLabel, contains('Pas de caravage'));
      expect(advice.decantingAdvice, contains('Éviter le caravage'));
    });

    test('Delicate Burgundy Pinot Noir should recommend balloon glass and 14-16°C', () {
      final advice = WineServiceAdvisor.computeAdvice(
        wineType: 'red',
        vintage: 2021,
        region: 'Bourgogne',
        appellation: 'Vosne-Romanée',
        producer: 'Domaine de la Romanée-Conti',
        wineName: 'Vosne-Romanée',
      );

      expect(advice.minTemp, 14);
      expect(advice.maxTemp, 16);
      expect(advice.glasswareType, contains('ballon'));
    });

    test('Rich White Burgundy (Meursault) should recommend 11-13°C with mild decanting', () {
      final advice = WineServiceAdvisor.computeAdvice(
        wineType: 'white',
        vintage: 2020,
        region: 'Bourgogne',
        appellation: 'Meursault',
        producer: 'Domaine des Comtes Lafon',
        wineName: 'Charmes',
      );

      expect(advice.minTemp, 11);
      expect(advice.maxTemp, 13);
      expect(advice.carafeMinutes, 30);
      expect(advice.glasswareType, contains('Bourgogne blanc'));
    });

    test('Crisp White (Sancerre) should recommend 9-11°C with direct service', () {
      final advice = WineServiceAdvisor.computeAdvice(
        wineType: 'white',
        vintage: 2023,
        region: 'Vallée de la Loire',
        appellation: 'Sancerre',
        producer: 'Henri Bourgeois',
        wineName: 'Les Baronnes',
      );

      expect(advice.minTemp, 9);
      expect(advice.maxTemp, 11);
      expect(advice.carafeMinutes, 0);
      expect(advice.carafeLabel, contains('direct'));
    });

    test('Champagne / Sparkling should recommend 8-10°C in tulip glass', () {
      final advice = WineServiceAdvisor.computeAdvice(
        wineType: 'sparkling',
        vintage: 2012,
        region: 'Champagne',
        appellation: 'Champagne',
        producer: 'Dom Pérignon',
        wineName: 'Vintage',
      );

      expect(advice.minTemp, 8);
      expect(advice.maxTemp, 10);
      expect(advice.carafeMinutes, 0);
      expect(advice.glasswareType, contains('tulipe'));
    });

    test('Sweet wine (Sauternes) should recommend 7-9°C', () {
      final advice = WineServiceAdvisor.computeAdvice(
        wineType: 'sweet',
        vintage: 2015,
        region: 'Bordeaux',
        appellation: 'Sauternes',
        producer: 'Château d\'Yquem',
        wineName: 'Grand Vin',
      );

      expect(advice.minTemp, 7);
      expect(advice.maxTemp, 9);
      expect(advice.carafeMinutes, 15);
    });
  });

  group('WineOenologyAdvisor Tests', () {
    test('Grand Cru Bordeaux with explicit verified data should retain technical fields', () {
      final advice = WineOenologyAdvisor.computeAdvice(
        wineType: 'red',
        vintage: 2019,
        region: 'Bordeaux',
        appellation: 'Pauillac',
        producer: 'Château Latour',
        wineName: 'Premier Grand Cru Classé',
        explicitBarrelAging: '18 à 24 mois en barriques',
        explicitVinification: 'Égrappage total et tri optique',
        explicitMalolactic: '100% réalisée en barriques',
        explicitHarvest: 'Vendanges manuelles parcellaires',
        isVerified: true,
      );

      expect(advice.hasTechnicalData, isTrue);
      expect(advice.barrelAgingDuration, contains('18 à 24 mois'));
      expect(advice.vinificationMethod, contains('Égrappage total'));
      expect(advice.malolacticFermentation, contains('100% réalisée'));
      expect(advice.harvestMethod, contains('manuelles'));
      expect(advice.agingPotential, contains('20 à 40 ans'));
    });

    test('Wine without verified data should not fabricate technical details but compute aging potential', () {
      final advice = WineOenologyAdvisor.computeAdvice(
        wineType: 'white',
        vintage: 2020,
        region: 'Bourgogne',
        appellation: 'Chablis Grand Cru',
        producer: 'Domaine Laroche',
        wineName: 'Les Clos Grand Cru',
      );

      expect(advice.hasTechnicalData, isFalse);
      expect(advice.barrelAgingDuration, isNull);
      expect(advice.malolacticFermentation, isNull);
      expect(advice.agingPotential, contains('10 à 25 ans'));
    });
  });

  group('GrapeBlendResolver Tests', () {
    test('Chablis should resolve to 100% Chardonnay', () {
      final grapes = GrapeBlendResolver.resolveGrapes(
        existingGrapes: const [],
        wineType: 'white',
        appellation: 'Chablis Grand Cru',
        region: 'Bourgogne',
        wineName: 'Domaine Laroche Chablis Grand Cru',
      );

      expect(grapes.length, 1);
      expect(grapes.first.name, 'Chardonnay');
      expect(grapes.first.pct, 100);
    });

    test('Bordeaux Médoc should resolve typical sommelier encépagement for Médoc appellation', () {
      final grapes = GrapeBlendResolver.resolveGrapes(
        existingGrapes: const [],
        wineType: 'red',
        appellation: 'Pauillac',
        region: 'Bordeaux',
        wineName: 'Château Grand Vin',
      );

      expect(grapes.isNotEmpty, isTrue);
      expect(grapes.map((g) => g.name), containsAll(['Cabernet Sauvignon', 'Merlot', 'Cabernet Franc', 'Petit Verdot']));
      expect(grapes.first.name, 'Cabernet Sauvignon');
      expect(grapes.first.pct, 65.0);
      final totalPct = grapes.fold<double>(0.0, (sum, g) => sum + (g.pct ?? 0.0));
      expect(totalPct, 100.0);
    });
  });
}
