import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/taste_profile_service.dart';
import '../domain/taste_profile.dart';
import '../domain/wine_taste_radar.dart';
import 'widgets/wine_taste_radar_chart.dart';
import 'taste_profiles_dialog.dart';

/// 🎨 Distinct Vibrant Color Palette for Multi-Guest Overlays
const List<Color> kRadarPalette = [
  Color(0xFF8B1E3F), // Wine Burgundy (Primary / Moi)
  Color(0xFFD4AF37), // Gold
  Color(0xFF2E7D32), // Emerald Green
  Color(0xFF1E88E5), // Royal Blue
  Color(0xFFFB8C00), // Amber Orange
  Color(0xFF8E24AA), // Deep Purple
  Color(0xFF00ACC1), // Cyan
  Color(0xFFD81B60), // Rose Pink
];

enum RadarViewMode {
  individual,
  overlay,
  comparison,
}

class TasteProfileRadarScreen extends ConsumerStatefulWidget {
  final String? initialProfileId;

  const TasteProfileRadarScreen({super.key, this.initialProfileId});

  static Future<void> show(BuildContext context, {String? initialProfileId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TasteProfileRadarScreen(initialProfileId: initialProfileId),
    );
  }

  @override
  ConsumerState<TasteProfileRadarScreen> createState() => _TasteProfileRadarScreenState();
}

class _TasteProfileRadarScreenState extends ConsumerState<TasteProfileRadarScreen> {
  RadarViewMode _mode = RadarViewMode.individual;

  // Mode 1: Individual
  String? _selectedProfileId;

  // Mode 2: Overlay visibility map
  final Map<String, bool> _overlayVisibility = {};

  // Mode 3: Comparison profiles
  String? _compareProfileId1;
  String? _compareProfileId2;

  @override
  void initState() {
    super.initState();
    _selectedProfileId = widget.initialProfileId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesAsync = ref.watch(tasteProfilesListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18151F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('Aucun profil de goût disponible.'));
          }

          // Initialize selections if needed
          _selectedProfileId ??= profiles.first.id;
          if (!profiles.any((p) => p.id == _selectedProfileId)) {
            _selectedProfileId = profiles.first.id;
          }

          for (final p in profiles) {
            _overlayVisibility.putIfAbsent(p.id, () => true);
          }

          _compareProfileId1 ??= profiles.first.id;
          _compareProfileId2 ??= profiles.length > 1 ? profiles[1].id : profiles.first.id;

