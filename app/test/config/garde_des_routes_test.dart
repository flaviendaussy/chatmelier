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
}
