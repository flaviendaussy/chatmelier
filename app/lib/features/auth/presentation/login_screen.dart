import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../menu_scan/presentation/join_table_sheet.dart';
import 'reprise_de_soiree_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Google en premier, sauf sur iPhone (V2.3 · iOS) : l'App Store exige « Se connecter avec
/// Apple » à côté de toute connexion par un tiers (règle 4.8). En attendant, l'iPhone se
/// connecte par lien e-mail, sur le même compte : Supabase relie les connexions d'une même
/// adresse vérifiée.
bool get _googleProposee => kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

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
      return tr('Email ou mot de passe incorrect. Si vous n\'avez pas encore de compte, cliquez sur "Créer un compte".', 'Incorrect email or password. If you don\'t have an account yet, tap "Create an account".');
    }
    if (str.contains('email_address_invalid')) {
      return tr('Format d\'adresse email invalide. Veuillez vérifier votre saisie.', 'Invalid email address. Please check what you typed.');
    }
    if (str.contains('user already registered') || str.contains('user_already_exists')) {
      return tr('Cette adresse email est déjà enregistrée. Veuillez vous connecter.', 'This email address is already registered. Please sign in.');
    }
    if (str.contains('email not confirmed')) {
      return tr('Adresse email non confirmée. Veuillez vérifier votre boîte de réception.', 'Email address not confirmed. Please check your inbox.');
    }
    if (str.contains('password should be at least 6')) {
      return tr('Le mot de passe doit comporter au moins 6 caractères.', 'The password must be at least 6 characters long.');
    }
    if (str.contains('rate limit') || str.contains('over_email_send_rate_limit')) {
      return tr('Trop de tentatives en peu de temps. Veuillez patienter 60 secondes avant de réessayer.', 'Too many attempts in a short time. Please wait 60 seconds before trying again.');
    }
    if (str.contains('socketexception') ||
        str.contains('network') ||
        str.contains('connection refused') ||
        str.contains('failed host lookup') ||
        str.contains('timed out') ||
        str.contains('offline')) {
      return tr('Impossible de joindre le serveur. Veuillez vérifier votre connexion Internet et réessayer.', 'Can\'t reach the server. Please check your internet connection and try again.');
    }
    return tr('Une erreur est survenue lors de la connexion. Veuillez réessayer.', 'Something went wrong while signing in. Please try again.');
  }

  Future<void> _sendMagicLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Veuillez renseigner une adresse email valide', 'Please enter a valid email address'))),
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
            content: Text(tr('✉️ Lien de connexion envoyé à {email} ! Cliquez sur le lien reçu (vérifiez vos spams) pour entrer directement.', '✉️ Sign-in link sent to {email}! Tap the link in that email (check your spam folder) to sign straight in.', {'email': email})),
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
        SnackBar(content: Text(tr('Veuillez remplir votre email et votre mot de passe', 'Please enter your email and password'))),
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
              content: Text(tr('Mot de passe incorrect ou compte créé sans mot de passe.', 'Wrong password, or an account created without a password.')),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: tr('Connexion email ✉️', 'Email sign-in ✉️'),
                textColor: Colors.white,
                onPressed: () {
                  _tabController.animateTo(0);
                  _sendMagicLink();
                },
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

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final email = _emailCtrl.text.trim();
    final emailController = TextEditingController(text: email);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.lock_reset, color: Color(0xFF8B1E3F), size: 40),
        title: Text(tr('Mot de passe oublié ?', 'Forgot your password?'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('Renseignez votre email pour recevoir un lien direct de connexion (sans mot de passe) ou un lien de réinitialisation :', 'Enter your email to get a direct sign-in link (no password needed) or a reset link:'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: tr('Adresse email', 'Email address'),
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actionsOverflowButtonSpacing: 8,
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.mark_email_read_outlined, size: 18),
            label: Text(tr('Lien direct par email (Recommandé)', 'Direct link by email (recommended)')),
            onPressed: () async {
              final targetEmail = emailController.text.trim();
              if (targetEmail.isEmpty || !targetEmail.contains('@')) {
                messenger.showSnackBar(
                  SnackBar(content: Text(tr('Veuillez renseigner une adresse email valide.', 'Please enter a valid email address.'))),
                );
                return;
              }
              Navigator.of(dialogCtx).pop();
              _emailCtrl.text = targetEmail;
              _tabController.animateTo(0);
              await _sendMagicLink();
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.send_outlined, size: 18),
            label: Text(tr('Réinitialiser le mot de passe', 'Reset password')),
            onPressed: () async {
              final targetEmail = emailController.text.trim();
              if (targetEmail.isEmpty || !targetEmail.contains('@')) {
                messenger.showSnackBar(
                  SnackBar(content: Text(tr('Veuillez renseigner une adresse email valide.', 'Please enter a valid email address.'))),
                );
                return;
              }
              Navigator.of(dialogCtx).pop();
              try {
                final repo = ref.read(authRepositoryProvider);
                await repo.resetPasswordForEmail(targetEmail);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(tr('✉️ Email de réinitialisation envoyé à {targetEmail} (vérifiez vos courriers indésirables / spams)', '✉️ Reset email sent to {targetEmail} (check your junk / spam folder)', {'targetEmail': targetEmail})),
                      backgroundColor: const Color(0xFF10B981),
                      duration: const Duration(seconds: 7),
                    ),
                  );
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
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(tr('Annuler', 'Cancel')),
          ),
        ],
      ),
    );
    emailController.dispose();
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
          SnackBar(content: Text(tr('Échec de connexion Google : {e}', 'Google sign-in failed: {e}', {'e': e}))),
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
                    l10n?.loginTagline ?? tr('Votre cave à vin intelligente et partagée', 'Your smart, shared wine cellar'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🍽️ Section Invité / Restaurant (Accès immédiat sans compte)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C1530), Color(0xFF190C1C)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text('🍽️', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('Au restaurant ce soir ?', 'Eating out tonight?'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  Text(
                                    tr('Profitez du sommelier & de la table sans compte !', 'Use the sommelier and the table without an account!'),
                                    style: TextStyle(color: const Color(0xFFD4AF37).withValues(alpha: 0.9), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD4AF37),
                                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.groups_rounded, size: 16),
                                label: Text(tr('Rejoindre table', 'Join table'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                onPressed: () => JoinTableSheet.show(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B1E3F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                label: Text(tr('Scanner menu', 'Scan menu'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                onPressed: () => context.push('/scan/menu'),
                              ),
                            ),
                          ],
                        ),
                        // Une soirée commencée sans compte, sur un autre appareil ou avant
                        // d'avoir vidé son cache : le code de reprise la rend (P6).
                        Center(
                          child: TextButton(
                            onPressed: () => RepriseDeSoireeSheet.show(context),
                            child: Text(
                              tr('J\'ai un code de reprise', 'I have a recovery code'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sur iPhone, pas de Google sans « Se connecter avec Apple » à côté : l'App
                  // Store l'exige (règle 4.8). L'iPhone se connecte par lien e-mail.
                  if (_googleProposee) ...[
                    // GOOGLE EN PREMIER, ET NON TOUT EN BAS.
                    //
                    // Il était relégué sous un `TabBarView` de 380 pixels, derrière un
                    // diviseur « OU », en bouton gris avec l'icône générique
                    // `Icons.g_mobiledata`. Il fallait faire défiler pour le trouver, et une
                    // fois trouvé rien ne disait que c'était Google. C'est pourtant la
                    // connexion la plus rapide de toutes : aucun mot de passe à retenir,
                    // aucune boîte mail à ouvrir.
                    //
                    // Fond blanc et « G » aux quatre couleurs : c'est à ça qu'on le
                    // reconnaît d'un coup d'œil, pas à un libellé.
                    Material(
                      color: Colors.white,
                      elevation: 1.5,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isLoading ? null : _googleLogin,
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDADCE0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _LogoGoogle(taille: 20),
                              const SizedBox(width: 12),
                              Text(
                                l10n?.loginGoogleButton ?? tr('Continuer avec Google', 'Continue with Google'),
                                style: const TextStyle(
                                  color: Color(0xFF3C4043),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Le diviseur sépare maintenant Google de ce qui suit, au lieu de
                    // l'enterrer après.
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
                    const SizedBox(height: 18),
                  ],

                  // Auth Method Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      // Sur deux lignes s'il le faut : « Lien de connexion » se coupait en
                      // fondu sur un petit écran (V2.3 · E1), et l'espagnol est plus long.
                      tabs: [
                        for (final libelle in [
                          l10n?.loginTabMagicLink ?? tr('✉️ Lien de connexion', '✉️ Sign-in link'),
                          l10n?.loginTabPassword ?? tr('🔑 Mot de passe', '🔑 Password'),
                        ])
                          Tab(
                            height: 52,
                            child: Text(libelle, textAlign: TextAlign.center, maxLines: 2, softWrap: true),
                          ),
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
                                  labelText: l10n?.loginEmailLabel ?? tr('Adresse email', 'Email address'),
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
                                      Row(
                                        children: [
                                          const Icon(Icons.mark_email_read_outlined, color: Color(0xFF10B981), size: 24),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              tr('Lien de connexion envoyé !', 'Sign-in link sent!'),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF065F46)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        tr('Un email sécurisé a été envoyé à :\n{v1}\n\nOuvrez simplement cet email et cliquez sur le lien pour vous connecter automatiquement à votre cave (vérifiez votre dossier spams si nécessaire).', 'A secure email has been sent to:\n{v1}\n\nJust open it and tap the link to sign in to your cellar automatically (check your spam folder if needed).', {'v1': _emailCtrl.text.trim()}),
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
                                    _isLoading ? tr('Renvoi en cours...', 'Resending...') : tr('Renvoyer le lien de connexion', 'Resend the sign-in link'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      _magicLinkSent = false;
                                    }),
                                    child: Text(tr('Changer d\'adresse email', 'Use another email address'), style: const TextStyle(fontSize: 13)),
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
                                    _isLoading ? tr('Envoi en cours...', 'Sending...') : (l10n?.loginSendMagicLink ?? tr('Recevoir mon lien de connexion', 'Email me a sign-in link')),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  tr('Connexion sans mot de passe : vous recevrez un email contenant un lien direct et sécurisé pour accéder à votre cave.', 'Password-free sign-in: you\'ll get an email with a direct, secure link to your cellar.'),
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
                                  labelText: l10n?.loginEmailLabel ?? tr('Adresse email', 'Email address'),
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n?.loginPasswordLabel ?? tr('Mot de passe', 'Password'),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                ),
                                obscureText: true,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showForgotPasswordDialog(context),
                                  child: Text(tr('Mot de passe oublié ?', 'Forgot your password?'), style: const TextStyle(fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _isLoading ? null : _passwordLogin,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B1E3F),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  _isLoading ? tr('Connexion...', 'Signing in...') : (l10n?.loginSignInButton ?? tr('Se connecter', 'Sign in')),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
                                  onPressed: () => context.push('/register'),
                                  child: Text(tr('Pas encore inscrit ? Créer un compte en 1 clic', 'Not registered yet? Create an account in one tap'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Register link
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(l10n?.loginRegisterLink ?? tr('Créer un nouveau compte', 'Create a new account')),
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

/// Le « G » de Google, dessiné plutôt qu'importé.
///
/// Pas d'asset à ajouter au bundle pour vingt pixels, et surtout : les quatre couleurs
/// sont ce qui rend le bouton reconnaissable avant même qu'on ait lu le mot « Google ».
/// L'icône générique `Icons.g_mobiledata` qui servait jusqu'ici ne dit rien à personne.
class _LogoGoogle extends StatelessWidget {
  final double taille;
  const _LogoGoogle({required this.taille});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: taille,
      height: taille,
      child: CustomPaint(painter: _PeintreG()),
    );
  }
}

class _PeintreG extends CustomPainter {
  // Les quatre couleurs de la marque.
  static const _bleu = Color(0xFF4285F4);
  static const _vert = Color(0xFF34A853);
  static const _jaune = Color(0xFFFBBC05);
  static const _rouge = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centre = Offset(r, r);
    final trait = size.width * 0.22;
    final rayon = r - trait / 2;
    final boite = Rect.fromCircle(center: centre, radius: rayon);

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trait
      ..strokeCap = StrokeCap.butt;

    // Quatre arcs, dans l'ordre horaire du logo.
    canvas.drawArc(boite, -0.30, -1.30, false, p..color = _rouge);
    canvas.drawArc(boite, -1.60, -1.35, false, p..color = _jaune);
    canvas.drawArc(boite, -2.95, -1.35, false, p..color = _vert);
    canvas.drawArc(boite, 1.75, -1.45, false, p..color = _bleu);

    // La barre horizontale du G, qui le distingue d'un simple anneau.
    final barre = Paint()..color = _bleu;
    canvas.drawRect(
      Rect.fromLTWH(centre.dx, centre.dy - trait / 2, rayon + trait / 2, trait),
      barre,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
