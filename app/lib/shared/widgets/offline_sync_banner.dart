import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/offline/presentation/sync_provider.dart';
import '../../features/offline/presentation/pending_actions_sheet.dart';
import '../../features/cellar/presentation/vintage_resolution_dialog.dart';
import '../../shared/providers/cellar_provider.dart';

class OfflineSyncBanner extends ConsumerWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final isSyncing = ref.watch(isSyncingStateProvider);
    final pendingResolutions = ref.watch(pendingResolutionWinesProvider);

    if (pendingCount == 0 && pendingResolutions.isEmpty && !isSyncing) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

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
                  : const Color(0xFFD97706).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSyncing
                    ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                    : const Color(0xFFD97706).withValues(alpha: 0.4),
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
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.cloud_off,
                        size: 20,
                        color: Color(0xFFD97706),
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
                              ? 'Synchronisation en cours...'
                              : '$pendingCount action${pendingCount > 1 ? 's' : ''} en attente',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSyncing
                                ? const Color(0xFF1E3A5F)
                                : const Color(0xFF92400E),
                          ),
                        ),
                        if (!isSyncing)
                          const Text(
                            'Appuyez pour voir le détail des actions',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!isSyncing)
                  TextButton(
                    onPressed: () async {
                      ref.read(isSyncingStateProvider.notifier).state = true;
                      final syncService = ref.read(syncServiceProvider);
                      final result = await syncService.processPendingActions();
                      if (!context.mounted) return;
                      ref.read(isSyncingStateProvider.notifier).state = false;

                      // Refresh pending count
                      final storage = ref.read(offlineStorageServiceProvider);
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
                                '✨ ${result.succeeded} action${result.succeeded > 1 ? 's' : ''} synchronisée${result.succeeded > 1 ? 's' : ''} avec succès !',
                              ),
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Synchroniser',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // 2. Pending Vintage Resolution Banner
        if (pendingResolutions.isNotEmpty)
          ...pendingResolutions.map((item) {
            final wineName = item['wine_name'] ?? 'Bouteille ajoutée';
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
                      'Millésime manquant pour "$wineName"',
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
                    child: const Text(
                      'Préciser l\'année',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
