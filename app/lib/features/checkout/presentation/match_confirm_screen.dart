import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MatchConfirmScreen extends StatelessWidget {
  const MatchConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmer la sélection')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wine_bar, size: 90, color: Color(0xFF8B1E3F)),
              const SizedBox(height: 16),
              const Text('Château Margaux 2015', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Correspondance : 98%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Pas cette bouteille'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () => context.push('/checkout/review'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('C\'est bien celle-ci !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
