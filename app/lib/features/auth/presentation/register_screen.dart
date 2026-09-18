import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/auth_provider.dart';

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
        const SnackBar(content: Text('Veuillez renseigner une adresse email valide')),
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
          content: Text('Envoi impossible : $e'),
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
        SnackBar(content: Text(l10n?.registerFillAllFields ?? 'Veuillez remplir tous les champs')),
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
              const SnackBar(
                content: Text('👋 Compte existant reconnu ! Connexion réussie.'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 4),
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
        title: const Text('Compte déjà existant', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'L\'adresse email $email possède déjà un compte Chatmelier.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pour accéder à votre cave immédiatement, choisissez une option :',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
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
            label: const Text('Recevoir un lien magique (Sans mot de passe)', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                final repo = ref.read(authRepositoryProvider);
                await repo.sendMagicLink(email);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('✉️ Lien de connexion envoyé à $email ! Cliquez sur le lien reçu par email (vérifiez vos spams) pour vous connecter.'),
                      backgroundColor: const Color(0xFF10B981),
                      duration: const Duration(seconds: 8),
                    ),
                  );
                  router.go('/login');
                }
              } catch (err) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Erreur : $err'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Se connecter avec mot de passe'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.go('/login');
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Modifier l\'email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.registerTitle ?? 'Créer un compte')),
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
                      'Lien envoyé à ${emailCtrl.text.trim()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ouvrez-le depuis ce téléphone et vous y êtes. Pensez aux spams.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _lienEnvoye = false),
                  child: const Text('Changer d\'adresse'),
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
                    labelText: l10n?.registerNameLabel ?? 'Nom d\'affichage / Prénom',
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
                        l10n?.loginPasswordLabel ?? 'Mot de passe (min 6 caractères)',
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
                      ? 'Un instant…'
                      : (_avecMotDePasse
                          ? (l10n?.registerSubmitButton ?? 'Créer mon compte')
                          : 'Recevoir mon lien de connexion'),
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
                        ? 'Plutôt un lien par e-mail'
                        : 'Je préfère un mot de passe',
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
                label: const Text(
                  'Vous avez déjà un compte ? Se connecter',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
