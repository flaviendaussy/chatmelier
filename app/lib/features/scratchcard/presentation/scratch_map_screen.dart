import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/responsive_layout.dart';
import '../../cellar/domain/bottle.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../offline/presentation/sync_provider.dart';
import '../data/terroir_resolver_service.dart';

final allUserBottlesProvider = FutureProvider<List<Bottle>>((ref) async {
  final repo = ref.watch(cellarRepositoryProvider);
  final offlineStorage = ref.watch(offlineStorageServiceProvider);
  final activeCellarId = ref.watch(currentCellarIdProvider);
  final Map<String, Bottle> bottleMap = {};

  final Set<String> targetCellarIds = {};
  if (activeCellarId != null && activeCellarId.isNotEmpty) {
    targetCellarIds.add(activeCellarId);
  }

  try {
    final cellars = await repo.getUserCellarsWithRole();
    for (final c in cellars) {
      if (c['id'] != null) targetCellarIds.add(c['id'].toString());
      if (c['cellar_id'] != null) targetCellarIds.add(c['cellar_id'].toString());
      final cMap = c['cellars'] as Map<String, dynamic>?;
      if (cMap != null && cMap['id'] != null) {
        targetCellarIds.add(cMap['id'].toString());
      }
    }
  } catch (e) {
    AppLogger.warning('GEO_MAP', 'Error fetching user cellars list for map: $e');
  }

  final cachedCellars = offlineStorage.getCachedCellars();
  for (final c in cachedCellars) {
    targetCellarIds.add(c.id);
  }

  for (final cId in targetCellarIds) {
    try {
      final bList = await repo.getBottles(cId);
      for (final b in bList) {
        bottleMap[b.id] = b;
      }
    } catch (_) {}

    final cachedList = offlineStorage.getCachedBottles(cId);
    for (final b in cachedList) {
      bottleMap.putIfAbsent(b.id, () => b);
    }
  }

  AppLogger.info('GEO_MAP', 'Map evaluated ${bottleMap.length} unique bottles across ${targetCellarIds.length} cellars');
  return bottleMap.values.toList();
});

enum MapTileTheme {
  darkMatter,
  openStreetMap,
  topoRelief,
}

class ScratchMapScreen extends ConsumerStatefulWidget {
  const ScratchMapScreen({super.key});

  @override
  ConsumerState<ScratchMapScreen> createState() => _ScratchMapScreenState();
}

