import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/menu_wine.dart';
import 'menu_chat_assistant_sheet.dart';
import 'menu_matchmaker_sheet.dart';
import 'menu_wine_compare_sheet.dart';

class EnrichedMenuScreen extends ConsumerStatefulWidget {
  final ScannedMenu menu;

  const EnrichedMenuScreen({super.key, required this.menu});

  @override
  ConsumerState<EnrichedMenuScreen> createState() => _EnrichedMenuScreenState();
}

class _EnrichedMenuScreenState extends ConsumerState<EnrichedMenuScreen> {
  late ScannedMenu _menu;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedColor = 'all'; // 'all', 'red', 'white', 'rose', 'sparkling'
  String? _selectedTag; // e.g. 'minéral', 'beurré', 'tannique', etc.
  double? _maxPrice; // null = any
  final Set<String> _selectedWineIds = {};

  final List<String> _sensoryFilters = [
    'minéral',
    'beurré',
    'tannique',
    'fruité',
    'léger',
    'puissant',
    'boisé',
    'rond',
    'frais',
  ];

  @override
  void initState() {
    super.initState();
    _menu = widget.menu;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MenuWine> _filterWines() {
    return _menu.wines.where((wine) {
      // 1. Text Search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final match = wine.name.toLowerCase().contains(query) ||
            wine.producer.toLowerCase().contains(query) ||
            (wine.appellation?.toLowerCase().contains(query) ?? false) ||
            (wine.region?.toLowerCase().contains(query) ?? false) ||
            wine.grapes.any((g) => g.toLowerCase().contains(query));
        if (!match) return false;
      }

      // 2. Color filter
      if (_selectedColor != 'all') {
        if (_selectedColor == 'red' && !wine.isRed) return false;
        if (_selectedColor == 'white' && !wine.isWhite) return false;
        if (_selectedColor == 'rose' && !wine.isRose) return false;
        if (_selectedColor == 'sparkling' && !wine.isSparkling) return false;
      }

      // 3. Sensory tag filter
      if (_selectedTag != null && _selectedTag!.isNotEmpty) {
        if (!wine.tags.contains(_selectedTag!.toLowerCase())) {
          return false;
        }
      }

      // 4. Max Price filter
      if (_maxPrice != null) {
        final effectivePrice = wine.bottlePrice ?? wine.primaryGlassPrice ?? 999.0;
        if (effectivePrice > _maxPrice!) return false;
      }

      return true;
    }).toList();
  }

