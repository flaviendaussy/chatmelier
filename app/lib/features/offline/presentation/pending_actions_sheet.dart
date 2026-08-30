import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/offline_action.dart';
import 'sync_provider.dart';
import '../../../shared/providers/cellar_provider.dart';

class PendingActionsSheet extends ConsumerStatefulWidget {
  const PendingActionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PendingActionsSheet(),
    );
  }

  @override
  ConsumerState<PendingActionsSheet> createState() => _PendingActionsSheetState();
}

class _PendingActionsSheetState extends ConsumerState<PendingActionsSheet> {
  bool _isProcessing = false;

  String _formatActionType(OfflineActionType type) {
    switch (type) {
      case OfflineActionType.addBottle:
        return 'Ajout de bouteille';
      case OfflineActionType.consumeBottle:
        return 'Dégustation / Sortie';
      case OfflineActionType.updateBottle:
        return 'Modification bouteille';
      case OfflineActionType.updateWine:
        return 'Modification fiche vin';
      case OfflineActionType.deleteBottle:
        return 'Suppression bouteille';
      case OfflineActionType.createCellar:
        return 'Création de cave';
      case OfflineActionType.updateCellar:
        return 'Modification cave';
      case OfflineActionType.moveBottle:
        return 'Déplacement de cave';
    }
  }

  IconData _getActionIcon(OfflineActionType type) {
    switch (type) {
      case OfflineActionType.addBottle:
        return Icons.add_circle_outline;
      case OfflineActionType.consumeBottle:
        return Icons.wine_bar;
      case OfflineActionType.updateBottle:
      case OfflineActionType.updateWine:
        return Icons.edit_outlined;
      case OfflineActionType.deleteBottle:
        return Icons.delete_outline;
      case OfflineActionType.createCellar:
      case OfflineActionType.updateCellar:
        return Icons.home_work_outlined;
      case OfflineActionType.moveBottle:
        return Icons.move_to_inbox_outlined;
    }
  }

  String _getActionDescription(OfflineAction action) {
    final data = action.data;
    if (data.containsKey('wine_name')) return data['wine_name'].toString();
    if (data.containsKey('name')) return data['name'].toString();
    if (data.containsKey('bottle_id')) return 'Bouteille ID: ${data['bottle_id']}';
    return 'Action locale enregistrée';
  }

  Future<void> _syncAll() async {
    setState(() => _isProcessing = true);
    final syncService = ref.read(syncServiceProvider);
    final result = await syncService.processPendingActions();

    // Refresh state
    final storage = ref.read(offlineStorageServiceProvider);
    ref.read(pendingSyncCountProvider.notifier).state = storage.pendingActionCount;
    ref.read(pendingResolutionWinesProvider.notifier).state = storage.getPendingResolutionWines();

    ref.invalidate(userCellarsProvider);
    final currentCellarId = ref.read(currentCellarIdProvider);
    if (currentCellarId != null) {
      ref.invalidate(bottlesProvider(currentCellarId));
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${result.errors.length} erreur(s) lors de la synchronisation'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (result.succeeded > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ ${result.succeeded} action(s) synchronisée(s) !'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteAction(String actionId) async {
    final storage = ref.read(offlineStorageServiceProvider);
    await storage.removeAction(actionId);
    ref.read(pendingSyncCountProvider.notifier).state = storage.pendingActionCount;
    setState(() {});
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la file d\'attente ?'),
        content: const Text(
          'Les actions hors-ligne non synchronisées seront définitivement supprimées de la mémoire locale.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = ref.read(offlineStorageServiceProvider);
      final queue = storage.getQueue();
      for (final a in queue) {
        await storage.removeAction(a.id);
      }
      ref.read(pendingSyncCountProvider.notifier).state = 0;
      if (mounted) {
        setState(() {});
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storage = ref.watch(offlineStorageServiceProvider);
    final queue = storage.getQueue();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
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
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_sync, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions en attente',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${queue.length} action${queue.length > 1 ? 's' : ''} dans la file locale',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (queue.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                    label: const Text('Vider', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions List
          if (queue.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  Text(
                    'File de synchronisation vide',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toutes vos modifications sont à jour sur le serveur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shrinkWrap: true,
                itemCount: queue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final action = queue[i];
                  final isFailed = action.status == OfflineActionStatus.failed;
                  final isSyncing = action.status == OfflineActionStatus.syncing;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFailed
                          ? Colors.red.withValues(alpha: 0.08)
                          : (isDark ? const Color(0xFF2A2A3C) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFailed
                            ? Colors.redAccent.withValues(alpha: 0.4)
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getActionIcon(action.type),
                          size: 24,
                          color: isFailed ? Colors.redAccent : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _formatActionType(action.type),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('HH:mm - d MMM', 'fr_FR').format(action.createdAt),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _getActionDescription(action),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              if (isFailed && action.errorMessage != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          action.errorMessage!,
                                          style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSyncing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                            tooltip: 'Supprimer cette action',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteAction(action.id),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Bottom Sync Action Button
          if (queue.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _syncAll,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      _isProcessing ? 'Synchronisation en cours...' : 'Synchroniser maintenant (${queue.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
