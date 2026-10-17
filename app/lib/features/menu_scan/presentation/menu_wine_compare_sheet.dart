import 'package:flutter/material.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import '../domain/menu_wine.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/widgets/wine_type_badge.dart';

class MenuWineCompareSheet extends StatefulWidget {
  final List<MenuWine> selectedWines;

  const MenuWineCompareSheet({super.key, required this.selectedWines});

  static Future<void> show(BuildContext context, List<MenuWine> wines) {
    // Trace d'usage : la console d'administration compte ce qui ne laisse rien en base.
    AppLogger.info('USAGE', 'comparaison_de_vins');
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

  // Deux groupes, les rouges et les autres (13/10 : « c'est bien de séparer en seulement deux
  // catégories »). Les autres comptaient seulement blancs, rosés et bulles : un moelleux ou un
  // muté choisi pour la comparaison disparaissait.
  late final List<MenuWine> _rouges = widget.selectedWines.where((w) => w.isRed).toList();
  late final List<MenuWine> _autres = widget.selectedWines.where((w) => !w.isRed).toList();
  late final PageController _pages = PageController(initialPage: _rouges.isEmpty ? 1 : 0);
  late int _groupe = _rouges.isEmpty ? 1 : 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Le groupe choisi au bouton : la page glisse jusqu'à lui ; glisser du doigt fait de même
  /// en sens inverse (13/10 : « je dois pouvoir slider ici en glissant mon doigt »).
  void _allerAuGroupe(int groupe) {
    setState(() => _groupe = groupe);
    _pages.animateToPage(groupe, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lesDeux = _rouges.isNotEmpty && _autres.isNotEmpty;
    final modeBlanc = _groupe == 1;

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
                        trSi(isFr, 'Comparateur Spider Radar', 'Spider Radar Comparator'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        modeBlanc
                            ? (trSi(isFr, 'Profil Blancs (Beurré, Minéralité, Vivacité, Douceur...)', 'White Profile (Buttery, Minerality, Crispness, Sweetness...)'))
                            : (trSi(isFr, 'Profil Rouges (Tannins, Puissance, Baies, Élevage...)', 'Red Profile (Tannins, Power, Berries, Oak aging...)')),
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

          if (lesDeux)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(trSi(isFr, 'Rouges ({reds_length})', 'Reds ({reds_length})', {'reds_length': _rouges.length})),
                    icon: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F)),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(trSi(isFr, 'Autres ({n})', 'Others ({n})', {'n': _autres.length})),
                    icon: const Icon(Icons.wine_bar, color: Color(0xFFE8D08D)),
                  ),
                ],
                selected: {_groupe},
                onSelectionChanged: (val) => _allerAuGroupe(val.first),
              ),
            ),

          const Divider(height: 1),

          Expanded(
            child: lesDeux
                ? PageView(
                    controller: _pages,
                    onPageChanged: (page) => setState(() => _groupe = page),
                    children: [
                      _pageDuGroupe(context, _rouges, modeBlanc: false),
                      _pageDuGroupe(context, _autres, modeBlanc: true),
                    ],
                  )
                : _pageDuGroupe(context, _rouges.isNotEmpty ? _rouges : _autres, modeBlanc: _rouges.isEmpty),
          ),
        ],
      ),
    );
  }

  /// Le radar d'un groupe, et la fiche de chaque vin avec sa couleur (13/10 : « on doit quand
  /// même pouvoir voir lesquels sont blancs, rosés, etc. dans leurs détails »).
  Widget _pageDuGroupe(BuildContext context, List<MenuWine> vins, {required bool modeBlanc}) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (vins.isEmpty) {
      return Center(child: Text(trSi(isFr, 'Aucun vin sélectionné dans cette couleur.', 'No wine selected in this style.')));
    }
    final datasets = [
      for (final (i, wine) in vins.indexed)
        RadarChartDataset(
          label: wine.vintage != null ? '${wine.name} (${wine.vintage})' : wine.name,
          customValues: modeBlanc ? wine.metrics.toWhiteValues() : wine.metrics.toRedValues(),
          color: _palette[i % _palette.length],
        ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 270,
            child: WineTasteRadarChart(
              datasets: datasets,
              customAxisLabels: modeBlanc
                  ? MenuWineRadarMetrics.whiteAxisLabelsLocalized(isFr)
                  : MenuWineRadarMetrics.redAxisLabelsLocalized(isFr),
              size: 260,
              showLabels: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              modeBlanc
                  ? (trSi(isFr, 'Axes Blancs : Minéralité • Vivacité • Fleurs • Beurré & Rondeur • Boisé • Douceur • Puissance', 'White Axes: Minerality • Crispness • Floral • Buttery & Round • Oak • Sweetness • Body'))
                  : (trSi(isFr, 'Axes Rouges : Tannins • Puissance • Acidité • Baies • Élevage • Minéralité • Persistance', 'Red Axes: Tannins • Body • Acidity • Berries • Oak Aging • Minerality • Finish')),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 14),
          for (final (idx, wine) in vins.indexed) _ficheDuVin(wine, _palette[idx % _palette.length], isFr, isDark),
        ],
      ),
    );
  }

  Widget _ficheDuVin(MenuWine wine, Color color, bool isFr, bool isDark) {
    var priceLabel = '';
    if (wine.bottlePrice != null && wine.bottlePrice! > 0) {
      priceLabel = '${wine.formaterPrix(wine.bottlePrice!)} / ${wine.uniteDuPrix()}';
    }
    if (wine.glassPrices.isNotEmpty) {
      final g = wine.glassPrices.first;
      final gStr = '${wine.formaterPrix(g.price)} (${g.format})';
      priceLabel = priceLabel.isNotEmpty ? '$priceLabel • $gStr' : gStr;
    }
    final details = [
      if (wine.producer.trim().isNotEmpty) wine.producer.trim(),
      '${wine.vintage ?? trSi(isFr, 'NM', 'NV')}',
      if ((wine.region ?? '').trim().isNotEmpty) wine.region!.trim(),
    ].join(' • ');
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
          // La couleur du vin sur le radar.
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                // Sa couleur de vin : blanc, rosé, bulles, moelleux, muté.
                WineTypeBadge(type: wine.wineType),
                const SizedBox(height: 3),
                Text(details, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (wine.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      wine.tags.map((t) => '#$t').join(' '),
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (priceLabel.isNotEmpty) Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                    style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
