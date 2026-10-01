import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import '../domain/menu_wine.dart';
import '../domain/menu_table_matcher_engine.dart';
import '../../blind_battle/presentation/widgets/stylized_chatmelier_qr.dart';
import '../data/menu_table_session_manager.dart';
import '../data/table_session_service.dart';
import '../domain/table_matchmaker.dart';
import 'table_matchmaker_sheet.dart';
import '../../../shared/widgets/bandeau_connexion_perdue.dart';
import '../../../shared/services/sondage_espace.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/app_logger.dart';
import 'titre_du_classement.dart';
import '../../../shared/utils/langue.dart';
import 'carte_deux_bouteilles.dart';

class MenuTableConsensusSheet extends ConsumerStatefulWidget {
  final ScannedMenu menu;

  const MenuTableConsensusSheet({super.key, required this.menu});

  static Future<void> show(BuildContext context, {required ScannedMenu menu}) {
    // Trace d'usage : la console d'administration compte ce qui ne laisse rien en base.
    AppLogger.info('USAGE', 'consensus_de_table');
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MenuTableConsensusSheet(menu: menu),
    );
  }

  @override
  ConsumerState<MenuTableConsensusSheet> createState() => _MenuTableConsensusSheetState();
}

class _MenuTableConsensusSheetState extends ConsumerState<MenuTableConsensusSheet> {
  final List<GuestProfile> _tableGuests = [];
  List<MenuTableMatchResult> _top3 = [];

  /// Deux bouteilles, quand une seule laisse trop de convives de côté (E4).
  PaireDeBouteilles? _paire;
  bool _showQrCode = false;
  late final String _tableSessionId;

  /// Le code délivré par le serveur, quand la table a pu être ouverte.
  ///
  /// L'ancien « code de partage » était fabriqué ici à partir de l'horodatage et ne
  /// correspondait à rien : on invitait les convives à le saisir alors qu'aucun écran ne
  /// pouvait le résoudre. Celui-ci se tape et fonctionne.
  String? _codeServeur;
  bool _ouvertureEnCours = true;

  /// Les convives qui ont rejoint depuis leur propre téléphone.
  SondageEspace? _sondage;
  bool _connexionPerdue = false;