class _ScratchMapScreenState extends ConsumerState<ScratchMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  MapTileTheme _currentTileTheme = MapTileTheme.darkMatter;
  String _activeCountryCode = 'ALL';
  String _filterStatus = 'ALL'; // 'ALL', 'OWNED', 'DRUNK', 'UNLOCKED', 'LOCKED'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;
  ResolvedTerroirNode? _selectedTerroir;

  static const LatLng _worldCenter = LatLng(30.0, 10.0);
  static const double _worldZoom = 2.5;

  static final Map<String, (LatLng, double)> _countryPresets = {
    'ALL': (const LatLng(35.0, 10.0), 2.8),
    'FR': (const LatLng(46.6033, 2.5), 6.2),
    'IT': (const LatLng(42.5042, 12.5), 6.2),
    'ES': (const LatLng(40.4637, -3.7492), 6.2),
    'PT': (const LatLng(39.3999, -8.2245), 7.0),
    'US': (const LatLng(38.5, -120.0), 5.5),
    'AR': (const LatLng(-34.0, -68.0), 5.5),
    'CL': (const LatLng(-34.5, -71.0), 6.5),
    'AU': (const LatLng(-34.0, 140.0), 5.2),
    'ZA': (const LatLng(-33.8, 19.0), 7.5),
  };

  void _flyTo(LatLng target, double zoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: target.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: target.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: zoom,
    );

    final animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    final animation = CurvedAnimation(
      parent: animController,
      curve: Curves.easeInOutCubic,
    );

    animController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animController.forward().then((_) => animController.dispose());
  }

  void _selectCountry(String code) {
    setState(() => _activeCountryCode = code);
    final preset = _countryPresets[code] ?? (const LatLng(46.6, 2.5), 6.0);
    _flyTo(preset.$1, preset.$2);
  }

  void _showTerroirDetails(ResolvedTerroirNode node) {
    setState(() => _selectedTerroir = node);
    _flyTo(node.node.center, (node.node.defaultZoom).clamp(8.0, 13.0));

    final isDesktop = Responsive.isDesktop(context);
    if (!isDesktop) {
      _showMobileTerroirModal(node);
    }
  }

  void _showMobileTerroirModal(ResolvedTerroirNode node) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: _TerroirDetailContent(
            node: node,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);

    final bottlesAsync = ref.watch(allUserBottlesProvider);
    final tastingsAsync = ref.watch(tastingLogProvider);

    final bottles = bottlesAsync.value ?? const [];
    final tastings = tastingsAsync.value ?? const [];

    final resolvedNodes = TerroirResolverService.resolveAll(
      bottles: bottles,
      tastings: tastings,
    );

    // Filter nodes
    final filteredNodes = resolvedNodes.where((r) {
      if (_activeCountryCode != 'ALL' && r.node.countryCode != _activeCountryCode) {
        return false;
      }
      if (_filterStatus == 'OWNED' && !r.isOwned) return false;
      if (_filterStatus == 'DRUNK' && !r.isDrunk) return false;
      if (_filterStatus == 'UNLOCKED' && !r.isUnlocked) return false;
      if (_filterStatus == 'LOCKED' && r.isUnlocked) return false;

      if (_searchQuery.isNotEmpty) {
        final q = TerroirResolverService.normalize(_searchQuery);
        final name = TerroirResolverService.normalize(r.node.name);
        final reg = TerroirResolverService.normalize(r.node.region);
        final ctry = TerroirResolverService.normalize(r.node.country);
        final grapes = TerroirResolverService.normalize(r.node.keyGrapes);
        final soil = TerroirResolverService.normalize(r.node.soilType);
        final aliases = r.node.aliases.map(TerroirResolverService.normalize).join(' ');

        if (!name.contains(q) && !reg.contains(q) && !ctry.contains(q) && !grapes.contains(q) && !soil.contains(q) && !aliases.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    final totalCount = resolvedNodes.length;
    final unlockedCount = resolvedNodes.where((r) => r.isUnlocked).length;
    final ownedCount = resolvedNodes.where((r) => r.isOwned).length;
    final drunkCount = resolvedNodes.where((r) => r.isDrunk).length;
    final completionPct = totalCount > 0 ? (unlockedCount / totalCount * 100).toStringAsFixed(0) : '0';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carte des Terroirs du Monde',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '$unlockedCount/$totalCount terroirs explorés ($completionPct%) • $ownedCount en cave • $drunkCount dégustés',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.search_off : Icons.search),
            tooltip: 'Recherche Terroir / Appellation',
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
          PopupMenuButton<MapTileTheme>(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Fonds de carte',
            initialValue: _currentTileTheme,
            onSelected: (theme) => setState(() => _currentTileTheme = theme),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: MapTileTheme.darkMatter,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_outlined, size: 18, color: Color(0xFF8B1E3F)),
                    SizedBox(width: 10),
                    Text('Sommelier Dark (CartoDB)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MapTileTheme.openStreetMap,
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Standard (OpenStreetMap)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MapTileTheme.topoRelief,
                child: Row(
                  children: [
                    Icon(Icons.terrain_outlined, size: 18, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Relief Topographique (OpenTopo)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Vue globale du Monde',
            onPressed: () => _flyTo(_worldCenter, _worldZoom),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                // 1. FlutterMap GIS Engine
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(46.6, 2.5),
                    initialZoom: 5.8,
                    minZoom: 2.0,
                    maxZoom: 17.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Tile Layer based on active theme
                    TileLayer(
                      urlTemplate: _getTileUrlTemplate(_currentTileTheme),
                      subdomains: _getTileSubdomains(_currentTileTheme),
                      userAgentPackageName: 'com.chatmelier.app',
                      maxZoom: 19,
                    ),

                    // Shaded Terroir Halos
                    CircleLayer(
                      circles: filteredNodes.map((r) {
                        Color circleColor;
                        if (r.isMastered) {
                          circleColor = const Color(0xFFD4AF37).withValues(alpha: 0.22);
                        } else if (r.isOwned) {
                          circleColor = const Color(0xFF8B1E3F).withValues(alpha: 0.25);
                        } else if (r.isDrunk) {
                          circleColor = Colors.purple.withValues(alpha: 0.22);
                        } else {
                          circleColor = Colors.grey.withValues(alpha: 0.08);
                        }

                        return CircleMarker(
                          point: r.node.center,
                          radius: r.isUnlocked ? 35 : 22,
                          useRadiusInMeter: false,
                          color: circleColor,
                          borderColor: r.isUnlocked
                              ? (r.isMastered ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F))
                              : Colors.white24,
                          borderStrokeWidth: r.isUnlocked ? 1.5 : 0.8,
                        );
                      }).toList(),
                    ),

                    // Interactive Markers
                    MarkerLayer(
                      markers: filteredNodes.map((r) {
                        return Marker(
                          point: r.node.center,
                          width: r.isUnlocked ? 110 : 80,
                          height: 52,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () => _showTerroirDetails(r),
                            child: _buildTerroirMarkerWidget(r, isDark),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // 2. Top Navigation Bar (Country & Status quick filters)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      // Search Bar Overlay
                      if (_showSearchBar)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Rechercher une appellation (Pomerol, Barolo, Priorat, Napa...)',
                              hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                              border: InputBorder.none,
                              icon: const Icon(Icons.search, size: 20, color: Color(0xFF8B1E3F)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),

                      // Horizontal Quick-Jump Country Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCountryChip('ALL', '🌍 Monde'),
                            const SizedBox(width: 6),
                            _buildCountryChip('FR', '🇫🇷 France'),
                            const SizedBox(width: 6),
                            _buildCountryChip('IT', '🇮🇹 Italie'),
                            const SizedBox(width: 6),
                            _buildCountryChip('ES', '🇪🇸 Espagne'),
                            const SizedBox(width: 6),
                            _buildCountryChip('PT', '🇵🇹 Portugal'),
                            const SizedBox(width: 6),
                            _buildCountryChip('US', '🇺🇸 USA'),
                            const SizedBox(width: 6),
                            _buildCountryChip('AR', '🇦🇷 Argentine'),
                            const SizedBox(width: 6),
                            _buildCountryChip('CL', '🇨🇱 Chili'),
                            const SizedBox(width: 6),
                            _buildCountryChip('AU', '🇦🇺 Océanie'),
                            const SizedBox(width: 6),
                            _buildCountryChip('ZA', '🇿🇦 Afrique du Sud'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status Filters Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusFilterChip('ALL', 'Tous ($totalCount)'),
                            const SizedBox(width: 6),
                            _buildStatusFilterChip('OWNED', '🏷️ En Cave ($ownedCount)'),
                            const SizedBox(width: 6),
                            _buildStatusFilterChip('DRUNK', '🍷 Dégustés ($drunkCount)'),
                            const SizedBox(width: 6),
                            _buildStatusFilterChip('UNLOCKED', '✨ Débloqués ($unlockedCount)'),
                            const SizedBox(width: 6),
                            _buildStatusFilterChip('LOCKED', '🔒 À découvrir (${totalCount - unlockedCount})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Floating Quick Legend
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF141318) : Colors.white).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendBullet(const Color(0xFFD4AF37), 'Cave & Dégusté 🌟'),
                        const SizedBox(width: 12),
                        _buildLegendBullet(const Color(0xFF8B1E3F), 'En Cave 🏷️'),
                        const SizedBox(width: 12),
                        _buildLegendBullet(Colors.purple.shade400, 'Dégusté 🍷'),
                        const SizedBox(width: 12),
                        _buildLegendBullet(Colors.grey.shade600, 'À explorer 🔒'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Desktop Side Inspector Panel
          if (isDesktop && _selectedTerroir != null) ...[
            const VerticalDivider(width: 1, thickness: 1),
            Container(
              width: 380,
              color: isDark ? const Color(0xFF16151D) : const Color(0xFFFAF7F5),
              child: _TerroirDetailContent(
                node: _selectedTerroir!,
                onClose: () => setState(() => _selectedTerroir = null),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountryChip(String code, String label) {
    final isSelected = _activeCountryCode == code;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectCountry(code),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8B1E3F)
                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF22212C) : Colors.white).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _filterStatus = status),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1922) : Colors.white).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendBullet(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTerroirMarkerWidget(ResolvedTerroirNode r, bool isDark) {
    Color badgeColor;
    Color borderColor;
    String badgeText;

    if (r.isMastered) {
      badgeColor = const Color(0xFFD4AF37);
      borderColor = Colors.amber.shade200;
      badgeText = '🌟 ${r.ownedCount} btl';
    } else if (r.isOwned) {
      badgeColor = const Color(0xFF8B1E3F);
      borderColor = const Color(0xFFD4AF37);
      badgeText = '🏷️ ${r.ownedCount} btl';
    } else if (r.isDrunk) {
      badgeColor = Colors.purple.shade700;
      borderColor = Colors.purple.shade200;
      badgeText = '🍷 Dégusté';
    } else {
      badgeColor = isDark ? const Color(0xFF2C2B36) : Colors.grey.shade700;
      borderColor = Colors.white24;
      badgeText = '🔒 Terroir';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: badgeColor.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                r.node.flag,
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            r.node.name.split('—').first.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getTileUrlTemplate(MapTileTheme theme) {
    switch (theme) {
      case MapTileTheme.darkMatter:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png';
      case MapTileTheme.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapTileTheme.topoRelief:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> _getTileSubdomains(MapTileTheme theme) {
    switch (theme) {
      case MapTileTheme.darkMatter:
        return const ['a', 'b', 'c', 'd'];
      case MapTileTheme.openStreetMap:
        return const [];
      case MapTileTheme.topoRelief:
        return const ['a', 'b', 'c'];
    }
  }
}

class _TerroirDetailContent extends StatelessWidget {
  final ResolvedTerroirNode node;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  const _TerroirDetailContent({
    required this.node,
    this.scrollController,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color badgeColor;
    String badgeLabel;
    IconData badgeIcon;

    if (node.isMastered) {
      badgeColor = const Color(0xFFD4AF37);
      badgeLabel = 'En Cave & Dégusté 🌟';
      badgeIcon = Icons.stars;
    } else if (node.isOwned) {
      badgeColor = const Color(0xFF8B1E3F);
      badgeLabel = 'En Cave uniquement 🏷️';
      badgeIcon = Icons.inventory_2;
    } else if (node.isDrunk) {
      badgeColor = Colors.purple.shade700;
      badgeLabel = 'Dégusté uniquement 🍷';
      badgeIcon = Icons.wine_bar;
    } else {
      badgeColor = Colors.grey;
      badgeLabel = 'Terroir inexploré 🔒';
      badgeIcon = Icons.lock_outline;
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (onClose != null)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClose,
            ),
          )
        else
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

        // Header with Flag and Region Title
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Text(node.node.flag, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.node.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${node.node.region} • ${node.node.country} (${node.node.classification})',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Status Capsule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(badgeIcon, color: badgeColor, size: 18),
              const SizedBox(width: 8),
              Text(
                badgeLabel,
                style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Stats Row
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'En Stock',
                value: '${node.ownedCount} btl',
                icon: Icons.inventory_2,
                color: const Color(0xFF8B1E3F),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'Dégustés',
                value: '${node.drunkCount}',
                icon: Icons.wine_bar,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'Statut',
                value: node.isUnlocked ? 'Exploré ✨' : 'À découvrir',
                icon: Icons.explore,
                color: const Color(0xFFD4AF37),
              ),
            ),
          ],
        ),

        if (node.topWine != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF2A2030) : theme.colorScheme.primaryContainer.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cuvée de référence : ${node.topWine}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Sommelier Pedological Masterclass
        Text(
          'PROFIL DU TERROIR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          node.node.description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 12),

        _TerroirMetaRow(
          icon: Icons.terrain,
          label: 'Type de sol',
          value: node.node.soilType,
          color: Colors.brown.shade400,
        ),
        const SizedBox(height: 8),
        _TerroirMetaRow(
          icon: Icons.wb_sunny_outlined,
          label: 'Climat & Exposition',
          value: node.node.climate,
          color: Colors.orange.shade600,
        ),
        const SizedBox(height: 8),
        _TerroirMetaRow(
          icon: Icons.local_florist_outlined,
          label: 'Cépages emblématiques',
          value: node.node.keyGrapes,
          color: const Color(0xFF8B1E3F),
        ),

        // Bottles in stock list if any
        if (node.ownedBottles.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'VOS BOUTEILLES ISSUES DE CE TERROIR (${node.ownedBottles.length})',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...node.ownedBottles.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF22212C) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wine_bar, size: 16, color: Color(0xFF8B1E3F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${b.wine?.producer ?? ""} ${b.wine?.name ?? ""} ${b.wine?.vintage ?? ""}'.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x${b.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1E3F),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],

        const SizedBox(height: 24),

        // Navigation Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.menu_book, size: 18),
                label: const Text('Journal'),
                onPressed: () => context.go('/journal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.inventory_2, size: 18),
                label: const Text('Ma Cave'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                onPressed: () => context.go('/'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TerroirMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TerroirMetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
