import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../../../shared/widgets/drinking_window_badge.dart';
import '../../../shared/widgets/gaussian_drinking_curve.dart';
import '../../../shared/widgets/grape_chart.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../../../shared/widgets/bottle_image_view.dart';
import '../domain/bottle.dart';
import '../domain/wine.dart';
import '../domain/wine_image_service.dart';
import '../domain/wine_service_advisor.dart';
import '../../../l10n/app_localizations.dart';
import '../../scan/presentation/review_screen.dart';
import '../../scan/data/scan_service.dart';
import 'terroir_map_view.dart';
import 'delete_bottle_dialog.dart';
import 'sommelier_table_mode_sheet.dart';
import 'bottle_edit_sheet.dart';
import 'shelf_grid_view_sheet.dart';
import 'widgets/furniture_graphic_card.dart';
import 'wine_enrichment_diff_dialog.dart';
import 'wine_reverse_food_pairing_sheet.dart';
import 'spirit_bottle_fill_view.dart';
import '../../offline/presentation/sync_provider.dart';
import '../data/vineyard_knowledge_service.dart';

class BottleDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BottleDetailScreen({super.key, required this.id});

  @override
  ConsumerState<BottleDetailScreen> createState() => _BottleDetailScreenState();
}

class _BottleDetailScreenState extends ConsumerState<BottleDetailScreen> {
  Map<String, dynamic>? _bottleData;
  String? _labelPhotoUrl;
  bool _isLoading = true;
  bool _isEnriching = false;
  String? _error;

