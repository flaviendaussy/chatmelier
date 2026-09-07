import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/feedback/presentation/feedback_annotation_sheet.dart';
import 'package:chatmelier/features/feedback/data/shake_feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cellar Wine vs Spirit Partition & Adaptive Filtering', () {
    const redWine = Wine(
      id: 'w_red',
      name: 'Château Margaux',
      producer: 'Château Margaux',
      vintage: 2015,
      type: 'red',
      region: 'Bordeaux',
      country: 'France',
    );

    const whiteWine = Wine(
      id: 'w_white',
      name: 'Chablis Premier Cru',
      producer: 'Domaine Laroche',
      vintage: 2021,
      type: 'white',
      region: 'Bourgogne',
      country: 'France',
    );

    const ginBottle = Wine(
      id: 's_gin',
      name: 'Tanqueray London Dry Gin',
      producer: 'Tanqueray',
      type: 'gin',
      region: 'London',
      country: 'UK',
    );

    const grappaBottle = Wine(
      id: 's_grappa',
      name: 'Grappa di Sassicaia',
      producer: 'Poli Distillerie',
      type: 'grappa',
      region: 'Veneto',
      country: 'Italy',
    );

    const whiskyBottle = Wine(
      id: 's_whisky',
      name: 'Lagavulin 16 ans Single Malt Scotch Whisky',
      producer: 'Lagavulin',
      type: 'whisky',
      region: 'Islay',
      country: 'Écosse',
    );

    final b1 = Bottle(
      id: 'b1',
      cellarId: 'c1',
      wineId: 'w_red',
      addedBy: 'u1',
      ownerId: 'u1',
      quantity: 3,
      createdAt: DateTime.now(),
      wine: redWine,
    );

    final b2 = Bottle(
      id: 'b2',
      cellarId: 'c1',
      wineId: 'w_white',
      addedBy: 'u1',
      ownerId: 'u1',
      quantity: 2,
      createdAt: DateTime.now(),
      wine: whiteWine,
    );

    final b3 = Bottle(
      id: 'b3',
      cellarId: 'c1',
      wineId: 's_gin',
      addedBy: 'u1',
      ownerId: 'u1',
      quantity: 1,
      createdAt: DateTime.now(),
      wine: ginBottle,
    );

    final b4 = Bottle(
      id: 'b4',
      cellarId: 'c1',
      wineId: 's_grappa',
      addedBy: 'u1',
      ownerId: 'u1',
      quantity: 2,
      createdAt: DateTime.now(),
      wine: grappaBottle,
    );

    final b5 = Bottle(
      id: 'b5',
      cellarId: 'c1',
      wineId: 's_whisky',
      addedBy: 'u1',
      ownerId: 'u1',
      quantity: 1,
      createdAt: DateTime.now(),
      wine: whiskyBottle,
    );

    final allBottles = [b1, b2, b3, b4, b5];

    test('Separates wines and spirits into isolated collections without mixing', () {
      final wineBottles = allBottles.where((b) => !(b.wine?.isSpirit ?? false)).toList();
      final spiritBottles = allBottles.where((b) => (b.wine?.isSpirit ?? false)).toList();

      expect(wineBottles.length, 2);
      expect(wineBottles.map((b) => b.wine?.name), containsAll(['Château Margaux', 'Chablis Premier Cru']));

      expect(spiritBottles.length, 3);
      expect(spiritBottles.map((b) => b.wine?.name), containsAll(['Tanqueray London Dry Gin', 'Grappa di Sassicaia', 'Lagavulin 16 ans Single Malt Scotch Whisky']));

      final hasWines = wineBottles.isNotEmpty;
      final hasSpirits = spiritBottles.isNotEmpty;
      final hasBoth = hasWines && hasSpirits;
      expect(hasBoth, isTrue);
    });

    test('Detects single-category cellars (only wines or only spirits)', () {
      final onlyWinesList = [b1, b2];
      final wineCount = onlyWinesList.where((b) => !(b.wine?.isSpirit ?? false)).length;
      final spiritCount = onlyWinesList.where((b) => (b.wine?.isSpirit ?? false)).length;

      expect(wineCount, 2);
      expect(spiritCount, 0);
      expect(wineCount > 0 && spiritCount > 0, isFalse);
    });

    test('Filters spirit categories correctly by spirit type', () {
      final spiritBottles = allBottles.where((b) => (b.wine?.isSpirit ?? false)).toList();

      // Gin filter
      final ginMatches = spiritBottles.where((b) {
        final w = b.wine!;
        return w.name.toLowerCase().contains('gin') || w.type.toLowerCase().contains('gin');
      }).toList();
      expect(ginMatches.length, 1);
      expect(ginMatches.first.wine?.name, 'Tanqueray London Dry Gin');

      // Grappa filter
      final grappaMatches = spiritBottles.where((b) {
        final w = b.wine!;
        return w.name.toLowerCase().contains('grappa') || w.type.toLowerCase().contains('grappa');
      }).toList();
      expect(grappaMatches.length, 1);
      expect(grappaMatches.first.wine?.name, 'Grappa di Sassicaia');

      // Whisky filter
      final whiskyMatches = spiritBottles.where((b) {
        final w = b.wine!;
        return w.name.toLowerCase().contains('whisk') || w.type.toLowerCase().contains('whisk');
      }).toList();
      expect(whiskyMatches.length, 1);
      expect(whiskyMatches.first.wine?.name, 'Lagavulin 16 ans Single Malt Scotch Whisky');
    });

    test('Calculates 2-line header values accurately (references & bottle counts)', () {
      final wineBottles = allBottles.where((b) => !(b.wine?.isSpirit ?? false)).toList();
      final spiritBottles = allBottles.where((b) => (b.wine?.isSpirit ?? false)).toList();

      final wineTotalBottles = wineBottles.fold<int>(0, (sum, b) => sum + b.quantity);
      final spiritTotalBottles = spiritBottles.fold<int>(0, (sum, b) => sum + b.quantity);

      expect(wineBottles.length, 2); // 2 références
      expect(wineTotalBottles, 5); // 5 btl (3 Margaux + 2 Chablis)

      expect(spiritBottles.length, 3); // 3 références
      expect(spiritTotalBottles, 4); // 4 btl (1 Gin + 2 Grappa + 1 Whisky)
    });
  });

  group('ShakeFeedbackService & Annotation Sheet Tests', () {
    test('ShakeFeedbackService singleton instance exists with key', () {
      expect(ShakeFeedbackService.instance, isNotNull);
      expect(ShakeFeedbackService.rootRepaintBoundaryKey, isNotNull);
    });

    testWidgets('FeedbackAnnotationSheet renders comment input and tools', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackAnnotationSheet(
              screenshotBytes: null,
            ),
          ),
        ),
      );

      expect(find.text('Retour Testeur & Annotation'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Envoyer le rapport'), findsOneWidget);
    });
  });
}
