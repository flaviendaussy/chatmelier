import 'package:flutter/material.dart';

import '../../../shared/utils/langue.dart';
import '../../../shared/widgets/chatmelier_loader.dart';

/// L'écran « pas de réseau » : le Chatmelier animé, ce qui se passe, et de quoi réessayer.
///
/// Le dessin d'un chat tendant sa bouteille comme une antenne a laissé place au Chatmelier
/// des autres écrans d'attente (16/10).
class ChatmelierOfflineAntennaWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const ChatmelierOfflineAntennaWidget({
    super.key,
    this.title = 'Recherche de réseau...',
    this.message = 'Chatmelier tend le goulot de sa bouteille façon antenne pour capter le signal !',
    this.onRetry,
    this.compact = false,
  });

  @override
  State<ChatmelierOfflineAntennaWidget> createState() => _ChatmelierOfflineAntennaWidgetState();
}

class _ChatmelierOfflineAntennaWidgetState extends State<ChatmelierOfflineAntennaWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 12 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Le Chatmelier animé, comme sur les autres écrans d'attente (16/10), à la place du
            // dessin du chat à l'antenne.
            ChatmelierLoader(type: ChatmelierLoaderType.reseau, size: widget.compact ? 120 : 170, title: null, subtitle: null),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B1E3F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                widget.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (widget.onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(tr('Tester la connexion', 'Test the connection'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
