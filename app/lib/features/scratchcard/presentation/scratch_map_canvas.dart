import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'france_geo_data.dart';
import 'italy_geo_data.dart';
import 'spain_portugal_geo_data.dart';
import 'germany_austria_geo_data.dart';
import 'usa_americas_geo_data.dart';
import 'oceania_africa_geo_data.dart';
import 'world_geo_data.dart';
import 'svg_path_parser.dart';

class MapRegionData {
  final String id;
  final String name;
  final String country;
  final String flag;
  final Rect normalizedBounds; // Rect from 0.0 to 1.0 relative to mapRefSize
  final bool isOwned;
  final bool isDrunk;
  final int ownedCount;
  final int drunkCount;
  final String? topWine;
  final String description;
  final String? soilType;
  final String? climate;
  final String? keyGrapes;

  const MapRegionData({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.normalizedBounds,
    required this.isOwned,
    required this.isDrunk,
    required this.ownedCount,
    required this.drunkCount,
    this.topWine,
    required this.description,
    this.soilType,
    this.climate,
    this.keyGrapes,
  });

  bool get isUnlocked => isOwned || isDrunk;
}

class ScratchMapCanvas extends StatefulWidget {
  final String mapMode; // 'france', 'italy', 'spain', 'portugal', 'germany_austria', 'usa', 'south_america', 'oceania', 'south_africa', 'world'
  final List<MapRegionData> regions;
  final Function(MapRegionData) onRegionTapped;

  const ScratchMapCanvas({
    super.key,
    required this.mapMode,
    required this.regions,
    required this.onRegionTapped,
  });

  @override
  State<ScratchMapCanvas> createState() => _ScratchMapCanvasState();
}

class _ScratchMapCanvasState extends State<ScratchMapCanvas> {
  final TransformationController _transformController = TransformationController();
  double _currentScale = 1.0;

