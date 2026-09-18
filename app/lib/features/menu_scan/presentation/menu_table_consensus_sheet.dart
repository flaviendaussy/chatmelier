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

class MenuTableConsensusSheet extends ConsumerStatefulWidget {
  final ScannedMenu menu;

  const MenuTableConsensusSheet({super.key, required this.menu});

  static Future<void> show(BuildContext context, {required ScannedMenu menu}) {
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
  Timer? _sondage;

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
    _sondage?.cancel();
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
      // Sondage plutôt que temps réel : une politique RLS ne peut pas recevoir le code en
      // paramètre, et l'ouvrir à tous laisserait lister les tables en cours. Quatre
      // convives autour d'une table ne justifient pas d'y sacrifier ça — six secondes
      // suffisent à ce que l'arrivée d'un ami paraisse immédiate.
      _sondage = Timer.periodic(const Duration(seconds: 6), (_) => _rafraichirConvives());
    } catch (_) {
      if (!mounted) return;
      // La table reste utilisable en local : l'hôte garde son écran, ses convives ajoutés
      // à la main et son consensus. Seule l'invitation à distance manque, et on le dit.
      setState(() => _ouvertureEnCours = false);
    }
  }

  Future<void> _rafraichirConvives() async {
    final code = _codeServeur;
    if (code == null || !mounted) return;
    final distants = await ref.read(tableSessionServiceProvider).convives(code);
    if (!mounted || distants.isEmpty) return;
    setState(() {
      for (final g in distants) {
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
  }

  Future<void> _initHostAndDemo() async {
    try {
      final profiles = await ref.read(tasteProfilesListProvider.future);
      final primary = profiles.firstWhere((p) => p.isPrimary, orElse: () => profiles.first);
      if (mounted) {
        final host = GuestProfile.fromTasteProfile(primary);
        setState(() {
          if (!_tableGuests.any((g) => g.id == host.id)) {
            _tableGuests.add(host);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tableGuests.add(const GuestProfile(
            id: 'host_me',
            name: 'Moi (Hôte)',
            favoriteTypes: ['Rouge', 'Blanc'],
            archetype: 'Curieux & Éclectique',
          ));
        });
      }
    }

    // Ajout d'un 2ème invité de démo pour un consensus immédiat
    if (_tableGuests.length == 1) {
      _tableGuests.add(const GuestProfile(
        id: 'guest_demo_1',
        name: 'Camille',
        favoriteTypes: ['Blanc'],
        dislikedCharacteristics: ['tanin dur', 'boisé excessif'],
        archetype: 'Adepte de Minéralité & Fraîcheur Droite',
      ));
    }

    _calculateConsensus();
  }

  void _calculateConsensus() {
    if (_tableGuests.isEmpty || widget.menu.wines.isEmpty) {
      setState(() => _top3 = []);
      return;
    }

    final top3 = MenuTableMatcherEngine.rankTop3WinesForTable(
      menuWines: widget.menu.wines,
      guests: _tableGuests,
    );

    setState(() => _top3 = top3);
  }

  void _addGuestDialog() {
    final nameCtrl = TextEditingController(text: 'Convive ${_tableGuests.length + 1}');
    String selectedArchetype = 'equilibre';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1A24),
          title: const Text('Ajouter un convive à table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Prénom du convive',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Profil / Préférences :', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedArchetype,
                isExpanded: true,
                dropdownColor: const Color(0xFF282230),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'equilibre', child: Text('🍷 Curieux & Éclectique')),
                  DropdownMenuItem(value: 'puissant', child: Text('🧱 Grands Rouges Puissants & Tanniques')),
                  DropdownMenuItem(value: 'mineral', child: Text('⚡ Blancs Tendus, Frais & Minéraux')),
                  DropdownMenuItem(value: 'fruit', child: Text('🍒 Rouges Fruit Croquant & Souples')),
                  DropdownMenuItem(value: 'sans_tanin', child: Text('🕊️ Aversion stricte aux tanins durs')),
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
              child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty ? 'Convive' : nameCtrl.text.trim();
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
              child: const Text('Ajouter à table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      const Text(
                        'Consensus de Table Multi-Palais',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.menu.wines.length} vins analysés pour ${_tableGuests.length} convives',
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
                    const Text(
                      'Convives autour de la table :',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD4AF37),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                        '${g.name} (${g.archetype})',
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

                // Les 3 meilleures bouteilles qui matchent
                const Row(
                  children: [
                    Icon(Icons.wine_bar_rounded, color: Color(0xFFD4AF37), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'LES 3 MEILLEURES BOUTEILLES DU RESTAURANT',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_top3.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucune correspondance trouvée sur cette carte.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  ..._top3.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final match = entry.value;
                    return _buildTopMatchCard(rank, match);
                  }),
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
            title: const Text(
              'Inviter la table',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              _ouvertureEnCours
                  ? 'Ouverture de la table…'
                  : (_codeServeur != null
                      ? 'Code $_codeServeur — ou faites scanner le QR'
                      : 'Hors ligne : ajoutez vos convives à la main ci-dessus'),
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
                    const Text('CODE DE LA TABLE',
                        style: TextStyle(
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
                    const Text(
                      'À saisir dans Chatmelier, onglet Dégustation',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: StylizedChatmelierQr(
                sessionId: _tableSessionId,
                title: 'CONSENSUS DE TABLE CHATMELIER',
                icon: Icons.groups_rounded,
                customUrl: MenuTableSessionManager.buildQrUrl(
                  sessionId: _tableSessionId,
                  menu: widget.menu,
                ),
                shareMessage: _codeServeur != null
                    ? 'Rejoins notre table sur Chatmelier pour choisir le vin ensemble ! '
                        'Code : $_codeServeur — ou clique ici : '
                        '${MenuTableSessionManager.buildQrUrl(sessionId: _tableSessionId, menu: widget.menu)}'
                    : 'Rejoins notre table sur Chatmelier pour choisir le vin ensemble ! '
                        '${MenuTableSessionManager.buildQrUrl(sessionId: _tableSessionId, menu: widget.menu)}',
                shareSubject: _codeServeur != null
                    ? 'Table Chatmelier — code $_codeServeur'
                    : 'Table Chatmelier',
                size: 260,
              ),
            ),
          ],
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
                      '${match.harmonyScore.toStringAsFixed(0)}% accord',
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
                    Text(guest.name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
