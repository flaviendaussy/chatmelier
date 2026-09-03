import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatmelierThinkingIndicator extends StatefulWidget {
  const ChatmelierThinkingIndicator({super.key});

  @override
  State<ChatmelierThinkingIndicator> createState() => _ChatmelierThinkingIndicatorState();
}

class _ChatmelierThinkingIndicatorState extends State<ChatmelierThinkingIndicator> {
  static const List<String> _thinkingPhrases = [
    'Chatmelier explore les recoins de votre cave...',
    'Chatmelier consulte ses grimoires œnologiques...',
    'Chatmelier réfléchit aux meilleurs accords mets-vins...',
    'Chatmelier analyse les terroirs et les millésimes...',
    'Chatmelier prépare votre recommandation sur-mesure...',
    'Chatmelier affine ses conseils de service et carafage...',
  ];

  int _phraseIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (t) {
      if (mounted) {
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _thinkingPhrases.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phrase = _thinkingPhrases[_phraseIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF22252B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B1E3F).withValues(alpha: 0.18),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Prominent Animated Chatmelier Sommelier Mascot
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2226),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/animations/loader_sommelier_square.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) {
                      return Image.asset(
                        'assets/animations/loader_sommelier_square.gif',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/logo_transparent_128.png',
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Animated Phrase with CrossFade
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  phrase,
                  key: ValueKey<int>(_phraseIndex),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sommelier en réflexion',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFD4AF37),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPulseDot(0),
                  const SizedBox(width: 4),
                  _buildPulseDot(200),
                  const SizedBox(width: 4),
                  _buildPulseDot(400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseDot(int delayMs) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFFD4AF37),
        shape: BoxShape.circle,
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(
      delay: Duration(milliseconds: delayMs),
      duration: 600.ms,
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.5, 1.5),
    );
  }
}
