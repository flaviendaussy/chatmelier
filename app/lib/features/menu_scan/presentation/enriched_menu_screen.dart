import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/currency_helper.dart';
import '../../auth/presentation/taste_profiles_dialog.dart';
import '../domain/menu_wine.dart';
import '../domain/cellar_bridge.dart';
import '../data/cellar_context_provider.dart';
import '../data/recent_menus_store.dart';
import 'menu_chat_assistant_sheet.dart';
import 'menu_matchmaker_sheet.dart';
import 'menu_photo_capture_screen.dart';
import 'menu_wine_compare_sheet.dart';
import 'menu_table_consensus_sheet.dart';
import 'menu_flight_sheet.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../sommelier/domain/taste_frontier_engine.dart';
import '../../../shared/utils/langue.dart';

/// L'écran de résultat ouvert sans carte (lien direct, historique du navigateur, app
/// restaurée sans son état) : on rouvre la dernière carte scannée, ou on propose d'en
/// scanner une. Jamais d'écran rouge.
class DerniereCarteOuScan extends ConsumerWidget {
  const DerniereCarteOuScan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentes = ref.watch(recentMenusProvider);
    return recentes.when(
      data: (menus) => menus.isNotEmpty
          ? EnrichedMenuScreen(menu: menus.first)
          : const MenuPhotoCaptureScreen(),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const MenuPhotoCaptureScreen(),
    );
  }
}

class EnrichedMenuScreen extends ConsumerStatefulWidget {
  final ScannedMenu menu;

  const EnrichedMenuScreen({super.key, required this.menu});

  @override
  ConsumerState<EnrichedMenuScreen> createState() => _EnrichedMenuScreenState();
}

class _EnrichedMenuScreenState extends ConsumerState<EnrichedMenuScreen> {
  late ScannedMenu _menu;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedColor = 'all'; // 'all', 'red', 'white', 'rose', 'sparkling'
  String? _selectedTag; // e.g. 'minéral', 'beurré', 'tannique', etc.
  /// Plafond de prix. Existait déjà dans le filtrage — et n'avait aucune interface : il
  /// n'était jamais écrit, seulement remis à zéro. Un filtre budget sur une carte de
  /// restaurant est pourtant le premier geste de beaucoup de gens.
  double? _maxPrice;

  /// Le drapeau du sommelier retenu, s'il y en a un.
  ///
  /// Un seul interrupteur « Pépites & Bons plans » fusionnait les deux, ce qui est
  /// exactement à l'envers du besoin : une pépite est une cuvée rare qu'on accepte de
  /// payer, un bon plan une bouteille au prix juste. Qui cherche l'une ne cherche pas
  /// l'autre.
  MenuWineFlagType? _filtreDrapeau;

  /// Ne montrer que les vins que la cave ou le journal reconnaissent.
  bool _seulementConnus = false;
  bool _isCompactView = true; // High density compact mode for viewing many wines simultaneously
  final Set<String> _selectedWineIds = {};

  final List<String> _sensoryFilters = [
    'minéral',
    'beurré',
    'tannique',
    'fruité',
    'léger',
    'puissant',
    'boisé',
    'rond',
    'frais',
  ];

