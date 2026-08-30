import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/widgets/owner_avatar.dart';

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
      final link = 'https://chatmelier.app/invite/$code';

      await Share.share(
        'Join my wine cellar "${widget.cellarName}" on Chatmelier!\n$link',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sharing & Members'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ============ INVITE SECTION (admin only) ============
                if (_isAdmin) ...[
                  Text('Invite someone', style: theme.textTheme.titleMedium),
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
}
