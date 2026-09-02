import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/cellar_access_request.dart';
import '../../friends/domain/friend.dart';
import '../../friends/domain/user_notification.dart';
import '../../../shared/widgets/owner_avatar.dart';

/// Modal bottom sheet providing a full Inbox for incoming friend requests,
/// cellar access requests, and notifications, with support for "Dismiss / Pour plus tard".
class NotificationsInboxSheet extends ConsumerStatefulWidget {
  const NotificationsInboxSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsInboxSheet(),
    );
  }

  @override
  ConsumerState<NotificationsInboxSheet> createState() => _NotificationsInboxSheetState();
}

class _NotificationsInboxSheetState extends ConsumerState<NotificationsInboxSheet> {
  bool _isProcessing = false;

  Future<void> _refresh() async {
    refreshFriendsAndNotifications(ref);
  }

  Future<void> _acceptFriend(Friend friend) async {
    setState(() => _isProcessing = true);
    final repo = ref.read(friendsRepositoryProvider);
    try {
      await repo.acceptFriendRequest(friend.id, friend.friendUserId);
      refreshFriendsAndNotifications(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Vous êtes désormais ami avec ${friend.displayName} !'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _declineFriend(Friend friend) async {
    setState(() => _isProcessing = true);
    final repo = ref.read(friendsRepositoryProvider);
    try {
      await repo.declineFriendRequest(friend.id);
      refreshFriendsAndNotifications(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami déclinée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _dismissForLater(String id, String label) async {
    await ref.read(dismissedNotificationIdsProvider.notifier).dismiss(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label mis de côté pour plus tard ⏱️'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _respondCellarRequest(CellarAccessRequest req, bool accept, String role) async {
    setState(() => _isProcessing = true);
    final repo = ref.read(friendsRepositoryProvider);
    try {
      await repo.respondCellarAccess(
        requestId: req.id,
        cellarId: req.cellarId,
        requesterId: req.requesterId,
        accept: accept,
        role: role,
        cellarName: req.cellarName,
      );
      refreshFriendsAndNotifications(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? '🍾 Accès accordé à ${req.requesterName} (${role == "editor" ? "Sommelier" : "Lecteur"}) !'
                  : 'Demande d\'accès refusée.',
            ),
            backgroundColor: accept ? const Color(0xFF10B981) : Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markAllRead() async {
    final repo = ref.read(friendsRepositoryProvider);
    await repo.markAllNotificationsRead();
    refreshFriendsAndNotifications(ref);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final incomingFriendsAsync = ref.watch(pendingIncomingRequestsProvider);
    final incomingCellarAsync = ref.watch(incomingCellarRequestsProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final dismissedIds = ref.watch(dismissedNotificationIdsProvider);

    final allFriends = incomingFriendsAsync.valueOrNull ?? [];
    final allCellar = incomingCellarAsync.valueOrNull ?? [];
    final allNotifs = notificationsAsync.valueOrNull ?? [];

    // Filter active items vs dismissed for later
    final activeFriends = allFriends.where((f) => !dismissedIds.contains(f.id) && !dismissedIds.contains(f.friendUserId)).toList();
    final activeCellar = allCellar.where((c) => !dismissedIds.contains(c.id)).toList();
    final activeNotifs = allNotifs.where((n) => !dismissedIds.contains(n.id)).toList();
    final snoozedCount = (allFriends.length - activeFriends.length) + (allCellar.length - activeCellar.length);

    final totalCount = activeFriends.length + activeCellar.length + activeNotifs.where((n) => !n.isRead).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Color(0xFFD4AF37), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Boîte de réception',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (totalCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1E3F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalCount',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Actualiser',
                  onPressed: _refresh,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Demandes d'amis
                  if (activeFriends.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: '👥 Demandes d\'amis (${activeFriends.length})',
                      color: const Color(0xFF8B1E3F),
                    ),
                    const SizedBox(height: 8),
                    ...activeFriends.map((f) => _buildFriendRequestCard(f, isDark)),
                    const SizedBox(height: 16),
                  ],

                  // 2. Demandes d'accès cave
                  if (activeCellar.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: '🍷 Demandes d\'accès à votre Cave (${activeCellar.length})',
                      color: const Color(0xFFD4AF37),
                    ),
                    const SizedBox(height: 8),
                    ...activeCellar.map((c) => _buildCellarRequestCard(c, isDark)),
                    const SizedBox(height: 16),
                  ],

                  // 3. Notifications récentes
                  if (activeNotifs.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(
                          context,
                          title: '🔔 Activité récente',
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        TextButton(
                          onPressed: _markAllRead,
                          child: const Text('Tout marquer comme lu', style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...activeNotifs.map((n) => _buildNotificationTile(n, isDark)),
                    const SizedBox(height: 16),
                  ],

                  // Empty State
                  if (activeFriends.isEmpty && activeCellar.isEmpty && activeNotifs.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Votre boîte de réception est vide',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Les demandes d\'amis, invitations et partages de cave apparaîtront ici.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Snoozed items notice
                  if (snoozedCount > 0) ...[
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: Text('Afficher les $snoozedCount élément(s) mis de côté'),
                        onPressed: () {
                          ref.read(dismissedNotificationIdsProvider.notifier).clearAll();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required Color color}) {
    return Text(
      title,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: color),
    );
  }

  // ---------------------------------------------------------------------------
  // Friend Request Card
  // ---------------------------------------------------------------------------
  Widget _buildFriendRequestCard(Friend friend, bool isDark) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF8B1E3F).withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OwnerAvatar(userId: friend.friendUserId, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        friend.handle,
                        style: const TextStyle(color: Color(0xFF8B1E3F), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatRelativeDate(friend.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Souhaite devenir votre ami pour échanger vos goûts et partager vos caves.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accepter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _isProcessing ? null : () => _acceptFriend(friend),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  ),
                  onPressed: _isProcessing ? null : () => _declineFriend(friend),
                  child: const Text('Refuser', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.snooze, size: 19, color: Colors.grey),
                  tooltip: 'Garder pour plus tard',
                  onPressed: () => _dismissForLater(friend.id, 'Demande de ${friend.displayName}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cellar Access Request Card
  // ---------------------------------------------------------------------------
  Widget _buildCellarRequestCard(CellarAccessRequest req, bool isDark) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OwnerAvatar(userId: req.requesterId, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.requesterName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Demande l\'accès à "${req.cellarName ?? "Ma Cave"}"',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4AF37)),
                  ),
                  child: Text(
                    req.requestedRole == 'editor' ? '✍️ Sommelier' : '👁️ Lecteur',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                  ),
                ),
              ],
            ),
            if (req.message != null && req.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '« ${req.message} »',
                  style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      'Accorder (${req.requestedRole == "editor" ? "Sommelier" : "Lecteur"})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _respondCellarRequest(req, true, req.requestedRole),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  ),
                  onPressed: _isProcessing
                      ? null
                      : () => _respondCellarRequest(req, false, 'none'),
                  child: const Text('Refuser', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.snooze, size: 19, color: Colors.grey),
                  tooltip: 'Garder pour plus tard',
                  onPressed: () => _dismissForLater(req.id, 'Demande de cave de ${req.requesterName}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification Tile
  // ---------------------------------------------------------------------------
  Widget _buildNotificationTile(UserNotification notif, bool isDark) {
    IconData iconData = Icons.notifications;
    Color iconColor = const Color(0xFFD4AF37);

    if (notif.type == 'friend_accepted') {
      iconData = Icons.person_add_alt_1;
      iconColor = const Color(0xFF10B981);
    } else if (notif.type == 'cellar_granted') {
      iconData = Icons.wine_bar;
      iconColor = const Color(0xFFD4AF37);
    } else if (notif.type == 'cellar_request') {
      iconData = Icons.vpn_key;
      iconColor = const Color(0xFF8B1E3F);
    }

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      color: notif.isRead
          ? (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02))
          : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F6F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notif.body,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              _formatRelativeDate(notif.createdAt),
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
            ),
          ],
        ),
        trailing: notif.isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.done, size: 18, color: Colors.grey),
                tooltip: 'Marquer comme lu',
                onPressed: () async {
                  await ref.read(friendsRepositoryProvider).markNotificationRead(notif.id);
                  refreshFriendsAndNotifications(ref);
                },
              ),
      ),
    );
  }

  String _formatRelativeDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
