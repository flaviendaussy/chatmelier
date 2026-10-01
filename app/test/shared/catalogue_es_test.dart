import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/shared/langues/catalogue_es.g.dart';

/// Toute phrase française passée à `tr`, `trSi` ou `Phrase` a sa traduction espagnole
/// (V2.3 · H4). Une phrase ajoutée sans passer par `tool/langues` fait échouer ce test :
///
///     python3 tool/langues/extraire.py        # liste les nouvelles phrases
///     python3 tool/langues/lot.py es afficher 0 110
///     python3 tool/langues/lot.py es appliquer traductions.json
///     python3 tool/langues/generer.py es
void main() {
  final marque = RegExp(r'\{(\w+)\}');

  test('le catalogue espagnol couvre toutes les phrases du code', () {
    final manquantes = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/langues/')) continue;
      for (final phrase in phrasesFrancaises(f.readAsStringSync())) {
        if (!catalogueEs.containsKey(phrase)) manquantes.add('${f.path} : $phrase');
      }
    }
    expect(manquantes, isEmpty, reason: 'Sans traduction espagnole :\n${manquantes.take(30).join('\n')}');
  });

  test('chaque traduction garde exactement les marques de la phrase française', () {
    final fautives = <String>[];
    catalogueEs.forEach((fr, es) {
      final a = marque.allMatches(fr).map((m) => m.group(1)).toSet();
      final b = marque.allMatches(es).map((m) => m.group(1)).toSet();
      if (a.length != b.length || !a.containsAll(b)) fautives.add('$fr → $es');
      if (es.trim().isEmpty) fautives.add('$fr → (vide)');
    });
    expect(fautives, isEmpty, reason: fautives.take(20).join('\n'));
  });
}

/// Les phrases françaises littérales passées à `tr(`, `trSi(x, ` ou `Phrase(`.
///
/// Un petit analyseur plutôt qu'une expression régulière : les chaînes se suivent parfois
/// (« 'a' 'b' »), contiennent des apostrophes échappées, et le premier argument de `trSi`
/// peut lui-même contenir des chaînes et des virgules entre parenthèses.
Iterable<String> phrasesFrancaises(String source) sync* {
  // Les lignes de commentaire (exemples de la documentation) ne sont pas du code.
  source = source.split('\n').map((l) => l.trimLeft().startsWith('//') ? '' : l).join('\n');
  final appel = RegExp(r"(?<![A-Za-z0-9_])(tr|trSi|Phrase)\(");
  for (final m in appel.allMatches(source)) {
    var i = m.end;
    if (m.group(1) == 'trSi') {
      i = _apresPremierArgument(source, i);
      if (i < 0) continue;
    }
    final phrase = _litterauxAdjacents(source, i);
    if (phrase != null) yield phrase;
  }
}

int _sauterEspaces(String s, int i) {
  while (i < s.length && ' \t\r\n'.contains(s[i])) {
    i++;
  }
  return i;
}

/// L'indice juste après la virgule qui termine le premier argument, ou -1.
int _apresPremierArgument(String s, int i) {
  var profondeur = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      final fin = _finDeChaine(s, i);
      if (fin < 0) return -1;
      i = fin;
      continue;
    }
    if (c == '(' || c == '[' || c == '{') profondeur++;
    if (c == ')' || c == ']' || c == '}') {
      if (profondeur == 0) return -1;
      profondeur--;
    }
    if (c == ',' && profondeur == 0) return i + 1;
    i++;
  }
  return -1;
}

/// L'indice juste après la chaîne qui commence en [i].
int _finDeChaine(String s, int i) {
  final q = s[i];
  var j = i + 1;
  while (j < s.length) {
    if (s[j] == '\\') {
      j += 2;
      continue;
    }
    if (s[j] == q) return j + 1;
    if (s[j] == '\n') return -1;
    j++;
  }
  return -1;
}

/// Une ou plusieurs chaînes littérales adjacentes, décodées ; nul si l'argument n'en est pas.
String? _litterauxAdjacents(String s, int i) {
  final morceaux = StringBuffer();
  var trouve = false;
  while (true) {
    i = _sauterEspaces(s, i);
    if (i >= s.length || (s[i] != "'" && s[i] != '"')) break;
    final fin = _finDeChaine(s, i);
    if (fin < 0) return null;
    final brut = s.substring(i + 1, fin - 1);
    if (brut.contains(r'$')) {
      // Une interpolation : la phrase n'est pas une clé fixe (il n'en reste plus dans le
      // code, les marques {nom} les remplacent).
      if (RegExp(r'(?<!\\)\$').hasMatch(brut)) return null;
    }
    morceaux.write(_decoder(brut));
    trouve = true;
    i = fin;
  }
  if (!trouve) return null;
  // L'argument doit s'arrêter là (une virgule ou la parenthèse), sans opérateur.
  final apres = _sauterEspaces(s, i);
  if (apres < s.length && s[apres] != ',' && s[apres] != ')') return null;
  return morceaux.toString();
}

String _decoder(String brut) {
  final sortie = StringBuffer();
  for (var i = 0; i < brut.length; i++) {
    final c = brut[i];
    if (c == '\\' && i + 1 < brut.length) {
      final n = brut[++i];
      switch (n) {
        case 'n':
          sortie.write('\n');
        case 't':
          sortie.write('\t');
        case 'r':
          sortie.write('\r');
        default:
          sortie.write(n);
      }
    } else {
      sortie.write(c);
    }
  }
  return sortie.toString();
}
