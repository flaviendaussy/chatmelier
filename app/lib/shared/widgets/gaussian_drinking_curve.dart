import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../features/cellar/domain/wine.dart';
import '../../features/cellar/domain/wine_service_advisor.dart';
import '../../shared/utils/langue.dart';

class GaussianDrinkingCurve extends StatelessWidget {
  final Wine wine;
  final double height;

  const GaussianDrinkingCurve({
    super.key,
    required this.wine,
    this.height = 200,
  });

  /// La fenêtre que la courbe dessine : la démonstration de l'apogée (E6) en tire sa
  /// légende, pour qu'elle dise exactement ce que la courbe montre.
  static WineDrinkingWindowData fenetreDe(Wine wine) => WineOenologyAdvisor.computeDrinkingWindow(
        wineType: wine.type,
        vintage: wine.vintage,
        country: wine.country,
        producer: wine.producer,
        grapes: wine.grapes.map((g) => g.name).toList(),
        region: wine.region,
        appellation: wine.appellation,
        classification: wine.classification,
        wineName: wine.name,
        explicitDrinkStart: wine.drinkStart,
        explicitDrinkEnd: wine.drinkEnd,
        explicitPeakStart: wine.peakStart,
        explicitPeakEnd: wine.peakEnd,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // For non-vintage wines (Champagne NV, Prosecco, Sans Millésime):
    // Do not show an artificial chronological curve since harvest year does not exist.
    if (wine.vintage == null || wine.vintage == 0) {
      return _buildNonVintageView(context, theme, isDark);
    }

    final currentYear = DateTime.now().year;

    final window = fenetreDe(wine);

    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final vintage = window.vintage;
    final drinkStart = window.drinkStart;
    final drinkEnd = window.drinkEnd;
    final peakStart = window.peakStart;
    final peakEnd = window.peakEnd;
    final maxYear = window.maxYear;

    final status = wine.windowStatus;
    String statusDescription;
    String badgeText;
    final Color statusColor = status.color;

    switch (status) {
      case DrinkWindowStatus.tooYoung:
        badgeText = trSi(isFr, 'TROP JEUNE', 'TOO YOUNG');
        statusDescription = trSi(isFr, 'Trop jeune pour être apprécié à son plein potentiel. Laisser reposer en cave.', 'Too young to be enjoyed at its full potential. Let it rest in cellar.');
        break;
      case DrinkWindowStatus.aging:
        badgeText = trSi(isFr, 'EN GARDE', 'AGING');
        statusDescription = trSi(isFr, 'En période de garde et d\'élevage. Le vin affine ses tanins et sa complexité.', 'In aging and maturation phase. The wine is softening its tannins and developing complexity.');
        break;
      case DrinkWindowStatus.inPeak:
        badgeText = trSi(isFr, 'À L\'APOGÉE ✨', 'AT PEAK ✨');
        statusDescription = trSi(isFr, 'Actuellement dans sa fenêtre d\'apogée idéale ! Équilibre parfait. 🍷', 'Currently in its ideal drinking peak! Perfect balance. 🍷');
        break;
      case DrinkWindowStatus.drinkSoon:
        badgeText = trSi(isFr, 'À BOIRE ⏰', 'DRINK SOON ⏰');
        statusDescription = trSi(isFr, 'À consommer prochainement pour profiter de toute sa fraîcheur et de son fruit.', 'Consume soon to enjoy all of its freshness and fruit expression.');
        break;
      case DrinkWindowStatus.pastPeak:
        badgeText = trSi(isFr, 'PASSÉ L\'APOGÉE ⚠️', 'PAST PEAK ⚠️');
        statusDescription = trSi(isFr, 'Apogée dépassée. À déguster sans tarder pour apprécier les arômes tertiaires.', 'Past peak. Taste without delay to appreciate tertiary aromas.');
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Texte agrandi du téléphone : le titre passe à la ligne, le badge reste entier.
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.auto_graph, size: 18, color: Color(0xFF8B1E3F)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      trSi(isFr, 'Courbe de Maturité & Apogée', 'Maturity & Drinking Window Curve'),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withAlpha(100)),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _GaussianCurvePainter(
              vintage: vintage,
              drinkStart: drinkStart,
              drinkEnd: drinkEnd,
              peakStart: peakStart,
              peakEnd: peakEnd,
              maxYear: maxYear,
              currentYear: currentYear,
              primaryColor: const Color(0xFF8B1E3F),
              goldColor: const Color(0xFFD4AF37),
              isDark: isDark,
              isFr: isFr,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNonVintageView(BuildContext context, ThemeData theme, bool isDark) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    const goldColor = Color(0xFFD4AF37);
    const burgColor = Color(0xFF8B1E3F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Le titre est celui de la section qui accueille la courbe (fiche de la bouteille,
        // dégustation) : le répéter ici poussait « Prêt à boire » hors de la carte (Caro,
        // 04/10).
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 12, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                trSi(isFr, 'PRÊT À BOIRE ✨', 'READY TO DRINK ✨'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Non-vintage Sommelier Guidance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1A24) : const Color(0xFFFBF8F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: goldColor.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🍾', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trSi(isFr, 'Cuvée Sans Millésime (NM)', 'Non-Vintage Cuvee (NV)'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          trSi(isFr, 'Assemblage équilibré multi-années', 'Balanced multi-vintage blend'),
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                trSi(isFr, 'Par définition, les champagnes et vins non millésimés sont commercialisés à leur parfait équilibre par le chef de cave. Ils sont prêts à être savourés dès aujourd\'hui sans nécessiter de garde prolongée.', 'By definition, non-vintage champagnes and wines are released at their perfect balance by the cellar master. They are ready to be enjoyed today without requiring extended cellar aging.'),
                style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
              ),
              const SizedBox(height: 14),

              // 2 Insight badges
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: burgColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: burgColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trSi(isFr, 'Dégustation Idéale', 'Ideal Tasting'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: burgColor)),
                          const SizedBox(height: 2),
                          Text(trSi(isFr, 'Dès à présent', 'Ready now'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trSi(isFr, 'Potentiel de cave', 'Cellar Potential'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: goldColor)),
                          const SizedBox(height: 2),
                          Text(trSi(isFr, '1 à 3 ans max', '1 to 3 yrs max'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Les bords gauches d'étiquettes centrées sur [centres] et larges de [largeurs], rangées
/// dans l'ordre entre [debut] et [fin] sans se chevaucher (au moins [ecart] entre deux) ;
/// nul si elles n'y tiennent pas.
///
/// Les étiquettes qui se touchent forment une grappe, placée pour que chacune s'écarte le
/// moins possible de son année : deux voisines se partagent le décalage, au lieu que la
/// seconde le prenne tout entier.
@visibleForTesting
List<double>? placerSansChevauchement(
  List<double> centres,
  List<double> largeurs,
  double debut,
  double fin, {
  double ecart = 4,
}) {
  final n = centres.length;
  // Chaque grappe : [première, dernière] étiquette.
  final grappes = <List<int>>[
    for (var i = 0; i < n; i++) [i, i],
  ];
  double largeur(List<int> g) {
    var w = ecart * (g[1] - g[0]);
    for (var i = g[0]; i <= g[1]; i++) {
      w += largeurs[i];
    }
    return w;
  }

  // Le bord gauche qui minimise les écarts au carré entre chaque étiquette et son année.
  double gauche(List<int> g) {
    var somme = 0.0;
    var decalage = 0.0;
    for (var i = g[0]; i <= g[1]; i++) {
      somme += centres[i] - decalage - largeurs[i] / 2;
      decalage += largeurs[i] + ecart;
    }
    final w = largeur(g);
    return (somme / (g[1] - g[0] + 1)).clamp(debut, math.max(debut, fin - w));
  }

  var fusion = true;
  while (fusion) {
    fusion = false;
    for (var k = 0; k + 1 < grappes.length; k++) {
      if (gauche(grappes[k]) + largeur(grappes[k]) + ecart > gauche(grappes[k + 1]) + 1e-9) {
        grappes[k] = [grappes[k][0], grappes[k + 1][1]];
        grappes.removeAt(k + 1);
        fusion = true;
        break;
      }
    }
  }

  final gauches = List<double>.filled(n, 0);
  for (final g in grappes) {
    if (largeur(g) > fin - debut) return null;
    var x = gauche(g);
    for (var i = g[0]; i <= g[1]; i++) {
      gauches[i] = x;
      x += largeurs[i] + ecart;
    }
  }
  return gauches;
}

class _GaussianCurvePainter extends CustomPainter {
  final int vintage;
  final int drinkStart;
  final int drinkEnd;
  final int peakStart;
  final int peakEnd;
  final int maxYear;
  final int currentYear;
  final Color primaryColor;
  final Color goldColor;
  final bool isDark;
  final bool isFr;

  _GaussianCurvePainter({
    required this.vintage,
    required this.drinkStart,
    required this.drinkEnd,
    required this.peakStart,
    required this.peakEnd,
    required this.maxYear,
    required this.currentYear,
    required this.primaryColor,
    required this.goldColor,
    required this.isDark,
    this.isFr = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final startYear = math.min(vintage, currentYear - 1);
    final endYear = math.max(maxYear, currentYear + 2);
    final totalYears = endYear - startYear;

    if (totalYears <= 0) return;

    const double paddingLeft = 10;
    const double paddingRight = 10;
    const double paddingTop = 25;
    const double paddingBottom = 30;

    final double graphWidth = size.width - paddingLeft - paddingRight;
    final double graphHeight = size.height - paddingTop - paddingBottom;

    double yearToX(double year) {
      return paddingLeft + ((year - startYear) / totalYears) * graphWidth;
    }

    double calcGaussian(double year) {
      final center = (peakStart + peakEnd) / 2.0;
      final span = math.max(1.0, (drinkEnd - drinkStart) / 2.0);
      final sigma = span / 2.0;
      final exponent = -math.pow(year - center, 2) / (2 * math.pow(sigma, 2));
      return math.exp(exponent);
    }

    final double baselineY = paddingTop + graphHeight;

    // 1. Draw Peak Drinking Window Zone (Golden shaded background)
    final double peakStartX = yearToX(peakStart.toDouble()).clamp(paddingLeft, size.width - paddingRight);
    final double peakEndX = yearToX(peakEnd.toDouble()).clamp(paddingLeft, size.width - paddingRight);

    final peakZonePaint = Paint()
      ..color = goldColor.withAlpha(isDark ? 35 : 25)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(peakStartX, paddingTop - 10, peakEndX, baselineY),
        const Radius.circular(6),
      ),
      peakZonePaint,
    );

    // 2. Compute Bell Curve Path
    final path = Path();
    final fillPath = Path();
    fillPath.moveTo(paddingLeft, baselineY);

    const int steps = 60;
    for (int i = 0; i <= steps; i++) {
      final double year = startYear + (totalYears * (i / steps));
      final double x = yearToX(year);
      final double yRatio = calcGaussian(year);
      final double y = baselineY - (yRatio * (graphHeight * 0.85));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(paddingLeft + graphWidth, baselineY);
    fillPath.close();

    // 3. Fill Curve Gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withAlpha(isDark ? 90 : 60),
        primaryColor.withAlpha(5),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, paddingTop, size.width, graphHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 4. Stroke Curve Outline
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // 5. Draw Peak Interval Highlight
    final peakStrokePaint = Paint()
      ..color = goldColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final peakPath = Path();
    bool peakStarted = false;
    for (int i = 0; i <= steps; i++) {
      final double year = startYear + (totalYears * (i / steps));
      if (year >= peakStart && year <= peakEnd) {
        final double x = yearToX(year);
        final double yRatio = calcGaussian(year);
        final double y = baselineY - (yRatio * (graphHeight * 0.85));
        if (!peakStarted) {
          peakPath.moveTo(x, y);
          peakStarted = true;
        } else {
          peakPath.lineTo(x, y);
        }
      }
    }
    canvas.drawPath(peakPath, peakStrokePaint);

    // 6. Draw Current Year Indicator (Vertical Marker with Dot)
    final double curX = yearToX(currentYear.toDouble());
    if (curX >= paddingLeft && curX <= size.width - paddingRight) {
      final linePaint = Paint()
        ..color = isDark ? Colors.white70 : Colors.black87
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Dashed vertical line
      const double dashHeight = 4;
      const double dashSpace = 3;
      double startY = paddingTop;
      while (startY < baselineY) {
        canvas.drawLine(
          Offset(curX, startY),
          Offset(curX, math.min(startY + dashHeight, baselineY)),
          linePaint,
        );
        startY += dashHeight + dashSpace;
      }

      // Point on the curve for current year
      final curYRatio = calcGaussian(currentYear.toDouble());
      final curY = baselineY - (curYRatio * (graphHeight * 0.85));

      final dotOuter = Paint()..color = primaryColor;
      final dotInner = Paint()..color = Colors.white;

      canvas.drawCircle(Offset(curX, curY), 5, dotOuter);
      canvas.drawCircle(Offset(curX, curY), 2.5, dotInner);

      // Label "Aujourd'hui"
      final todayPainter = TextPainter(
        text: TextSpan(
          text: '$currentYear',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      todayPainter.paint(
        canvas,
        Offset(curX - (todayPainter.width / 2), paddingTop - 16),
      );
    }

    // 7. Les années de l'axe — récolte, début, apogée, fin — sans se chevaucher : à un an
    // d'écart, « 2024 Début » s'écrivait sur « 2025 Apogée ». Trop proches, elles s'écartent
    // tant que la place le permet ; sinon la moins utile cède, la récolte d'abord (le
    // millésime est déjà sur la fiche). Une même année ne porte qu'une étiquette.
    final etiquettes = <(int annee, double x, TextPainter tp, int rang)>[];
    void etiquette(int yr, String label, int rang, {bool isGold = false}) {
      final x = yearToX(yr.toDouble());
      if (x < paddingLeft - 5 || x > size.width - paddingRight + 5) return;
      final meme = etiquettes.indexWhere((e) => e.$1 == yr);
      if (meme >= 0) {
        if (etiquettes[meme].$4 >= rang) return;
        etiquettes.removeAt(meme);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '$yr\n$label',
          style: TextStyle(
            color: isGold ? goldColor : (isDark ? Colors.white60 : Colors.black54),
            fontSize: 9,
            fontWeight: isGold ? FontWeight.bold : FontWeight.normal,
            height: 1.1,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      etiquettes.add((yr, x, tp, rang));
    }

    etiquette(vintage, trSi(isFr, 'Récolte', 'Vintage'), 1);
    if (drinkStart != vintage) etiquette(drinkStart, trSi(isFr, 'Début', 'Start'), 2);
    etiquette(peakStart, trSi(isFr, 'Apogée ✨', 'Peak ✨'), 3, isGold: true);
    if (drinkEnd != peakStart && drinkEnd != peakEnd) etiquette(drinkEnd, trSi(isFr, 'Fin', 'End'), 2);
    etiquettes.sort((a, b) => a.$2.compareTo(b.$2));

    while (etiquettes.isNotEmpty) {
      final gauches = placerSansChevauchement(
        [for (final e in etiquettes) e.$2],
        [for (final e in etiquettes) e.$3.width],
        0,
        size.width,
      );
      if (gauches != null) {
        for (var i = 0; i < etiquettes.length; i++) {
          etiquettes[i].$3.paint(canvas, Offset(gauches[i], baselineY + 5));
        }
        break;
      }
      // La moins utile cède : le rang le plus bas, et à rang égal la plus tardive.
      var faible = 0;
      for (var i = 1; i < etiquettes.length; i++) {
        if (etiquettes[i].$4 <= etiquettes[faible].$4) faible = i;
      }
      etiquettes.removeAt(faible);
    }
  }

  @override
  bool shouldRepaint(covariant _GaussianCurvePainter oldDelegate) {
    return oldDelegate.vintage != vintage ||
        oldDelegate.drinkStart != drinkStart ||
        oldDelegate.drinkEnd != drinkEnd ||
        oldDelegate.peakStart != peakStart ||
        oldDelegate.peakEnd != peakEnd ||
        oldDelegate.currentYear != currentYear ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isFr != isFr;
  }
}
