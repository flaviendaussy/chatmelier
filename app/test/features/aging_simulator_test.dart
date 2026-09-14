import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/aging_simulator_engine.dart';

void main() {
  group('⏳ Aging Simulator & Kinetic Deformation Tests', () {
    const grandCruRed = Wine(
      id: 'w_margaux',
      name: 'Château Margaux Premier Grand Cru Classé',
      type: 'Rouge',
      region: 'Bordeaux',
      country: 'France',
      vintage: 2018,
    );

    const whiteChablis = Wine(
      id: 'w_chablis',
      name: 'Chablis Grand Cru Les Clos',
      type: 'Blanc',
      region: 'Bourgogne',
      country: 'France',
      vintage: 2020,
    );

    test('Simulating +10 years on red wine softens tannins and boosts tertiary aromas', () {
      final snap0 = AgingSimulatorEngine.simulateAging(
        wine: grandCruRed,
        additionalYears: 0,
      );

      final snap10 = AgingSimulatorEngine.simulateAging(
        wine: grandCruRed,
        additionalYears: 10,
      );

      expect(snap10.targetYear, equals(DateTime.now().year + 10));

      // Tannins decrease over 10 years
      expect(snap10.simulatedRadar.tannin, lessThan(snap0.simulatedRadar.tannin));

      // Fresh fruit decreases
      expect(snap10.simulatedRadar.freshFruit, lessThan(snap0.simulatedRadar.freshFruit));

      // Tertiary aromas (sous-bois / spice) increase
      expect(snap10.simulatedRadar.spice, greaterThan(snap0.simulatedRadar.spice));

      // Robe transitions from red/ruby to brick/tuilé
      expect(snap10.robeDescription, contains('tuilé'));
    });

    test('Simulating white wine aging evolves color towards golden/amber without tannins', () {
      final snap0 = AgingSimulatorEngine.simulateAging(
        wine: whiteChablis,
        additionalYears: 0,
      );

      final snap8 = AgingSimulatorEngine.simulateAging(
        wine: whiteChablis,
        additionalYears: 8,
      );

      expect(snap0.simulatedRadar.tannin, equals(0.0));
      expect(snap8.simulatedRadar.tannin, equals(0.0));

      // White robe turns golden
      expect(snap8.robeDescription, contains('Or'));
    });
  });
}
