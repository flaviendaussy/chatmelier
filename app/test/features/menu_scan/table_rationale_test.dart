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
}
