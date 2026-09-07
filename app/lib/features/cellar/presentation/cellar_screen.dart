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
import '../domain/cellar_furniture.dart';
import 'bottle_list_item.dart';
import 'bottle_context_sheet.dart';
import 'cellar_filter_sheet.dart';
import 'cellar_switcher_sheet.dart';
import 'cellar_food_pairing_sheet.dart';
import 'create_cellar_dialog.dart';
import 'shelf_grid_view_sheet.dart';
import '../data/favorite_wines_service.dart';
import 'cellar_proximity_banner.dart';
import '../../voice/presentation/voice_dictation_sheet.dart';
import '../../auth/presentation/mandatory_username_dialog.dart';
import '../../../shared/widgets/offline_sync_banner.dart';
import '../../../shared/widgets/grape_chart.dart';
import '../../../shared/utils/responsive_layout.dart';
import '../../../shared/widgets/notification_bell_button.dart';

enum CellarViewMode { grid, list }

class CellarScreen extends ConsumerStatefulWidget {
  const CellarScreen({super.key});

  @override
  ConsumerState<CellarScreen> createState() => _CellarScreenState();
}

class _CellarScreenState extends ConsumerState<CellarScreen>
    with TickerProviderStateMixin {
  CellarViewMode _viewMode = CellarViewMode.grid;
  CellarSortBy _sortBy = CellarSortBy.recentlyAdded;
  String _searchQuery = '';
  bool _showSearchBar = false;
  final _searchController = TextEditingController();

  CellarFilterState _filter = const CellarFilterState();

  // Tab controller for swipeable Vins vs Spiritueux zones
  TabController? _tabController;
  int _activeTabIndex = 0; // 0 = wines, 1 = spirits (when both exist)

  // Custom Grouping State
  CellarGroupBy _groupBy = CellarGroupBy.none;
  final Set<String> _collapsedGroups = {};

  // Total Costs display toggle (defaults to false)
  bool _showTotalCosts = false;

  bool get _isViewOnly => ref.watch(currentCellarRoleProvider) == 'viewer';

  // Pending invite count for badge
  int _pendingInviteCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingInviteCount();
    _loadGroupByPreference();
    _loadSortByPreference();
    _loadViewModePreference();
    _loadTotalCostsPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MandatoryUsernameDialog.checkAndPromptIfNeeded(context, ref);
    });
  }

  Future<void> _loadTotalCostsPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('cellar_show_total_costs') ?? false;
      if (mounted) setState(() => _showTotalCosts = saved);
    } catch (_) {}
  }

  Future<void> _toggleTotalCosts() async {
    HapticFeedback.selectionClick();
    final next = !_showTotalCosts;
    setState(() => _showTotalCosts = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cellar_show_total_costs', next);
    } catch (_) {}
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
        final mode = (saved == 'grid') ? CellarViewMode.grid : CellarViewMode.list;
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

  void _onTabChanged() {
    if (mounted && _tabController != null && _activeTabIndex != _tabController!.index) {
      setState(() {
        _activeTabIndex = _tabController!.index;
        // Reset specific type filter when switching between Vins and Spiritueux
        _filter = _filter.copyWith(wineType: () => null);
      });
    }
  }

  void _updateTabController(int count) {
    if (_tabController == null || _tabController!.length != count) {
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();
      _tabController = TabController(
        length: count,
        vsync: this,
        initialIndex: oldIndex.clamp(0, count - 1),
      );
      _activeTabIndex = _tabController!.index;
      _tabController!.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
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
    final favIds = ref.watch(favoriteWineIdsProvider);

    return bottleList.where((b) {
      final wine = b.wine;
      if (wine == null) return true;

      // 0. Favorites filter
      if (_filter.onlyFavorites) {
        final isFav = favIds.contains(b.id) || (favIds.contains(wine.id));
        if (!isFav) return false;
      }

      // 1. Wine or Spirit Type filter
      if (_filter.wineType != null && _filter.wineType!.isNotEmpty) {
        final targetType = _filter.wineType!.toLowerCase();
        final actualType = wine.type.toLowerCase();
        final actualName = wine.name.toLowerCase();

        if (targetType == 'red') {
          if (actualType != 'red' && actualType != 'rouge') return false;
        } else if (targetType == 'white') {
          if (actualType != 'white' && actualType != 'blanc') return false;
        } else if (targetType == 'rose') {
          if (!actualType.contains('ros')) return false;
        } else if (targetType == 'sparkling') {
          if (!actualType.contains('spark') && !actualType.contains('bull') && !actualType.contains('champ')) return false;
        } else if (targetType == 'dessert') {
          if (!actualType.contains('dessert') && !actualType.contains('moell') && !actualType.contains('liquor')) return false;
        } else if (targetType == 'gin') {
          if (!actualType.contains('gin') && !actualName.contains('gin')) return false;
        } else if (targetType == 'whisky') {
          if (!actualType.contains('whisk') && !actualType.contains('bourbon') && !actualType.contains('scotch') && !actualName.contains('whisk') && !actualName.contains('bourbon')) return false;
        } else if (targetType == 'rum') {
          if (!actualType.contains('rum') && !actualType.contains('rhum') && !actualName.contains('rum') && !actualName.contains('rhum')) return false;
        } else if (targetType == 'vodka') {
          if (!actualType.contains('vodka') && !actualName.contains('vodka')) return false;
        } else if (targetType == 'liqueur') {
          if (!actualType.contains('liqueur') && !actualType.contains('rosolio') && !actualType.contains('amaretto') && !actualName.contains('liqueur') && !actualName.contains('crème de') && !actualName.contains('creme de')) return false;
        } else if (targetType == 'grappa') {
          if (!actualType.contains('grappa') && !actualType.contains('eau-de-vie') && !actualType.contains('eau de vie') && !actualName.contains('grappa') && !actualName.contains('eau de vie') && !actualName.contains('eau-de-vie')) return false;
        } else if (targetType == 'tequila') {
          if (!actualType.contains('tequila') && !actualType.contains('mezcal') && !actualName.contains('tequila') && !actualName.contains('mezcal')) return false;
        } else if (targetType == 'cognac') {
          if (!actualType.contains('cognac') && !actualType.contains('armagnac') && !actualType.contains('calvados') && !actualName.contains('cognac') && !actualName.contains('armagnac') && !actualName.contains('calvados')) return false;
        } else {
          if (actualType != targetType && !actualName.contains(targetType)) return false;
        }
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
    final currentCellarId = ref.watch(currentCellarIdProvider);
    final furnitures = currentCellarId != null
        ? (ref.watch(cellarFurnitureProvider(currentCellarId)).value ?? const <CellarFurniture>[])
        : const <CellarFurniture>[];
    final furnitureMap = {for (final f in furnitures) f.id: f};

    final Map<String, int> locations = {};
    for (final b in bottleList) {
      String loc = 'Non classé';
      if (b.furnitureId != null && b.furnitureId!.isNotEmpty) {
        final f = furnitureMap[b.furnitureId];
        final fName = f?.name ?? 'Meuble';
        if (b.furnitureSlot != null && b.furnitureSlot!.isNotEmpty) {
          final slotStr = b.furnitureSlot!;
          final lower = slotStr.trim().toLowerCase();
          String slotDesc;
          if (f?.isCupboard == true) {
            if (lower.startsWith('etagere') || lower.startsWith('étagère') || lower.startsWith('niveau')) {
              slotDesc = slotStr.trim();
            } else {
              final parsed = CellarFurniture.parseSlotCode(slotStr);
              if (parsed != null) {
                slotDesc = 'Étagère ${parsed.row + 1}';
              } else {
                final match = RegExp(r'\d+').firstMatch(slotStr);
                slotDesc = match != null ? 'Étagère ${match.group(0)}' : slotStr;
              }
            }
          } else {
            slotDesc = CellarFurniture.describeSlotCode(slotStr);
          }
          loc = '📍 $fName ($slotDesc)';
        } else {
          loc = '📍 $fName';
        }
      } else if (b.furnitureSlot != null && b.furnitureSlot!.isNotEmpty) {
        loc = '📍 ${CellarFurniture.describeSlotCode(b.furnitureSlot!)}';
      } else if (b.rack != null && b.rack!.isNotEmpty) {
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
    String? currentWifiSsid;

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
          final raw = cMap['name']?.toString() ?? 'Cave';
          final isFr = Localizations.localeOf(context).languageCode == 'fr';
          currentDisplayName = (raw == 'Ma Cave' || raw == 'My Cellar') ? (isFr ? 'Ma Cave' : 'My Cellar') : raw;
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
            final raw = cMap['name']?.toString() ?? 'Cave';
            final isFr = Localizations.localeOf(context).languageCode == 'fr';
            currentDisplayName = (raw == 'Ma Cave' || raw == 'My Cellar') ? (isFr ? 'Ma Cave' : 'My Cellar') : raw;
            currentWifiSsid = cMap['wifi_ssid'] as String?;
            break;
          }
        }
      }
    }

    final activeCellarId = resolvedCellarId;
    final bottles = ref.watch(bottlesProvider(activeCellarId));

    final canPopCellar = !_showSearchBar && !(_tabController != null && _tabController!.index > 0);

    return PopScope(
      canPop: canPopCellar,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showSearchBar) {
          setState(() {
            _showSearchBar = false;
            _searchQuery = '';
            _searchController.clear();
          });
          return;
        }
        if (_tabController != null && _tabController!.index > 0) {
          _tabController!.animateTo(0);
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => CellarSwitcherSheet.show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                if (currentWifiSsid != null && currentWifiSsid.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi, size: 11, color: Color(0xFF1976D2)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'Wi-Fi : "$currentWifiSsid"',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF1976D2), fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          // Notification Bell with live badge
          const NotificationBellButton(),
          // Mode Shelves (Meubles & Rayonnages)
          IconButton(
            icon: const Icon(Icons.shelves, color: Color(0xFFD4AF37)),
            tooltip: 'Meubles & Rayonnages (Mode Shelves)',
            onPressed: () {
              final cid = currentCellarId;
              if (cid != null) {
                ShelfGridViewSheet.show(context, cellarId: cid);
              }
            },
          ),
          // Importer Excel / CSV
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Color(0xFF2E7D32)),
            tooltip: 'Importer un fichier (Excel / CSV)',
            onPressed: () {
              final cid = currentCellarId;
              context.push('/cellar/import-excel?cellarId=${cid ?? ""}');
            },
          ),
          // Voice Dictation
          IconButton(
            icon: const Icon(Icons.mic, color: Color(0xFF8B1E3F)),
            tooltip: 'Dictée Vocale Mains Libres',
            onPressed: () => VoiceDictationSheet.show(context),
          ),
          // View Mode Selector (Grid / Liste)
          PopupMenuButton<CellarViewMode>(
            icon: Icon(
              _viewMode == CellarViewMode.grid ? Icons.grid_view : Icons.view_list,
            ),
            tooltip: 'Mode d\'affichage (Grille / Liste)',
            initialValue: _viewMode,
            onSelected: _setViewMode,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CellarViewMode.grid,
                child: Row(
                  children: [
                    Icon(Icons.grid_view, size: 20),
                    SizedBox(width: 12),
                    Text('Grille'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CellarViewMode.list,
                child: Row(
                  children: [
                    Icon(Icons.view_list, size: 20),
                    SizedBox(width: 12),
                    Text('Liste'),
                  ],
                ),
              ),
            ],
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

          // Bottle grid, list or empty state
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
                          : 'Touchez Actions Cave pour ajouter une bouteille ou importez directement votre fichier Excel / CSV !',
                      action: isViewOnly
                          ? null
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.table_chart_outlined),
                              label: const Text('Importer un fichier Excel / CSV'),
                              onPressed: () {
                                context.push('/cellar/import-excel?cellarId=${currentCellarId ?? ""}');
                              },
                            ),
                    );
                  }

                  final wineBottles = bottleList.where((b) => !(b.wine?.isSpirit ?? false)).toList();
                  final spiritBottles = bottleList.where((b) => (b.wine?.isSpirit ?? false)).toList();
                  final hasWines = wineBottles.isNotEmpty;
                  final hasSpirits = spiritBottles.isNotEmpty;
                  final hasBoth = hasWines && hasSpirits;

                  _updateTabController(hasBoth ? 2 : 1);
                  final isSpiritsView = hasBoth ? (_activeTabIndex == 1) : (!hasWines && hasSpirits);
                  final displayedBottles = isSpiritsView ? spiritBottles : wineBottles;

                  return Column(
                    children: [
                      // Search button to the left of the Vins / Spiritueux selector
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: Row(
                          children: [
                            // Search toggle button
                            Material(
                              color: _showSearchBar
                                  ? const Color(0xFF8B1E3F)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _showSearchBar = !_showSearchBar;
                                    if (!_showSearchBar) {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _showSearchBar ? Icons.search_off : Icons.search,
                                        size: 20,
                                        color: _showSearchBar ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                      if (_searchQuery.isNotEmpty) ...[
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
                            const SizedBox(width: 8),

                            // Swipeable category tabs or single view header
                            if (hasBoth)
                              Expanded(
                                child: Container(
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
                                            const Text('🍷 Vins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _activeTabIndex == 0
                                                    ? Colors.white.withValues(alpha: 0.25)
                                                    : const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${wineBottles.fold<int>(0, (sum, b) => sum + b.quantity)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _activeTabIndex == 0 ? Colors.white : const Color(0xFF8B1E3F),
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
                                            const Text('🥃 Spiritueux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _activeTabIndex == 1
                                                    ? Colors.white.withValues(alpha: 0.25)
                                                    : const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${spiritBottles.fold<int>(0, (sum, b) => sum + b.quantity)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _activeTabIndex == 1 ? Colors.white : const Color(0xFF8B1E3F),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        isSpiritsView ? '🥃 Spiritueux' : '🍷 Vins',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${displayedBottles.fold<int>(0, (sum, b) => sum + b.quantity)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Filter chips row
                      _buildFilterRow(
                        theme: theme,
                        l10n: l10n,
                        isSpiritsView: isSpiritsView,
                        displayedBottles: displayedBottles,
                        currentDisplayName: currentDisplayName,
                      ),

                      // Swipeable or single bottle view
                      Expanded(
                        child: hasBoth
                            ? TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildBottleView(
                                    theme: theme,
                                    sourceBottles: wineBottles,
                                    activeCellarId: activeCellarId ?? '',
                                    isViewOnly: isViewOnly,
                                  ),
                                  _buildBottleView(
                                    theme: theme,
                                    sourceBottles: spiritBottles,
                                    activeCellarId: activeCellarId ?? '',
                                    isViewOnly: isViewOnly,
                                  ),
                                ],
                              )
                            : _buildBottleView(
                                theme: theme,
                                sourceBottles: isSpiritsView ? spiritBottles : wineBottles,
                                activeCellarId: activeCellarId ?? '',
                                isViewOnly: isViewOnly,
                              ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Erreur : $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow({
    required ThemeData theme,
    required AppLocalizations? l10n,
    required bool isSpiritsView,
    required List<Bottle> displayedBottles,
    required String currentDisplayName,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // 1. Prominent unnamed filter icon button with badge
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => CellarFilterSheet(
                  initialFilter: _filter,
                  bottles: displayedBottles,
                  onApply: (newFilter) => setState(() => _filter = newFilter),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _filter.activeFilterCount > 0
                    ? const Color(0xFF8B1E3F).withValues(alpha: 0.18)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _filter.activeFilterCount > 0
                      ? const Color(0xFF8B1E3F)
                      : theme.dividerColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Badge(
                isLabelVisible: _filter.activeFilterCount > 0,
                backgroundColor: const Color(0xFFD4AF37),
                textColor: Colors.black,
                label: Text(
                  '${_filter.activeFilterCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
                child: Icon(
                  Icons.tune,
                  size: 20,
                  color: _filter.activeFilterCount > 0
                      ? const Color(0xFF8B1E3F)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Mode Shelves (Meubles & Rayonnages) Shortcut
          ActionChip(
            avatar: const Icon(Icons.shelves, size: 16, color: Color(0xFFD4AF37)),
            label: const Text(
              'Meubles & Rayonnages',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2B221E)
                : const Color(0xFFFAF0E6),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
            onPressed: () {
              HapticFeedback.mediumImpact();
              final cid = ref.read(currentCellarIdProvider);
              if (cid != null) {
                ShelfGridViewSheet.show(context, cellarId: cid);
              }
            },
          ),
          const SizedBox(width: 8),

          // 2. Adaptive filter chips: Wines vs Spirits
          if (!isSpiritsView) ...[
            // Food Pairing Sommelier Matcher Shortcut - prominent at the very front!
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
                CellarFoodPairingSheet.show(
                  context,
                  bottles: displayedBottles,
                  cellarName: currentDisplayName,
                );
              },
            ),
            const SizedBox(width: 8),

            // All Wine Types
            FilterChip(
              label: Text(l10n?.filterAll ?? 'Tous'),
              selected: _filter.wineType == null && !_filter.onlyFavorites,
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                if (selected) {
                  setState(() => _filter = _filter.copyWith(wineType: () => null, onlyFavorites: false));
                }
              },
            ),
            const SizedBox(width: 6),

            // Favoris FilterChip
            FilterChip(
              avatar: const Text('❤️', style: TextStyle(fontSize: 12)),
              label: const Text('Favoris'),
              selected: _filter.onlyFavorites,
              selectedColor: Colors.pink.withValues(alpha: 0.18),
              checkmarkColor: Colors.pink,
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(onlyFavorites: selected));
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
          ] else ...[
            // All Spirits
            FilterChip(
              label: Text(l10n?.filterAll ?? 'Tous'),
              selected: _filter.wineType == null,
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                if (selected) {
                  setState(() => _filter = _filter.copyWith(wineType: () => null, onlyFavorites: false));
                }
              },
            ),
            const SizedBox(width: 6),

            // Favoris FilterChip
            FilterChip(
              avatar: const Text('❤️', style: TextStyle(fontSize: 12)),
              label: const Text('Favoris'),
              selected: _filter.onlyFavorites,
              selectedColor: Colors.pink.withValues(alpha: 0.18),
              checkmarkColor: Colors.pink,
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(onlyFavorites: selected));
              },
            ),
            const SizedBox(width: 6),

            // Gin
            FilterChip(
              avatar: const Text('🍸', style: TextStyle(fontSize: 12)),
              label: const Text('Gin'),
              selected: _filter.wineType == 'gin',
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'gin' : null));
              },
            ),
            const SizedBox(width: 6),

            // Whisky
            FilterChip(
              avatar: const Text('🥃', style: TextStyle(fontSize: 12)),
              label: const Text('Whisky'),
              selected: _filter.wineType == 'whisky',
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'whisky' : null));
              },
            ),
            const SizedBox(width: 6),

            // Rhum
            FilterChip(
              avatar: const Text('🍹', style: TextStyle(fontSize: 12)),
              label: const Text('Rhum'),
              selected: _filter.wineType == 'rum',
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'rum' : null));
              },
            ),
            const SizedBox(width: 6),

            // Vodka
            FilterChip(
              avatar: const Text('🧊', style: TextStyle(fontSize: 12)),
              label: const Text('Vodka'),
              selected: _filter.wineType == 'vodka',
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'vodka' : null));
              },
            ),
            const SizedBox(width: 6),

            // Liqueur
            FilterChip(
              avatar: const Text('🌿', style: TextStyle(fontSize: 12)),
              label: const Text('Liqueur'),
              selected: _filter.wineType == 'liqueur',
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'liqueur' : null));
              },
            ),
            const SizedBox(width: 6),

            // Grappa / Eau-de-vie
            FilterChip(
              avatar: const Text('🍇', style: TextStyle(fontSize: 12)),
              label: const Text('Grappa / Eau-de-vie'),
              selected: _filter.wineType == 'grappa',
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'grappa' : null));
              },
            ),
            const SizedBox(width: 6),

            // Tequila
            FilterChip(
              avatar: const Text('🌵', style: TextStyle(fontSize: 12)),
              label: const Text('Tequila'),
              selected: _filter.wineType == 'tequila',
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'tequila' : null));
              },
            ),
            const SizedBox(width: 6),

            // Cognac / Armagnac
            FilterChip(
              avatar: const Text('🍷', style: TextStyle(fontSize: 12)),
              label: const Text('Cognac / Armagnac'),
              selected: _filter.wineType == 'cognac',
              selectedColor: const Color(0xFF8B1E3F).withAlpha(25),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _filter = _filter.copyWith(wineType: () => selected ? 'cognac' : null));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortButton(ThemeData theme) {
    return PopupMenuButton<CellarSortBy>(
      tooltip: 'Trier',
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _sortBy != CellarSortBy.recentlyAdded
              ? const Color(0xFFD4AF37).withValues(alpha: 0.18)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
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
              size: 14,
              color: _sortBy != CellarSortBy.recentlyAdded ? const Color(0xFFD4AF37) : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Trier',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _sortBy != CellarSortBy.recentlyAdded ? FontWeight.bold : FontWeight.w500,
                color: _sortBy != CellarSortBy.recentlyAdded ? const Color(0xFFD4AF37) : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: _sortBy != CellarSortBy.recentlyAdded ? const Color(0xFFD4AF37) : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupByButton(ThemeData theme) {
    return PopupMenuButton<CellarGroupBy>(
      tooltip: 'Catégories',
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _groupBy != CellarGroupBy.none
              ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
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
              size: 14,
              color: _groupBy != CellarGroupBy.none ? const Color(0xFF8B1E3F) : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Catégories',
              style: TextStyle(
                fontSize: 12,
                fontWeight: _groupBy != CellarGroupBy.none ? FontWeight.bold : FontWeight.w500,
                color: _groupBy != CellarGroupBy.none ? const Color(0xFF8B1E3F) : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: _groupBy != CellarGroupBy.none ? const Color(0xFF8B1E3F) : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottleView({
    required ThemeData theme,
    required List<Bottle> sourceBottles,
    required String activeCellarId,
    required bool isViewOnly,
  }) {
    final filteredList = _filterBottles(sourceBottles);

    if (filteredList.isEmpty) {
      if (sourceBottles.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucune bouteille dans cette catégorie',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
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
    final totalValue = sortedList.fold<double>(0.0, (sum, b) {
      final val = b.wine?.estimatedMarketValue ?? b.purchasePrice ?? 0.0;
      return sum + (val * b.quantity);
    });

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
        activeCellarId: activeCellarId,
        totalBottles: totalBottles,
        totalReferences: sortedList.length,
      );
    } else {
      mainContent = Column(
        children: [
          // Toolbar for ungrouped mode: 2-line summary on left, Trier & Catégories on right
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${sortedList.length} référence${sortedList.length > 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1E3F),
                        ),
                      ),
                      Text(
                        '$totalBottles btl',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildSortButton(theme),
                const SizedBox(width: 6),
                _buildGroupByButton(theme),
              ],
            ),
          ),
          if (_searchQuery.isNotEmpty)
            _buildLocationSummaryHeader(theme, sortedList)
          else if (!isViewOnly && _showTotalCosts && totalValue > 0)
            _buildTotalCostsBanner(theme, totalBottles, sortedList.length, totalValue),
          Expanded(
            child: _viewMode == CellarViewMode.grid
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
                          cellarId: activeCellarId,
                        ),
                      ).animate()
                        .fadeIn(delay: Duration(milliseconds: index * 40))
                        .slideY(begin: 0.08, end: 0);
                    },
                  )
                : ResponsiveContentWrapper(
                    maxWidth: 1000,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      itemCount: sortedList.length,
                      itemBuilder: (context, index) {
                        final bottle = sortedList[index];
                        return BottleListItem(
                          bottle: bottle,
                          isUltraCompact: true,
                          onTap: () => context.push('/cellar/${bottle.id}'),
                          onLongPress: () => BottleContextSheet.show(
                            context,
                            bottle: bottle,
                            cellarId: activeCellarId,
                          ),
                        ).animate()
                          .fadeIn(delay: Duration(milliseconds: index * 25));
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        notifyCellarChanged(ref, activeCellarId);
        await Future.delayed(const Duration(milliseconds: 200));
      },
      child: mainContent,
    );
  }

  Widget _buildTotalCostsBanner(ThemeData theme, int totalBottles, int totalReferences, double totalValue) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFFD4AF37)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Coût total estimé : ${totalValue.toStringAsFixed(0)} € ($totalBottles btl • $totalReferences réf.)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggleTotalCosts,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.visibility_off_outlined, size: 17, color: Color(0xFFD4AF37)),
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
    final grandTotalValue = sections.fold<double>(0.0, (sum, s) => sum + s.totalEstimatedValue);

    return Column(
      children: [
        // Group summary on 2 lines & controls: Tout replier, Trier, Catégories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${sections.length} groupe${sections.length > 1 ? "s" : ""}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1E3F),
                      ),
                    ),
                    Text(
                      '$totalBottles btl',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isViewOnly && _showTotalCosts && grandTotalValue > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 13, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 3),
                      Text(
                        '${grandTotalValue.toStringAsFixed(0)} €',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                icon: Icon(
                  allCollapsed ? Icons.unfold_more : Icons.unfold_less,
                  size: 15,
                  color: const Color(0xFFD4AF37),
                ),
                label: Text(
                  allCollapsed ? 'Tout déplier' : 'Tout replier',
                  style: const TextStyle(
                    fontSize: 11.5,
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
              const SizedBox(width: 4),
              _buildSortButton(theme),
              const SizedBox(width: 6),
              _buildGroupByButton(theme),
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
                            if (!_isViewOnly && _showTotalCosts && section.totalEstimatedValue > 0) ...[
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
                        padding: const EdgeInsets.all(6),
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
                                separatorBuilder: (_, __) => const SizedBox(height: 3),
                                itemBuilder: (context, bIdx) {
                                  final bottle = sortedSectionBottles[bIdx];
                                  return BottleListItem(
                                    bottle: bottle,
                                    isUltraCompact: true,
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
