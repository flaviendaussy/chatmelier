import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/taste_profile_service.dart';
import '../domain/affinite_des_palais.dart';
import '../domain/mots_du_palais.dart';
import '../domain/palais.dart';
import '../domain/taste_profile.dart';
import 'widgets/bouteilles_qui_apprendraient.dart';
import 'widgets/radar_du_palais.dart';
import 'widgets/radar_legende.dart';
import 'widgets/wine_taste_radar_chart.dart';
import '../../journal/domain/tasting_questionnaire_result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/utils/valeurs_rangees.dart';
import '../../friends/data/friends_repository.dart' show palaisDesAmisProvider;
import '../../../shared/widgets/libere_a_la_fermeture.dart';

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

  /// La famille regardée (V2.6) : celle qu'on a choisie, sinon la mieux connue du palais
  /// affiché.
  String? _famille;
  String _familleDe(TasteProfile p) => _famille ?? p.familleDominante;

  Widget _choixDeFamille(String famille) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ChoixDeFamille(
          famille: famille,
          onChanged: (f) {
            HapticFeedback.selectionClick();
            setState(() => _famille = f);
          },
        ),
      );

  @override
  void initState() {
    super.initState();
    _selectedProfileId = widget.initialProfileId;
  }

  /// Le nom de la personne connectée, ou rien : un prénom inventé serait pire qu'aucun.
  String? get _userDisplayName {
    try {
      final user = ref.read(supabaseProvider).auth.currentUser;
      final rawName = (user?.userMetadata?['display_name'] as String?)?.trim();
      return (rawName != null && rawName.isNotEmpty) ? rawName : null;
    } catch (_) {
      return null;
    }
  }

  String _profileLabel(TasteProfile p, [String? userDisplayName]) {
    if (p.isPrimary) {
      final name = userDisplayName ?? _userDisplayName;
      final moi = tr('Moi', 'Me');
      return name == null ? moi : '$moi ($name)';
    }
    return _estUnAmi(p) ? '${p.name} (@)' : p.name;
  }

  /// Le palais d'un ami, lu sur le serveur : il n'est pas à nous, on ne le retire pas.
  static bool _estUnAmi(TasteProfile p) => p.id.startsWith('ami:');

  /// Retirer un proche de ses profils (« je ne veux pas voir Paul et Aude ici », 07/10).
  Future<void> _retirer(TasteProfile p) async {
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Retirer {name} ?', 'Remove {name}?', {'name': p.name})),
        content: Text(tr('Son profil de goût disparaît de vos listes. Les dégustations déjà notées restent dans votre journal.',
            'Their taste profile disappears from your lists. Tastings already rated stay in your journal.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Annuler', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Retirer', 'Remove'))),
        ],
      ),
    );
    if (ok != true) return;
    await conteneur.read(tasteProfileServiceProvider).deleteProfile(p.id);
    conteneur.invalidate(tasteProfilesListProvider);
    if (mounted) setState(() => _selectedProfileId = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Effet de bord : réaligne l'inventaire de cépages sur la cave avant de dessiner le
    // radar, qui pondère cet inventaire. Sans cet appel, `cellarGrapes` restait vide et
    // toute une branche du calcul ne s'exécutait jamais.
    ref.watch(cellarGrapeSyncProvider);
    final profilesAsync = ref.watch(tasteProfilesListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18151F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(tr('Erreur : {err}', 'Error: {err}', {'err': err}))),
        data: (propres) {
          // Ses amis aussi, avec leur vrai palais (R5, migration 067) — sauf ceux qu'un profil
          // local représente déjà.
          final amis = ref.watch(palaisDesAmisProvider).valueOrNull ?? const <TasteProfile>[];
          final profiles = [
            ...propres,
            for (final a in amis)
              if (!propres.any((p) => p.friendUserId != null && p.friendUserId == a.friendUserId)) a,
          ];
          if (profiles.isEmpty) {
            final emptyText = tr('Aucun profil de goût disponible.', 'No taste profiles available.');
            return Center(child: Text(emptyText));
          }

          // Initialize selections if needed
          _selectedProfileId ??= profiles.first.id;
          if (!profiles.any((p) => p.id == _selectedProfileId)) {
            _selectedProfileId = profiles.first.id;
          }

          for (final p in profiles) {
            // Les amis sont proposés en superposition, pas imposés : un geste les ajoute.
            _overlayVisibility.putIfAbsent(p.id, () => !_estUnAmi(p));
          }

          _compareProfileId1 ??= profiles.first.id;
          // Le second palais se choisit quand il y en a un autre : les amis arrivent après
          // les profils locaux, et le comparatif restait figé sur « Moi » face à « Moi »
          // (« 99 % d'affinité, votre compatibilité avec Moi », 17/10).
          if (_compareProfileId2 == null || _compareProfileId2 == _compareProfileId1) {
            _compareProfileId2 = profiles.firstWhere((p) => p.id != _compareProfileId1, orElse: () => profiles.first).id;
          }

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
                            tr('Spider Chart des Goûts 🕸️🍷', 'Spider Chart of Tastes 🕸️🍷'),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            tr('Profils gustatifs de vous et vos invités', 'Taste profiles of you and your guests'),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      tooltip: tr('Ajouter un invité / proche', 'Add a guest / friend'),
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
                  segments: [
                    ButtonSegment(
                      value: RadarViewMode.individual,
                      icon: const Icon(Icons.person, size: 16),
                      label: Text(tr('Individuel', 'Individual'), style: const TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: RadarViewMode.overlay,
                      icon: const Icon(Icons.layers, size: 16),
                      label: Text(tr('Overlay', 'Overlay'), style: const TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: RadarViewMode.comparison,
                      icon: const Icon(Icons.compare_arrows, size: 16),
                      label: Text(tr('Comparaison', 'Comparison'), style: const TextStyle(fontSize: 12)),
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
    final famille = _familleDe(currentProfile);
    final palais = currentProfile.palaisPour(famille);
    final couleur = kRadarPalette[profiles.indexOf(currentProfile) % kRadarPalette.length];

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
                label: Text(_profileLabel(p)),
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
        if (!currentProfile.isPrimary && !_estUnAmi(currentProfile))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.person_remove_outlined, size: 18),
              label: Text(tr('Retirer {name} de mes profils', 'Remove {name} from my profiles', {'name': currentProfile.name})),
              onPressed: () => _retirer(currentProfile),
            ),
          ),
        _choixDeFamille(famille),
        const SizedBox(height: 16),

        // Radar Chart
        Center(
          child: WineTasteRadarChart(
            size: 270,
            customAxisLabels: RadarDuPalais.libelles(famille),
            datasets: [RadarDuPalais.jeu(currentProfile, famille, label: currentProfile.name, color: couleur)],
          ),
        ),
        const SizedBox(height: 6),
        LegendeDuRadar(color: couleur),
        const SizedBox(height: 20),

        // Les bouteilles de la cave qui trancheraient ce que le radar devine (V2.5 · F3).
        BouteillesQuiApprendraient(
          profil: currentProfile,
          couleur: couleur,
        ),

        // Le détail des axes de la famille (V2.6 : cinq par famille, et non huit).
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Le palais des {famille}, axe par axe', 'The {famille} palate, axis by axis',
                  {'famille': MotsDuPalais.familleAuPluriel(famille)}),
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
                for (final axe in AxesDuPalais.duRadar(famille))
                  _buildMetricTile(
                    AxesDuPalais.nom(axe),
                    palais.valeur(axe),
                    _iconeDe(axe),
                    _couleurDe(axe),
                    observations: currentProfile.observationsSur(famille, axe),
                    bout: _boutDe(axe, palais.valeur(axe)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Les arômes : des étiquettes, plus des axes (V2.6). La minéralité en est une.
        if (MotsDuPalais.aromesPreferes(currentProfile) case final aromes when aromes.isNotEmpty) ...[
          _AromesPreferes(ids: aromes, nom: currentProfile.isPrimary ? null : currentProfile.name),
          const SizedBox(height: 20),
        ],

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
                      tr('Préférences de {nom}', 'Preferences of {nom}', {'nom': currentProfile.name}),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...currentProfile.favoriteTypes.map((t) => _buildChipTag(valeurAffichee(t), const Color(0xFF8B1E3F))),
                    ...currentProfile.favoriteRegions.map((r) => _buildChipTag(valeurAffichee(r), const Color(0xFFD4AF37))),
                    ...currentProfile.favoriteGrapes.map((g) => _buildChipTag(g, const Color(0xFF2E7D32))),
                  ],
                ),
                if (currentProfile.dislikedCharacteristics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    tr('Évite : {liste}', 'Avoids: {liste}', {'liste': currentProfile.dislikedCharacteristics.map(valeurAffichee).join(', ')}),
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

  /// [observations] : dégustations qui ont renseigné cet axe. Sous cinq, la valeur est
  /// devinée et le dit (mêmes seuils que le radar).
  Widget _buildMetricTile(String label, double value, IconData icon, Color color, {int? observations, String? bout}) {
    final devine = observations != null && observations < 5;
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
                  bout == null ? label : '$label · $bout',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${value.toStringAsFixed(1)} / 10',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: devine ? color.withAlpha(150) : color),
                    ),
                    if (observations != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)?.radarAxisTastings(observations) ??
                              (observations == 0 ? '?' : '$observations'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontStyle: devine ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconeDe(String axe) => switch (axe) {
        AxesDuPalais.fraicheur => Icons.bolt_rounded,
        AxesDuPalais.douceur => Icons.water_drop_outlined,
        AxesDuPalais.corps => Icons.fitness_center_rounded,
        AxesDuPalais.tanins => Icons.grain_rounded,
        AxesDuPalais.boise => Icons.forest_rounded,
        _ => Icons.hourglass_bottom_rounded,
      };

  static Color _couleurDe(String axe) => switch (axe) {
        AxesDuPalais.fraicheur => const Color(0xFF1E88E5),
        AxesDuPalais.douceur => const Color(0xFFD4A017),
        AxesDuPalais.corps => const Color(0xFF8B1E3F),
        AxesDuPalais.tanins => const Color(0xFF795548),
        AxesDuPalais.boise => const Color(0xFF8D6E63),
        _ => const Color(0xFF6D4C9F),
      };

  /// Le bout de l'axe vers lequel penche la valeur, ou rien au milieu.
  static String? _boutDe(String axe, double v) {
    final (bas, haut) = AxesDuPalais.bouts(axe);
    if (v >= 6.5) return haut;
    if (v <= 3.5) return bas;
    return null;
  }

  // =========================================================================
  // MODE 2: OVERLAY (TOUS LES CONVIVES SUPERPOSÉS)
  // =========================================================================
  Widget _buildOverlayView(ThemeData theme, bool isDark, List<TasteProfile> profiles) {
    final famille = _familleDe(profiles.firstWhere((p) => p.isPrimary, orElse: () => profiles.first));
    final datasets = <RadarChartDataset>[];
    for (int i = 0; i < profiles.length; i++) {
      final p = profiles[i];
      final isVis = _overlayVisibility[p.id] ?? true;
      datasets.add(RadarDuPalais.jeu(
        p,
        famille,
        label: p.name,
        color: kRadarPalette[i % kRadarPalette.length],
        isVisible: isVis,
        avecConfiance: false,
      ));
    }

    return Column(
      children: [
        _choixDeFamille(famille),
        const SizedBox(height: 16),
        // Multi-layer Radar Chart
        Center(
          child: WineTasteRadarChart(
            size: 280,
            customAxisLabels: RadarDuPalais.libelles(famille),
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
                    tr('Convives affichés ({n}/{total})', 'Guests shown ({n}/{total})',
                        {'n': datasets.where((d) => d.isVisible).length, 'total': profiles.length}),
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
                    label: Text(
                      tr('Tout cocher / décocher', 'Toggle all'),
                      style: const TextStyle(fontSize: 11.5),
                    ),
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
                    label: Text(_profileLabel(p)),
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
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('Astuce Sommelier : Les zones où les polygones se chevauchent représentent le profil de vin idéal qui plaira à toute la table.', 'Sommelier Tip: Overlapping polygon zones represent the ideal wine profile that will please everyone at the table.'),
                  style: const TextStyle(fontSize: 12, height: 1.35),
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
              Text(
                tr('Ajoutez au moins 2 convives pour comparer leurs profils gustatifs', 'Add at least 2 guests to compare their taste profiles'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showAddGuestDialog(context),
                icon: const Icon(Icons.person_add),
                label: Text(
                  tr('Ajouter un invité (ex: Papa, Maman...)', 'Add a guest (e.g. Dad, Mom...)'),
                ),
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

    final famille = _familleDe(p1);
    final affinite = AffiniteDesPalais.comparer(p1, p2, famille);
    final pourcentage = affinite.pourcentage;

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
                        child: Text(_profileLabel(p), style: TextStyle(fontWeight: FontWeight.bold, color: color1)),
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
                        child: Text(_profileLabel(p), style: TextStyle(fontWeight: FontWeight.bold, color: color2)),
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
        _choixDeFamille(famille),
        const SizedBox(height: 16),

        // Dual Spider Chart
        Center(
          child: WineTasteRadarChart(
            size: 280,
            customAxisLabels: RadarDuPalais.libelles(famille),
            datasets: [
              RadarDuPalais.jeu(p1, famille, label: p1.name, color: color1, avecConfiance: false),
              RadarDuPalais.jeu(p2, famille, label: p2.name, color: color2, avecConfiance: false),
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
                      // Sur un ou deux axes connus des deux, ce n'est qu'une approximation.
                      pourcentage == null
                          ? tr('Affinité à venir', 'Affinity to come')
                          : tr('{pct} % d\'affinité', '{pct}% affinity',
                              {'pct': '${affinite.axesCompares < 3 ? '≈' : ''}${pourcentage.toStringAsFixed(0)}'}),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      // On parle à la personne : « Votre compatibilité avec Caro », pas « Moi & Caro ».
                      p1.isPrimary || p2.isPrimary
                          ? tr('Votre compatibilité avec {b}', 'Your compatibility with {b}',
                              {'b': p1.isPrimary ? p2.name : p1.name})
                          : tr('Compatibilité {a} & {b}', 'Compatibility {a} & {b}', {'a': p1.name, 'b': p2.name}),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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
                      affinite.phraseEnCommun,
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
                      affinite.phraseEcarts,
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
                        Text(
                          tr('Recommandation Sommelier pour ce duo :', 'Sommelier Recommendation for this duo:'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          affinite.vinIdeal,
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
        const SizedBox(height: 16),
        // L'axe que ni l'un ni l'autre n'a encore montré, et la bouteille qui le trancherait (F2).
        PourVousConnaitreTousLesDeux(a: p1, b: p2),
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

    final dialogTitle = tr('Ajouter un proche / invité', 'Add a friend / guest');

    final nameLabel = tr('Prénom / Nom du convive *', 'Guest Name *');

    final nameHint = tr('ex. Papa, Maman…', 'e.g. Dad, Mom…');

    final notesLabel = tr('Notes ou préférences (optionnel)', 'Notes or preferences (optional)');

    final notesHint = tr('ex: Préfère les rouges charpentés et les vins du Sud', 'e.g. Prefers full-bodied reds and Southern wines');

    final cancelText = tr('Annuler', 'Cancel');

    final createText = tr('Créer le profil', 'Create profile');

    showDialog(
      context: context,
      builder: (ctx) => LibereALaFermeture(
        controleurs: [nameCtrl, notesCtrl],
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFF8B1E3F)),
              const SizedBox(width: 10),
              Text(dialogTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: nameLabel,
                  hintText: nameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: notesLabel,
                  hintText: notesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(cancelText),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
              onPressed: () async {
                final conteneur = ProviderScope.containerOf(context, listen: false);
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final service = conteneur.read(tasteProfileServiceProvider);
                final newP = await service.addProfile(
                  name: name,
                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : (tr('Ajouté par l\'utilisateur', 'Added by user')),
                );
                conteneur.invalidate(tasteProfilesListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() => _selectedProfileId = newP.id);
              },
              child: Text(createText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les arômes qu'une personne cite le plus, en étiquettes (V2.6).
class _AromesPreferes extends StatelessWidget {
  final List<String> ids;

  /// Le prénom d'un proche ; nul pour soi (« que vous citez »).
  final String? nom;

  const _AromesPreferes({required this.ids, this.nom});

  @override
  Widget build(BuildContext context) {
    final options = {for (final o in TastingQuestionnaireResult.getAromaOptions(AppLocalizations.of(context))) o.id: o};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nom == null
              ? tr('Les arômes que vous citez le plus', 'The aromas you mention most')
              : tr('Les arômes que {nom} cite le plus', 'The aromas {nom} mentions most', {'nom': nom}),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final id in ids)
              if (options[id] case final o?)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Text(o.emoji),
                  label: Text(o.label, style: const TextStyle(fontSize: 12)),
                ),
          ],
        ),
      ],
    );
  }
}
