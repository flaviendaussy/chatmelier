// V2.5 · Q3 (revue du 18/10) — le partage d'une cave par lien était cassé de bout en bout :
// la route `/invite/:code` jetait le code, l'écran ne listait que les invitations adressées à
// son e-mail, et rien n'acceptait un code en production (accept_invite_by_code, migration
// 074). Le destinataire voyait un écran vide.

import 'dart:convert';

import 'package:chatmelier/features/cellar/data/invitation_en_attente.dart';
import 'package:chatmelier/features/cellar/presentation/pending_invites_screen.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';
import 'package:chatmelier/shared/providers/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _code = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('l\'invitation gardée le temps de se connecter', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('gardée, relue, effacée', () async {
      await InvitationEnAttente.garder(prefs, _code);
      expect(InvitationEnAttente.lire(prefs), _code);
      await InvitationEnAttente.effacer(prefs);
      expect(InvitationEnAttente.lire(prefs), isNull);
    });

    test('un jour au plus', () async {
      final hier = DateTime(2026, 10, 18, 9);
      await InvitationEnAttente.garder(prefs, _code, maintenant: hier);
      expect(InvitationEnAttente.lire(prefs, maintenant: hier.add(const Duration(hours: 23))), _code);
      expect(InvitationEnAttente.lire(prefs, maintenant: hier.add(const Duration(hours: 25))), isNull);
    });

    test('rien d\'autre qu\'un code ne passe', () async {
      await InvitationEnAttente.garder(prefs, '../profile?x=<script>');
      expect(InvitationEnAttente.lire(prefs), isNull);
      expect(InvitationEnAttente.codeValide('abc'), isFalse);
      expect(InvitationEnAttente.codeValide(_code), isTrue);
    });
  });

  group('l\'écran d\'un lien d\'invitation', () {
    late SharedPreferences prefs;
    final appels = <http.Request>[];

    Future<SupabaseClient> client({required bool connecte, Map<String, dynamic>? reponse}) async {
      appels.clear();
      final client = SupabaseClient('https://test.supabase.co', 'cle-publique-de-test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((req) async {
            appels.add(req);
            final corps = req.url.path.endsWith('/rpc/accept_invite_by_code') ? jsonEncode(reponse ?? {}) : '[]';
            return http.Response(corps, 200, request: req, headers: {'content-type': 'application/json; charset=utf-8'});
          }));
      if (connecte) {
        await client.auth.setInitialSession(jsonEncode({
          'access_token': 'jeton-de-test',
          'token_type': 'bearer',
          'user': {
            'id': '11111111-1111-4111-8111-111111111111',
            'aud': 'authenticated',
            'email': 'caro@exemple.fr',
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'created_at': '2026-09-01T00:00:00Z',
          },
        }));
      }
      return client;
    }

    Future<void> monter(WidgetTester tester, SupabaseClient client, String code) async {
      await tester.binding.setSurfaceSize(const Size(480, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final routeur = GoRouter(initialLocation: '/invite/$code', routes: [
        GoRoute(path: '/invite/:code', builder: (_, etat) => PendingInvitesScreen(code: etat.pathParameters['code'])),
        GoRoute(path: '/login', builder: (_, etat) => Scaffold(body: Text('Connexion ${etat.uri.queryParameters['suite']}'))),
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Accueil'))),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseProvider.overrideWithValue(client),
          sharedPreferencesInstanceProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: routeur),
      ));
      await tester.pumpAndSettle();
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('sans compte : se connecter d\'abord, l\'invitation attend', (tester) async {
      await monter(tester, await client(connecte: false), _code);
      expect(find.byKey(const Key('invitation_par_lien')), findsOneWidget);

      await tester.tap(find.byKey(const Key('se_connecter_pour_rejoindre')));
      await tester.pumpAndSettle();
      expect(find.text('Connexion /invite/$_code'), findsOneWidget);
      expect(InvitationEnAttente.lire(prefs), _code);
    });

    testWidgets('connectée : la cave se rejoint en un geste, par son code', (tester) async {
      await InvitationEnAttente.garder(prefs, _code);
      await monter(tester, await client(connecte: true, reponse: {'success': true, 'cellar_id': 'c1', 'role': 'viewer'}), _code);

      await tester.tap(find.byKey(const Key('rejoindre_la_cave')));
      await tester.pumpAndSettle();
      final rpc = appels.where((r) => r.url.path.endsWith('/rpc/accept_invite_by_code')).toList();
      expect(rpc, hasLength(1));
      expect(jsonDecode(rpc.single.body), {'p_code': _code});
      expect(find.text('Accueil'), findsOneWidget);
      expect(InvitationEnAttente.lire(prefs), isNull);
    });

    testWidgets('un lien qui a déjà servi le dit, et s\'efface', (tester) async {
      await monter(tester, await client(connecte: true, reponse: {'error': 'Invalid or expired invite code'}), _code);

      await tester.tap(find.byKey(const Key('rejoindre_la_cave')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ce lien a déjà servi'), findsOneWidget);
      expect(find.byKey(const Key('invitation_par_lien')), findsNothing);
      expect(find.text('Accueil'), findsNothing);
    });

    testWidgets('une adresse qui n\'a pas la forme d\'un code ne propose rien', (tester) async {
      await monter(tester, await client(connecte: true), 'x');
      expect(find.byKey(const Key('invitation_par_lien')), findsNothing);
      expect(appels.where((r) => r.url.path.contains('/rpc/')), isEmpty);
    });
  });
}
