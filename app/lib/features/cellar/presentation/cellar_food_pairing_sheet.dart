import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../domain/bottle.dart';
import '../domain/wine_food_matcher.dart';

class CellarFoodPairingSheet extends StatefulWidget {
  final List<Bottle> bottles;
  final String cellarName;

  const CellarFoodPairingSheet({
    super.key,
    required this.bottles,
    required this.cellarName,
  });

  static Future<void> show(BuildContext context, {required List<Bottle> bottles, required String cellarName}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CellarFoodPairingSheet(bottles: bottles, cellarName: cellarName),
    );
  }

  @override
  State<CellarFoodPairingSheet> createState() => _CellarFoodPairingSheetState();
}

class _CellarFoodPairingSheetState extends State<CellarFoodPairingSheet> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  List<FoodPairingMatch> _matches = [];

  @override
  void initState() {
    super.initState();
    // Default search with first category
    _selectCategory(WineFoodMatcher.categories.first);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(FoodPairingCategory cat) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = cat.id;
      _searchController.text = cat.sampleDishes.first;
      _matches = WineFoodMatcher.findMatches(
        bottles: widget.bottles,
        dishQuery: cat.sampleDishes.first,
      );
    });
  }

  void _selectDish(String dish) {
    HapticFeedback.selectionClick();
    setState(() {
      _searchController.text = dish;
      _matches = WineFoodMatcher.findMatches(
        bottles: widget.bottles,
        dishQuery: dish,
      );
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _selectedCategory = null;
      _matches = WineFoodMatcher.findMatches(
        bottles: widget.bottles,
        dishQuery: query,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inCellarBottles = widget.bottles.where((b) => b.status == 'in_cellar' && b.quantity > 0).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A1B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🍽️', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quel vin pour votre plat ?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Playfair Display',
                        ),
                      ),
                      Text(
                        'Recherche intelligente dans "${widget.cellarName}" (${inCellarBottles.length} en stock)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Ex: Bar de ligne, Magret de canard, Risotto...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2426) : const Color(0xFFF3EFE9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Pills
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: WineFoodMatcher.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = WineFoodMatcher.categories[idx];
                final isSelected = _selectedCategory == cat.id;

                return ChoiceChip(
                  avatar: Text(cat.icon, style: const TextStyle(fontSize: 14)),
                  label: Text(cat.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) _selectCategory(cat);
                  },
                  selectedColor: const Color(0xFF722F37),
                  backgroundColor: isDark ? const Color(0xFF2A2426) : const Color(0xFFF0EBE3),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                    width: 1.2,
                  ),
                );
              },
            ),
          ),

          // Quick Clickable Dish Suggestions (Chips)
          Builder(
            builder: (context) {
              final activeCategory = WineFoodMatcher.categories.firstWhere(
                (c) => c.id == _selectedCategory,
                orElse: () => WineFoodMatcher.categories.first,
              );

              return Container(
                height: 38,
                margin: const EdgeInsets.only(top: 2, bottom: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: activeCategory.sampleDishes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final dish = activeCategory.sampleDishes[idx];
                    final isCurrentDish = _searchController.text.trim().toLowerCase() == dish.toLowerCase();

                    return ActionChip(
                      label: Text(dish),
                      onPressed: () => _selectDish(dish),
                      backgroundColor: isCurrentDish
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                          : (isDark ? const Color(0xFF2A2426) : const Color(0xFFF7F4F0)),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrentDish ? FontWeight.bold : FontWeight.w500,
                        color: isCurrentDish
                            ? const Color(0xFFD4AF37)
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      side: BorderSide(
                        color: isCurrentDish ? const Color(0xFFD4AF37) : (isDark ? Colors.white12 : Colors.black12),
                        width: isCurrentDish ? 1.2 : 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          // Matches list
          Expanded(
            child: _matches.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wine_bar_outlined, size: 54, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun accord trouvé pour ce plat',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Essayez une autre recherche ou sélectionnez une catégorie ci-dessus.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final match = _matches[idx];
                      final bottle = match.bottle;
                      final wine = bottle.wine;
                      if (wine == null) return const SizedBox.shrink();

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/cellar/${bottle.id}');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262022) : const Color(0xFFFAF7F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(match.matchLevel.colorValue).withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Match Score + Wine Type + Qty
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(match.matchLevel.colorValue).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Color(match.matchLevel.colorValue),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, size: 13, color: Color(match.matchLevel.colorValue)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${match.score}% • ${match.matchLevel.label}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(match.matchLevel.colorValue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white12 : Colors.black12,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      wine.type.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${bottle.quantity} en cave',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Wine Name & Appellation
                              Text(
                                wine.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${wine.vintage != null ? "${wine.vintage} • " : ""}${wine.appellation ?? wine.region}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Sommelier Match Note
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(match.matchLevel.colorValue).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Color(match.matchLevel.colorValue).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFFD4AF37)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        match.sommelierComment,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.35,
                                          fontStyle: FontStyle.italic,
                                          color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2523),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Service Tip and Action
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.thermostat, size: 14, color: Color(0xFFD4AF37)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            match.servingAdvice,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.arrow_forward, size: 14),
                                    label: const Text('Voir fiche'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFD4AF37),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.push('/cellar/${bottle.id}');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 250.ms, delay: (idx * 50).ms).slideY(begin: 0.08, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
