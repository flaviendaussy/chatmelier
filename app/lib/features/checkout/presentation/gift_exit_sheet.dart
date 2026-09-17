import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../cellar/domain/bottle.dart';
import '../../offline/domain/offline_action.dart';
import '../../offline/presentation/sync_provider.dart';
import '../data/post_tasting_notification_service.dart';
import '../domain/gift_exit.dart';

/// Offrir une bouteille : la sortir de la cave sans prétendre l'avoir bue.
///
/// Écran délibérément court. Sortir une bouteille pour la boire demande une note, des
/// convives, des arômes ; l'offrir demande un nom et une décision. Réutiliser l'écran de
/// dégustation aurait imposé le premier formulaire à la seconde intention — c'est ce qui
/// se passait jusqu'ici, et la note inventée partait nourrir le profil de goût.
class GiftExitSheet extends ConsumerStatefulWidget {
  final Bottle bottle;
  final String wineName;
  final int? vintage;
  final String? producer;
  final String? region;
  final String? wineType;

  const GiftExitSheet({
    super.key,
    required this.bottle,
    required this.wineName,
    this.vintage,
    this.producer,
    this.region,
    this.wineType,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Bottle bottle,
    required String wineName,
    int? vintage,
    String? producer,
    String? region,
    String? wineType,
  }) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GiftExitSheet(
            bottle: bottle,
            wineName: wineName,
            vintage: vintage,
            producer: producer,
            region: region,
            wineType: wineType,
          ),
        ),
      );

  @override
  ConsumerState<GiftExitSheet> createState() => _GiftExitSheetState();
}

class _GiftExitSheetState extends ConsumerState<GiftExitSheet> {
  final _destinataire = TextEditingController();
  SuiteDuCadeau _suite = SuiteDuCadeau.aucuneSuite;
  int _quantite = 1;
  bool _enCours = false;

  @override
  void dispose() {
    _destinataire.dispose();
    super.dispose();
  }

  Future<void> _offrir() async {
    final sortie = SortieCadeau(
      destinataire: _destinataire.text.trim(),
      quantite: _quantite,
      suite: _suite,
    );
    if (!sortie.valide) return;
    setState(() => _enCours = true);

    final supabase = ref.read(supabaseProvider);
    final offline = ref.read(offlineStorageServiceProvider);
    final restant = widget.bottle.quantity - sortie.quantite;

    // Une quantité restante garde la ligne en cave ; le dernier exemplaire la fait passer
    // au statut « offerte ». `gifted_at` et non `consumed_at` : elle n'a pas été bue.
    final maj = restant > 0
        ? <String, dynamic>{'quantity': restant}
        : <String, dynamic>{
            'quantity': 0,
            'status': 'gifted',
            'gifted_to': sortie.destinataire,
            'gifted_at': DateTime.now().toIso8601String(),
          };

    var enLigne = false;
    try {
      await supabase.from('bottles').update(maj).eq('id', widget.bottle.id);
      enLigne = true;
    } catch (e) {
      AppLogger.warning('CADEAU', 'Écriture distante impossible: $e');
    }
    if (!enLigne) {
      await offline.queueAction(OfflineAction(
        type: OfflineActionType.updateBottle,
        cellarId: widget.bottle.cellarId,
        status: OfflineActionStatus.pending,
        data: {'bottle_id': widget.bottle.id, ...maj},
        createdAt: DateTime.now(),
      ));
    }

    // Aucun appel au profil de goût, ici ni ailleurs : offrir n'apprend rien sur son
    // propre palais. C'est le pendant exact de l'exclusion des bouteilles REÇUES en
    // cadeau, que le modèle comptait jusqu'ici comme des préférences.

    if (sortie.suite == SuiteDuCadeau.redemanderPlusTard) {
      try {
        await ref.read(postTastingNotificationProvider).schedulePostCheckout(
              bottleId: widget.bottle.id,
              wineName: widget.wineName,
              vintage: widget.vintage,
              producer: widget.producer,
              region: widget.region,
              wineType: widget.wineType,
              delayAfterCheckout: SortieCadeau.delaiDeRelance,
            );
      } catch (e) {
        AppLogger.warning('CADEAU', 'Relance non programmée: $e');
      }
    }

    AppLogger.info('CADEAU',
        '${widget.wineName} offert à ${sortie.destinataire} '
        '(x${sortie.quantite}, suite: ${sortie.suite.name}, en ligne: $enLigne)');

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final maxQte = widget.bottle.quantity;

    // Les convives déjà connus font des destinataires plausibles : on offre le plus
    // souvent à des gens dont le nom est déjà dans l'app.
    final connus = (ref.watch(tasteProfilesListProvider).valueOrNull ?? [])
        .where((p) => !p.isPrimary && p.name.trim().isNotEmpty)
        .map((p) => p.name)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFr ? 'Offrir cette bouteille' : 'Give this bottle',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.vintage != null
                  ? '${widget.wineName} ${widget.vintage}'
                  : widget.wineName,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _destinataire,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: isFr ? 'À qui ?' : 'To whom?',
                hintText: isFr ? 'Prénom, ou « mes parents »' : 'A name, or "my parents"',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (connus.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final nom in connus.take(6))
                    ActionChip(
                      label: Text(nom),
                      onPressed: () => setState(() {
                        _destinataire.text = nom;
                      }),
                    ),
                ],
              ),
            ],

            if (maxQte > 1) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(isFr ? 'Combien ?' : 'How many?',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: _quantite > 1 ? () => setState(() => _quantite--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('$_quantite',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton.filledTonal(
                    onPressed:
                        _quantite < maxQte ? () => setState(() => _quantite++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            Text(
              isFr ? 'Et la dégustation ?' : 'What about the tasting?',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _ChoixSuite(
              titre: isFr ? 'On n\'en reparle plus' : 'Don\'t ask again',
              detail: isFr
                  ? 'Elle quitte la cave, sans note ni relance.'
                  : 'It leaves the cellar, with no rating and no reminder.',
              choisi: _suite == SuiteDuCadeau.aucuneSuite,
              onTap: () => setState(() => _suite = SuiteDuCadeau.aucuneSuite),
            ),
            const SizedBox(height: 8),
            _ChoixSuite(
              titre: isFr ? 'Me redemander dans un mois' : 'Ask me again in a month',
              detail: isFr
                  ? 'Au cas où elle serait ouverte devant vous.'
                  : 'In case it gets opened in front of you.',
              choisi: _suite == SuiteDuCadeau.redemanderPlusTard,
              onTap: () => setState(() => _suite = SuiteDuCadeau.redemanderPlusTard),
            ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _enCours || _destinataire.text.trim().isEmpty ? null : _offrir,
              icon: _enCours
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.card_giftcard),
              label: Text(isFr ? 'Offrir' : 'Give'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoixSuite extends StatelessWidget {
  final String titre;
  final String detail;
  final bool choisi;
  final VoidCallback onTap;

  const _ChoixSuite({
    required this.titre,
    required this.detail,
    required this.choisi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: choisi
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: choisi ? 1.6 : 1,
          ),
          color: choisi
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              choisi ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: choisi ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(detail,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
