import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/langue.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  bool _isLoading = false;

  /// Le formulaire complet est replié par défaut.
  ///
  /// Créer un compte demandait un nom, une adresse et un mot de passe — trois champs et
  /// un secret à inventer, avant d'avoir rien vu de l'app. Le lien par e-mail crée le
  /// compte aussi bien, avec un seul champ et rien à retenir. Le mot de passe reste
  /// possible pour qui le préfère, il cesse simplement d'être le chemin par défaut.
  bool _avecMotDePasse = false;
  bool _lienEnvoye = false;

  /// Crée le compte par lien e-mail. `signInWithOtp` crée l'utilisateur s'il n'existe
  /// pas : inscription et connexion sont le même geste, ce qui retire au passage l'écran
  /// « avez-vous déjà un compte ? » à quoi personne ne sait répondre.
  Future<void> _envoyerLeLien() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Veuillez renseigner une adresse email valide', 'Please enter a valid email address'))),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).sendMagicLink(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lienEnvoye = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Envoi impossible : {e}', 'Couldn\'t send: {e}', {'e': e})),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    final name = nameCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.registerFillAllFields ?? tr('Veuillez remplir tous les champs', 'Please fill in all the fields'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final res = await repo.signUp(email, pass, name);
      if (res.session == null) {
        try {
          await repo.signIn(email, pass);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.registerWelcome ?? '🎉 Bienvenue sur Chatmelier !'),
            backgroundColor: const Color(0xFF8B1E3F),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isAlreadyRegistered = errStr.contains('user already registered') ||
          errStr.contains('user_already_exists') ||
          errStr.contains('already registered') ||
          errStr.contains('existe déjà');

      if (isAlreadyRegistered) {
        // 1. Attempt automatic sign-in if the user typed their existing password
        try {
          final repo = ref.read(authRepositoryProvider);
          await repo.signIn(email, pass);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tr('👋 Compte existant reconnu ! Connexion réussie.', '👋 Existing account recognised! You\'re signed in.')),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 4),
              ),
            );
            context.go('/');
            return;
          }
        } catch (_) {
          // If password doesn't match, propose immediate solutions
        }

        // 2. Show helpful dialog to connect without friction
        if (mounted) {
          _showExistingAccountDialog(context, email);
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n?.registerErrorGeneric ?? "Erreur lors de l'inscription"}: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showExistingAccountDialog(BuildContext context, String email) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.account_circle, color: Color(0xFF8B1E3F), size: 48),
        title: Text(tr('Compte déjà existant', 'Account already exists'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('L\'adresse email {email} possède déjà un compte Chatmelier.', 'The email address {email} already has a Chatmelier account.', {'email': email}),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            Text(
              tr('Pour accéder à votre cave immédiatement, choisissez une option :', 'To get to your cellar right away, choose an option:'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowButtonSpacing: 10,
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.mark_email_read_outlined, size: 20),
            label: Text(tr('Recevoir un lien magique (Sans mot de passe)', 'Get a magic link (no password)'), style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                final repo = ref.read(authRepositoryProvider);
                await repo.sendMagicLink(email);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(tr('✉️ Lien de connexion envoyé à {email} ! Cliquez sur le lien reçu par email (vérifiez vos spams) pour vous connecter.', '✉️ Sign-in link sent to {email}! Tap the link in the email (check your spam folder) to sign in.', {'email': email})),
                      backgroundColor: const Color(0xFF10B981),
                      duration: const Duration(seconds: 8),
                    ),
                  );
                  router.go('/login');
                }
              } catch (err) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(tr('Erreur : {err}', 'Error: {err}', {'err': err})), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.login, size: 18),
            label: Text(tr('Se connecter avec mot de passe', 'Sign in with a password')),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.go('/login');
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(tr('Modifier l\'email', 'Change the email')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.registerTitle ?? tr('Créer un compte', 'Create an account'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            if (_lienEnvoye) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.mark_email_read_outlined,
                        color: Color(0xFF10B981), size: 32),
                    const SizedBox(height: 10),
                    Text(
                      tr('Lien envoyé à {v1}', 'Link sent to {v1}', {'v1': emailCtrl.text.trim()}),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('Ouvrez-le depuis ce téléphone et vous y êtes. Pensez aux spams.', 'Open it on this phone and you\'re in. Check your spam folder.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _lienEnvoye = false),
                  child: Text(tr('Changer d\'adresse', 'Change address')),
                ),
              ),
            ] else ...[
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n?.loginEmailLabel ?? 'Adresse Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _avecMotDePasse ? null : _envoyerLeLien(),
              ),

              // Le chemin par mot de passe, replié : deux champs de plus et un secret à
              // inventer, pour qui y tient.
              if (_avecMotDePasse) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n?.registerNameLabel ?? tr('Nom d\'affichage / Prénom', 'Display name / first name'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        l10n?.loginPasswordLabel ?? tr('Mot de passe (min 6 caractères)', 'Password (at least 6 characters)'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading
                    ? null
                    : (_avecMotDePasse ? _register : _envoyerLeLien),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isLoading
                      ? tr('Un instant…', 'One moment…')
                      : (_avecMotDePasse
                          ? (l10n?.registerSubmitButton ?? tr('Créer mon compte', 'Create my account'))
                          : tr('Recevoir mon lien de connexion', 'Email me a sign-in link')),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () =>
                      setState(() => _avecMotDePasse = !_avecMotDePasse),
                  child: Text(
                    _avecMotDePasse
                        ? tr('Plutôt un lien par e-mail', 'Rather get a link by email')
                        : tr('Je préfère un mot de passe', 'I\'d rather use a password'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(
                  tr('Vous avez déjà un compte ? Se connecter', 'Already have an account? Sign in'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
