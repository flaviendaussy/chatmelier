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

      // Les titres disent la place du verre ; le rôle décrit le vin servi (29/09).
      expect(flight.steps[0].stepTitle, contains('Ouverture'));
      expect(flight.steps[0].sommelierRole, equals('Bulles & Minéralité'));

      expect(flight.steps[1].stepTitle, contains('Cœur'));
      expect(flight.steps[1].sommelierRole, equals('Fruit'));

      expect(flight.steps[2].stepTitle, contains('Final'));
      expect(flight.steps[2].sommelierRole, equals('Ampleur & Charpente'));

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

      // Cinq rôles, chacun tiré du profil du vin servi.
      expect(flight.steps[0].sommelierRole, equals('Bulles & Minéralité')); // Champagne
      expect(flight.steps[1].sommelierRole, equals('Ampleur & Gras')); // Meursault
      expect(flight.steps[2].sommelierRole, equals('Fruit')); // Bandol rosé
      expect(flight.steps[3].sommelierRole, equals('Ampleur & Charpente')); // Lynch-Bages
      expect(flight.steps[4].sommelierRole, equals('Douceur & Ampleur')); // Sauternes

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
      expect(flight.steps[0].sommelierRole, equals('Bulles & Minéralité'));
      expect(flight.steps[1].sommelierRole, equals('Minéralité & Vivacité'));
      expect(flight.steps[2].sommelierRole, equals('Ampleur & Gras'));
    });

    test('Generates 100% Rosé flight with floral and gastronomic progression', () {
      final flight = MenuFlightEngine.buildFlight(
        menu: sampleMenu,
        format: FlightFormat.threeGlasses,
        color: FlightWineColor.rose,
      );

      expect(flight.color, equals(FlightWineColor.rose));
      expect(flight.title, contains('100% Rosés'));
      // La carte d'exemple n'a qu'UN rosé. L'ancien moteur complétait le « 100 % Rosés »
      // avec un effervescent et un rouge — le défaut signalé le 25/09 (« flights rouges
      // mais il y a des blancs »). Le flight dit maintenant la vérité : un seul verre.
      expect(flight.steps.length, equals(1));
      expect(flight.steps.every((s) => s.wine.isRose), isTrue);
      expect(flight.title, contains('(1 Verre)'));
      expect(flight.storyline, contains('qu\'un seul rosé'));
      expect(flight.steps[0].sommelierRole, equals('Fruit'));
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
      expect(flight.steps[0].sommelierRole, equals('Fruit & Souplesse')); // Volnay
      expect(flight.steps[1].sommelierRole, equals('Fruit')); // Côtes du Rhône
      expect(flight.steps[2].sommelierRole, equals('Ampleur & Charpente')); // Lynch-Bages
    });

    test('un flight se commande au verre, et une estimation se dit (29/09)', () {
      // « £22 / glass » s'affichait pour un Champagne que la carte ne sert qu'en bouteille.
      final carte = ScannedMenu(
        id: 'v',
        restaurantName: 'R',
        scannedAt: DateTime(2026),
        pagePhotoPaths: const [],
        wines: const [
          MenuWine(id: 'b', name: 'Bouteille seule', producer: 'A', wineType: 'white', bottlePrice: 60,
              metrics: MenuWineRadarMetrics(acidity: 8, minerality: 8)),
          MenuWine(id: 'v', name: 'Servi au verre', producer: 'B', wineType: 'white', bottlePrice: 50,
              glassPrices: [MenuWineGlassPrice(format: '15cl', price: 11)],
              metrics: MenuWineRadarMetrics(acidity: 7, minerality: 7)),
        ],
      );
      final f = MenuFlightEngine.buildFlight(menu: carte, color: FlightWineColor.white);
      expect(f.steps.first.wine.name, 'Servi au verre', reason: 'à style comparable, le verre passe devant');
      expect(f.steps.first.glassPrice, 11);
      expect(f.steps.first.prixEstime, isFalse);
      final estime = f.steps.firstWhere((s) => s.wine.name == 'Bouteille seule');
      expect(estime.prixEstime, isTrue);
      expect(estime.glassPrice, 12, reason: 'un cinquième de la bouteille, et marqué comme tel');
    });

    test('le parcours parle anglais', () {
      final flight = MenuFlightEngine.buildFlight(
        menu: sampleMenu,
        format: FlightFormat.threeGlasses,
        isFr: false,
      );
      expect(flight.title, contains('3 Glasses'));
      expect(flight.steps[0].stepTitle, '1. The Opening');
      expect(flight.steps[0].sommelierRole, 'Bubbles & Minerality');
      expect(flight.storyline, contains('Le Bistro des Vignes'));
      expect(flight.storyline, isNot(contains('verres')));
    });

    test('plausibilité : le rôle et la note décrivent le vin servi, jamais une place', () {
      // « Grand Vin de Garde » s'écrivait sur le plus puissant des rouges, quel qu'il soit.
      for (final couleur in FlightWineColor.values) {
        for (final format in FlightFormat.values) {
          final flight = MenuFlightEngine.buildFlight(menu: sampleMenu, format: format, color: couleur);
          for (final step in flight.steps) {
            if (step.wine.isRed) {
              expect(step.sommelierRole, isNot(contains('Minéralité')), reason: step.wine.name);
              expect(step.sommelierRole, isNot(contains('Gras')), reason: step.wine.name);
            }
            if (!step.wine.isRed) {
              expect(step.sommelierRole, isNot(contains('Charpente')), reason: step.wine.name);
            }
            expect(step.sommelierRole, isNot(contains('Garde')));
          }
        }
      }
      // La note reprend ce que le scan a écrit de CE vin.
      final commente = ScannedMenu(
        id: 'c',
        restaurantName: 'R',
        scannedAt: DateTime(2026),
        pagePhotoPaths: const [],
        wines: const [
          MenuWine(
            id: 'x',
            name: 'Sancerre',
            producer: 'Vacheron',
            wineType: 'white',
            sommelierComment: 'Silex, agrumes, grande tension.',
            metrics: MenuWineRadarMetrics(acidity: 8.5, minerality: 9),
          ),
        ],
      );
      final f = MenuFlightEngine.buildFlight(menu: commente, color: FlightWineColor.white);
      expect(f.steps.single.tastingNotesSummary, 'Silex, agrumes, grande tension.');
      expect(f.steps.single.sommelierRole, 'Minéralité & Vivacité');
    });
  });
}
