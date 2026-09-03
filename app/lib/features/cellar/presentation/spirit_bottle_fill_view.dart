import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpiritBottleFillView extends StatefulWidget {
  final int fillLevel; // 0 to 100
  final ValueChanged<int> onFillLevelChanged;
  final String spiritType;
  final String? wineName;
  final bool readOnly;
  final double height;

  const SpiritBottleFillView({
    super.key,
    required this.fillLevel,
    required this.onFillLevelChanged,
    this.spiritType = 'spirit',
    this.wineName,
    this.readOnly = false,
    this.height = 240,
  });

  @override
  State<SpiritBottleFillView> createState() => _SpiritBottleFillViewState();
}

class _SpiritBottleFillViewState extends State<SpiritBottleFillView> {
  late int _currentLevel;
  double? _dragStartY;
  int? _dragStartLevel;

  @override
  void initState() {
    super.initState();
    _currentLevel = (widget.fillLevel / 10).round() * 10;
  }

  @override
  void didUpdateWidget(covariant SpiritBottleFillView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillLevel != widget.fillLevel) {
      setState(() {
        _currentLevel = (widget.fillLevel / 10).round() * 10;
      });
    }
  }

  void _updateLevel(int newLevel) {
    final clamped = (newLevel.clamp(0, 100) / 10).round() * 10;
    if (clamped != _currentLevel) {
      HapticFeedback.selectionClick();
      setState(() => _currentLevel = clamped);
      widget.onFillLevelChanged(clamped);
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (widget.readOnly) return;
    _dragStartY = details.localPosition.dy;
    _dragStartLevel = _currentLevel;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double bottleBodyHeight) {
    if (widget.readOnly || _dragStartY == null || _dragStartLevel == null) return;
    // Dragging UP decreases dy (negative delta), which means volume goes UP (+ level)
    final dyDelta = _dragStartY! - details.localPosition.dy;
    final pctDelta = (dyDelta / (bottleBodyHeight * 0.75)) * 100;
    final targetLevel = (_dragStartLevel! + pctDelta).round();
    _updateLevel(targetLevel);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _dragStartY = null;
    _dragStartLevel = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colors = _resolveLiquidColors(widget.spiritType, widget.wineName, isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getSpiritIcon(widget.spiritType, widget.wineName),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau de la bouteille',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _describeFillLevel(_currentLevel),
                      style: TextStyle(
                        fontSize: 11,
                        color: _currentLevel == 0 ? Colors.red : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Big Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentLevel == 0
                      ? Colors.red.withOpacity(0.15)
                      : colors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _currentLevel == 0 ? Colors.red : colors.primary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$_currentLevel %',
                  style: TextStyle(
                    color: _currentLevel == 0 ? Colors.red : colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Central Area: Stylized Bottle Canvas + Drag Interaction
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stylized Interactive Bottle
              GestureDetector(
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, widget.height),
                onVerticalDragEnd: _onVerticalDragEnd,
                child: SizedBox(
                  width: 120,
                  height: widget.height,
                  child: CustomPaint(
                    painter: _StylizedBottlePainter(
                      fillFraction: _currentLevel / 100.0,
                      primaryColor: colors.primary,
                      secondaryColor: colors.secondary,
                      glassBorderColor: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Side Controls & Explanatory Guide
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Glissez le doigt sur la bouteille pour ajuster le volume',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Step +/- 10%
                    if (!widget.readOnly)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.remove, size: 16),
                              label: const Text('-10%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: _currentLevel > 0 ? () => _updateLevel(_currentLevel - 10) : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('+10%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: _currentLevel < 100 ? () => _updateLevel(_currentLevel + 10) : null,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),

                    // Quick Preset Chips
                    if (!widget.readOnly)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildPresetChip(0, 'Vide (0%)'),
                          _buildPresetChip(25, '1/4'),
                          _buildPresetChip(50, '1/2'),
                          _buildPresetChip(75, '3/4'),
                          _buildPresetChip(100, 'Plein (100%)'),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(int level, String label) {
    final isSelected = _currentLevel == level;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onSelected: (_) => _updateLevel(level),
    );
  }

  static String _describeFillLevel(int level) {
    if (level <= 0) return '🔴 Bouteille vide (0%)';
    if (level <= 20) return '🟠 Fond de bouteille (~${(level * 7).round()} cl)';
    if (level <= 40) return '🟡 Moins de la moitié (~${(level * 7).round()} cl)';
    if (level <= 60) return '🟢 À moitié pleine (~${(level * 7).round()} cl)';
    if (level <= 80) return '🟢 Plus de la moitié (~${(level * 7).round()} cl)';
    return '🟢 Bouteille quasi pleine (~70 cl)';
  }

  static String _getSpiritIcon(String spiritType, String? wineName) {
    final lower = '${spiritType.toLowerCase()} ${wineName?.toLowerCase() ?? ""}';
    if (lower.contains('bénédictine') || lower.contains('benedictine')) return '🍯';
    if (lower.contains('chartreuse')) return '🌿';
    if (lower.contains('whisky') || lower.contains('bourbon')) return '🥃';
    if (lower.contains('rhum') || lower.contains('rum')) return '🏴‍☠️';
    if (lower.contains('gin')) return '🍸';
    if (lower.contains('vodka')) return '🧊';
    if (lower.contains('tequila') || lower.contains('mezcal')) return '🌵';
    if (lower.contains('cognac') || lower.contains('armagnac')) return '🍷';
    return '🍾';
  }

  static _SpiritColors _resolveLiquidColors(String spiritType, String? wineName, bool isDark) {
    final text = '${spiritType.toLowerCase()} ${wineName?.toLowerCase() ?? ""}';

    // Bénédictine: Honey amber gold
    if (text.contains('bénédictine') || text.contains('benedictine')) {
      return const _SpiritColors(
        primary: Color(0xFFD4AF37),
        secondary: Color(0xFFE5A93B),
      );
    }

    // Chartreuse
    if (text.contains('chartreuse')) {
      if (text.contains('jaune') || text.contains('yellow')) {
        return const _SpiritColors(
          primary: Color(0xFFC0CA33),
          secondary: Color(0xFFD4E157),
        );
      }
      return const _SpiritColors(
        primary: Color(0xFF2E7D32),
        secondary: Color(0xFF4CAF50),
      );
    }

    // Whisky / Bourbon
    if (text.contains('whisky') || text.contains('whiskey') || text.contains('bourbon') || text.contains('scotch')) {
      return const _SpiritColors(
        primary: Color(0xFFCC7722),
        secondary: Color(0xFFF39C12),
      );
    }

    // Rhum
    if (text.contains('rhum') || text.contains('rum')) {
      if (text.contains('blanc') || text.contains('white')) {
        return const _SpiritColors(
          primary: Color(0xFF0097A7),
          secondary: Color(0xFF80DEEA),
        );
      }
      return const _SpiritColors(
        primary: Color(0xFFB7410E),
        secondary: Color(0xFFE67E22),
      );
    }

    // Cognac / Armagnac
    if (text.contains('cognac') || text.contains('armagnac') || text.contains('brandy')) {
      return const _SpiritColors(
        primary: Color(0xFF9C4116),
        secondary: Color(0xFFD35400),
      );
    }

    // Gin / Vodka / Tequila Blanco
    if (text.contains('gin') || text.contains('vodka') || (text.contains('tequila') && text.contains('blanco'))) {
      return const _SpiritColors(
        primary: Color(0xFF00838F),
        secondary: Color(0xFF4DD0E1),
      );
    }

    // Tequila Reposado / Anejo / Mezcal
    if (text.contains('tequila') || text.contains('mezcal')) {
      return const _SpiritColors(
        primary: Color(0xFFD4AC0D),
        secondary: Color(0xFFF7DC6F),
      );
    }

    // Campari / Bitters / Liqueurs rouges
    if (text.contains('campari') || text.contains('bitter') || text.contains('aperitif') || text.contains('vermouth')) {
      return const _SpiritColors(
        primary: Color(0xFFC62828),
        secondary: Color(0xFFEF5350),
      );
    }

    // Default Liqueur / Spirit
    return const _SpiritColors(
      primary: Color(0xFFD4AF37),
      secondary: Color(0xFFF5B041),
    );
  }
}

class _SpiritColors {
  final Color primary;
  final Color secondary;

  const _SpiritColors({required this.primary, required this.secondary});
}

/// CustomPainter drawing a stylized, elegant spirit bottle with realistic glass and colored liquid
class _StylizedBottlePainter extends CustomPainter {
  final double fillFraction; // 0.0 to 1.0
  final Color primaryColor;
  final Color secondaryColor;
  final Color glassBorderColor;
  final bool isDark;

  _StylizedBottlePainter({
    required this.fillFraction,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glassBorderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bottle geometry specs
    final neckWidth = w * 0.28;
    final neckHeight = h * 0.28;
    final capHeight = h * 0.08;
    final shoulderTop = neckHeight;
    final shoulderBottom = h * 0.40;
    final bodyWidth = w * 0.76;
    final bodyLeft = (w - bodyWidth) / 2;
    final bodyRight = bodyLeft + bodyWidth;
    final bodyBottom = h * 0.94;
    final glassBaseBottom = h * 0.98;

    // 1. Build the outer bottle path
    final bottlePath = Path();
    // Cap top
    bottlePath.moveTo((w - neckWidth) / 2, capHeight);
    // Neck left
    bottlePath.lineTo((w - neckWidth) / 2, shoulderTop);
    // Shoulder left curve to body
    bottlePath.cubicTo(
      (w - neckWidth) / 2 - 2,
      shoulderTop + (shoulderBottom - shoulderTop) * 0.4,
      bodyLeft,
      shoulderTop + (shoulderBottom - shoulderTop) * 0.7,
      bodyLeft,
      shoulderBottom,
    );
    // Body left side
    bottlePath.lineTo(bodyLeft, bodyBottom);
    // Bottom left rounded corner
    bottlePath.quadraticBezierTo(bodyLeft, glassBaseBottom, bodyLeft + 12, glassBaseBottom);
    // Bottom line
    bottlePath.lineTo(bodyRight - 12, glassBaseBottom);
    // Bottom right rounded corner
    bottlePath.quadraticBezierTo(bodyRight, glassBaseBottom, bodyRight, bodyBottom);
    // Body right side
    bottlePath.lineTo(bodyRight, shoulderBottom);
    // Shoulder right curve to neck
    bottlePath.cubicTo(
      bodyRight,
      shoulderTop + (shoulderBottom - shoulderTop) * 0.7,
      (w + neckWidth) / 2 + 2,
      shoulderTop + (shoulderBottom - shoulderTop) * 0.4,
      (w + neckWidth) / 2,
      shoulderTop,
    );
    // Neck right
    bottlePath.lineTo((w + neckWidth) / 2, capHeight);
    bottlePath.close();

    // 2. Clip canvas to inside bottle for liquid painting
    canvas.save();
    canvas.clipPath(bottlePath);

    // Subtle dark/light glass backplate
    final glassBackPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02);
    canvas.drawPaint(glassBackPaint);

    // 3. Draw Liquid if fillFraction > 0
    if (fillFraction > 0.0) {
      // Liquid occupies from bodyBottom up to shoulderBottom (and neck if > 0.9)
      final liquidTotalHeight = bodyBottom - (shoulderTop + 10);
      final liquidTop = bodyBottom - (liquidTotalHeight * fillFraction.clamp(0.0, 1.0));

      final liquidRect = Rect.fromLTRB(0, liquidTop, w, glassBaseBottom);
      final liquidGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          secondaryColor.withOpacity(0.85),
          primaryColor.withOpacity(0.95),
        ],
      );

      final liquidPaint = Paint()..shader = liquidGradient.createShader(liquidRect);
      canvas.drawRect(liquidRect, liquidPaint);

      // Meniscus / surface line
      final meniscusPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final meniscusPath = Path();
      meniscusPath.moveTo(bodyLeft + 2, liquidTop);
      meniscusPath.quadraticBezierTo(w / 2, liquidTop - 2, bodyRight - 2, liquidTop);
      canvas.drawPath(meniscusPath, meniscusPaint);
    }

    // 4. Draw Graduation Notches (10%, 25%, 50%, 75%, 100%)
    final liquidTotalHeight = bodyBottom - (shoulderTop + 10);
    final notchPaint = Paint()
      ..color = isDark ? Colors.white38 : Colors.black26
      ..strokeWidth = 1.0;

    for (int step = 10; step <= 90; step += 10) {
      final y = bodyBottom - (liquidTotalHeight * (step / 100.0));
      final isMajor = step % 25 == 0;
      final notchWidth = isMajor ? 12.0 : 6.0;
      canvas.drawLine(
        Offset(bodyRight - notchWidth - 4, y),
        Offset(bodyRight - 4, y),
        notchPaint..strokeWidth = isMajor ? 1.5 : 1.0,
      );
    }

    // 5. Light Reflection Highlight (Glass Gleam)
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(bodyLeft + 6, shoulderBottom, 12, bodyBottom - shoulderBottom));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyLeft + 6, shoulderBottom + 4, 10, bodyBottom - shoulderBottom - 12),
        const Radius.circular(5),
      ),
      reflectionPaint,
    );

    canvas.restore();

    // 6. Draw Bottle Outer Stroke
    final outlinePaint = Paint()
      ..color = glassBorderColor.withOpacity(isDark ? 0.7 : 0.6)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bottlePath, outlinePaint);

    // 7. Draw Cap / Stopper
    final capRect = Rect.fromLTRB(
      (w - neckWidth) / 2 - 2,
      capHeight - 10,
      (w + neckWidth) / 2 + 2,
      capHeight + 4,
    );
    final capPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(4)), capPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(4)),
      outlinePaint..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _StylizedBottlePainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}
