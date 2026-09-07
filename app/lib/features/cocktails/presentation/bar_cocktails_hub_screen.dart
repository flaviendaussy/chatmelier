import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../data/bar_pantry_service.dart';
import '../data/custom_cocktail_service.dart';
import '../domain/bar_pantry_item.dart';
import '../domain/cocktail_matcher.dart';
import 'bar_equipment_sheet.dart';
import 'cocktail_detail_sheet.dart';

class BarCocktailsHubScreen extends ConsumerStatefulWidget {
  const BarCocktailsHubScreen({super.key});

  @override
  ConsumerState<BarCocktailsHubScreen> createState() => _BarCocktailsHubScreenState();
}

class _BarCocktailsHubScreenState extends ConsumerState<BarCocktailsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filters for Pantry
  String _pantrySearch = '';
  bool _showPantrySearch = false;
  final TextEditingController _pantrySearchController = TextEditingController();
  PantryCategory? _selectedPantryCategory;

  // Search & Filters for Catalog
  String _catalogSearch = '';
  bool _showCatalogSearch = false;
  final TextEditingController _catalogSearchController = TextEditingController();
  String _selectedCatalogSpirit = 'all';

  // Sort for unified Cocktails tab
  String _sortBy = 'missing'; // 'missing', 'name', 'spirit', 'difficulty'
  String _filterStatus = 'all'; // 'all', 'ready', 'almost'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _catalogSearchController.dispose();
    _pantrySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFr = Localizations.localeOf(context).languageCode != 'en';

    final currentCellarId = ref.watch(currentCellarIdProvider);
    final bottlesAsync = currentCellarId != null
        ? ref.watch(bottlesProvider(currentCellarId))
        : null;
    final bottles = bottlesAsync?.valueOrNull ?? [];
    final pantry = ref.watch(barPantryProvider);
    final allCocktails = ref.watch(allCocktailsProvider);

    // Compute matches
    final allMatches = allCocktails.map((c) {
      return CocktailMatcher.matchCocktail(
        cocktail: c,
        cellarBottles: bottles,
        pantryItems: pantry,
      );
    }).toList();

    final readyMatches = allMatches.where((m) => m.isReady).toList();
    final almostMatches = allMatches.where((m) => m.isAlmostReady).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_bar, color: Color(0xFF8B1E3F), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Bar & Cocktails',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isFr ? 'Mon Matériel de Bar' : 'My Bar Equipment',
            icon: const Icon(Icons.handyman_outlined),
            onPressed: () => BarEquipmentSheet.show(context),
          ),
          IconButton(
            tooltip: isFr ? 'Demander au Chatmelier Mixologue' : 'Ask Chatmelier Mixologist',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            onPressed: () => _askChatmelierMixologist(context, readyMatches.length),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 2, 14, 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF8B1E3F),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🍸 Cocktails', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${readyMatches.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _tabController.index == 0 ? Colors.white : const Color(0xFF8B1E3F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isFr ? '🥫 Réserve du Bar' : '🥫 Bar Pantry', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pantry.where((i) => i.inStock).length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _tabController.index == 1 ? Colors.white : const Color(0xFF8B1E3F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Cocktails (Catalogue unifié avec tri & filtres prêts à shaker)
          _buildCatalogTab(context, allMatches, readyMatches, almostMatches, isFr),

          // 2. Bar Pantry Stock
          _buildBarPantryTab(context, pantry, isFr),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: Bar Pantry Stock
  // ==========================================
  Widget _buildBarPantryTab(BuildContext context, List<BarPantryItem> pantry, bool isFr) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = pantry.where((item) {
      if (_selectedPantryCategory != null && item.category != _selectedPantryCategory) {
        return false;
      }
      if (_pantrySearch.isNotEmpty) {
        final q = _pantrySearch.toLowerCase();
        return item.name.toLowerCase().contains(q) || item.category.label(isFr).toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Controls Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expandable Search Input
              if (_showPantrySearch) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _pantrySearchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: isFr ? 'Rechercher un ingrédient...' : 'Search for an ingredient...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _pantrySearch.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _pantrySearchController.clear();
                                setState(() => _pantrySearch = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _pantrySearch = v.trim()),
                  ),
                ),
              ],

              // Category Filter Chips with Search on the left + Action Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Search shortcut button on the left
                    Material(
                      color: _showPantrySearch
                          ? const Color(0xFF8B1E3F)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _showPantrySearch = !_showPantrySearch;
                            if (!_showPantrySearch) {
                              _pantrySearch = '';
                              _pantrySearchController.clear();
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Icon(
                            _showPantrySearch ? Icons.search_off : Icons.search,
                            size: 18,
                            color: _showPantrySearch ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Add Custom Item Button
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(isFr ? 'Ajouter' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _showAddPantryItemDialog(context, isFr),
                    ),
                    const SizedBox(width: 6),

                    // Reset Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _confirmResetAll(context, isFr),
                    ),
                    const SizedBox(width: 8),

                    // Tous Chip
                    FilterChip(
                      label: Text(isFr ? 'Tous' : 'All'),
                      selected: _selectedPantryCategory == null,
                      onSelected: (_) => setState(() => _selectedPantryCategory = null),
                    ),
                    const SizedBox(width: 6),
                    ...PantryCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: Icon(cat.icon, size: 14),
                          label: Text(cat.label(isFr)),
                          selected: _selectedPantryCategory == cat,
                          onSelected: (_) => setState(() {
                            _selectedPantryCategory = _selectedPantryCategory == cat ? null : cat;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Pantry List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final inStock = item.inStock;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: inStock
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: inStock
                        ? Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: inStock ? FontWeight.bold : FontWeight.normal,
                    color: inStock ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade600,
                  ),
                ),
                subtitle: Text(
                  '${item.category.label(isFr)} • ${item.unit}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minus Button
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: item.quantity > 0 ? const Color(0xFF8B1E3F) : Colors.grey.shade400,
                      onPressed: item.quantity > 0
                          ? () => ref.read(barPantryProvider.notifier).decrement(item.id)
                          : null,
                    ),

                    // Quantity Badge
                    Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: inStock
                            ? const Color(0xFF2E7D32)
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: inStock ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // Plus Button
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFF2E7D32),
                      onPressed: () => ref.read(barPantryProvider.notifier).increment(item.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: Catalogue Unifié des Cocktails
  // ==========================================
  Widget _buildCatalogTab(
    BuildContext context,
    List<CocktailMatchResult> allMatches,
    List<CocktailMatchResult> readyMatches,
    List<CocktailMatchResult> almostMatches,
    bool isFr,
  ) {
    final theme = Theme.of(context);
    final filtered = allMatches.where((m) {
      final c = m.cocktail;

      // Filter by readiness status
      if (_filterStatus == 'ready' || _filterStatus == 'Prêts') {
        if (!m.isReady) return false;
      } else if (_filterStatus == 'almost' || _filterStatus == '1 manquant') {
        if (!m.isAlmostReady) return false;
      }

      // Filter by base spirit / creations
      if (_selectedCatalogSpirit != 'all' && _selectedCatalogSpirit != 'Tous') {
        if (_selectedCatalogSpirit == 'custom' || _selectedCatalogSpirit == '✨ Mes créations') {
          if (!c.isCustom) return false;
        } else {
          final target = _selectedCatalogSpirit.toLowerCase();
          if (target == 'gin' && c.baseSpirit != 'gin') return false;
          if ((target == 'rhum' || target == 'rum') && c.baseSpirit != 'rhum' && c.baseSpirit != 'rum') return false;
          if ((target == 'whisky' || target == 'whiskey') && c.baseSpirit != 'whisky' && c.baseSpirit != 'whiskey' && c.baseSpirit != 'bourbon') return false;
          if (target == 'vodka' && c.baseSpirit != 'vodka') return false;
          if (target == 'tequila' && (c.baseSpirit != 'tequila' && c.baseSpirit != 'mezcal')) return false;
          if ((target == 'apéritifs' || target == 'aperitifs') && (c.baseSpirit != 'aperitif' && c.baseSpirit != 'liqueur' && c.baseSpirit != 'cognac' && c.baseSpirit != 'campari' && c.baseSpirit != 'aperol')) return false;
        }
      }

      // Search
      if (_catalogSearch.isNotEmpty) {
        final q = _catalogSearch.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(q);
        final matchesDesc = c.description.toLowerCase().contains(q);
        final matchesCat = c.category.toLowerCase().contains(q);
        final matchesIng = c.ingredients.any((i) => i.name.toLowerCase().contains(q));
        return matchesName || matchesDesc || matchesCat || matchesIng;
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'missing':
          final cmp = a.missingCount.compareTo(b.missingCount);
          if (cmp != 0) return cmp;
          return a.cocktail.name.compareTo(b.cocktail.name);
        case 'name':
          return a.cocktail.name.compareTo(b.cocktail.name);
        case 'spirit':
          final cmp = a.cocktail.baseSpirit.compareTo(b.cocktail.baseSpirit);
          if (cmp != 0) return cmp;
          return a.cocktail.name.compareTo(b.cocktail.name);
        case 'difficulty':
          return a.cocktail.difficulty.compareTo(b.cocktail.difficulty);
        default:
          return a.missingCount.compareTo(b.missingCount);
      }
    });

    return Column(
      children: [
        // Search bar (if expanded) + compact filters with search icon on the left
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expandable Search Input
              if (_showCatalogSearch) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _catalogSearchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: isFr ? 'Rechercher un cocktail, ingrédient...' : 'Search cocktail, ingredient...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _catalogSearch.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _catalogSearchController.clear();
                                setState(() => _catalogSearch = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _catalogSearch = v.trim()),
                  ),
                ),
              ],

              // Single-row horizontal scroll filters with search icon on the left
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Search shortcut button on the left
                    Material(
                      color: _showCatalogSearch
                          ? const Color(0xFF8B1E3F)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _showCatalogSearch = !_showCatalogSearch;
                            if (!_showCatalogSearch) {
                              _catalogSearch = '';
                              _catalogSearchController.clear();
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showCatalogSearch ? Icons.search_off : Icons.search,
                                size: 18,
                                color: _showCatalogSearch ? Colors.white : theme.colorScheme.onSurface,
                              ),
                              if (_catalogSearch.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD4AF37),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Sort button
                    PopupMenuButton<String>(
                      tooltip: isFr ? 'Trier la liste' : 'Sort list',
                      initialValue: _sortBy,
                      onSelected: (val) => setState(() => _sortBy = val),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'missing',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: _sortBy == 'missing' ? const Color(0xFF2E7D32) : null),
                              const SizedBox(width: 8),
                              Text(isFr ? 'Les + faisables en 1er (Défaut)' : 'Most ready first (Default)'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'name',
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha, size: 18, color: _sortBy == 'name' ? const Color(0xFF8B1E3F) : null),
                              const SizedBox(width: 8),
                              Text(isFr ? 'Nom (A → Z)' : 'Name (A → Z)'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'spirit',
                          child: Row(
                            children: [
                              Icon(Icons.local_bar, size: 18, color: _sortBy == 'spirit' ? const Color(0xFF8B1E3F) : null),
                              const SizedBox(width: 8),
                              Text(isFr ? 'Alcool de base' : 'Base spirit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'difficulty',
                          child: Row(
                            children: [
                              Icon(Icons.speed, size: 18, color: _sortBy == 'difficulty' ? const Color(0xFF8B1E3F) : null),
                              const SizedBox(width: 8),
                              Text(isFr ? 'Difficulté' : 'Difficulty'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort, color: Color(0xFF8B1E3F), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _getSortLabel(_sortBy, isFr),
                              style: const TextStyle(
                                color: Color(0xFF8B1E3F),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${isFr ? "Tous" : "All"} (${allMatches.length})', style: const TextStyle(fontSize: 12)),
                      selected: (_filterStatus == 'all' || _filterStatus == 'Tous') && (_selectedCatalogSpirit == 'all' || _selectedCatalogSpirit == 'Tous'),
                      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                      checkmarkColor: const Color(0xFF8B1E3F),
                      onSelected: (_) => setState(() {
                        _filterStatus = 'all';
                        _selectedCatalogSpirit = 'all';
                      }),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
                      label: Text('${isFr ? "Prêts" : "Ready"} (${readyMatches.length})', style: const TextStyle(fontSize: 12)),
                      selected: _filterStatus == 'ready' || _filterStatus == 'Prêts',
                      selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.18),
                      checkmarkColor: const Color(0xFF2E7D32),
                      onSelected: (_) => setState(() => _filterStatus = (_filterStatus == 'ready' || _filterStatus == 'Prêts') ? 'all' : 'ready'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.pending_actions, size: 14, color: Colors.orange.shade800),
                      label: Text('${isFr ? "1 manquant" : "1 missing"} (${almostMatches.length})', style: const TextStyle(fontSize: 12)),
                      selected: _filterStatus == 'almost' || _filterStatus == '1 manquant',
                      selectedColor: Colors.orange.withValues(alpha: 0.18),
                      checkmarkColor: Colors.orange.shade800,
                      onSelected: (_) => setState(() => _filterStatus = (_filterStatus == 'almost' || _filterStatus == '1 manquant') ? 'all' : 'almost'),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 18,
                      width: 1.2,
                      color: theme.dividerColor.withValues(alpha: 0.4),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                    ),
                    const SizedBox(width: 6),
                    ...[
                      (key: 'custom', label: isFr ? '✨ Mes créations' : '✨ My creations'),
                      (key: 'gin', label: 'Gin'),
                      (key: 'rhum', label: isFr ? 'Rhum' : 'Rum'),
                      (key: 'whisky', label: 'Whisky'),
                      (key: 'vodka', label: 'Vodka'),
                      (key: 'tequila', label: 'Tequila'),
                      (key: 'aperitifs', label: isFr ? 'Apéritifs' : 'Aperitifs'),
                    ].map((item) {
                      final isSelected = _selectedCatalogSpirit == item.key || _selectedCatalogSpirit == item.label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(item.label, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                          checkmarkColor: const Color(0xFF8B1E3F),
                          onSelected: (_) => setState(() {
                            _selectedCatalogSpirit = isSelected ? 'all' : item.key;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Cocktails List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (_filterStatus == 'ready' || _filterStatus == 'Prêts') ? Icons.inventory_2_outlined : Icons.bookmark_border,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (_filterStatus == 'ready' || _filterStatus == 'Prêts')
                              ? (isFr ? 'Aucun cocktail 100% prêt pour l\'instant' : 'No 100% ready cocktails right now')
                              : (_selectedCatalogSpirit == 'custom' || _selectedCatalogSpirit == '✨ Mes créations')
                                  ? (isFr ? 'Aucune création enregistrée' : 'No custom creations saved')
                                  : (isFr ? 'Aucun cocktail trouvé' : 'No cocktails found'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (_filterStatus == 'ready' || _filterStatus == 'Prêts')
                              ? (isFr
                                  ? 'Allez dans l\'onglet "Réserve du Bar" pour cocher vos citrons, glaçons, tonics ou menthe fraîche !'
                                  : 'Go to the "Bar Pantry" tab to add your lemons, ice, tonics or fresh mint!')
                              : (_selectedCatalogSpirit == 'custom' || _selectedCatalogSpirit == '✨ Mes créations')
                                  ? (isFr
                                      ? 'Demandez au Chatmelier Mixologue de concevoir un cocktail sur-mesure !'
                                      : 'Ask Chatmelier Mixologist to design a custom cocktail!')
                                  : (isFr ? 'Essayez un autre filtre ou une autre recherche.' : 'Try another filter or search.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (_filterStatus == 'ready' || _filterStatus == 'Prêts') ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.kitchen_outlined),
                            label: Text(isFr ? 'Gérer ma Réserve' : 'Manage Pantry'),
                            onPressed: () => _tabController.animateTo(1),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final m = filtered[index];
                    return _buildCocktailCard(context, m, isReady: m.isReady, isFr: isFr);
                  },
                ),
        ),
      ],
    );
  }

  String _getSortLabel(String sort, bool isFr) {
    switch (sort) {
      case 'missing':
        return isFr ? 'Faisables d\'abord' : 'Ready first';
      case 'name':
        return isFr ? 'Nom (A-Z)' : 'Name (A-Z)';
      case 'spirit':
        return isFr ? 'Alcool' : 'Spirit';
      case 'difficulty':
        return isFr ? 'Difficulté' : 'Difficulty';
      default:
        return isFr ? 'Trier' : 'Sort';
    }
  }

  // ==========================================
  // Reusable Cocktail Card
  // ==========================================
  Widget _buildCocktailCard(
    BuildContext context,
    CocktailMatchResult match, {
    required bool isReady,
    required bool isFr,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = match.cocktail;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => CocktailDetailSheet.show(context, c),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Emoji Circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _getSpiritEmoji(c.baseSpirit),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (c.isCustom)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFD4AF37)),
                            ),
                            child: Text(
                              isFr ? '✨ Ma Recette' : '✨ My Recipe',
                              style: const TextStyle(
                                color: Color(0xFFB8860B),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isReady)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isFr ? 'Prêt' : 'Ready',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        else if (match.isAlmostReady)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isFr ? 'Manque 1' : '1 missing',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.glass} • ${c.prepTime} • ${c.difficulty}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (!isReady && match.missingIngredients.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${isFr ? "Manquant" : "Missing"} : ${match.missingIngredients.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddPantryItemDialog(BuildContext context, bool isFr) async {
    final nameCtrl = TextEditingController();
    PantryCategory selectedCat = PantryCategory.custom;
    final emojiCtrl = TextEditingController(text: '✨');
    final unitCtrl = TextEditingController(text: isFr ? 'unités' : 'units');
    final messenger = ScaffoldMessenger.of(context);

    try {
      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: Color(0xFF8B1E3F)),
                  const SizedBox(width: 8),
                  Text(isFr ? 'Nouvel ingrédient' : 'New Ingredient', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: isFr ? 'Nom de l\'ingrédient *' : 'Ingredient name *',
                        hintText: isFr ? 'Ex: Sirop de fleur de sureau, Yuzu...' : 'e.g. Elderflower syrup, Yuzu...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PantryCategory>(
                      initialValue: selectedCat,
                      decoration: InputDecoration(
                        labelText: isFr ? 'Catégorie' : 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: PantryCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 16),
                              const SizedBox(width: 8),
                              Text(cat.label(isFr)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCat = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: emojiCtrl,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: isFr ? 'Émoji' : 'Emoji',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            decoration: InputDecoration(
                              labelText: isFr ? 'Unité (ex: pièces, cl)' : 'Unit (e.g. pcs, cl)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(isFr ? 'Annuler' : 'Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E3F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    ref.read(barPantryProvider.notifier).addCustomItem(
                      name,
                      selectedCat,
                      unit: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : (isFr ? 'unités' : 'units'),
                      emoji: emojiCtrl.text.trim().isNotEmpty ? emojiCtrl.text.trim() : '🍹',
                    );
                    Navigator.pop(dialogCtx);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(isFr
                            ? 'Ingrédient "$name" ajouté à la réserve du bar !'
                            : 'Ingredient "$name" added to bar pantry!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(isFr ? 'Ajouter' : 'Add'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      nameCtrl.dispose();
      emojiCtrl.dispose();
      unitCtrl.dispose();
    }
  }

  void _confirmResetAll(BuildContext context, bool isFr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isFr ? 'Réinitialiser la Réserve du Bar ?' : 'Reset Bar Pantry?'),
        content: Text(
          isFr
              ? 'Voulez-vous remettre toutes les quantités d\'ingrédients frais, softs et herbes à 0 ?'
              : 'Do you want to reset all quantities of fresh ingredients, sodas and herbs to 0?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(barPantryProvider.notifier).resetAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isFr ? 'Réserve du bar réinitialisée à zéro.' : 'Bar pantry reset to zero.')),
              );
            },
            child: Text(isFr ? 'Tout réinitialiser' : 'Reset all'),
          ),
        ],
      ),
    );
  }

  void _askChatmelierMixologist(BuildContext context, int readyCount) {
    context.go('/chat');
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
