import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../cellar/presentation/cellar_export_dialog.dart';
import 'taste_profiles_dialog.dart';
import 'taste_profile_edit_sheet.dart';
import '../data/taste_profile_service.dart';
import '../domain/taste_profile.dart';
import 'mandatory_username_dialog.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/phone_dial_code.dart';
import '../../../shared/widgets/international_phone_input.dart';
import '../domain/user_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _defaultCurrency = 'EUR';
  String _displayName = '';
  String? _username;
  String? _phoneNumber;
  TasteProfile? _userTasteProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final repo = ref.read(authRepositoryProvider);
        final profile = await repo.getProfile(user.id).timeout(const Duration(seconds: 2));
        if (mounted && profile != null) {
          setState(() {
            _displayName = profile.displayName;
            _username = profile.username;
            _phoneNumber = profile.phoneNumber;
            _defaultCurrency = profile.defaultCurrency;
          });
        }
      }
    } catch (e) {
      AppLogger.warning('PROFILE', 'Could not load user profile', e);
    }

    try {
      final tasteService = ref.read(tasteProfileServiceProvider);
      final tp = await tasteService.getPrimaryProfile();
      if (mounted) {
        setState(() {
          _userTasteProfile = tp;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _openTasteProfileEditor() async {
    final tasteService = ref.read(tasteProfileServiceProvider);
    final current = _userTasteProfile ?? await tasteService.getPrimaryProfile();
    if (mounted) {
      await TasteProfileEditSheet.show(
        context,
        profile: current,
        onSaved: (updated) {
          setState(() {
            _userTasteProfile = updated;
          });
        },
      );
    }
  }

  String _tasteProfileSummary() {
    final p = _userTasteProfile;
    if (p == null || (p.favoriteTypes.isEmpty && p.favoriteRegions.isEmpty && p.favoriteGrapes.isEmpty && p.dislikedCharacteristics.isEmpty)) {
      return 'Aucune préférence définie pour l\'instant. Cliquez pour personnaliser vos styles, régions, cépages favoris et aversions !';
    }

    final parts = <String>[];
    if (p.favoriteTypes.isNotEmpty) {
      parts.add('Styles : ${p.favoriteTypes.take(2).join(", ")}');
    }
    if (p.favoriteRegions.isNotEmpty) {
      parts.add('Terroirs : ${p.favoriteRegions.take(2).join(", ")}');
    }
    if (p.favoriteGrapes.isNotEmpty) {
      parts.add('Cépages : ${p.favoriteGrapes.take(2).join(", ")}');
    }
    if (p.dislikedCharacteristics.isNotEmpty) {
      parts.add('Aversions : ${p.dislikedCharacteristics.take(1).join(", ")}');
    }
    return parts.join(' • ');
  }

  Future<void> _changeCurrency(String newCurrency) async {
    setState(() => _defaultCurrency = newCurrency);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateProfile(
        displayName: _displayName.isNotEmpty ? _displayName : (user.userMetadata?['display_name'] ?? 'User'),
        defaultCurrency: newCurrency,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final msg = l10n != null ? l10n.profileCurrencyUpdated(newCurrency) : 'Devise mise à jour: $newCurrency';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  Future<void> _editDisplayName() async {
    final ctrl = TextEditingController(text: _displayName);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person, color: Color(0xFF8B1E3F)),
            SizedBox(width: 8),
            Text('Nom d\'affichage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Votre nom ou prénom',
            hintText: 'ex: Flavien',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final repo = ref.read(authRepositoryProvider);
        await repo.updateProfile(
          displayName: result,
          username: _username,
          phoneNumber: _phoneNumber,
          email: user.email,
        );
        setState(() => _displayName = result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nom d\'affichage mis à jour'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    }
  }

  Future<void> _editPhoneNumber() async {
    String tempPhone = _phoneNumber ?? '';
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone_iphone, color: Color(0xFF8B1E3F)),
            SizedBox(width: 8),
            Text('Numéro de téléphone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InternationalPhoneInput(
              initialValue: _phoneNumber,
              labelText: 'Votre numéro (indicatif obligatoire)',
              helperText: 'FR (+33) par défaut, UK (+44) ou indicatif détecté par GPS',
              onChanged: (val) => tempPhone = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final valErr = UserProfile.validatePhoneNumber(tempPhone.isNotEmpty ? tempPhone : null);
              if (valErr != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(valErr), backgroundColor: Colors.red));
                return;
              }
              Navigator.of(ctx).pop(tempPhone);
            },
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final repo = ref.read(authRepositoryProvider);
        if (result.isNotEmpty) {
          final isPhoneAvailable = await repo.isPhoneAvailable(result, excludeUserId: user.id);
          if (!isPhoneAvailable) {
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

        await repo.updateProfile(
          displayName: _displayName,
          username: _username,
          phoneNumber: result.isNotEmpty ? result : null,
          email: user.email,
        );
        setState(() => _phoneNumber = result.isNotEmpty ? result : null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Numéro de téléphone mis à jour avec succès'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userLocale = ref.watch(localeProvider);

    final currentLangValue = userLocale == null ? 'system' : userLocale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.profileTitle ?? 'Profil & Réglages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (user == null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_circle_outlined, color: Colors.amber, size: 24),
                            SizedBox(width: 10),
                            Text('Session Invité / Non Connecté', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Connectez-vous pour synchroniser votre cave entre vos téléphones et tablettes et accéder à toutes vos fonctionnalités.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: const Text('Se connecter / Créer un compte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1E3F),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Center(child: OwnerAvatar(userId: user?.id ?? '', radius: 50)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.alternate_email, color: Color(0xFF8B1E3F)),
                  title: const Text('Pseudo unique Chatmelier', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _username != null && _username!.isNotEmpty ? '@$_username' : 'Non défini (cliquer pour choisir)',
                    style: TextStyle(
                      color: _username != null && _username!.isNotEmpty ? const Color(0xFF8B1E3F) : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => MandatoryUsernameDialog(
                        onCompleted: () => _loadProfile(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l10n?.profileEmail ?? 'Email'),
                  subtitle: Text(user?.email ?? 'Non renseigné (Mode Invité)'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n?.profileDisplayName ?? 'Nom d\'affichage'),
                  subtitle: Text(_displayName.isNotEmpty ? _displayName : (user?.userMetadata?['display_name'] ?? 'Utilisateur')),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: _editDisplayName,
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: Color(0xFF8B1E3F)),
                  title: const Text('Numéro de téléphone', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _phoneNumber != null && _phoneNumber!.isNotEmpty
                        ? '${PhoneDialCodeHelper.parseExisting(_phoneNumber).$1.flag} $_phoneNumber'
                        : 'Non renseigné (cliquer pour ajouter)',
                    style: TextStyle(
                      color: _phoneNumber != null && _phoneNumber!.isNotEmpty ? null : Colors.grey,
                      fontWeight: _phoneNumber != null && _phoneNumber!.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: _editPhoneNumber,
                ),
                const Divider(),
                // TASTE PROFILE CARD
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                  ),
                  color: isDark ? const Color(0xFF231C28) : const Color(0xFFFAF5EF),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _openTasteProfileEditor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.wine_bar_rounded, color: Color(0xFF8B1E3F), size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mon Profil de Goûts',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune, size: 14, color: Color(0xFF8B1E3F)),
                                    SizedBox(width: 4),
                                    Text('Personnaliser', style: TextStyle(color: Color(0xFF8B1E3F), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _tasteProfileSummary(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.language),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n?.profileLanguage ?? 'Langue de l\'application',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentLangValue,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'system',
                                child: Text('Automatique (Système) 🌐', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: 'fr',
                                child: Text('Français 🇫🇷', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English 🇬🇧', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                if (val == 'system') {
                                  ref.read(localeProvider.notifier).setLocale(null);
                                } else {
                                  ref.read(localeProvider.notifier).setLocale(Locale(val));
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Langue modifiée avec succès'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.paid_outlined),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n?.profileDefaultCurrency ?? 'Devise par défaut',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _defaultCurrency,
                            isDense: true,
                            items: CurrencyHelper.supportedCurrencies.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.code,
                                child: Text('${c.code} (${c.symbol})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) _changeCurrency(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Theme Mode Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.dark_mode_outlined),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Ambiance / Thème',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ThemeMode>(
                            value: ref.watch(appThemeModeProvider),
                            isDense: true,
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('Automatique ⚙️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Chai Lumineux ☀️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Cave Sombre 🕯️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(appThemeModeProvider.notifier).setTheme(val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people_alt, color: Color(0xFFD4AF37)),
                  title: const Text('Mes Amis & Cartes des Goûts 🍷', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Boire ensemble, recherche @pseudo/tél/email, cartes partagées'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/friends'),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Color(0xFF8B1E3F)),
                  title: const Text('Profils de Goût & Co-Dégustateurs', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Gérer les goûts de Flavien, Caro et invités pour l\'IA'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => TasteProfilesDialog.show(context),
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: Color(0xFF2E7D32)),
                  title: const Text('Exporter ma Cave & Rapport d\'Assurance', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Fichiers Excel / CSV & Certificat de valeur patrimoniale'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final cellars = ref.read(userCellarsProvider).value ?? [];
                    final name = cellars.isNotEmpty ? (cellars.first['cellars']?['name'] ?? 'Ma Cave') : 'Ma Cave';
                    CellarExportDialog.show(context, name);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.public, color: Colors.amber),
                  title: Text(l10n?.profileScratchcard ?? 'Planisphère des Terroirs à Gratter'),
                  subtitle: const Text('Révélez vos zones et appellations dégustées'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/scratchcard'),
                ),
                ListTile(
                  leading: const Icon(Icons.history_toggle_off, color: Colors.purple),
                  title: Text(l10n?.profileChangelog ?? 'Journal des versions & Changelog'),
                  subtitle: const Text('Bascule Vue Client / Vue Développeur'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/changelog'),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                  title: const Text('Estimation des Coûts IA (Gemini)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Suivi des tokens et dépenses : Jour, Semaine, Mois, Année, All-Time'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/ai-costs'),
                ),
                ListTile(
                  leading: const Icon(Icons.terminal, color: Colors.teal),
                  title: const Text('Console & Logs de Diagnostic', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Inspecter l\'historique des requêtes et copier les rapports'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/diagnostic-logs'),
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n?.profileLogout ?? 'Se déconnecter', style: const TextStyle(color: Colors.red)),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  onTap: () async {
                    AppLogger.info('AUTH', 'User requested sign out from ProfileScreen');
                    try {
                      await ref.read(supabaseProvider).auth.signOut();
                    } catch (e) {
                      AppLogger.error('AUTH', 'Error during signOut', e);
                    }
                    ref.read(currentCellarIdProvider.notifier).state = null;
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
                const SizedBox(height: 12),
                AboutListTile(
                  applicationName: 'Chatmelier',
                  applicationVersion: '1.2.0',
                  applicationIcon: Image.asset(
                    'assets/images/logo_transparent_64.png',
                    width: 48,
                    height: 48,
                  ),
                  applicationLegalese: '© 2026 Chatmelier • Smart AI Wine Cellar Manager',
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
    );
  }
}
