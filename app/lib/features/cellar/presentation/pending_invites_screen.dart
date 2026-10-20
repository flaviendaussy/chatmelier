import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../offline/presentation/sync_provider.dart';
import '../data/invitation_en_attente.dart';

/// Les invitations reçues, et celle d'un lien (`/invite/:code`, V2.5 · Q3).
///
/// Le partage par lien était cassé de bout en bout : la route jetait le code, l'écran ne
/// listait que les invitations adressées à son e-mail, et rien n'acceptait un code en
/// production. Désormais la route passe le code, et l'écran propose de rejoindre la cave
/// en un geste (`accept_invite_by_code`, migration 074), ou de se connecter d'abord.
class PendingInvitesScreen extends ConsumerStatefulWidget {
  /// Le code d'un lien d'invitation, s'il y en a un.
  final String? code;

  const PendingInvitesScreen({super.key, this.code});

  @override
  ConsumerState<PendingInvitesScreen> createState() => _PendingInvitesScreenState();
}

class _PendingInvitesScreenState extends ConsumerState<PendingInvitesScreen> {
  List<Map<String, dynamic>> _invites = [];
  bool _isLoading = true;
  bool _lienEcarte = false;
  bool _rejointEnCours = false;

  /// Le code du lien, s'il a la forme d'un code : rien d'autre ne part au serveur.
  String? get _code {
    final code = widget.code?.trim();
    return code != null && InvitationEnAttente.codeValide(code) ? code : null;
  }

