import 'package:flutter/material.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import '../domain/menu_wine.dart';

class MenuWineCompareSheet extends StatefulWidget {
  final List<MenuWine> selectedWines;

  const MenuWineCompareSheet({super.key, required this.selectedWines});

  static Future<void> show(BuildContext context, List<MenuWine> wines) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuWineCompareSheet(selectedWines: wines),
    );
  }

  @override
  State<MenuWineCompareSheet> createState() => _MenuWineCompareSheetState();
}

class _MenuWineCompareSheetState extends State<MenuWineCompareSheet> {
  static const List<Color> _palette = [
    Color(0xFF8B1E3F), // Burgundy Red
    Color(0xFFD4AF37), // Gold
    Color(0xFF1E88E5), // Blue
    Color(0xFF2E7D32), // Green
    Color(0xFFE65100), // Orange
    Color(0xFF8E24AA), // Purple
  ];

  String _currentColorTab = 'red'; // 'red' or 'white'

  @override
  void initState() {
    super.initState();
    final reds = widget.selectedWines.where((w) => w.isRed).toList();
    final whites = widget.selectedWines.where((w) => w.isWhite || w.isSparkling || w.isRose).toList();

    if (reds.isNotEmpty) {
      _currentColorTab = 'red';
    } else if (whites.isNotEmpty) {
      _currentColorTab = 'white';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final reds = widget.selectedWines.where((w) => w.isRed).toList();
    final whites = widget.selectedWines.where((w) => w.isWhite || w.isSparkling || w.isRose).toList();
    final hasBoth = reds.isNotEmpty && whites.isNotEmpty;

    final activeWines = _currentColorTab == 'red' ? reds : whites;
    final isWhiteMode = _currentColorTab == 'white';

    // Build Spider Datasets with colour-specific fields (Beurre for whites, Tannins for reds)
    final datasets = <RadarChartDataset>[];
    for (int i = 0; i < activeWines.length; i++) {
      final wine = activeWines[i];
      final color = _palette[i % _palette.length];
      final values = isWhiteMode ? wine.metrics.toWhiteValues() : wine.metrics.toRedValues();

      datasets.add(RadarChartDataset(
        label: wine.vintage != null ? '${wine.name} (${wine.vintage})' : wine.name,
        customValues: values,
        color: color,
      ));
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1724) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.radar, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparateur Spider Radar',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isWhiteMode
                            ? 'Profil Blancs (Beurré, Minéralité, Vivacité, Douceur...)'
                            : 'Profil Rouges (Tannins, Puissance, Baies, Élevage...)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Color Isolation Tabs if mixed colors are selected
          if (hasBoth)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'red',
                    label: Text('Rouges (${reds.length})'),
                    icon: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F)),
                  ),
                  ButtonSegment(
                    value: 'white',
                    label: Text('Blancs & Bulles (${whites.length})'),
                    icon: const Icon(Icons.wine_bar, color: Color(0xFFE8D08D)),
                  ),
                ],
                selected: {_currentColorTab},
                onSelectionChanged: (val) {
                  setState(() => _currentColorTab = val.first);
                },
              ),
            ),

          const Divider(height: 1),

          // Scrollable Content: Spider Chart + Wine Cards with Prices & Match Scores
          Expanded(
            child: activeWines.isEmpty
                ? const Center(
                    child: Text('Aucun vin sélectionné dans cette couleur.'),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Radar Chart with 7 dynamic colour-specific axes
                        SizedBox(
                          height: 270,
                          child: WineTasteRadarChart(
                            datasets: datasets,
                            customAxisLabels: isWhiteMode
                                ? MenuWineRadarMetrics.whiteAxisLabels
                                : MenuWineRadarMetrics.redAxisLabels,
                            size: 260,
                            showLabels: true,
                          ),
                        ),

                        // Radar Axis Legend Note
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            isWhiteMode
                                ? 'Axes Blancs : Minéralité • Vivacité • Fleurs • Beurré & Rondeur • Boisé • Douceur • Puissance'
                                : 'Axes Rouges : Tannins • Puissance • Acidité • Baies • Élevage • Minéralité • Persistance',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Wine Cards with Color indicators, prices & Match Score
                        ...List.generate(activeWines.length, (idx) {
                          final wine = activeWines[idx];
                          final color = _palette[idx % _palette.length];

                          // Resolve price automatically without format selector
                          String priceLabel = '';
                          if (wine.bottlePrice != null && wine.bottlePrice! > 0) {
                            priceLabel = '${CurrencyHelper.formatPrice(wine.bottlePrice!)} / bt';
                          }
                          if (wine.glassPrices.isNotEmpty) {
                            final g = wine.glassPrices.first;
                            final gStr = '${CurrencyHelper.formatPrice(g.price)} (${g.format})';
                            priceLabel = priceLabel.isNotEmpty ? '$priceLabel • $gStr' : gStr;
                          }
                          if (priceLabel.isEmpty) priceLabel = 'Prix non indiqué';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                // Color Dot
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                // Name & Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wine.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        '${wine.producer} • ${wine.vintage ?? "NM"} • ${wine.region ?? ""}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      if (wine.tags.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            wine.tags.map((t) => '#$t').join(' '),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Price & Match Score
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      priceLabel,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (wine.userMatchScore != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${wine.userMatchScore!.round()}% Match',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
