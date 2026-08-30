import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/taste_profile_service.dart';
import '../domain/taste_profile.dart';

class TasteProfileEditSheet extends ConsumerStatefulWidget {
  final TasteProfile profile;
  final ValueChanged<TasteProfile>? onSaved;

  const TasteProfileEditSheet({
    super.key,
    required this.profile,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required TasteProfile profile,
    ValueChanged<TasteProfile>? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TasteProfileEditSheet(profile: profile, onSaved: onSaved),
    );
  }

  @override
  ConsumerState<TasteProfileEditSheet> createState() => _TasteProfileEditSheetState();
}

class _TasteProfileEditSheetState extends ConsumerState<TasteProfileEditSheet> {
  late String _name;
  late List<String> _favoriteTypes;
  late List<String> _favoriteRegions;
  late List<String> _favoriteGrapes;
  late List<String> _dislikedCharacteristics;
  late TextEditingController _notesController;
  late TextEditingController _customInputController;

  double _tanninPref = 0.5;
  double _acidityPref = 0.5;
  double _bodyPref = 0.5;
  bool _hasCustomSliders = false;

  // Suggested canonical items for easy 1-tap toggles
  static const List<String> _suggestedTypes = [
    'Rouge puissant & structuré',
    'Rouge soyeux & fruité',
    'Blanc sec minéral & tendu',
    'Blanc gras & aromatique',
    'Rosé de gastronomie',
    'Champagne & Effervescents',
    'Moelleux / Liquoreux',
    'Vins Nature & Biodynamie',
  ];

  static const List<String> _suggestedRegions = [
    'Bourgogne',
    'Vallée du Rhône',
    'Bordeaux',
    'Bandol & Provence',
    'Val de Loire',
    'Champagne',
    'Alsace',
    'Jura & Savoie',
    'Languedoc-Roussillon',
    'Sud-Ouest',
    'Corse',
    'Toscane (Italie)',
    'Piémont (Italie)',
    'Rioja (Espagne)',
    'Ribera del Duero (Espagne)',
    'Napa Valley (USA)',
    'Mendoza (Argentine)',
  ];

  static const List<String> _suggestedGrapes = [
    'Pinot Noir',
    'Syrah',
    'Chardonnay',
    'Mourvèdre',
    'Cabernet Sauvignon',
    'Merlot',
    'Grenache',
    'Cinsault',
    'Sauvignon Blanc',
    'Chenin',
    'Riesling',
    'Viognier',
    'Gamay',
    'Nebbiolo',
    'Sangiovese',
    'Malbec',
    'Tempranillo',
    'Cabernet Franc',
  ];

  static const List<String> _suggestedAversions = [
    'Tanins trop astringents / râpeux',
    'Boisé ou vanille excessif',
    'Acidité agressive',
    'Alcool trop chaleureux / lourd',
    'Sucre résiduel / Vins trop doux',
    'Notes végétales / poivron vert',
    'Vins industriels standardisés',
  ];

