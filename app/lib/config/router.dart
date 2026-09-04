import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/cellar/presentation/cellar_screen.dart';
import '../features/cellar/presentation/bottle_detail_screen.dart';
import '../features/cellar/presentation/cellar_sharing_screen.dart';
import '../features/cellar/presentation/pending_invites_screen.dart';
import '../features/cellar/domain/bottle.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../features/scan/presentation/review_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/checkout/presentation/match_confirm_screen.dart';
import '../features/checkout/presentation/consumption_review_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/journal/presentation/journal_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/changelog/presentation/changelog_screen.dart';
import '../features/changelog/presentation/diagnostic_logs_screen.dart';
import '../features/scratchcard/presentation/scratch_map_screen.dart';
import '../features/auth/presentation/ai_cost_estimator_screen.dart';
import '../features/friends/presentation/friends_screen.dart';
import '../features/cocktails/presentation/bar_cocktails_hub_screen.dart';
import '../shared/widgets/adaptive_app_shell.dart';
import '../shared/providers/supabase_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

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

      if (!isLoggedIn && !isAuthRoute && !isInviteRoute) return '/login';
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

      // Main app shell with adaptive responsive navigation (Mobile / Tablet / Desktop)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
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
        path: '/cellar/:id',
        builder: (context, state) =>
            BottleDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cellar/bottle/:id',
        builder: (context, state) =>
            BottleDetailScreen(id: state.pathParameters['id']!),
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
        path: '/changelog',
        builder: (context, state) => const ChangelogScreen(),
      ),
      GoRoute(
        path: '/scratchcard',
        builder: (context, state) => const ScratchMapScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const ScratchMapScreen(),
      ),
      GoRoute(
        path: '/bar',
        builder: (context, state) => const BarCocktailsHubScreen(),
      ),
      GoRoute(
        path: '/cocktails',
        builder: (context, state) => const BarCocktailsHubScreen(),
      ),
      GoRoute(
        path: '/terroirs',
        builder: (context, state) => const ScratchMapScreen(),
      ),
      GoRoute(
        path: '/diagnostic-logs',
        builder: (context, state) => const DiagnosticLogsScreen(),
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

