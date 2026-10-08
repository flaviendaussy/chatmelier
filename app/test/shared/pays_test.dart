import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/shared/utils/langue.dart';
import 'package:chatmelier/shared/utils/pays.dart';

void main() {
  tearDown(() => Langue.code = 'fr');

  test('un pays se reconnaît dans toutes les langues, et se lit dans celle de l\'écran', () {
    for (final nom in ['Spain', 'Espagne', 'España', 'espana', 'Spagna']) {
      expect(Pays.code(nom), 'ES', reason: nom);
      expect(Pays.nom(nom, 'fr'), 'Espagne');
      expect(Pays.nom(nom, 'en'), 'Spain');
      expect(Pays.nom(nom, 'es'), 'España');
      expect(Pays.nom(nom, 'it'), 'Spagna');
    }
    Langue.code = 'fr';
    expect(Pays.nom('New Zealand'), 'Nouvelle-Zélande');
    expect(Pays.nom('USA'), 'États-Unis');
    expect(Pays.nom('Maroc', 'en'), 'Morocco');
  });

  test('un nom inconnu reste tel quel, et rien ne devient la France', () {
    expect(Pays.code('Narnia'), isNull);
    expect(Pays.nom('Narnia'), 'Narnia');
    expect(Pays.nom(''), '');
    expect(Pays.nom(null), '');
    expect(Pays.drapeau('Narnia'), '🌍');
  });

  test('les drapeaux', () {
    expect(Pays.drapeau('Espagne'), '🇪🇸');
    expect(Pays.drapeau('Morocco'), '🇲🇦');
    expect(Pays.drapeau('Scotland'), '🏴󠁧󠁢󠁳󠁣󠁴󠁿');
  });
}
