import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../monetization/admob_service.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/providers/premium_provider.dart';
import '../../cellar/presentation/cellar_export_dialog.dart';
import '../data/export_des_donnees.dart';
import 'taste_profiles_dialog.dart';
import 'taste_profile_edit_sheet.dart';
import 'taste_profile_radar_screen.dart';
import 'widgets/radar_legende.dart';
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
import '../../feedback/data/shake_feedback_service.dart';
import '../../feedback/data/feedback_history_service.dart';
import '../../feedback/presentation/mes_retours_sheet.dart';
import 'taste_evidence_sheet.dart';
import '../../cellar/domain/wine.dart';
import '../../sommelier/domain/taste_frontier_engine.dart';
import 'partage_empreinte_sheet.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/widgets/onglets.dart';
import '../../../shared/utils/valeurs_rangees.dart';
import 'widgets/carte_des_terroirs_card.dart';

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
  String? _avatarUrl;
  TasteProfile? _userTasteProfile;
  bool _isLoading = true;
  bool _showPrivacyOptions = false;
  bool _isUploadingAvatar = false;

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
            _avatarUrl = profile.avatarUrl;
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


  /// Dit à voix haute ce que le radar montre (traits pleins, pointillés, moustaches) :
  /// jusqu'où le modèle sait, et où il devine.
  ///
  /// Un radar sans cette phrase affiche ses huit axes avec la même autorité qu'on ait
  /// une dégustation ou cinquante derrière. Le modèle devient lisible seulement s'il
  /// admet ce qu'il ignore — et l'axe le moins connu est exactement l'endroit où une
  /// prochaine bouteille apprendrait le plus.
  Widget _buildConfidenceLine(ThemeData theme, TasteProfile profile) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final confiance = profile.overallConfidence;

    final String texte;
    if (confiance < 0.05) {
      texte = l10n.tasteConfidenceUnknown;
    } else {
      final labels = WineTasteRadarMetrics.localizedAxisLabels(lang);
      final idx = TasteProfile.axisKeys.indexOf(profile.leastKnownAxis);
      final axe = (idx >= 0 && idx < labels.length)
          ? labels[idx].replaceAll('\n', ' ')
          : profile.leastKnownAxis;
      texte = '${l10n.tasteConfidenceKnown((confiance * 100).round().toString())} '
          '${l10n.tasteConfidenceFrontier(axe)}';
    }

    // Le moteur de frontière (S4) : la bouteille de la cave qui apprendrait le plus, prête
    // à boire — jamais une bouteille en garde, jamais un vin détesté.
    final bouteilles = ref.watch(bottlesProvider(ref.watch(currentCellarIdProvider))).valueOrNull ?? const [];
    final pretes = [
      for (final b in bouteilles)
        if (b.quantity > 0 && b.wine != null && _pretABoire(b.wine!)) b,
    ];
    final frontiere = TasteFrontierEngine.choisir(
      pretes,
      profile,
      profilDe: (b) => ProfilDeVin.depuisLaCave(b.wine!),
    );
    final suggestion = frontiere == null
        ? null
        : TasteFrontierEngine.phraseCave(
            frontiere,
            '${frontiere.vin.wine!.name}${frontiere.vin.wine!.vintage != null ? ' ${frontiere.vin.wine!.vintage}' : ''}',
            lang == 'fr',
          );

    // La phrase affirme quelque chose sur le palais : c'est donc l'endroit naturel pour
    // demander « d'où sors-tu ça ? ». Un modèle lisible doit être interrogeable là où il
    // se prononce, pas depuis un écran de réglages.
    final ligne = InkWell(
      onTap: () => showTasteEvidenceSheet(context),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights_rounded,
                size: 15, color: Colors.grey.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$texte '),
                    TextSpan(
                      text: l10n.tasteEvidenceOpen,
                      style: const TextStyle(
                        color: Color(0xFF8B1E3F),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.3,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (suggestion == null) return ligne;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ligne,
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧭', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(suggestion,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5, height: 1.3)),
            ),
          ],
        ),
      ],
    );
  }

  /// Prête à boire : à son apogée, à boire bientôt, ou sur le déclin (raison de plus).
  static bool _pretABoire(Wine w) => const {
        DrinkWindowStatus.inPeak,
        DrinkWindowStatus.drinkSoon,
        DrinkWindowStatus.pastPeak,
      }.contains(w.windowStatus);

  String _tasteProfileSummary([dynamic lang]) {
    final langCode = (lang is String && lang.isNotEmpty)
        ? lang
        : (Localizations.maybeLocaleOf(context)?.languageCode ?? 'fr');
    final p = _userTasteProfile;
    if (p == null ||
        (p.favoriteTypes.isEmpty &&
            p.favoriteRegions.isEmpty &&
            p.favoriteGrapes.isEmpty &&
            p.dislikedCharacteristics.isEmpty)) {
      switch (langCode) {
        case 'en':
          return 'No preferences defined yet. Customize your favorite styles, terroirs, and grape varieties!';
        case 'es':
          return '¡Aún no hay preferencias definidas. Personaliza tus estilos, terruños y variedades!';
        case 'it':
          return 'Nessuna preferenza definita per ora. Personalizza i tuoi stili, terroir e vitigni preferiti!';
        case 'ca':
          return 'Encara no hi ha preferències definides. Personalitza els teus estils, terroirs i varietats!';
        case 'la':
          return 'Nullae praeferentiae constitutae sunt. Adapta stylos, terrena et uvas dilectas!';
        default:
          return 'Aucune préférence définie pour l\'instant. Personnalisez vos styles, terroirs et cépages favoris !';
      }
    }

    String stylesLabel;
    String terroirsLabel;
    String grapesLabel;
    String dislikesLabel;
    switch (langCode) {
      case 'en':
        stylesLabel = 'Styles'; terroirsLabel = 'Terroirs'; grapesLabel = 'Grapes'; dislikesLabel = 'Dislikes';
        break;
      case 'es':
        stylesLabel = 'Estilos'; terroirsLabel = 'Terruños'; grapesLabel = 'Uvas'; dislikesLabel = 'Aversiones';
        break;
      case 'it':
        stylesLabel = 'Stili'; terroirsLabel = 'Terroir'; grapesLabel = 'Vitigni'; dislikesLabel = 'Avversioni';
        break;
      case 'ca':
        stylesLabel = 'Estils'; terroirsLabel = 'Terroirs'; grapesLabel = 'Raïms'; dislikesLabel = 'Aversions';
        break;
      case 'la':
        stylesLabel = 'Styli'; terroirsLabel = 'Terrena'; grapesLabel = 'Uvae'; dislikesLabel = 'Aversiones';
        break;
      default:
        stylesLabel = 'Styles'; terroirsLabel = 'Terroirs'; grapesLabel = 'Cépages'; dislikesLabel = 'Aversions';
        break;
    }

    // L'espace avant les deux-points est français.
    final dp = langCode == 'fr' ? ' :' : ':';
    final parts = <String>[];
    if (p.favoriteTypes.isNotEmpty) {
      parts.add('$stylesLabel$dp ${p.favoriteTypes.take(2).map(valeurAffichee).join(", ")}');
    }
    if (p.favoriteRegions.isNotEmpty) {
      parts.add('$terroirsLabel$dp ${p.favoriteRegions.take(2).map(valeurAffichee).join(", ")}');
    }
    if (p.favoriteGrapes.isNotEmpty) {
      parts.add('$grapesLabel$dp ${p.favoriteGrapes.take(2).join(", ")}');
    }
    if (p.dislikedCharacteristics.isNotEmpty) {
      parts.add('$dislikesLabel$dp ${p.dislikedCharacteristics.take(1).map(valeurAffichee).join(", ")}');
    }
    return parts.join(' • ');
  }

  Future<void> _setAvatar(String? url) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _avatarUrl = url);
    final repo = ref.read(authRepositoryProvider);
    await repo.updateProfile(
      displayName: _displayName.isNotEmpty ? _displayName : (user.userMetadata?['display_name'] ?? 'User'),
      username: _username,
      phoneNumber: _phoneNumber,
      email: user.email,
      avatarUrl: url ?? '',
      defaultCurrency: _defaultCurrency,
    );
    if (mounted) {
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(url == null
              ? (trSi(isFr, 'Avatar réinitialisé.', 'Avatar reset.'))
              : (trSi(isFr, 'Avatar mis à jour ! 🍷', 'Avatar updated! 🍷'))),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isUploadingAvatar = true);

      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final bytes = await picked.readAsBytes();
      String? finalUrl;

      try {
        final supabase = Supabase.instance.client;
        final ext = picked.path.split('.').last.toLowerCase();
        final safeExt = (ext == 'png' || ext == 'webp') ? ext : 'jpg';
        final fileName = 'avatars/avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
        await supabase.storage.from('labels').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$safeExt', upsert: true),
        );
        finalUrl = supabase.storage.from('labels').getPublicUrl(fileName);
      } catch (storageErr) {
        AppLogger.warning('PROFILE', 'Supabase storage avatar upload failed, falling back to data URI: $storageErr');
        final b64 = base64Encode(bytes);
        finalUrl = 'data:image/jpeg;base64,$b64';
      }

      await _setAvatar(finalUrl);
    } catch (e) {
      AppLogger.error('PROFILE', 'Avatar selection failed: $e');
      if (mounted) {
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trSi(isFr, 'Erreur lors de la sélection de la photo', 'Error picking avatar image')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showAvatarPickerSheet() {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final sommelierAvatars = [
      '🍷', '🍇', '🍾', '🥂', '🍸', '🥃', '🧀', '🕯️', '🎩', '👑', '🧑‍🍳', '⚜️', '🏰', '🌱', '🌿', '🪵'
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  trSi(isFr, 'Photo de profil & Avatar', 'Profile Picture & Avatar'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(trSi(isFr, 'Appareil photo', 'Camera')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pickAndUploadAvatar(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(trSi(isFr, 'Galerie', 'Gallery')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pickAndUploadAvatar(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  trSi(isFr, 'Avatars Sommelier', 'Sommelier Avatars'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sommelierAvatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final emoji = sommelierAvatars[idx];
                      final isSelected = _avatarUrl == 'emoji:$emoji';
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _setAvatar('emoji:$emoji');
                        },
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    },
                  ),
                ),
                if (_avatarUrl != null && _avatarUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(trSi(isFr, 'Supprimer l\'avatar actuel', 'Remove current avatar')),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _setAvatar(null);
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
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
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final ctrl = TextEditingController(text: _displayName);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF8B1E3F)),
            const SizedBox(width: 8),
            Text(trSi(isFr, 'Nom d\'affichage', 'Display Name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: trSi(isFr, 'Votre nom ou prénom', 'Your first or last name'),
            hintText: trSi(isFr, 'ex: Flavien', 'e.g. Flavien'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(trSi(isFr, 'Annuler', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text(trSi(isFr, 'Enregistrer', 'Save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          avatarUrl: _avatarUrl,
        );
        setState(() => _displayName = result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(trSi(isFr, 'Nom d\'affichage mis à jour', 'Display name updated')),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    }
  }

  Future<void> _editPhoneNumber() async {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    String tempPhone = _phoneNumber ?? '';
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_iphone, color: Color(0xFF8B1E3F)),
            const SizedBox(width: 8),
            Text(trSi(isFr, 'Numéro de téléphone', 'Phone Number'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InternationalPhoneInput(
              initialValue: _phoneNumber,
              labelText: trSi(isFr, 'Votre numéro (indicatif obligatoire)', 'Your number (country code required)'),
              helperText: trSi(isFr, 'FR (+33) par défaut, UK (+44) ou indicatif détecté par GPS', 'FR (+33) default, UK (+44) or GPS detected code'),
              onChanged: (val) => tempPhone = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(trSi(isFr, 'Annuler', 'Cancel')),
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
            child: Text(trSi(isFr, 'Enregistrer', 'Save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  content: Text(trSi(isFr, 'Ce numéro de téléphone est déjà associé à un autre compte.', 'This phone number is already associated with another account.')),
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
          avatarUrl: _avatarUrl,
        );
        setState(() => _phoneNumber = result.isNotEmpty ? result : null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(trSi(isFr, 'Numéro de téléphone mis à jour avec succès', 'Phone number updated successfully')),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    }
  }

  void _showLegalDialog(String title, String content) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
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
            child: Text(trSi(isFr, 'Fermer', 'Close')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    // Le résumé ; le détail (données, durées, destinataires) est sur le site (08/10).
    _showLegalDialog(
      trSi(isFr, 'Confidentialité', 'Privacy'),
      trSi(
          isFr,
          'Mise à jour : 8 octobre 2026\n\n'
              '• Chatmelier ne vend pas vos données.\n'
              '• Les photos d\'étiquettes et de cartes, un vin saisi par son nom et vos questions au sommelier sont analysés par l\'intelligence artificielle de Google (Gemini), depuis nos serveurs.\n'
              '• Votre palais vous suit : sur votre appareil, avec une copie que vous seul pouvez lire.\n'
              '• À une table, vos convives voient votre prénom et votre palais ; la table est effacée quelques heures après.\n'
              '• Une carte que vous scannez en disant où vous êtes est proposée aux membres qui passent au même endroit, sans photo ni rien qui vous désigne.\n'
              '• La localisation ne sert que pendant l\'utilisation, avec votre accord.\n'
              '• La base de données est hébergée à Paris (Supabase).\n\n'
              'Vos droits : Profil → Compte → « Télécharger mes données » et « Supprimer mon compte ». Responsable : Flavien Daussy, Londres. Contact : flavien.daussy@gmail.com\n\n'
              'Tout le détail : https://chatmelier.github.io/privacy.html',
          'Updated: October 8, 2026\n\n'
              '• Chatmelier does not sell your data.\n'
              '• Label and wine-list photos, a wine entered by its name and your questions to the sommelier are analysed by Google\'s artificial intelligence (Gemini), from our servers.\n'
              '• Your palate follows you: on your device, with a copy only you can read.\n'
              '• At a table, your guests see your first name and palate; the table is deleted a few hours later.\n'
              '• A wine list you scan while saying where you are is offered to members who come to the same place, without photos or anything identifying you.\n'
              '• Location is only used while you use the app, with your permission.\n'
              '• The database is hosted in Paris (Supabase).\n\n'
              'Your rights: Profile → Account → “Download my data” and “Delete my account”. Controller: Flavien Daussy, London. Contact: flavien.daussy@gmail.com\n\n'
              'Full details: https://chatmelier.github.io/privacy.html'),
    );
  }

  void _showTermsOfService() {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    _showLegalDialog(
      trSi(isFr, 'Conditions Générales d\'Utilisation', 'Terms of Service'),
      trSi(
          isFr,
          'En vigueur au 8 octobre 2026\n\n'
              '1. LE SERVICE\n'
              'Chatmelier gère votre cave, votre journal de dégustation et votre palais, et vous aide à choisir un vin, au restaurant ou chez vous, avec l\'aide de l\'intelligence artificielle.\n\n'
              '2. ÂGE ET SANTÉ\n'
              'Chatmelier est réservé aux personnes qui ont l\'âge légal de consommer de l\'alcool dans leur pays. L\'abus d\'alcool est dangereux pour la santé, à consommer avec modération.\n\n'
              '3. CE QUE DIT L\'INTELLIGENCE ARTIFICIELLE\n'
              'Apogées, accords et commentaires sont indicatifs. Quand Chatmelier ne reconnaît pas un vin avec certitude, il le dit plutôt que de deviner ; vérifiez avant de vous y fier.\n\n'
              '4. CE QUE VOUS PARTAGEZ\n'
              'Vous restez propriétaire de vos photos et de vos notes. Une carte des vins que vous scannez en indiquant le lieu est proposée aux autres membres qui s\'y trouvent, sans rien qui vous désigne.\n\n'
              '5. VOTRE COMPTE\n'
              'Vous pouvez télécharger vos données et supprimer votre compte à tout moment, depuis Profil → Compte.\n\n'
              'Texte complet : https://chatmelier.github.io/terms.html',
          'Effective as of October 8, 2026\n\n'
              '1. THE SERVICE\n'
              'Chatmelier manages your cellar, tasting journal and palate, and helps you choose a wine, out or at home, with the help of artificial intelligence.\n\n'
              '2. AGE AND HEALTH\n'
              'Chatmelier is for people of legal drinking age in their country. Alcohol abuse is dangerous for your health. Drink responsibly.\n\n'
              '3. WHAT THE ARTIFICIAL INTELLIGENCE SAYS\n'
              'Drinking windows, pairings and comments are indicative. When Chatmelier cannot recognise a wine with certainty, it says so rather than guessing; check before relying on it.\n\n'
              '4. WHAT YOU SHARE\n'
              'You remain the owner of your photos and notes. A wine list you scan while giving the place is offered to other members who are there, without anything identifying you.\n\n'
              '5. YOUR ACCOUNT\n'
              'You can download your data and delete your account at any time, from Profile → Account.\n\n'
              'Full text: https://chatmelier.github.io/terms.html'),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
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
                  trSi(isFr, 'Supprimer mon compte ?', 'Delete my account?'),
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
                trSi(isFr, 'Cette action est irréversible et immédiate.\n\n' 'Toutes vos données seront définitivement effacées :\n' '• Vos caves, casiers et bouteilles\n' '• Vos photos et vos notes de dégustation\n' '• Votre profil et votre historique de discussion', 'This action is irreversible and immediate.\n\n' 'All your data will be permanently deleted:\n' '• Your cellars, racks and bottles\n' '• Your photos and tasting notes\n' '• Your profile and chat history'),
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                trSi(isFr, 'Pour confirmer, tapez SUPPRIMER ci-dessous :', 'To confirm, type DELETE below:'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: trSi(isFr, 'SUPPRIMER', 'DELETE'),
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
              child: Text(trSi(isFr, 'Annuler', 'Cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: canDelete ? () => Navigator.of(ctx).pop(true) : null,
              child: Text(trSi(isFr, 'Supprimer définitivement', 'Permanently delete'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  Text(trSi(isFr, 'Suppression du compte et des données...', 'Deleting account and data...')),
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
              content: Text(trSi(isFr, 'Votre compte et vos données ont été définitivement supprimés.', 'Your account and data have been permanently deleted.')),
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
              content: Text(trSi(isFr, 'Erreur lors de la suppression : {e}', 'Error during deletion: {e}', {'e': e})),
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
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    final resolvedDisplayName = _displayName.isNotEmpty
        ? _displayName
        : (user?.userMetadata?['display_name'] as String? ?? (trSi(isFr, 'Amateur de Vin', 'Wine Lover')));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n?.profileTitle ?? (trSi(isFr, 'Profil & Réglages', 'Profile & Settings'))),
          actions: const [
            BoutonSommelier(),
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
                      GestureDetector(
                        onTap: user == null ? null : _showAvatarPickerSheet,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            OwnerAvatar(
                              userId: user?.id ?? '',
                              avatarUrl: _avatarUrl,
                              radius: 24,
                            ),
                            if (user != null)
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (_isUploadingAvatar)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
                                  : (user?.email ?? (trSi(isFr, 'Mode Invité', 'Guest Mode'))),
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
                          child: Text(trSi(isFr, 'Connexion', 'Sign in'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                      text: l10n?.profileTabPalate ?? (trSi(isFr, 'Palais', 'Palate')),
                    ),
                    Tab(
                      icon: const Icon(Icons.tune, size: 20),
                      text: l10n?.profileTabSettings ?? (trSi(isFr, 'Réglages', 'Settings')),
                    ),
                    Tab(
                      icon: const Icon(Icons.inventory_2_outlined, size: 20),
                      text: l10n?.profileTabTools ?? (trSi(isFr, 'Outils', 'Tools')),
                    ),
                    Tab(
                      icon: const Icon(Icons.shield_outlined, size: 20),
                      text: l10n?.profileTabAccount ?? (trSi(isFr, 'Compte', 'Account')),
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
          name: trSi(isFr, 'Moi', 'Me'),
          isPrimary: true,
          favoriteTypes: const [],
          favoriteRegions: const [],
          favoriteGrapes: const [],
          dislikedCharacteristics: const [],
          notes: '',
        );
    // Même effet de bord que sur l'écran du radar plein écran : c'est ici qu'on atterrit,
    // donc c'est ici que l'inventaire de cave doit être à jour avant le dessin.
    ref.watch(cellarGrapeSyncProvider);
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
                          Text(trSi(isFr, 'Radar des Goûts', 'Taste Radar'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(trSi(isFr, 'Empreinte œnologique & équilibre des saveurs', 'Oenological footprint & flavor balance'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    // L'empreinte en image : l'objet qui circule (P5).
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: trSi(isFr, 'Partager mon empreinte', 'Share my palate'),
                      icon: const Icon(Icons.ios_share, size: 19, color: Color(0xFF8B1E3F)),
                      onPressed: () => PartageEmpreinteSheet.show(
                        context,
                        profil: currentProfile,
                        nom: _displayName.isNotEmpty ? _displayName : null,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onPressed: () => TasteProfileRadarScreen.show(context),
                      icon: const Icon(Icons.fullscreen, size: 15),
                      label: Text(trSi(isFr, 'Plein écran', 'Fullscreen'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                            label: _displayName.isNotEmpty ? _displayName : (trSi(isFr, 'Mes Goûts', 'My Taste')),
                            color: const Color(0xFF8B1E3F),
                            metrics: metrics,
                            confidences: TasteProfile.axisKeys
                                .map(currentProfile.axisConfidence)
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const LegendeDuRadar(),
                const SizedBox(height: 8),

                _buildConfidenceLine(theme, currentProfile),
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
                    _tasteProfileSummary(Localizations.localeOf(context).languageCode),
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
                        label: Text(trSi(isFr, 'Invités / Proches', 'Guests / Friends'), style: const TextStyle(fontSize: 11.5)),
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
                        label: Text(trSi(isFr, 'Personnaliser', 'Customize'), style: const TextStyle(fontSize: 11.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 🗺️ LES TERROIRS GOÛTÉS, EN CAVE, À EXPLORER (V2.3 · J3)
        CarteDesTerroirsCard(profil: currentProfile),

        // 📊 STATISTIQUES DE CAVE & ANALYSES
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFF8B1E3F).withValues(alpha: 0.35), width: 1.5),
          ),
          color: isDark ? const Color(0xFF201724) : const Color(0xFFFAF5F8),
          child: InkWell(
            onTap: () => context.push('/stats'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insights, color: Color(0xFF8B1E3F), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trSi(isFr, 'Statistiques de la Cave 📊', 'Cellar & Tasting Analytics 📊'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trSi(isFr, 'Répartition par couleur, régions, valeur patrimoniale, apogée', 'Color breakdown, regions, total asset value, peak windows'),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8B1E3F)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 1 : RÉGLAGES (ZERO SCROLL)
  // =========================================================================
  Widget _buildSettingsTab(BuildContext context, ThemeData theme, bool isDark, bool isFr) {
    final l10n = AppLocalizations.of(context);
    final userLocale = ref.watch(localeProvider);
    final currentLangValue =
        userLocale == null || !kSupportedLanguageCodes.contains(userLocale.languageCode) ? 'system' : userLocale.languageCode;

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
                l10n?.profileLanguage ?? (trSi(isFr, 'Langue de l\'application', 'Application Language')),
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
                      child: Text(l10n?.profileLanguageSystem ?? (trSi(isFr, 'Système 🌐', 'System 🌐')), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    for (final langue in kLangues)
                      DropdownMenuItem(
                        value: langue.code,
                        child: Text(langue.nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                          content: Text(l10n?.profileLanguageUpdated ?? (trSi(isFr, 'Langue modifiée avec succès', 'Language updated successfully'))),
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
                l10n?.profileDefaultCurrency ?? (trSi(isFr, 'Devise par défaut', 'Default Currency')),
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
                l10n?.profileTheme ?? (trSi(isFr, 'Ambiance / Thème', 'Appearance / Theme')),
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
                      child: Text(l10n?.profileThemeSystem ?? (trSi(isFr, 'Système ⚙️', 'System ⚙️')), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n?.profileThemeLight ?? (trSi(isFr, 'Lumineux ☀️', 'Light ☀️')), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n?.profileThemeDark ?? (trSi(isFr, 'Sombre 🕯️', 'Dark 🕯️')), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
          title: Text(trSi(isFr, 'Notifications & Alertes Système 🔔', 'Notifications & System Alerts 🔔'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            _alertesActives(ref.watch(notificationPreferencesProvider).activeCount, isFr),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => NotificationSettingsSheet.show(context),
        ),

        // RGPD Consent options (le séparateur vient avec : sans elles, aucun espace vide)
        if (_showPrivacyOptions) ...[
          const Divider(height: 28),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune, color: Color(0xFFD4AF37)),
            title: Text(trSi(isFr, 'Préférences Publicitaires & RGPD', 'Ad Preferences & Privacy'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(trSi(isFr, 'Modifier mes choix de consentement publicitaire', 'Manage your advertising consent choices'), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(admobServiceProvider).showPrivacyOptionsForm(),
          ),
        ],
      ],
    );
  }

  /// « 1 alerte active », « 3 alertes actives » : en français, zéro est au singulier.
  static String _alertesActives(int n, bool isFr) {
    final un = isFr ? n <= 1 : n == 1;
    return un
        ? trSi(isFr, '{n} alerte active • Dégustations, apogées, caves', '{n} active alert • Tastings, aging peaks, cellars', {'n': n})
        : trSi(isFr, '{n} alertes actives • Dégustations, apogées, caves', '{n} active alerts • Tastings, aging peaks, cellars', {'n': n});
  }

  // =========================================================================
  // TAB 2 : OUTILS & DONNÉES (ZERO SCROLL)
  // =========================================================================
  Widget _buildToolsTab(BuildContext context, ThemeData theme, bool isDark, bool isFr) {
    // Statut admin décidé par le serveur (profiles.is_admin, migration 029).
    // Ferme par défaut pendant le chargement et en cas d'erreur.
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insights, color: Color(0xFF8B1E3F)),
          title: Text(trSi(isFr, 'Statistiques de Cave & Analyses 📊', 'Cellar Analytics & Insights 📊'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(trSi(isFr, 'Graphiques, apogées, valeurs financières et stocks', 'Charts, aging peaks, financial valuation and stock'), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/stats'),
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.people_alt, color: Color(0xFFD4AF37)),
          title: Text(trSi(isFr, 'Mes Amis & Cartes des Goûts 🍷', 'My Friends & Taste Maps 🍷'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(trSi(isFr, 'Boire ensemble, recherche @pseudo, cartes partagées', 'Drink together, search @username, shared maps'), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/friends'),
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.file_download_outlined, color: Color(0xFF2E7D32)),
          title: Text(trSi(isFr, 'Exporter ma cave', 'Export my cellar'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(trSi(isFr, 'Excel / CSV, et un inventaire à valeurs indicatives', 'Excel / CSV, and an inventory with indicative values'), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final cellars = ref.read(userCellarsProvider).value ?? [];
            final name = cellars.isNotEmpty ? (cellars.first['cellars']?['name'] ?? (trSi(isFr, 'Ma Cave', 'My Cellar'))) : (trSi(isFr, 'Ma Cave', 'My Cellar'));
            CellarExportDialog.show(context, name);
          },
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.file_upload_outlined, color: Color(0xFF1B5E20)),
          title: Text(trSi(isFr, 'Importer une Cave (Excel / CSV / Texte)', 'Import a Cellar (Excel / CSV / Text)'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(trSi(isFr, 'Import instantané intelligent par IA sommelier', 'Instant smart import powered by AI sommelier'), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final currentCellarId = ref.read(currentCellarIdProvider);
            context.push('/cellar/import-excel?cellarId=${currentCellarId ?? ""}');
          },
        ),
        const Divider(height: 12),



        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.feedback_outlined, color: Colors.orange),
          title: Text(trSi(isFr, 'Signaler un bug / Commenter', 'Report a Bug / Feedback'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(trSi(isFr, 'Secouer le téléphone ou cliquer ici pour annoter', 'Shake phone or tap here to annotate'), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ShakeFeedbackService.instance.triggerFeedback(context),
        ),

        // N'apparaît qu'à qui a déjà envoyé quelque chose : personne ne doit découvrir un
        // écran vide pour une fonctionnalité qu'il n'a jamais utilisée.
        Consumer(builder: (context, ref, _) {
          // `valueOrNull` et non `value` : sur une erreur (hors ligne, session absente)
          // `value` relance l'exception et emporterait tout l'onglet avec elle. Ne rien
          // proposer vaut mieux qu'un écran blanc.
          final retours = ref.watch(mesRetoursProvider).valueOrNull ?? const [];
          if (retours.isEmpty) return const SizedBox.shrink();
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_outlined, color: Colors.orange),
            title: Text(trSi(isFr, 'Mes retours envoyés', 'My sent reports'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              retours.length > 1
                  ? trSi(isFr, '{n} envoyés · à retirer si vous le souhaitez', '{n} sent · withdraw them if you wish', {'n': retours.length})
                  : trSi(isFr, '{n} envoyé · à retirer si vous le souhaitez', '{n} sent · withdraw it if you wish', {'n': retours.length}),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => MesRetoursSheet.show(context),
          );
        }),

        if (isAdmin) ...[
          const Divider(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insights_rounded, color: Color(0xFF8B1E3F)),
            title: Text(trSi(isFr, 'Console', 'Console'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                trSi(isFr, 'Actifs par jour, ce qu\'ils font, répartitions', 'Daily actives, what they do, breakdowns'),
                style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/admin/console'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            title: Text(trSi(isFr, 'Estimation des Coûts IA (Gemini)', 'AI Cost Estimation (Gemini)'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(trSi(isFr, 'Suivi des tokens et dépenses All-Time', 'Token usage & all-time expenditure'), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ai-costs'),
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
  /// RGPD, articles 15 et 20 : la personne emporte ses données (V2.1 · 0.6, fait le 08/10).
  Future<void> _telechargerMesDonnees(bool isFr) async {
    final messager = ScaffoldMessenger.of(context);
    messager.showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(trSi(isFr, 'Préparation de vos données…', 'Preparing your data…')),
    ));
    try {
      final manquants = await ref.read(exportDesDonneesProvider).partager();
      if (manquants > 0) {
        messager.showSnackBar(SnackBar(
          content: Text(trSi(isFr, 'Fichier prêt, mais {n} partie(s) n\'ont pas pu être lues : le fichier les nomme.',
              'File ready, but {n} part(s) could not be read: the file lists them.', {'n': manquants})),
        ));
      }
    } catch (e) {
      AppLogger.error('EXPORT_DONNEES', 'Export impossible', e);
      messager.showSnackBar(SnackBar(
        content: Text(trSi(isFr, 'Export impossible pour l\'instant : vérifiez la connexion et réessayez.',
            'Export failed for now: check your connection and try again.')),
      ));
    }
  }

  Widget _buildAccountTab(BuildContext context, ThemeData theme, bool isDark, bool isFr) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);
    final isPremium = ref.watch(premiumProvider);
    // Statut admin décidé par le serveur (profiles.is_admin, migration 029).
    // Ferme par défaut pendant le chargement et en cas d'erreur.
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

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
                          ? (trSi(isFr, '👑 Mode Premium (Admin actif)', '👑 Premium Mode (Admin active)'))
                          : (trSi(isFr, 'Mode Standard (Gratuit)', 'Standard Mode (Free)')),
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
          title: Text(trSi(isFr, 'Pseudo unique', 'Unique Username'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            _username != null && _username!.isNotEmpty ? '@$_username' : (trSi(isFr, 'Non défini', 'Not set')),
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
          title: Text(l10n?.profileDisplayName ?? (trSi(isFr, 'Nom d\'affichage', 'Display Name')), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(_displayName.isNotEmpty ? _displayName : (user?.userMetadata?['display_name'] ?? (trSi(isFr, 'Utilisateur', 'User'))), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.edit, size: 16),
          onTap: _editDisplayName,
        ),
        const Divider(height: 8),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone_outlined, color: Color(0xFF8B1E3F)),
          title: Text(trSi(isFr, 'Numéro de téléphone', 'Phone Number'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            _phoneNumber != null && _phoneNumber!.isNotEmpty
                ? '${PhoneDialCodeHelper.parseExisting(_phoneNumber).$1.flag} $_phoneNumber'
                : (trSi(isFr, 'Non renseigné', 'Not set')),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.edit, size: 16),
          onTap: _editPhoneNumber,
        ),
        const Divider(height: 8),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.email_outlined),
          title: Text(l10n?.profileEmail ?? (trSi(isFr, 'Email', 'Email')), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(user?.email ?? (trSi(isFr, 'Non renseigné (Mode Invité)', 'Not set (Guest Mode)')), style: const TextStyle(fontSize: 12)),
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF8B1E3F)),
          title: Text(trSi(isFr, 'Politique de Confidentialité', 'Privacy Policy'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: _showPrivacyPolicy,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined, color: Color(0xFF8B1E3F)),
          title: Text(trSi(isFr, 'Conditions Générales d\'Utilisation', 'Terms of Service'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: _showTermsOfService,
        ),
        const Divider(height: 12),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout),
          title: Text(l10n?.profileLogout ?? (trSi(isFr, 'Se déconnecter', 'Log out')), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          onTap: () async {
            AppLogger.info('AUTH', 'User requested sign out from ProfileScreen');
            // Lu AVANT la déconnexion : elle déclenche la redirection du routeur, l'écran est
            // démonté pendant l'attente, et `ref` n'est plus utilisable après (18/09).
            final caveCourante = ref.read(currentCellarIdProvider.notifier);
            try {
              await ref.read(authRepositoryProvider).signOut();
            } catch (e) {
              AppLogger.error('AUTH', 'Error during signOut', e);
            }
            caveCourante.state = null;
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.download_outlined, color: Color(0xFF8B1E3F)),
          title: Text(trSi(isFr, 'Télécharger mes données', 'Download my data'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
              trSi(isFr, 'Compte, caves, dégustations, palais et conversations, en un fichier', 'Account, cellars, tastings, palate and conversations, in one file'),
              style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _telechargerMesDonnees(isFr),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(trSi(isFr, 'Supprimer mon compte', 'Delete my account'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, color: Colors.red, size: 18),
          onTap: _confirmDeleteAccount,
        ),
        const SizedBox(height: 8),

        AboutListTile(
          applicationName: 'Chatmelier',
          // La version du build, pas un numéro écrit en dur : « 1.2.1 » s'affichait pour
          // tout le monde, quelle que soit la version installée (V2.4 · K10).
          applicationVersion: versionApp,
          applicationIcon: Image.asset(
            'assets/images/logo_transparent_64.png',
            width: 36,
            height: 36,
          ),
          // Ni « conforme RGPD » ni « conforme aux règles des magasins » : rien ne le prouve. L'éditeur, oui.
          applicationLegalese: trSi(isFr, '© 2026 Chatmelier\nÉdité par Flavien Daussy, Londres', '© 2026 Chatmelier\nPublished by Flavien Daussy, London'),
          icon: const Icon(Icons.info_outline, size: 20),
        ),
      ],
    );
  }
}
