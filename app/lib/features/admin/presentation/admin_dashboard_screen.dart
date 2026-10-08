import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_console_service.dart';
import '../data/admin_metrics_service.dart';
import '../data/admin_personnes_service.dart';
import '../domain/admin_economie.dart';
import '../domain/admin_metrics.dart';
import 'admin_console_onglets.dart';
import 'admin_onglets.dart';

/// La console d'administration : qui utilise l'app, et pour quoi faire.
///
/// **Vue d'ensemble** : des agrégats, sans identifiant ni contenu (migration 041).
/// **Personnes, Fonctionnalités, Erreurs** : le détail nominatif de la phase de test
/// (migration 044) — les testeurs ont accepté d'être visibles. Un interrupteur serveur
/// (`app_config.admin_detail_nominatif`) l'opacifie d'un geste, et le bandeau en tête de
/// chaque écran rappelle dans quel mode on regarde.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  static const _periodes = {7: '7 j', 30: '30 j', 90: '90 j', 365: '1 an'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jours = ref.watch(adminPeriodeProvider);
    final async = ref.watch(adminTableauProvider);

    return DefaultTabController(
      length: 7,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () {
              ref.invalidate(adminTableauProvider);
              ref.invalidate(adminPersonnesProvider);
              ref.invalidate(adminUsagesProvider);
              ref.invalidate(adminErreursProvider);
              ref.invalidate(adminNominatifProvider);
              ref.invalidate(adminEconomieProvider);
              ref.invalidate(adminCroissanceProvider);
              ref.invalidate(adminRetoursProvider);
              ref.invalidate(adminReglagesProvider);
              ref.invalidate(adminEconomieDetailProvider);
              ref.invalidate(adminRevenusPubProvider);
              ref.invalidate(adminErreursParJourProvider);
              ref.invalidate(adminVersionsProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Row(
                  children: [
                    for (final e in _periodes.entries) ...[
                      ChoiceChip(
                        label: Text(e.value),
                        selected: jours == e.key,
                        onSelected: (_) =>
                            ref.read(adminPeriodeProvider.notifier).state = e.key,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                // Sept onglets : le premier commence au bord, sans le retrait par défaut.
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Vue d\'ensemble'),
                  Tab(text: 'Retours'),
                  Tab(text: 'Personnes'),
                  Tab(text: 'Erreurs'),
                  Tab(text: 'Économie'),
                  Tab(text: 'Fonctionnalités'),
                  Tab(text: 'Réglages'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const BandeauModeTest(),
          Expanded(
            child: TabBarView(
              children: [
                _vueDEnsemble(ref, async, jours),
                const OngletRetours(),
                const OngletPersonnes(),
                const OngletErreurs(),
                const OngletEconomie(),
                const OngletFonctionnalites(),
                const OngletReglages(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _vueDEnsemble(WidgetRef ref, AsyncValue<TableauDeBord> async, int jours) {
    return async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Refus(erreur: e.toString()),
        data: (t) => t.estVide
            ? const _RienEncore()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminTableauProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    _Resume(resume: t.resume, jours: jours),
                    const SizedBox(height: 16),
                    const _ASurveiller(),
                    const SizedBox(height: 24),
                    _Section(
                      titre: 'Personnes actives, jour par jour',
                      detail: 'Qui a produit quelque chose : une dégustation, une '
                          'bouteille, un message. Ouvrir l\'app ne compte pas.',
                      enfant: _CourbeActifs(jours: t.jours),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      titre: 'Ce qu\'elles font',
                      detail: 'Les gestes produits chaque jour, empilés par nature.',
                      enfant: _BarresGestes(jours: t.jours),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      titre: 'Arrivées',
                      detail: 'Comptes créés par jour, anonymes compris.',
                      enfant: _CourbeNouveaux(jours: t.jours),
                    ),
                    const SizedBox(height: 24),
                    const SectionVersions(),
                    const SizedBox(height: 24),
                    _Camembert(titre: 'Répartition des gestes', parts: t.famille('geste')),
                    const SizedBox(height: 20),
                    _Camembert(titre: 'Plateformes', parts: t.famille('plateforme')),
                    const SizedBox(height: 20),
                    _Camembert(titre: 'Couleurs en cave', parts: t.famille('couleur')),
                    const SizedBox(height: 20),
                    _Barres(titre: 'Pays représentés', parts: t.famille('pays')),
                  ],
                ),
              ),
    );
  }
}

// =============================================================================
// Les grands nombres
// =============================================================================
class _Resume extends StatelessWidget {
  final ResumeDUsage resume;
  final int jours;
  const _Resume({required this.resume, required this.jours});

  @override
  Widget build(BuildContext context) {
    final r = resume;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Chiffre(valeur: '${r.actifsPeriode}', libelle: 'actifs sur $jours j', accent: true),
        _Chiffre(valeur: '${r.nouveauxPeriode}', libelle: 'arrivées'),
        _Chiffre(valeur: '${r.utilisateursTotal}', libelle: 'comptes en tout'),
        // Les comptes anonymes comptent dans la facture Supabase et ne rapportent rien
        // tant qu'ils ne sont pas convertis : c'est un chiffre à surveiller, pas à cacher.
        _Chiffre(
          valeur: '${r.anonymes}',
          libelle: 'dont anonymes (${(r.partAnonymes * 100).round()} %)',
        ),
        _Chiffre(valeur: '${r.degustationsPeriode}', libelle: 'dégustations'),
        _Chiffre(valeur: '${r.bouteillesTotal}', libelle: 'bouteilles en cave'),
        _Chiffre(valeur: '${r.cavesTotal}', libelle: 'caves'),
        _Chiffre(valeur: '${r.vinsTotal}', libelle: 'vins connus'),
      ],
    );
  }
}

class _Chiffre extends StatelessWidget {
  final String valeur;
  final String libelle;
  final bool accent;
  const _Chiffre({required this.valeur, required this.libelle, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: accent
            ? const Color(0xFF8B1E3F).withValues(alpha: 0.10)
            : t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: accent
            ? Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valeur,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: accent ? const Color(0xFF8B1E3F) : null,
              )),
          const SizedBox(height: 2),
          Text(libelle,
              style: t.textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

// =============================================================================
// À surveiller : ce qui demande un geste, et où aller le faire
// =============================================================================
class _ASurveiller extends ConsumerWidget {
  const _ASurveiller();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatRetours = ref.watch(adminRetoursProvider);
    final etatErreurs = ref.watch(adminErreursProvider);
    final etatEconomie = ref.watch(adminEconomieProvider);
    final aTraiter = etatRetours.valueOrNull?.where((r) => r.statut.ouvert).length;
    final nbErreurs = etatErreurs.valueOrNull?.where((e) => e.estErreur).fold<int>(0, (s, e) => s + e.n);
    final economie = etatEconomie.valueOrNull;
    // « … » pendant le chargement ; « — » quand la lecture a échoué (une migration pas encore
    // appliquée, par exemple) : l'onglet dit pourquoi.
    String valeur(AsyncValue<Object?> etat, String? lue) => lue ?? (etat.hasError ? '—' : '…');
    void aller(int onglet) => DefaultTabController.of(context).animateTo(onglet);
    Widget tuile(String valeur, String libelle, IconData icone, Color couleur, int onglet) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => aller(onglet),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: couleur.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icone, size: 18, color: couleur),
                  const SizedBox(height: 6),
                  Text(valeur,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: couleur,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  Text(libelle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        tuile(valeur(etatRetours, aTraiter?.toString()), 'retours à traiter', Icons.campaign_outlined,
            const Color(0xFFC62828), 1),
        const SizedBox(width: 8),
        tuile(valeur(etatErreurs, nbErreurs?.toString()), 'erreurs', Icons.error_outline, const Color(0xFFEF6C00), 3),
        const SizedBox(width: 8),
        tuile(valeur(etatEconomie, economie == null ? null : euros(economie.coutIaEur)), 'coût de l\'IA',
            Icons.payments_outlined, const Color(0xFF8B1E3F), 4),
      ],
    );
  }
}

// =============================================================================
// Habillage commun
// =============================================================================
class _Section extends StatelessWidget {
  final String titre;
  final String detail;
  final Widget enfant;
  const _Section({required this.titre, required this.detail, required this.enfant});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(detail, style: t.textTheme.bodySmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 14),
        SizedBox(height: 210, child: enfant),
      ],
    );
  }
}

String _jourCourt(DateTime d) => '${d.day}/${d.month}';

/// Un intervalle d'étiquettes qui ne se chevauchent pas, quelle que soit la période.
double _pasDesEtiquettes(int n) => n <= 10 ? 1 : (n / 6).ceilToDouble();

// =============================================================================
// Courbes
// =============================================================================
class _CourbeActifs extends StatelessWidget {
  final List<JourDUsage> jours;
  const _CourbeActifs({required this.jours});

  @override
  Widget build(BuildContext context) {
    if (jours.isEmpty) return const SizedBox.shrink();
    final maxi = jours.map((j) => j.actifs).fold<int>(1, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxi * 1.25).ceilToDouble(),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titres(jours),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < jours.length; i++)
                FlSpot(i.toDouble(), jours[i].actifs.toDouble()),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            color: const Color(0xFF8B1E3F),
            barWidth: 2.5,
            dotData: FlDotData(show: jours.length <= 31),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourbeNouveaux extends StatelessWidget {
  final List<JourDUsage> jours;
  const _CourbeNouveaux({required this.jours});

  @override
  Widget build(BuildContext context) {
    if (jours.isEmpty) return const SizedBox.shrink();
    final maxi = jours.map((j) => j.nouveaux).fold<int>(1, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: (maxi * 1.3).ceilToDouble(),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titres(jours),
        barGroups: [
          for (var i = 0; i < jours.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: jours[i].nouveaux.toDouble(),
                color: const Color(0xFF2E7D32),
                width: jours.length > 60 ? 2 : 6,
                borderRadius: BorderRadius.circular(2),
              ),
            ]),
        ],
      ),
    );
  }
}

