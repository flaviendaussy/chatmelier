import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/widgets/empty_state.dart';
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

  List<TastingEntry> _filterEntries(List<TastingEntry> allEntries) {
    return allEntries.where((entry) {
      // 1. Origin filter
      if (_selectedOriginFilter == 'cellar' && entry.isExternal) return false;
      if (_selectedOriginFilter == 'external' && !entry.isExternal) return false;

      // 2. Year filter
      if (_selectedYear != null && _selectedYear!.isNotEmpty) {
        final entryYear = entry.consumedAt.year.toString();
        if (entryYear != _selectedYear) return false;
      }

      // 3. Minimum rating filter
      if (_minRatingOnly) {
        final r = entry.rating ?? 0.0;
        // Standardized rating check: rating >= 4/5 (or >= 8/10)
        if (r < 4.0 && r < 8.0) return false;
      }

      // 4. Multi-fields text search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (entry.wineName ?? '').toLowerCase();
        final region = (entry.region ?? '').toLowerCase();
        final appellation = (entry.appellation ?? '').toLowerCase();
        final country = (entry.country ?? '').toLowerCase();
        final loc = (entry.locationName ?? '').toLowerCase();
        final notes = (entry.tastingNotes ?? '').toLowerCase();
        final food = (entry.foodPaired ?? '').toLowerCase();
        final owner = (entry.bottleOwnerName ?? '').toLowerCase();
        final vintageStr = entry.vintage?.toString() ?? 'nm';
        final yearStr = entry.consumedAt.year.toString();
        final guests = entry.coTasters.map((g) => g.toLowerCase()).join(' ');

        final matches = name.contains(q) ||
            region.contains(q) ||
            appellation.contains(q) ||
            country.contains(q) ||
            loc.contains(q) ||
            notes.contains(q) ||
            food.contains(q) ||
            owner.contains(q) ||
            vintageStr.contains(q) ||
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
              subtitle: l10n?.journalEmptySub ?? 'Dégustez et sortez une bouteille de votre cave ou notez un vin bu au restaurant.',
              action: FilledButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Noter un vin hors-cave (Restaurant, Amis)'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F), foregroundColor: Colors.white),
                onPressed: () => ExternalTastingDialog.show(context),
              ),
            );
          }

          // Extract available years for filter
          final availableYears = allEntries.map((e) => e.consumedAt.year.toString()).toSet().toList()
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
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Rechercher : vin, lieu, invité, plat, note, année...',
                            hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF8B1E3F)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E1A24) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF8B1E3F), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filter Chips row (Horizontally scrollable)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // All / Origin filters
                              FilterChip(
                                label: const Text('Tous'),
                                selected: _selectedOriginFilter == 'all' && _selectedYear == null && !_minRatingOnly,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedOriginFilter = 'all';
                                    _selectedYear = null;
                                    _minRatingOnly = false;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                avatar: const Icon(Icons.inventory_2_outlined, size: 14),
                                label: const Text('Ma Cave'),
                                selected: _selectedOriginFilter == 'cellar',
                                onSelected: (sel) => setState(() => _selectedOriginFilter = sel ? 'cellar' : 'all'),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                avatar: const Icon(Icons.restaurant, size: 14),
                                label: const Text('Hors-Cave'),
                                selected: _selectedOriginFilter == 'external',
                                onSelected: (sel) => setState(() => _selectedOriginFilter = sel ? 'external' : 'all'),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                avatar: const Icon(Icons.star, size: 14, color: Colors.amber),
                                label: const Text('Coup de Cœur (⭐ 8+)'),
                                selected: _minRatingOnly,
                                onSelected: (sel) => setState(() => _minRatingOnly = sel),
                              ),
                              if (availableYears.length > 1) ...[
                                const SizedBox(width: 8),
                                ...availableYears.map((yr) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(yr),
                                        selected: _selectedYear == yr,
                                        onSelected: (sel) => setState(() => _selectedYear = sel ? yr : null),
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Scratch Map banner card
                        Card(
                          margin: EdgeInsets.zero,
                          color: const Color(0xFF1E1A24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => context.push('/scratchcard'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.public, color: Color(0xFFD4AF37), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Carte à Gratter des Terroirs',
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        Text(
                                          '${allEntries.length} vin(s) dégusté(s) • Voir vos régions débloquées',
                                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Color(0xFFD4AF37), size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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
                            const Icon(Icons.search_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun souvenir trouvé',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Aucune dégustation ne correspond aux filtres actuels.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = filteredEntries[index];
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
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Wine Name & Vintage + Rating on 10
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$wineName$vintage',
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        if (entry.rating != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD4AF37),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star, size: 14, color: Colors.white),
                                                const SizedBox(width: 4),
                                                Text(
                                                  entry.rating! <= 5.0 && entry.rating! > 0
                                                      ? '${(entry.rating! * 2).toStringAsFixed(1)} / 10'
                                                      : '${entry.rating!.toStringAsFixed(1)} / 10',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Row 2: Origin badge, Location pin, and Date
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        // Date badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.calendar_today, size: 11, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(dateStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),

                                        // Location badge (Où)
                                        if (entry.locationName != null && entry.locationName!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.place, size: 12, color: Colors.blue),
                                                const SizedBox(width: 4),
                                                Text(
                                                  entry.locationName!,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Origin Description
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (entry.isExternal ? Colors.purple : const Color(0xFF8B1E3F)).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: (entry.isExternal ? Colors.purple : const Color(0xFF8B1E3F)).withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                entry.isExternal ? Icons.restaurant : Icons.inventory_2,
                                                size: 11,
                                                color: entry.isExternal ? Colors.purple : const Color(0xFF8B1E3F),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                entry.originDescription,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: entry.isExternal ? Colors.purple : const Color(0xFF8B1E3F),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Row 3: Co-tasters (Avec qui)
                                    if (entry.coTasters.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.people_alt, size: 13, color: Color(0xFFD4AF37)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Avec : ${entry.coTasters.join(", ")}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Food pairing (Accord mets)
                                    if (entry.foodPaired != null && entry.foodPaired!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.restaurant_menu, size: 14, color: Color(0xFF8B1E3F)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Accord : ${entry.foodPaired!}',
                                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // Occasion
                                    if (entry.occasion != null && entry.occasion!.isNotEmpty && !entry.isExternal) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Occasion : ${entry.occasion}',
                                        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                      ),
                                    ],

                                    // Tasting notes
                                    if (entry.tastingNotes != null && entry.tastingNotes!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          entry.tastingNotes!,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 10),

                                    // Bottom Row: Voir fiche complète & Questionnaire
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(0xFF8B1E3F),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                          ),
                                          icon: const Icon(Icons.wine_bar_outlined, size: 16),
                                          label: const Text('Fiche & Carte du Vin ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => TastingEntryDetailScreen(entry: entry),
                                              ),
                                            );
                                          },
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.grey.shade700,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.quiz_outlined, size: 15),
                                          label: const Text('Quiz sommelier', style: TextStyle(fontSize: 11)),
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
                        },
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
}
