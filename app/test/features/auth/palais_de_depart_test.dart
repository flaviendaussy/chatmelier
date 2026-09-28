import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const declare = TasteProfile(id: 'moi', name: 'Moi', palaisDeDepart: {'tannin': 8, 'acidity': 3});

  test('sans dégustation, le radar montre le palais déclaré, avec une confiance nulle', () {
    final radar = WineTasteRadarCalculator.compute(declare);
    expect(radar.tannin, closeTo(8, 0.5));
    expect(declare.axisConfidence('tannin'), 0);
  });

  test('dès la première dégustation, la déclaration ne pèse plus que 15 %', () {
    final apresUne = declare.copyWith(avgTanninPreference: 0.4, axisObservations: {'tannin': 1});
    // 8 × 0,15 + 4 × 0,85 = 4,6 : la dégustation l'emporte nettement.
    expect(WineTasteRadarCalculator.compute(apresUne).tannin, closeTo(4.6, 0.6));
    expect(apresUne.axisConfidence('tannin'), greaterThan(0));
  });

  test('à la troisième, la déclaration s\'efface', () {
    final apresTrois = declare.copyWith(avgTanninPreference: 0.4, axisObservations: {'tannin': 3});
    final sansDeclaration = const TasteProfile(id: 'moi', name: 'Moi')
        .copyWith(avgTanninPreference: 0.4, axisObservations: {'tannin': 3});
    expect(WineTasteRadarCalculator.compute(apresTrois).tannin,
        closeTo(WineTasteRadarCalculator.compute(sansDeclaration).tannin, 1e-9));
  });

  test('sans déclaration, rien ne change', () {
    const vierge = TasteProfile(id: 'moi', name: 'Moi');
    expect(WineTasteRadarCalculator.compute(vierge).tannin, closeTo(5, 1));
  });

  test('le palais de départ se garde d\'une ouverture à l\'autre', () {
    final relu = TasteProfile.fromJson(declare.toJson());
    expect(relu.palaisDeDepart, {'tannin': 8.0, 'acidity': 3.0});
    expect(relu.axisObservations, isEmpty);
  });
}
