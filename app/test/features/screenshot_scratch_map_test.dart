import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  testWidgets('Capture ScratchMapScreen Mobile & Desktop', skip: true, (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
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
      Bottle(
        id: 'b3',
        cellarId: 'c1',
        wineId: 'w3',
        addedBy: 'u1',
        ownerId: 'u1',
        createdAt: DateTime.now(),
        wine: const Wine(
          id: 'w3',
          name: 'Barolo Monfortino',
          region: 'Piémont',
          appellation: 'Barolo',
          country: 'Italie',
          type: 'red',
        ),
      ),
    ];

    final keyMobile = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUserBottlesProvider.overrideWith((ref) async => dummyBottles),
          tastingLogProvider.overrideWith((ref) async => <TastingEntry>[]),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: RepaintBoundary(
            key: keyMobile,
            child: const ScratchMapScreen(),
          ),
        ),
      ),
    );

    // Let the FutureProvider resolve and widgets settle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final boundaryMobile = keyMobile.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imageMobile = await boundaryMobile.toImage(pixelRatio: 1.0);
    final byteDataMobile = await imageMobile.toByteData(format: ui.ImageByteFormat.png);
    final bytesMobile = byteDataMobile!.buffer.asUint8List();

    final dir = Directory('/home/flavien-daussy/.gemini/antigravity/brain/317339a5-0319-42fe-82ff-2181e50518fd');
    File('${dir.path}/scratch_map_mobile.png').writeAsBytesSync(bytesMobile);
    print('Saved ${bytesMobile.length} bytes to scratch_map_mobile.png');

    // 2. Desktop Capture (1200 x 800)
    tester.view.physicalSize = const Size(1200 * 2, 800 * 2);
    tester.view.devicePixelRatio = 2.0;

    final keyDesktop = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUserBottlesProvider.overrideWith((ref) async => dummyBottles),
          tastingLogProvider.overrideWith((ref) async => <TastingEntry>[]),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: RepaintBoundary(
            key: keyDesktop,
            child: const ScratchMapScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final boundaryDesktop = keyDesktop.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imageDesktop = await boundaryDesktop.toImage(pixelRatio: 1.0);
    final byteDataDesktop = await imageDesktop.toByteData(format: ui.ImageByteFormat.png);
    final bytesDesktop = byteDataDesktop!.buffer.asUint8List();

    File('${dir.path}/scratch_map_desktop.png').writeAsBytesSync(bytesDesktop);
    print('Saved ${bytesDesktop.length} bytes to scratch_map_desktop.png');
  });
}
