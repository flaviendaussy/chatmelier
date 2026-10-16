import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/menu_scan/data/menu_scan_service.dart';
import 'package:chatmelier/features/menu_scan/domain/a_prix_egal.dart';
import 'package:chatmelier/features/menu_scan/domain/cellar_bridge.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_flight_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';

/// 13/10, carte du vol BA484 : « ici, tes prix par verre sont pas ok vu qu'on est sur des
/// bouteilles de 187 ou 200ml ». Le verre d'une mignonnette à 8 £ s'affichait ≈ 1,60 £.
void main() {
  MenuWine vin(String nom, {double? prix, int? ml, double? accord, String type = 'white'}) => MenuWine(
        id: nom,
        name: nom,
        producer: 'Maison $nom',
        wineType: type,
        bottlePrice: prix,
        contenanceMl: ml,
        userMatchScore: accord,
        devise: 'GBP',
        metrics: const MenuWineRadarMetrics(acidity: 7, minerality: 6),
      );

  ScannedMenu carte(List<MenuWine> vins) =>
      ScannedMenu(id: 'ba484', restaurantName: 'BA484', scannedAt: DateTime(2026, 10, 13), pagePhotoPaths: const [], wines: vins, currency: 'GBP');

  test('la contenance se lit, se garde et se dit', () {
    final m = MenuWine.fromJson({'id': 'a', 'name': 'Chablis', 'producer': 'X', 'wine_type': 'white', 'bottle_price': 8, 'bottle_ml': 187, 'currency': 'GBP'});
    expect((m.contenanceMl, m.estUneMignonnette, m.contenanceAffichee), (187, true, '187 ml'));
    expect(m.prixAffiche(true), endsWith('/ 187 ml'));
    expect(MenuWine.fromJson(m.toJson()).contenanceMl, 187);

    expect(vin('Bouteille', prix: 40).uniteDuPrix(true), 'bt');
    expect(vin('Bouteille', prix: 40, ml: 750).contenanceAffichee, isNull);
    expect(vin('Demie', prix: 22, ml: 375).contenanceAffichee, '375 ml');
    expect(vin('Magnum', prix: 120, ml: 1500).contenanceAffichee, 'magnum');
    expect(vin('Demie', prix: 22, ml: 375).estUneMignonnette, isFalse);
    // Ce qui n'est pas une contenance de bouteille est ignoré.
    for (final brut in [5, 'beaucoup', 50000, null]) {
      expect(MenuWine.contenanceDepuis(brut), isNull, reason: '$brut');
    }
  });

  test('dans un parcours, une mignonnette est un service, à son prix', () {
    final f = MenuFlightEngine.buildFlight(
      menu: carte([vin('Chablis', prix: 8, ml: 187), vin('Sancerre', prix: 9, ml: 187), vin('Champagne', prix: 12, ml: 200, type: 'sparkling')]),
      color: FlightWineColor.white,
    );
    expect(f.steps, isNotEmpty);
    for (final s in f.steps) {
      expect(s.glassPrice, s.wine.bottlePrice, reason: s.wine.name);
      expect(s.prixEstime, isFalse);
      expect(s.service, '${s.wine.contenanceMl} ml');
    }
  });

  test('le verre estimé suit la contenance de la bouteille', () {
    final f = MenuFlightEngine.buildFlight(
      menu: carte([vin('Bouteille', prix: 60), vin('Demie', prix: 30, ml: 375), vin('Magnum', prix: 120, ml: 1500)]),
      color: FlightWineColor.white,
    );
    final verre = {for (final s in f.steps) s.wine.name: s};
    expect(verre['Bouteille']?.glassPrice, 12);
    expect(verre['Demie']?.glassPrice, 12);
    expect(verre['Magnum']?.glassPrice, 12);
    expect(f.steps.every((s) => s.prixEstime && s.service == null), isTrue);
  });

  test('à prix égal, on ne compare que des bouteilles de même contenance', () {
    expect(APrixEgal.choisir([vin('Mignonnette', prix: 8, ml: 187, accord: 90), vin('Bouteille', prix: 8, accord: 70)]), isEmpty);
    expect(APrixEgal.choisir([vin('A', prix: 8, ml: 187, accord: 90), vin('B', prix: 8, ml: 187, accord: 70)]).keys, ['A']);
  });

  test('« le moins cher » ne compare pas une mignonnette à une bouteille', () {
    final mignonnette = vin('Chablis', prix: 8, ml: 187);
    final bouteille = vin('Sancerre', prix: 30);
    final phrase = RedactionDesRaisons.placeEnPrix(mignonnette, [mignonnette, bouteille], true);
    expect(phrase, contains('187 ml'));
    expect(phrase, isNot(contains('moins cher')));
    final entreMignonnettes = RedactionDesRaisons.placeEnPrix(mignonnette, [mignonnette, vin('Sancerre', prix: 9, ml: 187)], true);
    expect(entreMignonnettes, contains('le moins cher'));
  });

  test('la cave ne compare pas le prix d\'une mignonnette à celui d\'une bouteille', () {
    const cave = ContexteDeCave(cave: [VinDeMaCave(nom: 'Chablis', producteur: 'Maison Chablis', prixAchat: 20, deviseAchat: 'GBP')]);
    final lien = CellarBridgeEngine.lier([vin('Chablis', prix: 8, ml: 187)], cave).single.pontDeCave;
    expect(lien?.detail, isNot(contains('moins')));
    final bouteille = CellarBridgeEngine.lier([vin('Chablis', prix: 45)], cave).single.pontDeCave;
    expect(bouteille?.detail, contains('de moins qu\'ici'));
  });

  test('une demi-bouteille reste un autre vin de la carte, le verre rejoint la bouteille', () {
    final fusion = MenuScanService.fusionnerPagesDeCarte([
      {
        'wines': [
          {'name': 'Chablis', 'producer': 'X', 'vintage': 2022, 'bottle_price': 60},
          {'name': 'Chablis', 'producer': 'X', 'vintage': 2022, 'bottle_price': 32, 'bottle_ml': 375},
        ],
      },
      {
        'wines': [
          {'name': 'Chablis', 'producer': 'X', 'vintage': 2022, 'glass_prices': [{'format': '125ml', 'price': 12}]},
        ],
      },
    ], pagesDemandees: 2);
    final vins = (fusion['wines'] as List).cast<Map<String, dynamic>>();
    expect(vins, hasLength(2));
    expect(vins.firstWhere((v) => v['bottle_ml'] == null)['glass_prices'], hasLength(1));
    expect(vins.firstWhere((v) => v['bottle_ml'] == 375)['bottle_price'], 32);
  });
}
