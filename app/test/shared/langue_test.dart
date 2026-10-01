import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/shared/langues/catalogues.dart';
import 'package:chatmelier/shared/utils/langue.dart';

/// Le moteur des langues (V2.3 · H1 à H6) : français, anglais, espagnol, et la place pour
/// d'autres. Une phrase s'écrit en français et en anglais dans le code ; toute autre langue
/// la retrouve dans son catalogue, indexé par la phrase française.
void main() {
  tearDown(() => Langue.code = 'fr');

  group('tr', () {
    test('rend le français, l\'anglais, ou le catalogue de la langue', () {
      Langue.code = 'fr';
      expect(tr('Annuler', 'Cancel'), 'Annuler');
      Langue.code = 'en';
      expect(tr('Annuler', 'Cancel'), 'Cancel');
      Langue.code = 'es';
      expect(tr('Annuler', 'Cancel'), 'Cancelar');
    });

    test('une phrase absente du catalogue retombe sur l\'anglais', () {
      Langue.code = 'es';
      expect(tr('Phrase qui n\'existe nulle part', 'A sentence that exists nowhere'),
          'A sentence that exists nowhere');
    });

    test('les marques sont remplies dans chaque langue', () {
      final valeurs = {'v1': 'Clio', 'quantity': 3};
      Langue.code = 'fr';
      expect(tr('Vin : {v1} ({quantity} en stock)', 'Wine: {v1} ({quantity} in stock)', valeurs),
          'Vin : Clio (3 en stock)');
      Langue.code = 'en';
      expect(tr('Vin : {v1} ({quantity} en stock)', 'Wine: {v1} ({quantity} in stock)', valeurs),
          'Wine: Clio (3 in stock)');
      Langue.code = 'es';
      expect(tr('Vin : {v1} ({quantity} en stock)', 'Wine: {v1} ({quantity} in stock)', valeurs),
          'Vino: Clio (3 en existencias)');
    });
  });

  group('trSi', () {
    test('vrai choisit le français, quelle que soit la langue de l\'app', () {
      Langue.code = 'es';
      expect(trSi(true, 'Annuler', 'Cancel'), 'Annuler');
    });

    test('faux choisit la langue de l\'app quand ce n\'est pas le français, l\'anglais sinon', () {
      Langue.code = 'es';
      expect(trSi(false, 'Annuler', 'Cancel'), 'Cancelar');
      Langue.code = 'en';
      expect(trSi(false, 'Annuler', 'Cancel'), 'Cancel');
      Langue.code = 'fr';
      expect(trSi(false, 'Annuler', 'Cancel'), 'Cancel');
    });
  });

  test('Phrase suit la langue de l\'app, ou celle qu\'on lui donne', () {
    const p = Phrase('Annuler', 'Cancel');
    Langue.code = 'es';
    expect(p.texte, 'Cancelar');
    expect(p.dans(true), 'Annuler');
    expect(p.dans(false), 'Cancelar');
  });

  test('trDonnee et trDonneeSi : le catalogue, puis la table anglaise, puis le français', () {
    const anglais = {'Rouge': 'Red', 'Donnée sans espagnol': 'Data without Spanish'};
    Langue.code = 'es';
    expect(trDonnee('Rouge', anglais), 'Tinto');
    expect(trDonnee('Donnée sans espagnol', anglais), 'Data without Spanish');
    expect(trDonnee('Inconnue partout', anglais), 'Inconnue partout');
    expect(trDonneeSi(true, 'Rouge', anglais), 'Rouge');
    expect(trDonneeSi(false, 'Rouge', anglais), 'Tinto');
    Langue.code = 'en';
    expect(trDonneeSi(false, 'Rouge', anglais), 'Red');
  });

  test('le code de langue d\'un paramètre booléen hérité', () {
    Langue.code = 'es';
    expect(codeDeLangue(true), 'fr');
    expect(codeDeLangue(false), 'es');
    Langue.code = 'fr';
    expect(codeDeLangue(false), 'en');
    expect(codeDeLangue('ES'), 'es');
  });

  test('une langue du téléphone non proposée retombe sur l\'anglais', () {
    Langue.definir(const Locale('de'));
    expect(Langue.code, 'en');
    Langue.definir(const Locale('es', 'MX'));
    expect(Langue.code, 'es');
    Langue.definir(const Locale('fr', 'CA'));
    expect(Langue.code, 'fr');
  });

  test('les verbes s\'accordent en espagnol avec « tú » et avec le groupe', () {
    Langue.code = 'es';
    const f = FormesDuVerbe.adorer;
    expect(f.pour(fr: false, lecteur: true, plusieurs: false), 'lo vas a adorar');
    expect(f.pour(fr: false, lecteur: false, plusieurs: false), 'lo va a adorar');
    expect(f.pour(fr: false, lecteur: true, plusieurs: true), 'lo van a adorar');
    expect(f.pour(fr: true, lecteur: true, plusieurs: true), 'allez l\'adorer');
    Langue.code = 'en';
    expect(f.pour(fr: false, lecteur: true, plusieurs: true), 'will love it');
  });

  test('chaque langue proposée hors français et anglais a son catalogue', () {
    for (final code in Langue.supportees.where((c) => c != 'fr' && c != 'en')) {
      expect(catalogues[code], isNotNull, reason: 'pas de catalogue pour « $code »');
      expect(catalogues[code], isNotEmpty);
    }
  });
}
