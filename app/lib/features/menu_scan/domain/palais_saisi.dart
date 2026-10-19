import '../../../shared/utils/langue.dart';
import '../../auth/domain/palais.dart';
import '../../auth/domain/wine_taste_radar.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';

/// Ce qu'un invité dit de ses goûts en vingt secondes : cinq curseurs en mots de tous les
/// jours (V2.6) — sec ou doux, rond ou vif, léger ou puissant, des tanins souples ou
/// fermes, sans bois ou boisé.
///
/// Un curseur qu'on n'a pas touché ne dit rien : il n'est pas déclaré. Les six d'avant
/// (dont le fruit et la minéralité) déclaraient tout, même ce que personne n'avait dit.
class PalaisSaisi {
  /// Ce que la personne a dit, axe par axe (clés de [AxesDuPalais]), de 0 à 10.
  final Map<String, double> dits;

  /// « Rouge », « Blanc », « Rosé », « Bulles » — le vocabulaire du moteur de consensus.
  final Set<String> couleurs;

  /// « tanin », « boisé », « acide », « sucré » — les aversions que le moteur sait lire.
  final Set<String> aversions;

  const PalaisSaisi({this.dits = const {}, this.couleurs = const {}, this.aversions = const {}});

  /// Où se tient un curseur que personne n'a touché : ce qu'on boit d'ordinaire.
  static const departs = {
    AxesDuPalais.douceur: 1.5,
    AxesDuPalais.fraicheur: 5.5,
    AxesDuPalais.corps: 5.0,
    AxesDuPalais.tanins: 5.0,
    AxesDuPalais.boise: 3.0,
  };

  double valeur(String axe) => dits[axe] ?? departs[axe] ?? 5.0;

  /// Les curseurs, dans l'ordre où on les pose : chacun entre ses deux bouts, en mots de
  /// tous les jours.
  static List<(String, String, String)> curseurs(bool fr) => [
        (AxesDuPalais.douceur, trSi(fr, 'Sec', 'Dry'), trSi(fr, 'Doux', 'Sweet')),
        (AxesDuPalais.fraicheur, trSi(fr, 'Rond', 'Soft'), trSi(fr, 'Vif', 'Crisp')),
        (AxesDuPalais.corps, trSi(fr, 'Léger', 'Light'), trSi(fr, 'Puissant', 'Full')),
        (AxesDuPalais.tanins, trSi(fr, 'Tanins souples', 'Soft tannins'), trSi(fr, 'Tanins fermes', 'Firm tannins')),
        (AxesDuPalais.boise, trSi(fr, 'Sans bois', 'Unoaked'), trSi(fr, 'Boisé', 'Oaky')),
      ];

  PalaisSaisi avec(String axe, double v) => copie(dits: {...dits, axe: v});

  PalaisSaisi copie({Map<String, double>? dits, Set<String>? couleurs, Set<String>? aversions}) => PalaisSaisi(
        dits: dits ?? this.dits,
        couleurs: couleurs ?? this.couleurs,
        aversions: aversions ?? this.aversions,
      );

  /// Le radar des versions d'avant, pour un hôte qui ne lit pas encore les palais par
  /// famille.
  WineTasteRadarMetrics get radar => WineTasteRadarMetrics(
        tannin: valeur(AxesDuPalais.tanins),
        body: valeur(AxesDuPalais.corps),
        oak: valeur(AxesDuPalais.boise),
        ripeFruit: 5,
        spice: 4,
        freshFruit: 5,
        minerality: 5,
        acidity: valeur(AxesDuPalais.fraicheur),
      );

  /// Ce qui a été dit, pour chaque famille : un axe déclaré compte pleinement, comme à
  /// table avant ; un axe tu reste inconnu.
  Map<String, PalaisDeFamille> get palaisParFamille => {
        for (final f in FamillesDeVins.toutes)
          f: PalaisDeFamille(
            famille: f,
            valeurs: {for (final a in AxesDuPalais.de(f)) a: dits[a] ?? AxesDuPalais.neutre(f, a)},
            confiance: {for (final a in dits.keys) if (AxesDuPalais.deLaFamille(f, a)) a: 1.0},
            connus: {for (final a in dits.keys) if (AxesDuPalais.deLaFamille(f, a)) a},
          ),
      };

  String archetype(bool fr) {
    final douceur = valeur(AxesDuPalais.douceur);
    final fraicheur = valeur(AxesDuPalais.fraicheur);
    final corps = valeur(AxesDuPalais.corps);
    final tanins = valeur(AxesDuPalais.tanins);
    if (aversions.contains('tanin')) return trSi(fr, 'Aversion aux tanins durs', 'Dislikes firm tannins');
    if (douceur >= 4) return trSi(fr, 'Blancs tendres ou doux', 'Off-dry and sweet whites');
    if (tanins >= 7 && corps >= 6) return trSi(fr, 'Grands Rouges Puissants', 'Big, powerful reds');
    if (fraicheur >= 7 && corps <= 4.5) return trSi(fr, 'Blancs Minéraux & Tendus', 'Taut, mineral whites');
    if (fraicheur >= 6.5 && tanins <= 4.5 && corps <= 5.5) return trSi(fr, 'Rouges Fruits Croquants', 'Crunchy fruity reds');
    return trSi(fr, 'Curieux & Éclectique', 'Curious & eclectic');
  }

  GuestProfile versConvive({required String id, required String nom, required bool fr}) => GuestProfile(
        id: id,
        name: nom,
        favoriteTypes: couleurs.toList(),
        dislikedCharacteristics: aversions.toList(),
        archetype: archetype(fr),
        radarDistant: radar,
        palaisDistants: dits.isEmpty ? null : palaisParFamille,
      );

  /// Les points de départ proposés, pour aller plus vite que cinq curseurs.
  static const prereglages = <String, PalaisSaisi>{
    'sans_tanin': PalaisSaisi(
      dits: {'sweetness': 1.5, 'acidity': 6, 'body': 4, 'tannin': 2, 'oak': 2},
      couleurs: {'Blanc', 'Rosé'},
      aversions: {'tanin'},
    ),
    'mineral': PalaisSaisi(dits: {'sweetness': 1, 'acidity': 8, 'body': 3.5, 'tannin': 3, 'oak': 1}, couleurs: {'Blanc'}),
    'tendre': PalaisSaisi(dits: {'sweetness': 6, 'acidity': 6, 'body': 5, 'tannin': 4, 'oak': 2}, couleurs: {'Blanc'}),
    'puissant': PalaisSaisi(dits: {'sweetness': 0.5, 'acidity': 5, 'body': 8, 'tannin': 8, 'oak': 6}, couleurs: {'Rouge'}),
    'fruit': PalaisSaisi(dits: {'sweetness': 1, 'acidity': 7, 'body': 4.5, 'tannin': 4, 'oak': 1.5}, couleurs: {'Rouge'}),
    'equilibre': PalaisSaisi(),
  };
}
