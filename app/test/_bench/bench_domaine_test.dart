// Banc de mesure (revue du 20/10) — pas un essai : il chronomètre ce que les écrans
// calculent sur le fil principal, pour une cave et une carte de taille réaliste.
//   flutter test --run-skipped --tags bench test/_bench
// ignore_for_file: avoid_print
@Tags(['bench'])
library;

import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/badges/data/badge_evaluator.dart';
import 'package:chatmelier/features/auth/presentation/widgets/bouteilles_qui_apprendraient.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/cellar_gap_engine.dart';
import 'package:chatmelier/features/cellar/domain/cellar_group_by.dart';
import 'package:chatmelier/features/cellar/domain/cellar_sort_by.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/menu_scan/domain/explication_du_score.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/angle_mort_de_la_cave.dart';
import 'package:chatmelier/features/sommelier/domain/carte_des_terroirs.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/features/sommelier/domain/profil_du_vin.dart';
import 'package:chatmelier/features/sommelier/domain/profil_du_vin_de_cave.dart';
import 'package:chatmelier/features/sommelier/domain/taste_frontier_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/benchmark/benchmark_menu_catalog.dart';
import '../helpers/benchmark/real_world_bottle_generator.dart';

const n = 300;

double mesurer(String nom, void Function() f, {int tours = 5}) {
  f(); // échauffement (JIT)
  var meilleur = double.infinity;
  for (var i = 0; i < tours; i++) {
    final sw = Stopwatch()..start();
    f();
    sw.stop();
    final ms = sw.elapsedMicroseconds / 1000;
    if (ms < meilleur) meilleur = ms;
  }
  print('${nom.padRight(58)} ${meilleur.toStringAsFixed(2).padLeft(9)} ms');
  return meilleur;
}

