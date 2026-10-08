import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/wine_food_matcher.dart';

/// « Quel vin pour mon plat ? » dans les quatre langues de l'app (08/10) : chaque plat
/// proposé trouve un accord, et le sommelier reste plausible quelle que soit la langue.
void main() {
  var n = 0;
  Bottle bouteille(String nom, String type, String region, List<String> cepages,
      {String? appellation, int millesime = 2018, int debut = 2022, int fin = 2035}) {
    n++;
    return Bottle(
      id: 'b$n',
      cellarId: 'c1',
      wineId: 'w$n',
      addedBy: 'u',
      ownerId: 'u',
      status: 'in_cellar',
      quantity: 2,
      createdAt: DateTime(2026, 1, 1),
      wine: Wine(
        id: 'w$n',
        name: nom,
        appellation: appellation,
        region: region,
        country: 'France',
        type: type,
        vintage: millesime,
        drinkStart: debut,
        drinkEnd: fin,
        grapes: [for (final c in cepages) Grape(name: c)],
      ),
    );
  }

  // Une cave variée, comme celle d'un amateur.
  final pauillac = bouteille('Château Pontet-Canet', 'red', 'Bordeaux', ['Cabernet Sauvignon', 'Merlot'], appellation: 'Pauillac', millesime: 2010, debut: 2020, fin: 2040);
  final bourgogne = bouteille('Gevrey-Chambertin', 'red', 'Bourgogne', ['Pinot Noir'], appellation: 'Gevrey-Chambertin', millesime: 2015, debut: 2021, fin: 2030);
  final cave = [
    pauillac,
    bourgogne,
    bouteille('Morgon', 'red', 'Beaujolais', ['Gamay'], appellation: 'Morgon', millesime: 2022, debut: 2023, fin: 2028),
    bouteille('Cornas', 'red', 'Vallée du Rhône', ['Syrah'], appellation: 'Cornas', millesime: 2016, debut: 2022, fin: 2034),
    bouteille('Cahors', 'red', 'Sud-Ouest', ['Malbec'], appellation: 'Cahors', millesime: 2015, debut: 2021, fin: 2032),
    bouteille('Chianti Classico', 'red', 'Toscane', ['Sangiovese'], appellation: 'Chianti Classico', millesime: 2019, debut: 2022, fin: 2030),
    bouteille('Chablis Premier Cru', 'white', 'Bourgogne', ['Chardonnay'], appellation: 'Chablis Premier Cru', millesime: 2020, debut: 2023, fin: 2032),
    bouteille('Meursault', 'white', 'Bourgogne', ['Chardonnay'], appellation: 'Meursault', millesime: 2018, debut: 2022, fin: 2030),
    bouteille('Sancerre', 'white', 'Vallée de la Loire', ['Sauvignon Blanc'], appellation: 'Sancerre', millesime: 2022, debut: 2023, fin: 2028),
    bouteille('Riesling Grand Cru', 'white', 'Alsace', ['Riesling'], millesime: 2019, debut: 2022, fin: 2032),
    bouteille('Gewurztraminer', 'white', 'Alsace', ['Gewurztraminer'], millesime: 2020, debut: 2022, fin: 2030),
    bouteille('Apremont', 'white', 'Savoie', ['Jacquère'], appellation: 'Apremont', millesime: 2023, debut: 2023, fin: 2027),
    bouteille('Muscadet sur lie', 'white', 'Vallée de la Loire', ['Melon de Bourgogne'], appellation: 'Muscadet Sèvre-et-Maine', millesime: 2023, debut: 2023, fin: 2027),
    bouteille('Bandol rosé', 'rose', 'Provence', ['Mourvèdre'], appellation: 'Bandol', millesime: 2023, debut: 2023, fin: 2027),
    bouteille('Champagne Brut', 'sparkling', 'Champagne', ['Chardonnay', 'Pinot Noir'], appellation: 'Champagne', millesime: 2016, debut: 2020, fin: 2030),
    bouteille('Sauternes', 'dessert', 'Bordeaux', ['Sémillon'], appellation: 'Sauternes', millesime: 2015, debut: 2020, fin: 2050),
    bouteille('Banyuls', 'fortified', 'Roussillon', ['Grenache'], appellation: 'Banyuls', millesime: 2012, debut: 2018, fin: 2040),
  ];

  test('chaque catégorie a son nom et ses plats en anglais, espagnol et italien, sans français', () {
    for (final cat in WineFoodMatcher.categories) {
      for (final langue in ['en', 'es', 'it']) {
        expect(cat.localizedLabel(langue), isNot(cat.label), reason: '${cat.id} en $langue');
        final plats = cat.getSampleDishes(langue);
        expect(plats, isNotEmpty);
        expect(plats, isNot(equals(cat.sampleDishes)), reason: '${cat.id} en $langue');
      }
    }
  });

  test('chaque plat proposé, dans chaque langue, trouve au moins un vin de la cave', () {
    final sansAccord = <String>[];
    for (final cat in WineFoodMatcher.categories) {
      for (final langue in ['fr', 'en', 'es', 'it']) {
        for (final plat in cat.getSampleDishes(langue)) {
          if (WineFoodMatcher.findMatches(bottles: cave, dishQuery: plat, lang: langue).isEmpty) {
            sansAccord.add('$langue · ${cat.id} · $plat');
          }
        }
      }
    }
    expect(sansAccord, isEmpty, reason: sansAccord.join('\n'));
  });

  test('un poulet rôti n\'est pas une viande rouge, quelle que soit la langue', () {
    for (final plat in ['Poulet rôti fermier', 'Roast farm chicken', 'Pollo asado de granja', 'Pollo ruspante arrosto']) {
      final accords = WineFoodMatcher.findMatches(bottles: cave, dishQuery: plat);
      expect(accords, isNotEmpty, reason: plat);
      expect(accords.first.bottle.id, isNot(pauillac.id), reason: '$plat : ${accords.first.bottle.wine!.name}');
    }
  });

  test('un bœuf bourguignon appelle un Bourgogne, en français comme en italien', () {
    for (final plat in ['Bœuf Bourguignon', 'Manzo alla borgognona']) {
      final accords = WineFoodMatcher.findMatches(bottles: cave, dishQuery: plat);
      expect(accords.first.bottle.id, bourgogne.id, reason: '$plat : ${accords.first.bottle.wine!.name}');
    }
  });

  test('un dessert au chocolat appelle un vin doux naturel, aussi en italien', () {
    for (final plat in ['Fondant au chocolat cœur coulant', 'Tortino al cioccolato dal cuore fondente']) {
      final accords = WineFoodMatcher.findMatches(bottles: cave, dishQuery: plat);
      expect(accords.first.bottle.wine!.name, 'Banyuls', reason: plat);
    }
  });

  test('le conseil sans bouteille parle la langue de l\'écran', () {
    expect(WineFoodMatcher.getSommelierAdviceForDish('', 'it'), contains('Indica un piatto'));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Ostriche', 'it'), contains('Chablis'));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Foie gras', 'en'), contains('Sauternes'));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Foie gras', 'en'), isNot(contains('Pour le foie gras')));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Tiramisù', 'es'), contains('Para un postre'));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Tartar de ternera', 'es'), isNot(contains('postre')));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Fondue bourguignonne', 'fr'), isNot(contains('Savoie')));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Pizza', 'it'), contains('Chianti'));
  });
}
