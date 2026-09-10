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

  String localizedGlass([bool isFr = true]) {
    if (isFr) return glass;
    final g = glass.toLowerCase();
    if (g.contains('coupe') || g.contains('martini')) return 'Coupe / Martini';
    if (g.contains('highball') || g.contains('tumbler') || g.contains('collins')) return 'Highball / Collins';
    if (g.contains('old fashioned') || g.contains('rocks')) return 'Old Fashioned / Rocks';
    if (g.contains('flûte') || g.contains('flute')) return 'Champagne Flute';
    if (g.contains('mule') || g.contains('cuivre')) return 'Copper Mug';
    if (g.contains('verre à vin') || g.contains('ballon')) return 'Wine Glass';
    if (g.contains('verre à mélange')) return 'Mixing Glass';
    return glass;
  }

  String localizedMethod([bool isFr = true]) {
    if (isFr) return method;
    final m = method.toLowerCase();
    if (m.contains('shak')) return 'Shaken';
    if (m.contains('mélang') || m.contains('stir')) return 'Stirred';
    if (m.contains('direct') || m.contains('build')) return 'Built in glass';
    if (m.contains('pil') || m.contains('muddle')) return 'Muddled';
    if (m.contains('mix') || m.contains('blend')) return 'Blended';
    return method;
  }

  String localizedDifficulty([bool isFr = true]) {
    if (isFr) return difficulty;
    final d = difficulty.toLowerCase();
    if (d.contains('facil') || d.contains('easy')) return 'Easy';
    if (d.contains('moyen') || d.contains('medium')) return 'Medium';
    if (d.contains('diffic') || d.contains('hard')) return 'Advanced';
    return difficulty;
  }

  String localizedIce([bool isFr = true]) {
    if (isFr) return ice;
    final i = ice.toLowerCase();
    if (i.contains('glaçon') || i.contains('cubes')) return 'Ice Cubes';
    if (i.contains('pil') || i.contains('crush')) return 'Crushed Ice';
    if (i.contains('sphèr') || i.contains('sphere')) return 'Ice Sphere';
    if (i.contains('sans') || i.contains('aucun') || i.contains('no ice')) return 'No Ice';
    return ice;
  }

  String localizedPrepTime([bool isFr = true]) {
    if (isFr) return prepTime;
    return prepTime.replaceAll('min', 'mins');
  }

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
