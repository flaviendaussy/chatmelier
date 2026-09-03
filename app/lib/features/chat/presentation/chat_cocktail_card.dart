import 'package:flutter/material.dart';
import '../../cocktails/data/cocktail_catalog.dart';
import '../../cocktails/domain/cocktail.dart';
import '../../cocktails/presentation/cocktail_detail_sheet.dart';

class ChatCocktailCardData {
  final String name;
  final String baseSpirit;
  final String? glass;
  final String? method;
  final List<String> ingredients;
  final String? recipe;
  final String? garnish;
  final String? reason;

  const ChatCocktailCardData({
    required this.name,
    required this.baseSpirit,
    this.glass,
    this.method,
    this.ingredients = const [],
    this.recipe,
    this.garnish,
    this.reason,
  });

  factory ChatCocktailCardData.fromJson(Map<String, dynamic> json) {
    List<String> parsedIngredients = [];
    if (json['ingredients'] is List) {
      parsedIngredients = (json['ingredients'] as List).map((e) => e.toString()).toList();
    } else if (json['ingredients'] is String) {
      parsedIngredients = [json['ingredients'].toString()];
    }

    return ChatCocktailCardData(
      name: json['name']?.toString() ?? 'Cocktail Signature',
      baseSpirit: json['base_spirit']?.toString() ?? json['spirit']?.toString() ?? 'gin',
      glass: json['glass']?.toString() ?? 'Verre Old Fashioned',
      method: json['method']?.toString() ?? 'Au shaker',
      ingredients: parsedIngredients,
      recipe: json['recipe']?.toString() ?? json['instructions']?.toString(),
      garnish: json['garnish']?.toString(),
      reason: json['reason']?.toString(),
    );
  }
}

class ChatCocktailCard extends StatelessWidget {
  final ChatCocktailCardData data;

  const ChatCocktailCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badge & Glass
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getSpiritEmoji(data.baseSpirit),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${data.baseSpirit.toUpperCase()} • ${data.glass ?? "Verre à cocktail"}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4AF37)),
                  ),
                  child: const Text(
                    'Mixologie ✨',
                    style: TextStyle(
                      color: Color(0xFFB8860B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (data.reason != null && data.reason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.reason!,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Ingredients Pills
            if (data.ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: data.ingredients.map((ing) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ing,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.local_bar, size: 18),
                label: const Text(
                  'Voir la recette pas à pas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _openCocktailRecipe(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCocktailRecipe(BuildContext context) {
    // Check if matching cocktail in catalog
    final catalogMatch = CocktailCatalog.all.firstWhere(
      (c) => c.name.toLowerCase() == data.name.toLowerCase(),
      orElse: () => Cocktail(
        id: 'custom_chat_${data.name.toLowerCase().replaceAll(' ', '_')}',
        name: data.name,
        baseSpirit: data.baseSpirit,
        category: 'Création Chatmelier',
        glass: data.glass ?? 'Verre à cocktail',
        method: data.method ?? 'Au shaker',
        garnish: data.garnish ?? 'Zeste d\'agrume frais',
        description: data.reason ?? 'Cocktail créé sur-mesure d\'après vos ingrédients disponibles.',
        ingredients: data.ingredients
            .map((i) => CocktailIngredient(name: i))
            .toList(),
        instructions: data.recipe != null && data.recipe!.isNotEmpty
            ? [data.recipe!]
            : [
                'Mettre tous les ingrédients dans le shaker avec des glaçons.',
                'Frapper vigoureusement pendant 15 secondes.',
                'Filtrer dans le verre et garnir.',
              ],
      ),
    );

    CocktailDetailSheet.show(context, catalogMatch);
  }

  static String _getSpiritEmoji(String baseSpirit) {
    switch (baseSpirit.toLowerCase().trim()) {
      case 'gin':
        return '🍸';
      case 'rhum':
      case 'rum':
        return '🍹';
      case 'whisky':
      case 'whiskey':
      case 'bourbon':
        return '🥃';
      case 'vodka':
        return '🧊';
      case 'tequila':
      case 'mezcal':
        return '🌵';
      case 'cognac':
        return '🍇';
      case 'aperitif':
        return '🍷';
      case 'liqueur':
        return '🍒';
      default:
        return '🍸';
    }
  }
}
