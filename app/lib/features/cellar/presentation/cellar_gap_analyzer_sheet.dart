import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../domain/bottle.dart';
import '../domain/cellar_gap_engine.dart';

class CellarGapAnalyzerSheet extends ConsumerWidget {
  final List<Bottle>? preloadedBottles;

  const CellarGapAnalyzerSheet({super.key, this.preloadedBottles});

  static Future<void> show(BuildContext context, {List<Bottle>? bottles}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CellarGapAnalyzerSheet(preloadedBottles: bottles),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCellarId = ref.watch(currentCellarIdProvider);
    final bottlesAsync = ref.watch(bottlesProvider(currentCellarId));
    final bottles = preloadedBottles ?? bottlesAsync.value ?? [];
    final analysis = CellarGapEngine.analyzeCellar(bottles);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF140F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.auto_graph_rounded, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cellar Gap Filler',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Analyse des déséquilibres & Opportunités (${analysis.totalBottles} bouteilles)',
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Répartition des Couleurs
                _buildSectionTitle('Répartition des Styles en Cave', Icons.pie_chart_outline_rounded),
                const SizedBox(height: 10),
                _buildColorDistributionBar(analysis),
                const SizedBox(height: 20),

                // 2. Horizon de Dégustation / Maturité
                _buildSectionTitle('Maturité & Horizons de Garde', Icons.hourglass_empty_rounded),
                const SizedBox(height: 10),
                _buildMaturityCard(analysis),
                const SizedBox(height: 24),

                // 3. Diagnostics & Alertes
                _buildSectionTitle('Diagnostics Sommelier', Icons.health_and_safety_outlined),
                const SizedBox(height: 10),
                ...analysis.gaps.map(_buildGapCard),
                const SizedBox(height: 24),

                // 4. Wishlist d'Achats Recommandée
                if (analysis.shoppingWishlist.isNotEmpty) ...[
                  _buildSectionTitle('Wishlist d\'Achats Idéale pour Rééquilibrer', Icons.shopping_bag_outlined),
                  const SizedBox(height: 10),
                  _buildShoppingWishlist(analysis.shoppingWishlist),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildColorDistributionBar(CellarGapAnalysis a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (a.redRatio > 0)
                    Expanded(
                      flex: (a.redRatio * 100).round(),
                      child: Container(color: const Color(0xFF8B1E3F)),
                    ),
                  if (a.whiteRatio > 0)
                    Expanded(
                      flex: (a.whiteRatio * 100).round(),
                      child: Container(color: const Color(0xFFE5C07B)),
                    ),
                  if (a.sparklingRatio > 0)
                    Expanded(
                      flex: (a.sparklingRatio * 100).round(),
                      child: Container(color: const Color(0xFF61AFEF)),
                    ),
                  if (a.roseRatio > 0)
                    Expanded(
                      flex: (a.roseRatio * 100).round(),
                      child: Container(color: const Color(0xFFE06C75)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildColorLegend('Rouges', '${(a.redRatio * 100).toStringAsFixed(0)}%', const Color(0xFF8B1E3F)),
              _buildColorLegend('Blancs', '${(a.whiteRatio * 100).toStringAsFixed(0)}%', const Color(0xFFE5C07B)),
              _buildColorLegend('Bulles', '${(a.sparklingRatio * 100).toStringAsFixed(0)}%', const Color(0xFF61AFEF)),
              _buildColorLegend('Rosés', '${(a.roseRatio * 100).toStringAsFixed(0)}%', const Color(0xFFE06C75)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorLegend(String label, String pct, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label $pct', style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildMaturityCard(CellarGapAnalysis a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMaturityColumn('Prêts à boire 🍷', '${a.readyToDrinkCount}', Colors.greenAccent),
          Container(width: 1, height: 36, color: Colors.white12),
          _buildMaturityColumn('En garde ⏳', '${a.inAgingCount}', Colors.lightBlueAccent),
          Container(width: 1, height: 36, color: Colors.white12),
          _buildMaturityColumn('À boire vite ⚠️', '${a.pastPeakCount}', a.pastPeakCount > 0 ? Colors.orangeAccent : Colors.white38),
        ],
      ),
    );
  }

  Widget _buildMaturityColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildGapCard(CellarGapCategory gap) {
    Color statusColor;
    IconData statusIcon;

    switch (gap.status) {
      case 'critical':
        statusColor = Colors.redAccent;
        statusIcon = Icons.error_outline_rounded;
        break;
      case 'warning':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'balanced':
      default:
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  gap.title,
                  style: TextStyle(color: statusColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(gap.diagnosis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(gap.sommelierAdvice, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
          if (gap.recommendedAppellations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: gap.recommendedAppellations.map((app) {
                return Chip(
                  backgroundColor: const Color(0xFF2B1A2C),
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
                  label: Text(app, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShoppingWishlist(List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B182B), Color(0xFF191020)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFFD4AF37), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
