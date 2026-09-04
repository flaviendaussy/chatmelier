import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/domain/user_profile.dart';
import '../domain/cellar_access_request.dart';
import '../domain/friend.dart';
import '../domain/user_notification.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return FriendsRepository(client);
});

final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getFriends();
});

final pendingIncomingRequestsProvider = FutureProvider<List<Friend>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getPendingIncomingRequests();
});

final pendingOutgoingRequestsProvider = FutureProvider<List<Friend>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getPendingOutgoingRequests();
});

final incomingCellarRequestsProvider = FutureProvider<List<CellarAccessRequest>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getIncomingCellarRequests();
});

final userNotificationsProvider = FutureProvider<List<UserNotification>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getUserNotifications();
});

/// Tracks IDs of notifications / requests dismissed by the user for later
final dismissedNotificationIdsProvider = StateNotifierProvider<DismissedNotificationIdsNotifier, Set<String>>((ref) {
  return DismissedNotificationIdsNotifier();
});

class DismissedNotificationIdsNotifier extends StateNotifier<Set<String>> {
  static const _key = 'chatmelier_dismissed_notification_ids_v1';
  DismissedNotificationIdsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    if (mounted) {
      state = list.toSet();
    }
  }

  Future<void> dismiss(String id) async {
    final updated = Set<String>.from(state)..add(id);
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.toList());
  }

  Future<void> undismiss(String id) async {
    final updated = Set<String>.from(state)..remove(id);
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.toList());
  }

  Future<void> clearAll() async {
    state = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Global computed badge count for the Notification Bell
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final incomingFriends = ref.watch(pendingIncomingRequestsProvider).valueOrNull ?? [];
  final incomingCellar = ref.watch(incomingCellarRequestsProvider).valueOrNull ?? [];
  final notifications = ref.watch(userNotificationsProvider).valueOrNull ?? [];
  final dismissed = ref.watch(dismissedNotificationIdsProvider);

  final activeFriendsCount = incomingFriends.where((f) => !dismissed.contains(f.id) && !dismissed.contains(f.friendUserId)).length;
  final activeCellarCount = incomingCellar.where((c) => !dismissed.contains(c.id)).length;
  final unreadNotifsCount = notifications.where((n) => !n.isRead && !dismissed.contains(n.id)).length;

  return activeFriendsCount + activeCellarCount + unreadNotifsCount;
});

/// Refreshes all friend and notification providers across the app
void refreshFriendsAndNotifications(WidgetRef ref) {
  ref.invalidate(friendsListProvider);
  ref.invalidate(pendingIncomingRequestsProvider);
  ref.invalidate(pendingOutgoingRequestsProvider);
  ref.invalidate(incomingCellarRequestsProvider);
  ref.invalidate(userNotificationsProvider);
}

class FriendsRepository {
  final SupabaseClient _client;
  static const String _cacheKey = 'chatmelier_friends_cache_v2';

  FriendsRepository(this._client);

