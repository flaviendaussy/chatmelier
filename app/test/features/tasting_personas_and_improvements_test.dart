import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/checkout/data/post_tasting_notification_service.dart';
import 'package:chatmelier/features/journal/data/tasting_ai_assistant_service.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';

void main() {
  group('PostTastingNotificationService - Persona improvements', () {
    test('computeNextMorningTarget returns 11h00 tomorrow or next day', () {
      final now = DateTime.now();
      final target = PostTastingNotificationService.computeNextMorningTarget(now: now);

      expect(target.hour, 11);
      expect(target.minute, 0);
      expect(target.second, 0);
      expect(target.isAfter(now), isTrue);

      final diffHours = target.difference(now).inHours;
      expect(diffHours >= 1 && diffHours <= 36, isTrue);
    });

    test('computeNextMorningTarget when called at 8h morning schedules for today 11h', () {
      final morning = DateTime(2026, 9, 10, 8, 30);
      final target = PostTastingNotificationService.computeNextMorningTarget(now: morning);
      expect(target.year, 2026);
      expect(target.month, 9);
      expect(target.day, 10);
      expect(target.hour, 11);
    });

    test('computeNextMorningTarget when called at 23h night schedules for tomorrow 11h', () {
      final night = DateTime(2026, 9, 10, 23, 15);
      final target = PostTastingNotificationService.computeNextMorningTarget(now: night);
      expect(target.year, 2026);
      expect(target.month, 9);
      expect(target.day, 11);
      expect(target.hour, 11);
    });
  });

  group('TastingAiAssistantService - Blind Quiz Generation', () {
    final service = TastingAiAssistantService();

    test('generateBlindQuizOptions generates valid options for Bordeaux red', () {
      final quiz = service.generateBlindQuizOptions(
        wineName: 'Château Margaux',
        region: 'Bordeaux',
        appellation: 'Pauillac',
        wineType: 'red',
        vintage: 2018,
        price: 45.0,
      );

      expect(quiz.correctRegion, 'Pauillac');
      expect(quiz.regionChoices.length, 4);
      expect(quiz.regionChoices.contains('Pauillac'), isTrue);

      expect(quiz.correctGrape, isNotNull);
      expect(quiz.grapeChoices.length, 4);
      expect(quiz.grapeChoices.contains(quiz.correctGrape), isTrue);

      expect(quiz.correctVintageBracket, 'À parfaite maturité (7 - 12 ans)');
      expect(quiz.vintageBrackets.length, 4);
      expect(quiz.vintageBrackets.contains('À parfaite maturité (7 - 12 ans)'), isTrue);

      expect(quiz.estimatedPriceBracket, '30 € - 60 € (Grande cuvée)');
      expect(quiz.priceBrackets.length, 4);
      expect(quiz.priceBrackets.contains('30 € - 60 € (Grande cuvée)'), isTrue);
    });

    test('generateBlindQuizOptions generates valid options for Bourgogne blanc', () {
      final quiz = service.generateBlindQuizOptions(
        wineName: 'Meursault Premier Cru',
        region: 'Bourgogne',
        appellation: 'Meursault',
        wineType: 'white',
        vintage: 2022,
        price: 75.0,
      );

      expect(quiz.correctRegion, 'Meursault');
      expect(quiz.regionChoices.contains('Meursault'), isTrue);

      expect(quiz.correctGrape, 'Chardonnay');
      expect(quiz.grapeChoices.contains('Chardonnay'), isTrue);

      expect(quiz.correctVintageBracket, 'En pleine jeunesse (3 - 6 ans)');
      expect(quiz.vintageBrackets.contains('En pleine jeunesse (3 - 6 ans)'), isTrue);

      expect(quiz.estimatedPriceBracket, 'Plus de 60 € (Flacon d\'exception)');
      expect(quiz.priceBrackets.contains('Plus de 60 € (Flacon d\'exception)'), isTrue);
    });

    test('generateBlindQuizOptions handles Champagne effervescent', () {
      final quiz = service.generateBlindQuizOptions(
        wineName: 'Dom Pérignon',
        region: 'Champagne',
        appellation: 'Champagne',
        wineType: 'sparkling',
        vintage: null,
        price: 90.0,
      );

      expect(quiz.correctRegion, 'Champagne');
      expect(quiz.correctVintageBracket, 'En pleine jeunesse (3 - 6 ans)');
      expect(quiz.vintageBrackets.contains('En pleine jeunesse (3 - 6 ans)'), isTrue);
      expect(quiz.estimatedPriceBracket, 'Plus de 60 € (Flacon d\'exception)');
    });
  });

  group('TastingAiAssistantService - Fallback & Heuristic Parsing', () {
    final service = TastingAiAssistantService();

    test('parseNaturalLanguageNotes extracts score, emojis, and tags offline', () async {
      const naturalSpeech = "Franchement un régal ! Je lui mets un bon 8.5 sur 10. Au nez c'est très cerise, vanille, boisé, et en bouche belle acidité et tanins.";

      final result = await service.parseNaturalLanguageNotes(
        spokenText: naturalSpeech,
        tasterNames: ['Caro'],
        wineType: 'red',
        wineName: 'Château Margaux',
      );

      expect(result.profiles.isNotEmpty, isTrue);
      final profile = result.profiles['Caro'] ?? result.profiles.values.first;
      expect(profile.noteOutOf10, closeTo(8.5, 0.5));
      expect(profile.emojiImpression, greaterThanOrEqualTo(3));
      expect(profile.perceivedAromas.isNotEmpty, isTrue);
      expect(result.summary.isNotEmpty, isTrue);
    });

    test('generateWineStorytelling returns 4 engaging talking points offline', () async {
      final storytelling = await service.generateWineStorytelling(
        wineName: 'Château Margaux',
        producer: 'Château Margaux',
        vintage: 2015,
        region: 'Bordeaux',
        appellation: 'Margaux',
        wineType: 'red',
      );

      expect(storytelling.terroirAndGrape.isNotEmpty, isTrue);
      expect(storytelling.vintageClimate.isNotEmpty, isTrue);
      expect(storytelling.sommelierTip.isNotEmpty, isTrue);
      expect(storytelling.funFact.isNotEmpty, isTrue);
    });

    test('generateTastingConsensus generates concise summary for group tasting', () async {
      final results = [
        const TastingQuestionnaireResult(
          profileId: '1',
          profileName: 'Caro',
          noteOutOf10: 9.0,
          emojiImpression: 4,
          perceivedAromas: {'Cerise', 'Framboise'},
          aromaIntensity: 0.8,
          acidity: 0.5,
          tannins: 0.3,
          body: 0.6,
          length: 0.7,
          wouldBuyAgain: 'yes',
          idealMoment: 'diner_romantique',
          whatLikedMost: {'fruite', 'equilibre'},
          whatDislikedMost: {},
        ),
        const TastingQuestionnaireResult(
          profileId: '2',
          profileName: 'Marc',
          noteOutOf10: 7.0,
          emojiImpression: 2,
          perceivedAromas: {'Boisé', 'Épices'},
          aromaIntensity: 0.6,
          acidity: 0.4,
          tannins: 0.7,
          body: 0.8,
          length: 0.5,
          wouldBuyAgain: 'maybe',
          idealMoment: 'repas',
          whatLikedMost: {'puissance'},
          whatDislikedMost: {'tanins_durs'},
        ),
      ];

      final summary = await service.generateTastingConsensus(
        wineName: 'Gevrey-Chambertin',
        results: results,
      );

      expect(summary.isNotEmpty, isTrue);
      expect(
        summary.contains('Caro') ||
            summary.contains('Marc') ||
            summary.contains('débat') ||
            summary.contains('Moyenne'),
        isTrue,
      );
    });
  });
}
