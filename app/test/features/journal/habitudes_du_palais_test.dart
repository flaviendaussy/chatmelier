import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/journal/domain/habitudes_du_palais.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';

/// 13/10 : « base-toi aussi un peu sur ce que l'utilisateur boit pour voir si un vin est à
/// son niveau ou pas ». Le sommelier de la carte reçoit ce que la personne boit d'habitude.
void main() {
  final maintenant = DateTime(2026, 10, 16);

  TastingEntry degustation(String nom,
          {String? producteur, int? millesime, String? appellation, double? note, int ilYA = 10, String? defaut}) =>
      TastingEntry(
        id: nom,
        wineId: nom,
        wineName: nom,
        producer: producteur,
        vintage: millesime,
        appellation: appellation,
        rating: note,
        fault: defaut,
        consumedAt: maintenant.subtract(Duration(days: ilYA)),
      );

  test('les dégustations récentes, de la plus récente, avec domaine, appellation et note', () {
    final texte = HabitudesDuPalais.resumer([
      degustation('Clos des Grives', producteur: 'Domaine Combier', millesime: 2019, appellation: 'Crozes-Hermitage', note: 8, ilYA: 20),
      degustation('Meursault 1er Cru Charmes', producteur: 'Domaine Roulot', millesime: 2018, appellation: 'Meursault', note: 9.5, ilYA: 3),
    ], fr: true, maintenant: maintenant);
    final lignes = texte.split('\n');
    expect(lignes[1], '- Meursault 1er Cru Charmes 2018, Domaine Roulot — 9,5/10');
    expect(lignes[2], '- Clos des Grives 2019, Domaine Combier, Crozes-Hermitage — 8/10');
    expect(lignes.last, 'Note moyenne : 8,8/10 sur 2 dégustations.');
  });

  test('ni bouteille défectueuse, ni dégustation ancienne, ni journal vide', () {
    final texte = HabitudesDuPalais.resumer([
      degustation('Bouchonné', note: 3, defaut: 'bouchon'),
      degustation('Il y a un an', note: 9, ilYA: 365),
      degustation('Récent', note: 7),
    ], fr: true, maintenant: maintenant);
    expect(texte, isNot(contains('Bouchonné')));
    expect(texte, isNot(contains('Il y a un an')));
    expect(texte, contains('Récent'));
    expect(HabitudesDuPalais.resumer(const [], fr: true), isEmpty);
  });

  test('pas plus de douze vins, la moyenne sur toutes les notes', () {
    final texte = HabitudesDuPalais.resumer([
      for (var i = 0; i < 20; i++) degustation('Vin $i', note: 6, ilYA: i + 1),
    ], fr: true, maintenant: maintenant);
    expect(texte.split('\n').where((l) => l.startsWith('- ')), hasLength(HabitudesDuPalais.nombreMax));
    expect(texte, endsWith('sur 20 dégustations.'));
  });
}
