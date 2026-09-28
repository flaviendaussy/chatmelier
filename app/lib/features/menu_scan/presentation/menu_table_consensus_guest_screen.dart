import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../data/table_session_service.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import 'palais_express.dart';
import 'table_matchmaker_sheet.dart';
import '../domain/table_matchmaker.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import '../domain/menu_wine.dart';
import '../domain/food_pairing_engine.dart';
import '../domain/menu_table_matcher_engine.dart';
import '../domain/menu_flight_engine.dart';
import '../data/menu_table_session_manager.dart';

class MenuTableConsensusGuestScreen extends ConsumerStatefulWidget {
  final String? initialSessionId;
  final String? initialData;

  /// Code de la table côté serveur (six caractères), porté par le QR (`?table=`) ou saisi
  /// à la main.
  /// Avec lui, l'invité rejoint vraiment la table — l'hôte le voit arriver — et voit les
  /// autres convives. Sans lui (ancien QR, pas de réseau), la table reste locale.
  final String? codeTable;

  /// Vrai quand l'invité a déjà rejoint par la feuille « Rejoindre une table » : son nom
  /// et son profil sont déjà enregistrés, il n'a pas à se présenter une seconde fois.
  final bool dejaAssis;

  /// Le prénom sous lequel il s'est assis par la feuille, pour le reconnaître à table.
  final String? nomAssis;

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
    this.codeTable,
    this.dejaAssis = false,
    this.nomAssis,
  });

  @override
  ConsumerState<MenuTableConsensusGuestScreen> createState() => _MenuTableConsensusGuestScreenState();
}

class _MenuTableConsensusGuestScreenState extends ConsumerState<MenuTableConsensusGuestScreen> {
  late final TextEditingController _nameCtrl;
  // L'arrivée : « Vous avez un compte ? » (null tant qu'on n'a pas répondu).
  bool? _aUnCompte;
  bool _chargementDuPalais = false;
  TasteProfile? _palaisDuCompte;
  PalaisSaisi? _monPalais;
  bool _sansPreferences = false;

  /// Ses avis au matchmaker de table (clé du vin → avis).
  Map<String, AvisDeTable> _mesAvis = {};
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

  /// Code serveur de la table, s'il est connu (paramètre, ou `?table=` de l'URL).
  String? _code;
  Timer? _sondage;

