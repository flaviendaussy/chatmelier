import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../../shared/utils/langue.dart';

/// Screen for managing cellar members and invitations.
/// Allows admins to invite users (by email or shareable link),
/// toggle roles (viewer/editor), and remove members.
class CellarSharingScreen extends ConsumerStatefulWidget {
  final String cellarId;
  final String cellarName;

  const CellarSharingScreen({
    super.key,
    required this.cellarId,
    required this.cellarName,
  });

  @override
  ConsumerState<CellarSharingScreen> createState() =>
      _CellarSharingScreenState();
}

class _CellarSharingScreenState extends ConsumerState<CellarSharingScreen> {
  final _emailController = TextEditingController();
  String _selectedRole = 'viewer';
  bool _isSending = false;
  bool _isAdmin = false;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;

    List<Map<String, dynamic>> membersList = [];
    List<Map<String, dynamic>> invitesList = [];
    bool isAdmin = true;

    try {
      final membersRes = await supabase
          .from('cellar_members')
          .select('*, profiles(display_name, avatar_url)')
          .eq('cellar_id', widget.cellarId);
      membersList = List<Map<String, dynamic>>.from(membersRes);

      isAdmin = membersList.any(
        (m) => m['user_id'] == userId && m['role'] == 'admin',
      ) || membersList.isEmpty;
    } catch (e) {
      debugPrint('Error loading members: $e');
    }

    try {
      final invitesRes = await supabase
          .from('cellar_invites')
          .select('*')
          .eq('cellar_id', widget.cellarId)
          .eq('status', 'pending');
      invitesList = List<Map<String, dynamic>>.from(invitesRes);
    } catch (e) {
      debugPrint('Error loading invites: $e');
    }

    if (mounted) {
      setState(() {
        _members = membersList;
        _pendingInvites = invitesList;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    }
  }

  Future<void> _inviteByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSending = true);
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser!.id;

