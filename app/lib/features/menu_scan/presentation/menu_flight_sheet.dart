import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/menu_wine.dart';
import '../domain/menu_flight_engine.dart';

class MenuFlightSheet extends StatefulWidget {
  final ScannedMenu menu;

  const MenuFlightSheet({super.key, required this.menu});

  static Future<void> show(BuildContext context, {required ScannedMenu menu}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MenuFlightSheet(menu: menu),
    );
  }

  @override
  State<MenuFlightSheet> createState() => _MenuFlightSheetState();
}

class _MenuFlightSheetState extends State<MenuFlightSheet> {
  FlightFormat _format = FlightFormat.threeGlasses;
  FlightWineColor _color = FlightWineColor.mix;
  final FlightTheme _theme = FlightTheme.progressive;
  late TastingFlightProposal _proposal;

  @override
  void initState() {
    super.initState();
    _recalculateFlight();
  }

  void _recalculateFlight() {
    setState(() {
      _proposal = MenuFlightEngine.buildFlight(
        menu: widget.menu,
        format: _format,
        color: _color,
        theme: _theme,
      );
    });
  }

  void _shareFlight() {
    final buffer = StringBuffer();
    final restName = widget.menu.restaurantName.isNotEmpty ? widget.menu.restaurantName : "Carte des vins";
    buffer.writeln('🍷 ${_proposal.title} — $restName');
    buffer.writeln('Thème : ${_color.labelFr} (${_format.glassCount} verres)');
    buffer.writeln(_proposal.storyline);
    buffer.writeln('');
    for (final step in _proposal.steps) {
      final priceStr = step.glassPrice != null ? ' (~${step.glassPrice!.toStringAsFixed(1)}€)' : '';
      buffer.writeln('${step.stepTitle} : ${step.wine.name}${step.wine.vintage != null ? " ${step.wine.vintage}" : ""}$priceStr');
      buffer.writeln('   👉 ${step.sommelierRole} — ${step.tastingNotesSummary}');
    }
    buffer.writeln('');
    buffer.writeln('Composé par Chatmelier AI Sommelier');
    Share.share(buffer.toString(), subject: '${_proposal.title} - $restName');
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

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
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFr ? 'Flight Sommelier Dégustation' : 'Tasting Wine Flight',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_proposal.steps.length} verres cohérents • ${widget.menu.restaurantName.isNotEmpty ? widget.menu.restaurantName : (isFr ? "Carte des vins" : "Wine list")}',
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Color(0xFFD4AF37)),
                  tooltip: isFr ? 'Partager le flight' : 'Share flight',
                  onPressed: _shareFlight,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Format selector (3 verres vs 5 verres)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        '✨ 3 Verres Express',
                        style: TextStyle(
                          color: _format == FlightFormat.threeGlasses ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    selected: _format == FlightFormat.threeGlasses,
                    selectedColor: const Color(0xFFD4AF37),
                    backgroundColor: const Color(0xFF22162A),
                    side: BorderSide(
                      color: _format == FlightFormat.threeGlasses ? const Color(0xFFD4AF37) : Colors.white24,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _format = FlightFormat.threeGlasses);
                        _recalculateFlight();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        '👑 5 Verres Grand Parcours',
                        style: TextStyle(
                          color: _format == FlightFormat.fiveGlasses ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    selected: _format == FlightFormat.fiveGlasses,
                    selectedColor: const Color(0xFFD4AF37),
                    backgroundColor: const Color(0xFF22162A),
                    side: BorderSide(
                      color: _format == FlightFormat.fiveGlasses ? const Color(0xFFD4AF37) : Colors.white24,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _format = FlightFormat.fiveGlasses);
                        _recalculateFlight();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Color & Style selector (Mix, Blanc, Rosé, Rouge)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FlightWineColor.values.map((c) {
                  final isSelected = _color == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Text(c.icon, style: const TextStyle(fontSize: 13)),
                      label: Text(
                        c == FlightWineColor.mix
                            ? (isFr ? 'Mix (Harmonie)' : 'Mix')
                            : c == FlightWineColor.white
                                ? (isFr ? '100% Blanc' : 'White')
                                : c == FlightWineColor.rose
                                    ? (isFr ? '100% Rosé' : 'Rosé')
                                    : (isFr ? '100% Rouge' : 'Red'),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8B1E3F),
                      backgroundColor: const Color(0xFF1E1424),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFD4AF37) : Colors.white12,
                        width: isSelected ? 1.4 : 1,
                      ),
                      onSelected: (selected) {
                        if (selected && _color != c) {
                          setState(() => _color = c);
                          _recalculateFlight();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Scrollable list of steps
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Storyline Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23172C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📜', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _proposal.title,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _proposal.storyline,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Flight Glass Steps
                ..._proposal.steps.map((step) => _buildStepCard(step, isFr)),

                const SizedBox(height: 12),
              ],
            ),
          ),

          // Bottom Bar with Total & Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1B1224),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFr ? 'Prix estimé du flight' : 'Estimated flight total',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      Text(
                        '~${_proposal.totalEstimatedPrice.toStringAsFixed(0)} € (${_proposal.steps.length} verres)',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      isFr ? 'Prêt à déguster 🍷' : 'Ready to taste 🍷',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(FlightGlassStep step, bool isFr) {
    final wine = step.wine;
    final priceStr = step.glassPrice != null
        ? '${step.glassPrice!.toStringAsFixed(1)} € / verre'
        : (wine.bottlePrice != null ? '${wine.bottlePrice!.toStringAsFixed(0)} € / btl' : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1627),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                  ),
                  child: Text(
                    step.stepTitle,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•  ${step.sommelierRole}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (priceStr.isNotEmpty)
                  Text(
                    priceStr,
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              wine.name,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (wine.appellation != null || wine.region != null || wine.vintage != null) ...[
              const SizedBox(height: 2),
              Text(
                '${wine.appellation ?? wine.region ?? ""} ${wine.vintage != null ? "• ${wine.vintage}" : ""}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.tastingNotesSummary,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                    ),
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
