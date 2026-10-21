import 'package:flutter/material.dart';

import '../../shared/utils/langue.dart';

/// Demander avant de montrer une vidéo récompensée (modèle économique, phase 0).
///
/// Les règles d'AdMob veulent qu'une vidéo récompensée soit **choisie** : la personne voit
/// ce qu'elle obtient et décide de regarder. Le scan d'étiquette lançait la vidéo dès la
/// photo prise ; une pub non sollicitée peut valoir une suspension du compte, seule source
/// de revenu de l'app.
///
/// Rend vrai si la personne choisit de regarder, faux si elle renonce (ou ferme la feuille).
class ProposerUneVideo {
  static Future<bool> demander(
    BuildContext context, {
    required String titre,
    required String explication,
    String? renoncer,
  }) async {
    final choix = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.play_circle_outline, color: Color(0xFFD4AF37), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(titre, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(explication, style: Theme.of(c).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(
                tr('Chatmelier ne vend rien : ces courtes vidéos paient l\'IA.',
                    'Chatmelier sells nothing: these short videos pay for the AI.'),
                style: Theme.of(c).textTheme.bodySmall?.copyWith(color: Theme.of(c).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(c, true),
                icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFFD4AF37)),
                label: Text(tr('Regarder la vidéo', 'Watch the video')),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(renoncer ?? tr('Pas maintenant', 'Not now')),
              ),
            ],
          ),
        ),
      ),
    );
    return choix == true;
  }
}
