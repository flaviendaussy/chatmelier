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
      case 'whisky':
      case 'whiskey':
      case 'bourbon':
      case 'scotch':
        return const Color(0xFFC67D28); // Amber Oak
      case 'rum':
      case 'rhum':
        return const Color(0xFFB85D19); // Golden Rum
      case 'gin':
        return const Color(0xFF167D7F); // Botanical Teal
      case 'vodka':
        return const Color(0xFF4A90E2); // Crystal Ice Blue
      case 'tequila':
        return const Color(0xFF2E7D32); // Agave Green
      case 'mezcal':
        return const Color(0xFF388E3C); // Smoky Mezcal Green
      case 'cognac':
      case 'armagnac':
      case 'brandy':
        return const Color(0xFF8D4004); // Cognac Copper
      case 'liqueur':
      case 'amaretto':
      case 'triple_sec':
      case 'benedictine':
      case 'bénédictine':
      case 'chartreuse':
        return const Color(0xFF9C27B0); // Velvet Purple
      case 'campari':
      case 'bitter':
        return const Color(0xFFD32F2F); // Bitter Ruby Red
      case 'aperol':
      case 'aperitif':
        return const Color(0xFFFF5722); // Aperol Orange
      case 'vermouth':
        return const Color(0xFF880E4F); // Vermouth Rosso
      case 'spirit':
      case 'spiritueux':
        return const Color(0xFF5D4037); // Deep Spirit Brown
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
      case 'whisky':
      case 'whiskey':
      case 'bourbon':
      case 'scotch':
        return 'WHISKY';
      case 'rum':
      case 'rhum':
        return 'RHUM';
      case 'gin':
        return 'GIN';
      case 'vodka':
        return 'VODKA';
      case 'tequila':
        return 'TEQUILA';
      case 'mezcal':
        return 'MEZCAL';
      case 'cognac':
      case 'armagnac':
      case 'brandy':
        return 'COGNAC';
      case 'liqueur':
      case 'amaretto':
      case 'triple_sec':
      case 'benedictine':
      case 'bénédictine':
      case 'chartreuse':
        return 'LIQUEUR';
      case 'campari':
      case 'bitter':
        return 'BITTER';
      case 'aperol':
      case 'aperitif':
        return 'APÉRITIF';
      case 'vermouth':
        return 'VERMOUTH';
      case 'spirit':
      case 'spiritueux':
        return 'SPIRITUEUX';
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
