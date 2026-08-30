import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/scratchcard/presentation/svg_path_parser.dart';
import 'package:chatmelier/features/scratchcard/presentation/france_geo_data.dart';
import 'package:chatmelier/features/scratchcard/presentation/italy_geo_data.dart';
import 'package:chatmelier/features/scratchcard/presentation/spain_portugal_geo_data.dart';
import 'package:chatmelier/features/scratchcard/presentation/germany_austria_geo_data.dart';
import 'package:chatmelier/features/scratchcard/presentation/usa_americas_geo_data.dart';
import 'package:chatmelier/features/scratchcard/presentation/oceania_africa_geo_data.dart';
import 'package:chatmelier/features/scratchcard/presentation/scratch_map_canvas.dart';

void main() {
  group('v6 Geographic Maps Overhaul - SvgPathParser', () {
    setUp(() {
      SvgPathParser.clearCache();
    });

    test('Parses SVG commands into non-empty Flutter Path and caches results', () {
      const svgD = 'M 100 100 L 300 100 L 300 300 L 100 300 Z';
      const viewBox = Rect.fromLTWH(0, 0, 1000, 1000);
      const targetRect = Rect.fromLTWH(0, 0, 500, 500);

      final path1 = SvgPathParser.parse(svgD, viewBox: viewBox, targetRect: targetRect);
      expect(path1, isNotNull);
      final bounds = path1.getBounds();
      expect(bounds.width, closeTo(100.0, 1.0));
      expect(bounds.height, closeTo(100.0, 1.0));

      // Test hit-testing
      expect(path1.contains(const Offset(100, 100)), isTrue);
      expect(path1.contains(const Offset(10, 10)), isFalse);

      // Verify cached retrieval
      final path2 = SvgPathParser.parse(svgD, viewBox: viewBox, targetRect: targetRect);
      expect(path2.getBounds(), equals(path1.getBounds()));
    });
  });

  group('v6 Geographic Maps Overhaul - Vector Geodata Integrity', () {
    const stdViewBox = Rect.fromLTWH(0, 0, 1000, 1000);
    const targetRect = Rect.fromLTWH(0, 0, 800, 800);

    test('France GeoData has valid mainland, rivers and 12 regions', () {
      final mainland = SvgPathParser.parse(FranceGeoData.franceMainlandSvg, viewBox: FranceGeoData.viewBox, targetRect: targetRect);
      expect(mainland.getBounds().isEmpty, isFalse);

      final rivers = SvgPathParser.parse(FranceGeoData.riversSvg, viewBox: FranceGeoData.viewBox, targetRect: targetRect);
      expect(rivers.getBounds().isEmpty, isFalse);

      final bordeaux = SvgPathParser.parse(FranceGeoData.bordeauxSvg, viewBox: FranceGeoData.viewBox, targetRect: targetRect);
      expect(bordeaux.getBounds().isEmpty, isFalse);

      final bourgogne = SvgPathParser.parse(FranceGeoData.bourgogneSvg, viewBox: FranceGeoData.viewBox, targetRect: targetRect);
      expect(bourgogne.getBounds().isEmpty, isFalse);
    });

    test('Italy GeoData has valid boot, islands and 7 DOCG regions', () {
      final mainland = SvgPathParser.parse(ItalyGeoData.italyMainlandSvg, viewBox: ItalyGeoData.viewBox, targetRect: targetRect);
      expect(mainland.getBounds().isEmpty, isFalse);

      final piemonte = SvgPathParser.parse(ItalyGeoData.piemonteSvg, viewBox: ItalyGeoData.viewBox, targetRect: targetRect);
      expect(piemonte.getBounds().isEmpty, isFalse);

      final toscana = SvgPathParser.parse(ItalyGeoData.toscanaSvg, viewBox: ItalyGeoData.viewBox, targetRect: targetRect);
      expect(toscana.getBounds().isEmpty, isFalse);

      final etna = SvgPathParser.parse(ItalyGeoData.siciliaEtnaSvg, viewBox: ItalyGeoData.viewBox, targetRect: targetRect);
      expect(etna.getBounds().isEmpty, isFalse);
    });

    test('Spain & Portugal GeoData has valid Iberian outline and regions', () {
      final mainland = SvgPathParser.parse(SpainPortugalGeoData.iberianMainlandSvg, viewBox: SpainPortugalGeoData.viewBox, targetRect: targetRect);
      expect(mainland.getBounds().isEmpty, isFalse);

      final rioja = SvgPathParser.parse(SpainPortugalGeoData.riojaSvg, viewBox: SpainPortugalGeoData.viewBox, targetRect: targetRect);
      expect(rioja.getBounds().isEmpty, isFalse);

      final douro = SvgPathParser.parse(SpainPortugalGeoData.douroPortoSvg, viewBox: SpainPortugalGeoData.viewBox, targetRect: targetRect);
      expect(douro.getBounds().isEmpty, isFalse);
    });

    test('Germany & Austria GeoData has valid Rhine/Mosel/Danube and regions', () {
      final mainland = SvgPathParser.parse(GermanyAustriaGeoData.centralEuropeMainlandSvg, viewBox: GermanyAustriaGeoData.viewBox, targetRect: targetRect);
      expect(mainland.getBounds().isEmpty, isFalse);

      final mosel = SvgPathParser.parse(GermanyAustriaGeoData.moselSvg, viewBox: GermanyAustriaGeoData.viewBox, targetRect: targetRect);
      expect(mosel.getBounds().isEmpty, isFalse);

      final wachau = SvgPathParser.parse(GermanyAustriaGeoData.wachauKremstalSvg, viewBox: GermanyAustriaGeoData.viewBox, targetRect: targetRect);
      expect(wachau.getBounds().isEmpty, isFalse);
    });

    test('USA & Americas GeoData has valid West Coast, Andes, and regions', () {
      final mainland = SvgPathParser.parse(UsaAmericasGeoData.usWestCoastMainlandSvg, viewBox: UsaAmericasGeoData.viewBox, targetRect: targetRect);
      expect(mainland.getBounds().isEmpty, isFalse);

      final napa = SvgPathParser.parse(UsaAmericasGeoData.napaValleySvg, viewBox: UsaAmericasGeoData.viewBox, targetRect: targetRect);
      expect(napa.getBounds().isEmpty, isFalse);

      final mendoza = SvgPathParser.parse(UsaAmericasGeoData.mendozaUcoSvg, viewBox: UsaAmericasGeoData.viewBox, targetRect: targetRect);
      expect(mendoza.getBounds().isEmpty, isFalse);
    });

    test('Oceania & South Africa GeoData has valid outlines and regions', () {
      final australia = SvgPathParser.parse(OceaniaAfricaGeoData.australiaMainlandSvg, viewBox: stdViewBox, targetRect: targetRect);
      expect(australia.getBounds().isEmpty, isFalse);

      final barossa = SvgPathParser.parse(OceaniaAfricaGeoData.barossaValleySvg, viewBox: stdViewBox, targetRect: targetRect);
      expect(barossa.getBounds().isEmpty, isFalse);

      final stellenbosch = SvgPathParser.parse(OceaniaAfricaGeoData.stellenboschSwartlandSvg, viewBox: stdViewBox, targetRect: targetRect);
      expect(stellenbosch.getBounds().isEmpty, isFalse);
    });
  });

  group('v6 Geographic Maps Overhaul - MapRegionData Sommelier Attributes', () {
    test('MapRegionData stores geology, climate, and key grapes', () {
      const region = MapRegionData(
        id: 'champagne',
        name: 'Champagne',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.44, 0.14, 0.22, 0.14),
        isOwned: true,
        isDrunk: false,
        ownedCount: 3,
        drunkCount: 0,
        description: 'Effervescents de classe mondiale.',
        soilType: 'Craie blanche campanienne & marnes',
        climate: 'Océanique frais & septentrional',
        keyGrapes: 'Chardonnay, Pinot Noir, Pinot Meunier',
      );

      expect(region.isUnlocked, isTrue);
      expect(region.soilType, contains('Craie blanche'));
      expect(region.climate, contains('Océanique'));
      expect(region.keyGrapes, contains('Chardonnay'));
    });
  });
}
