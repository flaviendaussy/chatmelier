import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/widgets/international_phone_input.dart';
import '../domain/user_profile.dart';

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

      // If missing across all tiers, prompt the user
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false, // Mandatory prompt
        builder: (ctx) => const MandatoryUsernameDialog(),
      );
    } catch (e) {
      AppLogger.warning('AUTH', 'Error checking username prompt requirement: $e');
    }
  }

  @override
  ConsumerState<MandatoryUsernameDialog> createState() => _MandatoryUsernameDialogState();
}

class _MandatoryUsernameDialogState extends ConsumerState<MandatoryUsernameDialog> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _formattedPhoneNumber = '';
  final _formKey = GlobalKey<FormState>();

  bool _isChecking = false;
  bool _isSaving = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final initialName = user?.userMetadata?['display_name'] as String? ?? 'Amateur de Vin';
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

    final phone = _formattedPhoneNumber.trim();
    final phoneErr = UserProfile.validatePhoneNumber(phone.isNotEmpty ? phone : null);
    if (phoneErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneErr), backgroundColor: Colors.red),
      );
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
        _usernameError = 'Ce pseudo est déjà pris par un autre utilisateur.';
      });
      return;
    }

    // 2. Check Phone number availability across all users if provided
    if (phone.isNotEmpty) {
      final phoneAvailable = await repo.isPhoneAvailable(phone, excludeUserId: user?.id);
      if (!phoneAvailable) {
        setState(() => _isChecking = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ce numéro de téléphone est déjà associé à un autre compte.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
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
        phoneNumber: phone.isNotEmpty ? phone : null,
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
            content: Text('Bienvenue @$rawUser ! Votre profil est prêt.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('AUTH', 'Error saving username', e);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _usernameError = 'Erreur lors de l\'enregistrement : $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return PopScope(
      canPop: false, // Prevent back button dismissal without completing profile
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
                                        'Créez votre Pseudo',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pour partager vos dégustations et caves avec vos amis',
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
                                labelText: 'Pseudo unique *',
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
                                labelText: 'Nom d\'affichage',
                                hintText: 'Flavien D.',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Phone Number Field
                            InternationalPhoneInput(
                              labelText: 'Numéro de téléphone (optionnel)',
                              helperText: 'Pour retrouver vos contacts plus facilement',
                              onChanged: (val) {
                                _formattedPhoneNumber = val;
                              },
                            ),
                            const SizedBox(height: 20),

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
                                _isChecking ? 'Vérification...' : (_isSaving ? 'Enregistrement...' : 'Valider mon Pseudo ✨'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              onPressed: (_isChecking || _isSaving) ? null : _submit,
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
