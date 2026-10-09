import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/utils/responsive_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../data/tasting_deletion_service.dart';
import '../domain/tasting_entry.dart';
import '../../auth/data/taste_profile_service.dart';
import 'external_tasting_dialog.dart';
import 'tasting_questionnaire_sheet.dart';
import 'tasting_entry_detail_screen.dart';
import '../../cellar/data/favorite_wines_service.dart';

import '../../../features/offline/domain/offline_action.dart';
import '../../../features/offline/presentation/sync_provider.dart';
import '../../offline/data/offline_storage_service.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/widgets/onglets.dart';

final tastingLogProvider = FutureProvider<List<TastingEntry>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final offlineStorage = ref.watch(offlineStorageServiceProvider);
  final user = supabase.auth.currentUser;

  final List<TastingEntry> entries = [];

  // 1. Load from local cache first for instantaneous and reliable offline access
  final cached = offlineStorage.getCachedTastings();
  for (final raw in cached) {
    try {
      entries.add(TastingEntry.fromJson(raw));
    } catch (_) {}
  }

  // 2. Fetch from Supabase if online and update cache
  if (user != null) {
    try {
      final res = await supabase
          .from('tasting_log')
          .select('*, wines(*)')
          .order('consumed_at', ascending: false)
          .timeout(const Duration(seconds: 5));

      final remoteMaps = (res as List<dynamic>)
          .map((j) => Map<String, dynamic>.from(j as Map))
          .toList();

      if (remoteMaps.isNotEmpty) {
        // Fusionner le serveur avec les dégustations encore en attente de synchronisation.
        //
        // Une entrée du cache absente du serveur peut signifier deux choses opposées :
        // « pas encore partie » ou « supprimée ailleurs ». L'ancienne version supposait
        // toujours la première, si bien qu'une dégustation effacée en base restait
        // affichée indéfiniment — constaté sur appareil. Seul le marqueur tranche.
        //
        // Transition : les entrées mises en cache par une version antérieure n'ont pas le
        // marqueur. On garde celles dont l'identifiant est horodaté plutôt qu'un UUID,
        // preuve qu'elles ont été fabriquées localement et n'ont jamais atteint la base.
        final existingCached = offlineStorage.getCachedTastings();
        final remoteIds = remoteMaps.map((m) => m['id']?.toString()).whereType<String>().toSet();
        final localOnly = existingCached.where((m) {
          final id = m['id']?.toString();
          if (id == null || id.isEmpty || remoteIds.contains(id)) return false;
          if (m[OfflineStorageService.pendingSyncKey] == true) return true;
          return !_looksLikeUuid(id);
        }).toList();

        final mergedMaps = [...remoteMaps, ...localOnly];
        await offlineStorage.saveCachedTastings(mergedMaps);

        entries.clear();
        for (final raw in mergedMaps) {
          try {
            entries.add(TastingEntry.fromJson(raw));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Tasting log remote fetch notice: $e');
    }
  }

  // Fusionner avec les actions hors-ligne de consommation
  final queue = offlineStorage.getQueue();
  for (final action in queue) {
    if (action.type == OfflineActionType.consumeBottle) {
      final data = action.data;
      final wineMap = data['wines'] as Map<String, dynamic>?;
      final wineName = data['wine_name'] as String? ?? data['name'] as String? ?? wineMap?['name'] as String? ?? 'Vin dégusté';
      final vintage = (data['vintage'] as num?)?.toInt() ?? int.tryParse(data['vintage']?.toString() ?? '') ?? (wineMap?['vintage'] as num?)?.toInt();
      final rating = (data['rating'] as num?)?.toDouble();
      final notes = data['tasting_notes'] as String? ?? data['notes'] as String?;
      final paired = data['food_paired'] as String? ?? data['paired'] as String?;
      final photoUrl = data['photo_url'] as String? ?? data['image_url'] as String?;
      final region = data['region'] as String? ?? wineMap?['region'] as String?;
      final country = data['country'] as String? ?? wineMap?['country'] as String?;
      final appellation = data['appellation'] as String? ?? wineMap?['appellation'] as String?;
      final wineType = data['wine_type'] as String? ?? data['type'] as String? ?? wineMap?['wine_type'] as String? ?? wineMap?['type'] as String?;
      final coTasters = (data['co_tasters'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
      final bottleOwnerName = data['bottle_owner_name'] as String?;
      final bottleOwnerId = data['bottle_owner_id'] as String?;
      final locationName = data['location_name'] as String?;
      final isExternal = data['is_external'] == true;
      final rawBottleId = data['bottle_id'] as String?;

      // Éviter les doublons si déjà présent par ID ou par bouteille/timestamp
      final alreadyPresent = entries.any((e) =>
        e.id == action.id ||
        (rawBottleId != null && rawBottleId.isNotEmpty && e.bottleId == rawBottleId && e.consumedAt.difference(action.createdAt).inMinutes.abs() < 5)
      );

      if (!alreadyPresent) {
        entries.insert(0, TastingEntry(
          id: action.id,
          bottleId: rawBottleId,
          wineId: data['wine_id'] as String? ?? '',
          wineName: wineName,
          vintage: vintage,
          region: region,
          country: country,
          appellation: appellation,
          wineType: wineType,
          rating: rating,
          foodPaired: paired,
          tastingNotes: notes,
          photoUrl: photoUrl,
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


/// Un identifiant fabriqué localement est un horodatage, pas un UUID : c'est ce qui permet
/// de reconnaître, parmi les entrées mises en cache avant l'introduction du marqueur de
/// synchronisation, celles qui n'ont jamais atteint la base.
bool _looksLikeUuid(String id) => RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);

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
  bool _onlyFavorites = false;

  /// Balayées, en attente de la fermeture du bandeau « Annuler » (V2.4 · R3).
  final Set<String> _enSuppression = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TastingEntry> _filterEntries(List<TastingEntry> entries, Set<String> favoriteWineIds) {
    return entries.where((entry) {
      // Filter by favorites
      if (_onlyFavorites) {
        final isFav = favoriteWineIds.contains(entry.id) ||
            favoriteWineIds.contains(entry.wineId) ||
            (entry.bottleId != null && favoriteWineIds.contains(entry.bottleId));
        if (!isFav) return false;
      }

      // Filter by origin (Cave vs Hors-cave)
      if (_selectedOriginFilter == 'cellar' && entry.isExternal) return false;
      if (_selectedOriginFilter == 'external' && !entry.isExternal) return false;

      // Filter by year
      if (_selectedYear != null && entry.consumedAt.year.toString() != _selectedYear) {
        return false;
      }

      // Filter by high rating (>= 8/10)
      final effRating = entry.displayRating;
      if (_minRatingOnly && (effRating == null || effRating < 8.0)) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final wineName = (entry.wineName ?? '').toLowerCase();
        final domaine = (entry.producer ?? '').toLowerCase();
        final notes = (entry.tastingNotes ?? '').toLowerCase();
        final food = (entry.foodPaired ?? '').toLowerCase();
        final region = (entry.region ?? '').toLowerCase();
        final country = (entry.country ?? '').toLowerCase();
        final appellation = (entry.appellation ?? '').toLowerCase();
        final loc = (entry.locationName ?? '').toLowerCase();
        final yearStr = entry.consumedAt.year.toString();
        final guests = entry.coTasters.map((g) => g.toLowerCase()).join(' ');

        final matches = wineName.contains(q) ||
            domaine.contains(q) ||
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

  String _formatDate(DateTime dt, [bool isFr = true]) {
    try {
      return DateFormat('d MMMM yyyy', trSi(isFr, 'fr_FR', 'en_US')).format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(tastingLogProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final l10n = AppLocalizations.of(context);
    final favoriteWineIds = ref.watch(favoriteWineIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(trSi(isFr, 'Journal de dégustation', 'Tasting journal')),
        actions: [
          const BoutonSommelier(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B1E3F)),
            tooltip: trSi(isFr, 'Dégustation Hors-Cave (Restaurant, Amis)', 'Out-of-Cellar Tasting (Restaurant, Friends)'),
            onPressed: () => ExternalTastingDialog.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'journal_external_tasting_fab',
        onPressed: () => ExternalTastingDialog.show(context),
        icon: const Icon(Icons.restaurant),
        label: Text(trSi(isFr, 'Déguster Hors-Cave', 'Taste Out-of-Cellar')),
        backgroundColor: const Color(0xFF8B1E3F),
        foregroundColor: Colors.white,
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(trSi(isFr, 'Erreur : {err}', 'Error: {err}', {'err': err})),
          ),
        ),
        data: (toutes) {
          final allEntries = toutes.where((e) => !_enSuppression.contains(e.id)).toList();
          if (allEntries.isEmpty) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  EmptyState(
                    icon: Icons.menu_book,
                    title: l10n?.journalEmpty ?? (trSi(isFr, 'Aucun souvenir de dégustation pour le moment', 'No tasting memories yet')),
                    subtitle: l10n?.journalEmptySub ??
                        (trSi(isFr, 'Dégustez et sortez une bouteille de votre cave, notez un vin bu au restaurant ou scannez une carte.', 'Taste and check out a bottle from your cellar, rate a wine at a restaurant or scan a menu.')),
                    action: FilledButton.icon(
                      icon: const Icon(Icons.restaurant_menu),
                      label: Text(trSi(isFr, 'Noter un vin hors-cave (Restaurant, Amis)', 'Log out-of-cellar wine (Restaurant, Friends)')),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E3F),
                          foregroundColor: Colors.white),
                      onPressed: () => ExternalTastingDialog.show(context),
                    ),
                  ),
                ],
              ),
            );
          }

          // Extract available years for filter
          final availableYears = allEntries
              .map((e) => e.consumedAt.year.toString())
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          final filteredEntries = _filterEntries(allEntries, favoriteWineIds);

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(tastingLogProvider.future),
            child: CustomScrollView(
              slivers: [
                // L'« Espace Dégustation » (scanner une carte, rejoindre une table, rouvrir
                // la dernière carte…) est devenu l'onglet « Ce soir » (V2.3 · E1).
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
                            hintText: trSi(isFr, 'Rechercher : vin, lieu, invité, plat, note, année...', 'Search: wine, place, guest, dish, rating, year...'),
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
                                label: Text(trSi(isFr, 'Tous', 'All')),
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
                                label: Text(trSi(isFr, 'Ma Cave', 'My Cellar')),
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
                                label: Text(trSi(isFr, 'Hors-Cave', 'Out-of-Cellar')),
                                selected: _selectedOriginFilter == 'external',
                                selectedColor:
                                    Colors.orange.withValues(alpha: 0.2),
                                onSelected: (sel) {
                                  setState(() => _selectedOriginFilter =
                                      sel ? 'external' : 'all');
                                },
                              ),
                              const SizedBox(width: 8),

                              // Favorites Filter Chip
                              FilterChip(
                                avatar: const Icon(Icons.favorite,
                                    size: 13, color: Color(0xFFE91E63)),
                                label: Text(trSi(isFr, 'Favoris', 'Favorites')),
                                selected: _onlyFavorites,
                                selectedColor:
                                    const Color(0xFFE91E63).withValues(alpha: 0.2),
                                onSelected: (sel) {
                                  setState(() => _onlyFavorites = sel);
                                },
                              ),
                              const SizedBox(width: 8),

                              // High Rating Filter (>= 8/10)
                              FilterChip(
                                avatar: const Icon(Icons.star,
                                    size: 14, color: Color(0xFFD4AF37)),
                                label: Text(trSi(isFr, 'Coups de Cœur (≥ 8/10)', 'Top Rated (≥ 8/10)')),
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
                                      hint: Text(trSi(isFr, 'Année', 'Year'),
                                          style: const TextStyle(fontSize: 12)),
                                      isDense: true,
                                      items: [
                                        DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text(trSi(isFr, 'Toutes les années', 'All years'),
                                              style: const TextStyle(fontSize: 12)),
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
                              trSi(isFr, 'Aucun souvenir trouvé', 'No memories found'),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              trSi(isFr, 'Aucune dégustation ne correspond aux filtres actuels.', 'No tastings match current filters.'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.filter_alt_off),
                              label: Text(trSi(isFr, 'Réinitialiser les filtres', 'Reset filters')),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedYear = null;
                                  _selectedOriginFilter = 'all';
                                  _minRatingOnly = false;
                                  _onlyFavorites = false;
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
                                isFr,
                                enGrille: true,
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
                                isFr,
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
    bool isFr, {
    bool enGrille = false,
  }) {
    final wineName = entry.wineName ?? (trSi(isFr, 'Vin dégusté', 'Tasted wine'));
    final vintage = entry.vintage != null && entry.vintage! > 0
        ? ' (${entry.vintage})'
        : ' (NV)';
    final dateStr = _formatDate(entry.consumedAt, isFr);

    return Dismissible(
      key: ObjectKey(entry),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trSi(isFr, 'Supprimer', 'Delete'),
              style: TextStyle(color: theme.colorScheme.onError, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline, color: theme.colorScheme.onError),
          ],
        ),
      ),
      onDismissed: (_) => _supprimerAvecAnnulation(entry, isFr),
      child: _carteDeDegustation(context, entry, isDark, theme, isFr, wineName, vintage, dateStr, enGrille),
    );
  }

  /// Balayer une dégustation la supprime, avec « Annuler » (V2.4 · R3 ; Dimitri, 04/10).
  ///
  /// Elle disparaît tout de suite de la liste, mais n'est vraiment supprimée (serveur,
  /// cache, file d'attente, profils de goût) qu'à la fermeture du bandeau sans « Annuler » :
  /// défaire une suppression déjà faite demanderait de rejouer ce qu'elle avait appris au
  /// profil. Un second balayage referme le bandeau précédent, dont la suppression part.
  void _supprimerAvecAnnulation(TastingEntry entry, bool isFr) {
    setState(() => _enSuppression.add(entry.id));
    final service = ref.read(tastingDeletionServiceProvider);
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final messager = ScaffoldMessenger.of(context);
    final nom = entry.wineName ?? trSi(isFr, 'Vin dégusté', 'Tasted wine');
    messager.hideCurrentSnackBar();
    messager
        .showSnackBar(SnackBar(
          content: Text(trSi(isFr, '« {nom} » supprimé du journal.', '"{nom}" removed from your journal.', {'nom': nom})),
          duration: const Duration(seconds: 5),
          // Un bandeau qui porte une action reste affiché sans fin (`persist` vaut alors
          // vrai par défaut) : la suppression ne partirait jamais.
          persist: false,
          action: SnackBarAction(label: trSi(isFr, 'Annuler', 'Undo'), onPressed: () {}),
        ))
        .closed
        .then((raison) async {
      if (raison == SnackBarClosedReason.action) {
        if (mounted) setState(() => _enSuppression.remove(entry.id));
        return;
      }
      final resultat = await service.supprimer(entry.id);
      conteneur.invalidate(tastingLogProvider);
      conteneur.invalidate(tasteProfilesListProvider);
      final message = !resultat.supprimeeEnLigne
          ? trSi(
              isFr,
              'Pas de connexion : « {nom} » reviendra au journal. Supprimez-le à nouveau une fois connecté.',
              'No connection: "{nom}" will come back to your journal. Delete it again once online.',
              {'nom': nom},
            )
          : TastingDeletionService.phraseDesRestes(resultat.restes);
      if (message != null) {
        messager.showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 6)));
      }
    });
  }

  Widget _carteDeDegustation(
    BuildContext context,
    TastingEntry entry,
    bool isDark,
    ThemeData theme,
    bool isFr,
    String wineName,
    String vintage,
    String dateStr,
    bool enGrille,
  ) {
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
                        if (entry.domaineAffiche case final domaine?)
                          Text(
                            domaine,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFE8A0B4) : const Color(0xFF8B1E3F),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
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
                  // Favorite Heart Button
                  FavoriteHeartButton(
                    wineOrBottleId: entry.wineId.isNotEmpty
                        ? entry.wineId
                        : (entry.bottleId ?? entry.id),
                    size: 20,
                    inactiveColor: isDark ? Colors.white38 : Colors.black26,
                  ),
                  const SizedBox(width: 4),
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
                          entry.formattedRating,
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
                      child: Text(trSi(isFr, '🍽️ Hors-Cave', '🍽️ Out-of-Cellar'),
                          style: const TextStyle(
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
                      child: Text(trSi(isFr, '🍷 Cave', '🍷 Cellar'),
                          style: const TextStyle(
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
                        '${trSi(isFr, "Accord", "Pairing")}${deuxPoints(isFr)}${entry.foodPaired}',
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

              // Dans la grille (tablette), la carte a une hauteur fixe et le bas de carte s'y
              // aligne. Dans la liste du téléphone, la hauteur n'est pas bornée : un Spacer y
              // faisait échouer la mise en page, et l'onglet entier restait vide (01/10).
              if (enGrille) const Spacer() else const SizedBox(height: 8),

              // Bottom Actions: Questionnaire Sheet & Detail Link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Souple : en espagnol, ou sur un petit écran, la ligne débordait.
                  Flexible(
                    child: Text(
                      trSi(isFr, 'Fiche complète & arômes', 'Full details & aromas'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.quiz_outlined, size: 15),
                    label: Text(trSi(isFr, 'Quiz sommelier', 'Sommelier quiz'),
                        style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      TastingQuestionnaireSheet.show(
                        context,
                        wineName: entry.wineName ?? (trSi(isFr, 'Vin dégusté', 'Tasted wine')),
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
