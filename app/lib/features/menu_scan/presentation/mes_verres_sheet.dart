import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../journal/data/degustation_rapide.dart';
import '../../journal/data/degustations_partagees.dart';
import '../../journal/data/format_du_questionnaire.dart';
import '../../journal/presentation/journal_screen.dart' show tastingLogProvider;
import '../../journal/presentation/tasting_questionnaire_sheet.dart';
import '../../notifications/presentation/notification_pre_permission_dialog.dart';
import '../../sommelier/data/cepages_du_vin.dart';
import '../data/verres_de_la_soiree_store.dart';
import '../domain/verres_de_la_soiree.dart';

/// « Mes verres » : les verres choisis sur la carte, et leur dégustation (Flavien, 22/10 :
/// « je veux sélectionner les vins qui m'intéressent, et les déguster avec test et tout »).
///
/// Avec qui et le format se choisissent une fois pour la soirée. Un verre touché ouvre ses
/// questions directement : ni photo d'étiquette, ni formulaire — la carte sait déjà le vin,
/// son domaine, son millésime, ses cépages et le lieu. Le 22/10, sans cet écran, il a fallu
/// onze photos et onze formulaires pour onze verres, et les lieux devinés étaient faux.
class MesVerresSheet extends ConsumerStatefulWidget {
  final CarteDeLaSoiree carte;

  const MesVerresSheet({super.key, required this.carte});

  static Future<void> show(BuildContext context, CarteDeLaSoiree carte) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MesVerresSheet(carte: carte),
      );

  @override
  ConsumerState<MesVerresSheet> createState() => _MesVerresSheetState();
}

class _MesVerresSheetState extends ConsumerState<MesVerresSheet> {
  static const _bordeaux = Color(0xFF8B1E3F);
  bool _express = true;
  String? _enCours;

  @override
  void initState() {
    super.initState();
    FormatDuQuestionnaire.express().then((e) {
      if (mounted) setState(() => _express = e);
    });
  }

  VerresDeLaSoiree get _soiree => ref.read(verresDeLaSoireeProvider(widget.carte).notifier);

  /// Les amis qui ont l'app parmi les convives : ils notent sur leur téléphone.
  List<Friend> _amisQuiNotent(SoireeDeVerres s, List<Friend> amis) =>
      [for (final a in amis) if (s.convives.contains(a.displayName)) a];

