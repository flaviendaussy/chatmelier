import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/auth/presentation/widgets/wine_taste_radar_chart.dart';

/// Vérifie que les libellés d'axes du radar tiennent dans la zone qu'on leur donne.
///
/// Constaté à l'écran sur Pixel 7 : dans la carte « Taste Radar » de l'écran de profil
/// (boîte 260 × 190), « Tannins & Grip » recouvrait le sous-titre de la carte et
/// « Spice & Character » passait sous l'encadré suivant. Le rayon était calculé à partir
/// de la seule LARGEUR (`size.width / 2 * 0.70`), donc dès que la boîte était plus large
/// que haute, les libellés du haut et du bas tombaient hors du cadre.
void main() {
  /// Position verticale du libellé le plus haut (angle -π/2) et du plus bas (+π/2).
  ({double haut, double bas}) extremesVerticaux(Size size) {
    final r = WineTasteRadarChart.radiusFor(size, true);
    final labelRadius = r + WineTasteRadarChart.labelBand * 0.6;
    final cy = size.height / 2;
    return (haut: cy - labelRadius, bas: cy + labelRadius);
  }

  group('🕸️ Géométrie des libellés du radar', () {
    test('la boîte large et basse de l\'écran de profil ne déborde plus', () {
      const size = Size(260, 190);
      final e = extremesVerticaux(size);

      // Demi-hauteur d'un libellé sur deux lignes à 9,5 px (height: 1.1) ≈ 10,5 px.
      const demiLibelle = 10.5;
      expect(e.haut - demiLibelle, greaterThanOrEqualTo(0.0),
          reason: 'Le libellé du haut sortait de 18 px et recouvrait le sous-titre.');
      expect(e.bas + demiLibelle, lessThanOrEqualTo(size.height),
          reason: 'Le libellé du bas passait sous l\'encadré suivant.');
    });

    test('l\'ancienne formule débordait bien — le test aurait attrapé le défaut', () {
      const size = Size(260, 190);
      final ancienRayon = (size.width / 2) * 0.70;
      final ancienHaut = size.height / 2 - (ancienRayon + 22);
      expect(ancienHaut, lessThan(0.0),
          reason: 'Reproduit le défaut d\'origine : -18 px, donc hors cadre.');
    });

    test('une boîte carrée reste correcte', () {
      for (final cote in [190.0, 260.0, 360.0]) {
        final e = extremesVerticaux(Size(cote, cote));
        expect(e.haut, greaterThanOrEqualTo(0.0), reason: 'côté $cote');
        expect(e.bas, lessThanOrEqualTo(cote), reason: 'côté $cote');
      }
    });

    test('le rayon suit le plus petit côté, jamais la largeur seule', () {
      final large = WineTasteRadarChart.radiusFor(const Size(400, 190), true);
      final carre = WineTasteRadarChart.radiusFor(const Size(190, 190), true);
      expect(large, equals(carre),
          reason: 'Élargir la boîte sans la grandir ne doit pas grossir le tracé.');
    });

    test('une boîte minuscule garde un rayon dessinable', () {
      expect(WineTasteRadarChart.radiusFor(const Size(40, 40), true), equals(20.0),
          reason: 'Plancher à 20 px plutôt qu\'un rayon négatif.');
    });

    test('sans libellés, le tracé occupe presque toute la boîte', () {
      final r = WineTasteRadarChart.radiusFor(const Size(200, 200), false);
      expect(r, closeTo(90.0, 0.001));
      expect(r, greaterThan(WineTasteRadarChart.radiusFor(const Size(200, 200), true)),
          reason: 'Pas de libellés à loger : aucune raison de réserver la bande.');
    });
  });

  test('la bande réservée couvre bien deux lignes de libellé', () {
    const tailleTexte = 9.5, hauteurLigne = 1.1, lignes = 2;
    expect(WineTasteRadarChart.labelBand,
        greaterThan(tailleTexte * hauteurLigne * lignes),
        reason: 'Sinon un libellé sur deux lignes dépasse quand même.');
  });

  group("🌫️ Halo d'incertitude", () {
    test('un axe bien connu ne produit aucun halo', () {
      expect(WineTasteRadarChart.uncertaintyMargin(1.0), equals(0.0),
          reason: 'Suggérer une incertitude là où le modèle a observé serait aussi '
              'malhonnête que de prétendre savoir là où il devine.');
    });

    test("un axe jamais observé s'affiche au maximum de flou", () {
      expect(WineTasteRadarChart.uncertaintyMargin(0.0), equals(2.5));
    });

    test('le halo se resserre à mesure que les observations arrivent', () {
      // Confiance = n/(n+5) : 1 dégustation ≈ 0,17, 5 ≈ 0,50, 20 ≈ 0,80.
      final m1 = WineTasteRadarChart.uncertaintyMargin(1 / 6);
      final m5 = WineTasteRadarChart.uncertaintyMargin(0.5);
      final m20 = WineTasteRadarChart.uncertaintyMargin(20 / 25);
      expect(m1, greaterThan(m5));
      expect(m5, greaterThan(m20));
      expect(m20, greaterThan(0.0),
          reason: 'Même à 20 dégustations, on ne prétend jamais tout savoir.');
    });

    test('une confiance hors bornes ne casse pas le tracé', () {
      expect(WineTasteRadarChart.uncertaintyMargin(-1.0), equals(2.5));
      expect(WineTasteRadarChart.uncertaintyMargin(42.0), equals(0.0));
    });
  });
}