void main() {
  final bb = RealWorldBottleGenerator.generateBatch(n);
  final vins = [
    for (final b in bb)
      Wine(
        id: b.id,
        name: b.name,
        type: b.wineType,
        country: b.country,
        region: b.region,
        subRegion: b.subRegion,
        appellation: b.appellation,
        classification: b.classification,
        producer: b.producer,
        vintage: b.vintage,
        alcoholPct: b.alcoholPct,
        grapes: b.grapes,
      ),
  ];
  final bouteilles = [
    for (final w in vins)
      Bottle(
          id: 'b_${w.id}',
          cellarId: 'c',
          wineId: w.id,
          addedBy: 'moi',
          ownerId: 'moi',
          createdAt: DateTime(2026),
          quantity: 2,
          wine: w),
  ];
  const palais = TasteProfile(
    id: 'moi',
    name: 'Moi',
    isPrimary: true,
    questionnairesCompleted: 20,
    favoriteTypes: ['Rouge', 'Blanc'],
    palais: {
      'rouge': {'tannin': 0.7, 'body': 0.7, 'acidity': 0.5},
      'blanc': {'acidity': 0.8, 'oak': 0.2},
    },
    observationsPalais: {
      'rouge': {'tannin': 6, 'body': 5, 'acidity': 2},
      'blanc': {'acidity': 4, 'oak': 1},
    },
  );

  test('banc', () {
    print('— $n bouteilles (VM de test, JIT : l\'appli en release est 2 à 5 fois plus rapide)');
    mesurer('BadgeEvaluator.evaluate($n bouteilles, 0 dégustation)', () => BadgeEvaluator.evaluate(bottles: bouteilles, tastings: const [], isLatin: false), tours: 2);
    mesurer('Wine.fenetreEffective ×$n', () {
      for (final w in vins) {
        w.fenetreEffective;
      }
    });
    mesurer('Wine.windowStatus ×$n', () {
      for (final w in vins) {
        w.windowStatus;
      }
    });
    mesurer('Wine.isSpirit + isFortified ×$n', () {
      for (final w in vins) {
        w.isSpirit;
        w.isFortified;
      }
    });
    for (final tri in [CellarSortBy.maturity, CellarSortBy.nameAsc]) {
      mesurer('CellarSortBy.${tri.name}.sort($n)', () => tri.sort(bouteilles));
    }
    for (final g in CellarGroupBy.values) {
      mesurer('CellarGroupEngine.partitionBottles(${g.name})', () => CellarGroupEngine.partitionBottles(bouteilles, g, sortBy: CellarSortBy.maturity));
    }
    mesurer('ProfilDuVinDeCave.estimer ×$n', () {
      for (final w in vins) {
        ProfilDuVinDeCave.estimer(w, annee: 2026);
      }
    });
    mesurer('ProfilDuVin.deLaCave ×$n', () {
      for (final w in vins) {
        ProfilDuVin.deLaCave(w, le: DateTime(2026, 10));
      }
    });
    mesurer('ProfilDeVin.depuisLaCave ×$n', () {
      for (final w in vins) {
        ProfilDeVin.depuisLaCave(w);
      }
    });
    mesurer('CellarGapEngine.analyzeCellar($n)', () => CellarGapEngine.analyzeCellar(bouteilles));
    mesurer('AngleMortDeLaCave.trouver($n)', () => AngleMortDeLaCave.trouver(palais, bouteilles, annee: 2026));
    mesurer('bouteillesPourApprendre($n)', () => bouteillesPourApprendre(bouteilles));
    final pretes = bouteillesPourApprendre(bouteilles);
    mesurer('TasteFrontierEngine.parAxe(${pretes.length})', () => TasteFrontierEngine.parAxe(pretes, [palais], profilDe: (b) => ProfilDeVin.depuisLaCave(b.wine!)));
    mesurer('TasteFrontierEngine.choisir(${pretes.length})', () => TasteFrontierEngine.choisir(pretes, palais, profilDe: (b) => ProfilDeVin.depuisLaCave(b.wine!)));
    final lieux = [for (final w in vins) (pays: w.country, region: w.region, appellation: w.appellation, nom: w.name)];
    mesurer('CarteDesTerroirs.dresser($n goûtés + $n en cave)', () => CarteDesTerroirs.dresser(goutes: lieux, enCave: lieux, profil: palais));
    final convives = [
      GuestProfile.fromTasteProfile(palais),
      const GuestProfile(id: 'g1', name: 'Caro', favoriteTypes: ['Blanc']),
      const GuestProfile(id: 'g2', name: 'Paul', favoriteTypes: ['Rouge'], dislikedCharacteristics: ['tanin']),
      const GuestProfile(id: 'g3', name: 'Léa'),
    ];
    mesurer('GuestMatcherEngine.rankBottlesForGuests($n × 4)', () => GuestMatcherEngine.rankBottlesForGuests(bottles: bouteilles, guests: convives, maxResults: 6));

    final carte = [
      for (final m in BenchmarkMenuCatalog.menus)
        for (final w in m.expectedWines)
          MenuWine(
            id: '${m.id}_${w.name}',
            name: w.name,
            producer: w.producer,
            vintage: w.vintage,
            wineType: w.wineType,
            appellation: w.appellation,
            region: w.region,
            country: w.country,
            bottlePrice: w.bottlePrice,
            metrics: const MenuWineRadarMetrics(tannins: 5, acidity: 6, body: 6, oak: 4, sweetness: 1),
          ),
    ];
    final quarante = carte.take(40).toList();
    print('— carte de ${quarante.length} vins');
    mesurer('ExplicationDuScore.expliquer ×${quarante.length}', () {
      for (final w in quarante) {
        ExplicationDuScore.expliquer(w, palais);
      }
    });
    mesurer('MenuTableMatcherEngine.classerLaCarte(${quarante.length} × 4)', () => MenuTableMatcherEngine.classerLaCarte(menuWines: quarante, guests: convives));
    mesurer('MenuTableMatcherEngine.rankTop3WinesForTable(${quarante.length} × 4)', () => MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: quarante, guests: convives));
  });
}
