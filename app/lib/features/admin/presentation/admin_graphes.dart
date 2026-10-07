import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/admin_console.dart';
import '../domain/admin_economie.dart';

/// Les graphes de la console (V2.4 · R9) : l'économie et les erreurs jour par jour, le coût
/// par modèle, la franchise de recherche.

const _bordeaux = Color(0xFF8B1E3F);
const _vert = Color(0xFF2E7D32);
const _or = Color(0xFFD4AF37);
const _rouge = Color(0xFFC62828);
const _orange = Color(0xFFEF6C00);

String _jour(DateTime d) => '${d.day}/${d.month}';
double _pas(int n) => n <= 10 ? 1 : (n / 6).ceilToDouble();

FlTitlesData _titres(List<DateTime> jours, {String Function(double)? gauche, double reserve = 40}) => FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: reserve,
          getTitlesWidget: (v, meta) {
            if (v == meta.max) return const SizedBox.shrink();
            return Text(gauche == null ? meta.formattedValue : gauche(v),
                style: const TextStyle(fontSize: 9.5, color: Colors.grey));
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: _pas(jours.length),
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= jours.length || v != i.toDouble()) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_jour(jours[i]), style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
            );
          },
        ),
      ),
    );

/// Un titre de graphe, sa phrase, sa légende, et le graphe lui-même.
class CadreDeGraphe extends StatelessWidget {
  final String titre;
  final String detail;
  final Widget graphe;
  final Map<String, Color> legende;
  final double hauteur;

  const CadreDeGraphe({
    super.key,
    required this.titre,
    required this.detail,
    required this.graphe,
    this.legende = const {},
    this.hauteur = 190,
  });

  @override
  Widget build(BuildContext context) {
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(detail, style: TextStyle(fontSize: 12, color: gris)),
          const SizedBox(height: 12),
          SizedBox(height: hauteur, child: graphe),
          if (legende.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                for (final e in legende.entries)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(e.key, style: TextStyle(fontSize: 11, color: gris)),
                  ]),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

LineChartBarData _ligne(List<FlSpot> points, Color couleur, {bool aire = false, bool pointille = false}) =>
    LineChartBarData(
      spots: points,
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      color: couleur,
      barWidth: 2.4,
      dashArray: pointille ? [6, 4] : null,
      dotData: FlDotData(show: points.length <= 31),
      belowBarData: BarAreaData(show: aire, color: couleur.withValues(alpha: 0.12)),
    );

/// Ce que coûte l'IA et ce que rapporte la pub, chaque jour.
class CourbeCoutEtRevenu extends StatelessWidget {
  final List<JourEconomique> jours;
  const CourbeCoutEtRevenu({super.key, required this.jours});

  @override
  Widget build(BuildContext context) {
    if (jours.isEmpty) return const SizedBox.shrink();
    final maxi = jours.fold<double>(0.0001, (m, j) => [m, j.coutEur, j.revenuEur].reduce((a, b) => a > b ? a : b));
    return CadreDeGraphe(
      titre: 'Jour par jour',
      detail: 'Coût réel de l\'IA (tarifs datés) et revenu estimé de la pub.',
      legende: const {'Coût de l\'IA': _bordeaux, 'Revenu de la pub': _vert},
      graphe: LineChart(LineChartData(
        minY: 0,
        maxY: maxi * 1.25,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titres([for (final j in jours) j.jour], gauche: (v) => euros(v), reserve: 52),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (points) => [
              for (final p in points)
                LineTooltipItem('${_jour(jours[p.x.toInt()].jour)} · ${euros(p.y)}',
                    TextStyle(color: p.bar.color ?? Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        lineBarsData: [
          _ligne([for (var i = 0; i < jours.length; i++) FlSpot(i.toDouble(), jours[i].coutEur)], _bordeaux,
              aire: true),
          _ligne([for (var i = 0; i < jours.length; i++) FlSpot(i.toDouble(), jours[i].revenuEur)], _vert),
        ],
      )),
    );
  }
}

/// Le coût d'une page de carte et d'une étiquette, face à l'objectif de 0,8 c€ la page.
class CourbeCoutDesScans extends StatelessWidget {
  final List<JourEconomique> jours;
  const CourbeCoutDesScans({super.key, required this.jours});

  @override
  Widget build(BuildContext context) {
    final avecDonnees = jours.any((j) => j.carteMoyenEur != null || j.etiquetteMoyenEur != null);
    if (!avecDonnees) return const SizedBox.shrink();
    final valeurs = [
      for (final j in jours) ...[
        if (j.carteMoyenEur != null) j.carteMoyenEur!,
        if (j.etiquetteMoyenEur != null) j.etiquetteMoyenEur!
      ],
      DetailEconomique.objectifCarteEur,
    ];
    final maxi = valeurs.reduce((a, b) => a > b ? a : b);
    return CadreDeGraphe(
      titre: 'Ce que coûte un scan',
      detail: 'Moyenne du jour : une page de carte, une étiquette (lecture et description). '
          'Pointillés : l\'objectif de 0,8 c€ la page.',
      legende: const {'Page de carte': _bordeaux, 'Étiquette': _or},
      graphe: LineChart(LineChartData(
        minY: 0,
        maxY: maxi * 1.3,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titres([for (final j in jours) j.jour], gauche: (v) => euros(v), reserve: 52),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: DetailEconomique.objectifCarteEur, color: _vert, strokeWidth: 1.5, dashArray: [6, 4]),
        ]),
        lineBarsData: [
          _ligne([
            for (var i = 0; i < jours.length; i++)
              if (jours[i].carteMoyenEur != null) FlSpot(i.toDouble(), jours[i].carteMoyenEur!)
          ], _bordeaux),
          _ligne([
            for (var i = 0; i < jours.length; i++)
              if (jours[i].etiquetteMoyenEur != null) FlSpot(i.toDouble(), jours[i].etiquetteMoyenEur!)
          ], _or),
        ],
      )),
    );
  }
}

/// Le coût par modèle réellement servi : ce que change un choix de modèle, ou un relais.
class CoutsParModele extends StatelessWidget {
  final List<CoutParModele> modeles;
  const CoutsParModele({super.key, required this.modeles});

