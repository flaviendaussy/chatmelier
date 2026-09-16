import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/bottle_size.dart';

/// Demande une contenance libre et renvoie son code canonique, ou nul si annulé.
///
/// Demandé par une utilisatrice qui voulait saisir une 20 cl. Les douze formats nommés
/// couvrent le vin de garde, pas les fioles, les pots lyonnais ni les formats de
/// dégustation — et il y en aura toujours un qui manque. Plutôt que d'allonger la liste
/// au fil des demandes, on laisse saisir le volume.
///
/// La saisie est en **centilitres** : c'est l'unité imprimée sur les étiquettes
/// européennes, et c'est dans cette unité que la demande est arrivée. `BottleSize`
/// s'occupe de rendre un format nommé si le volume en correspond à un — taper 75 donne
/// la bouteille standard, pas un doublon anonyme.
Future<String?> showCustomBottleSizeDialog(
  BuildContext context, {
  String? currentCode,
}) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  final actuel = BottleSize.fromCode(currentCode);
  final controller = TextEditingController(
    text: currentCode == null ? '' : (actuel.volumeLiters * 100).toStringAsFixed(0),
  );
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F)),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.bottleSizeCustomTitle)),
        ],
      ),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: InputDecoration(
            labelText: l10n.bottleSizeCustomLabel,
            suffixText: 'cl',
            border: const OutlineInputBorder(),
          ),
          validator: (v) {
            final cl = double.tryParse((v ?? '').replaceAll(',', '.'));
            // Mêmes bornes que `BottleSize` : en dessous de 1 cl ce n'est plus une
            // bouteille, au-dessus de 30 L on dépasse le Melchior.
            if (cl == null || cl < 1 || cl > 3000) return l10n.bottleSizeCustomInvalid;
            return null;
          },
          onFieldSubmitted: (_) {
            if (formKey.currentState?.validate() ?? false) {
              final cl = double.parse(controller.text.replaceAll(',', '.'));
              Navigator.pop(ctx, BottleSize.fromLiters(cl / 100).code);
            }
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              final cl = double.parse(controller.text.replaceAll(',', '.'));
              Navigator.pop(ctx, BottleSize.fromLiters(cl / 100).code);
            }
          },
          child: Text(l10n.add, style: TextStyle(color: theme.colorScheme.onPrimary)),
        ),
      ],
    ),
  );
}
