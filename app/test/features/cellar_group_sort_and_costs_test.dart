import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/cellar_group_by.dart';
import 'package:chatmelier/features/cellar/domain/cellar_sort_by.dart';

void main() {
  group('CellarGroupEngine - Group By + Sort By Combinations', () {
    const wine2022 = Wine(
      id: 'w1',
      name: 'Beaujolais Lantignié',
      producer: 'Frédéric Berne',
      vintage: 2022,
      type: 'red',
      region: 'Beaujolais',
      appellation: 'Beaujolais-Villages',
      country: 'France',
      estimatedMarketValue: 16.5,
    );

    const wine2015 = Wine(
      id: 'w2',
      name: 'Château Margaux',
      producer: 'Château Margaux',
      vintage: 2015,
      type: 'red',
      region: 'Bordeaux',
      appellation: 'Margaux',
      country: 'France',
      estimatedMarketValue: 650.0,
    );

    const wine2020White = Wine(
      id: 'w3',
      name: 'Alba Dolia',
      producer: 'Mas des Volques',
      vintage: 2020,
      type: 'white',
      region: 'Vallée du Rhône',
      appellation: 'Duché d\'Uzès',
      country: 'France',
      estimatedMarketValue: 18.0,
    );

    final bottle1 = Bottle(
      id: 'b1',
      cellarId: 'c1',
      wineId: 'w1',
      addedBy: 'u1',
      ownerId: 'u1',
      quantity: 1,
      purchasePrice: 15.0,
      createdAt: DateTime(2026, 9, 2, 10, 0),
      wine: wine2022,
    );

    final bottle2 = Bottle(
      id: 'b2',
      cellarId: 'c1',
      wineId: 'w2',
      addedBy: 'u1',
      ownerId: 'u1',
      quantity: 6,
      purchasePrice: 600.0,
      createdAt: DateTime(2026, 8, 1, 10, 0),
      wine: wine2015,
    );

    final bottle3 = Bottle(
      id: 'b3',
      cellarId: 'c1',
      wineId: 'w3',
      addedBy: 'u1',
      ownerId: 'u1',
      quantity: 3,
      purchasePrice: 17.0,
      createdAt: DateTime(2026, 9, 1, 12, 0),
      wine: wine2020White,
    );

    final List<Bottle> allBottles = [bottle1, bottle2, bottle3];

    test('Group by vintage + sort by vintageDesc sorts years descending', () {
      final sections = CellarGroupEngine.partitionBottles(
        allBottles,
        CellarGroupBy.vintage,
        sortBy: CellarSortBy.vintageDesc,
      );

      expect(sections.length, 3);
      expect(sections[0].key, '2022');
      expect(sections[1].key, '2020');
      expect(sections[2].key, '2015');
    });

    test('Group by vintage + sort by vintageAsc sorts years ascending', () {
      final sections = CellarGroupEngine.partitionBottles(
        allBottles,
        CellarGroupBy.vintage,
        sortBy: CellarSortBy.vintageAsc,
      );

      expect(sections.length, 3);
      expect(sections[0].key, '2015');
      expect(sections[1].key, '2020');
      expect(sections[2].key, '2022');
    });

    test('Group by region + sort by quantityDesc puts region with most bottles first', () {
      final sections = CellarGroupEngine.partitionBottles(
        allBottles,
        CellarGroupBy.region,
        sortBy: CellarSortBy.quantityDesc,
      );

      // Bordeaux has 6 bottles, Rhône has 3, Beaujolais has 1
      expect(sections.length, 3);
      expect(sections[0].title, contains('Bordeaux'));
      expect(sections[0].totalBottleCount, 6);
      expect(sections[1].title, contains('Rhône'));
      expect(sections[1].totalBottleCount, 3);
      expect(sections[2].title, contains('Beaujolais'));
      expect(sections[2].totalBottleCount, 1);
    });

    test('Group by region + sort by priceDesc puts highest total value region first', () {
      final sections = CellarGroupEngine.partitionBottles(
        allBottles,
        CellarGroupBy.region,
        sortBy: CellarSortBy.priceDesc,
      );

      // Bordeaux (6 * 650 = 3900€) > Rhône (3 * 18 = 54€) > Beaujolais (1 * 16.50 = 16.50€)
      expect(sections.length, 3);
      expect(sections[0].title, contains('Bordeaux'));
      expect(sections[0].totalEstimatedValue, greaterThan(3000));
    });

    test('Group by region + sort by recentlyAdded puts most recently added bottle region first', () {
      final sections = CellarGroupEngine.partitionBottles(
        allBottles,
        CellarGroupBy.region,
        sortBy: CellarSortBy.recentlyAdded,
      );

      // bottle1 (Beaujolais) added 2026-09-02 > bottle3 (Rhône) added 2026-09-01 > bottle2 (Bordeaux) added 2026-08-01
      expect(sections.length, 3);
      expect(sections[0].title, contains('Beaujolais'));
      expect(sections[0].totalBottleCount, 1);
      expect(sections[1].title, contains('Rhône'));
      expect(sections[2].title, contains('Bordeaux'));
    });

    test('Bottles inside each section are sorted strictly by sortBy criterion', () {
      final bottleBordeaux2018 = Bottle(
        id: 'b4',
        cellarId: 'c1',
        wineId: 'w4',
        addedBy: 'u1',
        ownerId: 'u1',
        quantity: 2,
        createdAt: DateTime(2026, 9, 2, 11, 0),
        wine: const Wine(
          id: 'w4',
          name: 'Château Palmer',
          producer: 'Château Palmer',
          vintage: 2018,
          type: 'red',
          region: 'Bordeaux',
          country: 'France',
        ),
      );

      final sections = CellarGroupEngine.partitionBottles(
        [bottle2, bottleBordeaux2018],
        CellarGroupBy.region,
        sortBy: CellarSortBy.vintageDesc,
      );

      expect(sections.length, 1);
      final bordeauxBottles = sections[0].bottles;
      expect(bordeauxBottles.length, 2);
      expect(bordeauxBottles[0].wine?.vintage, 2018);
      expect(bordeauxBottles[1].wine?.vintage, 2015);
    });
  });
}
