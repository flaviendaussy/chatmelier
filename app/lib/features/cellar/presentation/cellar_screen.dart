import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/widgets/bottle_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/cellar_filter_state.dart';
import '../domain/cellar_group_by.dart';
import '../domain/cellar_sort_by.dart';
import '../domain/bottle.dart';
import '../domain/wine.dart';
import 'bottle_list_item.dart';
import 'bottle_context_sheet.dart';
import 'cellar_filter_sheet.dart';
import 'cellar_switcher_sheet.dart';
import 'cellar_export_dialog.dart';
import 'cellar_food_pairing_sheet.dart';
import 'create_cellar_dialog.dart';
import 'cellar_proximity_banner.dart';
import '../../voice/presentation/voice_dictation_sheet.dart';
import '../../auth/presentation/mandatory_username_dialog.dart';
import '../../../shared/widgets/offline_sync_banner.dart';
import '../../../shared/widgets/grape_chart.dart';
import '../../../shared/utils/responsive_layout.dart';

enum CellarViewMode { grid, list, compact }

class CellarScreen extends ConsumerStatefulWidget {
  const CellarScreen({super.key});

  @override
  ConsumerState<CellarScreen> createState() => _CellarScreenState();
}

class _CellarScreenState extends ConsumerState<CellarScreen> {
  CellarViewMode _viewMode = CellarViewMode.grid;
  CellarSortBy _sortBy = CellarSortBy.recentlyAdded;
  String _searchQuery = '';
  bool _showSearchBar = false;
  final _searchController = TextEditingController();

  CellarFilterState _filter = const CellarFilterState();

  // Custom Grouping State
  CellarGroupBy _groupBy = CellarGroupBy.none;
  final Set<String> _collapsedGroups = {};

