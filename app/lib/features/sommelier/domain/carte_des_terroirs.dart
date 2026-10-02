import '../../../shared/utils/langue.dart';
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

  const ProchaineRegion(this.nom, this.axe);

  String get phrase => tr('Prochaine région à explorer : {region}. Ses vins vous diraient ce que vous pensez {quoi}.',
      'Next region to explore: {region}. Its wines would tell you how you feel about {quoi}.',
      {'region': valeurAffichee(nom), 'quoi': TasteFrontierEngine.ceQueJugeLAxe(axe)});
}

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

  /// Les régions qui montrent le mieux chaque axe, dans l'ordre où on les propose.
  static const regionsQuiMontrent = {
    'oak': ['Rioja', 'Meursault', 'Pessac-Léognan', 'Napa Valley'],
    'minerality': ['Chablis', 'Sancerre', 'Santorin', 'Muscadet'],
    'tannin': ['Madiran', 'Barolo', 'Bandol'],
    'acidity': ['Moselle', 'Muscadet', 'Jura', 'Chablis'],
    'body': ['Châteauneuf-du-Pape', 'Amarone', 'Priorat', 'Barossa'],
  };

  static CarteDesTerroirs dresser({
    required Iterable<VinSitue> goutes,
    required Iterable<VinSitue> enCave,
    TasteProfile? profil,
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
      for (final axe in AngleMortDeLaCave.axesAApprendre(profil)) {
        for (final nom in regionsQuiMontrent[axe] ?? const <String>[]) {
          final id = WineWorld.region(appellation: nom)?.id;
          final dejaVue = id != null ? regions.contains(id) : libelles.contains(nom.toLowerCase());
          if (!dejaVue) {
            prochaine = ProchaineRegion(nom, axe);
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

  /// Un terroir par région reconnue (le premier libellé rencontré), un par libellé sinon.
  static List<TerroirVu> _terroirs(Iterable<VinSitue> vins) {
    final vus = <String, TerroirVu>{};
    for (final v in vins) {
      final region = (v.region ?? '').trim();
      final appellation = (v.appellation ?? '').trim().isNotEmpty
          ? v.appellation!.trim()
          : (WineWorld.appellationDansLeNom(v.nom, pays: v.pays) ? v.nom!.trim() : '');
      final libelle = appellation.isNotEmpty ? appellation : region;
      if (libelle.isEmpty || libelle.toLowerCase() == 'autre') continue;
      final id = WineWorld.region(pays: v.pays, region: region, appellation: appellation)?.id;
      final t = TerroirVu(libelle, id);
      vus.putIfAbsent(_cle(t), () => t);
    }
    return vus.values.toList();
  }
}
