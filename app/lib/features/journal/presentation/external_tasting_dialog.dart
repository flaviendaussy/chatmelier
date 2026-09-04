import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../config/router.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/services/cellar_location_service.dart';
import '../../../shared/services/nearby_places_service.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/widgets/bottle_image_view.dart';
import '../../offline/domain/offline_action.dart';
import '../../offline/presentation/sync_provider.dart';
import '../../scan/data/scan_service.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../cellar/domain/wine.dart';
import 'journal_screen.dart';
import 'tasting_questionnaire_sheet.dart';

class ExternalTastingDialog extends ConsumerStatefulWidget {
  final String? initialWineName;
  final String? initialProducer;
  final int? initialVintage;
  final String? initialRegion;
  final String? initialAppellation;
  final String? initialType;
  final String? photoUrl;

  const ExternalTastingDialog({
    super.key,
    this.initialWineName,
    this.initialProducer,
    this.initialVintage,
    this.initialRegion,
    this.initialAppellation,
    this.initialType,
    this.photoUrl,
  });

  static Future<void> show(
    BuildContext context, {
    String? wineName,
    String? producer,
    int? vintage,
    String? region,
    String? appellation,
    String? wineType,
    String? photoUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExternalTastingDialog(
        initialWineName: wineName,
        initialProducer: producer,
        initialVintage: vintage,
        initialRegion: region,
        initialAppellation: appellation,
        initialType: wineType,
        photoUrl: photoUrl,
      ),
    );
  }

  @override
  ConsumerState<ExternalTastingDialog> createState() => _ExternalTastingDialogState();
}

