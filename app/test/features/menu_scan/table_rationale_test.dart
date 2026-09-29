import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:flutter_test/flutter_test.dart';

MenuWine vin(String nom, String type, double prix,
        {double tanins = 0, double acidite = 5, double corps = 5, double bois = 3, double mineral = 5}) =>
    MenuWine(
      id: nom,
      name: nom,
      producer: 'Domaine',
      wineType: type,
      bottlePrice: prix,
      devise: 'GBP',
      metrics: MenuWineRadarMetrics(
          tannins: tanins, acidity: acidite, body: corps, oak: bois, minerality: mineral),
    );

GuestProfile convive(String nom, List<String> couleurs,
        {required double tanin, required double corps, required double acidite, required double bois,
        List<String> aversions = const []}) =>
    GuestProfile(
      id: nom,
      name: nom,
      favoriteTypes: couleurs,
      dislikedCharacteristics: aversions,
      radarDistant: WineTasteRadarMetrics(
        tannin: tanin,
        body: corps,
        oak: bois,
        ripeFruit: 5,
        spice: 4,
        freshFruit: 6,
        minerality: 5,
        acidity: acidite,
      ),
    );

final tableExemple = [
    convive('Flavien', ['Rouge'], tanin: 7, corps: 7, acidite: 5, bois: 5),
    convive('Caro', ['Blanc'], tanin: 1, corps: 4, acidite: 8, bois: 2, aversions: ['tanin']),
    convive('Paul', ['Rouge', 'Blanc'], tanin: 5, corps: 5, acidite: 6, bois: 4),
  ];
final carteExemple = [
    vin('Barolo', 'red', 95, tanins: 9, corps: 8, acidite: 6, bois: 6),
    vin('Pinot Noir', 'red', 48, tanins: 4, corps: 5, acidite: 7, bois: 3),
    vin('Sancerre', 'white', 42, acidite: 9, corps: 4, bois: 1, mineral: 8),
    vin('Rioja', 'red', 60, tanins: 7, corps: 7, acidite: 5, bois: 8),
  ];

