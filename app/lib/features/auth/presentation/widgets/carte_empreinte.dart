import 'package:flutter/material.dart';

import '../../../../shared/utils/langue.dart';
import '../../domain/empreinte_de_palais.dart';
import '../../domain/taste_profile.dart';
import '../../domain/wine_taste_radar.dart';
import 'radar_legende.dart';
import 'wine_taste_radar_chart.dart';

/// L'empreinte de palais, mise en carte pour être partagée (P5).
///
/// Format 4:5 (360 × 450, exporté ×3 en 1080 × 1350) : celui qu'Instagram et les
/// messageries affichent sans rogner. Fond sombre dans les deux thèmes de l'app : l'image
/// quitte l'app, elle doit se lire pareil partout.
class CarteEmpreinte extends StatelessWidget {
  static const Size taille = Size(360, 450);

  // La couleur du radar, éclaircie : le bordeaux de l'app se perd sur un fond sombre.
  static const Color _vin = Color(0xFFD35C7C);
  static const Color _or = Color(0xFFD4AF37);
  static const Color _fond = Color(0xFF1B1622);
  static const Color _fondBas = Color(0xFF2B1621);

  final String? nom;
  final TasteProfile profil;

  const CarteEmpreinte({super.key, required this.profil, this.nom});

  @override
  Widget build(BuildContext context) {
    final radar = WineTasteRadarCalculator.compute(profil);
    final empreinte = EmpreinteDePalais.lire(profil, radar);
    final titre = (nom != null && nom!.trim().isNotEmpty) ? nom!.trim() : tr('Mon palais', 'My palate');
    final aDecouvrir = empreinte.phraseADecouvrir;

    return Theme(
      data: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      child: SizedBox.fromSize(
        size: taille,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_fond, _fondBas],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('EMPREINTE DE PALAIS', 'PALATE FINGERPRINT'),
                        style: const TextStyle(color: _or, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 2.2),
                      ),
                    ),
                    Image.asset('assets/images/logo_transparent_128.png', width: 26, height: 26),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.1),
                ),
                const SizedBox(height: 2),
                // Le radar prend la place que les textes laissent : une phrase plus longue
                // (l'anglais, une grande police) le réduit au lieu de faire déborder la carte.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => Center(
                      child: WineTasteRadarChart(
                        size: c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight,
                        anime: false,
                        isInteractive: false,
                        customAxisLabels: WineTasteRadarMetrics.localizedAxisLabels(Langue.estFr ? 'fr' : 'en'),
                        datasets: [
                          RadarChartDataset(
                            label: titre,
                            color: _vin,
                            metrics: radar,
                            confidences: [for (final k in TasteProfile.axisKeys) profil.axisConfidence(k)],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Center(child: LegendeDuRadar(color: _vin)),
                const SizedBox(height: 10),
                Container(height: 1, color: Colors.white12),
                const SizedBox(height: 10),
                Text(
                  empreinte.phraseAime,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                if (aDecouvrir != null) ...[
                  const SizedBox(height: 3),
                  Text(aDecouvrir, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        empreinte.phraseBase,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white54, fontSize: 10.5, height: 1.25),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'chatmelier.github.io',
                      style: TextStyle(color: _or, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
