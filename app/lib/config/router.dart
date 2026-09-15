import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/cellar/presentation/cellar_screen.dart';
import '../features/cellar/presentation/bottle_detail_screen.dart';
import '../features/cellar/presentation/cellar_sharing_screen.dart';
import '../features/cellar/presentation/pending_invites_screen.dart';
import '../features/cellar/presentation/excel_import_screen.dart';
import '../features/cellar/domain/bottle.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../features/scan/presentation/review_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/checkout/presentation/match_confirm_screen.dart';
import '../features/checkout/presentation/consumption_review_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/journal/presentation/journal_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/auth/presentation/ai_cost_estimator_screen.dart';
import '../features/friends/presentation/friends_screen.dart';
import '../features/cocktails/presentation/bar_cocktails_hub_screen.dart';
import '../features/menu_scan/domain/menu_wine.dart';
import '../features/menu_scan/presentation/menu_photo_capture_screen.dart';
import '../features/menu_scan/presentation/enriched_menu_screen.dart';
import '../features/blind_battle/presentation/blind_battle_guest_screen.dart';
import '../features/blind_battle/presentation/blind_battle_host_screen.dart';
import '../features/menu_scan/presentation/menu_table_consensus_guest_screen.dart';
import '../shared/widgets/adaptive_app_shell.dart';
import '../shared/providers/supabase_provider.dart';

export 'navigator_keys.dart';
import 'navigator_keys.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isInviteRoute = state.matchedLocation.startsWith('/invite/');
      final isBlindBattleRoute = state.matchedLocation.startsWith('/blind');
      final isTableConsensusRoute = state.matchedLocation.startsWith('/table-consensus') ||
          state.matchedLocation.startsWith('/menu-match');
      final isMenuScanRoute = state.matchedLocation.startsWith('/scan/menu');
      if (kIsWeb) {
        final uri = Uri.base;
        final isOAuthCallback = uri.queryParameters.containsKey('code') ||
            uri.queryParameters.containsKey('error') ||
            uri.fragment.contains('access_token') ||
            uri.fragment.contains('error');
        if (isOAuthCallback && !isLoggedIn) {
          // Allow Supabase auth to process incoming tokens without wiping URL
          return null;
        }
      }

      if (!isLoggedIn && !isAuthRoute && !isInviteRoute && !isBlindBattleRoute && !isTableConsensusRoute && !isMenuScanRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Deep link for invite codes
      GoRoute(
        path: '/invite/:code',
        builder: (context, state) {
          return const PendingInvitesScreen();
        },
      ),

      // Blind Battle routes (public access for guests via QR code or host)
      GoRoute(
        path: '/blind',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['session'];
          return BlindBattleGuestScreen(initialSessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/blind/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'];
          return BlindBattleGuestScreen(initialSessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/blind-host',
        builder: (context, state) {
          return const BlindBattleHostScreen();
        },
      ),

      // Table Consensus routes (public access for guests via QR code on web or app)
      GoRoute(
        path: '/table-consensus',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['session'] ?? state.uri.queryParameters['s'];
          final data = state.uri.queryParameters['data'] ?? state.uri.queryParameters['d'];
          return MenuTableConsensusGuestScreen(initialSessionId: sessionId, initialData: data);
        },
      ),
      GoRoute(
        path: '/menu-match',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['session'] ?? state.uri.queryParameters['s'];
          final data = state.uri.queryParameters['data'] ?? state.uri.queryParameters['d'];
          return MenuTableConsensusGuestScreen(initialSessionId: sessionId, initialData: data);
        },
      ),

      // Public Restaurant Menu Scan routes (no account required)
      GoRoute(
        path: '/scan/menu',
        builder: (context, state) => const MenuPhotoCaptureScreen(),
      ),
      GoRoute(
        path: '/scan/menu/result',
        builder: (context, state) {
          final menu = state.extra as ScannedMenu;
          return EnrichedMenuScreen(menu: menu);
        },
      ),

      // Main app shell with adaptive responsive navigation (Mobile / Tablet / Desktop)
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AdaptiveAppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CellarScreen(),
            ),
          ),
          GoRoute(
            path: '/bar',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BarCocktailsHubScreen(),
            ),
          ),
          GoRoute(
            path: '/cocktails',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BarCocktailsHubScreen(),
            ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatScreen(),
            ),
          ),
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/historique',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: '/cellar/import-excel',
        builder: (context, state) {
          final cellarId = state.uri.queryParameters['cellarId'] ?? '';
          return ExcelImportScreen(cellarId: cellarId);
        },
      ),
      GoRoute(
        path: '/cellar-import-excel',
        builder: (context, state) {
          final cellarId = state.uri.queryParameters['cellarId'] ?? '';
          return ExcelImportScreen(cellarId: cellarId);
        },
      ),
      GoRoute(
        path: '/bottle/:id',
        redirect: (context, state) {
          final rawId = state.pathParameters['id']?.replaceAll(' ', '').trim() ?? '';
          return '/cellar/bottle/$rawId';
        },
      ),
      GoRoute(
        path: '/cellar/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']?.replaceAll(' ', '').trim() ?? '';
          return BottleDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/cellar/bottle/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']?.replaceAll(' ', '').trim() ?? '';
          return BottleDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            return ReviewScreen(
              imagePath: (map['path'] as String?) ?? '',
              imageBytes: map['bytes'] as Uint8List?,
              prefillBottle: map['prefillBottle'] as Bottle?,
            );
          }
          return ReviewScreen(
            imagePath: (state.extra as String?) ?? '',
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => CheckoutScreen(
          bottleId: state.uri.queryParameters['bottleId'],
        ),
      ),
      GoRoute(
        path: '/checkout/confirm',
        builder: (context, state) => const MatchConfirmScreen(),
      ),
      GoRoute(
        path: '/checkout/review',
        builder: (context, state) => const ConsumptionReviewScreen(),
      ),
      GoRoute(
        path: '/sharing/:cellarId',
        builder: (context, state) => CellarSharingScreen(
          cellarId: state.pathParameters['cellarId']!,
          cellarName: state.uri.queryParameters['name'] ?? 'Cellar',
        ),
      ),
      GoRoute(
        path: '/invites',
        builder: (context, state) => const PendingInvitesScreen(),
      ),
      GoRoute(
        path: '/ai-costs',
        builder: (context, state) => const AiCostEstimatorScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
    ],
  );
});
