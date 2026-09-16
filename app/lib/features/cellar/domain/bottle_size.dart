import 'package:flutter/material.dart';

/// Standard wine and spirit bottle formats / volumes with complete multilingual support
class BottleSize {
  final String code; // Standard storage key, e.g. '75cl', '1.5L', '37.5cl'
  final String labelFr; // French display label
  final String labelEn; // English display label
  final double volumeLiters;
  final String shortNameFr; // Compact pill badge in French
  final String shortNameEn; // Compact pill badge in English

  const BottleSize({
    required this.code,
    required this.labelFr,
    required this.labelEn,
    required this.volumeLiters,
    required this.shortNameFr,
    required this.shortNameEn,
  });

  /// Backward-compatible label defaulting to French
  String get label => labelFr;

  /// Backward-compatible shortName defaulting to French
  String get shortName => shortNameFr;

  /// Context-aware localized full label
  String localizedLabel(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return localizedLabelForLang(lang);
  }

  /// Explicit language-aware localized label
  String localizedLabelForLang(String? lang) {
    final isFr = (lang ?? 'fr').toLowerCase().startsWith('fr');
    return isFr ? labelFr : labelEn;
  }

  /// Context-aware localized short pill name
  String localizedShortName(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isFr = lang.toLowerCase().startsWith('fr');
    return isFr ? shortNameFr : shortNameEn;
  }

  static const String defaultCode = '75cl';

  static const List<BottleSize> standardSizes = [
    BottleSize(
      code: '37.5cl',
      labelFr: 'Demi-bouteille (37,5 cl)',
      labelEn: 'Half Bottle (375 ml)',
      volumeLiters: 0.375,
      shortNameFr: '37,5 cl',
      shortNameEn: '375 ml',
    ),
    BottleSize(
      code: '50cl',
      labelFr: 'Demi-litre / Pot (50 cl)',
      labelEn: 'Half Liter / Pot (500 ml)',
      volumeLiters: 0.5,
      shortNameFr: '50 cl',
      shortNameEn: '500 ml',
    ),
    BottleSize(
      code: '62cl',
      labelFr: 'Clavelin (Jura 62 cl)',
      labelEn: 'Clavelin (Jura 620 ml)',
      volumeLiters: 0.62,
      shortNameFr: '62 cl',
      shortNameEn: '620 ml',
    ),
    BottleSize(
      code: '75cl',
      labelFr: 'Bouteille standard (75 cl)',
      labelEn: 'Standard Bottle (750 ml)',
      volumeLiters: 0.75,
      shortNameFr: '75 cl',
      shortNameEn: '750 ml',
    ),
    BottleSize(
      code: '1.5L',
      labelFr: 'Magnum (1,5 L - 2 btl)',
      labelEn: 'Magnum (1.5 L - 2 btl)',
      volumeLiters: 1.5,
      shortNameFr: '1,5 L (Magnum)',
      shortNameEn: '1.5 L (Magnum)',
    ),
    BottleSize(
      code: '3L',
      labelFr: 'Jéroboam / Double Magnum (3 L - 4 btl)',
      labelEn: 'Jeroboam / Double Magnum (3 L - 4 btl)',
      volumeLiters: 3.0,
      shortNameFr: '3 L (Jéroboam)',
      shortNameEn: '3 L (Jeroboam)',
    ),
    BottleSize(
      code: '4.5L',
      labelFr: 'Réhoboam (4,5 L - 6 btl)',
      labelEn: 'Rehoboam (4.5 L - 6 btl)',
      volumeLiters: 4.5,
      shortNameFr: '4,5 L',
      shortNameEn: '4.5 L',
    ),
    BottleSize(
      code: '6L',
      labelFr: 'Mathusalem / Impériale (6 L - 8 btl)',
      labelEn: 'Methuselah / Imperial (6 L - 8 btl)',
      volumeLiters: 6.0,
      shortNameFr: '6 L (Impériale)',
      shortNameEn: '6 L (Imperial)',
    ),
    BottleSize(
      code: '9L',
      labelFr: 'Salmanazar (9 L - 12 btl)',
      labelEn: 'Salmanazar (9 L - 12 btl)',
      volumeLiters: 9.0,
      shortNameFr: '9 L',
      shortNameEn: '9 L',
    ),
    BottleSize(
      code: '12L',
      labelFr: 'Balthazar (12 L - 16 btl)',
      labelEn: 'Balthazar (12 L - 16 btl)',
      volumeLiters: 12.0,
      shortNameFr: '12 L',
      shortNameEn: '12 L',
    ),
    BottleSize(
      code: '15L',
      labelFr: 'Nabuchodonosor (15 L - 20 btl)',
      labelEn: 'Nebuchadnezzar (15 L - 20 btl)',
      volumeLiters: 15.0,
      shortNameFr: '15 L',
      shortNameEn: '15 L',
    ),
    BottleSize(
      code: '18L',
      labelFr: 'Melchior / Salomon (18 L - 24 btl)',
      labelEn: 'Melchior / Solomon (18 L - 24 btl)',
      volumeLiters: 18.0,
      shortNameFr: '18 L',
      shortNameEn: '18 L',
    ),
  ];

