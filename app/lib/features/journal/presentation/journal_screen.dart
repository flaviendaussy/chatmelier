import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/utils/responsive_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/tasting_entry.dart';
import 'external_tasting_dialog.dart';
import 'tasting_questionnaire_sheet.dart';
import 'tasting_entry_detail_screen.dart';

import '../../../features/offline/domain/offline_action.dart';
import '../../../features/offline/presentation/sync_provider.dart';

final tastingLogProvider = FutureProvider<List<TastingEntry>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final offlineStorage = ref.watch(offlineStorageServiceProvider);
  final user = supabase.auth.currentUser;

  final List<TastingEntry> entries = [];

  if (user != null) {
    try {
      final res = await supabase
          .from('tasting_log')
          .select('*, wines(*)')
          .order('consumed_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      final remote = (res as List<dynamic>)
          .map((j) => TastingEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      entries.addAll(remote);
    } catch (_) {}
  }

  // Fusionner avec les actions hors-ligne de consommation
  final queue = offlineStorage.getQueue();
  for (final action in queue) {
    if (action.type == OfflineActionType.consumeBottle) {
      final data = action.data;
      final wineName = data['wine_name'] as String? ?? data['name'] as String? ?? 'Vin dégusté';
      final vintage = (data['vintage'] as num?)?.toInt() ?? int.tryParse(data['vintage']?.toString() ?? '');
      final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
      final notes = data['tasting_notes'] as String?;
      final paired = data['food_paired'] as String?;
      final region = data['region'] as String?;
      final country = data['country'] as String?;
      final appellation = data['appellation'] as String?;
      final coTasters = (data['co_tasters'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
      final bottleOwnerName = data['bottle_owner_name'] as String?;
      final bottleOwnerId = data['bottle_owner_id'] as String?;
      final locationName = data['location_name'] as String?;
      final isExternal = data['is_external'] == true;

      // Éviter les doublons si déjà présent
      if (!entries.any((e) => e.id == action.id)) {
        entries.insert(0, TastingEntry(
          id: action.id,
          bottleId: data['bottle_id'] as String?,
          wineId: data['wine_id'] as String? ?? '',
          wineName: wineName,
          vintage: vintage,
          region: region,
          country: country,
          appellation: appellation,
          rating: rating,
          foodPaired: paired,
          tastingNotes: notes,
          coTasters: coTasters,
          bottleOwnerId: bottleOwnerId,
          bottleOwnerName: bottleOwnerName,
          locationName: locationName,
          isExternal: isExternal,
          consumedAt: action.createdAt,
        ));
      }
    }
  }

  // Sort strictly descending by date
  entries.sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
  return entries;
});

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedYear;
  String _selectedOriginFilter = 'all'; // 'all', 'cellar', 'external'
  bool _minRatingOnly = false; // >= 8/10 or >= 4/5

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TastingEntry> _filterEntries(List<TastingEntry> entries) {
    return entries.where((entry) {
      // Filter by origin (Cave vs Hors-cave)
      if (_selectedOriginFilter == 'cellar' && entry.isExternal) return false;
      if (_selectedOriginFilter == 'external' && !entry.isExternal) return false;

      // Filter by year
      if (_selectedYear != null && entry.consumedAt.year.toString() != _selectedYear) {
        return false;
      }

      // Filter by high rating (>= 8/10 or >= 4/5)
      if (_minRatingOnly && (entry.rating == null || entry.rating! < 8.0)) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final wineName = (entry.wineName ?? '').toLowerCase();
        final notes = (entry.tastingNotes ?? '').toLowerCase();
        final food = (entry.foodPaired ?? '').toLowerCase();
        final region = (entry.region ?? '').toLowerCase();
        final country = (entry.country ?? '').toLowerCase();
        final appellation = (entry.appellation ?? '').toLowerCase();
        final loc = (entry.locationName ?? '').toLowerCase();
        final yearStr = entry.consumedAt.year.toString();
        final guests = entry.coTasters.map((g) => g.toLowerCase()).join(' ');

        final matches = wineName.contains(q) ||
            notes.contains(q) ||
            food.contains(q) ||
            region.contains(q) ||
            country.contains(q) ||
            appellation.contains(q) ||
            loc.contains(q) ||
            yearStr.contains(q) ||
            guests.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('d MMMM yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(tastingLogProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.journalTitle ?? 'Historique de Dégustation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B1E3F)),
            tooltip: 'Dégustation Hors-Cave (Restaurant, Amis)',
            onPressed: () => ExternalTastingDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.public, color: Colors.amber),
            tooltip: 'Carte à Gratter des Terroirs',
            onPressed: () => context.push('/scratchcard'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'journal_external_tasting_fab',
        onPressed: () => ExternalTastingDialog.show(context),
        icon: const Icon(Icons.restaurant),
        label: const Text('Déguster Hors-Cave'),
        backgroundColor: const Color(0xFF8B1E3F),
        foregroundColor: Colors.white,
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur : $err'),
          ),
        ),
        data: (allEntries) {
          if (allEntries.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book,
              title: l10n?.journalEmpty ?? 'Aucun souvenir de dégustation pour le moment',
              subtitle: l10n?.journalEmptySub ??
                  'Dégustez et sortez une bouteille de votre cave ou notez un vin bu au restaurant.',
              action: FilledButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Noter un vin hors-cave (Restaurant, Amis)'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E3F),
                    foregroundColor: Colors.white),
                onPressed: () => ExternalTastingDialog.show(context),
              ),
            );
          }

          // Extract available years for filter
          final availableYears = allEntries
              .map((e) => e.consumedAt.year.toString())
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          final filteredEntries = _filterEntries(allEntries);

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(tastingLogProvider.future),
            child: CustomScrollView(
              slivers: [
                // 1. Search Bar & Multi-fields Search Filter Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search textfield
                        TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText:
                                'Rechercher : vin, lieu, invité, plat, note, année...',
                            hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black45),
                            prefixIcon:
                                const Icon(Icons.search, color: Color(0xFF8B1E3F)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filters Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // All / Cave / Hors-cave Segmented Filter
                              FilterChip(
                                label: const Text('Tous'),
                                selected: _selectedOriginFilter == 'all',
                                selectedColor:
                                    const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(
                                        () => _selectedOriginFilter = 'all');
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              FilterChip(
                                avatar: const Text('🍷',
                                    style: TextStyle(fontSize: 12)),
                                label: const Text('Ma Cave'),
                                selected: _selectedOriginFilter == 'cellar',
                                selectedColor:
                                    const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                                onSelected: (sel) {
                                  setState(() => _selectedOriginFilter =
                                      sel ? 'cellar' : 'all');
                                },
                              ),
                              const SizedBox(width: 6),
                              FilterChip(
                                avatar: const Text('🍽️',
                                    style: TextStyle(fontSize: 12)),
                                label: const Text('Hors-Cave'),
                                selected: _selectedOriginFilter == 'external',
                                selectedColor:
                                    Colors.orange.withValues(alpha: 0.2),
                                onSelected: (sel) {
                                  setState(() => _selectedOriginFilter =
                                      sel ? 'external' : 'all');
                                },
                              ),
                              const SizedBox(width: 8),

                              // High Rating Filter (>= 8/10)
                              FilterChip(
                                avatar: const Icon(Icons.star,
                                    size: 14, color: Color(0xFFD4AF37)),
                                label: const Text('Coups de Cœur (≥ 8/10)'),
                                selected: _minRatingOnly,
                                selectedColor: const Color(0xFFD4AF37)
                                    .withValues(alpha: 0.2),
                                onSelected: (sel) {
                                  setState(() => _minRatingOnly = sel);
                                },
                              ),
                              const SizedBox(width: 8),

                              // Year Filter Dropdown / Chips
                              if (availableYears.length > 1)
                                DropdownButtonHideUnderline(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _selectedYear != null
                                          ? const Color(0xFF8B1E3F)
                                              .withValues(alpha: 0.15)
                                          : (isDark
                                              ? Colors.white10
                                              : Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _selectedYear != null
                                            ? const Color(0xFF8B1E3F)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: DropdownButton<String?>(
                                      value: _selectedYear,
                                      hint: const Text('Année',
                                          style: TextStyle(fontSize: 12)),
                                      isDense: true,
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('Toutes les années',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        ...availableYears.map(
                                          (yr) => DropdownMenuItem<String?>(
                                            value: yr,
                                            child: Text(yr,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                      onChanged: (yr) {
                                        setState(() => _selectedYear = yr);
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. List of entries or empty filter state
                if (filteredEntries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun souvenir trouvé',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Aucune dégustation ne correspond aux filtres actuels.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('Réinitialiser les filtres'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedYear = null;
                                  _selectedOriginFilter = 'all';
                                  _minRatingOnly = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    sliver: Responsive.isTabletOrDesktop(context)
                        ? SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 460,
                              mainAxisExtent: 220,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildTastingCard(
                                context,
                                filteredEntries[index],
                                isDark,
                                theme,
                              ),
                              childCount: filteredEntries.length,
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildTastingCard(
                                context,
                                filteredEntries[index],
                                isDark,
                                theme,
                              ),
                              childCount: filteredEntries.length,
                            ),
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTastingCard(
    BuildContext context,
    TastingEntry entry,
    bool isDark,
    ThemeData theme,
  ) {
    final wineName = entry.wineName ?? 'Vin dégusté';
    final vintage = entry.vintage != null && entry.vintage! > 0
        ? ' (${entry.vintage})'
        : ' (NM)';
    final dateStr = _formatDate(entry.consumedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TastingEntryDetailScreen(entry: entry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Wine Name & Vintage + Rating on 10
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$wineName$vintage',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (entry.appellation != null &&
                                entry.appellation!.isNotEmpty)
                              entry.appellation!
                            else if (entry.region != null &&
                                entry.region!.isNotEmpty)
                              entry.region!,
                            if (entry.country != null &&
                                entry.country!.isNotEmpty)
                              entry.country!,
                            dateStr,
                          ].join(' • '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Rating Badge on 10
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 4),
                        Text(
                          entry.rating != null
                              ? '${entry.rating!.toStringAsFixed(1)}/10'
                              : 'Non noté',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Badges row: Provenance / Location / Co-tasters
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (entry.isExternal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🍽️ Hors-Cave',
                          style: TextStyle(
                              fontSize: 10.5, color: Colors.deepOrange)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🍷 Cave',
                          style: TextStyle(
                              fontSize: 10.5, color: Color(0xFF8B1E3F))),
                    ),
                  if (entry.locationName != null &&
                      entry.locationName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('📍 ${entry.locationName}',
                          style: const TextStyle(
                              fontSize: 10.5, color: Colors.blueGrey)),
                    ),
                  if (entry.coTasters.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('👥 ${entry.coTasters.join(", ")}',
                          style: const TextStyle(
                              fontSize: 10.5, color: Colors.purple)),
                    ),
                ],
              ),

              if (entry.foodPaired != null && entry.foodPaired!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.restaurant, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Accord : ${entry.foodPaired}',
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              if (entry.tastingNotes != null &&
                  entry.tastingNotes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '"${entry.tastingNotes}"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Spacer(),

              // Bottom Actions: Questionnaire Sheet & Detail Link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fiche complète & arômes',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B1E3F).withValues(alpha: 0.8),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.quiz_outlined, size: 15),
                    label: const Text('Quiz sommelier',
                        style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      TastingQuestionnaireSheet.show(
                        context,
                        wineName: entry.wineName ?? 'Vin dégusté',
                        vintage: entry.vintage,
                        region: entry.region,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
