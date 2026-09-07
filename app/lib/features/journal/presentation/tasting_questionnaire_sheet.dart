import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/domain/taste_profile.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../offline/presentation/sync_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../data/tasting_ai_assistant_service.dart';
import '../domain/tasting_questionnaire_result.dart';
import 'journal_screen.dart';

/// A 4-step paginated bottom sheet for structured post-tasting feedback.
///
/// Adapts to wine type (hides tannins for whites, shows effervescence for sparkling).
/// Supports multi-profile: each selected taster answers in turn or shared.
/// Includes completion confirmation and automatic synchronization for friends with the app.
class TastingQuestionnaireSheet extends ConsumerStatefulWidget {
  final String wineName;
  final int? vintage;
  final String? producer;
  final String? region;
  final String? wineType; // 'red', 'white', 'rose', 'sparkling', etc.
  final List<String>? wineGrapes;
  final String? wineId;
  final String? bottleId;
  final String? cellarId;
  final int quantityToConsume;
  final List<String>? preselectedTasters;
  final String? bottleOwnerId;
  final String? bottleOwnerName;
  final VoidCallback? onFinished;

  const TastingQuestionnaireSheet({
    super.key,
    required this.wineName,
    this.vintage,
    this.producer,
    this.region,
    this.wineType,
    this.wineGrapes,
    this.wineId,
    this.bottleId,
    this.cellarId,
    this.quantityToConsume = 1,
    this.preselectedTasters,
    this.bottleOwnerId,
    this.bottleOwnerName,
    this.onFinished,
  });

  /// Show the questionnaire as a full-screen modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required String wineName,
    int? vintage,
    String? producer,
    String? region,
    String? wineType,
    List<String>? wineGrapes,
    String? wineId,
    String? bottleId,
    String? cellarId,
    int quantityToConsume = 1,
    List<String>? preselectedTasters,
    String? bottleOwnerId,
    String? bottleOwnerName,
    VoidCallback? onFinished,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => TastingQuestionnaireSheet(
        wineName: wineName,
        vintage: vintage,
        producer: producer,
        region: region,
        wineType: wineType,
        wineGrapes: wineGrapes,
        wineId: wineId,
        bottleId: bottleId,
        cellarId: cellarId,
        quantityToConsume: quantityToConsume,
        preselectedTasters: preselectedTasters,
        bottleOwnerId: bottleOwnerId,
        bottleOwnerName: bottleOwnerName,
        onFinished: onFinished,
      ),
    );
  }

  @override
  ConsumerState<TastingQuestionnaireSheet> createState() => _TastingQuestionnaireSheetState();
}

