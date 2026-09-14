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
  String get _langCode => Localizations.maybeLocaleOf(context)?.languageCode ?? 'fr';

  String _t(String en, String es, String ca, String la, String fr) {
    switch (_langCode) {
      case 'en': return en;
      case 'es': return es;
      case 'ca': return ca;
      case 'la': return la;
      default: return fr;
    }
  }

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
        title: Text('${_t("Add", "Añadir", "Afegir", "Adde", "Ajouter un(e)")} $label'),
        content: TextField(
          controller: _customInputController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '${_t("Name of", "Nombre del", "Nom del", "Nomen", "Nom du")} $label...',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitCustomItem(targetList),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Cancel', 'Cancelar', 'Cancel·lar', 'Abrogare', 'Annuler')),
          ),
          FilledButton(
            onPressed: () => _submitCustomItem(targetList),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
            ),
            child: Text(_t('Add', 'Añadir', 'Afegir', 'Adde', 'Ajouter'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: Text(_t('Reset your taste profile?', '¿Restablecer tu perfil de gusto?', 'Restablir el teu perfil de gust?', 'Restituere profilum saporis?', 'Réinitialiser votre profil de goûts ?')),
        content: Text(
          _t('All preferences (styles, regions, grapes, aversions and settings) will be reset.',
             'Todas tus preferencias (estilos, regiones, uvas, aversiones y ajustes) se restablecerán.',
             'Totes les preferències (estils, regions, raïms, aversions i paràmetres) es restabliran.',
             'Omnes praeferentiae ad nihilum restituentur.',
             'Toutes vos préférences (styles, régions, cépages, aversions et réglages) seront remises à zéro.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('Cancel', 'Cancelar', 'Cancel·lar', 'Abrogare', 'Annuler'))),
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
            child: Text(_t('Reset', 'Restablecer', 'Restablir', 'Restituere', 'Réinitialiser'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        SnackBar(
          content: Text(_t('✨ Taste profile updated successfully!',
                           '✨ ¡Perfil de gusto actualizado con éxito!',
                           '✨ Perfil de gust actualitzat amb èxit!',
                           '✨ Profilum saporis feliciter renovatum est!',
                           '✨ Profil de goûts mis à jour avec succès !')),
          backgroundColor: const Color(0xFF2E7D32),
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
                              _t('My Taste Profile', 'Mi Perfil de Gusto', 'El meu Perfil de Gust', 'Meum Profilum Saporis', 'Mon Profil de Goûts'),
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _resetProfile,
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                          label: Text(_t('Reset', 'Restablecer', 'Restablir', 'Restituere', 'Réinitialiser'), style: const TextStyle(color: Colors.grey)),
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
                      _t('Customize your wine preferences anytime. Chatmelier adapts in real time for food & wine pairings and recommendations.',
                         'Personaliza tus preferencias enológicas en cualquier momento. Chatmelier se adapta en tiempo real para tus maridajes y recomendaciones.',
                         'Personalitza les teves preferències enològiques en qualsevol moment. Chatmelier s\'adapta en temps real per als teus maridatges i recomanacions.',
                         'Praeferentias oenologicas quolibet tempore adapta. Chatmelier tecum concordat in concordantiis ciborum et vinorum.',
                         'Personnalisez vos préférences œnologiques à tout moment. Chatmelier s\'adapte en temps réel pour vos accords mets-vins et recommandations.'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: STYLES & TYPES DE VINS
                    _buildSectionHeader(
                      _t('Favorite Wine Styles & Types', 'Estilos y Tipos de Vino Favoritos', 'Estils i Tipus de Vi Favorits', 'Genera & Styli Vini Praedilecti', 'Styles & Types de Vins Préférés'),
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
                      _t('Favorite Regions & Terroirs', 'Regiones y Terruños Favoritos', 'Regions i Terroirs Favorits', 'Regiones & Terrena Praedilecta', 'Régions & Terroirs Coups de Cœur'),
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
                      _t('Favorite Grape Varieties', 'Variedades de Uva Favoritas', 'Varietats de Raïm Preferides', 'Uvae Praedilectae', 'Cépages Favoris'),
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
                      _t('Disliked Traits / Aromas (Aversions)', 'Rasgos / Aromas no deseados (Aversiones)', 'Trets / Aromes no desitjats (Aversions)', 'Qualitates / Aromata non grata (Aversiones)', 'Traits / Arômes non appréciés (Aversions)'),
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
                                      _t('Palate Sensitivities', 'Sensibilidades del Paladar', 'Sensibilitats del Paladar', 'Sensibilitas Palati', 'Sensibilités du Palais'),
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
                                label: _t('Tannic structure', 'Estructura tánica', 'Estructura tànnica', 'Structura tannica', 'Structure tannique'),
                                value: _tanninPref,
                                leftLabel: _t('Soft & Smooth', 'Suave y Sedoso', 'Suau i Sedós', 'Mollis & Fundus', 'Souple & Fondu'),
                                rightLabel: _t('Bold & Powerful', 'Potente y Noble', 'Potent i Noble', 'Fortis & Nobilis', 'Puissant & Racé'),
                                onChanged: (v) => setState(() => _tanninPref = v),
                              ),
                              const SizedBox(height: 12),
                              // Acidity
                              _buildSliderRow(
                                label: _t('Acidity / Freshness', 'Acidez / Frescura', 'Acidesa / Frescor', 'Aciditas / Viriditas', 'Acidité / Fraîcheur'),
                                value: _acidityPref,
                                leftLabel: _t('Round', 'Redondo', 'Rodó', 'Rotundum', 'Rondeur'),
                                rightLabel: _t('Crisp & Lively', 'Vivo y Tenso', 'Viu i Tens', 'Acer & Intentus', 'Vif & Tendu'),
                                onChanged: (v) => setState(() => _acidityPref = v),
                              ),
                              const SizedBox(height: 12),
                              // Body
                              _buildSliderRow(
                                label: _t('Body & Weight', 'Cuerpo y Sustancia', 'Cos i Substància', 'Corpus & Substantia', 'Corps & Matière'),
                                value: _bodyPref,
                                leftLabel: _t('Light & Easy', 'Ligero y Fácil', 'Lleuger i Fàcil', 'Leve & Facile', 'Léger & Digest'),
                                rightLabel: _t('Full & Powerful', 'Carnoso y Potente', 'Carni i Potent', 'Carnosum & Validum', 'Charnu & Puissant'),
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
                      _t('Personal Notes & Details', 'Notas personales y detalles', 'Notes personals i detalls', 'Notae & singula', 'Notes personnelles & Précisions'),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: _t('E.g. Great lover of mature vintages, biodynamic mineral wines...',
                                     'Ej: Gran aficionado a las añadas viejas, vinos minerales biodinámicos...',
                                     'Ex: Gran aficionat a les anyades velles, vins minerals biodinàmics...',
                                     'Ex: Amator veterum annorum, vinorum mineralium...',
                                     'Ex: Grand amateur de vieux millésimes, vins minéraux en biodynamie...'),
                        border: const OutlineInputBorder(),
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
                    child: Text(
                      _t('Save my taste profile ✨', 'Guardar mi perfil de gusto ✨', 'Desar el meu perfil de gust ✨', 'Servare meum profilum saporis ✨', 'Enregistrer mon profil de goûts ✨'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