  @override
  void initState() {
    super.initState();
    _menu = widget.menu;
    _loadViewPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // La suggestion « pour mieux vous connaître » vient APRÈS le croisement avec la cave :
      // elle écarte les vins qu'on a chez soi ou déjà goûtés (01/10 : elle proposait le
      // Clio, à 85 £, à quelqu'un qui en a une bouteille en cave).
      await _croiserAvecMaCave();
      _chercherLaFrontiere();
    });
    // Conserver la carte dès son ouverture, et non à la sortie : on quitte cet écran de
    // mille façons — retour, appel entrant, app tuée — et une seule d'entre elles serait
    // passée par un `dispose`.
    ref.read(recentMenusProvider.notifier).retenir(widget.menu).catchError((_) {});
  }

  /// Annote la carte avec ce que la cave et le journal savent.
  ///
  /// Après le premier rendu, et sans bloquer : la carte doit s'afficher tout de suite,
  /// les annotations arrivent quand elles peuvent. Si la cave est illisible — hors ligne,
  /// aucune cave choisie — la carte reste une carte utilisable.
  /// Le vin de la carte qui apprendrait le plus sur votre palais (moteur de frontière,
  /// S4) — parmi ceux qui ont des chances de vous plaire. Rien sans profil.
  SuggestionDeFrontiere<MenuWine>? _frontiere;

  Future<void> _chercherLaFrontiere() async {
    try {
      final profils = await ref.read(tasteProfilesListProvider.future);
      if (profils.isEmpty || !mounted) return;
      final principal = profils.firstWhere((p) => p.isPrimary, orElse: () => profils.first);
      final s = TasteFrontierEngine.choisir<MenuWine>(
        TasteFrontierEngine.candidatsDeLaCarte(_menu.wines),
        principal,
        profilDe: ProfilDeVin.depuisLaCarte,
        plaisir: (w) => w.userMatchScore,
        prix: (w) => w.bottlePrice,
      );
      if (mounted) setState(() => _frontiere = s);
    } catch (_) {
      // Invité sans profil, hors ligne : la carte reste une carte.
    }
  }

  Widget _carteDeFrontiere(SuggestionDeFrontiere<MenuWine> f, bool isFr, bool isDark) {
    final vin = f.vin;
    final nom = '${vin.name}${vin.vintage != null ? ' ${vin.vintage}' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1F2530) : const Color(0xFFEFF4FA),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            _searchCtrl.text = vin.name;
            _searchQuery = vin.name;
          }),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trSi(isFr, '🧭 Pour mieux vous connaître', '🧭 To get to know you better'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 6),
                Text(
                  TasteFrontierEngine.phrase(f, trSi(isFr, 'Ce {nom}', 'This {nom}', {'nom': nom}), isFr),
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _croiserAvecMaCave() async {
    try {
      final contexte = await ref.read(cellarContextProvider.future);
      if (!mounted || contexte.estVide) return;
      setState(() {
        _menu = _menu.copie(wines: CellarBridgeEngine.lier(_menu.wines, contexte, isFr: _estFr));
      });
    } catch (_) {}
  }

  Future<void> _loadViewPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool('menu_scan_compact_view');
      if (val != null && mounted) {
        setState(() => _isCompactView = val);
      }
    } catch (_) {}
  }

  Future<void> _toggleViewMode() async {
    final next = !_isCompactView;
    setState(() => _isCompactView = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('menu_scan_compact_view', next);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Une puce de filtre pour un drapeau, rendue seulement si la carte en porte.
  List<Widget> _puceDeDrapeau(
      MenuWineFlagType type, String emoji, String libelle, bool isDark) {
    final n = _menu.wines.where((w) => w.flag?.type == type).length;
    if (n == 0) return const [];
    final actif = _filtreDrapeau == type;
    return [
      FilterChip(
        avatar: Text(emoji, style: const TextStyle(fontSize: 13)),
        label: Text('$libelle ($n)',
            style: TextStyle(
              fontWeight: actif ? FontWeight.bold : FontWeight.w600,
              color: actif ? const Color(0xFFD4AF37) : null,
            )),
        selected: actif,
        selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.22),
        checkmarkColor: const Color(0xFFD4AF37),
        side: BorderSide(
          color: actif
              ? const Color(0xFFD4AF37)
              : (isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        onSelected: (val) => setState(() => _filtreDrapeau = val ? type : null),
      ),
      const SizedBox(width: 8),
    ];
  }

  /// « Ce que je connais déjà » : le filtre que seul ce produit peut offrir.
  /// Un vin qu'on CONNAÎT : déjà goûté, ou dans sa cave. « Comblerait un manque » est
  /// l'inverse — un vin qu'on ne connaît pas — et la puce « Vous connaissez (2) » les
  /// comptait (The Kitchin, 29/09 : deux vins, tous deux « comblerait un manque »).
  static bool _estConnu(MenuWine w) =>
      w.pontDeCave?.type == TypeDeLien.dejaGoute || w.pontDeCave?.type == TypeDeLien.enCave;

  List<Widget> _puceDesConnus(bool isFr, bool isDark) {
    final n = _menu.wines.where(_estConnu).length;
    if (n == 0) return const [];
    return [
      FilterChip(
        avatar: const Text('📓', style: TextStyle(fontSize: 13)),
        label: Text(trSi(isFr, 'Vous connaissez ({n})', 'You know ({n})', {'n': n}),
            style: TextStyle(
              fontWeight: _seulementConnus ? FontWeight.bold : FontWeight.w600,
              color: _seulementConnus ? const Color(0xFF6A4C93) : null,
            )),
        selected: _seulementConnus,
        selectedColor: const Color(0xFF6A4C93).withValues(alpha: 0.22),
        checkmarkColor: const Color(0xFF6A4C93),
        side: BorderSide(
          color: _seulementConnus
              ? const Color(0xFF6A4C93)
              : (isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        onSelected: (val) => setState(() => _seulementConnus = val),
      ),
      const SizedBox(width: 8),
    ];
  }

  /// Trois plafonds de prix, tirés de la carte elle-même.
  ///
  /// Des seuils fixes (20/50/100 €) seraient absurdes sur une carte de bistrot comme sur
  /// une carte étoilée. Les quartiles des prix réellement présents découpent toujours la
  /// carte en trois tiers qui veulent dire quelque chose ici.
  List<double> get _plafondsDePrix {
    final prix = _menu.wines
        .map((w) => w.bottlePrice ?? w.primaryGlassPrice)
        .whereType<double>()
        .where((p) => p > 0)
        .toList()
      ..sort();
    if (prix.length < 6) return const [];
    double quantile(double q) => prix[(prix.length * q).floor().clamp(0, prix.length - 1)];
    final seuils = <double>[];
    for (final q in const [0.33, 0.66]) {
      final v = (quantile(q) / 5).ceil() * 5.0;
      if (v > 0 && !seuils.contains(v)) seuils.add(v);
    }
    return seuils;
  }

  List<MenuWine> _filterWines() {
    return _menu.wines.where((wine) {
      // 0. Drapeau du sommelier, par nature
      if (_filtreDrapeau != null && wine.flag?.type != _filtreDrapeau) {
        return false;
      }

      // 0 bis. Ce que je connais déjà
      if (_seulementConnus && !_estConnu(wine)) {
        return false;
      }

      // 1. Text Search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final match = wine.name.toLowerCase().contains(query) ||
            wine.producer.toLowerCase().contains(query) ||
            (wine.appellation?.toLowerCase().contains(query) ?? false) ||
            (wine.region?.toLowerCase().contains(query) ?? false) ||
            wine.grapes.any((g) => g.toLowerCase().contains(query));
        if (!match) return false;
      }

      // 2. Color filter
      if (_selectedColor != 'all') {
        if (_selectedColor == 'red' && !wine.isRed) return false;
        if (_selectedColor == 'white' && !wine.isWhite) return false;
        if (_selectedColor == 'rose' && !wine.isRose) return false;
        if (_selectedColor == 'sparkling' && !wine.isSparkling) return false;
      }

      // 3. Sensory tag filter
      if (_selectedTag != null && _selectedTag!.isNotEmpty) {
        if (!wine.tags.contains(_selectedTag!.toLowerCase())) {
          return false;
        }
      }

      // 4. Max Price filter
      if (_maxPrice != null) {
        final effectivePrice = wine.bottlePrice ?? wine.primaryGlassPrice ?? 999.0;
        if (effectivePrice > _maxPrice!) return false;
      }

      return true;
    }).toList();
  }

  void _editRestaurantName() {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final nameCtrl = TextEditingController(text: _menu.restaurantName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trSi(isFr, 'Nom de l\'établissement', 'Venue Name')),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(labelText: trSi(isFr, 'Restaurant / Bar', 'Restaurant / Bar')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(trSi(isFr, 'Annuler', 'Cancel'))),
          FilledButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _menu = _menu.copie(restaurantName: newName);
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(trSi(isFr, 'Valider', 'Save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredWines = _filterWines();

    final redCount = _menu.wines.where((w) => w.isRed).length;
    final whiteCount = _menu.wines.where((w) => w.isWhite).length;
    final sparklingCount = _menu.wines.where((w) => w.isSparkling).length;
    // Les rosés manquaient au décompte : « 7 références · 2 blancs • 3 rouges • 1 bulles »
    // (The Kitchin, 29/09) laissait un vin introuvable.
    final roseCount = _menu.wines.where((w) => w.isRose && !w.isSparkling).length;
    // Chaque langue accorde elle-même : « 1 Blanc », « 3 Blancs ».
    String compte(int n, Phrase un, Phrase plusieurs) => (n > 1 ? plusieurs : un).dans(isFr).replaceFirst('{n}', '$n');
    final decompte = [
      if (whiteCount > 0) compte(whiteCount, const Phrase('{n} Blanc', '{n} White'), const Phrase('{n} Blancs', '{n} Whites')),
      if (redCount > 0) compte(redCount, const Phrase('{n} Rouge', '{n} Red'), const Phrase('{n} Rouges', '{n} Reds')),
      if (roseCount > 0) compte(roseCount, const Phrase('{n} Rosé', '{n} Rosé'), const Phrase('{n} Rosés', '{n} Rosés')),
      if (sparklingCount > 0) compte(sparklingCount, const Phrase('{n} Effervescent', '{n} Sparkling'), const Phrase('{n} Effervescents', '{n} Sparkling')),
    ].join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _editRestaurantName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _menu.restaurantName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 16, color: Colors.grey),
            ],
          ),
        ),
        // Rien d'autre dans la barre : « on montre deux fois la même chose, enlevons celle
        // du haut » (Flavien, 01/10). Le bouton « Compact » y doublait celui du bandeau
        // juste dessous, et les raccourcis En groupe, Flight et Chat les grandes cartes
        // de l'écran.
      ),
      body: Column(
        children: [
          // Une page illisible ne doit pas passer pour une carte complète.
          if (_menu.pagesNonLues > 0)
            MaterialBanner(
              backgroundColor: isDark ? const Color(0xFF3A2A12) : Colors.orange.shade50,
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              content: Text(
                _menu.pagesNonLues == 1
                    ? trSi(isFr, 'Une page n\'a pas pu être lue : la carte ci-dessous est incomplète. Reprenez-la en photo pour l\'ajouter.',
                        'One page could not be read: this list is incomplete. Take the photo again to add it.')
                    : trSi(isFr, '{n} pages n\'ont pas pu être lues : la carte ci-dessous est incomplète. Reprenez-les en photo pour les ajouter.',
                        '{n} pages could not be read: this list is incomplete. Take the photos again to add them.', {'n': _menu.pagesNonLues}),
                style: const TextStyle(fontSize: 12.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pushReplacement('/scan/menu'),
                  child: Text(trSi(isFr, 'Reprendre', 'Retake')),
                ),
              ],
            ),
          // 1. Stats & Breakdown Banner with Compact Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1E1925) : Colors.amber.shade50.withValues(alpha: 0.6),
            child: Row(
              children: [
                const Icon(Icons.menu_book, size: 18, color: Color(0xFF8B1E3F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trSi(isFr, '{wines_length} références détectées', '{wines_length} references detected', {'wines_length': _menu.wines.length}),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        decompte,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      // Salon d'aéroport, avion, formule : une carte sans aucun prix se
                      // choisit au goût, et l'écran le dit une fois plutôt que sous chaque vin.
                      if (_menu.sansPrix)
                        Text(
                          tr('Carte sans prix : on choisit au goût.', 'No prices on this list: choose by taste.'),
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _toggleViewMode,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white70,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isCompactView ? Icons.view_headline_rounded : Icons.view_agenda_outlined,
                          size: 14,
                          color: const Color(0xFF8B1E3F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isCompactView ? (trSi(isFr, 'Compact', 'Compact')) : (trSi(isFr, 'Détaillé', 'Detailed')),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B1E3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 1b. Prominent Interactive "Chat with the Menu" Hero Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1E3F), Color(0xFF530E26)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => MenuChatAssistantSheet.show(context, _menu),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFDF73), Color(0xFFD4AF37)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF5B0E2D), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  trSi(isFr, 'Discuter avec la Carte', 'Chat with the Wine List'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    trSi(isFr, 'IA SOMMELIER', 'AI SOMMELIER'),
                                    style: const TextStyle(
                                      color: Color(0xFF5B0E2D),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              trSi(isFr, 'Posez vos questions : accords mets & vins, conseils en direct...', 'Ask questions: food & wine pairings, live sommelier advice...'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD4AF37), size: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 1c. High Visibility Hero Actions: "Choose as a group" & "Flight Sommelier"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Card 1: Choisir en groupe 👥
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => MenuTableConsensusSheet.show(context, menu: _menu),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF33163A), Color(0xFF1E0B24)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B1E3F).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.groups_rounded, color: Color(0xFF33163A), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    trSi(isFr, 'Choisir en groupe 👥', 'Choose as a group 👥'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    trSi(isFr, 'Consensus multi-palais', 'Multi-palate consensus'),
                                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Card 2: Mode Flight Dégustation ✈️
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => MenuFlightSheet.show(context, menu: _menu),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1F3B), Color(0xFF0F1024)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.6), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Color(0xFFBA68C8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF1E1F3B), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    trSi(isFr, 'Flight Sommelier 🍷', 'Wine Flight 🍷'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    trSi(isFr, '3 ou 5 verres en ordre', '3 or 5 glasses in order'),
                                    style: const TextStyle(color: Color(0xFFCE93D8), fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: trSi(isFr, 'Rechercher un vin, domaine, cépage, appellation...', 'Search wine, estate, grape, appellation...'),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // 3. Color Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Une puce par nature de drapeau, et seulement si la carte en contient.
                // Un menu sans bonne affaire n'affiche pas de puce « Bons plans » : mieux
                // vaut un filtre de moins qu'un filtre qui ne filtre rien.
                ..._puceDeDrapeau(MenuWineFlagType.deal, '💎',
                    trSi(isFr, 'Bons plans', 'Deals'), isDark),
                ..._puceDeDrapeau(MenuWineFlagType.gem, '✨',
                    trSi(isFr, 'Pépites', 'Gems'), isDark),
                ..._puceDeDrapeau(MenuWineFlagType.tasteMatch, '🎯',
                    trSi(isFr, 'Pour vous', 'For you'), isDark),
                ..._puceDesConnus(isFr, isDark),
                // Le budget, enfin atteignable. Les seuils viennent de la carte.
                for (final plafond in _plafondsDePrix) ...[
                  FilterChip(
                    label: Text(
                      '≤ ${_prix(plafond.roundToDouble())}',
                      style: TextStyle(
                        fontWeight: _maxPrice == plafond
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _maxPrice == plafond
                            ? const Color(0xFF2E7D32)
                            : null,
                      ),
                    ),
                    selected: _maxPrice == plafond,
                    selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.18),
                    checkmarkColor: const Color(0xFF2E7D32),
                    side: BorderSide(
                      color: _maxPrice == plafond
                          ? const Color(0xFF2E7D32)
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    onSelected: (val) =>
                        setState(() => _maxPrice = val ? plafond : null),
                  ),
                  const SizedBox(width: 8),
                ],
                ChoiceChip(
                  label: Text(trSi(isFr, 'Tous', 'All')),
                  selected: _selectedColor == 'all',
                  onSelected: (_) => setState(() => _selectedColor = 'all'),
                ),
                if (!(_selectedTag == 'beurré' || _selectedTag == 'beurre')) ...[
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.circle, size: 12, color: Color(0xFF8B1E3F)),
                    label: Text(trSi(isFr, 'Rouges ({redCount})', 'Reds ({redCount})', {'redCount': redCount})),
                    selected: _selectedColor == 'red',
                    onSelected: (_) => setState(() {
                      _selectedColor = 'red';
                      if (_selectedTag == 'beurré' || _selectedTag == 'beurre') {
                        _selectedTag = null;
                      }
                    }),
                  ),
                ],
                if (_selectedTag != 'tannique') ...[
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.circle, size: 12, color: Color(0xFFE8D08D)),
                    label: Text(trSi(isFr, 'Blancs ({whiteCount})', 'Whites ({whiteCount})', {'whiteCount': whiteCount})),
                    selected: _selectedColor == 'white',
                    onSelected: (_) => setState(() {
                      _selectedColor = 'white';
                      if (_selectedTag == 'tannique') {
                        _selectedTag = null;
                      }
                    }),
                  ),
                  if (roseCount > 0 && !(_selectedTag == 'beurré' || _selectedTag == 'beurre')) ...[
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: const Icon(Icons.circle, size: 12, color: Color(0xFFE8A0A8)),
                      label: Text('Rosés ($roseCount)'),
                      selected: _selectedColor == 'rose',
                      onSelected: (_) => setState(() => _selectedColor = 'rose'),
                    ),
                  ],
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.circle, size: 12, color: Color(0xFFD4AF37)),
                    label: Text(trSi(isFr, 'Bulles ({sparklingCount})', 'Sparkling ({sparklingCount})', {'sparklingCount': sparklingCount})),
                    selected: _selectedColor == 'sparkling',
                    onSelected: (_) => setState(() {
                      _selectedColor = 'sparkling';
                      if (_selectedTag == 'tannique') {
                        _selectedTag = null;
                      }
                    }),
                  ),
                ],
              ],
            ),
          ),

          // 4. Sensory Tags Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  trSi(isFr, 'Profil : ', 'Profile: '),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                ..._sensoryFilters.where((tag) {
                  if (_selectedColor == 'red' && (tag == 'beurré' || tag == 'beurre')) return false;
                  if ((_selectedColor == 'white' || _selectedColor == 'sparkling') && tag == 'tannique') return false;
                  return true;
                }).map((tag) {
                  final isSelected = _selectedTag == tag;
                  final localizedLabel = switch (tag) {
                    'minéral' => trSi(isFr, 'Minéral', 'Mineral'),
                    'beurré' => trSi(isFr, 'Beurré', 'Buttery'),
                    'tannique' => trSi(isFr, 'Tannique', 'Tannic'),
                    'fruité' => trSi(isFr, 'Fruité', 'Fruity'),
                    'léger' => trSi(isFr, 'Léger', 'Light'),
                    'puissant' => trSi(isFr, 'Puissant', 'Bold'),
                    'boisé' => trSi(isFr, 'Boisé', 'Oaked'),
                    _ => tag[0].toUpperCase() + tag.substring(1),
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(localizedLabel),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                      onSelected: (val) {
                        setState(() {
                          _selectedTag = val ? tag : null;
                          if (val && (tag == 'beurré' || tag == 'beurre') && _selectedColor == 'red') {
                            _selectedColor = 'white';
                          } else if (val && tag == 'tannique' && (_selectedColor == 'white' || _selectedColor == 'sparkling')) {
                            _selectedColor = 'red';
                          }
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // 5. Wine List
          Expanded(
            child: filteredWines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          trSi(isFr, 'Aucun vin ne correspond à vos filtres', 'No wines match your filters'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filtreDrapeau = null;
                              _seulementConnus = false;
                              _selectedColor = 'all';
                              _selectedTag = null;
                              _maxPrice = null;
                              _searchCtrl.clear();
                              _searchQuery = '';
                            });
                          },
                          child: Text(trSi(isFr, 'Réinitialiser les filtres', 'Reset filters')),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      _isCompactView ? 12 : 16,
                      _isCompactView ? 6 : 10,
                      _isCompactView ? 12 : 16,
                      90,
                    ),
                    itemCount: filteredWines.length + (_frontiere != null && _searchQuery.isEmpty ? 1 : 0),
                    itemBuilder: (context, i) {
                      final avecFrontiere = _frontiere != null && _searchQuery.isEmpty;
                      if (avecFrontiere && i == 0) return _carteDeFrontiere(_frontiere!, isFr, isDark);
                      final index = avecFrontiere ? i - 1 : i;
                      final wine = filteredWines[index];
                      final isSelected = _selectedWineIds.contains(wine.id);

                      if (_isCompactView) {
                        return _buildCompactWineCard(context, wine, isDark, isSelected);
                      }
                      return _buildDetailedWineCard(context, wine, isDark, isSelected);
                    },
                  ),
          ),
        ],
      ),

      // Floating Action Bar: Compare / Matchmaker / Sommelier Chat
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chat Sommelier Button
            Expanded(
              flex: 4,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: () => MenuChatAssistantSheet.show(context, _menu),
                icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFFD4AF37)),
                label: Text(
                  trSi(isFr, 'Chat Menu', 'Chat Menu'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Compare Button (active when >= 2 selected)
            Expanded(
              flex: 4,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedWineIds.length >= 2
                      ? const Color(0xFF530E26)
                      : Colors.grey.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _selectedWineIds.length >= 2
                    ? () {
                        final selected =
                            _menu.wines.where((w) => _selectedWineIds.contains(w.id)).toList();
                        MenuWineCompareSheet.show(context, selected);
                      }
                    : null,
                icon: const Icon(Icons.radar, size: 16),
                label: Text(
                  _selectedWineIds.length >= 2
                      ? (trSi(isFr, 'Comparer ({selectedWineIds_length})', 'Compare ({selectedWineIds_length})', {'selectedWineIds_length': _selectedWineIds.length}))
                      : (trSi(isFr, 'Comparer', 'Compare')),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Matchmaker Button
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final pool = filteredWines.isNotEmpty ? filteredWines : _menu.wines;
                  MenuMatchmakerSheet.show(context, pool);
                },
                icon: const Icon(Icons.style_outlined, size: 16, color: Color(0xFFD4AF37)),
                label: const Text(
                  'Matchmaker',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact Wine Card: Optimized for high density (6-8+ wines visible simultaneously)
  bool get _estFr => Localizations.localeOf(context).languageCode == 'fr';

  /// Un prix de la carte, dans sa devise ; à défaut — carte sans symbole — dans celle de
  /// la langue du téléphone. Les cartes de vin prenaient toujours la seconde : « $42 » sur
  /// une carte d'Édimbourg, lue par un téléphone réglé en anglais américain (29/09).
  String _prix(double v) => CurrencyHelper.formatPrice(v,
      currency: _menu.currency ?? CurrencyHelper.getCurrencyForLocale(Localizations.localeOf(context)),
      decimals: v % 1 == 0 ? 0 : 2);

  Widget _buildCompactWineCard(
    BuildContext context,
    MenuWine wine,
    bool isDark,
    bool isSelected,
  ) {
    final effectiveBottlePrice = wine.bottlePrice;
    final effectiveGlassPrice = wine.glassPrices.isNotEmpty ? wine.glassPrices.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF231D2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFF8B1E3F)
              : (wine.flag != null
                  ? wine.flag!.color.withValues(alpha: 0.45)
                  : (isDark ? Colors.white10 : Colors.grey.shade200)),
          width: isSelected ? 1.8 : (wine.flag != null ? 1.2 : 1.0),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedWineIds.remove(wine.id);
            } else {
              _selectedWineIds.add(wine.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Line 1: Compact Checkbox, Color Dot, Name, Inline Flag, Bottle/Glass Price
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: const Color(0xFF8B1E3F),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedWineIds.add(wine.id);
                          } else {
                            _selectedWineIds.remove(wine.id);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: wine.colorIndicator,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            wine.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (wine.flag != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: wine.flag!.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: wine.flag!.color.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(wine.flag!.iconEmoji, style: const TextStyle(fontSize: 10.5)),
                                const SizedBox(width: 3),
                                Text(
                                  wine.flag!.libelle(_estFr),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: wine.flag!.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (effectiveBottlePrice != null)
                    Text(
                      _prix(effectiveBottlePrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF8B1E3F),
                      ),
                    )
                  else if (effectiveGlassPrice != null)
                    Text(
                      '${_prix(effectiveGlassPrice.price)}/${trSi(_estFr, 'v', 'glass')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF8B1E3F),
                      ),
                    ),
                ],
              ),

              // Ce que VOTRE cave et VOTRE journal disent de ce vin.
              //
              // Sur sa propre ligne, et non fondu dans le badge du sommelier : « le
              // sommelier remarque » et « vous savez déjà » répondent à deux questions
              // différentes, et la seconde vaut souvent plus que la première.
              if (wine.pontDeCave != null)
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wine.pontDeCave!.emoji,
                          style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 11, height: 1.25),
                            children: [
                              TextSpan(
                                text: wine.pontDeCave!.libelle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6A4C93),
                                ),
                              ),
                              if (wine.pontDeCave!.detail != null)
                                TextSpan(
                                  text: ' — ${wine.pontDeCave!.detail}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Line 2: Origin & Producer + Glass Price / Match score
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${wine.producer.isNotEmpty ? "${wine.producer} • " : ""}'
                        '${wine.vintage != null ? wine.vintage.toString() : (trSi(_estFr, 'NM', 'NV'))}'
                        '${wine.countryWithFlag.isNotEmpty ? " • ${wine.countryWithFlag}" : ""}'
                        '${wine.appellation != null ? " • ${wine.appellation}" : (wine.region != null ? " • ${wine.region}" : "")}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (effectiveBottlePrice != null && effectiveGlassPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${_prix(effectiveGlassPrice.price)}/${trSi(_estFr, 'v', 'glass')}',
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ],
                    if (wine.userMatchScore != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${wine.userMatchScore!.round()}% Match',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Line 3: Compact chips & sommelier quote snippet (if present)
              if (wine.tags.isNotEmpty ||
                  (wine.isRed && wine.metrics.tannins > 0) ||
                  (wine.isWhite && wine.metrics.minerality > 0) ||
                  (wine.sommelierComment != null && wine.sommelierComment!.isNotEmpty)) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 3),
                  child: Row(
                    children: [
                      if (wine.isRed && wine.metrics.tannins > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildCompactMetricPill(
                            '${trSi(Localizations.localeOf(context).languageCode == 'fr', 'Tanins', 'Tannins')} ${wine.metrics.tannins.toStringAsFixed(1)}',
                            const Color(0xFF8B1E3F),
                          ),
                        ),
                      if (wine.isWhite && wine.metrics.minerality > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildCompactMetricPill(
                            '${trSi(Localizations.localeOf(context).languageCode == 'fr', 'Minéralité', 'Minerality')} ${wine.metrics.minerality.toStringAsFixed(1)}',
                            const Color(0xFF00897B),
                          ),
                        ),
                      ...wine.tags.take(2).map((t) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _buildCompactTagPill(t, isDark),
                          )),
                      if (wine.sommelierComment != null && wine.sommelierComment!.isNotEmpty)
                        Expanded(
                          child: Tooltip(
                            message: wine.sommelierComment!,
                            child: Text(
                              '« ${wine.sommelierComment} »',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Detailed Wine Card: Generous spacing with full radar pills, sommelier flags and notes
  Widget _buildDetailedWineCard(
    BuildContext context,
    MenuWine wine,
    bool isDark,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF231D2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFF8B1E3F)
              : (wine.flag != null
                  ? wine.flag!.color.withValues(alpha: 0.45)
                  : (isDark ? Colors.white10 : Colors.grey.shade200)),
          width: isSelected ? 2.0 : (wine.flag != null ? 1.5 : 1.0),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedWineIds.remove(wine.id);
            } else {
              _selectedWineIds.add(wine.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wine.flag != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: wine.flag!.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: wine.flag!.color.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(wine.flag!.iconEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        wine.flag!.libelle(_estFr),
                        style: TextStyle(
                          color: wine.flag!.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      if (wine.flag!.raisonAffichee(_estFr) != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• ${wine.flag!.raisonAffichee(_estFr)!}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFF8B1E3F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedWineIds.add(wine.id);
                        } else {
                          _selectedWineIds.remove(wine.id);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: wine.colorIndicator,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                wine.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${wine.producer} • ${wine.vintage != null ? wine.vintage.toString() : (trSi(_estFr, 'NM', 'NV'))}'
                          '${wine.countryWithFlag.isNotEmpty ? " • ${wine.countryWithFlag}" : ""}'
                          '${wine.appellation != null ? " • ${wine.appellation}" : (wine.region != null ? " • ${wine.region}" : "")}',
                          style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (wine.bottlePrice != null)
                        Text(
                          _prix(wine.bottlePrice!),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF8B1E3F),
                          ),
                        ),
                      if (wine.glassPrices.isNotEmpty)
                        Text(
                          wine.glassPrices
                              .map((g) => '${_prix(g.price)}/${g.format}')
                              .join(' • '),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Sensory Tags & Match Score Pill
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (wine.isRed && wine.metrics.tannins > 0)
                          _buildMetricPill(
                            '${trSi(Localizations.localeOf(context).languageCode == 'fr', 'Tanins', 'Tannins')} ${wine.metrics.tannins.toStringAsFixed(1)}/10',
                            const Color(0xFF8B1E3F),
                          ),
                        if (wine.isWhite && wine.metrics.minerality > 0)
                          _buildMetricPill(
                            '${trSi(Localizations.localeOf(context).languageCode == 'fr', 'Minéralité', 'Minerality')} ${wine.metrics.minerality.toStringAsFixed(1)}/10',
                            const Color(0xFF00897B),
                          ),
                        ...wine.tags.take(3).map((t) => _buildTagPill(t, isDark)),
                      ],
                    ),
                  ),
                  if (wine.userMatchScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite, size: 12, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 4),
                          Text(
                            '${wine.userMatchScore!.round()}% Match',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => TasteProfilesDialog.show(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.shade700.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 12, color: Colors.amber.shade900),
                            const SizedBox(width: 4),
                            Text(
                              Localizations.localeOf(context).languageCode == 'fr'
                                  ? 'Profil à compléter'
                                  : 'Complete profile',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              if (wine.sommelierComment != null && wine.sommelierComment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '« ${wine.sommelierComment} »',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMetricPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildCompactTagPill(String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 9.5,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTagPill(String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}
