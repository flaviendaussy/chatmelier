import '../../scratchcard/data/terroir_resolver_service.dart';
import '../../scratchcard/domain/terroir_gis_catalog.dart';

/// Une contradiction entre ce que dit le NOM d'un vin et la région que l'enrichissement
/// lui a attribuée.
class RegionContradiction {
  /// L'indice trouvé dans le nom (« jura », « chablis »…).
  final String indiceDuNom;

  /// Le terroir que ce nom désigne.
  final TerroirGISNode terroirDuNom;

  /// Le terroir auquel la région enrichie renvoie.
  final TerroirGISNode terroirEnrichi;

  const RegionContradiction({
    required this.indiceDuNom,
    required this.terroirDuNom,
    required this.terroirEnrichi,
  });

  /// Question à poser à la seconde source. Volontairement fermée et vérifiable.
  String get questionDeVerification =>
      'De quelle région viticole vient exactement le vin nommé « $indiceDuNom » ? '
      'Réponds par la région et l\'appellation officielles.';

  @override
  String toString() =>
      'nom → ${terroirDuNom.name} (via « $indiceDuNom ») ≠ enrichi → ${terroirEnrichi.name}';
}

/// Repère les cas où l'enrichissement s'est manifestement trompé de région.
///
/// Motivé par une remontée utilisateur : un **Crémant du Jura** affichait « Pauillac &
/// Haut-Médoc » comme terroir. Le résolveur de terroir est innocent — testé, il place
/// correctement ce vin dans le Jura — c'est la région STOCKÉE qui était fausse, écrite
/// par l'enrichissement IA. Le nom, lui, était resté juste.
///
/// D'où la règle : **quand le nom d'un vin nomme lui-même une région, il fait autorité
/// contre une région enrichie qui le contredit.** Un producteur n'appelle pas son vin
/// « Crémant du Jura » s'il vient du Médoc.
///
/// La détection est **entièrement locale** : elle réutilise les alias du catalogue de
/// terroirs, déjà présents. C'est ce qui rend abordable la vérification par seconde
/// source, qui, elle, coûte cher — voir [GroundedVerificationBudget].
class RegionContradictionDetector {
  /// Longueur minimale d'un alias pour être pris comme indice.
  ///
  /// Quatre, parce que c'est la longueur des noms de région les plus courts du
  /// catalogue — `jura`, `napa`, `alba`, `etna`, `toro` — et que les exclure reviendrait
  /// à ne jamais attraper le cas qui a motivé tout ceci, un Crémant du Jura. En dessous
  /// de quatre, on n'attraperait plus que du bruit.
  ///
  /// Ce n'est pas ce seuil qui tient la rareté : c'est la correspondance sur mot entier,
  /// puis [memeGrandeRegion], puis le budget.
  static const int longueurMinimaleIndice = 4;

  /// Renvoie la contradiction, ou nul — ce qui doit être le cas courant.
  static RegionContradiction? detecter({
    required String nomDuVin,
    String? regionEnrichie,
    String? appellationEnrichie,
  }) {
    final nom = TerroirResolverService.normalize(nomDuVin);
    if (nom.isEmpty) return null;

    final regionBrute = [regionEnrichie, appellationEnrichie]
        .whereType<String>()
        .where((r) => r.trim().isNotEmpty)
        .join(' ');
    if (regionBrute.trim().isEmpty) return null;

    final depuisNom = _noeudEtIndice(nom);
    if (depuisNom == null) return null;

    final depuisRegion = _noeudPour(TerroirResolverService.normalize(regionBrute));
    if (depuisRegion == null) return null;

    if (depuisNom.$1.id == depuisRegion.id) return null;

    // Deux sous-zones d'une même grande région ne se contredisent pas, elles se
    // voisinent : un Chablis enrichi « Bourgogne » tombe sur le nœud Côte de Nuits, ce
    // qui n'est pas une erreur mais une imprécision. Quatre nœuds partagent
    // « Bourgogne », trois « Bordeaux », deux « Vallée du Rhône ». Sans ce filtre, ces
    // vins déclencheraient une vérification payante pour rien — et ils sont nombreux.
    if (memeGrandeRegion(depuisNom.$1, depuisRegion)) return null;

    return RegionContradiction(
      indiceDuNom: depuisNom.$2,
      terroirDuNom: depuisNom.$1,
      terroirEnrichi: depuisRegion,
    );
  }

  /// Deux nœuds appartiennent-ils à la même grande région viticole ?
  static bool memeGrandeRegion(TerroirGISNode a, TerroirGISNode b) =>
      a.region.trim().toLowerCase() == b.region.trim().toLowerCase() &&
      a.countryCode == b.countryCode;

  /// Le nœud désigné par un texte, et l'alias qui l'a désigné.
  ///
  /// Exige une correspondance sur un MOT ENTIER : sans ça, « graves » se déclencherait
  /// sur « Graves de Vayres » et l'alias « medoc » sur n'importe quel « Médocain ».
  static (TerroirGISNode, String)? _noeudEtIndice(String texteNormalise) {
    final mots = texteNormalise.split(' ').where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return null;

    (TerroirGISNode, String)? meilleur;
    var meilleureLongueur = 0;

    for (final noeud in TerroirGISCatalog.nodes) {
      for (final aliasBrut in noeud.aliases) {
        final alias = TerroirResolverService.normalize(aliasBrut);
        if (alias.length < longueurMinimaleIndice) continue;
        if (!_contientMotsEntiers(mots, alias)) continue;
        // Le plus long alias gagne : « haut medoc » prime sur « medoc ».
        if (alias.length > meilleureLongueur) {
          meilleureLongueur = alias.length;
          meilleur = (noeud, aliasBrut);
        }
      }
    }
    return meilleur;
  }

  static TerroirGISNode? _noeudPour(String texteNormalise) {
    final r = _noeudEtIndice(texteNormalise);
    return r?.$1;
  }

  /// `alias` apparaît-il comme une suite de mots entiers dans `mots` ?
  static bool _contientMotsEntiers(List<String> mots, String alias) {
    final motsAlias = alias.split(' ').where((m) => m.isNotEmpty).toList();
    if (motsAlias.isEmpty || motsAlias.length > mots.length) return false;
    for (var i = 0; i <= mots.length - motsAlias.length; i++) {
      var ok = true;
      for (var j = 0; j < motsAlias.length; j++) {
        if (mots[i + j] != motsAlias[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }
}
