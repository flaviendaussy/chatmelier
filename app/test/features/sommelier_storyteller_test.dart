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
    expect(t, contains('peaux'));
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