  @override
  Widget build(BuildContext context) {
    if (modeles.isEmpty) return const SizedBox.shrink();
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    final total = modeles.fold<double>(0, (s, m) => s + m.coutEur);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Par modèle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('Le modèle que Google a réellement servi, et ce qu\'un appel lui coûte en moyenne.',
              style: TextStyle(fontSize: 12, color: gris)),
          const SizedBox(height: 10),
          for (final m in modeles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(m.modele, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    Text('${euros(m.coutEur)} · ${m.appels} appels', style: const TextStyle(fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : (m.coutEur / total).clamp(0.0, 1.0),
                      minHeight: 7,
                      color: _bordeaux,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                      '${euros(m.coutMoyenEur)} l\'appel · ${m.entreeMoyenne} jetons en entrée, ${m.sortieMoyenne} en sortie',
                      style: TextStyle(fontSize: 11.5, color: gris)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// La franchise de recherche Google du mois : au-delà, chaque recherche se paie.
class JaugeDeRecherche extends StatelessWidget {
  final int utilisees;
  final int franchise;
  const JaugeDeRecherche({super.key, required this.utilisees, required this.franchise});

  @override
  Widget build(BuildContext context) {
    final part = franchise == 0 ? 0.0 : utilisees / franchise;
    final couleur = part >= 1 ? _rouge : (part >= 0.8 ? _orange : _vert);
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recherches Google ce mois-ci', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('$utilisees sur $franchise offertes ; au-delà, 0,014 \$ chacune.',
              style: TextStyle(fontSize: 12, color: gris)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: part.clamp(0.0, 1.0),
              minHeight: 12,
              color: couleur,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Erreurs et avertissements, empilés jour par jour.
class BarresDErreurs extends StatelessWidget {
  final List<JourDErreurs> jours;
  const BarresDErreurs({super.key, required this.jours});

  @override
  Widget build(BuildContext context) {
    if (jours.isEmpty) return const SizedBox.shrink();
    final maxi = jours.fold<int>(1, (m, j) => (j.erreurs + j.alertes) > m ? j.erreurs + j.alertes : m);
    return CadreDeGraphe(
      titre: 'Jour par jour',
      detail: 'Erreurs et avertissements remontés par les apps.',
      legende: const {'Erreurs': _rouge, 'Avertissements': _orange},
      hauteur: 160,
      graphe: BarChart(BarChartData(
        minY: 0,
        maxY: maxi * 1.2,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titres([for (final j in jours) j.jour], reserve: 32),
        barGroups: [
          for (var i = 0; i < jours.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: (jours[i].erreurs + jours[i].alertes).toDouble(),
                width: jours.length > 60 ? 2 : 6,
                borderRadius: BorderRadius.circular(2),
                rodStackItems: [
                  if (jours[i].erreurs > 0) BarChartRodStackItem(0, jours[i].erreurs.toDouble(), _rouge),
                  if (jours[i].alertes > 0)
                    BarChartRodStackItem(
                        jours[i].erreurs.toDouble(), (jours[i].erreurs + jours[i].alertes).toDouble(), _orange),
                ],
              ),
            ]),
        ],
      )),
    );
  }
}
