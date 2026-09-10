import 'package:flutter/material.dart';

enum PantryCategory {
  ice,
  fruits,
  herbs,
  mixers,
  syrups,
  custom;

  String get labelFr => label(true);

  String label([bool isFr = true]) {
    if (isFr) {
      switch (this) {
        case PantryCategory.ice:
          return 'Glaçons & Glace';
        case PantryCategory.fruits:
          return 'Agrumes & Fruits';
        case PantryCategory.herbs:
          return 'Herbes & Épices';
        case PantryCategory.mixers:
          return 'Mixers & Softs';
        case PantryCategory.syrups:
          return 'Sirops & Bitters';
        case PantryCategory.custom:
          return 'Personnalisés';
      }
    }
    switch (this) {
      case PantryCategory.ice:
        return 'Ice & Cubes';
      case PantryCategory.fruits:
        return 'Citrus & Fruits';
      case PantryCategory.herbs:
        return 'Herbs & Spices';
      case PantryCategory.mixers:
        return 'Mixers & Sodas';
      case PantryCategory.syrups:
        return 'Syrups & Bitters';
      case PantryCategory.custom:
        return 'Custom';
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

  String localizedName([bool isFr = true]) {
    if (isFr) return name;
    return _enNames[id] ?? name;
  }

  String localizedUnit([bool isFr = true]) {
    if (isFr) return unit;
    return _enUnits[id] ?? _enGenericUnits[unit] ?? unit;
  }

  static const Map<String, String> _enNames = {
    'ice_cubes': 'Standard Ice Cubes',
    'clear_ice': 'Clear Ice Block (XXL Cube)',
    'ice_sphere': 'Ice Sphere',
    'crushed_ice': 'Crushed Ice',
    'lime': 'Lime (Fresh)',
    'lemon': 'Lemon (Fresh)',
    'orange': 'Juicing Orange & Zests',
    'grapefruit': 'Pink Grapefruit',
    'yuzu': 'Yuzu / Yuzu Juice',
    'clementine': 'Clementine / Mandarin',
    'bergamot': 'Bergamot',
    'cucumber': 'Fresh Cucumber',
    'strawberries': 'Fresh Strawberries',
    'raspberries': 'Fresh Raspberries',
    'blackberries': 'Wild Blackberries',
    'blueberries': 'Blueberries',
    'pineapple': 'Fresh Pineapple',
    'passion_fruit': 'Passion Fruit (Maracuja)',
    'pomegranate': 'Fresh Pomegranate Arils',
    'apple': 'Green Granny Smith Apple',
    'cherries_fresh': 'Fresh Cherries',
    'peach': 'White Peach',
    'mint': 'Fresh Mint',
    'basil': 'Fresh Basil',
    'rosemary': 'Fresh Rosemary',
    'thyme': 'Fresh Thyme',
    'sage': 'Fresh Sage',
    'ginger': 'Fresh Ginger Root',
    'cinnamon': 'Cinnamon Sticks',
    'nutmeg': 'Whole Nutmeg',
    'star_anise': 'Star Anise',
    'cloves': 'Whole Cloves',
    'chili_espelette': 'Espelette Pepper',
    'black_pepper': 'Black Tellicherry Pepper',
    'cardamom': 'Green Cardamom Pods',
    'tonic': 'Classic Tonic Water',
    'mediterranean_tonic': 'Mediterranean Tonic Water',
    'ft_elderflower_tonic': 'Fever-Tree Elderflower Tonic',
    'ft_light_tonic': 'Fever-Tree Refreshingly Light Tonic',
    'ft_aromatic_tonic': 'Fever-Tree Aromatic Tonic',
    'ft_clementine_tonic': 'Fever-Tree Clementine & Cinnamon Tonic',
    'ft_rhubarb_tonic': 'Fever-Tree Rhubarb & Raspberry Tonic',
    'ft_cucumber_tonic': 'Fever-Tree Cucumber Tonic Water',
    'ft_pink_grapefruit_soda': 'Fever-Tree Sparkling Pink Grapefruit',
    'ginger_beer': 'Spicy Ginger Beer',
    'ft_ginger_beer': 'Fever-Tree Premium Ginger Beer',
    'ginger_ale': 'Ginger Ale',
    'ft_ginger_ale': 'Fever-Tree Premium Ginger Ale',
    'soda_water': 'Club Soda / Sparkling Water',
    'ft_soda_water': 'Fever-Tree Premium Soda Water',
    'cola': 'Craft Cola',
    'ft_cola': 'Fever-Tree Madagascan Cola',
    'lemonade': 'Artisanal Lemonade',
    'ft_lemonade': 'Fever-Tree Sicilian Lemonade',
    'cranberry_juice': 'Cranberry Juice',
    'pineapple_juice': '100% Pineapple Juice',
    'orange_juice': 'Pure Orange Juice',
    'grapefruit_juice': 'Pink Grapefruit Juice',
    'apple_juice': 'Farmhouse Apple Juice',
    'tomato_juice': 'Tomato Juice',
    'coconut_water': 'Coconut Water',
    'grapefruit_soda': 'Pink Grapefruit Soda (Paloma)',
    'sugar_syrup': 'Simple Sugar Syrup (1:1)',
    'rich_demerara_syrup': 'Rich Demerara Syrup (2:1)',
    'agave_syrup': 'Organic Agave Syrup',
    'honey': 'Liquid Acacia Honey',
    'maple_syrup': 'Pure Maple Syrup',
    'syrup_grenadine': 'Artisanal Grenadine Syrup',
    'syrup_orgeat': 'Orgeat (Almond) Syrup',
    'syrup_vanilla': 'Bourbon Vanilla Syrup',
    'honey_ginger_syrup': 'Honey-Ginger Syrup (Penicillin)',
    'syrup_passion': 'Passion Fruit Syrup',
    'syrup_raspberry': 'Raspberry Syrup',
    'sugar_cube': 'White Sugar Cube',
    'brown_sugar': 'Brown Sugar / Demerara',
    'angostura': 'Angostura Aromatic Bitters',
    'orange_bitters': 'Orange Bitters',
    'peychauds': 'Peychaud\'s Bitters',
    'chocolate_bitters': 'Chocolate / Cocoa Bitters',
    'celery_bitters': 'Celery Bitters',
    'salt': 'Guérande Sea Salt Flakes',
    'celery_salt': 'Celery Salt',
    'tabasco': 'Red Tabasco Sauce',
    'worcestershire': 'Worcestershire Sauce (Lea & Perrins)',
    'espresso': 'Fresh Espresso Coffee',
    'cream': 'Heavy Cream (30%)',
    'coconut_cream': 'Coconut Cream / Milk',
    'egg_white': 'Fresh Egg White / Aquafaba',
    'amarena_cherries': 'Amarena Cherries in Syrup',
    'green_olives': 'Cocktail Green Olives',
    'cocktail_onions': 'Cocktail Pearl Onions',
  };

  static const Map<String, String> _enUnits = {
    'ice_cubes': 'trays / bags',
    'clear_ice': 'XXL cubes',
    'ice_sphere': 'spheres',
    'crushed_ice': 'trays / bags',
    'lime': 'items',
    'lemon': 'items',
    'orange': 'items',
    'grapefruit': 'items',
    'yuzu': 'items / bottles',
    'clementine': 'items',
    'bergamot': 'items',
    'cucumber': 'items',
    'strawberries': 'punnets',
    'raspberries': 'punnets',
    'blackberries': 'punnets',
    'blueberries': 'punnets',
    'pineapple': 'items',
    'passion_fruit': 'items',
    'pomegranate': 'items',
    'apple': 'items',
    'cherries_fresh': 'punnets',
    'peach': 'items',
    'mint': 'bunches',
    'basil': 'bunches',
    'rosemary': 'sprigs',
    'thyme': 'sprigs',
    'sage': 'leaves',
    'ginger': 'roots',
    'cinnamon': 'sticks',
    'nutmeg': 'whole',
    'star_anise': 'stars',
    'cloves': 'cloves',
    'chili_espelette': 'bottles',
    'black_pepper': 'mills',
    'cardamom': 'pods',
    'tonic': 'bottles / cans',
    'mediterranean_tonic': 'bottles / cans',
    'ft_elderflower_tonic': 'bottles / cans',
    'ft_light_tonic': 'bottles / cans',
    'ft_aromatic_tonic': 'bottles / cans',
    'ft_clementine_tonic': 'bottles / cans',
    'ft_rhubarb_tonic': 'bottles / cans',
    'ft_cucumber_tonic': 'bottles / cans',
    'ft_pink_grapefruit_soda': 'bottles / cans',
    'ginger_beer': 'bottles / cans',
    'ft_ginger_beer': 'bottles / cans',
    'ginger_ale': 'bottles / cans',
    'ft_ginger_ale': 'bottles / cans',
    'soda_water': 'bottles',
    'ft_soda_water': 'bottles',
    'cola': 'bottles / cans',
    'ft_cola': 'bottles / cans',
    'lemonade': 'bottles',
    'ft_lemonade': 'bottles',
    'cranberry_juice': 'bottles',
    'pineapple_juice': 'bottles',
    'orange_juice': 'bottles',
    'grapefruit_juice': 'bottles',
    'apple_juice': 'bottles',
    'tomato_juice': 'bottles',
    'coconut_water': 'cartons',
    'grapefruit_soda': 'cans',
    'sugar_syrup': 'bottles',
    'rich_demerara_syrup': 'bottles',
    'agave_syrup': 'bottles',
    'honey': 'jars',
    'maple_syrup': 'bottles',
    'syrup_grenadine': 'bottles',
    'syrup_orgeat': 'bottles',
    'syrup_vanilla': 'bottles',
    'honey_ginger_syrup': 'jars',
    'syrup_passion': 'bottles',
    'syrup_raspberry': 'bottles',
    'sugar_cube': 'cubes',
    'brown_sugar': 'packs',
    'angostura': 'bottles',
    'orange_bitters': 'bottles',
    'peychauds': 'bottles',
    'chocolate_bitters': 'bottles',
    'celery_bitters': 'bottles',
    'salt': 'pinches',
    'celery_salt': 'bottles',
    'tabasco': 'bottles',
    'worcestershire': 'bottles',
    'espresso': 'cups',
    'cream': 'cartons',
    'coconut_cream': 'cartons',
    'egg_white': 'eggs',
    'amarena_cherries': 'jars',
    'green_olives': 'jars',
    'cocktail_onions': 'jars',
  };

  static const Map<String, String> _enGenericUnits = {
    'unités': 'units',
    'pièces': 'pieces',
    'bouteilles': 'bottles',
    'canettes': 'cans',
    'bacs / sacs': 'trays / bags',
    'cubes XXL': 'XXL cubes',
    'sphères': 'spheres',
    'barquettes': 'punnets',
    'bottes': 'bunches',
    'branches': 'sprigs',
    'feuilles': 'leaves',
    'racines': 'roots',
    'bâtons': 'sticks',
    'noix': 'whole',
    'étoiles': 'stars',
    'clous': 'cloves',
    'flacons': 'bottles',
    'moulins': 'mills',
    'gousses': 'pods',
    'briques': 'cartons',
    'pots': 'jars',
    'morceaux': 'cubes',
    'sachets': 'packs',
    'pincées': 'pinches',
    'tasses': 'cups',
    'œufs': 'eggs',
    'bocaux': 'jars',
  };

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