/// Les gestes empilés : on voit d'un coup le volume ET sa composition.
class _BarresGestes extends StatelessWidget {
  final List<JourDUsage> jours;
  const _BarresGestes({required this.jours});

  static const _couleurs = {
    'Dégustations': Color(0xFF8B1E3F),
    'Bouteilles': Color(0xFFD4AF37),
    'Messages': Color(0xFF6A4C93),
    'Vins découverts': Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) {
    if (jours.isEmpty) return const SizedBox.shrink();
    final maxi = jours.map((j) => j.gestes).fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: (maxi * 1.25).ceilToDouble(),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: _titres(jours),
              barGroups: [
                for (var i = 0; i < jours.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: jours[i].gestes.toDouble(),
                      width: jours.length > 60 ? 2 : 6,
                      borderRadius: BorderRadius.circular(2),
                      rodStackItems: _pile(jours[i]),
                    ),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final e in _couleurs.entries)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 9, height: 9,
                    decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(e.key, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
              ]),
          ],
        ),
      ],
    );
  }

  List<BarChartRodStackItem> _pile(JourDUsage j) {
    final segments = <MapEntry<Color, int>>[
      MapEntry(_couleurs['Dégustations']!, j.degustations),
      MapEntry(_couleurs['Bouteilles']!, j.bouteilles),
      MapEntry(_couleurs['Messages']!, j.messages),
      MapEntry(_couleurs['Vins découverts']!, j.vinsDecouverts),
    ];
    final out = <BarChartRodStackItem>[];
    var bas = 0.0;
    for (final s in segments) {
      if (s.value == 0) continue;
      final haut = bas + s.value;
      out.add(BarChartRodStackItem(bas, haut, s.key));
      bas = haut;
    }
    return out;
  }
}

