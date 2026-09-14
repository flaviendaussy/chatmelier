import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/scratchcard/presentation/scratch_map_screen.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/features/journal/presentation/journal_screen.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('Capture ScratchMapScreen mobile view after overhaul', skip: true, (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 780 * 2);
    tester.view.devicePixelRatio = 2.0;

    final dummyBottles = [
      Bottle(
        id: 'b1',
        cellarId: 'c1',
        wineId: 'w1',
        addedBy: 'u1',
        ownerId: 'u1',
        createdAt: DateTime.now(),
        wine: const Wine(
          id: 'w1',
          name: 'Château Margaux',
          region: 'Bordeaux',
          appellation: 'Margaux',
          country: 'France',
          type: 'red',
        ),
      ),
      Bottle(
        id: 'b2',
        cellarId: 'c1',
        wineId: 'w2',
        addedBy: 'u1',
        ownerId: 'u1',
        createdAt: DateTime.now(),
        wine: const Wine(
          id: 'w2',
          name: 'Romanée-Conti',
          region: 'Bourgogne',
          appellation: 'Vosne-Romanée',
          country: 'France',
          type: 'red',
        ),
      ),
    ];

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUserBottlesProvider.overrideWith((ref) async => dummyBottles),
          tastingLogProvider.overrideWith((ref) async => <TastingEntry>[]),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: RepaintBoundary(
            key: repaintKey,
            child: const ScratchMapScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = Directory('/home/flavien-daussy/.gemini/antigravity/brain/317339a5-0319-42fe-82ff-2181e50518fd');
    File('${dir.path}/scratch_map_mobile_after.png').writeAsBytesSync(bytes);
    print('Saved ${bytes.length} bytes to scratch_map_mobile_after.png');
  });
}
