import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/langue.dart';

/// Pourquoi une vidéo au scan d'une carte, dit franchement, jusqu'à « Ne plus montrer »
/// (13/10 : « ajoutons-en un [message] qui explique la nécessité de la pub de par les coûts
/// AI et l'envie de rester 100 % fonctionnel en version gratuite, et qui explique qu'aucun
/// temps n'est perdu »). Le court message d'après la vidéo, lui, reste toujours.
class ExplicationDeLaVideo extends StatelessWidget {
  static const cleMasquee = 'pub_scan_carte_explication_masquee';

  const ExplicationDeLaVideo({super.key});

  /// Montre l'explication, sauf si la personne l'a masquée ; se termine quand elle la ferme.
  static Future<void> montrerSiBesoin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(cleMasquee) ?? false) return;
    if (!context.mounted) return;
    final masquer = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const ExplicationDeLaVideo(),
    );
    if (masquer == true) await prefs.setBool(cleMasquee, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(tr('Votre carte est lue', 'Your wine list is ready'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(tr('Pendant la vidéo, Chatmelier lisait déjà votre carte : vous n\'avez pas attendu une seconde de plus.',
                'While the video played, Chatmelier was already reading your list: you didn\'t wait a second longer.')),
            const SizedBox(height: 14),
            Text(tr('Pourquoi une vidéo ?', 'Why a video?'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(tr('Lire une carte des vins demande une intelligence artificielle, qui coûte à chaque scan. La vidéo la paie : Chatmelier reste entièrement gratuit, sans aucune fonction bridée.',
                'Reading a wine list takes artificial intelligence, which costs money on every scan. The video pays for it: Chatmelier stays completely free, with no feature held back.')),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(tr('Ne plus montrer', 'Don\'t show again')),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                  child: Text(tr('Voir ma carte', 'See my list')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
