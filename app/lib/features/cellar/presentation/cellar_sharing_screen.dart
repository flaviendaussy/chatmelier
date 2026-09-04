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
          SnackBar(content: Text('Invite sent to $email')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      String baseUrl = 'https://flaviendaussy.github.io';
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
        'Rejoins ma cave à vin "${widget.cellarName}" sur Chatmelier !\n$link',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating link: $e')),
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
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer le membre'),
        content: Text('Retirer $memberName de cette cave ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Retirer'),
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
            SnackBar(content: Text('Erreur: $e')),
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
          SnackBar(content: Text('Error: $e')),
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
        title: Text('Partage - ${widget.cellarName}'),
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
                  Text('Inviter par email ou lien', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 16, color: Color(0xFF6B7280)),
                                SizedBox(width: 6),
                                Text('Lecture seule'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'editor',
                            child: Row(
                              children: [
                                Icon(Icons.edit_note, size: 16, color: Color(0xFF2E7D32)),
                                SizedBox(width: 6),
                                Text('Lecture & Écriture'),
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
                          label: Text(_isSending ? 'Envoi...' : 'Inviter par e-mail'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _createShareableLink,
                        icon: const Icon(Icons.link),
                        label: const Text('Lien'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/friends'),
                        icon: const Icon(Icons.people, color: Color(0xFFD4AF37)),
                        label: const Text('Mes Amis'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ============ CURRENT MEMBERS ============
                Text('Membres actuels', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...(_members.map((member) {
                  final profile = member['profiles'] as Map<String, dynamic>?;
                  final name = profile?['display_name'] ?? 'Inconnu';
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
                        name + (isCurrentUser ? ' (vous)' : ''),
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        isOwner
                            ? '👑 Propriétaire'
                            : (role == 'editor'
                                ? '✍️ Lecture & Écriture'
                                : '👁️ Lecture seule'),
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
                                        ? 'Passer en Lecture seule'
                                        : 'Passer en Lecture & Écriture',
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text(
                                    'Retirer le membre',
                                    style: TextStyle(color: Colors.red),
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
                  Text('Pending Invites', style: theme.textTheme.titleMedium),
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
                          'Invited as ${role == 'editor' ? 'Editor' : 'Viewer'} • Pending',
                        ),
                        trailing: _isAdmin
                            ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _revokeInvite(invite['id']),
                                tooltip: 'Revoke invite',
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
                            Text('About sharing', style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Viewers can browse and search the cellar\n'
                          '• Editors can add bottles, consume, and manage wines\n'
                          '• Changes sync in real-time across all devices\n'
                          '• Each person sees their own collection + shared ones',
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
                'Demandes d\'accès reçues (${requests.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFFD4AF37)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...requests.map((r) {
            final req = r;
            final reqName = req.requesterName as String? ?? 'Un ami';
            final role = req.requestedRole == 'editor' ? 'Sommelier ✍️' : 'Lecteur 👁️';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$reqName souhaite accéder en tant que $role',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _respondCellarRequest(req.id, req.requesterId, false, 'none'),
                    child: const Text('Refuser', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _respondCellarRequest(req.id, req.requesterId, true, req.requestedRole),
                    child: const Text('Accepter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
            content: Text(accept ? 'Accès accordé !' : 'Demande refusée.'),
            backgroundColor: accept ? const Color(0xFF10B981) : Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
            Text('Partager avec mes amis', style: theme.textTheme.titleMedium),
            TextButton.icon(
              icon: const Icon(Icons.person_add, size: 16, color: Color(0xFFD4AF37)),
              label: const Text('Ajouter un ami', style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
              onPressed: () => context.push('/friends'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        friendsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
          error: (err, _) => Text('Erreur amis: $err', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                      const Expanded(
                        child: Text(
                          'Vous n\'avez pas encore d\'amis ajoutés. Ajoutez vos proches pour partager votre cave en 1 clic !',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/friends'),
                        child: const Text('Rechercher'),
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
                              memberRole == 'editor' ? '✍️ Sommelier' : '👁️ Lecteur',
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
                            label: const Text('Donner accès', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                  'Accès cave pour ${friend.displayName}',
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
                'Donner accès à "${widget.cellarName}" :',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('Lecteur (Consultation 👁️)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('Peut voir votre cave, vos bouteilles et vos fiches de dégustation.', style: TextStyle(fontSize: 11)),
                value: 'viewer',
                groupValue: selectedRole,
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: const Text('Sommelier Délégué (Éditeur ✍️)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('Peut ajouter, déplacer et consommer des bouteilles dans cette cave.', style: TextStyle(fontSize: 11)),
                value: 'editor',
                groupValue: selectedRole,
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
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
                        content: Text('🍾 Accès accordé à ${friend.displayName} !'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Confirmer l\'accès', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
