import '../../../shared/utils/langue.dart';

/// Où « Me montrer » emmène.
enum Destination { cave, ceSoir, journal, profil, sommelier, secouer }

/// Une fonction de l'app, expliquée en deux phrases (R10, « Le saviez-vous ? »).
class Astuce {
  final String id;
  final String emoji;
  final Phrase titre;
  final Phrase texte;
  final Destination destination;

  const Astuce({
    required this.id,
    required this.emoji,
    required this.titre,
    required this.texte,
    required this.destination,
  });
}

class Astuces {
  /// Dans l'ordre où elles reviennent : d'abord ce qui sert tous les jours.
  static const toutes = <Astuce>[
    Astuce(
      id: 'jauge',
      emoji: '⏳',
      titre: Phrase('Quand ouvrir chaque bouteille', 'When to open each bottle'),
      texte: Phrase(
          'Sous chaque bouteille de votre cave, une petite jauge dit si elle est en garde, à son apogée ou à boire bientôt.',
          'Under each bottle in your cellar, a small gauge shows whether it should wait, is at its peak, or should be drunk soon.'),
      destination: Destination.cave,
    ),
    Astuce(
      id: 'a_prix_egal',
      emoji: '⚖️',
      titre: Phrase('À prix égal, le sommelier choisit', 'Same price? The sommelier picks'),
      texte: Phrase(
          'Photographiez la carte d\'un restaurant : quand deux vins coûtent le même prix, Chatmelier vous dit lequel va le mieux à vos goûts.',
          'Take a photo of a restaurant\'s wine list: when two wines cost the same, Chatmelier tells you which one suits your taste best.'),
      destination: Destination.ceSoir,
    ),
    Astuce(
      id: 'sommelier',
      emoji: '💬',
      titre: Phrase('Une question au sommelier', 'Ask the sommelier'),
      texte: Phrase(
          'La bulle en haut de l\'écran ouvre le sommelier : demandez quelle bouteille ouvrir ce soir, ou avec quel plat la servir.',
          'The bubble at the top of the screen opens the sommelier: ask which bottle to open tonight, or what dish to serve it with.'),
      destination: Destination.sommelier,
    ),
    Astuce(
      id: 'table',
      emoji: '👥',
      titre: Phrase('Choisir à plusieurs', 'Choosing together'),
      texte: Phrase(
          'Au restaurant, « Choisir en groupe » fait voter la table : chacun donne ses goûts sur son propre téléphone, même sans l\'app.',
          'At a restaurant, “Choose as a group” lets the table vote: everyone gives their taste on their own phone, even without the app.'),
      destination: Destination.ceSoir,
    ),
    Astuce(
      id: 'vin_dehors',
      emoji: '🥂',
      titre: Phrase('Un vin bu ailleurs', 'A wine you had elsewhere'),
      texte: Phrase(
          'Chez des amis ou au restaurant, « Noter un vin bu dehors » le garde dans votre journal, sans toucher à votre cave.',
          'At friends\' or at a restaurant, “Rate a wine had out” keeps it in your journal without touching your cellar.'),
      destination: Destination.ceSoir,
    ),
    Astuce(
      id: 'plat',
      emoji: '🍽️',
      titre: Phrase('Quel vin pour mon plat ?', 'Which wine for my dish?'),
      texte: Phrase(
          'Dans votre cave, dites ce que vous cuisinez : Chatmelier choisit parmi vos propres bouteilles.',
          'In your cellar, say what you\'re cooking: Chatmelier picks from your own bottles.'),
      destination: Destination.cave,
    ),
    Astuce(
      id: 'palais',
      emoji: '🎯',
      titre: Phrase('Votre palais', 'Your palate'),
      texte: Phrase(
          'Chaque vin noté affine votre profil de goût. Profil → Palais montre ce que l\'app a compris, et ce qu\'elle devine encore.',
          'Every wine you rate sharpens your taste profile. Profile → Palate shows what the app has understood, and what it still guesses.'),
      destination: Destination.profil,
    ),
    Astuce(
      id: 'export',
      emoji: '📤',
      titre: Phrase('Votre cave dans un tableur', 'Your cellar in a spreadsheet'),
      texte: Phrase(
          'Profil → Outils → Exporter ma cave : un fichier Excel ou CSV de toutes vos bouteilles.',
          'Profile → Tools → Export my cellar: an Excel or CSV file of all your bottles.'),
      destination: Destination.profil,
    ),
    Astuce(
      id: 'secouer',
      emoji: '📳',
      titre: Phrase('Un avis, un souci ?', 'A thought, a problem?'),
      texte: Phrase(
          'Secouez le téléphone : vous pouvez nous écrire, et entourer sur l\'écran ce qui ne va pas.',
          'Shake your phone: you can write to us, and circle on the screen what\'s wrong.'),
      destination: Destination.secouer,
    ),
  ];

  /// La prochaine astuce : la première pas encore vue ; un tour fini, on recommence. Rend
  /// aussi la liste des vues à garder.
  static ({Astuce astuce, List<String> vues}) suivante(List<String> vues) {
    final reste = toutes.where((a) => !vues.contains(a.id)).toList();
    if (reste.isEmpty) return (astuce: toutes.first, vues: [toutes.first.id]);
    return (astuce: reste.first, vues: [...vues, reste.first.id]);
  }
}