  static BottleSize fromCode(String? code) {
    if (code == null || code.isEmpty) {
      return standardSizes.firstWhere((s) => s.code == defaultCode);
    }
    final norm = code.trim().toLowerCase().replaceAll(' ', '').replaceAll(',', '.');

    // 1. Direct standard matches
    for (final s in standardSizes) {
      if (s.code.toLowerCase() == norm ||
          s.shortNameFr.toLowerCase().replaceAll(' ', '') == norm ||
          s.shortNameEn.toLowerCase().replaceAll(' ', '') == norm) {
        return s;
      }
    }

    // 2. Comprehensive heuristics for 75cl / Standard
    if (norm == '750ml' ||
        norm == '750' ||
        norm == '0.75l' ||
        norm == '0.75' ||
        norm == '75cl' ||
        norm == 'standard' ||
        norm == 'standard(750ml)' ||
        norm == 'standardbottle' ||
        norm == 'bouteillestandard' ||
        norm == 'bottle' ||
        norm == 'bouteille') {
      return standardSizes.firstWhere((s) => s.code == '75cl');
    }

    // 3. Magnum heuristics
    if (norm == '1.5l' ||
        norm == '1500ml' ||
        norm == '1.5' ||
        norm.contains('magnum')) {
      return standardSizes.firstWhere((s) => s.code == '1.5L');
    }

    // 4. Half bottle heuristics
    if (norm == '37.5cl' ||
        norm == '375ml' ||
        norm == '37.5' ||
        norm == 'half' ||
        norm == 'demi' ||
        norm == 'demi-bouteille' ||
        norm == 'halfbottle') {
      return standardSizes.firstWhere((s) => s.code == '37.5cl');
    }

    // 5. 50cl
    if (norm == '50cl' || norm == '500ml' || norm == '50' || norm.contains('pot')) {
      return standardSizes.firstWhere((s) => s.code == '50cl');
    }

    // 6. 62cl Clavelin
    if (norm == '62cl' || norm == '620ml' || norm.contains('clavelin')) {
      return standardSizes.firstWhere((s) => s.code == '62cl');
    }

    // 7. Jeroboam 3L
    if (norm == '3l' || norm == '3000ml' || norm.contains('jeroboam') || norm.contains('jéroboam')) {
      return standardSizes.firstWhere((s) => s.code == '3L');
    }

    // 8. Imperial / Mathusalem 6L
    if (norm == '6l' || norm == '6000ml' || norm.contains('imperiale') || norm.contains('mathusalem')) {
      return standardSizes.firstWhere((s) => s.code == '6L');
    }

    // 9. Contenance libre : « 20cl », « 200ml », « 0.2L »…
    //
    // Le repli historique renvoyait `volumeLiters: 0.75` pour tout code inconnu, ce qui
    // faisait compter une fiole de 20 cl comme une bouteille standard. Personne ne lisait
    // encore ce champ, mais c'était une donnée fausse qui attendait son premier lecteur.
    final libre = _parseVolume(norm);
    if (libre != null) return fromLiters(libre);

    // Dernier repli : on préserve le code sans prétendre en connaître le volume.
    final displayCode = code.trim();
    return BottleSize(
      code: code,
      labelFr: displayCode,
      labelEn: displayCode,
      volumeLiters: 0.75,
      shortNameFr: displayCode,
      shortNameEn: displayCode,
    );
  }

  /// Volume en litres à partir d'un code normalisé, ou nul si le code n'en est pas un.
  ///
  /// Accepte les trois unités qu'on écrit sur une étiquette : centilitres, millilitres et
  /// litres. Les bornes écartent les saisies absurdes — au-delà de 30 L on est au-dessus
  /// du Melchior, en dessous de 1 cl ce n'est plus une bouteille.
  static double? _parseVolume(String norm) {
    final m = RegExp(r'^(\d+(?:\.\d+)?)(cl|ml|l)$').firstMatch(norm);
    if (m == null) return null;
    final valeur = double.tryParse(m.group(1)!);
    if (valeur == null || valeur <= 0) return null;
    final litres = switch (m.group(2)!) {
      'cl' => valeur / 100.0,
      'ml' => valeur / 1000.0,
      _ => valeur,
    };
    if (litres < 0.01 || litres > 30.0) return null;
    return litres;
  }

  /// Contenance libre à partir d'un volume en litres.
  ///
  /// Rend d'abord un format standard si le volume en correspond à un — saisir « 75 cl »
  /// à la main doit donner la bouteille standard, avec son nom, pas un doublon anonyme.
  static BottleSize fromLiters(double litres) {
    for (final s in standardSizes) {
      if ((s.volumeLiters - litres).abs() < 0.001) return s;
    }
    final code = canonicalCode(litres);
    return BottleSize(
      code: code,
      labelFr: _lisible(litres, francais: true),
      labelEn: _lisible(litres, francais: false),
      volumeLiters: litres,
      shortNameFr: _lisible(litres, francais: true),
      shortNameEn: _lisible(litres, francais: false),
    );
  }

  /// Écriture lisible d'un volume, alignée sur les formats nommés : centilitres et
  /// virgule décimale en français (« 20 cl », « 37,5 cl »), millilitres en anglais sous
  /// le litre (« 200 ml »), litres au-dessus. Sans ça, une contenance libre s'affichait
  /// « 20cl » au milieu de pastilles disant « 75 cl » — c'est le genre d'écart que l'œil
  /// attrape immédiatement.
  static String _lisible(double litres, {required bool francais}) {
    String nombre(double v) {
      final s = v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
      return francais ? s.replaceAll('.', ',') : s;
    }

    if (litres >= 1.0) return '${nombre(litres)} L';
    return francais ? '${nombre(litres * 100)} cl' : '${nombre(litres * 1000)} ml';
  }

  /// Écriture canonique d'un volume : centilitres en dessous du litre, litres au-dessus.
  /// C'est la convention des codes existants (`37.5cl`, `75cl`, `1.5L`, `3L`).
  static String canonicalCode(double litres) {
    String sansZeroInutile(double v) {
      final s = v.toStringAsFixed(2);
      return s.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    if (litres < 1.0) return '${sansZeroInutile(litres * 100)}cl';
    return '${sansZeroInutile(litres)}L';
  }

  bool get isStandard75cl => code == '75cl';
}
