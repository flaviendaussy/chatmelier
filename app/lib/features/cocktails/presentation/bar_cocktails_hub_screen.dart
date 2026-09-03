import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../data/bar_pantry_service.dart';
import '../data/cocktail_catalog.dart';
import '../data/custom_cocktail_service.dart';
import '../domain/bar_pantry_item.dart';
import '../domain/cocktail.dart';
import '../domain/cocktail_matcher.dart';
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
  PantryCategory? _selectedPantryCategory;

  // Search & Filters for Catalog
  String _catalogSearch = '';
  String _selectedCatalogSpirit = 'Tous';

  // Sort for unified Cocktails tab
  String _sortBy = 'missing'; // 'missing', 'name', 'base_spirit', 'difficulty'
  String _filterStatus = 'Tous'; // 'Tous', 'Prêts', '1 manquant'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                color: const Color(0xFF8B1E3F).withOpacity(0.15),
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
            tooltip: 'Demander au Chatmelier Mixologue',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            onPressed: () => _askChatmelierMixologist(context, readyMatches.length),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B1E3F),
          indicatorWeight: 3,
          labelColor: const Color(0xFF8B1E3F),
          unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: readyMatches.isNotEmpty,
                backgroundColor: const Color(0xFF2E7D32),
                label: Text('${readyMatches.length}'),
                child: const Icon(Icons.local_bar, size: 20),
              ),
              text: 'Cocktails',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: pantry.where((i) => i.inStock).isNotEmpty,
                backgroundColor: const Color(0xFF8B1E3F),
                label: Text('${pantry.where((i) => i.inStock).length}'),
                child: const Icon(Icons.kitchen_outlined, size: 20),
              ),
              text: 'Mon Bar Pantry',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Cocktails (Catalogue unifié avec tri & filtres prêts à shaker)
          _buildCatalogTab(context, allMatches, readyMatches, almostMatches),

          // 2. Bar Pantry Stock
          _buildBarPantryTab(context, pantry),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: Cocktails Réalisables
  // ==========================================


  // ==========================================
  // TAB 2: Bar Pantry Stock
  // ==========================================
  Widget _buildBarPantryTab(BuildContext context, List<BarPantryItem> pantry) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = pantry.where((item) {
      if (_selectedPantryCategory != null && item.category != _selectedPantryCategory) {
        return false;
      }
      if (_pantrySearch.isNotEmpty) {
        final q = _pantrySearch.toLowerCase();
        return item.name.toLowerCase().contains(q) || item.category.labelFr.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Controls Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Search & Reset
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un ingrédient...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => setState(() => _pantrySearch = v.trim()),
                    ),
                  ),
                  // Add Custom Item Button
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _showAddPantryItemDialog(context),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _confirmResetAll(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _selectedPantryCategory == null,
                      onSelected: (_) => setState(() => _selectedPantryCategory = null),
                    ),
                    const SizedBox(width: 6),
                    ...PantryCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: Icon(cat.icon, size: 14),
                          label: Text(cat.labelFr),
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
                        ? const Color(0xFF2E7D32).withOpacity(0.12)
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: inStock
                        ? Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4))
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
                  '${item.category.labelFr} • ${item.unit}',
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
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = allMatches.where((m) {
      final c = m.cocktail;

      // Filter by readiness status
      if (_filterStatus == 'Prêts') {
        if (!m.isReady) return false;
      } else if (_filterStatus == '1 manquant') {
        if (!m.isAlmostReady) return false;
      }

      // Filter by base spirit / creations
      if (_selectedCatalogSpirit != 'Tous') {
        if (_selectedCatalogSpirit == '✨ Mes créations') {
          if (!c.isCustom) return false;
        } else {
          final target = _selectedCatalogSpirit.toLowerCase();
          if (target == 'gin' && c.baseSpirit != 'gin') return false;
          if (target == 'rhum' && c.baseSpirit != 'rhum') return false;
          if (target == 'whisky' && c.baseSpirit != 'whisky') return false;
          if (target == 'vodka' && c.baseSpirit != 'vodka') return false;
          if (target == 'tequila' && (c.baseSpirit != 'tequila' && c.baseSpirit != 'mezcal')) return false;
          if (target == 'apéritifs' && (c.baseSpirit != 'aperitif' && c.baseSpirit != 'liqueur' && c.baseSpirit != 'cognac')) return false;
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
        // Search & Sort bar + Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input + Sort button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un cocktail, ingrédient...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => setState(() => _catalogSearch = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Trier la liste',
                    initialValue: _sortBy,
                    onSelected: (val) => setState(() => _sortBy = val),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'missing',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 18, color: _sortBy == 'missing' ? const Color(0xFF2E7D32) : null),
                            const SizedBox(width: 8),
                            const Text('Les + faisables en 1er (Défaut)'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'name',
                        child: Row(
                          children: [
                            Icon(Icons.sort_by_alpha, size: 18, color: _sortBy == 'name' ? const Color(0xFF8B1E3F) : null),
                            const SizedBox(width: 8),
                            const Text('Nom (A → Z)'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'spirit',
                        child: Row(
                          children: [
                            Icon(Icons.local_bar, size: 18, color: _sortBy == 'spirit' ? const Color(0xFF8B1E3F) : null),
                            const SizedBox(width: 8),
                            const Text('Alcool de base'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'difficulty',
                        child: Row(
                          children: [
                            Icon(Icons.speed, size: 18, color: _sortBy == 'difficulty' ? const Color(0xFF8B1E3F) : null),
                            const SizedBox(width: 8),
                            const Text('Difficulté'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B1E3F).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort, color: Color(0xFF8B1E3F), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _getSortLabel(_sortBy),
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
                ],
              ),
              const SizedBox(height: 8),

              // Filter Row 1: Readiness Status Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('Tous (${allMatches.length})'),
                      selected: _filterStatus == 'Tous',
                      onSelected: (_) => setState(() => _filterStatus = 'Tous'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      avatar: const Icon(Icons.check_circle, size: 15, color: Color(0xFF2E7D32)),
                      label: Text('Prêts à shaker (${readyMatches.length})'),
                      selected: _filterStatus == 'Prêts',
                      selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                      onSelected: (_) => setState(() => _filterStatus = 'Prêts'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      avatar: Icon(Icons.pending_actions, size: 15, color: Colors.orange.shade800),
                      label: Text('1 manquant (${almostMatches.length})'),
                      selected: _filterStatus == '1 manquant',
                      selectedColor: Colors.orange.withOpacity(0.2),
                      onSelected: (_) => setState(() => _filterStatus = '1 manquant'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Filter Row 2: Spirits Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Tous',
                    '✨ Mes créations',
                    'Gin',
                    'Rhum',
                    'Whisky',
                    'Vodka',
                    'Tequila',
                    'Apéritifs',
                  ].map((spirit) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(spirit, style: const TextStyle(fontSize: 12)),
                        selected: _selectedCatalogSpirit == spirit,
                        onSelected: (_) => setState(() => _selectedCatalogSpirit = spirit),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Optional Ready Hero Banner when viewing all
        if (readyMatches.isNotEmpty && _filterStatus == 'Tous' && _catalogSearch.isEmpty) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🍸', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${readyMatches.length} cocktail${readyMatches.length > 1 ? "s" : ""} 100% prêt${readyMatches.length > 1 ? "s" : ""} à shaker !',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _filterStatus = 'Prêts'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Voir seulement les prêts',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

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
                          _filterStatus == 'Prêts' ? Icons.inventory_2_outlined : Icons.bookmark_border,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterStatus == 'Prêts'
                              ? 'Aucun cocktail 100% prêt pour l\'instant'
                              : _selectedCatalogSpirit == '✨ Mes créations'
                                  ? 'Aucune création enregistrée'
                                  : 'Aucun cocktail trouvé',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _filterStatus == 'Prêts'
                              ? 'Allez dans l\'onglet "Mon Bar Pantry" pour cocher vos citrons, glaçons, tonics ou menthe fraîche !'
                              : _selectedCatalogSpirit == '✨ Mes créations'
                                  ? 'Demandez au Chatmelier Mixologue de concevoir un cocktail sur-mesure !'
                                  : 'Essayez un autre filtre ou une autre recherche.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (_filterStatus == 'Prêts') ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.kitchen_outlined),
                            label: const Text('Gérer mon Bar Pantry'),
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
                    return _buildCocktailCard(context, m, isReady: m.isReady);
                  },
                ),
        ),
      ],
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'missing':
        return 'Faisables d\'abord';
      case 'name':
        return 'Nom (A-Z)';
      case 'spirit':
        return 'Alcool';
      case 'difficulty':
        return 'Difficulté';
      default:
        return 'Trier';
    }
  }

  // ==========================================
  // Reusable Cocktail Card
  // ==========================================
  Widget _buildCocktailCard(
    BuildContext context,
    CocktailMatchResult match, {
    required bool isReady,
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
                      ? const Color(0xFF2E7D32).withOpacity(0.12)
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
                              color: const Color(0xFFD4AF37).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFD4AF37)),
                            ),
                            child: const Text(
                              '✨ Ma Recette',
                              style: TextStyle(
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
                            child: const Text(
                              'Prêt',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        else if (match.isAlmostReady)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Manque 1',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                        'Manquant : ${match.missingIngredients.join(', ')}',
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

  void _showAddPantryItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    PantryCategory selectedCat = PantryCategory.custom;
    final emojiCtrl = TextEditingController(text: '✨');
    final unitCtrl = TextEditingController(text: 'unités');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFF8B1E3F)),
                SizedBox(width: 8),
                Text('Nouvel ingrédient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      labelText: 'Nom de l\'ingrédient *',
                      hintText: 'Ex: Sirop de fleur de sureau, Yuzu...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<PantryCategory>(
                    value: selectedCat,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: PantryCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 16),
                            const SizedBox(width: 8),
                            Text(cat.labelFr),
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
                            labelText: 'Émoji',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: InputDecoration(
                            labelText: 'Unité (ex: pièces, cl)',
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
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
                    unit: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'unités',
                    emoji: emojiCtrl.text.trim().isNotEmpty ? emojiCtrl.text.trim() : '🍹',
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ingrédient "$name" ajouté au bar pantry !'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmResetAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le Bar Pantry ?'),
        content: const Text(
          'Voulez-vous remettre toutes les quantités d\'ingrédients frais, softs et herbes à 0 ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
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
                const SnackBar(content: Text('Bar Pantry réinitialisé à zéro.')),
              );
            },
            child: const Text('Tout réinitialiser'),
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