  // ---------------------------------------------------------------------------
  // Local Cache Helpers
  // ---------------------------------------------------------------------------
  Future<List<Friend>> _loadCachedFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        return list.map((e) => Friend.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Error reading cached friends: $e');
    }
    return [];
  }

  Future<void> _saveCachedFriends(List<Friend> friends) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(friends.map((f) => f.toJson()).toList());
      await prefs.setString(_cacheKey, jsonStr);
    } catch (e) {
      AppLogger.error('FRIENDS', 'Error caching friends', e);
    }
  }

  static ({String displayName, String username, String? avatarUrl, String? phone, String? email}) _extractProfileData(Map<String, dynamic> map) {
    String name = map['display_name'] as String? ?? 'Ami';
    String? user = map['username'] as String?;
    String? avatar = map['avatar_url'] as String?;
    String? phone = map['phone_number'] as String?;
    String? email = map['email'] as String?;

    if (avatar != null && avatar.startsWith('meta://')) {
      try {
        final queryStr = avatar.contains('?') ? avatar.substring(avatar.indexOf('?') + 1) : avatar.substring(7);
        final uriParams = Uri.splitQueryString(queryStr);
        user ??= uriParams['u'] ?? uriParams['username'];
        phone ??= uriParams['p'] ?? uriParams['phone'];
        email ??= uriParams['e'] ?? uriParams['email'];
        avatar = uriParams['avatar'];
      } catch (_) {}
    }

    return (
      displayName: name,
      username: (user ?? '').replaceAll('@', '').toLowerCase(),
      avatarUrl: avatar,
      phone: phone,
      email: email,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Get Accepted Friends List (with Cellar Sharing Roles)
  // ---------------------------------------------------------------------------
  Future<List<Friend>> getFriends() async {
    final user = _client.auth.currentUser;

    if (user != null) {
      try {
        // Query accepted friendships where user is either sender or receiver
        final res = await _client
            .from('friendships')
            .select('''
              id, user_id, friend_id, status, created_at,
              requester:profiles!friendships_user_id_fkey(id, display_name, avatar_url),
              recipient:profiles!friendships_friend_id_fkey(id, display_name, avatar_url)
            ''')
            .or('user_id.eq.${user.id},friend_id.eq.${user.id}')
            .eq('status', 'accepted')
            .timeout(const Duration(seconds: 4));

        final List<Friend> friendsList = [];

        // Fetch user's accessible shared cellars to determine roles
        Map<String, String> friendCellarRoles = {};
        Map<String, String> friendCellarIds = {};
        Map<String, String> friendCellarNames = {};

        try {
          final membersRes = await _client
              .from('cellar_members')
              .select('cellar_id, role, cellars(id, name, owner_id)')
              .eq('user_id', user.id);

          for (final row in (membersRes as List<dynamic>)) {
            final cellar = row['cellars'] as Map<String, dynamic>?;
            if (cellar != null) {
              final ownerId = cellar['owner_id']?.toString() ?? '';
              friendCellarRoles[ownerId] = row['role']?.toString() ?? 'viewer';
              friendCellarIds[ownerId] = cellar['id']?.toString() ?? '';
              friendCellarNames[ownerId] = cellar['name']?.toString() ?? 'Cave Partagée';
            }
          }
        } catch (_) {}

        for (final row in (res as List<dynamic>)) {
          final map = row as Map<String, dynamic>;
          final isSender = map['user_id'] == user.id;
          final friendProfile = isSender ? map['recipient'] as Map<String, dynamic>? : map['requester'] as Map<String, dynamic>?;

          if (friendProfile != null) {
            final friendId = friendProfile['id']?.toString() ?? (isSender ? map['friend_id'] : map['user_id'])?.toString() ?? '';
            final role = friendCellarRoles[friendId] ?? 'none';
            final extracted = _extractProfileData(friendProfile);

            final tasteData = friendProfile['taste_profile'] as Map<String, dynamic>?;
            final taste = tasteData != null
                ? TasteProfile.fromJson(tasteData)
                : TasteProfile(
                    id: friendId,
                    name: extracted.displayName,
                    favoriteTypes: (friendProfile['favorite_types'] as List<dynamic>?)?.cast<String>() ?? const [],
                    favoriteRegions: (friendProfile['favorite_regions'] as List<dynamic>?)?.cast<String>() ?? const [],
                    favoriteGrapes: (friendProfile['favorite_grapes'] as List<dynamic>?)?.cast<String>() ?? const [],
                  );

            friendsList.add(
              Friend(
                id: map['id']?.toString() ?? '',
                friendUserId: friendId,
                displayName: extracted.displayName,
                username: extracted.username,
                avatarUrl: extracted.avatarUrl,
                phoneNumber: extracted.phone,
                email: extracted.email,
                tasteProfile: taste,
                status: 'accepted',
                cellarAccessRole: role,
                friendCellarId: friendCellarIds[friendId],
                friendCellarName: friendCellarNames[friendId],
                createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : DateTime.now(),
              ),
            );
          }
        }

        await _saveCachedFriends(friendsList);
        return friendsList;
      } catch (e) {
        AppLogger.warning('FRIENDS', 'Could not fetch remote friends, using cache: $e');
        return _loadCachedFriends();
      }
    }

    return _loadCachedFriends();
  }

  // ---------------------------------------------------------------------------
  // 2. Pending Incoming Friend Requests (Must be accepted by current user)
  // ---------------------------------------------------------------------------
  Future<List<Friend>> getPendingIncomingRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _client
          .from('friendships')
          .select('''
            id, user_id, friend_id, status, created_at,
            requester:profiles!friendships_user_id_fkey(id, display_name, avatar_url)
          ''')
          .eq('friend_id', user.id)
          .eq('status', 'pending')
          .timeout(const Duration(seconds: 3));

      final list = <Friend>[];
      for (final item in (res as List<dynamic>)) {
        final map = item as Map<String, dynamic>;
        final profile = map['requester'] as Map<String, dynamic>?;
        if (profile != null) {
          final extracted = _extractProfileData(profile);
          final friendId = profile['id']?.toString() ?? map['user_id']?.toString() ?? '';
          final tasteData = profile['taste_profile'] as Map<String, dynamic>?;
          list.add(
            Friend(
              id: map['id']?.toString() ?? '',
              friendUserId: friendId,
              displayName: extracted.displayName,
              username: extracted.username,
              avatarUrl: extracted.avatarUrl,
              phoneNumber: extracted.phone,
              email: extracted.email,
              tasteProfile: tasteData != null
                  ? TasteProfile.fromJson(tasteData)
                  : TasteProfile(id: friendId, name: extracted.displayName),
              status: 'pending',
              isOutgoing: false,
              createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : DateTime.now(),
            ),
          );
        }
      }
      return list;
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Could not fetch pending incoming requests: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Pending Outgoing Friend Requests (Sent by current user)
  // ---------------------------------------------------------------------------
  Future<List<Friend>> getPendingOutgoingRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _client
          .from('friendships')
          .select('''
            id, user_id, friend_id, status, created_at,
            recipient:profiles!friendships_friend_id_fkey(id, display_name, avatar_url)
          ''')
          .eq('user_id', user.id)
          .eq('status', 'pending')
          .timeout(const Duration(seconds: 3));

      final list = <Friend>[];
      for (final item in (res as List<dynamic>)) {
        final map = item as Map<String, dynamic>;
        final profile = map['recipient'] as Map<String, dynamic>?;
        if (profile != null) {
          final extracted = _extractProfileData(profile);
          final friendId = profile['id']?.toString() ?? map['friend_id']?.toString() ?? '';
          final tasteData = profile['taste_profile'] as Map<String, dynamic>?;
          list.add(
            Friend(
              id: map['id']?.toString() ?? '',
              friendUserId: friendId,
              displayName: extracted.displayName,
              username: extracted.username,
              avatarUrl: extracted.avatarUrl,
              phoneNumber: extracted.phone,
              email: extracted.email,
              tasteProfile: tasteData != null
                  ? TasteProfile.fromJson(tasteData)
                  : TasteProfile(id: friendId, name: extracted.displayName),
              status: 'pending',
              isOutgoing: true,
              createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : DateTime.now(),
            ),
          );
        }
      }
      return list;
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Could not fetch pending outgoing requests: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Send Friend Request (Creates Pending Status + Notification)
  // ---------------------------------------------------------------------------
  Future<void> sendFriendRequest(UserProfile targetUser) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    if (user.id == targetUser.id) throw Exception('Vous ne pouvez pas vous ajouter vous-même en ami.');

    final friendshipId = const Uuid().v4();

    // 1. Insert friendship row with status = 'pending'
    await _client.from('friendships').upsert({
      'id': friendshipId,
      'user_id': user.id,
      'friend_id': targetUser.id,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. Send notification to target user
    final myDisplayName = user.userMetadata?['display_name'] as String? ?? 'Un utilisateur';
    try {
      await _client.from('user_notifications').insert({
        'user_id': targetUser.id,
        'actor_id': user.id,
        'type': 'friend_request',
        'title': 'Nouvelle demande d\'ami 🍷',
        'body': '$myDisplayName (@${user.userMetadata?['username'] ?? "sommelier"}) vous a envoyé une demande d\'ami pour partager vos goûts et vos caves.',
        'data': {
          'friendship_id': friendshipId,
          'requester_id': user.id,
          'requester_name': myDisplayName,
        },
      });
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Could not send friend request notification: $e');
    }

    AppLogger.info('FRIENDS', 'Sent friend request to ${targetUser.displayName} (${targetUser.id})');
  }

  // ---------------------------------------------------------------------------
  // 5. Accept Friend Request (Unlocks mutual taste visibility)
  // ---------------------------------------------------------------------------
  Future<void> acceptFriendRequest(String friendshipId, String friendUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // 1. Update status to accepted
    await _client
        .from('friendships')
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', friendshipId);

    // 2. Notify friend that their request was accepted
    final myDisplayName = user.userMetadata?['display_name'] as String? ?? 'Votre ami';
    try {
      await _client.from('user_notifications').insert({
        'user_id': friendUserId,
        'actor_id': user.id,
        'type': 'friend_accepted',
        'title': 'Demande d\'ami acceptée ! 🎉',
        'body': '$myDisplayName a accepté votre demande d\'ami. Vous avez désormais accès à sa Carte des Goûts et pouvez demander l\'accès à sa cave !',
        'data': {
          'friend_user_id': user.id,
        },
      });
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Could not send friend accepted notification: $e');
    }

    AppLogger.info('FRIENDS', 'Accepted friend request $friendshipId from $friendUserId');
  }

  // ---------------------------------------------------------------------------
  // 6. Decline or Cancel Friend Request / Remove Friend
  // ---------------------------------------------------------------------------
  Future<void> declineFriendRequest(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<void> removeFriend(String friendUserId) async {
    final cached = await _loadCachedFriends();
    cached.removeWhere((f) => f.friendUserId == friendUserId || f.id == friendUserId);
    await _saveCachedFriends(cached);

    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        await _client
            .from('friendships')
            .delete()
            .or('and(user_id.eq.${user.id},friend_id.eq.$friendUserId),and(user_id.eq.$friendUserId,friend_id.eq.${user.id})');
      } catch (e) {
        AppLogger.warning('FRIENDS', 'Remote delete friend notice: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 7. Request Cellar Access (Friend asks to view / edit a friend's cellar)
  // ---------------------------------------------------------------------------
  Future<void> requestCellarAccess({
    String? cellarId,
    required String ownerId,
    required String requestedRole, // 'viewer' or 'editor'
    String? message,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    if (user.id == ownerId) throw Exception('Vous êtes déjà propriétaire de cette cave.');

    // 1. Try server-side RPC (bypasses RLS restrictions cleanly)
    try {
      final rpcRes = await _client.rpc(
        'request_friend_cellar_access',
        params: {
          'p_target_owner_id': ownerId,
          'p_requested_role': requestedRole,
          'p_cellar_id': cellarId,
          'p_message': message,
        },
      );
      if (rpcRes != null) {
        AppLogger.info('FRIENDS', 'Successfully requested cellar access via RPC: $rpcRes');
        return;
      }
    } catch (rpcErr) {
      AppLogger.warning('FRIENDS', 'RPC request_friend_cellar_access fallback: $rpcErr');
    }

    // 2. Client-side fallback if RPC unavailable
    String targetCellarId = cellarId ?? '';
    String targetCellarName = 'Cave Partagée';

    if (targetCellarId.isEmpty || targetCellarId == ownerId) {
      try {
        final cellarRes = await _client
            .from('cellars')
            .select('id, name')
            .eq('owner_id', ownerId)
            .limit(1)
            .maybeSingle();
        if (cellarRes != null && cellarRes['id'] != null) {
          targetCellarId = cellarRes['id'].toString();
          targetCellarName = cellarRes['name']?.toString() ?? 'Cave Partagée';
        }
      } catch (_) {}
    }

    if (targetCellarId.isEmpty || targetCellarId == ownerId) {
      try {
        final memberRes = await _client
            .from('cellar_members')
            .select('cellar_id, cellars(id, name)')
            .eq('user_id', ownerId)
            .eq('role', 'admin')
            .limit(1)
            .maybeSingle();
        if (memberRes != null) {
          targetCellarId = memberRes['cellar_id']?.toString() ?? '';
          final cMap = memberRes['cellars'] as Map<String, dynamic>?;
          if (cMap != null && cMap['name'] != null) {
            targetCellarName = cMap['name'].toString();
          }
        }
      } catch (_) {}
    }

    final requestId = const Uuid().v4();

    // Insert into cellar_access_requests if targetCellarId is a valid cellar UUID
    if (targetCellarId.isNotEmpty && targetCellarId != ownerId) {
      try {
        await _client.from('cellar_access_requests').upsert({
          'id': requestId,
          'cellar_id': targetCellarId,
          'owner_id': ownerId,
          'requester_id': user.id,
          'requested_role': requestedRole,
          'status': 'pending',
          'message': message,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (err) {
        AppLogger.warning('FRIENDS', 'Could not upsert into cellar_access_requests: $err');
      }
    }

    // 2. Always notify cellar owner
    final myDisplayName = user.userMetadata?['display_name'] as String? ?? 'Un ami';
    final roleLabel = requestedRole == 'editor' ? 'Écriture / Sommelier délégué ✍️' : 'Consultation (Lecture seule) 👁️';

    try {
      await _client.from('user_notifications').insert({
        'user_id': ownerId,
        'actor_id': user.id,
        'type': 'cellar_request',
        'title': 'Demande d\'accès à votre Cave 🍷',
        'body': '$myDisplayName souhaite accéder à votre cave en mode "$roleLabel".',
        'data': {
          'request_id': requestId,
          'cellar_id': targetCellarId,
          'cellar_name': targetCellarName,
          'requester_id': user.id,
          'requester_name': myDisplayName,
          'requested_role': requestedRole,
          'message': message,
        },
      });
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Could not send cellar access notification: $e');
    }

    AppLogger.info('FRIENDS', 'Requested cellar access for owner $ownerId (cellar: $targetCellarId, role: $requestedRole)');
  }

  // ---------------------------------------------------------------------------
  // 8. Respond to Cellar Access Request (Accept / Refuse with Role selection)
  // ---------------------------------------------------------------------------
  Future<void> respondCellarAccess({
    required String requestId,
    required String cellarId,
    required String requesterId,
    required bool accept,
    required String role, // 'viewer' or 'editor'
    String? cellarName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Resolve owner's actual cellar if cellarId was blank
    String targetCellarId = cellarId;
    if (targetCellarId.isEmpty) {
      try {
        final myCellar = await _client.from('cellars').select('id, name').eq('owner_id', user.id).limit(1).maybeSingle();
        if (myCellar != null && myCellar['id'] != null) {
          targetCellarId = myCellar['id'].toString();
          cellarName ??= myCellar['name']?.toString();
        }
      } catch (_) {}
    }

    if (targetCellarId.isEmpty) {
      try {
        final myMember = await _client.from('cellar_members').select('cellar_id').eq('user_id', user.id).eq('role', 'admin').limit(1).maybeSingle();
        if (myMember != null && myMember['cellar_id'] != null) {
          targetCellarId = myMember['cellar_id'].toString();
        }
      } catch (_) {}
    }

    if (accept) {
      // 1. Update request to accepted
      try {
        await _client
            .from('cellar_access_requests')
            .update({'status': 'accepted', 'responded_at': DateTime.now().toIso8601String()})
            .eq('id', requestId);
      } catch (_) {}

      // 2. Add member to cellar_members
      if (targetCellarId.isNotEmpty) {
        await _client.from('cellar_members').upsert({
          'cellar_id': targetCellarId,
          'user_id': requesterId,
          'role': role,
          'invited_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. Notify requester
      final myName = user.userMetadata?['display_name'] as String? ?? 'Le propriétaire';
      final roleText = role == 'editor' ? 'Éditeur (ajout & retrait)' : 'Lecteur (consultation)';
      try {
        await _client.from('user_notifications').insert({
          'user_id': requesterId,
          'actor_id': user.id,
          'type': 'cellar_granted',
          'title': 'Accès à la cave accordé ! 🍾',
          'body': '$myName a accepté votre demande d\'accès à sa cave "${cellarName ?? "Ma Cave"}" avec les droits "$roleText".',
          'data': {
            'cellar_id': targetCellarId,
            'role': role,
          },
        });
      } catch (e) {
        AppLogger.warning('FRIENDS', 'Could not send cellar granted notification: $e');
      }
    } else {
      // Reject request
      try {
        await _client
            .from('cellar_access_requests')
            .update({'status': 'rejected', 'responded_at': DateTime.now().toIso8601String()})
            .eq('id', requestId);
      } catch (_) {}

      final myName = user.userMetadata?['display_name'] as String? ?? 'Le propriétaire';
      try {
        await _client.from('user_notifications').insert({
          'user_id': requesterId,
          'actor_id': user.id,
          'type': 'cellar_rejected',
          'title': 'Demande d\'accès cave refusée',
          'body': '$myName a décliné votre demande d\'accès à sa cave.',
          'data': {'cellar_id': targetCellarId},
        });
      } catch (_) {}
    }

    // Always remove/mark read related notifications for the owner
    try {
      await _client
          .from('user_notifications')
          .delete()
          .eq('user_id', user.id)
          .eq('actor_id', requesterId)
          .eq('type', 'cellar_request');
    } catch (_) {
      try {
        await _client
            .from('user_notifications')
            .update({'is_read': true})
            .eq('user_id', user.id)
            .eq('type', 'cellar_request');
      } catch (_) {}
    }
  }

  Future<void> dismissCellarRequest({
    required String requestId,
    required String requesterId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('cellar_access_requests')
          .update({'status': 'rejected', 'responded_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
    } catch (_) {}

    try {
      await _client
          .from('user_notifications')
          .delete()
          .eq('user_id', user.id)
          .eq('actor_id', requesterId)
          .eq('type', 'cellar_request');
    } catch (_) {
      try {
        await _client
            .from('user_notifications')
            .update({'is_read': true})
            .eq('user_id', user.id)
            .eq('type', 'cellar_request');
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // 9. Proactively Grant Cellar Access to a Friend (Owner-Initiated)
  // ---------------------------------------------------------------------------
  Future<void> grantCellarAccessDirectly({
    required String cellarId,
    required String friendUserId,
    required String role, // 'viewer' or 'editor'
    String? cellarName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Resolve cellar ID if empty
    String targetCellarId = cellarId;
    if (targetCellarId.isEmpty) {
      final myCellar = await _client.from('cellars').select('id, name').eq('owner_id', user.id).limit(1).maybeSingle();
      if (myCellar != null && myCellar['id'] != null) {
        targetCellarId = myCellar['id'].toString();
        cellarName ??= myCellar['name']?.toString();
      }
    }

    if (targetCellarId.isEmpty) {
      final myMember = await _client.from('cellar_members').select('cellar_id').eq('user_id', user.id).eq('role', 'admin').limit(1).maybeSingle();
      if (myMember != null && myMember['cellar_id'] != null) {
        targetCellarId = myMember['cellar_id'].toString();
      }
    }

    if (targetCellarId.isEmpty) throw Exception('Impossible de déterminer la cave à partager.');

    // Upsert into cellar_members
    await _client.from('cellar_members').upsert({
      'cellar_id': targetCellarId,
      'user_id': friendUserId,
      'role': role,
      'invited_at': DateTime.now().toIso8601String(),
    });

    // Notify friend
    final myName = user.userMetadata?['display_name'] as String? ?? 'Votre ami';
    final roleText = role == 'editor' ? 'Éditeur (Sommelier délégué ✍️)' : 'Lecteur (Consultation 👁️)';

    try {
      await _client.from('user_notifications').insert({
        'user_id': friendUserId,
        'actor_id': user.id,
        'type': 'cellar_granted',
        'title': 'Accès à la cave accordé ! 🍷',
        'body': '$myName vous a accordé l\'accès à sa cave "${cellarName ?? "Ma Cave"}" en mode $roleText.',
        'data': {
          'cellar_id': targetCellarId,
          'role': role,
        },
      });
    } catch (_) {}

    AppLogger.info('FRIENDS', 'Owner granted cellar $targetCellarId access to friend $friendUserId as $role');
  }

  // ---------------------------------------------------------------------------
  // 10. Revoke Cellar Access
  // ---------------------------------------------------------------------------
  Future<void> revokeCellarAccess({
    required String cellarId,
    required String userId,
  }) async {
    await _client
        .from('cellar_members')
        .delete()
        .eq('cellar_id', cellarId)
        .eq('user_id', userId);
  }

  // ---------------------------------------------------------------------------
  // 11. Fetch Incoming Cellar Requests
  // ---------------------------------------------------------------------------
  Future<List<CellarAccessRequest>> getIncomingCellarRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final List<CellarAccessRequest> requests = [];

    try {
      final res = await _client
          .from('cellar_access_requests')
          .select('''
            id, cellar_id, owner_id, requester_id, requested_role, status, message, created_at, responded_at,
            requester:profiles!cellar_access_requests_requester_id_fkey(id, display_name, avatar_url),
            cellars!cellar_access_requests_cellar_id_fkey(id, name)
          ''')
          .eq('owner_id', user.id)
          .eq('status', 'pending')
          .timeout(const Duration(seconds: 3));

      for (final j in (res as List<dynamic>)) {
        requests.add(CellarAccessRequest.fromJson(j as Map<String, dynamic>));
      }
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Could not fetch incoming cellar requests from table: $e');
    }

    // Complement with pending cellar requests from notifications
    try {
      final notifsRes = await _client
          .from('user_notifications')
          .select('''
            id, user_id, actor_id, type, title, body, data, is_read, created_at,
            actor:profiles!user_notifications_actor_id_fkey(id, display_name, avatar_url)
          ''')
          .eq('user_id', user.id)
          .eq('type', 'cellar_request')
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(10);

      for (final n in (notifsRes as List<dynamic>)) {
        if (n['is_read'] == true) continue;
        final nData = n['data'] as Map<String, dynamic>? ?? {};
        final reqId = nData['request_id']?.toString() ?? n['id']?.toString() ?? '';
        final requesterId = nData['requester_id']?.toString() ?? n['actor_id']?.toString() ?? '';
        final alreadyPresent = requests.any((r) => r.id == reqId || (r.requesterId == requesterId));
        if (alreadyPresent || requesterId.isEmpty) continue;

        // Check if cellar_access_requests has already handled it
        try {
          final existing = await _client
              .from('cellar_access_requests')
              .select('status')
              .eq('owner_id', user.id)
              .eq('requester_id', requesterId)
              .maybeSingle();
          if (existing != null && existing['status'] != 'pending') {
            await _client.from('user_notifications').update({'is_read': true}).eq('id', n['id']);
            continue;
          }
        } catch (_) {}

        final actorProfile = n['actor'] as Map<String, dynamic>?;
        final extracted = _extractProfileData(actorProfile ?? {});
        requests.add(
          CellarAccessRequest(
            id: reqId,
            cellarId: nData['cellar_id']?.toString() ?? '',
            cellarName: nData['cellar_name']?.toString() ?? 'Ma Cave',
            ownerId: user.id,
            requesterId: requesterId,
            requesterName: extracted.displayName,
            requesterUsername: extracted.username,
            requesterAvatarUrl: extracted.avatarUrl,
            requestedRole: nData['requested_role']?.toString() ?? 'viewer',
            status: 'pending',
            message: nData['message']?.toString(),
            createdAt: DateTime.tryParse(n['created_at']?.toString() ?? '') ?? DateTime.now(),
          ),
        );
      }
    } catch (_) {}

    return requests;
  }

  // ---------------------------------------------------------------------------
  // 12. User Notifications
  // ---------------------------------------------------------------------------
  Future<List<UserNotification>> getUserNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _client
          .from('user_notifications')
          .select('''
            id, user_id, actor_id, type, title, body, data, is_read, created_at,
            actor:profiles!user_notifications_actor_id_fkey(id, display_name, avatar_url)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(30)
          .timeout(const Duration(seconds: 3));

      return (res as List<dynamic>).map((j) => UserNotification.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Could not fetch notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('user_notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } catch (e) {
      AppLogger.warning('FRIENDS', 'Could not delete notification: $e');
    }
  }
}
