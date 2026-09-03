import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A charming animated widget depicting Chatmelier holding a wine bottle upwards,
/// stretching its neck into a telescopic antenna to search for network signal.
class ChatmelierOfflineAntennaWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const ChatmelierOfflineAntennaWidget({
    super.key,
    this.title = 'Recherche de réseau...',
    this.message = 'Chatmelier tend le goulot de sa bouteille façon antenne pour capter le signal !',
    this.onRetry,
    this.compact = false,
  });

  @override
  State<ChatmelierOfflineAntennaWidget> createState() => _ChatmelierOfflineAntennaWidgetState();
}

class _ChatmelierOfflineAntennaWidgetState extends State<ChatmelierOfflineAntennaWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 12 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Bottle Antenna Illustration
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.compact ? 120 : 180, widget.compact ? 130 : 190),
                  painter: _ChatmelierAntennaPainter(
                    animationProgress: _controller.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B1E3F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                widget.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (widget.onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tester la connexion', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatmelierAntennaPainter extends CustomPainter {
  final double animationProgress;
  final bool isDark;

  _ChatmelierAntennaPainter({
    required this.animationProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height - 20;

    // 1. Draw Sommelier Cat Mascot Base (Silhouette & Bowtie)
    final catBodyPaint = Paint()
      ..color = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(Offset(centerX - 30, bottomY - 30), 22, catBodyPaint);

    // Cat ears
    final earPath = Path()
      ..moveTo(centerX - 46, bottomY - 42)
      ..lineTo(centerX - 40, bottomY - 60)
      ..lineTo(centerX - 30, bottomY - 48)
      ..close();
    canvas.drawPath(earPath, catBodyPaint);

    final earPath2 = Path()
      ..moveTo(centerX - 28, bottomY - 48)
      ..lineTo(centerX - 18, bottomY - 60)
      ..lineTo(centerX - 14, bottomY - 42)
      ..close();
    canvas.drawPath(earPath2, catBodyPaint);

    // Cute facial features & eyes looking up to the bottle antenna!
    final eyePaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.fill;
    // Eyes looking up towards bottle
    canvas.drawCircle(Offset(centerX - 36, bottomY - 35), 3, eyePaint);
    canvas.drawCircle(Offset(centerX - 24, bottomY - 35), 3, eyePaint);

    // Sommelier Burgundy Bow Tie
    final bowTiePaint = Paint()
      ..color = const Color(0xFF8B1E3F)
      ..style = PaintingStyle.fill;
    final bowPath = Path()
      ..moveTo(centerX - 30, bottomY - 14)
      ..lineTo(centerX - 38, bottomY - 20)
      ..lineTo(centerX - 38, bottomY - 8)
      ..close();
    canvas.drawPath(bowPath, bowTiePaint);
    final bowPath2 = Path()
      ..moveTo(centerX - 30, bottomY - 14)
      ..lineTo(centerX - 22, bottomY - 20)
      ..lineTo(centerX - 22, bottomY - 8)
      ..close();
    canvas.drawPath(bowPath2, bowTiePaint);
    canvas.drawCircle(Offset(centerX - 30, bottomY - 14), 2.5, bowTiePaint);

    // Sommelier Paw holding the bottle
    final pawPaint = Paint()
      ..color = isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, bottomY - 30), 8, pawPaint);

    // 2. Wine Bottle Body
    final bottleBasePaint = Paint()
      ..color = const Color(0xFF5C1126) // Deep Bordeaux bottle glass
      ..style = PaintingStyle.fill;

    final bottleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 12, bottomY - 65, 24, 45),
      const Radius.circular(5),
    );
    canvas.drawRRect(bottleRect, bottleBasePaint);

    // Gold label on bottle
    final labelPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 9, bottomY - 55, 18, 24),
      const Radius.circular(3),
    );
    canvas.drawRRect(labelRect, labelPaint);

    // Bottle shoulder transition
    final shoulderPath = Path()
      ..moveTo(centerX - 12, bottomY - 65)
      ..quadraticBezierTo(centerX - 10, bottomY - 78, centerX - 5, bottomY - 82)
      ..lineTo(centerX + 5, bottomY - 82)
      ..quadraticBezierTo(centerX + 10, bottomY - 78, centerX + 12, bottomY - 65)
      ..close();
    canvas.drawPath(shoulderPath, bottleBasePaint);

    // 3. Telescopic Bottle Neck Antenna stretching upwards!
    final stretchFactor = (math.sin(animationProgress * 2 * math.pi) + 1) / 2; // 0.0 -> 1.0
    final maxAntennaHeight = size.height * 0.45;
    final antennaHeight = 30.0 + (maxAntennaHeight * stretchFactor);

    final antennaPaint = Paint()
      ..color = const Color(0xFFD4AF37) // Metallic Gold Antenna Segments
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startAntennaY = bottomY - 82;
    final endAntennaY = startAntennaY - antennaHeight;

    // Segment 1 (thickest)
    antennaPaint.strokeWidth = 6.0;
    canvas.drawLine(Offset(centerX, startAntennaY), Offset(centerX, startAntennaY - (antennaHeight * 0.35)), antennaPaint);

    // Telescopic Joint 1
    canvas.drawCircle(Offset(centerX, startAntennaY - (antennaHeight * 0.35)), 3.5, Paint()..color = const Color(0xFF8B1E3F));

    // Segment 2 (medium)
    antennaPaint.strokeWidth = 4.0;
    canvas.drawLine(Offset(centerX, startAntennaY - (antennaHeight * 0.35)), Offset(centerX, startAntennaY - (antennaHeight * 0.7)), antennaPaint);

    // Telescopic Joint 2
    canvas.drawCircle(Offset(centerX, startAntennaY - (antennaHeight * 0.7)), 2.5, Paint()..color = const Color(0xFF8B1E3F));

    // Segment 3 (thin tip)
    antennaPaint.strokeWidth = 2.5;
    canvas.drawLine(Offset(centerX, startAntennaY - (antennaHeight * 0.7)), Offset(centerX, endAntennaY), antennaPaint);

    // Cork Antenna Tip (Bouchon de liège au sommet de l'antenne)
    final corkPaint = Paint()
      ..color = const Color(0xFFC29B38)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, endAntennaY), 4.5, corkPaint);

    // 4. Radio / Wi-Fi Signal Waves pulsing outwards from the tip
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= 3; i++) {
      final waveProgress = (animationProgress + (i * 0.33)) % 1.0;
      final radius = 10.0 + (waveProgress * 32.0);
      final alpha = ((1.0 - waveProgress) * 255).clamp(0, 255).toInt();

      wavePaint
        ..color = const Color(0xFF8B1E3F).withAlpha(alpha)
        ..strokeWidth = 2.5 - (waveProgress * 1.5);

      // Arc waves upwards
      const startAngle = -math.pi * 0.85;
      const sweepAngle = math.pi * 0.7;
      final waveRect = Rect.fromCircle(center: Offset(centerX, endAntennaY), radius: radius);
      canvas.drawArc(waveRect, startAngle, sweepAngle, false, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatmelierAntennaPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.isDark != isDark;
  }
}
