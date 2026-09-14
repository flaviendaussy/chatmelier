import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/blind_battle/domain/blind_battle_models.dart';
import 'package:chatmelier/features/blind_battle/data/blind_battle_service.dart';

void main() {
  group('Blind Battle Domain & Scoring Tests', () {
    const testWine = Wine(
      id: 'wine_test_chablis',
      name: 'Domaine Laroche Chablis Premier Cru',
      appellation: 'Chablis Premier Cru',
      region: 'Bourgogne',
      country: 'France',
      type: 'Blanc',
      vintage: 2020,
      grapes: [
        Grape(name: 'Chardonnay', pct: 100),
      ],
    );

    test('Evaluate exact guess yields high score', () {
      const perfectGuess = BlindGuess(
        color: 'Blanc',
        selectedAromaIds: ['citron', 'pomme', 'pierre', 'fleur_blanche'],
        sweetness: 'Sec',
        acidity: 'Tranchante / Vive',
        tannins: 'Nuls (Blanc)',
        caudaliesSeconds: 8,
        grape: 'Chardonnay',
        region: 'Chablis Premier Cru',
        vintage: 2020,
      );

      final breakdown = BlindBattleScorer.evaluate(
        guess: perfectGuess,
        secretWine: testWine,
      );

      expect(breakdown.colorScore, equals(20));
      expect(breakdown.grapeScore, equals(30));
      expect(breakdown.regionScore, equals(25));
      expect(breakdown.vintageScore, equals(25));
      expect(breakdown.aromasScore, equals(20));
      expect(breakdown.palateScore, equals(20));
      expect(breakdown.totalScore, equals(140));
    });

    test('Evaluate partial guess (different vintage, partial region)', () {
      const partialGuess = BlindGuess(
        color: 'Blanc',
        selectedAromaIds: ['citron'],
        sweetness: 'Sec',
        grape: 'Chardonnay',
        region: 'Bourgogne', // Region instead of specific appellation
        vintage: 2021, // 1 year diff
      );

      final breakdown = BlindBattleScorer.evaluate(
        guess: partialGuess,
        secretWine: testWine,
      );

      expect(breakdown.colorScore, equals(20));
      expect(breakdown.grapeScore, equals(30));
      expect(breakdown.regionScore, equals(20)); // Regional match
      expect(breakdown.vintageScore, equals(18)); // 1 year difference
      expect(breakdown.aromasScore, equals(5));
      expect(breakdown.totalScore, greaterThan(90));
    });

    test('Evaluate completely off guess', () {
      const wrongGuess = BlindGuess(
        color: 'Rouge',
        grape: 'Syrah',
        region: 'Bordeaux',
        vintage: 2010,
      );

      final breakdown = BlindBattleScorer.evaluate(
        guess: wrongGuess,
        secretWine: testWine,
      );

      expect(breakdown.colorScore, equals(0));
      expect(breakdown.grapeScore, equals(0));
      expect(breakdown.regionScore, equals(0));
      expect(breakdown.vintageScore, equals(0));
    });

    test('BlindBattleManager lifecycle: create, join, submit and reveal', () {
      final session = BlindBattleManager.createSession(
        secretWine: testWine,
        hostName: 'Sommelier Thomas',
      );

      expect(session.id.startsWith('CHAT-'), isTrue);
      expect(session.status, equals(BlindSessionStatus.waiting));
      expect(session.participants.length, equals(1));
      expect(session.participants.first.isHost, isTrue);

      final guest = BlindBattleManager.joinSession(
        sessionId: session.id,
        pseudo: 'Camille',
        email: 'camille@example.com',
      );

      expect(guest, isNotNull);
      expect(guest!.pseudo, equals('Camille'));

      final submitted = BlindBattleManager.submitGuess(
        sessionId: session.id,
        participantId: guest.id,
        guess: const BlindGuess(
          color: 'Blanc',
          grape: 'Chardonnay',
          region: 'Chablis',
          vintage: 2020,
        ),
      );

      expect(submitted, isTrue);

      final revealed = BlindBattleManager.revealSession(session.id);
      expect(revealed, isNotNull);
      expect(revealed!.status, equals(BlindSessionStatus.revealed));

      final revealedGuest = revealed.participants.firstWhere((p) => p.id == guest.id);
      expect(revealedGuest.totalScore, greaterThan(80));
      expect(revealedGuest.scoreBreakdown, isNotNull);
    });
  });
}
