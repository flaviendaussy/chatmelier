import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_pedagogy_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le débrief de dégustation : juste pour chaque vin, et entièrement en anglais quand
/// l'app l'est (29/09).
void main() {
  tearDown(() => Langue.estFr = true);

  Wine vin(String nom, String type, String region,
          {String? appellation, List<String> cepages = const [], int? millesime = 2019, String? elevage}) =>
      Wine(
        id: nom,
        name: nom,
        type: type,
        region: region,
        country: 'France',
        appellation: appellation,
        vintage: millesime,
        grapes: [for (final c in cepages) Grape(name: c, pct: 100 / cepages.length)],
        elevageType: elevage,
      );

  final vins = {
    'champagne': vin('Brut Réserve', 'sparkling', 'Champagne', appellation: 'Champagne', millesime: null),
    'prosecco': vin('Prosecco Superiore', 'sparkling', 'Vénétie', appellation: 'Prosecco', cepages: ['Glera'], millesime: null),
    'sauternes': vin('Château Test', 'dessert', 'Bordeaux', appellation: 'Sauternes', cepages: ['Sémillon']),
    'porto': vin('Porto Tawny 10 ans', 'fortified', 'Douro', millesime: null),
    'pauillac': vin('Château Test', 'red', 'Bordeaux', appellation: 'Pauillac', cepages: ['Cabernet Sauvignon', 'Merlot']),
    'cotes_du_rhone': vin('Côtes-du-Rhône', 'red', 'Vallée du Rhône', cepages: ['Grenache', 'Syrah']),
    'morgon': vin('Morgon', 'red', 'Beaujolais', appellation: 'Morgon', cepages: ['Gamay']),
    'chablis': vin('Chablis Premier Cru', 'white', 'Bourgogne', appellation: 'Chablis', cepages: ['Chardonnay']),
    'muscadet': vin('Muscadet Sèvre et Maine', 'white', 'Loire', appellation: 'Muscadet', cepages: ['Melon de Bourgogne']),
    'riesling': vin('Riesling Grand Cru', 'white', 'Alsace', cepages: ['Riesling']),
    'meursault': vin('Meursault', 'white', 'Bourgogne', appellation: 'Meursault', cepages: ['Chardonnay']),
    'rose': vin('Côtes de Provence', 'rosé', 'Provence', cepages: ['Grenache', 'Cinsault']),
    'orange': vin('Vin orange', 'orange', 'Jura'),
  };

  List<String> textes(TastingPedagogyReport r) => [
        r.archetypeAppearance,
        r.archetypePalate,
        r.sommelierPraise,
        ...r.archetypeAromas,
        for (final n in r.hiddenNuancesToDiscover) ...[n.name, n.origin, n.explanation],
        for (final p in r.scientificPillars) ...[p.title, p.chemicalKey, p.summary, p.detailedExplanation],
        for (final c in r.flavorOrigins) ...[c.title, c.sensoryContribution, c.detailedWhy, if (c.badgeText != null) c.badgeText!],
      ];

  // Des mots qui ne s'écrivent qu'en français ; les noms propres (Mourvèdre, Côtes…) passent.
  final francais = RegExp(r"\b(le|la|les|des|du|une|et|avec|pour|dans|sur|est|sont|vin|cépage|élevage|arômes?|bouche|robe)\b",
      caseSensitive: false);

  test('en anglais, aucun texte du débrief ne reste en français', () {
    Langue.estFr = false;
    final restes = <String>[];
    vins.forEach((cle, w) {
      for (final t in textes(TastingPedagogyEngine.analyze(wine: w))) {
        // Les noms de région sont des données : « Vallée du Rhône » reste tel quel.
        if (francais.hasMatch(t.replaceAll('Vallée du Rhône', ''))) restes.add('$cle : $t');
      }
    });
    expect(restes, isEmpty);
  });

  String tout(String cle) => textes(TastingPedagogyEngine.analyze(wine: vins[cle]!)).join('\n');

  test('un Prosecco ne sent ni la craie ni la brioche de Champagne', () {
    final t = tout('prosecco');
    expect(t, isNot(contains('craie')));
    expect(t, isNot(contains('Champagne')));
    expect(t, contains('cuve'));
  });

  test('un Sauternes et un Porto ne sont pas des rosés', () {
    expect(tout('sauternes'), isNot(contains('saumon')));
    expect(tout('sauternes'), contains('Miel'));
    expect(tout('porto'), isNot(contains('saumon')));
    expect(tout('porto'), contains('Mutage'));
  });

  test('un Pauillac n\'a pas le poivre de la Syrah, un Côtes-du-Rhône si', () {
    expect(tout('pauillac'), isNot(contains('Rotundone')));
    expect(tout('pauillac'), contains('Cassis'));
    expect(tout('cotes_du_rhone'), contains('Rotundone'));
  });

  test('le Kimméridgien et les thiols ne vont qu\'où ils sont', () {
    expect(tout('chablis'), contains('Kimméridgien'));
    expect(tout('muscadet'), isNot(contains('Kimméridgien')));
    expect(tout('riesling'), isNot(contains('Kimméridgien')));
    expect(tout('riesling'), contains('TDN'));
    expect(tout('chablis'), isNot(contains('Buis')));
  });

  test('un Chablis n\'a ni beurre noisette ni brioche', () {
    final t = tout('chablis');
    expect(t, isNot(contains('Beurre noisette')));
    expect(t, contains('Pomme verte'));
  });
}
