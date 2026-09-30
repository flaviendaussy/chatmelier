import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/user_profile.dart';
import '../../../shared/utils/langue.dart';

class MandatoryUsernameDialog extends ConsumerStatefulWidget {
  final VoidCallback? onCompleted;

  const MandatoryUsernameDialog({super.key, this.onCompleted});

  /// Check if the current user needs to define a username, and show dialog if so
  static Future<void> checkAndPromptIfNeeded(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // 1. Instant check: is username already in Auth User Metadata?
    final metadataUser = user.userMetadata?['username'] as String?;
    if (metadataUser != null && metadataUser.trim().isNotEmpty) {
      return; // Already configured!
    }

    // 2. Instant check: is username in local SharedPreferences?
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConfigured = prefs.getBool('user_profile_configured_${user.id}') ?? false;
      final cachedUsername = prefs.getString('user_profile_username_${user.id}');
      if (isConfigured || (cachedUsername != null && cachedUsername.trim().isNotEmpty)) {
        return; // Already configured!
      }
    } catch (_) {}

    // 3. Deep check from auth repository
    try {
      final repo = ref.read(authRepositoryProvider);
      final profile = await repo.getProfile(user.id);

      if (profile != null && profile.username != null && profile.username!.trim().isNotEmpty) {
        // Cache to SharedPreferences so subsequent screen visits take 0ms
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('user_profile_configured_${user.id}', true);
          await prefs.setString('user_profile_username_${user.id}', profile.username!);
        } catch (_) {}
        return; // Profile already has valid username
      }

      // Reporté récemment ? On se tait.
      if (await _reporteRecemment(user.id)) return;

      // If missing across all tiers, prompt the user
      if (!context.mounted) return;
      await showDialog(
        context: context,
        // Différable. Cette boîte s'ouvrait immédiatement après l'inscription, sans
        // échappatoire : premier écran de l'app, on venait de s'inscrire, et on se
        // retrouvait devant un formulaire bloquant. Or le pseudo ne sert qu'à être
        // retrouvé par ses amis — une fonctionnalité dont personne n'a besoin à cet
        // instant précis. Le demander reste utile ; l'exiger fait fermer l'app.
        barrierDismissible: true,
        builder: (ctx) => const MandatoryUsernameDialog(),
      );
    } catch (e) {
      AppLogger.warning('AUTH', 'Error checking username prompt requirement: $e');
    }
  }

  /// Combien de temps on se tait après un « plus tard ».
  ///
  /// Une semaine : assez pour ne pas harceler, assez court pour que la question revienne
  /// avant qu'on ait vraiment besoin du pseudo — c'est-à-dire avant qu'un ami cherche à
  /// nous retrouver.
  static const Duration delaiDeReport = Duration(days: 7);

  static String _cleDeReport(String userId) => 'username_prompt_deferred_$userId';

  static Future<bool> _reporteRecemment(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_cleDeReport(userId));
      if (brut == null) return false;
      final quand = DateTime.tryParse(brut);
      if (quand == null) return false;
      return DateTime.now().difference(quand) < delaiDeReport;
    } catch (_) {
      return false;
    }
  }

  static Future<void> reporter(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _cleDeReport(userId), DateTime.now().toIso8601String());
    } catch (_) {}
  }

  @override
  ConsumerState<MandatoryUsernameDialog> createState() => _MandatoryUsernameDialogState();
}

