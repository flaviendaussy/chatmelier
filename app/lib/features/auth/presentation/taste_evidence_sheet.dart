import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/taste_evidence.dart';

/// Montre ce qui a construit le profil de goût, dans l'ordre où c'est arrivé.
///
/// Le registre existait déjà et n'était lisible nulle part — c'est le défaut qu'on a
/// rencontré trois fois dans ce dépôt : une fonctionnalité complète et inerte. Tracer
/// pourquoi le modèle pense ce qu'il pense ne sert à rien si personne ne peut le lire.
Future<void> showTasteEvidenceSheet(BuildContext context) async {
  final registre = await TasteEvidenceLedger.ouvrir();
  final entrees = registre.lire();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _TasteEvidenceContent(entrees: entrees),
  );
}

class _TasteEvidenceContent extends StatelessWidget {
  final List<TasteEvidenceEntry> entrees;
  const _TasteEvidenceContent({required this.entrees});

  /// Un libellé lisible pour une cible technique (`region:Jura`, `axe:acidity`).
  static ({String icone, String libelle}) _cible(String brut) {
    final sep = brut.indexOf(':');
    final type = sep > 0 ? brut.substring(0, sep) : brut;
    final valeur = sep > 0 ? brut.substring(sep + 1) : brut;
    return switch (type) {
      'region' => (icone: '📍', libelle: valeur),
      'cepage' => (icone: '🍇', libelle: valeur),
      'axe' => (icone: '📈', libelle: _axe(valeur)),
      _ => (icone: '•', libelle: valeur),
    };
  }

  static String _axe(String cle) => switch (cle) {
        'acidity' => 'Acidité',
        'body' => 'Corps',
        'tannin' => 'Tanins',
        'oak' => 'Boisé',
        'ripeFruit' => 'Fruit mûr',
        'spice' => 'Épices',
        'freshFruit' => 'Fruit frais',
        'minerality' => 'Minéralité',
        _ => cle,
      };

  static String _source(String s) => switch (s) {
        'degustation' => 'Dégustation',
        'gorgee' => 'Gorgée',
        'rachat' => 'Rachat',
        'cave' => 'Cave',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFF8B1E3F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.tasteEvidenceTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (entrees.isEmpty)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  l10n.tasteEvidenceEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: entrees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                  itemBuilder: (ctx, i) {
                    final e = entrees[i];
                    final c = _cible(e.cible);
                    return ListTile(
                      dense: true,
                      leading: Text(c.icone, style: const TextStyle(fontSize: 18)),
                      title: Text(
                        c.libelle,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.effet, style: const TextStyle(fontSize: 12)),
                          if (e.vin != null)
                            Text(
                              e.vin!,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '${_source(e.source)}\n'
                        '${e.quand.day}/${e.quand.month}/${e.quand.year}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.3),
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
