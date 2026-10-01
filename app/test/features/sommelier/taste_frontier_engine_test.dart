import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/menu_scan/domain/cellar_bridge.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/taste_frontier_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le moteur de frontière (S4) : quelle bouteille apprendrait le plus sur un palais,
/// sans faire boire un vin détesté.
void main() {
  TasteProfile profil({Map<String, int> observations = const {}, List<String> aversions = const []}) =>
      TasteProfile(id: 'p', name: 'Moi', axisObservations: observations, dislikedCharacteristics: aversions);

  MenuWine vin(String nom, String type,
          {double tanins = 5, double corps = 5, double bois = 5, double acidite = 5, double mineral = 5}) =>
      MenuWine(
        id: nom,
        name: nom,
        producer: 'Domaine',
        wineType: type,
        metrics: MenuWineRadarMetrics(tannins: tanins, body: corps, oak: bois, acidity: acidite, minerality: mineral),
      );

  SuggestionDeFrontiere<MenuWine>? choisir(List<MenuWine> carte, TasteProfile p, {Map<String, double>? plaisirs}) =>
      TasteFrontierEngine.choisir<MenuWine>(carte, p,
          profilDe: ProfilDeVin.depuisLaCarte, plaisir: plaisirs == null ? null : (w) => plaisirs[w.name]);

  test('un palais inconnu : le vin le plus marqué l\'emporte, sur l\'axe qu\'il tranche', () {
    final s = choisir([
      vin('Meursault', 'white', bois: 9, corps: 7),
      vin('Rouge moyen', 'red'),
    ], profil());
    expect(s?.vin.name, 'Meursault');
    expect(s?.axe, 'oak');
  });

  test('un vin sans bois apprend moins sur le boisé qu\'un vin boisé', () {
    final s = choisir([
      vin('Sans bois', 'white', bois: 1),
      vin('Boisé', 'white', bois: 9),
    ], profil());
    expect(s?.vin.name, 'Boisé');
  });

  test('plausibilité : jamais la minéralité d\'un rouge, jamais les tanins d\'un blanc', () {
    expect(ProfilDeVin.depuisLaCarte(vin('R', 'red', mineral: 9)).axes.containsKey('minerality'), isFalse);
    expect(ProfilDeVin.depuisLaCarte(vin('B', 'white', tanins: 9)).axes.containsKey('tannin'), isFalse);
    expect(ProfilDeVin.depuisLaCarte(vin('R', 'red')).axes.containsKey('tannin'), isTrue);
    expect(ProfilDeVin.depuisLaCarte(vin('B', 'white')).axes.containsKey('minerality'), isTrue);
  });

  test('un palais bien connu ne motive aucune suggestion', () {
    final connu = profil(observations: {for (final k in TasteProfile.axisKeys) k: 20});
    expect(choisir([vin('Meursault', 'white', bois: 9, corps: 8)], connu), isNull);
  });

  test('on ne fait pas boire un vin détesté pour apprendre', () {
    final s = choisir([
      vin('Très boisé', 'white', bois: 9),
      vin('Très vif', 'white', acidite: 9.5, mineral: 8),
    ], profil(aversions: ['Trop boisé']));
    expect(s?.vin.name, 'Très vif');
  });

  test('ni un vin dont le plaisir prédit est faible', () {
    final s = choisir([
      vin('Marqué mais déplaisant', 'white', bois: 9),
      vin('Marqué et plaisant', 'white', acidite: 9.5),
    ], profil(), plaisirs: {'Marqué mais déplaisant': 40, 'Marqué et plaisant': 82});
    expect(s?.vin.name, 'Marqué et plaisant');
    expect(s?.plaisir, 82);
  });

  test('la phrase dit ce qu\'on ignore et comment le vin le montre', () {
    final s = choisir([vin('Meursault', 'white', bois: 9, corps: 7)], profil(), plaisirs: {'Meursault': 78})!;
    expect(TasteFrontierEngine.phrase(s, 'Ce Meursault', true),
        'Je ne sais pas encore ce que vous pensez du boisé. Ce Meursault, nettement boisé, me le dirait, '
        'et il a de bonnes chances de vous plaire (78 %).');
    expect(TasteFrontierEngine.phrase(s, 'This Meursault', false), contains('how you feel about oak'));
  });

  test('la phrase de la cave invite à ouvrir une bouteille prête', () {
    final s = choisir([vin('Bandol', 'red', tanins: 8.5, corps: 7.5)], profil())!;
    expect(TasteFrontierEngine.phraseCave(s, 'Bandol Rouge 2019', true),
        'Pour mieux vous connaître : ouvrez votre Bandol Rouge 2019 (très charpenté, prêt à boire) — '
        'il me dirait ce que vous pensez des tanins.');
    expect(TasteFrontierEngine.phraseCave(s, 'Bandol Rouge 2019', false), contains('open your Bandol Rouge 2019'));
  });

  group('les vins de la cave, estimés', () {
    Wine vinDeCave(String nom, String type,
            {List<String> cepages = const [], String region = '', String? appellation, String? elevage}) =>
        Wine(
          id: nom,
          name: nom,
          type: type,
          country: 'France',
          region: region,
          appellation: appellation,
          grapes: [for (final c in cepages) Grape(name: c)],
          elevageType: elevage,
        );

    test('un Bandol (mourvèdre) élevé en fût tranche tanins et boisé', () {
      final p = ProfilDeVin.depuisLaCave(vinDeCave('Bandol', 'Rouge',
          cepages: ['Mourvèdre'], region: 'Provence', appellation: 'Bandol', elevage: '18 mois en foudres de chêne'));
      expect(p.axes['tannin'], 8);
      expect(p.axes['oak'], 6.5);
      expect(p.estime, isTrue);
    });

    test('un rouge dont on ignore les cépages ne dit rien de ses tanins', () {
      final p = ProfilDeVin.depuisLaCave(vinDeCave('Rouge', 'Rouge', region: 'Inconnue'));
      expect(p.axes.containsKey('tannin'), isFalse);
    });

    test('un Sancerre dit sa vivacité et sa minéralité, élevé en cuve il est sans bois', () {
      final p = ProfilDeVin.depuisLaCave(vinDeCave('Sancerre', 'Blanc',
          cepages: ['Sauvignon Blanc'], region: 'Loire', appellation: 'Sancerre', elevage: 'cuve inox'));
      expect(p.axes['acidity'], 8.5);
      expect(p.axes['minerality'], 8);
      expect(p.axes['oak'], 1.5);
    });
  });
  test('au restaurant, ni un vin de sa cave ni un vin déjà goûté (01/10)', () {
    final carte = [
      vin('Clio', 'red', corps: 9.5, tanins: 8).copyWith(
          pontDeCave: const LienAvecMaCave(type: TypeDeLien.enCave, libelle: 'Vous en avez en cave')),
      vin('Bandol', 'red', corps: 9, tanins: 8).copyWith(
          pontDeCave: const LienAvecMaCave(type: TypeDeLien.dejaGoute, libelle: 'Vous l\'avez goûté')),
      vin('Priorat', 'red', corps: 9, tanins: 7.5).copyWith(
          pontDeCave: const LienAvecMaCave(type: TypeDeLien.combleUneLacune, libelle: 'Comblerait un manque')),
    ];
    final candidats = TasteFrontierEngine.candidatsDeLaCarte(carte);
    expect(candidats.map((w) => w.name), ['Priorat']);
    expect(choisir(candidats, profil())?.vin.name, 'Priorat');
  });

  group('Le prix (01/10)', () {
    MenuWine rouge(String nom, double prix, {double corps = 9, double tanins = 8}) => MenuWine(
          id: nom,
          name: nom,
          producer: 'Domaine',
          wineType: 'red',
          bottlePrice: prix,
          metrics: MenuWineRadarMetrics(tannins: tanins, body: corps),
        );
    SuggestionDeFrontiere<MenuWine>? choisirAvecPrix(List<MenuWine> carte) => TasteFrontierEngine.choisir<MenuWine>(
        carte, profil(),
        profilDe: ProfilDeVin.depuisLaCarte, prix: (w) => w.bottlePrice);

    test('à apprentissage presque égal, la bouteille la moins chère', () {
      final s = choisirAvecPrix([
        rouge('Léoville Las Cases 2012', 420, corps: 9.5, tanins: 8.5),
        rouge('Malbec', 44),
      ]);
      expect(s?.vin.name, 'Malbec');
    });

    test('pour apprendre, une bouteille du milieu de la carte au plus', () {
      // La carte de « The Kitchin » (01/10) : le Léoville, marqué sur tout, avait le plus
      // gros gain ; une bouteille à 40 £ apprend presque autant.
      final s = choisirAvecPrix([
        rouge('Léoville Las Cases 2012', 420, corps: 9, tanins: 8.5),
        rouge('Lynch-Bages 2015', 240, corps: 8.5, tanins: 8),
        rouge('Crianza 2019', 55, corps: 8, tanins: 7.5),
        rouge('Côtes du Rhône 2021', 36, corps: 6.5, tanins: 6),
        rouge('Morgon 2022', 48, corps: 5.5, tanins: 4.5),
      ]);
      expect(s?.vin.name, 'Crianza 2019');
    });

    test('mais pas un vin qui apprendrait nettement moins', () {
      final s = choisirAvecPrix([
        rouge('Grand rouge charpenté', 120, corps: 9.5, tanins: 9.5),
        rouge('Rouge léger', 25, corps: 6.5, tanins: 6),
      ]);
      expect(s?.vin.name, 'Grand rouge charpenté');
    });
  });
}
