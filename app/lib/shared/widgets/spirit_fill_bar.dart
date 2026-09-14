import 'package:flutter/material.dart';

class SpiritFillBar extends StatelessWidget {
  final int fillLevel;
  final String? spiritType;
  final String? wineName;
  final double width;
  final double height;
  final bool showLabel;
  final bool compact;

  const SpiritFillBar({
    super.key,
    required this.fillLevel,
    this.spiritType,
    this.wineName,
    this.width = 72,
    this.height = 6,
    this.showLabel = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final progress = (fillLevel / 100.0).clamp(0.0, 1.0);

    final colors = _resolveColors(spiritType, wineName);
    final statusColor = fillLevel <= 20
        ? Colors.red.shade600
        : fillLevel <= 50
            ? Colors.orange.shade700
            : colors.primary;

    final barWidget = SizedBox(
      width: width,
      height: height + (compact ? 2 : 4),
      child: CustomPaint(
        painter: _SpiritFillPainter(
          progress: progress,
          barHeight: height,
          gradientColors: [colors.primary, colors.secondary],
          trackColor: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
    );

    if (!showLabel) {
      return barWidget;
    }

    final labelText = fillLevel >= 100
        ? (isFr ? 'Scellée (100%)' : 'Sealed (100%)')
        : (isFr ? '$fillLevel% restant' : '$fillLevel% left');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                labelText,
                style: TextStyle(
                  fontSize: compact ? 9.5 : 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        barWidget,
      ],
    );
  }

  static _SpiritGradientColors _resolveColors(String? spiritType, String? wineName) {
    final text = '${spiritType?.toLowerCase() ?? ""} ${wineName?.toLowerCase() ?? ""}';

    if (text.contains('disaronno') || text.contains('amaretto')) {
      return const _SpiritGradientColors(Color(0xFFBF360C), Color(0xFFE64A19));
    }
    if (text.contains('italicus') || text.contains('rosolio')) {
      return const _SpiritGradientColors(Color(0xFF00A896), Color(0xFF00C9A7));
    }
    if (text.contains('chartreuse') || text.contains('absinthe')) {
      return const _SpiritGradientColors(Color(0xFF2E7D32), Color(0xFF4CAF50));
    }
    if (RegExp(r'\bgin\b', caseSensitive: false).hasMatch(text) || text.contains('vodka')) {
      return const _SpiritGradientColors(Color(0xFF00838F), Color(0xFF4DD0E1));
    }
    if (text.contains('rhum') || text.contains('rum')) {
      return const _SpiritGradientColors(Color(0xFF795548), Color(0xFFA1887F));
    }
    if (text.contains('cognac') || text.contains('armagnac') || text.contains('calvados')) {
      return const _SpiritGradientColors(Color(0xFF8D6E63), Color(0xFFBCAAA4));
    }
    if (text.contains('tequila') || text.contains('mezcal')) {
      return const _SpiritGradientColors(Color(0xFFD4AC0D), Color(0xFFF1C40F));
    }
    if (text.contains('porto') || text.contains('sherry') || text.contains('banyuls') || text.contains('fortified')) {
      return const _SpiritGradientColors(Color(0xFF8B1E3F), Color(0xFFC0392B));
    }
    // Default whisky / liquor amber gold
    return const _SpiritGradientColors(Color(0xFFD35400), Color(0xFFF39C12));
  }
}

class _SpiritGradientColors {
  final Color primary;
  final Color secondary;
  const _SpiritGradientColors(this.primary, this.secondary);
}

class _SpiritFillPainter extends CustomPainter {
  final double progress;
  final double barHeight;
  final List<Color> gradientColors;
  final Color trackColor;

  _SpiritFillPainter({
    required this.progress,
    required this.barHeight,
    required this.gradientColors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = (size.height - barHeight) / 2;
    final trackRect = Rect.fromLTWH(0, y, size.width, barHeight);
    final trackRRect = RRect.fromRectAndRadius(trackRect, Radius.circular(barHeight / 2));

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(trackRRect, trackPaint);

    if (progress <= 0.0) return;

    // Fill rect
    final fillWidth = (size.width * progress).clamp(barHeight, size.width);
    final fillRect = Rect.fromLTWH(0, y, fillWidth, barHeight);
    final fillRRect = RRect.fromRectAndRadius(fillRect, Radius.circular(barHeight / 2));

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(fillRect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(fillRRect, fillPaint);

    // Indicator bubble / meniscus dot at the end
    final indicatorX = (size.width * progress).clamp(barHeight / 2, size.width - barHeight / 2);
    final meniscusPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(indicatorX, size.height / 2), (barHeight / 2) - 0.5, meniscusPaint);
  }

  @override
  bool shouldRepaint(covariant _SpiritFillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.trackColor != trackColor;
  }
}
