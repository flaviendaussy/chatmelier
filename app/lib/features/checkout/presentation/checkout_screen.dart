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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseProvider);
    var cellarId = ref.read(currentCellarIdProvider);

    try {
      _friends = await ref.read(friendsRepositoryProvider).getFriends();
      _companionProfiles = await ref.read(tasteProfileServiceProvider).getProfiles();
      if (widget.bottleId != null && widget.bottleId!.isNotEmpty) {
        final res = await supabase
            .from('bottles')
            .select('*, wines(*)')
            .eq('id', widget.bottleId!)
            .single();
        _selectedBottle = res;
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
          final res = await supabase
              .from('bottles')
              .select('*, wines(*)')
              .eq('cellar_id', cellarId)
              .eq('status', 'in_cellar')
              .order('created_at', ascending: false);
          _cellarBottles = List<Map<String, dynamic>>.from(res);
        } else {
          final res = await supabase
              .from('bottles')
              .select('*, wines(*)')
              .eq('status', 'in_cellar')
              .order('created_at', ascending: false);
          _cellarBottles = List<Map<String, dynamic>>.from(res);
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

  Future<void> _submitCheckout() async {
    if (_selectedBottle == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    final bottleId = _selectedBottle!['id'] as String;
    final currentQty = _selectedBottle!['quantity'] as int? ?? 1;
    final cellarId = _selectedBottle!['cellar_id'] as String?;

    if (cellarId != null) {
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

          if (proceed != true) {
            setState(() => _isSubmitting = false);
            return;
          }
        }
      }
    }

    final ownerName = (_selectedBottle!['profiles'] as Map<String, dynamic>?)?['display_name'] as String? ??
        (user?.userMetadata?['display_name'] as String?) ??
        'Moi';
    final ownerId = _selectedBottle!['owner_id'] as String? ?? user?.id;

    try {
      bool savedOnline = false;
      // 1. Record tasting log
      if (user != null) {
        try {
          await supabase.from('tasting_log').insert({
            'bottle_id': bottleId,
            'user_id': user.id,
            'rating': _rating,
            'food_paired': _foodController.text.trim(),
            'tasting_notes': _notesController.text.trim(),
            'co_tasters': _selectedCoTasters.toList(),
            'bottle_owner_id': ownerId,
            'bottle_owner_name': ownerName,
            'is_external': false,
            'consumed_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Tasting log table insert notice: $e');
        }
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
        savedOnline = true;
      } catch (e) {
        debugPrint('Checkout offline fallback: $e');
        savedOnline = false;
      }

    final offlineStorage = ref.read(offlineStorageServiceProvider);
    final wineMap = _selectedBottle!['wines'] as Map<String, dynamic>?;

    // Apply immediate local cache update
    if (cellarId != null) {
      await offlineStorage.applyOfflineConsume(cellarId, bottleId);
    }

    // Only queue offline sync action if remote push failed
    if (!savedOnline) {
      await offlineStorage.queueAction(OfflineAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: OfflineActionType.consumeBottle,
        cellarId: cellarId,
        status: OfflineActionStatus.pending,
        data: {
          'bottle_id': bottleId,
          'cellar_id': cellarId,
          'wine_id': _selectedBottle!['wine_id'] as String? ?? '',
          'wine_name': wineMap?['name'] as String? ?? 'Vin dégusté',
          'vintage': (wineMap?['vintage'] as num?)?.toInt() ?? int.tryParse(wineMap?['vintage']?.toString() ?? ''),
          'region': wineMap?['region'] as String?,
          'country': wineMap?['country'] as String?,
          'appellation': wineMap?['appellation'] as String?,
          'rating': _rating.toDouble(),
          'food_paired': _foodController.text.trim(),
          'tasting_notes': _notesController.text.trim(),
          'co_tasters': _selectedCoTasters.toList(),
          'bottle_owner_id': ownerId,
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
          await tasteService.recordTastingExperience(
            nameOrId: 'primary',
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Text('🥂 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Dégustation enregistrée ! Rappel prévu dans 1h.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
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
                  );
                }
              },
            ),
            backgroundColor: const Color(0xFF8B1E3F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
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
    final wineType = wine['wine_type'] ?? 'red';
    final maxQty = _selectedBottle!['quantity'] as int? ?? 1;

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
            const SizedBox(height: 24),

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
                hintText: l10n?.checkoutNotesHint ?? 'Arômes, équilibre des tanins, fraîcheur, moment partagé...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.edit_note),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitCheckout,
              icon: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.celebration, color: Colors.white),
              label: Text(
                _isSubmitting ? 'Enregistrement...' : '${l10n?.checkoutSubmit ?? "Valider la dégustation"} 🥂',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFF8B1E3F).withValues(alpha: 0.4),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
