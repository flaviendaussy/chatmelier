import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'wine_enrichment_diff_dialog.dart';
import 'wine_reverse_food_pairing_sheet.dart';
import '../../offline/presentation/sync_provider.dart';

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
                  'Photo & Étiquette',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFD4AF37)),
              title: const Text('Prendre une photo'),
              subtitle: const Text('Photographier l\'étiquette de cette bouteille'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndSetPhoto(ImageSource.camera, wine);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFD4AF37)),
              title: const Text('Choisir depuis la galerie'),
              subtitle: const Text('Sélectionner une photo existante'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndSetPhoto(ImageSource.gallery, wine);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Color(0xFF722F37)),
              title: const Text('Restaurer l\'étiquette officielle'),
              subtitle: const Text('Appliquer le visuel haute résolution du domaine'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final officialImg = WineImageService.resolveWineImageUrl(wine);
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ Étiquette officielle du domaine appliquée !'),
                      backgroundColor: Color(0xFF2E7D32),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Photo de la bouteille enregistrée avec succès !'),
            backgroundColor: Color(0xFF2E7D32),
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
                          const Text(
                            'Mes Notes & Commentaires',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            'Privé • Strictement réservé à votre usage',
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
                  decoration: const InputDecoration(
                    hintText: 'Vos impressions, circonstances d\'achat, potentiel ressenti...',
                    border: OutlineInputBorder(),
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
                              const SnackBar(
                                content: Text('🗑️ Note personnelle effacée'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        label: const Text('Effacer', style: TextStyle(color: Colors.redAccent)),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
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
                            const SnackBar(
                              content: Text('✅ Note personnelle enregistrée !'),
                              backgroundColor: Color(0xFF2E7D32),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Chatmelier recherche les données et cépages manquants...')),
            ],
          ),
          duration: Duration(seconds: 4),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ Données et apogée mis à jour avec vos sélections !'),
                  backgroundColor: Color(0xFF2E7D32),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Données œnologiques, cépages et apogée enrichis avec succès !'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'enrichir les données : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnriching = false);
    }
  }

  Future<void> _showEditPriceDialog() async {
    final currentPrice = (_bottleData!['purchase_price'] as num?)?.toDouble();
    String currentCurrency = _bottleData!['currency'] as String? ?? 'EUR';
    final priceCtrl = TextEditingController(text: currentPrice != null ? currentPrice.toStringAsFixed(2) : '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Modifier Prix & Devise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Prix d\'achat unitaire',
                  prefixText: '${CurrencyHelper.getSymbol(currentCurrency)} ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: currentCurrency,
                decoration: const InputDecoration(
                  labelText: 'Devise d\'achat',
                  border: OutlineInputBorder(),
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
              child: const Text('Annuler'),
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
              child: const Text('Enregistrer'),
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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _bottleData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche Bouteille')),
        body: Center(child: Text('Erreur : ${_error ?? "Bouteille introuvable"}')),
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
                  tooltip: 'Modifier toutes les informations',
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
                tooltip: 'Chercher données manquantes / Vérifier avec l\'IA',
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
                  tooltip: 'Supprimer définitivement',
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
                    children: [
                      WineTypeBadge(type: wine.type),
                      const SizedBox(width: 8),
                      DrinkingWindowBadge(status: wine.windowStatus),
                      const Spacer(),
                      if (ownerProfile != null)
                        Row(
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
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Recherche IA',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD4AF37),
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Cépages & Apogée',
                                          style: TextStyle(fontSize: 10, color: Colors.grey),
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
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit_note, color: Color(0xFF8B1E3F), size: 22),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Modifier la fiche',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF8B1E3F),
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Tous les champs',
                                            style: TextStyle(fontSize: 10, color: Colors.grey),
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
                              Text('Estimation & Valeur patrimoniale', style: theme.textTheme.titleMedium),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Modifier prix ou devise',
                                onPressed: _showEditPriceDialog,
                              ),
                              Flexible(
                                child: Text(
                                  '$quantity bouteille${quantity > 1 ? "s" : ""} en cave',
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
                                      l10n?.bottleDetailPurchasePrice ?? 'Prix d\'achat',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      purchasePrice != null 
                                          ? CurrencyHelper.formatPrice(purchasePrice, currency: currency, decimals: 2) 
                                          : 'Non renseigné',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: purchasePrice != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
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
                                          l10n?.bottleDetailEstimatedValue ?? 'Valeur estimée',
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, size: 14, color: Colors.blue),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      wine.estimatedMarketValue != null
                                          ? CurrencyHelper.formatPrice(wine.estimatedMarketValue, currency: currency, decimals: 2)
                                          : 'Estimation...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (wine.lastValuationDate != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Indice de marché vérifié • Actualisé semestriellement (${DateFormat.yMMMd().format(wine.lastValuationDate!)})',
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
                  _buildQuickNavBar(context),

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
                                  'Notes & Distinctions des Guides (${wine.vintage ?? "NM"})',
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

                  // ================= DRINKING WINDOW GAUSSIAN CURVE =================
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
                                  wine.vintage != null && wine.vintage! > 0
                                      ? 'Garde & Fenêtre d\'Apogée'
                                      : 'Garde & Maturité (Non Millésimé)',
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
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_outline, size: 11, color: Colors.green),
                                        SizedBox(width: 3),
                                        Text('Personnalisé', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (!isViewOnly)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Modifier les dates d\'apogée et de garde',
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
                                      'Conseils de Service & Dégustation',
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
                                            const Row(
                                              children: [
                                                Icon(Icons.thermostat, color: Color(0xFF1976D2), size: 18),
                                                SizedBox(width: 4),
                                                Text('Température', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 12)),
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
                                            const Row(
                                              children: [
                                                Icon(Icons.hourglass_top, color: Color(0xFFD84315), size: 18),
                                                SizedBox(width: 4),
                                                Text('Aération', style: TextStyle(color: Color(0xFFD84315), fontWeight: FontWeight.bold, fontSize: 12)),
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
                                      Text('Verre conseillé : ${advice.glasswareType}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
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
                                    label: const Text(
                                      'Mode Sommelier à Table (Minuteur & Notes)',
                                      style: TextStyle(fontWeight: FontWeight.bold),
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
                                Text('Origine Géographique & Terroir', style: theme.textTheme.titleMedium),
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

                  // ================= GRAPES COMPOSITION (PIE CHART) =================
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
                                  l10n?.bottleDetailGrapes ?? 'Composition & Cépages (Raisin)',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                if (!isViewOnly)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Modifier les cépages',
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

                  // ================= ÉLEVAGE & VINIFICATION (BARREL AGING & OENOLOGY) =================
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
                                      'Élevage & Vinification',
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
                                              const Text(
                                                'Temps passé en fût & Élevage',
                                                style: TextStyle(
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
                                    label: 'Fermentation malolactique',
                                    value: oenology.malolacticFermentation!,
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                if (oenology.harvestMethod != null) ...[
                                  _buildOenologyRow(
                                    context,
                                    icon: Icons.agriculture_outlined,
                                    label: 'Mode de vendanges',
                                    value: oenology.harvestMethod!,
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                _buildOenologyRow(
                                  context,
                                  icon: Icons.hourglass_top_outlined,
                                  label: 'Potentiel de garde estimé',
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
                                            'Données d\'élevage & vinification non renseignées par le domaine.',
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
                                        l10n?.bottleDetailTastingNotes ?? 'Profil Sommelier',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Fiche œnologique & aromatique (IA & Guides)',
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
                                    tooltip: 'Modifier le profil sommelier',
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
                                l10n?.bottleDetailFoodPairings ?? 'Accords Mets & Vins conseillés',
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
                                label: const Text(
                                  'Que cuisiner avec ce vin ? (Accords Inversés)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

                  // ================= PHYSICAL LOCATION =================
                  if (rack != null || shelf != null || position != null || (bottleObj.purchaseLocation != null && bottleObj.purchaseLocation!.isNotEmpty)) ...[
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
                                const Icon(Icons.grid_on, color: Color(0xFF8B1E3F), size: 18),
                                const SizedBox(width: 8),
                                Text(l10n?.bottleDetailLocation ?? 'Emplacement en cave', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                if (!isViewOnly)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Modifier l\'emplacement',
                                    onPressed: () => _showFullEditSheet(wine, bottleObj),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (rack != null || shelf != null || position != null)
                              Row(
                                children: [
                                  const Icon(Icons.grid_on, size: 18),
                                  const SizedBox(width: 8),
                                  Text('${l10n?.bottleDetailRack ?? "Casier / Rang"}: ${rack ?? "-"}  |  ${l10n?.bottleDetailShelf ?? "Tablette / Niveau"}: ${shelf ?? "-"}  |  Pos: ${position ?? "-"}'),
                                ],
                              ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.place_outlined, size: 18, color: Color(0xFFD4AF37)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Provenance : ${bottleObj.provenanceDisplay}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.brightness == Brightness.dark ? const Color(0xFFF3E5AB) : const Color(0xFF722F37),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                                        'Mes Notes & Commentaires Personnels',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Privé • Rédigé par vous (non modifiable par l\'IA)',
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
                                    tooltip: 'Modifier ma note',
                                    onPressed: () => _showQuickEditPersonalNotes(bottleObj),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    tooltip: 'Supprimer ma note',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Supprimer votre note ?'),
                                          content: const Text('Voulez-vous effacer vos commentaires personnels pour cette bouteille ?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
                                            FilledButton(
                                              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
                                              onPressed: () => Navigator.pop(c, true),
                                              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
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
                      label: const Text(
                        '+ Ajouter une note personnelle (souvenirs, circonstances d\'achat...)',
                        style: TextStyle(fontSize: 13, color: Color(0xFFD4AF37), fontWeight: FontWeight.w600),
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
                        '${l10n?.bottleDetailDrinkButton ?? "Sortir cette bouteille"} 🍷',
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
                      label: const Text(
                        'Mode Sommelier à Table (Service & Notes)',
                        style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
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
                      label: const Text(
                        '+ 1 Bouteille / Ajouter un exemplaire',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                      label: const Text(
                        'Supprimer définitivement de la cave',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
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
                            'Mode consultation (lecture seule)',
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

  Widget _buildQuickNavBar(BuildContext context) {
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
            _buildQuickNavChip(context, icon: Icons.show_chart, label: 'Apogée', targetKey: _apogeeKey),
            const SizedBox(width: 8),
            _buildQuickNavChip(context, icon: Icons.wine_bar, label: 'Service', targetKey: _serviceKey),
            const SizedBox(width: 8),
            _buildQuickNavChip(context, icon: Icons.explore_outlined, label: 'Terroir', targetKey: _terroirKey),
            const SizedBox(width: 8),
            _buildQuickNavChip(context, icon: Icons.pie_chart_outline, label: 'Cépages', targetKey: _grapesKey),
            const SizedBox(width: 8),
            _buildQuickNavChip(context, icon: Icons.inventory_2_outlined, label: 'Élevage', targetKey: _elevageKey),
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
    int extraQty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                        'Ajouter un exemplaire de ce vin',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Bouteille : ${bottle.wine?.name ?? ""} (${bottle.wine?.vintage ?? "NV"})\nStock actuel : ${bottle.quantity} bouteille${bottle.quantity > 1 ? "s" : ""}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                
                // Option 1: Direct Stock Bump
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
                      const Text(
                        '1. Augmenter le stock de cette fiche',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Quantité à ajouter :'),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: extraQty > 1 ? () => setSheetState(() => extraQty--) : null,
                            icon: const Icon(Icons.remove, size: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('+$extraQty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => setSheetState(() => extraQty++),
                            icon: const Icon(Icons.add, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          final repo = ref.read(cellarRepositoryProvider);
                          final newTotal = bottle.quantity + extraQty;
                          await repo.updateBottleQuantity(bottle.id, newTotal, cellarId: bottle.cellarId);
                          notifyCellarChanged(ref, bottle.cellarId);
                          _loadBottleDetails();
                          HapticFeedback.mediumImpact();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('🍾 Stock augmenté : $newTotal bouteilles en cave !'),
                              backgroundColor: const Color(0xFF8B1E3F),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          'Valider le nouveau stock (+ $extraQty)',
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
                  label: const Text('2. Créer une nouvelle entrée (autre casier / prix)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
