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
import '../features/voice/presentation/voice_dictation_sheet.dart';
import '../features/journal/presentation/external_tasting_dialog.dart';
import '../features/auth/presentation/ai_cost_estimator_screen.dart';
import '../features/friends/presentation/friends_screen.dart';
import '../shared/providers/supabase_provider.dart';
import '../l10n/app_localizations.dart';

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

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _AppShell(child: child);
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
        builder: (context, state) => ReviewScreen(
          imagePath: (state.extra as String?) ?? '',
        ),
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
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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

/// App shell with bottom navigation bar
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/journal') || location.startsWith('/history') || location.startsWith('/historique')) return 2;
    if (location.startsWith('/stats')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final l10n = AppLocalizations.of(context);

    final tabs = [
      (icon: Icons.wine_bar_outlined, activeIcon: Icons.wine_bar, label: l10n?.navCellar ?? 'Ma Cave'),
      (icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: l10n?.navChat ?? 'Chatmelier'),
      (icon: Icons.history_outlined, activeIcon: Icons.history, label: l10n?.navJournal ?? 'Historique'),
      (icon: Icons.insights_outlined, activeIcon: Icons.insights, label: l10n?.navStats ?? 'Statistiques'),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/history');
              break;
            case 3:
              context.go('/stats');
              break;
          }
        },
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
      floatingActionButton: index == 0
          ? FloatingActionButton(
              onPressed: () => _showCellarActionMenu(context),
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  void _showCellarActionMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.actionMenuTitle ?? 'Actions Cave',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            _ActionMenuItem(
              icon: Icons.add_a_photo_outlined,
              color: const Color(0xFF8B1E3F),
              title: l10n?.actionAddBottle ?? 'Ajouter une bouteille',
              subtitle: l10n?.actionAddBottleSub ?? 'Scanner une étiquette ou saisie manuelle',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/scan');
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.mic_outlined,
              color: Colors.purple.shade700,
              title: 'Ajout Rapide à la Voix (Sommelier)',
              subtitle: 'Dictez vos bouteilles naturellement à l\'IA',
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const VoiceDictationSheet(),
                );
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.wine_bar_outlined,
              color: const Color(0xFFD4AF37),
              title: l10n?.actionCheckoutBottle ?? 'Déguster / Sortir une bouteille',
              subtitle: l10n?.actionCheckoutBottleSub ?? 'Enregistrer une dégustation et sortir du stock',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/checkout');
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.restaurant_outlined,
              color: const Color(0xFFE65100),
              title: 'Déguster Hors-Cave (Restaurant, Amis)',
              subtitle: 'Noter un vin bu à l\'extérieur sans toucher au stock',
              onTap: () {
                Navigator.pop(ctx);
                ExternalTastingDialog.show(context);
              },
            ),
            const SizedBox(height: 8),
            _ActionMenuItem(
              icon: Icons.auto_awesome_outlined,
              color: const Color(0xFF2E7D32),
              title: l10n?.actionLookupWine ?? 'Consulter / Identifier un vin',
              subtitle: l10n?.actionLookupWineSub ?? 'Découverte et analyse instantanée par l\'IA',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/chat');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
