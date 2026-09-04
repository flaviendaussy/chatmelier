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
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n?.loginEmailLabel ?? 'Adresse Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n?.loginPasswordLabel ?? 'Mot de passe (min 6 caractères)',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _register,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isLoading ? 'Création en cours...' : (l10n?.registerSubmitButton ?? 'Créer mon compte'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ),
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
