import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/cellar_access_request.dart';
import '../../friends/domain/friend.dart';
import '../../friends/domain/user_notification.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/langue.dart';

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
            content: Text(tr('🎉 Vous êtes désormais ami avec {displayName} !', '🎉 You\'re now friends with {displayName}!', {'displayName': friend.displayName})),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e})), backgroundColor: Colors.redAccent),
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
          SnackBar(content: Text(tr('Demande d\'ami déclinée.', 'Friend request declined.'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e})), backgroundColor: Colors.redAccent),
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
          content: Text(tr('{label} mis de côté pour plus tard ⏱️', '{label} saved for later ⏱️', {'label': label})),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _respondCellarRequest(CellarAccessRequest req, bool accept, String role) async {
    // Immediately dismiss from local state so badge and card vanish instantly
    await ref.read(dismissedNotificationIdsProvider.notifier).dismiss(req.id);
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
                  ? tr('🍾 Accès accordé à {requesterName} ({v1}) !', '🍾 Access granted to {requesterName} ({v1})!', {'requesterName': req.requesterName, 'v1': role == "editor" ? tr('Sommelier', 'Sommelier') : tr('Lecteur', 'Viewer')})
                  : tr('Demande d\'accès refusée.', 'Access request declined.'),
            ),
            backgroundColor: accept ? const Color(0xFF10B981) : Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e})), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showGrantCellarAccessDialog(CellarAccessRequest req) async {
    final cellars = await ref.read(cellarRepositoryProvider).getUserCellarsWithRole();
    final ownedCellars = cellars.where((c) => c['role'] == 'admin').toList();

    if (!mounted) return;

    if (ownedCellars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Aucune cave propriétaire trouvée.', 'No cellar of yours found.'))),
      );
      return;
    }

    // Default: ONLY check the requested cellar (or the first one if not matched).
    // All other cellars are UNCHECKED by default!
    final Map<String, bool> selectedCellars = {};
    final Map<String, String> selectedRoles = {};

    bool hasRequestedMatch = false;
    for (final c in ownedCellars) {
      final cMap = c['cellars'] is Map<String, dynamic> ? c['cellars'] as Map<String, dynamic> : c;
      final cId = (cMap['id'] ?? c['cellar_id'] ?? '').toString();
      final isRequested = (cId == req.cellarId) || (req.cellarId.isEmpty && !hasRequestedMatch);
      if (isRequested) hasRequestedMatch = true;
      selectedCellars[cId] = isRequested;
      selectedRoles[cId] = isRequested ? req.requestedRole : 'editor';
    }

    if (!selectedCellars.values.any((v) => v)) {
      final firstCMap = ownedCellars.first['cellars'] is Map<String, dynamic>
          ? ownedCellars.first['cellars'] as Map<String, dynamic>
          : ownedCellars.first;
      final firstId = (firstCMap['id'] ?? ownedCellars.first['cellar_id'] ?? '').toString();
      selectedCellars[firstId] = true;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final theme = Theme.of(dialogCtx);
            final anySelected = selectedCellars.values.any((v) => v);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Partager mes caves', 'Share my cellars'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          tr('avec {requesterName}', 'with {requesterName}', {'requesterName': req.requesterName}),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Choisissez quelle(s) cave(s) partager et l\'accès pour chacune :', 'Choose which cellar(s) to share, and the access for each:'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...ownedCellars.map((item) {
                      final cMap = item['cellars'] is Map<String, dynamic>
                          ? item['cellars'] as Map<String, dynamic>
                          : item;
                      final cId = (cMap['id'] ?? item['cellar_id'] ?? '').toString();
                      final cName = cMap['name']?.toString() ?? tr('Cave', 'Cellar');
                      final isChecked = selectedCellars[cId] ?? false;
                      final currentRole = selectedRoles[cId] ?? 'editor';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? const Color(0xFF10B981).withValues(alpha: 0.08)
                              : Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isChecked
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      selectedCellars[cId] = val ?? false;
                                    });
                                  },
                                ),
                                const Icon(Icons.wine_bar, size: 20, color: Color(0xFF8B1E3F)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cName,
                                    style: TextStyle(
                                      fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isChecked) ...[
                              const Divider(height: 12),
                              Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr('Accès :', 'Access:'),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                    ),
                                    DropdownButton<String>(
                                      value: currentRole,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'editor',
                                          child: Text(tr('✍️ Sommelier (Écriture)', '✍️ Sommelier (write)'), style: const TextStyle(fontSize: 12.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'viewer',
                                          child: Text(tr('👁️ Lecteur (Lecture)', '👁️ Viewer (read)'), style: const TextStyle(fontSize: 12.5)),
                                        ),
                                      ],
                                      onChanged: (newRole) {
                                        if (newRole != null) {
                                          setDialogState(() {
                                            selectedRoles[cId] = newRole;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(tr('Annuler', 'Cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: anySelected
                      ? () async {
                          Navigator.of(dialogCtx).pop();
                          await _executeMultiCellarGrant(
                            req: req,
                            selectedCellars: selectedCellars,
                            selectedRoles: selectedRoles,
                            ownedCellars: ownedCellars,
                          );
                        }
                      : null,
                  child: Text(tr('Confirmer le partage', 'Confirm sharing'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeMultiCellarGrant({
    required CellarAccessRequest req,
    required Map<String, bool> selectedCellars,
    required Map<String, String> selectedRoles,
    required List<Map<String, dynamic>> ownedCellars,
  }) async {
    // 1. Instantly dismiss locally so card vanishes
    await ref.read(dismissedNotificationIdsProvider.notifier).dismiss(req.id);
    setState(() => _isProcessing = true);

    final repo = ref.read(friendsRepositoryProvider);
    int grantedCount = 0;

    try {
      // 2. Grant access for each selected cellar
      for (final item in ownedCellars) {
        final cMap = item['cellars'] is Map<String, dynamic> ? item['cellars'] as Map<String, dynamic> : item;
        final cId = (cMap['id'] ?? item['cellar_id'] ?? '').toString();
        final isChecked = selectedCellars[cId] ?? false;
        if (isChecked && cId.isNotEmpty) {
          final role = selectedRoles[cId] ?? 'editor';
          final cName = cMap['name']?.toString() ?? tr('Ma Cave', 'My cellar');
          await repo.grantCellarAccessDirectly(
            cellarId: cId,
            friendUserId: req.requesterId,
            role: role,
            cellarName: cName,
          );
          grantedCount++;
        }
      }

      // 3. Mark the access request as accepted
      await repo.respondCellarAccess(
        requestId: req.id,
        cellarId: req.cellarId,
        requesterId: req.requesterId,
        accept: true,
        role: req.requestedRole,
        cellarName: req.cellarName,
      );

      refreshFriendsAndNotifications(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('🍾 Accès accordé pour {grantedCount} cave(s) à {requesterName} !', '🍾 Access to {grantedCount} cellar(s) granted to {requesterName}!', {'grantedCount': grantedCount, 'requesterName': req.requesterName})),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur : {e}', 'Error: {e}', {'e': e})), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _dismissCellarRequest(CellarAccessRequest req) async {
    await ref.read(dismissedNotificationIdsProvider.notifier).dismiss(req.id);
    final repo = ref.read(friendsRepositoryProvider);
    try {
      await repo.dismissCellarRequest(requestId: req.id, requesterId: req.requesterId);
      refreshFriendsAndNotifications(ref);
    } catch (_) {}
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
                      Text(
                        tr('Boîte de réception', 'Inbox'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                  tooltip: tr('Actualiser', 'Refresh'),
                  onPressed: _refresh,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: tr('Fermer', 'Close'),
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
                      title: tr('👥 Demandes d\'amis ({activeFriends_length})', '👥 Friend requests ({activeFriends_length})', {'activeFriends_length': activeFriends.length}),
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
                      title: tr('🍷 Demandes d\'accès à votre Cave ({activeCellar_length})', '🍷 Requests to access your cellar ({activeCellar_length})', {'activeCellar_length': activeCellar.length}),
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
                          title: tr('🔔 Activité récente', '🔔 Recent activity'),
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        TextButton(
                          onPressed: _markAllRead,
                          child: Text(tr('Tout marquer comme lu', 'Mark all as read'), style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
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
                          Text(
                            tr('Votre boîte de réception est vide', 'Your inbox is empty'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr('Les demandes d\'amis, invitations et partages de cave apparaîtront ici.', 'Friend requests, invitations and shared cellars will show up here.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                        label: Text(tr('Afficher les {snoozedCount} élément(s) mis de côté', 'Show the {snoozedCount} item(s) saved for later', {'snoozedCount': snoozedCount})),
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
            Text(
              tr('Souhaite devenir votre ami pour échanger vos goûts et partager vos caves.', 'Would like to be your friend, to compare tastes and share cellars.'),
              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
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
                    label: Text(tr('Accepter', 'Accept'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                  child: Text(tr('Refuser', 'Decline'), style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.snooze, size: 19, color: Colors.grey),
                  tooltip: tr('Garder pour plus tard', 'Keep for later'),
                  onPressed: () => _dismissForLater(friend.id, tr('Demande de {displayName}', 'Request from {displayName}', {'displayName': friend.displayName})),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  tooltip: tr('Fermer / Ignorer', 'Close / ignore'),
                  onPressed: _isProcessing ? null : () async {
                    await ref.read(dismissedNotificationIdsProvider.notifier).dismiss(friend.id);
                    await _declineFriend(friend);
                  },
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
                        tr('Demande l\'accès à "{v1}"', 'Asks for access to "{v2}"', {'v1': req.cellarName ?? 'Ma Cave', 'v2': req.cellarName ?? 'My cellar'}),
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
                    req.requestedRole == 'editor' ? tr('✍️ Sommelier', '✍️ Sommelier') : tr('👁️ Lecteur', '👁️ Viewer'),
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
                      tr('Accorder l\'accès ({v1})', 'Grant access ({v1})', {'v1': req.requestedRole == "editor" ? tr('Sommelier', 'Sommelier') : tr('Lecteur', 'Viewer')}),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _showGrantCellarAccessDialog(req),
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
                  child: Text(tr('Refuser', 'Decline'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.snooze, size: 19, color: Colors.grey),
                  tooltip: tr('Garder pour plus tard', 'Keep for later'),
                  onPressed: () => _dismissForLater(req.id, tr('Demande de cave de {requesterName}', 'Cellar request from {requesterName}', {'requesterName': req.requesterName})),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  tooltip: tr('Fermer / Ignorer', 'Close / ignore'),
                  onPressed: _isProcessing ? null : () => _dismissCellarRequest(req),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notif.isRead)
              IconButton(
                icon: const Icon(Icons.done, size: 18, color: Colors.grey),
                tooltip: tr('Marquer comme lu', 'Mark as read'),
                onPressed: () async {
                  await ref.read(friendsRepositoryProvider).markNotificationRead(notif.id);
                  refreshFriendsAndNotifications(ref);
                },
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              tooltip: tr('Supprimer', 'Delete'),
              onPressed: () async {
                await ref.read(friendsRepositoryProvider).deleteNotification(notif.id);
                refreshFriendsAndNotifications(ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return tr('À l\'instant', 'Just now');
    if (diff.inMinutes < 60) return tr('Il y a {inMinutes} min', '{inMinutes} min ago', {'inMinutes': diff.inMinutes});
    if (diff.inHours < 24) return tr('Il y a {inHours} h', '{inHours} h ago', {'inHours': diff.inHours});
    if (diff.inDays < 7) return tr('Il y a {inDays} j', '{inDays} d ago', {'inDays': diff.inDays});
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
