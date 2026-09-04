import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/premium_provider.dart';
import '../../../shared/widgets/chatmelier_loader.dart';

/// Modal dialog/sheet shown before scanning a wine bottle in Free Mode.
/// Enforces: "Chaque bouteille scannée en mode gratuit doit donner lieu à une vidéo
/// qui doit être visionnée. Zéro gratuité."
class RewardedVideoAdSheet extends ConsumerStatefulWidget {
  final VoidCallback onRewardEarned;
  final VoidCallback onCancel;

  const RewardedVideoAdSheet({
    super.key,
    required this.onRewardEarned,
    required this.onCancel,
  });

  static Future<bool> show(
    BuildContext context, {
    required VoidCallback onRewardEarned,
    required VoidCallback onCancel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RewardedVideoAdSheet(
        onRewardEarned: onRewardEarned,
        onCancel: onCancel,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<RewardedVideoAdSheet> createState() => _RewardedVideoAdSheetState();
}

class _RewardedVideoAdSheetState extends ConsumerState<RewardedVideoAdSheet> {
  static const int _totalSeconds = 15;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _isCompleted = false;

  final List<Map<String, String>> _sponsors = const [
    {
      'name': 'Fever-Tree Mixers',
      'tagline': 'Des ingrédients naturels pour sublimer vos cocktails et dégustations.',
      'icon': '🌿',
    },
    {
      'name': 'Verrerie Riedel',
      'tagline': 'Le verre adapté à chaque cépage pour révéler les plus grands terroirs.',
      'icon': '🍷',
    },
    {
      'name': 'EuroCave',
      'tagline': 'L\'art de la conservation et du vieillissement des grands crus.',
      'icon': '🏰',
    },
    {
      'name': 'Académie des Sommeliers',
      'tagline': 'L\'accord parfait entre mets et vins guidé par l\'intelligence artificielle.',
      'icon': '🎓',
    },
  ];

  late final Map<String, String> _currentSponsor;

  @override
  void initState() {
    super.initState();
    _currentSponsor = _sponsors[Random().nextInt(_sponsors.length)];
    // Auto-start video countdown after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startPlayback();
    });
  }

  void _startPlayback() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isCompleted = true;
        });
        // Short celebratory delay before triggering scan reward
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.of(context).pop(true);
            widget.onRewardEarned();
          }
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _confirmCancel() {
    if (_isCompleted) {
      Navigator.of(context).pop(true);
      widget.onRewardEarned();
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner le scan IA ?'),
        content: const Text(
          'En mode gratuit, chaque scan de bouteille nécessite le visionnage complet de la vidéo pour financer l\'analyse Gemini.\n\nSi vous quittez, l\'analyse sera annulée mais vous pourrez saisir la bouteille manuellement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuer la vidéo'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.of(ctx).pop(true);
              Navigator.of(context).pop(false);
              widget.onCancel();
            },
            child: const Text('Quitter (Saisie manuelle)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (_totalSeconds - _remainingSeconds) / _totalSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmCancel();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD97706), width: 1.2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ondemand_video_rounded, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Text(
                          'Vidéo Sponsorisée Requise',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Annuler le scan',
                    onPressed: _confirmCancel,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                'Analyse IA par Chatmelier',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'En mode gratuit, chaque scan d\'étiquette requiert le visionnage complet d\'une courte vidéo pour financer les serveurs IA. (Zéro gratuité)',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // Simulated Video Player Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2C1810), const Color(0xFF1A120B)]
                        : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Mascot Loader
                    const ChatmelierLoader.sommelier(
                      size: 130,
                      title: '',
                      subtitle: '',
                      showCardBackground: false,
                    ),
                    const SizedBox(height: 12),

                    // Sponsor Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_currentSponsor['icon']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          _currentSponsor['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentSponsor['tagline']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Progress bar & Countdown
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.black38 : Colors.amber.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isCompleted ? Colors.green : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isCompleted
                              ? '✨ Récompense débloquée !'
                              : 'Lecture en cours...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isCompleted ? Colors.green : Colors.grey.shade600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isCompleted
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _isCompleted ? '✓ Prêt' : '${_remainingSeconds}s',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _isCompleted ? Colors.green : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Upgrade to Premium Shortcut (No Ads)
              OutlinedButton.icon(
                onPressed: () {
                  // Toggle or enable premium
                  ref.read(premiumProvider.notifier).setPremium(true);
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('👑 Mode Premium activé ! Scans instantanés sans aucune pub.'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                  widget.onRewardEarned();
                },
                icon: const Icon(Icons.workspace_premium, color: Color(0xFFD97706)),
                label: const Text(
                  'Passer au Mode Premium (0 pub, scans illimités)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFD97706), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),

              // Manual Input Option
              TextButton(
                onPressed: _confirmCancel,
                child: Text(
                  'Saisir manuellement sans vidéo ni scan IA',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
