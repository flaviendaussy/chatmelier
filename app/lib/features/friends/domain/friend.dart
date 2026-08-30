import '../../auth/domain/taste_profile.dart';

/// Represents a friend in Chatmelier with their profile details, taste card, and cellar sharing permissions.
class Friend {
  final String id; // Friendship ID
  final String friendUserId;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? email;
  final TasteProfile tasteProfile;
  final String status; // 'accepted', 'pending', 'declined'
  final bool isOutgoing; // True if current user requested the friendship
  final String cellarAccessRole; // 'none', 'viewer', 'editor', 'owner'
  final String? friendCellarId;
  final String? friendCellarName;
  final DateTime? createdAt;

  const Friend({
    required this.id,
    required this.friendUserId,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.phoneNumber,
    this.email,
    required this.tasteProfile,
    this.status = 'accepted',
    this.isOutgoing = false,
    this.cellarAccessRole = 'none',
    this.friendCellarId,
    this.friendCellarName,
    this.createdAt,
  });

  String get handle => '@${username.replaceAll('@', '')}';
  bool get isAccepted => status == 'accepted';
  bool get hasCellarAccess => cellarAccessRole == 'viewer' || cellarAccessRole == 'editor' || cellarAccessRole == 'owner';
  bool get canWriteCellar => cellarAccessRole == 'editor' || cellarAccessRole == 'owner';

  factory Friend.fromJson(Map<String, dynamic> json) {
    final profileMap = json['profiles'] as Map<String, dynamic>? ?? json;
    final tasteData = json['taste_profile'] as Map<String, dynamic>? ?? profileMap['taste_profile'] as Map<String, dynamic>?;

    TasteProfile parsedTaste;
    if (tasteData != null) {
      parsedTaste = TasteProfile.fromJson(tasteData);
    } else {
      parsedTaste = TasteProfile(
        id: json['friend_id']?.toString() ?? json['id']?.toString() ?? '',
        name: profileMap['display_name'] as String? ?? 'Ami',
        favoriteTypes: (profileMap['favorite_types'] as List<dynamic>?)?.cast<String>() ?? const [],
        favoriteRegions: (profileMap['favorite_regions'] as List<dynamic>?)?.cast<String>() ?? const [],
        favoriteGrapes: (profileMap['favorite_grapes'] as List<dynamic>?)?.cast<String>() ?? const [],
      );
    }

    return Friend(
      id: json['id']?.toString() ?? '',
      friendUserId: json['friend_id']?.toString() ?? profileMap['id']?.toString() ?? '',
      displayName: profileMap['display_name'] as String? ?? 'Ami',
      username: (profileMap['username'] as String? ?? '').replaceAll('@', '').toLowerCase(),
      avatarUrl: profileMap['avatar_url'] as String?,
      phoneNumber: profileMap['phone_number'] as String?,
      email: profileMap['email'] as String?,
      tasteProfile: parsedTaste,
      status: json['status'] as String? ?? 'accepted',
      isOutgoing: json['is_outgoing'] as bool? ?? false,
      cellarAccessRole: json['cellar_access_role'] as String? ?? 'none',
      friendCellarId: json['friend_cellar_id'] as String?,
      friendCellarName: json['friend_cellar_name'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'friend_id': friendUserId,
        'status': status,
        'is_outgoing': isOutgoing,
        'cellar_access_role': cellarAccessRole,
        if (friendCellarId != null) 'friend_cellar_id': friendCellarId,
        if (friendCellarName != null) 'friend_cellar_name': friendCellarName,
        'created_at': createdAt?.toIso8601String(),
        'profiles': {
          'id': friendUserId,
          'display_name': displayName,
          'username': username,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (email != null) 'email': email,
          'taste_profile': tasteProfile.toJson(),
        },
      };

  Friend copyWith({
    String? id,
    String? friendUserId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? phoneNumber,
    String? email,
    TasteProfile? tasteProfile,
    String? status,
    bool? isOutgoing,
    String? cellarAccessRole,
    String? friendCellarId,
    String? friendCellarName,
    DateTime? createdAt,
  }) =>
      Friend(
        id: id ?? this.id,
        friendUserId: friendUserId ?? this.friendUserId,
        displayName: displayName ?? this.displayName,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        email: email ?? this.email,
        tasteProfile: tasteProfile ?? this.tasteProfile,
        status: status ?? this.status,
        isOutgoing: isOutgoing ?? this.isOutgoing,
        cellarAccessRole: cellarAccessRole ?? this.cellarAccessRole,
        friendCellarId: friendCellarId ?? this.friendCellarId,
        friendCellarName: friendCellarName ?? this.friendCellarName,
        createdAt: createdAt ?? this.createdAt,
      );
}
