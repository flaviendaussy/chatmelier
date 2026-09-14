import 'dart:math';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';
import 'benchmark_bottle_catalog.dart';
import 'benchmark_menu_catalog.dart';

class FieldMatchResult {
  final String fieldName;
  final dynamic expected;
  final dynamic actual;
  final double score;
  final double maxScore;
  final bool isMatch;
  final String? note;

  const FieldMatchResult({
    required this.fieldName,
    required this.expected,
    required this.actual,
    required this.score,
    required this.maxScore,
    required this.isMatch,
    this.note,
  });
}

class BottleEvaluationReport {
  final String bottleId;
  final double totalScore;
  final bool passed;
  final List<FieldMatchResult> fields;

  const BottleEvaluationReport({
    required this.bottleId,
    required this.totalScore,
    required this.passed,
    required this.fields,
  });

  String formatSummary() {
    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🍷 RAPPORT D\'ÉVALUATION SCAN : $bottleId');
    buffer.writeln('Score global: ${totalScore.toStringAsFixed(1)} / 100 pts  [${passed ? "SUCCÈS ✅" : "RÉGRESSION ❌"}]');
    buffer.writeln('──────────────────────────────────────────────────────────');
    for (final f in fields) {
      final icon = f.isMatch ? '✓' : (f.score > 0 ? '~' : '✗');
      buffer.writeln('  $icon ${f.fieldName.padRight(14)} : ${f.score.toStringAsFixed(1)}/${f.maxScore.toStringAsFixed(1)} pts | Attendu: "${f.expected}" | Obtenu: "${f.actual}"${f.note != null ? " (${f.note})" : ""}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }
}

class MenuEvaluationReport {
  final String menuId;
  final int totalExpected;
  final int totalExtracted;
  final int exactMatches;
  final double precisionScore;
  final double priceAccuracyScore;
  final bool passed;
  final List<String> missingWines;
  final List<String> falsePositives;

  const MenuEvaluationReport({
    required this.menuId,
    required this.totalExpected,
    required this.totalExtracted,
    required this.exactMatches,
    required this.precisionScore,
    required this.priceAccuracyScore,
    required this.passed,
    required this.missingWines,
    required this.falsePositives,
  });

  String formatSummary() {
    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 RAPPORT D\'ÉVALUATION CARTE DES VINS : $menuId');
    buffer.writeln('Vins attendus: $totalExpected | Vins extraits: $totalExtracted | Concordances: $exactMatches');
    buffer.writeln('Score de rappel / précision: ${precisionScore.toStringAsFixed(1)}% | Exactitude des prix: ${priceAccuracyScore.toStringAsFixed(1)}%');
    buffer.writeln('Statut: [${passed ? "SUCCÈS ✅" : "RÉGRESSION ❌"}]');
    if (missingWines.isNotEmpty) {
      buffer.writeln('  ⚠️ Vins manqués (${missingWines.length}):');
      for (final m in missingWines) buffer.writeln('    - $m');
    }
    if (falsePositives.isNotEmpty) {
      buffer.writeln('  ⚠️ Faux positifs (${falsePositives.length}):');
      for (final f in falsePositives) buffer.writeln('    - $f');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }
}

/// Evaluates extraction quality against ground-truth benchmark catalogs
/// with flexible fuzzy matching and domain-aware tolerance thresholds.
class ScanAccuracyScorer {
  /// Evaluates an extracted [actual] ScanResult against a canonical [expected] BenchmarkBottle.
  static BottleEvaluationReport evaluateBottle(BenchmarkBottle expected, ScanResult actual) {
    final fields = <FieldMatchResult>[];

    // 1. Producer Match (20 pts)
    final prodSim = _similarity(expected.producer, actual.producer ?? '');
    final prodScore = prodSim >= 0.85 ? 20.0 : (prodSim >= 0.65 ? 10.0 : 0.0);
    fields.add(FieldMatchResult(
      fieldName: 'Producteur',
      expected: expected.producer,
      actual: actual.producer,
      score: prodScore,
      maxScore: 20.0,
      isMatch: prodSim >= 0.85,
      note: 'Sim: ${(prodSim * 100).toStringAsFixed(0)}%',
    ));

    // 2. Name & Cuvée / Climat Match (20 pts)
    final nameSim = _similarity(expected.name, actual.name);
    final cuveeMatch = expected.cuveeParcel == null ||
        (actual.name.toLowerCase().contains(expected.cuveeParcel!.toLowerCase()) ||
            (actual.cuveeParcel != null && _similarity(expected.cuveeParcel!, actual.cuveeParcel!) >= 0.80));
    final nameScore = (nameSim >= 0.75 && cuveeMatch) ? 20.0 : (nameSim >= 0.50 ? 10.0 : 0.0);
    fields.add(FieldMatchResult(
      fieldName: 'Nom & Cuvée',
      expected: expected.name,
      actual: actual.name,
      score: nameScore,
      maxScore: 20.0,
      isMatch: nameScore >= 18.0,
      note: 'Sim: ${(nameSim * 100).toStringAsFixed(0)}%',
    ));

    // 3. Vintage Match (20 pts)
    final isVintageMatch = expected.vintage == actual.vintage;
    final vintageScore = isVintageMatch ? 20.0 : 0.0;
    fields.add(FieldMatchResult(
      fieldName: 'Millésime',
      expected: expected.vintage ?? 'NV',
      actual: actual.vintage ?? 'NV',
      score: vintageScore,
      maxScore: 20.0,
      isMatch: isVintageMatch,
    ));

    // 4. Wine Type Match (10 pts)
    final expType = expected.wineType.toLowerCase().replaceAll('é', 'e');
    final actType = actual.wineType.toLowerCase().replaceAll('é', 'e');
    final typeMatch = expType == actType || (expType == 'dessert' && actType == 'white');
    final typeScore = typeMatch ? 10.0 : 0.0;
    fields.add(FieldMatchResult(
      fieldName: 'Type de vin',
      expected: expected.wineType,
      actual: actual.wineType,
      score: typeScore,
      maxScore: 10.0,
      isMatch: typeMatch,
    ));

    // 5. Geography Match: Appellation & Region & Country (15 pts)
    final countryMatch = _clean(expected.country) == _clean(actual.country);
    final regionMatch = _similarity(expected.region, actual.region) >= 0.70;
    final appelMatch = actual.appellation != null &&
        _similarity(expected.appellation, actual.appellation!) >= 0.70;

    double geoScore = 0.0;
    if (countryMatch) geoScore += 5.0;
    if (regionMatch) geoScore += 5.0;
    if (appelMatch) geoScore += 5.0;

    fields.add(FieldMatchResult(
      fieldName: 'Géographie',
      expected: '${expected.appellation} (${expected.region}, ${expected.country})',
      actual: '${actual.appellation ?? "?"} (${actual.region}, ${actual.country})',
      score: geoScore,
      maxScore: 15.0,
      isMatch: geoScore >= 10.0,
    ));

    // 6. Ampelography & Alcohol (15 pts)
    double ampScore = 0.0;
    if (actual.alcoholPct != null) {
      final alcDiff = (expected.alcoholPct - actual.alcoholPct!).abs();
      if (alcDiff <= 0.5) ampScore += 7.5;
      else if (alcDiff <= 1.0) ampScore += 4.0;
    } else {
      ampScore += 3.0; // Partial score if alcohol not on front label
    }

    // Check grapes identification
    if (actual.grapes.isNotEmpty) {
      final expectedGrapes = expected.grapes.map((g) => _clean(g.name)).toSet();
      final actualGrapes = actual.grapes.map((g) => _clean(g.name)).toSet();
      final common = expectedGrapes.intersection(actualGrapes);
      if (common.isNotEmpty) {
        ampScore += 7.5 * (common.length / expectedGrapes.length);
      }
    } else if (expected.grapes.isEmpty) {
      ampScore += 7.5;
    }

    fields.add(FieldMatchResult(
      fieldName: 'Alcool & Cépages',
      expected: '${expected.alcoholPct}% | ${expected.grapes.map((g) => g.name).join(", ")}',
      actual: '${actual.alcoholPct ?? "?"}% | ${actual.grapes.map((g) => g.name).join(", ")}',
      score: ampScore,
      maxScore: 15.0,
      isMatch: ampScore >= 10.0,
    ));

    final totalScore = fields.fold(0.0, (sum, f) => sum + f.score);
    final passed = totalScore >= 75.0;

    return BottleEvaluationReport(
      bottleId: expected.id,
      totalScore: totalScore,
      passed: passed,
      fields: fields,
    );
  }

  /// Evaluates an extracted list of [actual] MenuWine against a canonical [expected] BenchmarkMenu.
  static MenuEvaluationReport evaluateMenu(BenchmarkMenu expected, List<MenuWine> actual) {
    int exactMatches = 0;
    int priceAccurateCount = 0;
    final matchedActualIds = <String>{};
    final missingWines = <String>[];

    for (final exp in expected.expectedWines) {
      MenuWine? bestMatch;
      double bestSim = 0.0;

      for (final act in actual) {
        if (matchedActualIds.contains(act.id)) continue;
        final nameSim = _similarity(exp.name, act.name);
        final prodSim = _similarity(exp.producer, act.producer);
        final combined = (nameSim * 0.6) + (prodSim * 0.4);

        if (combined > bestSim && combined >= 0.65) {
          bestSim = combined;
          bestMatch = act;
        }
      }

      if (bestMatch != null) {
        exactMatches++;
        matchedActualIds.add(bestMatch.id);

        // Check bottle price accuracy within 1€ tolerance
        if (exp.bottlePrice != null && bestMatch.bottlePrice != null) {
          if ((exp.bottlePrice! - bestMatch.bottlePrice!).abs() <= 1.0) {
            priceAccurateCount++;
          }
        } else if (exp.bottlePrice == null && bestMatch.bottlePrice == null) {
          priceAccurateCount++;
        }
      } else {
        missingWines.add('${exp.producer} - ${exp.name} (${exp.vintage ?? "NV"})');
      }
    }

    final falsePositives = actual
        .where((a) => !matchedActualIds.contains(a.id))
        .map((a) => '${a.producer} - ${a.name} (${a.vintage ?? "NV"})')
        .toList();

    final precisionScore = expected.expectedWines.isNotEmpty
        ? (exactMatches / expected.expectedWines.length) * 100.0
        : 100.0;

    final priceAccuracyScore = exactMatches > 0
        ? (priceAccurateCount / exactMatches) * 100.0
        : 0.0;

    final passed = precisionScore >= 80.0 && priceAccuracyScore >= 75.0;

    return MenuEvaluationReport(
      menuId: expected.id,
      totalExpected: expected.expectedWines.length,
      totalExtracted: actual.length,
      exactMatches: exactMatches,
      precisionScore: precisionScore,
      priceAccuracyScore: priceAccuracyScore,
      passed: passed,
      missingWines: missingWines,
      falsePositives: falsePositives,
    );
  }

  static String _clean(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static double _similarity(String s1, String s2) {
    final c1 = _clean(s1);
    final c2 = _clean(s2);
    if (c1.isEmpty && c2.isEmpty) return 1.0;
    if (c1.isEmpty || c2.isEmpty) return 0.0;
    if (c1 == c2) return 1.0;
    if (c1.contains(c2) || c2.contains(c1)) {
      return (min(c1.length, c2.length) / max(c1.length, c2.length)) * 0.9;
    }

    final dist = _levenshtein(c1, c2);
    final maxLen = max(c1.length, c2.length);
    return (1.0 - (dist / maxLen)).clamp(0.0, 1.0);
  }

  static int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = s1.codeUnitAt(i) == s2.codeUnitAt(j) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