  @override
  void initState() {
    super.initState();
    _tableSessionId = 'TABLE-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    MenuTableSessionManager.registerSession(_tableSessionId, widget.menu);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHostAndDemo());
    WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrirLaTable());
  }

  @override
  void dispose() {
    _sondage?.arreter();
    super.dispose();
  }

  /// Ouvre la table côté serveur, et se met à écouter qui arrive.
  Future<void> _ouvrirLaTable() async {
    try {
      final t = await ref.read(tableSessionServiceProvider).ouvrir(
            restaurantName: widget.menu.restaurantName,
            menu: widget.menu,
          );
      if (!mounted) return;
      setState(() {
        _codeServeur = t.code;
        _ouvertureEnCours = false;
      });
      unawaited(_inscrireLHote(t.code));
      // Sondage plutôt que temps réel : une politique RLS ne peut pas recevoir le code en
      // paramètre, et l'ouvrir à tous laisserait lister les tables en cours. Quatre
      // convives autour d'une table ne justifient pas d'y sacrifier ça — six secondes
      // suffisent à ce que l'arrivée d'un ami paraisse immédiate.
      _sondage = SondageEspace(
        etiquette: 'Convives de la table ${t.code}',
        tache: _rafraichirConvives,
        surAlerte: (alerte) {
          if (mounted) setState(() => _connexionPerdue = alerte);
        },
      )..demarrer(immediat: false);
    } catch (_) {
      if (!mounted) return;
      // La table reste utilisable en local : l'hôte garde son écran, ses convives ajoutés
      // à la main et son consensus. Seule l'invitation à distance manque, et on le dit.
      setState(() => _ouvertureEnCours = false);
    }
  }

  /// Le prénom sous lequel l'hôte s'est assis à sa propre table (voir [_inscrireLHote]).
  String? _nomHoteInscrit;

  /// L'identifiant de l'hôte dans `_tableGuests`, et ses avis au matchmaker de table.
  String? _idHote;
  Map<String, AvisDeTable> _avisHote = {};

  /// Le matchmaker de la table, pour l'hôte : ses avis pèsent chez lui et, par le
  /// serveur, chez chaque invité.
  Future<void> _ouvrirLeMatchmaker() async {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final hote = _tableGuests.where((g) => g.id == _idHote).firstOrNull ??
        (_tableGuests.isNotEmpty ? _tableGuests.first : null);
    if (hote == null) return;
    final avis = await TableMatchmakerSheet.show(
      context,
      candidats: TableMatchmaker.candidats(widget.menu.wines, _tableGuests),
      moi: hote,
      isFr: isFr,
      avisDeja: _avisHote,
    );
    if (avis == null || !mounted) return;
    if (avis.isNotEmpty) AppLogger.info('USAGE', 'matchmaker_de_table');
    _avisHote = avis;
    final avecAvis = hote.copie(avis: {for (final e in avis.entries) e.key: e.value.name});
    setState(() {
      final i = _tableGuests.indexWhere((g) => g.id == hote.id);
      if (i >= 0) _tableGuests[i] = avecAvis;
    });
    _calculateConsensus();

    final code = _codeServeur;
    final nom = _nomHoteInscrit;
    if (code == null || nom == null) return;
    try {
      await ref.read(tableSessionServiceProvider).rejoindre(code: code, nom: nom, profil: avecAvis);
    } catch (e) {
      AppLogger.warning('TABLE', 'Avis de l\'hôte non transmis à la table $code: $e');
    }
  }

  /// L'hôte s'assoit à sa propre table, sous son prénom et avec son vrai palais.
  ///
  /// Sans cela, les invités ne le voyaient pas : leur écran calculait le consensus avec
  /// un « Hôte de la table » aux goûts génériques (« Rouge, Blanc »).
  Future<void> _inscrireLHote(String code) async {
    try {
      final profiles = await ref.read(tasteProfilesListProvider.future);
      final primary = profiles.firstWhere((p) => p.isPrimary, orElse: () => profiles.first);
      final userId = ref.read(currentUserProvider)?.id;
      final compte = userId == null ? null : await ref.read(authRepositoryProvider).getProfile(userId);
      final prenom = (compte?.displayName.trim().isNotEmpty ?? false) ? compte!.displayName.trim() : primary.name;
      await ref.read(tableSessionServiceProvider).rejoindre(
            code: code,
            nom: prenom,
            profil: GuestProfile.fromTasteProfile(primary),
          );
      _nomHoteInscrit = prenom;
    } catch (e) {
      AppLogger.warning('TABLE', 'Inscription de l\'hôte à sa table impossible ($code): $e');
    }
  }

  Future<bool> _rafraichirConvives() async {
    final code = _codeServeur;
    if (code == null || !mounted) return true;
    final lus = await ref.read(tableSessionServiceProvider).lireConvives(code);
    if (lus == null) return false;
    final distants = lus;
    if (!mounted || distants.isEmpty) return true;
    setState(() {
      for (final g in distants) {
        // L'hôte est déjà à l'écran, sous son profil local : ne pas le compter deux fois.
        if (_nomHoteInscrit != null &&
            g.name.trim().toLowerCase() == _nomHoteInscrit!.toLowerCase()) {
          continue;
        }
        final deja = _tableGuests.indexWhere(
            (x) => x.name.trim().toLowerCase() == g.name.trim().toLowerCase());
        if (deja >= 0) {
          _tableGuests[deja] = g;
        } else {
          _tableGuests.add(g);
        }
      }
    });
    _calculateConsensus();
    return true;
  }

  Future<void> _initHostAndDemo() async {
    try {
      final profiles = await ref.read(tasteProfilesListProvider.future);
      final primary = profiles.firstWhere((p) => p.isPrimary, orElse: () => profiles.first);
      if (mounted) {
        final host = GuestProfile.fromTasteProfile(primary);
        _idHote = host.id;
        setState(() {
          if (!_tableGuests.any((g) => g.id == host.id)) {
            _tableGuests.add(host);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        _idHote = 'host_me';
        setState(() {
          // Nom et archétype restent en français : ce sont des clés (voir _nomAffiche et
          // GuestProfile.archetypeAffiche pour l'affichage).
          _tableGuests.add(const GuestProfile(
            id: 'host_me',
            name: 'Moi (Hôte)',
            favoriteTypes: ['Rouge', 'Blanc'],
            archetype: 'Curieux & Éclectique',
          ));
        });
      }
    }

    // Plus d'invitée de démonstration : « Camille », convive fictive aux goûts de blancs
    // minéraux, s'ajoutait à toute table où l'hôte était seul, et pesait dans le
    // consensus d'un vrai repas. Seul à table, l'hôte a un consensus d'une personne.

    _calculateConsensus();
  }

  bool get _isFr => Localizations.localeOf(context).languageCode == 'fr';

  /// Le nom d'un convive à l'écran : l'hôte, nommé « Moi » par son profil principal, se
  /// lit « Me » en anglais. La valeur stockée ne change pas (elle sert d'identité).
  String _nomAffiche(GuestProfile g) {
    if (_isFr || g.id != _idHote) return g.name;
    return switch (g.name) {
      'Moi' => 'Me',
      'Moi (Hôte)' => 'Me (host)',
      _ => g.name,
    };
  }

  void _calculateConsensus() {
    if (_tableGuests.isEmpty || widget.menu.wines.isEmpty) {
      setState(() {
        _top3 = [];
        _paire = null;
      });
      return;
    }

    final fr = Localizations.localeOf(context).languageCode == 'fr';
    final top3 = MenuTableMatcherEngine.rankTop3WinesForTable(
      menuWines: widget.menu.wines,
      guests: _tableGuests,
      isFr: fr,
      idLecteur: _idHote,
    );
    final paire = MenuTableMatcherEngine.meilleurePaire(
      MenuTableMatcherEngine.classerLaCarte(menuWines: widget.menu.wines, guests: _tableGuests, isFr: fr),
    );

    setState(() {
      _top3 = top3;
      _paire = paire;
    });
  }

  void _addGuestDialog() {
    final fr = _isFr;
    final nameCtrl = TextEditingController(text: '${trSi(fr, 'Convive', 'Guest')} ${_tableGuests.length + 1}');
    String selectedArchetype = 'equilibre';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1A24),
          title: Text(trSi(fr, 'Ajouter un convive à table', 'Add a guest to the table'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: trSi(fr, 'Prénom du convive', 'Guest\'s first name'),
                  labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                ),
              ),
              const SizedBox(height: 18),
              Text(trSi(fr, 'Profil / Préférences :', 'Profile / Preferences:'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedArchetype,
                isExpanded: true,
                dropdownColor: const Color(0xFF282230),
                style: const TextStyle(color: Colors.white),
                items: [
                  DropdownMenuItem(value: 'equilibre', child: Text(trSi(fr, '🍷 Curieux & Éclectique', '🍷 Curious & eclectic'))),
                  DropdownMenuItem(
                      value: 'puissant',
                      child: Text(trSi(fr, '🧱 Grands Rouges Puissants & Tanniques', '🧱 Big, powerful, tannic reds'))),
                  DropdownMenuItem(
                      value: 'mineral', child: Text(trSi(fr, '⚡ Blancs Tendus, Frais & Minéraux', '⚡ Taut, crisp, mineral whites'))),
                  DropdownMenuItem(
                      value: 'fruit', child: Text(trSi(fr, '🍒 Rouges Fruit Croquant & Souples', '🍒 Crunchy, supple fruity reds'))),
                  DropdownMenuItem(
                      value: 'sans_tanin', child: Text(trSi(fr, '🕊️ Aversion stricte aux tanins durs', '🕊️ No firm tannins at all'))),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => selectedArchetype = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(trSi(fr, 'Annuler', 'Cancel'), style: const TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty ? (trSi(fr, 'Convive', 'Guest')) : nameCtrl.text.trim();
                GuestProfile newGuest;

                if (selectedArchetype == 'puissant') {
                  newGuest = GuestProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    favoriteTypes: const ['Rouge'],
                    archetype: 'Grands Rouges Puissants',
                  );
                } else if (selectedArchetype == 'mineral') {
                  newGuest = GuestProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    favoriteTypes: const ['Blanc'],
                    archetype: 'Blancs Minéraux & Frais',
                  );
                } else if (selectedArchetype == 'fruit') {
                  newGuest = GuestProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    favoriteTypes: const ['Rouge'],
                    archetype: 'Fruit Croquant',
                  );
                } else if (selectedArchetype == 'sans_tanin') {
                  newGuest = GuestProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    favoriteTypes: const ['Blanc', 'Rosé'],
                    dislikedCharacteristics: const ['tanin', 'tannin', 'dur'],
                    archetype: 'Aversion Tanins Durs',
                  );
                } else {
                  newGuest = GuestProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    archetype: 'Curieux & Éclectique',
                  );
                }

                setState(() => _tableGuests.add(newGuest));
                _calculateConsensus();
                Navigator.pop(ctx);
              },
              child: Text(trSi(fr, 'Ajouter à table', 'Add to table'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF140F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trSi(_isFr, 'Consensus de Table Multi-Palais', 'Multi-Palate Table Consensus'),
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        vinsPourConvives(widget.menu.wines.length, _tableGuests.length, _isFr),
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Liste déroulante
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Bouton / Carte QR Code pour les amis à table
                _buildQrInviteBanner(),
                const SizedBox(height: 18),

                // Convives à table
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trSi(_isFr, 'Convives autour de la table :', 'Around the table:'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD4AF37),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: Text(trSi(_isFr, 'Ajouter', 'Add'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _addGuestDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tableGuests.map((g) {
                    return Chip(
                      backgroundColor: const Color(0xFF22162A),
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFF8B1E3F),
                        child: Text(
                          g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      label: Text(
                        '${_nomAffiche(g)} (${GuestProfile.archetypeAffiche(g.archetype, _isFr)})',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      onDeleted: _tableGuests.length > 1
                          ? () {
                              setState(() => _tableGuests.remove(g));
                              _calculateConsensus();
                            }
                          : null,
                      deleteIconColor: Colors.white38,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

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
                    label: Text(Localizations.localeOf(context).languageCode == 'fr'
                        ? (_avisHote.isEmpty ? 'Le matchmaker de la table' : 'Revoir mes ${_avisHote.length} avis')
                        : (_avisHote.isEmpty ? 'The table matchmaker' : 'Review my ${_avisHote.length} views')),
                  ),
                ),
                const SizedBox(height: 16),

                // Les plus ADAPTÉES, pas les meilleures : le premier de la carte peut
                // déplaire à toute la table (retour du 29/09).
                TitreDuClassement(isFr: Localizations.localeOf(context).languageCode == 'fr'),
                const SizedBox(height: 12),

                if (_top3.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        trSi(_isFr, 'Aucune correspondance trouvée sur cette carte.', 'No match found on this list.'),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  ..._top3.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final match = entry.value;
                    return _buildTopMatchCard(rank, match);
                  }),
                if (_paire != null) CarteDeuxBouteilles(paire: _paire!, isFr: _isFr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrInviteBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_rounded, color: Color(0xFFD4AF37), size: 28),
            title: Text(
              trSi(_isFr, 'Inviter la table', 'Invite the table'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              _ouvertureEnCours
                  ? (trSi(_isFr, 'Ouverture de la table…', 'Opening the table…'))
                  : (_codeServeur != null
                      ? (trSi(_isFr, 'Code {codeServeur} — ou faites scanner le QR', 'Code {codeServeur} — or let them scan the QR', {'codeServeur': _codeServeur}))
                      : (trSi(_isFr, 'Hors ligne : ajoutez vos convives à la main ci-dessus', 'Offline: add your guests by hand above'))),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: IconButton(
              icon: Icon(_showQrCode ? Icons.expand_less : Icons.expand_more, color: const Color(0xFFD4AF37)),
              onPressed: () => setState(() => _showQrCode = !_showQrCode),
            ),
          ),
          if (_showQrCode) ...[
            const Divider(color: Colors.white12, height: 1),
            // Le code d'abord, le QR ensuite. Une photo échoue pour mille raisons — écran
            // rayé, lumière basse, téléphone sans appareil photo ; six caractères dits à
            // voix haute, non.
            if (_codeServeur != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    if (_connexionPerdue) BandeauConnexionPerdue(onReessayer: () => _sondage?.relancer()),
                    Text(trSi(_isFr, 'CODE DE LA TABLE', 'TABLE CODE'),
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SelectableText(
                      _codeServeur!,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trSi(_isFr, 'À saisir dans Chatmelier, onglet Dégustation', 'Enter it in Chatmelier, Tasting tab'),
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: StylizedChatmelierQr(
                sessionId: _tableSessionId,
                title: trSi(_isFr, 'CONSENSUS DE TABLE CHATMELIER', 'CHATMELIER TABLE CONSENSUS'),
                icon: Icons.groups_rounded,
                customUrl: MenuTableSessionManager.buildQrUrl(
                  sessionId: _tableSessionId,
                  menu: widget.menu,
                  code: _codeServeur,
                ),
                shareMessage: _messageDInvitation(),
                shareSubject: _codeServeur != null
                    ? (trSi(_isFr, 'Table Chatmelier — code {codeServeur}', 'Chatmelier table — code {codeServeur}', {'codeServeur': _codeServeur}))
                    : (trSi(_isFr, 'Table Chatmelier', 'Chatmelier table')),
                // Le code serveur est déjà affiché en grand au-dessus ; l'identifiant local
                // de la table ne sert à personne.
                afficherLeCode: false,
                size: 260,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _messageDInvitation() {
    final lien = MenuTableSessionManager.buildQrUrl(sessionId: _tableSessionId, menu: widget.menu, code: _codeServeur);
    final appel = trSi(_isFr, 'Rejoins notre table sur Chatmelier pour choisir le vin ensemble ! ', 'Join our table on Chatmelier to choose the wine together! ');
    if (_codeServeur == null) return '$appel$lien';
    return trSi(_isFr, '{appel}Code : {codeServeur} — ou clique ici : {lien}', '{appel}Code: {codeServeur} — or tap here: {lien}', {'appel': appel, 'codeServeur': _codeServeur, 'lien': lien});
  }

  Widget _buildTopMatchCard(int rank, MenuTableMatchResult match) {
    final wine = match.menuWine;
    final trophy = rank == 1 ? '🥇' : (rank == 2 ? '🥈' : '🥉');
    final rankColor = rank == 1
        ? const Color(0xFFD4AF37)
        : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    final priceStr = wine.bottlePrice != null ? wine.formaterPrix(wine.bottlePrice!) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                      '${wine.appellation ?? wine.region ?? ''} • ${wine.vintage ?? 'NV'}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: rankColor),
                    ),
                    child: Text(
                      '${match.harmonyScore.toStringAsFixed(0)}% ${trSi(_isFr, 'accord', 'match')}',
                      style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  if (priceStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      priceStr,
                      style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),

          // Rationale sommelier
          Text(
            match.consensusRationale,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 12),

          // Scores individuels des convives
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: match.guestScores.entries.map((e) {
              final guest = _tableGuests.firstWhere((g) => g.id == e.key, orElse: () => _tableGuests.first);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1422),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_nomAffiche(guest), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '${e.value.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: e.value >= 80 ? Colors.greenAccent : (e.value >= 60 ? Colors.orangeAccent : Colors.redAccent),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (match.aversionAlerts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.aversionAlerts.first,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
