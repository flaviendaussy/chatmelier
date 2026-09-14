import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';

/// Generates a high-density, low-token macro summary of the user's cellar inventory.
/// Exposes structured metadata (proportions by color, top appellations, drinking status).
class CellarMacroSummary {
  /// Builds a concise textual summary suitable for LLM system instructions (~120-180 tokens).
  static String generate(List<Bottle> bottles, {String languageCode = 'fr'}) {
    final activeBottles = bottles.where((b) => !b.isConsumed).toList();
    if (activeBottles.isEmpty) {
      return languageCode == 'en'
          ? 'Cellar is currently empty (0 bottles).'
          : 'La cave est actuellement vide (0 bouteille).';
    }

    int totalBottlesCount = 0;
    double totalEstimatedValue = 0.0;
    int readyCount = 0;
    int agingCount = 0;
    int urgentCount = 0;

    // Grouping by type
    final Map<String, List<Bottle>> byType = {};

    for (final b in activeBottles) {
      final qty = b.quantity;
      totalBottlesCount += qty;
      final wine = b.wine;
      if (wine != null) {
        if (wine.estimatedMarketValue != null) {
          totalEstimatedValue += wine.estimatedMarketValue! * qty;
        }

        switch (wine.windowStatus) {
          case DrinkWindowStatus.inPeak:
            readyCount += qty;
            break;
          case DrinkWindowStatus.tooYoung:
          case DrinkWindowStatus.aging:
            agingCount += qty;
            break;
          case DrinkWindowStatus.drinkSoon:
          case DrinkWindowStatus.pastPeak:
            urgentCount += qty;
            break;
        }

        final typeKey = wine.isSpirit ? 'spirit' : (wine.type.isNotEmpty ? wine.type.toLowerCase() : 'red');
        byType.putIfAbsent(typeKey, () => []).add(b);
      }
    }

    final isEn = languageCode.toLowerCase().startsWith('en');
    final buffer = StringBuffer();

    if (isEn) {
      buffer.writeln('=== CELLAR MACRO METADATA (GLOBAL INVENTORY SUMMARY) ===');
      buffer.writeln('Total in Cellar: $totalBottlesCount bottles (${activeBottles.length} references)'
          '${totalEstimatedValue > 0 ? " • Estimated market value: ~${totalEstimatedValue.round()}€" : ""}');
      buffer.writeln('Maturity Breakdown: $readyCount at peak maturity (drink now), $agingCount aging/cellaring, $urgentCount drink urgently.');
    } else {
      buffer.writeln('=== RÉSUMÉ MACRO DE LA CAVE (METADATA GLOBALES & STATISTIQUES) ===');
      buffer.writeln('Total en cave : $totalBottlesCount bouteilles (${activeBottles.length} références)'
          '${totalEstimatedValue > 0 ? " • Valeur estimée : ~${totalEstimatedValue.round()} €" : ""}');
      buffer.writeln('Statut de garde : $readyCount à leur apogée (prêts à boire), $agingCount de garde/vieillissement, $urgentCount à boire rapidement.');
    }

    // Type display order & labels
    final typeOrder = ['red', 'white', 'rosé', 'sparkling', 'dessert', 'fortified', 'orange', 'spirit'];
    for (final type in typeOrder) {
      final list = byType[type];
      if (list == null || list.isEmpty) continue;

      final typeCount = list.fold<int>(0, (sum, b) => sum + b.quantity);
      final label = _formatTypeLabel(type, isEn);

      // Sub-breakdown by Appellation or Region
      final Map<String, int> subCounts = {};
      for (final b in list) {
        final w = b.wine;
        final app = (w?.appellation != null && w!.appellation!.trim().isNotEmpty)
            ? w.appellation!.trim()
            : ((w?.region != null && w!.region.trim().isNotEmpty) ? w.region.trim() : (isEn ? 'Other' : 'Autres'));
        subCounts[app] = (subCounts[app] ?? 0) + b.quantity;
      }

      final sortedSubs = subCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topSubs = sortedSubs.take(4).map((e) => '${e.key} (${e.value})').toList();
      final remaining = sortedSubs.skip(4).fold<int>(0, (sum, e) => sum + e.value);
      if (remaining > 0) {
        topSubs.add('${isEn ? "Others" : "Autres"} ($remaining)');
      }

      buffer.writeln('- $label ($typeCount) : ${topSubs.join(", ")}');
    }

    return buffer.toString().trim();
  }

  static String _formatTypeLabel(String type, bool isEn) {
    switch (type) {
      case 'red':
        return isEn ? '🍷 Reds' : '🍷 Rouges';
      case 'white':
        return isEn ? '🥂 Whites' : '🥂 Blancs';
      case 'rosé':
        return isEn ? '🌸 Rosés' : '🌸 Rosés';
      case 'sparkling':
        return isEn ? '🍾 Sparkling / Champagne' : '🍾 Effervescents & Champagnes';
      case 'dessert':
        return isEn ? '🍯 Dessert & Sweet' : '🍯 Moelleux & Liquoreux';
      case 'fortified':
        return isEn ? '🍇 Fortified (Port/Sherry)' : '🍇 Vins Mutés (Porto/Banyuls)';
      case 'orange':
        return isEn ? '🍊 Orange / Maceration' : '🍊 Vins Orange / Macération';
      case 'spirit':
        return isEn ? '🥃 Spirits & Bar' : '🥃 Spiritueux & Bar';
      default:
        return type;
    }
  }
}
