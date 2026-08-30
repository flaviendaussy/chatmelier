import 'package:flutter/material.dart';

class ConsumptionReviewScreen extends StatelessWidget {
  const ConsumptionReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Souvenir de Dégustation')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Note attribuée à cette bouteille', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) => const Icon(Icons.star, size: 36, color: Colors.amber)),
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Accord mets / Plat dégusté (optionnel)',
              hintText: 'ex: Magret de canard, côte de bœuf...',
              prefixIcon: Icon(Icons.restaurant),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Impressions & Commentaires oenologiques',
              hintText: 'Arômes, texture, tanins, persistance...',
              prefixIcon: Icon(Icons.edit_note),
              border: OutlineInputBorder(),
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
                const SnackBar(
                  content: Text('Dégustation enregistrée dans votre journal ! Santé ! 🍷'),
                  backgroundColor: Color(0xFF8B1E3F),
                ),
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Enregistrer la dégustation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
