import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../../cellar/domain/wine_food_matcher.dart';

class RagSearchResult {
  final List<Bottle> selectedBottles;
  final String formattedContext;

  const RagSearchResult({
    required this.selectedBottles,
    required this.formattedContext,
  });
}

/// Instant local RAG retriever for Chatmelier.
/// Selects the 5 to 8 most relevant bottles based on dish pairing, style, appellation,
/// and maturity context, avoiding the need to inject the full cellar into LLM prompts.
class CellarRagRetriever {
  static const int defaultMaxBottles = 7;

  /// Retrieves relevant bottles and formats a high-density, low-token context block.
  static RagSearchResult retrieve({
    required String query,
    required List<Bottle> bottles,
    int maxBottles = defaultMaxBottles,
    String languageCode = 'fr',
  }) {
    final activeBottles = bottles.where((b) => !b.isConsumed).toList();
    if (activeBottles.isEmpty) {
      return const RagSearchResult(
        selectedBottles: [],
        formattedContext: 'No bottles in cellar.',
      );
    }

    final queryNorm = query.toLowerCase().trim();
    final isEn = languageCode.toLowerCase().startsWith('en');

    // 1. Try food pairing engine first
    final foodMatches = WineFoodMatcher.findMatches(
      bottles: activeBottles,
      dishQuery: query,
      lang: languageCode,
      minScore: 55,
    );

    final Map<String, double> scores = {};

    // Base score from food pairing engine
    for (final fm in foodMatches) {
      scores[fm.bottle.id] = (fm.score.toDouble()) + 50.0;
    }

    // 2. Keyword & semantic matching for wine attributes
    final queryTokens = queryNorm.split(RegExp(r'''[\s,.;:!?\-_/'"“”]+''')).where((t) => t.length >= 3).toList();

    for (final b in activeBottles) {
      final w = b.wine;
      if (w == null) continue;

      double score = scores[b.id] ?? 0.0;

      // Bonus if wine is at peak drinking maturity
      if (w.windowStatus == DrinkWindowStatus.inPeak) {
        score += 15.0;
        if (queryNorm.contains('apogée') || queryNorm.contains('prêt') || queryNorm.contains('ready') || queryNorm.contains('ce soir')) {
          score += 25.0;
        }
      } else if (w.windowStatus == DrinkWindowStatus.drinkSoon || w.windowStatus == DrinkWindowStatus.pastPeak) {
        if (queryNorm.contains('urgent') || queryNorm.contains('boire vite') || queryNorm.contains('dépass')) {
          score += 40.0;
        }
      }

      // Color/type matching
      if (queryNorm.contains('rouge') || queryNorm.contains('red')) {
        if (w.type == 'red') score += 30.0;
      }
      if (queryNorm.contains('blanc') || queryNorm.contains('white')) {
        if (w.type == 'white') score += 30.0;
      }
      if (queryNorm.contains('rosé') || queryNorm.contains('rose')) {
        if (w.type == 'rosé') score += 30.0;
      }
      if (queryNorm.contains('champagne') || queryNorm.contains('bulle') || queryNorm.contains('effervescent') || queryNorm.contains('sparkling')) {
        if (w.type == 'sparkling' || w.name.toLowerCase().contains('champagne')) score += 35.0;
      }
      if (queryNorm.contains('spiritueux') || queryNorm.contains('whisky') || queryNorm.contains('rhum') || queryNorm.contains('gin') || queryNorm.contains('digestif') || queryNorm.contains('cocktail')) {
        if (w.isSpirit) score += 35.0;
      }

      // Token match on name, producer, appellation, region, grapes
      final textCorpus = '${w.name} ${w.producer ?? ""} ${w.appellation ?? ""} ${w.region} ${w.cuveeParcel ?? ""} ${w.grapes.map((g) => g.name).join(" ")} ${w.tastingNotes ?? ""} ${w.foodPairings.join(" ")}'.toLowerCase();

      for (final t in queryTokens) {
        if (textCorpus.contains(t)) {
          score += 20.0;
        }
      }

      if (score > 0) {
        scores[b.id] = score;
      }
    }

    List<Bottle> chosen;

    if (scores.isNotEmpty) {
      final sortedEntries = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final chosenIds = sortedEntries.take(maxBottles).map((e) => e.key).toSet();
      chosen = activeBottles.where((b) => chosenIds.contains(b.id)).toList();
      // Keep sort order by score
      chosen.sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));
    } else {
      // Fallback for generic conversational queries:
      // Pick a balanced, diverse curated set (peaks, top rated, white & red)
      final peaks = activeBottles.where((b) => b.wine?.windowStatus == DrinkWindowStatus.inPeak).take(3).toList();
      final others = activeBottles.where((b) => !peaks.contains(b)).take(maxBottles - peaks.length).toList();
      chosen = [...peaks, ...others];
    }

    if (chosen.isEmpty) {
      chosen = activeBottles.take(maxBottles).toList();
    }

    // Format selected candidate bottles concisely for LLM context
    final buffer = StringBuffer();
    if (isEn) {
      buffer.writeln('=== CANDIDATE BOTTLES RETRIEVED VIA RAG (${chosen.length} matches selected from cellar) ===');
    } else {
      buffer.writeln('=== BOUTEILLES CANDIDATES SÉLECTIONNÉES PAR LE RAG (${chosen.length} références pertinentes) ===');
    }

    for (int i = 0; i < chosen.length; i++) {
      final b = chosen[i];
      final w = b.wine;
      final grapesStr = (w?.grapes != null && w!.grapes.isNotEmpty)
          ? ' [Cépages: ${w.grapes.map((g) => "${g.name}${g.pct != null ? " ${g.pct}%" : ""}").join(", ")}]'
          : '';
      final rackPart = b.rack != null && b.rack!.isNotEmpty
          ? (b.rack!.toLowerCase().startsWith('casier') ? b.rack! : 'Casier ${b.rack}')
          : null;
      final shelfPart = b.shelf != null && b.shelf!.isNotEmpty
          ? (b.shelf!.toLowerCase().startsWith('étagère') || b.shelf!.toLowerCase().startsWith('etagere') || b.shelf!.toLowerCase().startsWith('shelf')
              ? b.shelf!
              : 'Étagère ${b.shelf}')
          : null;
      final posPart = b.position != null && b.position!.isNotEmpty
          ? (b.position!.toLowerCase().startsWith('pos') ? b.position! : 'Pos ${b.position}')
          : null;
      final locList = [rackPart, shelfPart, posPart].whereType<String>().toList();
      final loc = locList.isNotEmpty ? 'Emplacement: ${locList.join(", ")}' : 'Emplacement: -';
      final notes = (w?.tastingNotes != null && w!.tastingNotes!.isNotEmpty) ? ' • Profil: "${w.tastingNotes}"' : '';
      final status = w?.windowStatus.name ?? 'unknown';

      buffer.writeln('${i + 1}. [ID: ${b.id}] "${w?.name ?? "Vin"}" (${w?.vintage ?? "NM"}) - ${w?.producer ?? ""} • ${w?.type ?? "red"} - ${w?.appellation ?? w?.region ?? ""}$grapesStr');
      buffer.writeln('   $loc • Statut: $status • Dispo: ${b.quantity} btl$notes');
    }

    return RagSearchResult(
      selectedBottles: chosen,
      formattedContext: buffer.toString().trim(),
    );
  }

  /// Convenience alias for food pairing / conversational queries
  static RagSearchResult retrieveRelevantBottles({
    required String userMessage,
    required List<Bottle> bottles,
    int maxBottles = defaultMaxBottles,
    String languageCode = 'fr',
  }) {
    return retrieve(
      query: userMessage,
      bottles: bottles,
      maxBottles: maxBottles,
      languageCode: languageCode,
    );
  }
}
