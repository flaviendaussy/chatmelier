import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../data/chat_service.dart';
import 'chat_wine_card.dart';
import 'chat_cocktail_card.dart';

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;

  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          decoration: BoxDecoration(
            color: const Color(0xFF8B1E3F),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, height: 1.35, fontSize: 14),
          ),
        ),
      );
    }

    // AI message with Chatmelier Mascot Avatar, Markdown formatting & Wine Cards
    final parsed = _parseMessage(text);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8B1E3F).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Image.asset(
              'assets/images/logo_transparent_64.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: MarkdownBody(
                    data: parsed.cleanedText,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontSize: 14,
                      ),
                      strong: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE2C480), // Elegant champagne gold accent for bold highlights
                        fontSize: 14,
                      ),
                      em: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                      h1: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE2C480),
                      ),
                      h2: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE2C480),
                      ),
                      h3: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE2C480),
                      ),
                      listBullet: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                      listIndent: 20,
                      blockquote: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF8B1E3F), width: 3),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),

                // Render Wine Cards if any detected
                if (parsed.wineCards.isNotEmpty)
                  ...parsed.wineCards.map((card) => ChatWineCard(data: card)),

                // Render Cocktail Cards if any detected
                if (parsed.cocktailCards.isNotEmpty)
                  ...parsed.cocktailCards.map((card) => ChatCocktailCard(data: card)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ParsedContent _parseMessage(String raw) {
    final List<ChatWineCardData> wineCards = [];
    final List<ChatCocktailCardData> cocktailCards = [];

    Map<String, dynamic>? tryParseCardJson(String rawJson) {
      var s = rawJson.trim();
      if (s.startsWith('```json')) {
        s = s.substring(7);
      } else if (s.startsWith('```')) {
        s = s.substring(3);
      }
      if (s.endsWith('```')) {
        s = s.substring(0, s.length - 3);
      }
      s = s.trim();
      s = s.replaceAll('“', '"').replaceAll('”', '"').replaceAll('‘', "'").replaceAll('’', "'");
      s = s.replaceAll(RegExp(r',\s*\}'), '}').replaceAll(RegExp(r',\s*\]'), ']');
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        final start = s.indexOf('{');
        final end = s.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          try {
            var sub = s.substring(start, end + 1);
            sub = sub.replaceAll(RegExp(r',\s*\}'), '}').replaceAll(RegExp(r',\s*\]'), ']');
            return jsonDecode(sub) as Map<String, dynamic>;
          } catch (_) {}
        }
      }
      return null;
    }

    // 1. Wine Cards
    final wineCardRegex = RegExp(r'\[WINE_CARD:\s*(\{.*?\}|```(?:json)?\s*\{.*?\}\s*```)\s*\]', dotAll: true);
    var cleaned = raw.replaceAllMapped(wineCardRegex, (match) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        final map = tryParseCardJson(jsonStr);
        if (map != null) {
          wineCards.add(ChatWineCardData.fromJson(map));
        }
      }
      return '';
    });

    // 2. Cocktail Cards
    final cocktailCardRegex = RegExp(r'\[COCKTAIL_CARD:\s*(\{.*?\}|```(?:json)?\s*\{.*?\}\s*```)\s*\]', dotAll: true);
    cleaned = cleaned.replaceAllMapped(cocktailCardRegex, (match) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        final map = tryParseCardJson(jsonStr);
        if (map != null) {
          cocktailCards.add(ChatCocktailCardData.fromJson(map));
        }
      }
      return '';
    });

    // 3. Clean any partial/malformed card tags or leftovers
    cleaned = cleaned.replaceAll(RegExp(r'\[WINE_CARD:[^\]]*\]?', dotAll: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[COCKTAIL_CARD:[^\]]*\]?', dotAll: true), '');

    // 4. Heuristic Cocktail Extraction Fallback
    // If the assistant gave a full cocktail recipe but omitted the [COCKTAIL_CARD: ...] tag:
    if (cocktailCards.isEmpty) {
      final lower = raw.toLowerCase();
      final hasCocktailIntent = lower.contains('cocktail') ||
          lower.contains('shaker') ||
          lower.contains('mixologie') ||
          lower.contains('au verre à mélange') ||
          lower.contains('old fashioned');

      if (hasCocktailIntent) {
        final lines = raw.split('\n');
        final ingredients = <String>[];
        String? detectedName;
        final recipeLines = <String>[];
        bool inIngredients = false;
        bool inRecipe = false;

        for (final line in lines) {
          final trimmed = line.trim();
          final lineLower = trimmed.toLowerCase();

          if (detectedName == null &&
              (trimmed.startsWith('### ') || trimmed.startsWith('## ') || trimmed.startsWith('**') && trimmed.endsWith('**')) &&
              (lineLower.contains('cocktail') || lineLower.contains('le ') || lineLower.contains('smash') || lineLower.contains('sour') || lineLower.contains('fizz') || lineLower.contains('mule') || lineLower.contains('spritz') || lineLower.contains('martini'))) {
            detectedName = trimmed.replaceAll(RegExp(r'[#\*]'), '').trim();
          }

          if (lineLower.contains('ingrédient') || lineLower.contains('ingredients')) {
            inIngredients = true;
            inRecipe = false;
            continue;
          }
          if (lineLower.contains('recette') || lineLower.contains('préparation') || lineLower.contains('preparation') || lineLower.contains('instructions') || lineLower.contains('méthode')) {
            inIngredients = false;
            inRecipe = true;
            continue;
          }

          if (inIngredients) {
            if (trimmed.startsWith('-') || trimmed.startsWith('•') || trimmed.startsWith('*')) {
              final ing = trimmed.replaceFirst(RegExp(r'^[-•\*]\s*'), '').trim();
              if (ing.isNotEmpty && !ing.toLowerCase().startsWith('recette') && !ing.toLowerCase().startsWith('préparation')) {
                ingredients.add(ing);
              }
            } else if (trimmed.isEmpty && ingredients.isNotEmpty) {
              inIngredients = false;
            }
          } else if (inRecipe) {
            if (trimmed.startsWith('-') || trimmed.startsWith('•') || trimmed.startsWith('*') || RegExp(r'^\d+[\.\)]').hasMatch(trimmed) || (trimmed.isNotEmpty && !trimmed.startsWith('#'))) {
              recipeLines.add(trimmed.replaceFirst(RegExp(r'^[-•\*\d\.\)]\s*'), '').trim());
            } else if (trimmed.startsWith('#') || trimmed.startsWith('---')) {
              inRecipe = false;
            }
          }
        }

        if (ingredients.length >= 2) {
          String baseSpirit = 'gin';
          if (lower.contains('rhum') || lower.contains('rum')) baseSpirit = 'rhum';
          else if (lower.contains('whisky') || lower.contains('whiskey') || lower.contains('bourbon')) baseSpirit = 'whisky';
          else if (lower.contains('vodka')) baseSpirit = 'vodka';
          else if (lower.contains('tequila') || lower.contains('mezcal')) baseSpirit = 'tequila';
          else if (lower.contains('cognac')) baseSpirit = 'cognac';
          else if (lower.contains('armagnac')) baseSpirit = 'armagnac';
          else if (lower.contains('calvados')) baseSpirit = 'calvados';

          final synthesizedName = detectedName ?? 'Cocktail Signature';
          final synthesizedRecipe = recipeLines.isNotEmpty
              ? recipeLines.join(' ')
              : 'Mélanger les ingrédients au shaker avec des glaçons, filtrer et servir frais.';

          cocktailCards.add(ChatCocktailCardData(
            name: synthesizedName,
            baseSpirit: baseSpirit,
            glass: lower.contains('coupe') ? 'Coupe' : (lower.contains('highball') ? 'Verre Highball' : 'Verre Old Fashioned'),
            method: lower.contains('shaker') ? 'Au shaker' : 'Au verre à mélange',
            ingredients: ingredients,
            recipe: synthesizedRecipe,
            reason: 'Recette proposée par Chatmelier',
          ));
        }
      }
    }

    // 5. Scrub any customer-facing UUIDs from the text body
    cleaned = ChatService.sanitizeCustomerFacingText(cleaned).trim();

    return _ParsedContent(
      cleanedText: cleaned,
      wineCards: wineCards,
      cocktailCards: cocktailCards,
    );
  }
}

class _ParsedContent {
  final String cleanedText;
  final List<ChatWineCardData> wineCards;
  final List<ChatCocktailCardData> cocktailCards;
  _ParsedContent({
    required this.cleanedText,
    required this.wineCards,
    required this.cocktailCards,
  });
}
