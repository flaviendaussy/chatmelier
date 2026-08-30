import 'package:flutter/material.dart';
import '../../features/cellar/domain/wine.dart';

class DrinkingWindowTimeline extends StatelessWidget {
  final Wine wine;
  const DrinkingWindowTimeline({super.key, required this.wine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;
    final start = wine.drinkStart ?? (wine.vintage != null ? wine.vintage! + 2 : currentYear - 1);
    final end = wine.drinkEnd ?? (wine.vintage != null ? wine.vintage! + 10 : currentYear + 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Start: $start', style: theme.textTheme.bodySmall),
            Text('Now: $currentYear', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            Text('End: $end', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: end > start ? ((currentYear - start) / (end - start)).clamp(0.0, 1.0) : 0.5,
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              currentYear > end
                  ? Colors.red
                  : (currentYear >= end - 1 ? Colors.orange : Colors.green),
            ),
          ),
        ),
      ],
    );
  }
}
