import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../domain/terroir_geo_data.dart';

/// Assombrit les tuiles claires d'OpenTopoMap pour l'ambiance sombre.
///
/// Un seul fournisseur sert les deux ambiances, ce qui évite d'en dépendre de deux et
/// garde l'attribution unique. La matrice inverse la luminance puis la teinte légèrement
/// vers le bleu nuit : le relief et l'hydrographie restent lisibles, contrairement au
/// fond CARTO précédent qui était quasi noir avant même d'être filigrané.
const ColorFilter kDarkTerroirTileFilter = ColorFilter.matrix(<double>[
  -0.78, -0.10, -0.04, 0, 235,
  -0.08, -0.80, -0.04, 0, 238,
  -0.06, -0.10, -0.70, 0, 248,
  0, 0, 0, 1, 0,
]);

/// Attribution exigée par la licence CC-BY-SA d'OpenTopoMap. Elle doit rester
/// « deutlich sichtbar » — clairement visible — sur toute carte affichée.
const String kTerroirTileAttribution =
    '© OpenStreetMap · SRTM · rendu © OpenTopoMap (CC-BY-SA)';

/// Mention de licence, posée en surimpression permanente sur la carte.
///
/// La licence CC-BY-SA d'OpenTopoMap exige une attribution « clairement visible ». Le
/// `RichAttributionWidget` de flutter_map la replie derrière un bouton ⓘ, ce qui ne
/// satisfait pas cette exigence : on l'affiche en clair, en petit, sur un fond
/// translucide qui la garde lisible sur relief clair comme sombre.
class _TileAttributionBadge extends StatelessWidget {
  const _TileAttributionBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 6,
      bottom: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            kTerroirTileAttribution,
            style: TextStyle(fontSize: 8.5, height: 1.1, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

enum TerroirMapTheme {
  darkMatter,
  openStreetMap,
  satellite,
  topoRelief,
}

class TerroirMapView extends StatefulWidget {
  final String country;
  final String region;
  final String? subRegion;
  final String? appellation;
  final bool isSpirit;
  final String? wineType;
  final String? wineName;
  final String? producer;

  const TerroirMapView({
    super.key,
    required this.country,
    required this.region,
    this.subRegion,
    this.appellation,
    this.isSpirit = false,
    this.wineType,
    this.wineName,
    this.producer,
  });

  @override
  State<TerroirMapView> createState() => _TerroirMapViewState();
}

class _TerroirMapViewState extends State<TerroirMapView> {
  final MapController _mapController = MapController();
  TerroirMapTheme _mapTheme = TerroirMapTheme.darkMatter;
  bool _showHexagons = true;

  late TerroirGeoProfile _profile;
  late List<TerroirHexPolygon> _hexagons;
  late List<LatLng> _appellationBoundary;

  @override
  void initState() {
    super.initState();
    _resolveTerroir();
  }

  @override
  void didUpdateWidget(covariant TerroirMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.country != widget.country ||
        oldWidget.region != widget.region ||
        oldWidget.subRegion != widget.subRegion ||
        oldWidget.appellation != widget.appellation ||
        oldWidget.isSpirit != widget.isSpirit ||
        oldWidget.wineType != widget.wineType ||
        oldWidget.wineName != widget.wineName ||
        oldWidget.producer != widget.producer) {
      _resolveTerroir();
      _mapController.move(_profile.center, _profile.defaultZoom);
    }
  }

  void _resolveTerroir() {
    _profile = TerroirGeoResolver.resolve(
      country: widget.country,
      region: widget.region,
      subRegion: widget.subRegion,
      appellation: widget.appellation,
      isSpirit: widget.isSpirit,
      wineType: widget.wineType,
      wineName: widget.wineName,
      producer: widget.producer,
    );
    _hexagons = _profile.generateHexagons();
    _appellationBoundary = _profile.generateAppellationBoundary();
  }

  String _getTileUrl(TerroirMapTheme theme) {
    switch (theme) {
      // Un seul fournisseur pour les deux ambiances : OpenTopoMap, sans clé et
      // explicitement utilisable commercialement (CC-BY-SA, attribution obligatoire).
      // Le rendu sombre est obtenu par un filtre de couleur sur les mêmes tuiles —
      // voir `darkTileFilter`. Voir aussi l'en-tête de `_getTileUrl` pour l'historique.
      case TerroirMapTheme.darkMatter:
      case TerroirMapTheme.topoRelief:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case TerroirMapTheme.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case TerroirMapTheme.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{x}/{y}';
    }
  }

  List<String> _getTileSubdomains(TerroirMapTheme theme) {
    switch (theme) {
      case TerroirMapTheme.darkMatter:
      case TerroirMapTheme.topoRelief:
        return const ['a', 'b', 'c'];
      case TerroirMapTheme.openStreetMap:
        return const [];
      case TerroirMapTheme.satellite:
        return const [];
    }
  }

  String _getThemeName(TerroirMapTheme theme) {
    switch (theme) {
      case TerroirMapTheme.darkMatter:
        return 'Relief sombre';
      case TerroirMapTheme.openStreetMap:
        return 'OSM';
      case TerroirMapTheme.satellite:
        return 'Satellite';
      case TerroirMapTheme.topoRelief:
        return 'Relief';
    }
  }

  IconData _getThemeIcon(TerroirMapTheme theme) {
    switch (theme) {
      case TerroirMapTheme.darkMatter:
        return Icons.dark_mode_outlined;
      case TerroirMapTheme.openStreetMap:
        return Icons.map_outlined;
      case TerroirMapTheme.satellite:
        return Icons.satellite_alt_outlined;
      case TerroirMapTheme.topoRelief:
        return Icons.terrain_outlined;
    }
  }

  void _cycleTheme() {
    setState(() {
      const values = TerroirMapTheme.values;
      final nextIndex = (_mapTheme.index + 1) % values.length;
      _mapTheme = values[nextIndex];
    });
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
  }

  void _recenter() {
    _mapController.move(_profile.center, _profile.defaultZoom);
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _TerroirMapFullscreenScreen(
          profile: _profile,
          hexagons: _hexagons,
          initialTheme: _mapTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===================================================================
              // MAP CANVAS (280px tall, completely clear of text banners)
              // ===================================================================
              SizedBox(
                height: 280,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _profile.center,
                        initialZoom: _profile.defaultZoom,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        // Dynamic Base Tile Layer
                        TileLayer(
                          key: ValueKey(_mapTheme),
                          urlTemplate: _getTileUrl(_mapTheme),
                          subdomains: _getTileSubdomains(_mapTheme),
                          userAgentPackageName: 'com.chatmelier.app',
                          maxZoom: 17,
                          tileBuilder: _mapTheme == TerroirMapTheme.darkMatter
                              ? (context, tileWidget, tile) => ColorFiltered(
                                    colorFilter: kDarkTerroirTileFilter,
                                    child: tileWidget,
                                  )
                              : null,
                        ),

                        // Appellation Terroir Envelope & Cru Parcel Layer
                        if (_showHexagons)
                          PolygonLayer(
                            polygons: [
                              // Smooth Organic Appellation Boundary
                              Polygon(
                                points: _appellationBoundary,
                                color: _profile.accentColor.withValues(alpha: 0.15),
                                borderColor: _profile.accentColor.withValues(alpha: 0.85),
                                borderStrokeWidth: 2.0,
                              ),
                              // Cru Parcel Core
                              ..._hexagons.where((h) => h.isCenterCru).map((hex) {
                                return Polygon(
                                  points: hex.points,
                                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.22),
                                  borderColor: const Color(0xFFD4AF37),
                                  borderStrokeWidth: 1.5,
                                );
                              }),
                            ],
                          ),

                        // Sommelier Terroir Center Pin Marker
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _profile.center,
                              width: 80,
                              height: 48,
                              alignment: Alignment.center,
                              child: _buildTerroirPin(),
                            ),
                          ],
                        ),
                      ],
                    ),

                // Top-Left: Mini Theme Switcher Pill
                Positioned(
                  top: 10,
                  left: 10,
                  child: InkWell(
                    onTap: _cycleTheme,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getThemeIcon(_mapTheme),
                            size: 14,
                            color: const Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _getThemeName(_mapTheme),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top-Right: Discreet Floating Map Controls Bar
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white24,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniMapBtn(
                          icon: Icons.add,
                          tooltip: 'Zoom avant',
                          onPressed: _zoomIn,
                        ),
                        _buildDivider(),
                        _buildMiniMapBtn(
                          icon: Icons.remove,
                          tooltip: 'Zoom arrière',
                          onPressed: _zoomOut,
                        ),
                        _buildDivider(),
                        _buildMiniMapBtn(
                          icon: Icons.my_location,
                          tooltip: 'Recadrer sur le terroir',
                          onPressed: _recenter,
                        ),
                        _buildDivider(),
                        _buildMiniMapBtn(
                          icon: _showHexagons ? Icons.hexagon : Icons.hexagon_outlined,
                          tooltip: _showHexagons ? 'Masquer hexagones' : 'Afficher hexagones',
                          iconColor: _showHexagons ? const Color(0xFFD4AF37) : Colors.white70,
                          onPressed: () {
                            setState(() {
                              _showHexagons = !_showHexagons;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildMiniMapBtn(
                          icon: Icons.fullscreen,
                          tooltip: 'Plein écran',
                          iconColor: const Color(0xFFD4AF37),
                          onPressed: () => _openFullscreen(context),
                        ),
                      ],
                    ),
                  ),
                ),

                const _TileAttributionBadge(),
              ],
            ),
          ),

          // ===================================================================
          // TERROIR & CRU PROFILE DETAILS (Strictly BELOW the map canvas)
          // ===================================================================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Flag, Appellation Name & Classification
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_profile.region}${_profile.subRegion != null ? ' • ${_profile.subRegion}' : ''} (${_profile.country})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _profile.classification.split('(').first.trim(),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Terroir Attribute Chips (Soil, Climate, Exposure/Altitude, Grapes)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTerroirChip(
                      icon: Icons.layers_outlined,
                      label: 'Sol',
                      value: _profile.soilType,
                      theme: theme,
                    ),
                    _buildTerroirChip(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Climat',
                      value: _profile.climate,
                      theme: theme,
                    ),
                    _buildTerroirChip(
                      icon: Icons.landscape_outlined,
                      label: 'Relief',
                      value: '${_profile.exposure} • ${_profile.elevation}',
                      theme: theme,
                    ),
                    _buildTerroirChip(
                      icon: Icons.bubble_chart_outlined,
                      label: 'Cépages',
                      value: _profile.keyGrapes,
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Sommelier Geological Notes Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1B24)
                        : const Color(0xFFFBF8F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote,
                        size: 20,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _profile.sommelierNotes,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

          if (constraints.hasBoundedHeight) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              primary: false,
              child: content,
            );
          }
          return content;
        },
      ),
    );
  }

  Widget _buildTerroirPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF18151E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_profile.flag, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  _profile.appellation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFDF70), Color(0xFFD4AF37), Color(0xFF8A6D1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.wine_bar,
              size: 8,
              color: Color(0xFF18151E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMapBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 20,
      height: 1,
      color: Colors.white12,
    );
  }

  Widget _buildTerroirChip({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A26) : const Color(0xFFF2EFE9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                children: [
                  TextSpan(
                    text: '$label : ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FULLSCREEN INTERACTIVE TERROIR VIEWER
// =============================================================================
class _TerroirMapFullscreenScreen extends StatefulWidget {
  final TerroirGeoProfile profile;
  final List<TerroirHexPolygon> hexagons;
  final TerroirMapTheme initialTheme;

  const _TerroirMapFullscreenScreen({
    required this.profile,
    required this.hexagons,
    required this.initialTheme,
  });

  @override
  State<_TerroirMapFullscreenScreen> createState() =>
      _TerroirMapFullscreenScreenState();
}

class _TerroirMapFullscreenScreenState
    extends State<_TerroirMapFullscreenScreen> {
  final MapController _mapController = MapController();
  late TerroirMapTheme _theme;
  bool _showHexagons = true;

  @override
  void initState() {
    super.initState();
    _theme = widget.initialTheme;
  }

  String _getTileUrl(TerroirMapTheme theme) {
    switch (theme) {
      // Un seul fournisseur pour les deux ambiances : OpenTopoMap, sans clé et
      // explicitement utilisable commercialement (CC-BY-SA, attribution obligatoire).
      // Le rendu sombre est obtenu par un filtre de couleur sur les mêmes tuiles —
      // voir `darkTileFilter`. Voir aussi l'en-tête de `_getTileUrl` pour l'historique.
      case TerroirMapTheme.darkMatter:
      case TerroirMapTheme.topoRelief:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case TerroirMapTheme.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case TerroirMapTheme.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{x}/{y}';
    }
  }

  List<String> _getTileSubdomains(TerroirMapTheme theme) {
    switch (theme) {
      case TerroirMapTheme.darkMatter:
      case TerroirMapTheme.topoRelief:
        return const ['a', 'b', 'c'];
      case TerroirMapTheme.openStreetMap:
        return const [];
      case TerroirMapTheme.satellite:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.profile.flag} ${widget.profile.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showHexagons ? Icons.hexagon : Icons.hexagon_outlined,
              color: const Color(0xFFD4AF37),
            ),
            tooltip: 'Afficher/Masquer Hexagones Terroir',
            onPressed: () {
              setState(() {
                _showHexagons = !_showHexagons;
              });
            },
          ),
          PopupMenuButton<TerroirMapTheme>(
            icon: const Icon(Icons.layers_outlined, color: Color(0xFFD4AF37)),
            tooltip: 'Fond de carte',
            initialValue: _theme,
            onSelected: (t) => setState(() => _theme = t),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: TerroirMapTheme.darkMatter,
                child: Text('🌌 Sommelier Dark (CartoDB)'),
              ),
              const PopupMenuItem(
                value: TerroirMapTheme.openStreetMap,
                child: Text('🗺️ OpenStreetMap (OSM)'),
              ),
              const PopupMenuItem(
                value: TerroirMapTheme.satellite,
                child: Text('🛰️ Vue Satellite (Esri)'),
              ),
              const PopupMenuItem(
                value: TerroirMapTheme.topoRelief,
                child: Text('⛰️ Relief Topographique'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.profile.center,
              initialZoom: widget.profile.defaultZoom,
              minZoom: 2.5,
              maxZoom: 18.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                key: ValueKey(_theme),
                urlTemplate: _getTileUrl(_theme),
                subdomains: _getTileSubdomains(_theme),
                userAgentPackageName: 'com.chatmelier.app',
                maxZoom: 19,
              ),
              if (_showHexagons)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: widget.profile.generateAppellationBoundary(),
                      color: widget.profile.accentColor.withValues(alpha: 0.15),
                      borderColor: widget.profile.accentColor.withValues(alpha: 0.85),
                      borderStrokeWidth: 2.0,
                    ),
                    ...widget.hexagons.where((h) => h.isCenterCru).map((hex) {
                      return Polygon(
                        points: hex.points,
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.22),
                        borderColor: const Color(0xFFD4AF37),
                        borderStrokeWidth: 1.5,
                      );
                    }),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.profile.center,
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFD4AF37),
                          ),
                          child: const Icon(
                            Icons.wine_bar,
                            size: 18,
                            color: Color(0xFF18151E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Draggable Bottom Terroir Details Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.22,
            minChildSize: 0.10,
            maxChildSize: 0.60,
            builder: (ctx, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.profile.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      '${widget.profile.classification} • ${widget.profile.region}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRowItem('🪨 Sol', widget.profile.soilType),
                    _buildRowItem('☀️ Climat', widget.profile.climate),
                    _buildRowItem('📐 Relief & Exposition', '${widget.profile.exposure} (${widget.profile.elevation})'),
                    _buildRowItem('🍇 Cépages Phares', widget.profile.keyGrapes),
                    const SizedBox(height: 10),
                    Text(
                      widget.profile.sommelierNotes,
                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
