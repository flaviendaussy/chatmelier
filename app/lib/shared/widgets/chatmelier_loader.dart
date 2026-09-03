import 'package:flutter/material.dart';

enum ChatmelierLoaderType {
  detective,
  sommelier,
}

/// A premium animated loader featuring the Chatmelier mascot animations:
/// - [detective]: Camel with magnifying glass and wine bottle (for wine scanning, label search, vintage lookup).
/// - [sommelier]: Camel swirling wine glass with golden aroma bubbles (for AI thinking, pairings, cellar analysis).
class ChatmelierLoader extends StatelessWidget {
  final ChatmelierLoaderType type;
  final double size;
  final String? title;
  final String? subtitle;
  final bool showCardBackground;

  const ChatmelierLoader({
    super.key,
    required this.type,
    this.size = 180,
    this.title,
    this.subtitle,
    this.showCardBackground = false,
  });

  const ChatmelierLoader.detective({
    super.key,
    this.size = 180,
    this.title = 'Chatmelier examine l\'étiquette...',
    this.subtitle = 'Identification du cru, cépages et millésime',
    this.showCardBackground = false,
  }) : type = ChatmelierLoaderType.detective;

  const ChatmelierLoader.sommelier({
    super.key,
    this.size = 180,
    this.title = 'Chatmelier est en pleine réflexion...',
    this.subtitle = 'Accords mets-vins & conseils sur-mesure',
    this.showCardBackground = false,
  }) : type = ChatmelierLoaderType.sommelier;

  String get _assetWebp => type == ChatmelierLoaderType.detective
      ? 'assets/animations/loader_detective_square.webp'
      : 'assets/animations/loader_sommelier_square.webp';

  String get _assetGif => type == ChatmelierLoaderType.detective
      ? 'assets/animations/loader_detective_square.gif'
      : 'assets/animations/loader_sommelier_square.gif';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2226),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF8B1E3F).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          _assetWebp,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) {
            return Image.asset(
              _assetGif,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.wine_bar, color: Color(0xFFD4AF37), size: 40),
              ),
            );
          },
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        imageWidget,
        if (title != null) ...[
          const SizedBox(height: 18),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ],
    );

    if (!showCardBackground) return content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242428) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );
  }
}
