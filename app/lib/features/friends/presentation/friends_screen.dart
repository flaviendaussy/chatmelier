import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../auth/domain/user_profile.dart';
import '../data/friends_repository.dart';
import '../domain/cellar_access_request.dart';
import '../domain/friend.dart';
import '../domain/user_notification.dart';
import 'friend_taste_card_sheet.dart';
import 'contact_invite_sheet.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/utils/valeurs_rangees.dart';

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
    final List<UserProfile> results;
    try {
      results = await repo.searchUsers(query);
    } catch (_) {
      // La recherche a échoué : on le dit, plutôt que « aucun résultat ».
      if (mounted) {
        setState(() => _isSearching = false);
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trSi(isFr, 'Recherche impossible pour le moment. Vérifiez votre connexion et réessayez.', 'Search is unavailable right now. Check your connection and try again.')),
        ));
      }
      return;
    }

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
            content: Text(tr('📬 Demande d\'ami envoyée à {displayName} !', '📬 Friend request sent to {displayName}!', {'displayName': user.displayName})),
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
    }
  }

  Future<void> _declineFriend(Friend friend) async {
    final friendsRepo = ref.read(friendsRepositoryProvider);
    try {
      await friendsRepo.declineFriendRequest(friend.id);
      ref.invalidate(pendingIncomingRequestsProvider);
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
            content: Text(accept ? tr('🍾 Accès à la cave accordé !', '🍾 Cellar access granted!') : tr('Demande d\'accès refusée.', 'Access request declined.')),
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
        title: Text(tr('Amis & Caves Partagées', 'Friends & shared cellars')),
        actions: const [
          NotificationBellButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD4AF37),
          indicatorColor: const Color(0xFFD4AF37),
          tabs: [
            Tab(icon: const Icon(Icons.people_alt), text: tr('Mes Amis', 'My friends')),
            Tab(
              icon: Badge(
                isLabelVisible: totalPending > 0,
                label: Text('$totalPending'),
                backgroundColor: const Color(0xFFD4AF37),
                textColor: Colors.black,
                child: const Icon(Icons.notifications_active_outlined),
              ),
              text: tr('Demandes & Notifs', 'Requests'),
            ),
            Tab(icon: const Icon(Icons.person_add_alt_1), text: tr('Rechercher', 'Search')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. MES AMIS
          friendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(tr('Erreur: {err}', 'Error: {err}', {'err': err}))),
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
              Text(
                tr('Aucun ami pour le moment', 'No friends yet'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                tr('Invitez vos proches par pseudo, téléphone ou email pour découvrir leurs goûts et partager vos caves !', 'Invite people you know by username, phone or email to discover their tastes and share your cellars!'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                label: Text(tr('Rechercher un ami', 'Find a friend')),
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
                      OwnerAvatar(userId: friend.friendUserId, displayName: friend.displayName, avatarUrl: friend.avatarUrl, radius: 22),
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
                            friend.cellarAccessRole == 'editor' ? tr('Cave ✍️', 'Cellar ✍️') : tr('Cave 👁️', 'Cellar 👁️'),
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
                                title: Text(tr('Retirer cet ami ?', 'Remove this friend?')),
                                content: Text(tr('Voulez-vous retirer {displayName} de vos amis ?', 'Remove {displayName} from your friends?', {'displayName': friend.displayName})),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Annuler', 'Cancel'))),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(tr('Retirer', 'Remove'), style: const TextStyle(color: Colors.red)),
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
                          PopupMenuItem(value: 'taste', child: Text(tr('Voir la Carte des Goûts 🍷', 'See their taste card 🍷'))),
                          PopupMenuItem(value: 'remove', child: Text(tr('Retirer des amis', 'Remove from friends'), style: const TextStyle(color: Colors.red))),
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
                        ...taste.favoriteRegions.take(2).map((r) => _buildMiniChip('🗺️ ${valeurAffichee(r)}', isDark)),
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
                          label: Text(tr('Carte des Goûts', 'Taste card'), style: const TextStyle(fontSize: 12)),
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
                            friend.hasCellarAccess ? tr('Accès Partagé', 'Shared access') : tr('Partager ma cave', 'Share my cellar'),
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

    // Sans cave à soi (ni cave dont on est administrateur), il n'y a rien à partager :
    // le dire avant d'ouvrir le dialogue (Caro, 04/10).
    final moi = ref.read(currentUserProvider)?.id;
    final caves = ref.read(userCellarsProvider).valueOrNull;
    if (caves != null &&
        !caves.any((c) => c['role'] == 'admin' || (c['cellars'] is Map && (c['cellars'] as Map)['owner_id'] == moi))) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Pas encore de cave', 'No cellar yet')),
          content: Text(const AucuneCaveAPartager().toString()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Plus tard', 'Later'))),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/');
              },
              child: Text(tr('Aller à ma cave', 'Go to my cellar')),
            ),
          ],
        ),
      );
      return;
    }

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
                  tr('Partager ma cave avec {displayName}', 'Share my cellar with {displayName}', {'displayName': friend.displayName}),
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
                tr('Choisissez les droits d\'accès pour cette personne :', 'Choose what this person can do:'),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: Text(tr('Consultation (Lecteur 👁️)', 'View only (viewer 👁️)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text(tr('Peut voir votre cave, vos bouteilles et vos fiches de dégustation.', 'Can see your cellar, your bottles and your tasting notes.'), style: const TextStyle(fontSize: 11)),
                value: 'viewer',
                groupValue: selectedRole,
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: Text(tr('Sommelier Délégué (Éditeur ✍️)', 'Deputy sommelier (editor ✍️)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text(tr('Peut ajouter, déplacer et consommer des bouteilles dans votre cave.', 'Can add, move and drink bottles in your cellar.'), style: const TextStyle(fontSize: 11)),
                value: 'editor',
                groupValue: selectedRole,
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(tr('Annuler', 'Cancel')),
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
                        content: Text(tr('🍾 Accès à votre cave accordé à {displayName} !', '🍾 {displayName} now has access to your cellar!', {'displayName': friend.displayName})),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(e is AucuneCaveAPartager ? '$e' : tr('Erreur: {e}', 'Error: {e}', {'e': e})),
                        backgroundColor: e is AucuneCaveAPartager ? null : Colors.redAccent,
                      ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_none, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                tr('Aucune demande en attente', 'No pending requests'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                tr('Vous recevrez ici les demandes d\'amis et les demandes d\'accès à vos caves.', 'Friend requests and requests to access your cellars will show up here.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
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
          _buildSectionTitle(tr('👥 Demandes d\'amis reçues ({incomingFriends_length})', '👥 Friend requests ({incomingFriends_length})', {'incomingFriends_length': incomingFriends.length})),
          const SizedBox(height: 8),
          ...incomingFriends.map((f) => _buildIncomingFriendCard(f, isDark)),
          const SizedBox(height: 18),
        ],

        // 2. Demandes d'accès cave reçues
        if (incomingCellar.isNotEmpty) ...[
          _buildSectionTitle(tr('🍷 Demandes d\'accès à votre Cave ({incomingCellar_length})', '🍷 Requests to access your cellar ({incomingCellar_length})', {'incomingCellar_length': incomingCellar.length})),
          const SizedBox(height: 8),
          ...incomingCellar.map((req) => _buildIncomingCellarCard(req, isDark)),
          const SizedBox(height: 18),
        ],

        // 3. Notifications récentes
        if (notifications.isNotEmpty) ...[
          _buildSectionTitle(tr('🔔 Notifications récentes', '🔔 Recent notifications')),
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
            OwnerAvatar(userId: friend.friendUserId, displayName: friend.displayName, avatarUrl: friend.avatarUrl, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(friend.handle, style: const TextStyle(color: Color(0xFF8B1E3F), fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(tr('Souhaite devenir votre ami', 'Would like to be your friend'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              tooltip: tr('Décliner', 'Decline'),
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
              child: Text(tr('Accepter', 'Accept'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                OwnerAvatar(userId: req.requesterId, displayName: req.requesterName, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.requesterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        tr('Demande l\'accès à "{v1}"', 'Asks for access to "{v1}"', {'v1': req.cellarName ?? tr('Ma Cave', 'My cellar')}),
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
                    req.requestedRole == 'editor' ? tr('✍️ Sommelier', '✍️ Sommelier') : tr('👁️ Consultation', '👁️ View only'),
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
                  child: Text(tr('Refuser', 'Decline'), style: const TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(tr('Accepter ({v1})', 'Accept ({v1})', {'v1': req.requestedRole == "editor" ? tr('Éditeur', 'editor') : tr('Lecteur', 'viewer')})),
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
                Text(notif.titreLu, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(notif.corpsLu, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
              label: Text(tr('Inviter un proche', 'Invite someone'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              onPressed: () => ContactInviteSheet.show(context, existingUserIds),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: tr('Rechercher par @pseudo, nom, tél ou email...', 'Search by @username, name, phone or email...'),
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(tr('Aucun utilisateur trouvé.', 'No one found.'), style: const TextStyle(color: Colors.grey)),
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
                    leading: OwnerAvatar(userId: user.id, displayName: user.displayName, avatarUrl: user.avatarUrl, radius: 20),
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
                            child: Text(tr('Déjà ami', 'Already friends'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        : hasSentRequest
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(tr('⏳ Envoyée', '⏳ Sent'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B1E3F),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: const Icon(Icons.person_add, size: 14),
                                label: Text(tr('Inviter', 'Invite'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
