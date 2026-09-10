import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/utils/responsive_layout.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../../../shared/widgets/drinking_window_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../../scratchcard/presentation/scratch_map_canvas.dart';
import '../data/stats_repository.dart';
import '../domain/cellar_stats.dart';

final statsDisplayCurrencyProvider = StateProvider<String>((ref) => 'EUR');
final statsMapModeProvider = StateProvider<String>((ref) => 'france');

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _touchedTypeIndex = -1;
  int _touchedRegionIndex = -1;

  static const List<Color> _chartColors = [
    Color(0xFF722F37), // Bordeaux Wine
    Color(0xFFD4AF37), // Gold Chardonnay
    Color(0xFFE57373), // Coral Rosé
    Color(0xFF38BDF8), // Sparkling Cyan
    Color(0xFFF59E0B), // Dessert Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedCellarId = ref.watch(statsSelectedCellarIdProvider);
    final bottlesAsync = ref.watch(statsBottlesProvider);
    final userCellarsAsync = ref.watch(userCellarsProvider);
    final userCellars = userCellarsAsync.valueOrNull ?? [];
    final displayCurrency = ref.watch(statsDisplayCurrencyProvider);
    final mapMode = ref.watch(statsMapModeProvider);
    final l10n = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.statsTitle ?? (isFr ? 'Statistiques de la Cave' : 'Cellar Statistics')),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: displayCurrency,
                isDense: true,
                items: CurrencyHelper.supportedCurrencies.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.code,
                    child: Text('${c.code} (${c.symbol})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(statsDisplayCurrencyProvider.notifier).state = val;
                  }
                },
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.wine_bar, size: 18, color: Color(0xFF8B1E3F)),
                const SizedBox(width: 8),
                Text(
                  isFr ? 'Périmètre :' : 'Scope :',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCellarId ?? 'overall',
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        items: [
                          DropdownMenuItem(
                            value: 'overall',
                            child: Row(
                              children: [
                                const Icon(Icons.public, size: 16, color: Color(0xFF8B1E3F)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isFr ? 'Toutes mes caves (Global)' : 'All my cellars (Global / Overall)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...userCellars.map((c) {
                            final cMap = c['cellars'] as Map<String, dynamic>?;
                            final id = cMap?['id']?.toString() ?? c['cellar_id']?.toString() ?? '';
                            final name = cMap?['name']?.toString() ?? (isFr ? 'Cave $id' : 'Cellar $id');
                            return DropdownMenuItem(
                              value: id,
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 12.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(statsSelectedCellarIdProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: bottlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  isFr ? 'Erreur lors du chargement des statistiques : $err' : 'Error loading statistics: $err',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (bottles) {
          final stats = StatsRepository().computeStats(bottles, displayCurrency: displayCurrency);

          if (bottles.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.bar_chart,
                title: l10n?.statsTitle ?? (isFr ? 'Statistiques de la Cave' : 'Cellar Statistics'),
                subtitle: l10n?.emptyCellarSub ??
                    (isFr
                        ? 'Ajoutez votre première bouteille pour débloquer l\'estimation en temps réel, l\'apogée et les statistiques.'
                        : 'Add your first bottle to unlock real-time valuation, drinking windows, and cellar analytics.'),
                action: FilledButton.icon(
                  onPressed: () => context.push('/scan'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l10n?.actionAddBottle ?? (isFr ? 'Ajouter une bouteille' : 'Add a bottle')),
                ),
              ),
            );
          }

          final activeBottles = bottles.where((b) => b.isInCellar).toList();
          final drinkSoonBottles = activeBottles
              .where((b) => b.wine?.windowStatus == DrinkWindowStatus.drinkSoon)
              .toList();

          final mapRegions = _buildMapRegions(mapMode, bottles, isFr);

          final isLarge = Responsive.isTabletOrDesktop(context);

          final content = isLarge
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Top Overview: Valuation Card + KPI Grid in 2 Columns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildValuationCard(context, theme, stats, displayCurrency, l10n, isFr),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: _buildKpiGrid(context, theme, stats, l10n, isFr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sommelier Insight
                    _buildSommelierInsightCard(context, theme, stats, isDark, isFr),
                    const SizedBox(height: 20),

                    // Embedded Terroirs Map Full Width
                    _buildScratchMapCard(context, theme, isDark, mapMode, mapRegions, isFr),
                    const SizedBox(height: 20),

                    // Charts Row 1: Wine Colors + Drinking Window
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: stats.byType.isNotEmpty
                              ? _buildWineTypePieChartCard(theme, isDark, stats, isFr)
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: stats.byWindowStatus.isNotEmpty
                              ? _buildDrinkingWindowCard(theme, isDark, stats, isFr)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Charts Row 2: Regions + Vintages
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: stats.byRegion.isNotEmpty
                              ? _buildRegionPieChartCard(theme, isDark, stats, isFr)
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: stats.byVintage.isNotEmpty
                              ? _buildVintageHistogramCard(theme, isDark, stats, isFr)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Charts Row 3: Price Tiers + Urgent Drink List
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: stats.byPriceRange.isNotEmpty
                              ? _buildPriceTierCard(theme, isDark, stats, isFr)
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: drinkSoonBottles.isNotEmpty
                              ? Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.alarm, color: Colors.orange),
                                            const SizedBox(width: 8),
                                            Text(
                                              isFr
                                                  ? 'Prêtes à boire rapidement (${drinkSoonBottles.length})'
                                                  : 'Ready to drink soon (${drinkSoonBottles.length})',
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...drinkSoonBottles.take(6).map((b) {
                                          final wine = b.wine;
                                          return ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(wine?.name ?? (isFr ? 'Vin' : 'Wine'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text('${wine?.producer ?? ""} • ${isFr ? "Qté" : "Qty"}: ${b.quantity}'),
                                            trailing: wine != null ? DrinkingWindowBadge(status: wine.windowStatus) : null,
                                            onTap: () => context.push('/cellar/bottle/${b.id}'),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Valuation & Financial Overview Card
                    _buildValuationCard(context, theme, stats, displayCurrency, l10n, isFr),
                    const SizedBox(height: 16),

                    // 2. EMBEDDED INTERACTIVE SCRATCH MAP
                    _buildScratchMapCard(context, theme, isDark, mapMode, mapRegions, isFr),
                    const SizedBox(height: 16),

                    // 3. Sommelier KPI Counters Grid
                    _buildKpiGrid(context, theme, stats, l10n, isFr),
                    const SizedBox(height: 20),

                    // 4. Sommelier Recommendation & Insight Card
                    _buildSommelierInsightCard(context, theme, stats, isDark, isFr),
                    const SizedBox(height: 20),

                    // 5. Pie Chart: Wine Colors & Types
                    if (stats.byType.isNotEmpty) ...[
                      _buildWineTypePieChartCard(theme, isDark, stats, isFr),
                      const SizedBox(height: 20),
                    ],

                    // 6. Pie Chart: Wine Terroirs & Regions
                    if (stats.byRegion.isNotEmpty) ...[
                      _buildRegionPieChartCard(theme, isDark, stats, isFr),
                      const SizedBox(height: 20),
                    ],

                    // 7. Bar Chart: Vintages Histogram (Millésimes)
                    if (stats.byVintage.isNotEmpty) ...[
                      _buildVintageHistogramCard(theme, isDark, stats, isFr),
                      const SizedBox(height: 20),
                    ],

                    // 8. Bar Chart: Drinking Window Maturity
                    if (stats.byWindowStatus.isNotEmpty) ...[
                      _buildDrinkingWindowCard(theme, isDark, stats, isFr),
                      const SizedBox(height: 20),
                    ],

                    // 9. Bar Chart: Price Tiers Histogram
                    if (stats.byPriceRange.isNotEmpty) ...[
                      _buildPriceTierCard(theme, isDark, stats, isFr),
                      const SizedBox(height: 20),
                    ],

                    // 10. Drink Soon Urgent List
                    if (drinkSoonBottles.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.alarm, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            isFr
                                ? 'Prêtes à boire rapidement (${drinkSoonBottles.length})'
                                : 'Ready to drink soon (${drinkSoonBottles.length})',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...drinkSoonBottles.map((b) {
                        final wine = b.wine;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(wine?.name ?? (isFr ? 'Vin' : 'Wine'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${wine?.producer ?? ""} • ${isFr ? "Qté" : "Qty"}: ${b.quantity}'),
                            trailing: wine != null ? DrinkingWindowBadge(status: wine.windowStatus) : null,
                            onTap: () => context.push('/cellar/bottle/${b.id}'),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ],
                );

          return ResponsiveContentWrapper(
            maxWidth: 1350,
            child: content,
          );
        },
      ),
    );
  }

  // ================= 1. VALUATION CARD =================
  Widget _buildValuationCard(BuildContext context, ThemeData theme, CellarStats stats, String currency, AppLocalizations? l10n, bool isFr) {
    final isGain = stats.unrealizedGainAmount >= 0;
    final gainColor = isGain ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n?.statsTotalValue ?? (isFr ? "Valeur Totale Estimée" : "Total Estimated Value")} ($currency)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (stats.unrealizedGainAmount != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: gainColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gainColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${isGain ? "+" : ""}${stats.unrealizedGainPct.toStringAsFixed(1)}% (${isGain ? "+" : ""}${CurrencyHelper.formatPrice(stats.unrealizedGainAmount, currency: currency)})',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gainColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyHelper.formatPrice(stats.totalEstimatedMarketValue, currency: currency),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            if (stats.totalPaidValue > 0)
              Text(
                '${l10n?.bottleDetailPurchasePrice ?? (isFr ? "Coût d'achat total" : "Total purchase cost")}: ${CurrencyHelper.formatPrice(stats.totalPaidValue, currency: currency)} (${stats.bottlesWithPriceCount}/${stats.totalBottles} ${isFr ? "bouteilles renseignées" : "bottles specified"})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                isFr
                    ? 'Prix d\'achat non renseigné pour vos bouteilles'
                    : 'Purchase price not specified for your bottles',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (stats.paidByCurrency.length > 1) ...[
              const SizedBox(height: 12),
              const Divider(height: 12),
              const SizedBox(height: 4),
              Text(
                isFr ? 'Devises d\'achat déclarées :' : 'Declared purchase currencies:',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: stats.paidByCurrency.entries.map((e) {
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    label: Text(
                      CurrencyHelper.formatPrice(e.value, currency: e.key),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================= 2. EMBEDDED SCRATCH MAP CARD =================
  Widget _buildScratchMapCard(BuildContext context, ThemeData theme, bool isDark, String mapMode, List<MapRegionData> regions, bool isFr) {
    final unlockedCount = regions.where((r) => r.isUnlocked).length;
    final totalCount = regions.length;
    final pct = totalCount > 0 ? (unlockedCount / totalCount * 100).round() : 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1B1622) : const Color(0xFFFAF6EE),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.public, color: Color(0xFFD4AF37), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFr ? 'Carte des Terroirs & Découvertes' : 'Terroirs & Discoveries Map',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        isFr
                            ? '$unlockedCount / $totalCount terroirs explorés ($pct%)'
                            : '$unlockedCount / $totalCount terroirs explored ($pct%)',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Mode Toggle
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'france', label: Text('🇫🇷', style: TextStyle(fontSize: 13))),
                    ButtonSegment(value: 'world', label: Text('🌍', style: TextStyle(fontSize: 13))),
                  ],
                  selected: {mapMode},
                  onSelectionChanged: (val) {
                    ref.read(statsMapModeProvider.notifier).state = val.first;
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: isFr ? 'Plein écran' : 'Fullscreen',
                  icon: const Icon(Icons.fullscreen, color: Color(0xFFD4AF37)),
                  onPressed: () => context.push('/scratchcard'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 280,
            child: ScratchMapCanvas(
              mapMode: mapMode,
              regions: regions,
              onRegionTapped: (region) => _showRegionModal(context, region, isFr),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 3. KPI COUNTERS GRID =================
  Widget _buildKpiGrid(BuildContext context, ThemeData theme, CellarStats stats, AppLocalizations? l10n, bool isFr) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatKpiCard(
                title: l10n?.statsTotalBottles ?? (isFr ? 'Total Bouteilles' : 'Total Bottles'),
                value: '${stats.totalBottles}',
                icon: Icons.wine_bar,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatKpiCard(
                title: l10n?.statsBottlesEnjoyed ?? (isFr ? 'Dégustées' : 'Enjoyed'),
                value: '${stats.totalConsumed}',
                icon: Icons.check_circle_outline,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatKpiCard(
                title: l10n?.maturityDrinkSoon ?? (isFr ? 'À boire vite' : 'Drink Soon'),
                value: '${stats.drinkSoonCount}',
                icon: Icons.alarm,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatKpiCard(
                title: l10n?.maturityAtPeak ?? (isFr ? 'À l\'apogée' : 'At Peak'),
                value: '${stats.atPeakCount}',
                icon: Icons.auto_awesome,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatKpiCard(
                title: isFr ? 'Prix moyen / btl' : 'Avg price / btl',
                value: CurrencyHelper.formatPrice(stats.averageBottlePrice, decimals: 0),
                icon: Icons.euro,
                color: const Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatKpiCard(
                title: isFr ? 'Doyenne de la cave' : 'Oldest vintage',
                value: stats.oldestVintage != null ? '${stats.oldestVintage}' : 'N/A',
                icon: Icons.history_edu,
                color: const Color(0xFF9333EA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= 4. SOMMELIER INSIGHT CARD =================
  Widget _buildSommelierInsightCard(BuildContext context, ThemeData theme, CellarStats stats, bool isDark, bool isFr) {
    final readyPct = stats.totalBottles > 0
        ? ((stats.atPeakCount + stats.drinkSoonCount) / stats.totalBottles * 100).round()
        : 0;

    String advice = isFr
        ? 'Votre cave est équilibrée avec un bel étalement de millésimes.'
        : 'Your cellar is well-balanced with a great spread of vintages.';
    if (stats.drinkSoonCount > 3) {
      advice = isFr
          ? 'Attention : ${stats.drinkSoonCount} bouteilles arrivent en fin d\'apogée et devraient être ouvertes prochainement.'
          : 'Warning: ${stats.drinkSoonCount} bottles are reaching the end of their peak and should be enjoyed soon.';
    } else if (readyPct < 25 && stats.totalBottles > 5) {
      advice = isFr
          ? 'Une grande majorité de vos bouteilles sont encore en phase de vieillissement. Laissez-les reposer !'
          : 'A large majority of your bottles are still aging. Let them rest!';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1E1724) : const Color(0xFFFFF8EE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, color: Color(0xFFD4AF37), size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFr ? 'Analyse & Conseil du Sommelier' : 'Sommelier Insight & Advice',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? const Color(0xFFF3E5AB) : const Color(0xFF722F37),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    advice,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                  if (stats.topRegion != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      isFr
                          ? '🏰 Terroir de prédilection : ${stats.topRegion} (${stats.byRegion[stats.topRegion]} btl)'
                          : '🏰 Favorite terroir: ${stats.topRegion} (${stats.byRegion[stats.topRegion]} btl)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 5. PIE CHART: WINE TYPES =================
  Widget _buildWineTypePieChartCard(ThemeData theme, bool isDark, CellarStats stats, bool isFr) {
    final entries = stats.byType.entries.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, size: 20, color: Color(0xFF722F37)),
                const SizedBox(width: 8),
                Text(
                  isFr ? 'Répartition par Couleur & Type de Vin' : 'Breakdown by Wine Color & Type',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedTypeIndex = -1;
                              return;
                            }
                            _touchedTypeIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: entries.asMap().entries.map((e) {
                        final idx = e.key;
                        final type = e.value.key;
                        final count = e.value.value;
                        final isTouched = idx == _touchedTypeIndex;
                        final color = WineTypeBadge.getColor(type);
                        return PieChartSectionData(
                          color: color,
                          value: count.toDouble(),
                          title: count >= 2 ? '$count' : '',
                          radius: isTouched ? 34.0 : 28.0,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: entries.asMap().entries.map((e) {
                      final type = e.value.key;
                      final count = e.value.value;
                      final color = WineTypeBadge.getColor(type);
                      final pct = stats.totalBottles > 0 ? (count / stats.totalBottles * 100).toStringAsFixed(0) : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: WineTypeBadge(type: type)),
                            Text('$count btl ($pct%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= 6. PIE CHART: REGIONS =================
  Widget _buildRegionPieChartCard(ThemeData theme, bool isDark, CellarStats stats, bool isFr) {
    final entries = stats.byRegion.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(6).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terrain_outlined, size: 20, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  isFr ? 'Répartition par Grand Vignoble' : 'Breakdown by Wine Region',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedRegionIndex = -1;
                              return;
                            }
                            _touchedRegionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: topEntries.asMap().entries.map((e) {
                        final idx = e.key;
                        final count = e.value.value;
                        final isTouched = idx == _touchedRegionIndex;
                        return PieChartSectionData(
                          color: _chartColors[(idx + 2) % _chartColors.length],
                          value: count.toDouble(),
                          title: count >= 2 ? '$count' : '',
                          radius: isTouched ? 34.0 : 28.0,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: topEntries.asMap().entries.map((e) {
                      final idx = e.key;
                      final region = e.value.key;
                      final count = e.value.value;
                      final pct = stats.totalBottles > 0 ? (count / stats.totalBottles * 100).toStringAsFixed(0) : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: _chartColors[(idx + 2) % _chartColors.length], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                region,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('$count ($pct%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= 7. BAR CHART: VINTAGES HISTOGRAM =================
  Widget _buildVintageHistogramCard(ThemeData theme, bool isDark, CellarStats stats, bool isFr) {
    final sortedVintages = stats.byVintage.keys.toList()..sort();
    final maxCount = stats.byVintage.values.fold<int>(0, (prev, elem) => elem > prev ? elem : prev);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 20, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Text(
                  isFr ? 'Histogramme des Millésimes' : 'Vintage Distribution',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxCount + 2).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final vintage = sortedVintages[group.x.toInt()];
                        return BarTooltipItem(
                          '$vintage\n${rod.toY.round()} btl',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 26, interval: 2),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < sortedVintages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${sortedVintages[idx]}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedVintages.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final count = stats.byVintage[entry.value] ?? 0;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: const Color(0xFFD4AF37),
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 8. BAR CHART: DRINKING WINDOW MATURITY =================
  Widget _buildDrinkingWindowCard(ThemeData theme, bool isDark, CellarStats stats, bool isFr) {
    final statusData = [
      {'label': isFr ? 'En garde & Jeune ⏳' : 'Aging & Young ⏳', 'count': (stats.byWindowStatus[DrinkWindowStatus.aging] ?? 0) + (stats.byWindowStatus[DrinkWindowStatus.tooYoung] ?? 0), 'color': const Color(0xFF38BDF8)},
      {'label': isFr ? 'À l\'apogée ✨' : 'At Peak ✨', 'count': stats.byWindowStatus[DrinkWindowStatus.inPeak] ?? 0, 'color': const Color(0xFF10B981)},
      {'label': isFr ? 'À boire rapidement ⏰' : 'Drink Soon ⏰', 'count': stats.byWindowStatus[DrinkWindowStatus.drinkSoon] ?? 0, 'color': const Color(0xFFF59E0B)},
      {'label': isFr ? 'Passé l\'apogée ⚠️' : 'Past Peak ⚠️', 'count': stats.byWindowStatus[DrinkWindowStatus.pastPeak] ?? 0, 'color': const Color(0xFFE11D48)},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hourglass_bottom, size: 20, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                Text(
                  isFr ? 'Maturité & Fenêtres d\'Apogée' : 'Maturity & Drinking Windows',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...statusData.map((item) {
              final label = item['label'] as String;
              final count = item['count'] as int;
              final color = item['color'] as Color;
              final pct = stats.totalBottles > 0 ? (count / stats.totalBottles) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('$count btl (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ================= 9. BAR CHART: PRICE TIERS =================
  Widget _buildPriceTierCard(ThemeData theme, bool isDark, CellarStats stats, bool isFr) {
    final entries = stats.byPriceRange.entries.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sell_outlined, size: 20, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  isFr ? 'Gammes de Valeur / Prix' : 'Value & Price Tiers',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              final tier = entry.key;
              final count = entry.value;
              final pct = stats.totalBottles > 0 ? (count / stats.totalBottles) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tier, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                        Text('$count btl', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ================= REGION EXTRACTION & MODAL =================
  List<MapRegionData> _buildMapRegions(String mode, List<Bottle> bottles, bool isFr) {
    if (mode == 'france') {
      final bdxKeys = ['bordeaux', 'margaux', 'pauillac', 'pomerol', 'saint-émilion', 'saint-emilion', 'saint-julien', 'pessac', 'grave', 'médoc', 'medoc', 'sauternes'];
      final bouKeys = ['bourgogne', 'burgundy', 'chablis', 'meursault', 'beaune', 'nuits', 'vosne', 'pommard', 'volnay', 'gevrey', 'mâcon'];
      final beauKeys = ['beaujolais', 'morgon', 'fleurie', 'moulin-à-vent', 'brouilly', 'juliénas'];
      final rhoKeys = ['rhône', 'rhone', 'châteauneuf', 'saint-joseph', 'hermitage', 'côte-rôtie', 'gigondas', 'vacqueyras', 'cornas'];
      final chaKeys = ['champagne', 'reims', 'épernay'];
      final loiKeys = ['loire', 'sancerre', 'pouilly', 'chinon', 'vouvray', 'saumur'];
      final alsKeys = ['alsace', 'riesling', 'gewurztraminer', 'pinot gris'];
      final juraKeys = ['jura', 'savoie', 'arbois', 'vin jaune'];
      final langKeys = ['languedoc', 'roussillon', 'pic saint-loup', 'corbières'];
      final sudOuestKeys = ['sud-ouest', 'sud ouest', 'cahors', 'madiran', 'jurançon'];
      final proKeys = ['provence', 'bandol', 'cassis'];
      final corKeys = ['corse', 'corsica', 'patrimonio', 'ajaccio'];

      return [
        _createRegion('champagne', 'Champagne', 'France', '🇫🇷', const Rect.fromLTWH(0.44, 0.14, 0.22, 0.14), chaKeys, bottles, isFr ? 'Effervescents de craie et de renommée mondiale.' : 'World-renowned chalky sparkling wines.'),
        _createRegion('alsace', 'Alsace', 'France', '🇫🇷', const Rect.fromLTWH(0.72, 0.20, 0.16, 0.18), alsKeys, bottles, isFr ? 'Rieslings et cépages nobles sur coteaux vosgiens.' : 'Riesling and noble varietals on Vosges hillsides.'),
        _createRegion('bourgogne', 'Bourgogne', 'France', '🇫🇷', const Rect.fromLTWH(0.55, 0.31, 0.20, 0.18), bouKeys, bottles, isFr ? 'Pinot Noir et Chardonnay sur terroirs classés UNESCO.' : 'Pinot Noir and Chardonnay on UNESCO-classified terroirs.'),
        _createRegion('beaujolais', 'Beaujolais', 'France', '🇫🇷', const Rect.fromLTWH(0.57, 0.48, 0.10, 0.08), beauKeys, bottles, isFr ? 'Gamay sublime sur granites et schistes bleus.' : 'Sublime Gamay on granites and blue schist soils.'),
        _createRegion('jura_savoie', 'Jura & Savoie', 'France', '🇫🇷', const Rect.fromLTWH(0.70, 0.46, 0.12, 0.14), juraKeys, bottles, isFr ? 'Vins de voile oxydatifs et terroirs d\'altitude.' : 'Oxidative flor wines and alpine terroirs.'),
        _createRegion('loire', isFr ? 'Vallée de la Loire' : 'Loire Valley', 'France', '🇫🇷', const Rect.fromLTWH(0.24, 0.28, 0.28, 0.15), loiKeys, bottles, isFr ? 'Chenin Blanc, Sauvignon et Cabernet Franc.' : 'Chenin Blanc, Sauvignon Blanc, and Cabernet Franc.'),
        _createRegion('bordeaux', 'Bordeaux', 'France', '🇫🇷', const Rect.fromLTWH(0.18, 0.52, 0.24, 0.18), bdxKeys, bottles, isFr ? 'Grands Crus Classés de la rive gauche et rive droite.' : 'Left and right bank classified Grands Crus.'),
        _createRegion('sud_ouest', isFr ? 'Sud-Ouest' : 'South-West', 'France', '🇫🇷', const Rect.fromLTWH(0.20, 0.68, 0.22, 0.18), sudOuestKeys, bottles, isFr ? 'Cahors Tannat, Madiran et pépites authentiques.' : 'Cahors Tannat, Madiran, and authentic hidden gems.'),
        _createRegion('rhone', isFr ? 'Vallée du Rhône' : 'Rhône Valley', 'France', '🇫🇷', const Rect.fromLTWH(0.54, 0.58, 0.18, 0.20), rhoKeys, bottles, isFr ? 'Syrah septentrionale et Grenache méridional.' : 'Northern Syrah and Southern Grenache blends.'),
        _createRegion('languedoc_roussillon', 'Languedoc-Roussillon', 'France', '🇫🇷', const Rect.fromLTWH(0.40, 0.76, 0.24, 0.16), langKeys, bottles, isFr ? 'Vignoble solaire méditerranéen.' : 'Sunny Mediterranean terroirs and expressive crus.'),
        _createRegion('provence', 'Provence', 'France', '🇫🇷', const Rect.fromLTWH(0.64, 0.76, 0.20, 0.14), proKeys, bottles, isFr ? 'Rosés gastronomiques et Bandols d\'anthologie.' : 'Gastronomic rosés and legendary Bandol reds.'),
        _createRegion('corse', isFr ? 'Corse' : 'Corsica', 'France', '🇫🇷', const Rect.fromLTWH(0.86, 0.80, 0.12, 0.18), corKeys, bottles, isFr ? 'Niellucciu, Sciaccarellu et Vermentinu sur l\'Île de Beauté.' : 'Niellucciu, Sciaccarellu, and Vermentinu on the Isle of Beauty.'),
      ];
    } else {
      // International countries
      return [
        _createRegion('italy', isFr ? 'Italie' : 'Italy', isFr ? 'Italie' : 'Italy', '🇮🇹', const Rect.fromLTWH(0.50, 0.28, 0.05, 0.07), ['ital', 'barolo', 'chianti', 'brunello'], bottles, isFr ? 'Barolo, Brunello et diversité des DOCG.' : 'Barolo, Brunello, and the rich diversity of DOCG appellations.'),
        _createRegion('spain', isFr ? 'Espagne' : 'Spain', isFr ? 'Espagne' : 'Spain', '🇪🇸', const Rect.fromLTWH(0.45, 0.30, 0.05, 0.06), ['spain', 'espag', 'rioja', 'ribera', 'priorat'], bottles, isFr ? 'Tempranillo, Grenache et grands élevages.' : 'Tempranillo, Garnacha, and celebrated aged reserves.'),
        _createRegion('usa', isFr ? 'États-Unis' : 'United States', 'USA', '🇺🇸', const Rect.fromLTWH(0.12, 0.28, 0.14, 0.12), ['usa', 'calif', 'napa', 'oregon', 'sonoma'], bottles, isFr ? 'Napa Valley Cabernet et Pinots d\'Oregon.' : 'Napa Valley Cabernet and expressive Oregon Pinots.'),
        _createRegion('argentina', isFr ? 'Argentine' : 'Argentina', isFr ? 'Argentine' : 'Argentina', '🇦🇷', const Rect.fromLTWH(0.28, 0.68, 0.06, 0.14), ['argentin', 'mendoza', 'malbec'], bottles, isFr ? 'Malbec d\'altitude au pied des Andes.' : 'High-altitude Malbec grown at the foot of the Andes.'),
        _createRegion('chile', isFr ? 'Chili' : 'Chile', isFr ? 'Chili' : 'Chile', '🇨🇱', const Rect.fromLTWH(0.26, 0.66, 0.04, 0.16), ['chili', 'chile', 'carmenere', 'colchagua'], bottles, isFr ? 'Carmenère et vallées côtières pacifiques.' : 'Carmenère and cool-climate Pacific coastal valleys.'),
      ];
    }
  }

  String _normalizeDiacritics(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ÿ]'), 'y')
        .replaceAll(RegExp(r'[\-]'), ' ');
  }

  MapRegionData _createRegion(String id, String name, String country, String flag, Rect bounds, List<String> keywords, List<Bottle> bottles, String desc) {
    int owned = 0;
    int drunk = 0;
    String? topWine;

    for (final b in bottles) {
      final wine = b.wine;
      final match = keywords.any((k) {
        final normK = _normalizeDiacritics(k);
        return (wine != null && _normalizeDiacritics(wine.region).contains(normK)) ||
            (wine?.appellation != null && _normalizeDiacritics(wine!.appellation!).contains(normK)) ||
            (wine != null && _normalizeDiacritics(wine.country).contains(normK)) ||
            (wine != null && _normalizeDiacritics(wine.name).contains(normK));
      });

      if (match) {
        if (b.isConsumed) {
          drunk += b.quantity;
        } else {
          owned += b.quantity;
        }
        topWine ??= wine?.name;
      }
    }

    return MapRegionData(
      id: id,
      name: name,
      country: country,
      flag: flag,
      normalizedBounds: bounds,
      isOwned: owned > 0,
      isDrunk: drunk > 0,
      ownedCount: owned,
      drunkCount: drunk,
      topWine: topWine,
      description: desc,
    );
  }

  void _showRegionModal(BuildContext context, MapRegionData region, bool isFr) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(region.flag, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(region.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(region.country, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(region.isUnlocked ? (isFr ? 'Exploré ✨' : 'Explored ✨') : (isFr ? 'À découvrir 🔒' : 'To discover 🔒')),
                  backgroundColor: region.isUnlocked ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(region.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ModalStatTile(label: isFr ? 'En cave' : 'In cellar', value: '${region.ownedCount} btl', icon: Icons.inventory_2),
                _ModalStatTile(label: isFr ? 'Dégustées' : 'Tasted', value: '${region.drunkCount}', icon: Icons.wine_bar),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ModalStatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _StatKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
