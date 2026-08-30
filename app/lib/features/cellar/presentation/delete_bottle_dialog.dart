import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/bottle.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../l10n/app_localizations.dart';

class DeleteBottleDialog extends ConsumerStatefulWidget {
  final Bottle bottle;
  final String cellarId;
  final VoidCallback? onDeleted;

  const DeleteBottleDialog({
    super.key,
    required this.bottle,
    required this.cellarId,
    this.onDeleted,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Bottle bottle,
    required String cellarId,
    VoidCallback? onDeleted,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteBottleDialog(
        bottle: bottle,
        cellarId: cellarId,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  ConsumerState<DeleteBottleDialog> createState() => _DeleteBottleDialogState();
}

class _DeleteBottleDialogState extends ConsumerState<DeleteBottleDialog> {
  late int _quantityToDelete;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _quantityToDelete = widget.bottle.quantity;
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    final repo = ref.read(cellarRepositoryProvider);

    try {
      await repo.deleteBottlePermanently(
        bottleId: widget.bottle.id,
        cellarId: widget.cellarId,
        quantityToRemove: _quantityToDelete,
      );

      // Invalidate bottle provider
      notifyCellarChanged(ref, widget.cellarId);

      if (mounted) {
        widget.onDeleted?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _quantityToDelete >= widget.bottle.quantity
                  ? '🗑️ Bouteille supprimée définitivement de la cave.'
                  : '🗑️ $_quantityToDelete bouteille(s) supprimée(s) définitivement.',
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final wine = widget.bottle.wine;
    final wineTitle = '${wine?.name ?? "Vin"} ${wine?.vintage != null ? "(${wine!.vintage})" : ""}';
    final totalQty = widget.bottle.quantity;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n?.deleteBottleTitle ?? 'Supprimer définitivement',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              wineTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B1E3F),
              ),
            ),
            const SizedBox(height: 14),

            // Alert explanation box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Attention : Action irréversible',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'La suppression efface toute trace de cette bouteille sans conserver d\'historique.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Educational Distinction: Sortir vs Supprimer
            Text(
              '💡 Quelle est la différence ?',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Card 1: Sortir / Boire
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E3F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🍷', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sortir / Boire (Recommandé)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8B1E3F)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Archive la dégustation dans votre Journal, met à jour vos Statistiques et conserve vos notes.',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card 2: Supprimer définitivement
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🗑️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Supprimer définitivement',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Efface complètement la fiche (à utiliser en cas d\'erreur de saisie, doublon ou bouteille cassée).',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quantity selector if totalQty > 1
            if (totalQty > 1) ...[
              Text(
                'Quantité à supprimer ($totalQty au total en cave) :',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantityToDelete > 1
                        ? () => setState(() => _quantityToDelete--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_quantityToDelete / $totalQty',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: _quantityToDelete < totalQty
                        ? () => setState(() => _quantityToDelete++)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _quantityToDelete = totalQty),
                    child: const Text('Tout'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        // "Sortir / Boire plutôt" button
        OutlinedButton.icon(
          onPressed: _isDeleting
              ? null
              : () {
                  Navigator.of(context).pop(false);
                  context.push('/checkout?bottleId=${widget.bottle.id}');
                },
          icon: const Icon(Icons.wine_bar, size: 16, color: Color(0xFF8B1E3F)),
          label: const Text('Boire plutôt', style: TextStyle(color: Color(0xFF8B1E3F))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF8B1E3F)),
          ),
        ),

        // Confirm Delete button
        FilledButton.icon(
          onPressed: _isDeleting ? null : _handleDelete,
          icon: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.delete_forever, size: 18),
          label: Text(_isDeleting ? 'Suppression...' : 'Supprimer'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
