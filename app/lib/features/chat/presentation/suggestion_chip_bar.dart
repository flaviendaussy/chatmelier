import 'package:flutter/material.dart';

class SuggestionChipBar extends StatelessWidget {
  const SuggestionChipBar({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestions = ["What to drink tonight?", "Pair with steak", "Cellar summary", "Drink soon alerts"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: suggestions.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ActionChip(label: Text(suggestions[index]), onPressed: () {}),
        ),
      ),
    );
  }
}
