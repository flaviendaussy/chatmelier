import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/wine_food_matcher.dart';
import 'package:chatmelier/features/cellar/domain/wine_reverse_pairing_engine.dart';

void main() {
  group('Taste Radar Localization Tests', () {
    test('Axis labels localize accurately in English, Spanish, Catalan, Latin, and French', () {
      final enAxes = WineTasteRadarMetrics.localizedAxisLabels('en');
      final frAxes = WineTasteRadarMetrics.localizedAxisLabels('fr');
      final esAxes = WineTasteRadarMetrics.localizedAxisLabels('es');
      final caAxes = WineTasteRadarMetrics.localizedAxisLabels('ca');
      final laAxes = WineTasteRadarMetrics.localizedAxisLabels('la');

      expect(enAxes[0], 'Tannins\n& Grip');
      expect(enAxes[1], 'Body\n& Power');
      expect(enAxes[2], 'Oak\n& Aging');

      expect(frAxes[0], 'Structure\n& Tanins');
      expect(frAxes[1], 'Puissance\n& Corps');

      expect(esAxes[0], 'Estructura\n& Taninos');
      expect(esAxes[1], 'Cuerpo\n& Potencia');

      expect(caAxes[0], 'Estructura\n& Tanins');
      expect(caAxes[1], 'Cos\n& Potència');

      expect(laAxes[0], 'Tannina\n& Firmitas');
      expect(laAxes[1], 'Robur\n& Corpus');
    });

    test('Radar comparison advice generates authentic localized text', () {
      const p1 = TasteProfile(
        id: '1',
        name: 'Alice',
        favoriteTypes: ['Rouge puissant'],
        favoriteRegions: ['Bordeaux'],
        favoriteGrapes: ['Cabernet Sauvignon'],
        dislikedCharacteristics: ['Acidité'],
        avgTanninPreference: 0.8,
        avgAcidityPreference: 0.3,
        avgBodyPreference: 0.9,
      );

      const p2 = TasteProfile(
        id: '2',
        name: 'Bob',
        favoriteTypes: ['Rouge puissant'],
        favoriteRegions: ['Rhône'],
        favoriteGrapes: ['Syrah'],
        dislikedCharacteristics: ['Boisé'],
        avgTanninPreference: 0.7,
        avgAcidityPreference: 0.4,
        avgBodyPreference: 0.8,
      );

      final compEn = WineTasteRadarCalculator.compare(p1, p2, 'en');
      expect(compEn.commonGroundsSummary, contains('great affinity for'));
      expect(compEn.idealWineRecommendation, isNotEmpty);

      final compLa = WineTasteRadarCalculator.compare(p1, p2, 'la');
      expect(compLa.commonGroundsSummary, contains('concordiam'));
    });
  });

  group('Dish Pairing Localization Tests', () {
    test('FoodMatchLevel localizes accurately across languages', () {
      expect(FoodMatchLevel.ideal.localizedLabel('en'), 'Ideal Match 🌟');
      expect(FoodMatchLevel.ideal.localizedLabel('fr'), 'Accord Idéal 🌟');
      expect(FoodMatchLevel.ideal.localizedLabel('es'), 'Maridaje Ideal 🌟');
      expect(FoodMatchLevel.ideal.localizedLabel('ca'), 'Maridatge Ideal 🌟');
      expect(FoodMatchLevel.ideal.localizedLabel('la'), 'Harmonia Optima 🌟');

      expect(FoodMatchLevel.harmonious.localizedLabel('en'), 'Harmonious Match ✨');
      expect(FoodMatchLevel.gourmet.localizedLabel('en'), 'Gourmet Match 🍷');
      expect(FoodMatchLevel.subtle.localizedLabel('en'), 'Delicate Match 🥂');
    });

    test('FoodPairingCategory labels and sample dishes localize accurately', () {
      final redMeat = WineFoodMatcher.categories.firstWhere((c) => c.id == 'red_meat');

      expect(redMeat.localizedLabel('en'), 'Red Meat & Grills');
      expect(redMeat.localizedLabel('es'), 'Carnes Rojas y Parrilla');
      expect(redMeat.localizedLabel('ca'), 'Carns Vermelles i Graella');
      expect(redMeat.localizedLabel('la'), 'Carnes Rubrae & Assaturae');
      expect(redMeat.localizedLabel('fr'), 'Viandes Rouges & Grillades');

      final dishesEn = redMeat.getSampleDishes('en');
      expect(dishesEn.first, 'Grilled Prime Rib');

      final dishesEs = redMeat.getSampleDishes('es');
      expect(dishesEs.first, contains('Chuletón'));

      final dishesLa = redMeat.getSampleDishes('la');
      expect(dishesLa.first, 'Costa bubula assa');
    });

    test('getSommelierAdviceForDish provides English and multilingual advice', () {
      final adviceEn = WineFoodMatcher.getSommelierAdviceForDish('', 'en');
      expect(adviceEn, contains('Enter a dish or pick a suggestion'));

      final adviceFr = WineFoodMatcher.getSommelierAdviceForDish('', 'fr');
      expect(adviceFr, contains('Indiquez un mets ou choisissez une suggestion'));

      final adviceLa = WineFoodMatcher.getSommelierAdviceForDish('', 'la');
      expect(adviceLa, contains('Indica cibum'));

      final fallbackEn = WineFoodMatcher.getSommelierAdviceForDish('something exotic', 'en');
      expect(fallbackEn, contains('For this dish, prefer a harmonious wine'));
    });

    test('ReverseFoodPairing affinity level localizes across languages', () {
      const pairing = ReverseFoodPairing(
        dishName: 'Prime Rib',
        category: 'viande',
        categoryIcon: '🥩',
        affinityPct: 98,
        affinityLevel: 'Accord Majeur 🌟',
        keyIngredients: ['Beef'],
        cookingAdvice: 'Sear hot',
        molecularRationale: 'Proteins bind tannins',
      );

      expect(pairing.localizedAffinityLevel('en'), 'Major Match 🌟');
      expect(pairing.localizedAffinityLevel('es'), 'Maridaje Mayor 🌟');
      expect(pairing.localizedAffinityLevel('ca'), 'Maridatge Major 🌟');
      expect(pairing.localizedAffinityLevel('la'), 'Harmonia Optima 🌟');
      expect(pairing.localizedAffinityLevel('fr'), 'Accord Majeur 🌟');
    });
  });
}
