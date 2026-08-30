import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/ai_cost_tracker_service.dart';
import '../domain/ai_cost_event.dart';

class AiCostEstimatorScreen extends ConsumerStatefulWidget {
  const AiCostEstimatorScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiCostEstimatorScreen()),
    );
  }

  @override
  ConsumerState<AiCostEstimatorScreen> createState() => _AiCostEstimatorScreenState();
}

class _AiCostEstimatorScreenState extends ConsumerState<AiCostEstimatorScreen> with SingleTickerProviderStateMixin {
  late TabController _periodTabCtrl;
  String _selectedCurrency = 'EUR'; // 'EUR' or 'USD'

  @override
  void initState() {
    super.initState();
    _periodTabCtrl = TabController(length: 5, vsync: this, initialIndex: 2); // default 'Mois'
  }

  @override
  void dispose() {
    _periodTabCtrl.dispose();
    super.dispose();
  }

  String _formatCost(double eur, double usd) {
    if (_selectedCurrency == 'USD') {
      if (usd < 0.01 && usd > 0) {
        return '\$${usd.toStringAsFixed(4)}';
      }
      return '\$${usd.toStringAsFixed(3)}';
    } else {
      if (eur < 0.01 && eur > 0) {
        return '${eur.toStringAsFixed(4)} €';
      }
      return '${eur.toStringAsFixed(3)} €';
    }
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###', 'fr_FR').format(number);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(aiCostStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimation Coûts IA'),
        actions: [
          // Currency Toggle (€ / $)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DropdownMenuItem(value: 'USD', child: Text('USD (\$)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(aiCostStatsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _periodTabCtrl,
          isScrollable: true,
          labelColor: const Color(0xFFD4AF37),
          indicatorColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Aujourd\'hui 📅'),
            Tab(text: '7 Jours 📆'),
            Tab(text: '30 Jours 🗓️'),
            Tab(text: 'Année 2026 📅'),
            Tab(text: 'Tout (All-Time) ♾️'),
          ],
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (stats) {
          return TabBarView(
            controller: _periodTabCtrl,
            children: [
              _buildPeriodView(stats.daily, 'Aujourd\'hui', stats, isDark),
              _buildPeriodView(stats.weekly, '7 derniers jours', stats, isDark),
              _buildPeriodView(stats.monthly, '30 derniers jours', stats, isDark),
              _buildPeriodView(stats.yearly, 'Année 2026', stats, isDark),
              _buildPeriodView(stats.allTime, 'Historique Total', stats, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodView(AiPeriodSummary summary, String periodLabel, AiCostStats fullStats, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. HERO KPI CARDS
        _buildHeroCostCard(summary, periodLabel, isDark),
        const SizedBox(height: 16),

        // 2. TOKEN & REQUEST METRICS GRID
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.bolt,
                iconColor: Colors.amber,
                title: 'Requêtes IA',
                value: '${summary.requestCount}',
                subtitle: '${summary.searchQueriesCount} avec Google Search',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.token_outlined,
                iconColor: Colors.cyan,
                title: 'Tokens Totaux',
                value: _formatNumber(summary.totalTokens),
                subtitle: 'In: ${_formatNumber(summary.promptTokens)} · Out: ${_formatNumber(summary.candidatesTokens)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. MULTI-PERIOD COMPARISON CARD
        _buildComparisonTable(fullStats, isDark),
        const SizedBox(height: 16),

        // 4. BREAKDOWN BY MODEL (Gemini 3.7 Flash, 2.5 Flash, etc.)
        if (fullStats.byModel.isNotEmpty) ...[
          _buildSectionHeader('🧠 Répartition par Modèle Gemini', Icons.model_training),
          const SizedBox(height: 8),
          _buildModelBreakdownCard(fullStats.byModel, isDark),
          const SizedBox(height: 16),
        ],

        // 5. BREAKDOWN BY FEATURE (Scan vision, Chat, Enrichment)
        if (fullStats.byFeature.isNotEmpty) ...[
          _buildSectionHeader('🎯 Répartition par Fonctionnalité', Icons.category),
          const SizedBox(height: 8),
          _buildFeatureBreakdownCard(fullStats.byFeature, isDark),
          const SizedBox(height: 16),
        ],

        // 6. OFFICIAL PRICING REFERENCE
        _buildPricingReferenceCard(isDark),
        const SizedBox(height: 16),

        // 7. RECENT REQUESTS AUDIT LOG
        _buildSectionHeader('⏱️ Dernières Requêtes Traitées', Icons.history),
        const SizedBox(height: 8),
        _buildRecentEventsList(fullStats.recentEvents, isDark),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHeroCostCard(AiPeriodSummary summary, String periodLabel, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E0814), Color(0xFF16060D), Color(0xFF0F0B13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1E3F).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.analytics, size: 14, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 4),
                    Text(
                      periodLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text('Google Gemini API', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Coût IA Estimé',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatCost(summary.costEur, summary.costUsd),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedCurrency == 'EUR'
                    ? '(\$${summary.costUsd.toStringAsFixed(4)} USD)'
                    : '(${summary.costEur.toStringAsFixed(4)} €)',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Tokens Entrée', _formatNumber(summary.promptTokens)),
              _buildMiniMetric('Tokens Sortie', _formatNumber(summary.candidatesTokens)),
              _buildMiniMetric('Appels IA', '${summary.requestCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(AiCostStats stats, bool isDark) {
    final periods = [
      ('Jour', stats.daily),
      ('7 Jours', stats.weekly),
      ('30 Jours', stats.monthly),
      ('Année', stats.yearly),
      ('Total', stats.allTime),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Synthèse Multi-Périodes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.4),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.4),
                3: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  children: const [
                    Padding(padding: EdgeInsets.all(6), child: Text('Horizon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6), child: Text('Appels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6), child: Text('Tokens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6), child: Text('Coût', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFD4AF37)))),
                  ],
                ),
                ...periods.map((p) {
                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(6), child: Text(p.$1, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                      Padding(padding: const EdgeInsets.all(6), child: Text('${p.$2.requestCount}', style: const TextStyle(fontSize: 11.5))),
                      Padding(padding: const EdgeInsets.all(6), child: Text(_formatNumber(p.$2.totalTokens), style: const TextStyle(fontSize: 11))),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          _formatCost(p.$2.costEur, p.$2.costUsd),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelBreakdownCard(Map<String, AiPeriodSummary> byModel, bool isDark) {
    final totalCost = byModel.values.fold(0.0, (sum, s) => sum + (_selectedCurrency == 'EUR' ? s.costEur : s.costUsd));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: byModel.entries.map((entry) {
            final model = entry.key;
            final summary = entry.value;
            final cost = _selectedCurrency == 'EUR' ? summary.costEur : summary.costUsd;
            final pct = totalCost > 0 ? (cost / totalCost) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(model, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      Text(_formatCost(summary.costEur, summary.costUsd), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${summary.requestCount} requêtes · ${_formatNumber(summary.totalTokens)} tokens', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      color: const Color(0xFF8B1E3F),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeatureBreakdownCard(Map<String, AiPeriodSummary> byFeature, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: byFeature.entries.map((entry) {
            final name = _featureName(entry.key);
            final summary = entry.value;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_featureIcon(entry.key), color: const Color(0xFF8B1E3F), size: 18),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('${summary.requestCount} appels · ${_formatNumber(summary.totalTokens)} tokens', style: const TextStyle(fontSize: 11)),
              trailing: Text(
                _formatCost(summary.costEur, summary.costUsd),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPricingReferenceCard(bool isDark) {
    return const ExpansionTile(
      leading: Icon(Icons.price_check, color: Color(0xFFD4AF37)),
      title: Text('Barème & Tarifs Officiels Google Gemini', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
      subtitle: Text('Tarification officielle par million de tokens', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PricingRow('Gemini Flash (3.7 / 2.5 / latest)', '\$0.075 / 1M', '\$0.30 / 1M', '0.070 € / 0.28 €'),
              Divider(height: 12),
              _PricingRow('Gemini Flash-Lite (3.1 / 2.5)', '\$0.0375 / 1M', '\$0.15 / 1M', '0.035 € / 0.14 €'),
              Divider(height: 12),
              _PricingRow('Gemini Pro (1.5 / 2.0 / latest)', '\$1.25 / 1M', '\$5.00 / 1M', '1.15 € / 4.60 €'),
              Divider(height: 12),
              _PricingRow('Google Search Grounding', '\$0.035 / recherche', '-', '0.032 € / req'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEventsList(List<AiCostEvent> events, bool isDark) {
    if (events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Aucune requête IA enregistrée pour le moment.')),
        ),
      );
    }

    return Column(
      children: events.take(15).map((event) {
        final timeStr = DateFormat('dd/MM HH:mm').format(event.timestamp);
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            dense: true,
            leading: Text(
              _featureEmoji(event.feature),
              style: const TextStyle(fontSize: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    event.model,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatCost(event.costEur, event.costUsd),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), fontSize: 12),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(width: 8),
                Text('${event.promptTokens} in / ${event.candidatesTokens} out', style: const TextStyle(fontSize: 10)),
                if (event.isSearchGrounded) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.travel_explore, size: 11, color: Colors.blue),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _featureName(String f) {
    switch (f) {
      case 'scan_vision':
        return 'Vision & Reconnaissance Étiquette';
      case 'scan_enrichment':
        return 'Enrichissement Oenologique';
      case 'chat_sommelier':
        return 'Chat Sommelier IA';
      case 'offline_enrichment':
        return 'Synchronisation Hors-Ligne';
      default:
        return 'Traitement Général';
    }
  }

  IconData _featureIcon(String f) {
    switch (f) {
      case 'scan_vision':
        return Icons.camera_alt;
      case 'scan_enrichment':
        return Icons.auto_awesome;
      case 'chat_sommelier':
        return Icons.chat_bubble_outline;
      case 'offline_enrichment':
        return Icons.sync;
      default:
        return Icons.extension;
    }
  }

  String _featureEmoji(String f) {
    switch (f) {
      case 'scan_vision':
        return '📷';
      case 'scan_enrichment':
        return '🍇';
      case 'chat_sommelier':
        return '🍷';
      case 'offline_enrichment':
        return '⚡';
      default:
        return '✨';
    }
  }
}

class _PricingRow extends StatelessWidget {
  final String tier;
  final String inUsd;
  final String outUsd;
  final String eur;

  const _PricingRow(this.tier, this.inUsd, this.outUsd, this.eur);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tier, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
        const SizedBox(height: 2),
        Text('Entrée: $inUsd · Sortie: $outUsd  ($eur)', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
      ],
    );
  }
}
