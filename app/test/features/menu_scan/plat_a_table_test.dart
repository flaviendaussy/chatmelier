import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';

const palais = WineTasteRadarMetrics(
  tannin: 5, body: 5, oak: 3, ripeFruit: 5, spice: 4, freshFruit: 5, minerality: 5, acidity: 5);

GuestProfile convive(String nom, {String? plat}) =>
    GuestProfile(id: nom, name: nom, radarDistant: palais, plat: plat);

const carte = [
  MenuWine(id: 'r', name: 'Saint-Joseph 2020', producer: '', wineType: 'red',
      metrics: MenuWineRadarMetrics(tannins: 7, body: 7, acidity: 5)),
  MenuWine(id: 'b', name: 'Chablis 2022', producer: '', wineType: 'white',
      metrics: MenuWineRadarMetrics(tannins: 0, body: 5, acidity: 8, minerality: 8)),
];

double harmonie(List<MenuTableMatchResult> r, String id) => r.firstWhere((x) => x.menuWine.id == id).harmonyScore;

void main() {
  test('quand la table mange du poisson, le blanc monte et le rouge descend', () {
    final sans = MenuTableMatcherEngine.classerLaCarte(
        menuWines: carte, guests: [convive('Paul'), convive('Aude'), convive('Caro')]);
    final avec = MenuTableMatcherEngine.classerLaCarte(
        menuWines: carte,
        guests: [convive('Paul', plat: 'poisson'), convive('Aude', plat: 'poisson'), convive('Caro')]);
    expect(harmonie(avec, 'b'), greaterThan(harmonie(sans, 'b')));
    expect(harmonie(avec, 'r'), lessThan(harmonie(sans, 'r')));
    expect(avec.first.menuWine.id, 'b');
  });

  test('sans plat annoncé, seul le palais compte', () {
    final a = MenuTableMatcherEngine.classerLaCarte(menuWines: carte, guests: [convive('Paul')]);
    final b = MenuTableMatcherEngine.classerLaCarte(menuWines: carte, guests: [convive('Paul', plat: null)]);
    expect(harmonie(a, 'r'), harmonie(b, 'r'));
  });

  test('« juste mon prénom » et un plat : son plat compte, pas un palais prêté', () {
    const sansGout = GuestProfile(id: 'Caro', name: 'Caro', sansPreferences: true);
    final seule = MenuTableMatcherEngine.classerLaCarte(
        menuWines: carte, guests: [convive('Paul'), sansGout]);
    final avecPlat = MenuTableMatcherEngine.classerLaCarte(
        menuWines: carte, guests: [convive('Paul'), sansGout.copie(plat: 'poisson')]);
    // Sans plat, Caro ne vote pas ; avec son poisson, elle tire la table vers le Chablis,
    // et rien d'autre en elle ne départage les deux vins.
    expect(seule.first.guestScores.containsKey('Caro'), isFalse);
    final caro = avecPlat.firstWhere((x) => x.menuWine.id == 'b').guestScores['Caro']!;
    final caroRouge = avecPlat.firstWhere((x) => x.menuWine.id == 'r').guestScores['Caro']!;
    expect(caro, greaterThan(caroRouge));
    expect(harmonie(avecPlat, 'b') - harmonie(avecPlat, 'r'), greaterThan(harmonie(seule, 'b') - harmonie(seule, 'r')));
  });

  test('le plat voyage avec le profil du convive, et rien d\'inconnu ne passe', () {
    final p = GuestProfile.fromJson('x', convive('Paul', plat: 'viande').toJson());
    expect(p.plat, 'viande');
    expect(GuestProfile.fromJson('x', {...convive('Paul').toJson(), 'plat': 'pizza<script>'}).plat, isNull);
  });
}
