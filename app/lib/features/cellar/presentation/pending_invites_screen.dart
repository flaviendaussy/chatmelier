import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';

/// Screen that displays pending invites the current user has received.
/// Users can accept or decline each invite.
class PendingInvitesScreen extends ConsumerStatefulWidget {
  const PendingInvitesScreen({super.key});

  @override
  ConsumerState<PendingInvitesScreen> createState() =>
      _PendingInvitesScreenState();
}

class _PendingInvitesScreenState extends ConsumerState<PendingInvitesScreen> {
  List<Map<String, dynamic>> _invites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
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
          SnackBar(content: Text('Error loading invites: $e')),
        );
      }
    }
  }

  Future<void> _acceptInvite(String inviteId) async {
    final supabase = ref.read(supabaseProvider);
    try {
      final result = await supabase.rpc('accept_invite', params: {
        'p_invite_id': inviteId,
      });

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Welcome! You now have access to this cellar.'),
            ),
          );
        }
        _loadInvites();
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Invites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending invites',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When someone shares their cellar with you,\nit will appear here.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invites.length,
                  itemBuilder: (context, index) {
                    final invite = _invites[index];
                    final cellarName =
                        (invite['cellars'] as Map?)?['name'] ?? 'Unknown Cellar';
                    final invitedByProfile =
                        invite['profiles'] as Map<String, dynamic>?;
                    final invitedByName =
                        invitedByProfile?['display_name'] ?? 'Someone';
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
                                Icon(
                                  Icons.wine_bar,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cellarName,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      Text(
                                        '$invitedByName invited you as ${role == 'editor' ? 'an Editor' : 'a Viewer'}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              role == 'editor'
                                  ? '✏️ You can add, edit, and consume bottles'
                                  : '👁️ You can browse and search the collection',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _declineInvite(invite['id']),
                                  child: const Text('Decline'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _acceptInvite(invite['id']),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Accept'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
