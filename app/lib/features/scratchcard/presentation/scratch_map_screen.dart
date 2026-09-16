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

class _TerroirCluster {
  final String region;
  final String countryCode;
  final String flag;
  final LatLng center;
  final List<ResolvedTerroirNode> nodes;

  _TerroirCluster({
    required this.region,
    required this.countryCode,
    required this.flag,
    required this.center,
    required this.nodes,
  });

  int get count => nodes.length;
  int get ownedCount => nodes.fold(0, (sum, n) => sum + n.ownedCount);
  int get drunkCount => nodes.fold(0, (sum, n) => sum + n.drunkCount);
  int get unlockedCount => nodes.where((n) => n.isUnlocked).length;
  bool get isMastered => unlockedCount == count && count > 0;
  bool get isOwned => ownedCount > 0;
  bool get isDrunk => drunkCount > 0;
  bool get isUnlocked => unlockedCount > 0;
}

class ScratchMapScreen extends ConsumerStatefulWidget {
  const ScratchMapScreen({super.key});

  @override
  ConsumerState<ScratchMapScreen> createState() => _ScratchMapScreenState();
}

class _ScratchMapScreenState extends ConsumerState<ScratchMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  MapTileTheme _currentTileTheme = MapTileTheme.darkMatter;
  double _currentZoom = 5.8;
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

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

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

  List<_TerroirCluster> _buildClusters(List<ResolvedTerroirNode> nodes) {
    final Map<String, List<ResolvedTerroirNode>> grouped = {};
    for (final n in nodes) {
      final key = '${n.node.countryCode}_${n.node.region}';
      grouped.putIfAbsent(key, () => []).add(n);
    }

    final List<_TerroirCluster> clusters = [];
    for (final list in grouped.values) {
      if (list.isEmpty) continue;
      double sumLat = 0;
      double sumLon = 0;
      for (final n in list) {
        sumLat += n.node.center.latitude;
        sumLon += n.node.center.longitude;
      }
      final center = LatLng(sumLat / list.length, sumLon / list.length);
      clusters.add(
        _TerroirCluster(
          region: list.first.node.region,
          countryCode: list.first.node.countryCode,
          flag: list.first.node.flag,
          center: center,
          nodes: list,
        ),
      );
    }
    return clusters;
  }

  String _getCountryLabel(String code) {
    switch (code) {
      case 'ALL': return '🌍 Monde';
      case 'FR': return '🇫🇷 France';
      case 'IT': return '🇮🇹 Italie';
      case 'ES': return '🇪🇸 Espagne';
      case 'PT': return '🇵🇹 Portugal';
      case 'US': return '🇺🇸 USA';
      case 'AR': return '🇦🇷 Argentine';
      case 'CL': return '🇨🇱 Chili';
      case 'AU': return '🇦🇺 Océanie';
      case 'ZA': return '🇿🇦 Af. du Sud';
      default: return code;
    }
  }

  String _getStatusLabel(String status, int total, int owned, int drunk, int unlocked) {
    switch (status) {
      case 'OWNED': return '🏷️ En Cave ($owned)';
      case 'DRUNK': return '🍷 Dégusté ($drunk)';
      case 'UNLOCKED': return '✨ Débloqué ($unlocked)';
      case 'LOCKED': return '🔒 À découvrir (${total - unlocked})';
      case 'ALL':
      default:
        return 'Tous les terroirs ($total)';
    }
  }

  String _getShortStatusLabel(String status) {
    switch (status) {
      case 'OWNED': return '🏷️ Cave';
      case 'DRUNK': return '🍷 Dégusté';
      case 'UNLOCKED': return '✨ Débloqué';
      case 'LOCKED': return '🔒 À découvrir';
      case 'ALL':
      default:
        return 'Tous';
    }
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

    final clusters = _buildClusters(filteredNodes);

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
                  options: MapOptions(
                    initialCenter: const LatLng(46.6, 2.5),
                    initialZoom: 5.8,
                    minZoom: 2.0,
                    maxZoom: 17.0,
                    onPositionChanged: (camera, hasGesture) {
                      if ((camera.zoom >= 6.8 && _currentZoom < 6.8) ||
                          (camera.zoom < 6.8 && _currentZoom >= 6.8) ||
                          (_currentZoom - camera.zoom).abs() > 0.5) {
                        setState(() {
                          _currentZoom = camera.zoom;
                        });
                      }
                    },
                    interactionOptions: const InteractionOptions(
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

                    if (_currentZoom < 6.8) ...[
                      // Macro Regional Clusters
                      CircleLayer(
                        circles: clusters.map((c) {
                          final isDiscovered = c.nodes.any((n) => n.isUnlocked);
                          return CircleMarker(
                            point: c.center,
                            radius: 36,
                            useRadiusInMeter: false,
                            color: isDiscovered
                                ? const Color(0xFF8B1E3F).withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.05),
                            borderColor: isDiscovered
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                                : Colors.white12,
                            borderStrokeWidth: 1.2,
                          );
                        }).toList(),
                      ),
                      MarkerLayer(
                        markers: clusters.map((c) {
                          return Marker(
                            point: c.center,
                            width: 170,
                            height: 44,
                            alignment: Alignment.center,
                            child: _buildClusterMarkerWidget(c, isDark),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      // Micro Terroir Individual Halos & Pins
                      CircleLayer(
                        circles: filteredNodes.map((r) {
                          Color circleColor;
                          if (r.isMastered) {
                            circleColor = const Color(0xFFD4AF37).withValues(alpha: 0.25);
                          } else if (r.isOwned) {
                            circleColor = const Color(0xFF8B1E3F).withValues(alpha: 0.25);
                          } else if (r.isDrunk) {
                            circleColor = Colors.purple.withValues(alpha: 0.22);
                          } else {
                            circleColor = Colors.grey.withValues(alpha: 0.08);
                          }

                          return CircleMarker(
                            point: r.node.center,
                            radius: r.isUnlocked ? 22 : 14,
                            useRadiusInMeter: false,
                            color: circleColor,
                            borderColor: r.isUnlocked
                                ? (r.isMastered ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F))
                                : Colors.white24,
                            borderStrokeWidth: r.isUnlocked ? 1.5 : 0.8,
                          );
                        }).toList(),
                      ),
                      MarkerLayer(
                        markers: filteredNodes.map((r) {
                          return Marker(
                            point: r.node.center,
                            width: 110,
                            height: 48,
                            alignment: Alignment.center,
                            child: GestureDetector(
                              onTap: () => _showTerroirDetails(r),
                              child: _buildTerroirMarkerWidget(r, isDark),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),

                // 2. Top Navigation Bar (Search + Unified Dropdown Bar)
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

                      // Sleek Compact Unified Filter Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF181722) : Colors.white).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Country Menu
                            PopupMenuButton<String>(
                              initialValue: _activeCountryCode,
                              onSelected: (code) => _selectCountry(code),
                              tooltip: 'Filtrer par pays / région',
                              color: isDark ? const Color(0xFF22212E) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              itemBuilder: (ctx) => [
                                'ALL', 'FR', 'IT', 'ES', 'PT', 'US', 'AR', 'CL', 'AU', 'ZA',
                              ].map((code) => PopupMenuItem(
                                value: code,
                                child: Text(_getCountryLabel(code), style: const TextStyle(fontSize: 13)),
                              )).toList(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _activeCountryCode != 'ALL'
                                      ? const Color(0xFF8B1E3F)
                                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getCountryLabel(_activeCountryCode),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _activeCountryCode != 'ALL' ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 15,
                                      color: _activeCountryCode != 'ALL' ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            // Status Menu
                            PopupMenuButton<String>(
                              initialValue: _filterStatus,
                              onSelected: (status) => setState(() => _filterStatus = status),
                              tooltip: 'Filtrer par statut',
                              color: isDark ? const Color(0xFF22212E) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              itemBuilder: (ctx) => [
                                'ALL', 'OWNED', 'DRUNK', 'UNLOCKED', 'LOCKED',
                              ].map((status) => PopupMenuItem(
                                value: status,
                                child: Text(_getStatusLabel(status, totalCount, ownedCount, drunkCount, unlockedCount), style: const TextStyle(fontSize: 13)),
                              )).toList(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _filterStatus != 'ALL'
                                      ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _filterStatus != 'ALL' ? const Color(0xFFD4AF37) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _filterStatus == 'ALL'
                                          ? 'Tous ($totalCount)'
                                          : _getShortStatusLabel(_filterStatus),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _filterStatus != 'ALL' ? const Color(0xFFD4AF37) : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 15,
                                      color: _filterStatus != 'ALL' ? const Color(0xFFD4AF37) : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_activeCountryCode != 'ALL' || _filterStatus != 'ALL') ...[
                              const SizedBox(width: 2),
                              IconButton(
                                icon: const Icon(Icons.close, size: 15),
                                tooltip: 'Réinitialiser filtres',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                onPressed: () {
                                  setState(() {
                                    _activeCountryCode = 'ALL';
                                    _filterStatus = 'ALL';
                                  });
                                  _flyTo(_worldCenter, _worldZoom);
                                },
                              ),
                            ],
                            const Spacer(),
                            // Zoom Indicator Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black38 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _currentZoom < 6.8 ? 'Régions' : 'Terroirs',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF141318) : Colors.white).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendBullet(const Color(0xFFD4AF37), 'Cave & Dégusté 🌟'),
                        const SizedBox(width: 10),
                        _buildLegendBullet(const Color(0xFF8B1E3F), 'En Cave 🏷️'),
                        const SizedBox(width: 10),
                        _buildLegendBullet(Colors.purple.shade400, 'Dégusté 🍷'),
                        const SizedBox(width: 10),
                        _buildLegendBullet(Colors.grey.shade500, 'À explorer 🔒'),
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

  Widget _buildClusterMarkerWidget(_TerroirCluster cluster, bool isDark) {
    final totalInCluster = cluster.nodes.length;
    final unlockedInCluster = cluster.nodes.where((n) => n.isUnlocked).length;
    final ownedInCluster = cluster.nodes.where((n) => n.isOwned).fold(0, (acc, n) => acc + n.ownedCount);
    final isDiscovered = unlockedInCluster > 0;

    return GestureDetector(
      onTap: () => _flyTo(cluster.center, 8.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDiscovered
                ? [const Color(0xFF8B1E3F), const Color(0xFF4A0E17)]
                : [const Color(0xFF282733), const Color(0xFF1B1A24)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDiscovered ? const Color(0xFFD4AF37) : Colors.white24,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isDiscovered
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(cluster.flag, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                cluster.region,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isDiscovered ? const Color(0xFFD4AF37) : Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ownedInCluster > 0
                    ? '$totalInCluster ($ownedInCluster btl)'
                    : '$totalInCluster',
                style: TextStyle(
                  color: isDiscovered ? Colors.black : Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
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
      // Même fournisseur unique que la carte de terroir : OpenTopoMap, sans clé et
      // commercialement utilisable. CARTO filigrane désormais toutes ses tuiles.
      case MapTileTheme.darkMatter:
      case MapTileTheme.topoRelief:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapTileTheme.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> _getTileSubdomains(MapTileTheme theme) {
    switch (theme) {
      case MapTileTheme.darkMatter:
      case MapTileTheme.topoRelief:
        return const ['a', 'b', 'c'];
      case MapTileTheme.openStreetMap:
        return const [];
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
