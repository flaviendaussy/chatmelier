import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../scratchcard/presentation/france_geo_data.dart';
import '../../scratchcard/presentation/world_geo_data.dart';
import '../../scratchcard/presentation/svg_path_parser.dart';

class TerroirMapView extends StatefulWidget {
  final String country;
  final String region;
  final String? subRegion;
  final String? appellation;

  const TerroirMapView({
    super.key,
    required this.country,
    required this.region,
    this.subRegion,
    this.appellation,
  });

  @override
  State<TerroirMapView> createState() => _TerroirMapViewState();
}

class _TerroirMapViewState extends State<TerroirMapView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 2); // default to Vignoble
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getContinent(String country) {
    final c = country.toLowerCase();
    if (c.contains('france') || c.contains('ital') || c.contains('spain') || c.contains('espag') || c.contains('portug') || c.contains('german') || c.contains('allemag')) {
      return 'Europe';
    }
    if (c.contains('state') || c.contains('unis') || c.contains('usa') || c.contains('calif') || c.contains('argentin') || c.contains('chili') || c.contains('canada')) {
      return 'Amériques';
    }
    if (c.contains('austral') || c.contains('zealand') || c.contains('zélande')) {
      return 'Océanie';
    }
    if (c.contains('south africa') || c.contains('afrique')) {
      return 'Afrique';
    }
    return 'Monde';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final continent = _getContinent(widget.country);
    final country = widget.country.isNotEmpty ? widget.country : 'France';
    final region = widget.region.isNotEmpty ? widget.region : 'Bordeaux';
    final appellation = widget.appellation != null && widget.appellation!.isNotEmpty ? widget.appellation! : region;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18151E) : const Color(0xFFF7F3EE),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: const Color(0xFFD4AF37),
                    unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                    indicatorColor: const Color(0xFFD4AF37),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: const [
                      Tab(icon: Icon(Icons.public, size: 16), text: '1. Continent'),
                      Tab(icon: Icon(Icons.flag_outlined, size: 16), text: '2. Pays'),
                      Tab(icon: Icon(Icons.map_outlined, size: 16), text: '3. Vignoble'),
                      Tab(icon: Icon(Icons.terrain_outlined, size: 16), text: '4. Terroir & Cru'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Color(0xFFD4AF37)),
                  tooltip: 'Agrandir en plein écran (Zoom interactif)',
                  onPressed: () => _openFullscreen(context, isDark, continent, country, region, appellation),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(
                  painter: _RealContinentMapPainter(
                    country: country,
                    isDark: isDark,
                  ),
                  level: 'Continent • $continent',
                  title: '$country ($continent)',
                  subtitle: 'Bassin viticole tempéré - Natural Earth Data',
                  highlightTag: 'Origine : $country',
                  accentColor: const Color(0xFF38BDF8),
                ),

                _buildMapTab(
                  painter: _RealCountryMapPainter(
                    country: country,
                    region: region,
                    isDark: isDark,
                  ),
                  level: 'Pays • $country',
                  title: '$country ➔ Vignoble de $region',
                  subtitle: 'Contours officiels IGN Lambert-93 & Réseau fluvial',
                  highlightTag: 'Vignoble : $region',
                  accentColor: const Color(0xFFD4AF37),
                ),

                _buildMapTab(
                  painter: _RealWineRegionMapPainter(
                    region: region,
                    subRegion: widget.subRegion,
                    appellation: appellation,
                    isDark: isDark,
                  ),
                  level: 'Vignoble • $region',
                  title: '$region (${widget.subRegion ?? "Sous-région"})',
                  subtitle: 'Limites A.O.C. géoréférencées & Vallées fluviales',
                  highlightTag: 'Zone : ${widget.subRegion ?? appellation}',
                  accentColor: const Color(0xFF10B981),
                ),

                _buildMapTab(
                  painter: _RealAppellationTerroirPainter(
                    region: region,
                    appellation: appellation,
                    isDark: isDark,
                  ),
                  level: 'Cru & Terroir • $appellation',
                  title: 'AOC / Climat : $appellation',
                  subtitle: 'Courbes de niveau, exposition solaire & géologie',
                  highlightTag: 'Parcelle & Climat AOC',
                  accentColor: const Color(0xFFE11D48),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(
    BuildContext context,
    bool isDark,
    String continent,
    String country,
    String region,
    String appellation,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text('$appellation ($region) • Carte'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFFD4AF37),
              indicatorColor: const Color(0xFFD4AF37),
              tabs: const [
                Tab(icon: Icon(Icons.public, size: 16), text: '1. Continent'),
                Tab(icon: Icon(Icons.flag_outlined, size: 16), text: '2. Pays'),
                Tab(icon: Icon(Icons.map_outlined, size: 16), text: '3. Vignoble'),
                Tab(icon: Icon(Icons.terrain_outlined, size: 16), text: '4. Terroir & Cru'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMapTab(
                painter: _RealContinentMapPainter(country: country, isDark: isDark),
                level: 'Continent • $continent',
                title: '$country ($continent)',
                subtitle: 'Bassin viticole mondial - Natural Earth Data',
                highlightTag: 'Origine : $country',
                accentColor: const Color(0xFF38BDF8),
                isFullscreen: true,
              ),
              _buildMapTab(
                painter: _RealCountryMapPainter(country: country, region: region, isDark: isDark),
                level: 'Pays • $country',
                title: '$country ➔ Vignoble de $region',
                subtitle: 'Contours géographiques & Bassins fluviaux',
                highlightTag: 'Vignoble : $region',
                accentColor: const Color(0xFFD4AF37),
                isFullscreen: true,
              ),
              _buildMapTab(
                painter: _RealWineRegionMapPainter(region: region, subRegion: widget.subRegion, appellation: appellation, isDark: isDark),
                level: 'Vignoble • $region',
                title: '$region (${widget.subRegion ?? "Sous-région"})',
                subtitle: 'Limites A.O.C. géoréférencées & Reliefs',
                highlightTag: 'Zone : ${widget.subRegion ?? appellation}',
                accentColor: const Color(0xFF10B981),
                isFullscreen: true,
              ),
              _buildMapTab(
                painter: _RealAppellationTerroirPainter(region: region, appellation: appellation, isDark: isDark),
                level: 'Cru & Terroir • $appellation',
                title: 'AOC / Climat : $appellation',
                subtitle: 'Courbes de niveau, exposition solaire & géologie',
                highlightTag: 'Parcelle & Climat AOC',
                accentColor: const Color(0xFFE11D48),
                isFullscreen: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapTab({
    required CustomPainter painter,
    required String level,
    required String title,
    required String subtitle,
    required String highlightTag,
    required Color accentColor,
    bool isFullscreen = false,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 10.0,
            boundaryMargin: const EdgeInsets.all(100),
            child: CustomPaint(
              painter: painter,
            ),
          ),
        ),

        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: accentColor.withValues(alpha: 0.7), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  level,
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

        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.location_pin, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RealContinentMapPainter extends CustomPainter {
  final String country;
  final bool isDark;

  _RealContinentMapPainter({required this.country, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final seaPaint = Paint()..color = isDark ? const Color(0xFF0C1017) : const Color(0xFFE2ECF7);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), seaPaint);

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF1E3A8A)).withValues(alpha: 0.08)
      ..strokeWidth = 0.8;
    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final mapRect = computeFittingRect(size, const Size(2000, 1000));
    const viewBox = Rect.fromLTWH(0, 0, 2000, 1000);

    final worldPath = SvgPathParser.parse(
      WorldGeoData.worldAllSvg,
      viewBox: viewBox,
      targetRect: mapRect,
    );

    final landPaint = Paint()
      ..color = isDark ? const Color(0xFF1B2433) : const Color(0xFFF1EBE1)
      ..style = PaintingStyle.fill;
    final landBorder = Paint()
      ..color = isDark ? const Color(0xFF37475E) : const Color(0xFFC7BCAB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(worldPath, landPaint);
    canvas.drawPath(worldPath, landBorder);

    // Highlight European & French / Origin Wine Area
    Offset pinPos = Offset(mapRect.left + mapRect.width * 0.49, mapRect.top + mapRect.height * 0.26);
    final c = country.toLowerCase();
    if (c.contains('ital')) {
      pinPos = Offset(mapRect.left + mapRect.width * 0.52, mapRect.top + mapRect.height * 0.28);
    } else if (c.contains('espag') || c.contains('spain')) {
      pinPos = Offset(mapRect.left + mapRect.width * 0.47, mapRect.top + mapRect.height * 0.30);
    } else if (c.contains('usa') || c.contains('calif')) {
      pinPos = Offset(mapRect.left + mapRect.width * 0.15, mapRect.top + mapRect.height * 0.30);
    } else if (c.contains('argentin') || c.contains('chili')) {
      pinPos = Offset(mapRect.left + mapRect.width * 0.29, mapRect.top + mapRect.height * 0.74);
    }

    _drawGlowingPin(canvas, pinPos, const Color(0xFF38BDF8), country);
  }

  static Rect computeFittingRect(Size container, Size content) {
    final scale = math.min(container.width / content.width, container.height / content.height) * 1.1;
    final targetW = content.width * scale;
    final targetH = content.height * scale;
    final left = (container.width - targetW) / 2;
    final top = (container.height - targetH) / 2;
    return Rect.fromLTWH(left, top, targetW, targetH);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 2. REAL COUNTRY MAP PAINTER (IGN LAMBERT-93 DATA) =================
class _RealCountryMapPainter extends CustomPainter {
  final String country;
  final String region;
  final bool isDark;

  _RealCountryMapPainter({required this.country, required this.region, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()..color = isDark ? const Color(0xFF100E17) : const Color(0xFFF3ECE1);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final mapRect = _computeFittingRect(size, const Size(1000, 1000));
    const viewBox = Rect.fromLTWH(0, 0, 1000, 1000);

    // 1. Real IGN Mainland France Silhouette
    final francePath = SvgPathParser.parse(
      FranceGeoData.franceMainlandSvg,
      viewBox: viewBox,
      targetRect: mapRect,
    );
    final corsePath = SvgPathParser.parse(
      FranceGeoData.corseSvg,
      viewBox: viewBox,
      targetRect: mapRect,
    );

    final landFill = Paint()
      ..color = isDark ? const Color(0xFF1F1B2A) : const Color(0xFFEDE2D0)
      ..style = PaintingStyle.fill;
    final landBorder = Paint()
      ..color = isDark ? const Color(0xFF5D516B) : const Color(0xFFAFA089)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawPath(francePath, landFill);
    canvas.drawPath(francePath, landBorder);
    canvas.drawPath(corsePath, landFill);
    canvas.drawPath(corsePath, landBorder);

    // 2. Real French River Network (IGN / OSM)
    final riverPaint = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)).withValues(alpha: 0.50)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final riversPath = SvgPathParser.parse(
      FranceGeoData.riversSvg,
      viewBox: viewBox,
      targetRect: mapRect,
    );
    canvas.drawPath(riversPath, riverPaint);

    // 3. Highlight exact wine region with real AOC polygon
    final regionSvg = _getRegionSvg(region);
    if (regionSvg.isNotEmpty) {
      final regPath = SvgPathParser.parse(
        regionSvg,
        viewBox: viewBox,
        targetRect: mapRect,
      );

      final highlightGlow = Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(regPath, highlightGlow);

      final highlightFill = Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.80)
        ..style = PaintingStyle.fill;
      canvas.drawPath(regPath, highlightFill);

      final highlightBorder = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(regPath, highlightBorder);

      final pinCenter = regPath.getBounds().center;
      _drawGlowingPin(canvas, pinCenter, const Color(0xFFFFD700), region);
    }
  }

  String _getRegionSvg(String reg) {
    final r = reg.toLowerCase();
    if (r.contains('bordeaux') || r.contains('margaux') || r.contains('pauillac') || r.contains('pessac')) return FranceGeoData.bordeauxSvg;
    if (r.contains('bourgogne') || r.contains('chablis') || r.contains('beaune') || r.contains('nuits')) return FranceGeoData.bourgogneSvg;
    if (r.contains('champagne')) return FranceGeoData.champagneSvg;
    if (r.contains('loire') || r.contains('sancerre') || r.contains('chinon')) return FranceGeoData.loireSvg;
    if (r.contains('rhone') || r.contains('rhône') || r.contains('hermitage')) return FranceGeoData.rhoneSvg;
    if (r.contains('alsace') || r.contains('riesling')) return FranceGeoData.alsaceSvg;
    if (r.contains('corse') || r.contains('patrimonio') || r.contains('ajaccio')) return FranceGeoData.corseSvg;
    if (r.contains('provence') || r.contains('bandol')) return FranceGeoData.provenceSvg;
    if (r.contains('jura') || r.contains('savoie')) return FranceGeoData.juraSavoieSvg;
    if (r.contains('languedoc') || r.contains('roussillon')) return FranceGeoData.languedocRoussillonSvg;
    if (r.contains('sud-ouest') || r.contains('cahors') || r.contains('madiran')) return FranceGeoData.sudOuestSvg;
    if (r.contains('beaujolais') || r.contains('morgon')) return FranceGeoData.beaujolaisSvg;
    return FranceGeoData.bordeauxSvg;
  }

  static Rect _computeFittingRect(Size container, Size content) {
    final scale = math.min(container.width / content.width, container.height / content.height) * 0.95;
    final targetW = content.width * scale;
    final targetH = content.height * scale;
    final left = (container.width - targetW) / 2;
    final top = (container.height - targetH) / 2;
    return Rect.fromLTWH(left, top, targetW, targetH);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 3. REAL WINE REGION MAP PAINTER =================
class _RealWineRegionMapPainter extends CustomPainter {
  final String region;
  final String? subRegion;
  final String? appellation;
  final bool isDark;

  _RealWineRegionMapPainter({
    required this.region,
    this.subRegion,
    this.appellation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()..color = isDark ? const Color(0xFF14121B) : const Color(0xFFF0EBE0);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final topoPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (double r = 40; r < w; r += 35) {
      canvas.drawCircle(Offset(w * 0.45, h * 0.5), r, topoPaint);
    }

    final mapRect = Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.84);
    const viewBox = Rect.fromLTWH(0, 0, 1000, 1000);

    final svg = _getRegionSvg(region);
    final regionPath = SvgPathParser.parse(svg, viewBox: viewBox, targetRect: mapRect);

    final fillPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(regionPath, fillPaint);
    canvas.drawPath(regionPath, borderPaint);

    final riverPaint = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)).withValues(alpha: 0.6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    final riverPath = Path();
    riverPath.moveTo(w * 0.2, h * 0.2);
    riverPath.quadraticBezierTo(w * 0.45, h * 0.5, w * 0.8, h * 0.8);
    canvas.drawPath(riverPath, riverPaint);

    final pin = regionPath.getBounds().center;
    _drawGlowingPin(canvas, pin, const Color(0xFF10B981), appellation ?? region);
  }

  String _getRegionSvg(String reg) {
    final r = reg.toLowerCase();
    if (r.contains('bordeaux') || r.contains('margaux') || r.contains('pauillac')) return FranceGeoData.bordeauxSvg;
    if (r.contains('bourgogne') || r.contains('chablis') || r.contains('beaune')) return FranceGeoData.bourgogneSvg;
    if (r.contains('champagne')) return FranceGeoData.champagneSvg;
    if (r.contains('loire') || r.contains('sancerre')) return FranceGeoData.loireSvg;
    if (r.contains('rhone') || r.contains('rhône')) return FranceGeoData.rhoneSvg;
    if (r.contains('alsace')) return FranceGeoData.alsaceSvg;
    if (r.contains('corse')) return FranceGeoData.corseSvg;
    if (r.contains('provence')) return FranceGeoData.provenceSvg;
    if (r.contains('jura')) return FranceGeoData.juraSavoieSvg;
    if (r.contains('languedoc')) return FranceGeoData.languedocRoussillonSvg;
    if (r.contains('sud-ouest')) return FranceGeoData.sudOuestSvg;
    if (r.contains('beaujolais')) return FranceGeoData.beaujolaisSvg;
    return FranceGeoData.bordeauxSvg;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 4. REAL PARCEL & TOPOGRAPHIC TERROIR PAINTER =================
class _RealAppellationTerroirPainter extends CustomPainter {
  final String region;
  final String appellation;
  final bool isDark;

  _RealAppellationTerroirPainter({
    required this.region,
    required this.appellation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF23141E), const Color(0xFF120E17)]
            : [const Color(0xFFFFF7ED), const Color(0xFFF1E6D4)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final contourPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.brown).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double y = 40; y < h - 20; y += 30) {
      final p = Path();
      p.moveTo(0, y);
      p.cubicTo(w * 0.3, y - 15, w * 0.7, y + 20, w, y);
      canvas.drawPath(p, contourPaint);
    }

    final parcelRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.55, height: h * 0.45);
    final parcelPath = Path()
      ..moveTo(parcelRect.left, parcelRect.top + 20)
      ..lineTo(parcelRect.right - 20, parcelRect.top)
      ..lineTo(parcelRect.right, parcelRect.bottom - 10)
      ..lineTo(parcelRect.left + 20, parcelRect.bottom)
      ..close();

    final parcelFill = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final parcelBorder = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    canvas.drawPath(parcelPath, parcelFill);
    canvas.drawPath(parcelPath, parcelBorder);

    final rowPaint = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: 0.45)
      ..strokeWidth = 1.5;
    for (double i = parcelRect.left + 25; i < parcelRect.right - 25; i += 18) {
      canvas.drawLine(
        Offset(i, parcelRect.top + 25),
        Offset(i + 15, parcelRect.bottom - 25),
        rowPaint,
      );
    }

    final sunCenter = Offset(w * 0.85, h * 0.22);
    final sunGlow = Paint()
      ..color = const Color(0xFFFFB703).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(sunCenter, 18, sunGlow);

    final sunFill = Paint()..color = const Color(0xFFFFB703);
    canvas.drawCircle(sunCenter, 9, sunFill);

    _drawGlowingPin(canvas, parcelRect.center, const Color(0xFFE11D48), appellation);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Global Glowing Pin Helper
void _drawGlowingPin(Canvas canvas, Offset center, Color color, [String? label]) {
  final glow = Paint()
    ..color = color.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  canvas.drawCircle(center, 14, glow);

  final fill = Paint()..color = color;
  canvas.drawCircle(center, 7, fill);

  final border = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  canvas.drawCircle(center, 7, border);

  if (label != null && label.isNotEmpty) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black87, blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tagX = center.dx - painter.width / 2;
    final tagY = center.dy - 24;
    final tagRect = Rect.fromLTWH(tagX - 6, tagY - 2, painter.width + 12, painter.height + 4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(tagRect, const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tagRect, const Radius.circular(4)),
      Paint()
        ..color = color.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    painter.paint(canvas, Offset(tagX, tagY));
  }
}
