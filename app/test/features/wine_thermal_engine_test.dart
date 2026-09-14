import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/sommelier/domain/wine_thermal_engine.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

void main() {
  group('🌡️ Wine Thermal Engine & Newton Heating/Cooling Tests', () {
    final chablis = const Wine(
      id: 'w_chablis',
      name: 'Chablis Grand Cru Les Clos',
      type: 'Blanc sec',
      region: 'Bourgogne',
      country: 'France',
      grapes: [Grape(name: 'Chardonnay', pct: 100)],
      vintage: 2021,
    );

    final cornas = const Wine(
      id: 'w_cornas',
      name: 'Cornas Granit 30',
      type: 'Rouge',
      region: 'Vallée du Rhône',
      country: 'France',
      grapes: [Grape(name: 'Syrah', pct: 100)],
      vintage: 2022,
    );

    final champagne = const Wine(
      id: 'w_champ',
      name: 'Champagne Blanc de Blancs',
      type: 'Champagne',
      region: 'Champagne',
      country: 'France',
      grapes: [Grape(name: 'Chardonnay', pct: 100)],
      vintage: 2018,
    );

    test('Computes specialized sommelier target temperatures', () {
      expect(WineThermalEngine.getIdealServiceTemp(champagne), equals(8.5));
      expect(WineThermalEngine.getIdealServiceTemp(chablis), equals(9.5));
      expect(WineThermalEngine.getIdealServiceTemp(cornas), equals(16.5));
    });

    test('Computes aeration / decanting requirements accurately', () {
      // Champagne should not be decanted (preserve effervescence)
      expect(WineThermalEngine.getIdealDecantingMinutes(champagne), equals(0));

      // Young powerful Syrah requires ample decanting
      expect(WineThermalEngine.getIdealDecantingMinutes(cornas), greaterThanOrEqualTo(60));
    });

    test('Newton law: Warming from cellar (12°C) to ideal red (16.5°C) in a 20°C room', () {
      final plan = WineThermalEngine.calculatePlan(
        wine: cornas,
        initialTemp: 12.0,
        roomTemp: 20.0,
        fridgeTemp: 4.0,
      );

      expect(plan.action, equals(ThermalAction.leaveInRoom));
      expect(plan.targetTemp, equals(16.5));
      // Expected duration around 25-45 minutes
      expect(plan.durationMinutes, inInclusiveRange(20, 50));
      expect(plan.decantingMinutes, greaterThan(0));
      expect(plan.temperatureCurve.isNotEmpty, isTrue);
    });

    test('Newton law: Cooling white from room (21°C) to 9.5°C in a 4°C fridge', () {
      final plan = WineThermalEngine.calculatePlan(
        wine: chablis,
        initialTemp: 21.0,
        roomTemp: 21.0,
        fridgeTemp: 4.0,
      );

      expect(plan.action, equals(ThermalAction.putInFridge));
      expect(plan.targetTemp, equals(9.5));
      // Cooling takes around 40-70 minutes in 4°C fridge
      expect(plan.durationMinutes, inInclusiveRange(40, 75));
    });

    test('Ice bucket accelerates chilling drastically compared to fridge', () {
      final planFridge = WineThermalEngine.calculatePlan(
        wine: chablis,
        initialTemp: 20.0,
        roomTemp: 20.0,
        fridgeTemp: 4.0,
        useIceBucket: false,
      );

      final planIce = WineThermalEngine.calculatePlan(
        wine: chablis,
        initialTemp: 20.0,
        roomTemp: 20.0,
        fridgeTemp: 4.0,
        useIceBucket: true,
      );

      expect(planIce.action, equals(ThermalAction.iceBucket));
      expect(planIce.durationMinutes, lessThan(planFridge.durationMinutes / 2));
    });

    test('Already ideal temperature returns immediate ready action', () {
      final plan = WineThermalEngine.calculatePlan(
        wine: cornas,
        initialTemp: 16.5,
        roomTemp: 20.0,
        fridgeTemp: 4.0,
      );

      expect(plan.action, equals(ThermalAction.alreadyIdeal));
      expect(plan.durationMinutes, equals(0));
    });

    test('Warm room (24°C) for red wine triggers alert and proposes fridge cooling', () {
      final planWarmRed = WineThermalEngine.calculatePlan(
        wine: cornas,
        initialTemp: 24.0,
        roomTemp: 24.0,
        fridgeTemp: 4.0,
      );

      expect(planWarmRed.action, equals(ThermalAction.putInFridge));
      expect(planWarmRed.actionTitle, contains('Coup de frais'));
      expect(planWarmRed.warmRoomWarning, isNotNull);
      expect(planWarmRed.warmRoomWarning, contains('24°C'));
    });
  });
}