FlTitlesData _titres(List<JourDUsage> jours) => FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: null),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: _pasDesEtiquettes(jours.length),
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= jours.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_jourCourt(jours[i].jour),
                  style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
            );
          },
        ),
      ),
    );

// =============================================================================
// Camemberts et barres de répartition
// =============================================================================
class _Camembert extends StatelessWidget {
  final String titre;
  final List<Part> parts;
  const _Camembert({required this.titre, required this.parts});

  static const _palette = [
    Color(0xFF8B1E3F), Color(0xFFD4AF37), Color(0xFF6A4C93),
    Color(0xFF2E7D32), Color(0xFF1565C0), Color(0xFFE08B00),
    Color(0xFF00897B), Color(0xFFB3261E),
  ];

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();
    final total = parts.fold<int>(0, (a, p) => a + p.valeur);
    final t = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: Row(
            children: [
              SizedBox(
                width: 150,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: [
                      for (var i = 0; i < parts.length; i++)
                        PieChartSectionData(
                          value: parts[i].valeur.toDouble(),
                          color: _palette[i % _palette.length],
                          radius: 36,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < parts.length && i < 6; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10,
                                decoration: BoxDecoration(
                                    color: _palette[i % _palette.length],
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(parts[i].libelle,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            Text(
                              total == 0
                                  ? '—'
                                  : '${(parts[i].valeur * 100 / total).round()} %',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pour les répartitions à longue traîne — les pays, où un camembert deviendrait illisible.
class _Barres extends StatelessWidget {
  final String titre;
  final List<Part> parts;
  const _Barres({required this.titre, required this.parts});

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();
    final maxi = parts.first.valeur;
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        for (final p in parts.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(p.libelle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxi == 0 ? 0 : p.valeur / maxi,
                      minHeight: 14,
                      backgroundColor:
                          t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF8B1E3F)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 38,
                  child: Text('${p.valeur}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Les deux états qui ne sont pas des données
// =============================================================================
class _Refus extends StatelessWidget {
  final String erreur;
  const _Refus({required this.erreur});

  @override
  Widget build(BuildContext context) {
    // Le refus du serveur et la panne de réseau appellent deux gestes différents : le
    // premier ne se réessaie pas.
    final reserve = erreur.contains('reserve_admin');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(reserve ? Icons.lock_outline : Icons.cloud_off_outlined,
                size: 44, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              reserve
                  ? 'Ces chiffres demandent un compte administrateur.'
                  : 'Les chiffres n\'ont pas pu être chargés.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!reserve) ...[
              const SizedBox(height: 6),
              const Text('Vérifiez votre connexion, puis actualisez.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RienEncore extends StatelessWidget {
  const _RienEncore();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucune activité sur cette période.\nÉlargissez la fenêtre, ou revenez demain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
}
