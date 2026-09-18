import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import '../domain/menu_wine.dart';
import '../domain/menu_table_matcher_engine.dart';
import '../domain/menu_flight_engine.dart';
import '../data/menu_table_session_manager.dart';

class MenuTableConsensusGuestScreen extends StatefulWidget {
  final String? initialSessionId;
  final String? initialData;

  /// La carte déjà reçue du serveur, quand on est arrivé par un code plutôt que par un QR.
  ///
  /// Elle est complète : le plafond de seize vins ne valait que pour ce qui devait tenir
  /// dans une URL. Une table côté serveur n'a pas cette contrainte.
  final ScannedMenu? prechargedMenu;

  const MenuTableConsensusGuestScreen({
    super.key,
    this.initialSessionId,
    this.initialData,
    this.prechargedMenu,
  });

  @override
  State<MenuTableConsensusGuestScreen> createState() => _MenuTableConsensusGuestScreenState();
}

class _MenuTableConsensusGuestScreenState extends State<MenuTableConsensusGuestScreen> {
  late final TextEditingController _nameCtrl;
  String _selectedArchetype = 'sans_tanin';
  ScannedMenu? _menu;
  final List<GuestProfile> _guests = [];
  List<MenuTableMatchResult> _top3 = [];
  bool _hasJoined = false;

  // Tab 1: Carte des Vins
  final TextEditingController _wineSearchCtrl = TextEditingController();
  String _wineSearchQuery = '';
  String _wineColorFilter = 'all';
  bool _filterGemsOnly = false;

  // Tab 2: Flights
  FlightFormat _selectedFlightFormat = FlightFormat.threeGlasses;
  FlightWineColor _selectedFlightColor = FlightWineColor.mix;

