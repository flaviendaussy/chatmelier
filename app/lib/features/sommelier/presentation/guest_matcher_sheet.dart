import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/presentation/bottle_detail_screen.dart';
import '../../friends/data/friends_repository.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/data/taste_profile_service.dart';
import '../domain/guest_matcher_engine.dart';
import '../../../shared/utils/langue.dart';

class GuestMatcherSheet extends ConsumerStatefulWidget {
  final List<Bottle>? preloadedBottles;

  const GuestMatcherSheet({super.key, this.preloadedBottles});

  static Future<void> show(BuildContext context, {List<Bottle>? bottles}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GuestMatcherSheet(preloadedBottles: bottles),
    );
  }

  @override
  ConsumerState<GuestMatcherSheet> createState() => _GuestMatcherSheetState();
}

class _GuestMatcherSheetState extends ConsumerState<GuestMatcherSheet> {
  final List<GuestProfile> _selectedGuests = [];

  /// Le profil de la personne qui tient le téléphone : elle se lit « vous » dans les raisons.
  String? _idHote;
  bool _includeHost = true;
  List<GuestMatchResult> _results = [];
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHostAndPresets());
  }

  Future<void> _initHostAndPresets() async {
    try {
      final profiles = await ref.read(tasteProfilesListProvider.future);
      final primary = profiles.firstWhere((p) => p.isPrimary, orElse: () => profiles.first);
      if (mounted) {
        final hostGuest = GuestProfile.fromTasteProfile(primary, nom: primary.isPrimary ? tr('Moi', 'Me') : null);
        _idHote = hostGuest.id;
        setState(() {
          if (_includeHost && !_selectedGuests.any((g) => g.id == hostGuest.id)) {
            _selectedGuests.add(hostGuest);
          }
        });
        _runMatching();
      }
    } catch (_) {}
  }

  void _runMatching() {
    final cid = ref.read(currentCellarIdProvider);
    final bottles = widget.preloadedBottles ?? ref.read(bottlesProvider(cid)).value ?? [];
    if (_selectedGuests.isEmpty || bottles.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isCalculating = true);
    final ranked = GuestMatcherEngine.rankBottlesForGuests(
      bottles: bottles.where((b) => b.quantity > 0).toList(),
      guests: _selectedGuests,
      maxResults: 6,
      idLecteur: _idHote,
    );

    setState(() {
      _results = ranked;
      _isCalculating = false;
    });
  }

  void _addQuickGuestDialog() {
    final nameCtrl = TextEditingController(text: tr('Invité {v1}', 'Guest {v1}', {'v1': _selectedGuests.length + 1}));
    String selectedStyle = 'equilibre';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1A24),
          title: Text(tr('Ajouter un convive', 'Add a guest'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: tr('Prénom ou surnom', 'First name or nickname'),
                  labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                ),
              ),
              const SizedBox(height: 18),
              Text(tr('Profil gustatif estimé :', 'Their taste, roughly:'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedStyle,
                isExpanded: true,
                dropdownColor: const Color(0xFF282230),
                style: const TextStyle(color: Colors.white),
                items: [
                  DropdownMenuItem(value: 'equilibre', child: Text(tr('🍷 Curieux & Éclectique (Tout-terrain)', '🍷 Curious, likes a bit of everything'))),
                  DropdownMenuItem(value: 'puissant', child: Text(tr('🧱 Grands Rouges Puissants & Tanniques', '🧱 Big, powerful, tannic reds'))),
                  DropdownMenuItem(value: 'mineral', child: Text(tr('⚡ Blancs Tendus, Frais & Minéraux', '⚡ Crisp, fresh, mineral whites'))),
                  DropdownMenuItem(value: 'fruit', child: Text(tr('🍒 Rouges Légers & Fruit Croquant', '🍒 Light, fruity reds'))),
                  DropdownMenuItem(value: 'sans_tanin', child: Text(tr('🕊️ Aversion stricte aux tanins durs', '🕊️ Can\'t stand firm tannins'))),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => selectedStyle = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('Annuler', 'Cancel'), style: const TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty ? tr('Invité', 'Guest') : nameCtrl.text.trim();
                TasteProfile? tp;
                List<String> disliked = [];

                if (selectedStyle == 'puissant') {
                  tp = TasteProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    favoriteTypes: const ['Rouge'],
                    avgTanninPreference: 0.85,
                    avgBodyPreference: 0.85,
                    avgSpicePreference: 0.8,
                  );
                } else if (selectedStyle == 'mineral') {
                  tp = TasteProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    favoriteTypes: const ['Blanc sec', 'Champagne'],
                    avgAcidityPreference: 0.85,
                    avgMineralityPreference: 0.85,
                    avgFreshFruitPreference: 0.75,
                  );
                } else if (selectedStyle == 'fruit') {
                  tp = TasteProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    favoriteTypes: const ['Rouge'],
                    avgFreshFruitPreference: 0.85,
                    avgTanninPreference: 0.35,
                  );
                } else if (selectedStyle == 'sans_tanin') {
                  disliked = const ['Trop tannique', 'Trop lourd'];
                  tp = TasteProfile(
                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    favoriteTypes: const ['Blanc sec', 'Champagne', 'Rouge'],
                    dislikedCharacteristics: disliked,
                    avgTanninPreference: 0.2,
                  );
                }

                final newGuest = tp != null
                    ? GuestProfile.fromTasteProfile(tp)
                    : GuestProfile(id: 'guest_${DateTime.now().millisecondsSinceEpoch}', name: name);

                setState(() => _selectedGuests.add(newGuest));
                Navigator.pop(ctx);
                _runMatching();
              },
              child: Text(tr('Ajouter', 'Add'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Color(0xFF140D18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_alt, color: Color(0xFFD4AF37), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Accord Multi-Palais', 'One bottle for everyone'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tr('Consensus algorithmique & zéro déçu', 'The bottle that suits the whole table'),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
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
          const Divider(color: Colors.white10),

          // Guest Selection Chips Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ..._selectedGuests.map((g) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            backgroundColor: const Color(0xFF2E1B2D),
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
                            label: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                            onDeleted: () {
                              setState(() => _selectedGuests.remove(g));
                              _runMatching();
                            },
                          ),
                        )),
                        ActionChip(
                          backgroundColor: const Color(0xFF8B1E3F).withAlpha(60),
                          side: const BorderSide(color: Color(0xFF8B1E3F)),
                          avatar: const Icon(Icons.person_add_alt_1, size: 18, color: Color(0xFFD4AF37)),
                          label: Text(tr('+ Invité express', '+ Quick guest'), style: const TextStyle(color: Colors.white, fontSize: 13)),
                          onPressed: _addQuickGuestDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick Friend Picker Bar
          friendsAsync.when(
            data: (friends) {
              final unselectedFriends = friends.where((f) => !_selectedGuests.any((g) => g.id == f.friendUserId)).toList();
              if (unselectedFriends.isEmpty) return const SizedBox.shrink();
              return Container(
                height: 36,
                margin: const EdgeInsets.only(left: 16, bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: unselectedFriends.length,
                  itemBuilder: (ctx, i) {
                    final f = unselectedFriends[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedGuests.add(GuestProfile.fromTasteProfile(f.tasteProfile));
                          });
                          _runMatching();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 14, color: Color(0xFFD4AF37)),
                              const SizedBox(width: 4),
                              Text(f.displayName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Un palais encore deviné le dit (V2.3 · K5).
          if (PalaisDevine.legende(_selectedGuests, fr: Langue.estFr, idLecteur: _idHote) case final legende?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(legende, style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic, height: 1.3)),
            ),

          // Results Section
          Expanded(
            child: _isCalculating
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🍷', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                _selectedGuests.isEmpty
                                    ? tr('Ajoutez au moins un convive pour calculer l\'accord parfait.', 'Add at least one guest to find the right bottle.')
                                    : tr('Aucune bouteille disponible dans votre cave ne correspond aux critères.', 'No bottle in your cellar fits.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) {
                          final match = _results[i];
                          final bottle = match.bottle;
                          final wine = bottle.wine;
                          if (wine == null) return const SizedBox.shrink();

                          final isGoldMedal = i == 0;
                          final medalEmoji = isGoldMedal ? '🏆 ' : (i == 1 ? '🥈 ' : (i == 2 ? '🥉 ' : ''));

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: const Color(0xFF221626),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isGoldMedal ? const Color(0xFFD4AF37) : Colors.white12,
                                width: isGoldMedal ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$medalEmoji${wine.name}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${wine.producer} • ${wine.vintage ?? 'NV'} (${wine.region})',
                                              style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isGoldMedal
                                              ? const Color(0xFFD4AF37).withAlpha(40)
                                              : const Color(0xFF8B1E3F).withAlpha(40),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isGoldMedal ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F),
                                          ),
                                        ),
                                        child: Text(
                                          tr('{v1}% Harmonie', '{v1}% match', {'v1': match.consensusScore.toStringAsFixed(0)}),
                                          style: TextStyle(
                                            color: isGoldMedal ? const Color(0xFFD4AF37) : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Sommelier commentary
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      match.sommelierRationale,
                                      style: const TextStyle(color: Color(0xFFF3E5D8), fontSize: 13, height: 1.35),
                                    ),
                                  ),
                                  // Individual scores row
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: _selectedGuests.map((g) {
                                      final score = match.guestScores[g.id] ?? 0;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${g.name}: ${PalaisDevine.pourcentage(g, score)}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 14),
                                  // Action button
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFD4AF37),
                                        side: const BorderSide(color: Color(0xFFD4AF37)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.wine_bar, size: 18),
                                      label: Text(tr('Voir le flacon & Déboucher', 'See the bottle & open it')),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BottleDetailScreen(id: bottle.id),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
