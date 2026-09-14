import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_flight_engine.dart';

void main() {
  group('🍷 Menu Flight Engine Tests', () {
    final sampleMenu = ScannedMenu(
      id: 'menu_flight_1',
      restaurantName: 'Le Bistro des Vignes',
      scannedAt: DateTime.now(),
      pagePhotoPaths: const [],
      wines: const [
        // Bulles
        MenuWine(
          id: 'w_champagne',
          name: 'Champagne Drappier Brut Nature',
          producer: 'Drappier',
          wineType: 'Effervescent',
          bottlePrice: 75.0,
          glassPrices: [MenuWineGlassPrice(format: '12cl', price: 14.0)],
          metrics: MenuWineRadarMetrics(acidity: 8.0, minerality: 8.5, body: 5.0),
        ),
        // Blanc minéral
        MenuWine(
          id: 'w_chablis',
          name: 'Chablis 1er Cru Montée de Tonnerre',
          producer: 'Billaud-Simon',
          wineType: 'Blanc',
          appellation: 'Chablis',
          bottlePrice: 62.0,
          metrics: MenuWineRadarMetrics(acidity: 8.0, minerality: 8.5, body: 5.0),
        ),
        // Blanc riche / Meursault
        MenuWine(
          id: 'w_meursault',
          name: 'Meursault Les Narvaux',
          producer: 'Domaine d\'Auvenay',
          wineType: 'Blanc',
          appellation: 'Meursault',
          bottlePrice: 110.0,
          metrics: MenuWineRadarMetrics(butteriness: 7.5, oak: 6.0, body: 7.5, acidity: 5.5),
        ),
        // Rouge soyeux / Pinot Noir
        MenuWine(
          id: 'w_pinot',
          name: 'Volnay 1er Cru Clos des Chênes',
          producer: 'Michel Lafarge',
          wineType: 'Rouge',
          appellation: 'Volnay',
          bottlePrice: 95.0,
          metrics: MenuWineRadarMetrics(tannins: 4.0, acidity: 7.0, body: 5.5, fruit: 8.0),
        ),
        // Rouge puissant / Bordeaux
        MenuWine(
          id: 'w_pauillac',
          name: 'Château Lynch-Bages',
          producer: 'Lynch-Bages',
          wineType: 'Rouge',
          appellation: 'Pauillac',
          bottlePrice: 160.0,
          metrics: MenuWineRadarMetrics(tannins: 8.5, oak: 8.0, body: 9.0, acidity: 5.0),
        ),
        // Rouge équilibré / Côtes du Rhône
        MenuWine(
          id: 'w_rhone',
          name: 'Domaine de la Janasse Côtes du Rhône',
          producer: 'Domaine de la Janasse',
          wineType: 'Rouge',
          appellation: 'Côtes du Rhône',
          bottlePrice: 38.0,
          metrics: MenuWineRadarMetrics(tannins: 6.0, fruit: 7.5, body: 7.0, acidity: 5.5),
        ),
        // Rosé de gastronomie / Bandol
        MenuWine(
          id: 'w_bandol_rose',
          name: 'Domaine Tempier Bandol Rosé',
          producer: 'Domaine Tempier',
          wineType: 'Rosé',
          appellation: 'Bandol',
          bottlePrice: 46.0,
          metrics: MenuWineRadarMetrics(acidity: 7.0, fruit: 8.0, minerality: 7.5, body: 6.5),
        ),
        // Doux / Sauternes
        MenuWine(
          id: 'w_sauternes',
          name: 'Château Suduiraut Sauternes',
          producer: 'Suduiraut',
          wineType: 'Dessert',
          appellation: 'Sauternes',
          bottlePrice: 85.0,
          glassPrices: [MenuWineGlassPrice(format: '8cl', price: 12.0)],
          metrics: MenuWineRadarMetrics(sweetness: 9.0, acidity: 6.5, body: 8.0),
        ),
      ],
    );

    test('Generates 3-glass flight with progressive intensity and roles', () {
      final flight = MenuFlightEngine.buildFlight(
        menu: sampleMenu,
        format: FlightFormat.threeGlasses,
      );

      expect(flight.format, equals(FlightFormat.threeGlasses));
      expect(flight.steps.length, equals(3));
      expect(flight.title, contains('3 Verres'));
      expect(flight.storyline, isNotEmpty);

      // Verify progression: Opening -> Transition -> Climax
      expect(flight.steps[0].stepTitle, contains('Ouverture'));
      expect(flight.steps[0].sommelierRole, equals('Éveil & Fraîcheur'));

      expect(flight.steps[1].stepTitle, contains('Corps'));
      expect(flight.steps[1].sommelierRole, equals('Texture & Équilibre'));

      expect(flight.steps[2].stepTitle, contains('Apogée'));
      expect(flight.steps[2].sommelierRole, equals('Caractère & Profondeur'));

      // First wine should be Champagne or Chablis
      expect(flight.steps[0].wine.isSparkling || flight.steps[0].wine.isWhite, isTrue);

      // Last wine should be a powerful red or dessert
      expect(flight.steps[2].wine.isRed || flight.steps[2].wine.wineType.contains('Dessert'), isTrue);

      // Glass prices should be resolved
      expect(flight.steps.every((s) => s.glassPrice != null && s.glassPrice! > 0), isTrue);
      expect(flight.totalEstimatedPrice, greaterThan(0));
    });

    test('Generates 5-glass flight with full sommelier tasting arc', () {
      final flight = MenuFlightEngine.buildFlight(
        menu: sampleMenu,
        format: FlightFormat.fiveGlasses,
      );

      expect(flight.format, equals(FlightFormat.fiveGlasses));
      expect(flight.steps.length, equals(5));
      expect(flight.title, contains('5 Verres'));

      // Verify 5 roles
      expect(flight.steps[0].sommelierRole, equals('Bulles & Vivacité'));
      expect(flight.steps[1].sommelierRole, equals('Blanc Gastronomique'));
      expect(flight.steps[2].sommelierRole, equals('Rouge Fruit & Finesse'));
      expect(flight.steps[3].sommelierRole, equals('Grand Rouge d\'Assise'));
      expect(flight.steps[4].sommelierRole, equals('Élixir ou Fin de Bouche'));

      // First wine is effervescent
      expect(flight.steps[0].wine.isSparkling, isTrue);

      // Total price is sum of step glass prices
      final manualSum = flight.steps.fold<double>(0.0, (sum, s) => sum + (s.glassPrice ?? 0.0));
      expect(flight.totalEstimatedPrice, closeTo(manualSum, 0.01));
    });

    test('Handles short menus without crashing', () {
      final shortMenu = ScannedMenu(
        id: 'menu_short',
        restaurantName: 'Petit Bar',
        scannedAt: DateTime.now(),
        pagePhotoPaths: const [],
        wines: const [
          MenuWine(
            id: 'w1',
            name: 'Macon-Villages',
            producer: 'Vignerons des Terres',
            wineType: 'Blanc',
            bottlePrice: 28.0,
          ),
          MenuWine(
            id: 'w2',
            name: 'Côtes du Rhône',
            producer: 'Guigal',
            wineType: 'Rouge',
            bottlePrice: 32.0,
          ),
        ],
      );

      final flight = MenuFlightEngine.buildFlight(
        menu: shortMenu,
        format: FlightFormat.threeGlasses,
      );

      expect(flight.steps.isNotEmpty, isTrue);
      expect(flight.steps.length, lessThanOrEqualTo(3));
    });

    test('Generates 100% Blanc flight with minerality and rich white progression', () {
      final flight = MenuFlightEngine.buildFlight(
        menu: sampleMenu,
        format: FlightFormat.threeGlasses,
        color: FlightWineColor.white,
      );

      expect(flight.color, equals(FlightWineColor.white));
      expect(flight.title, contains('100% Blancs'));
      expect(flight.steps.length, equals(3));
      // All wines should be white or sparkling
      for (final step in flight.steps) {
        expect(step.wine.isWhite || step.wine.isSparkling || step.wine.wineType.contains('Dessert'), isTrue);
      }
      expect(flight.steps[0].sommelierRole, equals('Tension & Salinité'));
      expect(flight.steps[1].sommelierRole, equals('Fleurs & Fruits Mûrs'));
      expect(flight.steps[2].sommelierRole, equals('Volume & Élevage Noble'));
    });

    test('Generates 100% Rosé flight with floral and gastronomic progression', () {
      final flight = MenuFlightEngine.buildFlight(
        menu: sampleMenu,
        format: FlightFormat.threeGlasses,
        color: FlightWineColor.rose,
      );

      expect(flight.color, equals(FlightWineColor.rose));
      expect(flight.title, contains('100% Rosés'));
      expect(flight.steps.length, equals(3));
      // First available rosé should be picked
      expect(flight.steps.any((s) => s.wine.wineType == 'Rosé'), isTrue);
      expect(flight.steps[0].sommelierRole, equals('Agrumes & Pétale de Rose'));
      expect(flight.steps[1].sommelierRole, equals('Petits Fruits & Épices'));
      expect(flight.steps[2].sommelierRole, equals('Structure & Vin de Repas'));
    });

    test('Generates 100% Rouge flight with fruit and power progression', () {
      final flight = MenuFlightEngine.buildFlight(
        menu: sampleMenu,
        format: FlightFormat.threeGlasses,
        color: FlightWineColor.red,
      );

      expect(flight.color, equals(FlightWineColor.red));
      expect(flight.title, contains('100% Rouges'));
      expect(flight.steps.length, equals(3));
      // All wines should be red
      for (final step in flight.steps) {
        expect(step.wine.isRed, isTrue);
      }
      expect(flight.steps[0].sommelierRole, equals('Finesse & Tanins Soyeux'));
      expect(flight.steps[1].sommelierRole, equals('Rondeur & Fruits Noirs'));
      expect(flight.steps[2].sommelierRole, equals('Grand Vin de Garde'));
    });
  });
}
