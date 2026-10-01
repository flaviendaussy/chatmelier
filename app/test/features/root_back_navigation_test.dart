import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chatmelier/shared/widgets/adaptive_app_shell.dart';
import 'package:chatmelier/config/navigator_keys.dart';

/// Le retour arrière depuis un onglet autre que la cave (« Ce soir » depuis la V2.3 · E1 :
/// le chat n'est plus un onglet).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Back navigation: /ce-soir -> Cave (/) -> System Exit', (tester) async {
    final testRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/ce-soir',
      routes: [
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return AdaptiveAppShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Cave')),
              ),
            ),
            GoRoute(
              path: '/ce-soir',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Ce soir')),
              ),
            ),
            GoRoute(
              path: '/ce-soir',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Ce soir')),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initially on /bar
    expect(find.text('Screen: Ce soir'), findsOneWidget);
    expect(find.text('Screen: Cave'), findsNothing);

    // 2. Press back button: Non-cellar -> Cave
    final backFromChatHandled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Handled by PopScope
    expect(backFromChatHandled, isTrue);

    // Navigated to Cave (accueil)
    expect(find.text('Screen: Cave'), findsOneWidget);
    expect(find.text('Screen: Ce soir'), findsNothing);
    expect(testRouter.state.matchedLocation, equals('/'));

    // 3. Press back button again: Cave -> System Exit
    final backFromCaveHandled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // System exit (canPop is true, so no route was popped by handlePopRoute)
    expect(backFromCaveHandled, isFalse);
    expect(find.text('Screen: Cave'), findsOneWidget);
  });

  testWidgets('Back navigation: /ce-soir -> Cave (/) -> System Exit', (tester) async {
    final testRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/ce-soir',
      routes: [
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return AdaptiveAppShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Cave')),
              ),
            ),
            GoRoute(
              path: '/ce-soir',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Ce soir')),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Screen: Ce soir'), findsOneWidget);

    // 1. Back press: Chat -> Cave
    final handledFirst = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handledFirst, isTrue);
    expect(find.text('Screen: Cave'), findsOneWidget);
    expect(testRouter.state.matchedLocation, equals('/'));

    // 2. Back press: Cave -> System Exit
    final handledSecond = await tester.binding.handlePopRoute();
    expect(handledSecond, isFalse);
  });

  testWidgets('Bottom sheet opened on a tab is popped before navigating to Cave', (tester) async {
    final testRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/ce-soir',
      routes: [
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return AdaptiveAppShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Cave')),
              ),
            ),
            GoRoute(
              path: '/ce-soir',
              pageBuilder: (context, state) => NoTransitionPage(
                child: Scaffold(
                  body: Builder(
                    builder: (btnCtx) => ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: btnCtx,
                          builder: (_) => const Text('Bar Bottom Sheet Content'),
                        );
                      },
                      child: const Text('Open Sheet'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Bar Bottom Sheet Content'), findsOneWidget);

    // Back press 1: closes bottom sheet, stays on Bar
    final back1Handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(back1Handled, isTrue);
    expect(find.text('Bar Bottom Sheet Content'), findsNothing);
    expect(find.text('Open Sheet'), findsOneWidget);
    expect(testRouter.state.matchedLocation, equals('/ce-soir'));

    // Back press 2: Bar -> Cave
    final back2Handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(back2Handled, isTrue);
    expect(find.text('Screen: Cave'), findsOneWidget);
    expect(testRouter.state.matchedLocation, equals('/'));

    // Back press 3: Cave -> System Exit
    final back3Handled = await tester.binding.handlePopRoute();
    expect(back3Handled, isFalse);
  });
}
