import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/wine_taste_radar.dart';

/// Single Profile Layer for Radar Chart Overlay
class RadarChartDataset {
  final String label;
  final WineTasteRadarMetrics? metrics;
  final List<double>? customValues;
  final Color color;
  final bool isVisible;

  /// Confiance du modele sur chaque axe, de 0 (aucune idee) a 1 (bien etabli), dans le
  /// meme ordre que [values].
  ///
  /// Quand elle est fournie, le trace dit ce qu'il sait : trait plein et point plein la
  /// ou le modele a observe, pointilles et point creux la ou il devine, et sur chaque axe
  /// une moustache d'autant plus longue que la marge est grande. Sans ca, les huit axes
  /// s'affichent avec la meme autorite qu'on ait 0 ou 50 degustations derriere -- une
  /// fausse precision, pas une simplification.
  final List<double>? confidences;

  const RadarChartDataset({
    required this.label,
    this.metrics,
    this.customValues,
    required this.color,
    this.isVisible = true,
    this.confidences,
  });

  List<double> get values =>
      customValues ?? metrics?.toList() ?? const [5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0];
}

/// 🕸️ Interactive Multi-Layer Spider / Radar Chart for Wine Taste Profiles
class WineTasteRadarChart extends StatefulWidget {
  /// Place réservée autour du tracé pour les libellés d'axes. Deux lignes de 9,5 px à
  /// `height: 1.1` font ~21 px ; on garde de la marge pour les libellés qui reviennent
  /// à la ligne.
  static const double labelBand = 34.0;

  /// Rayon du tracé pour une boîte donnée.
  ///
  /// Se déduit du plus **petit** côté, pas de la largeur. L'ancienne formule
  /// (`size.width / 2 * 0.70`) débordait dès que la boîte était plus large que haute :
  /// à 260 × 190 sur l'écran de profil, les libellés du haut et du bas tombaient 18 px
  /// **en dehors** de la zone de dessin — « Tannins & Grip » recouvrait le sous-titre de
  /// la carte et « Spice & Character » passait sous l'encadré suivant.
  ///
  /// Extrait de `paint` pour être vérifiable : c'est une règle géométrique, pas du rendu.
  /// Demi-longueur de la moustache d'un axe, en unites de l'echelle (sur 10), pour une
  /// confiance donnee. Confiance 1 => 0 : aucune marge.
  static double uncertaintyMargin(double confidence) =>
      (1.0 - confidence.clamp(0.0, 1.0)) * _RadarChartPainter.uncertaintyReach;

  /// Seuil a partir duquel un axe est « observe » : cinq degustations (confiance 0,5).
  ///
  /// Le halo flou qui portait l'incertitude ne se lisait pas (29/09) : a 6 % de palais
  /// connu, tout etait egalement flou, et sur la carte du profil le halo se voyait a
  /// peine. Deux etats francs se lisent d'un coup d'oeil ; la moustache garde la nuance.
  static const double seuilObserve = 0.5;

  static bool estObserve(double confidence) => confidence >= seuilObserve;

  /// Un axe jamais observe porte un « ? » : c'est la question que la prochaine
  /// degustation peut trancher.
  static String libelleAvecStatut(String label, double confidence) =>
      confidence <= 0 ? '$label ?' : label;

  static double radiusFor(Size size, bool showLabels) {
    final half = math.min(size.width, size.height) / 2;
    return showLabels ? math.max(half - labelBand, 20.0) : half * 0.90;
  }

  final List<RadarChartDataset> datasets;
  final List<String>? customAxisLabels;
  final double size;
  final bool showLabels;
  final bool isInteractive;

  /// Faux pour un tracé immédiatement complet : une image capturée pendant l'animation
  /// d'ouverture montrerait un radar à moitié déployé.
  final bool anime;

  const WineTasteRadarChart({
    super.key,
    required this.datasets,
    this.customAxisLabels,
    this.size = 280,
    this.showLabels = true,
    this.isInteractive = true,
    this.anime = true,
  });

  @override
  State<WineTasteRadarChart> createState() => _WineTasteRadarChartState();
}

