import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

/// Task complexity tier for intelligent, cost-effective model routing.
enum GeminiTaskTier {
  /// Straightforward tasks: text enrichment, factual lookups, simple Q&A, greetings, background sync.
  /// Priority: Flash-Lite models FIRST (ultra-fast & low cost), Standard Flash as fallback.
  litePreferred,

  /// Complex tasks: multimodal label vision OCR, multi-course pairing menus, deep sommelier reasoning.
  /// Priority: Standard Flash models FIRST (high capability & vision accuracy), Flash-Lite as fallback.
  standardFlashPreferred,
}

/// Centralized, intelligent, future-proof registry and router for Google Gemini models.
/// Prioritizes Gemini Lite models for suitable tasks, uses Standard Flash when higher capability is needed,
/// and strictly avoids heavy/expensive Pro models.
class GeminiModelRegistry {
  static const String defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg',
  );

  /// Curated Lite baseline models (fastest, most economical, great for structured JSON & simple queries)
  static const List<String> baselineLiteModels = [
    'gemini-flash-lite-latest',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
    'gemini-3.1-flash-lite',
  ];

  /// Curated Standard Flash baseline models (powerful multimodal vision & deep reasoning without Pro latency/costs)
  static const List<String> baselineStandardFlashModels = [
    'gemini-flash-latest',
    'gemini-2.5-flash',
    'gemini-3.7-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-1.5-flash',
  ];

  /// Combined baseline list (Strictly excludes all Pro models)
  static List<String> get baselineModels => [
        ...baselineLiteModels,
        ...baselineStandardFlashModels,
      ];

  static List<String>? _discoveredLiteModels;
  static List<String>? _discoveredStandardFlashModels;
  static DateTime? _lastDiscoveryTime;
  static final Map<String, DateTime> _rateLimitCooldowns = {};

  /// Check whether a model name belongs to the Lite family
  static bool isLiteModel(String model) {
    final lower = model.toLowerCase();
    return lower.contains('lite');
  }

  /// Intelligent model routing based on task complexity.
  /// - [GeminiTaskTier.litePreferred]: Returns Lite models first, then Standard Flash as fallback.
  /// - [GeminiTaskTier.standardFlashPreferred]: Returns Standard Flash first, then Lite as fallback.
  /// Pro models are strictly excluded in all tiers.
  static List<String> getModelsForTier(GeminiTaskTier tier) {
    final now = DateTime.now();
    _rateLimitCooldowns.removeWhere((_, until) => now.isAfter(until));

    final liteList = (_discoveredLiteModels ?? baselineLiteModels)
        .where((m) => !_rateLimitCooldowns.containsKey(m))
        .toList();

    final standardList = (_discoveredStandardFlashModels ?? baselineStandardFlashModels)
        .where((m) => !_rateLimitCooldowns.containsKey(m) && !m.contains('-pro'))
        .toList();

    List<String> result;
    if (tier == GeminiTaskTier.litePreferred) {
      result = [...liteList, ...standardList];
    } else {
      result = [...standardList, ...liteList];
    }

    if (result.isEmpty) {
      return tier == GeminiTaskTier.litePreferred
          ? [...baselineLiteModels, ...baselineStandardFlashModels]
          : [...baselineStandardFlashModels, ...baselineLiteModels];
    }

    return result;
  }

  /// Backward-compatible candidate getter (strictly excludes Pro models).
  static List<String> getActiveModels({bool allowPro = false, GeminiTaskTier? tier}) {
    if (tier != null) {
      return getModelsForTier(tier);
    }

    // By default, provide Standard Flash preferred list (all Pro models filtered out)
    return getModelsForTier(GeminiTaskTier.standardFlashPreferred);
  }

  /// Heuristic router that classifies chat messages to choose the most cost-effective tier.
  /// Simple questions -> Lite (0.00005€/call, instant response).
  /// Complex pairing menus / deep cellar strategy -> Standard Flash.
  static GeminiTaskTier classifyChatComplexity(String message, {int conversationTurnCount = 0}) {
    final clean = message.trim().toLowerCase();

    // 1. Short or simple common intent checks -> Lite
    if (clean.length < 120) {
      const complexTriggers = [
        'menu complet',
        'accord complexe',
        'analyse approfondie',
        'comparaison détaillée',
        'dégustation à l\'aveugle',
        'stratégie de garde',
        'plusieurs plats',
        'plusieurs bouteilles',
      ];

      final isComplex = complexTriggers.any((trigger) => clean.contains(trigger));
      if (!isComplex) {
        return GeminiTaskTier.litePreferred;
      }
    }

    // 2. Factual cellar lookup / simple pairing / casual greetings -> Lite
    const simplePatterns = [
      'bonjour',
      'salut',
      'merci',
      'combien de',
      'quel est mon vin',
      'où est',
      'quel prix',
      'liste mes',
      'trouve moi un rouge pour',
      'trouve moi un blanc pour',
      'un vin pour ce soir',
    ];

    if (simplePatterns.any((pattern) => clean.startsWith(pattern) || clean.contains(pattern))) {
      // If it's not a lengthy multi-question prompt, use Lite
      if (clean.length < 180 && !clean.contains('\n')) {
        return GeminiTaskTier.litePreferred;
      }
    }

    // 3. Multi-paragraph or complex query -> Standard Flash
    return GeminiTaskTier.standardFlashPreferred;
  }

  /// Mark a model as temporarily rate-limited (HTTP 429) for [cooldownDuration].
  static void recordRateLimit(String model, {Duration cooldownDuration = const Duration(seconds: 45)}) {
    _rateLimitCooldowns[model] = DateTime.now().add(cooldownDuration);
    AppLogger.warning('GEMINI_REGISTRY', 'Model $model put on rate-limit cooldown for ${cooldownDuration.inSeconds}s');
  }

  /// Discovers available Gemini models dynamically from Google Gemini API endpoint.
  /// Automatically partitions models into Lite and Standard Flash tiers while ignoring Pro models.
  static Future<List<String>> refreshAvailableModels({String apiKey = defaultApiKey}) async {
    // Cache discovery for 2 hours
    if (_discoveredLiteModels != null && _discoveredStandardFlashModels != null && _lastDiscoveryTime != null) {
      if (DateTime.now().difference(_lastDiscoveryTime!).inHours < 2) {
        return getActiveModels();
      }
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawList = (data['models'] as List<dynamic>?) ?? [];

        final Set<String> liteCandidates = {};
        final Set<String> standardCandidates = {};

        for (final item in rawList) {
          if (item is Map) {
            final name = (item['name'] as String? ?? '').replaceFirst('models/', '');
            final methods = (item['supportedGenerationMethods'] as List<dynamic>?) ?? [];
            final supportsGenerate = methods.contains('generateContent');

            // Strictly exclude non-Gemini, TTS, Imagen and PRO models
            if (supportsGenerate &&
                name.startsWith('gemini-') &&
                !name.contains('-tts') &&
                !name.contains('-image') &&
                !name.contains('-pro')) {
              if (name.contains('lite')) {
                liteCandidates.add(name);
              } else if (name.contains('flash')) {
                standardCandidates.add(name);
              }
            }
          }
        }

        if (liteCandidates.isNotEmpty) {
          final sortedLite = liteCandidates.toList()..sort((a, b) => _compareModelVersions(b, a));
          if (sortedLite.contains('gemini-flash-lite-latest')) {
            sortedLite.remove('gemini-flash-lite-latest');
            sortedLite.insert(0, 'gemini-flash-lite-latest');
          }
          _discoveredLiteModels = sortedLite;
        }

        if (standardCandidates.isNotEmpty) {
          final sortedStandard = standardCandidates.toList()..sort((a, b) => _compareModelVersions(b, a));
          if (sortedStandard.contains('gemini-flash-latest')) {
            sortedStandard.remove('gemini-flash-latest');
            sortedStandard.insert(0, 'gemini-flash-latest');
          }
          _discoveredStandardFlashModels = sortedStandard;
        }

        _lastDiscoveryTime = DateTime.now();
        AppLogger.info('GEMINI_REGISTRY',
            'Discovered ${liteCandidates.length} Lite models (${_discoveredLiteModels?.take(3).join(', ')}) and ${standardCandidates.length} Standard Flash models (${_discoveredStandardFlashModels?.take(3).join(', ')}) [Pro models excluded]');
        return getActiveModels();
      }
    } catch (e) {
      AppLogger.debug('GEMINI_REGISTRY', 'Dynamic model discovery failed (using baseline): $e');
    }

    return getActiveModels();
  }

  static int _compareModelVersions(String a, String b) {
    final vA = _extractVersion(a);
    final vB = _extractVersion(b);

    if (vA != vB) {
      return vA.compareTo(vB);
    }
    return a.compareTo(b);
  }

  static double _extractVersion(String modelName) {
    if (modelName.contains('latest')) return 999.0;
    final match = RegExp(r'gemini-(\d+(?:\.\d+)?)').firstMatch(modelName);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }
}