void main() {
  final table = [
    convive('Flavien', ['Rouge'], tanin: 7, corps: 7, acidite: 5, bois: 5),
    convive('Caro', ['Blanc'], tanin: 1, corps: 4, acidite: 8, bois: 2, aversions: ['tanin']),
    convive('Paul', ['Rouge', 'Blanc'], tanin: 5, corps: 5, acidite: 6, bois: 4),
  ];
  final carte = [
    vin('Barolo', 'red', 95, tanins: 9, corps: 8, acidite: 6, bois: 6),
    vin('Pinot Noir', 'red', 48, tanins: 4, corps: 5, acidite: 7, bois: 3),
    vin('Sancerre', 'white', 42, acidite: 9, corps: 4, bois: 1, mineral: 8),
    vin('Rioja', 'red', 60, tanins: 7, corps: 7, acidite: 5, bois: 8),
  ];

  test('trois finalistes, trois raisons différentes (retour de Caro, 26/09)', () {
    final top = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: table);
    final raisons = top.map((r) => r.consensusRationale).toList();

    expect(raisons, hasLength(3));
    expect(raisons.toSet(), hasLength(3), reason: raisons.join('\n'));
    for (final r in raisons) {
      expect(r, isNot(contains('Option intéressante')));
      expect(table.any((g) => r.contains(g.name)), isTrue, reason: 'aucun prénom dans : $r');
    }
  });

  test('une raison dit ce qui distingue le vin, ou sa place en prix', () {
    final top = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: table);
    final raisons = top.map((r) => r.consensusRationale).join('\n');
    expect(raisons, anyOf(contains('des trois'), contains('le moins cher'), contains('le plus cher')));
    expect(raisons, contains('£'), reason: 'les prix sont dans la devise de la carte');
  });

  test('le seul blanc des finalistes est présenté comme tel', () {
    final top = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: table);
    final sancerre = top.where((r) => r.menuWine.name == 'Sancerre');
    if (sancerre.isNotEmpty) {
      expect(sancerre.single.consensusRationale, contains('seul blanc des trois'));
    }
  });

  test('les raisons suivent la langue de l\'écran', () {
    final top = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: table, isFr: false);
    final raisons = top.map((r) => r.consensusRationale).join('\n');
    expect(raisons, anyOf(contains('will love it'), contains('will enjoy it'), contains('may find it')));
    expect(raisons, isNot(contains('adorer')));
  });

  test('seul à table, la raison parle de « vos goûts »', () {
    final top = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: [table.first]);
    expect(top.first.consensusRationale, contains('goûts'));
  });

  test('seul à table mais lu par un autre, la raison le nomme (29/09)', () {
    // L'invité qui arrive à une table où l'hôte est seul lisait « Dans vos goûts » :
    // c'était des goûts de l'hôte qu'il s'agissait.
    final top = MenuTableMatcherEngine.rankTop3WinesForTable(
        menuWines: carte, guests: [table.first], idLecteur: 'guest_me');
    for (final r in top) {
      expect(r.consensusRationale, isNot(contains('vos goûts')));
      expect(r.consensusRationale, contains('Flavien'));
    }
    final luParLui = MenuTableMatcherEngine.rankTop3WinesForTable(
        menuWines: carte, guests: [table.first], idLecteur: 'Flavien');
    expect(luParLui.first.consensusRationale, contains('vos goûts'));
  });

  test('celui qui lit se lit « vous », avec le verbe accordé (29/09)', () {
    // L'hôte, nommé « Moi » sur son téléphone, lisait « Test Claude et Moi l'apprécieront ».
    final top = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: carte, guests: table, idLecteur: 'Caro');
    final raisons = top.map((r) => r.consensusRationale).join(' | ');
    expect(raisons, contains('ous'), reason: 'Caro se lit « vous »');
    expect(raisons, isNot(contains('Caro ')), reason: 'jamais son propre prénom');
    expect(raisons, isNot(matches(RegExp(r"[Vv]ous (va |vont |l'appréciera|s'en |le trouvera)"))),
        reason: '« vous » prend la deuxième personne : allez, apprécierez, vous en accommoderez, trouverez');
    final en = MenuTableMatcherEngine.rankTop3WinesForTable(
        menuWines: carte, guests: table, idLecteur: 'Caro', isFr: false);
    expect(en.map((r) => r.consensusRationale).join(' | '), contains('you'));
  });

  group('plausibilité œnologique des distinctions (29/09)', () {
    // Chaque vin ne diffère des deux autres que sur l'axe testé.
    MenuWine v(String type, {double mineral = 5, double doux = 1, double fruit = 5}) => MenuWine(
          id: '$type$mineral$doux$fruit',
          name: 'Vin',
          producer: 'Domaine',
          wineType: type,
          metrics: MenuWineRadarMetrics(
              tannins: type == 'red' ? 5 : 0, acidity: 6, body: 6, fruit: fruit, oak: 3,
              minerality: mineral, sweetness: doux),
        );
    String distinction(MenuWine vin, List<MenuWine> autres, {bool fr = true}) =>
        RedactionDesRaisons.ceQuiLeDistingue(vin, autres, fr);

    test('jamais de minéralité pour distinguer des rouges', () {
      final peu = v('red', mineral: 2);
      final autres = [v('red', mineral: 7), v('red', mineral: 8)];
      expect(distinction(peu, autres, fr: false), isNot(contains('mineral')),
          reason: '« the least mineral » d\'un rouge ne veut rien dire');
      expect(distinction(v('red', mineral: 9), [v('red', mineral: 4), v('red', mineral: 3)]),
          isNot(contains('minéral')));
    });

    test('la minéralité distingue un blanc parmi des blancs, dans le bon sens seulement', () {
      expect(distinction(v('white', mineral: 9), [v('white', mineral: 5), v('white', mineral: 4)]),
          'le plus minéral des trois');
      expect(distinction(v('white', mineral: 2), [v('white', mineral: 7), v('white', mineral: 8)]),
          isNot(contains('minéral')), reason: '« le moins minéral » n\'aide personne à choisir');
    });

    test('« le plus doux » seulement pour un vin qui l\'est', () {
      // Trois vins secs : 1, 1, 2,5 de sucre n'en font pas un vin doux.
      expect(distinction(v('white', doux: 2.5), [v('white', doux: 1), v('white', doux: 1)]),
          isNot(contains('doux')));
      expect(distinction(v('white', doux: 6), [v('white', doux: 1), v('white', doux: 1)]),
          'le plus doux des trois');
      expect(distinction(v('white', doux: 1), [v('white', doux: 5), v('white', doux: 6)]), 'le seul sec');
    });

    test('un superlatif doit être vrai dans l\'absolu : un Chablis à 3/10 n\'est pas « le plus boisé »', () {
      // Consensus du 29/09 : « The oakiest of the three » sur un Chablis Premier Cru, lu par
      // un convive qui fuit le bois.
      MenuWine blanc(String nom, double bois, {String type = 'white'}) => MenuWine(
            id: nom, name: nom, producer: 'Domaine', wineType: type,
            metrics: MenuWineRadarMetrics(acidity: 8.5, body: 6, fruit: 6.5, oak: bois, minerality: 8.5),
          );
      final chablis = blanc('Chablis Premier Cru', 3);
      final autres = [blanc('Sancerre', 1.5), blanc('Whispering Angel', 1, type: 'rose')];
      expect(distinction(chablis, autres, fr: false), isNot(contains('oak')));
      expect(distinction(chablis, autres), isNot(contains('boisé')));
      // Un vrai vin boisé, lui, se dit tel.
      expect(distinction(blanc('Meursault', 7), [blanc('Chablis', 3), blanc('Sancerre', 1.5)]),
          'le plus boisé des trois');
    });

    test('pas de « moins fruité »', () {
      expect(distinction(v('red', fruit: 2), [v('red', fruit: 7), v('red', fruit: 8)]),
          isNot(contains('fruité')));
      expect(distinction(v('red', fruit: 9), [v('red', fruit: 5), v('red', fruit: 4)]),
          'le plus fruité des trois');
    });
  });
}
