import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cellar/domain/wine.dart';
import '../domain/blind_battle_models.dart';

class BlindBattleManager {
  static final Map<String, BlindBattleSession> _sessions = {};

  static String _generateSessionId() {
    final random = Random();
    final num = 100 + random.nextInt(900);
    return 'CHAT-$num';
  }

  static BlindBattleSession createSession({
    required Wine secretWine,
    required String hostName,
    String? hostId,
  }) {
    final sessionId = _generateSessionId();
    final effectiveHostId = hostId ?? 'host_${DateTime.now().millisecondsSinceEpoch}';
    final hostParticipant = BlindParticipant(
      id: effectiveHostId,
      pseudo: hostName.isEmpty ? 'Hôte Sommelier' : hostName,
      isHost: true,
      joinedAt: DateTime.now(),
    );

    final session = BlindBattleSession(
      id: sessionId,
      createdAt: DateTime.now(),
      hostId: effectiveHostId,
      secretWine: secretWine,
      status: BlindSessionStatus.waiting,
      participants: [hostParticipant],
    );

    _sessions[sessionId] = session;
    return session;
  }

  static BlindBattleSession? getSession(String sessionId) {
    return _sessions[sessionId.toUpperCase().trim()];
  }

  static BlindParticipant? joinSession({
    required String sessionId,
    required String pseudo,
    String? email,
  }) {
    final normalizedId = sessionId.toUpperCase().trim();
    var session = _sessions[normalizedId];
    if (session == null) {
      // Pour permettre le test immédiat même si le serveur distant n'est pas branché,
      // on génère une session par défaut si demandée
      session = BlindBattleSession(
        id: normalizedId,
        createdAt: DateTime.now(),
        hostId: 'host_default',
        secretWine: const Wine(
          id: 'demo_wine',
          name: 'Château Margaux',
          appellation: 'Margaux',
          region: 'Bordeaux',
          country: 'France',
          type: 'Rouge',
          vintage: 2018,
          grapes: [
            Grape(name: 'Cabernet Sauvignon', pct: 75),
            Grape(name: 'Merlot', pct: 20),
            Grape(name: 'Petit Verdot', pct: 5),
          ],
        ),
        status: BlindSessionStatus.tasting,
        participants: [],
      );
      _sessions[normalizedId] = session;
    }

    final participantId = 'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final participant = BlindParticipant(
      id: participantId,
      pseudo: pseudo.trim(),
      email: email?.trim(),
      isHost: false,
      joinedAt: DateTime.now(),
    );

    final updatedParticipants = List<BlindParticipant>.from(session.participants)..add(participant);
    _sessions[normalizedId] = session.copyWith(participants: updatedParticipants);

    return participant;
  }

  static bool submitGuess({
    required String sessionId,
    required String participantId,
    required BlindGuess guess,
  }) {
    final normalizedId = sessionId.toUpperCase().trim();
    final session = _sessions[normalizedId];
    if (session == null) return false;

    final breakdown = BlindBattleScorer.evaluate(guess: guess, secretWine: session.secretWine);
    final updatedParticipants = session.participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(
          guess: guess,
          scoreBreakdown: breakdown,
          totalScore: breakdown.totalScore,
        );
      }
      return p;
    }).toList();

    _sessions[normalizedId] = session.copyWith(participants: updatedParticipants);
    return true;
  }

  static BlindBattleSession? revealSession(String sessionId) {
    final normalizedId = sessionId.toUpperCase().trim();
    final session = _sessions[normalizedId];
    if (session == null) return null;

    final updatedParticipants = session.participants.map((p) {
      if (p.guess != null && p.scoreBreakdown == null) {
        final breakdown = BlindBattleScorer.evaluate(guess: p.guess!, secretWine: session.secretWine);
        return p.copyWith(
          scoreBreakdown: breakdown,
          totalScore: breakdown.totalScore,
        );
      }
      return p;
    }).toList();

    // Tri des participants par score décroissant pour le podium
    updatedParticipants.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    final revealed = session.copyWith(
      status: BlindSessionStatus.revealed,
      participants: updatedParticipants,
    );
    _sessions[normalizedId] = revealed;
    return revealed;
  }
}

final activeBlindSessionProvider = StateProvider.family<BlindBattleSession?, String>((ref, sessionId) {
  return BlindBattleManager.getSession(sessionId);
});
