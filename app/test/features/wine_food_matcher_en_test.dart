import 'dart:io';

import 'package:chatmelier/features/cellar/domain/wine_food_matcher_en.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les commentaires d'accord de la cave en anglais : aucun ne doit retomber en français.
void main() {
  test('chaque commentaire et conseil de service a sa traduction', () {
    final source = File('lib/features/cellar/domain/wine_food_matcher.dart').readAsStringSync();
    final affectations = RegExp(r"\b(?:comment|serving|_parDefaut)\s*=\s*(.*?);\n", dotAll: true);
    final litteral = RegExp(r"'((?:[^'\\]|\\.)*)'");
    final manquants = <String>[];
    for (final a in affectations.allMatches(source)) {
      for (final l in litteral.allMatches(a.group(1)!)) {
        final t = l.group(1)!.replaceAll(r"\'", "'");
        if (t.isEmpty || RegExp(r'^[a-z_ ]+$').hasMatch(t)) continue;
        if (!accordsEnAnglais.containsKey(t)) manquants.add(t);
      }
    }
    expect(manquants, isEmpty);
  });

  test('les commentaires ne nomment pas un vin que la condition ne garantit pas', () {
    final source = File('lib/features/cellar/domain/wine_food_matcher.dart').readAsStringSync();
    expect(source, isNot(contains('richesse liquoreuse du Sauternes')));
    expect(source, isNot(contains('la fraîcheur du Champagne')));
    expect(source, isNot(contains('terroir kimméridgien')), reason: 'le Muscadet pousse sur granit et gneiss');
    expect(source, isNot(contains('rose, litchi')), reason: 'un Riesling d\'Alsace passe par cette branche');
    expect(source, isNot(contains('grand Tempranillo')), reason: 'un Jumilla est un Monastrell');
  });
}
