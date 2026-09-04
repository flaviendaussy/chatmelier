import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/services/cellar_location_service.dart';
import '../../cellar/domain/cellar.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine_service_advisor.dart';
import '../data/scan_service.dart';
import '../domain/scan_result.dart';
import '../../journal/presentation/external_tasting_dialog.dart';
import '../../../shared/widgets/chatmelier_loader.dart';
import '../../offline/presentation/chatmelier_offline_antenna_widget.dart';
import '../../offline/presentation/sync_provider.dart';
import '../../offline/data/connectivity_service.dart';
import '../../../shared/providers/premium_provider.dart';
import '../../monetization/admob_service.dart';
import 'rewarded_video_ad_sheet.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final Uint8List? imageBytes;
  final Bottle? prefillBottle;
  const ReviewScreen({super.key, required this.imagePath, this.imageBytes, this.prefillBottle});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _producerCtrl = TextEditingController();
  final _vintageCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _appellationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _purchaseLocationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _rackCtrl = TextEditingController();
  final _shelfCtrl = TextEditingController();
  final _alcoholPctCtrl = TextEditingController();

  String _wineType = 'red';
  int _quantity = 1;
  String _selectedCurrency = 'EUR';
  bool _isSaving = false;
  bool _isAnalyzing = false;
  ScanResult? _scanResult;
  String? _analysisError;

  Bottle? _duplicateBottle;
  bool _dismissDuplicate = false;
  bool _ignoreUndetected = false;

  bool get _isUndetected {
    if (_ignoreUndetected) return false;
    final hasImage = widget.imagePath.isNotEmpty || (widget.imageBytes != null && widget.imageBytes!.isNotEmpty);
    if (!hasImage) return false;
    if (widget.prefillBottle != null) return false;

    if (_analysisError != null) return true;
    if (_scanResult == null) return true;
    final name = _scanResult!.name.trim().toLowerCase();
    if (name.isEmpty || name == 'inconnu' || name == 'unknown' || name == 'non reconnu' || name == 'vin inconnu' || name == 'vin') {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefillBottle != null) {
      _prefillFromExisting(widget.prefillBottle!);
    } else if (widget.imagePath.isNotEmpty || (widget.imageBytes != null && widget.imageBytes!.isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndTriggerAnalysis();
      });
    }
  }

  void _checkAndTriggerAnalysis() async {
    final isPremium = ref.read(premiumProvider);
    if (isPremium) {
      _analyzeImage();
      return;
    }

    // Try showing real Google AdMob Rewarded Video Ad first (on Android/iOS)
    final showedAdMob = await AdMobService().showRewardedAd(
      onRewardEarned: () {
        if (mounted) _analyzeImage();
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _ignoreUndetected = true;
          });
        }
      },
    );

    // If AdMob is not supported (Web) or ad was not ready yet,
    // fallback cleanly to the interactive sponsor video sheet
    if (!showedAdMob && mounted) {
      RewardedVideoAdSheet.show(
        context,
        onRewardEarned: () {
          if (mounted) _analyzeImage();
        },
        onCancel: () {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
              _ignoreUndetected = true;
            });
          }
        },
      );
    }
  }

  void _prefillFromExisting(Bottle b) {
    final w = b.wine;
    _nameCtrl.text = w?.name ?? '';
    _producerCtrl.text = w?.producer ?? '';
    _vintageCtrl.text = w?.vintage != null ? '${w!.vintage}' : '';
    _wineType = _normalizeWineType(w?.type ?? 'red');
    _countryCtrl.text = w?.country ?? 'France';
    _regionCtrl.text = w?.region ?? 'Bordeaux';
    _appellationCtrl.text = w?.appellation ?? '';
    _selectedCurrency = b.currency;
    if (b.purchasePrice != null) {
      _priceCtrl.text = b.purchasePrice!.toStringAsFixed(0);
    }
    _purchaseLocationCtrl.text = b.purchaseLocation ?? '';
    _rackCtrl.text = b.rack ?? '';
    _shelfCtrl.text = b.shelf ?? '';
    _notesCtrl.text = b.notes ?? '';
    if (w?.alcoholPct != null) {
      _alcoholPctCtrl.text = w!.alcoholPct!.toStringAsFixed(w.alcoholPct! % 1 == 0 ? 0 : 1);
    }
  }

  Future<void> _analyzeImage() async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = 'offline';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final scanService = ScanService(ref.read(supabaseProvider));
      final result = await scanService.analyzeBottleImage(
        imagePath: widget.imagePath,
        imageBytes: widget.imageBytes,
      );
      
      if (mounted) {
        setState(() {
          _scanResult = result;
          _nameCtrl.text = result.name;
          _producerCtrl.text = result.producer ?? '';
          _vintageCtrl.text = result.vintage != null ? '${result.vintage}' : '';
          _wineType = _normalizeWineType(result.wineType);
          _countryCtrl.text = result.country.isNotEmpty ? result.country : 'France';
          _regionCtrl.text = result.region.isNotEmpty ? result.region : 'Bordeaux';
          _appellationCtrl.text = result.appellation ?? '';
          if (result.alcoholPct != null) {
            _alcoholPctCtrl.text = result.alcoholPct!.toStringAsFixed(result.alcoholPct! % 1 == 0 ? 0 : 1);
          }
          // Note: result.tastingNotes is an enological property of the wine, stored on Wine,
          // not user's personal bottle notes (_notesCtrl.text remains clean for user input).
          if (result.estimatedMarketValue != null && _priceCtrl.text.isEmpty) {
            _priceCtrl.text = result.estimatedMarketValue!.toStringAsFixed(0);
          }
        });

        // 1. Multi-Bottle detection check
        if (result.detectedQuantity > 1) {
          await _promptMultiBottleConfirmation(result.detectedQuantity, result.packagingType);
        }

        // 2. Prompt vintage confirmation
        await _promptVintageConfirmation(result.vintage);

        // 3. Check duplicate in cellar
        _checkDuplicateInCellar();
      }
    } catch (e, stack) {
      AppLogger.error('REVIEW_SCREEN', 'Image scan failed', e, stack);
      if (mounted) {
        setState(() {
          _analysisError = 'L\'analyse automatique a rencontré une difficulté ($e). Vous pouvez réessayer ou remplir manuellement.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _promptMultiBottleConfirmation(int detectedQty, String? pkgType) async {
    if (!mounted) return;
    String pkgLabel = '$detectedQty bouteilles';
    if (pkgType == 'carton_6' || detectedQty == 6) pkgLabel = 'Carton de 6 bouteilles 📦';
    if (pkgType == 'crate_12' || detectedQty == 12) pkgLabel = 'Caisse bois de 12 bouteilles 🪵';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Expanded(child: Text('Conditionnement Détecté')),
          ],
        ),
        content: Text(
          'L\'IA a identifié plusieurs exemplaires sur votre photo ($pkgLabel).\n\nSouhaitez-vous enregistrer directement $detectedQty bouteilles ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _quantity = 1);
              Navigator.pop(ctx);
            },
            child: const Text('Non, 1 seule bouteille'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _quantity = detectedQty);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            child: Text('Oui, $detectedQty bouteilles', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static String _normalizeColor(String? type) {
    final t = (type ?? 'red').toLowerCase().trim();
    if (t.contains('red') || t.contains('rouge')) return 'red';
    if (t.contains('white') || t.contains('blanc')) return 'white';
    if (t.contains('rosé') || t.contains('rose')) return 'rosé';
    if (t.contains('sparkling') || t.contains('champagne') || t.contains('bulles') || t.contains('crémant')) return 'sparkling';
    if (t.contains('sweet') || t.contains('liquoreux') || t.contains('moelleux') || t.contains('dessert')) return 'dessert';
    if (t.contains('fortified') || t.contains('porto')) return 'fortified';
    return t;
  }

  static String _cleanProducer(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\b(domaine|château|chateau|maison|vignoble|vignobles|clos|cave|de|la|les|du|des|le)\b'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static String _cleanWineName(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\b(rouge|blanc|rosé|rose|brut|sec|demi-sec|grand cru|premier cru|cru)\b'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  void _checkDuplicateInCellar() {
    final cellarId = ref.read(currentCellarIdProvider);
    if (cellarId == null) return;
    final bottles = ref.read(bottlesProvider(cellarId)).value ?? [];

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      if (_duplicateBottle != null) setState(() => _duplicateBottle = null);
      return;
    }

    final producer = _producerCtrl.text.trim();
    final vintageStr = _vintageCtrl.text.trim();
    final vintage = int.tryParse(vintageStr);
    final color = _normalizeColor(_wineType);

    final cleanCurrentName = _cleanWineName(name);
    final cleanCurrentProd = _cleanProducer(producer);

    Bottle? foundDuplicate;

    for (final b in bottles) {
      if (b.isConsumed) continue;
      final bw = b.wine;
      if (bw == null) continue;

      // 1. Check Vintage (Année) - If specified on either side, must match exactly
      final bVintage = bw.vintage;
      if (vintage != null || bVintage != null) {
        if (vintage != bVintage) continue;
      }

      // 2. Check Color / Type (Couleur)
      final bColor = _normalizeColor(bw.type);
      if (color != bColor) continue;

      // 3. Check Domaine / Producteur
      final bProducer = (bw.producer ?? '').trim();
      final cleanBProd = _cleanProducer(bProducer);

      if (cleanCurrentProd.isNotEmpty && cleanBProd.isNotEmpty) {
        bool prodMatch = cleanCurrentProd == cleanBProd;
        if (!prodMatch && cleanCurrentProd.length >= 5 && cleanBProd.length >= 5) {
          prodMatch = cleanCurrentProd.contains(cleanBProd) || cleanBProd.contains(cleanCurrentProd);
        }
        if (!prodMatch) continue;
      } else if (cleanCurrentProd.isNotEmpty && cleanBProd.isEmpty) {
        final cleanBName = _cleanWineName(bw.name);
        if (!cleanBName.contains(cleanCurrentProd)) continue;
      } else if (cleanCurrentProd.isEmpty && cleanBProd.isNotEmpty) {
        if (!cleanCurrentName.contains(cleanBProd)) continue;
      }

      // 3.5. Check Cuvée / Parcelle (e.g. "La Tourtine" vs "La Miguoua", "Les Clos", etc.)
      final cuvee1 = (_scanResult?.cuveeParcel ?? widget.prefillBottle?.wine?.cuveeParcel ?? '').trim().toLowerCase();
      final cuvee2 = (bw.cuveeParcel ?? '').trim().toLowerCase();

      final cleanBName = _cleanWineName(bw.name);
      if (cleanCurrentName.isEmpty || cleanBName.isEmpty) continue;

      if (cuvee1.isNotEmpty && cuvee2.isNotEmpty) {
        final c1Clean = _cleanWineName(cuvee1);
        final c2Clean = _cleanWineName(cuvee2);
        if (c1Clean != c2Clean && !c1Clean.contains(c2Clean) && !c2Clean.contains(c1Clean)) {
          continue; // Different explicit cuvée/parcel -> NOT duplicate!
        }
      } else if (cuvee1.isNotEmpty && cuvee2.isEmpty) {
        final c1Clean = _cleanWineName(cuvee1);
        if (c1Clean.length >= 4 && !cleanBName.contains(c1Clean)) {
          continue; // Current has specific parcel not present in cellar wine
        }
      } else if (cuvee1.isEmpty && cuvee2.isNotEmpty) {
        final c2Clean = _cleanWineName(cuvee2);
        if (c2Clean.length >= 4 && !cleanCurrentName.contains(c2Clean)) {
          continue; // Cellar wine has specific parcel not present in current wine
        }
      }

      // 4. Check Wine Name (Nom du vin)
      final lengthDiff = (cleanCurrentName.length - cleanBName.length).abs();
      final nameMatch = cleanCurrentName == cleanBName ||
          (lengthDiff <= 3 && cleanCurrentName.length >= 6 && cleanBName.length >= 6 &&
              (cleanBName.contains(cleanCurrentName) || cleanCurrentName.contains(cleanBName)));

      if (nameMatch) {
        foundDuplicate = b;
        break;
      }
    }

    if (foundDuplicate != _duplicateBottle) {
      setState(() {
        _duplicateBottle = foundDuplicate;
        if (foundDuplicate != null) {
          _dismissDuplicate = false;
        }
      });
      if (foundDuplicate != null) {
        AppLogger.info('REVIEW_SCREEN', 'Duplicate detected with bottle ID: ${foundDuplicate.id} ("${foundDuplicate.wine?.name}")');
      }
    }
  }

  Future<void> _increaseExistingBottleStock() async {
    if (_duplicateBottle == null) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(cellarRepositoryProvider);
      final newQty = _duplicateBottle!.quantity + _quantity;
      await repo.updateBottleQuantity(_duplicateBottle!.id, newQty, cellarId: _duplicateBottle!.cellarId);
      
      final cellarId = ref.read(currentCellarIdProvider);
      if (cellarId != null) ref.invalidate(bottlesProvider(cellarId));

      AppLogger.info('REVIEW_SCREEN', 'Updated stock for bottle ${_duplicateBottle!.id} to $newQty');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🍾 Stock augmenté avec succès ! ($newQty bouteilles en cave)'),
            backgroundColor: const Color(0xFF8B1E3F),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour du stock : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _promptVintageConfirmation(int? detectedVintage) async {
    // Only prompt the user if vintage was NOT detected by AI
    if (detectedVintage != null && detectedVintage > 0) return;
    if (!mounted) return;
    final tempVintageCtrl = TextEditingController();

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.calendar_month, color: Color(0xFFD4AF37)),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Millésime / Année', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Indiquez ou confirmez l\'année de récolte de cette bouteille :',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tempVintageCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Année (ex: 2018, 2020)',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _vintageCtrl.text = '';
                  Navigator.pop(ctx);
                },
                child: const Text('Inconnu / Non millésimé (NM)', style: TextStyle(color: Colors.grey)),
              ),
              FilledButton(
                onPressed: () {
                  _vintageCtrl.text = tempVintageCtrl.text.trim();
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Valider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } finally {
      tempVintageCtrl.dispose();
    }
  }

  String _normalizeWineType(String type) {
    final lower = type.toLowerCase().trim();
    if (lower.contains('bénédictine') || lower.contains('benedictine') || lower == 'liqueur') return 'liqueur';
    if (lower.contains('whisky') || lower.contains('whiskey') || lower.contains('bourbon') || lower.contains('scotch')) return 'whisky';
    if (lower.contains('rhum') || lower.contains('rum')) return 'rhum';
    if (lower.contains('gin')) return 'gin';
    if (lower.contains('vodka')) return 'vodka';
    if (lower.contains('tequila') || lower.contains('mezcal')) return 'tequila';
    if (lower.contains('cognac') || lower.contains('armagnac') || lower.contains('brandy')) return 'cognac';
    if (lower == 'spirit' || lower == 'spiritueux') return 'spirit';
    if (lower.contains('blanc') || lower == 'white') return 'white';
    if (lower.contains('ros') || lower == 'rosé') return 'rosé';
    if (lower.contains('sparkling') || lower.contains('champ') || lower.contains('bulles') || lower.contains('effervescent')) return 'sparkling';
    if (lower.contains('dessert') || lower.contains('moelleux') || lower.contains('liquoreux')) return 'dessert';
    return 'red';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _producerCtrl.dispose();
    _vintageCtrl.dispose();
    _alcoholPctCtrl.dispose();
    _regionCtrl.dispose();
    _countryCtrl.dispose();
    _appellationCtrl.dispose();
    _priceCtrl.dispose();
    _purchaseLocationCtrl.dispose();
    _notesCtrl.dispose();
    _rackCtrl.dispose();
    _shelfCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBottle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final repo = ref.read(cellarRepositoryProvider);
      
      // Determine cellar ID
      String? cellarId = ref.read(currentCellarIdProvider);
      if (cellarId == null || cellarId.isEmpty) {
        final userCellars = await repo.getUserCellarsWithRole();
        if (userCellars.isNotEmpty) {
          final first = userCellars.first;
          final cMap = first['cellars'];
          if (cMap is Map) {
            cellarId = cMap['id']?.toString();
          } else {
            cellarId = first['cellar_id']?.toString();
          }
        } else {
          final newCellar = await repo.createCellar(name: 'Cave Principale');
          cellarId = newCellar.id;
        }
        if (cellarId != null) {
          ref.read(currentCellarIdProvider.notifier).state = cellarId;
        }
      }

      if (cellarId == null) {
        throw Exception('Impossible de trouver ou créer une cave pour cet utilisateur.');
      }

      // Distant Cellar Proximity Warning
      final allRawCellars = await repo.getUserCellarsWithRole();
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
                '${distCheck.warningMessage}\n\nSouhaitez-vous quand même enregistrer cette bouteille dans la cave "${targetCellar!.displayName}" ?',
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
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      final vintage = int.tryParse(_vintageCtrl.text.trim());
      final price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));

      // Recompute or validate drinking window against the effective vintage
      int? drinkStart = _scanResult?.idealDrinkingStart;
      int? drinkEnd = _scanResult?.idealDrinkingEnd;
      int? peakStart = _scanResult?.peakDrinkingStart;
      int? peakEnd = _scanResult?.peakDrinkingEnd;

      if (vintage != null) {
        if (drinkStart == null || drinkStart < vintage || drinkEnd == null || drinkEnd < vintage) {
          final computed = WineOenologyAdvisor.computeDrinkingWindow(
            wineType: _wineType,
            vintage: vintage,
            region: _regionCtrl.text.trim(),
            appellation: _appellationCtrl.text.trim().isEmpty ? null : _appellationCtrl.text.trim(),
            classification: _scanResult?.classification,
            wineName: _nameCtrl.text.trim(),
          );
          drinkStart = computed.drinkStart;
          drinkEnd = computed.drinkEnd;
          peakStart = computed.peakStart;
          peakEnd = computed.peakEnd;
        }
      }

      final bottle = await repo.addBottle(
        cellarId: cellarId,
        wineName: _nameCtrl.text.trim(),
        producer: _producerCtrl.text.trim().isEmpty ? null : _producerCtrl.text.trim(),
        vintage: vintage,
        wineType: _wineType,
        country: _countryCtrl.text.trim().isEmpty ? 'France' : _countryCtrl.text.trim(),
        region: _regionCtrl.text.trim().isEmpty ? 'Bordeaux' : _regionCtrl.text.trim(),
        appellation: _appellationCtrl.text.trim().isEmpty ? null : _appellationCtrl.text.trim(),
        classification: _scanResult?.classification,
        cuveeParcel: _scanResult?.cuveeParcel,
        alcoholPct: double.tryParse(_alcoholPctCtrl.text.trim().replaceAll(',', '.')) ?? _scanResult?.alcoholPct,
        quantity: _quantity,
        purchasePrice: price,
        currency: _selectedCurrency,
        purchaseLocation: _purchaseLocationCtrl.text.trim().isEmpty ? null : _purchaseLocationCtrl.text.trim(),
        imageUrl: widget.imagePath.isNotEmpty ? widget.imagePath : null,
        rack: _rackCtrl.text.trim().isEmpty ? null : _rackCtrl.text.trim(),
        shelf: _shelfCtrl.text.trim().isEmpty ? null : _shelfCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        tastingNotes: _scanResult?.tastingNotes,
        aiSummary: _scanResult?.summary,
        foodPairings: _scanResult?.foodPairings,
        idealDrinkingStart: drinkStart,
        idealDrinkingEnd: drinkEnd,
        peakDrinkingStart: peakStart,
        peakDrinkingEnd: peakEnd,
        estimatedMarketValue: _scanResult?.estimatedMarketValue,
        localPhotoPath: widget.imagePath.isNotEmpty ? widget.imagePath : null,
      );

      // Upload photo to Supabase storage in background if present
      if (widget.imagePath.isNotEmpty || widget.imageBytes != null) {
        try {
          final scanService = ScanService(supabase);
          final uploadedUrl = await scanService.uploadPhoto(
            bottleId: bottle.id,
            imagePath: widget.imagePath,
            imageBytes: widget.imageBytes,
          );
          if (uploadedUrl != null && bottle.wine != null) {
            await repo.updateWine(bottle.wine!.id, imageUrl: uploadedUrl);
          }
        } catch (photoErr) {
          AppLogger.warning('REVIEW_SCREEN', 'Photo upload failed but bottle was created: $photoErr');
        }
      }

      // Invalidate bottles and cellars cache immediately
      ref.read(currentCellarIdProvider.notifier).state = cellarId;
      notifyCellarChanged(ref, cellarId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🍾 ${_nameCtrl.text.trim()} ajouté avec succès à la cave !'),
            backgroundColor: const Color(0xFF8B1E3F),
          ),
        );
        context.go('/');
      }
    } catch (e, stack) {
      AppLogger.error('REVIEW_SCREEN', 'Error saving bottle', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildPhotoPreview({double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty) {
      return Image.memory(
        widget.imageBytes!,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.wine_bar, size: 80, color: Colors.grey),
      );
    }
    if (widget.imagePath.isEmpty) {
      return const SizedBox.shrink();
    }
    if (kIsWeb || widget.imagePath.startsWith('blob:') || widget.imagePath.startsWith('http://') || widget.imagePath.startsWith('https://')) {
      return Image.network(
        widget.imagePath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.wine_bar, size: 80, color: Colors.grey),
      );
    }
    return Image.file(
      File(widget.imagePath),
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => const Icon(Icons.wine_bar, size: 80, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isAnalyzing) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text('Analyse du vin', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.imagePath.isNotEmpty || (widget.imageBytes != null && widget.imageBytes!.isNotEmpty))
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 100,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildPhotoPreview(height: 130, width: 100, fit: BoxFit.cover),
                    ),
                  ),
                const ChatmelierLoader.detective(
                  size: 190,
                  title: 'Chatmelier essaye de trouver...',
                  subtitle: 'Lecture de l\'étiquette, détection du domaine, millésime et accords mets-vins...',
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_analysisError == 'offline' && !_ignoreUndetected) {
      final isDark = theme.brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1E) : Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
            tooltip: 'Retour',
            onPressed: () => context.pop(),
          ),
          title: const Text('Mode Hors-Ligne', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChatmelierOfflineAntennaWidget(
                  title: 'Chatmelier cherche du réseau...',
                  message: 'La détection photo automatique par IA a besoin d\'une connexion internet. Vous pouvez saisir les détails manuellement ou réessayer dès que le réseau revient.',
                  onRetry: () async {
                    final online = await ref.read(connectivityServiceProvider).checkConnection();
                    if (online && mounted) {
                      _checkAndTriggerAnalysis();
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: const Text(
                      'Saisir manuellement ma bouteille',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () {
                      setState(() {
                        _ignoreUndetected = true;
                        _analysisError = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isUndetected) {
      final isDark = theme.brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1E) : Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
            tooltip: 'Abandonner',
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Bouteille non détectée',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.imagePath.isNotEmpty || (widget.imageBytes != null && widget.imageBytes!.isNotEmpty))
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 130,
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade700, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildPhotoPreview(height: 170, width: 130, fit: BoxFit.cover),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_off, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Text(
                  'Vin non reconnu',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chatmelier n\'a pas réussi à identifier l\'étiquette sur cette photo. Elle est peut-être trop sombre, floue ou avec des reflets.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Option 1: Reprendre une photo
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text(
                      'Reprendre une photo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: Entrer manuellement les détails
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: const Text(
                      'Entrer manuellement les détails',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () {
                      setState(() {
                        _ignoreUndetected = true;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Option 3: Abandonner
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white60 : Colors.black54,
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Abandonner'),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche de la Bouteille'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.restaurant_menu, color: Color(0xFFE65100)),
              tooltip: 'Déguster hors-cave (Restaurant/Amis)',
              onPressed: () {
                final vintage = int.tryParse(_vintageCtrl.text.trim());
                ExternalTastingDialog.show(
                  context,
                  wineName: _nameCtrl.text.trim(),
                  producer: _producerCtrl.text.trim(),
                  vintage: vintage,
                  region: _regionCtrl.text.trim(),
                  appellation: _appellationCtrl.text.trim(),
                  wineType: _wineType,
                  photoUrl: widget.imagePath.isNotEmpty ? widget.imagePath : null,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _saveBottle,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // DUPLICATE SUGGESTION BANNER
            if (_duplicateBottle != null && !_dismissDuplicate) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFFD4AF37), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Vin déjà présent dans votre cave ! (${_duplicateBottle!.quantity} en stock)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ce vin existe déjà (${_duplicateBottle!.wine?.name ?? ""} ${_duplicateBottle!.wine?.vintage != null ? "${_duplicateBottle!.wine!.vintage}" : ""}). Que souhaitez-vous faire ?',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _increaseExistingBottleStock,
                      icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                      label: Text(
                        'Augmenter le stock existant (+$_quantity)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _dismissDuplicate = true),
                        child: const Text('Créer une entrée distincte (autre casier / prix)'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // AI Recognition Banner
            if (_scanResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E3F).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B1E3F).withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF8B1E3F), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vin identifié par l\'IA Sommelier ✨',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8B1E3F)),
                          ),
                          Text(
                            'Informations extraites de votre étiquette. Vérifiez ou ajustez les détails ci-dessous.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Explicit Scan Error & Retry Banner
            if (_analysisError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_analysisError!, style: const TextStyle(fontSize: 12.5)),
                        ),
                      ],
                    ),
                    if (widget.imagePath.isNotEmpty || widget.imageBytes != null) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _checkAndTriggerAnalysis,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Réessayer l\'analyse IA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Photo preview with full-screen zoom preview
            if (widget.imagePath.isNotEmpty || widget.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.black,
                        insetPadding: const EdgeInsets.all(12),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              child: Center(
                                child: _buildPhotoPreview(fit: BoxFit.contain),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withAlpha(40)),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildPhotoPreview(fit: BoxFit.cover),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Agrandir', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Wine Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informations Générales', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom du vin *',
                        hintText: 'ex: Château Margaux, Domaine de la Solitude...',
                        prefixIcon: Icon(Icons.wine_bar),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez saisir le nom du vin' : null,
                      onChanged: (_) => _checkDuplicateInCellar(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _producerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Domaine / Producteur',
                        hintText: 'ex: Famille Perrin, Antinori...',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _checkDuplicateInCellar(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _vintageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Millésime',
                              hintText: 'ex: 2018',
                              prefixIcon: Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _checkDuplicateInCellar(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _alcoholPctCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Alcool',
                              hintText: 'ex: 13.5 ou 40',
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            initialValue: _wineType,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'red', child: Text('Rouge 🍷')),
                              DropdownMenuItem(value: 'white', child: Text('Blanc 🥂')),
                              DropdownMenuItem(value: 'rosé', child: Text('Rosé 🌸')),
                              DropdownMenuItem(value: 'sparkling', child: Text('Bulles 🍾')),
                              DropdownMenuItem(value: 'dessert', child: Text('Moelleux 🍯')),
                              DropdownMenuItem(value: 'liqueur', child: Text('Liqueur 🍯')),
                              DropdownMenuItem(value: 'spirit', child: Text('Spiritueux 🥃')),
                              DropdownMenuItem(value: 'whisky', child: Text('Whisky 🥃')),
                              DropdownMenuItem(value: 'rhum', child: Text('Rhum 🏴‍☠️')),
                              DropdownMenuItem(value: 'gin', child: Text('Gin 🍸')),
                              DropdownMenuItem(value: 'vodka', child: Text('Vodka 🧊')),
                              DropdownMenuItem(value: 'tequila', child: Text('Tequila 🌵')),
                              DropdownMenuItem(value: 'cognac', child: Text('Cognac 🍷')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _wineType = val);
                                _checkDuplicateInCellar();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Origin Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Origine & Terroir', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pays *',
                        prefixIcon: Icon(Icons.public),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Pays obligatoire' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _regionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Région / Vignoble *',
                        hintText: 'ex: Bordeaux, Bourgogne, Vallée du Rhône...',
                        prefixIcon: Icon(Icons.terrain),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Région obligatoire' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _appellationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Appellation (AOC / AOP / DOCG)',
                        hintText: 'ex: Margaux, Pauillac, Saint-Émilion...',
                        prefixIcon: Icon(Icons.verified),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Storage & Purchase Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantité & Achat', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Quantité :', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Prix unitaire',
                              prefixText: '${CurrencyHelper.getSymbol(_selectedCurrency)} ',
                              prefixIcon: const Icon(Icons.payments_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'Devise',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                            ),
                            items: CurrencyHelper.supportedCurrencies.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.code,
                                child: Text('${c.code} (${c.symbol})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCurrency = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _purchaseLocationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Circonstances de l\'achat (texte libre)',
                        hintText: 'ex: Acheté en vacances au Chili avec Caro...',
                        prefixIcon: Icon(Icons.flight_takeoff_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rackCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Casier / Étagère',
                              prefixIcon: Icon(Icons.grid_view),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _shelfCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Niveau / Rangée',
                              prefixIcon: Icon(Icons.table_rows),
                              border: OutlineInputBorder(),
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

            // Notes Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes & Commentaires Personnels', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Impressions, potentiel de garde, circonstances particulières...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _saveBottle,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text(
                  'Ajouter à ma cave',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  final vintage = int.tryParse(_vintageCtrl.text.trim());
                  ExternalTastingDialog.show(
                    context,
                    wineName: _nameCtrl.text.trim(),
                    producer: _producerCtrl.text.trim(),
                    vintage: vintage,
                    region: _regionCtrl.text.trim(),
                    appellation: _appellationCtrl.text.trim(),
                    wineType: _wineType,
                    photoUrl: widget.imagePath.isNotEmpty ? widget.imagePath : null,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1E3F),
                  side: const BorderSide(color: Color(0xFF8B1E3F), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.restaurant, size: 18),
                label: const Text(
                  'Dégusté hors cave (Chez des proches, resto...)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
