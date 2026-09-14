import 'dart:async';
import 'package:flutter/material.dart';
import '../../cellar/domain/wine.dart';
import '../../cellar/domain/bottle.dart';
import '../domain/wine_thermal_engine.dart';

class ThermalAerationCalculatorSheet extends StatefulWidget {
  final Wine? wine;
  final Bottle? bottle;

  const ThermalAerationCalculatorSheet({
    super.key,
    this.wine,
    this.bottle,
  });

  static Future<void> show(BuildContext context, {Wine? wine, Bottle? bottle}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ThermalAerationCalculatorSheet(
        wine: wine ?? bottle?.wine,
        bottle: bottle,
      ),
    );
  }

  @override
  State<ThermalAerationCalculatorSheet> createState() => _ThermalAerationCalculatorSheetState();
}

class _ThermalAerationCalculatorSheetState extends State<ThermalAerationCalculatorSheet> {
  late double _bottleTemp;
  double _fridgeTemp = WineThermalEngine.defaultFridgeTemp;
  double _roomTemp = WineThermalEngine.defaultRoomTemp;
  bool _useIceBucket = false;
  bool _showAdvancedSettings = false;

  // Minuteur actif
  Timer? _countdownTimer;
  int? _timerSecondsRemaining;
  bool _timerRunning = false;

  Wine? get _effectiveWine => widget.wine ?? widget.bottle?.wine;

