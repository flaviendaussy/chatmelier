import 'package:flutter/material.dart';
import '../../features/cellar/domain/wine.dart';
import '../../features/cellar/domain/wine_service_advisor.dart';

/// Où tombent l'éveil, l'apogée, le déclin et aujourd'hui sur la jauge, entre 0 et 1.
///
/// Le dégradé était FIXE : le vert de l'apogée toujours à 55 % de la barre, quelle que
/// soit la fenêtre du vin, alors que le curseur, lui, se plaçait à la bonne année. Un
/// vin au cœur de son apogée affichait donc un curseur hors du vert (retour du 28/09 :
/// « le curseur d'apogée doit être centré sur le centre de l'apogée »). Les arrêts du
/// dégradé viennent désormais de la fenêtre effective du vin — la même que le badge et
/// la courbe de la fiche — et le centre de l'apogée est `(peakStart + peakEnd) / 2`,
/// comme dans `GaussianDrinkingCurve`.
class GeometrieDeGarde {
  /// Position d'aujourd'hui sur la barre.
  final double curseur;

  /// Début et fin de la zone verte, et son centre.
  final double debutApogee;
  final double finApogee;
  double get centreApogee => (debutApogee + finApogee) / 2;

  /// Arrêts du dégradé, dans l'ordre des couleurs de [couleurs].
  final List<double> arrets;

  static const couleurs = [
    Color(0xFFE57373), // Jeunesse
    Color(0xFFFFD54F), // Ouverture
    Color(0xFF4CAF50), // Début de l'apogée
    Color(0xFF4CAF50), // Fin de l'apogée
    Color(0xFFFFB74D), // Déclin
    Color(0xFFC62828), // Passé
  ];

  const GeometrieDeGarde._({
    required this.curseur,
    required this.debutApogee,
    required this.finApogee,
    required this.arrets,
  });

  factory GeometrieDeGarde.calculer(WineDrinkingWindowData f, {required int annee}) {
    final debut = f.vintage.toDouble();
    final peakEnd = f.peakEnd < f.peakStart ? f.peakStart : f.peakEnd;
    // Trois ans de marge après la fin de garde, pour voir le déclin arriver.
    final fin = (f.drinkEnd > peakEnd ? f.drinkEnd : peakEnd) + 3.0;
    double position(num y) => fin > debut ? ((y - debut) / (fin - debut)).clamp(0.0, 1.0) : 0.5;

    // Arrêts croissants : un dégradé refuse des arrêts qui reculent, et une fenêtre
    // stockée peut être incohérente (ouverture après le début de l'apogée).
    final bruts = [0.0, position(f.drinkStart), position(f.peakStart), position(peakEnd),
        position(f.drinkEnd), 1.0];
    final arrets = <double>[];
    for (final a in bruts) {
      arrets.add(arrets.isEmpty || a >= arrets.last ? a : arrets.last);
    }

    return GeometrieDeGarde._(
      curseur: position(annee),
      debutApogee: position(f.peakStart),
      finApogee: position(peakEnd),
      arrets: arrets,
    );
  }
}

class MaturityColorbar extends StatelessWidget {
  final Wine wine;
  final double width;
  final double height;
  final bool showLabel;

  /// Ce qui se lit au bout de la ligne de l'état, à droite : les années de la fenêtre, sur la
  /// carte d'une bouteille. La jauge garde ainsi toute la largeur (retour du 08/10).
  final String? fin;

  const MaturityColorbar({
    super.key,
    required this.wine,
    this.width = 110,
    this.height = 8,
    this.showLabel = true,
    this.fin,
  });

  @override
  Widget build(BuildContext context) {
    final geometrie = GeometrieDeGarde.calculer(wine.fenetreEffective, annee: DateTime.now().year);

    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final status = wine.windowStatus;
    final statusText = status.phrase.dans(isFr);
    final statusColor = status.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisSize: fin == null ? MainAxisSize.min : MainAxisSize.max,
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
                if (fin == null)
                  Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor))
                else ...[
                  Expanded(
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fin!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        SizedBox(
          width: width,
          height: height + 6,
          child: CustomPaint(
            painter: _MaturityBarPainter(
              geometrie: geometrie,
              barHeight: height,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaturityBarPainter extends CustomPainter {
  final GeometrieDeGarde geometrie;
  final double barHeight;

  _MaturityBarPainter({
    required this.geometrie,
    required this.barHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, (size.height - barHeight) / 2, size.width, barHeight);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(barHeight / 2));

    final gradient = LinearGradient(
      colors: GeometrieDeGarde.couleurs,
      stops: geometrie.arrets,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);

    // Draw Today Tick (black vertical indicator needle with subtle white outline)
    final tickX = (size.width * geometrie.curseur).clamp(2.0, size.width - 2.0);
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
      oldDelegate.geometrie.curseur != geometrie.curseur ||
      oldDelegate.geometrie.arrets.toString() != geometrie.arrets.toString() ||
      oldDelegate.barHeight != barHeight;
}
