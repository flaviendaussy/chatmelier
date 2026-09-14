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

  Future<void> _submit(bool isFr) async {
    final vintage = _isNonVintage ? null : int.tryParse(_controller.text.trim());
    if (!_isNonVintage && vintage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFr ? 'Veuillez saisir une année valide (ex: 2018)' : 'Please enter a valid year (e.g. 2018)')),
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
                ? (isFr ? '✨ Millésime $vintage enregistré pour ${widget.wineName} !' : '✨ Vintage $vintage saved for ${widget.wineName}!')
                : (isFr ? '✨ Enregistré comme Non-Millésimé pour ${widget.wineName} !' : '✨ Saved as Non-Vintage for ${widget.wineName}!'),
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isFr ? 'Préciser le millésime' : 'Specify vintage',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              isFr
                  ? 'Cette bouteille a été ajoutée en mode hors-ligne. Veuillez indiquer son année :'
                  : 'This bottle was added in offline mode. Please indicate its vintage year:',
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
                decoration: InputDecoration(
                  labelText: isFr ? 'Année / Millésime' : 'Year / Vintage',
                  hintText: 'ex: 2019',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isFr ? 'Non-Millésimé (NV / Sans année)' : 'Non-Vintage (NV / No year)'),
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
          child: Text(isFr ? 'Plus tard' : 'Later'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : () => _submit(isFr),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isFr ? 'Enregistrer' : 'Save'),
        ),
      ],
    );
  }
}
