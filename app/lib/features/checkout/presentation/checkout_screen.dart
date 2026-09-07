import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/services/cellar_location_service.dart';
import '../../cellar/domain/cellar.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../offline/domain/offline_action.dart';
import '../../offline/presentation/sync_provider.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../journal/presentation/tasting_questionnaire_sheet.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../cellar/domain/wine.dart';
import '../../cellar/domain/wine_service_advisor.dart';
import '../../notifications/data/local_notification_service.dart';
import '../../journal/data/tasting_ai_assistant_service.dart';
import '../../../config/router.dart';
import '../data/post_tasting_notification_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? bottleId;
  const CheckoutScreen({super.key, this.bottleId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _selectedBottle;
  List<Map<String, dynamic>> _cellarBottles = [];
  String _searchQuery = '';

  // Friends & Co-tasters
  List<Friend> _friends = [];
  List<TasteProfile> _companionProfiles = [];
  final Set<String> _selectedCoTasters = {};

  // Dégustation form fields
  int _consumeCount = 1;
  double _rating = 8.5;
  final _foodController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _foodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isValidUuid(String? id) {
    if (id == null || id.isEmpty) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(id);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseProvider);
    var cellarId = ref.read(currentCellarIdProvider);

    try {
      _friends = await ref.read(friendsRepositoryProvider).getFriends();
      _companionProfiles = await ref.read(tasteProfileServiceProvider).getProfiles();
      if (widget.bottleId != null && widget.bottleId!.isNotEmpty) {
        try {
          final res = await supabase
              .from('bottles')
              .select('*, wines(*), profiles!bottles_owner_id_fkey(display_name)')
              .eq('id', widget.bottleId!)
              .single();
          _selectedBottle = res;
        } catch (_) {
          final res = await supabase
              .from('bottles')
              .select('*, wines(*)')
              .eq('id', widget.bottleId!)
              .single();
          _selectedBottle = res;
        }
      } else {
        // If no specific bottleId provided, load all bottles in user's cellar
        if (cellarId == null) {
          final members = await supabase
              .from('cellar_members')
              .select('cellar_id')
              .limit(1);
          if (members.isNotEmpty) {
            cellarId = members.first['cellar_id'] as String?;
          }
        }

        if (cellarId != null) {
          try {
            final res = await supabase
                .from('bottles')
                .select('*, wines(*), profiles!bottles_owner_id_fkey(display_name)')
                .eq('cellar_id', cellarId)
                .eq('status', 'in_cellar')
                .order('created_at', ascending: false);
            _cellarBottles = List<Map<String, dynamic>>.from(res);
          } catch (_) {
            final res = await supabase
                .from('bottles')
                .select('*, wines(*)')
                .eq('cellar_id', cellarId)
                .eq('status', 'in_cellar')
                .order('created_at', ascending: false);
            _cellarBottles = List<Map<String, dynamic>>.from(res);
          }
        } else {
          try {
            final res = await supabase
                .from('bottles')
                .select('*, wines(*), profiles!bottles_owner_id_fkey(display_name)')
                .eq('status', 'in_cellar')
                .order('created_at', ascending: false);
            _cellarBottles = List<Map<String, dynamic>>.from(res);
          } catch (_) {
            final res = await supabase
                .from('bottles')
                .select('*, wines(*)')
                .eq('status', 'in_cellar')
                .order('created_at', ascending: false);
            _cellarBottles = List<Map<String, dynamic>>.from(res);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading checkout bottle: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddCompanionDialog() async {
    final nameCtrl = TextEditingController();
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
              'Ajoutez un proche ou membre de la famille présent à cette dégustation (ex: Papa, Maman, Sophie...).',
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
  }

  Future<bool> _checkDistantCellarProceed(String? cellarId) async {
    if (cellarId == null) return true;
    final allRawCellars = await ref.read(cellarRepositoryProvider).getUserCellarsWithRole();
    final allCellars = allRawCellars.map((m) {
      final cMap = m['cellars'];
      if (cMap is Map<String, dynamic>) {
        return Cellar.fromJson(cMap);
      }
      return null;
    }).whereType<Cellar>().toList();

    Cellar? targetCellar;
    for (final c in allCellars) {
      if (c.id == cellarId) {
        targetCellar = c;
        break;
      }
    }

    if (targetCellar != null) {
      final distCheck = await CellarLocationService.checkDistantCellar(
        targetCellar: targetCellar,
        allCellars: allCellars,
      );

      if (distCheck.isDistant && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_off_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cave distante détectée',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              '${distCheck.warningMessage}\n\nSouhaitez-vous quand même enregistrer la sortie de cette bouteille depuis la cave "${targetCellar!.displayName}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Continuer quand même', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        return proceed == true;
      }
    }
    return true;
  }

  Future<void> _startGuidedTasting() async {
    if (_selectedBottle == null) return;
    final cellarId = _selectedBottle!['cellar_id'] as String?;
    final canProceed = await _checkDistantCellarProceed(cellarId);
    if (!canProceed || !mounted) return;

    final wine = _selectedBottle!['wines'] as Map<String, dynamic>? ?? {};
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final wineName = wine['name'] ?? (isFr ? 'Vin' : 'Wine');
    final vintage = (wine['vintage'] as num?)?.toInt() ?? int.tryParse(wine['vintage']?.toString() ?? '');
    final producer = wine['producer'] as String?;
    final region = wine['region'] as String?;
    final wineType = (wine['type'] ?? wine['wine_type'] ?? 'red').toString();
    final wineGrapes = wine['grapes'] is List ? List<String>.from(wine['grapes']) : null;
    final wineId = _selectedBottle!['wine_id'] as String? ?? wine['id'] as String?;
    final bottleId = _selectedBottle!['id'] as String?;

    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    final profilesData = _selectedBottle!['profiles'] as Map<String, dynamic>?;
    final bottleOwnerDisplayName = profilesData?['display_name'] as String?;
    final userDisplayName = (user?.userMetadata?['display_name'] as String?) ??
        (user?.userMetadata?['full_name'] as String?);
    final ownerName = bottleOwnerDisplayName ?? userDisplayName ?? 'Moi';
    final rawOwnerId = _selectedBottle!['owner_id']?.toString() ?? user?.id;
    final ownerId = _isValidUuid(rawOwnerId) ? rawOwnerId : (_isValidUuid(user?.id) ? user!.id : null);

    await TastingQuestionnaireSheet.show(
      context,
      wineName: wineName,
      vintage: vintage,
      producer: producer,
      region: region,
      wineType: wineType,
      wineGrapes: wineGrapes,
      wineId: wineId,
      bottleId: bottleId,
      cellarId: cellarId,
      quantityToConsume: _consumeCount,
      preselectedTasters: _selectedCoTasters.toList(),
      bottleOwnerId: ownerId,
      bottleOwnerName: ownerName,
      onFinished: () {
        if (mounted) {
          context.go('/');
        }
      },
    );
  }

  Future<void> _submitCheckout() async {
    if (_selectedBottle == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    final bottleId = _selectedBottle!['id'] as String;
    final currentQty = _selectedBottle!['quantity'] as int? ?? 1;
    final cellarId = _selectedBottle!['cellar_id'] as String?;

    final canProceed = await _checkDistantCellarProceed(cellarId);
    if (!canProceed || !mounted) {
      setState(() => _isSubmitting = false);
      return;
    }

    final profilesData = _selectedBottle!['profiles'] as Map<String, dynamic>?;
    final bottleOwnerDisplayName = profilesData?['display_name'] as String?;
    final userDisplayName = (user?.userMetadata?['display_name'] as String?) ??
        (user?.userMetadata?['full_name'] as String?);
    final ownerName = bottleOwnerDisplayName ?? userDisplayName ?? 'Moi';
    final rawOwnerId = _selectedBottle!['owner_id']?.toString() ?? user?.id;
    final ownerId = _isValidUuid(rawOwnerId) ? rawOwnerId : (_isValidUuid(user?.id) ? user!.id : null);

    try {
      bool tastingSavedOnline = false;
      bool bottleSavedOnline = false;
      final offlineStorage = ref.read(offlineStorageServiceProvider);
      final wineMap = _selectedBottle!['wines'] as Map<String, dynamic>?;
      final wineId = _selectedBottle!['wine_id'] as String? ?? wineMap?['id'] as String?;
      final effectiveCellarId = cellarId ?? ref.read(currentCellarIdProvider);
      final wineName = wineMap?['name'] as String? ?? 'Vin dégusté';
      final vintage = (wineMap?['vintage'] as num?)?.toInt() ?? int.tryParse(wineMap?['vintage']?.toString() ?? '');

      final localTastingEntry = <String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'wine_id': wineId ?? '',
        if (_isValidUuid(bottleId)) 'bottle_id': bottleId,
        'user_id': user?.id,
        if (_isValidUuid(effectiveCellarId)) 'cellar_id': effectiveCellarId,
        'rating': _rating,
        'food_paired': _foodController.text.trim(),
        'tasting_notes': _notesController.text.trim(),
        'co_tasters': _selectedCoTasters.toList(),
        if (ownerId != null) 'bottle_owner_id': ownerId,
        'bottle_owner_name': ownerName,
        'is_external': false,
        'consumed_at': DateTime.now().toIso8601String(),
        'wines': wineMap ?? {
          'name': wineName,
          'vintage': vintage,
          'region': wineMap?['region'],
          'country': wineMap?['country'],
          'appellation': wineMap?['appellation'],
          'type': wineMap?['type'],
        },
      };

      // 1. Record tasting log
      if (user != null && wineId != null && wineId.isNotEmpty) {
        final payload = <String, dynamic>{
          'wine_id': wineId,
          if (_isValidUuid(bottleId)) 'bottle_id': bottleId,
          'user_id': user.id,
          if (_isValidUuid(effectiveCellarId)) 'cellar_id': effectiveCellarId,
          'rating': _rating,
          'food_paired': _foodController.text.trim(),
          'tasting_notes': _notesController.text.trim(),
          'co_tasters': _selectedCoTasters.toList(),
          if (ownerId != null) 'bottle_owner_id': ownerId,
          'bottle_owner_name': ownerName,
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
            await offlineStorage.addCachedTasting(localTastingEntry);
          }
          tastingSavedOnline = true;
        } catch (insertErr) {
          debugPrint('Tasting log primary insert notice ($insertErr), retrying with core schema...');
          final corePayload = <String, dynamic>{
            'wine_id': wineId,
            if (_isValidUuid(bottleId)) 'bottle_id': bottleId,
            'user_id': user.id,
            if (_isValidUuid(effectiveCellarId)) 'cellar_id': effectiveCellarId,
            'rating': _rating,
            'food_paired': _foodController.text.trim(),
            'tasting_notes': _notesController.text.trim(),
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
              await offlineStorage.addCachedTasting(localTastingEntry);
            }
            tastingSavedOnline = true;
          } catch (coreErr) {
            debugPrint('Tasting log core insert notice ($coreErr), retrying with normalized rating...');
            try {
              corePayload['rating'] = (_rating / 2.0).clamp(0.0, 5.0);
              final inserted = await supabase
                  .from('tasting_log')
                  .insert(corePayload)
                  .select('*, wines(*)')
                  .maybeSingle();
              if (inserted != null) {
                inserted['rating'] = _rating;
                await offlineStorage.addCachedTasting(inserted);
              } else {
                await offlineStorage.addCachedTasting(localTastingEntry);
              }
              tastingSavedOnline = true;
            } catch (retryErr) {
              debugPrint('Tasting log retry insert notice: $retryErr');
              await offlineStorage.addCachedTasting(localTastingEntry);
              tastingSavedOnline = false;
            }
          }
        }
      } else {
        await offlineStorage.addCachedTasting(localTastingEntry);
      }

      // 2. Decrement bottle quantity or mark as consumed
      try {
        if (currentQty > _consumeCount) {
          await supabase
              .from('bottles')
              .update({'quantity': currentQty - _consumeCount})
              .eq('id', bottleId);
        } else {
          await supabase
              .from('bottles')
              .update({
                'quantity': 0,
                'status': 'consumed',
                'consumed_at': DateTime.now().toIso8601String(),
              })
              .eq('id', bottleId);
        }
        bottleSavedOnline = true;
      } catch (e) {
        debugPrint('Checkout offline fallback: $e');
        bottleSavedOnline = false;
      }

      // Apply immediate local cache update
      if (cellarId != null) {
        await offlineStorage.applyOfflineConsume(cellarId, bottleId);
      }

      // Only queue offline sync action if remote bottle push failed or tasting push failed
      if (!bottleSavedOnline || !tastingSavedOnline) {
        await offlineStorage.queueAction(OfflineAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OfflineActionType.consumeBottle,
          cellarId: cellarId,
          status: OfflineActionStatus.pending,
          data: {
            'bottle_id': bottleId,
            'cellar_id': cellarId,
            'wine_id': _selectedBottle!['wine_id'] as String? ?? '',
            'wine_name': wineName,
            'vintage': vintage,
            'region': wineMap?['region'] as String?,
            'country': wineMap?['country'] as String?,
            'appellation': wineMap?['appellation'] as String?,
            'rating': _rating.toDouble(),
            'food_paired': _foodController.text.trim(),
            'tasting_notes': _notesController.text.trim(),
            'co_tasters': _selectedCoTasters.toList(),
            if (ownerId != null) 'bottle_owner_id': ownerId,
            'bottle_owner_name': ownerName,
            'is_external': false,
            'quantity': _consumeCount,
          },
          createdAt: DateTime.now(),
        ));
      }

      // 3. Invalidate cellar & journal cache
      notifyCellarChanged(ref, cellarId);
      ref.invalidate(tastingLogProvider);

      // Reinforce taste profiles for primary user and all participants
      try {
        if (wineMap != null) {
          final wineObj = Wine.fromJson(wineMap);
          final tasteService = ref.read(tasteProfileServiceProvider);
          final primaryProfile = await tasteService.getPrimaryProfile();
          await tasteService.recordTastingExperience(
            nameOrId: primaryProfile.id,
            wine: wineObj,
            rating: _rating,
          );
          for (final coTaster in _selectedCoTasters) {
            await tasteService.recordTastingExperience(
              nameOrId: coTaster,
              wine: wineObj,
              rating: _rating,
            );
          }
          ref.invalidate(tasteProfilesListProvider);
        }
      } catch (e) {
        debugPrint('Taste profile reinforcement notice: $e');
      }

      // 4. Schedule post-tasting feedback notification (1h after checkout)
      try {
        final notifService = ref.read(postTastingNotificationProvider);
        await notifService.schedulePostCheckout(
          bottleId: bottleId,
          wineName: wineMap?['name'] as String? ?? 'Vin',
          vintage: (wineMap?['vintage'] as num?)?.toInt() ?? int.tryParse(wineMap?['vintage']?.toString() ?? ''),
          producer: wineMap?['producer'] as String?,
          region: wineMap?['region'] as String?,
          wineType: wineMap?['type'] as String?,
        );
      } catch (e) {
        debugPrint('Post-tasting notification scheduling notice: $e');
      }

      if (mounted) {
        final wineName = wineMap?['name'] as String? ?? 'Vin';
        final vintage = (wineMap?['vintage'] as num?)?.toInt() ?? int.tryParse(wineMap?['vintage']?.toString() ?? '');
        final producer = wineMap?['producer'] as String?;
        final region = wineMap?['region'] as String?;
        final wineType = wineMap?['type'] as String?;

        final advice = WineServiceAdvisor.computeAdvice(
          wineType: wineType,
          vintage: vintage,
          region: region,
          appellation: wineMap?['appellation'] as String?,
          producer: producer,
          wineName: wineName,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🥂 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dégustation enregistrée !',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        advice.carafeMinutes > 0
                            ? 'Conseil Sommelier : carafer ${advice.carafeMinutes} min. Chrono lockscreen prêt.'
                            : 'Rappel pour noter vos impressions prévu après dégustation.',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: advice.carafeMinutes > 0
                ? SnackBarAction(
                    label: 'Chrono ${advice.carafeMinutes}m ⏱️',
                    textColor: const Color(0xFFD4AF37),
                    onPressed: () {
                      ref.read(localNotificationServiceProvider).showLiveAerationNotification(
                        wineName: wineName,
                        vintage: vintage,
                        remainingSeconds: advice.carafeMinutes * 60,
                        bottleId: bottleId,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⏱️ Compte à rebours d\'aération actif sur votre écran de verrouillage !'),
                          backgroundColor: Color(0xFFD4AF37),
                        ),
                      );
                    },
                  )
                : SnackBarAction(
                    label: 'Noter le vin',
                    textColor: const Color(0xFFD4AF37),
                    onPressed: () {
                      final targetCtx = rootNavigatorKey.currentContext;
                      if (targetCtx != null && targetCtx.mounted) {
                        TastingQuestionnaireSheet.show(
                          targetCtx,
                          wineName: wineName,
                          vintage: vintage,
                          producer: producer,
                          region: region,
                          wineType: wineType,
                          wineId: wineMap?['id'] as String?,
                          bottleId: bottleId,
                          cellarId: cellarId,
                          preselectedTasters: _selectedCoTasters.toList(),
                          bottleOwnerId: ownerId,
                          bottleOwnerName: ownerName,
                        );
                      }
                    },
                  ),
            backgroundColor: const Color(0xFF8B1E3F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 7),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitDeferredCheckout() async {
    if (_selectedBottle == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    final bottleId = _selectedBottle!['id'] as String;
    final currentQty = _selectedBottle!['quantity'] as int? ?? 1;
    final cellarId = _selectedBottle!['cellar_id'] as String?;

    final canProceed = await _checkDistantCellarProceed(cellarId);
    if (!canProceed || !mounted) {
      setState(() => _isSubmitting = false);
      return;
    }

    final profilesData = _selectedBottle!['profiles'] as Map<String, dynamic>?;
    final bottleOwnerDisplayName = profilesData?['display_name'] as String?;
    final userDisplayName = (user?.userMetadata?['display_name'] as String?) ??
        (user?.userMetadata?['full_name'] as String?);
    final ownerName = bottleOwnerDisplayName ?? userDisplayName ?? 'Moi';
    final rawOwnerId = _selectedBottle!['owner_id']?.toString() ?? user?.id;
    final ownerId = _isValidUuid(rawOwnerId) ? rawOwnerId : (_isValidUuid(user?.id) ? user!.id : null);
    final wineMap = _selectedBottle!['wines'] as Map<String, dynamic>?;
    final wineName = wineMap?['name'] as String? ?? 'Vin';
    final vintage = (wineMap?['vintage'] as num?)?.toInt() ?? int.tryParse(wineMap?['vintage']?.toString() ?? '');
    final producer = wineMap?['producer'] as String?;
    final region = wineMap?['region'] as String?;
    final wineType = wineMap?['type'] as String?;

    try {
      bool tastingSavedOnline = false;
      bool bottleSavedOnline = false;
      final offlineStorage = ref.read(offlineStorageServiceProvider);
      final wineId = _selectedBottle!['wine_id'] as String? ?? wineMap?['id'] as String?;
      final effectiveCellarId = cellarId ?? ref.read(currentCellarIdProvider);
      final deferredNotes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'Débouché • Dégustation à noter ultérieurement';

      final localDeferredEntry = <String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'wine_id': wineId ?? '',
        if (_isValidUuid(bottleId)) 'bottle_id': bottleId,
        'user_id': user?.id,
        if (_isValidUuid(effectiveCellarId)) 'cellar_id': effectiveCellarId,
        'rating': _rating,
        'food_paired': _foodController.text.trim(),
        'tasting_notes': deferredNotes,
        'co_tasters': _selectedCoTasters.toList(),
        if (ownerId != null) 'bottle_owner_id': ownerId,
        'bottle_owner_name': ownerName,
        'is_external': false,
        'consumed_at': DateTime.now().toIso8601String(),
        'wines': wineMap ?? {
          'name': wineName,
          'vintage': vintage,
          'region': region,
          'type': wineType,
        },
      };

      // 1. Record provisional tasting log entry
      if (user != null && wineId != null && wineId.isNotEmpty) {
        final payload = <String, dynamic>{
          'wine_id': wineId,
          if (_isValidUuid(bottleId)) 'bottle_id': bottleId,
          'user_id': user.id,
          if (_isValidUuid(effectiveCellarId)) 'cellar_id': effectiveCellarId,
          'rating': _rating,
          'food_paired': _foodController.text.trim(),
          'tasting_notes': deferredNotes,
          'co_tasters': _selectedCoTasters.toList(),
          if (ownerId != null) 'bottle_owner_id': ownerId,
          'bottle_owner_name': ownerName,
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
            await offlineStorage.addCachedTasting(localDeferredEntry);
          }
          tastingSavedOnline = true;
        } catch (insertErr) {
          debugPrint('Deferred tasting log primary insert notice ($insertErr), retrying with core schema...');
          final corePayload = <String, dynamic>{
            'wine_id': wineId,
            if (_isValidUuid(bottleId)) 'bottle_id': bottleId,
            'user_id': user.id,
            if (_isValidUuid(effectiveCellarId)) 'cellar_id': effectiveCellarId,
            'rating': _rating,
            'food_paired': _foodController.text.trim(),
            'tasting_notes': deferredNotes,
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
              await offlineStorage.addCachedTasting(localDeferredEntry);
            }
            tastingSavedOnline = true;
          } catch (coreErr) {
            debugPrint('Deferred tasting log core insert notice ($coreErr), retrying with normalized rating...');
            try {
              corePayload['rating'] = (_rating / 2.0).clamp(0.0, 5.0);
              final inserted = await supabase
                  .from('tasting_log')
                  .insert(corePayload)
                  .select('*, wines(*)')
                  .maybeSingle();
              if (inserted != null) {
                inserted['rating'] = _rating;
                await offlineStorage.addCachedTasting(inserted);
              } else {
                await offlineStorage.addCachedTasting(localDeferredEntry);
              }
              tastingSavedOnline = true;
            } catch (retryErr) {
              debugPrint('Deferred tasting log retry insert notice: $retryErr');
              await offlineStorage.addCachedTasting(localDeferredEntry);
              tastingSavedOnline = false;
            }
          }
        }
      } else {
        await offlineStorage.addCachedTasting(localDeferredEntry);
      }

      // 2. Decrement bottle quantity or mark as consumed
      try {
        if (currentQty > _consumeCount) {
          await supabase
              .from('bottles')
              .update({'quantity': currentQty - _consumeCount})
              .eq('id', bottleId);
        } else {
          await supabase
              .from('bottles')
              .update({
                'quantity': 0,
                'status': 'consumed',
                'consumed_at': DateTime.now().toIso8601String(),
              })
              .eq('id', bottleId);
        }
        bottleSavedOnline = true;
      } catch (e) {
        debugPrint('Deferred checkout offline fallback: $e');
        bottleSavedOnline = false;
      }

      if (cellarId != null) {
        await offlineStorage.applyOfflineConsume(cellarId, bottleId);
      }

      if (!bottleSavedOnline || !tastingSavedOnline) {
        await offlineStorage.queueAction(OfflineAction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OfflineActionType.consumeBottle,
          cellarId: cellarId,
          status: OfflineActionStatus.pending,
          data: {
            'bottle_id': bottleId,
            'cellar_id': cellarId,
            'wine_id': _selectedBottle!['wine_id'] as String? ?? '',
            'wine_name': wineName,
            'vintage': vintage,
            'region': region,
            'rating': _rating.toDouble(),
            'tasting_notes': deferredNotes,
            'co_tasters': _selectedCoTasters.toList(),
            if (ownerId != null) 'bottle_owner_id': ownerId,
            'bottle_owner_name': ownerName,
            'is_external': false,
            'quantity': _consumeCount,
          },
          createdAt: DateTime.now(),
        ));
      }

      notifyCellarChanged(ref, cellarId);
      ref.invalidate(tastingLogProvider);

      // 3. Schedule next morning reminder at 11:00 AM
      DateTime scheduledTarget = DateTime.now().add(const Duration(hours: 14));
      try {
        final notifService = ref.read(postTastingNotificationProvider);
        scheduledTarget = await notifService.scheduleNextMorning(
          bottleId: bottleId,
          wineName: wineName,
          vintage: vintage,
          producer: producer,
          region: region,
          wineType: wineType,
        );
      } catch (e) {
        debugPrint('Next morning notification scheduling notice: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B1622),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            content: Row(
              children: [
                const Text('🌙 ', style: TextStyle(fontSize: 22)),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bouteille sortie de cave !',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Profitez de votre soirée. Rappel prévu demain à ${scheduledTarget.hour}h${scheduledTarget.minute.toString().padLeft(2, '0')} pour noter vos impressions.',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showStorytellingSheet() async {
    if (_selectedBottle == null) return;
    final wine = _selectedBottle!['wines'] as Map<String, dynamic>? ?? {};
    final wineName = wine['name']?.toString() ?? 'Vin';
    final vintage = (wine['vintage'] as num?)?.toInt() ?? int.tryParse(wine['vintage']?.toString() ?? '');
    final producer = wine['producer']?.toString();
    final region = wine['region']?.toString();
    final appellation = wine['appellation']?.toString();
    final wineType = (wine['type'] ?? wine['wine_type'] ?? 'red').toString();
    final grapes = wine['grapes'] is List ? List<String>.from(wine['grapes']) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WineStorytellingSheet(
        wineName: wineName,
        vintage: vintage,
        producer: producer,
        region: region,
        appellation: appellation,
        wineType: wineType,
        grapes: grapes,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.checkoutTitle ?? 'Déguster & Sortir de la Cave')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Bottle Selection View (if not preselected)
    if (_selectedBottle == null) {
      final filteredList = _cellarBottles.where((b) {
        if (_searchQuery.isEmpty) return true;
        final wine = b['wines'] as Map<String, dynamic>? ?? {};
        final name = (wine['name'] ?? '').toString().toLowerCase();
        final producer = (wine['producer'] ?? '').toString().toLowerCase();
        final vintage = (wine['vintage'] ?? '').toString();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || producer.contains(q) || vintage.contains(q);
      }).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.checkoutTitle ?? 'Déguster & Sortir de la Cave'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: l10n?.searchWinePlaceholder ?? 'Rechercher une bouteille dans votre cave...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wine_bar_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(100)),
                          const SizedBox(height: 12),
                          Text(l10n?.emptyCellarTitle ?? 'Aucune bouteille disponible', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final b = filteredList[index];
                        final wine = b['wines'] as Map<String, dynamic>? ?? {};
                        final wineName = wine['name'] ?? 'Vin';
                        final vintage = wine['vintage'] != null ? ' (${wine['vintage']})' : '';
                        final producer = wine['producer'] ?? 'Domaine inconnu';
                        final qty = b['quantity'] as int? ?? 1;

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withAlpha(80),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.wine_bar, color: theme.colorScheme.primary),
                            ),
                            title: Text('$wineName$vintage', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$producer • En stock : $qty bouteille${qty > 1 ? "s" : ""}'),
                            trailing: FilledButton.tonal(
                              onPressed: () => setState(() => _selectedBottle = b),
                              child: Text(l10n?.bottleDetailDrinkButton ?? 'Déguster'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final wine = _selectedBottle!['wines'] as Map<String, dynamic>? ?? {};
    final wineName = wine['name'] ?? (isFr ? 'Vin' : 'Wine');
    final vintage = wine['vintage'] != null ? '${wine['vintage']}' : (isFr ? 'NM' : 'NV');
    final producer = wine['producer'] ?? 'Domaine';
    final region = wine['region'] as String? ?? '';
    final wineType = (wine['type'] ?? wine['wine_type'] ?? 'red').toString();
    final isWhite = wineType.toLowerCase().contains('blanc') || wineType.toLowerCase().contains('white');
    final isRose = wineType.toLowerCase().contains('rose') || wineType.toLowerCase().contains('rosé');
    final isSparkling = wineType.toLowerCase().contains('effervescent') ||
        wineType.toLowerCase().contains('champagne') ||
        wineType.toLowerCase().contains('petillant') ||
        wineType.toLowerCase().contains('sparkling');
    final isRed = !isWhite && !isRose && !isSparkling;
    final maxQty = _selectedBottle!['quantity'] as int? ?? 1;

    final profilesData = _selectedBottle!['profiles'] as Map<String, dynamic>?;
    final ownerDisplayName = profilesData?['display_name'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.checkoutTitle ?? 'Déguster & Sortir de la Cave'),
        leading: widget.bottleId == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedBottle = null),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Bottle Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E3F).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B1E3F).withAlpha(60)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.wine_bar, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            WineTypeBadge(type: wineType),
                            if (ownerDisplayName != null && ownerDisplayName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Cave de $ownerDisplayName',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              'Stock : $maxQty bout.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$wineName ($vintage)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          producer,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sommelier Immediate Service Advice & Storytelling Card
            _buildSommelierServiceCard(theme, wine, wineName, vintage, producer, region, wineType),
            const SizedBox(height: 20),

            // Number of bottles consumed
            if (maxQty > 1) ...[
              Text(l10n?.checkoutQtyOpened ?? 'Nombre de bouteilles ouvertes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _consumeCount > 1 ? () => setState(() => _consumeCount--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_consumeCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton.filledTonal(
                    onPressed: _consumeCount < maxQty ? () => setState(() => _consumeCount++) : null,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n?.checkoutQtyOfTotal(maxQty) ?? 'sur $maxQty en cave', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 10-point Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n?.checkoutRating ?? 'Note de dégustation', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${_rating.toStringAsFixed(1)} / 10',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Slider(
              value: _rating,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              activeColor: const Color(0xFFD4AF37),
              label: '${_rating.toStringAsFixed(1)} / 10',
              onChanged: (val) {
                setState(() => _rating = val);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('1.0', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  _rating >= 9.5 ? '🏆 Exceptionnel' : (_rating >= 8.5 ? '✨ Remarquable' : (_rating >= 7.5 ? '🍷 Très bon' : (_rating >= 6.0 ? '👍 Agréable' : 'Passable'))),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                ),
                const Text('10.0', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),

            // Convives, Famille & Amis Co-dégustateurs
            Row(
              children: [
                const Icon(Icons.people_alt, color: Color(0xFF8B1E3F), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Qui a dégusté ce vin avec vous ?',
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
              'Les goûts de chaque participant seront automatiquement enrichis dans son profil.',
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

            // Food paired
            TextField(
              controller: _foodController,
              decoration: InputDecoration(
                labelText: l10n?.checkoutFoodPairing ?? 'Mets & Accords associés (optionnel)',
                hintText: l10n?.checkoutFoodHint ?? 'Ex: Côte de bœuf grillée, Risotto aux truffes...',
                prefixIcon: const Icon(Icons.restaurant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Tasting Impressions / Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n?.checkoutNotes ?? 'Impressions & Commentaires de dégustation',
                hintText: isRed
                    ? (l10n?.checkoutNotesHint ?? 'Arômes, équilibre des tanins, fraîcheur, moment partagé...')
                    : 'Arômes, minéralité, vivacité, fraîcheur, accords mets...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.edit_note),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            // Reassuring clarification for beginners / forgetful users
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_stories_outlined, size: 18, color: Color(0xFF8B1E3F)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rassurez-vous : cette bouteille sera précieusement archivée dans votre Journal de Dégustation avec vos photos et notes.',
                      style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Dégustation guidée (Primary & Recommended)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B1E3F), Color(0xFF6B1730)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSubmitting ? null : _startGuidedTasting,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Dégustation guidée',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text('✨', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _selectedCoTasters.isNotEmpty
                                    ? 'Partagez vos impressions chacun son tour ou ensemble'
                                    : 'Analysez robe, nez, bouche & affinez votre profil',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Déboucher maintenant, noter plus tard 🌙
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF241D2B)
                    : const Color(0xFFF9F5F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.45)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSubmitting ? null : _submitDeferredCheckout,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.nightlight_round, color: Color(0xFFD4AF37), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Déboucher maintenant, noter plus tard',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text('🌙', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sortie immédiate • Rappel automatique demain matin',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.schedule, color: theme.colorScheme.onSurfaceVariant, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 3: Sortie rapide (Tertiary / Outlined)
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _submitCheckout,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bolt, color: Color(0xFF8B1E3F)),
              label: Text(
                _isSubmitting ? 'Sortie en cours...' : 'Sortie rapide sans questionnaire ⚡',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B1E3F),
                side: BorderSide(color: const Color(0xFF8B1E3F).withValues(alpha: 0.4)),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSommelierServiceCard(
    ThemeData theme,
    Map<String, dynamic> wine,
    String wineName,
    String vintage,
    String producer,
    String region,
    String wineType,
  ) {
    final vInt = int.tryParse(vintage);
    final advice = WineServiceAdvisor.computeAdvice(
      wineType: wineType,
      vintage: vInt,
      region: region,
      appellation: wine['appellation'] as String?,
      producer: producer,
      wineName: wineName,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.wine_bar, color: Color(0xFFD4AF37), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Conseils Sommelier de Service',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
              ),
              const Spacer(),
              InkWell(
                onTap: _showStorytellingSheet,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories, size: 13, color: Color(0xFF8B1E3F)),
                      SizedBox(width: 4),
                      Text(
                        'Histoire & Anecdotes',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _serviceBadge(Icons.thermostat, advice.tempLabel, Colors.blue.shade300),
              _serviceBadge(
                Icons.hourglass_bottom,
                advice.carafeMinutes > 0 ? advice.carafeLabel : 'Pas de carafage',
                advice.carafeMinutes > 0 ? Colors.amber.shade400 : Colors.green.shade400,
              ),
              _serviceBadge(Icons.wine_bar_outlined, advice.glasswareType, Colors.purple.shade300),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            advice.decantingAdvice,
            style: const TextStyle(fontSize: 11.5, height: 1.35, color: Colors.grey),
          ),
          if (advice.carafeMinutes > 0) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFF8B1E3F),
                ),
                onPressed: () {
                  final notif = ref.read(localNotificationServiceProvider);
                  notif.showLiveAerationNotification(
                    wineName: wineName,
                    remainingSeconds: advice.carafeMinutes * 60,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⏱️ Chrono d\'aération (${advice.carafeMinutes} min) lancé sur l\'écran de verrouillage !'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.timer_outlined, size: 15),
                label: Text('Lancer le chrono (${advice.carafeMinutes}m) ⏱️', style: const TextStyle(fontSize: 11.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _serviceBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _WineStorytellingSheet extends ConsumerStatefulWidget {
  final String wineName;
  final int? vintage;
  final String? producer;
  final String? region;
  final String? appellation;
  final String? wineType;
  final List<String>? grapes;

  const _WineStorytellingSheet({
    required this.wineName,
    this.vintage,
    this.producer,
    this.region,
    this.appellation,
    this.wineType,
    this.grapes,
  });

  @override
  ConsumerState<_WineStorytellingSheet> createState() => _WineStorytellingSheetState();
}

class _WineStorytellingSheetState extends ConsumerState<_WineStorytellingSheet> {
  WineStorytellingData? _storyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStory();
  }

  Future<void> _fetchStory() async {
    try {
      final ai = ref.read(tastingAiAssistantServiceProvider);
      final data = await ai.generateWineStorytelling(
        wineName: widget.wineName,
        vintage: widget.vintage,
        producer: widget.producer,
        region: widget.region,
        appellation: widget.appellation,
        wineType: widget.wineType,
        grapes: widget.grapes,
      );
      if (mounted) {
        setState(() {
          _storyData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _storyData = WineStorytellingData.fallback(
            wineName: widget.wineName,
            vintage: widget.vintage,
            region: widget.region ?? widget.appellation,
            grape: widget.grapes?.isNotEmpty == true ? widget.grapes!.first : null,
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_stories, color: Color(0xFFD4AF37), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'L\'Histoire de cette Bouteille 📖',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Anecdotes captivantes à raconter à table',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFD4AF37)),
                        SizedBox(height: 14),
                        Text('Le sommelier prépare les anecdotes de dégustation...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      _storyCard(
                        icon: Icons.landscape,
                        title: 'Terroir & Cépages',
                        content: _storyData!.terroirAndGrape,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 12),
                      _storyCard(
                        icon: Icons.wb_sunny_outlined,
                        title: 'L\'Histoire du Millésime',
                        content: _storyData!.vintageClimate,
                        color: Colors.amber.shade400,
                      ),
                      const SizedBox(height: 12),
                      _storyCard(
                        icon: Icons.wine_bar,
                        title: 'Le Secret de Dégustation',
                        content: _storyData!.sommelierTip,
                        color: const Color(0xFF8B1E3F),
                      ),
                      const SizedBox(height: 12),
                      _storyCard(
                        icon: Icons.lightbulb_outline,
                        title: 'L\'Anecdote de Table',
                        content: _storyData!.funFact,
                        color: Colors.blue.shade400,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer & Déguster 🍷', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _storyCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