  Future<void> _deguster(VerreDeLaSoiree verre) async {
    if (_enCours != null) return;
    final s = ref.read(verresDeLaSoireeProvider(widget.carte));
    final amis = ref.read(friendsListProvider).valueOrNull ?? const <Friend>[];
    final quiNotent = _amisQuiNotent(s, amis);
    final locaux = [for (final n in s.convives) if (!quiNotent.any((a) => a.displayName == n)) n];
    final conteneur = ProviderScope.containerOf(context, listen: false);
    setState(() => _enCours = verre.id);
    var v = verre;
    try {
      // La dégustation écrite une fois : reprendre un verre la complète.
      if (v.tastingId == null) {
        final ecrite = await ref.read(degustationRapideProvider).enregistrer(VinBuDehors(
              nom: v.nom,
              producteur: v.producteur,
              millesime: v.millesime,
              region: v.region,
              pays: v.pays,
              couleur: v.couleur,
              cepages: v.cepages,
              lieu: s.lieu,
              convives: s.convives,
            ));
        v = v.copyWith(tastingId: ecrite.id);
        _soiree.remplacer(v);
        conteneur.invalidate(tastingLogProvider);
      }
      // Les amis qui ont l'app reçoivent ce verre à noter, une fois, en arrière-plan.
      if (!v.invites && quiNotent.isNotEmpty) {
        final partages = ref.read(degustationsPartageesProvider);
        for (final ami in quiNotent) {
          unawaited(partages
              .inviterANoter(
                amiId: ami.friendUserId,
                nomDuVin: v.nom,
                millesime: v.millesime,
                producteur: v.producteur,
                couleur: v.couleur,
                region: v.region,
                pays: v.pays,
                lieu: s.lieu,
              )
              .then((_) => AppLogger.info('MES_VERRES', 'Verre envoyé à noter à un ami'))
              .catchError((Object e) => AppLogger.warning('MES_VERRES', 'Verre non envoyé à un ami : $e')));
        }
        v = v.copyWith(invites: true);
        _soiree.remplacer(v);
        if (mounted) await NotificationPrePermissionDialog.auBonMoment(context);
      }
    } catch (e) {
      AppLogger.warning('MES_VERRES', 'Verre non ouvert : $e');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(tr('Impossible d\'ouvrir ce verre : réessayez.', 'Could not open this glass: try again.')),
        ));
      }
      if (mounted) setState(() => _enCours = null);
      return;
    }
    if (mounted) setState(() => _enCours = null);
    unawaited(FormatDuQuestionnaire.retenir(express: _express));
    if (!mounted) return;
    final tastingId = v.tastingId!;
    // La carte n'a pas toujours dit les cépages : on les cherche pendant qu'on répond (080).
    final cepagesAVenir = v.cepages.isNotEmpty
        ? null
        : conteneur.read(cepagesDuVinProvider).chercher(
            nom: v.nom, producteur: v.producteur, millesime: v.millesime, region: v.region, pays: v.pays, couleur: v.couleur);
    await TastingQuestionnaireSheet.show(
      context,
      dejaAuJournal: true,
      tastingLogId: tastingId,
      wineName: v.nom,
      vintage: v.millesime,
      producer: v.producteur,
      region: v.region,
      wineType: v.couleur,
      wineGrapes: v.cepages.isEmpty ? null : v.cepages,
      cepagesAVenir: cepagesAVenir,
      lieu: s.lieu,
      preselectedTasters: locaux,
      initialIsExpress: _express,
      demarrerDirectement: true,
      onNote: (note, defaut) {
        final actuel = conteneur.read(verresDeLaSoireeProvider(widget.carte)).verres.where((x) => x.id == v.id).firstOrNull ?? v;
        conteneur
            .read(verresDeLaSoireeProvider(widget.carte).notifier)
            .remplacer(actuel.copyWith(note: note, defaut: defaut, termine: true));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = ref.watch(verresDeLaSoireeProvider(widget.carte));
    final amis = ref.watch(friendsListProvider).valueOrNull ?? const <Friend>[];
    final profils = ref.watch(tasteProfilesListProvider).valueOrNull ?? const [];
    final candidats = <String>{
      for (final a in amis) a.displayName,
      for (final p in profils)
        if (!p.isPrimary) p.name,
    }.toList();
    final quiNotent = _amisQuiNotent(s, amis);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.wine_bar, color: _bordeaux),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Mes verres', 'My glasses'),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        tr('{lieu} · {n} notés sur {total}', '{lieu} · {n} of {total} rated',
                            {'lieu': s.lieu, 'n': s.notes, 'total': s.verres.length}),
                        style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // Avec qui, une fois pour la soirée.
                Text(tr('Avec qui ?', 'With whom?'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (candidats.isEmpty)
                  Text(tr('Seul, ou ajoutez des amis depuis votre profil.', 'On your own, or add friends from your profile.'),
                      style: const TextStyle(fontSize: 12.5, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final nom in candidats)
                        FilterChip(
                          label: Text(nom),
                          selected: s.convives.contains(nom),
                          selectedColor: _bordeaux.withValues(alpha: 0.16),
                          checkmarkColor: _bordeaux,
                          onSelected: (oui) => _soiree.convives(
                              oui ? [...s.convives, nom] : [for (final c in s.convives) if (c != nom) c]),
                        ),
                    ],
                  ),
                if (quiNotent.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.send_to_mobile, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tr('{noms} recevra chaque verre à noter sur son téléphone.',
                                '{noms} will get each glass to rate on their phone.',
                                {'noms': quiNotent.map((a) => a.displayName).join(', ')}),
                            style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Text(tr('Comment les noter ?', 'How to rate them?'),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(tr('Express · 3 questions', 'Express · 3 questions'))),
                    ButtonSegment(value: false, label: Text(tr('Sommelier', 'Sommelier'))),
                  ],
                  selected: {_express},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() => _express = v.first),
                ),
                const SizedBox(height: 20),
                Text(tr('Les verres', 'The glasses'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (s.verres.isEmpty)
                  Text(
                    tr('Touchez le verre d\'un vin de la carte pour l\'ajouter ici.', 'Tap the glass on a wine in the list to add it here.'),
                    style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                for (final v in s.verres) _ligne(v),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligne(VerreDeLaSoiree v) {
    final enCours = _enCours == v.id;
    final Widget statut;
    if (v.termine) {
      statut = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(v.defaut != null ? Icons.report_gmailerrorred_rounded : Icons.check_circle,
              size: 18, color: v.defaut != null ? Colors.orange.shade800 : const Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(
            v.defaut != null
                ? tr('Défaut', 'Faulty')
                : (v.note == null ? tr('Noté', 'Rated') : '${v.note! % 1 == 0 ? v.note!.toInt() : v.note!.toStringAsFixed(1)}/10'),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: v.defaut != null ? Colors.orange.shade800 : const Color(0xFF2E7D32)),
          ),
        ],
      );
    } else {
      statut = FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _bordeaux, visualDensity: VisualDensity.compact),
        onPressed: enCours ? null : () => _deguster(v),
        child: enCours
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(v.commence ? tr('Reprendre', 'Resume') : tr('Déguster', 'Taste')),
      );
    }
    final couleur = switch (v.couleur) {
      'white' => const Color(0xFFE8D08D),
      'rose' => const Color(0xFFF48FB1),
      'sparkling' => const Color(0xFFD4AF37),
      'red' => _bordeaux,
      _ => Colors.amber.shade700,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: v.termine || enCours ? null : () => _deguster(v),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${v.nom}${v.millesime != null ? ' ${v.millesime}' : ''}',
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (v.producteur != null)
                    Text(v.producteur!, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            statut,
          ],
        ),
      ),
    );
  }
}
