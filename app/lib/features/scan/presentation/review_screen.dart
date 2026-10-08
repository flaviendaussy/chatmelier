import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../monetization/domain/politique_pub.dart';
import '../../../l10n/app_localizations.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/services/cellar_location_service.dart';
import '../../cellar/domain/cellar.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/bottle_size.dart';
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
import '../../cellar/presentation/custom_bottle_size_dialog.dart';
import '../../../shared/utils/langue.dart';

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
  final _quantityCtrl = TextEditingController(text: '1');

  String _wineType = 'red';
  String _bottleSize = '75cl';
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
    final uid = ref.read(supabaseProvider).auth.currentUser?.id;
    final dejaFaits = await PolitiquePub.scansEtiquette(uid);
    unawaited(PolitiquePub.compterUnScanEtiquette(uid));
    // Le premier inventaire (30 étiquettes) se fait sans vidéo (V2.3 · G2).
    if (!PolitiquePub.doitMontrer(emplacement: 'scan_etiquette', premium: isPremium, scansEtiquetteDejaFaits: dejaFaits)) {
      await _analyzeImage(runPrompts: true);
      return;
    }

    // 🚀 UX Optimization: Parallelize AI image analysis in background WHILE the ad plays
    // User experiences ~0 seconds perceived waiting time after closing the video!
    ScanResult? analysisResult;
    final analysisFuture = _analyzeImage(runPrompts: false).then((res) {
      analysisResult = res;
      return res;
    });

    // AdMobService appelle SOIT onRewardEarned, SOIT onAdDismissed — jamais les deux
    // (admob_service.dart:226-231). La récompense doit donc être traitée dans
    // onRewardEarned : la version précédente la traitait dans onAdDismissed, si bien
    // que l'utilisateur qui regardait la vidéo jusqu'au bout n'obtenait jamais les
    // invites de fin d'analyse — confirmation du millésime, détection d'un carton de
    // 6 bouteilles, alerte de doublon en cave. Celui qui coupait la vidéo, si.
    final showedAdMob = await AdMobService().showRewardedAd(
      emplacement: 'scan_etiquette',
      onRewardEarned: () async {
        if (!mounted) return;
        final res = analysisResult ?? await analysisFuture;
        if (res != null && mounted) {
          await _runPostAnalysisPrompts(res);
        }
      },
      onAdDismissed: () {
        if (!mounted) return;
        debugPrint('[ReviewScreen] Rewarded ad dismissed without reward. Discarding analysis.');
        setState(() {
          _scanResult = null;
          _nameCtrl.clear();
          _producerCtrl.clear();
          _vintageCtrl.clear();
          _isAnalyzing = false;
          _ignoreUndetected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Vidéo interrompue. Regardez la vidéo jusqu\'au bout pour débloquer l\'analyse IA.', 'Video interrupted. Watch the video to the end to unlock the AI analysis.')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );

    // If AdMob did not show (no fill, offline, web, or ad not ready yet):
    // "Juste de l'admob ou rien": directly unlock the scan without fake ads!
    if (!showedAdMob && mounted) {
      final res = analysisResult ?? await analysisFuture;
      if (res != null && mounted) {
        await _runPostAnalysisPrompts(res);
      }
    }
  }

  void _prefillFromExisting(Bottle b) {
    final w = b.wine;
    _nameCtrl.text = w?.name ?? '';
    _producerCtrl.text = w?.producer ?? '';
    _vintageCtrl.text = w?.vintage != null ? '${w!.vintage}' : '';
    _wineType = _normalizeWineType(w?.type ?? 'red');
    // Inconnu reste vide : « France, Bordeaux » par défaut faisait d'un vin marocain un
    // bordeaux (V2.4 · R1).
    _countryCtrl.text = w?.country ?? '';
    _regionCtrl.text = w?.region ?? '';
    _appellationCtrl.text = w?.appellation ?? '';
    _selectedCurrency = b.currency;
    if (b.purchasePrice != null) {
      _priceCtrl.text = b.purchasePrice!.toStringAsFixed(0);
    }
    _purchaseLocationCtrl.text = b.purchaseLocation ?? '';
    _rackCtrl.text = b.rack ?? '';
    _shelfCtrl.text = b.shelf ?? '';
    _notesCtrl.text = b.notes ?? '';
    _bottleSize = b.bottleSize;
    if (w?.alcoholPct != null) {
      _alcoholPctCtrl.text = w!.alcoholPct!.toStringAsFixed(w.alcoholPct! % 1 == 0 ? 0 : 1);
    }
  }

  Future<ScanResult?> _analyzeImage({bool runPrompts = true}) async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = 'offline';
      });
      return null;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final scanService = ScanService(ref.read(supabaseProvider));
      final currentLang = Localizations.localeOf(context).languageCode;
      final result = await scanService.analyzeBottleImage(
        imagePath: widget.imagePath,
        imageBytes: widget.imageBytes,
        languageCode: currentLang,
      );
      
      if (mounted) {
        setState(() {
          _scanResult = result;
          _nameCtrl.text = result.name;
          _producerCtrl.text = result.producer ?? '';
          _vintageCtrl.text = result.vintage != null ? '${result.vintage}' : '';
          _wineType = _normalizeWineType(result.wineType);
          _countryCtrl.text = result.country;
          _regionCtrl.text = result.region;
          _appellationCtrl.text = result.appellation ?? '';
          if (result.alcoholPct != null) {
            _alcoholPctCtrl.text = result.alcoholPct!.toStringAsFixed(result.alcoholPct! % 1 == 0 ? 0 : 1);
          }
          // Note: result.tastingNotes is an enological property of the wine, stored on Wine,
          // not user's personal bottle notes (_notesCtrl.text remains clean for user input).
          // Le prix d'achat n'est pas la valeur de marché : on ne le préremplit plus avec
          // une estimation (30/09). La personne saisit ce qu'elle a payé.
        });

        if (runPrompts) {
          await _runPostAnalysisPrompts(result);
        }
      }
      return result;
    } catch (e, stack) {
      AppLogger.error('REVIEW_SCREEN', 'Image scan failed', e, stack);
      if (mounted) {
        setState(() {
          _analysisError = tr('L\'analyse automatique a rencontré une difficulté ({e}). Vous pouvez réessayer ou remplir manuellement.', 'The automatic analysis ran into a problem ({e}). You can try again or fill it in by hand.', {'e': e});
        });
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _runPostAnalysisPrompts(ScanResult result) async {
    if (!mounted) return;
    // 1. Multi-Bottle detection check
    if (result.detectedQuantity > 1) {
      await _promptMultiBottleConfirmation(result.detectedQuantity, result.packagingType);
    }

    // 2. Prompt vintage confirmation
    await _promptVintageConfirmation(result.vintage);

    // 3. Check duplicate in cellar
    _checkDuplicateInCellar();
  }

  Future<void> _promptMultiBottleConfirmation(int detectedQty, String? pkgType) async {
    if (!mounted) return;
    String pkgLabel = tr('{detectedQty} bouteilles', '{detectedQty} bottles', {'detectedQty': detectedQty});
    final l10n = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    if (pkgType == 'carton_6' || detectedQty == 6) {
      pkgLabel = trSi(isFr, 'Carton de 6 bouteilles 📦', '6-bottle case 📦');
    }
    if (pkgType == 'crate_12' || detectedQty == 12) {
      pkgLabel = trSi(isFr, 'Caisse bois de 12 bouteilles 🪵', '12-bottle wooden crate 🪵');
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFFD4AF37)),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n?.reviewPackagingDetected ?? 'Conditionnement Détecté')),
          ],
        ),
        content: Text(
          trSi(isFr, 'L\'IA a identifié plusieurs exemplaires sur votre photo ({pkgLabel}).\n\nSouhaitez-vous enregistrer directement {detectedQty} bouteilles ?', 'AI identified multiple bottles on your photo ({pkgLabel}).\n\nWould you like to directly add {detectedQty} bottles?', {'pkgLabel': pkgLabel, 'detectedQty': detectedQty}),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _quantity = 1;
                _quantityCtrl.text = '1';
              });
              Navigator.pop(ctx);
            },
            child: Text(l10n?.reviewSingleBottleOnly ?? 'Non, 1 seule bouteille'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _quantity = detectedQty;
                _quantityCtrl.text = '$detectedQty';
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n?.reviewMultipleBottlesConfirm(detectedQty) ?? 'Oui, $detectedQty bouteilles',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static String _normalizeColor(String? type) {
    final t = (type ?? '').toLowerCase().trim();
    if (t.contains('italicus') ||
        t.contains('rosolio') ||
        t.contains('bénédictine') ||
        t.contains('benedictine') ||
        t.contains('amaretto') ||
        t.contains('disaronno') ||
        t.contains('chartreuse') ||
        t.contains('cointreau') ||
        t.contains('chambord') ||
        t.contains('pimm') ||
        t.contains('fleur de lavande') ||
        t.contains('liqueur')) {
      return 'liqueur';
    }
    if (RegExp(r'\bgin\b', caseSensitive: false).hasMatch(t)) return 'gin';
    if (t.contains('vodka')) return 'vodka';
    if (t.contains('whisky') || t.contains('whiskey') || t.contains('bourbon') || t.contains('scotch')) return 'whisky';
    if (t.contains('rhum') || t.contains('rum')) return 'rhum';
    if (t.contains('tequila') || t.contains('mezcal')) return 'tequila';
    if (t.contains('cognac') || t.contains('armagnac') || t.contains('calvados')) return 'cognac';
    if (t.contains('grappa') || t.contains('vinaccia') || t.contains('acquavite')) return 'grappa';
    if (t.contains('eau de vie') || t.contains('eau-de-vie') || t.contains('marc de ')) return 'eau-de-vie';
    if (t.contains('pisco') ||
        t.contains('aguardente') ||
        t.contains('pastis') ||
        t.contains('ricard') ||
        t.contains('absinthe') ||
        t == 'spirit' ||
        t == 'spiritueux') {
      return 'spirit';
    }
    if (t.contains('porto') ||
        t.contains('port wine') ||
        t.contains('sherry') ||
        t.contains('xérès') ||
        t.contains('xeres') ||
        t.contains('banyuls') ||
        t.contains('maury') ||
        t.contains('rivesaltes') ||
        t.contains('madère') ||
        t.contains('madeira') ||
        t.contains('marsala') ||
        t.contains('vermouth') ||
        t.contains('fortified') ||
        t.contains('muté') ||
        t.contains('mute')) {
      return 'fortified';
    }
    if (t.contains('red') || t.contains('rouge')) return 'red';
    if (t.contains('white') || t.contains('blanc')) return 'white';
    if (t.contains('rosé') || t.contains('rose')) return 'rosé';
    if (t.contains('sparkling') || t.contains('champagne') || t.contains('bulles') || t.contains('crémant')) return 'sparkling';
    if (t.contains('sweet') || t.contains('liquoreux') || t.contains('moelleux') || t.contains('dessert')) return 'dessert';
    if (t.contains('orange')) return 'orange';
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

      // 2.5. Check Bottle Size / Format (e.g. 75cl vs 1.5L)
      if (b.bottleSize != _bottleSize) continue;

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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.reviewStockUpdatedSuccess(newQty) ??
                  '🍾 Stock augmenté avec succès ! ($newQty bouteilles en cave)',
            ),
            backgroundColor: const Color(0xFF8B1E3F),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur lors de la mise à jour du stock : {e}', 'Couldn\'t update the stock: {e}', {'e': e}))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _promptVintageConfirmation(int? detectedVintage) async {
    // Only prompt the user if vintage was NOT detected by AI
    if (detectedVintage != null && detectedVintage > 0) return;

    // Do NOT prompt for spirits, fortified/mutés, or non-vintage categories
    final typeLower = _wineType.toLowerCase();
    final isSpiritOrFortified = typeLower == 'spirit' ||
        typeLower == 'spiritueux' ||
        typeLower == 'fortified' ||
        typeLower == 'muté' ||
        typeLower == 'mute' ||
        typeLower == 'liqueur' ||
        typeLower == 'cocktail' ||
        typeLower == 'beer' ||
        typeLower == 'biere' ||
        typeLower == 'cider' ||
        typeLower == 'cidre';
    if (isSpiritOrFortified) return;

    if (!mounted) return;
    final tempVintageCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFFD4AF37)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n?.reviewVintageYear ?? 'Millésime / Année',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trSi(isFr, 'Indiquez ou confirmez l\'année de récolte de cette bouteille :', 'Enter or confirm the harvest year of this bottle:'),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tempVintageCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: trSi(isFr, 'Année (ex: 2018, 2020)', 'Year (e.g. 2018, 2020)'),
                    prefixIcon: const Icon(Icons.date_range),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    _vintageCtrl.text = '';
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4AF37)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.all_inclusive, size: 18, color: Color(0xFFB8860B)),
                        const SizedBox(width: 8),
                        Text(
                          trSi(isFr, 'C\'est un Non millésimé (NM)', 'Non-vintage (NV)'),
                          style: const TextStyle(
                            color: Color(0xFF8B1E3F),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
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
                child: Text(l10n?.reviewNonVintage ?? 'Passer / Non millésimé'),
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
                child: Text(
                  l10n?.reviewValidate ?? 'Valider',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
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
    return _normalizeColor(type);
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
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBottle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    // Le conteneur survit à l'écran, pas `ref` : voir l'invalidation en fin d'enregistrement.
    final conteneur = ProviderScope.containerOf(context, listen: false);

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
        throw Exception(tr('Impossible de trouver ou créer une cave pour cet utilisateur.', 'Couldn\'t find or create a cellar for this user.'));
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
          final l10n = AppLocalizations.of(context);
          final warning = distCheck.formatWarning(l10n);
          final proceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.location_off_outlined, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.distantCellarTitle ?? 'Cave distante détectée',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                l10n?.distantCellarAddConfirm(warning, targetCellar!.displayName) ??
                    '$warning\n\nSouhaitez-vous quand même enregistrer cette bouteille dans la cave "${targetCellar!.displayName}" ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n?.cancel ?? 'Annuler'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E3F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    l10n?.continueAnyway ?? 'Continuer quand même',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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
        country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
        region: _regionCtrl.text.trim().isEmpty ? null : _regionCtrl.text.trim(),
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
        bottleSize: _bottleSize,
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

      // Invalidate bottles and cellars cache immediately.
      // Par le conteneur et non par `ref` : si l'écran a été quitté pendant l'envoi de la
      // photo, `ref` n'est plus utilisable — la bouteille, pourtant créée, finissait en
      // « Error saving bottle », sans confirmation ni rafraîchissement (edith, 22/09, deux fois).
      conteneur.read(currentCellarIdProvider.notifier).state = cellarId;
      notifyCellarChangedIn(conteneur, cellarId);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.reviewBottleAddedSuccess(_nameCtrl.text.trim()) ??
                  '🍾 ${_nameCtrl.text.trim()} ajouté avec succès à la cave !',
            ),
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
            content: Text(tr('Erreur lors de l\'ajout : {e}', 'Couldn\'t add it: {e}', {'e': e})),
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
    final l10n = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

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
          title: Text(l10n?.reviewBottleAnalysis ?? 'Analyse de la bouteille', style: const TextStyle(color: Colors.white)),
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
                ChatmelierLoader.detective(
                  size: 190,
                  title: tr('Chatmelier essaye de trouver...', 'Chatmelier is looking...'),
                  subtitle: tr('Lecture de l\'étiquette, détection du domaine ou de la distillerie, millésime...', 'Reading the label, finding the estate or distillery, the vintage...'),
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
            tooltip: tr('Retour', 'Back'),
            onPressed: () => context.pop(),
          ),
          title: Text(tr('Mode Hors-Ligne', 'Offline mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChatmelierOfflineAntennaWidget(
                  title: tr('Chatmelier cherche du réseau...', 'Chatmelier is looking for a connection...'),
                  message: tr('La détection photo automatique par IA a besoin d\'une connexion internet. Vous pouvez saisir les détails manuellement ou réessayer dès que le réseau revient.', 'Automatic photo recognition needs an internet connection. You can enter the details by hand, or try again once you\'re back online.'),
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
                    label: Text(
                      tr('Saisir manuellement ma bouteille', 'Enter my bottle by hand'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1E) : Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
            tooltip: trSi(isFr, 'Abandonner', 'Discard'),
            onPressed: () => context.pop(),
          ),
          title: Text(
            trSi(isFr, 'Bouteille non détectée', 'Bottle not detected'),
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
                  trSi(isFr, 'Vin non reconnu', 'Wine not recognized'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  trSi(isFr, 'Chatmelier n\'a pas réussi à identifier l\'étiquette sur cette photo. Elle est peut-être trop sombre, floue ou avec des reflets.', 'Chatmelier could not identify the label on this photo. It may be too dark, blurry, or have reflections.'),
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
                    label: Text(
                      trSi(isFr, 'Reprendre une photo', 'Retake photo'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                    label: Text(
                      trSi(isFr, 'Entrer manuellement les détails', 'Enter details manually'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                  label: Text(l10n?.reviewDiscard ?? 'Abandonner'),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasUnsavedData = _nameCtrl.text.trim().isNotEmpty ||
        _producerCtrl.text.trim().isNotEmpty ||
        _vintageCtrl.text.trim().isNotEmpty ||
        _priceCtrl.text.trim().isNotEmpty;

    return PopScope(
      canPop: !hasUnsavedData,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n?.reviewDiscardConfirmTitle ?? 'Abandonner la saisie ?'),
            content: Text(
              trSi(isFr, 'Vous avez des informations non enregistrées sur cette bouteille. Souhaitez-vous vraiment quitter sans sauvegarder ?', 'You have unsaved information for this bottle. Are you sure you want to discard without saving?'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n?.reviewContinueEditing ?? 'Continuer la saisie'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n?.reviewDiscardWithoutSaving ?? 'Quitter sans enregistrer'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: trSi(isFr, 'Annuler et fermer', 'Cancel and close'),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n?.reviewBottleDetails ?? 'Fiche de la Bouteille'),
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
              tooltip: trSi(isFr, 'Déguster hors-cave (Restaurant/Amis)', 'Taste outside cellar (Restaurant/Friends)'),
              onPressed: () {
                final vintage = int.tryParse(_vintageCtrl.text.trim());
                ExternalTastingDialog.show(
                  context,
                  wineName: _nameCtrl.text.trim(),
                  producer: _producerCtrl.text.trim(),
                  vintage: vintage,
                  region: _regionCtrl.text.trim(),
                  appellation: _appellationCtrl.text.trim(),
                  country: _countryCtrl.text.trim(),
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
                child: Text(
                  l10n?.save ?? 'Enregistrer',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
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
              Builder(
                builder: (context) {
                  final dupStock = _duplicateBottle!.quantity;
                  final totalStock = dupStock + _quantity;
                  return Container(
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
                                trSi(isFr, 'Vin déjà présent dans votre cave ! ({dupStock} en stock)', 'Wine already in your cellar! ({dupStock} in stock)', {'dupStock': dupStock}),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trSi(isFr, 'Ce vin existe déjà ({v1} {v2}). Que souhaitez-vous faire ?', 'This wine already exists ({v1} {v2}). What would you like to do?', {'v1': _duplicateBottle!.wine?.name ?? "", 'v2': _duplicateBottle!.wine?.vintage != null ? "${_duplicateBottle!.wine!.vintage}" : ""}),
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(height: 10),

                        // Calculation formula card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(l10n?.reviewStockInCellar ?? 'Stock en cave', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text('$dupStock', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Icon(Icons.add, size: 16, color: Colors.grey),
                              Column(
                                children: [
                                  Text(l10n?.reviewStockAddition ?? 'Ajout', style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('+$_quantity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                                ],
                              ),
                              const Text('=', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Column(
                                children: [
                                  Text(l10n?.reviewStockNewTotal ?? 'Nouveau total', style: const TextStyle(fontSize: 11, color: Color(0xFF8B1E3F), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('$totalStock', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stepper row in duplicate banner
                        Row(
                          children: [
                            Text(l10n?.reviewQuantityToAdd ?? 'Quantité à ajouter :', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              onPressed: _quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantity--;
                                        _quantityCtrl.text = '$_quantity';
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove, size: 16),
                            ),
                            Container(
                              width: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: TextFormField(
                                controller: _quantityCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) {
                                  final p = int.tryParse(val);
                                  if (p != null && p > 0) {
                                    setState(() => _quantity = p);
                                  }
                                },
                              ),
                            ),
                            IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                  _quantityCtrl.text = '$_quantity';
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        FilledButton.icon(
                          onPressed: _increaseExistingBottleStock,
                          icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                          label: Text(
                            trSi(isFr, 'Augmenter le stock existant ({totalStock} btl au total)', 'Increase existing stock ({totalStock} bottles total)', {'totalStock': totalStock}),
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
                            child: Text(l10n?.reviewSeparateEntry ?? 'Créer une entrée distincte (autre casier / prix)'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                          Text(
                            trSi(isFr, 'Vin identifié par l\'IA Sommelier ✨', 'Wine identified by Sommelier AI ✨'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8B1E3F)),
                          ),
                          Text(
                            trSi(isFr, 'Informations extraites de votre étiquette. Vérifiez ou ajustez les détails ci-dessous.', 'Information extracted from your label. Verify or adjust the details below.'),
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
                        label: Text(tr('Réessayer l\'analyse IA', 'Retry the AI analysis')),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(l10n?.reviewEnlarge ?? 'Agrandir', style: const TextStyle(color: Colors.white, fontSize: 11)),
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
                    Text(l10n?.reviewGeneralInfo ?? 'Informations Générales', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: trSi(isFr, 'Nom du vin *', 'Wine name *'),
                        hintText: trSi(isFr, 'ex: Château Margaux, Domaine de la Solitude...', 'e.g. Château Margaux, Opus One...'),
                        prefixIcon: const Icon(Icons.wine_bar),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? (trSi(isFr, 'Veuillez saisir le nom du vin', 'Please enter wine name')) : null,
                      onChanged: (_) => _checkDuplicateInCellar(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _producerCtrl,
                      decoration: InputDecoration(
                        labelText: trSi(isFr, 'Domaine / Producteur', 'Producer / Winery'),
                        hintText: trSi(isFr, 'ex: Famille Perrin, Antinori...', 'e.g. Famille Perrin, Antinori...'),
                        prefixIcon: const Icon(Icons.business),
                        border: const OutlineInputBorder(),
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
                            decoration: InputDecoration(
                              labelText: trSi(isFr, 'Millésime', 'Vintage'),
                              hintText: trSi(isFr, 'ex: 2018', 'e.g. 2018'),
                              prefixIcon: const Icon(Icons.calendar_today, size: 16),
                              border: const OutlineInputBorder(),
                              suffixIcon: _vintageCtrl.text.isEmpty
                                  ? Tooltip(
                                      message: trSi(isFr, 'Non millésimé', 'Non-vintage'),
                                      child: const Icon(Icons.all_inclusive, size: 16, color: Color(0xFF8B1E3F)),
                                    )
                                  : null,
                            ),
                            onChanged: (_) {
                              setState(() {});
                              _checkDuplicateInCellar();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _alcoholPctCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: trSi(isFr, 'Alcool', 'Alcohol'),
                              hintText: trSi(isFr, 'ex: 13.5 ou 40', 'e.g. 13.5 or 40'),
                              suffixText: '%',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            initialValue: _wineType,
                            decoration: InputDecoration(
                              labelText: trSi(isFr, 'Catégorie', 'Category'),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(value: 'red', child: Text(l10n?.wineTypeRed ?? 'Rouge 🍷')),
                              DropdownMenuItem(value: 'white', child: Text(l10n?.wineTypeWhite ?? 'Blanc 🥂')),
                              DropdownMenuItem(value: 'rosé', child: Text(l10n?.wineTypeRose ?? 'Rosé 🌸')),
                              DropdownMenuItem(value: 'sparkling', child: Text(l10n?.wineTypeSparkling ?? 'Bulles 🍾')),
                              DropdownMenuItem(value: 'dessert', child: Text(l10n?.wineTypeDessert ?? 'Moelleux 🍯')),
                              DropdownMenuItem(value: 'liqueur', child: Text(l10n?.wineTypeLiqueur ?? 'Liqueur 🍯')),
                              DropdownMenuItem(value: 'spirit', child: Text(l10n?.wineTypeSpirit ?? 'Spiritueux 🥃')),
                              DropdownMenuItem(value: 'grappa', child: Text(l10n?.wineTypeGrappa ?? 'Grappa 🍇')),
                              DropdownMenuItem(value: 'eau-de-vie', child: Text(l10n?.wineTypeEauDeVie ?? 'Eau-de-vie 🍐')),
                              DropdownMenuItem(value: 'whisky', child: Text(l10n?.wineTypeWhisky ?? 'Whisky 🥃')),
                              DropdownMenuItem(value: 'rhum', child: Text(l10n?.wineTypeRum ?? 'Rhum 🏴‍☠️')),
                              DropdownMenuItem(value: 'gin', child: Text(l10n?.wineTypeGin ?? 'Gin 🍸')),
                              DropdownMenuItem(value: 'vodka', child: Text(l10n?.wineTypeVodka ?? 'Vodka 🧊')),
                              DropdownMenuItem(value: 'tequila', child: Text(l10n?.wineTypeTequila ?? 'Tequila 🌵')),
                              DropdownMenuItem(value: 'cognac', child: Text(l10n?.wineTypeCognac ?? 'Cognac 🍷')),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _vintageCtrl.clear();
                            _checkDuplicateInCellar();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _vintageCtrl.text.isEmpty
                                ? const Color(0xFF8B1E3F).withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _vintageCtrl.text.isEmpty
                                  ? const Color(0xFF8B1E3F)
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.all_inclusive,
                                size: 15,
                                color: _vintageCtrl.text.isEmpty
                                    ? const Color(0xFF8B1E3F)
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _vintageCtrl.text.isEmpty
                                    ? (trSi(isFr, 'Non millésimé (NM) ✓', 'Non-vintage (NV) ✓'))
                                    : (trSi(isFr, 'Cliquer si Non millésimé (NM)', 'Tap if Non-vintage (NV)')),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _vintageCtrl.text.isEmpty
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _vintageCtrl.text.isEmpty
                                      ? const Color(0xFF8B1E3F)
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                    Text(l10n?.reviewOriginTerroir ?? 'Origine & Terroir', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryCtrl,
                      decoration: InputDecoration(
                        labelText: trSi(isFr, 'Pays *', 'Country *'),
                        prefixIcon: const Icon(Icons.public),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? (trSi(isFr, 'Pays obligatoire', 'Country required')) : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _regionCtrl,
                      decoration: InputDecoration(
                        labelText: trSi(isFr, 'Région / Vignoble *', 'Region / Vineyard *'),
                        hintText: trSi(isFr, 'ex: Bordeaux, Bourgogne, Vallée du Rhône...', 'e.g. Bordeaux, Burgundy, Napa Valley...'),
                        prefixIcon: const Icon(Icons.terrain),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? (trSi(isFr, 'Région obligatoire', 'Region required')) : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _appellationCtrl,
                      decoration: InputDecoration(
                        labelText: trSi(isFr, 'Appellation (AOC / AOP / DOCG)', 'Appellation (AOC / AOP / DOCG)'),
                        hintText: trSi(isFr, 'ex: Margaux, Pauillac, Saint-Émilion...', 'e.g. Margaux, Pauillac, Saint-Émilion...'),
                        prefixIcon: const Icon(Icons.verified),
                        border: const OutlineInputBorder(),
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
                    Text(l10n?.reviewQuantityPurchase ?? 'Quantité & Achat', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trSi(isFr, 'Format / Contenance', 'Bottle Size / Volume'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ...['37.5cl', '75cl', '1.5L', '3L'].map((sizeCode) {
                              final sizeObj = BottleSize.fromCode(sizeCode);
                              final isSelected = _bottleSize == sizeCode;
                              return ChoiceChip(
                                label: Text(sizeObj.shortName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _bottleSize = sizeCode);
                                    _checkDuplicateInCellar();
                                  }
                                },
                                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.25),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFF8B1E3F) : null,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              );
                            }),
                            ActionChip(
                              avatar: const Icon(Icons.more_horiz, size: 16),
                              label: Text(!['37.5cl', '75cl', '1.5L', '3L'].contains(_bottleSize)
                                  ? BottleSize.fromCode(_bottleSize).shortName
                                  : (trSi(isFr, 'Autre format...', 'Other size...'))),
                              onPressed: _showAllBottleSizesPicker,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(trSi(isFr, 'Quantité :', 'Quantity:'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                    _quantityCtrl.text = '$_quantity';
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                        ),
                        Container(
                          width: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextFormField(
                            controller: _quantityCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (val) {
                              final p = int.tryParse(val);
                              if (p != null && p > 0) {
                                setState(() => _quantity = p);
                              }
                            },
                          ),
                        ),
                        IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              _quantity++;
                              _quantityCtrl.text = '$_quantity';
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
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
                              labelText: trSi(isFr, 'Prix unitaire', 'Unit price'),
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
                            decoration: InputDecoration(
                              labelText: trSi(isFr, 'Devise', 'Currency'),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
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
                      decoration: InputDecoration(
                        labelText: trSi(isFr, 'Circonstances de l\'achat (texte libre)', 'Purchase notes (optional)'),
                        hintText: trSi(isFr, 'ex: Acheté en vacances au Chili avec Caro...', 'e.g. Bought on vacation in Chile with Caro...'),
                        prefixIcon: const Icon(Icons.flight_takeoff_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rackCtrl,
                            decoration: InputDecoration(
                              labelText: trSi(isFr, 'Casier / Étagère', 'Rack / Shelf'),
                              prefixIcon: const Icon(Icons.grid_view),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _shelfCtrl,
                            decoration: InputDecoration(
                              labelText: tr('Niveau / Rangée', 'Shelf / row'),
                              prefixIcon: const Icon(Icons.table_rows),
                              border: const OutlineInputBorder(),
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
                    Text(tr('Notes & Commentaires Personnels', 'Personal notes'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: tr('Impressions, potentiel de garde, circonstances particulières...', 'Impressions, ageing potential, special occasions...'),
                        border: const OutlineInputBorder(),
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
                label: Text(
                  tr('Ajouter à ma cave', 'Add to my cellar'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    country: _countryCtrl.text.trim(),
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
                label: Text(
                  tr('Dégusté hors cave (Chez des proches, resto...)', 'Tasted outside the cellar (friends, restaurant...)'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                label: Text(
                  tr('Annuler et fermer sans ajouter', 'Cancel and close without adding'),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
  }

  void _showAllBottleSizesPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                tr('Choisir un format de bouteille', 'Choose a bottle size'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                // +1 : la dernière entrée est la contenance libre.
                itemCount: BottleSize.standardSizes.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == BottleSize.standardSizes.length) {
                    final l10n = AppLocalizations.of(ctx)!;
                    return ListTile(
                      leading: const Icon(Icons.straighten, color: Color(0xFF8B1E3F)),
                      title: Text(
                        l10n.bottleSizeCustom,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      onTap: () async {
                        final code = await showCustomBottleSizeDialog(
                          ctx,
                          currentCode: _bottleSize,
                        );
                        if (code == null) return;
                        setState(() => _bottleSize = code);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  }
                  final s = BottleSize.standardSizes[i];
                  final isSelected = _bottleSize == s.code;
                  return ListTile(
                    leading: Icon(
                      Icons.wine_bar,
                      color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey,
                    ),
                    title: Text(s.label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF8B1E3F)) : null,
                    onTap: () {
                      setState(() => _bottleSize = s.code);
                      _checkDuplicateInCellar();
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