  @override
  void initState() {
    super.initState();
    _name = widget.profile.name;
    _favoriteTypes = List<String>.from(widget.profile.favoriteTypes);
    _favoriteRegions = List<String>.from(widget.profile.favoriteRegions);
    _favoriteGrapes = List<String>.from(widget.profile.favoriteGrapes);
    _dislikedCharacteristics = List<String>.from(widget.profile.dislikedCharacteristics);
    _notesController = TextEditingController(text: widget.profile.notes);
    _customInputController = TextEditingController();

    if (widget.profile.avgTanninPreference != null ||
        widget.profile.avgAcidityPreference != null ||
        widget.profile.avgBodyPreference != null) {
      _hasCustomSliders = true;
      _tanninPref = widget.profile.avgTanninPreference ?? 0.5;
      _acidityPref = widget.profile.avgAcidityPreference ?? 0.5;
      _bodyPref = widget.profile.avgBodyPreference ?? 0.5;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customInputController.dispose();
    super.dispose();
  }

  void _addCustomItem(List<String> targetList, String label) {
    _customInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter un(e) $label'),
        content: TextField(
          controller: _customInputController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nom du $label...',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitCustomItem(targetList),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => _submitCustomItem(targetList),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _submitCustomItem(List<String> targetList) {
    final text = _customInputController.text.trim();
    if (text.isNotEmpty && !targetList.contains(text)) {
      setState(() {
        targetList.add(text);
      });
    }
    Navigator.pop(context);
  }

  void _resetProfile() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser votre profil de goûts ?'),
        content: const Text(
          'Toutes vos préférences (styles, régions, cépages, aversions et réglages) seront remises à zéro.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              setState(() {
                _favoriteTypes.clear();
                _favoriteRegions.clear();
                _favoriteGrapes.clear();
                _dislikedCharacteristics.clear();
                _notesController.clear();
                _hasCustomSliders = false;
                _tanninPref = 0.5;
                _acidityPref = 0.5;
                _bodyPref = 0.5;
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final updated = widget.profile.copyWith(
      name: _name,
      favoriteTypes: _favoriteTypes,
      favoriteRegions: _favoriteRegions,
      favoriteGrapes: _favoriteGrapes,
      dislikedCharacteristics: _dislikedCharacteristics,
      notes: _notesController.text.trim(),
      avgTanninPreference: _hasCustomSliders ? _tanninPref : null,
      avgAcidityPreference: _hasCustomSliders ? _acidityPref : null,
      avgBodyPreference: _hasCustomSliders ? _bodyPref : null,
    );

    final service = ref.read(tasteProfileServiceProvider);
    await service.updateProfile(updated);
    ref.invalidate(tasteProfilesListProvider);

    widget.onSaved?.call(updated);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Profil de goûts mis à jour avec succès !'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1A24) : Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: Color(0xFF8B1E3F), size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'Mon Profil de Goûts',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _resetProfile,
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                          label: const Text('Réinitialiser', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Personnalisez vos préférences œnologiques à tout moment. Chatmelier s\'adapte en temps réel pour vos accords mets-vins et recommandations.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: STYLES & TYPES DE VINS
                    _buildSectionHeader(
                      'Styles & Types de Vins Préférés',
                      icon: Icons.wine_bar,
                      count: _favoriteTypes.length,
                    ),
                    _buildChipGroup(
                      items: _favoriteTypes,
                      suggestions: _suggestedTypes,
                      onAddCustom: () => _addCustomItem(_favoriteTypes, 'style de vin'),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: RÉGIONS & TERROIRS
                    _buildSectionHeader(
                      'Régions & Terroirs Coups de Cœur',
                      icon: Icons.map_outlined,
                      count: _favoriteRegions.length,
                    ),
                    _buildChipGroup(
                      items: _favoriteRegions,
                      suggestions: _suggestedRegions,
                      onAddCustom: () => _addCustomItem(_favoriteRegions, 'région viticole'),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: CÉPAGES FAVORIS
                    _buildSectionHeader(
                      'Cépages Favoris',
                      icon: Icons.grain,
                      count: _favoriteGrapes.length,
                    ),
                    _buildChipGroup(
                      items: _favoriteGrapes,
                      suggestions: _suggestedGrapes,
                      onAddCustom: () => _addCustomItem(_favoriteGrapes, 'cépage'),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 4: AVERSIONS & TRAITS NON APPRÉCIÉS
                    _buildSectionHeader(
                      'Traits / Arômes non appréciés (Aversions)',
                      icon: Icons.thumb_down_alt_outlined,
                      count: _dislikedCharacteristics.length,
                      color: Colors.orange.shade800,
                    ),
                    _buildChipGroup(
                      items: _dislikedCharacteristics,
                      suggestions: _suggestedAversions,
                      chipColor: Colors.orange.shade100,
                      selectedColor: Colors.orange.shade800,
                      onAddCustom: () => _addCustomItem(_dislikedCharacteristics, 'aversion'),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 5: SENSIBILITÉS DU PALAIS (SLIDERS)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.tune, color: Color(0xFFD4AF37), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sensibilités du Palais',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _hasCustomSliders,
                                  activeThumbColor: const Color(0xFF8B1E3F),
                                  onChanged: (val) => setState(() => _hasCustomSliders = val),
                                ),
                              ],
                            ),
                            if (!_hasCustomSliders)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Activez pour calibrer manuellement votre sensibilité aux tanins, à l\'acidité et au corps.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                              )
                            else ...[
                              const SizedBox(height: 16),
                              // Tannins
                              _buildSliderRow(
                                label: 'Structure tannique',
                                value: _tanninPref,
                                leftLabel: 'Souple & Fondu',
                                rightLabel: 'Puissant & Racé',
                                onChanged: (v) => setState(() => _tanninPref = v),
                              ),
                              const SizedBox(height: 12),
                              // Acidity
                              _buildSliderRow(
                                label: 'Acidité / Fraîcheur',
                                value: _acidityPref,
                                leftLabel: 'Rondeur',
                                rightLabel: 'Vif & Tendu',
                                onChanged: (v) => setState(() => _acidityPref = v),
                              ),
                              const SizedBox(height: 12),
                              // Body
                              _buildSliderRow(
                                label: 'Corps & Matière',
                                value: _bodyPref,
                                leftLabel: 'Léger & Digest',
                                rightLabel: 'Charnu & Puissant',
                                onChanged: (v) => setState(() => _bodyPref = v),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 6: NOTES & PRÉCISIONS LIBRES
                    Text(
                      'Notes personnelles & Précisions',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Grand amateur de vieux millésimes, vins minéraux en biodynamie...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Bottom Save Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Enregistrer mon profil de goûts ✨',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {required IconData icon, int count = 0, Color? color}) {
    final c = color ?? const Color(0xFF8B1E3F);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: c),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChipGroup({
    required List<String> items,
    required List<String> suggestions,
    required VoidCallback onAddCustom,
    Color? chipColor,
    Color? selectedColor,
  }) {
    final activeSelectedColor = selectedColor ?? const Color(0xFF8B1E3F);

    // Merge suggestions and existing items
    final Set<String> allChoices = {...suggestions, ...items};

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...allChoices.map((choice) {
          final isSelected = items.contains(choice);
          return FilterChip(
            label: Text(choice),
            selected: isSelected,
            selectedColor: activeSelectedColor.withValues(alpha: 0.18),
            checkmarkColor: activeSelectedColor,
            labelStyle: TextStyle(
              color: isSelected ? activeSelectedColor : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            onSelected: (selected) {
              HapticFeedback.selectionClick();
              setState(() {
                if (selected) {
                  items.add(choice);
                } else {
                  items.remove(choice);
                }
              });
            },
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: const Text('Autre...'),
          onPressed: onAddCustom,
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required String leftLabel,
    required String rightLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          activeColor: const Color(0xFF8B1E3F),
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(rightLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
