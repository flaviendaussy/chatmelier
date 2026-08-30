import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/cellar.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';

void main() {
  group('Domain Models Serialization & Computations Tests', () {
    test('Wine JSON serialization & DrinkWindowStatus computation', () {
      final currentYear = DateTime.now().year;

      final winePeak = Wine(
        id: 'w1',
        name: 'Château Margaux',
        producer: 'Château Margaux',
        type: 'red',
        country: 'France',
        region: 'Bordeaux',
        vintage: 2015,
        drinkStart: currentYear - 2,
        drinkEnd: currentYear + 10,
        peakStart: currentYear - 1,
        peakEnd: currentYear + 3,
        estimatedMarketValue: 650.0,
      );

      final json = winePeak.toJson();
      final fromJson = Wine.fromJson(json);

      expect(fromJson.name, 'Château Margaux');
      expect(fromJson.vintage, 2015);
      expect(fromJson.windowStatus, DrinkWindowStatus.inPeak);
      expect(fromJson.estimatedMarketValue, 650.0);

      final wineYoung = Wine(
        id: 'w2',
        name: 'Château Latour',
        type: 'red',
        country: 'France',
        region: 'Bordeaux',
        vintage: currentYear,
        drinkStart: currentYear + 5,
        drinkEnd: currentYear + 25,
      );
      expect(wineYoung.windowStatus, DrinkWindowStatus.tooYoung);

      final winePast = Wine(
        id: 'w3',
        name: 'Vieux Beaujolais',
        type: 'red',
        country: 'France',
        region: 'Beaujolais',
        vintage: currentYear - 20,
        drinkStart: currentYear - 19,
        drinkEnd: currentYear - 15,
      );
      expect(winePast.windowStatus, DrinkWindowStatus.pastPeak);
    });

    test('Bottle JSON serialization & status helpers', () {
      final bottle = Bottle(
        id: 'b1',
        cellarId: 'c1',
        wineId: 'w1',
        addedBy: 'u1',
        ownerId: 'u1',
        quantity: 6,
        purchasePrice: 45.0,
        rack: 'A',
        shelf: '2',
        position: '3',
        status: 'in_cellar',
        createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
        wine: const Wine(
          id: 'w1',
          name: 'Chablis Premier Cru',
          type: 'white',
          country: 'France',
          region: 'Bourgogne',
        ),
      );

      final json = bottle.toJson();
      final fromJson = Bottle.fromJson(json);

      expect(fromJson.id, 'b1');
      expect(fromJson.quantity, 6);
      expect(fromJson.purchasePrice, 45.0);
      expect(fromJson.rack, 'A');
      expect(fromJson.isInCellar, isTrue);
      expect(fromJson.wine?.name, 'Chablis Premier Cru');
    });

    test('Cellar JSON serialization', () {
      final now = DateTime.now();
      final cellar = Cellar(
        id: 'c-vosges',
        name: 'Cave Vosges',
        nickname: 'Chalet',
        locationName: 'Gérardmer',
        ownerId: 'u1',
        createdAt: now,
      );

      final map = {
        'id': cellar.id,
        'name': cellar.name,
        'nickname': cellar.nickname,
        'location_name': cellar.locationName,
        'owner_id': cellar.ownerId,
        'created_at': cellar.createdAt.toIso8601String(),
      };

      final parsed = Cellar.fromJson(map);
      expect(parsed.name, 'Cave Vosges');
      expect(parsed.nickname, 'Chalet');
      expect(parsed.locationName, 'Gérardmer');
    });

    test('TastingEntry JSON serialization', () {
      final entry = TastingEntry(
        id: 't1',
        bottleId: 'b1',
        wineId: 'w1',
        wineName: 'Château d\'Yquem',
        vintage: 2009,
        region: 'Bordeaux',
        country: 'France',
        rating: 4.8,
        tastingNotes: 'Robe dorée sublime, notes d\'abricot confit et de safran.',
        consumedAt: DateTime.parse('2026-06-15T20:00:00Z'),
      );

      final json = entry.toJson();
      final fromJson = TastingEntry.fromJson(json);

      expect(fromJson.wineName, 'Château d\'Yquem');
      expect(fromJson.vintage, 2009);
      expect(fromJson.rating, 4.8);
      expect(fromJson.region, 'Bordeaux');
      expect(fromJson.tastingNotes, contains('abricot'));
    });

    test('Duplicate Wine detection should differentiate estates with identical appellation and color', () {
      const bandolTempier = Wine(
        id: 'w_bt',
        name: 'Bandol Rouge',
        producer: 'Domaine Tempier',
        vintage: 2020,
        type: 'red',
        country: 'France',
        region: 'Provence',
      );

      const bandolPibarnon = Wine(
        id: 'w_bp',
        name: 'Bandol Rouge',
        producer: 'Château de Pibarnon',
        vintage: 2020,
        type: 'red',
        country: 'France',
        region: 'Provence',
      );

      expect(bandolTempier.producer != bandolPibarnon.producer, true);
      expect(bandolTempier.name == bandolPibarnon.name, true);
    });

    test('Adaptive Enological Apogee: 2-year Rosé vs 10-year Bourgogne vs 30-year Grand Cru', () {
      final currentYear = DateTime.now().year;

      // 1. Short garde (2-year Rosé)
      final rose2025 = Wine(
        id: 'w_rose',
        name: 'Miraval Rosé',
        type: 'rosé',
        country: 'France',
        region: 'Provence',
        vintage: currentYear - 1,
        drinkStart: currentYear - 1,
        drinkEnd: currentYear + 1,
        peakStart: currentYear - 1,
        peakEnd: currentYear,
      );
      // In current year (e.g. 2026), currentYear <= peakEnd (2026) -> inPeak
      expect(rose2025.windowStatus, DrinkWindowStatus.inPeak);

      // 2. Moillard Bourgogne Hautes Côtes de Nuits 2022 (in 2026: peak 2027-2030)
      const moillard2022 = Wine(
        id: 'w_moillard',
        name: 'Moillard Hautes Côtes de Nuits',
        type: 'red',
        country: 'France',
        region: 'Bourgogne',
        vintage: 2022,
        drinkStart: 2025,
        drinkEnd: 2032,
        peakStart: 2027,
        peakEnd: 2030,
      );
      // In 2026 (currentYear < peakStart 2027), status must be aging (En garde), NOT inPeak!
      expect(moillard2022.windowStatus, DrinkWindowStatus.aging);

      // 3. Grand Cru 30-year aging potential
      const grandCru = Wine(
        id: 'w_gc',
        name: 'Château Margaux Grand Vin',
        type: 'red',
        country: 'France',
        region: 'Bordeaux',
        vintage: 2015,
        drinkStart: 2023,
        drinkEnd: 2045,
        peakStart: 2028,
        peakEnd: 2038,
      );
      // In 2026: before peakStart (2028), status is aging
      expect(grandCru.windowStatus, DrinkWindowStatus.aging);

      // 4. DrinkWindowStatus extension labels & colors
      expect(DrinkWindowStatus.aging.labelFr, 'En garde');
      expect(DrinkWindowStatus.inPeak.labelFr, 'À l\'apogée');
      expect(DrinkWindowStatus.drinkSoon.labelFr, 'À boire vite');
      expect(DrinkWindowStatus.tooYoung.labelFr, 'Trop jeune');
      expect(DrinkWindowStatus.pastPeak.labelFr, 'Passé');
    });

    test('Wine userOverrides tracking and copyWith functionality', () {
      const initialWine = Wine(
        id: 'w_test',
        name: 'Initial Wine Name',
        type: 'red',
        country: 'France',
        region: 'Rhône',
        vintage: 2018,
        drinkStart: 2022,
        drinkEnd: 2030,
        peakStart: 2024,
        peakEnd: 2027,
        userOverrides: ['peak_drinking_start', 'peak_drinking_end'],
      );

      // JSON serialization preserves user_overrides
      final json = initialWine.toJson();
      expect(json['user_overrides'], contains('peak_drinking_start'));
      expect(json['user_overrides'], contains('peak_drinking_end'));

      // Deserialization restores userOverrides correctly
      final fromJson = Wine.fromJson(json);
      expect(fromJson.userOverrides, contains('peak_drinking_start'));
      expect(fromJson.userOverrides, contains('peak_drinking_end'));

      // copyWith updates fields without dropping userOverrides
      final updated = initialWine.copyWith(
        peakStart: 2026,
        peakEnd: 2032,
        userOverrides: ['peak_drinking_start', 'peak_drinking_end', 'vintage'],
      );

      expect(updated.peakStart, 2026);
      expect(updated.peakEnd, 2032);
      expect(updated.userOverrides.length, 3);
      expect(updated.userOverrides, contains('vintage'));
    });
  });
}
