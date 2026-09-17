import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feedback_history_service.dart';

/// Ce que la personne a envoyé, et de quoi le retirer.
///
/// Un rapport part d'un geste impulsif : on secoue son téléphone et on joint une capture
/// de ce qu'on avait sous les yeux. Sans cet écran, ce qui est parti est parti — y compris
/// la capture, qui peut montrer plus que prévu.
class MesRetoursSheet extends ConsumerWidget {
  const MesRetoursSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const MesRetoursSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final retoursAsync = ref.watch(mesRetoursProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                isFr ? 'Mes retours envoyés' : 'My sent reports',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: retoursAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(isFr
                      ? 'Vos retours n\'ont pas pu être chargés. Réessayez une fois connecté.'
                      : 'Your reports could not be loaded. Try again once online.'),
                ),
                data: (retours) {
                  if (retours.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: Text(
                        isFr
                            ? 'Vous n\'avez encore envoyé aucun retour.'
                            : 'You haven\'t sent any reports yet.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: retours.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) =>
                        _Ligne(retour: retours[i], isFr: isFr),
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

class _Ligne extends ConsumerStatefulWidget {
  final RetourEnvoye retour;
  final bool isFr;
  const _Ligne({required this.retour, required this.isFr});

  @override
  ConsumerState<_Ligne> createState() => _LigneState();
}

class _LigneState extends ConsumerState<_Ligne> {
  bool _enCours = false;

  Future<void> _retirer() async {
    final isFr = widget.isFr;
    final avecCapture = widget.retour.capture != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isFr ? 'Retirer ce retour ?' : 'Withdraw this report?'),
        content: Text(isFr
            ? (avecCapture
                ? 'Votre message et la capture d\'écran jointe seront supprimés.'
                : 'Votre message sera supprimé.')
            : (avecCapture
                ? 'Your message and the attached screenshot will be deleted.'
                : 'Your message will be deleted.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isFr ? 'Retirer' : 'Withdraw'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _enCours = true);
    final reussi = await ref
        .read(feedbackHistoryServiceProvider)
        .retirer(widget.retour);
    if (!mounted) return;
    setState(() => _enCours = false);
    if (reussi) {
      ref.invalidate(mesRetoursProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isFr
            ? 'Le retrait n\'a pas abouti. Réessayez une fois connecté.'
            : 'The withdrawal did not go through. Try again once online.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.retour;
    final isFr = widget.isFr;
    final d = r.quand.toLocal();
    final date = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';

    return ListTile(
      title: Text(
        r.commentaire,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        r.capture != null
            ? (isFr ? '$date · capture jointe' : '$date · screenshot attached')
            : date,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: _enCours
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: isFr ? 'Retirer ce retour' : 'Withdraw this report',
              onPressed: _retirer,
            ),
    );
  }
}
