import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/notifications/domain/digest_apogee.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le rendez-vous d'apogée de la semaine (V2.3 · D5).
void main() {
  final annee = DateTime.now().year;

  Bottle bouteille(String id, Wine vin, {int quantite = 1, String statut = 'in_cellar'}) => Bottle(
        id: id,
        cellarId: 'cave',
        wineId: vin.id,
        addedBy: 'moi',
        ownerId: 'moi',
        quantity: quantite,
        status: statut,
        wine: vin,
        createdAt: DateTime(2026, 1, 1),
      );

  // Un Bandol dont la fenêtre se referme cette année, un Chablis à son apogée, un Pauillac
  // trop jeune, et une Chartreuse (suivie au niveau, pas à l'apogée).
  final bandol = Wine(
      id: 'bandol', name: 'Bandol Rouge', type: 'red', region: 'Provence', country: 'France',
      vintage: annee - 12, drinkStart: annee - 8, drinkEnd: annee, peakStart: annee - 5, peakEnd: annee - 1);
  final chablis = Wine(
      id: 'chablis', name: 'Chablis Premier Cru', type: 'white', region: 'Bourgogne', country: 'France',
      vintage: annee - 4, drinkStart: annee - 2, drinkEnd: annee + 6, peakStart: annee - 1, peakEnd: annee + 2);
  final pauillac = Wine(
      id: 'pauillac', name: 'Pauillac', type: 'red', region: 'Bordeaux', country: 'France',
      vintage: annee - 2, drinkStart: annee + 6, drinkEnd: annee + 30, peakStart: annee + 12, peakEnd: annee + 25);
  final chartreuse = Wine(id: 'chartreuse', name: 'Chartreuse Verte', type: 'liqueur', region: 'Isère', country: 'France');

  test('les vins à ouvrir : d\'abord ceux dont la fenêtre se referme, jamais un vin trop jeune', () {
    final aBoire = DigestApogee.aBoire([
      bouteille('1', pauillac),
      bouteille('2', chablis),
      bouteille('3', bandol),
      bouteille('4', chartreuse),
    ]);
    expect(aBoire.map((b) => b.wine!.id), isNot(contains('pauillac')));
    expect(aBoire.map((b) => b.wine!.id), isNot(contains('chartreuse')), reason: 'un spiritueux n\'a pas d\'apogée');
    expect(aBoire.first.wine!.id, 'bandol', reason: 'la fenêtre qui se referme passe avant l\'apogée');
  });

  test('une bouteille bue ou épuisée n\'est pas proposée', () {
    expect(DigestApogee.aBoire([bouteille('1', chablis, statut: 'consumed'), bouteille('2', chablis, quantite: 0)]), isEmpty);
  });

  test('le message nomme les vins, avec leur millésime', () {
    final m = DigestApogee.message(DigestApogee.aBoire([bouteille('1', bandol), bouteille('2', chablis)]))!;
    expect(m.$1, contains('2'));
    expect(m.$2, contains('Bandol Rouge ${annee - 12}'));
    expect(DigestApogee.message(const []), isNull);
  });

  test('le rendez-vous : le prochain dimanche à 18 h, jamais dans l\'heure qui vient', () {
    final mercredi = DateTime(2026, 9, 30, 10);
    expect(DigestApogee.prochainRendezVous(mercredi), DateTime(2026, 10, 4, 18));
    final dimancheMidi = DateTime(2026, 10, 4, 12);
    expect(DigestApogee.prochainRendezVous(dimancheMidi), DateTime(2026, 10, 4, 18));
    final dimancheSoir = DateTime(2026, 10, 4, 17, 30);
    expect(DigestApogee.prochainRendezVous(dimancheSoir), DateTime(2026, 10, 11, 18));
  });
}
