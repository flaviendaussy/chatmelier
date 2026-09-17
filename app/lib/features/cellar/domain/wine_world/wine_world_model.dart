import '../aging_reference.dart';

// Les fichiers de régions décrivent des longévités : leur donner `AgingProfile` évite
// de leur imposer un second import qui n'apporte rien.
export '../aging_reference.dart' show AgingProfile, WineTier;

/// D'où vient une fenêtre de garde, et donc quel crédit lui accorder.
enum Certitude {
  /// Vérifiée contre une source externe. Réservée aux cas où l'erreur coûte cher.
  verifiee,

  /// Estimée à partir de la connaissance de la catégorie. Le cas de la majorité.
  estimee,
}

/// Pourquoi une référence figure dans la base.
///
/// Les deux critères sont différents et se cumulent rarement : on veut couvrir les vins
/// dont l'erreur DÉÇOIT (un Yquem daté comme un moelleux courant) et ceux qui sont
/// SCANNÉS en masse (un Casillero del Diablo, vendu par millions). Un Pétrus est rarement
/// scanné ; un Yellow Tail l'est tous les jours.
enum RaisonDePresence {
  /// Grand vin : se tromper déçoit durablement.
  grandVin,

  /// Gros volume : se tromper se produit souvent.
  grandVolume,

  /// Les deux à la fois.
  lesDeux,
}

/// Contenant dans lequel un vin est élevé.
///
/// Le matériau change le vin plus que la durée : douze mois en barrique neuve marquent
/// bien davantage que vingt-quatre en foudre. C'est pour cela qu'on stocke les deux.
enum ContenantElevage {
  /// Cuve inox : aucun apport, on cherche le fruit.
  inox,

  /// Béton, brut ou revêtu : micro-oxygénation sans goût boisé.
  beton,

  /// Barrique (225 L environ) : l'apport boisé le plus marqué.
  barrique,

  /// Foudre, demi-muid, grand fût : bois discret, oxygénation lente.
  foudre,

  /// Amphore, dolia, jarre : terre cuite, micro-oxygénation sans bois.
  amphore,

  /// Œuf de béton ou de grès.
  oeuf,

  /// Bouteille : l'élevage se fait après tirage, cas des effervescents.
  bouteille,
}

/// L'élevage d'un vin : où, et combien de temps.
///
/// **Souvent imposé par l'appellation.** Un Barolo doit passer dix-huit mois sous bois,
/// un Rioja Crianza douze, un Brunello vingt-quatre. Cette obligation légale est une
/// source de données déterministe et gratuite : là où l'enrichissement ne dit rien, le
/// cahier des charges, lui, est connu.
class Elevage {
  final ContenantElevage contenant;

  /// Durée en mois. Quand l'appellation impose un minimum, c'est ce minimum qui figure
  /// ici — la valeur réelle d'un domaine donné peut être plus longue.
  final int mois;

  /// Vrai quand la durée vient d'un cahier des charges plutôt que d'une estimation.
  final bool impose;

  const Elevage(this.contenant, this.mois, {this.impose = false});

  bool get sousBois =>
      contenant == ContenantElevage.barrique || contenant == ContenantElevage.foudre;
}

/// Un domaine ou une cuvée nommée, dont la longévité s'écarte de sa catégorie.
///
/// C'est ce qui règle le cas Terrebrune : la catégorie « Bandol rosé » donne quatorze
/// ans, mais ce domaine précis en tient vingt. Sans ce niveau, on ne peut que décrire
/// des moyennes.
class ReferenceVin {
  final String nom;

  /// Variantes d'écriture rencontrées sur les étiquettes et dans les scans.
  final List<String> alias;

  /// Surcharge la longévité de la région. Nulle si le domaine suit sa catégorie et
  /// n'est là que pour être reconnu.
  final AgingProfile? longevite;

  final RaisonDePresence raison;
  final Certitude certitude;

  /// Surcharge l'élevage de la région, quand le domaine s'en écarte notablement.
  final Elevage? elevage;

  const ReferenceVin({
    required this.nom,
    this.alias = const [],
    this.longevite,
    this.raison = RaisonDePresence.grandVin,
    this.certitude = Certitude.estimee,
    this.elevage,
  });
}

/// Une région viticole, avec tout ce qu'on en sait.
///
/// **Une seule base pour tous les usages.** Il existait déjà `TerroirGISCatalog`
/// (géographie, sol, climat) et `AgingReference` (longévité) décrivant les mêmes régions
/// pour des besoins différents. Deux tables sur le même sujet divergent toujours : celle
/// qu'on met à jour et l'autre. Les usages deviennent des vues sur cette base-ci.
class RegionVin {
  final String id;
  final String pays;
  final String nom;
  final List<String> alias;

  /// Longévité par couleur : 'red', 'white', 'rose', 'sparkling', 'sweet', 'fortified'.
  /// La clé `'*'` sert de valeur par défaut quand une couleur n'est pas précisée.
  final Map<String, AgingProfile> longevites;

  final List<String> cepages;
  final List<ReferenceVin> references;

  /// Élevage typique de la région, par couleur. Clé `'*'` par défaut.
  final Map<String, Elevage> elevages;

  const RegionVin({
    required this.id,
    required this.pays,
    required this.nom,
    this.alias = const [],
    required this.longevites,
    this.cepages = const [],
    this.references = const [],
    this.elevages = const {},
  });

  Elevage? elevagePour(String couleur) => elevages[couleur] ?? elevages['*'];

  AgingProfile? longevitePour(String couleur) =>
      longevites[couleur] ?? longevites['*'];
}

/// Raccourci d'écriture : les profils sont nombreux et toujours faits des mêmes bornes.
AgingProfile prof(String id, String libelle, int d, int pd, int pf, int f) =>
    AgingProfile(
      id: id,
      libelle: libelle,
      debut: d,
      picDebut: pd,
      picFin: pf,
      fin: f,
    );
