import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/widgets/bottle_image_view.dart';
import '../domain/bottle.dart';
import '../domain/wine.dart';
import '../domain/wine_image_service.dart';
import '../domain/wine_service_advisor.dart';
import 'bottle_provenance_picker.dart';

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
  String? _imageUrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final isSpirit = widget.wine.isSpirit;
    _tabController = TabController(length: isSpirit ? 3 : 4, vsync: this);

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
    if (lower.contains('whisky') || lower.contains('whiskey') || lower.contains('bourbon') || lower.contains('scotch')) return 'whisky';
    if (lower.contains('rhum') || lower.contains('rum')) return 'rhum';
    if (lower.contains('gin')) return 'gin';
    if (lower.contains('vodka')) return 'vodka';
    if (lower.contains('tequila') || lower.contains('mezcal')) return 'tequila';
    if (lower.contains('cognac') || lower.contains('armagnac') || lower.contains('brandy') || lower.contains('calvados')) return 'cognac';
    if (lower.contains('spirit') || lower.contains('liqueur') || lower.contains('spiritueux') || lower.contains('digestif')) return 'spirit';
    if (lower.contains('blanc') || lower.contains('white')) return 'white';
    if (lower.contains('ros')) return 'rosé';
    if (lower.contains('efferv') || lower.contains('spark') || lower.contains('champ')) return 'sparkling';
    if (lower.contains('liquor') || lower.contains('moell') || lower.contains('dessert') || lower.contains('sauterne')) return 'dessert';
    if (lower.contains('fortif') || lower.contains('port') || lower.contains('vdn') || lower.contains('banyuls')) return 'fortified';
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
        },
      );

      // 4. Invalidate caches
      notifyCellarChanged(ref, initialBottle.cellarId);

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Toutes les modifications et apogées ont été enregistrées avec succès !'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
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
                      const Text(
                        'Modifier la Bouteille & le Vin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Tous les champs personnalisés sont protégés de l\'IA',
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
              const Tab(icon: Icon(Icons.wine_bar, size: 18), text: '1. Identité'),
              if (!widget.wine.isSpirit)
                const Tab(icon: Icon(Icons.auto_awesome, size: 18), text: '2. Apogée & Garde'),
              Tab(icon: const Icon(Icons.menu_book, size: 18), text: widget.wine.isSpirit ? '2. Profil Sommelier (IA)' : '3. Profil Sommelier (IA)'),
              Tab(icon: const Icon(Icons.inventory_2, size: 18), text: widget.wine.isSpirit ? '3. Mon Exemplaire & Notes' : '4. Mon Exemplaire & Notes'),
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
                  if (!widget.wine.isSpirit)
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
                    child: const Text('Annuler'),
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
                      _isSaving ? 'Enregistrement...' : 'Enregistrer les modifications',
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
                    const Text('Visuel / Étiquette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 14),
                          label: const Text('Photo', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 14),
                          label: const Text('Galerie', style: TextStyle(fontSize: 11)),
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
                          label: const Text('Officielle', style: TextStyle(fontSize: 11, color: Color(0xFFD4AF37))),
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
          decoration: const InputDecoration(
            labelText: 'Nom du vin *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wine_bar),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est obligatoire' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _producerCtrl,
          decoration: const InputDecoration(
            labelText: 'Domaine / Producteur / Château',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
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
                    decoration: const InputDecoration(
                      labelText: 'Millésime (Année)',
                      hintText: 'ex: 2020',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.history),
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
                            _vintageCtrl.text.isEmpty ? 'Non millésimé (NM) ✓' : 'Non millésimé (NM)',
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
                decoration: const InputDecoration(
                  labelText: 'Couleur / Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'red', child: Text('🍷 Rouge')),
                  DropdownMenuItem(value: 'white', child: Text('🥂 Blanc')),
                  DropdownMenuItem(value: 'rosé', child: Text('🌸 Rosé')),
                  DropdownMenuItem(value: 'sparkling', child: Text('🍾 Effervescent')),
                  DropdownMenuItem(value: 'dessert', child: Text('🍯 Liquoreux')),
                  DropdownMenuItem(value: 'fortified', child: Text('🍷 Fortifié / VDN')),
                  DropdownMenuItem(value: 'orange', child: Text('🍊 Vin Orange')),
                  DropdownMenuItem(value: 'spirit', child: Text('🥃 Spiritueux')),
                  DropdownMenuItem(value: 'whisky', child: Text('🥃 Whisky')),
                  DropdownMenuItem(value: 'rhum', child: Text('🏴‍☠️ Rhum')),
                  DropdownMenuItem(value: 'gin', child: Text('🍸 Gin')),
                  DropdownMenuItem(value: 'vodka', child: Text('🧊 Vodka')),
                  DropdownMenuItem(value: 'tequila', child: Text('🌵 Tequila / Mezcal')),
                  DropdownMenuItem(value: 'cognac', child: Text('🍷 Cognac / Armagnac')),
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
                decoration: const InputDecoration(
                  labelText: 'Pays',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.public),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _regionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Région',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
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
                decoration: const InputDecoration(
                  labelText: 'Sous-région',
                  hintText: 'ex: Côte de Nuits, Médoc...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _appellationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Appellation / AOC / AOP',
                  hintText: 'ex: Vosne-Romanée',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Classification',
                  hintText: 'Grand Cru, 1er Cru, DOCG...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cuveeParcelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cuvée / Lieu-dit / Parcelle',
                  hintText: 'ex: Les Amoureuses',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _alcoholPctCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Degré d\'alcool (% vol.)',
            hintText: 'ex: 13.5',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.percent),
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
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFFD4AF37), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Modifiez librement les années d\'apogée et de garde selon les conditions de votre cave ou vos préférences. Vos valeurs personnalisées seront protégées et prioritaires sur les recherches automatiques de l\'IA.',
                  style: TextStyle(fontSize: 13, height: 1.4),
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
                decoration: const InputDecoration(
                  labelText: 'Début d\'apogée (Année) *',
                  hintText: 'ex: 2028',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                  helperText: 'Moment où le vin s\'ouvre pleinement',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _peakEndCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fin d\'apogée (Année) *',
                  hintText: 'ex: 2035',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alarm, color: Colors.orange),
                  helperText: 'Fin de la phase optimale',
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
                decoration: const InputDecoration(
                  labelText: 'Début dégustation (Année)',
                  hintText: 'ex: 2025',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  helperText: 'Quand le vin devient buvable',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _drinkEndCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fin de garde / Limite (Année)',
                  hintText: 'ex: 2040',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timelapse),
                  helperText: 'Déclin aromatique après cette date',
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
          decoration: const InputDecoration(
            labelText: 'Encépagement / Cépages',
            hintText: 'ex: Pinot Noir (100%) ou Cabernet Sauvignon (60%), Merlot (40%)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.grass),
            helperText: 'Séparez les cépages par des virgules avec les pourcentages éventuels',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _foodPairingsCtrl,
          decoration: const InputDecoration(
            labelText: 'Accords Mets & Vins conseillés',
            hintText: 'ex: Côte de bœuf grillée, Magret de canard, Comté affiné',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.restaurant),
            helperText: 'Séparez chaque accord par une virgule',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tastingNotesCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Profil Sommelier & Notes de dégustation œnologique',
            hintText: 'Arômes au nez (fruits noirs, épices...), attaque en bouche, structure des tanins, longueur en finale...',
            border: OutlineInputBorder(),
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantité en stock *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 0 ? 'Quantité invalide' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _purchasePriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Prix d\'achat unitaire',
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
                decoration: const InputDecoration(
                  labelText: 'Devise',
                  border: OutlineInputBorder(),
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
            labelText: 'Valeur marchande estimée unitaire',
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
                decoration: const InputDecoration(
                  labelText: 'Casier / Rang',
                  hintText: 'ex: A, Nord...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grid_on),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _shelfCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tablette / Niveau',
                  hintText: 'ex: 2, Haut...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _positionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'ex: 4, Gauche...',
                  border: OutlineInputBorder(),
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
          child: const Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ces notes sont strictement privées, protégées et ne seront jamais altérées par l\'IA.',
                  style: TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _userNotesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Mes Notes & Commentaires Personnels',
            hintText: 'Vos impressions personnelles, circonstances d\'achat, souvenirs...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit_note),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