  static const Size _standardRefSize = Size(1000, 1000);
  static const Size _worldRefSize = Size(2000, 1000);

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale >= 1.35 && _currentScale < 1.35) || (scale < 1.35 && _currentScale >= 1.35)) {
      setState(() {
        _currentScale = scale;
      });
    } else {
      _currentScale = scale;
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  String _getSvgForRegion(String id, String mode) {
    // 1. FRANCE
    if (mode == 'france') {
      switch (id) {
        case 'champagne': return FranceGeoData.champagneSvg;
        case 'alsace': return FranceGeoData.alsaceSvg;
        case 'bourgogne': return FranceGeoData.bourgogneSvg;
        case 'beaujolais': return FranceGeoData.beaujolaisSvg;
        case 'jura_savoie': return FranceGeoData.juraSavoieSvg;
        case 'loire': return FranceGeoData.loireSvg;
        case 'bordeaux': return FranceGeoData.bordeauxSvg;
        case 'sud_ouest': return FranceGeoData.sudOuestSvg;
        case 'rhone': return FranceGeoData.rhoneSvg;
        case 'languedoc_roussillon': return FranceGeoData.languedocRoussillonSvg;
        case 'provence':
        case 'provence_corse': return FranceGeoData.provenceSvg;
        case 'corse': return FranceGeoData.corseSvg;
      }
    }

    // 2. ITALY
    if (mode == 'italy') {
      switch (id) {
        case 'piemonte': return ItalyGeoData.piemonteSvg;
        case 'toscana': return ItalyGeoData.toscanaSvg;
        case 'veneto': return ItalyGeoData.venetoSvg;
        case 'trentino_alto_adige': return ItalyGeoData.trentinoAltoAdigeSvg;
        case 'emilia_abruzzo': return ItalyGeoData.emiliaAbruzzoSvg;
        case 'puglia_campania': return ItalyGeoData.pugliaCampaniaSvg;
        case 'sicilia_etna': return ItalyGeoData.siciliaEtnaSvg;
      }
    }

    // 3. SPAIN
    if (mode == 'spain') {
      switch (id) {
        case 'rioja': return SpainPortugalGeoData.riojaSvg;
        case 'ribera_del_duero': return SpainPortugalGeoData.riberaDelDueroSvg;
        case 'priorat_catalunya': return SpainPortugalGeoData.prioratCatalunyaSvg;
        case 'galicia_rias_baixas': return SpainPortugalGeoData.galiciaRiasBaixasSvg;
        case 'castilla_rueda': return SpainPortugalGeoData.castillaRuedaSvg;
        case 'andalucia_jerez': return SpainPortugalGeoData.andaluciaJerezSvg;
        case 'levante_murcia': return SpainPortugalGeoData.levanteMurciaSvg;
      }
    }

    // 4. PORTUGAL
    if (mode == 'portugal') {
      switch (id) {
        case 'douro_porto': return SpainPortugalGeoData.douroPortoSvg;
        case 'alentejo': return SpainPortugalGeoData.alentejoSvg;
        case 'vinho_verde': return SpainPortugalGeoData.vinhoVerdeSvg;
        case 'dao_bairrada': return SpainPortugalGeoData.daoBairradaSvg;
        case 'madeira_acores': return SpainPortugalGeoData.madeiraAcoresSvg;
      }
    }

    // 5. GERMANY & AUSTRIA
    if (mode == 'germany_austria') {
      switch (id) {
        case 'mosel': return GermanyAustriaGeoData.moselSvg;
        case 'rheingau_pfalz': return GermanyAustriaGeoData.rheingauPfalzSvg;
        case 'baden_franken': return GermanyAustriaGeoData.badenFrankenSvg;
        case 'wachau_kremstal': return GermanyAustriaGeoData.wachauKremstalSvg;
        case 'burgenland': return GermanyAustriaGeoData.burgenlandSvg;
      }
    }

    // 6. USA
    if (mode == 'usa') {
      switch (id) {
        case 'napa_valley': return UsaAmericasGeoData.napaValleySvg;
        case 'sonoma_county': return UsaAmericasGeoData.sonomaCountySvg;
        case 'oregon_willamette': return UsaAmericasGeoData.oregonWillametteSvg;
        case 'washington_columbia': return UsaAmericasGeoData.washingtonColumbiaSvg;
      }
    }

    // 7. SOUTH AMERICA
    if (mode == 'south_america') {
      switch (id) {
        case 'mendoza_uco': return UsaAmericasGeoData.mendozaUcoSvg;
        case 'chile_central': return UsaAmericasGeoData.chileCentralSvg;
        case 'salta_patagonia': return UsaAmericasGeoData.saltaPatagoniaSvg;
      }
    }

    // 8. OCEANIA
    if (mode == 'oceania') {
      switch (id) {
        case 'barossa_valley': return OceaniaAfricaGeoData.barossaValleySvg;
        case 'marlborough':
        case 'marlborough_nz':
        case 'central_otago': return OceaniaAfricaGeoData.marlboroughCentralOtagoSvg;
        case 'margaret_river': return OceaniaAfricaGeoData.margaretRiverSvg;
      }
    }

    // 9. SOUTH AFRICA
    if (mode == 'south_africa') {
      switch (id) {
        case 'stellenbosch':
        case 'stellenbosch_franschhoek':
        case 'swartland_walker_bay': return OceaniaAfricaGeoData.stellenboschSwartlandSvg;
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final refSize = widget.mapMode == 'world' ? _worldRefSize : _standardRefSize;
        final mapRect = _MapCustomPainter.computeFittingRect(canvasSize, refSize);
        final viewBox = Rect.fromLTWH(0, 0, refSize.width, refSize.height);

        return Stack(
          children: [
            // Interactive Zoomable Map Canvas
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 10.0,
              boundaryMargin: const EdgeInsets.all(500),
              panEnabled: true,
              scaleEnabled: true,
              child: GestureDetector(
                onDoubleTapDown: (details) {
                  final currentScale = _transformController.value.getMaxScaleOnAxis();
                  if (currentScale > 1.8) {
                    _transformController.value = Matrix4.identity();
                  } else {
                    final pos = details.localPosition;
                    final matrix = Matrix4.identity()
                      ..multiply(Matrix4.translationValues(-pos.dx * 1.5 + canvasSize.width / 2, -pos.dy * 1.5 + canvasSize.height / 2, 0.0))
                      ..multiply(Matrix4.diagonal3Values(2.5, 2.5, 1.0));
                    _transformController.value = matrix;
                  }
                },
                onTapUp: (details) {
                  final pos = details.localPosition;

                  for (final r in widget.regions) {
                    final svg = _getSvgForRegion(r.id, widget.mapMode);
                    if (svg.isNotEmpty) {
                      final path = SvgPathParser.parse(
                        svg,
                        viewBox: viewBox,
                        targetRect: mapRect,
                      );
                      if (path.contains(pos) || path.getBounds().inflate(24).contains(pos)) {
                        HapticFeedback.selectionClick();
                        widget.onRegionTapped(r);
                        return;
                      }
                    } else {
                      final regionRect = Rect.fromLTWH(
                        mapRect.left + r.normalizedBounds.left * mapRect.width,
                        mapRect.top + r.normalizedBounds.top * mapRect.height,
                        r.normalizedBounds.width * mapRect.width,
                        r.normalizedBounds.height * mapRect.height,
                      ).inflate(28);

                      if (regionRect.contains(pos)) {
                        HapticFeedback.selectionClick();
                        widget.onRegionTapped(r);
                        return;
                      }
                    }
                  }
                },
                child: CustomPaint(
                  size: canvasSize,
                  painter: _MapCustomPainter(
                    mode: widget.mapMode,
                    regions: widget.regions,
                    isDark: isDark,
                    currentScale: _currentScale,
                  ),
                ),
              ),
            ),

            // Zoom Floating Controls
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E1A24) : Colors.white).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'Zoom avant (+)',
                      onPressed: () {
                        final current = _transformController.value;
                        final scale = current.getMaxScaleOnAxis();
                        if (scale < 9.5) {
                          _transformController.value = Matrix4.copy(current)
                            ..multiply(Matrix4.diagonal3Values(1.35, 1.35, 1.0));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      tooltip: 'Zoom arrière (-)',
                      onPressed: () {
                        final current = _transformController.value;
                        final scale = current.getMaxScaleOnAxis();
                        if (scale > 0.6) {
                          _transformController.value = Matrix4.copy(current)
                            ..multiply(Matrix4.diagonal3Values(1 / 1.35, 1 / 1.35, 1.0));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.center_focus_strong, size: 20, color: Color(0xFFD4AF37)),
                      tooltip: 'Recentrer la carte',
                      onPressed: () => _transformController.value = Matrix4.identity(),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Header Instructions Banner
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E1A24) : Colors.white).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Carte révélée selon vos stocks et dégustations. Touchez un terroir pour le détail !',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapCustomPainter extends CustomPainter {
  final String mode;
  final List<MapRegionData> regions;
  final bool isDark;
  final double currentScale;

  static const colorOwned = Color(0xFFE5A93B);  // Or Ambré Chaud (En Cave)
  static const colorDrunk = Color(0xFF8B1E3F);  // Rouge Lie-de-Vin (Dégusté)
  static const Size standardRefSize = Size(1000, 1000);
  static const Size worldRefSize = Size(2000, 1000);

  _MapCustomPainter({
    required this.mode,
    required this.regions,
    required this.isDark,
    this.currentScale = 1.0,
  });

  static Rect computeFittingRect(Size container, Size content) {
    const margin = 20.0;
    final availW = math.max(10.0, container.width - margin * 2);
    final availH = math.max(10.0, container.height - margin * 2);

    final scale = math.min(availW / content.width, availH / content.height);
    final targetW = content.width * scale;
    final targetH = content.height * scale;

    final left = (container.width - targetW) / 2;
    final top = (container.height - targetH) / 2;

    return Rect.fromLTWH(left, top, targetW, targetH);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case 'france':
        _drawFranceMap(canvas, size);
        break;
      case 'italy':
        _drawItalyMap(canvas, size);
        break;
      case 'spain':
        _drawSpainMap(canvas, size);
        break;
      case 'portugal':
        _drawPortugalMap(canvas, size);
        break;
      case 'germany_austria':
        _drawGermanyAustriaMap(canvas, size);
        break;
      case 'usa':
        _drawUsaMap(canvas, size);
        break;
      case 'south_america':
        _drawSouthAmericaMap(canvas, size);
        break;
      case 'oceania':
        _drawOceaniaMap(canvas, size);
        break;
      case 'south_africa':
        _drawSouthAfricaMap(canvas, size);
        break;
      default:
        _drawWorldMap(canvas, size);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. CARTE DE FRANCE 🇫🇷
  // ---------------------------------------------------------------------------
  void _drawFranceMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['LA MANCHE', 'OCÉAN ATLANTIQUE', 'MER MÉDITERRANÉE']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = FranceGeoData.viewBox;

    final francePath = SvgPathParser.parse(FranceGeoData.franceMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    final corsePath = SvgPathParser.parse(FranceGeoData.corseSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [francePath, corsePath]);

    final riversPath = SvgPathParser.parse(FranceGeoData.riversSvg, viewBox: viewBox, targetRect: mapRect);
    _drawRivers(canvas, riversPath);

    for (final r in regions) {
      String svg = '';
      switch (r.id) {
        case 'champagne': svg = FranceGeoData.champagneSvg; break;
        case 'alsace': svg = FranceGeoData.alsaceSvg; break;
        case 'bourgogne': svg = FranceGeoData.bourgogneSvg; break;
        case 'beaujolais': svg = FranceGeoData.beaujolaisSvg; break;
        case 'jura_savoie': svg = FranceGeoData.juraSavoieSvg; break;
        case 'loire': svg = FranceGeoData.loireSvg; break;
        case 'bordeaux': svg = FranceGeoData.bordeauxSvg; break;
        case 'sud_ouest': svg = FranceGeoData.sudOuestSvg; break;
        case 'rhone': svg = FranceGeoData.rhoneSvg; break;
        case 'languedoc_roussillon': svg = FranceGeoData.languedocRoussillonSvg; break;
        case 'provence':
        case 'provence_corse': svg = FranceGeoData.provenceSvg; break;
        case 'corse': svg = FranceGeoData.corseSvg; break;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. CARTE D'ITALIE 🇮🇹
  // ---------------------------------------------------------------------------
  void _drawItalyMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['MER TYRRHÉNIENNE', 'MER ADRIATIQUE', 'MER IONIENNE']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = ItalyGeoData.viewBox;

    final mainland = SvgPathParser.parse(ItalyGeoData.italyMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    final sicily = SvgPathParser.parse(ItalyGeoData.sicilySvg, viewBox: viewBox, targetRect: mapRect);
    final sardinia = SvgPathParser.parse(ItalyGeoData.sardiniaSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [mainland, sicily, sardinia]);

    final rivers = SvgPathParser.parse(ItalyGeoData.riversSvg, viewBox: viewBox, targetRect: mapRect);
    _drawRivers(canvas, rivers);

    for (final r in regions) {
      String svg = '';
      switch (r.id) {
        case 'piemonte': svg = ItalyGeoData.piemonteSvg; break;
        case 'toscana': svg = ItalyGeoData.toscanaSvg; break;
        case 'veneto': svg = ItalyGeoData.venetoSvg; break;
        case 'trentino_alto_adige': svg = ItalyGeoData.trentinoAltoAdigeSvg; break;
        case 'emilia_abruzzo': svg = ItalyGeoData.emiliaAbruzzoSvg; break;
        case 'puglia_campania': svg = ItalyGeoData.pugliaCampaniaSvg; break;
        case 'sicilia_etna': svg = ItalyGeoData.siciliaEtnaSvg; break;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. CARTE D'ESPAGNE 🇪🇸
  // ---------------------------------------------------------------------------
  void _drawSpainMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['OCÉAN ATLANTIQUE', 'MER CANTABRIQUE', 'MER MÉDITERRANÉE']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = SpainPortugalGeoData.viewBox;

    final mainland = SvgPathParser.parse(SpainPortugalGeoData.iberianMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    final balearic = SvgPathParser.parse(SpainPortugalGeoData.balearicSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [mainland, balearic]);

    final rivers = SvgPathParser.parse(SpainPortugalGeoData.riversSvg, viewBox: viewBox, targetRect: mapRect);
    _drawRivers(canvas, rivers);

    for (final r in regions) {
      String svg = '';
      switch (r.id) {
        case 'rioja': svg = SpainPortugalGeoData.riojaSvg; break;
        case 'ribera_del_duero': svg = SpainPortugalGeoData.riberaDelDueroSvg; break;
        case 'priorat_catalunya': svg = SpainPortugalGeoData.prioratCatalunyaSvg; break;
        case 'galicia_rias_baixas': svg = SpainPortugalGeoData.galiciaRiasBaixasSvg; break;
        case 'castilla_rueda': svg = SpainPortugalGeoData.castillaRuedaSvg; break;
        case 'andalucia_jerez': svg = SpainPortugalGeoData.andaluciaJerezSvg; break;
        case 'levante_murcia': svg = SpainPortugalGeoData.levanteMurciaSvg; break;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. CARTE DU PORTUGAL 🇵🇹
  // ---------------------------------------------------------------------------
  void _drawPortugalMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['OCÉAN ATLANTIQUE']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = SpainPortugalGeoData.viewBox;

    final mainland = SvgPathParser.parse(SpainPortugalGeoData.iberianMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [mainland]);

    final rivers = SvgPathParser.parse(SpainPortugalGeoData.riversSvg, viewBox: viewBox, targetRect: mapRect);
    _drawRivers(canvas, rivers);

    for (final r in regions) {
      String svg = '';
      switch (r.id) {
        case 'douro_porto': svg = SpainPortugalGeoData.douroPortoSvg; break;
        case 'alentejo': svg = SpainPortugalGeoData.alentejoSvg; break;
        case 'vinho_verde': svg = SpainPortugalGeoData.vinhoVerdeSvg; break;
        case 'dao_bairrada': svg = SpainPortugalGeoData.daoBairradaSvg; break;
        case 'madeira_acores': svg = SpainPortugalGeoData.madeiraAcoresSvg; break;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 5. CARTE ALLEMAGNE & AUTRICHE 🇩🇪🇦🇹
  // ---------------------------------------------------------------------------
  void _drawGermanyAustriaMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['MER DU NORD', 'MER BALTIQUE']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = GermanyAustriaGeoData.viewBox;

    final mainland = SvgPathParser.parse(GermanyAustriaGeoData.centralEuropeMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [mainland]);

    final rivers = SvgPathParser.parse(GermanyAustriaGeoData.riversSvg, viewBox: viewBox, targetRect: mapRect);
    _drawRivers(canvas, rivers);

    for (final r in regions) {
      String svg = '';
      switch (r.id) {
        case 'mosel': svg = GermanyAustriaGeoData.moselSvg; break;
        case 'rheingau_pfalz': svg = GermanyAustriaGeoData.rheingauPfalzSvg; break;
        case 'baden_franken': svg = GermanyAustriaGeoData.badenFrankenSvg; break;
        case 'wachau_kremstal': svg = GermanyAustriaGeoData.wachauKremstalSvg; break;
        case 'burgenland': svg = GermanyAustriaGeoData.burgenlandSvg; break;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 6. CARTE ÉTATS-UNIS (PACIFIQUE & CALIFORNIE) 🇺🇸
  // ---------------------------------------------------------------------------
  void _drawUsaMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['OCÉAN PACIFIQUE']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = UsaAmericasGeoData.viewBox;

    final mainland = SvgPathParser.parse(UsaAmericasGeoData.usWestCoastMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [mainland]);

    final rivers = SvgPathParser.parse(UsaAmericasGeoData.usPacificRiversSvg, viewBox: viewBox, targetRect: mapRect);
    _drawRivers(canvas, rivers);

    for (final r in regions) {
      String svg = '';
      switch (r.id) {
        case 'napa_valley': svg = UsaAmericasGeoData.napaValleySvg; break;
        case 'sonoma_county': svg = UsaAmericasGeoData.sonomaCountySvg; break;
        case 'oregon_willamette': svg = UsaAmericasGeoData.oregonWillametteSvg; break;
        case 'washington_columbia': svg = UsaAmericasGeoData.washingtonColumbiaSvg; break;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 7. CARTE AMÉRIQUE DU SUD (MENDOZA & CHILI) 🇦🇷🇨🇱
  // ---------------------------------------------------------------------------
  void _drawSouthAmericaMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['OCÉAN PACIFIQUE', 'OCÉAN ATLANTIQUE SUD']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = UsaAmericasGeoData.viewBox;

    final mainland = SvgPathParser.parse(UsaAmericasGeoData.southAmericaMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [mainland]);

    final andes = SvgPathParser.parse(UsaAmericasGeoData.andesRidgeSvg, viewBox: viewBox, targetRect: mapRect);
    _drawRivers(canvas, andes, color: Colors.brown.withValues(alpha: 0.5));

    for (final r in regions) {
      String svg = '';
      switch (r.id) {
        case 'mendoza_uco': svg = UsaAmericasGeoData.mendozaUcoSvg; break;
        case 'chile_central': svg = UsaAmericasGeoData.chileCentralSvg; break;
        case 'salta_patagonia': svg = UsaAmericasGeoData.saltaPatagoniaSvg; break;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 8. CARTE OCÉANIE (AUSTRALIE & NOUVELLE-ZÉLANDE) 🇦🇺🇳🇿
  // ---------------------------------------------------------------------------
  void _drawOceaniaMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['OCÉAN INDIEN', 'MER DE TASMAN', 'OCÉAN PACIFIQUE SUD']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = OceaniaAfricaGeoData.viewBox;

    final australia = SvgPathParser.parse(OceaniaAfricaGeoData.australiaMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    final nz = SvgPathParser.parse(OceaniaAfricaGeoData.newZealandSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [australia, nz]);

    for (final r in regions) {
      String svg = '';
      switch (r.id) {
        case 'barossa_valley': svg = OceaniaAfricaGeoData.barossaValleySvg; break;
        case 'marlborough_nz': svg = OceaniaAfricaGeoData.marlboroughCentralOtagoSvg; break;
        case 'margaret_river': svg = OceaniaAfricaGeoData.margaretRiverSvg; break;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 9. CARTE AFRIQUE DU SUD 🇿🇦
  // ---------------------------------------------------------------------------
  void _drawSouthAfricaMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['OCÉAN ATLANTIQUE', 'OCÉAN INDIEN']);
    final mapRect = computeFittingRect(size, standardRefSize);
    const viewBox = OceaniaAfricaGeoData.viewBox;

    final mainland = SvgPathParser.parse(OceaniaAfricaGeoData.southAfricaMainlandSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [mainland]);

    for (final r in regions) {
      String svg = '';
      if (r.id == 'stellenbosch') {
        svg = OceaniaAfricaGeoData.stellenboschSwartlandSvg;
      }
      _drawRegionPolygon(canvas, svg, r, mapRect, viewBox);
    }
  }

  // ---------------------------------------------------------------------------
  // 10. PLANISPHÈRE MONDIAL 🌎
  // ---------------------------------------------------------------------------
  void _drawWorldMap(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size, ['OCÉAN ATLANTIQUE', 'OCÉAN PACIFIQUE', 'OCÉAN INDIEN']);
    final mapRect = computeFittingRect(size, worldRefSize);
    const viewBox = Rect.fromLTWH(0, 0, 2000, 1000);

    // Equator graticule
    final equatorPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.28)
      ..strokeWidth = 1.2;

    final eqY = mapRect.top + mapRect.height * 0.50;
    canvas.drawLine(Offset(mapRect.left, eqY), Offset(mapRect.right, eqY), equatorPaint);

    final worldPath = SvgPathParser.parse(WorldGeoData.worldAllSvg, viewBox: viewBox, targetRect: mapRect);
    _drawCountrySilhouettes(canvas, [worldPath]);

    for (final r in regions) {
      final regionRect = Rect.fromLTWH(
        mapRect.left + r.normalizedBounds.left * mapRect.width,
        mapRect.top + r.normalizedBounds.top * mapRect.height,
        r.normalizedBounds.width * mapRect.width,
        r.normalizedBounds.height * mapRect.height,
      );

      final rrect = RRect.fromRectAndRadius(regionRect, const Radius.circular(8));
      final path = Path()..addRRect(rrect);

      _drawTerroirPathContent(canvas, path, r);
      _drawInteractivePin(canvas, regionRect.center, r, isDark, showCountry: true, currentScale: currentScale);
    }
  }

  // ===========================================================================
  // HELPER CARTO RENDERING METHODS
  // ===========================================================================
  void _drawOceanBackground(Canvas canvas, Size size, List<String> watermarks) {
    final w = size.width;
    final h = size.height;

    final seaPaint = Paint()..color = isDark ? const Color(0xFF0D1117) : const Color(0xFFE3EDF7);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(24)), seaPaint);

    // Grid coordinates
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF5A738E)).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    for (double x = 30; x < w; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 30; y < h; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    if (watermarks.isNotEmpty) {
      _drawWatermarkText(canvas, watermarks.first, Offset(w * 0.15, h * 0.15), isDark);
    }
    if (watermarks.length > 1) {
      _drawWatermarkText(canvas, watermarks[1], Offset(w * 0.08, h * 0.50), isDark, isVertical: true);
    }
    if (watermarks.length > 2) {
      _drawWatermarkText(canvas, watermarks[2], Offset(w * 0.65, h * 0.85), isDark);
    }
  }

  void _drawCountrySilhouettes(Canvas canvas, List<Path> paths) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.40 : 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final landPaint = Paint()
      ..color = isDark ? const Color(0xFF1B1824) : const Color(0xFFF3EBE0)
      ..style = PaintingStyle.fill;

    final coastBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF9E8364) : const Color(0xFFB5A48B)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (final p in paths) {
      canvas.drawPath(p, shadowPaint);
      canvas.drawPath(p, landPaint);
      canvas.drawPath(p, coastBorderPaint);
    }
  }

  void _drawRivers(Canvas canvas, Path riversPath, {Color? color}) {
    final riverPaint = Paint()
      ..color = color ?? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)).withValues(alpha: 0.55)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(riversPath, riverPaint);
  }

  void _drawRegionPolygon(Canvas canvas, String svg, MapRegionData r, Rect mapRect, Rect viewBox) {
    if (svg.isEmpty) return;

    final path = SvgPathParser.parse(svg, viewBox: viewBox, targetRect: mapRect);
    final bounds = path.getBounds();
    final pinPos = bounds.center;

    _drawTerroirPathContent(canvas, path, r);
    _drawInteractivePin(canvas, pinPos, r, isDark, currentScale: currentScale);
  }

  void _drawTerroirPathContent(Canvas canvas, Path path, MapRegionData r) {
    if (r.isOwned && r.isDrunk) {
      _drawHatchedPath(canvas, path, colorOwned, colorDrunk);
    } else if (r.isOwned) {
      final fill = Paint()
        ..color = colorOwned.withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
    } else if (r.isDrunk) {
      final fill = Paint()
        ..color = colorDrunk.withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
    } else {
      _drawUnexploredPathFoil(canvas, path);
    }

    final borderPaint = Paint()
      ..color = r.isUnlocked
          ? ((r.isOwned && r.isDrunk)
              ? const Color(0xFFFFE082)
              : (r.isOwned ? const Color(0xFFFFD54F) : const Color(0xFFFF80AB)))
          : (isDark ? const Color(0xFF7A6E8C) : const Color(0xFFA89885))
      ..strokeWidth = r.isUnlocked ? 2.5 : 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  void _drawHatchedPath(Canvas canvas, Path path, Color c1, Color c2) {
    canvas.save();
    canvas.clipPath(path);

    canvas.drawPaint(Paint()..color = c1);

    final stripePaint = Paint()
      ..color = c2
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    final bounds = path.getBounds();
    for (double x = bounds.left - bounds.height - 20; x < bounds.right + 20; x += 18) {
      canvas.drawLine(
        Offset(x, bounds.bottom + 10),
        Offset(x + bounds.height + 20, bounds.top - 10),
        stripePaint,
      );
    }

    canvas.restore();
  }

  void _drawUnexploredPathFoil(Canvas canvas, Path path) {
    canvas.save();
    canvas.clipPath(path);

    final bg = Paint()..color = isDark ? const Color(0xFF2C2638) : const Color(0xFFD6CBBA);
    canvas.drawPaint(bg);

    final texturePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    final bounds = path.getBounds();
    for (double i = bounds.left - bounds.height; i < bounds.right + bounds.height; i += 12) {
      canvas.drawLine(
        Offset(i, bounds.bottom),
        Offset(i + bounds.height, bounds.top),
        texturePaint,
      );
    }

    canvas.restore();
  }

  void _drawInteractivePin(
    Canvas canvas,
    Offset center,
    MapRegionData r,
    bool isDark, {
    bool showCountry = false,
    double currentScale = 1.0,
  }) {
    final isZoomed = currentScale >= 1.35;

    if (!isZoomed) {
      final pinRadius = r.isUnlocked ? 8.5 : 5.0;
      if (r.isUnlocked) {
        final glowColor = (r.isOwned && r.isDrunk)
            ? const Color(0xFFFFD700)
            : (r.isOwned ? const Color(0xFFE5A93B) : const Color(0xFF8B1E3F));
        
        final glowPaint = Paint()
          ..color = glowColor.withValues(alpha: 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(center, pinRadius + 4, glowPaint);

        final fillPaint = Paint()
          ..color = glowColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, pinRadius, fillPaint);

        final strokePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(center, pinRadius, strokePaint);

        final centerDot = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 2.5, centerDot);
      } else {
        final dotPaint = Paint()
          ..color = (isDark ? Colors.white38 : Colors.black38)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, pinRadius, dotPaint);
      }
      return;
    }

    if (r.isUnlocked) {
      final glowPaint = Paint()
        ..color = (r.isOwned ? const Color(0xFFFFD700) : const Color(0xFFFF4081)).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, 12, glowPaint);
    }

    final scaleFactor = math.max(1.0, currentScale);
    final titleFontSize = (11.0 / math.pow(scaleFactor, 0.4)).clamp(6.5, 11.0).toDouble();
    final badgeFontSize = (9.5 / math.pow(scaleFactor, 0.4)).clamp(5.5, 9.5).toDouble();

    final titleSpan = TextSpan(
      children: [
        TextSpan(text: '${r.flag} ', style: TextStyle(fontSize: titleFontSize + 1)),
        TextSpan(
          text: r.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
            shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1))],
          ),
        ),
      ],
    );

    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final countText = r.isOwned && r.isDrunk
        ? '${r.ownedCount} 🏷️  ${r.drunkCount} 🍷'
        : (r.isOwned ? '${r.ownedCount} en cave' : (r.isDrunk ? '${r.drunkCount} dégusté' : '🔒 Inexploré'));

    final badgeSpan = TextSpan(
      text: countText,
      style: TextStyle(
        color: r.isUnlocked ? const Color(0xFFFFE082) : Colors.white70,
        fontWeight: FontWeight.w700,
        fontSize: badgeFontSize,
      ),
    );

    final badgePainter = TextPainter(
      text: badgeSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final boxW = math.max(titlePainter.width, badgePainter.width) + 16.0;
    final boxH = titlePainter.height + badgePainter.height + 10.0;
    final boxRect = Rect.fromCenter(center: center, width: boxW, height: boxH);

    final bgPaint = Paint()
      ..color = (isDark ? const Color(0xFF1B1622) : const Color(0xFF2C243B)).withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = r.isUnlocked ? const Color(0xFFD4AF37) : Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(8)), borderPaint);

    titlePainter.paint(canvas, Offset(boxRect.left + (boxW - titlePainter.width) / 2, boxRect.top + 4));
    badgePainter.paint(canvas, Offset(boxRect.left + (boxW - badgePainter.width) / 2, boxRect.top + titlePainter.height + 5));
  }

  void _drawWatermarkText(Canvas canvas, String text, Offset position, bool isDark, {bool isVertical = false}) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    if (isVertical) {
      canvas.rotate(-math.pi / 2);
    }

    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: (isDark ? Colors.white : const Color(0xFF5A738E)).withValues(alpha: 0.14),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 4.0,
      ),
    );

    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapCustomPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.regions != regions ||
        oldDelegate.isDark != isDark ||
        oldDelegate.currentScale != currentScale;
  }
}
