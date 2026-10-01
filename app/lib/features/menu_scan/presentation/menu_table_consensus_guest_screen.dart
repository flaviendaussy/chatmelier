import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/services/croissance.dart';
import '../../../shared/widgets/bandeau_connexion_perdue.dart';
import '../../../shared/services/sondage_espace.dart';
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
import 'titre_du_classement.dart';
import '../../auth/domain/evening_summary.dart';
import '../../auth/presentation/keep_evening_sheet.dart';
import '../../../shared/utils/langue.dart';
import 'carte_deux_bouteilles.dart';
import '../domain/fin_de_soiree.dart';
import 'note_d_un_geste_sheet.dart';

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

  /// « Je ne bois pas ce soir » (E3).
  bool _neBoitPas = false;

  /// Ses avis au matchmaker de table (clé du vin → avis).
  Map<String, AvisDeTable> _mesAvis = {};
  ScannedMenu? _menu;
  final List<GuestProfile> _guests = [];
  List<MenuTableMatchResult> _top3 = [];

  /// Deux bouteilles, quand une seule laisse trop de convives de côté (E4).
  PaireDeBouteilles? _paire;

  /// Ce que la table a commandé, indiqué par l'hôte (E2), et les notes données ce soir sur
  /// ce téléphone.
  List<VinChoisi> _choixDeLaTable = const [];
  final Map<String, double> _notesDuSoir = {};
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
  SondageEspace? _sondage;
  bool _connexionPerdue = false;

  /// Le prénom sous lequel cet invité a rejoint la table côté serveur.
  String? _monNomAssis;

  /// Arrivé par un QR qui ne porte que le code : la carte se lit sur le serveur.
  bool _carteEnChargement = false;

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
      _sondage = SondageEspace(
        etiquette: 'Convives de la table $_code (invité)',
        tache: _rafraichirConvives,
        surAlerte: (alerte) {
          if (mounted) setState(() => _connexionPerdue = alerte);
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _sondage?.demarrer());
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
      // Le prénom proposé suit la langue, tant que l'invité n'en a pas choisi un.
      if (!_hasJoined && const {'Invité', 'Guest', 'Invitado'}.contains(_nameCtrl.text)) {
        _nameCtrl.text = trSi(isFr, 'Invité', 'Guest');
      }
      _recalculateConsensus();
    }
  }

  @override
  void dispose() {
    _sondage?.arreter();
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

    // Le QR ne porte plus que le code de la table (la carte entière n'y tenait pas) :
    // la carte se lit sur le serveur. Si la lecture échoue, l'invité rejoint d'abord, et
    // la carte arrive avec sa place à table.
    if (_menu == null && _code != null) {
      _carteEnChargement = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _chargerLaCarte());
    }

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

  Future<void> _chargerLaCarte() async {
    final code = _code;
    if (code == null) return;
    final carte = await ref.read(tableSessionServiceProvider).lireCarte(code);
    if (!mounted) return;
    setState(() {
      _carteEnChargement = false;
      if (carte != null && _menu == null) _menu = carte;
    });
    _recalculateConsensus();
  }

  void _recalculateConsensus() {
    if (_menu == null || _menu!.wines.isEmpty || _guests.isEmpty) {
      setState(() {
        _top3 = [];
        _paire = null;
      });
      return;
    }

    final top3 = MenuTableMatcherEngine.rankTop3WinesForTable(
      menuWines: _menu!.wines,
      guests: _guests,
      isFr: _isFr,
      idLecteur: _idDuLecteur,
    );
    final paire = MenuTableMatcherEngine.meilleurePaire(
      MenuTableMatcherEngine.classerLaCarte(menuWines: _menu!.wines, guests: _guests, isFr: _isFr),
    );

    setState(() {
      _top3 = top3;
      _paire = paire;
    });
  }

  /// Qui lit cet écran, parmi les convives : notre entrée locale, ou celle que le serveur
  /// a enregistrée sous notre prénom. Avant qu'on s'asseye, aucun convive n'est nous.
  String get _idDuLecteur {
    final nom = _monNomAssis?.trim().toLowerCase();
    for (final g in _guests) {
      if (g.id == 'guest_me' || (nom != null && g.name.trim().toLowerCase() == nom)) return g.id;
    }
    return 'guest_me';
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
    _neBoitPas = false;
    _rejoindre((nom) => palais.versConvive(id: 'guest_me', nom: nom, fr: _isFr));
  }

  void _rejoindreAvecLeCompte(TasteProfile palais) {
    final base = GuestProfile.fromTasteProfile(palais);
    _sansPreferences = false;
    _neBoitPas = false;
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

  /// « Je ne bois pas ce soir » (E3) : à table, sans vin à choisir. Il ne vote pas et ne
  /// compte pas parmi les buveurs à satisfaire.
  void _rejoindreSansBoire() {
    _sansPreferences = true;
    _neBoitPas = true;
    _rejoindre((nom) => GuestProfile(
          id: 'guest_me',
          name: nom,
          sansPreferences: true,
          neBoitPas: true,
          archetype: 'Ne boit pas ce soir',
        ));
  }

  /// « Juste mon prénom » : compté à table, sans peser sur le classement.
  void _rejoindreSansPreferences() {
    _sansPreferences = true;
    _neBoitPas = false;
    _rejoindre((nom) => GuestProfile(
          id: 'guest_me',
          name: nom,
          sansPreferences: true,
          archetype: trSi(_isFr, 'Sans préférences déclarées', 'No stated preferences'),
        ));
  }

  void _rejoindre(GuestProfile Function(String nom) profil) {
    final saisi = _nameCtrl.text.trim().isEmpty ? (trSi(_isFr, 'Convive', 'Guest')) : _nameCtrl.text.trim();
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
    return GuestProfile(id: 'guest_me', name: saisi.isEmpty ? (trSi(_isFr, 'Convive', 'Guest')) : saisi);
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
        labelText: trSi(isFr, 'Votre prénom', 'Your name'),
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
        if (_neBoitPas)
          Text(
            trSi(isFr, 'Vous êtes à table sans boire ce soir : les bouteilles se choisissent pour les autres. '
                'Si vous changez d\'avis, décrivez vos goûts :', 'You\'re at the table without drinking tonight: the bottles are chosen for the others. '
                'If you change your mind, describe your tastes:'),
            style: note,
          )
        else if (_sansPreferences)
          Text(
            trSi(isFr, 'Vous êtes à table sans préférences : le classement ne tient pas compte de vos goûts. ' 'Décrivez-les quand vous voulez :', 'You joined without preferences: the ranking ignores your taste. Describe it whenever you like:'),
            style: note,
          ),
        const SizedBox(height: 10),
        PalaisExpress(
          isFr: isFr,
          initial: _monPalais ?? const PalaisSaisi(),
          libelleValider: trSi(isFr, 'Mettre à jour mes préférences', 'Update my preferences'),
          onValider: _rejoindreAvec,
        ),
      ];
    }

    if (_aUnCompte == null) {
      return [
        champNom,
        const SizedBox(height: 14),
        Text(
          trSi(isFr, 'Vous avez un compte Chatmelier ?', 'Do you have a Chatmelier account?'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: or, side: const BorderSide(color: or)),
                onPressed: _utiliserMonCompte,
                child: Text(trSi(isFr, 'Oui', 'Yes')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: () => setState(() => _aUnCompte = false),
                child: Text(trSi(isFr, 'Non', 'No')),
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
          trSi(isFr, 'Votre palais Chatmelier sera utilisé ({questionnairesCompleted} dégustations).', 'Your Chatmelier palate will be used ({questionnairesCompleted} tastings).', {'questionnairesCompleted': palaisDuCompte.questionnairesCompleted}),
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
                  label: trSi(isFr, 'Votre palais', 'Your palate'),
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
            label: Text(trSi(isFr, 'Rejoindre avec mon palais', 'Join with my palate'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _rejoindreAvecLeCompte(palaisDuCompte),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _aUnCompte = false),
            child: Text(trSi(isFr, 'Plutôt décrire mes goûts ici', 'Describe my tastes here instead'), style: note),
          ),
        ),
      ];
    }

    return [
      champNom,
      const SizedBox(height: 12),
      Text(
        _aUnCompte == true
            ? (trSi(isFr, 'Aucun palais Chatmelier sur cet appareil. Décrivez vos goûts en vingt secondes — c\'est facultatif :', 'No Chatmelier palate on this device. Describe your tastes in twenty seconds — optional:'))
            : (trSi(isFr, 'Décrivez vos goûts en vingt secondes — c\'est facultatif :', 'Describe your tastes in twenty seconds — optional:')),
        style: note,
      ),
      const SizedBox(height: 10),
      PalaisExpress(
        isFr: isFr,
        libelleValider: trSi(isFr, 'Valider mes goûts pour la table', 'Confirm my tastes for the table'),
        onValider: _rejoindreAvec,
        onJusteMonPrenom: _rejoindreSansPreferences,
        onJeNeBoisPas: _rejoindreSansBoire,
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
        setState(() {
          _menu = t.menu;
          _carteEnChargement = false;
        });
        if (kIsWeb) unawaited(Croissance.noter('invite_web_arrivee', tableCode: code));
      }
      await _rafraichirConvives();
    } on TableSessionException catch (e) {
      // Journalisé : c'est exactement l'incident du 23/09 (« l'hôte ne la voit pas »), qui
      // n'avait laissé aucune trace.
      AppLogger.warning('TABLE', 'Invité non assis à la table $code (${e.cause.name})');
      if (!mounted) return;
      if (_carteEnChargement) {
        // Sans carte, l'invité revient à l'écran d'arrivée pour réessayer.
        setState(() {
          _carteEnChargement = false;
          if (_menu == null) _hasJoined = false;
        });
      }
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.cause == EchecDeTable.introuvable
            ? (trSi(isFr, 'Cette table a expiré : l\'hôte ne vous verra pas. Demandez-lui un nouveau code.', 'This table has expired: the host won\'t see you. Ask for a new code.'))
            : (trSi(isFr, 'Pas de réseau : l\'hôte ne vous voit pas encore.', 'No connection: the host can\'t see you yet.'))),
        action: e.cause == EchecDeTable.reseau
            ? SnackBarAction(
                label: trSi(isFr, 'Réessayer', 'Retry'),
                onPressed: () => _rejoindreLaTable(nom, profil),
              )
            : null,
      ));
    }
  }

  /// Qui est à table, lu sur le serveur. Remplace la liste locale : l'hôte y figure avec
  /// son vrai palais, et chaque convive qui arrive y apparaît.
  Future<bool> _rafraichirConvives() async {
    final code = _code;
    if (code == null || !mounted) return true;
    final lus = await ref.read(tableSessionServiceProvider).lireConvives(code);
    if (lus == null) return false;
    // Ce que l'hôte a indiqué avoir commandé, pour le noter d'un geste (E2). Sans la
    // migration 057, `null` : rien ne change.
    final etat = await ref.read(tableSessionServiceProvider).lireEtat(code);
    if (etat != null && mounted) setState(() => _choixDeLaTable = etat.choix);
    final distants = lus;
    if (!mounted || distants.isEmpty) return true;
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
    return true;
  }

  /// Le Play Store, et non plus le site lui-même (où l'invité se trouvait déjà) : le bouton
  /// « Découvrir Chatmelier » ne menait nulle part ailleurs jusqu'au 30/09.
  Future<void> _launchStore() async {
    unawaited(Croissance.noter('clic_installer', source: 'page_invite', tableCode: _code));
    final uri = Uri.parse(Croissance.lienPlayStore(source: 'page_invite', tableCode: _code));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Il n'existe pas encore d'app iPhone : on ne l'annonce pas.
  bool get _surIPhone => defaultTargetPlatform == TargetPlatform.iOS;

  /// Ce qu'on affiche quand la carte n'a pas pu être lue.
  ///
  /// Une vraie erreur, et non trois vins inventés sous le titre « Menu du Restaurant » :
  /// l'invité a le droit de savoir qu'il ne regarde pas la carte de l'établissement où il
  /// est assis. Le message dit quoi faire — redemander le QR — plutôt que de nommer une
  /// cause technique qui ne lui sert à rien.
  Widget _ecranChargementDeLaCarte(bool isFr) {
    return Scaffold(
      backgroundColor: const Color(0xFF140F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1528),
        elevation: 0,
        title: Text(trSi(isFr, 'Table {code}', 'Table {code}', {'code': _code ?? ''})),
      ),
      body: const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
    );
  }

  /// La table existe mais sa carte n'a pas pu être lue d'avance : l'invité rejoint
  /// d'abord (son prénom suffit), et la carte arrive avec sa place à table. Il pourra
  /// décrire ses goûts ensuite.
  Widget _ecranRejoindreDAbord(bool isFr) {
    return Scaffold(
      backgroundColor: const Color(0xFF140F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1528),
        elevation: 0,
        title: Text(trSi(isFr, 'Table {code}', 'Table {code}', {'code': _code ?? ''})),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_rounded, size: 56, color: Color(0xFFD4AF37)),
              const SizedBox(height: 20),
              Text(
                trSi(isFr, 'Rejoignez la table pour voir la carte', 'Join the table to see the wine list'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                trSi(isFr, 'Votre prénom suffit : la carte arrive dès que vous êtes à table, et vous pourrez décrire vos goûts ensuite.',
                    'Your first name is enough: the wine list arrives as soon as you are at the table, and you can describe your tastes afterwards.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: trSi(isFr, 'Votre prénom', 'Your first name'),
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E3F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() => _carteEnChargement = true);
                    _rejoindreSansPreferences();
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: Text(trSi(isFr, 'Rejoindre la table', 'Join the table')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ecranCarteIllisible(bool isFr) {
    return Scaffold(
      backgroundColor: const Color(0xFF140F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1528),
        elevation: 0,
        title: Text(trSi(isFr, 'Carte indisponible', 'Menu unavailable')),
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
                trSi(isFr, 'Cette carte n\'a pas pu être chargée', 'This menu could not be loaded'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                trSi(isFr, 'Le lien est incomplet ou a expiré. Demandez à la personne qui a ' 'scanné la carte de réafficher son QR code, puis scannez-le à nouveau.', 'The link is incomplete or has expired. Ask whoever scanned the menu ' 'to show their QR code again, then scan it once more.'),
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
    if (_menu == null || _menu!.wines.isEmpty) {
      if (_carteEnChargement) return _ecranChargementDeLaCarte(isFr);
      if (_code != null && !_hasJoined) return _ecranRejoindreDAbord(isFr);
      return _ecranCarteIllisible(isFr);
    }
    final menu = _menu!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF140F1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F1528),
          elevation: 0,
          title: Text(
            menu.restaurantName.isNotEmpty ? menu.restaurantName : (trSi(isFr, 'Menu de Table', 'Table Menu')),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD4AF37)),
              tooltip: trSi(_isFr, 'Actualiser', 'Refresh'),
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
              Tab(icon: const Icon(Icons.groups_rounded, size: 20), text: trSi(isFr, 'Consensus', 'Consensus')),
              Tab(icon: const Icon(Icons.menu_book_rounded, size: 20), text: trSi(isFr, 'Carte des Vins', 'Wine List')),
              Tab(icon: const Icon(Icons.wine_bar_rounded, size: 20), text: trSi(isFr, 'Flights', 'Flights')),
              Tab(icon: const Icon(Icons.restaurant_rounded, size: 20), text: trSi(isFr, 'Accords Mets', 'Food Match')),
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
        if (_connexionPerdue) BandeauConnexionPerdue(onReessayer: () => _sondage?.relancer()),
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
                      trSi(isFr, 'Consensus de Table Multi-Palais', 'Multi-Palate Table Consensus'),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vinsPourConvives(menu.wines.length, _guests.length, isFr),
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
                        ? (trSi(isFr, 'Vos préférences à table :', 'Your palate preferences:'))
                        : (trSi(isFr, 'Rejoindre la table avec vos goûts :', 'Join the table with your tastes:')),
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
          trSi(isFr, 'Convives à table :', 'Guests at the table:'),
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
              label: Text(
                  '${g.name == 'Hôte de la table' ? trSi(isFr, 'Hôte de la table', 'Table host') : g.name} '
                  '(${GuestProfile.archetypeAffiche(g.archetype, isFr)})',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5)),
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
                  ? (trSi(isFr, 'Donner mon avis sur les vins', 'Give my view on the wines'))
                  : (trSi(isFr, 'Revoir mes {mesAvis_length} avis', 'Review my {mesAvis_length} views', {'mesAvis_length': _mesAvis.length}))),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Les plus adaptées à la table, pas les meilleures de la carte.
        if (_choixDeLaTable.isNotEmpty)
          CarteDuChoixDeLaTable(
            choix: _choixDeLaTable,
            notes: _notesDuSoir,
            onNoter: (vin) => _noter(vin, menu),
          ),
        TitreDuClassement(isFr: isFr),
        const SizedBox(height: 12),

        if (_top3.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(trSi(isFr, 'Aucune correspondance trouvée sur cette carte.', 'No match found on this list.'),
                  style: const TextStyle(color: Colors.white54)),
            ),
          )
        else
          ..._top3.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final match = entry.value;
            return _buildTopMatchCard(rank, match);
          }),
        if (_paire != null) CarteDeuxBouteilles(paire: _paire!, isFr: isFr),

        const SizedBox(height: 20),

        // Garder la soirée (P6) : l'invité arrivé par le QR n'y avait jamais accès — la
        // proposition ne vivait que dans la feuille « Rejoindre une table » de l'app.
        _carteGarderLaSoiree(isFr, menu),

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
                Text(
                  trSi(isFr, 'Chatmelier — Sommelier Intelligent', 'Chatmelier — Your Smart Sommelier'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  // Pas d'app iPhone à ce jour : le texte disait « sur iOS et Android ».
                  _surIPhone
                      ? (trSi(isFr, 'L\'app arrive bientôt sur iPhone. D\'ici là, gardez votre soirée avec un code de reprise, juste au-dessus.', 'The iPhone app is coming soon. Until then, keep your evening with a recovery code, just above.'))
                      : (trSi(isFr, 'Gardez votre palais, gérez votre cave et découvrez des accords sur mesure dans l\'app Android.', 'Keep your palate, manage your cellar and discover tailored pairings in the Android app.')),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (!_surIPhone)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4AF37),
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(trSi(isFr, 'Installer l\'app', 'Install the app')),
                  onPressed: _launchStore,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Proposée seulement à un compte anonyme, et seulement s'il y a quelque chose de vrai
  /// à garder : réclamer une adresse pour sauvegarder le vide ne sert à rien.
  Future<void> _noter(VinChoisi vin, ScannedMenu menu) async {
    final moi = _monNomAssis?.toLowerCase();
    final note = await NoteDUnGesteSheet.show(
      context,
      vin: vin,
      restaurant: menu.restaurantName,
      convives: [
        for (final g in _guests)
          if (g.id != 'guest_me' && g.name.trim().toLowerCase() != moi) g.name,
      ],
    );
    if (note != null && mounted) setState(() => _notesDuSoir[vin.cle] = note);
  }

  Widget _carteGarderLaSoiree(bool isFr, ScannedMenu menu) {
    // Un bonus : quoi qu'il arrive (pas de session, pas de fournisseur), l'écran de table
    // doit s'afficher.
    final List<TasteProfile> profils;
    try {
      final auth = ref.read(authRepositoryProvider);
      if (!auth.aUneSession || !auth.estAnonyme) return const SizedBox.shrink();
      profils = ref.watch(tasteProfilesListProvider).valueOrNull ?? const <TasteProfile>[];
    } catch (_) {
      return const SizedBox.shrink();
    }
    final principal = profils.where((p) => p.isPrimary).firstOrNull;
    if (principal == null) return const SizedBox.shrink();
    final lignes = EveningSummary.lignes(
      profil: principal,
      verresGoutes: _notesDuSoir.length,
      nomDuLieu: menu.restaurantName.trim().isEmpty ? null : menu.restaurantName.trim(),
    );
    if (lignes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD4AF37),
          side: const BorderSide(color: Color(0xFFD4AF37)),
          minimumSize: const Size.fromHeight(46),
        ),
        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
        label: Text(trSi(isFr, 'Garder cette soirée', 'Keep this evening')),
        onPressed: () => KeepEveningSheet.show(context, cequiSeraGarde: lignes),
      ),
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
            wine.producer.toLowerCase().contains(q);
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
            hintText: trSi(isFr, 'Rechercher un vin, domaine, appellation...', 'Search wine, estate, appellation...'),
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
              _buildColorFilterChip('all', trSi(isFr, 'Tous', 'All')),
              const SizedBox(width: 8),
              _buildColorFilterChip('Rouge', trSi(isFr, '🍷 Rouge', '🍷 Red')),
              const SizedBox(width: 8),
              _buildColorFilterChip('Blanc', trSi(isFr, '🥂 Blanc', '🥂 White')),
              const SizedBox(width: 8),
              _buildColorFilterChip('Rosé', '🌸 Rosé'),
              const SizedBox(width: 8),
              _buildColorFilterChip('Bulles', trSi(isFr, '✨ Bulles', '✨ Sparkling')),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  trSi(isFr, '⭐ Pépites & Bons Plans', '⭐ Gems & Deals'),
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
          filteredWines.length > 1
              ? trSi(isFr, '{n} vins trouvés', '{n} wines found', {'n': filteredWines.length})
              : trSi(isFr, '{n} vin trouvé', '{n} wine found', {'n': filteredWines.length}),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),

        if (filteredWines.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(trSi(isFr, 'Aucun vin ne correspond à ces critères.', 'No wine matches these filters.'),
                  style: const TextStyle(color: Colors.white54)),
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
    final priceStr = wine.bottlePrice != null ? wine.formaterPrix(wine.bottlePrice!) : '';
    final glassStr = wine.primaryGlassPrice != null
        ? (trSi(isFr, 'Verre : ', 'Glass: ')) + wine.formaterPrix(wine.primaryGlassPrice!)
        : null;

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
                      child: Text(trSi(isFr, '⭐ Pépite', '⭐ Gem'),
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (wine.isDeal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(trSi(isFr, '🏷️ Bon Plan', '🏷️ Deal'),
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
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
                          '${wine.producer} • ${wine.region ?? ""} • ${wine.vintage ?? "NV"}',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (wine.bottlePrice != null)
                    Text(
                      wine.formaterPrix(wine.bottlePrice!),
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
              ...[
                Text(
                  trSi(isFr, 'Profil sensoriel estimé :', 'Estimated sensory profile:'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildRadarBar(trSi(isFr, 'Corps / Puissance', 'Body / Power'), m.body, Colors.amber),
                _buildRadarBar(trSi(isFr, 'Acidité / Fraîcheur', 'Acidity / Freshness'), m.acidity, Colors.cyan),
                _buildRadarBar(trSi(isFr, 'Fruit', 'Fruit'), m.fruit, Colors.redAccent),
                // Les tanins ne se disent que des rouges, la minéralité des blancs et des
                // bulles : mêmes règles de plausibilité que le consensus (29/09).
                if (wine.isRed && m.tannins > 0)
                  _buildRadarBar(trSi(isFr, 'Tanins & Structure', 'Tannins & Structure'), m.tannins, Colors.deepPurpleAccent),
                if (!wine.isRed && m.minerality > 0)
                  _buildRadarBar(trSi(isFr, 'Minéralité & Tension', 'Minerality & Tension'), m.minerality, Colors.tealAccent),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(trSi(isFr, 'Fermer', 'Close')),
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
      isFr: isFr,
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
                          trSi(isFr, 'Parcours Dégustation (Flights)', 'Tasting Flights'),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          trSi(isFr, 'Une progression œnologique sur-mesure composée sur la carte', 'A tailored sommelier progression composed from this menu'),
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
                      label: Center(child: Text(trSi(isFr, '3 Verres (Express)', '3 Glasses (Express)'), style: const TextStyle(fontSize: 12))),
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
                      label: Center(
                          child: Text(trSi(isFr, '5 Verres (Grand Sommelier)', '5 Glasses (Grand Sommelier)'),
                              style: const TextStyle(fontSize: 12))),
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
                    _buildFlightColorChip(FlightWineColor.white, '🥂 ${FlightWineColor.white.label(isFr)}'),
                    const SizedBox(width: 8),
                    _buildFlightColorChip(FlightWineColor.rose, '🌸 ${FlightWineColor.rose.label(isFr)}'),
                    const SizedBox(width: 8),
                    _buildFlightColorChip(FlightWineColor.red, '🍷 ${FlightWineColor.red.label(isFr)}'),
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
        ? '${wine.formaterPrix(wine.primaryGlassPrice!)} / ${trSi(isFr, 'verre', 'glass')}'
        : (wine.bottlePrice != null ? '${wine.formaterPrix(wine.bottlePrice!)} / ${trSi(isFr, 'bout.', 'btl')}' : '');

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
                          trSi(isFr, 'Accords Mets & Vins', 'Food & Wine Pairings'),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          trSi(isFr, 'Trouvez la bouteille idéale de cette carte pour accompagner votre plat', 'Find the ideal bottle on this menu to accompany your dish'),
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
                  hintText: trSi(isFr, 'Quel plat mangez-vous ? (ex: Côte de bœuf, Saumon, Risotto)', 'What are you eating? (e.g., Steak, Salmon, Risotto)'),
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
                    _buildDishCategoryChip('viande', trSi(isFr, '🥩 Viande Rouge', '🥩 Red Meat')),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('poisson', trSi(isFr, '🐟 Poisson & Crustacés', '🐟 Fish & Shellfish')),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('volaille', trSi(isFr, '🍗 Volaille', '🍗 Poultry')),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('fromage', trSi(isFr, '🧀 Fromages', '🧀 Cheese')),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('pates', trSi(isFr, '🍝 Pâtes & Risotto', '🍝 Pasta & Risotto')),
                    const SizedBox(width: 8),
                    _buildDishCategoryChip('dessert', trSi(isFr, '🍰 Desserts', '🍰 Desserts')),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        TitreDuClassement(isFr: isFr, pourUnPlat: true),
        const SizedBox(height: 10),

        if (matchedWines.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(trSi(isFr, 'Aucun vin adapté trouvé sur cette carte.', 'No suitable wine on this list.'),
                  style: const TextStyle(color: Colors.white54)),
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
                  trSi(isFr, '{v1}% Accord', '{v1}% match', {'v1': pair.score.toStringAsFixed(0)}),
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

    final priceStr = wine.bottlePrice != null ? wine.formaterPrix(wine.bottlePrice!) : '';

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
                      '${match.harmonyScore.toStringAsFixed(0)}% ${trSi(_isFr, 'Harmonie', 'match')}',
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
