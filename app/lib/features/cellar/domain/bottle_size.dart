/// Standard wine and spirit bottle formats / volumes
class BottleSize {
  final String code; // Standard storage key, e.g. '75cl', '1.5L', '37.5cl'
  final String label; // Full display label
  final double volumeLiters;
  final String shortName; // Compact pill badge, e.g. '75 cl', 'Magnum'

  const BottleSize({
    required this.code,
    required this.label,
    required this.volumeLiters,
    required this.shortName,
  });

  static const String defaultCode = '75cl';

  static const List<BottleSize> standardSizes = [
    BottleSize(code: '37.5cl', label: 'Demi-bouteille (37.5 cl)', volumeLiters: 0.375, shortName: '37.5 cl'),
    BottleSize(code: '50cl', label: 'Demi-litre / Pot (50 cl)', volumeLiters: 0.5, shortName: '50 cl'),
    BottleSize(code: '62cl', label: 'Clavelin (Jura 62 cl)', volumeLiters: 0.62, shortName: '62 cl'),
    BottleSize(code: '75cl', label: 'Bouteille standard (75 cl)', volumeLiters: 0.75, shortName: '75 cl'),
    BottleSize(code: '1.5L', label: 'Magnum (1.5 L - 2 btl)', volumeLiters: 1.5, shortName: '1.5 L (Magnum)'),
    BottleSize(code: '3L', label: 'Jéroboam / Double Magnum (3 L - 4 btl)', volumeLiters: 3.0, shortName: '3 L (Jéroboam)'),
    BottleSize(code: '4.5L', label: 'Réhoboam (4.5 L - 6 btl)', volumeLiters: 4.5, shortName: '4.5 L'),
    BottleSize(code: '6L', label: 'Mathusalem / Impériale (6 L - 8 btl)', volumeLiters: 6.0, shortName: '6 L (Impériale)'),
    BottleSize(code: '9L', label: 'Salmanazar (9 L - 12 btl)', volumeLiters: 9.0, shortName: '9 L'),
    BottleSize(code: '12L', label: 'Balthazar (12 L - 16 btl)', volumeLiters: 12.0, shortName: '12 L'),
    BottleSize(code: '15L', label: 'Nabuchodonosor (15 L - 20 btl)', volumeLiters: 15.0, shortName: '15 L'),
    BottleSize(code: '18L', label: 'Melchior / Salomon (18 L - 24 btl)', volumeLiters: 18.0, shortName: '18 L'),
  ];

  static BottleSize fromCode(String? code) {
    if (code == null || code.isEmpty) {
      return standardSizes.firstWhere((s) => s.code == defaultCode);
    }
    final norm = code.trim().toLowerCase().replaceAll(' ', '');
    return standardSizes.firstWhere(
      (s) => s.code.toLowerCase() == norm || s.shortName.toLowerCase().replaceAll(' ', '') == norm,
      orElse: () => BottleSize(code: code, label: code, volumeLiters: 0.75, shortName: code),
    );
  }

  bool get isStandard75cl => code == '75cl';
}
