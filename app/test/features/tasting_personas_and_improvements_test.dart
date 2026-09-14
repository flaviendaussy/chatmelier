import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/checkout/data/post_tasting_notification_service.dart';
import 'package:chatmelier/features/journal/data/tasting_ai_assistant_service.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/journal/domain/tasting_pedagogy_engine.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

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

  group('Multi-Persona Tasting Enhancements (Express, Custom Aromas, Food Synergy, Pedagogy)', () {
    const sampleChateauneuf = Wine(
      id: 'wine-chateauneuf-du-pape',
      name: 'Châteauneuf-du-Pape Rouge',
      producer: 'Château de Beaucastel',
      vintage: 2017,
      type: 'red',
      country: 'France',
      region: 'Vallée du Rhône',
      appellation: 'Châteauneuf-du-Pape AOC',
      grapes: [
        Grape(name: 'Grenache', pct: 70),
        Grape(name: 'Mourvèdre', pct: 15),
        Grape(name: 'Syrah', pct: 10),
      ],
      tastingNotes: 'Fruits noirs confits, garrigue sauvage, épices orientales et sous-bois.',
    );

    test('TastingQuestionnaireResult serializes and deserializes customAromas, foodPairingSynergy and isExpressMode', () {
      final initial = TastingQuestionnaireResult(
        profileId: 'taster-expert',
        profileName: 'Jean-Luc (Sommelier)',
        noteOutOf10: 9.5,
        emojiImpression: 4,
        perceivedAromas: const {'🫐 Fruits noirs', '🌶️ Poivre / Épices'},
        customAromas: const ['Garrigue', 'Sous-bois'],
        foodPairingSynergy: 'sublime',
        isExpressMode: true,
        aromaIntensity: 0.9,
        acidity: 0.5,
        tannins: 0.8,
        body: 0.9,
        length: 0.8,
        wouldBuyAgain: 'yes',
        idealMoment: 'diner_gastronomique',
        whatLikedMost: const {'complexite', 'longueur'},
        whatDislikedMost: const {},
      );

      final json = initial.toJson();
      expect(json['custom_aromas'], equals(['Garrigue', 'Sous-bois']));
      expect(json['food_pairing_synergy'], equals('sublime'));
      expect(json['is_express_mode'], isTrue);

      final reconstructed = TastingQuestionnaireResult.fromJson(json);
      expect(reconstructed.customAromas, equals(['Garrigue', 'Sous-bois']));
      expect(reconstructed.foodPairingSynergy, equals('sublime'));
      expect(reconstructed.isExpressMode, isTrue);
      expect(reconstructed.noteOutOf10, equals(9.5));
      expect(reconstructed.profileName, equals('Jean-Luc (Sommelier)'));
    });

    test('TastingQuestionnaireResult backwards compatibility when JSON lacks new fields', () {
      final legacyJson = <String, dynamic>{
        'profile_id': 'legacy-user',
        'profile_name': 'Sophie',
        'note_out_of_10': 8.0,
        'emoji_impression': 3,
        'perceived_aromas': ['Cerise'],
        'aroma_intensity': 0.7,
      };

      final result = TastingQuestionnaireResult.fromJson(legacyJson);
      expect(result.customAromas, isEmpty);
      expect(result.foodPairingSynergy, isNull);
      expect(result.isExpressMode, isFalse);
      expect(result.noteOutOf10, equals(8.0));
      expect(result.profileName, equals('Sophie'));
    });

    test('TastingPedagogyEngine awards bonus and detects custom aromas matching wine notes (Picky Connoisseur)', () {
      // Test without custom aromas
      final baseReport = TastingPedagogyEngine.analyze(
        wine: sampleChateauneuf,
        userAromas: const ['🫐 Fruits noirs'],
        userCaudalies: 8,
        userRating: 9.0,
      );

      // Test with connoisseur custom aromas that match tasting notes (garrigue, sous-bois)
      final connoisseurReport = TastingPedagogyEngine.analyze(
        wine: sampleChateauneuf,
        userAromas: const ['🫐 Fruits noirs'],
        customAromas: const ['Garrigue', 'Sous-bois'],
        userCaudalies: 8,
        userRating: 9.0,
      );

      // Connoisseur should get a higher acuity score thanks to custom aroma precision
      expect(connoisseurReport.acuityScore, greaterThan(baseReport.acuityScore));
      expect(connoisseurReport.sommelierPraise, isNotEmpty);
      expect(connoisseurReport.scientificPillars, isNotEmpty);
    });

    test('TastingPedagogyEngine handles express tasting inputs gracefully', () {
      final expressReport = TastingPedagogyEngine.analyze(
        wine: sampleChateauneuf,
        userAromas: const ['🫐 Fruits noirs', '🌶️ Poivre / Épices'],
        userStructure: 'Tanins fermes et puissants',
        userRating: 8.5,
      );

      expect(expressReport.acuityScore, greaterThan(50));
      expect(expressReport.archetypeAromas, isNotEmpty);
      expect(expressReport.matchingAromas, isNotEmpty);
      expect(expressReport.userStructure, equals('Tanins fermes et puissants'));
      expect(expressReport.sommelierPraise, isNotEmpty);
    });
  });
}