class _MandatoryUsernameDialogState extends ConsumerState<MandatoryUsernameDialog> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isChecking = false;
  bool _isSaving = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final initialName = user?.userMetadata?['display_name'] as String? ?? tr('Amateur de Vin', 'Wine lover');
    _displayNameController.text = initialName;

    // Suggest handle from display name
    final cleanSuggested = initialName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (cleanSuggested.length >= 3) {
      _usernameController.text = cleanSuggested;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawUser = _usernameController.text.trim().toLowerCase().replaceAll('@', '');
    final valErr = UserProfile.validateUsername(rawUser);
    if (valErr != null) {
      setState(() => _usernameError = valErr);
      return;
    }

    setState(() {
      _isChecking = true;
      _usernameError = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final user = ref.read(currentUserProvider);

    // 1. Check Username availability across all users
    final usernameAvailable = await repo.isUsernameAvailable(rawUser, excludeUserId: user?.id);
    if (!usernameAvailable) {
      setState(() {
        _isChecking = false;
        _usernameError = tr('Ce pseudo est déjà pris par un autre utilisateur.', 'That username is already taken.');
      });
      return;
    }

    setState(() {
      _isChecking = false;
      _isSaving = true;
    });

    try {
      final name = _displayNameController.text.trim().isNotEmpty ? _displayNameController.text.trim() : rawUser;

      await repo.updateProfile(
        displayName: name,
        username: rawUser,
        email: user?.email,
      );

      // Force mark local SharedPreferences flag
      if (user != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('user_profile_configured_${user.id}', true);
          await prefs.setString('user_profile_username_${user.id}', rawUser);
        } catch (_) {}
      }

      AppLogger.info('AUTH', 'Saved mandatory username @$rawUser for ${user?.id}');

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCompleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Bienvenue @{rawUser} ! Votre profil est prêt.', 'Welcome @{rawUser}! Your profile is ready.', {'rawUser': rawUser})),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('AUTH', 'Error saving username', e);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _usernameError = tr('Erreur lors de l\'enregistrement : {e}', 'Couldn\'t save: {e}', {'e': e});
        });
      }
    }
  }

  /// Déconnecte et ferme le dialogue, pour l'utilisateur qui s'est connecté avec le
  /// mauvais compte. Le routeur le ramène alors sur /login, où une nouvelle connexion
  /// Google proposera explicitement le choix du compte (`prompt=select_account`).
  Future<void> _switchAccount() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(tr('Déconnecté. Reconnectez-vous avec le compte de votre choix.', 'Signed out. Sign in with the account you want.')),
        ),
      );
    } catch (e) {
      AppLogger.error('AUTH', 'Error signing out from mandatory username dialog', e);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(tr('Déconnexion impossible : {e}', 'Couldn\'t sign out: {e}', {'e': e})), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return PopScope(
      // Le retour arrière fonctionne : voir `barrierDismissible` plus haut.
      canPop: true,
      child: AnimatedPadding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          bottomInset > 0 ? bottomInset + 12 : 16,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
            child: Material(
              color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
              elevation: 24,
              shadowColor: Colors.black.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('Créez votre Pseudo', 'Choose your username'),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tr('Pour partager vos dégustations et caves avec vos amis', 'To share your tastings and cellars with friends'),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Pseudo Field
                            TextFormField(
                              controller: _usernameController,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: tr('Pseudo unique *', 'Unique username *'),
                                prefixText: '@ ',
                                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                                hintText: 'flavien',
                                errorText: _usernameError,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: UserProfile.validateUsername,
                              onChanged: (val) {
                                if (_usernameError != null) setState(() => _usernameError = null);
                              },
                            ),
                            const SizedBox(height: 12),

                            // Display Name Field
                            TextFormField(
                              controller: _displayNameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: tr('Nom d\'affichage', 'Display name'),
                                hintText: tr('Camille D.', 'Alex D.'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // LE NUMÉRO DE TÉLÉPHONE N'EST PLUS ICI.
                            //
                            // Il ne sert qu'à retrouver ses contacts — une fonctionnalité
                            // qui n'intéresse personne à la seconde où l'on découvre
                            // l'app. Le demander à l'inscription, c'est réclamer une
                            // donnée personnelle avant d'avoir rendu le moindre service.
                            // Il se renseigne depuis Profil → Compte, là où il sert.


                            // Submit Button
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1E3F),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: (_isChecking || _isSaving)
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check, size: 20),
                              label: Text(
                                _isChecking ? tr('Vérification...', 'Checking...') : (_isSaving ? tr('Enregistrement...', 'Saving...') : tr('Valider mon Pseudo ✨', 'Confirm my username ✨')),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              onPressed: (_isChecking || _isSaving) ? null : _submit,
                            ),
                            const SizedBox(height: 4),

                            // La sortie. Sans elle, « différable » n'est qu'une intention :
                            // fermer par le bouton retour ne dit pas à l'app de se taire,
                            // et la boîte reviendrait au prochain passage dans la cave.
                            TextButton(
                              onPressed: (_isChecking || _isSaving)
                                  ? null
                                  : () async {
                                      final user = ref.read(currentUserProvider);
                                      if (user != null) {
                                        await MandatoryUsernameDialog.reporter(user.id);
                                      }
                                      if (context.mounted) Navigator.of(context).pop();
                                    },
                              child: Text(
                                tr('Plus tard', 'Later'),
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Se déconnecter, pour qui s'est trompé de compte. Distinct de
                            // « Plus tard » : l'un reporte la question, l'autre change de
                            // personne. La seule déconnexion de l'app vit dans l'écran
                            // profil, qu'on ne peut pas atteindre d'ici.
                            TextButton.icon(
                              onPressed: (_isChecking || _isSaving) ? null : _switchAccount,
                              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                              label: Text(tr('Ce n\'est pas mon compte — en changer', 'Not my account — switch')),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : Colors.black54,
                                minimumSize: const Size.fromHeight(44),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
