import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import 'garde_des_routes.dart';
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
import '../features/menu_scan/domain/menu_wine.dart';
import '../features/menu_scan/presentation/menu_photo_capture_screen.dart';
import '../features/menu_scan/presentation/enriched_menu_screen.dart';
import '../features/menu_scan/presentation/menu_table_consensus_guest_screen.dart';
import '../shared/widgets/adaptive_app_shell.dart';
import '../shared/providers/supabase_provider.dart';

export 'navigator_keys.dart';
import 'navigator_keys.dart';
import '../features/ce_soir/presentation/ce_soir_screen.dart';

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

      // UNE SESSION ANONYME N'EST PAS UN COMPTE.
      //
      // Le garde testait `session != null`. Depuis que rejoindre une table ouvre un
      // compte anonyme, ce test devenait vrai pour un invité de passage — avec deux
      // conséquences, l'une gênante et l'autre bloquante :
      //
      //   · il était déposé dans la cave, un écran qui suppose un compte, où la création
      //     de cave lui est désormais refusée par la RLS (migration 039) : il aurait vu
      //     des échecs sans explication ;
      //   · `isLoggedIn && isAuthRoute → '/'` l'empêchait d'atteindre /login et /register.
      //     Il se retrouvait enfermé dans un compte anonyme, sans aucun chemin visible
      //     pour s'inscrire — exactement la conversion qu'on venait de construire.
      //
      // Un anonyme est donc traité comme un visiteur : les parcours invités lui sont
      // ouverts, le reste demande un vrai compte. Ce n'est pas une restriction ajoutée,
      // c'est l'état antérieur préservé.
      //
      // Depuis le 07/10 (V2.4 · R2), l'app installée exige un vrai compte dès la première
      // ouverture ; seule la page web garde ses parcours invités sans compte.
      final estAnonyme = session?.user.isAnonymous ?? false;
      final isLoggedIn = session != null && !estAnonyme;
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

      return GardeDesRoutes.redirection(
        web: kIsWeb,
        connecte: isLoggedIn,
        chemin: state.matchedLocation,
        emplacement: state.uri.toString(),
        suite: state.uri.queryParameters['suite'],
      );
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(suite: GardeDesRoutes.suiteSure(state.uri.queryParameters['suite'])),
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

      // Blind Battle est masqué (V2.3 · I2) : un ancien QR mène à l'accueil plutôt qu'à une
      // partie qui n'existe que sur le téléphone de l'hôte.
      GoRoute(path: '/blind', redirect: (context, state) => '/login'),
      GoRoute(path: '/blind/:sessionId', redirect: (context, state) => '/login'),
      GoRoute(path: '/blind-host', redirect: (context, state) => '/'),

      // Le lien d'une table (QR, partage) : https://chatmelier.github.io/table/?t=CODE. Sur le
      // web, c'est la page invité légère ; ouvert dans l'app installée (#25), l'écran invité
      // de l'app, avec le palais de son compte.
      GoRoute(
        path: '/table',
        builder: (context, state) => MenuTableConsensusGuestScreen(codeTable: state.uri.queryParameters['t']),
      ),

      // Table Consensus routes (public access for guests via QR code on web or app)
      GoRoute(
        path: '/table-consensus',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['session'] ?? state.uri.queryParameters['s'];
          final data = state.uri.queryParameters['data'] ?? state.uri.queryParameters['d'];
          return MenuTableConsensusGuestScreen(
            initialSessionId: sessionId,
            initialData: data,
            codeTable: state.uri.queryParameters['table'],
          );
        },
      ),
      GoRoute(
        path: '/menu-match',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['session'] ?? state.uri.queryParameters['s'];
          final data = state.uri.queryParameters['data'] ?? state.uri.queryParameters['d'];
          return MenuTableConsensusGuestScreen(
            initialSessionId: sessionId,
            initialData: data,
            codeTable: state.uri.queryParameters['table'],
          );
        },
      ),

      // Public Restaurant Menu Scan routes (no account required)
      GoRoute(
        path: '/scan/menu',
        builder: (context, state) => MenuPhotoCaptureScreen(ardoise: state.uri.queryParameters['mode'] == 'ardoise'),
      ),
      GoRoute(
        path: '/scan/menu/result',
        builder: (context, state) {
          // `extra` n'est pas toujours une ScannedMenu : restauré après que le système a
          // tué l'app, ou rejoué par le navigateur, il revient sérialisé en Map — d'où le
          // plantage du 18/09 (« _Map<String, dynamic> is not a subtype of ScannedMenu »).
          final extra = state.extra;
          if (extra is ScannedMenu) return EnrichedMenuScreen(menu: extra);
          if (extra is Map) {
            return EnrichedMenuScreen(menu: ScannedMenu.fromJson(Map<String, dynamic>.from(extra)));
          }
          return const DerniereCarteOuScan();
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
            path: '/ce-soir',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CeSoirScreen(),
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

      // Le sommelier (le chat) n'a plus d'onglet : un bouton l'ouvre de partout, en plein
      // écran par-dessus l'onglet en cours (V2.3 · E1). Une question peut l'accompagner :
      // jusqu'ici elle était transmise puis ignorée (« demander au sommelier » depuis les
      // accords inversés ou la pédagogie ouvrait un chat vide).
      GoRoute(
        path: '/chat',
        builder: (context, state) => ChatScreen(
          questionInitiale: state.extra is String ? state.extra as String : null,
        ),
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
      // La console d'administration. L'écran ne porte AUCUNE clé : il appelle des
      // fonctions SQL qui vérifient `profiles.is_admin` côté serveur (migration 041).
      // Y arriver sans le droit ne montre donc qu'un refus, pas des données.
      GoRoute(
        path: '/admin/console',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
    ],
  );
});
