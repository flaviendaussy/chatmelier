import 'package:flutter/material.dart';
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

  String _selectedPriceFormat = 'bottle'; // 'bottle', '125ml', '175ml', 'glass'
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

    // Build Spider Datasets
    final datasets = <RadarChartDataset>[];
    for (int i = 0; i < activeWines.length; i++) {
      final wine = activeWines[i];
      final color = _palette[i % _palette.length];
      final metrics = isWhiteMode ? wine.metrics.toWhiteRadarMetrics() : wine.metrics.toRedRadarMetrics();

      datasets.add(RadarChartDataset(
        label: wine.vintage != null ? '${wine.name} (${wine.vintage})' : wine.name,
        metrics: metrics,
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
                            ? 'Comparaison Blancs (Minéralité, Beurré, Vivacité...)'
                            : 'Comparaison Rouges (Tannins, Puissance, Fruit...)',
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

          // Pricing Selector (Bouteille vs Verre 125ml vs Verre 175ml)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Format de prix :',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Bouteille'),
                      selected: _selectedPriceFormat == 'bottle',
                      onSelected: (v) => setState(() => _selectedPriceFormat = 'bottle'),
                    ),
                    ChoiceChip(
                      label: const Text('Verre 125ml'),
                      selected: _selectedPriceFormat == '125ml',
                      onSelected: (v) => setState(() => _selectedPriceFormat = '125ml'),
                    ),
                    ChoiceChip(
                      label: const Text('Verre 175ml'),
                      selected: _selectedPriceFormat == '175ml',
                      onSelected: (v) => setState(() => _selectedPriceFormat = '175ml'),
                    ),
                  ],
                ),
              ],
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
                        // Radar Chart
                        SizedBox(
                          height: 270,
                          child: WineTasteRadarChart(
                            datasets: datasets,
                            size: 260,
                            showLabels: true,
                          ),
                        ),

                        // Radar Axis Legend Note
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            isWhiteMode
                                ? 'Axes Blancs : Minéralité • Vivacité • Fruit • Beurré & Rondeur • Boisé • Corps'
                                : 'Axes Rouges : Tannins • Puissance • Acidité • Fruit • Boisé • Minéralité',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Wine Cards with Color indicators, prices & Match Score
                        ...List.generate(activeWines.length, (idx) {
                          final wine = activeWines[idx];
                          final color = _palette[idx % _palette.length];

                          // Resolve price according to selected format
                          String priceLabel = '';
                          if (_selectedPriceFormat == 'bottle') {
                            priceLabel = wine.bottlePrice != null
                                ? '${wine.bottlePrice!.toStringAsFixed(wine.bottlePrice! % 1 == 0 ? 0 : 2)} €'
                                : 'Non dispo';
                          } else {
                            final matchGlass = wine.glassPrices.firstWhere(
                              (g) => g.format.toLowerCase().contains(_selectedPriceFormat),
                              orElse: () => wine.glassPrices.isNotEmpty
                                  ? wine.glassPrices.first
                                  : const MenuWineGlassPrice(format: '', price: 0),
                            );
                            priceLabel = matchGlass.price > 0
                                ? '${matchGlass.price.toStringAsFixed(matchGlass.price % 1 == 0 ? 0 : 2)} € (${matchGlass.format})'
                                : (wine.bottlePrice != null ? '${wine.bottlePrice!.toStringAsFixed(0)} € (bt)' : 'N/A');
                          }

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
