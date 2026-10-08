import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/shared/langues/catalogue_it.g.dart';

import 'catalogue_es_test.dart' show phrasesFrancaises;

/// Toute phrase française passée à `tr`, `trSi` ou `Phrase` a sa traduction italienne
/// (ajoutée le 08/10, même règle que l'espagnol) :
///
///     python3 tool/langues/extraire.py it
///     python3 tool/langues/lot.py it afficher 0 110
///     python3 tool/langues/lot.py it appliquer traductions.json
///     python3 tool/langues/generer.py it
void main() {
  final marque = RegExp(r'\{(\w+)\}');

  test('le catalogue italien couvre toutes les phrases du code', () {
    final manquantes = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/langues/')) continue;
      for (final phrase in phrasesFrancaises(f.readAsStringSync())) {
        if (!catalogueIt.containsKey(phrase)) manquantes.add('${f.path} : $phrase');
      }
    }
    expect(manquantes, isEmpty, reason: 'Sans traduction italienne :\n${manquantes.take(30).join('\n')}');
  });

  test('chaque traduction garde exactement les marques de la phrase française', () {
    final fautives = <String>[];
    catalogueIt.forEach((fr, it) {
      final a = marque.allMatches(fr).map((m) => m.group(1)).toSet();
      final b = marque.allMatches(it).map((m) => m.group(1)).toSet();
      if (a.length != b.length || !a.containsAll(b)) fautives.add('$fr → $it');
      if (it.trim().isEmpty) fautives.add('$fr → (vide)');
    });
    expect(fautives, isEmpty, reason: fautives.take(20).join('\n'));
  });

  test('aucune traduction italienne n\'est restée en espagnol ou en français', () {
    // Mots qui n'existent pas en italien : un oubli de traduction se voit tout de suite.
    final temoins = RegExp(
        r"\b(bodega|botella|cata|añada|vino tinto|también|aquí|está|¿|¡|bouteille|dégustation|millésime|cave à vin|vous)\b",
        caseSensitive: false);
    final fautives = <String>[];
    catalogueIt.forEach((fr, it) {
      if (temoins.hasMatch(it)) fautives.add('$fr → $it');
    });
    expect(fautives, isEmpty, reason: fautives.take(20).join('\n'));
  });
}
