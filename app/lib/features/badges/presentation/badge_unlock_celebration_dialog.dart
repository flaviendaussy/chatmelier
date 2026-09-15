import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../data/badge_unlock_tracker.dart';
import '../domain/badge.dart';

/// Classy and celebratory dialog displayed when a badge is unlocked.
/// Features champagne micro-effervescence, rotating luminous halo,
/// tactile haptic feedback, and a clean contributing wine summary.
class BadgeUnlockCelebrationDialog extends StatefulWidget {
  final BadgeProgress progress;

  const BadgeUnlockCelebrationDialog({
    super.key,
    required this.progress,
  });

  static Future<void> show(BuildContext context, BadgeProgress progress) {
    HapticFeedback.mediumImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Badge Unlock',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (ctx, anim1, anim2) => BadgeUnlockCelebrationDialog(progress: progress),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<BadgeUnlockCelebrationDialog> createState() => _BadgeUnlockCelebrationDialogState();
}

class _BadgeUnlockCelebrationDialogState extends State<BadgeUnlockCelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _bubblesController;
  bool _showContributingList = false;

  @override
  void initState() {
    super.initState();
    // Gentle continuous rotation for halo
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    // Champagne bubbles animation
    _bubblesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Secondary subtle tactile response
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bubblesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final badge = widget.progress.badge;
    final tierColor = badge.tier.color;
    final items = widget.progress.contributingItems;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background Card with Velvet Burgundy sommelier styling
          Container(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF221124),
                  Color(0xFF140A17),
                  Color(0xFF1C0D1F),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: tierColor.withValues(alpha: 0.65),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: tierColor.withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Animated Champagne Micro-Bubbles
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _bubblesController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ChampagneBubblesPainter(
                            progress: _bubblesController.value,
                            tintColor: tierColor,
                          ),
                        );
                      },
                    ),
                  ),

                  // Content Area
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sommelier Ribbon Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                tierColor.withValues(alpha: 0.3),
                                tierColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tierColor.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 14, color: tierColor),
                              const SizedBox(width: 6),
                              Text(
                                '✦ DISTINCTION DÉBLOQUÉE ✦',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: tierColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Medallion with rotating golden halo
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Rotating soft aura
                              RotationTransition(
                                turns: _rotationController,
                                child: Container(
                                  width: 154,
                                  height: 154,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        tierColor.withValues(alpha: 0.0),
                                        tierColor.withValues(alpha: 0.45),
                                        tierColor.withValues(alpha: 0.0),
                                        tierColor.withValues(alpha: 0.55),
                                        tierColor.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Physical 3D Medallion
                              Container(
                                width: 136,
                                height: 136,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: tierColor,
                                    width: 3.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: tierColor.withValues(alpha: 0.45),
                                      blurRadius: 22,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: badge.assetImagePath != null
                                      ? Image.asset(
                                          badge.assetImagePath!,
                                          width: 136,
                                          height: 136,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(badge.emoji, style: const TextStyle(fontSize: 60)),
                                          ),
                                        )
                                      : Center(
                                          child: Text(badge.emoji, style: const TextStyle(fontSize: 60)),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          badge.localizedTitle(context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Category & Tier pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badge.category.label(context),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'Rang ${badge.tier.label(context)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tierColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Objective reached notice
                        Text(
                          badge.localizedDescription(context),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contributing Wine / Flacon Callout (Zero-bloat)
                        if (items.isNotEmpty) ...[
                          _buildContributingSection(context, items, tierColor),
                          const SizedBox(height: 16),
                        ],

                        // Le Mot du Chatmelier Quote Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.format_quote, color: Color(0xFFE5C158), size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      l10n?.badgesChatmelierLoreTitle ?? 'Le Mot du Chatmelier',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE5C158),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                badge.localizedLore(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Video ceremony button
                        SizedBox(
                          width: double.infinity,
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          children: [
                            // Gallery button
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.push('/badges');
                                },
                                child: const Text(
                                  'Galerie',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Primary celebration dismiss
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: tierColor,
                                  foregroundColor: tierColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Merveilleux !',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Opt-out option
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            await BadgeUnlockTracker.setAnimationsEnabled(false);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFr
                                        ? 'Animations désactivées. Vous pouvez les réactiver à tout moment dans Réglages.'
                                        : 'Celebration animations disabled. You can re-enable them anytime in Settings.',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          child: Text(
                            isFr ? 'Ne plus afficher ces animations' : 'Don\'t show these animations again',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributingSection(
    BuildContext context,
    List<ContributingItem> items,
    Color tierColor,
  ) {
    final firstItem = items.first;
    final totalCount = items.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    firstItem.isTasting ? Icons.wine_bar : Icons.liquor,
                    size: 18,
                    color: tierColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalCount == 1
                            ? 'Débloqué grâce à ce flacon :'
                            : 'Débloqué grâce à vos flacons ($totalCount) :',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        firstItem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        firstItem.displaySubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // If more than 1 item, show sleek zero-bloat expander
          if (totalCount > 1) ...[
            const Divider(height: 1, color: Colors.white12),
            InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              onTap: () {
                setState(() {
                  _showContributingList = !_showContributingList;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showContributingList
                          ? 'Masquer la liste'
                          : '+ ${totalCount - 1} autre${totalCount - 1 > 1 ? 's' : ''} flacon${totalCount - 1 > 1 ? 's' : ''}...',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: tierColor,
                      ),
                    ),
                    Icon(
                      _showContributingList ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: tierColor,
                    ),
                  ],
                ),
              ),
            ),
            if (_showContributingList)
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: items.skip(1).length,
                  separatorBuilder: (_, __) => const Divider(height: 8, color: Colors.white10),
                  itemBuilder: (context, idx) {
                    final item = items[idx + 1];
                    return Row(
                      children: [
                        Icon(
                          item.isTasting ? Icons.wine_bar : Icons.check_circle_outline,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                        if (item.vintage != null && item.vintage! > 0)
                          Text(
                            '${item.vintage}',
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter rendering rising golden champagne micro-bubbles.
class _ChampagneBubblesPainter extends CustomPainter {
  final double progress;
  final Color tintColor;

  static final List<_BubbleSpec> _specs = List.generate(28, (i) {
    final rand = math.Random(i * 997);
    return _BubbleSpec(
      relX: rand.nextDouble(),
      speed: 0.6 + rand.nextDouble() * 0.9,
      radius: 1.5 + rand.nextDouble() * 2.8,
      wobbleOffset: rand.nextDouble() * math.pi * 2,
      baseOpacity: 0.25 + rand.nextDouble() * 0.45,
    );
  });

  _ChampagneBubblesPainter({
    required this.progress,
    required this.tintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final spec in _specs) {
      // Calculate vertical position (rising from bottom to top)
      final yCycle = (1.0 - ((progress * spec.speed) % 1.0));
      final y = yCycle * size.height;

      // Subtle horizontal sway like effervescence in a flute
      final sway = math.sin((progress * 4.0) + spec.wobbleOffset) * 6.0;
      final x = (spec.relX * size.width) + sway;

      // Fade in near bottom, fade out near top
      final fade = math.sin(yCycle * math.pi);
      final opacity = (spec.baseOpacity * fade).clamp(0.0, 1.0);

      paint.color = tintColor.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), spec.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChampagneBubblesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.tintColor != tintColor;
  }
}

class _BubbleSpec {
  final double relX;
  final double speed;
  final double radius;
  final double wobbleOffset;
  final double baseOpacity;

  const _BubbleSpec({
    required this.relX,
    required this.speed,
    required this.radius,
    required this.wobbleOffset,
    required this.baseOpacity,
  });
}
