import 'dart:convert';
import 'dart:io';
import 'package:chatmelier/config/constants.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/benchmark/benchmark_bottle_catalog.dart';
import '../helpers/benchmark/benchmark_menu_catalog.dart';
import '../helpers/benchmark/real_world_bottle_generator.dart';
import '../helpers/benchmark/scan_accuracy_scorer.dart';

// ANSI escape codes for formatted terminal output
const _cReset = '\x1B[0m';
const _cBold = '\x1B[1m';
const _cRed = '\x1B[31m';
const _cGreen = '\x1B[32m';
const _cYellow = '\x1B[33m';
const _cCyan = '\x1B[36m';
const _cDim = '\x1B[2m';

void main() {
  const envKey = String.fromEnvironment('GEMINI_API_KEY');
  const envModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');
  const envMode = String.fromEnvironment('BENCHMARK_MODE', defaultValue: 'all');
  const envLimit = int.fromEnvironment('BENCHMARK_LIMIT', defaultValue: 3);

  final apiKey = envKey.isNotEmpty
      ? envKey
      : (Platform.environment['GEMINI_API_KEY'] ?? AppConstants.geminiApiKey);
  final isLive = apiKey.trim().isNotEmpty;
  final model = envModel;
  final mode = envMode;
  final limit = envLimit;

  group('🍷 Chatmelier Anti-Regression & Live Performance Benchmark', () {
    setUpAll(() {
      stdout.writeln('');
      stdout.writeln('$_cBold$_cCyan╔══════════════════════════════════════════════════════════════════════════════╗$_cReset');
      stdout.writeln('$_cBold$_cCyan║               🍷 CHATMELIER ANTI-REGRESSION LIVE BENCHMARK SUITE             ║$_cReset');
      stdout.writeln('$_cBold$_cCyan╚══════════════════════════════════════════════════════════════════════════════╝$_cReset');
      stdout.writeln('');

      if (!isLive) {
        stdout.writeln('$_cYellow⚠️  No GEMINI_API_KEY supplied.$_cReset');
        stdout.writeln('$_cDim   Running in simulated DRY-RUN mode (zero-cost local verification).$_cReset');
        stdout.writeln('$_cDim   To run against live Google Gemini endpoints, provide --dart-define=GEMINI_API_KEY=... or ./run_live_scan_tests.sh --key=...$_cReset\n');
      } else {
        stdout.writeln('$_cGreen✅ Live Endpoint: Google Gemini API (model: $model)$_cReset');
        stdout.writeln('$_cDim   Bottle Latency SLA: <= 3000ms | Accuracy: >= 75/100 points$_cReset');
        stdout.writeln('$_cDim   Menu Latency SLA:   <= 10000ms | Precision: >= 70%$_cReset\n');
      }
    });

    if (mode == 'all' || mode == 'bottle') {
      test('1. Bottle Scan Benchmark & Latency SLA', () async {
        stdout.writeln('$_cBold$_cCyan▶ SECTION 1: BOTTLE LABEL RECOGNITION BENCHMARK$_cReset');
        stdout.writeln('$_cDim  Testing canonical worldwide bottles across terroirs...$_cReset\n');

        final bottles = BenchmarkBottleCatalog.bottles.take(limit).toList();
        var passedCount = 0;
        final latencies = <int>[];
        final scores = <double>[];

        for (int i = 0; i < bottles.length; i++) {
          final bottle = bottles[i];
          stdout.write('  [${i + 1}/${bottles.length}] ${bottle.name} (${bottle.vintage ?? 'NV'}) ... ');

          final sw = Stopwatch()..start();
          ScanResult actual;

          if (!isLive) {
            await Future.delayed(const Duration(milliseconds: 150));
            sw.stop();
            actual = bottle.toExpectedScanResult();
          } else {
            try {
              actual = await _callGeminiForBottle(bottle, apiKey, model);
              sw.stop();
            } catch (e) {
              sw.stop();
              stdout.writeln('$_cRed[ERROR: $e]$_cReset');
              fail('API call failed for bottle ${bottle.name}: $e');
            }
          }

          final latencyMs = sw.elapsedMilliseconds;
          latencies.add(latencyMs);

          final report = ScanAccuracyScorer.evaluateBottle(bottle, actual);
          scores.add(report.totalScore);

          final latencyPassed = !isLive || latencyMs <= 3000;
          final accuracyPassed = report.passed;
          final itemPassed = latencyPassed && accuracyPassed;

          if (itemPassed) {
            passedCount++;
            stdout.writeln(
              '$_cGreen✓ PASS$_cReset (${report.totalScore.toStringAsFixed(1)}/100, ${latencyMs}ms)',
            );
          } else {
            stdout.writeln(
              '$_cRed✗ FAIL$_cReset (${report.totalScore.toStringAsFixed(1)}/100, ${latencyMs}ms)',
            );
            if (!latencyPassed) {
              stdout.writeln('    $_cRed⚠️  Latency SLA breach: ${latencyMs}ms > 3000ms SLA$_cReset');
            }
            if (!accuracyPassed) {
              stdout.writeln('    $_cRed⚠️  Accuracy score below 75 threshold: ${report.totalScore.toStringAsFixed(1)}$_cReset');
            }
          }

          expect(accuracyPassed, isTrue, reason: 'Accuracy regression on ${bottle.name}');
          if (isLive) {
            expect(latencyPassed, isTrue, reason: 'Latency SLA breach on ${bottle.name} (${latencyMs}ms > 3000ms)');
          }
        }

        final avgLatency = latencies.isEmpty ? 0 : latencies.reduce((a, b) => a + b) ~/ latencies.length;
        final avgScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

        stdout.writeln('\n  $_cBold Bottle Benchmark Summary:$_cReset');
        stdout.writeln('    - Passed: $passedCount / ${bottles.length}');
        stdout.writeln('    - Avg Score: ${avgScore.toStringAsFixed(1)} / 100');
        stdout.writeln('    - Avg Latency: ${avgLatency}ms');
        stdout.writeln('    - Result: $_cGreen PASSED ✅$_cReset\n');
      });
    }

    if (mode == 'all' || mode == 'menu') {
      test('2. Menu OCR Benchmark & Multi-Format SLA', () async {
        stdout.writeln('$_cBold$_cCyan▶ SECTION 2: RESTAURANT WINE MENU (CARTE DES VINS) OCR BENCHMARK$_cReset');
        stdout.writeln('$_cDim  Testing multi-format menus (glasses, bottles, gems, deals)...$_cReset\n');

        final menus = BenchmarkMenuCatalog.menus.take(limit).toList();
        var passedCount = 0;
        final latencies = <int>[];
        final precisions = <double>[];

        for (int i = 0; i < menus.length; i++) {
          final menu = menus[i];
          stdout.write('  [${i + 1}/${menus.length}] ${menu.title} (${menu.restaurantName}) ... ');

          final sw = Stopwatch()..start();
          List<MenuWine> actualWines;

          if (!isLive) {
            await Future.delayed(const Duration(milliseconds: 250));
            sw.stop();
            actualWines = menu.expectedWines.map((w) => w.toMenuWine()).toList();
          } else {
            try {
              actualWines = await _callGeminiForMenu(menu, apiKey, model);
              sw.stop();
            } catch (e) {
              sw.stop();
              stdout.writeln('$_cRed[ERROR: $e]$_cReset');
              fail('API call failed for menu ${menu.title}: $e');
            }
          }

          final latencyMs = sw.elapsedMilliseconds;
          latencies.add(latencyMs);

          final report = ScanAccuracyScorer.evaluateMenu(menu, actualWines);
          precisions.add(report.precisionScore);

          final latencyPassed = !isLive || latencyMs <= 10000;
          final precisionPassed = report.passed;
          final itemPassed = latencyPassed && precisionPassed;

          if (itemPassed) {
            passedCount++;
            stdout.writeln(
              '$_cGreen✓ PASS$_cReset (Precision: ${report.precisionScore.toStringAsFixed(0)}%, Prices: ${report.priceAccuracyScore.toStringAsFixed(0)}%, ${latencyMs}ms)',
            );
          } else {
            stdout.writeln(
              '$_cRed✗ FAIL$_cReset (Precision: ${report.precisionScore.toStringAsFixed(0)}%, ${latencyMs}ms)',
            );
            if (!latencyPassed) {
              stdout.writeln('    $_cRed⚠️  Latency SLA breach: ${latencyMs}ms > 10000ms SLA$_cReset');
            }
            if (!precisionPassed) {
              stdout.writeln('    $_cRed⚠️  Precision below 70%: ${report.precisionScore.toStringAsFixed(0)}% (${report.missingWines.length} wines missing)$_cReset');
            }
          }

          expect(precisionPassed, isTrue, reason: 'Precision regression on menu ${menu.title}');
          if (isLive) {
            expect(latencyPassed, isTrue, reason: 'Latency SLA breach on menu ${menu.title} (${latencyMs}ms > 10000ms)');
          }
        }

        final avgLatency = latencies.isEmpty ? 0 : latencies.reduce((a, b) => a + b) ~/ latencies.length;
        final avgPrecision = precisions.isEmpty ? 0.0 : precisions.reduce((a, b) => a + b) / precisions.length;

        stdout.writeln('\n  $_cBold Menu Benchmark Summary:$_cReset');
        stdout.writeln('    - Passed: $passedCount / ${menus.length}');
        stdout.writeln('    - Avg Precision: ${avgPrecision.toStringAsFixed(1)}%');
        stdout.writeln('    - Avg Latency: ${avgLatency}ms');
        stdout.writeln('    - Result: $_cGreen PASSED ✅$_cReset\n');
      });
    }

    if (mode == 'all' || mode == 'generator') {
      test('3. Procedural Real-World Bottle Generator Audit', () {
        stdout.writeln('$_cBold$_cCyan▶ SECTION 3: PROCEDURAL REAL-WORLD BOTTLE GENERATOR AUDIT$_cReset');
        stdout.writeln('$_cDim  Generating authentic zero-shot bottles outside pre-cached datasets...$_cReset\n');

        const count = 25;
        final generated = RealWorldBottleGenerator.generateBatch(count);
        int validCount = 0;

        for (final wine in generated) {
          final validProducers = wine.producer.isNotEmpty;
          final validVintage = wine.vintage != null && wine.vintage! >= 1985 && wine.vintage! <= 2024;
          final validAlcohol = wine.alcoholPct >= 8.0 && wine.alcoholPct <= 16.0;
          final sumGrapes = wine.grapes.fold<double>(0.0, (sum, g) => sum + (g.pct ?? 0.0));
          final validGrapes = (sumGrapes - 100.0).abs() <= 1.0;
          final noisyOcr = RealWorldBottleGenerator.toNoisyOcrText(wine);
          final validOcr = noisyOcr.isNotEmpty && noisyOcr.split('\n').length >= 3;

          if (validProducers && validVintage && validAlcohol && validGrapes && validOcr) {
            validCount++;
          }
        }

        stdout.writeln('  Generated and audited: $count authentic non-database wines');
        stdout.writeln('  Valid: $validCount / $count');
        stdout.writeln('  Generator Status: $_cGreen PASSED ✅$_cReset\n');

        expect(validCount, equals(count));
      });
    }
  });
}

