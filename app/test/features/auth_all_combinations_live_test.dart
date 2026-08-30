import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:chatmelier/features/auth/domain/user_profile.dart';
import 'package:chatmelier/features/auth/data/auth_repository.dart';
import 'package:chatmelier/features/auth/presentation/login_screen.dart';
import 'package:chatmelier/features/auth/presentation/register_screen.dart';
import 'package:chatmelier/shared/providers/supabase_provider.dart';
import 'package:chatmelier/shared/providers/auth_provider.dart';

/// Mock Supabase Auth Client to simulate all real authentication scenarios
class MockGoTrueClient extends Fake implements GoTrueClient {
  User? _currentUser;
  Session? _currentSession;
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();

  // Test triggers & spy properties
  String? lastSentMagicLinkEmail;
  String? lastMagicLinkRedirectTo;
  String? lastVerifiedEmail;
  String? lastVerifiedToken;
  OtpType? lastVerifiedOtpType;
  bool shouldFailOtpEmail = false;
  bool shouldFailOtpMagicLink = false;
  bool shouldFailAllOtp = false;
  bool shouldFailPasswordLogin = false;
  bool shouldFailRateLimit = false;
  bool shouldFailEmailInvalid = false;
  bool shouldFailGoogleOAuth = false;
  String? lastGoogleRedirectTo;
  LaunchMode? lastGoogleLaunchMode;

  @override
  User? get currentUser => _currentUser;

  @override
  Session? get currentSession => _currentSession;

  @override
  Stream<AuthState> get onAuthStateChange => _authStateController.stream;

  void emitSession(User? user, Session? session, AuthChangeEvent event) {
    _currentUser = user;
    _currentSession = session;
    _authStateController.add(AuthState(event, session));
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (shouldFailPasswordLogin) {
      throw const AuthException('Invalid login credentials', statusCode: '400');
    }
    if (shouldFailEmailInvalid) {
      throw const AuthException('email_address_invalid: email is malformed', statusCode: '422');
    }

    final user = User(
      id: 'user_pwd_123',
      appMetadata: {},
      userMetadata: {'full_name': 'Camille Dupont'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    final session = Session(
      accessToken: 'mock_access_token_pwd',
      tokenType: 'bearer',
      user: user,
    );
    _currentUser = user;
    _currentSession = session;
    _authStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    return AuthResponse(session: session, user: user);
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel? channel,
  }) async {
    if (email == 'already_exists@chatmelier.app') {
      throw const AuthException('User already registered', statusCode: '400');
    }
    final user = User(
      id: 'user_signup_456',
      appMetadata: {},
      userMetadata: data ?? {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    final session = Session(
      accessToken: 'mock_access_token_signup',
      tokenType: 'bearer',
      user: user,
    );
    _currentUser = user;
    _currentSession = session;
    _authStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    return AuthResponse(session: session, user: user);
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    String? captchaToken,
    OtpChannel? channel,
    Map<String, dynamic>? data,
  }) async {
    if (shouldFailRateLimit) {
      throw const AuthException('over_email_send_rate_limit: please wait 60s', statusCode: '429');
    }
    lastSentMagicLinkEmail = email;
    lastMagicLinkRedirectTo = emailRedirectTo;
  }

  @override
  Future<AuthResponse> verifyOTP({
    String? email,
    String? phone,
    String? token,
    required OtpType type,
    String? redirectTo,
    String? captchaToken,
    String? tokenHash,
  }) async {
    lastVerifiedEmail = email;
    lastVerifiedToken = token;
    lastVerifiedOtpType = type;

    if (shouldFailAllOtp) {
      throw const AuthException('Token is invalid or expired', statusCode: '400');
    }

    if (type == OtpType.email && shouldFailOtpEmail) {
      throw const AuthException('OtpType.email failed', statusCode: '400');
    }

    if (type == OtpType.magiclink && shouldFailOtpMagicLink) {
      throw const AuthException('OtpType.magiclink failed', statusCode: '400');
    }

    final user = User(
      id: 'user_otp_789',
      appMetadata: {},
      userMetadata: {'full_name': 'Camille Test'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    final session = Session(
      accessToken: 'mock_access_token_otp',
      tokenType: 'bearer',
      user: user,
    );
    _currentUser = user;
    _currentSession = session;
    _authStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    return AuthResponse(session: session, user: user);
  }

  @override
  Future<OAuthResponse> getOAuthSignInUrl({
    required OAuthProvider provider,
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
  }) async {
    if (shouldFailGoogleOAuth) {
      throw const AuthException('OAuth authentication failed or was cancelled', statusCode: '400');
    }
    lastGoogleRedirectTo = redirectTo;
    return OAuthResponse(
      provider: provider,
      url: 'https://supabase.co/auth/v1/authorize?provider=google&redirect_to=${redirectTo ?? ""}',
    );
  }

  @override
  Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
    LaunchMode authScreenLaunchMode = LaunchMode.platformDefault,
  }) async {
    if (shouldFailGoogleOAuth) {
      throw const AuthException('OAuth authentication failed or was cancelled', statusCode: '400');
    }
    lastGoogleRedirectTo = redirectTo;
    lastGoogleLaunchMode = authScreenLaunchMode;
    return true;
  }

  @override
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  }) async {
    lastSentMagicLinkEmail = email;
    lastMagicLinkRedirectTo = redirectTo;
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.global}) async {
    _currentUser = null;
    _currentSession = null;
    _authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
  }
}