  // Tab 3: Accords Mets
  final TextEditingController _dishSearchCtrl = TextEditingController();
  String _selectedDishCategory = 'viande';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Invité');
    _loadMenu();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wineSearchCtrl.dispose();
    _dishSearchCtrl.dispose();
    super.dispose();
  }

  void _loadMenu() {
    String? sessionId = widget.initialSessionId;
    String? rawData = widget.initialData;

    if (kIsWeb) {
      final baseUri = Uri.base;
      sessionId ??= baseUri.queryParameters['session'] ?? baseUri.queryParameters['s'];
      rawData ??= baseUri.queryParameters['data'] ?? baseUri.queryParameters['d'];

      if ((sessionId == null || rawData == null) && baseUri.hasFragment) {
        try {
          final frag = baseUri.fragment.startsWith('/') ? baseUri.fragment : '/${baseUri.fragment}';
          final fragUri = Uri.parse(frag);
          sessionId ??= fragUri.queryParameters['session'] ?? fragUri.queryParameters['s'];
          rawData ??= fragUri.queryParameters['data'] ?? fragUri.queryParameters['d'];
        } catch (_) {}
      }
    }

    // La carte reçue du serveur prime sur tout : elle est complète et à jour.
    ScannedMenu? resolved = widget.prechargedMenu;
    if (resolved == null && sessionId != null && sessionId.isNotEmpty) {
      resolved = MenuTableSessionManager.getSession(sessionId);
    }
    if (resolved == null && rawData != null && rawData.isNotEmpty) {
      resolved = MenuTableSessionManager.decodeMenuPayload(rawData);
    }

    // PAS DE MENU DE SECOURS.
    //
    // Il y avait ici trois vins inventés — un Chablis, un Graves, un Côtes du Rhône —
    // affichés sous le titre « Menu du Restaurant ». Quand le décodage échouait (ce qui
    // était le cas sur TOUS les navigateurs, `gzip` de dart:io n'existant pas sous
    // dart2js), l'invité voyait donc une carte imaginaire présentée comme celle de
    // l'établissement où il dînait, et pouvait voter pour un vin que le restaurant ne
    // sert pas. « Éviter l'écran blanc » ne justifie pas de mentir sur ce qu'on montre.
    //
    // Un menu nul déclenche l'écran d'erreur, qui dit ce qui s'est passé et propose de
    // rescanner.
    _menu = resolved;



    // Hôte initial par défaut
    _guests.add(const GuestProfile(
      id: 'host_table',
      name: 'Hôte de la table',
      favoriteTypes: ['Rouge', 'Blanc'],
      archetype: 'Curieux & Éclectique',
    ));

    _recalculateConsensus();
  }

  void _recalculateConsensus() {
    if (_menu == null || _menu!.wines.isEmpty || _guests.isEmpty) {
      setState(() => _top3 = []);
      return;
    }

    final top3 = MenuTableMatcherEngine.rankTop3WinesForTable(
      menuWines: _menu!.wines,
      guests: _guests,
    );

    setState(() => _top3 = top3);
  }

  void _joinTable() {
    final name = _nameCtrl.text.trim().isEmpty ? 'Convive' : _nameCtrl.text.trim();
    GuestProfile newGuest;

    if (_selectedArchetype == 'sans_tanin') {
      newGuest = GuestProfile(
        id: 'guest_me',
        name: name,
        favoriteTypes: const ['Blanc', 'Rosé'],
        dislikedCharacteristics: const ['tanin', 'tannin', 'dur'],
        archetype: 'Aversion aux tanins durs',
      );
    } else if (_selectedArchetype == 'mineral') {
      newGuest = GuestProfile(
        id: 'guest_me',
        name: name,
        favoriteTypes: const ['Blanc'],
        archetype: 'Blancs Minéraux & Tendus',
      );
    } else if (_selectedArchetype == 'puissant') {
      newGuest = GuestProfile(
        id: 'guest_me',
        name: name,
        favoriteTypes: const ['Rouge'],
        archetype: 'Grands Rouges Puissants',
      );
    } else if (_selectedArchetype == 'fruit') {
      newGuest = GuestProfile(
        id: 'guest_me',
        name: name,
        favoriteTypes: const ['Rouge'],
        archetype: 'Fruits Rouges Croquants',
      );
    } else {
      newGuest = GuestProfile(
        id: 'guest_me',
        name: name,
        archetype: 'Curieux & Éclectique',
      );
    }

    setState(() {
      _guests.removeWhere((g) => g.id == 'guest_me');
      _guests.add(newGuest);
      _hasJoined = true;
    });

    _recalculateConsensus();
  }

  Future<void> _launchStore() async {
    const url = 'https://chatmelier.github.io';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Ce qu'on affiche quand la carte n'a pas pu être lue.
  ///
  /// Une vraie erreur, et non trois vins inventés sous le titre « Menu du Restaurant » :
  /// l'invité a le droit de savoir qu'il ne regarde pas la carte de l'établissement où il
  /// est assis. Le message dit quoi faire — redemander le QR — plutôt que de nommer une
  /// cause technique qui ne lui sert à rien.
  Widget _ecranCarteIllisible(bool isFr) {
    return Scaffold(
      backgroundColor: const Color(0xFF140F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1528),
        elevation: 0,
        title: Text(isFr ? 'Carte indisponible' : 'Menu unavailable'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  size: 56, color: Color(0xFFD4AF37)),
              const SizedBox(height: 20),
              Text(
                isFr
                    ? 'Cette carte n\'a pas pu être chargée'
                    : 'This menu could not be loaded',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isFr
                    ? 'Le lien est incomplet ou a expiré. Demandez à la personne qui a '
                        'scanné la carte de réafficher son QR code, puis scannez-le à nouveau.'
                    : 'The link is incomplete or has expired. Ask whoever scanned the menu '
                        'to show their QR code again, then scan it once more.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    if (_menu == null || _menu!.wines.isEmpty) return _ecranCarteIllisible(isFr);
    final menu = _menu!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF140F1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F1528),
          elevation: 0,
          title: Text(
            menu.restaurantName.isNotEmpty ? menu.restaurantName : (isFr ? 'Menu de Table' : 'Table Menu'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD4AF37)),
              tooltip: 'Actualiser',
              onPressed: _recalculateConsensus,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFFD4AF37),
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: const Icon(Icons.groups_rounded, size: 20), text: isFr ? 'Consensus' : 'Consensus'),
              Tab(icon: const Icon(Icons.menu_book_rounded, size: 20), text: isFr ? 'Carte des Vins' : 'Wine List'),
              Tab(icon: const Icon(Icons.wine_bar_rounded, size: 20), text: isFr ? 'Flights' : 'Flights'),
              Tab(icon: const Icon(Icons.restaurant_rounded, size: 20), text: isFr ? 'Accords Mets' : 'Food Match'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildConsensusTab(isFr, menu),
            _buildWineListTab(isFr, menu),
            _buildFlightsTab(isFr, menu),
            _buildFoodMatchTab(isFr, menu),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0 : CONSENSUS DE TABLE
  // ==========================================
  Widget _buildConsensusTab(bool isFr, ScannedMenu menu) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner Héroïque
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF33163A), Color(0xFF1D0B24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, color: Color(0xFFD4AF37), size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFr ? 'Consensus de Table Multi-Palais' : 'Multi-Palate Table Consensus',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${menu.wines.length} vins analysés pour ${_guests.length} convives',
                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section d'ajout de son profil de goût
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1728),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_pin_rounded, color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _hasJoined
                        ? (isFr ? 'Vos préférences à table :' : 'Your palate preferences:')
                        : (isFr ? 'Rejoindre la table avec vos goûts :' : 'Join the table with your tastes:'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isFr ? 'Votre prénom' : 'Your name',
                  labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedArchetype,
                dropdownColor: const Color(0xFF281E34),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isFr ? 'Votre style de vin préféré' : 'Your preferred wine style',
                  labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'sans_tanin', child: Text('🕊️ Aversion aux tanins durs')),
                  DropdownMenuItem(value: 'mineral', child: Text('⚡ Blancs Minéraux & Tendus')),
                  DropdownMenuItem(value: 'puissant', child: Text('🧱 Grands Rouges Puissants')),
                  DropdownMenuItem(value: 'fruit', child: Text('🍒 Rouges Fruits Croquants')),
                  DropdownMenuItem(value: 'equilibre', child: Text('🍷 Curieux & Éclectique')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedArchetype = v);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E3F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(_hasJoined ? Icons.check_circle : Icons.group_add_rounded, size: 18),
                  label: Text(
                    _hasJoined
                        ? (isFr ? 'Mettre à jour mes préférences' : 'Update my preferences')
                        : (isFr ? 'Valider mes goûts pour la table' : 'Confirm my tastes for the table'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _joinTable,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Liste des convives
        Text(
          isFr ? 'Convives à table :' : 'Guests at the table:',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _guests.map((g) {
            return Chip(
              backgroundColor: const Color(0xFF261830),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
              avatar: CircleAvatar(
                backgroundColor: const Color(0xFF8B1E3F),
                child: Text(
                  g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              label: Text('${g.name} (${g.archetype})', style: const TextStyle(color: Colors.white, fontSize: 11.5)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // TOP 3 BOUTEILLES DU RESTAURANT
        Row(
          children: [
            const Icon(Icons.wine_bar_rounded, color: Color(0xFFD4AF37), size: 20),
            const SizedBox(width: 8),
            Text(
              isFr ? 'LES 3 MEILLEURES BOUTEILLES POUR LA TABLE' : 'THE 3 BEST BOTTLES FOR THE TABLE',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_top3.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucune correspondance trouvée sur cette carte.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ..._top3.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final match = entry.value;
            return _buildTopMatchCard(rank, match);
          }),

        const SizedBox(height: 20),

        // Web/CTA Banner
        if (kIsWeb)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1728),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                const Text('📱', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                const Text(
                  'Chatmelier — Sommelier Intelligent',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  isFr
                      ? 'Gérez votre cave et découvrez des accords sur-mesure sur iOS et Android.'
                      : 'Manage your cellar and discover tailored pairings on iOS & Android.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4AF37),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(isFr ? 'Découvrir Chatmelier' : 'Discover Chatmelier'),
                  onPressed: _launchStore,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // TAB 1 : CARTE DES VINS DU RESTAURANT
  // ==========================================
  Widget _buildWineListTab(bool isFr, ScannedMenu menu) {
    final filteredWines = menu.wines.where((wine) {
      // 1. Recherche texte
      if (_wineSearchQuery.isNotEmpty) {
        final q = _wineSearchQuery.toLowerCase();
        final matches = wine.name.toLowerCase().contains(q) ||
            (wine.appellation?.toLowerCase().contains(q) ?? false) ||
            (wine.region?.toLowerCase().contains(q) ?? false) ||
            (wine.producer?.toLowerCase().contains(q) ?? false);
        if (!matches) return false;
      }

      // 2. Filtre couleur
      if (_wineColorFilter != 'all') {
        final wt = wine.wineType.toLowerCase();
        if (_wineColorFilter == 'Rouge' && !wt.contains('rouge') && !wt.contains('red')) return false;
        if (_wineColorFilter == 'Blanc' && !wt.contains('blanc') && !wt.contains('white')) return false;
        if (_wineColorFilter == 'Rosé' && !wt.contains('rosé') && !wt.contains('rose')) return false;
        if (_wineColorFilter == 'Bulles' && !wt.contains('bull') && !wt.contains('champ') && !wt.contains('sparkling')) return false;
      }

      // 3. Pépites / Bons plans
      if (_filterGemsOnly && !(wine.isGem || wine.isDeal)) {
        return false;
      }

      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Champ de recherche
        TextField(
          controller: _wineSearchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: isFr ? 'Rechercher un vin, domaine, appellation...' : 'Search wine, estate, appellation...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37), size: 20),
            suffixIcon: _wineSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    onPressed: () {
                      _wineSearchCtrl.clear();
                      setState(() => _wineSearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF1E1728),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (val) => setState(() => _wineSearchQuery = val.trim()),
        ),
        const SizedBox(height: 12),

        // Filtres de couleur et tags
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildColorFilterChip('all', isFr ? 'Tous' : 'All'),
              const SizedBox(width: 8),
              _buildColorFilterChip('Rouge', '🍷 Rouge'),
              const SizedBox(width: 8),
              _buildColorFilterChip('Blanc', '🥂 Blanc'),
              const SizedBox(width: 8),
              _buildColorFilterChip('Rosé', '🌸 Rosé'),
              const SizedBox(width: 8),
              _buildColorFilterChip('Bulles', '✨ Bulles'),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  '⭐ Pépites & Bons Plans',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _filterGemsOnly ? Colors.white : const Color(0xFFD4AF37),
                  ),
                ),
                selected: _filterGemsOnly,
                selectedColor: const Color(0xFF8B1E3F),
                backgroundColor: const Color(0xFF261830),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
                onSelected: (val) => setState(() => _filterGemsOnly = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          '${filteredWines.length} vins trouvés',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),

        if (filteredWines.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aucun vin ne correspond à ces critères.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ...filteredWines.map((wine) => _buildMenuWineCard(wine, isFr)),
      ],
    );
  }

  Widget _buildColorFilterChip(String value, String label) {
    final isSelected = _wineColorFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedColor: const Color(0xFF8B1E3F),
      backgroundColor: const Color(0xFF1E1728),
      side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.white12),
      onSelected: (_) => setState(() => _wineColorFilter = value),
    );
  }

  Widget _buildMenuWineCard(MenuWine wine, bool isFr) {
    final priceStr = wine.bottlePrice != null ? '${wine.bottlePrice!.toStringAsFixed(0)} €' : '';
    final glassStr = wine.primaryGlassPrice != null ? 'Verre : ${wine.primaryGlassPrice!.toStringAsFixed(1)} €' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1728),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: wine.isGem
              ? const Color(0xFFD4AF37).withValues(alpha: 0.8)
              : (wine.isDeal ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white10),
          width: wine.isGem ? 1.4 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Row(
          children: [
            Expanded(
              child: Text(
                wine.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            if (priceStr.isNotEmpty)
              Text(
                priceStr,
                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${wine.wineType} • ${wine.appellation ?? wine.region ?? ""} • ${wine.vintage ?? "NV"}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (glassStr != null) ...[
                  const SizedBox(width: 8),
                  Text('($glassStr)', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                ],
              ],
            ),
            if (wine.isGem || wine.isDeal || (wine.sommelierComment?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  if (wine.isGem)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('⭐ Pépite', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (wine.isDeal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🏷️ Bon Plan', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (wine.sommelierComment != null && wine.sommelierComment!.isNotEmpty)
                    Text(
                      wine.sommelierComment!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ],
          ],
        ),
        onTap: () => _showWineDetailSheet(wine, isFr),
      ),
    );
  }

  void _showWineDetailSheet(MenuWine wine, bool isFr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1728),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final m = wine.metrics;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wine.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '${wine.producer ?? ""} • ${wine.region ?? ""} • ${wine.vintage ?? "NV"}',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (wine.bottlePrice != null)
                    Text(
                      '${wine.bottlePrice!.toStringAsFixed(0)} €',
                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (wine.sommelierComment != null && wine.sommelierComment!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Text('🍷', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wine.sommelierComment!,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (m != null) ...[
                Text(
                  isFr ? 'Profil sensoriel estimé :' : 'Estimated sensory profile:',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildRadarBar('Corps / Puissance', m.body ?? 5.0, Colors.amber),
                _buildRadarBar('Acidité / Fraîcheur', m.acidity ?? 5.0, Colors.cyan),
                _buildRadarBar('Fruit & Gourmandise', m.fruit ?? 5.0, Colors.redAccent),
                if ((m.tannins ?? 0.0) > 0) _buildRadarBar('Tanins & Structure', m.tannins ?? 5.0, Colors.deepPurpleAccent),
                if ((m.minerality ?? 0.0) > 0) _buildRadarBar('Minéralité & Tension', m.minerality ?? 5.0, Colors.tealAccent),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(isFr ? 'Fermer' : 'Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadarBar(String label, double value, Color barColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value / 10.0).clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                color: barColor,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2 : PARCOURS DE DÉGUSTATION (FLIGHTS)
  // ==========================================
  Widget _buildFlightsTab(bool isFr, ScannedMenu menu) {
    final flightProposal = MenuFlightEngine.buildFlight(
      menu: menu,
      format: _selectedFlightFormat,
      color: _selectedFlightColor,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // En-tête des parcours
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B1E28), Color(0xFF1B0E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🍷', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFr ? 'Parcours Dégustation (Flights)' : 'Tasting Flights',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isFr
                              ? 'Une progression œnologique sur-mesure composée sur la carte'
                              : 'A tailored sommelier progression composed from this menu',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Format selector : 3 vs 5 verres
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('3 Verres (Express)', style: TextStyle(fontSize: 12))),
                      selected: _selectedFlightFormat == FlightFormat.threeGlasses,
                      selectedColor: const Color(0xFF8B1E3F),
                      backgroundColor: Colors.black26,
                      onSelected: (val) {
                        if (val) setState(() => _selectedFlightFormat = FlightFormat.threeGlasses);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('5 Verres (Grand Sommelier)', style: TextStyle(fontSize: 12))),
                      selected: _selectedFlightFormat == FlightFormat.fiveGlasses,
                      selectedColor: const Color(0xFF8B1E3F),
                      backgroundColor: Colors.black26,
                      onSelected: (val) {
                        if (val) setState(() => _selectedFlightFormat = FlightFormat.fiveGlasses);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Color Arc Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFlightColorChip(FlightWineColor.mix, '🍷🥂 Mix'),
                    const SizedBox(width: 8),
                    _buildFlightColorChip(FlightWineColor.white, '🥂 100% Blanc'),
                    const SizedBox(width: 8),
                    _buildFlightColorChip(FlightWineColor.rose, '🌸 100% Rosé'),
                    const SizedBox(width: 8),
                    _buildFlightColorChip(FlightWineColor.red, '🍷 100% Rouge'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Résumé du parcours généré
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1728),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                flightProposal.title,
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                flightProposal.storyline,
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Étapes du vol (Glasses 1..N)
        ...flightProposal.steps.map((step) => _buildFlightStepCard(step, isFr)),
      ],
    );
  }

  Widget _buildFlightColorChip(FlightWineColor color, String label) {
    final isSelected = _selectedFlightColor == color;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedColor: const Color(0xFF8B1E3F),
      backgroundColor: Colors.black26,
      side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.white12),
      onSelected: (_) => setState(() => _selectedFlightColor = color),
    );
  }

  Widget _buildFlightStepCard(FlightGlassStep step, bool isFr) {
    final wine = step.wine;
    final priceStr = wine.primaryGlassPrice != null
        ? '${wine.primaryGlassPrice!.toStringAsFixed(1)} € / verre'
        : (wine.bottlePrice != null ? '${wine.bottlePrice!.toStringAsFixed(0)} € / bout.' : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1728),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF8B1E3F),
                child: Text(
                  '${step.stepIndex}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.stepTitle,
                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      wine.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (priceStr.isNotEmpty)
                Text(
                  priceStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${wine.appellation ?? wine.region ?? ""} • ${wine.vintage ?? "NV"}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.tastingNotesSummary,
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3 : ACCORDS METS & VINS DU RESTAURANT
  // ==========================================
  Widget _buildFoodMatchTab(bool isFr, ScannedMenu menu) {
    // Calculer les accords en fonction du plat ou de la catégorie sélectionnée
    final matchedWines = _matchWinesForFood(menu.wines, _selectedDishCategory, _dishSearchCtrl.text.trim());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C192E), Color(0xFF140C1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFr ? 'Accords Mets & Vins' : 'Food & Wine Pairings',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isFr
                              ? 'Trouvez la bouteille idéale de cette carte pour accompagner votre plat'
                              : 'Find the ideal bottle on this menu to accompany your dish',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Champ texte libre pour le plat
              TextField(
                controller: _dishSearchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: isFr ? 'Quel plat mangez-vous ? (ex: Côte de bœuf, Saumon, Risotto)' : 'What are you eating? (e.g., Steak, Salmon, Risotto)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFD4AF37), size: 20),
                  suffixIcon: _dishSearchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () {
                            _dishSearchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Catégories rapides
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDishCategoryChip('viande', '🥩 Viande Rouge'),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('poisson', '🐟 Poisson & Crustacés'),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('volaille', '🍗 Volaille'),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('fromage', '🧀 Fromages'),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('pates', '🍝 Pâtes & Risotto'),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('dessert', '🍰 Desserts'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          isFr ? 'LES MEILLEURES BOUTEILLES POUR CE PLAT :' : 'BEST BOTTLES FOR THIS DISH:',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        if (matchedWines.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Aucun vin adapté trouvé sur cette carte.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ...matchedWines.map((pair) => _buildFoodMatchCard(pair, isFr)),
      ],
    );
  }

  Widget _buildDishCategoryChip(String category, String label) {
    final isSelected = _selectedDishCategory == category;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedColor: const Color(0xFF8B1E3F),
      backgroundColor: Colors.black26,
      side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.white12),
      onSelected: (_) => setState(() => _selectedDishCategory = category),
    );
  }

  List<_FoodWinePair> _matchWinesForFood(List<MenuWine> wines, String category, String customQuery) {
    if (wines.isEmpty) return [];

    String effectiveCat = category;
    if (customQuery.isNotEmpty) {
      final q = customQuery.toLowerCase();
      if (q.contains('saumon') || q.contains('poisson') || q.contains('crevette') || q.contains('huitre') || q.contains('cabillaud') || q.contains('dorade')) {
        effectiveCat = 'poisson';
      } else if (q.contains('boeuf') || q.contains('bœuf') || q.contains('steak') || q.contains('agneau') || q.contains('canard') || q.contains('burger')) {
        effectiveCat = 'viande';
      } else if (q.contains('poulet') || q.contains('volaille') || q.contains('dinde') || q.contains('veau')) {
        effectiveCat = 'volaille';
      } else if (q.contains('fromage') || q.contains('comté') || q.contains('camembert') || q.contains('chèvre')) {
        effectiveCat = 'fromage';
      } else if (q.contains('tarte') || q.contains('chocolat') || q.contains('dessert') || q.contains('glace') || q.contains('fraise')) {
        effectiveCat = 'dessert';
      }
    }

    final scored = wines.map((wine) {
      double score = 70.0;
      String rationale = '';
      final wt = wine.wineType.toLowerCase();

      switch (effectiveCat) {
        case 'viande':
          if (wt.contains('rouge')) {
            score += 20.0;
            if ((wine.metrics?.tannins ?? 5.0) >= 6.0) score += 5.0;
            rationale = 'La trame tannique et la puissance du vin viennent sublimer les sucs de la viande rouge.';
          } else {
            score -= 25.0;
            rationale = 'Les blancs manquent généralement de matière tannique pour soutenir une viande rouge saignante.';
          }
          break;

        case 'poisson':
          if (wt.contains('blanc') || wt.contains('white') || wt.contains('bull') || wt.contains('champ')) {
            score += 22.0;
            if ((wine.metrics?.acidity ?? 5.0) >= 6.5) score += 5.0;
            rationale = 'L\'acidité vive et la tension minérale équilibrent la chair délicate du poisson.';
          } else {
            score -= 30.0;
            rationale = 'Les tanins des vins rouges réagissent avec l\'iode et créent une amertume métallique.';
          }
          break;

        case 'volaille':
          if (wt.contains('blanc') || (wt.contains('rouge') && (wine.metrics?.tannins ?? 3.0) <= 5.0)) {
            score += 20.0;
            rationale = 'Chair tendre respectée par le fruit soyeux et la rondeur du vin.';
          } else {
            score += 5.0;
            rationale = 'Accord envisageable si la volaille est accompagnée d\'une sauce riche ou rôtie.';
          }
          break;

        case 'fromage':
          if (wt.contains('blanc')) {
            score += 20.0;
            rationale = 'Les blancs évitent le conflit tannique avec le gras du fromage pour une pureté aromatique totale.';
          } else {
            score += 10.0;
            rationale = 'Accord classique si le fromage est à pâte pressée cuite bien affinée.';
          }
          break;

        case 'pates':
          score += 15.0;
          rationale = 'Bel équilibre aromatique accompagnant la rondeur des sauces et des féculents.';
          break;

        case 'dessert':
          if (wt.contains('bull') || wt.contains('champ') || wt.contains('moelleux') || wt.contains('doux') || (wine.sommelierComment?.toLowerCase().contains('doux') ?? false)) {
            score += 25.0;
            rationale = 'Fraîcheur des bulles ou sucrosité en miroir avec la gourmandise du dessert.';
          } else {
            score -= 15.0;
            rationale = 'Un vin trop sec ou tannique peut paraître âpre face au sucre du dessert.';
          }
          break;
      }

      return _FoodWinePair(wine: wine, score: score.clamp(30.0, 99.0), rationale: rationale);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(3).toList();
  }

  Widget _buildFoodMatchCard(_FoodWinePair pair, bool isFr) {
    final wine = pair.wine;
    final priceStr = wine.bottlePrice != null ? '${wine.bottlePrice!.toStringAsFixed(0)} €' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1728),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wine.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '${wine.wineType} • ${wine.appellation ?? wine.region ?? ""} • ${wine.vintage ?? "NV"}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                ),
                child: Text(
                  '${pair.score.toStringAsFixed(0)}% Accord',
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              if (priceStr.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(priceStr, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(pair.rationale, style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMatchCard(int rank, MenuTableMatchResult match) {
    final wine = match.menuWine;
    final trophy = rank == 1 ? '🥇' : (rank == 2 ? '🥈' : '🥉');
    final rankColor = rank == 1
        ? const Color(0xFFD4AF37)
        : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    final priceStr = wine.bottlePrice != null ? '${wine.bottlePrice!.toStringAsFixed(0)} €' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF26172D),
            rankColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rankColor.withValues(alpha: 0.6), width: rank == 1 ? 1.8 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trophy, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wine.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${wine.appellation ?? wine.region ?? ""} • ${wine.vintage ?? "NV"}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                    ),
                    child: Text(
                      '${match.harmonyScore.toStringAsFixed(0)}% Harmonie',
                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (priceStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(priceStr, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.consensusRationale,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodWinePair {
  final MenuWine wine;
  final double score;
  final String rationale;

  const _FoodWinePair({required this.wine, required this.score, required this.rationale});
}
