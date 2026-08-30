import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/shared/widgets/empty_state.dart';
import 'package:chatmelier/features/scratchcard/presentation/scratch_map_canvas.dart';

void main() {
  testWidgets('EmptyState widget renders icon, title and description', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.wine_bar,
            title: 'Cave vide',
            subtitle: 'Ajoutez votre première bouteille pour commencer.',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.wine_bar), findsOneWidget);
    expect(find.text('Cave vide'), findsOneWidget);
    expect(find.text('Ajoutez votre première bouteille pour commencer.'), findsOneWidget);
  });

  testWidgets('ScratchMapCanvas renders interactive terroirs map', (WidgetTester tester) async {
    const regions = [
      MapRegionData(
        id: 'bordeaux',
        name: 'Bordeaux',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.04, 0.58, 0.44, 0.15),
        isOwned: true,
        isDrunk: false,
        ownedCount: 2,
        drunkCount: 0,
        description: 'Bordeaux description',
      ),
      MapRegionData(
        id: 'bourgogne',
        name: 'Bourgogne',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.50, 0.43, 0.46, 0.14),
        isOwned: false,
        isDrunk: false,
        ownedCount: 0,
        drunkCount: 0,
        description: 'Bourgogne description',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: ScratchMapCanvas(
              mapMode: 'france',
              regions: regions,
              onRegionTapped: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ScratchMapCanvas), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
