import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../offline/presentation/sync_provider.dart';

class VintageResolutionDialog extends ConsumerStatefulWidget {
  final String wineName;
  final String bottleId;
  final String wineId;

  const VintageResolutionDialog({
    super.key,
    required this.wineName,
    required this.bottleId,
    required this.wineId,
  });

  @override
  ConsumerState<VintageResolutionDialog> createState() => _VintageResolutionDialogState();
}

class _VintageResolutionDialogState extends ConsumerState<VintageResolutionDialog> {
  final _controller = TextEditingController();
  bool _isNonVintage = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vintage = _isNonVintage ? null : int.tryParse(_controller.text.trim());
    if (!_isNonVintage && vintage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une année valide (ex: 2018)')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final repo = ref.read(cellarRepositoryProvider);
    if (vintage != null) {
      await repo.resolveMissingVintage(
        bottleId: widget.bottleId,
        wineId: widget.wineId,
        vintage: vintage,
      );
    } else {
      final storage = ref.read(offlineStorageServiceProvider);
      await storage.removePendingResolutionWine(widget.bottleId);
    }

    final storage = ref.read(offlineStorageServiceProvider);
    ref.read(pendingResolutionWinesProvider.notifier).state =
        storage.getPendingResolutionWines();

    final currentCellarId = ref.read(currentCellarIdProvider);
    if (currentCellarId != null) {
      ref.invalidate(bottlesProvider(currentCellarId));
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vintage != null
                ? '✨ Millésime $vintage enregistré pour ${widget.wineName} !'
                : '✨ Enregistré comme Non-Millésimé pour ${widget.wineName} !',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.wine_bar, color: Color(0xFF8B1E3F)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Préciser le millésime',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              'Cette bouteille a été ajoutée en mode hors-ligne. Veuillez indiquer son année :',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.wineName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isNonVintage)
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'Année / Millésime',
                  hintText: 'ex: 2019',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Non-Millésimé (NV / Sans année)'),
              value: _isNonVintage,
              onChanged: (val) {
                setState(() => _isNonVintage = val ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
