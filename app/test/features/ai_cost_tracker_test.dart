import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/auth/data/ai_cost_tracker_service.dart';
import 'package:chatmelier/features/auth/domain/ai_cost_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Pricing Calculator Tests', () {
    test('Flash Tier cost computation (0.075\$ / 1M prompt, 0.30\$ / 1M candidate)', () {
      // 100,000 prompt tokens, 20,000 candidate tokens
      final res = AiPricingCalculator.computeCost(
        model: 'gemini-3.7-flash',
        promptTokens: 100000,
        candidateTokens: 20000,
        isSearchGrounded: false,
      );

      // 100k * 0.075 / 1M = 0.0075$
      // 20k * 0.30 / 1M = 0.006$
      // Total = 0.0135$
      expect(res.costUsd, closeTo(0.0135, 0.0001));
      expect(res.costEur, closeTo(0.0135 * 0.92, 0.0001));
    });

    test('Flash-Lite Tier cost computation (0.0375\$ / 1M prompt, 0.15\$ / 1M candidate)', () {
      final res = AiPricingCalculator.computeCost(
        model: 'gemini-3.1-flash-lite',
        promptTokens: 100000,
        candidateTokens: 20000,
        isSearchGrounded: false,
      );

      // 100k * 0.0375 / 1M = 0.00375$
      // 20k * 0.15 / 1M = 0.003$
      // Total = 0.00675$
      expect(res.costUsd, closeTo(0.00675, 0.0001));
    });

    test('Pro Tier cost computation (1.25\$ / 1M prompt, 5.00\$ / 1M candidate)', () {
      final res = AiPricingCalculator.computeCost(
        model: 'gemini-pro-latest',
        promptTokens: 10000,
        candidateTokens: 1000,
        isSearchGrounded: false,
      );

      // 10k * 1.25 / 1M = 0.0125$
      // 1k * 5.00 / 1M = 0.005$
      // Total = 0.0175$
      expect(res.costUsd, closeTo(0.0175, 0.0001));
    });

    test('Search Grounding surcharge (0.035\$ per query)', () {
      final res = AiPricingCalculator.computeCost(
        model: 'gemini-3.7-flash',
        promptTokens: 1000,
        candidateTokens: 100,
        isSearchGrounded: true,
      );

      expect(res.costUsd, greaterThan(0.035));
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

      // 1. Today event
      await service.recordUsage(
        model: 'gemini-3.7-flash',
        feature: 'scan_vision',
        promptTokens: 1500,
        candidatesTokens: 500,
        isSearchGrounded: true,
        timestamp: now.subtract(const Duration(minutes: 10)),
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
