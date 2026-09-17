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
    final t = _norm('${nom ?? ''} ${producteur ?? ''}');
    if (t.isEmpty) return null;

    ReferenceVin? meilleure;
    var meilleureLongueur = 0;
    for (final r in regions) {
      for (final ref in r.references) {
        for (final cle in [ref.nom, ...ref.alias]) {
          final c = _norm(cle);
          // Au moins quatre caractères : en deçà, un fragment de nom de cuvée
          // déclencherait n'importe quoi.
          if (c.length < 4 || !t.contains(c)) continue;
          if (c.length > meilleureLongueur) {
            meilleureLongueur = c.length;
            meilleure = ref;
          }
        }
      }
    }
    return meilleure;
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