  void _editRestaurantName() {
    final nameCtrl = TextEditingController(text: _menu.restaurantName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nom de l\'établissement'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Restaurant / Bar'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _menu = ScannedMenu(
                    id: _menu.id,
                    restaurantName: newName,
                    scannedAt: _menu.scannedAt,
                    pagePhotoPaths: _menu.pagePhotoPaths,
                    wines: _menu.wines,
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredWines = _filterWines();

    final redCount = _menu.wines.where((w) => w.isRed).length;
    final whiteCount = _menu.wines.where((w) => w.isWhite).length;
    final sparklingCount = _menu.wines.where((w) => w.isSparkling).length;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _editRestaurantName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _menu.restaurantName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 16, color: Colors.grey),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Conseil Sommelier',
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD4AF37)),
            onPressed: () => MenuChatAssistantSheet.show(context, _menu),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Stats & Breakdown Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1E1925) : Colors.amber.shade50.withValues(alpha: 0.6),
            child: Row(
              children: [
                const Icon(Icons.menu_book, size: 18, color: Color(0xFF8B1E3F)),
                const SizedBox(width: 8),
                Text(
                  '${_menu.wines.length} références détectées',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '$whiteCount Blancs • $redCount Rouges • $sparklingCount Bulles',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 2. Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Rechercher un vin, domaine, cépage, appellation...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // 3. Color Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: _selectedColor == 'all',
                  onSelected: (_) => setState(() => _selectedColor = 'all'),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  avatar: const Icon(Icons.circle, size: 12, color: Color(0xFF8B1E3F)),
                  label: Text('Rouges ($redCount)'),
                  selected: _selectedColor == 'red',
                  onSelected: (_) => setState(() => _selectedColor = 'red'),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  avatar: const Icon(Icons.circle, size: 12, color: Color(0xFFE8D08D)),
                  label: Text('Blancs ($whiteCount)'),
                  selected: _selectedColor == 'white',
                  onSelected: (_) => setState(() => _selectedColor = 'white'),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  avatar: const Icon(Icons.circle, size: 12, color: Color(0xFFD4AF37)),
                  label: Text('Bulles ($sparklingCount)'),
                  selected: _selectedColor == 'sparkling',
                  onSelected: (_) => setState(() => _selectedColor = 'sparkling'),
                ),
              ],
            ),
          ),

          // 4. Sensory Tags Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Profil : ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                ..._sensoryFilters.map((tag) {
                  final isSelected = _selectedTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(tag[0].toUpperCase() + tag.substring(1)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                      onSelected: (val) {
                        setState(() => _selectedTag = val ? tag : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // 5. Wine List
          Expanded(
            child: filteredWines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Aucun vin ne correspond à vos filtres', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedColor = 'all';
                              _selectedTag = null;
                              _maxPrice = null;
                              _searchCtrl.clear();
                              _searchQuery = '';
                            });
                          },
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                    itemCount: filteredWines.length,
                    itemBuilder: (context, index) {
                      final wine = filteredWines[index];
                      final isSelected = _selectedWineIds.contains(wine.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF231D2A) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B1E3F)
                                : (isDark ? Colors.white10 : Colors.grey.shade200),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedWineIds.remove(wine.id);
                              } else {
                                _selectedWineIds.add(wine.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Checkbox for comparison
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: const Color(0xFF8B1E3F),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedWineIds.add(wine.id);
                                          } else {
                                            _selectedWineIds.remove(wine.id);
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    // Wine Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: wine.colorIndicator,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  wine.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${wine.producer} • ${wine.vintage != null ? wine.vintage.toString() : "NM"}'
                                            '${wine.appellation != null ? " • ${wine.appellation}" : (wine.region != null ? " • ${wine.region}" : "")}',
                                            style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Price Column
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (wine.bottlePrice != null)
                                          Text(
                                            '${wine.bottlePrice!.toStringAsFixed(wine.bottlePrice! % 1 == 0 ? 0 : 2)} €',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF8B1E3F),
                                            ),
                                          ),
                                        if (wine.glassPrices.isNotEmpty)
                                          Text(
                                            wine.glassPrices
                                                .map((g) => '${g.price.toStringAsFixed(0)}€/${g.format}')
                                                .join(' • '),
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Sensory Tags & Match Score Pill
                                Row(
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (wine.isRed && wine.metrics.tannins > 0)
                                            _buildMetricPill(
                                              'Tannins ${wine.metrics.tannins.toStringAsFixed(1)}/10',
                                              const Color(0xFF8B1E3F),
                                            ),
                                          if (wine.isWhite && wine.metrics.minerality > 0)
                                            _buildMetricPill(
                                              'Minéralité ${wine.metrics.minerality.toStringAsFixed(1)}/10',
                                              const Color(0xFF00897B),
                                            ),
                                          ...wine.tags.take(3).map((t) => _buildTagPill(t, isDark)),
                                        ],
                                      ),
                                    ),
                                    if (wine.userMatchScore != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.favorite, size: 12, color: Color(0xFF2E7D32)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${wine.userMatchScore!.round()}% Match',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                                if (wine.sommelierComment != null && wine.sommelierComment!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '« ${wine.sommelierComment} »',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Floating Action Bar: Compare / Matchmaker / Sommelier Chat
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Compare Button (active when >= 2 selected)
            Expanded(
              flex: 5,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedWineIds.length >= 2
                      ? const Color(0xFF8B1E3F)
                      : Colors.grey.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _selectedWineIds.length >= 2
                    ? () {
                        final selected =
                            _menu.wines.where((w) => _selectedWineIds.contains(w.id)).toList();
                        MenuWineCompareSheet.show(context, selected);
                      }
                    : null,
                icon: const Icon(Icons.radar, size: 18),
                label: Text(
                  _selectedWineIds.length >= 2
                      ? 'Comparer (${_selectedWineIds.length})'
                      : 'Sélectionner (min 2)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Matchmaker Button
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => MenuMatchmakerSheet.show(context, _menu.wines),
                icon: const Icon(Icons.style_outlined, size: 18, color: Color(0xFFD4AF37)),
                label: const Text(
                  'Matchmaker',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTagPill(String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}
