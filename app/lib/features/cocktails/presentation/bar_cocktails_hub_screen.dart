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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                child: const Icon(Icons.check_circle_outline, size: 20),
              ),
              text: 'Prêts à shaker',
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
            const Tab(
              icon: Icon(Icons.menu_book_outlined, size: 20),
              text: 'Catalogue',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Cocktails Réalisables
          _buildReadyCocktailsTab(context, readyMatches, almostMatches),

          // 2. Bar Pantry Stock
          _buildBarPantryTab(context, pantry),

          // 3. All Cocktails Catalog
          _buildCatalogTab(context, allMatches),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: Cocktails Réalisables
  // ==========================================
  Widget _buildReadyCocktailsTab(
    BuildContext context,
    List<CocktailMatchResult> ready,
    List<CocktailMatchResult> almost,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // AI Mixologist Hero Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B1E3F), Color(0xFF4A0E17)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B1E3F).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🍸', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chatmelier Mixologue IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Création sur-mesure d\'après vos spiritueux et vos ingrédients frais.',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _askChatmelierMixologist(context, ready.length),
                child: const Text('Créer ✨', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section Prêts à shaker
        Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22),
            const SizedBox(width: 8),
            Text(
              'Prêts à shaker (${ready.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Vous possédez 100% des spiritueux et ingrédients en stock !',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 12),

        if (ready.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
                const SizedBox(height: 10),
                const Text(
                  'Aucun cocktail 100% complet pour l\'instant',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Allez dans l\'onglet "Mon Bar Pantry" pour cocher les citrons, menthe ou softs que vous avez à la maison !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Mettre à jour mon stock'),
                  onPressed: () => _tabController.animateTo(1),
                ),
              ],
            ),
          )
        else
          ...ready.map((m) => _buildCocktailCard(context, m, isReady: true)),

        const SizedBox(height: 24),

        // Section Presque prêts
        Row(
          children: [
            Icon(Icons.pending_actions, color: Colors.orange.shade800, size: 22),
            const SizedBox(width: 8),
            Text(
              'Presque prêts (${almost.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Il ne vous manque qu\'un seul ingrédient pour les réaliser.',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 12),

        ...almost.map((m) => _buildCocktailCard(context, m, isReady: false)),
      ],
    );
  }

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
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset tout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
  // TAB 3: Catalogue des Cocktails
  // ==========================================
  Widget _buildCatalogTab(BuildContext context, List<CocktailMatchResult> allMatches) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = allMatches.where((m) {
      final c = m.cocktail;
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
      if (_catalogSearch.isNotEmpty) {
        final q = _catalogSearch.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un cocktail (ex: Mojito, Negroni)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _catalogSearch = v.trim()),
              ),
              const SizedBox(height: 8),
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
                    'Apéritifs'
                  ].map((spirit) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(spirit),
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

        const Divider(height: 1),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _selectedCatalogSpirit == '✨ Mes créations'
                              ? 'Aucune création enregistrée'
                              : 'Aucun cocktail trouvé',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedCatalogSpirit == '✨ Mes créations'
                              ? 'Demandez au Chatmelier Mixologue de vous concevoir un cocktail sur-mesure, puis enregistrez-le d\'un simple clic !'
                              : 'Essayez une autre recherche ou un autre spiritueux.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
    context.push('/chat', extra: {
      'initial_prompt':
          'Bonjour Chatmelier ! En tant qu\'expert sommelier et mixologue, propose-moi des créations de cocktails ou des variations audacieuses basées sur les spiritueux de ma cave et mes ingrédients frais en stock !'
    });
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
