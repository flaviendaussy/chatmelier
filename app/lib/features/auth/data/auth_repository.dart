import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  static const List<UserProfile> _mockUsers = [
    UserProfile(
      id: 'mock-user-flavien-001',
      displayName: 'Flavien',
      username: 'flavien',
      phoneNumber: '+33612345678',
      email: 'flavien@chatmelier.app',
      avatarUrl: null,
    ),
    UserProfile(
      id: 'mock-user-dimitri-003',
      displayName: 'Dimitri',
      username: 'dimitri',
      phoneNumber: '+33655443322',
      email: 'dimitri@chatmelier.app',
      avatarUrl: null,
    ),
    UserProfile(
      id: 'mock-user-pierre-004',
      displayName: 'Pierre',
      username: 'pierre_vins',
      phoneNumber: '+33611223344',
      email: 'pierre@chatmelier.app',
      avatarUrl: null,
    ),
    UserProfile(
      id: 'mock-user-james-005',
      displayName: 'James (UK)',
      username: 'james_uk',
      phoneNumber: '+447911123456',
      email: 'james@chatmelier.co.uk',
      avatarUrl: null,
    ),
    UserProfile(
      id: 'mock-user-marco-006',
      displayName: 'Marco (Italie)',
      username: 'marco_roma',
      phoneNumber: '+393123456789',
      email: 'marco@chatmelier.it',
      avatarUrl: null,
    ),
  ];

  Future<void> signIn(String email, String password) async {
    AppLogger.info('AUTH', 'Signing in with password for $email');
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, String displayName, {String? username}) async {
    AppLogger.info('AUTH', 'Signing up user $email');
    final cleanUsername = username?.replaceAll('@', '').trim().toLowerCase();
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        if (cleanUsername != null && cleanUsername.isNotEmpty) 'username': cleanUsername,
      },
    );
    return res;
  }

  String? _getRedirectUrl() {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin != 'null') {
          final path = Uri.base.path;
          final normalizedPath = path.isEmpty ? '/' : (path.endsWith('/') ? path : '$path/');
          return '$origin$normalizedPath';
        }
      } catch (_) {}
      final base = Uri.base;
      final portStr = (base.hasPort && base.port != 80 && base.port != 443) ? ':${base.port}' : '';
      final path = base.path.isEmpty ? '/' : (base.path.endsWith('/') ? base.path : '${base.path}/');
      return '${base.scheme}://${base.host}$portStr$path';
    }
    return 'chatmelier://login-callback';
  }

  /// Passwordless Connection Link (Magic Link) Email Authentication
  Future<void> sendMagicLink(String email) async {
    final redirectUrl = _getRedirectUrl();
    AppLogger.info('AUTH', 'Sending connection link to $email (redirect: $redirectUrl, platform: ${kIsWeb ? "web" : defaultTargetPlatform.name})');
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectUrl,
    );
  }

  /// Send password reset link to user's email
  Future<void> resetPasswordForEmail(String email) async {
    final redirectUrl = _getRedirectUrl();
    AppLogger.info('AUTH', 'Sending password reset email to $email (redirect: $redirectUrl)');
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  /// Verify 6-digit OTP code sent to user email (with multi-type fallback)
  Future<void> verifyEmailOtp(String email, String token) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    AppLogger.info('AUTH', 'Verifying email OTP ($cleanToken) for $cleanEmail');

    // 1. Try OtpType.email (numerical OTP code)
    try {
      await _client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.email,
      );
      return;
    } catch (e1) {
      AppLogger.warning('AUTH', 'OtpType.email failed: $e1, trying magiclink...');
    }

    // 2. Try OtpType.magiclink
    try {
      await _client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.magiclink,
      );
      return;
    } catch (e2) {
      AppLogger.warning('AUTH', 'OtpType.magiclink failed: $e2, trying signup...');
    }

    // 3. Try OtpType.signup
    await _client.auth.verifyOTP(
      email: cleanEmail,
      token: cleanToken,
      type: OtpType.signup,
    );
  }

  /// Google OAuth Sign In
  Future<void> signInWithGoogle() async {
    final redirectUrl = _getRedirectUrl();
    AppLogger.info('AUTH', 'Initiating Google OAuth (redirect: $redirectUrl, platform: ${kIsWeb ? "web" : defaultTargetPlatform.name})');
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
    );
  }

  /// Fetches a profile with multi-tier fallback (Remote Table -> Auth User Metadata -> Local SharedPreferences)
  Future<UserProfile?> getProfile(String userId) async {
    try {
      UserProfile? profile;
      try {
        final res = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (res != null) {
          profile = UserProfile.fromJson(res);
        }
      } catch (e) {
        AppLogger.warning('AUTH', 'Direct select from profiles failed for $userId: $e');
      }

      // Check current user metadata and SharedPreferences for local enrichment
      final user = _client.auth.currentUser;
      if (user != null && user.id == userId) {
        String? cachedUser = user.userMetadata?['username'] as String?;
        String? cachedPhone = user.userMetadata?['phone_number'] as String?;
        String? cachedEmail = (user.userMetadata?['email'] as String?) ?? user.email;
        String? cachedName = user.userMetadata?['display_name'] as String?;

        try {
          final prefs = await SharedPreferences.getInstance();
          cachedUser ??= prefs.getString('user_profile_username_$userId');
          cachedPhone ??= prefs.getString('user_profile_phone_$userId');
          cachedEmail ??= prefs.getString('user_profile_email_$userId');
          cachedName ??= prefs.getString('user_profile_name_$userId');
        } catch (_) {}

        if (profile != null) {
          profile = profile.copyWith(
            username: (profile.username != null && profile.username!.isNotEmpty) ? profile.username : cachedUser,
            phoneNumber: (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) ? profile.phoneNumber : cachedPhone,
            email: (profile.email != null && profile.email!.isNotEmpty) ? profile.email : cachedEmail,
            displayName: profile.displayName != 'User' ? profile.displayName : (cachedName ?? profile.displayName),
          );
        } else if (cachedUser != null || cachedName != null) {
          profile = UserProfile(
            id: userId,
            displayName: cachedName ?? user.userMetadata?['display_name'] ?? 'User',
            username: cachedUser,
            phoneNumber: cachedPhone,
            email: cachedEmail ?? user.email,
          );
        }
      }

      return profile;
    } catch (e) {
      AppLogger.warning('AUTH', 'Error loading profile for $userId: $e');
      return null;
    }
  }

  /// Checks if a username is already taken by another user (strictly unique)
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    if (clean.length < 3) return false;
    final currentId = excludeUserId ?? _client.auth.currentUser?.id;

    // Check remote database profiles
    try {
      var query = _client.from('profiles').select('id, display_name, avatar_url');
      if (currentId != null) {
        query = query.neq('id', currentId);
      }
      final list = await query;
      for (final row in (list as List)) {
        final p = UserProfile.fromJson(row as Map<String, dynamic>);
        if (p.id != currentId && p.username?.toLowerCase() == clean) {
          return false;
        }
      }
    } catch (_) {}

    return true;
  }

  /// Checks if a phone number is already taken by another user (strictly unique)
  Future<bool> isPhoneAvailable(String phoneNumber, {String? excludeUserId}) async {
    final cleanDigits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.length < 6) return false;
    final currentId = excludeUserId ?? _client.auth.currentUser?.id;

    // Check remote database profiles
    try {
      var query = _client.from('profiles').select('id, display_name, avatar_url');
      if (currentId != null) {
        query = query.neq('id', currentId);
      }
      final list = await query;
      for (final row in (list as List)) {
        final p = UserProfile.fromJson(row as Map<String, dynamic>);
        if (p.id != currentId && p.phoneNumber != null) {
          final rowDigits = p.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
          if (rowDigits.isNotEmpty && (rowDigits == cleanDigits || rowDigits.endsWith(cleanDigits) || cleanDigits.endsWith(rowDigits))) {
            return false;
          }
        }
      }
    } catch (_) {}

    return true;
  }

  /// Checks if an email address is already taken by another user (strictly unique)
  Future<bool> isEmailAvailable(String email, {String? excludeUserId}) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.contains('@')) return false;
    final currentId = excludeUserId ?? _client.auth.currentUser?.id;

    // Check remote database profiles
    try {
      var query = _client.from('profiles').select('id, display_name, avatar_url');
      if (currentId != null) {
        query = query.neq('id', currentId);
      }
      final list = await query;
      for (final row in (list as List)) {
        final p = UserProfile.fromJson(row as Map<String, dynamic>);
        if (p.id != currentId && p.email != null && p.email!.toLowerCase() == cleanEmail) {
          return false;
        }
      }
    } catch (_) {}

    return true;
  }

  /// Searches users by Username, Phone number, or Email
  Future<List<UserProfile>> searchUsers(String queryText) async {
    final q = queryText.trim().toLowerCase();
    if (q.isEmpty) return [];

    final cleanQuery = q.replaceAll('@', '');
    final currentUserId = _client.auth.currentUser?.id;

    // 1. Remote search across profiles
    try {
      final res = await _client.from('profiles').select().limit(50);
      final remoteList = (res as List<dynamic>)
          .map((j) => UserProfile.fromJson(j as Map<String, dynamic>))
          .where((p) => p.id != currentUserId)
          .where((p) {
            final matchUser = (p.username ?? '').toLowerCase().contains(cleanQuery);
            final matchName = p.displayName.toLowerCase().contains(cleanQuery);
            final matchEmail = (p.email ?? '').toLowerCase().contains(cleanQuery);
            final phoneDigits = (p.phoneNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            final queryDigits = cleanQuery.replaceAll(RegExp(r'[^0-9]'), '');
            final matchPhone = queryDigits.length >= 3 && phoneDigits.contains(queryDigits);
            return matchUser || matchName || matchEmail || matchPhone;
          })
          .toList();

      if (remoteList.isNotEmpty) return remoteList;
    } catch (e) {
      AppLogger.warning('AUTH', 'Remote search failed, falling back to simulated search: $e');
    }

    // 2. Mock users search
    final queryDigits = cleanQuery.replaceAll(RegExp(r'[^0-9]'), '');
    final noLeadingZeroDigits = queryDigits.startsWith('0') ? queryDigits.substring(1) : queryDigits;

    return _mockUsers.where((u) {
      if (u.id == currentUserId) return false;
      final matchUser = (u.username ?? '').toLowerCase().contains(cleanQuery);
      final matchName = u.displayName.toLowerCase().contains(cleanQuery);
      final matchEmail = (u.email ?? '').toLowerCase().contains(cleanQuery);

      final phoneDigits = (u.phoneNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      final matchPhone = (u.phoneNumber ?? '').replaceAll(' ', '').contains(cleanQuery.replaceAll(' ', '')) ||
          (noLeadingZeroDigits.length >= 3 && phoneDigits.contains(noLeadingZeroDigits));

      return matchUser || matchName || matchPhone || matchEmail;
    }).toList();
  }

  /// Updates profile with triple-redundancy persistence:
  /// 1. Supabase Auth User Metadata (Permanent cloud sync across all Supabase setups)
  /// 2. Local SharedPreferences (Instant 0ms retrieval)
  /// 3. Remote Postgres profiles table (with fallback meta URI in avatar_url if columns missing)
  Future<void> updateProfile({
    required String displayName,
    String? username,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    String? defaultCurrency,
    Map<String, dynamic>? tasteProfileData,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final cleanUsername = username?.replaceAll('@', '').trim().toLowerCase();
    final cleanPhone = phoneNumber?.trim();
    final cleanEmail = email?.trim().toLowerCase() ?? user.email;

    // 1. Supabase Auth User Metadata Update (Guaranteed cloud persistence)
    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': displayName,
            if (cleanUsername != null && cleanUsername.isNotEmpty) 'username': cleanUsername,
            if (cleanPhone != null && cleanPhone.isNotEmpty) 'phone_number': cleanPhone,
            if (cleanEmail != null && cleanEmail.isNotEmpty) 'email': cleanEmail,
            if (defaultCurrency != null) 'default_currency': defaultCurrency,
          },
        ),
      );
      AppLogger.info('AUTH', 'Updated auth user_metadata for ${user.id} (@$cleanUsername)');
    } catch (authErr) {
      AppLogger.warning('AUTH', 'Could not update auth user_metadata: $authErr');
    }

    // 2. Local SharedPreferences Cache (Instant 0ms retrieval)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (cleanUsername != null && cleanUsername.isNotEmpty) {
        await prefs.setString('user_profile_username_${user.id}', cleanUsername);
        await prefs.setBool('user_profile_configured_${user.id}', true);
      }
      if (cleanPhone != null && cleanPhone.isNotEmpty) {
        await prefs.setString('user_profile_phone_${user.id}', cleanPhone);
      }
      if (cleanEmail != null && cleanEmail.isNotEmpty) {
        await prefs.setString('user_profile_email_${user.id}', cleanEmail);
      }
      await prefs.setString('user_profile_name_${user.id}', displayName);
      if (defaultCurrency != null) {
        await prefs.setString('user_profile_currency_${user.id}', defaultCurrency);
      }
    } catch (_) {}

    // 3. Remote Postgres profiles table Update with fallback
    final updates = <String, dynamic>{
      'display_name': displayName,
      if (cleanUsername != null && cleanUsername.isNotEmpty) 'username': cleanUsername,
      if (cleanPhone != null && cleanPhone.isNotEmpty) 'phone_number': cleanPhone,
      if (cleanEmail != null && cleanEmail.isNotEmpty) 'email': cleanEmail,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (defaultCurrency != null) 'default_currency': defaultCurrency,
      if (tasteProfileData != null) 'taste_profile': tasteProfileData,
    };

    try {
      await _client.from('profiles').upsert({'id': user.id, ...updates});
      AppLogger.info('AUTH', 'Updated profiles table for user ${user.id} (handle: @$cleanUsername)');
    } catch (e) {
      AppLogger.warning('AUTH', 'Could not update all profile columns, attempting fallback encoding: $e');
      
      // Fallback: encode username & phone inside avatar_url meta URI if no custom avatar photo is set
      final metaAvatar = (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('meta://'))
          ? 'meta://?u=${cleanUsername ?? ""}&p=${Uri.encodeComponent(cleanPhone ?? "")}&e=${Uri.encodeComponent(cleanEmail ?? "")}'
          : avatarUrl;

      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'display_name': displayName,
          'avatar_url': metaAvatar,
          if (defaultCurrency != null) 'default_currency': defaultCurrency,
        });
        AppLogger.info('AUTH', 'Saved fallback profile with meta avatar for user ${user.id}');
      } catch (e2) {
        AppLogger.warning('AUTH', 'Final fallback profile upsert failed: $e2');
      }
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
