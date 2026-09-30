import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/widgets/bottle_image_view.dart';
import '../domain/bottle.dart';
import '../domain/bottle_size.dart';
import '../domain/wine.dart';
import '../domain/wine_image_service.dart';
import '../domain/wine_service_advisor.dart';
import 'bottle_provenance_picker.dart';
import 'custom_bottle_size_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/langue.dart';

class BottleEditSheet extends ConsumerStatefulWidget {
  final Bottle bottle;
  final Wine wine;
  final VoidCallback onSaved;

  const BottleEditSheet({
    super.key,
    required this.bottle,
    required this.wine,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required Bottle bottle,
    required Wine wine,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottleEditSheet(
        bottle: bottle,
        wine: wine,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<BottleEditSheet> createState() => _BottleEditSheetState();
}

class _BottleEditSheetState extends ConsumerState<BottleEditSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Wine Identity Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _producerCtrl;
  late TextEditingController _vintageCtrl;
  late String _wineType;
  late TextEditingController _countryCtrl;
  late TextEditingController _regionCtrl;
  late TextEditingController _subRegionCtrl;
  late TextEditingController _appellationCtrl;
  late TextEditingController _classificationCtrl;
  late TextEditingController _cuveeParcelCtrl;
  late TextEditingController _alcoholPctCtrl;

  // Drinking Window / Apogée Controllers
  late TextEditingController _drinkStartCtrl;
  late TextEditingController _peakStartCtrl;
  late TextEditingController _peakEndCtrl;
  late TextEditingController _drinkEndCtrl;

  // Sommelier & Grapes Controllers
  late TextEditingController _grapesCtrl;
  late TextEditingController _tastingNotesCtrl;
  late TextEditingController _foodPairingsCtrl;

  // Bottle Inventory & Physical Location Controllers
  late TextEditingController _quantityCtrl;
  late TextEditingController _purchasePriceCtrl;
  late String _currency;
  late TextEditingController _estimatedValueCtrl;
  late TextEditingController _purchaseLocationCtrl;
  late String _sourceType;
  String? _sourceDetails;
  late TextEditingController _rackCtrl;
  late TextEditingController _shelfCtrl;
  late TextEditingController _positionCtrl;
  late TextEditingController _userNotesCtrl;
  late int _fillLevel;
  late String _bottleSize;
  String? _imageUrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final tracksFillLevel = widget.wine.tracksFillLevel;
    _tabController = TabController(length: tracksFillLevel ? 3 : 4, vsync: this);
    _fillLevel = widget.bottle.fillLevel;
    _bottleSize = widget.bottle.bottleSize;

    final w = widget.wine;
    final b = widget.bottle;

    _imageUrl = w.imageUrl ?? b.photoUrl;
    if (_imageUrl == null || !WineImageService.isValidImagePath(_imageUrl)) {
      _imageUrl = WineImageService.resolveWineImageUrl(w);
    }

    // Wine Identity
    _nameCtrl = TextEditingController(text: w.name);
    _producerCtrl = TextEditingController(text: w.producer ?? '');
    _vintageCtrl = TextEditingController(text: w.vintage != null ? '${w.vintage}' : '');
    _wineType = _normalizeWineType(w.type);
    _countryCtrl = TextEditingController(text: w.country);
    _regionCtrl = TextEditingController(text: w.region);
    _subRegionCtrl = TextEditingController(text: w.subRegion ?? '');
    _appellationCtrl = TextEditingController(text: w.appellation ?? '');
    _classificationCtrl = TextEditingController(text: w.classification ?? '');
    _cuveeParcelCtrl = TextEditingController(text: w.cuveeParcel ?? '');
    _alcoholPctCtrl = TextEditingController(text: w.alcoholPct != null ? '${w.alcoholPct}' : '');

    // Apogée
    _drinkStartCtrl = TextEditingController(text: w.drinkStart != null ? '${w.drinkStart}' : '');
    _peakStartCtrl = TextEditingController(text: w.peakStart != null ? '${w.peakStart}' : '');
    _peakEndCtrl = TextEditingController(text: w.peakEnd != null ? '${w.peakEnd}' : '');
    _drinkEndCtrl = TextEditingController(text: w.drinkEnd != null ? '${w.drinkEnd}' : '');

    // Sommelier
    _grapesCtrl = TextEditingController(
      text: w.grapes.map((g) => g.pct != null ? '${g.name} (${g.pct!.toStringAsFixed(0)}%)' : g.name).join(', '),
    );
    _tastingNotesCtrl = TextEditingController(text: w.tastingNotes ?? '');
    _foodPairingsCtrl = TextEditingController(text: w.foodPairings.join(', '));

    // Bottle details
    _quantityCtrl = TextEditingController(text: '${b.quantity}');
    _purchasePriceCtrl = TextEditingController(text: b.purchasePrice != null ? b.purchasePrice!.toStringAsFixed(2) : '');
    _currency = b.currency.isNotEmpty ? b.currency : 'EUR';
    _estimatedValueCtrl = TextEditingController(
      text: w.estimatedMarketValue != null ? w.estimatedMarketValue!.toStringAsFixed(2) : '',
    );
    _purchaseLocationCtrl = TextEditingController(text: b.purchaseLocation ?? '');
    _sourceType = b.sourceType ?? (b.purchaseLocation != null && b.purchaseLocation!.isNotEmpty ? 'merchant' : 'estate');
    _sourceDetails = b.sourceDetails ?? b.purchaseLocation;
    _rackCtrl = TextEditingController(text: b.rack ?? '');
    _shelfCtrl = TextEditingController(text: b.shelf ?? '');
    _positionCtrl = TextEditingController(text: b.position ?? '');
    final rawNotes = b.notes;
    final isPolluted = rawNotes != null &&
        (rawNotes.trim().toLowerCase() == (w.tastingNotes ?? '').trim().toLowerCase() ||
         rawNotes.trim().toLowerCase() == (w.summary ?? '').trim().toLowerCase() ||
         rawNotes.contains('Sortie enregistrée par commande vocale'));
    _userNotesCtrl = TextEditingController(text: isPolluted ? '' : (rawNotes ?? ''));
  }

  String _normalizeWineType(String? raw) {
    if (raw == null) return 'red';
    final lower = raw.toLowerCase();
    if (lower.contains('italicus') ||
        lower.contains('rosolio') ||
        lower.contains('bénédictine') ||
        lower.contains('benedictine') ||
        lower.contains('chartreuse') ||
        lower.contains('cointreau') ||
        lower.contains('grand marnier') ||
        lower.contains('amaretto') ||
        lower.contains('disaronno') ||
        lower.contains('kahlúa') ||
        lower.contains('kahlua') ||
        lower.contains('limoncello') ||
        lower.contains('chambord') ||
        lower.contains('pimm') ||
        lower.contains('fleur de lavande') ||
        lower.contains('liqueur')) {
      return 'liqueur';
    }
    if (lower.contains('whisky') || lower.contains('whiskey') || lower.contains('bourbon') || lower.contains('scotch')) return 'whisky';
    if (lower.contains('rhum') || lower.contains('rum')) return 'rhum';
    if (RegExp(r'\bgin\b', caseSensitive: false).hasMatch(lower)) return 'gin';
    if (lower.contains('vodka')) return 'vodka';
    if (lower.contains('tequila') || lower.contains('mezcal')) return 'tequila';
    if (lower.contains('cognac') || lower.contains('armagnac') || lower.contains('brandy') || lower.contains('calvados')) return 'cognac';
    if (lower.contains('grappa') || lower.contains('vinaccia')) return 'grappa';
    if (lower.contains('eau de vie') || lower.contains('eau-de-vie') || lower.contains('marc')) return 'eau-de-vie';
    if (lower.contains('pisco') ||
        lower.contains('aguardente') ||
        lower.contains('pastis') ||
        lower.contains('ricard') ||
        lower.contains('absinthe') ||
        lower.contains('spirit') ||
        lower.contains('spiritueux') ||
        lower.contains('digestif')) {
      return 'spirit';
    }
    if (lower.contains('porto') ||
        lower.contains('port wine') ||
        lower.contains('sherry') ||
        lower.contains('xérès') ||
        lower.contains('xeres') ||
        lower.contains('banyuls') ||
        lower.contains('maury') ||
        lower.contains('rivesaltes') ||
        lower.contains('madère') ||
        lower.contains('madeira') ||
        lower.contains('marsala') ||
        lower.contains('vermouth') ||
        lower.contains('fortif') ||
        lower.contains('vdn') ||
        lower.contains('muté') ||
        lower.contains('mute')) {
      return 'fortified';
    }
    if (lower.contains('blanc') || lower.contains('white')) return 'white';
    if (lower.contains('ros')) return 'rosé';
    if (lower.contains('efferv') || lower.contains('spark') || lower.contains('champ')) return 'sparkling';
    if (lower.contains('liquor') || lower.contains('moell') || lower.contains('dessert') || lower.contains('sauterne')) return 'dessert';
    if (lower.contains('orange')) return 'orange';
    return 'red';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _producerCtrl.dispose();
    _vintageCtrl.dispose();
    _countryCtrl.dispose();
    _regionCtrl.dispose();
    _subRegionCtrl.dispose();
    _appellationCtrl.dispose();
    _classificationCtrl.dispose();
    _cuveeParcelCtrl.dispose();
    _alcoholPctCtrl.dispose();
    _drinkStartCtrl.dispose();
    _peakStartCtrl.dispose();
    _peakEndCtrl.dispose();
    _drinkEndCtrl.dispose();
    _grapesCtrl.dispose();
    _tastingNotesCtrl.dispose();
    _foodPairingsCtrl.dispose();
    _quantityCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _estimatedValueCtrl.dispose();
    _purchaseLocationCtrl.dispose();
    _rackCtrl.dispose();
    _shelfCtrl.dispose();
    _positionCtrl.dispose();
    _userNotesCtrl.dispose();
    super.dispose();
  }

  List<Grape> _parseGrapes(String input) {
    if (input.trim().isEmpty) return const [];
    final items = input.split(RegExp(r'[,;]'));
    final result = <Grape>[];
    for (var item in items) {
      item = item.trim();
      if (item.isEmpty) continue;
      // Check for percentage pattern: "Merlot (60%)" or "Merlot 60%"
      final match = RegExp(r'^(.+?)(?:\s*\(?(\d+(?:[.,]\d+)?)\s*%\)?)?$').firstMatch(item);
      if (match != null) {
        final name = match.group(1)?.trim() ?? item;
        final pctStr = match.group(2)?.replaceAll(',', '.');
        final pct = pctStr != null ? double.tryParse(pctStr) : null;
        result.add(Grape(name: name, pct: pct));
      } else {
        result.add(Grape(name: item));
      }
    }
    return result;
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(cellarRepositoryProvider);
      final initialWine = widget.wine;
      final initialBottle = widget.bottle;

      // 1. Determine newly overridden / modified fields to protect them from future automated overwrites
      final updatedOverrides = Set<String>.from(initialWine.userOverrides);

      final name = _nameCtrl.text.trim();
      final producer = _producerCtrl.text.trim().isEmpty ? null : _producerCtrl.text.trim();
      final vintage = int.tryParse(_vintageCtrl.text.trim());
      final country = _countryCtrl.text.trim().isEmpty ? 'France' : _countryCtrl.text.trim();
      final region = _regionCtrl.text.trim().isEmpty ? 'Bordeaux' : _regionCtrl.text.trim();
      final subRegion = _subRegionCtrl.text.trim().isEmpty ? null : _subRegionCtrl.text.trim();
      final appellation = _appellationCtrl.text.trim().isEmpty ? null : _appellationCtrl.text.trim();
      final classification = _classificationCtrl.text.trim().isEmpty ? null : _classificationCtrl.text.trim();
      final cuveeParcel = _cuveeParcelCtrl.text.trim().isEmpty ? null : _cuveeParcelCtrl.text.trim();
      final alcoholPct = double.tryParse(_alcoholPctCtrl.text.trim().replaceAll(',', '.'));
      int? drinkStart = int.tryParse(_drinkStartCtrl.text.trim());
      int? peakStart = int.tryParse(_peakStartCtrl.text.trim());
      int? peakEnd = int.tryParse(_peakEndCtrl.text.trim());
      int? drinkEnd = int.tryParse(_drinkEndCtrl.text.trim());

      // If vintage was modified and existing drink dates are inconsistent with the new vintage:
      if (vintage != null) {
        if (drinkStart != null && drinkStart < vintage) drinkStart = null;
        if (drinkEnd != null && (drinkEnd < vintage || (drinkStart != null && drinkEnd < drinkStart))) drinkEnd = null;
        if (peakStart != null && peakStart < vintage) peakStart = null;
        if (peakEnd != null && peakEnd < vintage) peakEnd = null;

        if (drinkStart == null || drinkEnd == null) {
          final computed = WineOenologyAdvisor.computeDrinkingWindow(
            wineType: _wineType,
            vintage: vintage,
            region: region,
            appellation: appellation,
            classification: classification,
            wineName: name,
          );
          drinkStart ??= computed.drinkStart;
          peakStart ??= computed.peakStart;
          peakEnd ??= computed.peakEnd;
          drinkEnd ??= computed.drinkEnd;
        }
      }

      final estimatedVal = double.tryParse(_estimatedValueCtrl.text.trim().replaceAll(',', '.'));
      final tastingNotes = _tastingNotesCtrl.text.trim().isEmpty ? null : _tastingNotesCtrl.text.trim();
      final foodPairings = _foodPairingsCtrl.text.trim().isEmpty
          ? const <String>[]
          : _foodPairingsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final grapes = _parseGrapes(_grapesCtrl.text);

      // Register overrides for fields explicitly edited or filled
      if (name != initialWine.name) updatedOverrides.add('name');
      if (producer != initialWine.producer) updatedOverrides.add('producer');
      if (vintage != initialWine.vintage) updatedOverrides.add('vintage');
      if (_wineType != initialWine.type) updatedOverrides.add('wine_type');
      if (country != initialWine.country) updatedOverrides.add('country');
      if (region != initialWine.region) updatedOverrides.add('region');
      if (subRegion != initialWine.subRegion) updatedOverrides.add('sub_region');
      if (appellation != initialWine.appellation) updatedOverrides.add('appellation');
      if (classification != initialWine.classification) updatedOverrides.add('classification');
      if (cuveeParcel != initialWine.cuveeParcel) updatedOverrides.add('cuvee_parcel');
      if (alcoholPct != initialWine.alcoholPct) updatedOverrides.add('alcohol_pct');

      // Crucial: Apogee & Garde overrides protection
      if (drinkStart != initialWine.drinkStart) updatedOverrides.add('ideal_drinking_start');
      if (peakStart != initialWine.peakStart) updatedOverrides.add('peak_drinking_start');
      if (peakEnd != initialWine.peakEnd) updatedOverrides.add('peak_drinking_end');
      if (drinkEnd != initialWine.drinkEnd) updatedOverrides.add('ideal_drinking_end');

      if (estimatedVal != initialWine.estimatedMarketValue) updatedOverrides.add('estimated_market_value');
      if (tastingNotes != initialWine.tastingNotes) updatedOverrides.add('tasting_notes');
      if (_grapesCtrl.text.trim().isNotEmpty) updatedOverrides.add('grapes');
      if (foodPairings.isNotEmpty) updatedOverrides.add('ai_food_pairings');

      // 2. Update Wine in database
      await repo.updateWine(
        initialWine.id,
        rawUpdates: {
          'name': name,
          'producer': producer,
          'vintage': vintage,
          'wine_type': _wineType,
          'country': country,
          'region': region,
          'sub_region': subRegion,
          'appellation': appellation,
          'classification': classification,
          'cuvee_parcel': cuveeParcel,
          'alcohol_pct': alcoholPct,
          'ideal_drinking_start': drinkStart,
          'ideal_drinking_end': drinkEnd,
          'peak_drinking_start': peakStart,
          'peak_drinking_end': peakEnd,
          'estimated_market_value': estimatedVal,
          'tasting_notes': tastingNotes,
          'ai_food_pairings': foodPairings,
          'grapes': grapes.map((g) => g.toJson()).toList(),
          'user_overrides': updatedOverrides.toList(),
          if (_imageUrl != null) 'image_url': _imageUrl,
          'external_links': {
            'user_overrides': updatedOverrides.toList(),
            if (_imageUrl != null) 'image_url': _imageUrl,
          },
        },
      );

      // 3. Update Bottle in database
      final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 1;
      final purchasePrice = double.tryParse(_purchasePriceCtrl.text.trim().replaceAll(',', '.'));
      final purchaseLocation = _purchaseLocationCtrl.text.trim().isEmpty ? null : _purchaseLocationCtrl.text.trim();
      final rack = _rackCtrl.text.trim().isEmpty ? null : _rackCtrl.text.trim();
      final shelf = _shelfCtrl.text.trim().isEmpty ? null : _shelfCtrl.text.trim();
      final position = _positionCtrl.text.trim().isEmpty ? null : _positionCtrl.text.trim();
      final userNotes = _userNotesCtrl.text.trim().isEmpty ? null : _userNotesCtrl.text.trim();

      await repo.updateBottle(
        initialBottle.id,
        fillLevel: _fillLevel,
        rawUpdates: {
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'currency': _currency,
          'source_type': _sourceType,
          'source_details': _sourceDetails ?? purchaseLocation,
          'purchase_location': _sourceDetails ?? purchaseLocation,
          'rack': rack,
          'shelf': shelf,
          'position': position,
          'notes': userNotes,
          'fill_level': _fillLevel,
          'bottle_size': _bottleSize,
        },
      );

      // 4. Invalidate caches
      notifyCellarChanged(ref, initialBottle.cellarId);

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('✅ Toutes les modifications et apogées ont été enregistrées avec succès !', '✅ All changes and drinking windows saved!')),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Erreur lors de l\'enregistrement : {e}', 'Couldn\'t save: {e}', {'e': e})),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Top Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Modifier la Bouteille & le Vin', 'Edit the bottle & the wine'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        tr('Tous les champs personnalisés sont protégés de l\'IA', 'Every field you edit is protected from the AI'),
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs Navigation
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF8B1E3F),
            indicatorColor: const Color(0xFF8B1E3F),
            tabs: [
              Tab(icon: const Icon(Icons.wine_bar, size: 18), text: tr('1. Identité', '1. Identity')),
              if (!widget.wine.tracksFillLevel)
                Tab(icon: const Icon(Icons.auto_awesome, size: 18), text: tr('2. Apogée & Garde', '2. Peak & ageing')),
              Tab(icon: const Icon(Icons.menu_book, size: 18), text: widget.wine.tracksFillLevel ? tr('2. Profil Sommelier (IA)', '2. Sommelier profile (AI)') : tr('3. Profil Sommelier (IA)', '3. Sommelier profile (AI)')),
              Tab(icon: const Icon(Icons.inventory_2, size: 18), text: widget.wine.tracksFillLevel ? tr('3. Mon Exemplaire & Notes', '3. My bottle & notes') : tr('4. Mon Exemplaire & Notes', '4. My bottle & notes')),
            ],
          ),

          // Tabs Content Form
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIdentityTab(theme),
                  if (!widget.wine.tracksFillLevel)
                    _buildApogeeTab(theme),
                  _buildSommelierTab(theme),
                  _buildInventoryTab(theme),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(tr('Annuler', 'Cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveAll,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18, color: Colors.white),
                    label: Text(
                      _isSaving ? tr('Enregistrement...', 'Saving...') : tr('Enregistrer les modifications', 'Save changes'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() => _imageUrl = picked.path);
      }
    } catch (e) {
      debugPrint('Error picking image in edit sheet: $e');
    }
  }

  // ================= 1. IDENTITY TAB =================
  Widget _buildIdentityTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photo & Étiquette Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2426) : const Color(0xFFF7F4F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              BottleImageView(
                imagePath: _imageUrl,
                wineType: _wineType,
                width: 60,
                height: 60,
                borderRadius: 8,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Visuel / Étiquette', 'Picture / label'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 14),
                          label: Text(tr('Photo', 'Photo'), style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 14),
                          label: Text(tr('Galerie', 'Gallery'), style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            PaintingBinding.instance.imageCache.clear();
                            PaintingBinding.instance.imageCache.clearLiveImages();
                            setState(() {
                              _imageUrl = WineImageService.resolveWineImageUrl(widget.wine, forceDomainOrArchetype: true);
                            });
                          },
                          icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD4AF37)),
                          label: Text(tr('Officielle', 'Official'), style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37))),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        TextFormField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: tr('Nom du vin *', 'Wine name *'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.wine_bar),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? tr('Le nom est obligatoire', 'The name is required') : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _producerCtrl,
          decoration: InputDecoration(
            labelText: tr('Domaine / Producteur / Château', 'Estate / producer / château'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _vintageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr('Millésime (Année)', 'Vintage (year)'),
                      hintText: 'ex: 2020',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.history),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _vintageCtrl.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _vintageCtrl.text.isEmpty
                            ? const Color(0xFF8B1E3F).withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.1),
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
                            size: 14,
                            color: _vintageCtrl.text.isEmpty
                                ? const Color(0xFF8B1E3F)
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _vintageCtrl.text.isEmpty ? tr('Non millésimé (NM) ✓', 'Non-vintage (NV) ✓') : tr('Non millésimé (NM)', 'Non-vintage (NV)'),
                            style: TextStyle(
                              fontSize: 11,
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _wineType,
                decoration: InputDecoration(
                  labelText: tr('Couleur / Type', 'Colour / type'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'red', child: Text(tr('🍷 Rouge', '🍷 Red'))),
                  DropdownMenuItem(value: 'white', child: Text(tr('🥂 Blanc', '🥂 White'))),
                  DropdownMenuItem(value: 'rosé', child: Text(tr('🌸 Rosé', '🌸 Rosé'))),
                  DropdownMenuItem(value: 'sparkling', child: Text(tr('🍾 Effervescent', '🍾 Sparkling'))),
                  DropdownMenuItem(value: 'dessert', child: Text(tr('🍯 Liquoreux', '🍯 Sweet'))),
                  DropdownMenuItem(value: 'fortified', child: Text(tr('🍷 Fortifié / VDN', '🍷 Fortified'))),
                  DropdownMenuItem(value: 'orange', child: Text(tr('🍊 Vin Orange', '🍊 Orange wine'))),
                  DropdownMenuItem(value: 'spirit', child: Text(tr('🥃 Spiritueux', '🥃 Spirit'))),
                  const DropdownMenuItem(value: 'grappa', child: Text('🍇 Grappa')),
                  DropdownMenuItem(value: 'eau-de-vie', child: Text(tr('🍐 Eau-de-vie / Marc', '🍐 Brandy / marc'))),
                  const DropdownMenuItem(value: 'liqueur', child: Text('🍸 Liqueur')),
                  const DropdownMenuItem(value: 'whisky', child: Text('🥃 Whisky')),
                  DropdownMenuItem(value: 'rhum', child: Text(tr('🏴‍☠️ Rhum', '🏴‍☠️ Rum'))),
                  const DropdownMenuItem(value: 'gin', child: Text('🍸 Gin')),
                  const DropdownMenuItem(value: 'vodka', child: Text('🧊 Vodka')),
                  const DropdownMenuItem(value: 'tequila', child: Text('🌵 Tequila / Mezcal')),
                  const DropdownMenuItem(value: 'cognac', child: Text('🍷 Cognac / Armagnac')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _wineType = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _countryCtrl,
                decoration: InputDecoration(
                  labelText: tr('Pays', 'Country'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.public),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _regionCtrl,
                decoration: InputDecoration(
                  labelText: tr('Région', 'Region'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.map),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _subRegionCtrl,
                decoration: InputDecoration(
                  labelText: tr('Sous-région', 'Sub-region'),
                  hintText: tr('ex: Côte de Nuits, Médoc...', 'e.g. Côte de Nuits, Médoc...'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _appellationCtrl,
                decoration: InputDecoration(
                  labelText: 'Appellation / AOC / AOP',
                  hintText: tr('ex: Vosne-Romanée', 'e.g. Vosne-Romanée'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _classificationCtrl,
                decoration: InputDecoration(
                  labelText: 'Classification',
                  hintText: tr('Grand Cru, 1er Cru, DOCG...', 'Grand Cru, Premier Cru, DOCG...'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cuveeParcelCtrl,
                decoration: InputDecoration(
                  labelText: tr('Cuvée / Lieu-dit / Parcelle', 'Cuvée / lieu-dit / plot'),
                  hintText: tr('ex: Les Amoureuses', 'e.g. Les Amoureuses'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _alcoholPctCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: tr('Degré d\'alcool (% vol.)', 'Alcohol (% vol.)'),
            hintText: 'ex: 13.5',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.percent),
          ),
        ),
      ],
    );
  }

  // ================= 2. APOGÉE TAB =================
  Widget _buildApogeeTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFD4AF37), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('Modifiez librement les années d\'apogée et de garde selon les conditions de votre cave ou vos préférences. Vos valeurs personnalisées seront protégées et prioritaires sur les recherches automatiques de l\'IA.', 'Adjust the peak and ageing years to suit your cellar conditions or your taste. Your own values are protected and take priority over the AI\'s automatic research.'),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Apogee Start & End
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _peakStartCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('Début d\'apogée (Année) *', 'Peak from (year) *'),
                  hintText: 'ex: 2028',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                  helperText: tr('Moment où le vin s\'ouvre pleinement', 'When the wine fully opens up'),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _peakEndCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('Fin d\'apogée (Année) *', 'Peak until (year) *'),
                  hintText: 'ex: 2035',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.alarm, color: Colors.orange),
                  helperText: tr('Fin de la phase optimale', 'End of its best phase'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Drink Window Start & End
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _drinkStartCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('Début dégustation (Année)', 'Drinkable from (year)'),
                  hintText: 'ex: 2025',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  helperText: tr('Quand le vin devient buvable', 'When the wine becomes drinkable'),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _drinkEndCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('Fin de garde / Limite (Année)', 'Drink by (year)'),
                  hintText: 'ex: 2040',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.timelapse),
                  helperText: tr('Déclin aromatique après cette date', 'Aromas decline after this date'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= 3. SOMMELIER TAB =================
  Widget _buildSommelierTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _grapesCtrl,
          decoration: InputDecoration(
            labelText: tr('Encépagement / Cépages', 'Blend / grapes'),
            hintText: tr('ex: Pinot Noir (100%) ou Cabernet Sauvignon (60%), Merlot (40%)', 'e.g. Pinot Noir (100%) or Cabernet Sauvignon (60%), Merlot (40%)'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.grass),
            helperText: tr('Séparez les cépages par des virgules avec les pourcentages éventuels', 'Separate grapes with commas, with percentages if you know them'),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _foodPairingsCtrl,
          decoration: InputDecoration(
            labelText: tr('Accords Mets & Vins conseillés', 'Suggested food pairings'),
            hintText: tr('ex: Côte de bœuf grillée, Magret de canard, Comté affiné', 'e.g. grilled rib of beef, duck breast, aged Comté'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.restaurant),
            helperText: tr('Séparez chaque accord par une virgule', 'Separate each pairing with a comma'),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tastingNotesCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: tr('Profil Sommelier & Notes de dégustation œnologique', 'Sommelier profile & tasting notes'),
            hintText: tr('Arômes au nez (fruits noirs, épices...), attaque en bouche, structure des tanins, longueur en finale...', 'Nose (black fruit, spice...), attack, tannin structure, length of the finish...'),
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // ================= 4. INVENTORY TAB =================
  Widget _buildInventoryTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.wine.tracksFillLevel) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _fillLevel <= 20
                    ? Colors.redAccent
                    : _fillLevel <= 50
                        ? Colors.orangeAccent
                        : const Color(0xFFD4AF37).withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_bar,
                          size: 18,
                          color: _fillLevel <= 20
                              ? Colors.redAccent
                              : _fillLevel <= 50
                                  ? Colors.orangeAccent
                                  : const Color(0xFFD4AF37),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr('Niveau de remplissage', 'Fill level'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _fillLevel <= 20
                            ? Colors.red.withValues(alpha: 0.15)
                            : _fillLevel <= 50
                                ? Colors.orange.withValues(alpha: 0.15)
                                : const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_fillLevel %',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _fillLevel <= 20
                              ? Colors.redAccent
                              : _fillLevel <= 50
                                  ? Colors.orangeAccent
                                  : const Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _fillLevel <= 20
                        ? Colors.redAccent
                        : _fillLevel <= 50
                            ? Colors.orangeAccent
                            : const Color(0xFFD4AF37),
                    thumbColor: _fillLevel <= 20
                        ? Colors.redAccent
                        : _fillLevel <= 50
                            ? Colors.orangeAccent
                            : const Color(0xFFD4AF37),
                  ),
                  child: Slider(
                    value: _fillLevel.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '$_fillLevel%',
                    onChanged: (val) {
                      setState(() {
                        _fillLevel = val.round();
                      });
                    },
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(tr('Vide (0%)', 'Empty (0%)')),
                      selected: _fillLevel == 0,
                      onSelected: (_) => setState(() => _fillLevel = 0),
                    ),
                    ChoiceChip(
                      label: const Text('1/4 (25%)'),
                      selected: _fillLevel == 25,
                      onSelected: (_) => setState(() => _fillLevel = 25),
                    ),
                    ChoiceChip(
                      label: const Text('1/2 (50%)'),
                      selected: _fillLevel == 50,
                      onSelected: (_) => setState(() => _fillLevel = 50),
                    ),
                    ChoiceChip(
                      label: const Text('3/4 (75%)'),
                      selected: _fillLevel == 75,
                      onSelected: (_) => setState(() => _fillLevel = 75),
                    ),
                    ChoiceChip(
                      label: Text(tr('Pleine (100%)', 'Full (100%)')),
                      selected: _fillLevel == 100,
                      onSelected: (_) => setState(() => _fillLevel = 100),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Bottle Size / Format Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Format de la bouteille / Contenance', 'Bottle size'),
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
                      if (selected) setState(() => _bottleSize = sizeCode);
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
                      : tr('Autre format...', 'Other size...')),
                  onPressed: _showAllBottleSizesPicker,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final val = int.tryParse(_quantityCtrl.text) ?? 0;
                      if (val > 0) {
                        setState(() {
                          _quantityCtrl.text = '${val - 1}';
                        });
                      }
                    },
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Stock *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                      ),
                      validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? tr('Invalide', 'Invalid') : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final val = int.tryParse(_quantityCtrl.text) ?? 0;
                      setState(() {
                        _quantityCtrl.text = '${val + 1}';
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _purchasePriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr('Prix d\'achat unitaire', 'Purchase price per bottle'),
                  border: const OutlineInputBorder(),
                  prefixText: '${CurrencyHelper.getSymbol(_currency)} ',
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: tr('Devise', 'Currency'),
                  border: const OutlineInputBorder(),
                ),
                items: ['EUR', 'USD', 'CHF', 'GBP', 'CAD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _currency = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _estimatedValueCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: tr('Valeur marchande estimée unitaire', 'Estimated market value per bottle'),
            hintText: 'ex: 45.00',
            border: const OutlineInputBorder(),
            prefixText: '${CurrencyHelper.getSymbol(_currency)} ',
            prefixIcon: const Icon(Icons.trending_up, color: Colors.green),
          ),
        ),
        const SizedBox(height: 16),
        BottleProvenancePicker(
          initialSourceType: _sourceType,
          initialSourceDetails: _sourceDetails,
          onChanged: (type, details) {
            setState(() {
              _sourceType = type;
              _sourceDetails = details;
              _purchaseLocationCtrl.text = details ?? '';
            });
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _rackCtrl,
                decoration: InputDecoration(
                  labelText: tr('Casier / Rang', 'Rack / row'),
                  hintText: tr('ex: A, Nord...', 'e.g. A, North...'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.grid_on),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _shelfCtrl,
                decoration: InputDecoration(
                  labelText: tr('Tablette / Niveau', 'Shelf / level'),
                  hintText: tr('ex: 2, Haut...', 'e.g. 2, Top...'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _positionCtrl,
                decoration: InputDecoration(
                  labelText: 'Position',
                  hintText: tr('ex: 4, Gauche...', 'e.g. 4, Left...'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Ces notes sont strictement privées, protégées et ne seront jamais altérées par l\'IA.', 'These notes are strictly private, protected, and never changed by the AI.'),
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _userNotesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: tr('Mes Notes & Commentaires Personnels', 'My personal notes'),
            hintText: tr('Vos impressions personnelles, circonstances d\'achat, souvenirs...', 'Your impressions, where you bought it, memories...'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.edit_note),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  void _showAllBottleSizesPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                shrinkWrap: true,
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
