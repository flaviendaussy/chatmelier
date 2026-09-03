import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../data/bar_pantry_service.dart';
import '../domain/cocktail.dart';
import '../domain/cocktail_matcher.dart';

class CocktailDetailSheet extends ConsumerWidget {
  final Cocktail cocktail;

  const CocktailDetailSheet({super.key, required this.cocktail});

  static Future<void> show(BuildContext context, Cocktail cocktail) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CocktailDetailSheet(cocktail: cocktail),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentCellarId = ref.watch(currentCellarIdProvider);
    final bottlesAsync = currentCellarId != null
        ? ref.watch(bottlesProvider(currentCellarId))
        : null;
    final bottles = bottlesAsync?.valueOrNull ?? [];
    final pantry = ref.watch(barPantryProvider);

    final match = CocktailMatcher.matchCocktail(
      cocktail: cocktail,
      cellarBottles: bottles,
      pantryItems: pantry,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: match.isReady
                            ? const Color(0xFF2E7D32).withOpacity(0.15)
                            : const Color(0xFF8B1E3F).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getSpiritEmoji(cocktail.baseSpirit),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cocktail.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cocktail.category,
                                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (match.isReady)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Prêt à shaker 🟢',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else if (match.isAlmostReady)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade800,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Manque 1 ingrédient 🟡',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // Quick Specs Cards
                    Row(
                      children: [
                        _buildSpecCard(context, Icons.local_bar, 'Verre', cocktail.glass),
                        const SizedBox(width: 8),
                        _buildSpecCard(context, Icons.science, 'Méthode', cocktail.method),
                        const SizedBox(width: 8),
                        _buildSpecCard(context, Icons.timer, 'Prépa', cocktail.prepTime),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    if (cocktail.description.isNotEmpty) ...[
                      Text(
                        cocktail.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Ingrédients Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ingrédients & Dosages',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${match.availableIngredients.length}/${cocktail.ingredients.length} en stock',
                          style: TextStyle(
                            color: match.isReady ? const Color(0xFF2E7D32) : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ...cocktail.ingredients.map((ing) {
                      final isAvailable = match.availableIngredients.contains(ing.name);
                      final matchedBottle = ing.spiritType != null ? match.matchedBottles[ing.spiritType] : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? (isDark ? const Color(0xFF1B2E1D) : const Color(0xFFE8F5E9))
                              : (isDark ? const Color(0xFF2E241E) : const Color(0xFFFFF3E0)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAvailable ? const Color(0xFF81C784).withOpacity(0.4) : Colors.orange.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAvailable ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isAvailable ? const Color(0xFF2E7D32) : Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ing.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  if (matchedBottle != null)
                                    Text(
                                      'Dans votre cave : ${matchedBottle.wine?.name ?? "Bouteille"}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.green.shade300 : const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  else if (!isAvailable && ing.isSpirit)
                                    Text(
                                      'Spiritueux manquant dans votre cave',
                                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                                    )
                                  else if (!isAvailable && ing.pantryKey != null)
                                    Text(
                                      'Manquant dans votre Bar Pantry',
                                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                                    ),
                                ],
                              ),
                            ),
                            if (ing.displayAmount.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : Colors.white70,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ing.displayAmount,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Instructions Section
                    Text(
                      'Préparation pas à pas',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    ...cocktail.instructions.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF8B1E3F).withOpacity(0.15),
                              child: Text(
                                '$index',
                                style: const TextStyle(
                                  color: Color(0xFF8B1E3F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Garnish & Service Card
                    if (cocktail.garnish.isNotEmpty || cocktail.ice.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, size: 18, color: Color(0xFFD4AF37)),
                                const SizedBox(width: 8),
                                Text(
                                  'Glaçons & Garniture',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (cocktail.ice.isNotEmpty)
                              Text('• Glace : ${cocktail.ice}', style: theme.textTheme.bodySmall),
                            if (cocktail.garnish.isNotEmpty)
                              Text('• Décoration : ${cocktail.garnish}', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecCard(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8B1E3F)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ),
    );
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
      case 'armagnac':
        return '🍇';
      case 'aperitif':
      case 'campari':
      case 'aperol':
        return '🍷';
      case 'liqueur':
        return '🍒';
      default:
        return '🍹';
    }
  }
}