          return Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.radar, color: Color(0xFF8B1E3F), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spider Chart des Goûts 🕸️🍷',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Profils gustatifs de vous et vos invités',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      tooltip: 'Ajouter un invité / proche',
                      onPressed: () => _showAddGuestDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Mode Segmented Control
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<RadarViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: RadarViewMode.individual,
                      icon: Icon(Icons.person, size: 16),
                      label: Text('Individuel', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: RadarViewMode.overlay,
                      icon: Icon(Icons.layers, size: 16),
                      label: Text('Overlay', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: RadarViewMode.comparison,
                      icon: Icon(Icons.compare_arrows, size: 16),
                      label: Text('Comparaison', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (set) {
                    HapticFeedback.selectionClick();
                    setState(() => _mode = set.first);
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // Mode Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildModeContent(theme, isDark, profiles),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeContent(ThemeData theme, bool isDark, List<TasteProfile> profiles) {
    switch (_mode) {
      case RadarViewMode.individual:
        return _buildIndividualView(theme, isDark, profiles);
      case RadarViewMode.overlay:
        return _buildOverlayView(theme, isDark, profiles);
      case RadarViewMode.comparison:
        return _buildComparisonView(theme, isDark, profiles);
    }
  }

  // =========================================================================
  // MODE 1: INDIVIDUEL (UTILISATEUR PAR UTILISATEUR)
  // =========================================================================
  Widget _buildIndividualView(ThemeData theme, bool isDark, List<TasteProfile> profiles) {
    final currentProfile = profiles.firstWhere(
      (p) => p.id == _selectedProfileId,
      orElse: () => profiles.first,
    );
    final metrics = WineTasteRadarCalculator.compute(currentProfile);

    return Column(
      children: [
        // Horizontal Profile Selector Chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final p = profiles[index];
              final isSelected = p.id == currentProfile.id;
              final color = kRadarPalette[index % kRadarPalette.length];

              return FilterChip(
                avatar: CircleAvatar(
                  backgroundColor: color,
                  radius: 10,
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                label: Text(p.isPrimary ? '${p.name} (Moi)' : p.name),
                selected: isSelected,
                selectedColor: color.withAlpha(40),
                checkmarkColor: color,
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : null,
                ),
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedProfileId = p.id);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Radar Chart
        Center(
          child: WineTasteRadarChart(
            size: 270,
            datasets: [
              RadarChartDataset(
                label: currentProfile.name,
                metrics: metrics,
                color: kRadarPalette[profiles.indexOf(currentProfile) % kRadarPalette.length],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Metrics Breakdown Grid (6 dimensions)
        Text(
          'Détail des 6 Dimensions Gustatives',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            _buildMetricTile('Puissance & Corps', metrics.body, Icons.fitness_center_rounded, const Color(0xFF8B1E3F)),
            _buildMetricTile('Fraîcheur & Acidité', metrics.acidity, Icons.wb_sunny_outlined, const Color(0xFF1E88E5)),
            _buildMetricTile('Fruit & Gourmandise', metrics.fruit, Icons.eco_rounded, const Color(0xFF2E7D32)),
            _buildMetricTile('Boisé & Élevage', metrics.oak, Icons.forest_rounded, const Color(0xFF795548)),
            _buildMetricTile('Minéralité & Terroir', metrics.minerality, Icons.landscape_rounded, const Color(0xFF607D8B)),
            _buildMetricTile('Douceur & Sucres', metrics.sweetness, Icons.water_drop_rounded, const Color(0xFFD4AF37)),
          ],
        ),
        const SizedBox(height: 20),

        // Profile Tags Summary
        if (currentProfile.favoriteTypes.isNotEmpty ||
            currentProfile.favoriteRegions.isNotEmpty ||
            currentProfile.favoriteGrapes.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF221D2C) : const Color(0xFFFBF8F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_outline, color: Color(0xFF8B1E3F), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Préférences de ${currentProfile.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...currentProfile.favoriteTypes.map((t) => _buildChipTag(t, const Color(0xFF8B1E3F))),
                    ...currentProfile.favoriteRegions.map((r) => _buildChipTag(r, const Color(0xFFD4AF37))),
                    ...currentProfile.favoriteGrapes.map((g) => _buildChipTag(g, const Color(0xFF2E7D32))),
                  ],
                ),
                if (currentProfile.dislikedCharacteristics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Évite : ${currentProfile.dislikedCharacteristics.join(", ")}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildMetricTile(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${value.toStringAsFixed(1)} / 10',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MODE 2: OVERLAY (TOUS LES CONVIVES SUPERPOSÉS)
  // =========================================================================
  Widget _buildOverlayView(ThemeData theme, bool isDark, List<TasteProfile> profiles) {
    final datasets = <RadarChartDataset>[];
    for (int i = 0; i < profiles.length; i++) {
      final p = profiles[i];
      final isVis = _overlayVisibility[p.id] ?? true;
      datasets.add(RadarChartDataset(
        label: p.name,
        metrics: WineTasteRadarCalculator.compute(p),
        color: kRadarPalette[i % kRadarPalette.length],
        isVisible: isVis,
      ));
    }

    return Column(
      children: [
        // Multi-layer Radar Chart
        Center(
          child: WineTasteRadarChart(
            size: 280,
            datasets: datasets,
          ),
        ),
        const SizedBox(height: 20),

        // Interactive Legend & Visibility Toggles
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF221D2C) : const Color(0xFFFBF8F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Convives affichés (${datasets.where((d) => d.isVisible).length}/${profiles.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      final allVisible = _overlayVisibility.values.every((v) => v);
                      setState(() {
                        for (final p in profiles) {
                          _overlayVisibility[p.id] = !allVisible;
                        }
                      });
                    },
                    icon: const Icon(Icons.select_all, size: 14),
                    label: const Text('Tout cocher / décocher', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: profiles.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final color = kRadarPalette[idx % kRadarPalette.length];
                  final isVis = _overlayVisibility[p.id] ?? true;

                  return FilterChip(
                    avatar: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: Text(p.isPrimary ? '${p.name} (Moi)' : p.name),
                    selected: isVis,
                    selectedColor: color.withAlpha(35),
                    checkmarkColor: color,
                    labelStyle: TextStyle(
                      fontWeight: isVis ? FontWeight.bold : FontWeight.normal,
                      color: isVis ? color : null,
                    ),
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _overlayVisibility[p.id] = val);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withAlpha(40)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFD4AF37), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Astuce Sommelier : Les zones où les polygones se chevauchent représentent le profil de vin idéal qui plaira à toute la table.',
                  style: TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // MODE 3: COMPARAISON (DUO & ACCORDS)
  // =========================================================================
  Widget _buildComparisonView(ThemeData theme, bool isDark, List<TasteProfile> profiles) {
    if (profiles.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.people_outline, size: 48, color: Color(0xFF8B1E3F)),
              const SizedBox(height: 12),
              const Text(
                'Ajoutez au moins 2 convives pour comparer leurs profils gustatifs',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showAddGuestDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter un invité (ex: Papa, Maman...)'),
              ),
            ],
          ),
        ),
      );
    }

    final p1 = profiles.firstWhere((p) => p.id == _compareProfileId1, orElse: () => profiles.first);
    final p2 = profiles.firstWhere((p) => p.id == _compareProfileId2, orElse: () => profiles[1]);

    final color1 = kRadarPalette[profiles.indexOf(p1) % kRadarPalette.length];
    final color2 = kRadarPalette[profiles.indexOf(p2) % kRadarPalette.length];

    final affinity = WineTasteRadarCalculator.compare(p1, p2);

    return Column(
      children: [
        // Selectors for Profile 1 and Profile 2
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color1.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: p1.id,
                    isExpanded: true,
                    items: profiles.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: color1)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _compareProfileId1 = val);
                    },
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.compare_arrows, color: Color(0xFFD4AF37)),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color2.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: p2.id,
                    isExpanded: true,
                    items: profiles.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: color2)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _compareProfileId2 = val);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Dual Spider Chart
        Center(
          child: WineTasteRadarChart(
            size: 280,
            datasets: [
              RadarChartDataset(
                label: p1.name,
                metrics: WineTasteRadarCalculator.compute(p1),
                color: color1,
              ),
              RadarChartDataset(
                label: p2.name,
                metrics: WineTasteRadarCalculator.compute(p2),
                color: color2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Compatibility Index Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color1.withAlpha(30),
                color2.withAlpha(30),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD4AF37).withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${affinity.affinityPercentage.toStringAsFixed(0)}% d\'affinité',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Compatibilité ${p1.name} & ${p2.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Points communs
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      affinity.commonGroundsSummary,
                      style: const TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Divergences
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1E88E5), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      affinity.divergencesSummary,
                      style: const TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Sommelier Ideal Bottle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommandation Sommelier pour ce duo :',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          affinity.idealWineRecommendation,
                          style: const TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _showAddGuestDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Color(0xFF8B1E3F)),
            SizedBox(width: 10),
            Text('Ajouter un proche / invité'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Prénom / Nom du convive *',
                hintText: 'ex: Papa, Maman, Sophie, Dimitri...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes ou préférences (optionnel)',
                hintText: 'ex: Préfère les rouges charpentés et les vins du Sud',
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
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final service = ref.read(tasteProfileServiceProvider);
              final newP = await service.addProfile(
                name: name,
                notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'Ajouté par l\'utilisateur',
              );
              ref.invalidate(tasteProfilesListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() => _selectedProfileId = newP.id);
            },
            child: const Text('Créer le profil'),
          ),
        ],
      ),
    );
  }
}
