import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/wine_food_matcher.dart';

/// 19/10, Flavien : « regarde les plats proposés : il n'y a pas de salades par exemple.
/// Augmente le nombre de plats pour les accords ! » Quatre familles de plus (salades,
/// légumes, soupes, œufs et tartes salées), des plats de plus dans les autres, et ce que
/// ces plats ont révélé du moteur : un Riesling sec proposé sur une pavlova, un Muscadet
/// relégué sur un plateau de fruits de mer, un Sancerre sur un Ossau-Iraty.
void main() {
  var n = 0;
  Bottle bouteille(String nom, String type, String region, List<String> cepages, {String? appellation}) {
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
        vintage: 2018,
        drinkStart: 2022,
        drinkEnd: 2035,
        grapes: [for (final c in cepages) Grape(name: c)],
      ),
    );
  }

  final cave = [
    bouteille('Pauillac', 'red', 'Bordeaux', ['Cabernet Sauvignon', 'Merlot'], appellation: 'Pauillac'),
    bouteille('Gevrey-Chambertin', 'red', 'Bourgogne', ['Pinot Noir'], appellation: 'Gevrey-Chambertin'),
    bouteille('Morgon', 'red', 'Beaujolais', ['Gamay'], appellation: 'Morgon'),
    bouteille('Cornas', 'red', 'Vallée du Rhône', ['Syrah'], appellation: 'Cornas'),
    bouteille('Cahors', 'red', 'Sud-Ouest', ['Malbec'], appellation: 'Cahors'),
    bouteille('Chianti Classico', 'red', 'Toscane', ['Sangiovese'], appellation: 'Chianti Classico'),
    bouteille('Chablis', 'white', 'Bourgogne', ['Chardonnay'], appellation: 'Chablis Premier Cru'),
    bouteille('Meursault', 'white', 'Bourgogne', ['Chardonnay'], appellation: 'Meursault'),
    bouteille('Sancerre', 'white', 'Vallée de la Loire', ['Sauvignon Blanc'], appellation: 'Sancerre'),
    bouteille('Riesling', 'white', 'Alsace', ['Riesling']),
    bouteille('Gewurztraminer', 'white', 'Alsace', ['Gewurztraminer']),
    bouteille('Apremont', 'white', 'Savoie', ['Jacquère'], appellation: 'Apremont'),
    bouteille('Muscadet', 'white', 'Vallée de la Loire', ['Melon de Bourgogne'], appellation: 'Muscadet Sèvre-et-Maine'),
    bouteille('Bandol rosé', 'rose', 'Provence', ['Mourvèdre'], appellation: 'Bandol'),
    bouteille('Champagne', 'sparkling', 'Champagne', ['Chardonnay', 'Pinot Noir'], appellation: 'Champagne'),
    bouteille('Sauternes', 'dessert', 'Bordeaux', ['Sémillon'], appellation: 'Sauternes'),
    bouteille('Banyuls', 'fortified', 'Roussillon', ['Grenache'], appellation: 'Banyuls'),
  ];

  List<String> vins(String plat) =>
      [for (final m in WineFoodMatcher.findMatches(bottles: cave, dishQuery: plat)) m.bottle.wine!.name];
  String premier(String plat) => vins(plat).first;
  final rouges = {'Pauillac', 'Gevrey-Chambertin', 'Morgon', 'Cornas', 'Cahors', 'Chianti Classico'};

  test('quatre familles de plus, chacune riche d\'au moins neuf plats', () {
    for (final id in ['salads', 'vegetarian', 'soups', 'eggs_savoury_tarts']) {
      final famille = WineFoodMatcher.categories.firstWhere((c) => c.id == id);
      expect(famille.sampleDishes.length, greaterThanOrEqualTo(9), reason: id);
    }
    final total = WineFoodMatcher.categories.fold<int>(0, (s, c) => s + c.sampleDishes.length);
    expect(total, greaterThanOrEqualTo(200));
  });

  group('les salades se jugent à leur vinaigrette', () {
    test('le chèvre chaud appelle un Sancerre, la niçoise un rosé de Provence', () {
      expect(premier('Salade de chèvre chaud'), 'Sancerre');
      expect(premier('Salade niçoise'), 'Bandol rosé');
      expect(premier('Insalata nizzarda'), 'Bandol rosé');
    });

    test('une salade thaïe au bœuf n\'appelle pas un grand rouge', () {
      for (final plat in ['Salade thaïe de bœuf au citron vert', 'Thai beef salad with lime']) {
        expect(['Gewurztraminer', 'Riesling'], contains(premier(plat)), reason: plat);
        expect(vins(plat), isNot(contains('Pauillac')), reason: plat);
      }
    });

    test('aucun rouge en tête d\'une salade, sauf le Gamay de la salade lyonnaise ou des lentilles', () {
      for (final plat in ['Salade grecque à la feta', 'Taboulé libanais aux herbes', 'Salade César au poulet', 'Salade de crevettes et pamplemousse']) {
        expect(rouges, isNot(contains(premier(plat))), reason: plat);
      }
      expect(premier('Salade lyonnaise aux lardons et œuf poché'), 'Morgon');
      expect(premier('Salade de lentilles aux échalotes'), 'Morgon');
    });
  });

  test('les soupes : la bouillabaisse en Provence, le pho sans rouge, la bisque au Chardonnay', () {
    expect(premier('Bouillabaisse marseillaise'), 'Bandol rosé');
    expect(rouges, isNot(contains(premier('Pho vietnamien au bœuf'))));
    expect(premier('Bisque de homard'), 'Meursault');
    expect(premier('Soupe à l\'oignon gratinée'), 'Apremont');
    expect(premier('Garbure béarnaise'), 'Cahors');
  });

  test('les légumes : la ratatouille au rosé, l\'asperge au Sauvignon, pas au Pinot Noir', () {
    expect(premier('Ratatouille provençale'), 'Bandol rosé');
    expect(premier('Risotto aux asperges vertes'), 'Sancerre');
    expect(premier('Aubergines à la parmigiana'), 'Chianti Classico');
    expect(premier('Gratin dauphinois'), 'Meursault');
  });

  test('les œufs et les tartes salées : la meurette en Bourgogne, la quiche en Alsace, sec', () {
    expect(premier('Œufs en meurette'), 'Gevrey-Chambertin');
    expect(premier('Quiche lorraine'), 'Riesling');
    expect(premier('Flammekueche alsacienne'), 'Riesling');
    expect(premier('Œufs Bénédicte'), 'Champagne');
    expect(premier('Galette bretonne complète'), 'Muscadet');
    // Une tarte à l'oignon n'est pas un dessert ; les œufs à la neige, si.
    expect(vins('Tarte à l\'oignon'), isNot(contains('Sauternes')));
    expect(premier('Œufs à la neige'), 'Sauternes');
  });

  test('ce que les nouveaux plats ont révélé du moteur', () {
    // Un Riesling sec n'est pas un vin de dessert.
    for (final plat in ['Pavlova aux fruits rouges', 'Mille-feuille à la vanille', 'Tarte Tatin tiède à la crème']) {
      expect(vins(plat), isNot(contains('Riesling')), reason: plat);
      expect(vins(plat), isNot(contains('Gewurztraminer')), reason: plat);
      expect(premier(plat), 'Sauternes', reason: plat);
    }
    // Le Muscadet, classique du plateau de fruits de mer et de la plancha.
    for (final plat in ['Plateau de fruits de mer', 'Calamars à la plancha', 'Paella aux fruits de mer']) {
      expect(vins(plat).take(2), contains('Muscadet'), reason: plat);
    }
    // Une brebis appelle un rouge, pas un Sancerre.
    for (final plat in ['Ossau-Iraty et confiture de cerises noires', 'Manchego affiné', 'Pecorino toscano']) {
      expect(rouges, contains(premier(plat)), reason: plat);
    }
    // Le petit salé et le hachis : un Gamay, avant un grand Pinot Noir.
    expect(premier('Petit salé aux lentilles du Puy'), 'Morgon');
    expect(premier('Hachis parmentier'), 'Morgon');
    // Le Gewurztraminer n'est plus le blanc de la raclette.
    expect(vins('Raclette traditionnelle').take(3), isNot(contains('Gewurztraminer')));
  });

  test('le conseil sans bouteille connaît les familles nouvelles, dans la langue de l\'écran', () {
    expect(WineFoodMatcher.getSommelierAdviceForDish('Salade niçoise', 'fr'), contains('vinaigrette'));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Gazpacho andaluz', 'es'), contains('Fino'));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Quiche lorraine', 'it'), contains('Alsazia'));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Provençal ratatouille', 'en'), contains('rosé'));
    expect(WineFoodMatcher.getSommelierAdviceForDish('Eggplant curry', 'en'), isNot(contains('quiche')));
  });
}
