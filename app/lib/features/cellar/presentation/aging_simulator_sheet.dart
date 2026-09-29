import 'package:flutter/material.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import '../domain/wine.dart';
import '../domain/aging_simulator_engine.dart';
import '../../../shared/utils/langue.dart';

class AgingSimulatorSheet extends StatefulWidget {
  final Wine wine;

  const AgingSimulatorSheet({super.key, required this.wine});

  static Future<void> show(BuildContext context, {required Wine wine}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgingSimulatorSheet(wine: wine),
    );
  }

  @override
  State<AgingSimulatorSheet> createState() => _AgingSimulatorSheetState();
}

class _AgingSimulatorSheetState extends State<AgingSimulatorSheet> {
  int _additionalYears = 3;

  @override
  Widget build(BuildContext context) {
    final snapshot = AgingSimulatorEngine.simulateAging(
      wine: widget.wine,
      additionalYears: _additionalYears,
    );

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
                  child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Jumeau Numérique & Vieillissement', 'Digital twin & ageing'),
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.wine.name} ${widget.wine.vintage ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                // 1. Slider temporel
                _buildTimeTravelControl(snapshot),
                const SizedBox(height: 20),

                // 2. Carte Robe & Phase d'apogée
                _buildPhaseAndRobeCard(snapshot),
                const SizedBox(height: 20),

                // 3. Radar Gustatif Projeté
                _buildRadarSection(snapshot),
                const SizedBox(height: 20),

                // 4. Notes de Dégustation Projetées
                _buildTastingProjection(snapshot),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTravelControl(AgingSnapshot snapshot) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1626),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('Horizon de vieillissement :', 'Ageing horizon:'),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E3F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tr('+$_additionalYears ans • Année ${snapshot.targetYear}', '+$_additionalYears years • ${snapshot.targetYear}'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: _additionalYears.toDouble(),
            min: 0,
            max: 15,
            divisions: 15,
            activeColor: const Color(0xFFD4AF37),
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => _additionalYears = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('Aujourd\'hui', 'Today'), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(tr('+5 ans', '+5 years'), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(tr('+10 ans', '+10 years'), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(tr('+15 ans', '+15 years'), style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseAndRobeCard(AgingSnapshot snapshot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1524),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Disque visuel de la robe avec animation de couleur
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: snapshot.robeColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: [
                BoxShadow(
                  color: snapshot.robeColor.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        snapshot.phaseName,
                        style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      '${snapshot.peakSatisfactionPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.robeDescription,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSection(AgingSnapshot snapshot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1524),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: Color(0xFFD4AF37), size: 18),
              const SizedBox(width: 8),
              Text(
                tr('Évolution Cinétique des 8 Piliers Gustatifs', 'How the 8 taste pillars evolve'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              height: 220,
              width: 280,
              child: WineTasteRadarChart(
                datasets: [
                  RadarChartDataset(
                    label: tr('Simulation (${snapshot.targetYear})', 'Simulation (${snapshot.targetYear})'),
                    metrics: snapshot.simulatedRadar,
                    color: const Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTastingProjection(AgingSnapshot snapshot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1524),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Profil Sensoriel Projeté', 'Projected taste profile'),
            style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildTastingRow(tr('🍎 Fruit & Fraîcheur', '🍎 Fruit & freshness'), snapshot.primaryAromas),
          const Divider(color: Colors.white10, height: 16),
          _buildTastingRow(tr('🍄 Tertiaire & Sous-Bois', '🍄 Tertiary & forest floor'), snapshot.tertiaryAromas),
          const Divider(color: Colors.white10, height: 16),
          _buildTastingRow(tr('👅 Matière & Caudalies', '👅 Texture & length'), snapshot.palateTexture),
        ],
      ),
    );
  }

  Widget _buildTastingRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
      ],
    );
  }
}
