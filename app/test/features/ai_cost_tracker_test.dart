import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/auth/data/ai_cost_tracker_service.dart';
import 'package:chatmelier/features/auth/domain/ai_cost_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Pricing Calculator Tests', () {
    final automne2026 = DateTime(2026, 10, 1);

    test('Flash 3.x : 0,75 \$ / 3,75 \$ le million, réflexion comprise', () {
      final res = AiPricingCalculator.computeCost(
        model: 'gemini-3.7-flash',
        promptTokens: 100000,
        candidateTokens: 20000,
        le: automne2026,
      );
      // 100k × 0,75 / 1M = 0,075 $ ; 20k × 3,75 / 1M = 0,075 $
      expect(res.costUsd, closeTo(0.15, 0.0001));
      expect(res.costEur, closeTo(0.15 * 0.92, 0.0001));
    });

    test('les Flash 3.x doublent le 1er janvier 2027', () {
      final avant = AiPricingCalculator.computeCost(
          model: 'gemini-3.8-flash', promptTokens: 100000, candidateTokens: 20000, le: DateTime(2026, 12, 31));
      final apres = AiPricingCalculator.computeCost(
          model: 'gemini-3.8-flash', promptTokens: 100000, candidateTokens: 20000, le: DateTime(2027, 1, 1));
      expect(apres.costUsd, closeTo(avant.costUsd * 2, 0.0001));
    });

    test('3.5-flash est le plus cher des Flash (1,50 \$ / 9,00 \$)', () {
      final res = AiPricingCalculator.computeCost(
          model: 'gemini-3.5-flash', promptTokens: 100000, candidateTokens: 20000, le: automne2026);
      expect(res.costUsd, closeTo(0.15 + 0.18, 0.0001));
    });

    test('Flash-Lite 3.1 : 0,25 \$ / 1,50 \$', () {
      final res = AiPricingCalculator.computeCost(
        model: 'gemini-3.1-flash-lite',
        promptTokens: 100000,
        candidateTokens: 20000,
        le: automne2026,
      );
      // 0,025 $ + 0,03 $
      expect(res.costUsd, closeTo(0.055, 0.0001));
    });

    test('les alias suivent le modèle le plus récent de leur famille', () {
      expect(AiPricingCalculator.tarif('gemini-flash-latest', le: automne2026), (entree: 0.75, sortie: 3.75));
      expect(AiPricingCalculator.tarif('gemini-flash-lite-latest', le: automne2026), (entree: 0.30, sortie: 2.50));
    });

    test('le scan d\'étiquette relevé le 29/09 coûte environ 0,72 c€, pas 0,08', () {
      // Lecture : 1 284 jetons en entrée, 111 de réponse + 552 de réflexion.
      // Description : 222 en entrée, 387 de réponse + 730 de réflexion.
      final lecture = AiPricingCalculator.computeCost(
          model: 'gemini-3.8-flash', promptTokens: 1284, candidateTokens: 663, le: DateTime(2026, 9, 29));
      final description = AiPricingCalculator.computeCost(
          model: 'gemini-3.8-flash', promptTokens: 222, candidateTokens: 1117, le: DateTime(2026, 9, 29));
      expect(lecture.costEur + description.costEur, closeTo(0.00718, 0.0001));
    });

    test('Pro Tier cost computation (1.25\$ / 1M prompt, 5.00\$ / 1M candidate)', () {
      final res = AiPricingCalculator.computeCost(
        model: 'gemini-pro-latest',
        promptTokens: 10000,
        candidateTokens: 1000,
        isSearchGrounded: false,
      );
      expect(res.costUsd, closeTo(0.0175, 0.0001));
    });

    test('recherche Google : 0,014 \$ par requête au-delà de la franchise', () {
      final sans = AiPricingCalculator.computeCost(
          model: 'gemini-3.7-flash', promptTokens: 1000, candidateTokens: 100, le: automne2026);
      final avec = AiPricingCalculator.computeCost(
          model: 'gemini-3.7-flash', promptTokens: 1000, candidateTokens: 100,
          isSearchGrounded: true, requetesDeRecherche: 3, le: automne2026);
      expect(avec.costUsd - sans.costUsd, closeTo(0.042, 0.00001));
    });
  });

  group('AI Cost Tracker Service & Aggregations', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Record usage saves event and accumulates stats across horizons', () async {
      final service = AiCostTrackerService();
      await service.clearHistory();

      final now = DateTime.now();
      // « Aujourd'hui » est le jour du calendrier : entre minuit et minuit dix, il y a dix
      // minutes, c'était hier (échec du 02/10 à 00 h 03).
      final ilYADixMinutes = now.subtract(const Duration(minutes: 10));
      final aujourdhui = ilYADixMinutes.day == now.day ? ilYADixMinutes : now;

      // 1. Today event
      await service.recordUsage(
        model: 'gemini-3.7-flash',
        feature: 'scan_vision',
        promptTokens: 1500,
        candidatesTokens: 500,
        isSearchGrounded: true,
        timestamp: aujourdhui,
      );

      // 2. 3 days ago event (this week, this month, this year)
      await service.recordUsage(
        model: 'gemini-3.7-flash',
        feature: 'chat_sommelier',
        promptTokens: 2000,
        candidatesTokens: 400,
        timestamp: now.subtract(const Duration(days: 3)),
      );

      // 3. 15 days ago event (this month, this year)
      await service.recordUsage(
        model: 'gemini-2.5-flash',
        feature: 'scan_enrichment',
        promptTokens: 1000,
        candidatesTokens: 300,
        timestamp: now.subtract(const Duration(days: 15)),
      );

      final stats = await service.getStats();

      // Daily should only have event 1
      expect(stats.daily.requestCount, 1);
      expect(stats.daily.totalTokens, 2000);
      expect(stats.daily.searchQueriesCount, 1);

      // Weekly should have event 1 & 2
      expect(stats.weekly.requestCount, 2);
      expect(stats.weekly.totalTokens, 4400);

      // Monthly should have all 3
      expect(stats.monthly.requestCount, 3);
      expect(stats.monthly.totalTokens, 5700);

      // All-Time
      expect(stats.allTime.requestCount, 3);

      // Breakdown by Model
      expect(stats.byModel.containsKey('gemini-3.7-flash'), isTrue);
      expect(stats.byModel['gemini-3.7-flash']!.requestCount, 2);
      expect(stats.byModel['gemini-2.5-flash']!.requestCount, 1);

      // Breakdown by Feature
      expect(stats.byFeature['scan_vision']!.requestCount, 1);
      expect(stats.byFeature['chat_sommelier']!.requestCount, 1);
      expect(stats.byFeature['scan_enrichment']!.requestCount, 1);
    });

    test('RecordRawResponse parses usageMetadata correctly', () async {
      final service = AiCostTrackerService();
      await service.clearHistory();

      final fakeGeminiResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Voici mes conseils de dégustation...'}
              ]
            }
          }
        ],
        'usageMetadata': {
          'promptTokenCount': 1250,
          'candidatesTokenCount': 350,
          'totalTokenCount': 1600,
        }
      };

      final event = await service.recordRawResponse(
        model: 'gemini-3.7-flash',
        feature: 'chat_sommelier',
        responseJson: fakeGeminiResponse,
      );

      expect(event, isNotNull);
      expect(event!.promptTokens, 1250);
      expect(event.candidatesTokens, 350);
      expect(event.totalTokens, 1600);
      expect(event.costEur, greaterThan(0));
    });
  });
}
