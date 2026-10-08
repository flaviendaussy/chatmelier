import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/cellar/data/traduction_des_fiches.dart';
import 'package:chatmelier/shared/services/fonctions_ia.dart';

const notesAnglaises = 'Deep ruby with garnet reflections at the rim. The nose offers ripe black cherries and plums, '
    'with refined notes of cedar and clove.';
const accordsAnglais = ['Roasted suckling lamb with rosemary', 'Charcoal-grilled ribeye with pepper sauce'];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('une fiche anglaise, lue en français : traduite une fois, puis gardée', () async {
    final appels = <Map<String, dynamic>>[];
    final service = TraductionDesFiches(
      ia: FonctionsIa.pourEssai((fonction, corps) async {
        appels.add(corps);
        return {
          'resultat': {
            'notes': 'Rubis profond aux reflets grenat. Le nez offre des cerises noires mûres et des prunes, '
                'avec de fines notes de cèdre et de clou de girofle.',
            'accords': ['Agneau de lait rôti au romarin', 'Entrecôte grillée au charbon, sauce au poivre'],
          },
          'couts': [],
        };
      }),
    );
    final t = await service.traduire(notes: notesAnglaises, accords: accordsAnglais, langue: 'fr');
    expect(t, isNotNull);
    expect(t!.depuis, 'en');
    expect(t.notes, startsWith('Rubis profond'));
    expect(t.accords, hasLength(2));
    expect(appels.single['tache'], 'traduire_fiche');
    expect(appels.single['langue'], 'fr');

    final encore = await service.traduire(notes: notesAnglaises, accords: accordsAnglais, langue: 'fr');
    expect(encore!.notes, t.notes);
    expect(appels, hasLength(1), reason: 'la seconde lecture vient du téléphone');
  });

  test('une fiche déjà dans la langue de l\'app : aucun appel', () async {
    var appels = 0;
    final service = TraductionDesFiches(
      ia: FonctionsIa.pourEssai((f, c) async {
        appels++;
        return {};
      }),
    );
    expect(await service.traduire(notes: notesAnglaises, accords: accordsAnglais, langue: 'en'), isNull);
    expect(appels, 0);
  });

  test('une traduction qui perd un plat n\'est pas fidèle : les accords restent tels quels', () {
    final t = TraductionDesFiches.lire(
      {'notes': 'Rubis profond.', 'accords': ['Agneau de lait rôti']},
      (notes: 'en', accords: 'en'),
      accordsAttendus: 2,
    );
    expect(t!.notes, 'Rubis profond.');
    expect(t.accords, isNull);
  });

  test('seule la partie dans une autre langue part à la traduction', () {
    final besoin = TraductionDesFiches.aTraduire(
        notesAnglaises, ['Carré d\'agneau rôti au romarin', 'Côte de bœuf grillée sauce au poivre'], 'fr');
    expect(besoin.notes, 'en');
    expect(besoin.accords, isNull);
  });
}