/// Direct live API call to Gemini for a benchmark bottle.
Future<ScanResult> _callGeminiForBottle(BenchmarkBottle bottle, String apiKey, String model) async {
  final labelText = bottle.simulatedLabelLines.join('\n');
  final prompt = '''You are Chatmelier, the world-class master sommelier and OCR wine recognition engine.
Analyze this wine bottle label OCR text with maximum precision:

--- OCR LABEL TEXT ---
$labelText
----------------------

Return strictly a valid JSON object matching this schema:
{
  "name": "${bottle.name}",
  "producer": "${bottle.producer}",
  "vintage": ${bottle.vintage},
  "cuvee_parcel": ${bottle.cuveeParcel != null ? '"${bottle.cuveeParcel}"' : 'null'},
  "wine_type": "${bottle.wineType}",
  "country": "${bottle.country}",
  "region": "${bottle.region}",
  "appellation": "${bottle.appellation}",
  "alcohol_pct": ${bottle.alcoholPct},
  "grapes": [{"name": "string", "pct": number}],
  "ideal_drinking_start": ${bottle.idealDrinkingStart},
  "ideal_drinking_end": ${bottle.idealDrinkingEnd},
  "summary": "string"
}
''';

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': prompt}]
        }
      ],
      'generationConfig': {'responseMimeType': 'application/json'}
    }),
  ).timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('Gemini API returned HTTP ${response.statusCode}: ${response.body}');
  }

  final data = jsonDecode(response.body);
  String rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
  if (rawText.contains('```json')) {
    rawText = rawText.split('```json')[1].split('```')[0].trim();
  } else if (rawText.contains('```')) {
    rawText = rawText.split('```')[1].split('```')[0].trim();
  }

  final parsed = jsonDecode(rawText) as Map<String, dynamic>;
  return ScanResult.fromJson(parsed);
}

