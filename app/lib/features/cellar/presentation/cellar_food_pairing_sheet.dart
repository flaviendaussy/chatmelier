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
  bool _initialized = false;

  String get _langCode => Localizations.maybeLocaleOf(context)?.languageCode ?? 'fr';

  String _t(String en, String es, String ca, String la, String fr) {
    switch (_langCode) {
      case 'en': return en;
      case 'es': return es;
      case 'ca': return ca;
      case 'la': return la;
      default: return fr;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _selectCategory(WineFoodMatcher.categories.first);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(FoodPairingCategory cat) {
    HapticFeedback.selectionClick();
    final firstDish = cat.getSampleDishes(_langCode).first;
    setState(() {
      _selectedCategory = cat.id;
      _searchController.text = firstDish;
      _matches = WineFoodMatcher.findMatches(
        bottles: widget.bottles,
        dishQuery: firstDish,
        lang: _langCode,
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
        lang: _langCode,
      );
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _selectedCategory = null;
      _matches = WineFoodMatcher.findMatches(
        bottles: widget.bottles,
        dishQuery: query,
        lang: _langCode,
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
                        _t('What wine for your dish?', '¿Qué vino para tu plato?', 'Quin vi pel teu plat?', 'Quod vinum ad cibum tuum?', 'Quel vin pour votre plat ?'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Playfair Display',
                        ),
                      ),
                      Text(
                        '${_t("Smart cellar search in", "Búsqueda inteligente en", "Cerca intel·ligent a", "Quaesitio ingeniosa in", "Recherche intelligente dans")} "${widget.cellarName}" (${inCellarBottles.length} ${_t("in stock", "en stock", "en estoc", "in cella", "en stock")})',
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
                hintText: _t('e.g. Ribeye steak, Duck breast, Risotto, Salmon...', 'ej: Entrecot, Magret de pato, Risotto, Salmón...', 'ex: Entrecot, Magret d\'ànec, Risotto, Salmó...', 'ex: Bubula assa, Magret, Risotto, Salmo...', 'Ex: Bar de ligne, Magret de canard, Risotto...'),
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
                  label: Text(cat.localizedLabel(_langCode)),
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
                  itemCount: activeCategory.getSampleDishes(_langCode).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final dish = activeCategory.getSampleDishes(_langCode)[idx];
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
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, size: 36, color: Color(0xFFD4AF37)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t('No bottle in cellar matches', 'Ninguna botella en bodega coincide', 'Cap ampolla al celler no coincideix', 'Nulla lagena in cella convenit', 'Aucun flacon en cave ne convient'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Playfair Display',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _t('Sommelier requirement (Threshold ≥ 60%): better to open nothing than an unsuitable bottle that would spoil your dish.',
                             'Exigencia de sumiller (Umbral ≥ 60%): mejor no abrir nada que una botella inadecuada que desvirtúe el plato.',
                             'Exigència de sommelier (Llindar ≥ 60%): val més no obrir res que una ampolla inadequada que espatlli el plat.',
                             'Postulatio sommelier (Limes ≥ 60%): melius nihil aperire quam lagenam ineptam quae cibum corrumpat.',
                             'Exigence sommelière (Seuil ≥ 60%) : mieux vaut ne rien ouvrir plutôt qu\'une bouteille inadaptée qui dénaturerait votre mets.'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Sommelier Advice Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2325) : const Color(0xFFF9F6F0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('💡', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _t("Chatmelier's Advice", "Consejo del Chatmelier", "Consell del Chatmelier", "Consilium Chatmelier", "Conseil du Chatmelier"),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFFD4AF37),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                WineFoodMatcher.getSommelierAdviceForDish(_searchController.text, _langCode),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _t('Try another search or select a category above.',
                             'Pruebe otra búsqueda o seleccione una categoría arriba.',
                             'Proveu una altra cerca o seleccioneu una categoria a dalt.',
                             'Aliam quaestionem tenta aut categoriam supra elige.',
                             'Essayez une autre recherche ou sélectionnez une catégorie ci-dessus.'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                                    label: Text(_t('View wine', 'Ver ficha', 'Veure fitxa', 'Vide lagenam', 'Voir fiche')),
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