  /// Le prénom sous lequel cet invité a rejoint la table côté serveur.
  String? _monNomAssis;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Invité');
    _loadMenu();
    if (widget.dejaAssis) _hasJoined = true;
    if (widget.nomAssis != null && widget.nomAssis!.trim().isNotEmpty) {
      _monNomAssis = widget.nomAssis!.trim();
      _nameCtrl.text = _monNomAssis!;
    }
    if (_code != null) {
      // Même cadence que l'hôte : six secondes suffisent à ce qu'une arrivée paraisse
      // immédiate, sans ouvrir la lecture des tables à tous.
      WidgetsBinding.instance.addPostFrameCallback((_) => _rafraichirConvives());
      _sondage = Timer.periodic(const Duration(seconds: 6), (_) => _rafraichirConvives());
    }
  }

  /// Langue des raisons du consensus. Lue dans `didChangeDependencies` : `initState` ne
  /// peut pas consulter `Localizations`.
  bool _isFr = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    if (isFr != _isFr) {
      _isFr = isFr;
      _recalculateConsensus();
    }
  }

  @override
  void dispose() {
    _sondage?.cancel();
    _nameCtrl.dispose();
    _wineSearchCtrl.dispose();
    _dishSearchCtrl.dispose();
    super.dispose();
  }

  void _loadMenu() {
    String? sessionId = widget.initialSessionId;
    String? rawData = widget.initialData;
    String? code = widget.codeTable;

    if (kIsWeb) {
      final baseUri = Uri.base;
      sessionId ??= baseUri.queryParameters['session'] ?? baseUri.queryParameters['s'];
      rawData ??= baseUri.queryParameters['data'] ?? baseUri.queryParameters['d'];
      code ??= baseUri.queryParameters['table'];

      if ((sessionId == null || rawData == null || code == null) && baseUri.hasFragment) {
        try {
          final frag = baseUri.fragment.startsWith('/') ? baseUri.fragment : '/${baseUri.fragment}';
          final fragUri = Uri.parse(frag);
          sessionId ??= fragUri.queryParameters['session'] ?? fragUri.queryParameters['s'];
          rawData ??= fragUri.queryParameters['data'] ?? fragUri.queryParameters['d'];
          code ??= fragUri.queryParameters['table'];
        } catch (_) {}
      }
    }
    _code = (code != null && code.trim().isNotEmpty) ? code.trim().toUpperCase() : null;

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



    // Sans code serveur (ancien QR), la table reste locale : on garde un hôte générique
    // pour que le consensus ait un point de départ. Avec un code, les vrais convives —
    // l'hôte compris, avec son palais — arrivent du serveur au premier sondage.
    if (_code == null) {
      _guests.add(const GuestProfile(
        id: 'host_table',
        name: 'Hôte de la table',
        favoriteTypes: ['Rouge', 'Blanc'],
        archetype: 'Curieux & Éclectique',
      ));
    }

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
      isFr: _isFr,
    );

    setState(() => _top3 = top3);
  }

  /// Le serveur fusionne deux convives du même nom (`ON CONFLICT (session_id,
  /// guest_name)`) : deux « Invité » n'en feraient qu'un. On numérote au besoin.
  String _nomLibre(String nom) {
    bool pris(String n) => _guests.any((g) =>
        g.id != 'guest_me' &&
        // Son propre prénom, déjà assis, n'est pas « pris » : mettre à jour ses goûts ne
        // doit pas renommer Caro en « Caro (2) ».
        !(_monNomAssis != null && g.name.trim().toLowerCase() == _monNomAssis!.toLowerCase()) &&
        g.name.trim().toLowerCase() == n.toLowerCase());
    if (!pris(nom)) return nom;
    var i = 2;
    while (pris('$nom ($i)')) {
      i++;
    }
    return '$nom ($i)';
  }

  /// « Oui, j'ai un compte » : le palais Chatmelier de cet appareil, s'il existe.
  ///
  /// Le profil de goût vit sur l'appareil (pas encore sur le compte) : sur le navigateur
  /// ou le téléphone où la personne utilise Chatmelier, il est là sans connexion. Vide ou
  /// absent, on le dit et on propose les curseurs.
  Future<void> _utiliserMonCompte() async {
    setState(() {
      _aUnCompte = true;
      _chargementDuPalais = true;
    });
    TasteProfile? palais;
    try {
      palais = await ref.read(tasteProfileServiceProvider).getPrimaryProfile();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _chargementDuPalais = false;
      _palaisDuCompte =
          palais != null && (palais.questionnairesCompleted > 0 || palais.isWellProvided) ? palais : null;
    });
  }

  void _rejoindreAvec(PalaisSaisi palais) {
    _monPalais = palais;
    _sansPreferences = false;
    _rejoindre((nom) => palais.versConvive(id: 'guest_me', nom: nom, fr: _isFr));
  }

  void _rejoindreAvecLeCompte(TasteProfile palais) {
    final base = GuestProfile.fromTasteProfile(palais);
    _sansPreferences = false;
    _rejoindre((nom) => GuestProfile(
          id: 'guest_me',
          name: nom,
          tasteProfile: palais,
          favoriteTypes: base.favoriteTypes,
          favoriteGrapes: base.favoriteGrapes,
          dislikedCharacteristics: base.dislikedCharacteristics,
          archetype: base.archetype,
        ));
  }

  /// « Juste mon prénom » : compté à table, sans peser sur le classement.
  void _rejoindreSansPreferences() {
    _sansPreferences = true;
    _rejoindre((nom) => GuestProfile(
          id: 'guest_me',
          name: nom,
          sansPreferences: true,
          archetype: _isFr ? 'Sans préférences déclarées' : 'No stated preferences',
        ));
  }

  void _rejoindre(GuestProfile Function(String nom) profil) {
    final saisi = _nameCtrl.text.trim().isEmpty ? (_isFr ? 'Convive' : 'Guest') : _nameCtrl.text.trim();
    final name = _nomLibre(saisi);
    final newGuest = profil(name);

    setState(() {
      // Retirer aussi sa copie venue du serveur : sinon on se compte deux fois jusqu'au
      // prochain sondage.
      _guests.removeWhere((g) =>
          g.id == 'guest_me' ||
          (_monNomAssis != null && g.name.trim().toLowerCase() == _monNomAssis!.toLowerCase()));
      _guests.add(newGuest);
      _hasJoined = true;
    });

    _recalculateConsensus();
    if (_code != null) unawaited(_rejoindreLaTable(name, newGuest));
  }

  /// Sa propre place à table : la copie locale, ou celle venue du serveur.
  GuestProfile _moiATable() {
    for (final g in _guests) {
      if (g.id == 'guest_me') return g;
      if (_monNomAssis != null && g.name.trim().toLowerCase() == _monNomAssis!.toLowerCase()) return g;
    }
    final saisi = _nameCtrl.text.trim();
    return GuestProfile(id: 'guest_me', name: saisi.isEmpty ? (_isFr ? 'Convive' : 'Guest') : saisi);
  }

  /// Le matchmaker de la table, depuis son téléphone : ses avis partent à la table.
  Future<void> _ouvrirLeMatchmaker() async {
    final menu = _menu;
    if (menu == null) return;
    final moi = _moiATable();
    final avis = await TableMatchmakerSheet.show(
      context,
      candidats: TableMatchmaker.candidats(menu.wines, _guests),
      moi: moi,
      isFr: _isFr,
      avisDeja: _mesAvis,
    );
    if (avis == null || !mounted) return;
    if (avis.isNotEmpty) AppLogger.info('USAGE', 'matchmaker_de_table');
    _mesAvis = avis;
    final avecAvis = moi.copie(avis: {for (final e in avis.entries) e.key: e.value.name});
    _rejoindre((nom) => avecAvis.copie(id: 'guest_me', name: nom));
  }

  /// La carte d'arrivée, selon où en est l'invité.
  ///
  /// D'abord « Vous avez un compte ? » — Caro aurait dû se le voir demander (23/09). Oui :
  /// son palais Chatmelier. Non : le profilage express, qu'on peut refuser (« Juste mon
  /// prénom »). Une fois assis : mettre à jour ses goûts.
  List<Widget> _carteDArrivee(bool isFr) {
    const or = Color(0xFFD4AF37);
    const note = TextStyle(color: Colors.white70, fontSize: 12.5);
    final champNom = TextField(
      controller: _nameCtrl,
      // Assis côté serveur, le prénom est la clé de sa place : le changer créerait un
      // second convive.
      readOnly: _hasJoined && _monNomAssis != null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: isFr ? 'Votre prénom' : 'Your name',
        labelStyle: const TextStyle(color: or),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (_hasJoined) {
      return [
        champNom,
        const SizedBox(height: 10),
        if (_sansPreferences)
          Text(
            isFr
                ? 'Vous êtes à table sans préférences : le classement ne tient pas compte de vos goûts. '
                    'Décrivez-les quand vous voulez :'
                : 'You joined without preferences: the ranking ignores your taste. Describe it whenever you like:',
            style: note,
          ),
        const SizedBox(height: 10),
        PalaisExpress(
          isFr: isFr,
          initial: _monPalais ?? const PalaisSaisi(),
          libelleValider: isFr ? 'Mettre à jour mes préférences' : 'Update my preferences',
          onValider: _rejoindreAvec,
        ),
      ];
    }

    if (_aUnCompte == null) {
      return [
        champNom,
        const SizedBox(height: 14),
        Text(
          isFr ? 'Vous avez un compte Chatmelier ?' : 'Do you have a Chatmelier account?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: or, side: const BorderSide(color: or)),
                onPressed: _utiliserMonCompte,
                child: Text(isFr ? 'Oui' : 'Yes'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: () => setState(() => _aUnCompte = false),
                child: Text(isFr ? 'Non' : 'No'),
              ),
            ),
          ],
        ),
      ];
    }

    if (_aUnCompte == true && _chargementDuPalais) {
      return [champNom, const SizedBox(height: 16), const Center(child: CircularProgressIndicator())];
    }

    final palaisDuCompte = _palaisDuCompte;
    if (_aUnCompte == true && palaisDuCompte != null) {
      return [
        champNom,
        const SizedBox(height: 12),
        Text(
          isFr
              ? 'Votre palais Chatmelier sera utilisé (${palaisDuCompte.questionnairesCompleted} dégustations).'
              : 'Your Chatmelier palate will be used (${palaisDuCompte.questionnairesCompleted} tastings).',
          style: note,
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: WineTasteRadarChart(
              size: 140,
              showLabels: false,
              isInteractive: false,
              datasets: [
                RadarChartDataset(
                  label: isFr ? 'Votre palais' : 'Your palate',
                  color: or,
                  metrics: palaisDuCompte.radarMetrics,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.group_add_rounded, size: 18),
            label: Text(isFr ? 'Rejoindre avec mon palais' : 'Join with my palate',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _rejoindreAvecLeCompte(palaisDuCompte),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _aUnCompte = false),
            child: Text(isFr ? 'Plutôt décrire mes goûts ici' : 'Describe my tastes here instead', style: note),
          ),
        ),
      ];
    }

    return [
      champNom,
      const SizedBox(height: 12),
      Text(
        _aUnCompte == true
            ? (isFr
                ? 'Aucun palais Chatmelier sur cet appareil. Décrivez vos goûts en vingt secondes — c\'est facultatif :'
                : 'No Chatmelier palate on this device. Describe your tastes in twenty seconds — optional:')
            : (isFr
                ? 'Décrivez vos goûts en vingt secondes — c\'est facultatif :'
                : 'Describe your tastes in twenty seconds — optional:'),
        style: note,
      ),
      const SizedBox(height: 10),
      PalaisExpress(
        isFr: isFr,
        libelleValider: isFr ? 'Valider mes goûts pour la table' : 'Confirm my tastes for the table',
        onValider: _rejoindreAvec,
        onJusteMonPrenom: _rejoindreSansPreferences,
      ),
    ];
  }

  /// Rejoint la table côté serveur : l'hôte voit arriver l'invité, et l'invité reçoit la
  /// carte complète (le QR n'en porte que seize vins).
  ///
  /// Jusqu'au 28/09 cet écran n'appelait jamais le serveur : Caro avait rejoint, l'hôte
  /// ne la voyait pas (23/09).
  Future<void> _rejoindreLaTable(String nom, GuestProfile profil) async {
    final code = _code;
    if (code == null) return;
    // Un compte sans formulaire (anonyme), comme par la feuille « Rejoindre » : s'il
    // échoue, on rejoint quand même, seule la mémoire de la soirée manquera.
    await ref.read(authRepositoryProvider).assurerUneSession();
    try {
      final t = await ref.read(tableSessionServiceProvider).rejoindre(code: code, nom: nom, profil: profil);
      _monNomAssis = nom;
      if (!mounted) return;
      if (_menu == null || t.menu.wines.length > _menu!.wines.length) {
        setState(() => _menu = t.menu);
      }
      await _rafraichirConvives();
    } on TableSessionException catch (e) {
      // Journalisé : c'est exactement l'incident du 23/09 (« l'hôte ne la voit pas »), qui
      // n'avait laissé aucune trace.
      AppLogger.warning('TABLE', 'Invité non assis à la table $code (${e.cause.name})');
      if (!mounted) return;
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.cause == EchecDeTable.introuvable
            ? (isFr
                ? 'Cette table a expiré : l\'hôte ne vous verra pas. Demandez-lui un nouveau code.'
                : 'This table has expired: the host won\'t see you. Ask for a new code.')
            : (isFr
                ? 'Pas de réseau : l\'hôte ne vous voit pas encore.'
                : 'No connection: the host can\'t see you yet.')),
        action: e.cause == EchecDeTable.reseau
            ? SnackBarAction(
                label: isFr ? 'Réessayer' : 'Retry',
                onPressed: () => _rejoindreLaTable(nom, profil),
              )
            : null,
      ));
    }
  }

  /// Qui est à table, lu sur le serveur. Remplace la liste locale : l'hôte y figure avec
  /// son vrai palais, et chaque convive qui arrive y apparaît.
  Future<void> _rafraichirConvives() async {
    final code = _code;
    if (code == null || !mounted) return;
    final distants = await ref.read(tableSessionServiceProvider).convives(code);
    if (!mounted || distants.isEmpty) return;
    final moi = _guests.where((g) => g.id == 'guest_me').toList();
    final dejaListe = _monNomAssis != null &&
        distants.any((g) => g.name.trim().toLowerCase() == _monNomAssis!.toLowerCase());
    setState(() {
      _guests
        ..clear()
        ..addAll(distants)
        // Tant que le serveur n'a pas enregistré notre arrivée, on se garde à l'écran.
        ..addAll(dejaListe ? const <GuestProfile>[] : moi);
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
              ..._carteDArrivee(isFr),
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

        // Le matchmaker de la table : chacun donne son avis, rien n'est écarté.
        if (_hasJoined) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                foregroundColor: const Color(0xFFD4AF37),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _ouvrirLeMatchmaker,
              icon: const Icon(Icons.how_to_vote_rounded),
              label: Text(_mesAvis.isEmpty
                  ? (isFr ? 'Donner mon avis sur les vins' : 'Give my view on the wines')
                  : (isFr ? 'Revoir mes ${_mesAvis.length} avis' : 'Review my ${_mesAvis.length} views')),
            ),
          ),
          const SizedBox(height: 16),
        ],

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
        if (_wineColorFilter == 'Rouge' && !wine.isRed) return false;
        if (_wineColorFilter == 'Blanc' && !wine.isWhite) return false;
        if (_wineColorFilter == 'Rosé' && !wine.isRose) return false;
        if (_wineColorFilter == 'Bulles' && !wine.isSparkling) return false;
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
    // Un plat saisi (« Scottish beef fillet ») prime sur la pastille sélectionnée.
    final categorie = FoodPairingEngine.categorieDuPlat(_dishSearchCtrl.text) ?? _selectedDishCategory;
    final matchedWines = FoodPairingEngine.meilleursVins(menu.wines, categorie, isFr: isFr);

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
      onSelected: (_) {
        AppLogger.info('USAGE', 'accords_mets_vins');
        setState(() => _selectedDishCategory = category);
      },
    );
  }

  Widget _buildFoodMatchCard(AccordMetVin pair, bool isFr) {
    final wine = pair.vin;
    final priceStr = wine.bottlePrice != null ? wine.formaterPrix(wine.bottlePrice!) : '';

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
                  isFr ? '${pair.score.toStringAsFixed(0)}% Accord' : '${pair.score.toStringAsFixed(0)}% match',
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
                  child: Text(pair.raison, style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3)),
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
