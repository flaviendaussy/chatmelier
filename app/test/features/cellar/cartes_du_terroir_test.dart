// V2.5 · F7 — l'origine d'un vin en deux cartes fixes : le pays, puis la zone de
// l'appellation (à défaut, environ un département).
//
// Et, vu en chemin, un terroir qui ne sort plus de son pays : chercher « malbec » dans tout
// l'atlas envoyait un Cahors à Mendoza, et « ay » (pour Aÿ) trouvait la Champagne dans
// « Côtes de Blaye » comme dans « Pays d'Oc ».

import 'package:chatmelier/features/cellar/domain/cadrage_du_terroir.dart';
import 'package:chatmelier/features/cellar/domain/terroir_geo_data.dart';
import 'package:chatmelier/features/cellar/presentation/terroir_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TerroirGeoProfile fiche(String id) => TerroirGeoResolver.toutes.firstWhere((p) => p.id == id);

  double largeurKm(LatLngBounds b) =>
      const Distance().as(LengthUnit.Kilometer, LatLng(b.center.latitude, b.west), LatLng(b.center.latitude, b.east));

  group('le cadrage des deux cartes', () {
    test('la première montre la France entière, Corse comprise', () {
      final pays = CadrageDuTerroir.pays(fiche('pauillac'));
      for (final ville in const [
        LatLng(48.86, 2.35), // Paris
        LatLng(43.30, 5.37), // Marseille
        LatLng(48.39, -4.49), // Brest
        LatLng(48.58, 7.75), // Strasbourg
        LatLng(41.92, 8.74), // Ajaccio
      ]) {
        expect(pays.contains(ville), isTrue, reason: '$ville');
      }
    });

    test('la seconde tient l\'appellation entière, et pas beaucoup plus', () {
      final pauillac = fiche('pauillac');
      final zone = CadrageDuTerroir.zone(pauillac, appellationReconnue: true);
      expect(pauillac.generateAppellationBoundary().every(zone.contains), isTrue);
      expect(largeurKm(zone), lessThan(30));
    });

    test('à défaut d\'appellation, environ un département', () {
      final zone = CadrageDuTerroir.zone(fiche('pauillac'), appellationReconnue: false);
      expect(largeurKm(zone), closeTo(90, 5));
    });

    test('le centre et le zoom calculés tiennent le cadre entier dans la carte', () {
      // Calculés plutôt que confiés à `initialCameraFit`, qui laissait la carte vide quand
      // les tuiles étaient déjà en cache.
      for (final (cadre, taille) in [
        (CadrageDuTerroir.pays(fiche('pauillac')), const Size(170, 190)),
        (CadrageDuTerroir.pays(fiche('italy_barolo')), const Size(170, 190)),
        (CadrageDuTerroir.zone(fiche('pauillac'), appellationReconnue: true), const Size(170, 190)),
        (CadrageDuTerroir.zone(fiche('pauillac'), appellationReconnue: false), const Size(360, 170)),
      ]) {
        final (centre, zoom) = cadrer(cadre, taille);
        final vue = MapCamera(crs: const Epsg3857(), center: centre, zoom: zoom, rotation: 0, nonRotatedSize: taille)
            .visibleBounds;
        expect(vue.contains(cadre.northWest) && vue.contains(cadre.southEast), isTrue, reason: '$taille');
      }
      expect(cadrer(CadrageDuTerroir.pays(fiche('pauillac')), const Size(170, 190)).$2, inInclusiveRange(2.5, 5));
    });

    test('un lieu outre-mer est situé dans sa région, pas sur la carte de la métropole', () {
      final rhum = fiche('spirit_rhum_martinique');
      expect(CadrageDuTerroir.dansLePays(rhum), isFalse);
      final cadre = CadrageDuTerroir.pays(rhum);
      expect(cadre.contains(rhum.center), isTrue);
      expect(cadre.contains(const LatLng(48.86, 2.35)), isFalse);
    });
  });

  group('l\'appellation reconnue au sens strict', () {
    test('la fiche de l\'appellation, mentions (DOCa, AVA…) mises à part', () {
      expect(TerroirGeoResolver.parAppellation(fiche('pauillac'), 'Pauillac 1er Grand Cru Classé'), isTrue);
      expect(TerroirGeoResolver.parAppellation(fiche('spain_rioja'), 'Rioja Alta'), isTrue);
      expect(TerroirGeoResolver.parAppellation(fiche('usa_napa_valley'), 'Oakville, Napa Valley'), isTrue);
      expect(TerroirGeoResolver.parAppellation(fiche('portugal_douro'), 'Porto'), isTrue);
    });

    test('un mot-clé voisin ne suffit pas à dessiner un contour', () {
      final rhoneNord = TerroirGeoResolver.trouver(country: 'France', region: 'Vallée du Rhône', appellation: 'Hermitage');
      expect(rhoneNord?.id, 'rhone_cote_rotie_hermitage');
      expect(TerroirGeoResolver.parAppellation(rhoneNord!, 'Hermitage'), isFalse,
          reason: 'le contour de Côte-Rôtie, cinquante kilomètres plus au nord');
      expect(TerroirGeoResolver.parAppellation(fiche('pauillac'), null), isFalse);
    });
  });

  group('un terroir ne sort pas de son pays', () {
    test('un Cahors de Malbec n\'est pas à Mendoza', () {
      final cahors = TerroirGeoResolver.trouver(
          country: 'France', region: 'Sud-Ouest', appellation: 'Cahors', wineName: 'Malbec du Lot');
      expect(cahors?.country, isNot('Argentine'));
      expect(TerroirGeoResolver.trouver(country: 'Argentine', region: 'Mendoza', wineName: 'Malbec')?.id, 'argentina_mendoza');
    });

    test('un Riesling de Moselle n\'est pas alsacien ; un whisky japonais n\'est pas écossais', () {
      expect(TerroirGeoResolver.trouver(country: 'Allemagne', region: 'Mosel', wineName: 'Riesling Kabinett'), isNull);
      expect(TerroirGeoResolver.trouver(country: 'Japon', region: '', isSpirit: true, wineName: 'Yamazaki whisky'), isNull);
    });

    test('l\'Écosse est au Royaume-Uni, la Martinique en France', () {
      expect(TerroirGeoResolver.trouver(country: 'Écosse', region: 'Speyside', isSpirit: true, wineName: 'Macallan 12')?.id,
          'spirit_whisky_speyside');
      expect(TerroirGeoResolver.trouver(country: 'Martinique', region: '', isSpirit: true, wineName: 'Rhum J.M Blanc')?.id,
          'spirit_rhum_martinique');
    });

    test('des mots-clés qui trouvaient un autre terroir', () {
      expect(TerroirGeoResolver.trouver(country: 'France', region: 'Bordeaux', appellation: 'Côtes de Blaye')?.id,
          isNot('champagne_cote_des_blancs'));
      expect(TerroirGeoResolver.trouver(country: 'France', region: 'Languedoc', appellation: 'IGP Pays d\'Oc')?.id,
          isNot('champagne_cote_des_blancs'));
      expect(TerroirGeoResolver.trouver(country: 'France', region: 'Vallée de la Loire', appellation: 'Muscadet Sèvre et Maine'),
          isNull, reason: 'le Pays nantais n\'est pas le Sancerrois');
      expect(TerroirGeoResolver.trouver(country: 'France', region: 'Vallée du Rhône', appellation: 'Côtes du Rhône')?.id,
          'rhone_chateauneuf_du_pape', reason: 'le Rhône méridional, pas Côte-Rôtie');
      expect(TerroirGeoResolver.trouver(country: 'Italie', region: 'Toscane', appellation: 'Chianti Classico')?.id,
          'italy_montalcino', reason: 'la fiche le revendique : « Brunello di Montalcino & Chianti Classico »');
    });
  });

  group('les deux cartes', () {
    Future<void> poser(WidgetTester tester, Widget carte) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: carte))));
      await tester.pump();
    }

    testWidgets('le pays puis l\'appellation, figés, avec son contour', (tester) async {
      await poser(tester, const TerroirMapView(country: 'France', region: 'Bordeaux', appellation: 'Pauillac'));

      final cartes = tester.widgetList<FlutterMap>(find.byType(FlutterMap)).toList();
      expect(cartes, hasLength(2));
      for (final c in cartes) {
        expect(c.options.interactionOptions.flags, InteractiveFlag.none);
      }
      expect(find.text('🇫🇷 France'), findsOneWidget);
      expect(find.text('Pauillac'), findsWidgets);
      expect(find.byType(PolygonLayer), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.textContaining('OpenTopoMap'), findsOneWidget, reason: 'l\'attribution de la licence, en clair');
    });

    testWidgets('reconnu par sa région seulement : environ un département, sans contour', (tester) async {
      await poser(tester, const TerroirMapView(country: 'France', region: 'Vallée du Rhône', appellation: 'Hermitage'));

      expect(find.byType(FlutterMap), findsNWidgets(2));
      expect(find.byType(PolygonLayer), findsNothing);
      expect(find.text('Vallée du Rhône'), findsOneWidget);
    });
  });
}
