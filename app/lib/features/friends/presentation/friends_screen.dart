import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../auth/domain/user_profile.dart';
import '../data/friends_repository.dart';
import '../domain/cellar_access_request.dart';
import '../domain/friend.dart';
import '../domain/user_notification.dart';
import 'friend_taste_card_sheet.dart';
import 'contact_invite_sheet.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  final Set<String> _sentRequestUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final repo = ref.read(authRepositoryProvider);
    final results = await repo.searchUsers(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _sendFriendRequest(UserProfile user) async {
    final friendsRepo = ref.read(friendsRepositoryProvider);
    try {
      await friendsRepo.sendFriendRequest(user);
      ref.invalidate(pendingOutgoingRequestsProvider);

      if (mounted) {
        setState(() => _sentRequestUserIds.add(user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📬 Demande d\'ami envoyée à ${user.displayName} !'),
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
    }
  }

  Future<void> _acceptFriend(Friend friend) async {
    final friendsRepo = ref.read(friendsRepositoryProvider);
    try {
      await friendsRepo.acceptFriendRequest(friend.id, friend.friendUserId);
      ref.invalidate(friendsListProvider);
      ref.invalidate(pendingIncomingRequestsProvider);
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
    }
  }

  Future<void> _declineFriend(Friend friend) async {
    final friendsRepo = ref.read(friendsRepositoryProvider);
    try {
      await friendsRepo.declineFriendRequest(friend.id);
      ref.invalidate(pendingIncomingRequestsProvider);
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
    }
  }

  Future<void> _respondCellarRequest(CellarAccessRequest req, bool accept, String role) async {
    final friendsRepo = ref.read(friendsRepositoryProvider);
    try {
      await friendsRepo.respondCellarAccess(
        requestId: req.id,
        cellarId: req.cellarId,
        requesterId: req.requesterId,
        accept: accept,
        role: role,
        cellarName: req.cellarName,
      );
      ref.invalidate(incomingCellarRequestsProvider);
      ref.invalidate(friendsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? '🍾 Accès à la cave accordé !' : 'Demande d\'accès refusée.'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final friendsAsync = ref.watch(friendsListProvider);
    final incomingFriendsAsync = ref.watch(pendingIncomingRequestsProvider);
    final incomingCellarAsync = ref.watch(incomingCellarRequestsProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider);

    final incomingFriendsCount = incomingFriendsAsync.valueOrNull?.length ?? 0;
    final incomingCellarCount = incomingCellarAsync.valueOrNull?.length ?? 0;
    final totalPending = incomingFriendsCount + incomingCellarCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amis & Caves Partagées'),
        actions: const [
          NotificationBellButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD4AF37),
          indicatorColor: const Color(0xFFD4AF37),
          tabs: [
            const Tab(icon: Icon(Icons.people_alt), text: 'Mes Amis'),
            Tab(
              icon: Badge(
                isLabelVisible: totalPending > 0,
                label: Text('$totalPending'),
                backgroundColor: const Color(0xFFD4AF37),
                textColor: Colors.black,
                child: const Icon(Icons.notifications_active_outlined),
              ),
              text: 'Demandes & Notifs',
            ),
            const Tab(icon: Icon(Icons.person_add_alt_1), text: 'Rechercher'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. MES AMIS
          friendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur: $err')),
            data: (friends) => _buildFriendsList(friends, isDark),
          ),

          // 2. DEMANDES & NOTIFICATIONS
          _buildRequestsAndNotificationsTab(
            incomingFriends: incomingFriendsAsync.valueOrNull ?? [],
            incomingCellar: incomingCellarAsync.valueOrNull ?? [],
            notifications: notificationsAsync.valueOrNull ?? [],
            isDark: isDark,
          ),

          // 3. RECHERCHER UN AMI
          _buildSearchTab(isDark, friendsAsync.valueOrNull ?? []),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Mes Amis
  // ---------------------------------------------------------------------------
  Widget _buildFriendsList(List<Friend> friends, bool isDark) {
    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🍷', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'Aucun ami pour le moment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 6),
              const Text(
                'Invitez vos proches par pseudo, téléphone ou email pour découvrir leurs goûts et partager vos caves !',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Rechercher un ami'),
                onPressed: () => _tabController.animateTo(2),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final friend = friends[index];
        final taste = friend.tasteProfile;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => FriendTasteCardSheet.show(context, friend),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                              style: const TextStyle(color: Color(0xFF8B1E3F), fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (friend.hasCellarAccess)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            friend.cellarAccessRole == 'editor' ? 'Cave ✍️' : 'Cave 👁️',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (val) async {
                          if (val == 'taste') {
                            FriendTasteCardSheet.show(context, friend);
                          } else if (val == 'remove') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Retirer cet ami ?'),
                                content: Text('Voulez-vous retirer ${friend.displayName} de vos amis ?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Retirer', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(friendsRepositoryProvider).removeFriend(friend.friendUserId);
                              ref.invalidate(friendsListProvider);
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'taste', child: Text('Voir la Carte des Goûts 🍷')),
                          const PopupMenuItem(value: 'remove', child: Text('Retirer des amis', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Grapes / Regions summary chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (taste.favoriteGrapes.isNotEmpty)
                        ...taste.favoriteGrapes.take(2).map((g) => _buildMiniChip('🍇 $g', isDark)),
                      if (taste.favoriteRegions.isNotEmpty)
                        ...taste.favoriteRegions.take(2).map((r) => _buildMiniChip('🗺️ $r', isDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFD4AF37)),
                          label: const Text('Carte des Goûts', style: TextStyle(fontSize: 12)),
                          onPressed: () => FriendTasteCardSheet.show(context, friend),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: friend.hasCellarAccess ? const Color(0xFF10B981) : const Color(0xFF8B1E3F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: Icon(friend.hasCellarAccess ? Icons.check_circle : Icons.card_giftcard, size: 16),
                          label: Text(
                            friend.hasCellarAccess ? 'Accès Partagé' : 'Partager ma cave',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _showGrantCellarDialog(friend),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGrantCellarDialog(Friend friend) {
    String selectedRole = friend.cellarAccessRole == 'editor' ? 'editor' : 'viewer';
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
                  'Partager ma cave avec ${friend.displayName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez les droits d\'accès pour cette personne :',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('Consultation (Lecteur 👁️)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('Peut voir votre cave, vos bouteilles et vos fiches de dégustation.', style: TextStyle(fontSize: 11)),
                value: 'viewer',
                groupValue: selectedRole,
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: const Text('Sommelier Délégué (Éditeur ✍️)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('Peut ajouter, déplacer et consommer des bouteilles dans votre cave.', style: TextStyle(fontSize: 11)),
                value: 'editor',
                groupValue: selectedRole,
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  await ref.read(friendsRepositoryProvider).grantCellarAccessDirectly(
                    cellarId: '', // Automatically resolved to current user's cellar
                    friendUserId: friend.friendUserId,
                    role: selectedRole,
                  );
                  ref.invalidate(friendsListProvider);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('🍾 Accès à votre cave accordé à ${friend.displayName} !'),
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

  // ---------------------------------------------------------------------------
  // Tab 2: Demandes & Notifications Hub
  // ---------------------------------------------------------------------------
  Widget _buildRequestsAndNotificationsTab({
    required List<Friend> incomingFriends,
    required List<CellarAccessRequest> incomingCellar,
    required List<UserNotification> notifications,
    required bool isDark,
  }) {
    if (incomingFriends.isEmpty && incomingCellar.isEmpty && notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Aucune demande en attente',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Vous recevrez ici les demandes d\'amis et les demandes d\'accès à vos caves.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Demandes d'amis reçues
        if (incomingFriends.isNotEmpty) ...[
          _buildSectionTitle('👥 Demandes d\'amis reçues (${incomingFriends.length})'),
          const SizedBox(height: 8),
          ...incomingFriends.map((f) => _buildIncomingFriendCard(f, isDark)),
          const SizedBox(height: 18),
        ],

        // 2. Demandes d'accès cave reçues
        if (incomingCellar.isNotEmpty) ...[
          _buildSectionTitle('🍷 Demandes d\'accès à votre Cave (${incomingCellar.length})'),
          const SizedBox(height: 8),
          ...incomingCellar.map((req) => _buildIncomingCellarCard(req, isDark)),
          const SizedBox(height: 18),
        ],

        // 3. Notifications récentes
        if (notifications.isNotEmpty) ...[
          _buildSectionTitle('🔔 Notifications récentes'),
          const SizedBox(height: 8),
          ...notifications.map((n) => _buildNotificationCard(n, isDark)),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFD4AF37)),
    );
  }

  Widget _buildIncomingFriendCard(Friend friend, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            OwnerAvatar(userId: friend.friendUserId, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(friend.handle, style: const TextStyle(color: Color(0xFF8B1E3F), fontSize: 12)),
                  const SizedBox(height: 2),
                  const Text('Souhaite devenir votre ami', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              tooltip: 'Décliner',
              onPressed: () => _declineFriend(friend),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _acceptFriend(friend),
              child: const Text('Accepter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingCellarCard(CellarAccessRequest req, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OwnerAvatar(userId: req.requesterId, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.requesterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        'Demande l\'accès à "${req.cellarName ?? "Ma Cave"}"',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    req.requestedRole == 'editor' ? '✍️ Sommelier' : '👁️ Consultation',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                  ),
                ),
              ],
            ),
            if (req.message != null && req.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('"${req.message}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _respondCellarRequest(req, false, 'viewer'),
                  child: const Text('Refuser', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Accepter (${req.requestedRole == "editor" ? "Éditeur" : "Lecteur"})'),
                  onPressed: () => _respondCellarRequest(req, true, req.requestedRole),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(UserNotification notif, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🍇 ', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(notif.body, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Rechercher un ami
  // ---------------------------------------------------------------------------
  Widget _buildSearchTab(bool isDark, List<Friend> existingFriends) {
    final existingUserIds = existingFriends.map((f) => f.friendUserId).toSet();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.contacts, size: 20),
              label: const Text('Chercher depuis mes contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              onPressed: () => ContactInviteSheet.show(context, existingUserIds),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par @pseudo, nom, tél ou email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) => _performSearch(val),
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )
        else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Aucun utilisateur trouvé.', style: TextStyle(color: Colors.grey)),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final isAlreadyFriend = existingUserIds.contains(user.id);
                final hasSentRequest = _sentRequestUserIds.contains(user.id);

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: OwnerAvatar(userId: user.id, radius: 20),
                    title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '@${user.username ?? user.displayName.toLowerCase()}',
                      style: const TextStyle(color: Color(0xFF8B1E3F), fontSize: 12),
                    ),
                    trailing: isAlreadyFriend
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Déjà ami', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        : hasSentRequest
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('⏳ Envoyée', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B1E3F),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: const Icon(Icons.person_add, size: 14),
                                label: const Text('Inviter', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                onPressed: () => _sendFriendRequest(user),
                              ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMiniChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
