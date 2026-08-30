import 'package:flutter/material.dart';

class WineTypeBadge extends StatelessWidget {
  final String type;
  const WineTypeBadge({super.key, required this.type});

  static Color getColor(String type) {
    switch (type.toLowerCase().trim()) {
      case 'red':
      case 'rouge':
        return const Color(0xFF8B1A2B); // Burgundy Red
      case 'white':
      case 'blanc':
        return const Color(0xFFC2A649); // White Wine Gold
      case 'rosé':
      case 'rose':
        return const Color(0xFFE8A0BF); // Rose Pink
      case 'sparkling':
      case 'bulles':
      case 'champagne':
      case 'effervescent':
        return const Color(0xFFD4AF37); // Champagne Gold
      case 'dessert':
      case 'moelleux':
      case 'liquoreux':
        return const Color(0xFFE5A65D); // Sweet Amber
      case 'orange':
        return const Color(0xFFE67E22); // Orange
      case 'fortified':
      case 'muté':
      case 'porto':
      case 'xérès':
        return const Color(0xFF78281F); // Fortified
      default:
        return Colors.grey.shade700;
    }
  }

  static String getLabel(String type) {
    switch (type.toLowerCase().trim()) {
      case 'red':
      case 'rouge':
        return 'ROUGE';
      case 'white':
      case 'blanc':
        return 'BLANC';
      case 'rosé':
      case 'rose':
        return 'ROSÉ';
      case 'sparkling':
      case 'bulles':
      case 'champagne':
      case 'effervescent':
        return 'BULLES';
      case 'dessert':
      case 'moelleux':
      case 'liquoreux':
        return 'MOELLEUX';
      case 'orange':
        return 'ORANGE';
      case 'fortified':
      case 'muté':
      case 'porto':
      case 'xérès':
        return 'FORTIFIÉ';
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor(type);
    final label = getLabel(type);
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
