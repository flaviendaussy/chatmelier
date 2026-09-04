import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../data/bar_pantry_service.dart';
import '../data/custom_cocktail_service.dart';
import '../domain/cocktail.dart';
import '../domain/cocktail_matcher.dart';
import 'save_cocktail_dialog.dart';

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
    final customCocktails = ref.watch(customCocktailsProvider);
    final isSaved = customCocktails.any((c) =>
        c.id == cocktail.id || c.name.toLowerCase().trim() == cocktail.name.toLowerCase().trim());

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
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                            : const Color(0xFF8B1E3F).withValues(alpha: 0.15),
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
                                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
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
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
                        color: isSaved ? const Color(0xFFD4AF37) : null,
                      ),
                      tooltip: isSaved ? 'Modifier le nom dans mes cocktails' : 'Ajouter à mes cocktails',
                      onPressed: () => SaveCocktailDialog.show(context, cocktail: cocktail),
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
                      final matchedBottles = ing.spiritType != null ? match.matchedBottles[ing.spiritType] : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? (isDark ? const Color(0xFF1B2E1D) : const Color(0xFFE8F5E9))
                              : (isDark ? const Color(0xFF2E241E) : const Color(0xFFFFF3E0)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAvailable ? const Color(0xFF81C784).withValues(alpha: 0.4) : Colors.orange.withValues(alpha: 0.4),
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
                                  if (matchedBottles != null && matchedBottles.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    if (matchedBottles.length > 1) ...[
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.touch_app_outlined, size: 12, color: Color(0xFFD4AF37)),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Au choix : utilisez 1 seule bouteille parmi vos ${matchedBottles.length} disponibles',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFD4AF37),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    ...matchedBottles.asMap().entries.map((entry) {
                                      final optIndex = entry.key + 1;
                                      final bottle = entry.value;
                                      final name = bottle.wine?.name ?? 'Bouteille';
                                      final producer = bottle.wine?.producer;
                                      final displayName = producer != null && producer.isNotEmpty
                                          ? '$producer – $name'
                                          : name;
                                      final location = bottle.rack != null && bottle.rack!.isNotEmpty
                                          ? ' • ${bottle.rack}${bottle.shelf != null ? " - ${bottle.shelf}" : ""}'
                                          : '';
                                      final fillColor = bottle.fillLevel <= 20
                                          ? Colors.red.shade600
                                          : bottle.fillLevel <= 50
                                              ? Colors.orange.shade700
                                              : Colors.green.shade600;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 3),
                                        child: Row(
                                          children: [
                                            if (matchedBottles.length > 1) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                margin: const EdgeInsets.only(right: 6),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Option $optIndex',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white70 : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            Icon(Icons.liquor, size: 12, color: isDark ? Colors.green.shade300 : const Color(0xFF2E7D32)),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                displayName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.green.shade300 : const Color(0xFF2E7D32),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${bottle.fillLevel}%$location',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: fillColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ] else if (!isAvailable && ing.isSpirit)
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
                              backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
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
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
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

                    const SizedBox(height: 20),

                    // Add to My Cocktails / Rename Actions
                    if (!isSaved)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E3F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.bookmark_add, size: 20),
                        label: const Text(
                          'Ajouter à mes cocktails',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () => SaveCocktailDialog.show(context, cocktail: cocktail),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Renommer le cocktail'),
                              onPressed: () => SaveCocktailDialog.show(
                                context,
                                cocktail: cocktail,
                                initialName: cocktail.name,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            style: IconButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.all(12),
                            ),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Retirer de mes cocktails',
                            onPressed: () => _confirmDelete(context, ref),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer ce cocktail ?'),
        content: Text('Voulez-vous retirer "${cocktail.name}" de vos recettes enregistrées ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final saved = ref.read(customCocktailsProvider).firstWhere(
        (c) => c.name.toLowerCase() == cocktail.name.toLowerCase() || c.id == cocktail.id,
        orElse: () => cocktail,
      );
      await ref.read(customCocktailsProvider.notifier).deleteCocktail(saved.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cocktail "${cocktail.name}" retiré de vos recettes.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSpecCard(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
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
