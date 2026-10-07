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

  Future<void> signIn(String email, String password) async {
    AppLogger.info('AUTH', 'Signing in with password for ${masquerEmail(email)}');
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, String displayName, {String? username}) async {
    AppLogger.info('AUTH', 'Signing up user ${masquerEmail(email)}');
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
      } catch (e) {
        AppLogger.debug('AUTH', 'Repli : $e');
      }
      final base = Uri.base;
      final portStr = (base.hasPort && base.port != 80 && base.port != 443) ? ':${base.port}' : '';
      final path = base.path.isEmpty ? '/' : (base.path.endsWith('/') ? base.path : '${base.path}/');
      return '${base.scheme}://${base.host}$portStr$path';
    }
    return 'chatmelier://login-callback';
  }

  /// Ouvre un compte anonyme, invisible et immédiat.
  ///
  /// **Pourquoi un vrai compte plutôt qu'un stockage local.** Tout ce qui s'accumule le
  /// temps d'une soirée — les verres goûtés, le palais qui se dessine, la conversation
  /// avec le sommelier — est écrit côté serveur sous un vrai `user_id`, avec la RLS
  /// habituelle. La conversion se réduit alors à ajouter une adresse au compte existant :
  /// aucun code de migration local → serveur à écrire, aucune perte, l'historique reste
  /// identique.
  ///
  /// **Ce que ça coûte.** Ces comptes comptent dans les MAU Supabase, donc dans la
  /// facture. Une purge des comptes anonymes inactifs et non convertis est indispensable
  /// (voir la migration des sessions de table). Et les connexions anonymes sont
  /// désactivées par défaut dans Supabase : sans le réglage, cet appel échoue.
  Future<User?> signInAnonymously() async {
    final res = await _client.auth.signInAnonymously();
    AppLogger.info('AUTH', 'Compte anonyme ouvert: ${res.user?.id}');
    return res.user;
  }

  /// Y a-t-il déjà quelqu'un — même sans nom ?
  bool get aUneSession => _client.auth.currentSession != null;

  /// La personne connectée est-elle anonyme ?
  bool get estAnonyme => _client.auth.currentUser?.isAnonymous ?? false;

  /// S'assure qu'une session existe, en en ouvrant une anonyme au besoin.
  ///
  /// À appeler au premier geste qui produit quelque chose à garder — rejoindre une table,
  /// scanner une carte — et non au démarrage : ouvrir un compte à chaque lancement
  /// gonflerait la facture pour des gens qui n'ont rien fait.
  Future<User?> assurerUneSession() async {
    final actuel = _client.auth.currentUser;
    if (actuel != null) return actuel;
    try {
      return await signInAnonymously();
    } catch (e) {
      // Réglage Supabase absent, réseau coupé : l'app continue sans compte, comme avant.
      AppLogger.warning('AUTH', 'Session anonyme impossible: $e');
      return null;
    }
  }

  /// Transforme le compte anonyme en compte nommé, sans rien déplacer.
  ///
  /// `updateUser(email:)` sur le compte existant : l'identifiant ne change pas, donc les
  /// dégustations, le profil de goût et les conversations restent rattachés à la même
  /// personne. C'est tout l'intérêt d'avoir ouvert un vrai compte dès le départ.
  Future<void> convertirEnCompte(String email) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('aucune session à convertir');
    if (!user.isAnonymous) return; // déjà nommé : rien à faire
    // Le lien de confirmation revient dans l'app (ou sur la page web), pas sur le site par
    // défaut du projet.
    await _client.auth.updateUser(UserAttributes(email: email.trim()), emailRedirectTo: _getRedirectUrl());
    AppLogger.info('AUTH', 'Compte anonyme ${user.id} converti vers ${masquerEmail(email)}');
  }

  /// Passwordless Connection Link (Magic Link) Email Authentication
  Future<void> sendMagicLink(String email) async {
    final redirectUrl = _getRedirectUrl();
    AppLogger.info('AUTH', 'Sending connection link to ${masquerEmail(email)} (redirect: $redirectUrl, platform: ${kIsWeb ? "web" : defaultTargetPlatform.name})');
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectUrl,
    );
  }

  /// Send password reset link to user's email
  Future<void> resetPasswordForEmail(String email) async {
    final redirectUrl = _getRedirectUrl();
    AppLogger.info('AUTH', 'Sending password reset email to ${masquerEmail(email)} (redirect: $redirectUrl)');
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  /// Verify 6-digit OTP code sent to user email (with multi-type fallback)
  Future<void> verifyEmailOtp(String email, String token) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    // Jamais le code lui-même dans les journaux : ils sont lisibles au dépouillement.
    AppLogger.info('AUTH', 'Verifying email OTP for ${masquerEmail(cleanEmail)}');

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
      // Sans ceci, Google réutilise silencieusement le dernier compte connecté sur
      // l'appareil : quelqu'un qui s'est trompé de compte ne peut plus en changer,
      // même après une déconnexion ou un redémarrage du téléphone.
      queryParams: const {'prompt': 'select_account'},
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

        String? cachedAvatar = user.userMetadata?['avatar_url'] as String?;

        try {
          final prefs = await SharedPreferences.getInstance();
          cachedUser ??= prefs.getString('user_profile_username_$userId');
          cachedPhone ??= prefs.getString('user_profile_phone_$userId');
          cachedEmail ??= prefs.getString('user_profile_email_$userId');
          cachedName ??= prefs.getString('user_profile_name_$userId');
          cachedAvatar ??= prefs.getString('user_profile_avatar_$userId');
        } catch (e) {
        AppLogger.debug('AUTH', 'Repli : $e');
      }

        if (profile != null) {
          profile = profile.copyWith(
            username: (profile.username != null && profile.username!.isNotEmpty) ? profile.username : cachedUser,
            phoneNumber: (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) ? profile.phoneNumber : cachedPhone,
            email: (profile.email != null && profile.email!.isNotEmpty) ? profile.email : cachedEmail,
            displayName: profile.displayName != 'User' ? profile.displayName : (cachedName ?? profile.displayName),
            avatarUrl: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) ? profile.avatarUrl : cachedAvatar,
          );
        } else if (cachedUser != null || cachedName != null || cachedAvatar != null) {
          profile = UserProfile(
            id: userId,
            displayName: cachedName ?? user.userMetadata?['display_name'] ?? 'User',
            username: cachedUser,
            phoneNumber: cachedPhone,
            email: cachedEmail ?? user.email,
            avatarUrl: cachedAvatar,
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
    } catch (e) {
        AppLogger.debug('AUTH', 'Repli : $e');
      }

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
    } catch (e) {
        AppLogger.debug('AUTH', 'Repli : $e');
      }

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
    } catch (e) {
        AppLogger.debug('AUTH', 'Repli : $e');
      }

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
            final noLeadingZeroDigits = queryDigits.startsWith('0') ? queryDigits.substring(1) : queryDigits;
            final matchPhone = (queryDigits.length >= 3 && phoneDigits.contains(queryDigits)) ||
                (noLeadingZeroDigits.length >= 3 && phoneDigits.contains(noLeadingZeroDigits));
            return matchUser || matchName || matchEmail || matchPhone;
          })
          .toList();

      return remoteList;
    } catch (e) {
      // Plus de « recherche simulée » : elle renvoyait des profils fictifs (dont un faux
      // « Flavien ») présentés comme de vrais comptes — en cas d'échec, mais aussi chaque
      // fois que la vraie recherche ne trouvait personne. Vu sept fois par le testeur
      // Google Play le 18/09. Un échec remonte maintenant à l'écran, qui le dit.
      AppLogger.warning('AUTH', 'Remote user search failed: $e');
      rethrow;
    }
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
            if (avatarUrl != null) 'avatar_url': avatarUrl,
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
      if (avatarUrl != null) {
        await prefs.setString('user_profile_avatar_${user.id}', avatarUrl);
      }
      await prefs.setString('user_profile_name_${user.id}', displayName);
      if (defaultCurrency != null) {
        await prefs.setString('user_profile_currency_${user.id}', defaultCurrency);
      }
    } catch (e) {
        AppLogger.debug('AUTH', 'Repli : $e');
      }

    // 3. Remote Postgres profiles table Update with fallback
    //
    // JAMAIS le téléphone ni l'e-mail dans `profiles` : la table est lisible par tous,
    // sans compte (politique « Public profiles are viewable by everyone »). Le 29/09,
    // douze adresses e-mail y étaient exposées par le repli `meta://` ci-dessous. Ils
    // restent sur l'appareil et dans le compte d'authentification, pas dans l'annuaire.
    final updates = <String, dynamic>{
      'display_name': displayName,
      if (cleanUsername != null && cleanUsername.isNotEmpty) 'username': cleanUsername,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (defaultCurrency != null) 'default_currency': defaultCurrency,
      if (tasteProfileData != null) 'taste_profile': tasteProfileData,
    };

    try {
      await _client.from('profiles').upsert({'id': user.id, ...updates});
      AppLogger.info('AUTH', 'Updated profiles table for user ${user.id} (handle: @$cleanUsername)');
    } catch (e) {
      AppLogger.warning('AUTH', 'Could not update all profile columns, attempting fallback encoding: $e');
      
      // Repli : le pseudo seul, encodé dans avatar_url faute de colonne `username` en
      // production. Le pseudo est public par nature ; le téléphone et l'e-mail ne le sont
      // pas, et ce repli les y écrivait (voir plus haut).
      final metaAvatar = (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('meta://'))
          ? UserProfile.avatarPseudoSeul(cleanUsername)
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

  /// Permanently deletes the user account and associated personal data,
  /// satisfying Apple Guideline 5.1.1(v), Google Play Account Deletion requirements, and RGPD.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Aucun utilisateur connecté pour supprimer le compte.');
    }

    AppLogger.warning('AUTH', 'Initiating permanent account deletion for user: ${user.id}');

    // 1. Appeler la fonction RPC Supabase delete_user_account
    await _client.rpc('delete_user_account');

    // 2. Nettoyer le cache local SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_username_${user.id}');
      await prefs.remove('user_profile_configured_${user.id}');
      await prefs.remove('user_profile_phone_${user.id}');
      await prefs.remove('user_profile_email_${user.id}');
      await prefs.remove('user_profile_name_${user.id}');
      await prefs.remove('user_profile_currency_${user.id}');
    } catch (e) {
      AppLogger.warning('AUTH', 'Error clearing local profile cache during account deletion: $e');
    }

    // 3. Déconnexion de la session
    try {
      await _client.auth.signOut();
    } catch (e) {
        AppLogger.debug('AUTH', 'Repli : $e');
      }
    AppLogger.info('AUTH', 'Account deletion complete and session terminated.');
  }
}

/// Une adresse e-mail pour les journaux : assez pour s'y retrouver, pas assez pour l'avoir.
/// « flavien.daussy@gmail.com » devient « f…@gmail.com ».
String masquerEmail(String email) {
  final e = email.trim();
  final at = e.indexOf('@');
  if (at <= 0) return '…';
  return '${e[0]}…${e.substring(at)}';
}
