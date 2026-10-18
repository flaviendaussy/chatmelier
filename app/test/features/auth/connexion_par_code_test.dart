// V2.5 · Q11 — Camille, 18/10 : « Je reçois bien le lien, quand je clique ça me demande si
// j'ai l'âge, et après ça me remet sur la page initiale où tu rentres l'adresse e-mail. »
//
// Le lien s'ouvrait dans un autre navigateur que celui qui l'avait demandé : sur le web,
// Supabase n'y connecte personne, et l'app revenait à l'adresse sans un mot. Désormais
// l'adresse d'ouverture est lue, l'écran le dit, et le code du même e-mail connecte là où
// on le tape.

import 'package:chatmelier/features/auth/data/auth_repository.dart';
import 'package:chatmelier/features/auth/domain/retour_du_lien.dart';
import 'package:chatmelier/features/auth/presentation/login_screen.dart';
import 'package:chatmelier/shared/providers/auth_provider.dart';
import 'package:chatmelier/shared/providers/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FauxDepot extends AuthRepository {
  _FauxDepot(super.client, {this.refus});

  final AuthException? refus;
  final envois = <String>[];
  final codes = <(String, String)>[];

  @override
  Future<void> sendMagicLink(String email) async => envois.add(email);

  @override
  Future<void> verifyEmailOtp(String email, String token) async {
    codes.add((email, token));
    if (refus != null) throw refus!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Le retour d\'un lien, lu dans l\'adresse d\'ouverture', () {
    test('un code de connexion dans la requête : un retour, sans motif', () {
      final retour = RetourDuLien.lire(Uri.parse('https://chatmelier.github.io/login/?code=4f1c2e'));
      expect(retour, isNotNull);
      expect(retour!.motif, isNull);
      expect(retour.expire, isFalse);
    });

    test('un lien expiré : Supabase le dit dans le fragment', () {
      final retour = RetourDuLien.lire(Uri.parse(
          'https://chatmelier.github.io/login/#error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired'));
      expect(retour?.motif, 'otp_expired');
      expect(retour!.expire, isTrue);
    });

    test('une erreur sans code précis compte aussi comme un lien à redemander', () {
      final retour = RetourDuLien.lire(Uri.parse('https://chatmelier.github.io/login/?error=access_denied&error_description=x'));
      expect(retour?.motif, 'access_denied');
      expect(retour!.expire, isTrue);
    });

    test('le lien de l\'app installée se lit de la même façon', () {
      expect(RetourDuLien.lire(Uri.parse('chatmelier://login-callback?code=4f1c2e')), isNotNull);
    });

    test('une adresse ordinaire n\'est pas un retour de connexion', () {
      for (final adresse in [
        'https://chatmelier.github.io/login',
        'https://chatmelier.github.io/',
        'https://chatmelier.github.io/login?suite=%2Ftable%2FKYZ3YZ',
        'https://chatmelier.github.io/table/?t=KYZ3YZ',
        'https://chatmelier.github.io/#/cellar',
      ]) {
        expect(RetourDuLien.lire(Uri.parse(adresse)), isNull, reason: adresse);
      }
    });
  });

  group('L\'écran de connexion propose le code du même e-mail', () {
    late SupabaseClient client;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      client = SupabaseClient('https://test.supabase.co', 'cle-publique-de-test',
          authOptions: const AuthClientOptions(autoRefreshToken: false));
      lienSansEffet.value = null;
      adresseDuDernierLien.value = null;
    });

    tearDown(() {
      lienSansEffet.value = null;
      adresseDuDernierLien.value = null;
    });

    Future<void> monter(WidgetTester tester, _FauxDepot depot) async {
      await tester.binding.setSurfaceSize(const Size(480, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final routeur = GoRouter(initialLocation: '/login', routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Accueil'))),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseProvider.overrideWithValue(client),
          authRepositoryProvider.overrideWithValue(depot),
        ],
        child: MaterialApp.router(routerConfig: routeur),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> taperLeCode(WidgetTester tester, String code) async {
      await tester.ensureVisible(find.byKey(const Key('saisie_du_code')));
      await tester.enterText(find.byKey(const Key('saisie_du_code')), code);
      await tester.tap(find.byKey(const Key('valider_le_code')));
      await tester.pumpAndSettle();
    }

    testWidgets('après l\'envoi du lien, le code se tape et connecte', (tester) async {
      final depot = _FauxDepot(client);
      await monter(tester, depot);
      expect(find.byKey(const Key('saisie_du_code')), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'camille@hotmail.fr');
      await tester.tap(find.text('Recevoir mon lien de connexion'));
      await tester.pumpAndSettle();
      expect(depot.envois, ['camille@hotmail.fr']);

      await taperLeCode(tester, '482913');
      expect(depot.codes, [('camille@hotmail.fr', '482913')]);
      expect(find.text('Accueil'), findsOneWidget);
    });

    testWidgets('un code refusé le dit, et l\'écran reste là', (tester) async {
      final depot = _FauxDepot(client, refus: const AuthException('Token has expired or is invalid', code: 'otp_expired'));
      adresseDuDernierLien.value = 'camille@hotmail.fr';
      await monter(tester, depot);

      await taperLeCode(tester, '482913');
      expect(depot.codes, hasLength(1));
      expect(find.textContaining('Ce code ne marche pas'), findsOneWidget);
      expect(find.text('Accueil'), findsNothing);
    });

    testWidgets('un code mal recopié ne part pas', (tester) async {
      final depot = _FauxDepot(client);
      adresseDuDernierLien.value = 'camille@hotmail.fr';
      await monter(tester, depot);

      await taperLeCode(tester, '48291');
      expect(depot.codes, isEmpty);
      expect(find.textContaining('ne contient que des chiffres'), findsOneWidget);
    });

    testWidgets('un lien parti de l\'inscription : l\'écran reprend son adresse et propose le code', (tester) async {
      adresseDuDernierLien.value = 'camille@hotmail.fr';
      await monter(tester, _FauxDepot(client));

      expect(find.text('camille@hotmail.fr'), findsWidgets);
      expect(find.byKey(const Key('saisie_du_code')), findsOneWidget);
    });

    testWidgets('arrivée par un lien ouvert ailleurs : l\'avis, et le code sans redemander de lien', (tester) async {
      lienSansEffet.value = RetourDuLien.lire(Uri.parse('https://chatmelier.github.io/login/?code=4f1c2e'));
      final depot = _FauxDepot(client);
      await monter(tester, depot);

      expect(find.byKey(const Key('avis_lien_sans_effet')), findsOneWidget);
      expect(find.textContaining('autre navigateur'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'camille@hotmail.fr');
      await taperLeCode(tester, '482913');
      expect(depot.envois, isEmpty);
      expect(depot.codes, [('camille@hotmail.fr', '482913')]);
      expect(find.text('Accueil'), findsOneWidget);
    });

    testWidgets('un lien expiré : l\'avis dit d\'en demander un autre, sans proposer son code', (tester) async {
      lienSansEffet.value = RetourDuLien.lire(Uri.parse('https://chatmelier.github.io/login/#error=access_denied&error_code=otp_expired'));
      await monter(tester, _FauxDepot(client));

      expect(find.textContaining('a expiré'), findsOneWidget);
      expect(find.byKey(const Key('saisie_du_code')), findsNothing);
    });

    testWidgets('un nouveau lien demandé ici retire l\'avis sur l\'ancien', (tester) async {
      lienSansEffet.value = RetourDuLien.lire(Uri.parse('https://chatmelier.github.io/login/?code=4f1c2e'));
      await monter(tester, _FauxDepot(client));

      await tester.enterText(find.byType(TextField).first, 'camille@hotmail.fr');
      await tester.tap(find.text('Recevoir mon lien de connexion'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('avis_lien_sans_effet')), findsNothing);
      expect(find.byKey(const Key('saisie_du_code')), findsOneWidget);
    });
  });
}
