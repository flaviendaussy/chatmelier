import 'package:flutter_test/flutter_test.dart';

/// Une session anonyme n'est pas un compte.
///
/// Le garde du routeur testait `session != null`. Depuis que rejoindre une table ouvre un
/// compte anonyme, ce test devenait vrai pour un invité de passage — et le laissait
/// enfermé : déposé dans la cave, où la RLS lui refuse la création (migration 039), et
/// privé de /login comme de /register, c'est-à-dire du seul chemin vers l'inscription
/// qu'on venait de construire.
///
/// La règle est reproduite ici telle qu'elle est écrite dans le routeur.
bool aAccesAuxEcransDeCompte({required bool aUneSession, required bool estAnonyme}) =>
    aUneSession && !estAnonyme;

bool redirigeVersLogin({
  required bool aUneSession,
  required bool estAnonyme,
  required bool estRouteInvite,
  required bool estRouteAuth,
}) {
  final connecte = aAccesAuxEcransDeCompte(
      aUneSession: aUneSession, estAnonyme: estAnonyme);
  return !connecte && !estRouteAuth && !estRouteInvite;
}

void main() {
  group('🚪 Ce qu\'une session anonyme ouvre, et ce qu\'elle n\'ouvre pas', () {
    test('un anonyme n\'est pas déposé dans la cave', () {
      expect(
        redirigeVersLogin(
            aUneSession: true,
            estAnonyme: true,
            estRouteInvite: false,
            estRouteAuth: false),
        isTrue,
        reason: 'la cave suppose un compte, et la RLS lui refuse d\'en créer une',
      );
    });

    test('un anonyme peut TOUJOURS atteindre l\'inscription', () {
      // Le vrai piège : `connecté && routeAuth → '/'` l'aurait renvoyé à la cave chaque
      // fois qu'il tentait de s'inscrire.
      expect(
        aAccesAuxEcransDeCompte(aUneSession: true, estAnonyme: true),
        isFalse,
        reason: 'sinon la redirection vers « / » lui ferme /login et /register',
      );
    });

    test('un anonyme garde les parcours invités', () {
      expect(
        redirigeVersLogin(
            aUneSession: true,
            estAnonyme: true,
            estRouteInvite: true,
            estRouteAuth: false),
        isFalse,
        reason: 'rejoindre une table ne doit demander aucun compte',
      );
    });

    test('un compte nommé accède à tout', () {
      expect(
        aAccesAuxEcransDeCompte(aUneSession: true, estAnonyme: false),
        isTrue,
      );
      expect(
        redirigeVersLogin(
            aUneSession: true,
            estAnonyme: false,
            estRouteInvite: false,
            estRouteAuth: false),
        isFalse,
      );
    });

    test('sans session, rien ne change par rapport à avant', () {
      expect(
        redirigeVersLogin(
            aUneSession: false,
            estAnonyme: false,
            estRouteInvite: false,
            estRouteAuth: false),
        isTrue,
      );
      expect(
        redirigeVersLogin(
            aUneSession: false,
            estAnonyme: false,
            estRouteInvite: true,
            estRouteAuth: false),
        isFalse,
      );
    });
  });
}