  final _apogeeKey = GlobalKey();
  final _fillLevelKey = GlobalKey();
  final _serviceKey = GlobalKey();
  final _terroirKey = GlobalKey();
  final _grapesKey = GlobalKey();
  final _elevageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadBottleDetails();
  }

  Future<void> _loadBottleDetails() async {
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseProvider);

    try {
      final res = await supabase
          .from('bottles')
          .select('*, wines(*), bottle_photos(storage_path), profiles!bottles_owner_id_fkey(display_name, avatar_url), cellars(name, nickname)')
          .eq('id', widget.id)
          .single()
          .timeout(const Duration(seconds: 10));

      // Check for uploaded bottle photo
      String? photoUrl;
      final photosList = res['bottle_photos'] as List?;
      if (photosList != null && photosList.isNotEmpty) {
        photoUrl = (photosList.first as Map<String, dynamic>)['storage_path'] as String?;
      }

      final winesMap = res['wines'] as Map<String, dynamic>?;
      if ((photoUrl == null || photoUrl.isEmpty) && winesMap != null) {
        photoUrl = winesMap['image_url'] as String? ?? 
            (winesMap['external_links'] is Map ? (winesMap['external_links'] as Map)['image_url'] as String? : null);
      }

      final wineObj = winesMap != null ? Wine.fromJson(winesMap) : null;
      if (photoUrl == null || !WineImageService.isValidImagePath(photoUrl)) {
        if (wineObj != null) {
          photoUrl = WineImageService.resolveWineImageUrl(wineObj);
        }
      }

      if (mounted) {
        setState(() {
          _bottleData = res;
          _labelPhotoUrl = photoUrl;
          _isLoading = false;
        });

        try {
          final offline = ref.read(offlineStorageServiceProvider);
          offline.applyOfflineUpdateBottle(widget.id, {
            'furniture_id': res['furniture_id'],
            'furniture_slot': res['furniture_slot'],
            'rack': res['rack'],
            'shelf': res['shelf'],
            'position': res['position'],
            'quantity': res['quantity'],
            'status': res['status'],
            'notes': res['notes'],
          });
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('BottleDetailScreen offline fallback: $e');
      final offline = ref.read(offlineStorageServiceProvider);
      final cellars = offline.getCachedCellars();
      Bottle? foundBottle;
      for (final c in cellars) {
        final cached = offline.getCachedBottles(c.id);
        final match = cached.where((b) => b.id == widget.id);
        if (match.isNotEmpty) {
          foundBottle = match.first;
          break;
        }
      }

      if (foundBottle != null) {
        final resolvedImg = WineImageService.isValidImagePath(foundBottle.photoUrl)
            ? foundBottle.photoUrl
            : (WineImageService.isValidImagePath(foundBottle.wine?.imageUrl)
                ? foundBottle.wine?.imageUrl
                : (foundBottle.wine != null ? WineImageService.resolveWineImageUrl(foundBottle.wine) : null));

        if (mounted) {
          setState(() {
            _bottleData = {
              'id': foundBottle!.id,
              'cellar_id': foundBottle.cellarId,
              'wine_id': foundBottle.wineId,
              'added_by': foundBottle.addedBy,
              'owner_id': foundBottle.ownerId,
              'quantity': foundBottle.quantity,
              'purchase_price': foundBottle.purchasePrice,
              'currency': foundBottle.currency,
              'rack': foundBottle.rack,
              'shelf': foundBottle.shelf,
              'position': foundBottle.position,
              'status': foundBottle.status,
              'notes': foundBottle.notes,
              'created_at': foundBottle.createdAt.toIso8601String(),
              'wines': foundBottle.wine?.toJson() ?? {},
              'profiles': null,
              'cellars': {'name': 'Cave', 'nickname': 'Cave'},
              'fill_level': foundBottle.fillLevel,
              'furniture_id': foundBottle.furnitureId,
              'furniture_slot': foundBottle.furnitureSlot,
              'bottle_size': foundBottle.bottleSize,
              'purchase_location': foundBottle.purchaseLocation,
              'source_type': foundBottle.sourceType,
              'source_details': foundBottle.sourceDetails,
              'purchase_date': foundBottle.purchaseDate?.toIso8601String(),
            };
            _labelPhotoUrl = resolvedImg;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showPhotoOptions(Wine wine) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode != 'en';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1A1B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  child: const Icon(Icons.photo_camera_back, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  isFr ? 'Photo & Étiquette' : 'Photo & Label',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFD4AF37)),
              title: Text(isFr ? 'Prendre une photo' : 'Take a photo'),
              subtitle: Text(isFr ? 'Photographier l\'étiquette de cette bouteille' : 'Photograph this bottle\'s label'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndSetPhoto(ImageSource.camera, wine);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFD4AF37)),
              title: Text(isFr ? 'Choisir depuis la galerie' : 'Choose from gallery'),
              subtitle: Text(isFr ? 'Sélectionner une photo existante' : 'Select an existing photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndSetPhoto(ImageSource.gallery, wine);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Color(0xFF722F37)),
              title: Text(isFr ? 'Restaurer l\'étiquette officielle' : 'Restore official label'),
              subtitle: Text(isFr ? 'Appliquer le visuel haute résolution du domaine' : 'Apply high-resolution estate visual'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final officialImg = WineImageService.resolveWineImageUrl(wine, forceDomainOrArchetype: true);
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                setState(() {
                  _labelPhotoUrl = officialImg;
                  if (_bottleData != null) {
                    _bottleData!['photo_url'] = null;
                    if (_bottleData!['wines'] is Map) {
                      (_bottleData!['wines'] as Map)['image_url'] = officialImg;
                    }
                  }
                });
                final repo = ref.read(cellarRepositoryProvider);
                await repo.updateBottle(widget.id, photoUrl: '');
                await repo.updateWine(wine.id, imageUrl: officialImg);
                final currentCellar = ref.read(currentCellarIdProvider);
                notifyCellarChanged(ref, currentCellar);
                if (mounted) {
                  final snackFr = Localizations.localeOf(context).languageCode != 'en';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(snackFr ? '✨ Étiquette officielle du domaine appliquée !' : '✨ Official estate label applied!'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSetPhoto(ImageSource source, Wine wine) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      setState(() {
        _labelPhotoUrl = picked.path;
        if (_bottleData != null) {
          _bottleData!['photo_url'] = picked.path;
          if (_bottleData!['wines'] is Map) {
            (_bottleData!['wines'] as Map)['image_url'] = picked.path;
          }
        }
      });

      // Save to bottle repo and wine repo
      final repo = ref.read(cellarRepositoryProvider);
      await repo.updateBottle(widget.id, photoUrl: picked.path);
      await repo.updateWine(wine.id, imageUrl: picked.path);

      // Upload to Supabase storage if online
      try {
        final scanService = ScanService(ref.read(supabaseProvider));
        final bytes = await picked.readAsBytes();
        final publicUrl = await scanService.uploadPhoto(
          bottleId: widget.id,
          imagePath: picked.path,
          imageBytes: bytes,
        );
        if (publicUrl != null) {
          await repo.updateBottle(widget.id, photoUrl: publicUrl);
          await repo.updateWine(wine.id, imageUrl: publicUrl);
          if (mounted) {
            setState(() {
              _labelPhotoUrl = publicUrl;
              if (_bottleData != null) {
                _bottleData!['photo_url'] = publicUrl;
                if (_bottleData!['wines'] is Map) {
                  (_bottleData!['wines'] as Map)['image_url'] = publicUrl;
                }
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Photo upload notice: $e');
      }

      final currentCellar = ref.read(currentCellarIdProvider);
      notifyCellarChanged(ref, currentCellar);

      if (mounted) {
        final snackFr = Localizations.localeOf(context).languageCode != 'en';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackFr ? '📸 Photo de la bouteille enregistrée avec succès !' : '📸 Bottle photo saved successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  void _showFullEditSheet(Wine wine, Bottle bottle) {
    BottleEditSheet.show(
      context,
      bottle: bottle,
      wine: wine,
      onSaved: () {
        _loadBottleDetails();
      },
    );
  }

  void _showQuickEditPersonalNotes(Bottle bottleObj) {
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final textCtrl = TextEditingController(text: bottleObj.notes ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      child: const Icon(Icons.edit_note, color: Color(0xFF8B1E3F), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFr ? 'Mes Notes & Commentaires' : 'My Notes & Comments',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            isFr ? 'Privé • Strictement réservé à votre usage' : 'Private • Strictly for your personal use',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: isFr ? 'Vos impressions, circonstances d\'achat, potentiel ressenti...' : 'Your impressions, purchase context, perceived potential...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (bottleObj.notes != null && bottleObj.notes!.trim().isNotEmpty) ...[
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final repo = ref.read(cellarRepositoryProvider);
                          await repo.updateBottle(bottleObj.id, notes: null);
                          setState(() {
                            if (_bottleData != null) _bottleData!['notes'] = null;
                          });
                          await _loadBottleDetails();
                          final currentCellar = ref.read(currentCellarIdProvider);
                          notifyCellarChanged(ref, currentCellar);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFr ? '🗑️ Note personnelle effacée' : '🗑️ Personal note cleared'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        label: Text(isFr ? 'Effacer' : 'Clear', style: const TextStyle(color: Colors.redAccent)),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(isFr ? 'Annuler' : 'Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final val = textCtrl.text.trim();
                        final newNotes = val.isEmpty ? null : val;
                        Navigator.pop(ctx);
                        final repo = ref.read(cellarRepositoryProvider);
                        await repo.updateBottle(bottleObj.id, notes: newNotes);
                        setState(() {
                          if (_bottleData != null) _bottleData!['notes'] = newNotes;
                        });
                        await _loadBottleDetails();
                        final currentCellar = ref.read(currentCellarIdProvider);
                        notifyCellarChanged(ref, currentCellar);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFr ? '✅ Note personnelle enregistrée !' : '✅ Personal note saved!'),
                              backgroundColor: const Color(0xFF2E7D32),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isFr ? 'Enregistrer' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _enrichWineData(Wine wine) async {
    if (_isEnriching) return;
    setState(() => _isEnriching = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final scanService = ScanService(supabase);
      final isFr = mounted ? Localizations.localeOf(context).languageCode != 'en' : true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isFr
                      ? 'Chatmelier recherche les données et cépages manquants...'
                      : 'Chatmelier is searching for missing data and grape varieties...',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      final enriched = await scanService.enrichWineData(
        wineName: wine.name,
        producer: wine.producer,
        vintage: wine.vintage,
        country: wine.country,
        region: wine.region,
        subRegion: wine.subRegion,
        appellation: wine.appellation,
        classification: wine.classification,
        wineType: wine.type,
      );

      // Parse grapes
      final rawGrapes = enriched['grapes'] as List<dynamic>?;
      final grapes = rawGrapes?.map((g) => Grape.fromJson(g)).toList() ?? [];

      // Check for conflicts on manually overridden fields
      final overrides = wine.userOverrides.toSet();
      bool hasConflict = false;

      void testConflict(String key, dynamic currentVal, dynamic aiVal) {
        if (aiVal == null) return;
        if (overrides.contains(key)) {
          final s1 = currentVal?.toString().trim().toLowerCase() ?? '';
          final s2 = aiVal.toString().trim().toLowerCase();
          if (s1.isNotEmpty && s2.isNotEmpty && s1 != s2) {
            hasConflict = true;
          }
        }
      }

      testConflict('peak_drinking_start', wine.peakStart, enriched['peak_drinking_start']);
      testConflict('peak_drinking_end', wine.peakEnd, enriched['peak_drinking_end']);
      testConflict('ideal_drinking_start', wine.drinkStart, enriched['ideal_drinking_start']);
      testConflict('ideal_drinking_end', wine.drinkEnd, enriched['ideal_drinking_end']);
      testConflict('alcohol_pct', wine.alcoholPct, enriched['alcohol_pct']);
      testConflict('region', wine.region, enriched['region']);
      testConflict('country', wine.country, enriched['country']);
      testConflict('appellation', wine.appellation, enriched['appellation']);
      testConflict('producer', wine.producer, enriched['producer']);
      testConflict('name', wine.name, enriched['name']);
      testConflict('cuvee_parcel', wine.cuveeParcel, enriched['cuvee_parcel']);
      testConflict('classification', wine.classification, enriched['classification']);
      testConflict('tasting_notes', wine.tastingNotes, enriched['tasting_notes']);

      if (overrides.contains('grapes') && grapes.isNotEmpty) {
        final currentG = wine.grapes.map((g) => g.name).join(', ').toLowerCase();
        final aiG = grapes.map((g) => g.name).join(', ').toLowerCase();
        if (currentG.isNotEmpty && currentG != aiG) {
          hasConflict = true;
        }
      }

      if (hasConflict && mounted) {
        await WineEnrichmentDiffDialog.show(
          context,
          currentWine: wine,
          enrichedData: enriched,
          enrichedGrapes: grapes,
          onApply: (finalPayload, updatedOverrides) async {
            final repo = ref.read(cellarRepositoryProvider);
            await repo.updateWine(
              wine.id,
              name: finalPayload['name'] as String?,
              producer: finalPayload['producer'] as String?,
              vintage: (finalPayload['vintage'] as num?)?.toInt() ?? int.tryParse(finalPayload['vintage']?.toString() ?? ''),
              wineType: finalPayload['wine_type'] as String?,
              country: finalPayload['country'] as String?,
              region: finalPayload['region'] as String?,
              subRegion: finalPayload['sub_region'] as String?,
              appellation: finalPayload['appellation'] as String?,
              classification: finalPayload['classification'] as String?,
              cuveeParcel: finalPayload['cuvee_parcel'] as String?,
              alcoholPct: (finalPayload['alcohol_pct'] as num?)?.toDouble(),
              idealDrinkingStart: (finalPayload['ideal_drinking_start'] as num?)?.toInt(),
              idealDrinkingEnd: (finalPayload['ideal_drinking_end'] as num?)?.toInt(),
              peakDrinkingStart: (finalPayload['peak_drinking_start'] as num?)?.toInt(),
              estimatedMarketValue: (finalPayload['estimated_market_value'] as num?)?.toDouble(),
              tastingNotes: finalPayload['tasting_notes'] as String?,
              foodPairings: (finalPayload['ai_food_pairings'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
              grapes: finalPayload['grapes'] != null
                  ? (finalPayload['grapes'] as List<dynamic>).map((g) => Grape.fromJson(g)).toList()
                  : null,
              userOverrides: updatedOverrides,
            );
            await _loadBottleDetails();
            final currentCellar = ref.read(currentCellarIdProvider);
            notifyCellarChanged(ref, currentCellar);
            if (mounted) {
              final sFr = Localizations.localeOf(context).languageCode != 'en';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    sFr
                        ? '✨ Données et apogée mis à jour avec vos sélections !'
                        : '✨ Data and peak window updated with your selections!',
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              );
            }
          },
        );
        return;
      }

      // If no conflict on manual overrides, update all non-override fields directly
      final updatePayload = <String, dynamic>{
        if (enriched['ideal_drinking_start'] != null && !overrides.contains('ideal_drinking_start'))
          'ideal_drinking_start': enriched['ideal_drinking_start'],
        if (enriched['ideal_drinking_end'] != null && !overrides.contains('ideal_drinking_end'))
          'ideal_drinking_end': enriched['ideal_drinking_end'],
        if (enriched['peak_drinking_start'] != null && !overrides.contains('peak_drinking_start'))
          'peak_drinking_start': enriched['peak_drinking_start'],
        if (enriched['peak_drinking_end'] != null && !overrides.contains('peak_drinking_end'))
          'peak_drinking_end': enriched['peak_drinking_end'],
        if (enriched['estimated_market_value'] != null && !overrides.contains('estimated_market_value'))
          'estimated_market_value': enriched['estimated_market_value'],
        if (enriched['alcohol_pct'] != null && !overrides.contains('alcohol_pct'))
          'alcohol_pct': enriched['alcohol_pct'],
        if (enriched['classification'] != null && !overrides.contains('classification'))
          'classification': enriched['classification'],
        if (enriched['appellation'] != null && !overrides.contains('appellation'))
          'appellation': enriched['appellation'],
        if (enriched['sub_region'] != null && !overrides.contains('sub_region'))
          'sub_region': enriched['sub_region'],
        if (enriched['cuvee_parcel'] != null && !overrides.contains('cuvee_parcel'))
          'cuvee_parcel': enriched['cuvee_parcel'],
        if (enriched['tasting_notes'] != null && !overrides.contains('tasting_notes'))
          'tasting_notes': enriched['tasting_notes'],
        if (enriched['ai_summary'] != null && !overrides.contains('ai_summary'))
          'ai_summary': enriched['ai_summary'],
        if (enriched['food_pairings'] != null && !overrides.contains('ai_food_pairings'))
          'ai_food_pairings': enriched['food_pairings'],
        if (grapes.isNotEmpty && !overrides.contains('grapes'))
          'grapes': grapes.map((g) => g.toJson()).toList(),
        'is_verified_online': true,
      };

      await supabase.from('wines').update(updatePayload).eq('id', wine.id);

      // Reload bottle details
      await _loadBottleDetails();

      final currentCellar = ref.read(currentCellarIdProvider);
      notifyCellarChanged(ref, currentCellar);

      if (mounted) {
        final sFr = Localizations.localeOf(context).languageCode != 'en';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sFr
                  ? '✨ Données œnologiques, cépages et apogée enrichis avec succès !'
                  : '✨ Oenological data, grapes, and peak window successfully enriched!',
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final sFr = Localizations.localeOf(context).languageCode != 'en';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sFr ? 'Impossible d\'enrichir les données : $e' : 'Unable to enrich data: $e',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnriching = false);
    }
  }

  void _showApogeeExplanationDialog(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.hourglass_top, color: Color(0xFFD4AF37), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isFr ? 'Qu\'est-ce que l\'Apogée ?' : 'What is the Peak Window?',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                  ? 'L\'apogée est la période idéale pour déguster un vin. C\'est le moment où il atteint son équilibre parfait entre arômes, tanins et acidité.'
                  : 'The peak window is the ideal period to enjoy a wine. It is the moment when it reaches perfect balance between aromas, tannins, and acidity.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⏳ ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    isFr
                        ? 'Trop jeune / En garde : le vin gagnera en complexité en vieillissant en cave.'
                        : 'Too young / Aging: the wine will gain complexity as it ages in cellar.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🍷 ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    isFr
                        ? 'À l\'apogée : le vin est à son sommet gustatif, moment idéal pour l\'ouvrir.'
                        : 'At peak: the wine is at its taste peak, perfect time to open it.',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    isFr
                        ? 'En déclin : le vin approche ou dépasse sa limite de garde, à boire sans tarder.'
                        : 'In decline: the wine is nearing or past its aging limit, drink promptly.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isFr
                  ? '💡 Chatmelier estime cette fenêtre grâce à l\'IA à partir du domaine, de l\'appellation et du millésime. Vous pouvez la personnaliser à tout moment.'
                  : '💡 Chatmelier estimates this window using AI based on producer, appellation, and vintage. You can customize it at any time.',
              style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isFr ? 'Compris !' : 'Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPriceDialog() async {
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final currentPrice = (_bottleData!['purchase_price'] as num?)?.toDouble();
    String currentCurrency = _bottleData!['currency'] as String? ?? 'EUR';
    final priceCtrl = TextEditingController(text: currentPrice != null ? currentPrice.toStringAsFixed(2) : '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(isFr ? 'Modifier Prix & Devise' : 'Edit Price & Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isFr ? 'Prix d\'achat unitaire' : 'Unit purchase price',
                  prefixText: '${CurrencyHelper.getSymbol(currentCurrency)} ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: currentCurrency,
                decoration: InputDecoration(
                  labelText: isFr ? 'Devise d\'achat' : 'Purchase currency',
                  border: const OutlineInputBorder(),
                ),
                items: CurrencyHelper.supportedCurrencies.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.code,
                    child: Text('${c.code} (${c.symbol}) - ${c.name}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => currentCurrency = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isFr ? 'Annuler' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newPrice = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
                final repo = ref.read(cellarRepositoryProvider);
                await repo.updateBottle(
                  widget.id,
                  purchasePrice: newPrice,
                  currency: currentCurrency,
                );
                final cellarId = _bottleData!['cellar_id'] as String?;
                notifyCellarChanged(ref, cellarId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  _loadBottleDetails();
                }
              },
              child: Text(isFr ? 'Enregistrer' : 'Save'),
            ),
          ],
        ),
      ),
    );
    priceCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode != 'en';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _bottleData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isFr ? 'Fiche Bouteille' : 'Bottle Details')),
        body: Center(child: Text(isFr ? 'Erreur : ${_error ?? "Bouteille introuvable"}' : 'Error: ${_error ?? "Bottle not found"}')),
      );
    }

    final l10n = AppLocalizations.of(context);
    final wineRaw = _bottleData!['wines'] as Map<String, dynamic>;
    final wine = Wine.fromJson(wineRaw);
    final ownerProfile = _bottleData!['profiles'] as Map<String, dynamic>?;

    final quantity = _bottleData!['quantity'] as int? ?? 1;
    final purchasePrice = (_bottleData!['purchase_price'] as num?)?.toDouble();
    final currency = _bottleData!['currency'] as String? ?? 'EUR';
    final status = _bottleData!['status'] as String? ?? 'in_cellar';
    final isConsumed = status == 'consumed';

    final rack = _bottleData!['rack'] as String?;
    final shelf = _bottleData!['shelf'] as String?;
    final position = _bottleData!['position'] as String?;
    final rawUserNotes = _bottleData!['notes'] as String?;
    final isAIPollutedNote = rawUserNotes != null &&
        (rawUserNotes.trim().toLowerCase() == (wine.tastingNotes ?? '').trim().toLowerCase() ||
         rawUserNotes.trim().toLowerCase() == (wine.summary ?? '').trim().toLowerCase() ||
         rawUserNotes.contains('Sortie enregistrée par commande vocale'));
    final userNotes = isAIPollutedNote ? null : rawUserNotes;
    final isViewOnly = ref.watch(currentCellarRoleProvider) == 'viewer';

    final fillLevel = (_bottleData!['fill_level'] as num?)?.toInt() ?? 100;

    final bottleObj = Bottle(
      id: widget.id,
      cellarId: _bottleData!['cellar_id'] as String? ?? '',
      wineId: _bottleData!['wine_id'] as String? ?? '',
      addedBy: _bottleData!['added_by'] as String? ?? '',
      ownerId: _bottleData!['owner_id'] as String? ?? '',
      quantity: quantity,
      purchasePrice: purchasePrice,
      currency: currency,
      rack: rack,
      shelf: shelf,
      position: position,
      status: status,
      notes: userNotes,
      createdAt: DateTime.tryParse(_bottleData!['created_at']?.toString() ?? '') ?? DateTime.now(),
      wine: wine,
      fillLevel: fillLevel,
      furnitureId: (_bottleData!['furniture_id'] ?? _bottleData!['furnitureId'])?.toString(),
      furnitureSlot: (_bottleData!['furniture_slot'] ?? _bottleData!['furnitureSlot'])?.toString(),
      bottleSize: (_bottleData!['bottle_size'] ?? _bottleData!['bottleSize'])?.toString() ?? '75cl',
      purchaseLocation: (_bottleData!['purchase_location'] ?? _bottleData!['purchaseLocation'])?.toString(),
      sourceType: (_bottleData!['source_type'] ?? _bottleData!['sourceType'])?.toString(),
      sourceDetails: (_bottleData!['source_details'] ?? _bottleData!['sourceDetails'])?.toString(),
      purchaseDate: DateTime.tryParse((_bottleData!['purchase_date'] ?? _bottleData!['purchaseDate'])?.toString() ?? ''),
      photoUrl: _labelPhotoUrl,
      ownerName: (_bottleData!['profiles'] as Map<String, dynamic>?)?['display_name'] as String?,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver Hero App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                wine.vintage != null ? '${wine.name} (${wine.vintage})' : wine.name,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  BottleImageView(
                    imagePath: _labelPhotoUrl,
                    wineType: wine.type,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for text readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  if (!isViewOnly)
                    Positioned(
                      top: 48,
                      right: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showPhotoOptions(wine),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white38, width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Photo',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              if (!isViewOnly)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: isFr ? 'Modifier toutes les informations' : 'Edit all details',
                  onPressed: () => _showFullEditSheet(wine, bottleObj),
                ),
              IconButton(
                icon: _isEnriching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                tooltip: isFr ? 'Chercher données manquantes / Vérifier avec l\'IA' : 'Find missing data / Verify with AI',
                onPressed: _isEnriching ? null : () => _enrichWineData(wine),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Share bottle details
                },
              ),
              if (!isViewOnly)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: isFr ? 'Supprimer définitivement' : 'Delete permanently',
                  onPressed: () {
                    DeleteBottleDialog.show(
                      context,
                      bottle: bottleObj,
                      cellarId: bottleObj.cellarId,
                      onDeleted: () => context.pop(),
                    );
                  },
                ),
            ],
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            WineTypeBadge(type: wine.type),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2416) : const Color(0xFFFFF8E7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wine_bar, size: 12, color: Color(0xFFD4AF37)),
                                  const SizedBox(width: 4),
                                  Text(
                                    bottleObj.sizeObject.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFF3E5AB) : const Color(0xFF8C6D05),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (wine.alcoholPct != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                                  ),
                                ),
                                child: Text(
                                  '${wine.alcoholPct!.toStringAsFixed(wine.alcoholPct! % 1 == 0 ? 0 : 1)}% vol',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                            if (wine.tracksFillLevel) ...[
                              Builder(
                                builder: (context) {
                                  final fillLevel = bottleObj.fillLevel;
                                  final fillColor = fillLevel <= 20
                                      ? Colors.redAccent
                                      : fillLevel <= 50
                                          ? Colors.orangeAccent
                                          : Colors.amber.shade400;
                                  final borderColor = fillLevel <= 20
                                      ? Colors.red.shade700
                                      : fillLevel <= 50
                                          ? Colors.orange.shade700
                                          : Colors.amber.shade700;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A2325) : const Color(0xFFFAF0E6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: borderColor.withValues(alpha: 0.85), width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_bar, size: 12, color: fillColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$fillLevel% ${isFr ? "plein" : "full"}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: fillColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ] else ...[
                              DrinkingWindowBadge(status: wine.windowStatus),
                            ],
                          ],
                        ),
                      ),
                      if (ownerProfile != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OwnerAvatar(
                              displayName: ownerProfile['display_name'] ?? 'User',
                              avatarUrl: ownerProfile['avatar_url'],
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ownerProfile['display_name'] ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title & Cuvée / Parcel
                  if (wine.producer != null && wine.producer!.isNotEmpty)
                    Text(
                      wine.producer!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    wine.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (wine.cuveeParcel != null && wine.cuveeParcel!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cuvée / Parcel: ${wine.cuveeParcel}',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  // Bottle Fill View (Spirits, Liqueurs & Fortified/Mutés)
                  if (wine.tracksFillLevel) ...[
                    const SizedBox(height: 14),
                    Container(
                      key: _fillLevelKey,
                      child: SpiritBottleFillView(
                        fillLevel: bottleObj.fillLevel,
                        spiritType: wine.type,
                        wineName: wine.name,
                        readOnly: isViewOnly,
                        onFillLevelChanged: (newLevel) async {
                          setState(() {
                            _bottleData!['fill_level'] = newLevel;
                          });
                          final repo = ref.read(cellarRepositoryProvider);
                          await repo.updateBottle(bottleObj.id, fillLevel: newLevel);
                          final currentCellar = ref.read(currentCellarIdProvider);
                          notifyCellarChanged(ref, currentCellar);
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ================= ACTIONS: AI ENRICHMENT & EDIT ALL FIELDS =================
                  Row(
                    children: [
                      // Enrichment Button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isEnriching ? null : () => _enrichWineData(wine),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_isEnriching)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFr ? 'Recherche IA' : 'AI Search',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD4AF37),
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          isFr ? 'Cépages & Apogée' : 'Grapes & Peak',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isViewOnly) ...[
                        const SizedBox(width: 10),
                        // Edit All Fields Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showFullEditSheet(wine, bottleObj),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_note, color: Color(0xFF8B1E3F), size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isFr ? 'Modifier la fiche' : 'Edit Details',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF8B1E3F),
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            isFr ? 'Tous les champs' : 'All fields',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ================= VALUATION & PRICE CARD =================
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(isFr ? 'Estimation & Valeur patrimoniale' : 'Valuation & Asset Value', style: theme.textTheme.titleMedium),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: isFr ? 'Modifier prix ou devise' : 'Edit price or currency',
                                onPressed: _showEditPriceDialog,
                              ),
                              Flexible(
                                child: Text(
                                  '$quantity ${isFr ? (quantity > 1 ? "bouteilles en cave" : "bouteille en cave") : (quantity > 1 ? "bottles in cellar" : "bottle in cellar")}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              // Purchase Price Paid
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.bottleDetailPurchasePrice ?? (isFr ? 'Prix d\'achat' : 'Purchase price'),
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isViewOnly
                                          ? (isFr ? 'Confidentiel' : 'Confidential')
                                          : (purchasePrice != null 
                                              ? CurrencyHelper.formatPrice(purchasePrice, currency: currency, decimals: 2) 
                                              : (isFr ? 'Non renseigné' : 'Not set')),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isViewOnly
                                            ? theme.colorScheme.onSurfaceVariant
                                            : (purchasePrice != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(height: 40, width: 1, color: theme.dividerColor, margin: const EdgeInsets.symmetric(horizontal: 8)),
                              // Estimated Market Value
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          l10n?.bottleDetailEstimatedValue ?? (isFr ? 'Valeur estimée' : 'Estimated value'),
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, size: 14, color: Colors.blue),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isViewOnly
                                          ? (isFr ? 'Confidentiel' : 'Confidential')
                                          : (wine.estimatedMarketValue != null
                                              ? CurrencyHelper.formatPrice(wine.estimatedMarketValue, currency: currency, decimals: 2)
                                              : (isFr ? 'Estimation...' : 'Estimating...')),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isViewOnly ? theme.colorScheme.onSurfaceVariant : Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!isViewOnly && wine.lastValuationDate != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              isFr
                                  ? 'Indice de marché vérifié • Actualisé semestriellement (${DateFormat.yMMMd().format(wine.lastValuationDate!)})'
                                  : 'Verified market index • Updated semi-annually (${DateFormat.yMMMd().format(wine.lastValuationDate!)})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ================= QUICK SOMMAIRE NAVIGATION =================
                  _buildQuickNavBar(context, wine, isFr),

                  // ================= CRITIC SCORES / RANKINGS =================
                  if (wine.criticScores.isNotEmpty) ...[
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isFr
                                      ? 'Notes & Distinctions des Guides (${wine.vintage ?? "NM"})'
                                      : 'Ratings & Guide Awards (${wine.vintage ?? "NV"})',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...wine.criticScores.take(5).map((score) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      score.score,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          score.source,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        if (score.reviewer != null)
                                          Text(
                                            score.reviewer!,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (score.year != null)
                                    Text(
                                      '${score.year}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ================= DRINKING WINDOW GAUSSIAN CURVE (Only for wines) =================
                  if (!wine.tracksFillLevel) ...[
                    Container(
                      key: _apogeeKey,
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isFr
                                        ? (wine.vintage != null && wine.vintage! > 0
                                            ? 'Garde & Fenêtre d\'Apogée'
                                            : 'Garde & Maturité (Non Millésimé)')
                                        : (wine.vintage != null && wine.vintage! > 0
                                            ? 'Aging & Peak Drinking Window'
                                            : 'Aging & Maturity (Non-Vintage)'),
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (wine.userOverrides.any((k) => k.contains('drinking') || k.contains('peak'))) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.lock_outline, size: 11, color: Colors.green),
                                          const SizedBox(width: 3),
                                          Text(isFr ? 'Personnalisé' : 'Custom', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.help_outline, size: 18, color: Colors.grey),
                                    tooltip: isFr ? 'Qu\'est-ce que l\'apogée ?' : 'What is the peak window?',
                                    onPressed: () => _showApogeeExplanationDialog(context),
                                  ),
                                  if (!isViewOnly)
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      tooltip: isFr ? 'Modifier les dates d\'apogée et de garde' : 'Edit peak and drinking window dates',
                                      onPressed: () => _showFullEditSheet(wine, bottleObj),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GaussianDrinkingCurve(wine: wine),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ================= SOMMELIER SERVICE & TEMPERATURE ADVICE =================
                  Container(
                    key: _serviceKey,
                    child: Builder(
                      builder: (context) {
                        final advice = WineServiceAdvisor.computeAdvice(
                          wineType: wine.type,
                          vintage: wine.vintage,
                          region: wine.region,
                          appellation: wine.appellation,
                          producer: wine.producer,
                          wineName: wine.name,
                        );
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      isFr ? 'Conseils de Service & Dégustation' : 'Service & Tasting Advice',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    // Température Idéale
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.thermostat, color: Color(0xFF1976D2), size: 18),
                                                const SizedBox(width: 4),
                                                Text(isFr ? 'Température' : 'Temperature', style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              advice.tempLabel,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Temps de Caravage
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFBE9E7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.hourglass_top, color: Color(0xFFD84315), size: 18),
                                                const SizedBox(width: 4),
                                                Text(isFr ? 'Aération' : 'Aeration', style: const TextStyle(color: Color(0xFFD84315), fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              advice.carafeLabel,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFBF360C)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${isFr ? "Verre conseillé" : "Recommended glassware"} : ${advice.glasswareType}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(advice.decantingAdvice, style: theme.textTheme.bodySmall?.copyWith(height: 1.3)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF722F37),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.timer_outlined, color: Color(0xFFD4AF37), size: 20),
                                    label: Text(
                                      isFr ? 'Mode Sommelier à Table (Minuteur & Notes)' : 'Table Sommelier Mode (Timer & Notes)',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      SommelierTableModeSheet.show(context, bottle: bottleObj);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ================= TERROIR & GEOGRAPHY MAP =================
                  Container(
                    key: _terroirKey,
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.explore_outlined, size: 18, color: Color(0xFF8B1E3F)),
                                const SizedBox(width: 6),
                                Text(isFr ? 'Origine Géographique & Terroir' : 'Geographic Origin & Terroir', style: theme.textTheme.titleMedium),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TerroirMapView(
                              country: wine.country,
                              region: wine.region,
                              subRegion: wine.subRegion,
                              appellation: wine.appellation,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ================= GRAPES COMPOSITION (PIE CHART) (Only for wines) =================
                  if (!wine.isSpirit) ...[
                    Container(
                      key: _grapesKey,
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.pie_chart, color: Color(0xFF8B1E3F), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n?.bottleDetailGrapes ?? (isFr ? 'Composition & Cépages (Raisin)' : 'Composition & Grape Varieties'),
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  if (!isViewOnly)
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      tooltip: isFr ? 'Modifier les cépages' : 'Edit grape varieties',
                                      onPressed: () => _showFullEditSheet(wine, bottleObj),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              GrapeChart(grapes: wine.grapes, wine: wine),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ================= ÉLEVAGE & VINIFICATION (BARREL AGING & OENOLOGY) (Only for wines) =================
                  if (!wine.tracksFillLevel) ...[
                    Container(
                      key: _elevageKey,
                    child: Builder(
                      builder: (context) {
                        final oenology = WineOenologyAdvisor.computeAdvice(
                          wineType: wine.type,
                          vintage: wine.vintage,
                          region: wine.region,
                          appellation: wine.appellation,
                          producer: wine.producer,
                          wineName: wine.name,
                          existingAlcoholPct: wine.alcoholPct,
                          explicitDrinkStart: wine.drinkStart,
                          explicitDrinkEnd: wine.drinkEnd,
                          explicitPeakStart: wine.peakStart,
                          explicitPeakEnd: wine.peakEnd,
                          explicitBarrelAging: wine.barrelAging,
                          explicitVinification: wine.vinificationMethod,
                          explicitMalolactic: wine.malolacticFermentation,
                          explicitHarvest: wine.harvestMethod,
                          explicitTerroirSoil: wine.terroirSoil,
                          isVerified: wine.isTechnicalDataVerified,
                        );

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, color: Color(0xFF8B1E3F), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      isFr ? 'Élevage & Vinification' : 'Aging & Vinification',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (wine.isTechnicalDataVerified) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 14),

                                if (oenology.barrelAgingDuration != null) ...[
                                  // Barrel Aging Highlight
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B1E3F).withAlpha(20),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF8B1E3F).withAlpha(50)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('🪵', style: TextStyle(fontSize: 24)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isFr ? 'Temps passé en fût & Élevage' : 'Barrel Aging Duration & Method',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFD4AF37),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                oenology.barrelAgingDuration!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                if (oenology.vinificationMethod != null) ...[
                                  _buildOenologyRow(
                                    context,
                                    icon: Icons.science_outlined,
                                    label: 'Vinification',
                                    value: oenology.vinificationMethod!,
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                if (oenology.malolacticFermentation != null) ...[
                                  _buildOenologyRow(
                                    context,
                                    icon: Icons.bubble_chart_outlined,
                                    label: isFr ? 'Fermentation malolactique' : 'Malolactic fermentation',
                                    value: oenology.malolacticFermentation!,
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                if (oenology.harvestMethod != null) ...[
                                  _buildOenologyRow(
                                    context,
                                    icon: Icons.agriculture_outlined,
                                    label: isFr ? 'Mode de vendanges' : 'Harvest method',
                                    value: oenology.harvestMethod!,
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                _buildOenologyRow(
                                  context,
                                  icon: Icons.hourglass_top_outlined,
                                  label: isFr ? 'Potentiel de garde estimé' : 'Estimated aging potential',
                                  value: oenology.agingPotential,
                                ),

                                if (!oenology.hasTechnicalData) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isFr
                                                ? 'Données d\'élevage & vinification non renseignées par le domaine.'
                                                : 'Aging and vinification technical data not provided by estate.',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                  // ================= VERIFIED VINEYARD KNOWLEDGE (TRANSVERSAL 1-YEAR CACHE) =================
                  if (!wine.isSpirit && (wine.producer != null && wine.producer!.trim().isNotEmpty)) ...[
                    Consumer(
                      builder: (context, ref, _) {
                        final producer = wine.producer!.trim();
                        final vineyardAsync = ref.watch(vineyardKnowledgeProvider(producer));

                        return vineyardAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (vk) {
                            if (vk == null) return const SizedBox.shrink();
                            final verifiedDateStr = '${vk.verifiedAt.day.toString().padLeft(2, '0')}/${vk.verifiedAt.month.toString().padLeft(2, '0')}/${vk.verifiedAt.year}';
                            final expiryDays = vk.daysUntilExpiry;

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.terrain_outlined, color: Color(0xFF8B1E3F), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isFr ? 'Histoire & Terroir du Domaine' : 'Estate History & Terroir',
                                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                isFr ? 'Base transversale partagée • Re-vérification annuelle' : 'Shared transversal knowledge • Annual re-verification',
                                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green.withAlpha(60)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.verified, color: Colors.green, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                isFr ? 'Vérifié le $verifiedDateStr' : 'Verified on $verifiedDateStr',
                                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      vk.terroirDescription,
                                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (vk.soilType != null)
                                          Chip(
                                            avatar: const Text('🪨', style: TextStyle(fontSize: 12)),
                                            label: Text('${isFr ? "Sols" : "Soils"} : ${vk.soilType}', style: const TextStyle(fontSize: 11)),
                                            backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        if (vk.viticultureStyle != null)
                                          Chip(
                                            avatar: const Text('🌿', style: TextStyle(fontSize: 12)),
                                            label: Text('${isFr ? "Culture" : "Farming"} : ${vk.viticultureStyle}', style: const TextStyle(fontSize: 11)),
                                            backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        Chip(
                                          avatar: const Icon(Icons.schedule, size: 13, color: Colors.grey),
                                          label: Text(isFr ? 'Valable encore $expiryDays jours' : 'Valid for $expiryDays more days', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                                          backgroundColor: Colors.transparent,
                                          side: BorderSide(color: Colors.grey.withAlpha(50)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ================= TASTING NOTES & FOOD PAIRINGS =================
                  if (wine.tastingNotes != null || wine.foodPairings.isNotEmpty) ...[
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.menu_book, color: Color(0xFF8B1E3F), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n?.bottleDetailTastingNotes ?? (isFr ? 'Profil Sommelier' : 'Sommelier Profile'),
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        isFr ? 'Fiche œnologique & aromatique (IA & Guides)' : 'Oenological & aromatic profile (AI & Guides)',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isViewOnly)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: isFr ? 'Modifier le profil sommelier' : 'Edit sommelier profile',
                                    onPressed: () => _showFullEditSheet(wine, bottleObj),
                                  ),
                              ],
                            ),
                            if (wine.tastingNotes != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                wine.tastingNotes!,
                                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                              ),
                            ],
                            if (wine.foodPairings.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                wine.tracksFillLevel
                                    ? (isFr ? 'Accords & Dégustation conseillés' : 'Recommended pairings & tasting')
                                    : (l10n?.bottleDetailFoodPairings ?? (isFr ? 'Accords Mets & Vins conseillés' : 'Recommended Food & Wine Pairings')),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.brightness == Brightness.dark ? const Color(0xFFE25C74) : const Color(0xFF8B1E3F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: wine.foodPairings.map((pairing) => Chip(
                                  avatar: const Icon(Icons.restaurant, size: 14),
                                  label: Text(pairing),
                                  visualDensity: VisualDensity.compact,
                                )).toList(),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD4AF37),
                                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Text('👨‍🍳', style: TextStyle(fontSize: 16)),
                                label: Text(
                                  isFr ? 'Que cuisiner avec ce vin ? (Accords Inversés)' : 'What to cook with this wine? (Reverse Pairings)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: () => WineReverseFoodPairingSheet.show(context, wine),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ================= PHYSICAL LOCATION & MODE SHELVES =================
                  if (bottleObj.hasLocation) ...[
                    FurnitureGraphicCard(
                      bottle: bottleObj,
                      onEditRequested: !isViewOnly
                          ? () async {
                              await ShelfGridViewSheet.show(
                                context,
                                cellarId: bottleObj.cellarId,
                                bottleToPlace: bottleObj,
                                initialFurnitureId: bottleObj.furnitureId,
                              );
                              if (mounted) {
                                await _loadBottleDetails();
                              }
                            }
                          : null,
                      onUnassignRequested: !isViewOnly
                          ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: Text(isFr ? 'Retirer du meuble ?' : 'Remove from furniture?'),
                                  content: Text(
                                      isFr
                                          ? 'Voulez-vous retirer cette bouteille de son meuble et la replacer en stockage non assigné ?'
                                          : 'Do you want to remove this bottle from its furniture and return it to unassigned storage?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: Text(isFr ? 'Annuler' : 'Cancel'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red.shade800,
                                      ),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: Text(isFr ? 'Retirer' : 'Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final repo = ref.read(cellarRepositoryProvider);
                                await repo.assignBottleToSlot(
                                  bottleId: bottleObj.id,
                                  furnitureId: null,
                                  slot: null,
                                );
                                await repo.updateBottle(bottleObj.id, rawUpdates: {
                                  'rack': null,
                                  'shelf': null,
                                  'position': null,
                                });
                                notifyCellarChanged(ref, bottleObj.cellarId);
                                if (mounted) {
                                  await _loadBottleDetails();
                                }
                              }
                            }
                          : null,
                    ),
                    if (bottleObj.purchaseLocation != null && bottleObj.purchaseLocation!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.place_outlined, size: 18, color: Color(0xFFD4AF37)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${isFr ? "Provenance" : "Origin"} : ${bottleObj.getProvenanceDisplay(isFr)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.brightness == Brightness.dark ? const Color(0xFFF3E5AB) : const Color(0xFF722F37),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shelves, color: Color(0xFF8B1E3F), size: 20),
                                const SizedBox(width: 8),
                                Text(l10n?.bottleDetailLocation ?? (isFr ? 'Emplacement & Meuble de cave' : 'Location & Cellar Furniture'),
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                              label: Text(isFr ? 'Ranger dans un meuble (Mode Rayonnage)' : 'Store in furniture (Shelf Mode)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF8B1E3F),
                                side: const BorderSide(color: Color(0xFF8B1E3F)),
                              ),
                              onPressed: () async {
                                await ShelfGridViewSheet.show(
                                  context,
                                  cellarId: bottleObj.cellarId,
                                  bottleToPlace: bottleObj,
                                );
                                if (mounted) {
                                  await _loadBottleDetails();
                                }
                              },
                            ),
                            if (bottleObj.purchaseLocation != null && bottleObj.purchaseLocation!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.place_outlined, size: 18, color: Color(0xFFD4AF37)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${isFr ? "Provenance" : "Origin"} : ${bottleObj.getProvenanceDisplay(isFr)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.brightness == Brightness.dark ? const Color(0xFFF3E5AB) : const Color(0xFF722F37),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ================= USER PERSONAL NOTES =================
                  if (userNotes != null && userNotes.isNotEmpty) ...[
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.edit_note, color: Color(0xFFD4AF37), size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isFr ? 'Mes Notes & Commentaires Personnels' : 'My Personal Notes & Comments',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        isFr ? 'Privé • Rédigé par vous (non modifiable par l\'IA)' : 'Private • Written by you (not modifiable by AI)',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isViewOnly) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: isFr ? 'Modifier ma note' : 'Edit my note',
                                    onPressed: () => _showQuickEditPersonalNotes(bottleObj),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    tooltip: isFr ? 'Supprimer ma note' : 'Delete my note',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: Text(isFr ? 'Supprimer votre note ?' : 'Delete your note?'),
                                          content: Text(isFr ? 'Voulez-vous effacer vos commentaires personnels pour cette bouteille ?' : 'Do you want to erase your personal comments for this bottle?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(isFr ? 'Annuler' : 'Cancel')),
                                            FilledButton(
                                              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
                                              onPressed: () => Navigator.pop(c, true),
                                              child: Text(isFr ? 'Supprimer' : 'Delete', style: const TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final repo = ref.read(cellarRepositoryProvider);
                                        await repo.updateBottle(bottleObj.id, notes: null);
                                        setState(() {
                                          if (_bottleData != null) _bottleData!['notes'] = null;
                                        });
                                        await _loadBottleDetails();
                                        final currentCellar = ref.read(currentCellarIdProvider);
                                        notifyCellarChanged(ref, currentCellar);
                                        if (currentCellar != null) ref.invalidate(bottlesProvider(currentCellar));
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              userNotes,
                              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (!isViewOnly && !isConsumed) ...[
                    OutlinedButton.icon(
                      onPressed: () => _showQuickEditPersonalNotes(bottleObj),
                      icon: const Icon(Icons.edit_note, size: 18, color: Color(0xFFD4AF37)),
                      label: Text(
                        isFr
                            ? '+ Ajouter une note personnelle (souvenirs, circonstances d\'achat...)'
                            : '+ Add a personal note (memories, purchase context...)',
                        style: const TextStyle(fontSize: 13, color: Color(0xFFD4AF37), fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ================= SOURCES CITATIONS =================
                  if (wine.sourcesVerified.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Sources : ${wine.sourcesVerified.join(", ")}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  if (!isConsumed && !ref.watch(currentCellarRoleProvider.select((r) => r == 'viewer'))) ...[
                    // 1. Bouton Principal : Sortir cette bouteille (Haute visibilité & contraste)
                    FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        context.push('/checkout?bottleId=${widget.id}');
                      },
                      icon: const Icon(Icons.wine_bar, color: Colors.white, size: 22),
                      label: Text(
                        '${l10n?.bottleDetailDrinkButton ?? (isFr ? "Sortir cette bouteille" : "Checkout this bottle")} 🍷',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
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
                    const SizedBox(height: 12),

                    // 2. Mode Sommelier à Table
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        SommelierTableModeSheet.show(context, bottle: bottleObj);
                      },
                      icon: const Icon(Icons.room_service_outlined, color: Color(0xFFD4AF37)),
                      label: Text(
                        isFr ? 'Mode Sommelier à Table (Service & Notes)' : 'Table Sommelier Mode (Service & Notes)',
                        style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.4),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Ajouter un exemplaire
                    FilledButton.tonalIcon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showAddSiblingOrIncrementSheet(context, bottleObj);
                      },
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B1E3F)),
                      label: Text(
                        isFr ? '+ 1 Bouteille / Ajouter un exemplaire' : '+ 1 Bottle / Add duplicate',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Supprimer
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        DeleteBottleDialog.show(
                          context,
                          bottle: bottleObj,
                          cellarId: bottleObj.cellarId,
                          onDeleted: () => context.pop(),
                        );
                      },
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                      label: Text(
                        isFr ? 'Supprimer définitivement de la cave' : 'Permanently delete from cellar',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade700.withValues(alpha: 0.5)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else if (!isConsumed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            isFr ? 'Mode consultation (lecture seule)' : 'View-only mode (read-only)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNavBar(BuildContext context, Wine wine, bool isFr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221E1F) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (wine.tracksFillLevel) ...[
              _buildQuickNavChip(context, icon: Icons.local_bar, label: isFr ? 'Niveau' : 'Fill Level', targetKey: _fillLevelKey),
              const SizedBox(width: 8),
            ] else ...[
              _buildQuickNavChip(context, icon: Icons.show_chart, label: isFr ? 'Apogée' : 'Peak Window', targetKey: _apogeeKey),
              const SizedBox(width: 8),
            ],
            _buildQuickNavChip(context, icon: Icons.wine_bar, label: 'Service', targetKey: _serviceKey),
            const SizedBox(width: 8),
            _buildQuickNavChip(context, icon: Icons.explore_outlined, label: 'Terroir', targetKey: _terroirKey),
            if (!wine.isSpirit) ...[
              const SizedBox(width: 8),
              _buildQuickNavChip(context, icon: Icons.pie_chart_outline, label: isFr ? 'Cépages' : 'Grapes', targetKey: _grapesKey),
            ],
            if (!wine.tracksFillLevel) ...[
              const SizedBox(width: 8),
              _buildQuickNavChip(context, icon: Icons.inventory_2_outlined, label: isFr ? 'Élevage' : 'Aging', targetKey: _elevageKey),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavChip(BuildContext context, {required IconData icon, required String label, required GlobalKey targetKey}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        final ctx = targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFD4AF37)),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOenologyRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSiblingOrIncrementSheet(BuildContext context, Bottle bottle) {
    final theme = Theme.of(context);
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final initialQty = bottle.quantity;
    int extraQty = 1;
    final addCtrl = TextEditingController(text: '1');
    final totalCtrl = TextEditingController(text: '${initialQty + 1}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final currentTotal = initialQty + extraQty;

          void updateByDelta(int delta) {
            setSheetState(() {
              extraQty = (extraQty + delta).clamp(1, 9999);
              addCtrl.text = '$extraQty';
              totalCtrl.text = '${initialQty + extraQty}';
            });
          }

          void updateFromTotal(int newTotal) {
            setSheetState(() {
              final calculatedExtra = newTotal - initialQty;
              extraQty = calculatedExtra.clamp(1, 9999);
              addCtrl.text = '$extraQty';
              totalCtrl.text = '${initialQty + extraQty}';
            });
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.control_point_duplicate, color: Color(0xFFD4AF37), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isFr ? 'Ajuster le stock / Exemplaire' : 'Adjust Stock / Add Duplicate',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${bottle.wine?.name ?? ""} (${bottle.wine?.vintage ?? "NV"})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Option 1: Direct Stock Bump with dual steppers and formula
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFr ? '1. Ajuster le stock de cette fiche' : '1. Adjust stock for this entry',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 12),

                          // Calculation Summary Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(isFr ? 'Stock actuel' : 'Current stock', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 2),
                                    Text('$initialQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Icon(Icons.add, size: 16, color: Colors.grey),
                                Column(
                                  children: [
                                    Text(isFr ? 'Ajout' : 'Added', style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('+$extraQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                                  ],
                                ),
                                const Text('=', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Column(
                                  children: [
                                    Text(isFr ? 'Nouveau total' : 'New total', style: const TextStyle(fontSize: 11, color: Color(0xFF8B1E3F), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('$currentTotal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Row 1: Ajout (+/- & direct input)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(isFr ? 'Quantité ajoutée :' : 'Added quantity:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              ),
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                onPressed: extraQty > 1 ? () => updateByDelta(-1) : null,
                                icon: const Icon(Icons.remove, size: 18),
                              ),
                              SizedBox(
                                width: 52,
                                child: TextFormField(
                                  controller: addCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onChanged: (val) {
                                    final p = int.tryParse(val);
                                    if (p != null && p > 0) {
                                      setSheetState(() {
                                        extraQty = p;
                                        totalCtrl.text = '${initialQty + extraQty}';
                                      });
                                    }
                                  },
                                ),
                              ),
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => updateByDelta(1),
                                icon: const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Row 2: Nouveau stock total (+/- & direct input)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  isFr ? 'Nouveau stock total :' : 'New total stock:',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF8B1E3F)),
                                ),
                              ),
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                onPressed: extraQty > 1 ? () => updateByDelta(-1) : null,
                                icon: const Icon(Icons.remove, size: 18),
                              ),
                              SizedBox(
                                width: 52,
                                child: TextFormField(
                                  controller: totalCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF8B1E3F)),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF8B1E3F)),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final p = int.tryParse(val);
                                    if (p != null) {
                                      updateFromTotal(p);
                                    }
                                  },
                                ),
                              ),
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => updateByDelta(1),
                                icon: const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Submit Button
                          FilledButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(ctx);
                              final repo = ref.read(cellarRepositoryProvider);
                              final finalTotal = initialQty + extraQty;
                              await repo.updateBottleQuantity(bottle.id, finalTotal, cellarId: bottle.cellarId);
                              notifyCellarChanged(ref, bottle.cellarId);
                              _loadBottleDetails();
                              HapticFeedback.mediumImpact();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFr
                                        ? '🍾 Stock mis à jour : $finalTotal bouteilles en cave !'
                                        : '🍾 Stock updated: $finalTotal bottles in cellar!',
                                  ),
                                  backgroundColor: const Color(0xFF8B1E3F),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: Text(
                              isFr
                                  ? 'Valider le stock total ($currentTotal btl • +$extraQty)'
                                  : 'Confirm total stock ($currentTotal btl • +$extraQty)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8B1E3F),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Option 2: Duplicate as separate bottle entry
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewScreen(
                              imagePath: '',
                              prefillBottle: bottle,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(
                        isFr
                            ? '2. Créer une nouvelle entrée (autre casier / prix)'
                            : '2. Create a new entry (different slot / price)',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
