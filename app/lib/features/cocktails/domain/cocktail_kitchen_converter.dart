/// 🥄 Culinary conversion and kitchen DIY alternatives for cocktail crafting
class CocktailKitchenConverter {
  /// Converts a standard cocktail dose (in cl or ml) into friendly kitchen measurements
  static String getKitchenEquivalent(double? amount, String? unit) {
    if (amount == null || unit == null) return '';
    final u = unit.toLowerCase().trim();
    double cl = 0;
    if (u == 'cl') {
      cl = amount;
    } else if (u == 'ml') {
      cl = amount / 10.0;
    } else {
      return '';
    }

    if (cl <= 0.5) return '≈ 1 c.à.café';
    if (cl <= 1.0) return '≈ 2 c.à.café';
    if (cl <= 1.8) return '≈ 1 c.à.soupe';
    if (cl <= 2.5) return '≈ 1,5 c.à.soupe';
    if (cl <= 3.4) return '≈ 2 c.à.soupe (ou 1 shooter)';
    if (cl <= 4.0) return '≈ 2,5 c.à.soupe';
    if (cl <= 5.0) return '≈ 3 c.à.soupe';
    if (cl <= 6.4) return '≈ 4 c.à.soupe (ou 2 shooters)';
    if (cl <= 7.5) return '≈ 5 c.à.soupe';
    if (cl <= 9.0) return '≈ 6 c.à.soupe';
    if (cl <= 12.5) return '≈ 1/2 grand verre d\'eau';
    if (cl <= 20.0) return '≈ 1 verre d\'eau standard';
    return '≈ ${cl.toStringAsFixed(cl % 1 == 0 ? 0 : 1)} cl';
  }

  /// Adapts standard shaker instructions into friendly kitchen jar / DIY steps
  static List<String> adaptShakerInstructionsForKitchenJar(List<String> originalSteps) {
    return originalSteps.map((step) {
      var s = step;
      // Replace shaker mentions with hermetic jar
      s = s.replaceAll(
        RegExp(r'shaker', caseSensitive: false),
        'bocal hermétique (ou shaker de sport)',
      );
      // Replace strainer mentions with tea strainer
      s = s.replaceAll(
        RegExp(r'passoire à cocktail|strainer', caseSensitive: false),
        'passoire à thé (ou couvercle entrouvert)',
      );
      return s;
    }).toList();
  }
}