class _ExternalTastingDialogState extends ConsumerState<ExternalTastingDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _producerController;
  late final TextEditingController _vintageController;
  late final TextEditingController _regionController;
  late final TextEditingController _contextController;
  late final TextEditingController _notesController;
  late final TextEditingController _foodController;

  String _wineType = 'red';
  double _rating = 8.5;
  bool _isFavorite = false;
  bool _isSaving = false;

  // Friends & Co-tasters
  List<Friend> _friends = [];
  List<TasteProfile> _companionProfiles = [];
  final Set<String> _selectedCoTasters = {};

  Future<void> _showAddCompanionDialog() async {
    final nameCtrl = TextEditingController();
    try {
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF8B1E3F)),
              SizedBox(width: 8),
              Text('Ajouter un convive'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajoutez un proche présent à cette dégustation hors cave (ex: Papa, Maman, Sophie...).',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Prénom / Nom',
                  hintText: 'ex: Papa',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
              onPressed: () {
                final text = nameCtrl.text.trim();
                if (text.isNotEmpty) Navigator.pop(ctx, text);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      );

      if (newName != null && newName.isNotEmpty) {
        final service = ref.read(tasteProfileServiceProvider);
        await service.addOrGetProfileByName(newName);
        final fresh = await service.getProfiles();
        ref.invalidate(tasteProfilesListProvider);
        if (mounted) {
          setState(() {
            _companionProfiles = fresh;
            _selectedCoTasters.add(newName);
          });
        }
      }
    } finally {
      nameCtrl.dispose();
    }
  }

  // Nearby & Custom Places Discovery
  Position? _currentPosition;
  List<NearbyPlace> _nearbyPlaces = [];
  bool _isLoadingPlaces = true;
  bool _rememberThisPlace = true;
  NearbyPlace? _selectedPlace;
  bool _showCustomPlaceInput = false;
  String? _photoUrl;
  bool _isScanningPhoto = false;
  bool _isQuickAnalyzing = false;
  late final TextEditingController _quickSearchController;

  String _normalizeWineType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('blanc') || lower == 'white') return 'white';
    if (lower.contains('ros') || lower == 'rosé') return 'rose';
    if (lower.contains('sparkling') || lower.contains('champ') || lower.contains('bulles') || lower.contains('effervescent')) return 'sparkling';
    if (lower.contains('dessert') || lower.contains('moelleux') || lower.contains('liquoreux')) return 'dessert';
    return 'red';
  }

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.photoUrl;
    _quickSearchController = TextEditingController();
    _nameController = TextEditingController(text: widget.initialWineName ?? '');
    _producerController = TextEditingController(text: widget.initialProducer ?? '');
    _vintageController = TextEditingController(text: widget.initialVintage != null ? '${widget.initialVintage}' : '');
    _regionController = TextEditingController(text: widget.initialRegion ?? widget.initialAppellation ?? '');
    _contextController = TextEditingController();
    _notesController = TextEditingController();
    _foodController = TextEditingController();
    if (widget.initialType != null) {
      _wineType = widget.initialType!;
    }

    _detectNearbyPlaces();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      
      setState(() {
        _photoUrl = picked.path;
        _isScanningPhoto = true;
      });

      final supabase = ref.read(supabaseProvider);
      final scanService = ScanService(supabase);
      final bytes = await picked.readAsBytes();

      // 1. Automatic Gemini Vision OCR & Enology Extraction
      try {
        final result = await scanService.analyzeBottleImage(
          imagePath: picked.path,
          imageBytes: bytes,
        );
        if (mounted) {
          setState(() {
            _nameController.text = result.name;
            if (result.producer != null && result.producer!.isNotEmpty) {
              _producerController.text = result.producer!;
            }
            if (result.vintage != null) {
              _vintageController.text = '${result.vintage}';
            }
            if (result.appellation != null && result.appellation!.isNotEmpty) {
              _regionController.text = result.appellation!;
            } else if (result.region.isNotEmpty) {
              _regionController.text = result.region;
            }
            _wineType = _normalizeWineType(result.wineType);
            if (result.tastingNotes != null && result.tastingNotes!.isNotEmpty) {
              _notesController.text = result.tastingNotes!;
            }
            if (result.foodPairings.isNotEmpty) {
              _foodController.text = result.foodPairings.first;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ Bouteille reconnue par l\'IA : ${result.name}'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } catch (scanErr) {
        AppLogger.warning('EXTERNAL_TASTING', 'AI photo scan error: $scanErr');
      } finally {
        if (mounted) setState(() => _isScanningPhoto = false);
      }

      // 2. Upload photo in background
      try {
        final publicUrl = await scanService.uploadPhoto(
          bottleId: const Uuid().v4(),
          imagePath: picked.path,
          imageBytes: bytes,
        );
        if (publicUrl != null && mounted) {
          setState(() => _photoUrl = publicUrl);
        }
      } catch (e) {
        debugPrint('Photo upload notice: $e');
      }
    } catch (e) {
      if (mounted) setState(() => _isScanningPhoto = false);
      debugPrint('Error picking photo: $e');
    }
  }

  Future<void> _quickAnalyzeFromText() async {
    final text = _quickSearchController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isQuickAnalyzing = true);
    FocusScope.of(context).unfocus();

    try {
      final supabase = ref.read(supabaseProvider);
      final scanService = ScanService(supabase);
      final result = await scanService.analyzeWineFromText(text);

      if (mounted) {
        setState(() {
          _nameController.text = result.name;
          if (result.producer != null && result.producer!.isNotEmpty) {
            _producerController.text = result.producer!;
          }
          if (result.vintage != null) {
            _vintageController.text = '${result.vintage}';
          }
          if (result.appellation != null && result.appellation!.isNotEmpty) {
            _regionController.text = result.appellation!;
          } else if (result.region.isNotEmpty) {
            _regionController.text = result.region;
          }
          _wineType = _normalizeWineType(result.wineType);
          if (result.tastingNotes != null && result.tastingNotes!.isNotEmpty) {
            _notesController.text = result.tastingNotes!;
          }
          if (result.foodPairings.isNotEmpty) {
            _foodController.text = result.foodPairings.first;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Fiche complétée par l\'IA : ${result.name}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      AppLogger.warning('EXTERNAL_TASTING', 'Quick text analysis error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'analyse : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isQuickAnalyzing = false);
    }
  }

  Future<void> _detectNearbyPlaces() async {
    try {
      final friends = await ref.read(friendsRepositoryProvider).getFriends();
      final companionProfiles = await ref.read(tasteProfileServiceProvider).getProfiles();
      if (mounted) {
        setState(() {
          _friends = friends;
          _companionProfiles = companionProfiles;
        });
      }

      final pos = await CellarLocationService.getCurrentPosition();
      if (!mounted) return;
      _currentPosition = pos;

      final places = await ref.read(nearbyPlacesServiceProvider).getNearbyPlaces(
            latitude: pos?.latitude,
            longitude: pos?.longitude,
          );

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places;
        _isLoadingPlaces = false;

        // Auto-select matched custom place or very close place
        if (places.isNotEmpty) {
          final top = places.first;
          if (top.isCustom || (top.distanceMeters != null && top.distanceMeters! <= 80)) {
            _selectedPlace = top;
            _contextController.text = top.name;
          } else {
            _contextController.text = 'Au restaurant';
          }
        } else {
          _showCustomPlaceInput = true;
          _contextController.text = '';
        }
      });
    } catch (e) {
      AppLogger.warning('EXTERNAL_TASTING', 'Could not detect nearby places: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
          _showCustomPlaceInput = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _quickSearchController.dispose();
    _nameController.dispose();
    _producerController.dispose();
    _vintageController.dispose();
    _regionController.dispose();
    _contextController.dispose();
    _notesController.dispose();
    _foodController.dispose();
    super.dispose();
  }

  Future<void> _saveTasting() async {
    final wineName = _nameController.text.trim();
    if (wineName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer au moins le nom du vin.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final supabase = ref.read(supabaseProvider);
    final offlineStorage = ref.read(offlineStorageServiceProvider);
    final user = supabase.auth.currentUser;

    final vintage = int.tryParse(_vintageController.text.trim());
    final producer = _producerController.text.trim();
    final region = _regionController.text.trim();
    final occasion = _contextController.text.trim();
    final notes = _notesController.text.trim();
    final food = _foodController.text.trim();
    final effectiveRating = _isFavorite ? 5.0 : _rating;

    // 1. If user checked to remember this place & we have a location, save it!
    if (_rememberThisPlace && occasion.isNotEmpty && _currentPosition != null) {
      try {
        await ref.read(nearbyPlacesServiceProvider).rememberPlace(
              name: occasion,
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
            );
        AppLogger.info('EXTERNAL_TASTING', 'Remembered place: "$occasion"');
      } catch (e) {
        AppLogger.warning('EXTERNAL_TASTING', 'Could not save custom place: $e');
      }
    }

    final wineId = const Uuid().v4();
    final tastingId = const Uuid().v4();

    try {
      bool savedOnline = false;
      if (user != null) {
        // Create wine record in database
        try {
          await supabase.from('wines').insert({
            'id': wineId,
            'name': wineName,
            'producer': producer.isNotEmpty ? producer : null,
            'vintage': vintage,
            'type': _wineType,
            'region': region.isNotEmpty ? region : 'Autre',
            'image_url': _photoUrl,
          });
        } catch (e) {
          AppLogger.warning('EXTERNAL_TASTING', 'Could not insert standalone wine: $e');
        }

        // Insert into tasting_log
        try {
          await supabase.from('tasting_log').insert({
            'id': tastingId,
            'wine_id': wineId,
            'user_id': user.id,
            'rating': effectiveRating,
            'occasion': occasion.isNotEmpty ? occasion : 'Dégustation hors cave',
            'food_paired': food.isNotEmpty ? food : null,
            'tasting_notes': notes.isNotEmpty ? notes : null,
            'photo_url': _photoUrl,
            'co_tasters': _selectedCoTasters.toList(),
            'location_name': occasion.isNotEmpty ? occasion : null,
            'is_external': true,
            'consumed_at': DateTime.now().toIso8601String(),
          });
          savedOnline = true;
        } catch (e) {
          AppLogger.warning('EXTERNAL_TASTING', 'Could not save online, queueing offline: $e');
          savedOnline = false;
        }
      }

    // Only queue offline action if online insert failed
    if (!savedOnline) {
      await offlineStorage.queueAction(OfflineAction(
        id: tastingId,
        type: OfflineActionType.consumeBottle,
        status: OfflineActionStatus.pending,
        data: {
          'tasting_id': tastingId,
          'wine_id': wineId,
          'wine_name': wineName,
          'producer': producer,
          'vintage': vintage,
          'region': region,
          'type': _wineType,
          'rating': effectiveRating,
          'occasion': occasion,
          'food_paired': food,
          'tasting_notes': notes,
          'photo_url': widget.photoUrl,
          'co_tasters': _selectedCoTasters.toList(),
          'location_name': occasion.isNotEmpty ? occasion : null,
          'is_external': true,
        },
        createdAt: DateTime.now(),
      ));
    }

      // Invalidate tasting log
      ref.invalidate(tastingLogProvider);

      // Reinforce taste profiles for primary user and co-tasters
      try {
        final standaloneWine = Wine(
          id: wineId,
          name: wineName,
          producer: producer,
          vintage: vintage,
          region: region,
          country: 'France',
          type: _wineType,
          imageUrl: _photoUrl,
        );
        final tasteService = ref.read(tasteProfileServiceProvider);
        await tasteService.recordTastingExperience(
          nameOrId: 'primary',
          wine: standaloneWine,
          rating: effectiveRating,
        );
        for (final coTaster in _selectedCoTasters) {
          await tasteService.recordTastingExperience(
            nameOrId: coTaster,
            wine: standaloneWine,
            rating: effectiveRating,
          );
        }
        ref.invalidate(tasteProfilesListProvider);
      } catch (e) {
        debugPrint('External tasting profile update notice: $e');
      }

      if (mounted) {
        Navigator.pop(context);

        // Offer immediate questionnaire via rootContext or snackbar
        final targetCtx = rootNavigatorKey.currentContext;
        if (targetCtx != null && targetCtx.mounted) {
          TastingQuestionnaireSheet.show(
            targetCtx,
            wineName: wineName,
            vintage: vintage,
            producer: producer.isNotEmpty ? producer : null,
            region: region.isNotEmpty ? region : null,
            wineType: _wineType,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Text('🍷 ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      'Dégustation hors cave enregistrée ! Le Chatmelier s\'en souviendra.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF8B1E3F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.error('EXTERNAL_TASTING', 'Error saving tasting', e, stack);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dégustation Hors-Cave',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Restaurant, bar, chez des amis... sans modifier vos stocks',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // =================================================================
            // LIEU & GÉOLOCALISATION INTELLIGENTE (Chez Dimitri, Resto, etc.)
            // =================================================================
            _buildLocationSection(theme, isDark),
            const SizedBox(height: 16),

            // Convives, Famille & Amis Co-dégustateurs
            Row(
              children: [
                const Icon(Icons.people_alt, color: Color(0xFF8B1E3F), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Avec qui dégustez-vous ce vin ?',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: _showAddCompanionDialog,
                  icon: const Icon(Icons.person_add, size: 15, color: Color(0xFF8B1E3F)),
                  label: const Text(
                    '+ Ajouter un convive',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Les goûts de chaque participant seront automatiquement enregistrés dans son profil.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Companion / Family profiles (excluding primary "Moi")
                ..._companionProfiles.where((p) => !p.isPrimary).map((p) {
                  final isSelected = _selectedCoTasters.contains(p.name);
                  return FilterChip(
                    avatar: CircleAvatar(
                      backgroundColor: const Color(0xFFD4AF37),
                      radius: 10,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    label: Text(p.name),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.18),
                    checkmarkColor: const Color(0xFF8B1E3F),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF8B1E3F) : null,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCoTasters.add(p.name);
                        } else {
                          _selectedCoTasters.remove(p.name);
                        }
                      });
                    },
                  );
                }),
                // Registered Friends
                ..._friends.where((f) => !_companionProfiles.any((p) => p.name.toLowerCase() == f.displayName.toLowerCase())).map((f) {
                  final isSelected = _selectedCoTasters.contains(f.displayName);
                  return FilterChip(
                    avatar: const Text('🍷', style: TextStyle(fontSize: 13)),
                    label: Text('${f.displayName} (${f.handle})'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.18),
                    checkmarkColor: const Color(0xFF8B1E3F),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF8B1E3F) : null,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCoTasters.add(f.displayName);
                        } else {
                          _selectedCoTasters.remove(f.displayName);
                        }
                      });
                    },
                  );
                }),
                // Quick add ActionChip
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: Color(0xFF8B1E3F)),
                  label: const Text('Ajouter (Papa, Maman...)'),
                  onPressed: _showAddCompanionDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // =================================================================
            // PHOTO DE LA BOUTEILLE (SCAN / APPAREIL / GALERIE)
            // =================================================================
            _buildPhotoSection(theme, isDark),
            const SizedBox(height: 16),

            // =================================================================
            // RECONNAISSANCE IA RAPIDE (ARDOISE BAR / TEXTE / LISTE)
            // =================================================================
            _buildQuickAiSearchSection(theme, isDark),
            const SizedBox(height: 16),

            // Nom du vin & Millésime
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du Vin *',
                      hintText: 'Ex: Domaine de Terrebrune',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _vintageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Millésime',
                      hintText: '2019',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Domaine & Région
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _producerController,
                    decoration: InputDecoration(
                      labelText: 'Domaine / Producteur',
                      hintText: 'Ex: Famille Delon',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _regionController,
                    decoration: InputDecoration(
                      labelText: 'Région / Appellation',
                      hintText: 'Ex: Bandol Rouge',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Type / Couleur de vin
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip('Rouge 🍷', 'red'),
                _buildTypeChip('Blanc 🥂', 'white'),
                _buildTypeChip('Rosé 🌸', 'rose'),
                _buildTypeChip('Bulles ✨', 'sparkling'),
                _buildTypeChip('Liquoreux 🍯', 'dessert'),
              ],
            ),
            const SizedBox(height: 16),

            // Note et Coup de Cœur sur 10
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Note de dégustation :', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_rating.toStringAsFixed(1)} / 10',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.grey,
                          size: 16,
                        ),
                        label: const Text('Coup de cœur', style: TextStyle(fontSize: 12)),
                        selected: _isFavorite,
                        selectedColor: Colors.red.withValues(alpha: 0.15),
                        onSelected: (val) => setState(() => _isFavorite = val),
                      ),
                    ],
                  ),
                  Slider(
                    value: _rating,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    activeColor: const Color(0xFFD4AF37),
                    label: '${_rating.toStringAsFixed(1)} / 10',
                    onChanged: (val) => setState(() => _rating = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Plat dégusté avec
            TextField(
              controller: _foodController,
              decoration: InputDecoration(
                labelText: 'Accord Met & Vin',
                hintText: 'Ex: Côte de bœuf grillée, Risotto aux cèpes...',
                prefixIcon: const Icon(Icons.dinner_dining, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Notes & Impressions
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Impressions & Arômes ressentis',
                hintText: 'Ex: Fruits noirs intenses, tanins soyeux, très belle longueur...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(
                      _isSaving ? 'Enregistrement...' : 'Enregistrer & Noter ✨',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSaving ? null : _saveTasting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // LOCATION & NEARBY SUGGESTIONS BUILDER
  // =========================================================================

  Widget _buildLocationSection(ThemeData theme, bool isDark) {
    if (_isLoadingPlaces) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B1E3F)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Recherche des restaurants, bars & amis autour de vous...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Detection Status
        Row(
          children: [
            const Icon(Icons.place, color: Color(0xFF8B1E3F), size: 18),
            const SizedBox(width: 6),
            Text(
              'Où dégustez-vous ce vin ?',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_currentPosition != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 10, color: Colors.green),
                    SizedBox(width: 4),
                    Text('GPS actif', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Matched Custom Place Highlight (e.g. "Chez Dimitri")
        if (_selectedPlace != null && _selectedPlace!.isCustom)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vous semblez être : ${_selectedPlace!.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
                      ),
                      const Text(
                        'Lieu favori mémorisé automatiquement par Chatmelier',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  tooltip: 'Changer de lieu',
                  onPressed: () {
                    setState(() {
                      _showCustomPlaceInput = true;
                      _selectedPlace = null;
                      _contextController.clear();
                    });
                  },
                ),
              ],
            ),
          ),

        // Horizontal scrolling chips of nearby restaurants/bars
        if (_nearbyPlaces.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._nearbyPlaces.map((place) {
                  final isSelected = _selectedPlace?.id == place.id ||
                      _contextController.text.trim().toLowerCase() == place.name.trim().toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Text(place.iconEmoji, style: const TextStyle(fontSize: 14)),
                      label: Text(
                        place.distanceMeters != null
                            ? '${place.name} (${place.distanceMeters! < 1000 ? "${place.distanceMeters!.round()}m" : "${(place.distanceMeters! / 1000).toStringAsFixed(1)}km"})'
                            : place.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF8B1E3F) : null,
                        ),
                      ),
                      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedPlace = place;
                            _contextController.text = place.name;
                            _showCustomPlaceInput = false;
                          }
                        });
                      },
                    ),
                  );
                }),
                // Button to enter custom friend place (e.g. Chez Dimitri)
                ActionChip(
                  avatar: const Icon(Icons.add_home, size: 16, color: Color(0xFF8B1E3F)),
                  label: const Text('Chez un ami / Autre lieu...', style: TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    setState(() {
                      _showCustomPlaceInput = true;
                      _selectedPlace = null;
                      _contextController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Custom Place Input when no resto found or user chooses custom
        if (_showCustomPlaceInput || _nearbyPlaces.isEmpty) ...[
          if (_nearbyPlaces.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Aucun restaurant détecté à proximité immédiate.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          TextField(
            controller: _contextController,
            decoration: InputDecoration(
              labelText: 'Chez qui ou où êtes-vous ? *',
              hintText: 'Ex: Chez Dimitri, Chez mes parents, Maison de campagne...',
              prefixIcon: const Icon(Icons.home_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) => setState(() {}),
          ),
          if (_currentPosition != null && _contextController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: _rememberThisPlace,
                    activeColor: const Color(0xFFD4AF37),
                    checkColor: Colors.black,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) => setState(() => _rememberThisPlace = val ?? true),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _rememberThisPlace = !_rememberThisPlace),
                      child: Text(
                        'Mémoriser "${_contextController.text.trim()}" à cette position GPS pour vos prochaines visites',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildQuickAiSearchSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201A29) : const Color(0xFFF7F4F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF8B1E3F), size: 16),
              const SizedBox(width: 6),
              const Text(
                'Identifier avec l\'IA (Bar, Restaurant, Ardoise)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const Spacer(),
              if (_isQuickAnalyzing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B1E3F)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Entrez quelques mots (ex: "Saint-Joseph Coursodon 2021" ou "Bandol Terrebrune") pour pré-remplir la fiche.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quickSearchController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Saint-Joseph 2021 Coursodon...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (_) => _quickAnalyzeFromText(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _isQuickAnalyzing ? null : _quickAnalyzeFromText,
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('Détecter', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme, bool isDark) {
    if (_isScanningPhoto) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF261F30) : const Color(0xFFF9F6F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFD4AF37)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analyse de l\'étiquette par l\'IA...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Détection du domaine, millésime, cépages et notes...',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF261F30) : const Color(0xFFF9F6F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37).withAlpha(100)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 65,
                height: 80,
                child: BottleImageView(
                  imagePath: _photoUrl,
                  wineType: _wineType,
                  width: 65,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Photo de l\'étiquette ajoutée',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visible dans votre journal de dégustation',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showPhotoPickerSheet(context),
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Remplacer', style: TextStyle(fontSize: 11.5)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        tooltip: 'Supprimer la photo',
                        onPressed: () => setState(() => _photoUrl = null),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221D2C) : const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B1E3F).withAlpha(60),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF8B1E3F), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photographier l\'étiquette (Scan IA)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Reconnaissance automatique du vin et ajout au journal',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _showPhotoPickerSheet(context),
            icon: const Icon(Icons.add_a_photo, size: 15),
            label: const Text('Scan IA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPhotoPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF8B1E3F)),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Photographier l\'étiquette avec l\'appareil photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFD4AF37)),
                title: const Text('Choisir depuis la galerie'),
                subtitle: const Text('Sélectionner une photo existante'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String type) {
    final isSelected = _wineType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF8B1E3F) : null,
      ),
      onSelected: (val) {
        if (val) setState(() => _wineType = type);
      },
    );
  }
}
