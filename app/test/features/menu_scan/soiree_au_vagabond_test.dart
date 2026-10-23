import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/friends/data/friends_repository.dart';
import 'package:chatmelier/features/menu_scan/data/verres_de_la_soiree_store.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/domain/verres_de_la_soiree.dart';
import 'package:chatmelier/features/menu_scan/presentation/mes_verres_sheet.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La soirée du 22/10 au Vagabond, rejouée depuis la carte.
///
/// Ce soir-là : la carte scannée (17 vins, deux pages) savait tout des verres commandés, et
/// il a fallu, pour chacun des onze, photographier l'étiquette (15 s d'IA), remplir le
/// formulaire « Noter un vin bu dehors » (lieu deviné : « Dawson House »), puis le
/// questionnaire. Avec « Mes verres » : un geste par vin sur la carte, une fois « avec
/// qui », puis un toucher par verre — et le lieu, les cépages viennent de la carte.
MenuWine _vin(String id, String nom, String producteur, int? millesime, String type,
        {String? region, String? pays, List<String> cepages = const []}) =>
    MenuWine(id: id, name: nom, producer: producteur, vintage: millesime, wineType: type, region: region, country: pays, grapes: cepages);

final _carte = ScannedMenu(
  id: 'vagabond-2026-10-22',
  restaurantName: 'Vagabond',
  scannedAt: DateTime(2026, 10, 22, 19, 53),
  pagePhotoPaths: const [],
  currency: 'GBP',
  ardoise: true,
  wines: [
    _vin('erdener', 'Erdener Treppchen Kabinett', 'Markus Molitor', 2023, 'white', region: 'Mosel', pays: 'Germany', cepages: ['Riesling']),
    _vin('bernate', 'El Bernate Rioja Blanco', 'Exopto', 2024, 'white', region: 'Rioja', pays: 'Spain'),
    _vin('muscat', 'Ungrafted - Muscat', 'De Martino', 2024, 'white', region: 'Itata', pays: 'Chile', cepages: ['Muscat']),
    _vin('douro', 'Douro Rosé', 'Quinta do Crasto', 2025, 'rose', region: 'Douro', pays: 'Portugal'),
    _vin('rosy', 'Rosy', 'Pio Cesare', 2025, 'rose', region: 'Piedmont', pays: 'Italy'),
    _vin('rosado', 'Rosado', 'Contino', 2022, 'rose', region: 'Rioja', pays: 'Spain'),
    _vin('bio', 'Bio Tinto', 'Terrenus', 2024, 'red', region: 'Alentejo', pays: 'Portugal'),
    _vin('cinsault', 'Ungrafted Cinsault', 'De Martino', 2025, 'red', region: 'Itata', pays: 'Chile', cepages: ['Cinsault']),
    _vin('bruja', 'La Bruja de Rozas', 'Comando G', 2024, 'red', region: 'Vinos de Madrid', pays: 'Spain', cepages: ['Garnacha']),
    _vin('vinhas', 'Vinhas Velhas Reserva Tinto', 'Terrenus', 2019, 'red', region: 'Alentejo', pays: 'Portugal'),
    _vin('tannat', 'Finca Notables Tannat', 'El Esteco', 2020, 'red', region: 'Salta', pays: 'Argentina', cepages: ['Tannat']),
    // Les six autres vins de la carte, que personne n'a commandés.
    for (var i = 1; i <= 6; i++) _vin('autre-$i', 'Autre vin $i', 'Domaine $i', 2022, i.isEven ? 'red' : 'white'),
  ],
);

/// Ce que Flavien a commandé, dans l'ordre, avec sa note (le Bio Tinto : oxydé).
const _verresDeFlavien = [
  ('erdener', 8.0),
  ('bernate', 8.5),
  ('muscat', 3.5),
  ('douro', 3.0),
  ('rosy', 1.5),
  ('rosado', 9.5),
  ('bio', null),
  ('cinsault', 7.5),
  ('bruja', 9.0),
  ('vinhas', 9.0),
  ('tannat', 7.5),
];

MenuWine _surLaCarte(String id) => _carte.wines.firstWhere((w) => w.id == id);

