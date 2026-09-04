import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/wine_taste_radar.dart';

/// Single Profile Layer for Radar Chart Overlay
class RadarChartDataset {
  final String label;
  final WineTasteRadarMetrics metrics;
  final Color color;
  final bool isVisible;

  const RadarChartDataset({
    required this.label,
    required this.metrics,
    required this.color,
    this.isVisible = true,
  });
}

/// 🕸️ Interactive Multi-Layer Spider / Radar Chart for Wine Taste Profiles
class WineTasteRadarChart extends StatefulWidget {
  final List<RadarChartDataset> datasets;
  final double size;
  final bool showLabels;
  final bool isInteractive;

  const WineTasteRadarChart({
    super.key,
    required this.datasets,
    this.size = 280,
    this.showLabels = true,
    this.isInteractive = true,
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
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant WineTasteRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datasets != widget.datasets) {
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
  final double animProgress;
  final bool isDark;
  final Color textColor;
  final Color gridColor;
  final bool showLabels;

  _RadarChartPainter({
    required this.datasets,
    required this.animProgress,
    required this.isDark,
    required this.textColor,
    required this.gridColor,
    required this.showLabels,
  });

  static const int numAxes = 6;
  static const double maxVal = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * (showLabels ? 0.70 : 0.90);

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

    // 2. Draw 6 Spoke Axis Lines & Labels
    final labels = WineTasteRadarMetrics.axisLabels;
    for (int i = 0; i < numAxes; i++) {
      final angle = (i * 2 * math.pi / numAxes) - (math.pi / 2);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), axisPaint);

      if (showLabels) {
        // Label position slightly outside radius
        final labelRadius = radius + 22;
        final lx = center.dx + labelRadius * math.cos(angle);
        final ly = center.dy + labelRadius * math.sin(angle);

        final textSpan = TextSpan(
          text: labels[i],
          style: TextStyle(
            color: textColor.withAlpha(210),
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
      final values = ds.metrics.toList();
      final polyPath = Path();
      final points = <Offset>[];

      for (int i = 0; i < numAxes; i++) {
        final angle = (i * 2 * math.pi / numAxes) - (math.pi / 2);
        final clampedVal = values[i].clamp(0.5, maxVal);
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

      // Semi-transparent Fill
      final fillPaint = Paint()
        ..color = ds.color.withAlpha(55)
        ..style = PaintingStyle.fill;
      canvas.drawPath(polyPath, fillPaint);

      // Stroke Outline
      final strokePaint = Paint()
        ..color = ds.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(polyPath, strokePaint);

      // Vertex dots
      final dotPaint = Paint()
        ..color = ds.color
        ..style = PaintingStyle.fill;
      final dotCenterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      for (final pt in points) {
        canvas.drawCircle(pt, 4.0, dotPaint);
        canvas.drawCircle(pt, 2.0, dotCenterPaint);
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