  // Pending invite count for badge
  int _pendingInviteCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingInviteCount();
    _loadGroupByPreference();
    _loadSortByPreference();
    _loadViewModePreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MandatoryUsernameDialog.checkAndPromptIfNeeded(context, ref);
    });
  }

  Future<void> _loadSortByPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('cellar_sort_by_mode');
      if (saved != null) {
        final mode = CellarSortBy.fromKey(saved);
        if (mounted) setState(() => _sortBy = mode);
      }
    } catch (_) {}
  }

  Future<void> _setSortBy(CellarSortBy newSortBy) async {
    HapticFeedback.selectionClick();
    setState(() => _sortBy = newSortBy);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cellar_sort_by_mode', newSortBy.key);
    } catch (_) {}
  }

  Future<void> _loadViewModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('cellar_view_mode');
      if (saved != null) {
        final mode = CellarViewMode.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => CellarViewMode.grid,
        );
        if (mounted) setState(() => _viewMode = mode);
      }
    } catch (_) {}
  }

  Future<void> _setViewMode(CellarViewMode newMode) async {
    HapticFeedback.selectionClick();
    setState(() => _viewMode = newMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cellar_view_mode', newMode.name);
    } catch (_) {}
  }

  Future<void> _loadGroupByPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('cellar_group_by_mode');
      if (saved != null) {
        final mode = CellarGroupBy.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => CellarGroupBy.none,
        );
        if (mounted) setState(() => _groupBy = mode);
      }
    } catch (_) {}
  }

  Future<void> _setGroupBy(CellarGroupBy newGroupBy) async {
    HapticFeedback.selectionClick();
    setState(() {
      _groupBy = newGroupBy;
      _collapsedGroups.clear();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cellar_group_by_mode', newGroupBy.name);
    } catch (_) {}
  }

  void _toggleGroupCollapse(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_collapsedGroups.contains(key)) {
        _collapsedGroups.remove(key);
      } else {
        _collapsedGroups.add(key);
      }
    });
  }

  void _expandAllGroups() {
    HapticFeedback.selectionClick();
    setState(() {
      _collapsedGroups.clear();
    });
  }

  void _collapseAllGroups(List<CellarGroupSection> sections) {
    HapticFeedback.selectionClick();
    setState(() {
      _collapsedGroups.addAll(sections.map((s) => s.key));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingInviteCount() async {
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    final email = supabase.auth.currentUser?.email;

    try {
      final res = await supabase
          .from('cellar_invites')
          .select('id')
          .eq('status', 'pending')
          .or('invited_user_id.eq.$userId,invited_email.eq.$email');

      if (mounted) {
        setState(() {
          _pendingInviteCount = (res as List).length;
        });
      }
    } catch (_) {}
  }

  List<Bottle> _filterBottles(List<Bottle> bottleList) {
    return bottleList.where((b) {
      final wine = b.wine;
      if (wine == null) return true;

      // 1. Wine Type filter
      if (_filter.wineType != null && _filter.wineType!.isNotEmpty) {
        final targetType = _filter.wineType!.toLowerCase();
        final actualType = wine.type.toLowerCase();
        if (targetType == 'red' && actualType != 'red' && actualType != 'rouge') return false;
        if (targetType == 'white' && actualType != 'white' && actualType != 'blanc') return false;
        if (targetType == 'rose' && !actualType.contains('ros')) return false;
        if (targetType == 'sparkling' && !actualType.contains('spark') && !actualType.contains('bull') && !actualType.contains('champ')) return false;
        if (targetType == 'dessert' && !actualType.contains('dessert') && !actualType.contains('moell') && !actualType.contains('liquor')) return false;
      }

      // 2. Continent filter
      if (_filter.continent != null) {
        final country = wine.country.toLowerCase();
        if (_filter.continent == 'Europe') {
          if (!country.contains('france') &&
              !country.contains('ital') &&
              !country.contains('spain') &&
              !country.contains('espag') &&
              !country.contains('portug') &&
              !country.contains('german') &&
              !country.contains('allemag')) {
            return false;
          }
        } else if (_filter.continent == 'Amériques') {
          if (!country.contains('state') &&
              !country.contains('unis') &&
              !country.contains('usa') &&
              !country.contains('calif') &&
              !country.contains('argentin') &&
              !country.contains('chili') &&
              !country.contains('canada')) {
            return false;
          }
        } else if (_filter.continent == 'Océanie') {
          if (!country.contains('austral') && !country.contains('zealand') && !country.contains('zélande')) {
            return false;
          }
        }
      }

      // 3. Country filter
      if (_filter.country != null) {
        final country = wine.country.toLowerCase();
        if (!country.contains(_filter.country!.toLowerCase())) return false;
      }

      // 4. Grape variety filter
      if (_filter.grape != null) {
        final targetGrape = _filter.grape!.toLowerCase();
        final grapeMatch = wine.grapes.any((g) => g.name.toLowerCase().contains(targetGrape));
        final nameMatch = wine.name.toLowerCase().contains(targetGrape);
        
        bool blendMatch = false;
        if (!grapeMatch && !nameMatch) {
          final resolvedGrapes = GrapeBlendResolver.resolveGrapes(
            existingGrapes: wine.grapes,
            wineType: wine.type,
            appellation: wine.appellation,
            region: wine.region,
            wineName: wine.name,
            producer: wine.producer,
            cuveeParcel: wine.cuveeParcel,
          );
          blendMatch = resolvedGrapes.any((g) => g.name.toLowerCase().contains(targetGrape));
        }

        if (!grapeMatch && !nameMatch && !blendMatch) return false;
      }

      // 5. Appellation / Region filter
      if (_filter.appellation != null) {
        final reg = wine.region.toLowerCase();
        final app = (wine.appellation ?? '').toLowerCase();
        final sub = (wine.subRegion ?? '').toLowerCase();
        final target = _filter.appellation!.toLowerCase();
        if (!reg.contains(target) && !app.contains(target) && !sub.contains(target)) return false;
      }

      // 6. Maturity status filter
      if (_filter.maturityStatus != null) {
        final status = wine.windowStatus;
        if (_filter.maturityStatus == 'peak' && status != DrinkWindowStatus.inPeak) return false;
        if (_filter.maturityStatus == 'drink_soon' && status != DrinkWindowStatus.drinkSoon) return false;
        if (_filter.maturityStatus == 'aging' && (status != DrinkWindowStatus.aging && status != DrinkWindowStatus.tooYoung)) return false;
        if (_filter.maturityStatus == 'young' && status != DrinkWindowStatus.tooYoung) return false;
        if (_filter.maturityStatus == 'past' && status != DrinkWindowStatus.pastPeak) return false;
      }

      // 7. Vintage filter
      if (_filter.vintage != null) {
        if (wine.vintage != _filter.vintage) return false;
      }

      // 7. Multi-field search query ("Où est ma bouteille ?")
      if (_searchQuery.isNotEmpty) {
        final queryTokens = _searchQuery.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
        
        for (final token in queryTokens) {
          final matchName = wine.name.toLowerCase().contains(token);
          final matchProd = (wine.producer ?? '').toLowerCase().contains(token);
          final matchReg = wine.region.toLowerCase().contains(token);
          final matchSubReg = (wine.subRegion ?? '').toLowerCase().contains(token);
          final matchApp = (wine.appellation ?? '').toLowerCase().contains(token);
          final matchCountry = wine.country.toLowerCase().contains(token);
          final matchVintage = wine.vintage != null && wine.vintage.toString().contains(token);
          final matchGrapes = wine.grapes.any((g) => g.name.toLowerCase().contains(token));
          final matchRack = (b.rack ?? '').toLowerCase().contains(token);
          final matchShelf = (b.shelf ?? '').toLowerCase().contains(token);
          final matchPosition = (b.position ?? '').toLowerCase().contains(token);
          final matchPurchaseLoc = (b.purchaseLocation ?? '').toLowerCase().contains(token);
          final matchNotes = (b.notes ?? '').toLowerCase().contains(token);
          final matchTastingNotes = (wine.tastingNotes ?? '').toLowerCase().contains(token);

          final tokenMatches = matchName ||
              matchProd ||
              matchReg ||
              matchSubReg ||
              matchApp ||
              matchCountry ||
              matchVintage ||
              matchGrapes ||
              matchRack ||
              matchShelf ||
              matchPosition ||
              matchPurchaseLoc ||
              matchNotes ||
              matchTastingNotes;

          if (!tokenMatches) return false;
        }
      }

      return true;
    }).toList();
  }

  List<Widget> _buildLocationSummaryChips(List<Bottle> bottleList) {
    final Map<String, int> locations = {};
    for (final b in bottleList) {
      String loc = 'Non classé';
      if (b.rack != null && b.rack!.isNotEmpty) {
        loc = '📍 ${b.rack}';
        if (b.shelf != null && b.shelf!.isNotEmpty) {
          loc += ' • ${b.shelf}';
        }
      } else if (b.shelf != null && b.shelf!.isNotEmpty) {
        loc = '📍 Tablette ${b.shelf}';
      }
      locations[loc] = (locations[loc] ?? 0) + b.quantity;
    }

    return locations.entries.map((e) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${e.key} (${e.value} btl)',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      );
    }).toList();
  }

  Widget _buildLocationSummaryHeader(ThemeData theme, List<Bottle> filteredList) {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    final totalCount = filteredList.fold<int>(0, (sum, b) => sum + b.quantity);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.saved_search, size: 20, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$totalCount bouteille${totalCount > 1 ? "s" : ""} trouvée${totalCount > 1 ? "s" : ""} (${filteredList.length} référence${filteredList.length > 1 ? "s" : ""})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _buildLocationSummaryChips(filteredList),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    final cellarsAsync = ref.watch(userCellarsProvider);
    final currentCellarId = ref.watch(currentCellarIdProvider);
    final activeRole = ref.watch(currentCellarRoleProvider);
    final isViewOnly = activeRole == 'viewer';

    final cellarsList = cellarsAsync.value ?? const [];
    
    String? resolvedCellarId = currentCellarId;
    String currentDisplayName = cellarsList.isEmpty ? 'Créer une cave' : 'Cave';

    if (cellarsList.isNotEmpty) {
      final existsInList = cellarsList.any((item) {
        final cMap = item['cellars'];
        final id = cMap is Map ? cMap['id']?.toString() : item['cellar_id']?.toString();
        return id == resolvedCellarId;
      });

      if (resolvedCellarId == null || !existsInList) {
        final first = cellarsList.first;
        final cMap = first['cellars'];
        if (cMap is Map) {
          resolvedCellarId = cMap['id']?.toString();
          currentDisplayName = cMap['name']?.toString() ?? 'Cave';
        } else {
          resolvedCellarId = first['cellar_id']?.toString();
        }
        if (resolvedCellarId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(currentCellarIdProvider.notifier).state = resolvedCellarId;
            }
          });
        }
      } else {
        for (final item in cellarsList) {
          final cMap = item['cellars'];
          if (cMap is Map && cMap['id']?.toString() == resolvedCellarId) {
            currentDisplayName = cMap['name']?.toString() ?? 'Cave';
            break;
          }
        }
      }
    }

    final activeCellarId = resolvedCellarId;
    final bottles = ref.watch(bottlesProvider(activeCellarId));

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => CellarSwitcherSheet.show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    currentDisplayName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_showSearchBar ? Icons.search_off : Icons.search),
            tooltip: 'Recherche',
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          // Voice Dictation
          IconButton(
            icon: const Icon(Icons.mic, color: Color(0xFF8B1E3F)),
            tooltip: 'Dictée Vocale Mains Libres',
            onPressed: () => VoiceDictationSheet.show(context),
          ),
          // View Mode Selector (Grid, List, Ultra-Compact)
          PopupMenuButton<CellarViewMode>(
            icon: Icon(
              _viewMode == CellarViewMode.grid
                  ? Icons.grid_view
                  : _viewMode == CellarViewMode.list
                      ? Icons.view_list
                      : Icons.density_small,
            ),
            tooltip: 'Mode d\'affichage (Grille / Liste / Compacte)',
            initialValue: _viewMode,
            onSelected: _setViewMode,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CellarViewMode.grid,
                child: Row(
                  children: [
                    Icon(Icons.grid_view, size: 20),
                    SizedBox(width: 12),
                    Text('Grille Visuelle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CellarViewMode.list,
                child: Row(
                  children: [
                    Icon(Icons.view_list, size: 20),
                    SizedBox(width: 12),
                    Text('Liste Détaillée'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CellarViewMode.compact,
                child: Row(
                  children: [
                    Icon(Icons.density_small, size: 20),
                    SizedBox(width: 12),
                    Text('Liste Ultra-Compacte (Pixel / Mobile)'),
                  ],
                ),
              ),
            ],
          ),
          // More options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options de la cave',
            onSelected: (value) {
              if (value == 'export') {
                CellarExportDialog.show(context, currentDisplayName);
              } else if (value == 'sharing') {
                if (activeCellarId != null) {
                  context.push(
                    '/sharing/$activeCellarId?name=${Uri.encodeComponent(currentDisplayName)}',
                  );
                }
              } else if (value == 'map') {
                context.push('/scratchcard');
              } else if (value == 'friends') {
                context.push('/friends');
              } else if (value == 'invites') {
                context.push('/invites');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'friends',
                child: Row(
                  children: [
                    Icon(Icons.people_alt, color: Color(0xFF8B1E3F), size: 20),
                    SizedBox(width: 12),
                    Text('Amis & Cartes des Goûts 🍷'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'map',
                child: Row(
                  children: [
                    Icon(Icons.public, color: Color(0xFFD4AF37), size: 20),
                    SizedBox(width: 12),
                    Text('Carte des Terroirs du Monde'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Exporter (CSV / Assurance)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sharing',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Membres & Partage'),
                  ],
                ),
              ),
              if (_pendingInviteCount > 0)
                PopupMenuItem(
                  value: 'invites',
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 20),
                      const SizedBox(width: 12),
                      Text('Invitations ($_pendingInviteCount)'),
                    ],
                  ),
                ),
            ],
          ),
          // Profile
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mon Profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineSyncBanner(),
          const CellarProximityBanner(),
          // View-only banner for shared cellars
          if (isViewOnly)
            Container(
              width: double.infinity,
              color: theme.colorScheme.tertiaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Mode consultation (lecture seule)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),

          // Search bar
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: l10n?.searchWinePlaceholder ?? 'Rechercher un millésime, domaine, appellation...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),

          // Interactive Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // Sort Selector Menu
                PopupMenuButton<CellarSortBy>(
                  tooltip: 'Trier les vins',
                  initialValue: _sortBy,
                  onSelected: _setSortBy,
                  itemBuilder: (context) => CellarSortBy.values.map((sb) {
                    final isSelected = _sortBy == sb;
                    return PopupMenuItem<CellarSortBy>(
                      value: sb,
                      child: Row(
                        children: [
                          Icon(sb.icon, size: 18, color: isSelected ? const Color(0xFFD4AF37) : null),
                          const SizedBox(width: 10),
                          Text(
                            sb.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFFD4AF37) : null,
                            ),
                          ),
                          if (isSelected) ...[
                            const Spacer(),
                            const Icon(Icons.check, size: 16, color: Color(0xFFD4AF37)),
                          ]
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _sortBy != CellarSortBy.recentlyAdded
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.18)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _sortBy != CellarSortBy.recentlyAdded
                            ? const Color(0xFFD4AF37)
                            : theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _sortBy.icon,
                          size: 15,
                          color: _sortBy != CellarSortBy.recentlyAdded ? const Color(0xFFD4AF37) : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _sortBy != CellarSortBy.recentlyAdded ? 'Tri: ${_sortBy.label}' : 'Trier',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _sortBy != CellarSortBy.recentlyAdded ? FontWeight.bold : FontWeight.w500,
                            color: _sortBy != CellarSortBy.recentlyAdded ? const Color(0xFFD4AF37) : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: _sortBy != CellarSortBy.recentlyAdded ? const Color(0xFFD4AF37) : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Grouping Selector Menu
                PopupMenuButton<CellarGroupBy>(
                  tooltip: 'Regrouper les vins',
                  initialValue: _groupBy,
                  onSelected: _setGroupBy,
                  itemBuilder: (context) => CellarGroupBy.values.map((gb) {
                    final isSelected = _groupBy == gb;
                    return PopupMenuItem<CellarGroupBy>(
                      value: gb,
                      child: Row(
                        children: [
                          Icon(gb.icon, size: 18, color: isSelected ? const Color(0xFF8B1E3F) : null),
                          const SizedBox(width: 10),
                          Text(
                            gb.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF8B1E3F) : null,
                            ),
                          ),
                          if (isSelected) ...[
                            const Spacer(),
                            const Icon(Icons.check, size: 16, color: Color(0xFF8B1E3F)),
                          ]
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _groupBy != CellarGroupBy.none
                          ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _groupBy != CellarGroupBy.none
                            ? const Color(0xFF8B1E3F)
                            : theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _groupBy != CellarGroupBy.none ? _groupBy.icon : Icons.folder_copy_outlined,
                          size: 15,
                          color: _groupBy != CellarGroupBy.none ? const Color(0xFF8B1E3F) : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _groupBy != CellarGroupBy.none ? 'Par ${_groupBy.label}' : 'Regrouper',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _groupBy != CellarGroupBy.none ? FontWeight.bold : FontWeight.w500,
                            color: _groupBy != CellarGroupBy.none ? const Color(0xFF8B1E3F) : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: _groupBy != CellarGroupBy.none ? const Color(0xFF8B1E3F) : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Food Pairing Sommelier Matcher Shortcut
                ActionChip(
                  avatar: const Text('🍽️', style: TextStyle(fontSize: 14)),
                  label: const Text(
                    'Quel vin pour mon plat ?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                  ),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2B221E)
                      : const Color(0xFFFAF0E6),
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final bottleList = bottles.value ?? <Bottle>[];
                    CellarFoodPairingSheet.show(
                      context,
                      bottles: bottleList,
                      cellarName: currentDisplayName,
                    );
                  },
                ),
                const SizedBox(width: 8),

                // All Types
                FilterChip(
                  label: Text(l10n?.filterAll ?? 'Tous'),
                  selected: _filter.wineType == null,
                  selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
                  checkmarkColor: const Color(0xFF8B1E3F),
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    if (selected) {
                      setState(() => _filter = _filter.copyWith(wineType: () => null));
                    }
                  },
                ),
                const SizedBox(width: 6),

                // Red
                FilterChip(
                  avatar: const Text('🔴', style: TextStyle(fontSize: 12)),
                  label: Text(l10n?.filterRed ?? 'Rouge'),
                  selected: _filter.wineType == 'red',
                  selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
                  checkmarkColor: const Color(0xFF8B1E3F),
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'red' : null));
                  },
                ),
                const SizedBox(width: 6),

                // White
                FilterChip(
                  avatar: const Text('⚪', style: TextStyle(fontSize: 12)),
                  label: Text(l10n?.filterWhite ?? 'Blanc'),
                  selected: _filter.wineType == 'white',
                  selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
                  checkmarkColor: const Color(0xFF8B1E3F),
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'white' : null));
                  },
                ),
                const SizedBox(width: 6),

                // Rosé
                FilterChip(
                  avatar: const Text('🌸', style: TextStyle(fontSize: 12)),
                  label: Text(l10n?.filterRose ?? 'Rosé'),
                  selected: _filter.wineType == 'rose',
                  selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
                  checkmarkColor: const Color(0xFF8B1E3F),
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'rose' : null));
                  },
                ),
                const SizedBox(width: 6),

                // Sparkling
                FilterChip(
                  avatar: const Text('🍾', style: TextStyle(fontSize: 12)),
                  label: Text(l10n?.filterSparkling ?? 'Bulles'),
                  selected: _filter.wineType == 'sparkling',
                  selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
                  checkmarkColor: const Color(0xFF8B1E3F),
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'sparkling' : null));
                  },
                ),
                const SizedBox(width: 8),

                // More filters (Continent, Country, Grape, Appellation, Maturity)
                ActionChip(
                  avatar: Badge(
                    isLabelVisible: _filter.activeFilterCount > 0,
                    label: Text('${_filter.activeFilterCount}'),
                    child: const Icon(Icons.tune, size: 16),
                  ),
                  label: Text(_filter.activeFilterCount > 0 ? '${l10n?.filterSheetTitle ?? "Filtres"} (${_filter.activeFilterCount})' : (l10n?.filterSheetTitle ?? 'Plus de filtres')),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CellarFilterSheet(
                        initialFilter: _filter,
                        bottles: bottles.value ?? <Bottle>[],
                        onApply: (newFilter) => setState(() => _filter = newFilter),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottle grid or list
          if (cellarsList.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wine_bar, size: 64, color: Color(0xFF8B1E3F)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bienvenue sur Chatmelier 🍷',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pour commencer à gérer vos bouteilles, créez votre première cave à vin personnalisée.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Créer ma première cave'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          backgroundColor: const Color(0xFF8B1E3F),
                        ),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => const CreateCellarDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: bottles.when(
                data: (bottleList) {
                  if (bottleList.isEmpty) {
                    return EmptyState(
                      icon: Icons.wine_bar_outlined,
                      title: 'Aucune bouteille',
                      subtitle: isViewOnly
                          ? 'Cette cave est vide'
                          : 'Touchez Actions Cave pour ajouter votre première bouteille !',
                    );
                  }

                  final filteredList = _filterBottles(bottleList);

                  if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off, size: 48, color: theme.colorScheme.onSurfaceVariant.withAlpha(120)),
                        const SizedBox(height: 12),
                        const Text('Aucune bouteille ne correspond à ces critères', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _filter = const CellarFilterState()),
                          child: const Text('Effacer les filtres'),
                        ),
                      ],
                    ),
                  );
                }

                  final sortedList = _sortBy.sort(filteredList);
                  final totalBottles = sortedList.fold<int>(0, (sum, b) => sum + b.quantity);

                  Widget mainContent;

                  if (_groupBy != CellarGroupBy.none) {
                    final sections = CellarGroupEngine.partitionBottles(
                      sortedList,
                      _groupBy,
                      sortBy: _sortBy,
                    );
                    mainContent = _buildGroupedBottleView(
                      theme: theme,
                      sections: sections,
                      activeCellarId: activeCellarId ?? '',
                      totalBottles: totalBottles,
                      totalReferences: sortedList.length,
                    );
                  } else {
                    mainContent = _viewMode == CellarViewMode.grid
                        ? GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              mainAxisExtent: 295,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: sortedList.length,
                            itemBuilder: (context, index) {
                              final bottle = sortedList[index];
                              return BottleCard(
                                bottle: bottle,
                                onTap: () => context.push('/cellar/${bottle.id}'),
                                onLongPress: () => BottleContextSheet.show(
                                  context,
                                  bottle: bottle,
                                  cellarId: activeCellarId ?? '',
                                ),
                              ).animate()
                                .fadeIn(delay: Duration(milliseconds: index * 40))
                                .slideY(begin: 0.08, end: 0);
                            },
                          )
                        : ResponsiveContentWrapper(
                            maxWidth: 1000,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: _viewMode == CellarViewMode.compact ? 8 : 12,
                                vertical: _viewMode == CellarViewMode.compact ? 4 : 12,
                              ),
                              itemCount: sortedList.length,
                              itemBuilder: (context, index) {
                                final bottle = sortedList[index];
                                return BottleListItem(
                                  bottle: bottle,
                                  isUltraCompact: _viewMode == CellarViewMode.compact,
                                  onTap: () => context.push('/cellar/${bottle.id}'),
                                  onLongPress: () => BottleContextSheet.show(
                                    context,
                                    bottle: bottle,
                                    cellarId: activeCellarId ?? '',
                                  ),
                                ).animate()
                                  .fadeIn(delay: Duration(milliseconds: index * 25));
                              },
                            ),
                          );
                  }

                  Widget finalView = _searchQuery.isNotEmpty
                      ? Column(
                          children: [
                            _buildLocationSummaryHeader(theme, sortedList),
                            Expanded(child: mainContent),
                          ],
                        )
                      : mainContent;

                  return RefreshIndicator(
                    onRefresh: () async {
                      notifyCellarChanged(ref, activeCellarId);
                      await Future.delayed(const Duration(milliseconds: 200));
                    },
                    child: finalView,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Erreur : $err')),
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildGroupedBottleView({
    required ThemeData theme,
    required List<CellarGroupSection> sections,
    required String activeCellarId,
    required int totalBottles,
    required int totalReferences,
  }) {
    final allCollapsed = sections.isNotEmpty && sections.every((s) => _collapsedGroups.contains(s.key));

    return Column(
      children: [
        // Group summary & Global Collapse / Expand controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sections.length} groupe${sections.length > 1 ? "s" : ""} • $totalBottles btl',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B1E3F),
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: Icon(
                  allCollapsed ? Icons.unfold_more : Icons.unfold_less,
                  size: 16,
                  color: const Color(0xFFD4AF37),
                ),
                label: Text(
                  allCollapsed ? 'Tout déplier' : 'Tout replier',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                onPressed: () {
                  if (allCollapsed) {
                    _expandAllGroups();
                  } else {
                    _collapseAllGroups(sections);
                  }
                },
              ),
            ],
          ),
        ),

        // Group sections list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: sections.length,
            itemBuilder: (context, sIdx) {
              final section = sections[sIdx];
              final isCollapsed = _collapsedGroups.contains(section.key);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: section.color?.withValues(alpha: 0.3) ??
                        theme.dividerColor.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Accordion Header
                    InkWell(
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(16),
                        bottom: Radius.circular(isCollapsed ? 16 : 0),
                      ),
                      onTap: () => _toggleGroupCollapse(section.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: (section.color ?? const Color(0xFF8B1E3F))
                              .withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.06),
                          borderRadius: BorderRadius.vertical(
                            top: const Radius.circular(16),
                            bottom: Radius.circular(isCollapsed ? 16 : 0),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (section.emoji.isNotEmpty)
                              Text(section.emoji, style: const TextStyle(fontSize: 18))
                            else if (section.icon != null)
                              Icon(section.icon, size: 18, color: section.color ?? const Color(0xFF8B1E3F)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                section.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Bottle count badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: (section.color ?? const Color(0xFF8B1E3F)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${section.totalBottleCount} btl',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: section.color ?? const Color(0xFF8B1E3F),
                                ),
                              ),
                            ),
                            if (section.totalEstimatedValue > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${section.totalEstimatedValue.toStringAsFixed(0)} €',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4AF37),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: isCollapsed ? -0.25 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.expand_more, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Section Content (if expanded)
                    if (!isCollapsed) ...[
                      const Divider(height: 1, thickness: 0.8),
                      Padding(
                        padding: EdgeInsets.all(_viewMode == CellarViewMode.compact ? 6 : 10),
                        child: Builder(
                          builder: (context) {
                            final sortedSectionBottles = _sortBy.sort(section.bottles);
                            if (_viewMode == CellarViewMode.grid) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 250,
                                  mainAxisExtent: 295,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: sortedSectionBottles.length,
                                itemBuilder: (context, bIdx) {
                                  final bottle = sortedSectionBottles[bIdx];
                                  return BottleCard(
                                    bottle: bottle,
                                    onTap: () => context.push('/cellar/${bottle.id}'),
                                    onLongPress: () => BottleContextSheet.show(
                                      context,
                                      bottle: bottle,
                                      cellarId: activeCellarId,
                                    ),
                                  );
                                },
                              );
                            } else {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sortedSectionBottles.length,
                                separatorBuilder: (_, __) => SizedBox(height: _viewMode == CellarViewMode.compact ? 3 : 6),
                                itemBuilder: (context, bIdx) {
                                  final bottle = sortedSectionBottles[bIdx];
                                  return BottleListItem(
                                    bottle: bottle,
                                    isUltraCompact: _viewMode == CellarViewMode.compact,
                                    onTap: () => context.push('/cellar/${bottle.id}'),
                                    onLongPress: () => BottleContextSheet.show(
                                      context,
                                      bottle: bottle,
                                      cellarId: activeCellarId,
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
