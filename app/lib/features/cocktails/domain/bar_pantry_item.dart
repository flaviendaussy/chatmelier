import 'package:flutter/material.dart';

enum PantryCategory {
  fruits,
  herbs,
  mixers,
  syrups,
  ice,
  custom;

  String get labelFr {
    switch (this) {
      case PantryCategory.fruits:
        return 'Fruits & Agrumes';
      case PantryCategory.herbs:
        return 'Herbes & Aromates';
      case PantryCategory.mixers:
        return 'Softs & Mixers';
      case PantryCategory.syrups:
        return 'Sirops & Bitters';
      case PantryCategory.ice:
        return 'Glace';
      case PantryCategory.custom:
        return 'Personnalisés';
    }
  }

  IconData get icon {
    switch (this) {
      case PantryCategory.fruits:
        return Icons.eco;
      case PantryCategory.herbs:
        return Icons.grass;
      case PantryCategory.mixers:
        return Icons.local_drink;
      case PantryCategory.syrups:
        return Icons.water_drop;
      case PantryCategory.ice:
        return Icons.ac_unit;
      case PantryCategory.custom:
        return Icons.star_border;
    }
  }
}

class BarPantryItem {
  final String id;
  final String name;
  final PantryCategory category;
  final int quantity;
  final String unit;
  final String emoji;
  final bool isCustom;

  const BarPantryItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 0,
    this.unit = 'unités',
    this.emoji = '🍹',
    this.isCustom = false,
  });

  bool get inStock => quantity > 0;

  BarPantryItem copyWith({
    String? id,
    String? name,
    PantryCategory? category,
    int? quantity,
    String? unit,
    String? emoji,
    bool? isCustom,
  }) {
    return BarPantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      emoji: emoji ?? this.emoji,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'quantity': quantity,
    'unit': unit,
    'emoji': emoji,
    'is_custom': isCustom,
  };

  factory BarPantryItem.fromJson(Map<String, dynamic> json) {
    return BarPantryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: PantryCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => PantryCategory.custom,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'unités',
      emoji: json['emoji'] as String? ?? '🍹',
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }
}
