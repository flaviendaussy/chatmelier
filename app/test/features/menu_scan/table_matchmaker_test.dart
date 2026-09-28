import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/domain/table_matchmaker.dart';
import 'package:chatmelier/features/menu_scan/presentation/table_matchmaker_sheet.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MenuWine vin(String nom, String type, {double tanins = 0, double acidite = 5}) => MenuWine(
      id: nom,
      name: nom,
      producer: 'Domaine',
      wineType: type,
      bottlePrice: 40,
      metrics: MenuWineRadarMetrics(tannins: tanins, acidity: acidite, body: 6),
    );

const amateurDeRouge = GuestProfile(
  id: 'flavien',
  name: 'Flavien',
  favoriteTypes: ['Rouge'],
  radarDistant: WineTasteRadarMetrics(
      tannin: 7, body: 7, oak: 5, ripeFruit: 6, spice: 5, freshFruit: 5, minerality: 5, acidity: 5),
);

void main() {
  final carte = [
    vin('Barolo', 'red', tanins: 8),
    vin('Rioja', 'red', tanins: 7),
    vin('Cahors', 'red', tanins: 8),
    vin('Madiran', 'red', tanins: 9),
    vin('Chinon', 'red', tanins: 6),
    vin('Sancerre', 'white', acidite: 8),
    vin('Tavel', 'rosé', acidite: 6),
  ];

  test('non éliminatif : une table d\'amateurs de rouge voit aussi le blanc et le rosé', () {
    final candidats = TableMatchmaker.candidats(carte, const [amateurDeRouge], nombre: 5);
    expect(candidats.any((w) => w.isWhite), isTrue);
    expect(candidats.any((w) => w.isRose), isTrue);
    expect(candidats, hasLength(5));
  });

  test('un blanc proposé à un amateur de rouge est expliqué (retour du 28/09)', () {
    final sancerre = carte.firstWhere((w) => w.name == 'Sancerre');
    expect(TableMatchmaker.horsDeSesCouleurs(sancerre, amateurDeRouge), isTrue);
    expect(TableMatchmaker.horsDeSesCouleurs(carte.first, amateurDeRouge), isFalse);
    expect(TableMatchmaker.pourquoiCeVin(sancerre, amateurDeRouge, true),
        allOf(contains('Vous préférez le rouge'), contains('blanc')));
  });

  test('un « non » fait tomber le vin préféré, un « j\'adore » fait monter un autre', () {
    final avant = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: const [amateurDeRouge]);
    final premier = avant.first.menuWine;
    final chinon = carte.firstWhere((w) => w.name == 'Chinon');

    final avecAvis = amateurDeRouge.copie(avis: {
      premier.cacheKey: AvisDeTable.non.name,
      chinon.cacheKey: AvisDeTable.adore.name,
    });
    final apres = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: [avecAvis]);

    expect(apres.first.menuWine.name, 'Chinon');
    expect(apres.map((r) => r.menuWine.name), isNot(contains(premier.name)));
  });

  test('un convive « juste son prénom » qui donne des avis vote enfin', () {
    final sancerre = carte.firstWhere((w) => w.name == 'Sancerre');
    final paul = GuestProfile(
      id: 'paul',
      name: 'Paul',
      sansPreferences: true,
      avis: {for (final w in carte) w.cacheKey: (w == sancerre ? AvisDeTable.adore : AvisDeTable.non).name},
    );
    final top = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: [amateurDeRouge, paul]);
    expect(top.map((r) => r.menuWine.name), contains('Sancerre'));
  });

  test('les avis voyagent avec le profil envoyé à la table', () {
    final avecAvis = amateurDeRouge.copie(avis: {'barolo__domaine__0__red': 'adore'});
    final relu = GuestProfile.fromJson('flavien', avecAvis.toJson());
    expect(relu.avis, {'barolo__domaine__0__red': 'adore'});
  });

  testWidgets('la feuille rend les avis donnés, et explique le blanc à l\'amateur de rouge', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Map<String, AvisDeTable>? rendus;
    final sancerre = carte.firstWhere((w) => w.name == 'Sancerre');
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                rendus = await TableMatchmakerSheet.show(
                  context,
                  candidats: [carte.first, sancerre],
                  moi: amateurDeRouge,
                  isFr: false,
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('You prefer rouge'), findsNothing, reason: 'pas d\'explication pour un rouge');
    await tester.tap(find.text('Love it'));
    await tester.pumpAndSettle();

    expect(find.textContaining('You prefer'), findsOneWidget);
    await tester.tap(find.text('Rather not'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See the table\'s choice'));
    await tester.pumpAndSettle();

    expect(rendus, {
      carte.first.cacheKey: AvisDeTable.adore,
      sancerre.cacheKey: AvisDeTable.plutotPas,
    });
  });
}