  bool get _connecte {
    final personne = ref.read(supabaseProvider).auth.currentUser;
    return personne != null && !personne.isAnonymous;
  }

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesInstanceProvider);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    if (!_connecte) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    final email = supabase.auth.currentUser?.email;

    try {
      // Get invites addressed to this user (by user_id or email)
      final res = await supabase
          .from('cellar_invites')
          .select('*, cellars(name), profiles!cellar_invites_invited_by_fkey(display_name)')
          .eq('status', 'pending')
          .or('invited_user_id.eq.$userId,invited_email.eq.$email')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _invites = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Impossible de charger les invitations : {e}', 'Couldn\'t load invitations: {e}', {'e': e}))),
        );
      }
    }
  }

  Future<void> _acceptInvite(String inviteId) async {
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final supabase = conteneur.read(supabaseProvider);
    try {
      final result = await supabase.rpc('accept_invite', params: {
        'p_invite_id': inviteId,
      });

      if (result['success'] == true) {
        conteneur.invalidate(userCellarsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('🎉 Bienvenue ! Vous avez désormais accès à cette cave.', '🎉 Welcome! You now have access to this cellar.'))),
          );
        }
        _loadInvites();
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur : {e}', 'Error: {e}', {'e': e}))),
        );
      }
    }
  }

  Future<void> _declineInvite(String inviteId) async {
    final supabase = ref.read(supabaseProvider);
    try {
      await supabase.rpc('decline_invite', params: {
        'p_invite_id': inviteId,
      });
      _loadInvites();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur : {e}', 'Error: {e}', {'e': e}))),
        );
      }
    }
  }

  /// Sans compte : l'invitation attend la connexion, même faite dans un autre onglet.
  Future<void> _seConnecterPourRejoindre(String code) async {
    final prefs = _prefs;
    if (prefs != null) await InvitationEnAttente.garder(prefs, code);
    if (!mounted) return;
    context.go('/login?suite=${Uri.encodeComponent('/invite/$code')}');
  }

  Future<void> _rejoindreParLien(String code) async {
    final conteneur = ProviderScope.containerOf(context, listen: false);
    setState(() => _rejointEnCours = true);
    final messager = ScaffoldMessenger.of(context);
    try {
      final reponse = await conteneur.read(supabaseProvider).rpc('accept_invite_by_code', params: {'p_code': code});
      final resultat = reponse is Map ? reponse : const {};
      if (resultat['success'] == true) {
        final prefs = _prefs;
        if (prefs != null) await InvitationEnAttente.effacer(prefs);
        conteneur.invalidate(userCellarsProvider);
        AppLogger.info('CELLAR', 'Cave rejointe par un lien d\'invitation (${resultat['role'] ?? 'rôle inconnu'})');
        messager.showSnackBar(SnackBar(content: Text(tr('Vous avez rejoint la cave : elle apparaît avec les vôtres.', 'You\'ve joined the cellar: it now appears with yours.'))));
        if (mounted) context.go('/');
        return;
      }
      // Le motif seulement : jamais le code dans les journaux.
      final motif = resultat['error']?.toString() ?? 'réponse inattendue';
      AppLogger.warning('CELLAR', 'Lien d\'invitation refusé : $motif');
      if (motif == 'session_requise') {
        await _seConnecterPourRejoindre(code);
        return;
      }
      // Un lien qui a déjà servi, ou mal recopié : il ne servira plus.
      final prefs = _prefs;
      if (prefs != null) await InvitationEnAttente.effacer(prefs);
      messager.showSnackBar(SnackBar(
        content: Text(tr('Ce lien a déjà servi, ou il n\'est plus valable. Demandez-en un nouveau à la personne qui vous l\'a envoyé.',
            'This link has already been used, or is no longer valid. Ask the person who sent it for a new one.')),
        duration: const Duration(seconds: 8),
      ));
      if (mounted) setState(() => _lienEcarte = true);
    } catch (e) {
      AppLogger.warning('CELLAR', 'Lien d\'invitation : l\'appel a échoué (${e.runtimeType})');
      messager.showSnackBar(SnackBar(
        content: Text(tr('Impossible de rejoindre la cave pour l\'instant. Vérifiez votre connexion et réessayez.',
            'Couldn\'t join the cellar right now. Check your connection and try again.')),
      ));
    } finally {
      if (mounted) setState(() => _rejointEnCours = false);
    }
  }

  Future<void> _ecarterLeLien() async {
    final prefs = _prefs;
    if (prefs != null) await InvitationEnAttente.effacer(prefs);
    if (mounted) setState(() => _lienEcarte = true);
  }

  Widget _carteDuLien(String code) {
    final theme = Theme.of(context);
    final connecte = _connecte;
    return Card(
      key: const Key('invitation_par_lien'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wine_bar, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tr('Une invitation à rejoindre une cave', 'An invitation to join a cellar'),
                      style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              connecte
                  ? tr('Quelqu\'un vous a envoyé ce lien pour partager sa cave. Une fois rejointe, elle apparaît avec les vôtres.',
                      'Someone sent you this link to share their cellar. Once you join, it appears with yours.')
                  : tr('Connectez-vous, ou créez votre compte, pour rejoindre cette cave : vous reviendrez ici ensuite.',
                      'Sign in, or create your account, to join this cellar: you\'ll come back here afterwards.'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _rejointEnCours ? null : _ecarterLeLien,
                  child: Text(tr('Non merci', 'No thanks')),
                ),
                if (connecte)
                  FilledButton.icon(
                    key: const Key('rejoindre_la_cave'),
                    onPressed: _rejointEnCours ? null : () => _rejoindreParLien(code),
                    icon: const Icon(Icons.check),
                    label: Text(tr('Rejoindre la cave', 'Join the cellar')),
                  )
                else
                  FilledButton.icon(
                    key: const Key('se_connecter_pour_rejoindre'),
                    onPressed: () => _seConnecterPourRejoindre(code),
                    icon: const Icon(Icons.login),
                    label: Text(tr('Se connecter', 'Sign in')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _invitationRecue(ThemeData theme, Map<String, dynamic> invite) {
    final cellarName = (invite['cellars'] as Map?)?['name'] ?? tr('Cave sans nom', 'Unnamed cellar');
    final invitedByProfile = invite['profiles'] as Map<String, dynamic>?;
    final invitedByName = invitedByProfile?['display_name'] ?? tr('Quelqu\'un', 'Someone');
    final role = invite['role'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wine_bar, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$cellarName', style: theme.textTheme.titleMedium),
                      Text(
                        role == 'editor'
                            ? tr('{nom} vous invite à modifier sa cave', '{nom} invited you to edit their cellar', {'nom': invitedByName})
                            : tr('{nom} vous invite à consulter sa cave', '{nom} invited you to browse their cellar', {'nom': invitedByName}),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              role == 'editor'
                  ? tr('✏️ Vous pourrez ajouter, modifier et sortir des bouteilles', '✏️ You can add, edit, and consume bottles')
                  : tr('👁️ Vous pourrez parcourir la cave et y chercher', '👁️ You can browse and search the collection'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _declineInvite(invite['id']),
                  child: Text(tr('Refuser', 'Decline')),
                ),
                FilledButton.icon(
                  onPressed: () => _acceptInvite(invite['id']),
                  icon: const Icon(Icons.check),
                  label: Text(tr('Accepter', 'Accept')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = _lienEcarte ? null : _code;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Invitations', 'Invitations'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (code != null) _carteDuLien(code),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_invites.isEmpty && code == null)
            Padding(
              padding: const EdgeInsets.only(top: 96),
              child: Column(
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('Aucune invitation en attente', 'No pending invites'),
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('Quand quelqu\'un partagera sa cave avec vous,\nelle apparaîtra ici.', 'When someone shares their cellar with you,\nit will appear here.'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final invite in _invites) _invitationRecue(theme, invite),
        ],
      ),
    );
  }
}
