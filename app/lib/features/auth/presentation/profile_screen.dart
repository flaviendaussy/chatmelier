import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../monetization/admob_service.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/providers/premium_provider.dart';
import '../../cellar/presentation/cellar_export_dialog.dart';
import 'taste_profiles_dialog.dart';
import 'taste_profile_edit_sheet.dart';
import 'taste_profile_radar_screen.dart';
import 'widgets/wine_taste_radar_chart.dart';
import '../domain/wine_taste_radar.dart';
import '../data/taste_profile_service.dart';
import '../domain/taste_profile.dart';
import 'mandatory_username_dialog.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/phone_dial_code.dart';
import '../../../shared/widgets/international_phone_input.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../domain/user_profile.dart';
import '../../notifications/presentation/notification_settings_sheet.dart';
import '../../notifications/data/notification_preferences_service.dart';
import '../../badges/presentation/badges_gallery_sheet.dart';
import '../../feedback/data/shake_feedback_service.dart';

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
  bool _showPrivacyOptions = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkPrivacyOptions();
  }

  Future<void> _checkPrivacyOptions() async {
    try {
      final admob = ref.read(admobServiceProvider);
      final required = await admob.isPrivacyOptionsRequired();
      if (mounted) {
        setState(() => _showPrivacyOptions = required);
      }
    } catch (_) {}
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

  String _tasteProfileSummary([bool isFr = true]) {
    final p = _userTasteProfile;
    if (p == null ||
        (p.favoriteTypes.isEmpty &&
            p.favoriteRegions.isEmpty &&
            p.favoriteGrapes.isEmpty &&
            p.dislikedCharacteristics.isEmpty)) {
      return isFr
          ? 'Aucune préférence définie pour l\'instant. Personnalisez vos styles, terroirs et cépages favoris !'
          : 'No preferences defined yet. Customize your favorite styles, terroirs, and grape varieties!';
    }

    final parts = <String>[];
    if (p.favoriteTypes.isNotEmpty) {
      parts.add('${isFr ? "Styles" : "Styles"} : ${p.favoriteTypes.take(2).join(", ")}');
    }
    if (p.favoriteRegions.isNotEmpty) {
      parts.add('${isFr ? "Terroirs" : "Terroirs"} : ${p.favoriteRegions.take(2).join(", ")}');
    }
    if (p.favoriteGrapes.isNotEmpty) {
      parts.add('${isFr ? "Cépages" : "Grapes"} : ${p.favoriteGrapes.take(2).join(", ")}');
    }
    if (p.dislikedCharacteristics.isNotEmpty) {
      parts.add('${isFr ? "Aversions" : "Dislikes"} : ${p.dislikedCharacteristics.take(1).join(", ")}');
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
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final ctrl = TextEditingController(text: _displayName);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF8B1E3F)),
            const SizedBox(width: 8),
            Text(isFr ? 'Nom d\'affichage' : 'Display Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: isFr ? 'Votre nom ou prénom' : 'Your first or last name',
            hintText: isFr ? 'ex: Flavien' : 'e.g. Flavien',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text(isFr ? 'Enregistrer' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            SnackBar(
              content: Text(isFr ? 'Nom d\'affichage mis à jour' : 'Display name updated'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    }
  }

  Future<void> _editPhoneNumber() async {
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    String tempPhone = _phoneNumber ?? '';
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_iphone, color: Color(0xFF8B1E3F)),
            const SizedBox(width: 8),
            Text(isFr ? 'Numéro de téléphone' : 'Phone Number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InternationalPhoneInput(
              initialValue: _phoneNumber,
              labelText: isFr ? 'Votre numéro (indicatif obligatoire)' : 'Your number (country code required)',
              helperText: isFr ? 'FR (+33) par défaut, UK (+44) ou indicatif détecté par GPS' : 'FR (+33) default, UK (+44) or GPS detected code',
              onChanged: (val) => tempPhone = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
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
            child: Text(isFr ? 'Enregistrer' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                SnackBar(
                  content: Text(isFr ? 'Ce numéro de téléphone est déjà associé à un autre compte.' : 'This phone number is already associated with another account.'),
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
            SnackBar(
              content: Text(isFr ? 'Numéro de téléphone mis à jour avec succès' : 'Phone number updated successfully'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    }
  }

  void _showLegalDialog(String title, String content) {
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isFr ? 'Fermer' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    _showLegalDialog(
      isFr ? 'Politique de Confidentialité' : 'Privacy Policy',
      isFr
          ? 'APPLICATION CHATMELIER — POLITIQUE DE CONFIDENTIALITÉ\n'
            'Dernière mise à jour : 4 septembre 2026\n\n'
            '1. ENGAGEMENT DE CONFIDENTIALITÉ\n'
            'Chatmelier respecte scrupuleusement la vie privée de ses utilisateurs conformément au RGPD (Règlement UE 2016/679) et aux exigences d\'Apple et de Google.\n\n'
            '2. DONNÉES COLLECTÉES\n'
            '• Compte : Email, nom d\'affichage, pseudo et téléphone optionnel pour l\'ajout d\'amis.\n'
            '• Caves & Bouteilles : Noms de caves, inventaire, notes de dégustation, historique de consommation.\n'
            '• Photos : Étiquettes et bouteilles analysées par IA (Google Gemini Vision).\n'
            '• Localisation (Optionnelle) : Coordonnées GPS pour localiser les dégustations extérieures et détecter votre cave à proximité.\n'
            '• Publicités : Identifiants publicitaires pour annonces récompensées via Google AdMob.\n\n'
            '3. SUPPRESSION DU COMPTE (Article 17 RGPD)\n'
            'Vous pouvez à tout moment supprimer définitivement votre compte et l\'intégralité de vos données via le bouton "Supprimer mon compte" ci-dessous ou par email à contact@chatmelier.app.\n\n'
            'Version web complète consultable sur : https://chatmelier.github.io/privacy.html'
          : 'CHATMELIER APPLICATION — PRIVACY POLICY\n'
            'Last updated: September 4, 2026\n\n'
            '1. PRIVACY COMMITMENT\n'
            'Chatmelier strictly respects user privacy in compliance with GDPR (EU Regulation 2016/679) and Apple/Google store requirements.\n\n'
            '2. COLLECTED DATA\n'
            '• Account: Email, display name, username, and optional phone for friend additions.\n'
            '• Cellars & Bottles: Cellar names, inventory, tasting notes, consumption history.\n'
            '• Photos: Labels and bottles analyzed by AI (Google Gemini Vision).\n'
            '• Location (Optional): GPS coordinates to locate outdoor tastings and detect nearby cellar.\n'
            '• Ads: Advertising identifiers for rewarded ads via Google AdMob.\n\n'
            '3. ACCOUNT DELETION (Article 17 GDPR)\n'
            'You can permanently delete your account and all data at any time via the "Delete my account" button below or by email to contact@chatmelier.app.\n\n'
            'Full web version available at: https://chatmelier.github.io/privacy.html',
    );
  }

  void _showTermsOfService() {
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    _showLegalDialog(
      isFr ? 'Conditions Générales d\'Utilisation' : 'Terms of Service',
      isFr
          ? 'APPLICATION CHATMELIER — CONDITIONS GÉNÉRALES D\'UTILISATION\n'
            'En vigueur au 4 septembre 2026\n\n'
            '1. OBJET DU SERVICE\n'
            'Chatmelier est une application de gestion de cave à vins et spiritueux assistée par intelligence artificielle.\n\n'
            '2. PRÉVENTION & SANTÉ\n'
            'L\'abus d\'alcool est dangereux pour la santé, à consommer avec modération. Chatmelier est un outil informatif de gestion patrimoniale et n\'encourage pas la consommation excessive.\n\n'
            '3. CONSEILS DE L\'INTELLIGENCE ARTIFICIELLE\n'
            'Les estimations d\'apogée, accords mets-vins et valorisations financières sont donnés à titre indicatif sans garantie de valorisation marchande future.\n\n'
            '4. PROPRIÉTÉ DES DONNÉES\n'
            'Vous demeurez propriétaire de vos photos et notes de dégustation.\n\n'
            'Version web complète consultable sur : https://chatmelier.github.io/terms.html'
          : 'CHATMELIER APPLICATION — TERMS OF SERVICE\n'
            'Effective as of September 4, 2026\n\n'
            '1. PURPOSE OF SERVICE\n'
            'Chatmelier is an AI-assisted wine and spirits cellar management application.\n\n'
            '2. HEALTH & PREVENTION\n'
            'Alcohol abuse is dangerous to health, consume in moderation. Chatmelier is an informative asset management tool and does not encourage excessive consumption.\n\n'
            '3. ARTIFICIAL INTELLIGENCE ADVICE\n'
            'Peak maturity estimates, food & wine pairings, and valuations are given for informational purposes without market value guarantee.\n\n'
            '4. DATA OWNERSHIP\n'
            'You remain the owner of your photos and tasting notes.\n\n'
            'Full web version available at: https://chatmelier.github.io/terms.html',
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final confirmCtrl = TextEditingController();
    bool canDelete = false;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFr ? 'Supprimer mon compte ?' : 'Delete my account?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFr
                    ? 'Cette action est irréversible et immédiate.\n\n'
                      'Toutes vos données seront définitivement effacées :\n'
                      '• Vos caves, casiers et bouteilles\n'
                      '• Vos photos et vos notes de dégustation\n'
                      '• Votre profil et votre historique de discussion'
                    : 'This action is irreversible and immediate.\n\n'
                      'All your data will be permanently deleted:\n'
                      '• Your cellars, racks and bottles\n'
                      '• Your photos and tasting notes\n'
                      '• Your profile and chat history',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                isFr
                    ? 'Pour confirmer, tapez SUPPRIMER ci-dessous :'
                    : 'To confirm, type DELETE below:',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isFr ? 'SUPPRIMER' : 'DELETE',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) {
                  setDialogState(() {
                    final upper = val.trim().toUpperCase();
                    canDelete = upper == 'SUPPRIMER' || upper == 'DELETE';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isFr ? 'Annuler' : 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: canDelete ? () => Navigator.of(ctx).pop(true) : null,
              child: Text(isFr ? 'Supprimer définitivement' : 'Permanently delete', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.red),
                  const SizedBox(height: 16),
                  Text(isFr ? 'Suppression du compte et des données...' : 'Deleting account and data...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final repo = ref.read(authRepositoryProvider);
        await repo.deleteAccount();

        ref.read(currentCellarIdProvider.notifier).state = null;

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFr ? 'Votre compte et vos données ont été définitivement supprimés.' : 'Your account and data have been permanently deleted.'),
              backgroundColor: Colors.black87,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          AppLogger.error('AUTH', 'Error during deleteAccount', e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFr ? 'Erreur lors de la suppression : $e' : 'Error during deletion: $e'),
              backgroundColor: Colors.red,
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
    final isFr = Localizations.localeOf(context).languageCode != 'en';

    final resolvedDisplayName = _displayName.isNotEmpty
        ? _displayName
        : (user?.userMetadata?['display_name'] as String? ?? (isFr ? 'Amateur de Vin' : 'Wine Lover'));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n?.profileTitle ?? (isFr ? 'Profil & Réglages' : 'Profile & Settings')),
          actions: const [
            NotificationBellButton(),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104),
            child: Column(
              children: [
                // Compact Profile Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      OwnerAvatar(userId: user?.id ?? '', radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resolvedDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _username != null && _username!.isNotEmpty
                                  ? '@$_username'
                                  : (user?.email ?? (isFr ? 'Mode Invité' : 'Guest Mode')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user == null)
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: () => context.go('/login'),
                          child: Text(isFr ? 'Connexion' : 'Sign in', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                // Segmented TabBar
                TabBar(
                  isScrollable: false,
                  indicatorColor: const Color(0xFF8B1E3F),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF8B1E3F),
                  unselectedLabelColor: Colors.grey,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.wine_bar, size: 20),
                      text: l10n?.profileTabPalate ?? (isFr ? 'Palais' : 'Palate'),
                    ),
                    Tab(
                      icon: const Icon(Icons.tune, size: 20),
                      text: l10n?.profileTabSettings ?? (isFr ? 'Réglages' : 'Settings'),
                    ),
                    Tab(
                      icon: const Icon(Icons.inventory_2_outlined, size: 20),
                      text: l10n?.profileTabTools ?? (isFr ? 'Outils' : 'Tools'),
                    ),
                    Tab(
                      icon: const Icon(Icons.shield_outlined, size: 20),
                      text: l10n?.profileTabAccount ?? (isFr ? 'Compte' : 'Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildPalaisAndBadgesTab(context, theme, isDark, isFr),
                  _buildSettingsTab(context, theme, isDark, isFr),
                  _buildToolsTab(context, theme, isDark, isFr),
                  _buildAccountTab(context, theme, isDark, isFr),
                ],
              ),
      ),
    );
  }

  // =========================================================================
  // TAB 0 : PALAIS & BADGES
  // =========================================================================
  Widget _buildPalaisAndBadgesTab(BuildContext context, ThemeData theme, bool isDark, bool isFr) {
    final currentProfile = _userTasteProfile ??
        TasteProfile(
          id: 'primary_user',
          name: isFr ? 'Moi' : 'Me',
          isPrimary: true,
          favoriteTypes: const [],
          favoriteRegions: const [],
          favoriteGrapes: const [],
          dislikedCharacteristics: const [],
          notes: '',
        );
    final metrics = WineTasteRadarCalculator.compute(currentProfile);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 🕸️ HERO SPIDER CHART DES GOÛTS (RADAR)
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 1.5),
          ),
          color: isDark ? const Color(0xFF221A28) : const Color(0xFFFCF9F5),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.radar, color: Color(0xFF8B1E3F), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isFr ? 'Radar des Goûts' : 'Taste Radar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(isFr ? 'Empreinte œnologique & équilibre des saveurs' : 'Oenological footprint & flavor balance', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onPressed: () => TasteProfileRadarScreen.show(context),
                      icon: const Icon(Icons.fullscreen, size: 15),
                      label: Text(isFr ? 'Plein écran' : 'Fullscreen', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Radar chart interactive preview
                Center(
                  child: SizedBox(
                    height: 190,
                    width: 260,
                    child: GestureDetector(
                      onTap: () => TasteProfileRadarScreen.show(context),
                      child: WineTasteRadarChart(
                        datasets: [
                          RadarChartDataset(
                            label: _displayName.isNotEmpty ? _displayName : (isFr ? 'Mes Goûts' : 'My Taste'),
                            color: const Color(0xFF8B1E3F),
                            metrics: metrics,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Summary of current preferences
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white70,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _tasteProfileSummary(isFr),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.3,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: () => TasteProfilesDialog.show(context),
                        icon: const Icon(Icons.people_outline, size: 15),
                        label: Text(isFr ? 'Invités / Proches' : 'Guests / Friends', style: const TextStyle(fontSize: 11.5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E3F),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: _openTasteProfileEditor,
                        icon: const Icon(Icons.tune, size: 15),
                        label: Text(isFr ? 'Personnaliser' : 'Customize', style: const TextStyle(fontSize: 11.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 🏆 BADGES & TROPHÉES SHOWCASE
        const BadgesShowcaseCard(),
      ],
    );
  }

  // =========================================================================
  // TAB 1 : RÉGLAGES (ZERO SCROLL)
  // =========================================================================
  Widget _buildSettingsTab(BuildContext context, ThemeData theme, bool isDark, bool isFr) {
    final l10n = AppLocalizations.of(context);
    final userLocale = ref.watch(localeProvider);
    final currentLangValue = userLocale == null ? 'system' : userLocale.languageCode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Langue
        Row(
          children: [
            const Icon(Icons.language, color: Color(0xFF8B1E3F)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n?.profileLanguage ?? (isFr ? 'Langue de l\'application' : 'Application Language'),
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
                  items: [
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(l10n?.profileLanguageSystem ?? (isFr ? 'Système 🌐' : 'System 🌐'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'fr',
                      child: Text('Français 🇫🇷', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'en',
                      child: Text('English 🇬🇧', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'it',
                      child: Text('Italiano 🇮🇹', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'es',
                      child: Text('Español 🇪🇸', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'ca',
                      child: Text('Català 🟡🔴', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'pt',
                      child: Text('Português 🇵🇹', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'nl',
                      child: Text('Nederlands 🇳🇱', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'de',
                      child: Text('Deutsch 🇩🇪', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'ja',
                      child: Text('日本語 🇯🇵', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'zh',
                      child: Text('中文 (简体) 🇨🇳', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'ko',
                      child: Text('한국어 🇰🇷', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const DropdownMenuItem(
                      value: 'sv',
                      child: Text('Svenska 🇸🇪', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                        SnackBar(
                          content: Text(l10n?.profileLanguageUpdated ?? (isFr ? 'Langue modifiée avec succès' : 'Language updated successfully')),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 28),

        // Devise
        Row(
          children: [
            const Icon(Icons.paid_outlined, color: Color(0xFF8B1E3F)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n?.profileDefaultCurrency ?? (isFr ? 'Devise par défaut' : 'Default Currency'),
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
        const Divider(height: 28),

        // Ambiance / Thème
        Row(
          children: [
            const Icon(Icons.dark_mode_outlined, color: Color(0xFF8B1E3F)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n?.profileTheme ?? (isFr ? 'Ambiance / Thème' : 'Appearance / Theme'),
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n?.profileThemeSystem ?? (isFr ? 'Système ⚙️' : 'System ⚙️'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n?.profileThemeLight ?? (isFr ? 'Lumineux ☀️' : 'Light ☀️'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n?.profileThemeDark ?? (isFr ? 'Sombre 🕯️' : 'Dark 🕯️'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
        const Divider(height: 28),

        // Notifications
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFF8B1E3F)),
          title: Text(isFr ? 'Notifications & Alertes Système 🔔' : 'Notifications & System Alerts 🔔', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${ref.watch(notificationPreferencesProvider).activeCount} ${isFr ? "alerte(s) active(s) • Dégustations, apogées, caves" : "active alert(s) • Tastings, aging peak, cellars"}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => NotificationSettingsSheet.show(context),
        ),

        // RGPD Consent options
        if (_showPrivacyOptions) ...[
          const Divider(height: 28),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune, color: Color(0xFFD4AF37)),
            title: Text(isFr ? 'Préférences Publicitaires & RGPD' : 'Ad Preferences & Privacy', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isFr ? 'Modifier mes choix de consentement publicitaire' : 'Manage your advertising consent choices', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(admobServiceProvider).showPrivacyOptionsForm(),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // TAB 2 : OUTILS & DONNÉES (ZERO SCROLL)
  // =========================================================================
  Widget _buildToolsTab(BuildContext context, ThemeData theme, bool isDark, bool isFr) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final isAdmin = kDebugMode || (user?.email?.toLowerCase().contains('flavien') ?? false);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.people_alt, color: Color(0xFFD4AF37)),
          title: Text(isFr ? 'Mes Amis & Cartes des Goûts 🍷' : 'My Friends & Taste Maps 🍷', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isFr ? 'Boire ensemble, recherche @pseudo, cartes partagées' : 'Drink together, search @username, shared maps', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/friends'),
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.file_download_outlined, color: Color(0xFF2E7D32)),
          title: Text(isFr ? 'Exporter ma Cave & Rapport d\'Assurance' : 'Export My Cellar & Insurance Report', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isFr ? 'Excel / CSV & Certificat de valeur patrimoniale' : 'Excel / CSV & Asset valuation certificate', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final cellars = ref.read(userCellarsProvider).value ?? [];
            final name = cellars.isNotEmpty ? (cellars.first['cellars']?['name'] ?? (isFr ? 'Ma Cave' : 'My Cellar')) : (isFr ? 'Ma Cave' : 'My Cellar');
            CellarExportDialog.show(context, name);
          },
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.file_upload_outlined, color: Color(0xFF1B5E20)),
          title: Text(isFr ? 'Importer une Cave (Excel / CSV / Texte)' : 'Import a Cellar (Excel / CSV / Text)', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isFr ? 'Import instantané intelligent par IA sommelier' : 'Instant smart import powered by AI sommelier', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final currentCellarId = ref.read(currentCellarIdProvider);
            context.push('/cellar/import-excel?cellarId=${currentCellarId ?? ""}');
          },
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.public, color: Colors.amber),
          title: Text(l10n?.profileScratchcard ?? (isFr ? 'Planisphère des Terroirs à Gratter' : 'Scratch Map of Terroirs'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isFr ? 'Révélez vos zones et appellations dégustées' : 'Reveal your tasted regions and appellations', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/scratchcard'),
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_toggle_off, color: Colors.purple),
          title: Text(l10n?.profileChangelog ?? (isFr ? 'Journal des versions & Changelog' : 'Release Notes & Changelog'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isFr ? 'Bascule Vue Client / Vue Développeur' : 'Toggle Client View / Developer View', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/changelog'),
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.feedback_outlined, color: Colors.orange),
          title: Text(isFr ? 'Signaler un bug / Commenter' : 'Report a Bug / Feedback', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isFr ? 'Secouer le téléphone ou cliquer ici pour annoter' : 'Shake phone or tap here to annotate', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ShakeFeedbackService.instance.triggerFeedback(context),
        ),

        if (isAdmin) ...[
          const Divider(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            title: Text(isFr ? 'Estimation des Coûts IA (Gemini)' : 'AI Cost Estimation (Gemini)', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isFr ? 'Suivi des tokens et dépenses All-Time' : 'Token usage & all-time expenditure', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ai-costs'),
          ),
          const Divider(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.terminal, color: Colors.teal),
            title: Text(isFr ? 'Console & Logs de Diagnostic' : 'Diagnostic Console & Logs', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isFr ? 'Inspecter l\'historique des requêtes' : 'Inspect request and event history', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/diagnostic-logs'),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // TAB 3 : COMPTE & LÉGAL (ZERO SCROLL)
  // =========================================================================
  // =========================================================================
  // TAB 3 : COMPTE & LÉGAL (ZERO SCROLL)
  // =========================================================================
  Widget _buildAccountTab(BuildContext context, ThemeData theme, bool isDark, bool isFr) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);
    final isPremium = ref.watch(premiumProvider);
    final isAdmin = kDebugMode || (user?.email?.toLowerCase().contains('flavien') ?? false);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (isAdmin) ...[
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isPremium ? const Color(0xFFD4AF37) : Colors.grey.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, color: isPremium ? const Color(0xFFD4AF37) : Colors.grey, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isPremium
                          ? (isFr ? '👑 Mode Premium (Admin actif)' : '👑 Premium Mode (Admin active)')
                          : (isFr ? 'Mode Standard (Gratuit)' : 'Standard Mode (Free)'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Switch.adaptive(
                    value: isPremium,
                    activeTrackColor: const Color(0xFFD4AF37),
                    onChanged: (val) {
                      ref.read(premiumProvider.notifier).setPremium(val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.alternate_email, color: Color(0xFF8B1E3F)),
          title: Text(isFr ? 'Pseudo unique' : 'Unique Username', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            _username != null && _username!.isNotEmpty ? '@$_username' : (isFr ? 'Non défini' : 'Not set'),
            style: TextStyle(
              color: _username != null && _username!.isNotEmpty ? const Color(0xFF8B1E3F) : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(Icons.edit, size: 16),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => MandatoryUsernameDialog(
                onCompleted: () => _loadProfile(),
              ),
            );
          },
        ),
        const Divider(height: 8),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text(l10n?.profileDisplayName ?? (isFr ? 'Nom d\'affichage' : 'Display Name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(_displayName.isNotEmpty ? _displayName : (user?.userMetadata?['display_name'] ?? (isFr ? 'Utilisateur' : 'User')), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.edit, size: 16),
          onTap: _editDisplayName,
        ),
        const Divider(height: 8),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone_outlined, color: Color(0xFF8B1E3F)),
          title: Text(isFr ? 'Numéro de téléphone' : 'Phone Number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            _phoneNumber != null && _phoneNumber!.isNotEmpty
                ? '${PhoneDialCodeHelper.parseExisting(_phoneNumber).$1.flag} $_phoneNumber'
                : (isFr ? 'Non renseigné' : 'Not set'),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.edit, size: 16),
          onTap: _editPhoneNumber,
        ),
        const Divider(height: 8),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.email_outlined),
          title: Text(l10n?.profileEmail ?? (isFr ? 'Email' : 'Email'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(user?.email ?? (isFr ? 'Non renseigné (Mode Invité)' : 'Not set (Guest Mode)'), style: const TextStyle(fontSize: 12)),
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF8B1E3F)),
          title: Text(isFr ? 'Politique de Confidentialité' : 'Privacy Policy', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: _showPrivacyPolicy,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined, color: Color(0xFF8B1E3F)),
          title: Text(isFr ? 'Conditions Générales d\'Utilisation' : 'Terms of Service', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: _showTermsOfService,
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout),
          title: Text(l10n?.profileLogout ?? (isFr ? 'Se déconnecter' : 'Log out'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          onTap: () async {
            AppLogger.info('AUTH', 'User requested sign out from ProfileScreen');
            try {
              await ref.read(authRepositoryProvider).signOut();
            } catch (e) {
              AppLogger.error('AUTH', 'Error during signOut', e);
            }
            ref.read(currentCellarIdProvider.notifier).state = null;
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(isFr ? 'Supprimer mon compte' : 'Delete my account', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, color: Colors.red, size: 18),
          onTap: _confirmDeleteAccount,
        ),
        const SizedBox(height: 8),

        AboutListTile(
          applicationName: 'Chatmelier',
          applicationVersion: '1.2.1',
          applicationIcon: Image.asset(
            'assets/images/logo_transparent_64.png',
            width: 36,
            height: 36,
          ),
          applicationLegalese: isFr
              ? '© 2026 Chatmelier • Gestionnaire de Cave Intelligent par IA\nConforme RGPD & Apple/Google Store Guidelines'
              : '© 2026 Chatmelier • Smart AI Wine Cellar Manager\nCompliant with GDPR & Apple/Google Store Guidelines',
          icon: const Icon(Icons.info_outline, size: 20),
        ),
      ],
    );
  }
}
