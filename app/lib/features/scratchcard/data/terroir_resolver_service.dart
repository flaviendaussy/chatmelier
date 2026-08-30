import '../domain/terroir_gis_catalog.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../../journal/domain/tasting_entry.dart';

class ResolvedTerroirNode {
  final TerroirGISNode node;
  final List<Bottle> ownedBottles;
  final List<TastingEntry> tastings;
  final int ownedCount;
  final int drunkCount;
  final String? topWine;

  const ResolvedTerroirNode({
    required this.node,
    required this.ownedBottles,
    required this.tastings,
    required this.ownedCount,
    required this.drunkCount,
    this.topWine,
  });

  bool get isOwned => ownedCount > 0;
  bool get isDrunk => drunkCount > 0;
  bool get isUnlocked => isOwned || isDrunk;
  bool get isMastered => isOwned && isDrunk;
}

class TerroirResolverService {
  static String normalize(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ÿ]'), 'y')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Evaluates whether a bottle or wine matches a specific TerroirGISNode
  static bool matchesTerroir(
    TerroirGISNode node, {
    Wine? wine,
    String? rawAppellation,
    String? rawRegion,
    String? rawCountry,
    String? rawName,
    String? rawProducer,
  }) {
    final app = normalize(wine?.appellation ?? rawAppellation ?? '');
    final reg = normalize(wine?.region ?? rawRegion ?? '');
    final sub = normalize(wine?.subRegion ?? '');
    final ctry = normalize(wine?.country ?? rawCountry ?? '');
    final name = normalize(wine?.name ?? rawName ?? '');
    final prod = normalize(wine?.producer ?? rawProducer ?? '');
    final cuvee = normalize(wine?.cuveeParcel ?? '');

    final fullSearchCorpus = '$app $sub $reg $ctry $name $prod $cuvee';

    // Check aliases
    for (final rawAlias in node.aliases) {
      final alias = normalize(rawAlias);
      if (alias.isEmpty) continue;

      // Exact match in appellation or subRegion (highest confidence)
      if (app.isNotEmpty && (app == alias || app.contains(alias) || alias.contains(app))) {
        return true;
      }
      if (sub.isNotEmpty && (sub == alias || sub.contains(alias))) {
        return true;
      }
      if (reg.isNotEmpty && (reg == alias || reg.contains(alias))) {
        return true;
      }

      // Match in full name or producer if multi-word keyword
      if (alias.length >= 4 && fullSearchCorpus.contains(alias)) {
        return true;
      }
    }

    return false;
  }

  /// Resolves all catalog nodes against current cellar bottles and journal tastings
  static List<ResolvedTerroirNode> resolveAll({
    required List<Bottle> bottles,
    required List<TastingEntry> tastings,
  }) {
    final List<ResolvedTerroirNode> results = [];

    for (final node in TerroirGISCatalog.nodes) {
      final List<Bottle> matchedBottles = [];
      final List<TastingEntry> matchedTastings = [];

      for (final bottle in bottles) {
        final w = bottle.wine;
        if (matchesTerroir(
          node,
          wine: w,
          rawAppellation: w?.appellation,
          rawRegion: w?.region,
          rawCountry: w?.country,
          rawName: w?.name,
          rawProducer: w?.producer,
        )) {
          matchedBottles.add(bottle);
        }
      }

      for (final tasting in tastings) {
        if (matchesTerroir(
          node,
          rawAppellation: tasting.appellation,
          rawRegion: tasting.region,
          rawCountry: tasting.country,
          rawName: tasting.wineName,
        )) {
          matchedTastings.add(tasting);
        }
      }

      final ownedCount = matchedBottles.fold<int>(0, (sum, b) => sum + b.quantity);
      final drunkCount = matchedTastings.length;

      String? topWine;
      if (matchedTastings.isNotEmpty) {
        // Sort tastings by rating descending
        final sortedTastings = List<TastingEntry>.from(matchedTastings)
          ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        topWine = (sortedTastings.first.wineName ?? '').trim();
      } else if (matchedBottles.isNotEmpty) {
        topWine = '${matchedBottles.first.wine?.producer ?? ""} ${matchedBottles.first.wine?.name ?? ""}'.trim();
      }

      results.add(ResolvedTerroirNode(
        node: node,
        ownedBottles: matchedBottles,
        tastings: matchedTastings,
        ownedCount: ownedCount,
        drunkCount: drunkCount,
        topWine: (topWine != null && topWine.isNotEmpty) ? topWine : null,
      ));
    }

    return results;
  }
}
