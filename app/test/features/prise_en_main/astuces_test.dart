import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/prise_en_main/data/preferences_de_prise_en_main.dart';
import 'package:chatmelier/features/prise_en_main/domain/astuces.dart';

void main() {
  test('jamais la même astuce deux fois tant que le tour n\'est pas fini', () async {
    SharedPreferences.setMockInitialValues({});
    final vues = <String>[];
    for (var i = 0; i < Astuces.toutes.length; i++) {
      vues.add((await PreferencesDePriseEnMain.prochaineAstuce()).id);
    }
    expect(vues.toSet(), hasLength(Astuces.toutes.length));
    // Le tour fini, on recommence par la première.
    expect((await PreferencesDePriseEnMain.prochaineAstuce()).id, Astuces.toutes.first.id);
  });

  test('les astuces sont actives par défaut, et se coupent d\'un geste', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await PreferencesDePriseEnMain.astucesActives(), isTrue);
    await PreferencesDePriseEnMain.activerLesAstuces(false);
    expect(await PreferencesDePriseEnMain.astucesActives(), isFalse);
  });

  test('le guide n\'est vu qu\'une fois', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await PreferencesDePriseEnMain.guideVu(), isFalse);
    await PreferencesDePriseEnMain.marquerLeGuideVu();
    expect(await PreferencesDePriseEnMain.guideVu(), isTrue);
  });

  test('chaque astuce a un identifiant unique et deux phrases', () {
    expect(Astuces.toutes.map((a) => a.id).toSet(), hasLength(Astuces.toutes.length));
    for (final a in Astuces.toutes) {
      expect(a.texte.fr.split(RegExp(r'[.:!?]\s')).length, lessThanOrEqualTo(3), reason: a.id);
    }
  });
}
