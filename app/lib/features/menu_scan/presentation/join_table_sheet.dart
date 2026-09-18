import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/domain/evening_summary.dart';
import '../../auth/presentation/keep_evening_sheet.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import '../data/table_session_service.dart';
import 'menu_table_consensus_guest_screen.dart';

/// Rejoindre une table avec six caractères.
///
/// Le QR reste le chemin rapide, mais il échoue pour des raisons banales : écran rayé,
/// lumière basse, téléphone sans appareil photo, invité arrivé après le dessert. Un code
/// dit à voix haute n'a aucune de ces faiblesses — et il ne demande pas de compte, parce
/// qu'exiger une inscription au moment où l'on tend son téléphone à un ami tuerait la
/// seule boucle virale du produit.
class JoinTableSheet extends ConsumerStatefulWidget {
  const JoinTableSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const JoinTableSheet(),
        ),
      );

  @override
  ConsumerState<JoinTableSheet> createState() => _JoinTableSheetState();
}

class _JoinTableSheetState extends ConsumerState<JoinTableSheet> {
  final _code = TextEditingController();
  final _nom = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _code.dispose();
    _nom.dispose();
    super.dispose();
  }

  Future<void> _rejoindre({required bool isFr}) async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });

    // Un compte, sans formulaire. Ouvert ICI et non au démarrage : ce geste est le
    // premier qui produit quelque chose à garder — les verres de ce soir, le palais qui
    // se dessine. Ouvrir un compte à chaque lancement gonflerait la facture pour des gens
    // qui n'ont rien fait.
    //
    // S'il échoue (réglage Supabase absent, réseau coupé), on rejoint quand même : la
    // table fonctionne, seule la mémoire de la soirée manquera.
    await ref.read(authRepositoryProvider).assurerUneSession();

    // Le profil de goût part avec : c'est tout l'intérêt. Une table qui ne connaît pas
    // les palais de ses convives ne fait qu'un sondage à main levée.
    GuestProfile? profil;
    try {
      final p = await ref.read(tasteProfileServiceProvider).getPrimaryProfile();
      profil = GuestProfile.fromTasteProfile(p);
    } catch (_) {
      // Sans profil, on rejoint quand même : le nom suffit à être compté à table.
    }

    try {
      final t = await ref.read(tableSessionServiceProvider).rejoindre(
            code: _code.text,
            nom: _nom.text.trim().isEmpty
                ? (profil?.name ?? (isFr ? 'Invité' : 'Guest'))
                : _nom.text,
            profil: profil,
          );
      if (!mounted) return;

      // Ce que le palais savait AVANT la soirée. La différence, au retour, est ce qu'on
      // pourra annoncer sans exagérer.
      final avant = await ref.read(tasteProfileServiceProvider).getPrimaryProfile();
      final compteAvant = avant.questionnairesCompleted;
      if (!mounted) return;

      final navigateur = Navigator.of(context);
      navigateur.pop();
      await navigateur.push(MaterialPageRoute(
        builder: (_) => MenuTableConsensusGuestScreen(
          initialSessionId: t.sessionId,
          prechargedMenu: t.menu,
        ),
      ));

      // Au retour de la table : la soirée est finie, c'est le moment de proposer de la
      // garder. Ni pendant — on interromprait le repas — ni plus tard, quand plus rien
      // ne rappellera pourquoi ça vaut la peine.
      if (!mounted) return;
      await _proposerDeGarder(
        depart: compteAvant,
        lieu: t.menu.restaurantName,
        isFr: isFr,
      );
    } on TableSessionException catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = e.cause == EchecDeTable.introuvable
            ? (isFr
                ? 'Aucune table avec ce code. Il expire au bout de quatre heures — '
                    'redemandez-le à la personne qui a scanné la carte.'
                : 'No table with this code. Codes expire after four hours — ask whoever '
                    'scanned the menu for a new one.')
            : (isFr
                ? 'Impossible de joindre le serveur. Vérifiez votre connexion.'
                : 'Could not reach the server. Check your connection.');
      });
    }
  }

  /// Propose de garder la soirée, si elle a laissé quelque chose et si le compte est
  /// encore anonyme.
  Future<void> _proposerDeGarder({
    required int depart,
    required String lieu,
    required bool isFr,
  }) async {
    final auth = ref.read(authRepositoryProvider);
    // Un compte déjà nommé n'a rien à convertir ; sans session du tout, il n'y a rien à
    // garder côté serveur, et promettre le contraire serait faux.
    if (!auth.aUneSession || !auth.estAnonyme) return;

    final apres = await ref.read(tasteProfileServiceProvider).getPrimaryProfile();
    final lignes = EveningSummary.lignes(
      profil: apres,
      verresGoutes: (apres.questionnairesCompleted - depart).clamp(0, 99),
      nomDuLieu: lieu.trim().isEmpty ? null : lieu.trim(),
    );
    if (lignes.isEmpty || !mounted) return;

    await KeepEveningSheet.show(context, cequiSeraGarde: lignes);
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final pret = _code.text.trim().length == 6;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isFr ? 'Rejoindre une table' : 'Join a table',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              isFr
                  ? 'Le code à six caractères affiché sur le téléphone qui a scanné la carte.'
                  : 'The six-character code shown on the phone that scanned the menu.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
              textAlign: TextAlign.center,
              inputFormatters: [
                // L'alphabet du serveur : ni 0/O ni 1/I/L, qui se lisent de travers dans
                // un restaurant mal éclairé.
                FilteringTextInputFormatter.allow(
                    RegExp('[ABCDEFGHJKMNPQRSTUVWXYZ23456789abcdefghjkmnpqrstuvwxyz]')),
                TextInputFormatter.withFunction((_, n) =>
                    n.copyWith(text: n.text.toUpperCase())),
              ],
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() => _erreur = null),
              onSubmitted: (_) => pret ? _rejoindre(isFr: isFr) : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nom,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: isFr ? 'Votre prénom' : 'Your first name',
                helperText: isFr
                    ? 'Pour que la table sache qui a voté.'
                    : 'So the table knows who voted.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Text(_erreur!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: (!pret || _enCours) ? null : () => _rejoindre(isFr: isFr),
              icon: _enCours
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.groups_rounded),
              label: Text(isFr ? 'Rejoindre' : 'Join'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
