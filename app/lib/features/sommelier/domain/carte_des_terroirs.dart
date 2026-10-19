import '../../../shared/utils/langue.dart';
import '../../../shared/utils/sans_accents.dart';
import '../../../shared/utils/valeurs_rangees.dart';
import '../../auth/domain/taste_profile.dart';
import '../../cellar/domain/wine_world/wine_world.dart';
import 'angle_mort_de_la_cave.dart';
import 'taste_frontier_engine.dart';

/// Un vin vu quelque part : au journal ou en cave.
typedef VinSitue = ({String? pays, String? region, String? appellation, String? nom});

/// Un terroir rencontré, tel qu'on l'affiche : l'appellation de la fiche quand elle en a
/// une, sinon la région.
class TerroirVu {
  final String libelle;

  /// La région du référentiel, quand on la reconnaît ; deux vins de la même région n'en
  /// font qu'un terroir.
  final String? regionId;

  const TerroirVu(this.libelle, this.regionId);
}

/// La prochaine région à explorer, et l'axe du palais qu'elle éclairerait.
class ProchaineRegion {
  final String nom;
  final String axe;

  /// La famille du palais que la région éclairerait (V2.6).
  final String? famille;

  /// La bouteille de la cave qui la ferait découvrir, quand il y en a une (16/10).
  final String? vinDeLaCave;

  const ProchaineRegion(this.nom, this.axe, {this.vinDeLaCave, this.famille});

  String get phrase => vinDeLaCave != null
      ? tr('Prochaine région à explorer : {region}, déjà dans votre cave. Ouvrez votre {vin} : il vous dirait ce que vous pensez {quoi}.',
          'Next region to explore: {region}, already in your cellar. Open your {vin}: it would tell you how you feel about {quoi}.',
          {'region': valeurAffichee(nom), 'vin': vinDeLaCave, 'quoi': TasteFrontierEngine.ceQueJugeLAxe(axe, famille: famille)})
      : tr('Prochaine région à explorer : {region}. Ses vins vous diraient ce que vous pensez {quoi}.',
          'Next region to explore: {region}. Its wines would tell you how you feel about {quoi}.',
          {'region': valeurAffichee(nom), 'quoi': TasteFrontierEngine.ceQueJugeLAxe(axe, famille: famille)});
}

/// Une bouteille de la cave qui pourrait faire découvrir son terroir.
typedef BouteilleAExplorer = ({VinSitue lieu, String nomDuVin, ProfilDeVin profil});

/// Les terroirs d'un palais (V2.3 · J3) : ceux qu'il a goûtés, ceux qui attendent en cave
/// sans avoir été goûtés, ce qui reste à découvrir — et la prochaine région à explorer,
/// choisie par la frontière : celle qui éclairerait l'axe du palais le moins connu.
class CarteDesTerroirs {
  final List<TerroirVu> goutes;
  final List<TerroirVu> enCave;

  /// Régions du référentiel déjà approchées (goûtées ou en cave), sur [total].
  final int explorees;
  final int total;
  final ProchaineRegion? prochaine;

  const CarteDesTerroirs({
    required this.goutes,
    required this.enCave,
    required this.explorees,
    required this.total,
    this.prochaine,
  });

  /// Les régions qui montrent le mieux chaque axe d'une famille (`famille:axe`), dans
  /// l'ordre où on les propose. L'âge d'un vin ne tient pas à sa région : pas de liste.
  static const regionsQuiMontrent = {
    'blanc:oak': ['Meursault', 'Pessac-Léognan', 'Napa Valley'],
    'rouge:tannin': ['Madiran', 'Barolo', 'Bandol'],
    'blanc:acidity': ['Moselle', 'Muscadet', 'Jura', 'Chablis'],
    'rouge:body': ['Châteauneuf-du-Pape', 'Amarone', 'Priorat', 'Barossa'],
    'blanc:sweetness': ['Vouvray', 'Jurançon', 'Moselle'],
  };