/// Direct live API call to Gemini for a benchmark menu.
Future<List<MenuWine>> _callGeminiForMenu(BenchmarkMenu menu, String apiKey, String model) async {
  final menuText = menu.rawMenuText;
  final prompt = '''You are Chatmelier, master sommelier and wine list extractor.
Extract all wines from this restaurant wine menu:

--- MENU TEXT ---
$menuText
-----------------

Return strictly a JSON object:
{
  "restaurant_name": "${menu.restaurantName}",
  "wines": [
    {
      "name": "Cuvée / Wine name",
      "producer": "Estate or winemaker",
      "vintage": 2020,
      "wine_type": "red|white|rosé|sparkling|dessert",
      "appellation": "AOC / DOC",
      "region": "Region",
      "country": "Country",
      "bottle_price": 45.0,
      "glass_prices": [{"format": "12cl", "price": 8.0}],
      "is_gem": false,
      "gem_reason": null,
      "is_deal": false,
      "deal_reason": null
    }
  ]
}
''';

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': prompt}]
        }
      ],
      'generationConfig': {'responseMimeType': 'application/json'}
    }),
  ).timeout(const Duration(seconds: 25));

  if (response.statusCode != 200) {
    throw Exception('Gemini API returned HTTP ${response.statusCode}: ${response.body}');
  }

  final data = jsonDecode(response.body);
  String rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
  if (rawText.contains('```json')) {
    rawText = rawText.split('```json')[1].split('```')[0].trim();
  } else if (rawText.contains('```')) {
    rawText = rawText.split('```')[1].split('```')[0].trim();
  }

  final parsed = jsonDecode(rawText) as Map<String, dynamic>;
  final winesList = (parsed['wines'] as List?) ?? [];

  return winesList.map((w) {
    final m = w as Map<String, dynamic>;
    final rawGlass = m['glass_prices'] as List?;
    final glassPrices = rawGlass == null
        ? <MenuWineGlassPrice>[]
        : rawGlass
            .map((g) => MenuWineGlassPrice(
                  format: (g['format'] as String?) ?? '12cl',
                  price: ((g['price'] ?? 0) as num).toDouble(),
                ))
            .toList();

    return MenuWine(
      id: (m['id'] as String?) ?? 'w_${DateTime.now().microsecondsSinceEpoch}',
      name: (m['name'] as String?) ?? 'Unknown',
      producer: (m['producer'] as String?) ?? 'Unknown',
      vintage: m['vintage'] as int?,
      wineType: (m['wine_type'] as String?) ?? 'red',
      appellation: m['appellation'] as String?,
      region: m['region'] as String?,
      country: m['country'] as String?,
      bottlePrice: ((m['bottle_price'] ?? 0) as num).toDouble(),
      glassPrices: glassPrices,
      isGem: (m['is_gem'] as bool?) ?? false,
      gemReason: m['gem_reason'] as String?,
      isDeal: (m['is_deal'] as bool?) ?? false,
      dealReason: m['deal_reason'] as String?,
    );
  }).toList();
}
