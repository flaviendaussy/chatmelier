import 'package:flutter/material.dart';

import '../utils/langue.dart';

/// Ce que voit la table quand ses convives ne se lisent plus (V2.3 · D1) : on le dit, et on
/// propose de réessayer, plutôt que d'afficher en silence une table figée.
class BandeauConnexionPerdue extends StatelessWidget {
  final VoidCallback onReessayer;

  const BandeauConnexionPerdue({super.key, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Connexion perdue avec la table : les arrivées ne s\'affichent plus.',
                  'Lost connection with the table: new arrivals no longer show.'),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onReessayer,
            child: Text(tr('Réessayer', 'Retry'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
