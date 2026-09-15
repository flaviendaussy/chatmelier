import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/badge.dart';
import '../data/badges_provider.dart';
import '../data/badge_unlock_tracker.dart';
import 'badge_unlock_celebration_dialog.dart';

class BadgesGalleryPage extends StatelessWidget {
  const BadgesGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        bottom: false,
        child: BadgesGallerySheet(isPage: true),
      ),
    );
  }
}

class BadgesGallerySheet extends ConsumerStatefulWidget {
  final bool isPage;
  const BadgesGallerySheet({super.key, this.isPage = false});

  static Future<void> show(BuildContext context) async {
    context.push('/badges');
  }

  @override
  ConsumerState<BadgesGallerySheet> createState() => _BadgesGallerySheetState();
}

class _BadgesGallerySheetState extends ConsumerState<BadgesGallerySheet> {
  BadgeCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BadgeUnlockTracker.checkAndCelebrateNewUnlocks(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final allBadges = ref.watch(userBadgesProgressProvider);
    final stats = ref.watch(unlockedBadgesCountProvider);

    final filteredBadges = _selectedCategory == null
        ? allBadges
        : allBadges.where((b) => b.badge.category == _selectedCategory).toList();

    final pct = stats.total > 0 ? (stats.unlocked / stats.total) : 0.0;

    return Container(
      height: widget.isPage ? double.infinity : MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1522) : Colors.white,
        borderRadius: widget.isPage ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle (sheet only)
          if (!widget.isPage)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: widget.isPage ? 14 : 8,
            ),
            child: Row(
              children: [
                if (widget.isPage) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emoji_events, color: Color(0xFFD4AF37), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.badgesGalleryTitle ?? 'Galerie des Trophées',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.badgesGallerySubtitle(stats.unlocked, stats.total, (pct * 100).toInt()) ??
                            '${stats.unlocked} / ${stats.total} débloqués • ${(pct * 100).toInt()}% accomplis',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isPage)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                color: const Color(0xFFD4AF37),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category filter chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${l10n?.badgesFilterAll ?? 'Tous'} (${stats.total})'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                    selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF8B1E3F),
                  ),
                ),
                ...BadgeCategory.values.map((cat) {
                  final count = allBadges.where((b) => b.badge.category == cat).length;
                  final unlockedCat = allBadges.where((b) => b.badge.category == cat && b.isUnlocked).length;
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(cat.icon, size: 16),
                      label: Text('${cat.label(context)} ($unlockedCat/$count)'),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF8B1E3F),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 20),

          // Badges Grid
          Expanded(
            child: filteredBadges.isEmpty
                ? Center(child: Text(l10n?.badgesEmpty ?? 'Aucun badge trouvé dans cette catégorie.'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredBadges.length,
                    itemBuilder: (context, index) {
                      final item = filteredBadges[index];
                      return _BadgeGridCard(
                        progress: item,
                        onTap: () => _showBadgeDetail(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeProgress progress) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _BadgeDetailModal(progress: progress),
    );
  }
}

class _BadgeGridCard extends StatelessWidget {
  final BadgeProgress progress;
  final VoidCallback onTap;

  const _BadgeGridCard({
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final badge = progress.badge;
    final isUnlocked = progress.isUnlocked;
    final tierColor = badge.tier.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? (isUnlocked ? const Color(0xFF281E32) : const Color(0xFF1E1925))
              : (isUnlocked ? const Color(0xFFFFFBF0) : const Color(0xFFF6F5F8)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnlocked ? tierColor.withValues(alpha: 0.8) : Colors.grey.withValues(alpha: 0.25),
            width: isUnlocked ? 2.0 : 1.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: tierColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Tier Tag & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge.tier.label(context).toUpperCase(),
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isUnlocked)
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16)
                else
                  Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 15),
              ],
            ),
            const Spacer(),

            // Emoji or Custom Image
            if (badge.assetImagePath != null)
              ClipOval(
                child: Image.asset(
                  badge.assetImagePath!,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 54,
                      color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              )
            else
              Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 54,
                  color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.4),
                ),
              ),
            const SizedBox(height: 6),

            // Title
            Text(
              badge.localizedTitle(context),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isUnlocked ? null : Colors.grey.shade600,
              ),
            ),
            const Spacer(),

            // Progress or Unlocked chip
            if (isUnlocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n?.badgesUnlockedChip ?? 'Débloqué ✨',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.progressFraction,
                  minHeight: 5,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  color: tierColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${progress.currentCount} / ${badge.requiredCount}',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeDetailModal extends StatelessWidget {
  final BadgeProgress progress;

  const _BadgeDetailModal({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final badge = progress.badge;
    final tierColor = badge.tier.color;
    final isUnlocked = progress.isUnlocked;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF221A2B) : Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scrollable content area
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge Icon Header with Tier ring (Large Hero Showcase)
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tierColor.withValues(alpha: 0.15),
                          border: Border.all(color: tierColor, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: tierColor.withValues(alpha: isUnlocked ? 0.40 : 0.20),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: badge.assetImagePath != null
                            ? ClipOval(
                                child: Image.asset(
                                  badge.assetImagePath!,
                                  width: 128,
                                  height: 128,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    badge.emoji,
                                    style: const TextStyle(fontSize: 68),
                                  ),
                                ),
                              )
                            : Text(
                                badge.emoji,
                                style: const TextStyle(fontSize: 68),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        badge.localizedTitle(context),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),

                      // Category & Tier pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badge.category.icon, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  badge.category.label(context),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${l10n?.badgesTierLabel ?? 'Rang'} ${badge.tier.label(context)}',
                              style: TextStyle(fontSize: 11, color: tierColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isUnlocked
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : Colors.grey.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUnlocked ? Icons.verified : Icons.lock_clock,
                              color: isUnlocked ? const Color(0xFF10B981) : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUnlocked
                                        ? (l10n?.badgesStatusUnlocked ?? 'Trophée débloqué !')
                                        : (l10n?.badgesStatusInProgress ?? 'En cours d\'obtention'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isUnlocked ? const Color(0xFF10B981) : null,
                                    ),
                                  ),
                                  Text(
                                    '${l10n?.badgesObjectiveLabel ?? 'Objectif :'} ${badge.localizedDescription(context)} (${progress.currentCount} / ${badge.requiredCount})',
                                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lore du Chatmelier
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFFB8860B), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n?.badgesChatmelierLoreTitle ?? 'La Science & l\'Histoire du Chatmelier',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB8860B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              badge.localizedLore(context),
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF3E2723),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Flacons & Dégustations ayant contribué (Zero Bloat)
                      if (progress.contributingItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildContributingSection(context, progress, isDark),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Voir la cérémonie vidéo du Chatmelier
              SizedBox(
                width: double.infinity,
              ),
              const SizedBox(height: 8),

              // Revoir la célébration (unlocked badges)
              if (isUnlocked) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFD4AF37)),
                    label: const Text(
                      'Revoir la célébration 🏆',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      BadgeUnlockCelebrationDialog.show(context, progress);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Close Button (always accessible)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E3F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n?.badgesCloseButton ?? 'Fermer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributingSection(BuildContext context, BadgeProgress progress, bool isDark) {
    final items = progress.contributingItems;
    final total = items.length;
    final displayedItems = items.take(3).toList();
    final remaining = total - displayedItems.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wine_bar, size: 18, color: Color(0xFF8B1E3F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Flacons associés ($total)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            progress.isUnlocked
                ? 'Flacons ayant permis de débloquer cette distinction :'
                : 'Flacons ayant déjà contribué à cet objectif :',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),

          // Render top items
          ...displayedItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.isTasting ? Icons.wine_bar : Icons.liquor,
                        size: 16,
                        color: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.displaySubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.rating != null && item.rating! > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 2),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )),

          // Expand / View All button if > 3 items (prevents bloat for 500 wines!)
          if (remaining > 0) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF8B1E3F),
                ),
                icon: const Icon(Icons.format_list_bulleted, size: 15),
                label: Text(
                  '+ $remaining autre${remaining > 1 ? 's' : ''} flacon${remaining > 1 ? 's' : ''} (Voir tout)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showAllContributingSheet(context, progress),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllContributingSheet(BuildContext context, BadgeProgress progress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AllContributingItemsModal(progress: progress),
    );
  }
}

