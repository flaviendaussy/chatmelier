import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/wine_reverse_pairing_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// « Quel plat pour ce vin » : juste pour chaque vin, et en anglais quand l'app l'est.
void main() {
  tearDown(() => Langue.estFr = true);

  Wine vin(String nom, String type, String region, {String? appellation, List<String> cepages = const []}) => Wine(
        id: nom,
        name: nom,
        type: type,
        region: region,
        country: 'France',
        appellation: appellation,
        grapes: [for (final c in cepages) Grape(name: c, pct: 100 / cepages.length)],
      );

  final vins = [
    vin('Prosecco Superiore', 'sparkling', 'Vénétie', appellation: 'Prosecco'),
    vin('Château Test', 'dessert', 'Bordeaux', appellation: 'Sauternes'),
    vin('Porto Tawny', 'fortified', 'Douro'),
    vin('Bandol', 'red', 'Provence', appellation: 'Bandol', cepages: ['Mourvèdre']),
    vin('Morgon', 'red', 'Beaujolais', cepages: ['Gamay']),
    vin('Chablis', 'white', 'Bourgogne', appellation: 'Chablis', cepages: ['Chardonnay']),
    vin('Meursault', 'white', 'Bourgogne', cepages: ['Chardonnay']),
    vin('Côtes de Provence', 'rosé', 'Provence'),
    vin('Vin orange', 'orange', 'Jura'),
  ];

  test('en anglais, aucun plat ni raison ne reste en français', () {
    Langue.estFr = false;
    final francais = RegExp(r"\b(le|la|les|des|du|une|et|avec|pour|dans|sur|est|au|aux)\b", caseSensitive: false);
    final restes = <String>[];
    for (final w in vins) {
      for (final p in WineReversePairingEngine.getPairingsForWine(w)) {
        for (final t in [p.dishName, p.cookingAdvice, p.molecularRationale, ...p.keyIngredients]) {
          if (francais.hasMatch(t.replaceAll("d'Ambert", '').replaceAll("maître d'hôtel", ''))) restes.add('${w.name} : $t');
        }
      }
    }
    expect(restes, isEmpty);
  });

  test('un liquoreux n\'est pas servi avec une planche de charcuterie', () {
    final plats = WineReversePairingEngine.getPairingsForWine(vins[1]).map((p) => p.dishName).join(' ');
    expect(plats, contains('Foie Gras'));
    expect(plats, isNot(contains('Charcuteries')));
  });

  test('un Prosecco n\'a pas la craie de Champagne', () {
    final t = WineReversePairingEngine.getPairingsForWine(vins[0]).map((p) => p.molecularRationale).join(' ');
    expect(t, isNot(contains('craie')));
  });
}