void main() {
  group('la soirée, verre par verre', () {
    test('onze gestes sur la carte, un « avec qui », onze dégustations — sans une photo', () {
      var soiree = SoireeDeVerres(menuId: _carte.id, lieu: _carte.restaurantName);
      for (final (id, _) in _verresDeFlavien) {
        soiree = soiree.basculer(_surLaCarte(id));
      }
      soiree = soiree.avecConvives(['Caro']);
      expect(soiree.verres, hasLength(11));
      expect(soiree.verres.map((v) => v.id), [for (final (id, _) in _verresDeFlavien) id], reason: 'dans l\'ordre de la soirée');

      // Chaque verre sait son vin par la carte : le nom, le domaine, le millésime, les
      // cépages ; le lieu est celui de la carte, pas un bâtiment voisin.
      final muscat = soiree.verres.firstWhere((v) => v.id == 'muscat');
      expect(muscat.producteur, 'De Martino');
      expect(muscat.millesime, 2024);
      expect(muscat.cepages, ['Muscat']);
      expect(soiree.lieu, 'Vagabond');

      // On les déguste : chaque verre est écrit au journal, puis noté.
      for (final (i, (id, note)) in _verresDeFlavien.indexed) {
        final v = soiree.verres.firstWhere((x) => x.id == id);
        soiree = soiree.remplacer(v.copyWith(tastingId: 'degustation-$i'));
        expect(soiree.verres.firstWhere((x) => x.id == id).commence, isTrue);
        soiree = soiree.remplacer(soiree.verres
            .firstWhere((x) => x.id == id)
            .copyWith(note: note, defaut: note == null ? 'oxidation' : null, termine: true));
      }
      expect(soiree.notes, 11);
      expect(soiree.verres.where((v) => v.defaut != null).single.nom, 'Bio Tinto');
    });

    test('un verre commencé ne se retire plus de la liste ; un verre pas commencé, si', () {
      var soiree = SoireeDeVerres(menuId: _carte.id, lieu: 'Vagabond').basculer(_surLaCarte('rosy')).basculer(_surLaCarte('rosado'));
      soiree = soiree.basculer(_surLaCarte('rosy'));
      expect(soiree.verres.map((v) => v.id), ['rosado']);
      soiree = soiree.remplacer(soiree.verres.single.copyWith(tastingId: 't1'));
      soiree = soiree.basculer(_surLaCarte('rosado'));
      expect(soiree.verres.single.tastingId, 't1', reason: 'il est au journal : le retirer d\'ici ne l\'en retirerait pas');
    });

    test('la soirée survit à l\'app tuée : gardée, relue, identique', () async {
      SharedPreferences.setMockInitialValues({});
      final store = VerresDeLaSoireeStore(await SharedPreferences.getInstance());
      final soiree = SoireeDeVerres(menuId: _carte.id, lieu: 'Vagabond', convives: const ['Caro'])
          .basculer(_surLaCarte('bruja'))
          .remplacer(VerreDeLaSoiree.deLaCarte(_surLaCarte('bruja')).copyWith(tastingId: 't9', note: 9.0, termine: true));
      await store.ecrire(soiree);
      final relue = VerresDeLaSoireeStore(await SharedPreferences.getInstance()).lire(_carte.id)!;
      expect(relue.lieu, 'Vagabond');
      expect(relue.convives, ['Caro']);
      expect(relue.verres.single.note, 9.0);
      expect(relue.verres.single.termine, isTrue);
      expect(relue.verres.single.cepages, ['Garnacha']);
    });
  });

  testWidgets('« Mes verres » : où en est la soirée, verre par verre', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final carte = carteDeLaSoiree(_carte);
    final conteneur = ProviderContainer(overrides: [
      friendsListProvider.overrideWith((ref) async => const []),
      tasteProfilesListProvider.overrideWith((ref) async => const []),
    ]);
    addTearDown(conteneur.dispose);
    final notes = conteneur.read(verresDeLaSoireeProvider(carte).notifier);
    for (final id in ['erdener', 'muscat', 'bio']) {
      notes.basculer(_surLaCarte(id));
    }
    final s = conteneur.read(verresDeLaSoireeProvider(carte));
    notes.remplacer(s.verres[0].copyWith(tastingId: 't0', note: 8.0, termine: true));
    notes.remplacer(s.verres[2].copyWith(tastingId: 't2', defaut: 'oxidation', termine: true));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: conteneur,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MesVerresSheet(carte: carte)),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Vagabond · 2 notés sur 3'), findsOneWidget);
    expect(find.text('8/10'), findsOneWidget);
    expect(find.text('Défaut'), findsOneWidget);
    expect(find.text('Déguster'), findsOneWidget, reason: 'le Muscat, seul à déguster');
  });
}
