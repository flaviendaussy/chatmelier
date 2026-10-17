import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/sommelier/domain/taste_frontier_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// 11/10, Flavien : « pour le radar des goûts : ça serait bien de pouvoir savoir vite quelles
/// bouteilles en cave pourraient améliorer les axes encore inconnus ».
void main() {
  setUp(() => Langue.code = 'fr');

  // Des vins de cave déjà estimés, axe par axe (sur 10).
  const bandol = ProfilDeVin({'tannin': 8, 'body': 7.5}, estime: true);
  const chablis = ProfilDeVin({'acidity': 8.5, 'minerality': 8}, estime: true);
  const meursault = ProfilDeVin({'body': 7, 'oak': 8}, estime: true);
  const cotesDuRhone = ProfilDeVin({'body': 5.5}, estime: true);
  final cave = {'bandol': bandol, 'chablis': chablis, 'meursault': meursault, 'cdr': cotesDuRhone};

  TasteProfile palais(String nom, Map<String, int> observations,
          {List<String> aversions = const [], bool principal = false}) =>
      TasteProfile(
        id: nom,
        name: nom,
        isPrimary: principal,
        axisObservations: observations,
        dislikedCharacteristics: aversions,
      );

  test('un palais seul : chaque axe encore deviné, avec la bouteille qui le trancherait', () {
    final moi = palais('Moi', {'tannin': 12, 'body': 2, 'oak': 0, 'acidity': 1, 'minerality': 0}, principal: true);
    final axes = TasteFrontierEngine.parAxe(cave.keys.toList(), [moi], profilDe: (c) => cave[c]!);
    // Les tanins sont connus (douze dégustations) : rien à proposer.
    expect(axes.map((a) => a.axe), isNot(contains('tannin')));
    expect({for (final a in axes) a.axe: a.bouteille}, {
      'oak': 'meursault',
      'minerality': 'chablis',
      'acidity': 'chablis',
      'body': 'bandol',
    });
    // Le moins connu d'abord : jamais goûté (boisé, minéralité), puis une fois, puis deux.
    expect(axes.map((a) => a.axe).take(2).toSet(), {'oak', 'minerality'});
    expect(axes.last.axe, 'body');
    // Un côtes-du-rhône moyen (5,5) ne tranche rien.
    expect(axes.map((a) => a.bouteille), isNot(contains('cdr')));
  });

  test('une aversion déclarée écarte la bouteille, même si elle apprendrait beaucoup', () {
    final moi = palais('Moi', const {}, aversions: const ['Trop boisé'], principal: true);
    final axes = TasteFrontierEngine.parAxe(cave.keys.toList(), [moi], profilDe: (c) => cave[c]!);
    expect(axes.map((a) => a.bouteille), isNot(contains('meursault')));
  });

  test('à deux : d\'abord ce que ni l\'un ni l\'autre ne sait, une bouteille qui ne heurte personne', () {
    final moi = palais('Moi', {'tannin': 12, 'body': 12, 'oak': 0, 'acidity': 12, 'minerality': 1}, principal: true);
    final caro = palais('Caro', {'tannin': 0, 'body': 12, 'oak': 1, 'acidity': 12, 'minerality': 12},
        aversions: const ['Trop tannique']);
    final axes = TasteFrontierEngine.parAxe(cave.keys.toList(), [moi, caro], profilDe: (c) => cave[c]!);
    // Le boisé, ignoré des deux, passe devant.
    expect(axes.first.axe, 'oak');
    expect(axes.first.ignorants.map((p) => p.name), ['Moi', 'Caro']);
    expect(axes.first.bouteille, 'meursault');
    // Les tanins, que Caro ignore, mais le Bandol heurte son aversion : pas de proposition.
    expect(axes.map((a) => a.axe), isNot(contains('tannin')));
    expect(TasteFrontierEngine.commentLeVinLeMontre('oak', 8), 'nettement boisé');
  });
}
