import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cocktails/data/custom_cocktail_service.dart';
import '../../cocktails/domain/cocktail.dart';
import '../../cocktails/presentation/cocktail_detail_sheet.dart';
import '../../cocktails/presentation/save_cocktail_dialog.dart';

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

class ChatCocktailCard extends ConsumerWidget {
  final ChatCocktailCardData data;

  const ChatCocktailCard({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final customCocktails = ref.watch(customCocktailsProvider);
    final isSaved = customCocktails.any((c) =>
        c.name.toLowerCase().trim() == data.name.toLowerCase().trim() ||
        c.id.toLowerCase() == data.name.toLowerCase().replaceAll(' ', '_'));

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSaved
              ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
              : const Color(0xFFD4AF37).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
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
                if (isSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2E7D32)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 12, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text(
                          'Enregistré',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
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
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
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

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.local_bar, size: 18),
                    label: const Text(
                      'Voir la recette',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _openCocktailRecipe(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isSaved
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                    foregroundColor: isSaved ? const Color(0xFF2E7D32) : const Color(0xFF8B1E3F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
                    size: 20,
                  ),
                  tooltip: isSaved
                      ? 'Cocktail déjà enregistré (cliquer pour renommer)'
                      : 'Ajouter à mes cocktails',
                  onPressed: () => _saveCocktail(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveCocktail(BuildContext context, WidgetRef ref) {
    final cocktail = _toCocktail(ref);
    SaveCocktailDialog.show(context, cocktail: cocktail);
  }

  Cocktail _toCocktail(WidgetRef ref) {
    final allCocktails = ref.read(allCocktailsProvider);
    return allCocktails.firstWhere(
      (c) => c.name.toLowerCase().trim() == data.name.toLowerCase().trim(),
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
        isCustom: true,
      ),
    );
  }

  void _openCocktailRecipe(BuildContext context, WidgetRef ref) {
    final cocktail = _toCocktail(ref);
    CocktailDetailSheet.show(context, cocktail);
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
