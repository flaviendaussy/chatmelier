import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/app_logger.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  StreamSubscription? _authSub;

  bool _isLoading = false;
  bool _magicLinkSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _authSub = ref.read(supabaseProvider).auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _formatErrorMessage(dynamic e) {
    final str = e.toString().toLowerCase();
    if (str.contains('invalid login credentials') || str.contains('invalid_credentials')) {
      return 'Email ou mot de passe incorrect. Si vous n\'avez pas encore de compte, cliquez sur "Créer un compte".';
    }
    if (str.contains('email_address_invalid')) {
      return 'Format d\'adresse email invalide. Veuillez vérifier votre saisie.';
    }
    if (str.contains('user already registered') || str.contains('user_already_exists')) {
      return 'Cette adresse email est déjà enregistrée. Veuillez vous connecter.';
    }
    if (str.contains('email not confirmed')) {
      return 'Adresse email non confirmée. Veuillez vérifier votre boîte de réception.';
    }
    if (str.contains('password should be at least 6')) {
      return 'Le mot de passe doit comporter au moins 6 caractères.';
    }
    if (str.contains('rate limit') || str.contains('over_email_send_rate_limit')) {
      return 'Trop de tentatives en peu de temps. Veuillez patienter 60 secondes avant de réessayer.';
    }
    return 'Erreur d\'authentification : $e';
  }

  Future<void> _sendMagicLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner une adresse email valide')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendMagicLink(email);
      setState(() {
        _magicLinkSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✉️ Lien de connexion envoyé à $email ! Cliquez sur le lien reçu (vérifiez vos spams) pour entrer directement.'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_formatErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _passwordLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir votre email et votre mot de passe')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signIn(email, pass);
      if (mounted) context.go('/');
    } catch (e) {
      final errText = e.toString().toLowerCase();
      if (mounted) {
        if (errText.contains('invalid login credentials') || errText.contains('invalid_credentials')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Identifiants incorrects. Pas encore de compte ?'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Créer mon compte',
                textColor: Colors.white,
                onPressed: () => context.push('/register'),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_formatErrorMessage(e)),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
    } catch (e, stack) {
      AppLogger.error('AUTH', 'Google login failed', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de connexion Google : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & App Name
                  Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/images/logo_transparent.png',
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chatmelier',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.loginTagline ?? 'Votre cave à vin intelligente et partagée',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Auth Method Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(text: l10n?.loginTabMagicLink ?? '✉️ Lien de connexion'),
                        Tab(text: l10n?.loginTabPassword ?? '🔑 Mot de passe'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab Views
                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Passwordless Connection Link
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _emailCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n?.loginEmailLabel ?? 'Adresse email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              if (_magicLinkSent) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.mark_email_read_outlined, color: Color(0xFF10B981), size: 24),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Lien de connexion envoyé !',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF065F46)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Un email sécurisé a été envoyé à :\n${_emailCtrl.text.trim()}\n\nOuvrez simplement cet email et cliquez sur le lien pour vous connecter automatiquement à votre cave (vérifiez votre dossier spams si nécessaire).',
                                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _isLoading ? null : _sendMagicLink,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B1E3F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: Text(
                                    _isLoading ? 'Renvoi en cours...' : 'Renvoyer le lien de connexion',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      _magicLinkSent = false;
                                    }),
                                    child: const Text('Changer d\'adresse email', style: TextStyle(fontSize: 13)),
                                  ),
                                ),
                              ] else ...[
                                FilledButton.icon(
                                  onPressed: _isLoading ? null : _sendMagicLink,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B1E3F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                  label: Text(
                                    _isLoading ? 'Envoi en cours...' : (l10n?.loginSendMagicLink ?? 'Recevoir mon lien de connexion'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Connexion sans mot de passe : vous recevrez un email contenant un lien direct et sécurisé pour accéder à votre cave.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Tab 2: Standard Email + Password
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _emailCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n?.loginEmailLabel ?? 'Adresse email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n?.loginPasswordLabel ?? 'Mot de passe',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _isLoading ? null : _passwordLogin,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B1E3F),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  _isLoading ? 'Connexion...' : (l10n?.loginSignInButton ?? 'Se connecter'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
                                  onPressed: () => context.push('/register'),
                                  child: const Text('Pas encore inscrit ? Créer un compte en 1 clic', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n?.loginOrDivider ?? 'OU',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Sign-In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _googleLogin,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(l10n?.loginGoogleButton ?? 'Continuer avec Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(l10n?.loginRegisterLink ?? 'Créer un nouveau compte'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