/// Dedicated scrollable and searchable bottom sheet for badges with many contributing bottles (up to 500)
class _AllContributingItemsModal extends StatefulWidget {
  final BadgeProgress progress;

  const _AllContributingItemsModal({required this.progress});

  @override
  State<_AllContributingItemsModal> createState() => _AllContributingItemsModalState();
}

class _AllContributingItemsModalState extends State<_AllContributingItemsModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allItems = widget.progress.contributingItems;
    final badge = widget.progress.badge;

    final filtered = _searchQuery.trim().isEmpty
        ? allItems
        : allItems.where((i) {
            final q = _searchQuery.toLowerCase();
            return i.name.toLowerCase().contains(q) ||
                (i.producer ?? '').toLowerCase().contains(q) ||
                (i.appellation ?? '').toLowerCase().contains(q) ||
                (i.region ?? '').toLowerCase().contains(q) ||
                (i.vintage?.toString().contains(q) ?? false);
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1728) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flacons associés (${allItems.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        badge.localizedTitle(context),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search input if > 8 items
          if (allItems.length > 8)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Rechercher un flacon, producteur, millésime...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          const Divider(height: 16),

          // Virtualized scrollable list for zero-bloat performance (up to 500 wines)
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun flacon ne correspond à la recherche.',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.isTasting ? Icons.wine_bar : Icons.liquor,
                            size: 20,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          item.displaySubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        trailing: item.rating != null && item.rating! > 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: Color(0xFFD4AF37)),
                                  const SizedBox(width: 2),
                                  Text(
                                    item.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Compact Showcase Card for the Profile Screen
class BadgesShowcaseCard extends ConsumerWidget {
  const BadgesShowcaseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final allBadges = ref.watch(userBadgesProgressProvider);
    final stats = ref.watch(unlockedBadgesCountProvider);

    // Pick top unlocked badges or next to unlock
    final unlocked = allBadges.where((b) => b.isUnlocked).toList();
    final inProgress = allBadges.where((b) => !b.isUnlocked).toList();

    final previewList = unlocked.isNotEmpty
        ? unlocked.take(5).toList()
        : inProgress.take(5).toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      color: isDark ? const Color(0xFF221A28) : const Color(0xFFFCF9F5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emoji_events, color: Color(0xFFD4AF37), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.badgesShowcaseTitle ?? 'Trophées & Badges',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        l10n?.badgesShowcaseCount(stats.unlocked, stats.total) ??
                            '${stats.unlocked} sur ${stats.total} débloqués',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => BadgesGallerySheet.show(context),
                  icon: const Icon(Icons.grid_view_rounded, size: 16),
                  label: Text(
                    l10n?.badgesShowcaseGallery ?? 'Galerie',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Horizontal row of top badges
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previewList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final item = previewList[idx];
                  final isUnlocked = item.isUnlocked;
                  return InkWell(
                    onTap: () => BadgesGallerySheet.show(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? item.badge.tier.color.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUnlocked ? item.badge.tier.color : Colors.grey.withValues(alpha: 0.3),
                          width: isUnlocked ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item.badge.assetImagePath != null)
                            ClipOval(
                              child: Image.asset(
                                item.badge.assetImagePath!,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(item.badge.emoji, style: const TextStyle(fontSize: 24)),
                              ),
                            )
                          else
                            Text(item.badge.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 2),
                          Text(
                            item.badge.localizedTitle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? item.badge.tier.color : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
