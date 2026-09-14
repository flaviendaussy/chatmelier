import 'package:flutter/material.dart';

class ConsumptionReviewScreen extends StatelessWidget {
  const ConsumptionReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    return Scaffold(
      appBar: AppBar(title: Text(isFr ? 'Souvenir de Dégustation' : 'Tasting Memory')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isFr ? 'Note attribuée à cette bouteille' : 'Rating given to this bottle',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) => const Icon(Icons.star, size: 36, color: Colors.amber)),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: isFr ? 'Accord mets / Plat dégusté (optionnel)' : 'Food pairing / Dish tasted (optional)',
              hintText: isFr ? 'ex: Magret de canard, côte de bœuf...' : 'e.g., Duck breast, prime rib, aged cheeses...',
              prefixIcon: const Icon(Icons.restaurant),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: isFr ? 'Impressions & Commentaires oenologiques' : 'Tasting notes & Sommelier remarks',
              hintText: isFr ? 'Arômes, texture, tanins, persistance...' : 'Aromas, texture, tannins, persistence...',
              prefixIcon: const Icon(Icons.edit_note),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
              elevation: 2,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFr
                        ? 'Dégustation enregistrée dans votre journal ! Santé ! 🍷'
                        : 'Tasting recorded in your journal! Cheers! 🍷',
                  ),
                  backgroundColor: const Color(0xFF8B1E3F),
                ),
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              isFr ? 'Enregistrer la dégustation' : 'Save tasting note',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
