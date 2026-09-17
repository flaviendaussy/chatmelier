import 'regions_europe.dart';
import 'regions_france.dart';
import 'regions_iberie.dart';
import 'regions_italie.dart';
import 'regions_nouveau_monde.dart';
import 'wine_world_model.dart';

export 'wine_world_model.dart';

/// La base des régions viticoles — une seule, pour tous les usages.
///
/// Elle remplace la dispersion précédente : `AgingReference` décrivait des longévités,
/// `TerroirGISCatalog` des géographies, et les deux parlaient des mêmes régions sans se
/// connaître. Deux tables sur le même sujet divergent toujours — celle qu'on met à jour,
/// et l'autre.
///
/// Le dosage suit deux critères, jamais la simple exhaustivité :
///
///  - **le coût de l'erreur** : se tromper sur un Yquem ou un Barolo déçoit durablement,
///    parce que ce sont des bouteilles qu'on garde et qu'on attend ;
///  - **la fréquence de l'erreur** : se tromper sur un Casillero del Diablo ou un
///    Marlborough Sauvignon se produit des milliers de fois, parce qu'ils sont scannés
///    des milliers de fois.
///
/// Un Pétrus est rarement scanné, un Yellow Tail l'est tous les jours : les deux ont leur
/// place ici, pour des raisons opposées.
class WineWorld {
  static const List<RegionVin> regions = [
    ...regionsFrance,
    ...regionsItalie,
    ...regionsIberie,
    ...regionsEurope,
    ...regionsNouveauMonde,
  ];

  static String _norm(String? s) => (s ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r"[^a-z0-9\s'-]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// La région qui correspond, du plus spécifique au plus général.
  ///
  /// L'ordre de déclaration vaut priorité : les fichiers listent les appellations
  /// nommées avant les mentions larges, faute de quoi un Morgon serait capturé par
  /// « Bourgogne » et un Koonunga Hill par « Barossa ».
  static RegionVin? region({
    String? pays,
    String? region,
    String? appellation,
    List<String> cepages = const [],
  }) {
    final app = _norm(appellation);
    final reg = _norm(region);
    final pay = _norm(pays);
    final ceps = cepages.map(_norm).toList();

    // 1. L'appellation, qui est le signal le plus précis.
    for (final r in regions) {
      if (app.isEmpty) break;
      if (r.alias.any((a) => app.contains(_norm(a)))) return r;
    }
    // 2. La région déclarée.
    for (final r in regions) {
      if (reg.isEmpty) break;
      if (r.alias.any((a) => reg.contains(_norm(a)))) return r;
    }
    // 3. Le cépage, qui trahit souvent l'origine à défaut de mieux.
    for (final r in regions) {
      if (ceps.isEmpty) break;
      if (r.cepages.any((c) => ceps.any((x) => x == _norm(c)))) {
        if (pay.isEmpty || _norm(r.pays).contains(pay) || pay.contains(_norm(r.pays))) {
          return r;
        }
      }
    }
    return null;
  }

  /// La référence nommée qui correspond à ce vin, s'il y en a une.
  ///
  /// C'est le niveau qui règle les cas où un domaine s'écarte de sa catégorie :
  /// « Bandol rosé » donne quatorze ans, Terrebrune en tient vingt.
  static ReferenceVin? reference({String? nom, String? producteur}) {
    // Le NOM du vin est cherché en premier, et il l'emporte sur le producteur.
    //
    // La spécificité n'est pas la longueur du libellé : « Domaine de La Tour du Bon »
    // fait vingt-cinq caractères et « En Sol » six, mais c'est la cuvée qui décrit le
    // vin. Cette cuvée est élevée en amphores quand le domaine élève en foudre — la
    // faire perdre au profit du nom de domaine donnait une réponse fausse.
    final parLeNom = _chercherDans(_norm(nom));
    if (parLeNom != null) return parLeNom;
    return _chercherDans(_norm(producteur));
  }

  static ReferenceVin? _chercherDans(String texte) {
    if (texte.isEmpty) return null;
    ReferenceVin? meilleure;
    var meilleureLongueur = 0;
    for (final r in regions) {
      for (final ref in r.references) {
        for (final cle in [ref.nom, ...ref.alias]) {
          final c = _norm(cle);
          // Au moins quatre caractères : en deçà, un fragment de nom de cuvée
          // déclencherait n'importe quoi.
          if (c.length < 4 || !texte.contains(c)) continue;
          // À champ égal, le libellé le plus long reste le plus précis :
          // « Penfolds Grange » avant « Penfolds ».
          if (c.length > meilleureLongueur) {
            meilleureLongueur = c.length;
            meilleure = ref;
          }
        }
      }
    }
    return meilleure;
  }

  /// L'élevage de ce vin : celui du domaine s'il est connu, sinon celui de sa région.
  ///
  /// Beaucoup d'appellations IMPOSENT une durée minimale — Barolo dix-huit mois sous
  /// bois, Brunello vingt-quatre, Rioja Crianza douze. Là où l'enrichissement ne dit
  /// rien, le cahier des charges, lui, est connu : c'est une source déterministe et
  /// gratuite, et `Elevage.impose` distingue le fait de l'estimation.
  static Elevage? elevage({
    String? pays,
    String? region,
    String? appellation,
    String? nom,
    String? producteur,
    String? type,
    List<String> cepages = const [],
  }) {
    final duDomaine = reference(nom: nom, producteur: producteur)?.elevage;
    if (duDomaine != null) return duDomaine;

    final r = WineWorld.region(
      pays: pays, region: region, appellation: appellation, cepages: cepages);
    return r?.elevagePour(_couleur(type));
  }

  static String _couleur(String? type) {
    final t = _norm(type);
    if (t.contains('fortifi') || t.contains('mute')) return 'fortified';
    if (t.contains('moelleux') ||
        t.contains('liquoreux') ||
        t.contains('sweet') ||
        t.contains('dessert')) {
      return 'sweet';
    }
    if (t.contains('bulle') || t.contains('sparkl') || t.contains('effervesc')) {
      return 'sparkling';
    }
    if (t.contains('ros')) return 'rose';
    if (t.contains('blanc') || t.contains('white')) return 'white';
    return 'red';
  }

  /// Combien de régions et de références, par pays. Sert au test de couverture.
  static Map<String, ({int regions, int references})> couverture() {
    final m = <String, ({int regions, int references})>{};
    for (final r in regions) {
      final actuel = m[r.pays] ?? (regions: 0, references: 0);
      m[r.pays] = (
        regions: actuel.regions + 1,
        references: actuel.references + r.references.length,
      );
    }
    return m;
  }
}
