import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../domain/blind_battle_models.dart';
import '../data/blind_battle_service.dart';
import 'widgets/stylized_chatmelier_qr.dart';

class BlindBattleHostScreen extends ConsumerStatefulWidget {
  final Bottle? initialBottle;

  const BlindBattleHostScreen({super.key, this.initialBottle});

  @override
  ConsumerState<BlindBattleHostScreen> createState() => _BlindBattleHostScreenState();
}

class _BlindBattleHostScreenState extends ConsumerState<BlindBattleHostScreen> {
  Bottle? _selectedBottle;
  BlindBattleSession? _session;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedBottle = widget.initialBottle;
    if (_selectedBottle?.wine != null) {
      _initSession(_selectedBottle!.wine!);
    }
  }

  void _initSession(Wine wine) {
    setState(() => _isCreating = true);
    final session = BlindBattleManager.createSession(
      secretWine: wine,
      hostName: 'Moi (Hôte)',
    );
    setState(() {
      _session = session;
      _isCreating = false;
    });
  }

  void _revealResults() {
    if (_session == null) return;
    final revealed = BlindBattleManager.revealSession(_session!.id);
    if (revealed != null) {
      setState(() => _session = revealed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1424),
        title: const Text(
          'Blind Battle Sommelier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        elevation: 0,
      ),
      body: _isCreating
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _session == null
              ? _buildBottleSelection()
              : _buildActiveLobby(),
    );
  }

  Widget _buildBottleSelection() {
    final currentCellarId = ref.watch(currentCellarIdProvider);
    final bottlesAsync = ref.watch(bottlesProvider(currentCellarId));

    return bottlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      error: (e, st) => Center(child: Text('Erreur : $e', style: const TextStyle(color: Colors.white70))),
      data: (bottles) {
        final available = bottles.where((b) => b.quantity > 0 && b.wine != null).toList();
        if (available.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wine_bar_outlined, color: Colors.white38, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune bouteille disponible dans votre cave.',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajoutez une bouteille ou lancez une session avec notre flacon d\'initiation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Lancer avec un Grand Cru Démo'),
                    onPressed: () {
                      _initSession(const Wine(
                        id: 'demo_margaux',
                        name: 'Château Margaux Grand Cru',
                        appellation: 'Margaux',
                        region: 'Bordeaux',
                        country: 'France',
                        type: 'Rouge',
                        vintage: 2015,
                        grapes: [
                          Grape(name: 'Cabernet Sauvignon', pct: 75),
                          Grape(name: 'Merlot', pct: 20),
                        ],
                      ));
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Choisissez la bouteille mystère',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Seul vous connaitrez son identité jusqu\'à la révélation finale !',
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13),
            ),
            const SizedBox(height: 18),
            ...available.map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1627),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wine_bar_rounded, color: Color(0xFFD4AF37)),
                  ),
                  title: Text(
                    b.wine!.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${b.wine!.appellation ?? b.wine!.region} • ${b.wine!.vintage ?? 'NV'}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _initSession(b.wine!),
                    child: const Text('Choisir'),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildActiveLobby() {
    final session = _session!;
    final isRevealed = session.status == BlindSessionStatus.revealed;

    return RefreshIndicator(
      onRefresh: () async {
        final updated = BlindBattleManager.getSession(session.id);
        if (updated != null) setState(() => _session = updated);
      },
      color: const Color(0xFFD4AF37),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Carte QR Code Stylisé
          Center(
            child: StylizedChatmelierQr(
              sessionId: session.id,
              size: 200,
            ),
          ),
          const SizedBox(height: 24),

          // Révélation ou Lobby en cours
          if (isRevealed) ...[
            _buildPodium(session),
            const SizedBox(height: 24),
            _buildSecretWineCard(session.secretWine),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF22162A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.group_outlined, color: Color(0xFFD4AF37), size: 20),
                          SizedBox(width: 8),
                          Text('Dégustateurs connectés', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E3F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${session.participants.length} en table',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (session.participants.isEmpty)
                    const Text(
                      'En attente du scan des convives...',
                      style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                    )
                  else
                    ...session.participants.map((p) {
                      final hasGuessed = p.guess != null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191122),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: p.isHost ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F),
                              child: Text(
                                p.pseudo.isNotEmpty ? p.pseudo[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: p.isHost ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                p.isHost ? '${p.pseudo} (Hôte)' : p.pseudo,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (hasGuessed)
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text('Prêt', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                ],
                              )
                            else
                              const Row(
                                children: [
                                  Icon(Icons.hourglass_top_rounded, color: Colors.white38, size: 16),
                                  SizedBox(width: 4),
                                  Text('En dégustation', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF1E1424),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFF1E1424)),
                      label: const Text(
                        'Révéler la bouteille mystère & le Podium !',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: _revealResults,
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

  Widget _buildPodium(BlindBattleSession session) {
    final participants = List<BlindParticipant>.from(session.participants)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF331D3A), Color(0xFF1B1123)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFD4AF37), size: 28),
              SizedBox(width: 10),
              Text(
                'PODIUM DU SOMMELIER',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Podium visuel
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2ème place
              if (participants.length > 1)
                _buildPodiumStep(
                  place: 2,
                  participant: participants[1],
                  height: 100,
                  color: const Color(0xFFC0C0C0),
                ),
              // 1ère place
              if (participants.isNotEmpty)
                _buildPodiumStep(
                  place: 1,
                  participant: participants[0],
                  height: 140,
                  color: const Color(0xFFD4AF37),
                ),
              // 3ème place
              if (participants.length > 2)
                _buildPodiumStep(
                  place: 3,
                  participant: participants[2],
                  height: 80,
                  color: const Color(0xFFCD7F32),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Détail des scores
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),
          ...participants.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final p = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF191122),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text('#$idx', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.pseudo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (p.guess != null)
                          Text(
                            'Pari : ${p.guess!.grape.isNotEmpty ? p.guess!.grape : p.guess!.color} • ${p.guess!.region}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${p.totalScore} pts',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required int place,
    required BlindParticipant participant,
    required double height,
    required Color color,
  }) {
    final emoji = place == 1 ? '👑' : (place == 2 ? '🥈' : '🥉');
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            participant.pseudo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            '${participant.totalScore} pts',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color.withOpacity(0.3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: color),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$place',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretWineCard(Wine wine) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF24182D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_rounded, color: Color(0xFFD4AF37), size: 22),
              SizedBox(width: 8),
              Text(
                'Identité du Flacon Mystère',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            wine.name,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${wine.appellation ?? wine.region} • ${wine.country} • ${wine.vintage ?? 'Non Millésimé'}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (wine.grapes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Cépages : ${wine.grapes.map((g) => g.pct != null ? "${g.name} (${g.pct!.toInt()}%)" : g.name).join(", ")}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
