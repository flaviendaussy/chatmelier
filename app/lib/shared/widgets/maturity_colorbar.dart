import 'package:flutter/material.dart';
import '../../features/cellar/domain/wine.dart';

class MaturityColorbar extends StatelessWidget {
  final Wine wine;
  final double width;
  final double height;
  final bool showLabel;

  const MaturityColorbar({
    super.key,
    required this.wine,
    this.width = 110,
    this.height = 8,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final vintage = wine.vintage ?? (currentYear - 2);
    final drinkEnd = wine.drinkEnd ?? (vintage + 10);
    final timelineEnd = drinkEnd + 3;

    // Calculate normalized position (0.0 to 1.0)
    double progress = 0.5;
    if (timelineEnd > vintage) {
      progress = ((currentYear - vintage) / (timelineEnd - vintage)).clamp(0.0, 1.0);
    }

    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final status = wine.windowStatus;
    final statusText = isFr ? status.labelFr : status.labelEn;
    final statusColor = status.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
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
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: width,
          height: height + 6,
          child: CustomPaint(
            painter: _MaturityBarPainter(
              progress: progress,
              barHeight: height,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaturityBarPainter extends CustomPainter {
  final double progress;
  final double barHeight;

  _MaturityBarPainter({
    required this.progress,
    required this.barHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, (size.height - barHeight) / 2, size.width, barHeight);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(barHeight / 2));

    // Multi-color gradient spectrum: Red -> Yellow -> Green -> Amber -> Red
    const gradient = LinearGradient(
      colors: [
        Color(0xFFE57373), // Red / Youth
        Color(0xFFFFD54F), // Yellow / Maturing
        Color(0xFF4CAF50), // Green / Peak Plateau
        Color(0xFFFFB74D), // Amber / Declining
        Color(0xFFC62828), // Deep Red / Past Peak
      ],
      stops: [0.0, 0.25, 0.55, 0.80, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);

    // Draw Today Tick (black vertical indicator needle with subtle white outline)
    final tickX = (size.width * progress).clamp(2.0, size.width - 2.0);
    const tickTop = 0.0;
    final tickBottom = size.height;

    // Shadow / Outline
    final outlinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(tickX, tickTop), Offset(tickX, tickBottom), outlinePaint);

    // Black tick
    final tickPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(tickX, tickTop), Offset(tickX, tickBottom), tickPaint);
  }

  @override
  bool shouldRepaint(covariant _MaturityBarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.barHeight != barHeight;
}
