// Les années sous la courbe de garde ne se chevauchent plus : à un an d'écart,
// « 2024 Début » s'écrivait sur « 2025 Apogée » (fiche d'une bouteille, 18/10).

import 'package:chatmelier/shared/widgets/gaussian_drinking_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void sansChevauchement(List<double> gauches, List<double> largeurs, {double ecart = 4}) {
    for (var i = 1; i < gauches.length; i++) {
      expect(gauches[i], greaterThanOrEqualTo(gauches[i - 1] + largeurs[i - 1] + ecart - 1e-9), reason: 'étiquette $i');
    }
  }

  test('deux années voisines s\'écartent, dans leur ordre', () {
    // Début en 2024 et Apogée en 2025 : douze pixels entre les deux.
    final gauches = placerSansChevauchement([150, 162], [36, 48], 0, 320)!;
    sansChevauchement(gauches, [36, 48]);
    // Chacune s'éloigne de l'autre, d'autant : 17 px de part et d'autre.
    expect(gauches[0] + 18 - 150, closeTo(-17, 1e-9));
    expect(gauches[1] + 24 - 162, closeTo(17, 1e-9));
  });

  test('une étiquette seule reste centrée sur son année', () {
    expect(placerSansChevauchement([100], [40], 0, 320), [80]);
  });

  test('près des bords, elles restent dans le cadre', () {
    final gauches = placerSansChevauchement([3, 290, 312], [40, 40, 40], 0, 320)!;
    expect(gauches.first, 0);
    expect(gauches.last + 40, lessThanOrEqualTo(320));
    sansChevauchement(gauches, [40, 40, 40]);
  });

  test('quatre années serrées tiennent sur une fiche de téléphone', () {
    final gauches = placerSansChevauchement([100, 110, 120, 130], [38, 36, 48, 30], 0, 300)!;
    sansChevauchement(gauches, [38, 36, 48, 30]);
    expect(gauches.first, greaterThanOrEqualTo(0));
    expect(gauches.last + 30, lessThanOrEqualTo(300));
  });

  test('si elles ne tiennent pas, rien n\'est placé : l\'appelant en retire une', () {
    expect(placerSansChevauchement([50, 100, 150, 200, 250], [70, 70, 70, 70, 70], 0, 300), isNull);
  });
}
