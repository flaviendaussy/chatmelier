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
    expect(e.score, 99);
    expect(ExplicationDuScore.verdict(e.score), 'Taillé pour vous');
    expect(e.raisons.map((r) => r.phrase), [
      'Vous aimez les rouges',
      'Bourgogne, l\'une de vos régions préférées',
      'Pinot Noir, l\'un de vos cépages préférés',
      'Des tanins comme vous les aimez',
      'Un corps comme vous l\'aimez',
    ]);
    // 70 + 15 + 12 + 10 + 4,5 + 4,5 = 116, ramené à 99 : la fiche le dit.
    expect(e.borne, isTrue);
  });

  test('un Madiran boisé et tannique : ce qui l\'éloigne, avec son poids', () {
    final e = ExplicationDuScore.expliquer(madiran, palais)!;
    final poids = {for (final r in e.raisons) r.phrase: r.points};
    expect(poids['Un boisé marqué, que vous n\'aimez pas'], -25);
    expect(poids['Bien plus tannique que ce que vous aimez'], -0.5);
    expect(poids['Vous aimez les rouges'], 15);
    // Un corps de 9 pour qui aime 5 : plus corsé, encore dans ses goûts (un point).
    expect(poids['Plus corsé que ce que vous aimez'], 1);
    expect(e.score, 61);
    expect(ExplicationDuScore.verdict(e.score), 'Un peu loin de vos goûts');
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
      expect(e.score, _ancienCalcul(vin, profil), reason: 'cas $i');
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
    expect(e.score, 85);
  });

  test('un palais trop peu connu : pas d\'accord deviné', () {
    expect(ExplicationDuScore.expliquer(volnay, const TasteProfile(id: 'x', name: 'X')), isNull);
    expect(ExplicationDuScore.expliquer(volnay, null), isNull);
  });
}

/// Le calcul d'avant l'explication (`MenuWineMatchCalculator`, jusqu'au 17/10), recopié tel
/// quel : l'explication ne doit rien changer aux pourcentages des cartes.
double? _ancienCalcul(MenuWine wine, TasteProfile? profile) {
  if (profile == null || !profile.isWellProvided) return null;
  double score = 70.0;
  final favTypes = profile.favoriteTypes.map((t) => t.toLowerCase()).toList();
  if (favTypes.isNotEmpty) {
    final matchesColor = favTypes.any((t) =>
        (wine.isRed && t.contains('rouge')) ||
        (wine.isWhite && t.contains('blanc')) ||
        (wine.isRose && t.contains('rosé')) ||
        (wine.isSparkling && (t.contains('bulles') || t.contains('champ'))));
    if (matchesColor) {
      score += 15.0;
    } else {
      score -= 20.0;
    }
  }
  final favRegions = profile.favoriteRegions.map((r) => r.toLowerCase()).toList();
  final wineRegion = (wine.region ?? '').toLowerCase();
  final wineAppell = (wine.appellation ?? '').toLowerCase();
  if (favRegions.any((r) => wineRegion.contains(r) || wineAppell.contains(r))) {
    score += 12.0;
  }
  final favGrapes = profile.favoriteGrapes.map((g) => g.toLowerCase()).toList();
  if (wine.grapes.any((wg) => favGrapes.any((fg) => wg.toLowerCase().contains(fg)))) {
    score += 10.0;
  }
  final dislikes = profile.dislikedCharacteristics.map((d) => d.toLowerCase()).toList();
  for (final d in dislikes) {
    if (d.contains('tann') && wine.metrics.tannins > 7.0) score -= 25.0;
    if (d.contains('bois') && wine.metrics.oak > 7.0) score -= 25.0;
    if (d.contains('acid') && wine.metrics.acidity > 7.5) score -= 20.0;
    if (d.contains('sucr') && wine.metrics.sweetness > 4.0) score -= 20.0;
  }
  if (profile.avgTanninPreference != null && wine.isRed) {
    final diff = (profile.avgTanninPreference! * 10 - wine.metrics.tannins).abs();
    score += (5.0 - diff).clamp(-10.0, 8.0);
  }
  if (profile.avgBodyPreference != null) {
    final diff = (profile.avgBodyPreference! * 10 - wine.metrics.body).abs();
    score += (5.0 - diff).clamp(-10.0, 8.0);
  }
  return score.clamp(35.0, 99.0).roundToDouble();
}
