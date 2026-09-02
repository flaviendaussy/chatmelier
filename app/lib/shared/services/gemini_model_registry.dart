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
/// Prioritizes active Gemini 3.x Flash and Lite models, handles deprecations gracefully,
/// and strictly avoids heavy/expensive Pro models.
class GeminiModelRegistry {
  static const String defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AQ.Ab8RN6JFZQNPfXmDdjdGT0posCOmn_4wPIFv_TiviorSGL6BDg',
  );

  /// Curated Lite baseline models (Gemini 3.5 / 3.1 Flash-Lite, flash-lite-latest)
  static const List<String> baselineLiteModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-flash-lite-latest',
    'gemini-3.7-flash-lite',
    'gemini-3.6-flash-lite',
  ];

  /// Curated Standard Flash baseline models (Gemini 3.5 / 3.6 / 3.7 Flash, flash-latest)
  static const List<String> baselineStandardFlashModels = [
    'gemini-3.5-flash',
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-flash-latest',
    'gemini-3-flash-preview',
  ];

  /// Combined baseline list (Strictly excludes all Pro models)
  static List<String> get baselineModels => [
        ...baselineStandardFlashModels,
        ...baselineLiteModels,
      ];

  static List<String>? _discoveredLiteModels;
  static List<String>? _discoveredStandardFlashModels;
  static DateTime? _lastDiscoveryTime;
  static final Map<String, DateTime> _rateLimitCooldowns = {};
  static final Set<String> _disabledModels = {
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  };

  /// Check whether a model name belongs to the Lite family
  static bool isLiteModel(String model) {
    final lower = model.toLowerCase();
    return lower.contains('lite');
  }

  /// Intelligent model routing based on task complexity.
  /// - [GeminiTaskTier.litePreferred]: Returns Lite models first, then Standard Flash as fallback.
  /// - [GeminiTaskTier.standardFlashPreferred]: Returns Standard Flash first, then Lite as fallback.
  /// Pro models and deprecated models are strictly excluded in all tiers.
  static List<String> getModelsForTier(GeminiTaskTier tier) {
    final now = DateTime.now();
    _rateLimitCooldowns.removeWhere((_, until) => now.isAfter(until));

    final liteList = (_discoveredLiteModels ?? baselineLiteModels)
        .where((m) => !_rateLimitCooldowns.containsKey(m) && !_disabledModels.contains(m))
        .toList();

    final standardList = (_discoveredStandardFlashModels ?? baselineStandardFlashModels)
        .where((m) => !_rateLimitCooldowns.containsKey(m) && !_disabledModels.contains(m) && !m.contains('-pro'))
        .toList();

    List<String> result;
    if (tier == GeminiTaskTier.litePreferred) {
      result = [...liteList, ...standardList];
    } else {
      result = [...standardList, ...liteList];
    }

    // Remove duplicates while preserving priority order
    final uniqueResult = <String>[];
    for (final m in result) {
      if (!uniqueResult.contains(m)) {
        uniqueResult.add(m);
      }
    }

    if (uniqueResult.isEmpty) {
      return tier == GeminiTaskTier.litePreferred
          ? [...baselineLiteModels, ...baselineStandardFlashModels]
          : [...baselineStandardFlashModels, ...baselineLiteModels];
    }

    return uniqueResult;
  }

  /// Backward-compatible candidate getter (strictly excludes Pro models).
  static List<String> getActiveModels({bool allowPro = false, GeminiTaskTier? tier}) {
    if (tier != null) {
      return getModelsForTier(tier);
    }
    return getModelsForTier(GeminiTaskTier.standardFlashPreferred);
  }

  /// Heuristic router that classifies chat messages to choose the most cost-effective tier.
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

  /// Mark a model as permanently disabled (e.g. HTTP 404 Deprecated).
  static void recordDisabledModel(String model) {
    _disabledModels.add(model);
    _discoveredLiteModels?.remove(model);
    _discoveredStandardFlashModels?.remove(model);
    AppLogger.warning('GEMINI_REGISTRY', 'Model $model marked as disabled (404/Deprecated)');
  }

  /// Discovers available Gemini models dynamically from Google Gemini API endpoint.
  /// Automatically partitions models into Lite and Standard Flash tiers while ignoring Pro and deprecated models.
  static Future<List<String>> refreshAvailableModels({String apiKey = defaultApiKey}) async {
    if (_discoveredLiteModels != null && _discoveredStandardFlashModels != null && _lastDiscoveryTime != null) {
      if (DateTime.now().difference(_lastDiscoveryTime!).inHours < 2) {
        return getActiveModels();
      }
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 5));

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

            // Strictly exclude non-Gemini, TTS, Imagen, PRO models
            if (supportsGenerate &&
                name.startsWith('gemini-') &&
                !_disabledModels.contains(name) &&
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
          _discoveredLiteModels = sortedLite;
        }

        if (standardCandidates.isNotEmpty) {
          final sortedStandard = standardCandidates.toList()..sort((a, b) => _compareModelVersions(b, a));
          _discoveredStandardFlashModels = sortedStandard;
        }

        _lastDiscoveryTime = DateTime.now();
        AppLogger.info('GEMINI_REGISTRY', 'Discovered ${liteCandidates.length} Lite and ${standardCandidates.length} Flash active models');
      }
    } catch (e) {
      AppLogger.warning('GEMINI_REGISTRY', 'Dynamic discovery notice: $e');
    }

    return getActiveModels();
  }

  static int _compareModelVersions(String a, String b) {
    double getVersion(String s) {
      final match = RegExp(r'gemini-(\d+(?:\.\d+)?)').firstMatch(s);
      if (match != null) return double.tryParse(match.group(1)!) ?? 0.0;
      if (s.contains('latest')) return 99.0;
      return 0.0;
    }
    return getVersion(a).compareTo(getVersion(b));
  }
}
