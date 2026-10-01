import 'package:flutter/material.dart';

import '../domain/menu_table_matcher_engine.dart';
import '../../../shared/utils/langue.dart';

/// « À deux bouteilles » (V2.3 · E4) : quand le meilleur vin seul laisse trop de convives
/// de côté, la paire qui en satisfait le plus — un blanc pour l'entrée et un rouge pour le
/// plat, quand c'est le cas.
class CarteDeuxBouteilles extends StatelessWidget {
  final PaireDeBouteilles paire;
  final bool isFr;

  const CarteDeuxBouteilles({super.key, required this.paire, required this.isFr});

  @override
  Widget build(BuildContext context) {
    const or = Color(0xFFD4AF37);
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF241B2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: or.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wine_bar_rounded, color: or, size: 18),
              const Icon(Icons.wine_bar_rounded, color: or, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('À deux bouteilles', 'With two bottles'),
                  style: const TextStyle(color: or, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            RedactionDesRaisons.phraseDeLaPaire(paire, isFr: isFr),
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