  @override
  void initState() {
    super.initState();
    // Par défaut, bouteille venant de la cave (12°C)
    _bottleTemp = WineThermalEngine.defaultCellarTemp;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes) {
    _countdownTimer?.cancel();
    setState(() {
      _timerSecondsRemaining = minutes * 60;
      _timerRunning = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerSecondsRemaining != null && _timerSecondsRemaining! > 0) {
        setState(() {
          _timerSecondsRemaining = _timerSecondsRemaining! - 1;
        });
      } else {
        timer.cancel();
        setState(() {
          _timerRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFD4AF37),
            content: Text(
              '🍷 Température de service atteinte ! Dégustez votre flacon.',
              style: TextStyle(color: Color(0xFF1E1A24), fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _timerRunning = false;
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final plan = WineThermalEngine.calculatePlan(
      wine: _effectiveWine,
      initialTemp: _bottleTemp,
      roomTemp: _roomTemp,
      fridgeTemp: _fridgeTemp,
      useIceBucket: _useIceBucket,
    );

    final wineTitle = _effectiveWine?.name ?? 'Flacon sélectionné';
    final vintage = _effectiveWine?.vintage != null ? '${_effectiveWine!.vintage}' : '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF16121C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
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
                  child: const Icon(Icons.thermostat_rounded, color: Color(0xFFD4AF37), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thermocourbe & Aération',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '$wineTitle $vintage',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13),
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

          // Contenu déroulant
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Carte Résumé Recommandation
                _buildRecommendationCard(plan),
                if (plan.warmRoomWarning != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF331E20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.6), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alerte Température Ambiante (Rouge)',
                                style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan.warmRoomWarning!,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Minuteur actif si lancé
                if (_timerSecondsRemaining != null) ...[
                  _buildLiveTimerCard(plan),
                  const SizedBox(height: 18),
                ],

                // Réglage température bouteille
                _buildSectionHeader('État actuel de la bouteille', Icons.wine_bar),
                const SizedBox(height: 10),
                _buildBottleSourceSelector(),
                const SizedBox(height: 12),
                _buildTemperatureSlider(
                  label: 'Température actuelle du flacon',
                  value: _bottleTemp,
                  min: 4.0,
                  max: 26.0,
                  unit: '°C',
                  color: const Color(0xFF8B1E3F),
                  onChanged: (val) => setState(() => _bottleTemp = val),
                ),
                const SizedBox(height: 16),

                // Option Seau à glace express si besoin de refroidir
                if (_bottleTemp > plan.targetTemp) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1926),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _useIceBucket ? Colors.cyanAccent.withOpacity(0.6) : Colors.white10,
                      ),
                    ),
                    child: SwitchListTile(
                      activeColor: Colors.cyanAccent,
                      title: const Row(
                        children: [
                          Icon(Icons.ac_unit_rounded, color: Colors.cyanAccent, size: 20),
                          SizedBox(width: 8),
                          Text('Option Seau à glace express', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      subtitle: const Text(
                        'Eau + glaçons : refroidissement 4x plus rapide (loi thermique k=0.090)',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      value: _useIceBucket,
                      onChanged: (val) => setState(() => _useIceBucket = val),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Paramètres Ambiance Réglables (Frigo & Pièce)
                _buildAdvancedSettingsSection(),
                const SizedBox(height: 18),

                // Courbe & Timeline thermique
                _buildSectionHeader('Chronologie & Protocole Sommelier', Icons.timeline_rounded),
                const SizedBox(height: 10),
                _buildTimelineList(plan),
                const SizedBox(height: 18),

                // Courbe de température projetée
                _buildSectionHeader('Évolution thermique calculée', Icons.show_chart_rounded),
                const SizedBox(height: 10),
                _buildThermalCurveChart(plan),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(ThermalPlanResult plan) {
    IconData actionIcon;
    Color accentColor;

    switch (plan.action) {
      case ThermalAction.putInFridge:
        actionIcon = Icons.kitchen_rounded;
        accentColor = Colors.lightBlueAccent;
        break;
      case ThermalAction.iceBucket:
        actionIcon = Icons.ac_unit_rounded;
        accentColor = Colors.cyanAccent;
        break;
      case ThermalAction.leaveInRoom:
        actionIcon = Icons.wb_sunny_rounded;
        accentColor = Colors.orangeAccent;
        break;
      case ThermalAction.alreadyIdeal:
        actionIcon = Icons.check_circle_rounded;
        accentColor = Colors.greenAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF261D2F),
            accentColor.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(actionIcon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.actionTitle,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.actionDescription,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge(
                label: 'Cible idéale',
                value: '${plan.targetTemp.toStringAsFixed(1)}°C',
                color: const Color(0xFFD4AF37),
              ),
              _buildStatBadge(
                label: 'Temps requis',
                value: plan.durationMinutes == 0 ? 'Immédiat' : '${plan.durationMinutes} min',
                color: accentColor,
              ),
              _buildStatBadge(
                label: 'Carafage',
                value: plan.decantingMinutes == 0 ? 'Sans' : '${plan.decantingMinutes} min',
                color: Colors.pinkAccent,
              ),
            ],
          ),
          if (plan.durationMinutes > 0 && !_timerRunning) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.timer_outlined, size: 20),
                label: Text(
                  'Lancer le minuteur (${plan.durationMinutes} min)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _startTimer(plan.durationMinutes),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLiveTimerCard(ThermalPlanResult plan) {
    final isDone = _timerSecondsRemaining == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF22162B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom_rounded, color: Color(0xFFD4AF37), size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDone ? 'Temps écoulé !' : 'Minuteur sommelier en cours',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _formatTimer(_timerSecondsRemaining ?? 0),
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_timerRunning ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white),
            onPressed: () {
              if (_timerRunning) {
                _stopTimer();
              } else if (_timerSecondsRemaining != null && _timerSecondsRemaining! > 0) {
                _startTimer(_timerSecondsRemaining! ~/ 60);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            onPressed: () {
              _countdownTimer?.cancel();
              setState(() {
                _timerSecondsRemaining = null;
                _timerRunning = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottleSourceSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickChoiceChip(
            label: 'Cave à vin',
            sublabel: '12°C',
            icon: Icons.inventory_2_outlined,
            selected: (_bottleTemp - 12.0).abs() < 0.5,
            onTap: () => setState(() => _bottleTemp = 12.0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickChoiceChip(
            label: 'Pièce ambiante',
            sublabel: '${_roomTemp.toStringAsFixed(0)}°C',
            icon: Icons.home_outlined,
            selected: (_bottleTemp - _roomTemp).abs() < 0.5,
            onTap: () => setState(() => _bottleTemp = _roomTemp),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickChoiceChip(
            label: 'Frigo',
            sublabel: '${_fridgeTemp.toStringAsFixed(0)}°C',
            icon: Icons.kitchen_outlined,
            selected: (_bottleTemp - _fridgeTemp).abs() < 0.5,
            onTap: () => setState(() => _bottleTemp = _fridgeTemp),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChoiceChip({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B1E3F).withOpacity(0.4) : const Color(0xFF1E1926),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFD4AF37) : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? const Color(0xFFD4AF37) : Colors.white60),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(sublabel, style: TextStyle(color: selected ? const Color(0xFFD4AF37) : Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        initiallyExpanded: _showAdvancedSettings,
        onExpansionChanged: (v) => setState(() => _showAdvancedSettings = v),
        leading: const Icon(Icons.tune_rounded, color: Color(0xFFD4AF37)),
        title: const Text(
          'Ajuster mon frigo & ma pièce',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Frigo: ${_fridgeTemp.toStringAsFixed(0)}°C • Pièce: ${_roomTemp.toStringAsFixed(0)}°C',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          _buildTemperatureSlider(
            label: 'Température de votre réfrigérateur',
            value: _fridgeTemp,
            min: 1.0,
            max: 10.0,
            unit: '°C',
            color: Colors.lightBlueAccent,
            onChanged: (val) => setState(() => _fridgeTemp = val),
          ),
          const SizedBox(height: 12),
          _buildTemperatureSlider(
            label: 'Température ambiante de votre pièce',
            value: _roomTemp,
            min: 16.0,
            max: 28.0,
            unit: '°C',
            color: Colors.orangeAccent,
            onChanged: (val) => setState(() => _roomTemp = val),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFFD4AF37),
            overlayColor: color.withOpacity(0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 2).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineList(ThermalPlanResult plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: plan.timelineSteps.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final step = entry.value;
          final isLast = entry.key == plan.timelineSteps.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isLast ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$idx',
                    style: TextStyle(
                      color: isLast ? const Color(0xFF1E1A24) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      color: isLast ? const Color(0xFFD4AF37) : Colors.white,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThermalCurveChart(ThermalPlanResult plan) {
    final points = plan.temperatureCurve.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${plan.initialTemp.toStringAsFixed(1)}°C (Départ)',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                '${plan.targetTemp.toStringAsFixed(1)}°C (Idéal)',
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progression horizontale stylisée des points
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: points.map((pt) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261D2F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: pt.key == plan.durationMinutes
                          ? const Color(0xFFD4AF37)
                          : Colors.white10,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${pt.key} min',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pt.value.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          color: pt.key == plan.durationMinutes
                              ? const Color(0xFFD4AF37)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
