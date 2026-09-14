import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';
import '../helpers/benchmark/benchmark_bottle_catalog.dart';
import '../helpers/benchmark/benchmark_menu_catalog.dart';
import '../helpers/benchmark/real_world_bottle_generator.dart';
import '../helpers/benchmark/scan_accuracy_scorer.dart';

void main() {
  group('1. Benchmark Bottle Catalog Integrity Tests', () {
    test('catalog contains all 13 canonical worldwide control bottles', () {
      expect(BenchmarkBottleCatalog.bottles.length, equals(13));
      final categories = BenchmarkBottleCatalog.bottles.map((b) => b.category).toSet();
      expect(categories, containsAll([
        'bordeaux_blend',
        'burgundy_parcel',
        'champagne_nv',
        'rhone_syrah',
        'loire_sauvignon',
        'alsace_riesling',
        'italy_barolo',
        'spain_rioja',
        'california_cabernet',
        'argentina_malbec',
        'australia_shiraz',
        'germany_spatlese',
        'spirit_cognac',
      ]));
    });

    test('all benchmark bottles have mathematically sound grape percentages and apogees', () {
      for (final bottle in BenchmarkBottleCatalog.bottles) {
        expect(bottle.name, isNotEmpty);
        expect(bottle.producer, isNotEmpty);
        expect(bottle.alcoholPct, isPositive);
        expect(bottle.simulatedLabelLines, isNotEmpty);

        if (bottle.grapes.isNotEmpty) {
          final totalGrapesPct = bottle.grapes.fold<double>(0.0, (sum, g) => sum + (g.pct ?? 0.0));
          expect(totalGrapesPct.round(), equals(100), reason: 'Grape blend percentages for ${bottle.name} must sum to 100%');
        }

        if (bottle.idealDrinkingStart != null && bottle.idealDrinkingEnd != null) {
          expect(bottle.idealDrinkingStart!, lessThanOrEqualTo(bottle.idealDrinkingEnd!),
              reason: 'Ideal drinking start must be <= end for ${bottle.name}');
        }

        final scanResult = bottle.toExpectedScanResult();
        expect(scanResult.name, equals(bottle.name));
        expect(scanResult.producer, equals(bottle.producer));
        expect(scanResult.vintage, equals(bottle.vintage));
      }
    });

    test('champagne non-vintage and cognac handle null vintage gracefully', () {
      final krug = BenchmarkBottleCatalog.getById('bt_champagne_krug');
      expect(krug.vintage, isNull);
      expect(krug.wineType, equals('sparkling'));

      final cognac = BenchmarkBottleCatalog.getById('bt_spirit_delamain_pale_dry');
      expect(cognac.vintage, isNull);
      expect(cognac.wineType, equals('spirit'));
      expect(cognac.alcoholPct, equals(40.0));
    });
  });

  group('2. Benchmark Menu Catalog & OCR Ground Truth Tests', () {
    test('catalog contains 4 distinct realistic restaurant menu archetypes', () {
      expect(BenchmarkMenuCatalog.menus.length, equals(4));
      final categories = BenchmarkMenuCatalog.menus.map((m) => m.category).toSet();
      expect(categories, containsAll(['bistrot', 'three_stars', 'natural_wine_bar', 'trattoria']));
    });

    test('bistrot menu includes glass and bottle pricing with deal and gem flags', () {
      final bistrot = BenchmarkMenuCatalog.getById('menu_bistrot_parisien');
      expect(bistrot.expectedWines.length, equals(10));

      final glassWines = bistrot.expectedWines.where((w) => w.glassPrices.isNotEmpty).toList();
      expect(glassWines.length, greaterThanOrEqualTo(5), reason: 'Bistrot must feature wines by the glass');

      final gems = bistrot.expectedWines.where((w) => w.isGem).toList();
      expect(gems.length, greaterThanOrEqualTo(3));

      final deals = bistrot.expectedWines.where((w) => w.isDeal).toList();
      expect(deals.length, greaterThanOrEqualTo(3));
    });

    test('gastronomic 3-star menu has prestigious bottles with high pricing integrity', () {
      final threeStars = BenchmarkMenuCatalog.getById('menu_gastronomique_3etoiles');
      expect(threeStars.expectedWines.length, equals(10));
      expect(threeStars.expectedWines.every((w) => w.bottlePrice != null && w.bottlePrice! >= 200.0), isTrue);
    });
  });

  group('3. Procedural Real-World Bottle Generator Tests', () {
    test('generates 50 legitimate real-world wines without database collisions', () {
      final batch = RealWorldBottleGenerator.generateBatch(50);
      expect(batch.length, equals(50));

      final ids = batch.map((b) => b.id).toSet();
      expect(ids.length, equals(50), reason: 'Every generated bottle must have a distinct unique ID');

      for (final bottle in batch) {
        // Assert absence of default test fixture collisions
        expect(bottle.id.startsWith('gen_real_'), isTrue);
        expect(bottle.producer, isNotEmpty);
        expect(bottle.appellation, isNotEmpty);
        expect(bottle.country, isNotEmpty);
        expect(bottle.vintage, inInclusiveRange(1985, 2024));
        expect(bottle.alcoholPct, inInclusiveRange(8.0, 16.0));

        // Grape blends must sum to 100%
        final totalPct = bottle.grapes.fold<double>(0.0, (sum, g) => sum + (g.pct ?? 0.0));
        expect(totalPct.round(), equals(100));

        // Drinking window logic
        expect(bottle.idealDrinkingStart, isNotNull);
        expect(bottle.idealDrinkingEnd, isNotNull);
        expect(bottle.idealDrinkingStart!, lessThan(bottle.idealDrinkingEnd!));
      }
    });

    test('toNoisyOcrText produces realistic noisy variations without deleting core text', () {
      final bottle = RealWorldBottleGenerator.generateBottle(seed: 999);
      final cleanOcr = bottle.toOcrRawText();
      final noisyOcr = RealWorldBottleGenerator.toNoisyOcrText(bottle, noiseRatio: 0.1);

      expect(cleanOcr, isNotEmpty);
      expect(noisyOcr, isNotEmpty);
      expect(noisyOcr.length, greaterThan(cleanOcr.length * 0.7), reason: 'Noise should not decimate text');
    });
  });

  group('4. Scan Accuracy Scorer & Regression Detection Tests', () {
    test('perfect match scores 100 points and passes', () {
      final bottle = BenchmarkBottleCatalog.getById('bt_bordeaux_margaux');
      final perfectScan = bottle.toExpectedScanResult();

      final report = ScanAccuracyScorer.evaluateBottle(bottle, perfectScan);
      expect(report.totalScore, equals(100.0));
      expect(report.passed, isTrue);
      expect(report.formatSummary(), contains('SUCCÈS ✅'));
    });

    test('realistic fuzzy match with minor casing differences passes with >= 85 points', () {
      final bottle = BenchmarkBottleCatalog.getById('bt_bourgogne_clos_st_jacques');
      final fuzzyScan = ScanResult(
        name: 'Gevrey Chambertin 1er Cru Clos Saint Jacques',
        producer: 'Domaine Rousseau',
        cuveeParcel: 'Clos Saint-Jacques',
        vintage: 2018,
        wineType: 'red',
        country: 'France',
        region: 'Bourgogne',
        subRegion: 'Côte de Nuits',
        appellation: 'Gevrey-Chambertin Premier Cru',
        alcoholPct: 13.0,
        grapes: bottle.grapes,
      );

      final report = ScanAccuracyScorer.evaluateBottle(bottle, fuzzyScan);
      expect(report.totalScore, greaterThanOrEqualTo(85.0));
      expect(report.passed, isTrue);
    });

    test('severe regression (wrong vintage, wrong producer) triggers failure', () {
      final bottle = BenchmarkBottleCatalog.getById('bt_rhone_chave_hermitage');
      const badScan = ScanResult(
        name: 'Vin de Table Rouge',
        producer: 'Cave Coopérative Inconnue',
        vintage: 1999, // Wrong vintage
        wineType: 'white', // Wrong type
        country: 'Espagne', // Wrong country
        region: 'Inconnu',
      );

      final report = ScanAccuracyScorer.evaluateBottle(bottle, badScan);
      expect(report.totalScore, lessThan(40.0));
      expect(report.passed, isFalse);
      expect(report.formatSummary(), contains('RÉGRESSION ❌'));
    });

    test('menu evaluation report correctly scores matching wines and reports missing items', () {
      final menu = BenchmarkMenuCatalog.getById('menu_bistrot_parisien');
      final actualExtracted = menu.expectedWines.map((w) => w.toMenuWine()).toList();

      final report = ScanAccuracyScorer.evaluateMenu(menu, actualExtracted);
      expect(report.exactMatches, equals(menu.expectedWines.length));
      expect(report.precisionScore, equals(100.0));
      expect(report.priceAccuracyScore, equals(100.0));
      expect(report.passed, isTrue);
    });

    test('menu evaluation detects missing wines and drops precision score', () {
      final menu = BenchmarkMenuCatalog.getById('menu_bistrot_parisien');
      // Only extract 4 out of 10 wines
      final partialExtracted = menu.expectedWines.take(4).map((w) => w.toMenuWine()).toList();

      final report = ScanAccuracyScorer.evaluateMenu(menu, partialExtracted);
      expect(report.exactMatches, equals(4));
      expect(report.precisionScore, equals(40.0));
      expect(report.passed, isFalse);
      expect(report.missingWines.length, equals(6));
    });
  });
}
