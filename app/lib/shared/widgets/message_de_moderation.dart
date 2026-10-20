import 'package:flutter/material.dart';

import '../utils/langue.dart';

/// « L'abus d'alcool est dangereux pour la santé » (Caro, 18/10) : sur l'accueil et le
/// profil, et plus seulement à la porte de l'âge et dans les conditions d'utilisation.
class MessageDeModeration extends StatelessWidget {
  const MessageDeModeration({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        tr('L\'abus d\'alcool est dangereux pour la santé. À consommer avec modération.',
            'Alcohol abuse is dangerous for your health. Drink responsibly.'),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
