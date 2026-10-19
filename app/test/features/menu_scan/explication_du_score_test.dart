import 'dart:math';

import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/menu_scan/domain/explication_du_score.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// 13/10, Flavien : « ça m'affiche "taillé pour vous". je devrais pouvoir cliquer sur chaque
/// vin pour savoir pourquoi un vin est taillé pour moi ou pas ».
void main() {
  setUp(() => Langue.code = 'fr');

  const palais = TasteProfile(
    id: 'moi',
    name: 'Moi',
    isPrimary: true,
    favoriteTypes: ['Rouge'],
    favoriteRegions: ['Bourgogne'],
    favoriteGrapes: ['Pinot Noir'],
    dislikedCharacteristics: ['Trop boisé'],
    avgTanninPreference: 0.4,
    avgBodyPreference: 0.5,
  );

  const volnay = MenuWine(
    id: 'v',
    name: 'Volnay',
    producer: 'Domaine de Montille',
    wineType: 'red',
    appellation: 'Volnay',
    region: 'Bourgogne',
    grapes: ['Pinot Noir'],
    metrics: MenuWineRadarMetrics(tannins: 4.5, body: 5.5, oak: 4),
  );

  const madiran = MenuWine(
    id: 'm',
    name: 'Madiran',
    producer: 'Château Montus',
    wineType: 'red',
    appellation: 'Madiran',
    region: 'Sud-Ouest',
    grapes: ['Tannat'],
    metrics: MenuWineRadarMetrics(tannins: 9.5, body: 9, oak: 8.5),
  );

  test('un Volnay pour un amateur de Bourgogne : taillé pour lui, et pourquoi', () {
    final e = ExplicationDuScore.expliquer(volnay, palais)!;
    // V2.6 : les étiquettes ne pèsent plus que 4 points chacune, et des tanins et un corps
    // seulement devinés (aucune observation) ne rapprochent que d'un demi-point.
    // 70 + 4 + 4 + 4 + 0,5 + 0,5 = 83.
    expect(e.score, 83);
    expect(ExplicationDuScore.verdict(e.score), 'Taillé pour vous');
    expect(e.raisons.map((r) => r.phrase), [
      'Vous aimez les rouges',
      'Bourgogne, l\'une de vos régions préférées',
      'Pinot Noir, l\'un de vos cépages préférés',
      'Un corps comme vous l\'aimez',
      'Des tanins comme vous les aimez',
    ]);
    expect(e.borne, isFalse);
  });

  test('un Madiran boisé et tannique : ce qui l\'éloigne, avec son poids', () {
    final e = ExplicationDuScore.expliquer(madiran, palais)!;
    final poids = {for (final r in e.raisons) r.phrase: r.points};
    expect(poids['Un boisé marqué, que vous n\'aimez pas'], -25);
    // Des tanins devinés à 4 face à 9,5 : un écart de 5,5 éloigne, même deviné (V2.3 · K5).
    expect(poids['Bien plus tannique que ce que vous aimez'], -2.5);
    expect(poids['Vous aimez les rouges'], 4);
    expect(poids['Plus corsé que ce que vous aimez'], -1);
    expect(e.score, 46);
    expect(ExplicationDuScore.verdict(e.score), 'Loin de vos goûts');
  });

  test('le pourcentage est la somme de ses raisons, et celui de la carte', () {
    final hasard = Random(17);
    final types = ['Rouge', 'Blanc sec', 'Rosé', 'Bulles', 'Champagne'];
    final regions = ['Bourgogne', 'Rhône', 'Rioja', 'Loire', 'Bordeaux'];
    final cepages = ['Pinot Noir', 'Syrah', 'Chardonnay', 'Tempranillo', 'Chenin'];
    final aversions = ['Trop boisé', 'Trop acide', 'Trop tannique', 'Trop sucré'];
    final couleurs = ['red', 'white', 'rosé', 'sparkling', 'dessert'];
    List<String> quelques(List<String> l) => [for (final x in l) if (hasard.nextBool()) x];
    double note() => (hasard.nextInt(101)) / 10;
    for (var i = 0; i < 600; i++) {
      final profil = TasteProfile(
        id: 'p$i',
        name: 'P',
        favoriteTypes: quelques(types),
        favoriteRegions: quelques(regions),
        favoriteGrapes: quelques(cepages),
        dislikedCharacteristics: quelques(aversions),
        avgTanninPreference: hasard.nextBool() ? hasard.nextDouble() : null,
        avgBodyPreference: hasard.nextBool() ? hasard.nextDouble() : null,
        questionnairesCompleted: 3,
      );
      final vin = MenuWine(
        id: 'w$i',
        name: 'Vin',
        producer: 'Domaine',
        wineType: couleurs[hasard.nextInt(couleurs.length)],
        region: regions[hasard.nextInt(regions.length)],
        appellation: hasard.nextBool() ? regions[hasard.nextInt(regions.length)] : null,
        grapes: quelques(cepages),
        metrics: MenuWineRadarMetrics(
            tannins: note(), body: note(), oak: note(), acidity: note(), sweetness: note()),
      );
      final e = ExplicationDuScore.expliquer(vin, profil)!;
      // V2.6 : les pourcentages changent à dessein (palais par famille, étiquettes moins
      // lourdes) ; restent le total et l'égalité avec la carte.
      expect(e.score, e.brut.clamp(ExplicationDuScore.plancher, ExplicationDuScore.plafond).roundToDouble(),
          reason: 'cas $i');
      final somme = ExplicationDuScore.depart + e.raisons.fold<double>(0, (s, r) => s + r.points);
      expect(somme, closeTo(e.brut, 1e-9), reason: 'cas $i');
      expect(MenuWineMatchCalculator.computeMatchScore(vin, profil), e.score);
    }
  });

  test('une préférence vide ne fait plus gagner tous les vins', () {
    const vide = TasteProfile(
      id: 'v',
      name: 'V',
      favoriteTypes: ['Rouge'],
      favoriteRegions: [' '],
      favoriteGrapes: [''],
      questionnairesCompleted: 3,
    );
    final e = ExplicationDuScore.expliquer(madiran, vide)!;
    expect(e.raisons.map((r) => r.phrase), ['Vous aimez les rouges']);
    expect(e.score, 74);
  });

  test('un palais trop peu connu : pas d\'accord deviné', () {
    expect(ExplicationDuScore.expliquer(volnay, const TasteProfile(id: 'x', name: 'X')), isNull);
    expect(ExplicationDuScore.expliquer(volnay, null), isNull);
  });
}