  /// [aOuvrir] : les bouteilles de la cave prêtes à boire (sans spiritueux). La prochaine
  /// région vient d'abord de l'une d'elles, d'un terroir jamais goûté, choisie par la
  /// frontière ; une région hors cave seulement à défaut (« mais est-ce que j'ai un
  /// Meursault ?? », Flavien, 13/10).
  static CarteDesTerroirs dresser({
    required Iterable<VinSitue> goutes,
    required Iterable<VinSitue> enCave,
    TasteProfile? profil,
    Iterable<BouteilleAExplorer> aOuvrir = const [],
  }) {
    final dejaGoutes = _terroirs(goutes);
    final clesGoutees = {for (final t in dejaGoutes) _cle(t)};
    final enCaveSeulement = [
      for (final t in _terroirs(enCave))
        if (!clesGoutees.contains(_cle(t))) t,
    ];
    final regions = {
      for (final t in [...dejaGoutes, ...enCaveSeulement])
        if (t.regionId != null) t.regionId!,
    };
    final libelles = {for (final t in [...dejaGoutes, ...enCaveSeulement]) t.libelle.toLowerCase()};

    ProchaineRegion? prochaine;
    if (profil != null) {
      final jamaisGoutees = [
        for (final b in aOuvrir)
          if (_terroirs([b.lieu]).firstOrNull case final t? when !clesGoutees.contains(_cle(t))) (b, t),
      ];
      final choix = TasteFrontierEngine.choisir<(BouteilleAExplorer, TerroirVu)>(
        jamaisGoutees,
        profil,
        profilDe: (c) => c.$1.profil,
      );
      if (choix != null) {
        prochaine = ProchaineRegion(choix.vin.$2.libelle, choix.axe, vinDeLaCave: choix.vin.$1.nomDuVin, famille: choix.famille);
      }
    }
    if (profil != null && prochaine == null) {
      for (final (famille, axe) in AngleMortDeLaCave.axesAApprendre(profil)) {
        for (final nom in regionsQuiMontrent['$famille:$axe'] ?? const <String>[]) {
          final id = WineWorld.region(appellation: nom)?.id;
          final dejaVue = id != null ? regions.contains(id) : libelles.contains(nom.toLowerCase());
          if (!dejaVue) {
            prochaine = ProchaineRegion(nom, axe, famille: famille);
            break;
          }
        }
        if (prochaine != null) break;
      }
    }

    return CarteDesTerroirs(
      goutes: dejaGoutes,
      enCave: enCaveSeulement,
      explorees: regions.length,
      total: WineWorld.regions.length,
      prochaine: prochaine,
    );
  }

  static String _cle(TerroirVu t) => t.regionId ?? t.libelle.toLowerCase();

  /// Des mentions sans lieu : « Vin de France » dit une catégorie, pas un terroir.
  static const _sansLieu = {
    'autre', 'other', 'vin de france', 'vin de table', 'vino de espana', 'vino de mesa', 'table wine',
  };

  /// Un terroir par région reconnue (le premier libellé rencontré), un par libellé sinon.
  static List<TerroirVu> _terroirs(Iterable<VinSitue> vins) {
    final vus = <String, TerroirVu>{};
    for (final v in vins) {
      final region = (v.region ?? '').trim();
      // Sans appellation sur la fiche, celle que le nom porte, et elle seule : « Bandol », pas
      // « Bandol Pour Lulu » (17/10).
      var appellation = (v.appellation ?? '').trim().isNotEmpty
          ? v.appellation!.trim()
          : (WineWorld.appellationLueDans(v.nom, pays: v.pays) ?? '');
      // Une mention sans lieu laisse parler la région, quand la fiche en donne une.
      if (_sansLieu.contains(sansAccents(appellation))) appellation = '';
      final libelle = appellation.isNotEmpty ? appellation : region;
      if (libelle.isEmpty || _sansLieu.contains(sansAccents(libelle))) continue;
      final id = WineWorld.region(pays: v.pays, region: region, appellation: appellation)?.id;
      final t = TerroirVu(libelle, id);
      vus.putIfAbsent(_cle(t), () => t);
    }
    return vus.values.toList();
  }
}
