import 'package:chatmelier/config/garde_des_routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le compte obligatoire dans l'app, le web libre (V2.4 · R2). Le 07/10, des testeurs
/// utilisaient l'app installée sans compte, par les parcours invités de l'accueil.
void main() {
  String? aller(String chemin, {required bool web, bool connecte = false, String? emplacement, String? suite}) =>
      GardeDesRoutes.redirection(web: web, connecte: connecte, chemin: chemin, emplacement: emplacement ?? chemin, suite: suite);

  group('l\'app installée', () {
    test('sans compte, tout mène au compte, y compris les parcours invités', () {
      expect(aller('/', web: false), '/login');
      expect(aller('/cellar', web: false), '/login');
      expect(aller('/scan/menu', web: false), startsWith('/login?suite='));
      expect(aller('/table-consensus', web: false, emplacement: '/table-consensus?code=KYZ3YZ'),
          '/login?suite=%2Ftable-consensus%3Fcode%3DKYZ3YZ',
          reason: 'le lien d\'une table ouvert dans l\'app y ramène après l\'inscription');
    });

    test('l\'accueil et l\'inscription restent accessibles', () {
      expect(aller('/login', web: false), isNull);
      expect(aller('/register', web: false), isNull);
    });

    test('une fois connecté, on rejoint la suite, ou l\'accueil', () {
      expect(aller('/login', web: false, connecte: true, suite: '/table-consensus?code=KYZ3YZ'), '/table-consensus?code=KYZ3YZ');
      expect(aller('/login', web: false, connecte: true), '/');
      expect(aller('/cellar', web: false, connecte: true), isNull);
    });

    test('une suite ne mène jamais hors de l\'app', () {
      expect(aller('/login', web: false, connecte: true, suite: 'https://exemple.com'), '/');
      expect(aller('/login', web: false, connecte: true, suite: '//exemple.com'), '/');
    });
  });

  group('la page web', () {
    test('les parcours invités restent ouverts sans compte : c\'est par eux qu\'arrivent les nouveaux', () {
      expect(aller('/scan/menu', web: true), isNull);
      expect(aller('/table-consensus', web: true), isNull);
      expect(aller('/menu-match', web: true), isNull);
      expect(aller('/invite/ABC', web: true), isNull);
    });

    test('le reste demande un compte, comme avant', () {
      expect(aller('/cellar', web: true), '/login');
      expect(aller('/', web: true), '/login');
    });
  });

  test('le lien d\'une table ouvert dans l\'app sans compte y revient après l\'inscription (#25)', () {
    expect(
      GardeDesRoutes.redirection(web: false, connecte: false, chemin: '/table', emplacement: '/table?t=KYZ3YZ'),
      '/login?suite=${Uri.encodeComponent('/table?t=KYZ3YZ')}',
    );
    expect(GardeDesRoutes.redirection(web: false, connecte: true, chemin: '/table', emplacement: '/table?t=KYZ3YZ'), isNull);
  });

  group('une invitation par lien ouverte avant de se connecter (V2.5 · Q3)', () {
    String? apres(String chemin, {bool connecte = true, String? suite}) => GardeDesRoutes.redirection(
        web: true, connecte: connecte, chemin: chemin, emplacement: chemin, suite: suite, invitationEnAttente: 'a1b2c3d4e5f6');

    test('une fois connecté, on y revient, même quand la suite s\'est perdue dans un autre onglet', () {
      expect(apres('/'), '/invite/a1b2c3d4e5f6');
      expect(apres('/login'), '/invite/a1b2c3d4e5f6');
      expect(apres('/login', suite: '/cellar'), '/invite/a1b2c3d4e5f6');
    });

    test('sur l\'écran de l\'invitation, on reste', () {
      expect(apres('/invite/a1b2c3d4e5f6'), isNull);
    });

    test('sans compte, rien ne change', () {
      expect(apres('/', connecte: false), '/login');
      expect(apres('/invite/a1b2c3d4e5f6', connecte: false), isNull);
    });
  });
}
