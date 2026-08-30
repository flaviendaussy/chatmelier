class UserProfile {
  final String id;
  final String displayName;
  final String? username; // Unique handle e.g. 'flavien', 'caro'
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String defaultCurrency;
  final Map<String, dynamic>? tasteProfileData;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.username,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.defaultCurrency = 'EUR',
    this.tasteProfileData,
    this.createdAt,
  });

  /// Check if a username is valid according to Chatmelier rules:
  /// - 3 to 30 chars
  /// - lowercase letters, digits, and underscores only
  static String? validateUsername(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Le pseudo est obligatoire.';
    }
    final clean = val.trim().toLowerCase().replaceAll('@', '');
    if (clean.length < 3) {
      return 'Le pseudo doit comporter au moins 3 caractères.';
    }
    if (clean.length > 30) {
      return 'Le pseudo ne peut pas dépasser 30 caractères.';
    }
    final regex = RegExp(r'^[a-z0-9_]+$');
    if (!regex.hasMatch(clean)) {
      return 'Uniquement des lettres, chiffres et tirets bas (_) sans espaces.';
    }
    return null;
  }

  /// Validates that phone number, if provided, must strictly include an international dial code
  static String? validatePhoneNumber(String? val) {
    if (val == null || val.trim().isEmpty) return null; // Optional if empty
    final clean = val.trim();
    if (!clean.startsWith('+')) {
      return 'Le numéro de téléphone doit impérativement comporter un indicatif national (ex: +33, +44).';
    }
    final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) {
      return 'Le numéro de téléphone doit comporter au moins 7 chiffres.';
    }
    if (digits.length > 15) {
      return 'Le numéro de téléphone ne peut pas dépasser 15 chiffres.';
    }
    return null;
  }

  /// Formats username with an @ prefix (e.g. '@flavien')
  String get handle => username != null && username!.isNotEmpty ? '@${username!.replaceAll('@', '')}' : '@inconnu';

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? username,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    String? defaultCurrency,
    Map<String, dynamic>? tasteProfileData,
    DateTime? createdAt,
  }) =>
      UserProfile(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        username: username ?? this.username,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        tasteProfileData: tasteProfileData ?? this.tasteProfileData,
        createdAt: createdAt ?? this.createdAt,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String? username = json['username'] as String?;
    String? phone = json['phone_number'] as String?;
    String? email = json['email'] as String?;
    String? avatar = json['avatar_url'] as String?;
    String displayName = json['display_name'] as String? ?? 'User';

    // Parse embedded metadata from avatar_url if present
    if (avatar != null && avatar.startsWith('meta://')) {
      try {
        final queryStr = avatar.contains('?') ? avatar.substring(avatar.indexOf('?') + 1) : avatar.substring(7);
        final uriParams = Uri.splitQueryString(queryStr);
        if (username == null || username.isEmpty) {
          username = uriParams['u'] ?? uriParams['username'];
        }
        if (phone == null || phone.isEmpty) {
          phone = uriParams['p'] ?? uriParams['phone'];
        }
        if (email == null || email.isEmpty) {
          email = uriParams['e'] ?? uriParams['email'];
        }
        avatar = uriParams['avatar']; // Optional real avatar url
      } catch (_) {}
    }

    // Parse handle embedded in display_name if needed (e.g. "Flavien (@flavien)")
    if (username == null || username.isEmpty) {
      final match = RegExp(r'\(@([a-z0-9_]+)\)', caseSensitive: false).firstMatch(displayName);
      if (match != null) {
        username = match.group(1);
        displayName = displayName.replaceAll(match.group(0)!, '').trim();
      }
    }

    // Parse user_metadata or raw_user_meta_data if present in JSON
    final meta = (json['user_metadata'] ?? json['raw_user_meta_data']) as Map<String, dynamic>?;
    if (meta != null) {
      username ??= meta['username'] as String?;
      phone ??= meta['phone_number'] as String?;
      email ??= meta['email'] as String?;
      final metaDisplayName = meta['display_name'] as String?;
      if (metaDisplayName != null && metaDisplayName.isNotEmpty) {
        displayName = metaDisplayName;
      }
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: displayName.isNotEmpty ? displayName : (username != null ? '@$username' : 'User'),
      username: username != null && username.isNotEmpty ? username.toLowerCase().replaceAll('@', '').trim() : null,
      phoneNumber: phone,
      email: email,
      avatarUrl: avatar,
      defaultCurrency: json['default_currency'] as String? ?? 'EUR',
      tasteProfileData: json['taste_profile'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        if (username != null) 'username': username!.toLowerCase().replaceAll('@', '').trim(),
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'default_currency': defaultCurrency,
        if (tasteProfileData != null) 'taste_profile': tasteProfileData,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
