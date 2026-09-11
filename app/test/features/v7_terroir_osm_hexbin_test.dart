import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/terroir_geo_data.dart';
import 'package:chatmelier/features/cellar/presentation/terroir_map_view.dart';

void main() {
  group('v7 Terroir Geo Resolver & Hexbin Geometry Tests', () {
    test('Resolves Bordeaux Pauillac correctly with valid GPS and hexbins', () {
      final profile = TerroirGeoResolver.resolve(
        country: 'France',
        region: 'Bordeaux',
        subRegion: 'Médoc',
        appellation: 'Pauillac',
      );

      expect(profile.id, equals('pauillac'));
      expect(profile.center.latitude, closeTo(45.19, 0.1));
      expect(profile.center.longitude, closeTo(-0.74, 0.1));
      expect(profile.soilType, contains('graves'));

      final hexes = profile.generateHexagons();
      expect(hexes.length, greaterThanOrEqualTo(7)); // center + 6 surrounding
      expect(hexes.first.isCenterCru, isTrue);
      expect(hexes.first.points.length, equals(6));
    });

    test('Resolves Bourgogne Vosne-Romanée and Chablis', () {
      final vosne = TerroirGeoResolver.resolve(
        country: 'France',
        region: 'Bourgogne',
        appellation: 'Vosne-Romanée',
      );
      expect(vosne.id, equals('vosne_romanee'));
      expect(vosne.keyGrapes, contains('Pinot Noir'));

      final chablis = TerroirGeoResolver.resolve(
        country: 'France',
        region: 'Bourgogne',
        appellation: 'Chablis Grand Cru',
      );
      expect(chablis.id, equals('chablis'));
      expect(chablis.soilType, contains('kimméridg'));
    });

    test('Resolves International Terroirs: Rioja, Barolo, Napa Valley, Mendoza', () {
      final rioja = TerroirGeoResolver.resolve(
        country: 'Espagne',
        region: 'Rioja',
        appellation: 'DOCa Rioja Alta',
      );
      expect(rioja.id, equals('spain_rioja'));
      expect(rioja.flag, equals('🇪🇸'));

      final barolo = TerroirGeoResolver.resolve(
        country: 'Italie',
        region: 'Piémont',
        appellation: 'Barolo DOCG',
      );
      expect(barolo.id, equals('italy_barolo'));
      expect(barolo.keyGrapes, contains('Nebbiolo'));

      final napa = TerroirGeoResolver.resolve(
        country: 'United States',
        region: 'California',
        appellation: 'Oakville Napa Valley',
      );
      expect(napa.id, equals('usa_napa_valley'));

      final mendoza = TerroirGeoResolver.resolve(
        country: 'Argentine',
        region: 'Mendoza',
        appellation: 'Valle de Uco',
      );
      expect(mendoza.id, equals('argentina_mendoza'));
      expect(mendoza.elevation, contains('900'));
    });

    test('Hexagon coordinates maintain geometric integrity', () {
      final profile = TerroirGeoResolver.resolve(
        country: 'France',
        region: 'Champagne',
      );
      final hexes = profile.generateHexagons();
      for (final hex in hexes) {
        expect(hex.points.length, equals(6));
        // All points should have valid latitude and longitude
        for (final pt in hex.points) {
          expect(pt.latitude, inInclusiveRange(-90.0, 90.0));
          expect(pt.longitude, inInclusiveRange(-180.0, 180.0));
        }
      }
    });
  });

  group('v7 Terroir Map View Widget Tests', () {
    testWidgets('TerroirMapView renders map canvas and details below', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TerroirMapView(
                country: 'France',
                region: 'Bordeaux',
                appellation: 'Pauillac',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Terroir information below the map must be present
      expect(find.textContaining('Pauillac'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Sol :'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Climat :'),
        ),
        findsOneWidget,
      );

      // Map control buttons must be rendered
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });
  });
}
