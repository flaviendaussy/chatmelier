import 'package:flutter/material.dart';
import '../../features/cellar/domain/wine.dart';

class DrinkingWindowBadge extends StatelessWidget {
  final DrinkWindowStatus status;
  const DrinkingWindowBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    Color color;
    String label;
    switch (status) {
      case DrinkWindowStatus.inPeak:
        color = Colors.green.shade700;
        label = isFr ? 'À L\'APOGÉE ✨' : 'AT PEAK ✨';
        break;
      case DrinkWindowStatus.drinkSoon:
        color = Colors.orange.shade800;
        label = isFr ? 'À BOIRE VITE ⏰' : 'DRINK SOON ⏰';
        break;
      case DrinkWindowStatus.tooYoung:
        color = Colors.blue.shade700;
        label = isFr ? 'TROP JEUNE ⏳' : 'TOO YOUNG ⏳';
        break;
      case DrinkWindowStatus.aging:
        color = Colors.teal.shade700;
        label = isFr ? 'EN GARDE ⏳' : 'AGING ⏳';
        break;
      case DrinkWindowStatus.pastPeak:
        color = Colors.red.shade800;
        label = isFr ? 'DÉCLIN / PASSÉ ⚠️' : 'PAST PEAK ⚠️';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
