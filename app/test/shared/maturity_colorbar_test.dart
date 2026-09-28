import 'package:chatmelier/features/cellar/domain/wine_service_advisor.dart';
import 'package:chatmelier/shared/widgets/maturity_colorbar.dart';
import 'package:flutter_test/flutter_test.dart';

WineDrinkingWindowData fenetre({
  required int millesime,
  required int ouverture,
  required int debutApogee,
  required int finApogee,
  required int finDeGarde,
}) =>
    WineDrinkingWindowData(
      vintage: millesime,
      drinkStart: ouverture,
      drinkEnd: finDeGarde,
      peakStart: debutApogee,
      peakEnd: finApogee,
      maxYear: finDeGarde + 5,
      agingPotentialText: '',
    );

void main() {
  final bordeaux = fenetre(millesime: 2015, ouverture: 2019, debutApogee: 2024, finApogee: 2030, finDeGarde: 2036);

  test('au centre de son apogée, le curseur est au centre du vert (retour du 28/09)', () {
    final g = GeometrieDeGarde.calculer(bordeaux, annee: 2027);
    expect(g.curseur, closeTo(g.centreApogee, 1e-9));
    // L'ancienne jauge plaçait le vert à 55 % quel que soit le vin.
    expect(g.centreApogee, isNot(closeTo(0.55, 0.01)));
  });

  test('le vert suit la fenêtre de chaque vin', () {
    final primeur = fenetre(millesime: 2023, ouverture: 2023, debutApogee: 2024, finApogee: 2025, finDeGarde: 2027);
    final g = GeometrieDeGarde.calculer(primeur, annee: 2024);
    expect(g.curseur, closeTo(g.debutApogee, 1e-9));
    expect(GeometrieDeGarde.calculer(primeur, annee: 2025).curseur, closeTo(g.finApogee, 1e-9));
  });

  test('avant l\'apogée le curseur est à gauche du vert, après à droite', () {
    expect(GeometrieDeGarde.calculer(bordeaux, annee: 2021).curseur,
        lessThan(GeometrieDeGarde.calculer(bordeaux, annee: 2021).debutApogee));
    expect(GeometrieDeGarde.calculer(bordeaux, annee: 2033).curseur,
        greaterThan(GeometrieDeGarde.calculer(bordeaux, annee: 2033).finApogee));
  });

  test('une fenêtre incohérente ne produit jamais d\'arrêts qui reculent', () {
    final bancale = fenetre(millesime: 2015, ouverture: 2026, debutApogee: 2024, finApogee: 2022, finDeGarde: 2021);
    final arrets = GeometrieDeGarde.calculer(bancale, annee: 2024).arrets;
    expect(arrets, hasLength(GeometrieDeGarde.couleurs.length));
    for (var i = 1; i < arrets.length; i++) {
      expect(arrets[i], greaterThanOrEqualTo(arrets[i - 1]));
    }
  });
}