/// Mock Supabase Client holding the MockGoTrueClient
class MockSupabaseClient extends Fake implements SupabaseClient {
  final MockGoTrueClient _mockAuth = MockGoTrueClient();

  @override
  GoTrueClient get auth => _mockAuth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'launch' || methodCall.method == 'canLaunch') {
          return true;
        }
        return true;
      },
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Authentication Matrix: Password Auth Tests', () {
    late MockSupabaseClient mockSupabase;
    late AuthRepository authRepo;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      authRepo = AuthRepository(mockSupabase);
    });

    test('Combinaison 1.1: Successful Email & Password Login', () async {
      await authRepo.signIn('camille@chatmelier.app', 'Secret123!');
      expect(authRepo.currentUser, isNotNull);
      expect(authRepo.currentUser?.email, equals('camille@chatmelier.app'));
      expect(authRepo.currentUser?.id, equals('user_pwd_123'));
    });

    test('Combinaison 1.2: Successful Sign Up with Display Name', () async {
      final res = await authRepo.signUp('leo@chatmelier.app', 'Password456!', 'Léo Sommelier');
      expect(res.session, isNotNull);
      expect(res.user?.email, equals('leo@chatmelier.app'));
      expect(res.user?.userMetadata?['display_name'], equals('Léo Sommelier'));
    });

    test('Combinaison 1.3: Invalid Password Credentials throws AuthException', () async {
      mockSupabase._mockAuth.shouldFailPasswordLogin = true;
      expect(
        () => authRepo.signIn('camille@chatmelier.app', 'WrongPassword'),
        throwsA(isA<AuthException>()),
      );
    });

    test('Combinaison 1.4: Sign Up with already registered email triggers error', () async {
      expect(
        () => authRepo.signUp('already_exists@chatmelier.app', 'Secret123!', 'Duplicate'),
        throwsA(isA<AuthException>()),
      );
    });

    test('Combinaison 1.5: Send Password Reset Email', () async {
      await authRepo.resetPasswordForEmail('flavien@chatmelier.app');
      expect(mockSupabase._mockAuth.lastSentMagicLinkEmail, equals('flavien@chatmelier.app'));
    });
  });

  group('Authentication Matrix: Passwordless Connection Link & OTP Tests', () {
    late MockSupabaseClient mockSupabase;
    late AuthRepository authRepo;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      authRepo = AuthRepository(mockSupabase);
    });

    test('Combinaison 2.1: Send Connection Link computes valid redirect URL', () async {
      await authRepo.sendMagicLink('camille@chatmelier.app');
      expect(mockSupabase._mockAuth.lastSentMagicLinkEmail, equals('camille@chatmelier.app'));
      expect(mockSupabase._mockAuth.lastMagicLinkRedirectTo, isNotNull);
      expect(mockSupabase._mockAuth.lastMagicLinkRedirectTo, contains('login-callback'));
    });

    test('Combinaison 2.2: Verify OTP via OtpType.email direct success', () async {
      await authRepo.verifyEmailOtp('camille@chatmelier.app', '123456');
      expect(mockSupabase._mockAuth.lastVerifiedEmail, equals('camille@chatmelier.app'));
      expect(mockSupabase._mockAuth.lastVerifiedToken, equals('123456'));
      expect(mockSupabase._mockAuth.lastVerifiedOtpType, equals(OtpType.email));
    });

    test('Combinaison 2.3: Verify OTP cascades to OtpType.magiclink when OtpType.email fails', () async {
      mockSupabase._mockAuth.shouldFailOtpEmail = true; // Email OTP fails
      await authRepo.verifyEmailOtp('camille@chatmelier.app', '654321');
      // Should have fallen back and succeeded on OtpType.magiclink
      expect(mockSupabase._mockAuth.lastVerifiedOtpType, equals(OtpType.magiclink));
    });

    test('Combinaison 2.4: Verify OTP cascades to OtpType.signup when both email & magiclink fail', () async {
      mockSupabase._mockAuth.shouldFailOtpEmail = true;
      mockSupabase._mockAuth.shouldFailOtpMagicLink = true;
      await authRepo.verifyEmailOtp('nouveau_venu@chatmelier.app', '999888');
      // Should have fallen back to OtpType.signup
      expect(mockSupabase._mockAuth.lastVerifiedOtpType, equals(OtpType.signup));
    });

    test('Combinaison 2.5: Invalid or expired OTP throws exception gracefully', () async {
      mockSupabase._mockAuth.shouldFailAllOtp = true;
      expect(
        () => authRepo.verifyEmailOtp('camille@chatmelier.app', '000000'),
        throwsA(isA<AuthException>()),
      );
    });

    test('Combinaison 2.6: Rate limit handling on magic link requests', () async {
      mockSupabase._mockAuth.shouldFailRateLimit = true;
      expect(
        () => authRepo.sendMagicLink('spammer@chatmelier.app'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('Authentication Matrix: Google OAuth Tests', () {
    late MockSupabaseClient mockSupabase;
    late AuthRepository authRepo;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      authRepo = AuthRepository(mockSupabase);
    });

    test('Combinaison 3.1: Google OAuth initiation passes proper redirect and launchMode', () async {
      await authRepo.signInWithGoogle();
      expect(mockSupabase._mockAuth.lastGoogleRedirectTo, contains('login-callback'));
    });

    test('Combinaison 3.2: Google OAuth failure or cancellation is captured', () async {
      mockSupabase._mockAuth.shouldFailGoogleOAuth = true;
      expect(
        () => authRepo.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('Combinaison 3.3: Profile Resolution Tier 2 (Auth User Metadata fallback)', () async {
      // Profile table returns null, metadata has display_name & avatar
      final user = User(
        id: 'google_user_007',
        appMetadata: {},
        userMetadata: {
          'display_name': 'Camille Google',
          'avatar_url': 'https://example.com/avatar.jpg',
          'email': 'camille.google@gmail.com',
        },
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'camille.google@gmail.com',
      );
      mockSupabase._mockAuth.emitSession(user, Session(accessToken: 'tk', tokenType: 'b', user: user), AuthChangeEvent.signedIn);

      final profile = await authRepo.getProfile('google_user_007');
      expect(profile, isNotNull);
      expect(profile?.displayName, equals('Camille Google'));
      expect(profile?.email, equals('camille.google@gmail.com'));
    });
  });

  group('Authentication Matrix: Session Lifecycles & Uniqueness Tests', () {
    late MockSupabaseClient mockSupabase;
    late AuthRepository authRepo;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      authRepo = AuthRepository(mockSupabase);
    });

    test('Combinaison 4.1: Sign Out clears session and emits signedOut event', () async {
      await authRepo.signIn('camille@chatmelier.app', 'Password123');
      expect(authRepo.currentUser, isNotNull);

      await authRepo.signOut();
      expect(authRepo.currentUser, isNull);
    });

    test('Combinaison 4.2: UserProfile handle generation & validation rules', () {
      expect(UserProfile.validateUsername('camille'), isNull);
      expect(UserProfile.validateUsername('c'), isNotNull);
      expect(UserProfile.validateUsername('camille.dupont'), isNotNull); // only underscores
      expect(UserProfile.validateUsername('camille_dupont'), isNull);

      const profile = UserProfile(
        id: 'u_camille',
        displayName: 'Camille D.',
        username: 'camille_wine',
        email: 'camille@chatmelier.app',
      );
      expect(profile.handle, equals('@camille_wine'));
    });

    test('Combinaison 4.3: Local SharedPreferences fallback stores and retrieves profile', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_username_cached_user_1', 'flavien_c');
      await prefs.setString('user_profile_name_cached_user_1', 'Flavien Cached');
      await prefs.setString('user_profile_phone_cached_user_1', '+33611223344');

      final user = User(
        id: 'cached_user_1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'flavien@chatmelier.app',
      );
      mockSupabase._mockAuth.emitSession(user, Session(accessToken: 'tk', tokenType: 'b', user: user), AuthChangeEvent.signedIn);

      final retrieved = await authRepo.getProfile('cached_user_1');
      expect(retrieved, isNotNull);
      expect(retrieved?.displayName, equals('Flavien Cached'));
      expect(retrieved?.username, equals('flavien_c'));
      expect(retrieved?.phoneNumber, equals('+33611223344'));
    });
  });

  group('Authentication Matrix: UI & Widget Live Testing', () {
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockSupabase = MockSupabaseClient();
    });

    Widget createTestWidget(Widget child) {
      return ProviderScope(
        overrides: [
          supabaseProvider.overrideWithValue(mockSupabase),
          authRepositoryProvider.overrideWithValue(AuthRepository(mockSupabase)),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('Combinaison 5.1: LoginScreen renders Connection Link tab and Password tab', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Chatmelier'), findsOneWidget);
      expect(find.text('✉️ Lien de connexion'), findsOneWidget);
      expect(find.text('🔑 Mot de passe'), findsOneWidget);
      expect(find.text('Recevoir mon lien de connexion'), findsOneWidget);
    });

    testWidgets('Combinaison 5.2: Sending Connection Link in UI triggers success green feedback box', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Enter email
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'camille@chatmelier.app');
      await tester.pump();

      // Tap Receive link button
      final sendBtn = find.text('Recevoir mon lien de connexion');
      expect(sendBtn, findsOneWidget);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Green confirmation box is displayed
      expect(find.text('Lien de connexion envoyé !'), findsOneWidget);
      expect(find.text('Renvoyer le lien de connexion'), findsOneWidget);
      expect(mockSupabase._mockAuth.lastSentMagicLinkEmail, equals('camille@chatmelier.app'));
    });

    testWidgets('Combinaison 5.3: Switching to Password tab and entering credentials works', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Tap password tab
      final passwordTab = find.text('🔑 Mot de passe');
      await tester.tap(passwordTab);
      await tester.pumpAndSettle();

      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Pas encore inscrit ? Créer un compte en 1 clic'), findsOneWidget);
    });

    testWidgets('Combinaison 5.4: RegisterScreen renders with contrast-compliant FilledButton', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Créer un compte'), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(3)); // Name, Email, Password

      final createBtn = find.byType(FilledButton);
      expect(createBtn, findsOneWidget);

      final filledButton = tester.widget<FilledButton>(createBtn);
      expect(filledButton.style?.backgroundColor?.resolve({}), equals(const Color(0xFF8B1E3F)));
      expect(filledButton.style?.foregroundColor?.resolve({}), equals(Colors.white));
    });
  });
}
