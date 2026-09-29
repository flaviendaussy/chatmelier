import 'package:chatmelier/features/menu_scan/data/menu_scan_service.dart';
import 'package:chatmelier/features/menu_scan/domain/food_pairing_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_flight_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:flutter_test/flutter_test.dart';

MenuWine vin(
  String nom,
  String type, {
  double tanins = 0,
  double acidite = 5,
  double corps = 5,
  double sucre = 1.5,
  double? prix,
  String? devise,
}) =>
    MenuWine(
      id: nom,
      name: nom,
      producer: 'Domaine',
      wineType: type,
      bottlePrice: prix,
      devise: devise,
      metrics: MenuWineRadarMetrics(tannins: tanins, acidity: acidite, body: corps, sweetness: sucre),
    );

ScannedMenu carte(List<MenuWine> vins) => ScannedMenu(
      id: 'carte',
      restaurantName: 'The Kitchin',
      scannedAt: DateTime(2026, 9, 26),
      pagePhotoPaths: const [],
      wines: vins,
    );

void main() {
  group('couleur lue par mots entiers, en plusieurs langues', () {
    test('les rouges, quelle que soit la langue de la carte', () {
      for (final type in ['red', 'Red Wine', 'rouge', 'Vin rouge', 'tinto', 'rosso', 'Rotwein']) {
        expect(vin('x', type).isRed, isTrue, reason: type);
      }
    });

    test('« rosé » est lu, accent final compris, et n\'est pas un rouge', () {
      for (final type in ['rosé', 'Rosé', 'rose', 'rosado', 'Vin rosé']) {
        final v = vin('x', type);
        expect(v.isRose, isTrue, reason: type);
        expect(v.isRed, isFalse, reason: type);
      }
    });

    test('pas de rouge par accident dans un autre mot', () {
      expect(vin('x', 'aged white').isRed, isFalse);
      expect(vin('x', 'sacred').isRed, isFalse);
      expect(vin('x', 'white').isWhite, isTrue);
      expect(vin('x', 'Blanc').isWhite, isTrue);
    });

    test('un effervescent rosé est un effervescent, pas un rosé', () {
      final v = vin('x', 'Sparkling rosé');
      expect(v.isSparkling, isTrue);
      expect(v.isRose, isFalse);
    });
  });

  group('accords mets-vins (retour du 23/09 : trois blancs pour une viande rouge)', () {
    // Les blancs en tête de carte, comme au restaurant en Écosse.
    final vins = [
      vin('Chablis', 'white', acidite: 8),
      vin('Sancerre', 'White', acidite: 8.5),
      vin('Albariño', 'white', acidite: 7.5),
      vin('Rioja Reserva', 'Red', tanins: 7, corps: 7),
      vin('Barolo', 'red', tanins: 9, corps: 8),
      vin('Côtes du Rhône', 'rouge', tanins: 6, corps: 6),
    ];

    test('viande rouge : les trois rouges, le plus structuré en tête', () {
      final accords = FoodPairingEngine.meilleursVins(vins, 'viande');
      expect(accords.map((a) => a.vin.isRed), everyElement(isTrue));
      expect(accords.first.vin.name, 'Barolo');
    });

    test('poisson : les blancs, le plus vif en tête', () {
      final accords = FoodPairingEngine.meilleursVins(vins, 'poisson');
      expect(accords.map((a) => a.vin.isWhite), everyElement(isTrue));
      expect(accords.first.vin.name, 'Sancerre');
    });

    test('un plat saisi en anglais trouve sa catégorie', () {
      expect(FoodPairingEngine.categorieDuPlat('Scottish beef fillet'), 'viande');
      expect(FoodPairingEngine.categorieDuPlat('Roast venison, haggis'), 'viande');
      expect(FoodPairingEngine.categorieDuPlat('Pan-fried sea bass'), 'poisson');
      expect(FoodPairingEngine.categorieDuPlat('Côte de bœuf'), 'viande');
      expect(FoodPairingEngine.categorieDuPlat('Sticky toffee pudding'), 'dessert');
      // « bar » est un poisson, pas le début de « barbecue ».
      expect(FoodPairingEngine.categorieDuPlat('barbecue'), isNull);
    });

    test('la raison est dans la langue de l\'écran', () {
      final fr = FoodPairingEngine.meilleursVins(vins, 'viande').first.raison;
      final en = FoodPairingEngine.meilleursVins(vins, 'viande', isFr: false).first.raison;
      expect(fr, contains('Tanins'));
      expect(en, contains('Tannins'));
    });
  });

  group('flights (retour du 25/09 : « flights rouges mais il y a des blancs !! »)', () {
    test('un flight de rouges ne sert que des rouges, même quand la carte en manque', () {
      final menu = carte([
        vin('Pinot Grigio', 'white'), // « pinot » le classait rouge
        vin('Sacred Hill Chardonnay', 'white'), // « red » dans « Sacred »
        vin('Cabernet Sauvignon', 'red', tanins: 7), // « sauvignon » le classait blanc
        vin('Merlot', 'red', tanins: 5),
        vin('Chablis', 'white'),
      ]);

      final flight = MenuFlightEngine.buildFlight(
        menu: menu,
        format: FlightFormat.threeGlasses,
        color: FlightWineColor.red,
      );

      expect(flight.steps.map((e) => e.wine.isRed), everyElement(isTrue));
      expect(flight.steps, hasLength(2));
      expect(flight.title, contains('(2 Verres)'));
      expect(flight.storyline, contains('ne propose que 2 rouges'));
    });

    test('un flight mélangé ne sert jamais deux fois le même vin', () {
      final menu = carte([vin('Chablis', 'white'), vin('Merlot', 'red')]);
      final flight = MenuFlightEngine.buildFlight(menu: menu, format: FlightFormat.fiveGlasses);
      final noms = flight.steps.map((e) => e.wine.name).toList();
      expect(noms.toSet(), hasLength(noms.length));
    });
  });

  test('consensus : la couleur préférée « Rouge » reconnaît un vin « red »', () {
    expect(MenuTableMatcherEngine.correspondALaCouleur(vin('x', 'red'), 'Rouge'), isTrue);
    expect(MenuTableMatcherEngine.correspondALaCouleur(vin('x', 'white'), 'Rouge'), isFalse);
    expect(MenuTableMatcherEngine.correspondALaCouleur(vin('x', 'rosé'), 'Rosé'), isTrue);
    expect(MenuTableMatcherEngine.correspondALaCouleur(vin('x', 'sparkling'), 'Bulles'), isTrue);
  });

  group('devise de la carte (retour du 26/09 : des € en Écosse)', () {
    test('le code est normalisé, les symboles reconnus', () {
      expect(ScannedMenu.normaliserDevise('GBP'), 'GBP');
      expect(ScannedMenu.normaliserDevise(' gbp '), 'GBP');
      expect(ScannedMenu.normaliserDevise('£'), 'GBP');
      expect(ScannedMenu.normaliserDevise('€'), 'EUR');
      expect(ScannedMenu.normaliserDevise('Euro'), isNull);
      expect(ScannedMenu.normaliserDevise(''), isNull);
      expect(ScannedMenu.normaliserDevise(null), isNull);
    });

    test('les prix s\'affichent dans la devise de la carte, centimes compris', () {
      final v = vin('Rioja', 'red', prix: 45, devise: 'GBP').copyWith(
        glassPrices: const [MenuWineGlassPrice(format: '175ml', price: 7.5)],
      );
      expect(v.priceDisplay, '£45 / bt • £7.50 (175ml)');
    });

    test('une carte relue transmet sa devise à ses vins', () {
      final relue = ScannedMenu.fromJson({
        'id': 'c',
        'restaurant_name': 'The Kitchin',
        'currency': 'GBP',
        'wines': [
          {'id': 'v', 'name': 'Rioja', 'producer': 'X', 'wine_type': 'red', 'bottle_price': 45},
        ],
      });
      expect(relue.currency, 'GBP');
      expect(relue.wines.single.devise, 'GBP');
      expect(ScannedMenu.fromJson(relue.toJson()).wines.single.devise, 'GBP');
    });
  });

  test('scan page par page : un vin présent sur deux pages garde ses deux prix', () {
    final fusion = MenuScanService.fusionnerPagesDeCarte([
      {
        'restaurant_name': null,
        'currency': 'GBP',
        'modele': 'gemini-3.8-flash',
        'wines': [
          {'name': 'Chablis', 'producer': 'Fèvre', 'vintage': 2022, 'bottle_price': null,
           'glass_prices': [{'format': '175ml', 'price': 11.0}]},
        ],
      },
      {
        'restaurant_name': 'The Kitchin',
        'currency': null,
        'wines': [
          {'name': 'Chablis ', 'producer': 'fèvre', 'vintage': 2022, 'bottle_price': 52.0,
           'glass_prices': [{'format': '175ml', 'price': 11.0}]},
          {'name': 'Barolo', 'producer': 'Vietti', 'vintage': 2019, 'bottle_price': 95.0},
        ],
      },
    ], pagesDemandees: 3);

    final vins = fusion['wines'] as List;
    expect(vins, hasLength(2));
    final chablis = vins.first as Map;
    expect(chablis['bottle_price'], 52.0);
    expect(chablis['glass_prices'], hasLength(1));
    expect(fusion['restaurant_name'], 'The Kitchin');
    expect(fusion['currency'], 'GBP');
    expect(fusion['modele'], 'gemini-3.8-flash');
    expect(fusion['pages_non_lues'], 1);
  });

  test('renommer ou annoter la carte garde sa devise (29/09)', () {
    // La carte enrichie se reconstruisait champ par champ après le croisement avec la
    // cave, et une carte d'Édimbourg repassait en euros (« ≤ 60 € »).
    final carte = ScannedMenu(
      id: 'k',
      restaurantName: 'Kitchin',
      scannedAt: DateTime(2026, 9, 29),
      pagePhotoPaths: const [],
      wines: const [],
      currency: 'GBP',
      pagesNonLues: 1,
    );
    final renommee = carte.copie(restaurantName: 'The Kitchin');
    expect(renommee.restaurantName, 'The Kitchin');
    expect(renommee.currency, 'GBP');
    expect(renommee.pagesNonLues, 1);
    expect(carte.copie(wines: const []).currency, 'GBP');
    expect(renommee.formaterPrix(60), '£60');
  });
}
