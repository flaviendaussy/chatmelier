class CocktailIngredient {
  final String name;
  final double? amount;
  final String? unit;
  final bool isSpirit;
  final String? spiritType;
  final String? pantryKey;
  final bool optional;

  const CocktailIngredient({
    required this.name,
    this.amount,
    this.unit,
    this.isSpirit = false,
    this.spiritType,
    this.pantryKey,
    this.optional = false,
  });

  String get displayAmount {
    if (amount == null) return '';
    final formattedAmount = amount! % 1 == 0 ? amount!.toInt().toString() : amount!.toString();
    return unit != null ? '$formattedAmount $unit' : formattedAmount;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit,
    'is_spirit': isSpirit,
    'spirit_type': spiritType,
    'pantry_key': pantryKey,
    'optional': optional,
  };

  factory CocktailIngredient.fromJson(Map<String, dynamic> json) {
    return CocktailIngredient(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      isSpirit: json['is_spirit'] as bool? ?? false,
      spiritType: json['spirit_type'] as String?,
      pantryKey: json['pantry_key'] as String?,
      optional: json['optional'] as bool? ?? false,
    );
  }
}

class Cocktail {
  final String id;
  final String name;
  final String baseSpirit;
  final String category;
  final String glass;
  final String method;
  final String difficulty;
  final String prepTime;
  final String ice;
  final String garnish;
  final String description;
  final List<CocktailIngredient> ingredients;
  final List<String> instructions;
  final bool isCustom;

  const Cocktail({
    required this.id,
    required this.name,
    required this.baseSpirit,
    required this.category,
    required this.glass,
    required this.method,
    this.difficulty = 'Facile',
    this.prepTime = '3 min',
    this.ice = 'Glaçons',
    required this.garnish,
    required this.description,
    required this.ingredients,
    required this.instructions,
    this.isCustom = false,
  });

  Cocktail copyWith({
    String? id,
    String? name,
    String? baseSpirit,
    String? category,
    String? glass,
    String? method,
    String? difficulty,
    String? prepTime,
    String? ice,
    String? garnish,
    String? description,
    List<CocktailIngredient>? ingredients,
    List<String>? instructions,
    bool? isCustom,
  }) {
    return Cocktail(
      id: id ?? this.id,
      name: name ?? this.name,
      baseSpirit: baseSpirit ?? this.baseSpirit,
      category: category ?? this.category,
      glass: glass ?? this.glass,
      method: method ?? this.method,
      difficulty: difficulty ?? this.difficulty,
      prepTime: prepTime ?? this.prepTime,
      ice: ice ?? this.ice,
      garnish: garnish ?? this.garnish,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'base_spirit': baseSpirit,
    'category': category,
    'glass': glass,
    'method': method,
    'difficulty': difficulty,
    'prep_time': prepTime,
    'ice': ice,
    'garnish': garnish,
    'description': description,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'instructions': instructions,
    'is_custom': isCustom,
  };

  factory Cocktail.fromJson(Map<String, dynamic> json) {
    return Cocktail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      baseSpirit: json['base_spirit'] as String? ?? 'gin',
      category: json['category'] as String? ?? 'Classique',
      glass: json['glass'] as String? ?? 'Tumbler',
      method: json['method'] as String? ?? 'Au shaker',
      difficulty: json['difficulty'] as String? ?? 'Facile',
      prepTime: json['prep_time'] as String? ?? '3 min',
      ice: json['ice'] as String? ?? 'Glaçons',
      garnish: json['garnish'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCustom: json['is_custom'] as bool? ?? false,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((i) => CocktailIngredient.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
