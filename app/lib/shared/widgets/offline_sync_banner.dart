import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/offline/presentation/sync_provider.dart';
import '../../features/offline/presentation/pending_actions_sheet.dart';
import '../../features/offline/domain/offline_action.dart';
import '../../features/cellar/presentation/vintage_resolution_dialog.dart';
import '../../shared/providers/cellar_provider.dart';
import '../utils/langue.dart';

class OfflineSyncBanner extends ConsumerWidget {
  const OfflineSyncBanner({super.key});

  void _showDismissOptions(BuildContext context, WidgetRef ref, int pendingCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Alerte de synchronisation', 'Sync alert')),
        content: Text(
          pendingCount > 1
              ? tr('Il y a {pendingCount} actions hors-ligne enregistrées.\n\nQue souhaitez-vous faire ?', '{pendingCount} actions were saved while offline.\n\nWhat would you like to do?', {'pendingCount': pendingCount})
              : tr('Il y a 1 action hors-ligne enregistrée.\n\nQue souhaitez-vous faire ?',
                  '1 action was saved while offline.\n\nWhat would you like to do?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('Annuler', 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(syncBannerDismissedProvider.notifier).state = true;
              Navigator.of(ctx).pop();
            },
            child: Text(tr('Masquer l\'alerte', 'Hide alert')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              final storage = ref.read(offlineStorageServiceProvider);
              await storage.saveQueue([]);
              ref.read(pendingSyncCountProvider.notifier).state = 0;
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(tr('Tout effacer', 'Clear all'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDismissed = ref.watch(syncBannerDismissedProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final isSyncing = ref.watch(isSyncingStateProvider);
    final pendingResolutions = ref.watch(pendingResolutionWinesProvider);

    if (isDismissed || (pendingCount == 0 && pendingResolutions.isEmpty && !isSyncing)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final storage = ref.watch(offlineStorageServiceProvider);
    final queue = storage.getQueue();
    final hasFailedActions = queue.isNotEmpty && queue.any((a) => a.status == OfflineActionStatus.failed);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Pending Sync Actions Banner
        if (pendingCount > 0 || isSyncing)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSyncing
                  ? const Color(0xFF1E3A5F).withValues(alpha: 0.12)
                  : (hasFailedActions
                      ? Colors.red.shade50
                      : const Color(0xFFD97706).withValues(alpha: 0.14)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSyncing
                    ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                    : (hasFailedActions
                        ? Colors.red.shade300
                        : const Color(0xFFD97706).withValues(alpha: 0.4)),
              ),
            ),
            child: Row(
              children: [
                if (isSyncing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  InkWell(
                    onTap: () => PendingActionsSheet.show(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        hasFailedActions ? Icons.sync_problem : Icons.cloud_off,
                        size: 20,
                        color: hasFailedActions ? Colors.red.shade700 : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => PendingActionsSheet.show(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSyncing
                              ? tr('Synchronisation en cours...', 'Syncing...')
                              : (pendingCount > 1
                                  ? tr('{pendingCount} actions en attente', '{pendingCount} actions waiting', {'pendingCount': pendingCount})
                                  : tr('1 action en attente', '1 action waiting')),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSyncing
                                ? const Color(0xFF1E3A5F)
                                : (hasFailedActions ? Colors.red.shade800 : const Color(0xFF92400E)),
                          ),
                        ),
                        if (!isSyncing)
                          Text(
                            hasFailedActions
                                ? tr('Certaines actions ont échoué. Appuyez pour voir.', 'Some actions failed. Tap to see.')
                                : tr('Appuyez pour voir le détail des actions', 'Tap to see the actions'),
                            style: TextStyle(
                              fontSize: 11,
                              color: hasFailedActions ? Colors.red.shade600 : const Color(0xFFB45309),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!isSyncing) ...[
                  TextButton(
                    onPressed: () async {
                      ref.read(isSyncingStateProvider.notifier).state = true;
                      await storage.retryFailedActions();
                      final syncService = ref.read(syncServiceProvider);
                      final result = await syncService.processPendingActions();
                      if (!context.mounted) return;
                      ref.read(isSyncingStateProvider.notifier).state = false;

                      // Refresh pending count
                      ref.read(pendingSyncCountProvider.notifier).state =
                          storage.pendingActionCount;
                      ref.read(pendingResolutionWinesProvider.notifier).state =
                          storage.getPendingResolutionWines();

                      // Invalidate bottles & cellars
                      ref.invalidate(userCellarsProvider);
                      final currentCellarId = ref.read(currentCellarIdProvider);
                      if (currentCellarId != null) {
                        ref.invalidate(bottlesProvider(currentCellarId));
                      }

                      if (context.mounted) {
                        if (result.errors.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.errors.first),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } else if (result.succeeded > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.succeeded > 1
                                    ? tr('✨ {succeeded} actions synchronisées avec succès !', '✨ {succeeded} actions synced!', {'succeeded': result.succeeded})
                                    : tr('✨ 1 action synchronisée avec succès !', '✨ 1 action synced!'),
                              ),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      tr('Synchroniser', 'Sync'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: tr('Masquer l\'alerte', 'Hide alert'),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    color: Colors.grey.shade600,
                    onPressed: () => _showDismissOptions(context, ref, pendingCount),
                  ),
                ],
              ],
            ),
          ),

        // 2. Pending Vintage Resolution Banner
        if (pendingResolutions.isNotEmpty)
          ...pendingResolutions.map((item) {
            final wineName = item['wine_name'] ?? tr('Bouteille ajoutée', 'Added bottle');
            final bottleId = item['bottle_id'] as String;
            final wineId = item['wine_id'] as String;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6B21A8).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 20,
                    color: Color(0xFF6B21A8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('Millésime manquant pour "{wineName}"', 'Vintage missing for "{wineName}"', {'wineName': wineName}),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF581C87),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => VintageResolutionDialog(
                          wineName: wineName,
                          bottleId: bottleId,
                          wineId: wineId,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      tr('Préciser l\'année', 'Add the year'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: tr('Masquer', 'Hide'),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    color: const Color(0xFF581C87),
                    onPressed: () async {
                      await storage.removePendingResolutionWine(bottleId);
                      ref.read(pendingResolutionWinesProvider.notifier).state =
                          storage.getPendingResolutionWines();
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
