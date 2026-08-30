import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/scratchcard/presentation/scratch_map_canvas.dart';
import 'package:chatmelier/features/scratchcard/presentation/svg_path_parser.dart';
import 'package:chatmelier/features/scratchcard/presentation/france_geo_data.dart';
import 'package:chatmelier/features/scratchcard/presentation/world_geo_data.dart';

void main() {
  group('ScratchMap Logic & RegionData Tests', () {
    test('Region is unlocked when owned or drunk', () {
      const unexplored = MapRegionData(
        id: 'alsace',
        name: 'Alsace',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.56, 0.28, 0.40, 0.12),
        isOwned: false,
        isDrunk: false,
        ownedCount: 0,
        drunkCount: 0,
        description: 'Vins d\'Alsace',
      );
      expect(unexplored.isUnlocked, isFalse);

      const ownedOnly = MapRegionData(
        id: 'bourgogne',
        name: 'Bourgogne',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.50, 0.43, 0.46, 0.14),
        isOwned: true,
        isDrunk: false,
        ownedCount: 2,
        drunkCount: 0,
        description: 'Grands Climats',
      );
      expect(ownedOnly.isUnlocked, isTrue);

      const drunkOnly = MapRegionData(
        id: 'champagne',
        name: 'Champagne',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.40, 0.16, 0.44, 0.13),
        isOwned: false,
        isDrunk: true,
        ownedCount: 0,
        drunkCount: 1,
        description: 'Effervescents nobles',
      );
      expect(drunkOnly.isUnlocked, isTrue);

      const both = MapRegionData(
        id: 'bordeaux',
        name: 'Bordeaux',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.04, 0.58, 0.44, 0.15),
        isOwned: true,
        isDrunk: true,
        ownedCount: 2,
        drunkCount: 3,
        description: 'Rive gauche & droite',
      );
      expect(both.isUnlocked, isTrue);
    });

    test('Normalized Bounds containment check', () {
      const region = MapRegionData(
        id: 'bordeaux',
        name: 'Bordeaux',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.18, 0.52, 0.20, 0.18),
        isOwned: true,
        isDrunk: false,
        ownedCount: 2,
        drunkCount: 0,
        description: '',
      );

      // Inside point (normalized x: 0.25, y: 0.60)
      expect(region.normalizedBounds.contains(const Offset(0.25, 0.60)), isTrue);

      // Outside point (normalized x: 0.80, y: 0.10)
      expect(region.normalizedBounds.contains(const Offset(0.80, 0.10)), isFalse);
    });

    test('SvgPathParser should parse SVG path commands and scale correctly', () {
      const svg = 'M 10 10 L 90 10 L 90 90 L 10 90 Z';
      final path = SvgPathParser.parse(
        svg,
        viewBox: const Rect.fromLTWH(0, 0, 100, 100),
        targetRect: const Rect.fromLTWH(0, 0, 500, 500),
      );
      final bounds = path.getBounds();
      expect(bounds.left, closeTo(50, 1));
      expect(bounds.top, closeTo(50, 1));
      expect(bounds.width, closeTo(400, 1));
      expect(bounds.height, closeTo(400, 1));
    });

    test('FranceGeoData paths are valid SVG and parse without errors', () {
      final mainland = SvgPathParser.parse(FranceGeoData.franceMainlandSvg);
      final corse = SvgPathParser.parse(FranceGeoData.corseSvg);
      final rivers = SvgPathParser.parse(FranceGeoData.riversSvg);
      final bdx = SvgPathParser.parse(FranceGeoData.bordeauxSvg);

      expect(mainland.getBounds().isEmpty, isFalse);
      expect(corse.getBounds().isEmpty, isFalse);
      expect(rivers.getBounds().isEmpty, isFalse);
      expect(bdx.getBounds().isEmpty, isFalse);
    });

    test('WorldGeoData paths are valid SVG and parse all world continents', () {
      final continents = SvgPathParser.parse(
        WorldGeoData.worldAllSvg,
        viewBox: const Rect.fromLTWH(0, 0, 2000, 1000),
      );
      expect(continents.getBounds().isEmpty, isFalse);
      expect(WorldGeoData.worldAllSvg.isNotEmpty, isTrue);
      expect(WorldGeoData.viewBox.width, equals(2000));
      expect(WorldGeoData.viewBox.height, equals(1000));
    });
  });
}
