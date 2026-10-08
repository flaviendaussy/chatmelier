import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/sommelier/domain/sommelier_storyteller_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le récit du sommelier ne raconte que ce que la fiche permet de dire (29/09).
void main() {
  tearDown(() => Langue.estFr = true);

  String recit(Wine w) => SommelierStorytellerEngine.generateStory(w).fullText;

  test('un Prosecco ne naît pas dans la craie de Champagne', () {
    final t = recit(const Wine(
      id: 'p',
      name: 'Prosecco Superiore',
      type: 'Effervescent',
      region: 'Vénétie',
      country: 'Italie',
      appellation: 'Conegliano Valdobbiadene Prosecco',
      grapes: [Grape(name: 'Glera', pct: 100)],
    ));
    expect(t, isNot(contains('Champagne')));
    expect(t, isNot(contains('craie')));
    expect(t, contains('cuve close'));
    expect(t, isNot(contains('brioche')), reason: 'pas de long repos sur lies en cuve close');
  });

  test('un Champagne a sa craie et sa prise de mousse en bouteille', () {
    final t = recit(const Wine(
      id: 'c',
      name: 'Brut Réserve',
      producer: 'Maison Test',
      type: 'Effervescent',
      region: 'Champagne',
      country: 'France',
      vintage: 2016,
    ));
    expect(t, contains('crayeuses de Champagne'));
    expect(t, contains('en bouteille'));
    expect(t, contains('millésime 2016'));
  });

  test('un Morgon n\'est pas « élevé sous bois » sans que la fiche le dise', () {
    final t = recit(const Wine(
      id: 'm',
      name: 'Morgon Côte du Py',
      producer: 'Domaine Test',
      type: 'Rouge',
      region: 'Beaujolais',
      country: 'France',
      appellation: 'Morgon',
      vintage: 2021,
      grapes: [Grape(name: 'Gamay', pct: 100)],
    ));
    expect(t, isNot(contains('bois')));
    expect(t, contains('fruits rouges'));
    expect(t, isNot(contains('fruits noirs')));
    expect(t, contains('Tout commence par un lieu : Morgon, Beaujolais.'));
    expect(t, contains('Domaine Test y cultive Gamay'));
  });

  test('un élevage renseigné est raconté', () {
    final t = recit(const Wine(
      id: 'b',
      name: 'Château Test',
      type: 'Rouge',
      region: 'Bordeaux',
      country: 'France',
      appellation: 'Pauillac',
      grapes: [Grape(name: 'Cabernet Sauvignon', pct: 70), Grape(name: 'Merlot', pct: 30)],
      elevageType: 'Barriques de chêne, 18 mois',
    ));
    expect(t, contains('élevage sous bois patine les tanins'));
    expect(t, contains('Cabernet Sauvignon et Merlot'));
    expect(t, contains('cassis'));
  });

  test('un rosé n\'a ni tanins ni fruits noirs', () {
    final t = recit(const Wine(
      id: 'r',
      name: 'Côtes de Provence Rosé',
      type: 'Rosé',
      region: 'Provence',
      country: 'France',
      grapes: [Grape(name: 'Grenache', pct: 60), Grape(name: 'Cinsault', pct: 40)],
    ));
    expect(t, isNot(contains('tanin')));
    expect(t, isNot(contains('fruits noirs')));
    expect(t, contains('peau des raisins noirs'));
  });

  test('un liquoreux étiqueté « blanc » est raconté comme un liquoreux', () {
    final t = recit(const Wine(
      id: 's',
      name: 'Château Test',
      type: 'Blanc',
      region: 'Bordeaux',
      country: 'France',
      appellation: 'Sauternes',
      grapes: [Grape(name: 'Sémillon', pct: 90)],
    ));
    expect(t, contains('cueillis tard'));
    expect(t, contains('miel'));
  });

  test('« Château Cavalier » n\'est pas un cava, ni un Tokaji sec un liquoreux', () {
    final cavalier = recit(const Wine(
      id: 'cv',
      name: 'Château Cavalier Cuvée Marafiance',
      type: 'Rosé',
      region: 'Provence',
      country: 'France',
      appellation: 'Côtes de Provence',
    ));
    expect(cavalier, isNot(contains('bulle')));
    expect(cavalier, isNot(contains('en bouteille')));
    final tokaj = recit(const Wine(
      id: 'tk',
      name: 'Tokaji Furmint Száraz',
      type: 'Blanc',
      region: 'Tokaj',
      country: 'Hongrie',
      grapes: [Grape(name: 'Furmint', pct: 100)],
    ));
    expect(tokaj, isNot(contains('cueillis tard')));
    expect(tokaj, isNot(contains('miel')));
  });

  test('un porto ne passe pas pour un blanc pressé au frais', () {
    final t = recit(const Wine(
      id: 'pt',
      name: 'Porto Tawny 10 ans',
      type: 'Porto',
      region: 'Douro',
      country: 'Portugal',
    ));
    expect(t, isNot(contains('pressurage')));
    expect(t, isNot(contains('fleurs')));
    expect(t, isNot(contains('cueillis')));
  });

  test('rien d\'affirmé sur la vendange quand la fiche ne dit rien de l\'élevage', () {
    final t = recit(const Wine(
      id: 'cr',
      name: 'Crozes-Hermitage',
      type: 'Rouge',
      region: 'Vallée du Rhône',
      country: 'France',
      grapes: [Grape(name: 'Syrah', pct: 100)],
    ));
    expect(t, isNot(contains('cueillis')));
    expect(t, isNot(contains('mise en bouteille')));
    expect(t, contains('poivre'));
    // « Sans bois » n'est pas un élevage sous bois.
    final inox = recit(const Wine(
      id: 'ix',
      name: 'Chablis',
      type: 'Blanc',
      region: 'Bourgogne',
      country: 'France',
      grapes: [Grape(name: 'Chardonnay', pct: 100)],
      elevageType: 'Sans bois, en cuve inox',
    ));
    expect(inox, isNot(contains('sous bois')));
    expect(inox, contains('élevage en cuve'));
  });

  test('le cépage principal décide : un nebbiolo n\'a pas le cassis d\'un cabernet, ni la grenache le poivre', () {
    final barolo = recit(const Wine(
      id: 'bl',
      name: 'Barolo Castiglione',
      type: 'Rouge',
      region: 'Piémont',
      country: 'Italie',
      appellation: 'Barolo',
      subRegion: 'Castiglione Falletto',
      grapes: [Grape(name: 'Nebbiolo', pct: 100)],
    ));
    expect(barolo, contains('goudron'));
    expect(barolo, isNot(contains('cassis')));
    expect(barolo, isNot(contains('cuve close')), reason: '« asti » dans « Castiglione »');
    final cdp = recit(const Wine(
      id: 'cdp',
      name: 'Châteauneuf-du-Pape',
      type: 'Rouge',
      region: 'Vallée du Rhône',
      country: 'France',
      grapes: [Grape(name: 'Syrah', pct: 15), Grape(name: 'Grenache', pct: 70), Grape(name: 'Mourvèdre', pct: 15)],
    ));
    expect(cdp, contains('kirsch'));
    expect(cdp, isNot(contains('poivre')));
  });

  test('sans millésime, pas de « millésime les plus beaux millésimes »', () {
    final s = SommelierStorytellerEngine.generateStory(const Wine(
      id: 'n',
      name: 'Vin de France',
      type: 'Blanc',
      region: '',
      country: 'France',
    ));
    expect(s.fullText, isNot(contains('millésime')));
    expect(s.fullText, startsWith('Voici Vin de France.'));
    expect(s.subtitle, isEmpty);
  });

  test('en anglais, le récit est en anglais', () {
    Langue.estFr = false;
    final t = recit(const Wine(
      id: 'm',
      name: 'Morgon Côte du Py',
      type: 'Red',
      region: 'Beaujolais',
      country: 'France',
      appellation: 'Morgon',
      grapes: [Grape(name: 'Gamay', pct: 100)],
    ));
    expect(t, startsWith('It all starts with a place: Morgon, Beaujolais.'));
    expect(t, contains('red fruit'));
    expect(t, isNot(contains('é')));
  });
}