class _WineTasteRadarChartState extends State<WineTasteRadarChart> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    if (widget.anime) {
      _animController.forward();
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant WineTasteRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datasets != widget.datasets && widget.anime) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final langCode = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final resolvedAxisLabels = widget.customAxisLabels ?? WineTasteRadarMetrics.localizedAxisLabels(langCode);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RadarChartPainter(
              datasets: widget.datasets.where((d) => d.isVisible).toList(),
              customAxisLabels: resolvedAxisLabels,
              animProgress: _animation.value,
              isDark: isDark,
              textColor: theme.colorScheme.onSurface,
              gridColor: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20),
              showLabels: widget.showLabels,
            ),
          ),
        );
      },
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<RadarChartDataset> datasets;
  final List<String>? customAxisLabels;
  final double animProgress;
  final bool isDark;
  final Color textColor;
  final Color gridColor;
  final bool showLabels;

  _RadarChartPainter({
    required this.datasets,
    this.customAxisLabels,
    required this.animProgress,
    required this.isDark,
    required this.textColor,
    required this.gridColor,
    required this.showLabels,
  });

  static const double maxVal = 10.0;

  /// Demi-longueur de la moustache d'un axe totalement inconnu, en unites de l'echelle
  /// (sur 10). +/- 2,5 points : assez pour qu'on lise « je ne sais pas », assez borne
  /// pour que le trace reste lisible.
  static const double uncertaintyReach = 2.5;

  /// Un segment en pointilles : Flutter n'en dessine pas nativement.
  static void _pointilles(Canvas canvas, Offset a, Offset b, Paint p) {
    const trait = 4.5, vide = 3.5;
    final d = b - a;
    final longueur = d.distance;
    if (longueur == 0) return;
    final u = d / longueur;
    var t = 0.0;
    while (t < longueur) {
      final fin = math.min(t + trait, longueur);
      canvas.drawLine(a + u * t, a + u * fin, p);
      t = fin + vide;
    }
  }


  @override
  void paint(Canvas canvas, Size size) {
    final labels = customAxisLabels ?? WineTasteRadarMetrics.axisLabels;
    final int numAxes = labels.length;
    final center = Offset(size.width / 2, size.height / 2);

    final radius = WineTasteRadarChart.radiusFor(size, showLabels);
    final confLibelles = datasets.map((d) => d.confidences).whereType<List<double>>().firstOrNull;

    // 1. Draw Concentric Hexagonal Grids (levels 2, 4, 6, 8, 10)
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: (gridColor.a * 2).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int step = 2; step <= 10; step += 2) {
      final stepRadius = radius * (step / maxVal);
      final gridPath = Path();
      for (int i = 0; i < numAxes; i++) {
        final angle = (i * 2 * math.pi / numAxes) - (math.pi / 2);
        final x = center.dx + stepRadius * math.cos(angle);
        final y = center.dy + stepRadius * math.sin(angle);
        if (i == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // 2. Draw Spoke Axis Lines & Labels
    for (int i = 0; i < numAxes; i++) {
      final angle = (i * 2 * math.pi / numAxes) - (math.pi / 2);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), axisPaint);

      if (showLabels) {
        // Label position slightly outside radius
        final labelRadius = radius + (WineTasteRadarChart.labelBand * 0.6);
        final lx = center.dx + labelRadius * math.cos(angle);
        final ly = center.dy + labelRadius * math.sin(angle);

        final c = confLibelles == null
            ? null
            : (i < confLibelles.length ? confLibelles[i] : 0.0).clamp(0.0, 1.0);
        final textSpan = TextSpan(
          text: c == null ? labels[i] : WineTasteRadarChart.libelleAvecStatut(labels[i], c),
          style: TextStyle(
            color: textColor.withAlpha(c == null
                ? 210
                : WineTasteRadarChart.estObserve(c)
                    ? 225
                    : (c > 0 ? 150 : 115)),
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: 80);

        final offset = Offset(
          lx - (textPainter.width / 2),
          ly - (textPainter.height / 2),
        );
        textPainter.paint(canvas, offset);
      }
    }

    // 3. Draw Datasets (Polygons & Vertices)
    for (final ds in datasets) {
      final values = ds.values;
      final polyPath = Path();
      final points = <Offset>[];

      for (int i = 0; i < numAxes; i++) {
        final angle = (i * 2 * math.pi / numAxes) - (math.pi / 2);
        final rawVal = i < values.length ? values[i] : 5.0;
        final clampedVal = rawVal.clamp(0.5, maxVal);
        final r = radius * (clampedVal / maxVal) * animProgress;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        final pt = Offset(x, y);
        points.add(pt);

        if (i == 0) {
          polyPath.moveTo(x, y);
        } else {
          polyPath.lineTo(x, y);
        }
      }
      polyPath.close();

      final conf = ds.confidences;
      double confianceDe(int i) =>
          conf == null ? 1.0 : (i < conf.length ? conf[i] : 0.0).clamp(0.0, 1.0);
      double rayonPour(double v) => radius * (v.clamp(0.5, maxVal) / maxVal) * animProgress;

      // Semi-transparent Fill
      final fillPaint = Paint()
        ..color = ds.color.withAlpha(55)
        ..style = PaintingStyle.fill;
      canvas.drawPath(polyPath, fillPaint);

      // Moustaches d'incertitude : sur chaque axe, de la valeur moins la marge a la
      // valeur plus la marge, avec deux butees. Une barre d'erreur se lit sans legende
      // savante ; un halo flou a 18 % d'opacite ne se lisait pas.
      if (conf != null) {
        final moustache = Paint()
          ..color = ds.color.withAlpha(165)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < numAxes; i++) {
          final marge = WineTasteRadarChart.uncertaintyMargin(confianceDe(i));
          if (marge < 0.15) continue;
          final angle = (i * 2 * math.pi / numAxes) - (math.pi / 2);
          final dir = Offset(math.cos(angle), math.sin(angle));
          final perp = Offset(-dir.dy, dir.dx);
          final rawVal = i < values.length ? values[i] : 5.0;
          final a = center + dir * rayonPour(rawVal - marge);
          final b = center + dir * rayonPour(rawVal + marge);
          canvas.drawLine(a, b, moustache);
          const demi = 3.5;
          canvas.drawLine(a - perp * demi, a + perp * demi, moustache);
          canvas.drawLine(b - perp * demi, b + perp * demi, moustache);
        }
      }

      // Contour : plein entre deux axes observes, en pointilles des qu'un bout est devine.
      final strokePaint = Paint()
        ..color = ds.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (conf == null) {
        canvas.drawPath(polyPath, strokePaint);
      } else {
        for (int i = 0; i < numAxes; i++) {
          final k = (i + 1) % numAxes;
          final plein = WineTasteRadarChart.estObserve(confianceDe(i)) &&
              WineTasteRadarChart.estObserve(confianceDe(k));
          if (plein) {
            canvas.drawLine(points[i], points[k], strokePaint);
          } else {
            _pointilles(canvas, points[i], points[k], strokePaint..strokeWidth = 2.0);
            strokePaint.strokeWidth = 2.4;
          }
        }
      }

      // Sommets : pleins la ou le modele a observe, creux la ou il devine.
      final dotPaint = Paint()
        ..color = ds.color
        ..style = PaintingStyle.fill;
      final dotCenterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final fondCreux = Paint()
        ..color = isDark ? const Color(0xFF1E1A24) : Colors.white
        ..style = PaintingStyle.fill;
      final anneau = Paint()
        ..color = ds.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      for (int i = 0; i < points.length; i++) {
        final pt = points[i];
        if (conf == null) {
          canvas.drawCircle(pt, 4.0, dotPaint);
          canvas.drawCircle(pt, 2.0, dotCenterPaint);
        } else if (WineTasteRadarChart.estObserve(confianceDe(i))) {
          // Plein, sans cœur blanc : avec un cœur, il ressemblait au point creux (29/09).
          canvas.drawCircle(pt, 4.3, dotPaint);
        } else {
          canvas.drawCircle(pt, 3.6, fondCreux);
          canvas.drawCircle(pt, 3.6, anneau);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.datasets != datasets ||
        oldDelegate.isDark != isDark;
  }
}
