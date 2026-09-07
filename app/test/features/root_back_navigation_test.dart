import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chatmelier/shared/widgets/adaptive_app_shell.dart';
import 'package:chatmelier/config/navigator_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Back navigation: /bar -> Cave (/) -> System Exit', (tester) async {
    final testRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/bar',
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
              path: '/bar',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Bar')),
              ),
            ),
            GoRoute(
              path: '/chat',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Chat')),
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
    expect(find.text('Screen: Bar'), findsOneWidget);
    expect(find.text('Screen: Cave'), findsNothing);

    // 2. Press back button: Non-cellar -> Cave
    final backFromBarHandled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Handled by PopScope
    expect(backFromBarHandled, isTrue);

    // Navigated to Cave (accueil)
    expect(find.text('Screen: Cave'), findsOneWidget);
    expect(find.text('Screen: Bar'), findsNothing);
    expect(testRouter.state.matchedLocation, equals('/'));

    // 3. Press back button again: Cave -> System Exit
    final backFromCaveHandled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // System exit (canPop is true, so no route was popped by handlePopRoute)
    expect(backFromCaveHandled, isFalse);
    expect(find.text('Screen: Cave'), findsOneWidget);
  });

  testWidgets('Back navigation: /chat -> Cave (/) -> System Exit', (tester) async {
    final testRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/chat',
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
              path: '/chat',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('Screen: Chat')),
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

    expect(find.text('Screen: Chat'), findsOneWidget);

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
      initialLocation: '/bar',
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
              path: '/bar',
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
    expect(testRouter.state.matchedLocation, equals('/bar'));

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