    try {

      await supabase.from('cellar_invites').insert({
        'cellar_id': widget.cellarId,
        'invited_by': userId,
        'invited_email': email,
        'role': _selectedRole,
      });

      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Invitation envoyée à {email}', 'Invite sent to {email}', {'email': email}))),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur : {e}', 'Error: {e}', {'e': e}))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _createShareableLink() async {
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser!.id;

    try {
      final res = await supabase.from('cellar_invites').insert({
        'cellar_id': widget.cellarId,
        'invited_by': userId,
        'invited_email': 'link-invite@chatmelier.app', // placeholder for link invites
        'role': _selectedRole,
      }).select('invite_code').single();

      final code = res['invite_code'] as String;
      // L'app web actuelle (celle des tables) : l'autre domaine sert une version ancienne.
      String baseUrl = 'https://chatmelier.github.io';
      if (kIsWeb) {
        try {
          final origin = Uri.base.origin;
          final path = Uri.base.path;
          if (origin.isNotEmpty && origin != 'null') {
            final normalizedPath = path.isEmpty ? '/' : (path.endsWith('/') ? path : '$path/');
            baseUrl = '$origin$normalizedPath';
            if (baseUrl.endsWith('/')) {
              baseUrl = baseUrl.substring(0, baseUrl.length - 1);
            }
          }
        } catch (_) {}
      }
      final link = '$baseUrl/invite/$code';

      await Share.share(
        tr('Rejoins ma cave à vin "{cellarName}" sur Chatmelier !\n{link}', 'Join my wine cellar "{cellarName}" on Chatmelier!\n{link}', {'cellarName': widget.cellarName, 'link': link}),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Impossible de créer le lien : {e}', 'Error creating link: {e}', {'e': e}))),
        );
      }
    }
  }

  Future<void> _updateRole(String memberId, String newRole) async {
    final supabase = ref.read(supabaseProvider);
    try {
      await supabase
          .from('cellar_members')
          .update({'role': newRole})
          .eq('cellar_id', widget.cellarId)
          .eq('user_id', memberId);
      _loadData();
    } catch (_) {
      try {
        await supabase.rpc('update_member_role', params: {
          'p_cellar_id': widget.cellarId,
          'p_user_id': memberId,
          'p_new_role': newRole,
        });
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e}))),
          );
        }
      }
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Retirer le membre', 'Remove member')),
        content: Text(tr('Retirer {memberName} de cette cave ?', 'Remove {memberName} from this cellar?', {'memberName': memberName})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Annuler', 'Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('Retirer', 'Remove')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final supabase = ref.read(supabaseProvider);
    try {
      await supabase
          .from('cellar_members')
          .delete()
          .eq('cellar_id', widget.cellarId)
          .eq('user_id', memberId);
      _loadData();
    } catch (_) {
      try {
        await supabase.rpc('remove_cellar_member', params: {
          'p_cellar_id': widget.cellarId,
          'p_user_id': memberId,
        });
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e}))),
          );
        }
      }
    }
  }

  Future<void> _revokeInvite(String inviteId) async {
    final supabase = ref.read(supabaseProvider);
    try {
      await supabase.from('cellar_invites').update({
        'status': 'revoked',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', inviteId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur : {e}', 'Error: {e}', {'e': e}))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.read(supabaseProvider).auth.currentUser?.id;

    final incomingCellarAsync = ref.watch(incomingCellarRequestsProvider);
    final cellarRequests = (incomingCellarAsync.valueOrNull ?? [])
        .where((r) => r.cellarId == widget.cellarId || r.cellarId.isEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Partage - {cellarName}', 'Sharing - {cellarName}', {'cellarName': widget.cellarName})),
        actions: const [
          NotificationBellButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ============ INCOMING CELLAR REQUESTS ============
                if (cellarRequests.isNotEmpty) ...[
                  _buildPendingCellarRequestsBanner(cellarRequests, theme),
                  const SizedBox(height: 20),
                ],

                // ============ FRIENDS DIRECT ACCESS SECTION ============
                if (_isAdmin) ...[
                  _buildFriendsAccessSection(theme),
                  const SizedBox(height: 24),
                ],

                // ============ INVITE SECTION (admin only) ============
                if (_isAdmin) ...[
                  Text(tr('Inviter par email ou lien', 'Invite by email or link'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: tr('Adresse e-mail', 'Email address'),
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedRole,
                        items: [
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Row(
                              children: [
                                const Icon(Icons.visibility, size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Text(tr('Lecture seule', 'Read only')),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'editor',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_note, size: 16, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 6),
                                Text(tr('Lecture & Écriture', 'Read & write')),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSending ? null : _inviteByEmail,
                          icon: const Icon(Icons.send),
                          label: Text(_isSending ? tr('Envoi...', 'Sending...') : tr('Inviter par e-mail', 'Invite by email')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _createShareableLink,
                        icon: const Icon(Icons.link),
                        label: Text(tr('Lien', 'Link')),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/friends'),
                        icon: const Icon(Icons.people, color: Color(0xFFD4AF37)),
                        label: Text(tr('Mes Amis', 'My friends')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ============ CURRENT MEMBERS ============
                Text(tr('Membres actuels', 'Current members'), style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...(_members.map((member) {
                  final profile = member['profiles'] as Map<String, dynamic>?;
                  final name = profile?['display_name'] ?? tr('Inconnu', 'Unknown');
                  final avatarUrl = profile?['avatar_url'] as String?;
                  final role = member['role'] as String;
                  final isCurrentUser = member['user_id'] == currentUserId;
                  final isOwner = role == 'admin';

                  return Card(
                    child: ListTile(
                      leading: OwnerAvatar(
                        displayName: name,
                        avatarUrl: avatarUrl,
                        size: 40,
                      ),
                      title: Text(
                        name + (isCurrentUser ? tr(' (vous)', ' (you)') : ''),
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        isOwner
                            ? tr('👑 Propriétaire', '👑 Owner')
                            : (role == 'editor'
                                ? tr('✍️ Lecture & Écriture', '✍️ Read & write')
                                : tr('👁️ Lecture seule', '👁️ Read only')),
                        style: TextStyle(
                          color: isOwner
                              ? theme.colorScheme.primary
                              : (role == 'editor'
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF6B7280)),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: (_isAdmin && !isCurrentUser && !isOwner)
                          ? PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'toggle_role') {
                                  _updateRole(
                                    member['user_id'],
                                    role == 'editor' ? 'viewer' : 'editor',
                                  );
                                } else if (action == 'remove') {
                                  _removeMember(member['user_id'], name);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'toggle_role',
                                  child: Text(
                                    role == 'editor'
                                        ? tr('Passer en Lecture seule', 'Switch to read only')
                                        : tr('Passer en Lecture & Écriture', 'Switch to read & write'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(
                                    tr('Retirer le membre', 'Remove member'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                })),

                // ============ PENDING INVITES ============
                if (_pendingInvites.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(tr('Invitations en attente', 'Pending Invites'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...(_pendingInvites.map((invite) {
                    final email = invite['invited_email'] as String? ?? '';
                    final role = invite['role'] as String;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.hourglass_empty),
                        ),
                        title: Text(email),
                        subtitle: Text(
                          role == 'editor'
                              ? tr('Invité comme éditeur • En attente', 'Invited as Editor • Pending')
                              : tr('Invité comme lecteur • En attente', 'Invited as Viewer • Pending'),
                        ),
                        trailing: _isAdmin
                            ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _revokeInvite(invite['id']),
                                tooltip: tr('Annuler l\'invitation', 'Revoke invite'),
                              )
                            : null,
                      ),
                    );
                  })),
                ],

                // ============ INFO ============
                const SizedBox(height: 32),
                Card(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(tr('À propos du partage', 'About sharing'), style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                              '• Les lecteurs parcourent la cave et y cherchent\n'
                              '• Les éditeurs ajoutent, sortent et gèrent les bouteilles\n'
                              '• Les changements se synchronisent en direct sur tous les appareils\n'
                              '• Chacun voit sa propre cave et celles qu\'on lui partage',
                              '• Viewers can browse and search the cellar\n'
                              '• Editors can add bottles, consume, and manage wines\n'
                              '• Changes sync in real-time across all devices\n'
                              '• Each person sees their own collection + shared ones'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pending Requests Banner
  // ---------------------------------------------------------------------------
  Widget _buildPendingCellarRequestsBanner(List<dynamic> requests, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                tr('Demandes d\'accès reçues ({requests_length})', 'Access requests ({requests_length})', {'requests_length': requests.length}),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFFD4AF37)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...requests.map((r) {
            final req = r;
            final reqName = req.requesterName as String? ?? tr('Un ami', 'A friend');
            final role = req.requestedRole == 'editor' ? tr('Sommelier ✍️', 'Sommelier ✍️') : tr('Lecteur 👁️', 'Viewer 👁️');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('{reqName} souhaite accéder en tant que {role}', '{reqName} would like access as {role}', {'reqName': reqName, 'role': role}),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _respondCellarRequest(req.id, req.requesterId, false, 'none'),
                    child: Text(tr('Refuser', 'Decline'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _respondCellarRequest(req.id, req.requesterId, true, req.requestedRole),
                    child: Text(tr('Accepter', 'Accept'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _respondCellarRequest(String reqId, String requesterId, bool accept, String role) async {
    try {
      await ref.read(friendsRepositoryProvider).respondCellarAccess(
        requestId: reqId,
        cellarId: widget.cellarId,
        requesterId: requesterId,
        accept: accept,
        role: role,
        cellarName: widget.cellarName,
      );
      _loadData();
      refreshFriendsAndNotifications(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? tr('Accès accordé !', 'Access granted!') : tr('Demande refusée.', 'Request declined.')),
            backgroundColor: accept ? const Color(0xFF10B981) : Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e}))));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Friends Direct Access Section
  // ---------------------------------------------------------------------------
  Widget _buildFriendsAccessSection(ThemeData theme) {
    final friendsAsync = ref.watch(friendsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tr('Partager avec mes amis', 'Share with my friends'), style: theme.textTheme.titleMedium),
            TextButton.icon(
              icon: const Icon(Icons.person_add, size: 16, color: Color(0xFFD4AF37)),
              label: Text(tr('Ajouter un ami', 'Add a friend'), style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
              onPressed: () => context.push('/friends'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        friendsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
          error: (err, _) => Text(tr('Erreur amis: {err}', 'Friends error: {err}', {'err': err}), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          data: (friends) {
            if (friends.isEmpty) {
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Text('👥 ', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr('Vous n\'avez pas encore d\'amis ajoutés. Ajoutez vos proches pour partager votre cave en 1 clic !', 'You haven\'t added any friends yet. Add the people close to you to share your cellar in one tap!'),
                          style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/friends'),
                        child: Text(tr('Rechercher', 'Search')),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: friends.map((friend) {
                final member = _members.firstWhere(
                  (m) => m['user_id'] == friend.friendUserId,
                  orElse: () => <String, dynamic>{},
                );
                final isAlreadyMember = member.isNotEmpty;
                final memberRole = member['role']?.toString() ?? 'viewer';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: OwnerAvatar(userId: friend.friendUserId, radius: 20),
                    title: Text(friend.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(friend.handle, style: const TextStyle(fontSize: 12, color: Color(0xFF8B1E3F))),
                    trailing: isAlreadyMember
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              memberRole == 'editor' ? tr('✍️ Sommelier', '✍️ Sommelier') : tr('👁️ Lecteur', '👁️ Viewer'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF10B981)),
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B1E3F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.card_giftcard, size: 15),
                            label: Text(tr('Donner accès', 'Give access'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () => _showGrantCellarDialogToFriend(friend),
                          ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showGrantCellarDialogToFriend(Friend friend) {
    String selectedRole = 'viewer';
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🎁 ', style: TextStyle(fontSize: 22)),
              Expanded(
                child: Text(
                  tr('Accès cave pour {displayName}', 'Cellar access for {displayName}', {'displayName': friend.displayName}),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Donner accès à "{cellarName}" :', 'Give access to "{cellarName}":', {'cellarName': widget.cellarName}),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: Text(tr('Lecteur (Consultation 👁️)', 'Viewer (browse only 👁️)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text(tr('Peut voir votre cave, vos bouteilles et vos fiches de dégustation.', 'Can see your cellar, your bottles and your tasting notes.'), style: const TextStyle(fontSize: 11)),
                value: 'viewer',
                groupValue: selectedRole,
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: Text(tr('Sommelier Délégué (Éditeur ✍️)', 'Deputy sommelier (editor ✍️)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text(tr('Peut ajouter, déplacer et consommer des bouteilles dans cette cave.', 'Can add, move and drink bottles in this cellar.'), style: const TextStyle(fontSize: 11)),
                value: 'editor',
                groupValue: selectedRole,
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('Annuler', 'Cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(friendsRepositoryProvider).grantCellarAccessDirectly(
                    cellarId: widget.cellarId,
                    friendUserId: friend.friendUserId,
                    role: selectedRole,
                    cellarName: widget.cellarName,
                  );
                  _loadData();
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(tr('🍾 Accès accordé à {displayName} !', '🍾 Access granted to {displayName}!', {'displayName': friend.displayName})),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e})), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: Text(tr('Confirmer l\'accès', 'Confirm access'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
