import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/shared/services/gemini_model_registry.dart';

void main() {
  group('GeminiModelRegistry Intelligent Routing & Pro Exclusion Tests', () {
    test('Baseline models strictly exclude all Pro models and include Flash and Lite tiers', () {
      final models = GeminiModelRegistry.baselineModels;
      expect(models.any((m) => m.contains('-pro') && !m.contains('flash')), isFalse);
      expect(models.any((m) => m.contains('lite')), isTrue);
      expect(models.any((m) => m.contains('flash') && !m.contains('lite')), isTrue);
    });

    test('GeminiTaskTier.litePreferred prioritizes Lite models first', () {
      final liteList = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.litePreferred);
      expect(liteList.isNotEmpty, isTrue);
      // The first models must be Lite models
      expect(liteList.first.contains('lite'), isTrue);
      expect(liteList.take(3).every((m) => m.contains('lite')), isTrue);
      // Standard Flash models must still be present as fallback
      expect(liteList.any((m) => !m.contains('lite')), isTrue);
      // No Pro models allowed
      expect(liteList.any((m) => m.contains('-pro') && !m.contains('flash')), isFalse);
    });

    test('GeminiTaskTier.standardFlashPreferred prioritizes Standard Flash models first', () {
      final standardList = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.standardFlashPreferred);
      expect(standardList.isNotEmpty, isTrue);
      // The first model must be Standard Flash (e.g. gemini-flash-latest / 2.5-flash)
      expect(standardList.first.contains('lite'), isFalse);
      expect(standardList.first.contains('flash'), isTrue);
      // Lite models must be present as fallback
      expect(standardList.any((m) => m.contains('lite')), isTrue);
      // No Pro models allowed
      expect(standardList.any((m) => m.contains('-pro') && !m.contains('flash')), isFalse);
    });

    test('classifyChatComplexity routes simple questions and lookups to Lite tier', () {
      // Greetings
      expect(GeminiModelRegistry.classifyChatComplexity('Bonjour ! Que me conseilles-tu ce soir ?'),
          GeminiTaskTier.litePreferred);

      // Factual cellar counts
      expect(GeminiModelRegistry.classifyChatComplexity('Combien de bouteilles de Bordeaux ai-je en cave ?'),
          GeminiTaskTier.litePreferred);

      // Simple single-dish wine suggestion
      expect(GeminiModelRegistry.classifyChatComplexity('Un vin rouge pour des pâtes bolo ?'),
          GeminiTaskTier.litePreferred);

      // Short factual lookup
      expect(GeminiModelRegistry.classifyChatComplexity('Quel est le prix moyen de mes vins ?'),
          GeminiTaskTier.litePreferred);
    });

    test('classifyChatComplexity routes complex multi-course menus or deep strategy to Standard Flash tier', () {
      // Multi-course dinner menu
      const complexPrompt =
          'Bonjour sommelier, nous organisons un dîner 4 services : entrée foie gras poêlé, plat filet de bœuf aux morilles, plateau de fromages affinés et dessert coulant chocolat. Fais moi un menu complet avec les accords de ma cave.';
      expect(GeminiModelRegistry.classifyChatComplexity(complexPrompt),
          GeminiTaskTier.standardFlashPreferred);

      // Explicit deep cellar strategy
      const strategyPrompt =
          'Peux-tu faire une analyse approfondie de ma stratégie de garde sur les 10 prochaines années avec un tableau comparatif de mes millésimes ?';
      expect(GeminiModelRegistry.classifyChatComplexity(strategyPrompt),
          GeminiTaskTier.standardFlashPreferred);
    });

    test('Rate-limited models (HTTP 429) are temporarily excluded across all tiers', () {
      const testModel = 'gemini-flash-lite-latest';
      GeminiModelRegistry.recordRateLimit(testModel, cooldownDuration: const Duration(minutes: 2));

      final activeLite = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.litePreferred);
      expect(activeLite.contains(testModel), isFalse);

      final activeStandard = GeminiModelRegistry.getModelsForTier(GeminiTaskTier.standardFlashPreferred);
      expect(activeStandard.contains(testModel), isFalse);
    });
  });
}