class _TastingQuestionnaireSheetState extends ConsumerState<TastingQuestionnaireSheet> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Profile selection
  List<TasteProfile> _allProfiles = [];
  Set<String> _selectedProfileIds = {};
  bool _profilesLoaded = false;

  // Multi-taster mode
  bool _separateTurns = true; // true = "Chacun son tour", false = "Ensemble"
  bool _isTransitioningToNextTaster = false;
  bool _isCompleted = false;
  final Map<String, TastingQuestionnaireResult> _completedResults = {};
  final Set<String> _syncedFriendNames = {};

  // Current answering profile index (for multi-profile flow)
  int _currentProfileIndex = 0;
  List<TasteProfile> _selectedProfiles = [];

  // Step 1: Impression
  int _emojiIndex = 3; // default 😊
  double _noteSlider = 7.0;

  // Step 2: Nez
  Set<String> _selectedAromas = {};
  double _aromaIntensity = 0.5;

  // Step 3: Bouche
  double _acidity = 0.5;
  double _tannins = 0.5;
  double _mineralite = 0.5; // for whites and rosés
  double _body = 0.5;
  double _length = 0.5;
  double _effervescence = 0.5;

  // Step 4: Verdict
  String _wouldBuyAgain = 'maybe';
  String _idealMoment = 'repas';
  Set<String> _whatLiked = {};
  Set<String> _whatDisliked = {};

  // Blind Tasting Mode 🙈
  bool _isBlindTasting = false;
  BlindQuizData? _blindQuizData;
  String? _guessedRegion;
  String? _guessedGrape;
  String? _guessedVintage;
  String? _guessedPrice;

  // Occasion & Photo Souvenir 📸
  String _occasion = '';
  XFile? _tastingPhoto;

  // Conclave Consensus 🍷
  String? _conclaveSummary;

  bool _isSaving = false;

  String get _normalizedType {
    final t = (widget.wineType ?? '').toLowerCase().trim();
    if (t.contains('rouge') || t == 'red') return 'red';
    if (t.contains('blanc') || t == 'white') return 'white';
    if (t.contains('ros') || t == 'rose') return 'rose';
    if (t.contains('champ') || t.contains('sparkling') || t.contains('bulles') || t.contains('effervescent')) return 'sparkling';
    if (t.contains('liquoreux') || t.contains('moelleux') || t.contains('dessert') || t.contains('doux')) return 'dessert';
    return t;
  }

  bool get _isRed => _normalizedType == 'red';
  bool get _isWhite => _normalizedType == 'white';
  bool get _isSparkling => _normalizedType == 'sparkling';
  bool get _isRose => _normalizedType == 'rose';

  // Tanins are strictly for red wines. White, rosé, sparkling wines do NOT have tannins!
  bool get _showTannins => _isRed;

  static bool _isValidUuid(String? id) {
    if (id == null || id.isEmpty) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(id);
  }

  String _profileDisplayName(TasteProfile profile) {
    if (!profile.isPrimary) return profile.name;
    final user = ref.watch(supabaseProvider).auth.currentUser;
    final userDisplayName = (user?.userMetadata?['display_name'] as String?) ??
        (user?.email?.split('@').firstOrNull) ??
        '';
    return userDisplayName.isNotEmpty ? 'Moi ($userDisplayName)' : 'Moi';
  }

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final service = ref.read(tasteProfileServiceProvider);
    final profiles = await service.getProfiles();
    List<Friend> friends = [];
    try {
      friends = await ref.read(friendsRepositoryProvider).getFriends();
    } catch (_) {}

    // Link friends with matching companion profiles
    final merged = profiles.map((p) {
      final match = friends.where((f) => f.displayName.toLowerCase() == p.name.toLowerCase()).firstOrNull;
      if (match != null) {
        return p.copyWith(friendUserId: match.friendUserId);
      }
      return p;
    }).toList();

    // Add friends who don't have a companion profile yet
    for (final f in friends) {
      if (!merged.any((p) => p.name.toLowerCase() == f.displayName.toLowerCase())) {
        merged.add(TasteProfile(
          id: f.friendUserId,
          name: f.displayName,
          friendUserId: f.friendUserId,
        ));
      }
    }

    if (mounted) {
      final primary = merged.firstWhere((p) => p.isPrimary, orElse: () => merged.first);
      final initialSelected = <String>{primary.id};

      // Pre-select any tasters passed in arguments
      if (widget.preselectedTasters != null) {
        for (final tasterName in widget.preselectedTasters!) {
          final found = merged.where((p) => p.name.toLowerCase() == tasterName.toLowerCase()).firstOrNull;
          if (found != null) {
            initialSelected.add(found.id);
          }
        }
      }

      setState(() {
        _allProfiles = merged;
        _selectedProfileIds = initialSelected;
        _profilesLoaded = true;
      });
    }
  }

  void _resetAnswers() {
    _emojiIndex = 3;
    _noteSlider = 7.0;
    _selectedAromas = {};
    _aromaIntensity = 0.5;
    _acidity = 0.5;
    _tannins = 0.5;
    _mineralite = 0.5;
    _body = 0.5;
    _length = 0.5;
    _effervescence = 0.5;
    _wouldBuyAgain = 'maybe';
    _idealMoment = 'repas';
    _whatLiked = {};
    _whatDisliked = {};
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.selectionClick();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitCurrentProfile() async {
    final profile = _selectedProfiles[_currentProfileIndex];
    final result = TastingQuestionnaireResult(
      emojiImpression: _emojiIndex,
      noteOutOf10: _noteSlider,
      perceivedAromas: Set<String>.from(_selectedAromas),
      aromaIntensity: _aromaIntensity,
      acidity: _acidity,
      tannins: _showTannins ? _tannins : null,
      body: _body,
      length: _length,
      effervescence: _isSparkling ? _effervescence : null,
      wouldBuyAgain: _wouldBuyAgain,
      idealMoment: _idealMoment,
      whatLikedMost: Set<String>.from(_whatLiked),
      whatDislikedMost: Set<String>.from(_whatDisliked),
      profileId: profile.id,
      profileName: profile.name,
    );

    setState(() => _isSaving = true);
    try {
      final service = ref.read(tasteProfileServiceProvider);
      await service.applyQuestionnaireResult(
        result: result,
        wineRegion: widget.region,
        wineGrapes: widget.wineGrapes,
        wineType: widget.wineType,
      );
      AppLogger.info('QUESTIONNAIRE', 'Saved answers for ${profile.name}');
    } catch (e) {
      AppLogger.error('QUESTIONNAIRE', 'Error saving answers', e);
    }

    _completedResults[profile.id] = result;

    // Synchronize to friend's app if friendUserId is present
    if (profile.friendUserId != null && widget.wineId != null) {
      try {
        final supabase = ref.read(supabaseProvider);
        await supabase.rpc('record_shared_tasting_log', params: {
          'p_wine_id': widget.wineId,
          'p_friend_user_id': profile.friendUserId,
          'p_rating': result.noteOutOf10,
          if (_isValidUuid(widget.bottleId)) 'p_bottle_id': widget.bottleId,
          if (_isValidUuid(widget.cellarId)) 'p_cellar_id': widget.cellarId,
          'p_notes': result.perceivedAromas.isNotEmpty
              ? 'Dégustation partagée. Arômes : ${result.perceivedAromas.join(", ")}'
              : 'Dégustation partagée.',
          'p_occasion': result.idealMoment,
          'p_co_tasters': _selectedProfiles.map((p) => p.name).toList(),
          if (_isValidUuid(widget.bottleOwnerId)) 'p_bottle_owner_id': widget.bottleOwnerId,
          if (widget.bottleOwnerName != null) 'p_bottle_owner_name': widget.bottleOwnerName,
          'p_is_external': false,
          'p_questionnaire_data': result.toJson(),
        });
        _syncedFriendNames.add(profile.name);
        AppLogger.info('QUESTIONNAIRE', 'Synced shared tasting to friend ${profile.name}');
      } catch (e) {
        AppLogger.error('QUESTIONNAIRE', 'Failed to sync friend tasting log', e);
      }
    }

    // If "Ensemble" (shared answers), apply results to other profiles as well
    if (!_separateTurns && _selectedProfiles.length > 1) {
      final service = ref.read(tasteProfileServiceProvider);
      for (int i = 1; i < _selectedProfiles.length; i++) {
        final otherP = _selectedProfiles[i];
        final cloned = TastingQuestionnaireResult(
          emojiImpression: result.emojiImpression,
          noteOutOf10: result.noteOutOf10,
          perceivedAromas: result.perceivedAromas,
          aromaIntensity: result.aromaIntensity,
          acidity: result.acidity,
          tannins: result.tannins,
          body: result.body,
          length: result.length,
          effervescence: result.effervescence,
          wouldBuyAgain: result.wouldBuyAgain,
          idealMoment: result.idealMoment,
          whatLikedMost: result.whatLikedMost,
          whatDislikedMost: result.whatDislikedMost,
          profileId: otherP.id,
          profileName: otherP.name,
        );
        try {
          await service.applyQuestionnaireResult(
            result: cloned,
            wineRegion: widget.region,
            wineGrapes: widget.wineGrapes,
            wineType: widget.wineType,
          );
          _completedResults[otherP.id] = cloned;

          if (otherP.friendUserId != null && widget.wineId != null) {
            final supabase = ref.read(supabaseProvider);
            await supabase.rpc('record_shared_tasting_log', params: {
              'p_wine_id': widget.wineId,
              'p_friend_user_id': otherP.friendUserId,
              'p_rating': cloned.noteOutOf10,
              if (_isValidUuid(widget.bottleId)) 'p_bottle_id': widget.bottleId,
              if (_isValidUuid(widget.cellarId)) 'p_cellar_id': widget.cellarId,
              'p_notes': cloned.perceivedAromas.isNotEmpty
                  ? 'Dégustation partagée. Arômes : ${cloned.perceivedAromas.join(", ")}'
                  : 'Dégustation partagée.',
              'p_occasion': cloned.idealMoment,
              'p_co_tasters': _selectedProfiles.map((p) => p.name).toList(),
              if (_isValidUuid(widget.bottleOwnerId)) 'p_bottle_owner_id': widget.bottleOwnerId,
              if (widget.bottleOwnerName != null) 'p_bottle_owner_name': widget.bottleOwnerName,
              'p_is_external': false,
              'p_questionnaire_data': cloned.toJson(),
            });
            _syncedFriendNames.add(otherP.name);
          }
        } catch (_) {}
      }
    }

    // Check if next taster should answer or if all done
    if (_separateTurns && _currentProfileIndex < _selectedProfiles.length - 1) {
      setState(() {
        _isSaving = false;
        _isTransitioningToNextTaster = true;
      });
    } else {
      // All done! Finalize tasting & checkout
      await _finalizeTastingAndCheckout();
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isCompleted = true;
        });
      }
    }
  }

  Future<void> _finalizeTastingAndCheckout() async {
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;

    // 1. Decrement bottle in cellar if bottleId is provided
    if (widget.bottleId != null && widget.bottleId!.isNotEmpty) {
      try {
        final bRes = await supabase
            .from('bottles')
            .select('quantity, status')
            .eq('id', widget.bottleId!)
            .maybeSingle();
        final currentQty = bRes?['quantity'] as int? ?? 1;
        if (currentQty > widget.quantityToConsume) {
          await supabase
              .from('bottles')
              .update({'quantity': currentQty - widget.quantityToConsume})
              .eq('id', widget.bottleId!);
        } else {
          await supabase.from('bottles').update({
            'quantity': 0,
            'status': 'consumed',
            'consumed_at': DateTime.now().toIso8601String(),
          }).eq('id', widget.bottleId!);
        }

        final offlineStorage = ref.read(offlineStorageServiceProvider);
        if (widget.cellarId != null) {
          await offlineStorage.applyOfflineConsume(widget.cellarId!, widget.bottleId!);
        }
      } catch (e) {
        AppLogger.error('QUESTIONNAIRE', 'Error updating bottle status', e);
      }
    }

    // 2. Insert primary tasting log into tasting_log table
    if (user != null && widget.wineId != null) {
      final primaryResult = _completedResults.values.firstOrNull;
      final cleanOwnerId = _isValidUuid(widget.bottleOwnerId) ? widget.bottleOwnerId : null;
      final ratingOutOf10 = primaryResult?.noteOutOf10 ?? 8.0;
      final tastingNotes = primaryResult != null && primaryResult.perceivedAromas.isNotEmpty
          ? 'Dégustation guidée. Arômes : ${primaryResult.perceivedAromas.join(", ")}'
          : 'Dégustation guidée.';
      final occasionStr = _occasion.isNotEmpty ? _occasion : (primaryResult?.idealMoment ?? 'Dégustation guidée');
      final offlineStorage = ref.read(offlineStorageServiceProvider);

      final localPayload = <String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'wine_id': widget.wineId,
        if (_isValidUuid(widget.bottleId)) 'bottle_id': widget.bottleId,
        'user_id': user.id,
        if (_isValidUuid(widget.cellarId)) 'cellar_id': widget.cellarId,
        'rating': ratingOutOf10,
        'occasion': occasionStr,
        if (_tastingPhoto != null) 'photo_url': _tastingPhoto!.path,
        'tasting_notes': tastingNotes,
        'co_tasters': _selectedProfiles.where((p) => !p.isPrimary).map((p) => p.name).toList(),
        if (cleanOwnerId != null) 'bottle_owner_id': cleanOwnerId,
        if (widget.bottleOwnerName != null) 'bottle_owner_name': widget.bottleOwnerName,
        'is_external': false,
        'consumed_at': DateTime.now().toIso8601String(),
        'wines': {
          'name': widget.wineName,
          'vintage': widget.vintage,
        },
      };

      try {
        final payload = <String, dynamic>{
          'wine_id': widget.wineId,
          if (_isValidUuid(widget.bottleId)) 'bottle_id': widget.bottleId,
          'user_id': user.id,
          if (_isValidUuid(widget.cellarId)) 'cellar_id': widget.cellarId,
          'rating': ratingOutOf10,
          'occasion': occasionStr,
          if (_tastingPhoto != null) 'photo_url': _tastingPhoto!.path,
          'tasting_notes': tastingNotes,
          'co_tasters': _selectedProfiles.where((p) => !p.isPrimary).map((p) => p.name).toList(),
          if (cleanOwnerId != null) 'bottle_owner_id': cleanOwnerId,
          if (widget.bottleOwnerName != null) 'bottle_owner_name': widget.bottleOwnerName,
          'is_external': false,
          'consumed_at': DateTime.now().toIso8601String(),
        };

        try {
          final inserted = await supabase
              .from('tasting_log')
              .insert(payload)
              .select('*, wines(*)')
              .maybeSingle();
          if (inserted != null) {
            await offlineStorage.addCachedTasting(inserted);
          } else {
            await offlineStorage.addCachedTasting(localPayload);
          }
        } catch (insertErr) {
          debugPrint('Questionnaire tasting log insert failed ($insertErr), retrying with core schema...');
          final corePayload = <String, dynamic>{
            'wine_id': widget.wineId,
            if (_isValidUuid(widget.bottleId)) 'bottle_id': widget.bottleId,
            'user_id': user.id,
            if (_isValidUuid(widget.cellarId)) 'cellar_id': widget.cellarId,
            'rating': ratingOutOf10,
            'occasion': occasionStr,
            if (_tastingPhoto != null) 'photo_url': _tastingPhoto!.path,
            'tasting_notes': tastingNotes,
            'consumed_at': payload['consumed_at'],
          };
          try {
            final inserted = await supabase
                .from('tasting_log')
                .insert(corePayload)
                .select('*, wines(*)')
                .maybeSingle();
            if (inserted != null) {
              await offlineStorage.addCachedTasting(inserted);
            } else {
              await offlineStorage.addCachedTasting(localPayload);
            }
          } catch (coreErr) {
            debugPrint('Questionnaire tasting log core insert failed ($coreErr), retrying with normalized rating...');
            try {
              corePayload['rating'] = (ratingOutOf10 / 2.0).clamp(0.0, 5.0);
              final inserted = await supabase
                  .from('tasting_log')
                  .insert(corePayload)
                  .select('*, wines(*)')
                  .maybeSingle();
              if (inserted != null) {
                inserted['rating'] = ratingOutOf10;
                await offlineStorage.addCachedTasting(inserted);
              } else {
                await offlineStorage.addCachedTasting(localPayload);
              }
            } catch (retryErr) {
              debugPrint('Questionnaire tasting log retry insert failed: $retryErr');
              await offlineStorage.addCachedTasting(localPayload);
            }
          }
        }
      } catch (e) {
        AppLogger.error('QUESTIONNAIRE', 'Error inserting primary tasting log', e);
        await offlineStorage.addCachedTasting(localPayload);
      }
    }

    // Generate table conclave summary if multiple tasters
    if (_selectedProfiles.length > 1) {
      try {
        final ai = ref.read(tastingAiAssistantServiceProvider);
        _conclaveSummary = await ai.generateTastingConsensus(
          wineName: widget.wineName,
          results: _completedResults.values.toList(),
        );
      } catch (_) {}
    }

    // 3. Invalidate caches
    notifyCellarChanged(ref, widget.cellarId);
    ref.invalidate(tastingLogProvider);
    ref.invalidate(tasteProfilesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vintageStr = widget.vintage != null ? ' ${widget.vintage}' : '';

    if (_isCompleted) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1520) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(child: _buildCompletionView()),
          ],
        ),
      );
    }

    if (_isTransitioningToNextTaster) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1520) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(child: _buildTransitionView()),
          ],
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Wine name + profile selector or current profile indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('🍷', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Questionnaire Dégustation',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _isBlindTasting
                                ? 'Bouteille Mystère 🕵️‍♂️ (Vin ${_isRed ? "Rouge" : (_isWhite ? "Blanc" : "Rosé")})'
                                : '${widget.wineName}$vintageStr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8B1E3F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dicter mes impressions (IA) 🎙️',
                      icon: const Icon(Icons.mic, color: Color(0xFF8B1E3F)),
                      onPressed: _showVoiceDictationDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _confirmClose(context),
                    ),
                  ],
                ),

                // Profile indicator for multi-profile flow
                if (_selectedProfiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 16, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 6),
                          Text(
                            'Réponses de ${_profileDisplayName(_selectedProfiles[_currentProfileIndex])}'
                            '${_selectedProfiles.length > 1 ? " (${_currentProfileIndex + 1}/${_selectedProfiles.length})" : ""}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(5, (i) {
                final labels = ['Dégustateurs', 'Impression', 'Le Nez', 'La Bouche', 'Verdict'];
                final isActive = i == _currentStep;
                final isDone = i < _currentStep;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFFD4AF37)
                                : isActive
                                    ? const Color(0xFF8B1E3F)
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? const Color(0xFF8B1E3F) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildProfileSelector(),
                _buildStep1Impression(),
                _buildStep2Nez(),
                _buildStep3Bouche(),
                _buildStep4Verdict(),
              ],
            ),
          ),

          // Navigation buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Retour'),
                    ),
                  const Spacer(),
                  if (_currentStep == 0)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _selectedProfileIds.isEmpty
                          ? null
                          : () {
                              _selectedProfiles = _allProfiles
                                  .where((p) => _selectedProfileIds.contains(p.id))
                                  .toList();
                              _currentProfileIndex = 0;
                              _resetAnswers();
                              _nextStep();
                            },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text('Commencer (${_selectedProfileIds.length})'),
                    ),
                  if (_currentStep > 0 && _currentStep < 4)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _nextStep,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Suivant'),
                    ),
                  if (_currentStep == 4)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: _isSaving ? null : _submitCurrentProfile,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check, size: 16),
                      label: Text(
                        _separateTurns && _currentProfileIndex < _selectedProfiles.length - 1
                            ? 'Valider → Dégustateur suivant'
                            : 'Valider & Terminer ✨',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 0: Profile Selector ("Qui a dégusté ?")
  // ===========================================================================
  Widget _buildProfileSelector() {
    final theme = Theme.of(context);
    if (!_profilesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '👥 Qui a dégusté ce vin ?',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Sélectionnez les dégustateurs. Les profils de goût seront enrichis automatiquement.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Mode selector when multiple people are tasting
        if (_selectedProfileIds.length > 1)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Comment déguster ?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.phone_android, size: 14),
                        label: const Text('Chacun son tour', style: TextStyle(fontSize: 12)),
                        selected: _separateTurns,
                        selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF8B1E3F),
                        onSelected: (val) {
                          if (val) setState(() => _separateTurns = true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.celebration, size: 14),
                        label: const Text('Ensemble', style: TextStyle(fontSize: 12)),
                        selected: !_separateTurns,
                        selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF8B1E3F),
                        onSelected: (val) {
                          if (val) setState(() => _separateTurns = false);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _separateTurns
                      ? '📱 En passant le téléphone : chacun répond séparément à son rythme.'
                      : '🥂 Un seul questionnaire complété ensemble pour tous les convives.',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

        // Mode Dégustation à l'aveugle
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isBlindTasting
                ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isBlindTasting
                  ? const Color(0xFFD4AF37)
                  : Colors.grey.withValues(alpha: 0.25),
              width: _isBlindTasting ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🙈', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mode Dégustation à l\'Aveugle',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Masque le nom du vin et active un quiz de table interactif avec révélation finale !',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isBlindTasting,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (val) {
                  setState(() => _isBlindTasting = val);
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
        ),

        ..._allProfiles.map((profile) {
          final isSelected = _selectedProfileIds.contains(profile.id);
          final displayName = _profileDisplayName(profile);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? const Color(0xFF8B1E3F) : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedProfileIds.remove(profile.id);
                  } else {
                    _selectedProfileIds.add(profile.id);
                  }
                });
                HapticFeedback.selectionClick();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.person_outline,
                        color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (profile.questionnairesCompleted > 0)
                            Text(
                              '${profile.questionnairesCompleted} questionnaire${profile.questionnairesCompleted > 1 ? "s" : ""} complété${profile.questionnairesCompleted > 1 ? "s" : ""}',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (profile.isPrimary)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Profil principal',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                                  ),
                                ),
                              if (profile.hasApp)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.smartphone, size: 10, color: Colors.green),
                                      SizedBox(width: 3),
                                      Text(
                                        'App installée 📱',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // Step 1: Impression Générale 🎯
  // ===========================================================================
  Widget _buildStep1Impression() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '🎯 Impression Générale',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (_isBlindTasting) ...[
          const SizedBox(height: 12),
          _buildBlindQuizCard(theme),
        ],
        const SizedBox(height: 20),

        // Emoji selector
        Text('Votre ressenti global :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) {
            final isSelected = _emojiIndex == i;
            return GestureDetector(
              onTap: () {
                setState(() => _emojiIndex = i);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF8B1E3F) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      TastingQuestionnaireResult.emojiLabels[i],
                      style: TextStyle(fontSize: isSelected ? 36 : 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TastingQuestionnaireResult.emojiDescriptions[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        // Note slider
        Text('Note sur 10 :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('😐', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Slider(
                value: _noteSlider,
                min: 1,
                max: 10,
                divisions: 18,
                activeColor: const Color(0xFF8B1E3F),
                label: _noteSlider.toStringAsFixed(1),
                onChanged: (v) => setState(() => _noteSlider = v),
              ),
            ),
            const Text('🤩', style: TextStyle(fontSize: 20)),
          ],
        ),
        Center(
          child: Text(
            '${_noteSlider.toStringAsFixed(1)} / 10',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B1E3F),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 2: Le Nez (Arômes) 🍇
  // ===========================================================================
  Widget _buildStep2Nez() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '🍇 Le Nez — Arômes',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Quels arômes avez-vous perçus ? (Plusieurs choix possibles)',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TastingQuestionnaireResult.aromaOptions.map((aroma) {
            final isSelected = _selectedAromas.contains(aroma.id);
            return FilterChip(
              selected: isSelected,
              label: Text('${aroma.emoji} ${aroma.label}'),
              selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedAromas.add(aroma.id);
                  } else {
                    _selectedAromas.remove(aroma.id);
                  }
                });
                HapticFeedback.selectionClick();
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Text('Intensité aromatique :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildSliderRow(
          leftLabel: '🤫 Discret',
          rightLabel: '💥 Explosif',
          value: _aromaIntensity,
          onChanged: (v) => setState(() => _aromaIntensity = v),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 3: La Bouche (Équilibre) ⚖️
  // ===========================================================================
  Widget _buildStep3Bouche() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '⚖️ La Bouche — Équilibre',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Décrivez la texture et l\'équilibre du vin en bouche.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Acidité / Vivacité
        Text(_isWhite ? 'Acidité & Vivacité :' : 'Acidité :', style: theme.textTheme.titleSmall),
        _buildSliderRow(
          leftLabel: '🫠 Mou / Plat',
          rightLabel: '⚡ Vif / Tranchant',
          value: _acidity,
          onChanged: (v) => setState(() => _acidity = v),
        ),
        const SizedBox(height: 16),

        // Tanins (ONLY for reds — never for whites!)
        if (_showTannins) ...[
          Text('Tanins :', style: theme.textTheme.titleSmall),
          _buildSliderRow(
            leftLabel: '🧶 Fondus / Soyeux',
            rightLabel: '💪 Puissants / Astringents',
            value: _tannins,
            onChanged: (v) => setState(() => _tannins = v),
          ),
          const SizedBox(height: 16),
        ],

        // Minéralité & Fraîcheur (for whites and rosés instead of tannins)
        if (_isWhite || _isRose) ...[
          Text('Minéralité & Fraîcheur :', style: theme.textTheme.titleSmall),
          _buildSliderRow(
            leftLabel: '🧈 Rond / Beurré',
            rightLabel: '🪨 Minéral / Ciselé',
            value: _mineralite,
            onChanged: (v) => setState(() => _mineralite = v),
          ),
          const SizedBox(height: 16),
        ],

        // Effervescence (only for sparkling)
        if (_isSparkling) ...[
          Text('Effervescence :', style: theme.textTheme.titleSmall),
          _buildSliderRow(
            leftLabel: '🫧 Fine / Délicate',
            rightLabel: '🎆 Vive / Crémeuse',
            value: _effervescence,
            onChanged: (v) => setState(() => _effervescence = v),
          ),
          const SizedBox(height: 16),
        ],

        // Corps
        Text('Corps / Volume :', style: theme.textTheme.titleSmall),
        _buildSliderRow(
          leftLabel: '🍃 Léger / Aérien',
          rightLabel: '🏋️ Puissant / Charnu',
          value: _body,
          onChanged: (v) => setState(() => _body = v),
        ),
        const SizedBox(height: 16),

        // Longueur
        Text('Longueur en bouche :', style: theme.textTheme.titleSmall),
        _buildSliderRow(
          leftLabel: '⏱️ Courte',
          rightLabel: '♾️ Interminable',
          value: _length,
          onChanged: (v) => setState(() => _length = v),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 4: Verdict Final ✅
  // ===========================================================================
  Widget _buildStep4Verdict() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '✅ Verdict Final',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Would buy again
        Text('Rachèteriez-vous cette bouteille ?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildChoiceChip('🤩 Absolument !', 'yes', _wouldBuyAgain, (v) => setState(() => _wouldBuyAgain = v)),
            const SizedBox(width: 8),
            _buildChoiceChip('🤔 Peut-être', 'maybe', _wouldBuyAgain, (v) => setState(() => _wouldBuyAgain = v)),
            const SizedBox(width: 8),
            _buildChoiceChip('👎 Non merci', 'no', _wouldBuyAgain, (v) => setState(() => _wouldBuyAgain = v)),
          ],
        ),
        const SizedBox(height: 20),

        // Ideal moment
        Text('Quel moment idéal pour ce vin ?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChoiceChip('🥂 Apéro', 'apero', _idealMoment, (v) => setState(() => _idealMoment = v)),
            _buildChoiceChip('🍽️ Repas du quotidien', 'repas', _idealMoment, (v) => setState(() => _idealMoment = v)),
            _buildChoiceChip('🎩 Grand dîner', 'grand_diner', _idealMoment, (v) => setState(() => _idealMoment = v)),
            _buildChoiceChip('🕯️ Dîner romantique', 'diner_romantique', _idealMoment, (v) => setState(() => _idealMoment = v)),
            _buildChoiceChip('🧘 Solo / Méditation', 'solo', _idealMoment, (v) => setState(() => _idealMoment = v)),
          ],
        ),
        const SizedBox(height: 20),

        // What liked most
        Text('Ce que vous avez le plus aimé :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: TastingQuestionnaireResult.likedOptions.map((opt) {
            final isSelected = _whatLiked.contains(opt.id);
            return FilterChip(
              selected: isSelected,
              label: Text(opt.label, style: const TextStyle(fontSize: 12)),
              selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFFD4AF37),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _whatLiked.add(opt.id);
                  } else {
                    _whatLiked.remove(opt.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // What disliked (trop_tannique is hidden for non-red wines)
        Text('Ce qui vous a le moins plu :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: TastingQuestionnaireResult.dislikedOptions
              .where((opt) => _showTannins || opt.id != 'trop_tannique')
              .map((opt) {
            final isSelected = _whatDisliked.contains(opt.id);
            return FilterChip(
              selected: isSelected,
              label: Text(opt.label, style: const TextStyle(fontSize: 12)),
              selectedColor: Colors.red.withValues(alpha: 0.15),
              checkmarkColor: Colors.red,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    // If "rien" is selected, clear everything else
                    if (opt.id == 'rien') {
                      _whatDisliked = {'rien'};
                    } else {
                      _whatDisliked.remove('rien');
                      _whatDisliked.add(opt.id);
                    }
                  } else {
                    _whatDisliked.remove(opt.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Occasion / Moment partagé
        TextField(
          decoration: InputDecoration(
            labelText: 'Occasion / Souvenir partagé (optionnel) ✨',
            hintText: 'Ex: 70 ans de Papa, Dîner aux chandelles, Retrouvailles...',
            prefixIcon: const Icon(Icons.celebration_outlined, color: Color(0xFF8B1E3F)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => _occasion = v.trim(),
        ),
        const SizedBox(height: 14),

        // Photo Souvenir
        if (_tastingPhoto == null)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: const Color(0xFF8B1E3F),
              side: BorderSide(color: const Color(0xFF8B1E3F).withValues(alpha: 0.4)),
            ),
            onPressed: _pickTastingPhoto,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Ajouter une photo souvenir de la table 📸', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.image, color: Color(0xFF8B1E3F)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Photo souvenir enregistrée 📸',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => setState(() => _tastingPhoto = null),
                ),
              ],
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ===========================================================================
  // Completion & Transition Views
  // ===========================================================================

  Widget _buildCompletionView() {
    final theme = Theme.of(context);
    final vintageStr = widget.vintage != null ? ' ${widget.vintage}' : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 38)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Dégustation terminée & enregistrée !',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8B1E3F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.wineName}$vintageStr',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Les profils de dégustation ont été mis à jour avec succès ✨',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        if (widget.bottleId != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF8B1E3F)),
                  SizedBox(width: 6),
                  Text(
                    'Bouteille sortie de la cave',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Blind Tasting Grand Reveal Card
        if (_isBlindTasting) ...[
          _buildBlindRevealCard(vintageStr),
          const SizedBox(height: 16),
        ],

        // Table Conclave Consensus Card
        if (_selectedProfiles.length > 1 && _conclaveSummary != null) ...[
          _buildConclaveSummaryCard(),
          const SizedBox(height: 16),
        ],

        // Summary cards for each taster
        ..._selectedProfiles.map((profile) {
          final res = _completedResults[profile.id];
          final isSynced = _syncedFriendNames.contains(profile.name);
          final displayName = _profileDisplayName(profile);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF8B1E3F),
                        radius: 18,
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (res != null)
                              Row(
                                children: [
                                  Text(
                                    TastingQuestionnaireResult.emojiLabels[res.emojiImpression],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${res.noteOutOf10.toStringAsFixed(1)} / 10',
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (res != null && res.perceivedAromas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: res.perceivedAromas.map((aId) {
                        final opt = TastingQuestionnaireResult.aromaOptions.firstWhere(
                          (a) => a.id == aId,
                          orElse: () => AromaOption(id: aId, label: aId, emoji: '🍇'),
                        );
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          label: Text('${opt.emoji} ${opt.label}', style: const TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        isSynced ? Icons.cloud_done : Icons.check_circle,
                        size: 16,
                        color: isSynced ? Colors.green : const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSynced
                            ? 'Synchronisé dans l\'application de ${profile.name} ✨'
                            : 'Profil de goût enrichi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSynced ? FontWeight.bold : FontWeight.normal,
                          color: isSynced ? Colors.green.shade700 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            widget.onFinished?.call();
            Navigator.of(context).pop(true);
          },
          icon: const Icon(Icons.celebration, color: Colors.white),
          label: const Text('Terminer ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTransitionView() {
    final nextProfile = _selectedProfiles[_currentProfileIndex + 1];
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B1E3F), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.phone_android, size: 44, color: Color(0xFF8B1E3F)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Passez le téléphone à ${nextProfile.name} 📱',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Vos réponses ont bien été enregistrées.\nC\'est au tour de ${nextProfile.name} de donner ses impressions sur ce vin !',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                setState(() {
                  _currentProfileIndex++;
                  _isTransitioningToNextTaster = false;
                  _currentStep = 1;
                  _resetAnswers();
                });
                _pageController.jumpToPage(1);
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'C\'est parti, ${nextProfile.name} ! 🍷',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Shared widgets
  // ===========================================================================

  Widget _buildSliderRow({
    required String leftLabel,
    required String rightLabel,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(leftLabel, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF8B1E3F),
                inactiveTrackColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                thumbColor: const Color(0xFF8B1E3F),
                overlayColor: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                trackHeight: 5,
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(rightLabel, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value, String currentValue, ValueChanged<String> onChanged) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () {
        onChanged(value);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF8B1E3F) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBlindQuizCard(ThemeData theme) {
    if (_blindQuizData == null) {
      _blindQuizData = ref.read(tastingAiAssistantServiceProvider).generateBlindQuizOptions(
        wineName: widget.wineName,
        wineType: widget.wineType ?? 'red',
        vintage: widget.vintage,
        region: widget.region,
        grapes: widget.wineGrapes,
      );
    }
    final quiz = _blindQuizData!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🙈', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Quiz Dégustation à l\'Aveugle',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Faites vos pronostics avant la grande révélation finale !',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          // 1. Région
          const Text('1. Quelle est la région d\'origine ? 🌍', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quiz.regionChoices.map((r) {
              final isSelected = _guessedRegion == r;
              return ChoiceChip(
                label: Text(r, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) => setState(() => _guessedRegion = val ? r : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 2. Cépage
          const Text('2. Quel est le cépage principal ? 🍇', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quiz.grapeChoices.map((g) {
              final isSelected = _guessedGrape == g;
              return ChoiceChip(
                label: Text(g, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) => setState(() => _guessedGrape = val ? g : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 3. Millésime / Tranche d'âge
          const Text('3. Âge / Millésime estimé ? 📅', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quiz.vintageBrackets.map((v) {
              final isSelected = _guessedVintage == v;
              return ChoiceChip(
                label: Text(v, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) => setState(() => _guessedVintage = val ? v : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 4. Fourchette de prix
          const Text('4. Estimation de prix ? 💶', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quiz.priceBrackets.map((p) {
              final isSelected = _guessedPrice == p;
              return ChoiceChip(
                label: Text(p, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) => setState(() => _guessedPrice = val ? p : null),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showVoiceDictationDialog() {
    final parentContext = context;
    final controller = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1622) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Color(0xFF8B1E3F), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dicter les impressions à table 🎙️',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Parlez ou écrivez naturellement, l\'IA s\'occupe du reste',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFD4AF37)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Astuce : activez le micro sur votre clavier pour dicter à voix haute !',
                            style: TextStyle(fontSize: 11, color: Color(0xFFD4AF37), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Ex : Bernard a adoré, 8.5/10 avec des notes de sous-bois et de cassis. Caro a mis 7/10 en trouvant le vin un peu acide...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;

                            setSheetState(() => isProcessing = true);
                            try {
                              final currentTasterName = _selectedProfiles.isNotEmpty
                                  ? _selectedProfiles[_currentProfileIndex].name
                                  : 'Moi';
                              final tasterNames = _selectedProfiles.map((p) => p.name).toList();

                              final ai = ref.read(tastingAiAssistantServiceProvider);
                              final res = await ai.parseNaturalLanguageNotes(
                                spokenText: text,
                                tasterNames: tasterNames.isNotEmpty ? tasterNames : [currentTasterName],
                                wineType: widget.wineType ?? 'red',
                                wineName: widget.wineName,
                              );

                              // Apply parsed notes for current taster
                              final parsed = res.profiles[currentTasterName] ?? res.profiles.values.firstOrNull;
                              if (parsed != null && mounted) {
                                setState(() {
                                  _noteSlider = parsed.noteOutOf10;
                                  _emojiIndex = parsed.emojiImpression;
                                  _selectedAromas = parsed.perceivedAromas;
                                  _acidity = parsed.acidity;
                                  if (parsed.tannins != null && _showTannins) {
                                    _tannins = parsed.tannins!;
                                  }
                                  if (parsed.mineralite != null && !_showTannins) {
                                    _mineralite = parsed.mineralite!;
                                  }
                                  _body = parsed.body;
                                  _length = parsed.length;
                                });
                              }

                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  SnackBar(
                                    content: Text('✨ Impressions de dégustation appliquées par l\'IA (${parsed?.noteOutOf10.toStringAsFixed(1)}/10) !'),
                                    backgroundColor: const Color(0xFF8B1E3F),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isProcessing = false);
                            }
                          },
                    icon: isProcessing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text(
                      isProcessing ? 'Analyse en cours...' : 'Analyser & Appliquer aux fiches ✨',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickTastingPhoto() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo de la tablée 📸'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie 🖼️'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (choice != null) {
      final photo = await picker.pickImage(source: choice, imageQuality: 85);
      if (photo != null && mounted) {
        setState(() => _tastingPhoto = photo);
      }
    }
  }

  Widget _buildBlindRevealCard(String vintageStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFAA820A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🍾', style: TextStyle(fontSize: 26)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Révélation de la Bouteille Mystère !',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.wineName}$vintageStr',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          Text(
            '${widget.producer ?? "Domaine"} • ${widget.region ?? "Région"}',
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          if (widget.wineGrapes != null && widget.wineGrapes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Cépages : ${widget.wineGrapes!.join(", ")}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white38),
          const SizedBox(height: 6),
          const Text(
            'Bilan des pronostics à l\'aveugle 🎯 :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          if (_guessedRegion != null)
            _quizResultRow(
              'Région',
              _guessedRegion!,
              _blindQuizData?.correctRegion,
              _blindQuizData?.correctRegion == _guessedRegion,
            ),
          if (_guessedGrape != null)
            _quizResultRow(
              'Cépage',
              _guessedGrape!,
              _blindQuizData?.correctGrape,
              _blindQuizData?.correctGrape == _guessedGrape,
            ),
          if (_guessedVintage != null)
            _quizResultRow(
              'Millésime',
              _guessedVintage!,
              _blindQuizData?.correctVintageBracket,
              _blindQuizData?.correctVintageBracket == _guessedVintage,
            ),
          if (_guessedPrice != null)
            _quizResultRow(
              'Prix',
              _guessedPrice!,
              _blindQuizData?.estimatedPriceBracket,
              _blindQuizData?.estimatedPriceBracket == _guessedPrice,
            ),
        ],
      ),
    );
  }

  Widget _quizResultRow(String label, String guessed, String? correct, bool isCorrect) {
    final correctMsg = correct != null ? "(C'était : $correct)" : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.greenAccent : Colors.white70, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label : $guessed ${isCorrect ? "🎯 Bravo !" : correctMsg}',
              style: const TextStyle(fontSize: 11.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConclaveSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🍷', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Synthèse du Conclave',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8B1E3F)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _conclaveSummary!,
            style: const TextStyle(fontSize: 13, height: 1.45, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le questionnaire ?'),
        content: const Text('Vos réponses ne seront pas sauvegardées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
