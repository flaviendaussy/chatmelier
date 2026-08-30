import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'chat_wine_card.dart';

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
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ParsedContent _parseMessage(String raw) {
    final List<ChatWineCardData> cards = [];
    final cardRegex = RegExp(r'\[WINE_CARD:\s*(\{.*?\})\]', dotAll: true);

    final cleaned = raw.replaceAllMapped(cardRegex, (match) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          cards.add(ChatWineCardData.fromJson(map));
        } catch (_) {}
      }
      return ''; // remove token from text
    }).trim();

    return _ParsedContent(cleanedText: cleaned, wineCards: cards);
  }
}

class _ParsedContent {
  final String cleanedText;
  final List<ChatWineCardData> wineCards;
  _ParsedContent({required this.cleanedText, required this.wineCards});
}
