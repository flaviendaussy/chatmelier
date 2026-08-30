import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/scratchcard_repository.dart';
import '../domain/terroir_node.dart';

final selectedGranularityProvider = StateProvider<TerroirLevel>((ref) => TerroirLevel.region);

class ScratchcardScreen extends ConsumerWidget {
  const ScratchcardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final selectedLevel = ref.watch(selectedGranularityProvider);
    final terroirsAsync = ref.watch(unlockedTerroirsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.scratchcardTitle ?? 'Carte à Gratter des Terroirs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<TerroirLevel>(
                segments: const [
                  ButtonSegment<TerroirLevel>(
                    value: TerroirLevel.continent,
                    icon: Icon(Icons.public, size: 16),
                    label: Text('Continents'),
                  ),
                  ButtonSegment<TerroirLevel>(
                    value: TerroirLevel.country,
                    icon: Icon(Icons.flag, size: 16),
                    label: Text('Pays'),
                  ),
                  ButtonSegment<TerroirLevel>(
                    value: TerroirLevel.region,
                    icon: Icon(Icons.terrain, size: 16),
                    label: Text('Régions'),
                  ),
                  ButtonSegment<TerroirLevel>(
                    value: TerroirLevel.appellation,
                    icon: Icon(Icons.wine_bar, size: 16),
                    label: Text('Appellations'),
                  ),
                ],
                selected: {selectedLevel},
                onSelectionChanged: (Set<TerroirLevel> newSelection) {
                  ref.read(selectedGranularityProvider.notifier).state = newSelection.first;
                },
              ),
            ),
          ),
        ),
      ),
      body: terroirsAsync.when(
        data: (allNodes) {
          final filteredNodes = allNodes.where((n) => n.level == selectedLevel).toList();
          final unlockedCount = filteredNodes.where((n) => n.isUnlocked).length;
          final totalCount = filteredNodes.length;
          final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

          return CustomScrollView(
            slivers: [
              // Progress Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.military_tech, color: Colors.amber, size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Exploration des ${_getLevelLabel(selectedLevel)}',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                '$unlockedCount / $totalCount',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(progress * 100).toInt()}% du monde viticole exploré dans votre cave !',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Grid of Scratch Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final node = filteredNodes[index];
                      return _TerroirScratchCard(node: node);
                    },
                    childCount: filteredNodes.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  String _getLevelLabel(TerroirLevel level) {
    switch (level) {
      case TerroirLevel.continent:
        return 'Continents';
      case TerroirLevel.country:
        return 'Pays';
      case TerroirLevel.region:
        return 'Régions Viticoles';
      case TerroirLevel.appellation:
        return 'Grandes Appellations';
    }
  }
}

class _TerroirScratchCard extends StatefulWidget {
  final TerroirNode node;

  const _TerroirScratchCard({required this.node});

  @override
  State<_TerroirScratchCard> createState() => _TerroirScratchCardState();
}

class _TerroirScratchCardState extends State<_TerroirScratchCard> {
  bool _revealedManually = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRevealed = widget.node.isUnlocked || _revealedManually;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRevealed
            ? BorderSide(color: Colors.amber.shade700, width: 1.5)
            : BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      elevation: isRevealed ? 4 : 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!isRevealed) {
            setState(() {
              _revealedManually = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✨ Terroir découvert : ${widget.node.name} !'),
                duration: const Duration(seconds: 1),
              ),
            );
          } else {
            _showTerroirModal(context, widget.node);
          }
        },
        child: isRevealed ? _buildUnlockedContent(theme) : _buildScratchFoilContent(theme),
      ),
    );
  }

  Widget _buildScratchFoilContent(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade700,
            Colors.grey.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.touch_app, color: Colors.amber, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            widget.node.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '✨ Toucher pour gratter',
              style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedContent(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.node.flagEmoji,
                style: const TextStyle(fontSize: 22),
              ),
              if (widget.node.tastedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wine_bar, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.node.tastedCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            widget.node.name,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.node.parentName != null)
            Text(
              widget.node.parentName!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 11),
            ),
          const SizedBox(height: 4),
          Text(
            widget.node.description,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showTerroirModal(BuildContext context, TerroirNode node) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(node.flagEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (node.parentName != null)
                          Text(
                            node.parentName!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                node.description,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Bouteilles dégustées ou en cave :',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (node.bottleNames.isNotEmpty)
                ...node.bottleNames.map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  'Aucune bouteille enregistrée pour ce terroir pour l\'instant.',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
