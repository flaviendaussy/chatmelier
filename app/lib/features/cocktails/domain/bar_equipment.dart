/// 🍸 User's Bar & Mixology Equipment Profile
class BarEquipment {
  final bool hasShaker; // Shaker à cocktail (Cobbler, Boston ou Parisien)
  final bool hasJigger; // Doseur gradué (Jigger)
  final bool hasStrainer; // Passoire à cocktail (Hawthorne / Julep / Fine)
  final bool hasMuddler; // Pilon à cocktail
  final bool hasBarSpoon; // Cuillère à mélange torsadée

  const BarEquipment({
    this.hasShaker = true,
    this.hasJigger = false,
    this.hasStrainer = false,
    this.hasMuddler = false,
    this.hasBarSpoon = false,
  });

  BarEquipment copyWith({
    bool? hasShaker,
    bool? hasJigger,
    bool? hasStrainer,
    bool? hasMuddler,
    bool? hasBarSpoon,
  }) {
    return BarEquipment(
      hasShaker: hasShaker ?? this.hasShaker,
      hasJigger: hasJigger ?? this.hasJigger,
      hasStrainer: hasStrainer ?? this.hasStrainer,
      hasMuddler: hasMuddler ?? this.hasMuddler,
      hasBarSpoon: hasBarSpoon ?? this.hasBarSpoon,
    );
  }

  Map<String, dynamic> toJson() => {
        'has_shaker': hasShaker,
        'has_jigger': hasJigger,
        'has_strainer': hasStrainer,
        'has_muddler': hasMuddler,
        'has_bar_spoon': hasBarSpoon,
      };

  factory BarEquipment.fromJson(Map<String, dynamic> json) {
    return BarEquipment(
      hasShaker: json['has_shaker'] as bool? ?? true,
      hasJigger: json['has_jigger'] as bool? ?? false,
      hasStrainer: json['has_strainer'] as bool? ?? false,
      hasMuddler: json['has_muddler'] as bool? ?? false,
      hasBarSpoon: json['has_bar_spoon'] as bool? ?? false,
    );
  }
}
