import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// La légende de l'empreinte de palais : ce que veulent dire trait plein, pointillés et
/// moustaches. Trois glyphes dessinés comme dans le radar, pour qu'on les reconnaisse.
class LegendeDuRadar extends StatelessWidget {
  final Color color;

  const LegendeDuRadar({super.key, this.color = const Color(0xFF8B1E3F)});

  @override
  Widget build(BuildContext context) {
    // Sans délégués de traduction (tests, écrans isolés), on retombe sur la langue du
    // système plutôt que de planter.
    final l10n = AppLocalizations.of(context);
    final fr = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    final observe = l10n?.radarLegendObserved ?? (fr ? 'Observé' : 'Observed');
    final devine = l10n?.radarLegendGuessed ?? (fr ? 'Deviné' : 'Guessed');
    final marge = l10n?.radarLegendMargin ?? (fr ? 'Marge d\'incertitude' : 'Uncertainty');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = TextStyle(fontSize: 10.5, color: isDark ? Colors.white70 : Colors.black54);
    Widget element(_Glyphe glyphe, String texte) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(size: const Size(24, 10), painter: glyphe),
            const SizedBox(width: 5),
            Text(texte, style: style),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 4,
      children: [
        element(_Glyphe(color, _Sorte.observe, isDark), observe),
        element(_Glyphe(color, _Sorte.devine, isDark), devine),
        element(_Glyphe(color, _Sorte.marge, isDark), marge),
      ],
    );
  }
}

enum _Sorte { observe, devine, marge }

class _Glyphe extends CustomPainter {
  final Color color;
  final _Sorte sorte;
  final bool isDark;

  _Glyphe(this.color, this.sorte, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final trait = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sorte == _Sorte.marge ? 1.6 : 2.2
      ..strokeCap = StrokeCap.round;
    final milieu = Offset(size.width / 2, y);
    switch (sorte) {
      case _Sorte.observe:
        canvas.drawLine(Offset(0, y), Offset(size.width, y), trait);
        canvas.drawCircle(milieu, 4.3, Paint()..color = color);
      case _Sorte.devine:
        for (var x = 0.0; x < size.width; x += 8.0) {
          canvas.drawLine(Offset(x, y), Offset((x + 4.5).clamp(0, size.width), y), trait);
        }
        canvas.drawCircle(milieu, 3.6, Paint()..color = isDark ? const Color(0xFF1E1A24) : Colors.white);
        canvas.drawCircle(
            milieu,
            3.6,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8);
      case _Sorte.marge:
        final teinte = trait..color = color.withAlpha(200);
        canvas.drawLine(Offset(2, y), Offset(size.width - 2, y), teinte);
        canvas.drawLine(Offset(2, y - 3.5), Offset(2, y + 3.5), teinte);
        canvas.drawLine(Offset(size.width - 2, y - 3.5), Offset(size.width - 2, y + 3.5), teinte);
    }
  }

  @override
  bool shouldRepaint(covariant _Glyphe old) => old.color != color || old.sorte != sorte || old.isDark != isDark;
}
