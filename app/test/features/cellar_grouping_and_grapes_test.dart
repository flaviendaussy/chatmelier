import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/cellar_group_by.dart';
import 'package:chatmelier/shared/widgets/grape_chart.dart';

void main() {
  group('GrapeBlendResolver Tests', () {
    test('Resolves Domaine de Terrebrune Rouge 2019 Cépages correctly', () {
      final grapes = GrapeBlendResolver.resolveGrapes(
        existingGrapes: [],
        wineType: 'rouge',
        appellation: 'Bandol',
        region: 'Provence',
        wineName: 'Domaine de Terrebrune Rouge',
        producer: 'Domaine de Terrebrune',
      );

      expect(grapes.length, equals(3));
      expect(grapes.any((g) => g.name.contains('Mourvèdre') && g.pct == 85.0), isTrue);
      expect(grapes.any((g) => g.name.contains('Grenache') && g.pct == 10.0), isTrue);
      expect(grapes.any((g) => g.name.contains('Cinsault') && g.pct == 5.0), isTrue);
    });

    test('Resolves Domaine de Terrebrune Rosé Cépages correctly', () {
      final grapes = GrapeBlendResolver.resolveGrapes(
        existingGrapes: [],
        wineType: 'rosé',
        appellation: 'Bandol',
        region: 'Provence',
        wineName: 'Domaine de Terrebrune Rosé',
        producer: 'Domaine de Terrebrune',
      );

      expect(grapes.length, equals(3));
      expect(grapes.any((g) => g.name.contains('Mourvèdre') && g.pct == 50.0), isTrue);
      expect(grapes.any((g) => g.name.contains('Grenache') && g.pct == 25.0), isTrue);
      expect(grapes.any((g) => g.name.contains('Cinsault') && g.pct == 25.0), isTrue);
    });

    test('Resolves Domaine de Terrebrune Blanc Cépages correctly', () {
      final grapes = GrapeBlendResolver.resolveGrapes(
        existingGrapes: [],
        wineType: 'blanc',
        appellation: 'Bandol',
        region: 'Provence',
        wineName: 'Domaine de Terrebrune Blanc',
        producer: 'Domaine de Terrebrune',
      );

      expect(grapes.length, equals(4));
      expect(grapes.any((g) => g.name.contains('Clairette') && g.pct == 50.0), isTrue);
      expect(grapes.any((g) => g.name.contains('Ugni Blanc') && g.pct == 20.0), isTrue);
      expect(grapes.any((g) => g.name.contains('Bourboulenc') && g.pct == 20.0), isTrue);
      expect(grapes.any((g) => g.name.contains('Marsanne') && g.pct == 10.0), isTrue);
    });

    test('Resolves Domaine Tempier single parcel cuvées correctly', () {
      final tourtine = GrapeBlendResolver.resolveGrapes(
        existingGrapes: [],
        wineType: 'rouge',
        appellation: 'Bandol',
        region: 'Provence',
        wineName: 'La Tourtine',
        producer: 'Domaine Tempier',
        cuveeParcel: 'La Tourtine',
      );
      expect(tourtine.any((g) => g.name.contains('Mourvèdre') && g.pct == 80.0), isTrue);
      expect(tourtine.any((g) => g.name.contains('Grenache') && g.pct == 10.0), isTrue);

      final migoua = GrapeBlendResolver.resolveGrapes(
        existingGrapes: [],
        wineType: 'rouge',
        appellation: 'Bandol',
        region: 'Provence',
        wineName: 'La Migoua',
        producer: 'Domaine Tempier',
        cuveeParcel: 'La Migoua',
      );
      expect(migoua.any((g) => g.name.contains('Mourvèdre') && g.pct == 55.0), isTrue);
      expect(migoua.any((g) => g.name.contains('Grenache') && g.pct == 25.0), isTrue);
      expect(migoua.any((g) => g.name.contains('Syrah') && g.pct == 5.0), isTrue);
    });

    test('Resolves general Bandol AOC Rouge with minimum 50% Mourvèdre', () {
      final bandol = GrapeBlendResolver.resolveGrapes(
        existingGrapes: [],
        wineType: 'rouge',
        appellation: 'Bandol',
        region: 'Provence',
        wineName: 'Château Inconnu Rouge',
      );
      expect(bandol.any((g) => g.name.contains('Mourvèdre') && (g.pct ?? 0) >= 50.0), isTrue);
    });

    test('Grape.fromJson parses string percentages and decimal values', () {
      final g1 = Grape.fromJson({'name': 'Mourvèdre', 'percentage': '85%'});
      expect(g1.pct, equals(85.0));

      final g2 = Grape.fromJson({'name': 'Grenache', 'percentage': '10.5'});
      expect(g2.pct, equals(10.5));

      final g3 = Grape.fromJson({'name': 'Cinsault', 'percentage': 5});
      expect(g3.pct, equals(5.0));
    });
  });

  group('CellarGroupEngine Partitioning Tests', () {
    const wineTerrebrune = Wine(
      id: 'w1',
      name: 'Terrebrune Rouge',
      producer: 'Domaine de Terrebrune',
      type: 'Rouge',
      country: 'France',
      region: 'Provence',
      appellation: 'Bandol',
      vintage: 2019,
      estimatedMarketValue: 45.0,
      grapes: [],
      foodPairings: [],
      criticScores: [],
    );

    const wineTempier = Wine(
      id: 'w2',
      name: 'La Tourtine',
      producer: 'Domaine Tempier',
      type: 'Rouge',
      country: 'France',
      region: 'Provence',
      appellation: 'Bandol',
      vintage: 2020,
      estimatedMarketValue: 75.0,
      grapes: [],
      foodPairings: [],
      criticScores: [],
    );

    const wineChablis = Wine(
      id: 'w3',
      name: 'Chablis Premier Cru',
      producer: 'Domaine Laroche',
      type: 'Blanc',
      country: 'France',
      region: 'Bourgogne',
      appellation: 'Chablis',
      vintage: 2021,
      estimatedMarketValue: 35.0,
      grapes: [],
      foodPairings: [],
      criticScores: [],
    );

    const wineNapa = Wine(
      id: 'w4',
      name: 'Opus One',
      producer: 'Opus One Winery',
      type: 'Rouge',
      country: 'États-Unis',
      region: 'Napa Valley',
      appellation: 'Oakville',
      vintage: 2018,
      estimatedMarketValue: 380.0,
      grapes: [],
      foodPairings: [],
      criticScores: [],
    );

    final now = DateTime(2025, 1, 1);
    final List<Bottle> bottles = [
      Bottle(id: 'b1', cellarId: 'c1', wineId: 'w1', addedBy: 'u1', ownerId: 'u1', createdAt: now, wine: wineTerrebrune, quantity: 3, purchasePrice: 38.0),
      Bottle(id: 'b2', cellarId: 'c1', wineId: 'w2', addedBy: 'u1', ownerId: 'u1', createdAt: now, wine: wineTempier, quantity: 2, purchasePrice: 65.0),
      Bottle(id: 'b3', cellarId: 'c1', wineId: 'w3', addedBy: 'u1', ownerId: 'u1', createdAt: now, wine: wineChablis, quantity: 4, purchasePrice: 30.0),
      Bottle(id: 'b4', cellarId: 'c1', wineId: 'w4', addedBy: 'u1', ownerId: 'u1', createdAt: now, wine: wineNapa, quantity: 1, purchasePrice: 350.0),
    ];

    test('GroupBy none returns single section with all bottles', () {
      final sections = CellarGroupEngine.partitionBottles(bottles, CellarGroupBy.none);
      expect(sections.length, equals(1));
      expect(sections.first.bottles.length, equals(4));
      expect(sections.first.totalBottleCount, equals(10));
    });

    test('GroupBy color partitions into Rouge and Blanc', () {
      final sections = CellarGroupEngine.partitionBottles(bottles, CellarGroupBy.color);
      expect(sections.length, equals(2));

      final redGroup = sections.firstWhere((s) => s.key == 'red');
      expect(redGroup.bottles.length, equals(3));
      expect(redGroup.totalBottleCount, equals(6)); // 3 + 2 + 1
      expect(redGroup.totalEstimatedValue, equals(3 * 45.0 + 2 * 75.0 + 1 * 380.0));

      final whiteGroup = sections.firstWhere((s) => s.key == 'white');
      expect(whiteGroup.bottles.length, equals(1));
      expect(whiteGroup.totalBottleCount, equals(4));
    });

    test('GroupBy appellation groups Bandol, Chablis, Oakville', () {
      final sections = CellarGroupEngine.partitionBottles(bottles, CellarGroupBy.appellation);
      expect(sections.length, equals(3));

      final bandolGroup = sections.firstWhere((s) => s.key == 'Bandol');
      expect(bandolGroup.bottles.length, equals(2));
      expect(bandolGroup.totalBottleCount, equals(5)); // 3 + 2
    });

    test('GroupBy continent groups Europe and Amériques', () {
      final sections = CellarGroupEngine.partitionBottles(bottles, CellarGroupBy.continent);
      expect(sections.length, equals(2));

      final europeGroup = sections.firstWhere((s) => s.key == 'Europe');
      expect(europeGroup.bottles.length, equals(3)); // Terrebrune, Tempier, Chablis
      expect(europeGroup.totalBottleCount, equals(9));

      final ameriquesGroup = sections.firstWhere((s) => s.key == 'Amériques');
      expect(ameriquesGroup.bottles.length, equals(1)); // Napa
      expect(ameriquesGroup.totalBottleCount, equals(1));
    });

    test('GroupBy vintage sorts descending: 2021, 2020, 2019, 2018', () {
      final sections = CellarGroupEngine.partitionBottles(bottles, CellarGroupBy.vintage);
      expect(sections.length, equals(4));
      expect(sections[0].key, equals('2021'));
      expect(sections[1].key, equals('2020'));
      expect(sections[2].key, equals('2019'));
      expect(sections[3].key, equals('2018'));
    });
  });
}
