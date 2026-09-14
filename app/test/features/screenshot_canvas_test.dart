import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/scratchcard/presentation/scratch_map_canvas.dart';

void main() {
  testWidgets('Capture ScratchMapCanvas France after overhaul', skip: true, (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 600 * 2);
    tester.view.devicePixelRatio = 2.0;

    final franceRegions = [
      const MapRegionData(
        id: 'bordeaux',
        name: 'Bordeaux',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.04, 0.58, 0.44, 0.15),
        isOwned: true,
        isDrunk: true,
        ownedCount: 5,
        drunkCount: 3,
        description: 'Vins de Bordeaux',
      ),
      const MapRegionData(
        id: 'bourgogne',
        name: 'Bourgogne',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.50, 0.43, 0.46, 0.14),
        isOwned: true,
        isDrunk: false,
        ownedCount: 2,
        drunkCount: 0,
        description: 'Grands Crus',
      ),
      const MapRegionData(
        id: 'champagne',
        name: 'Champagne',
        country: 'France',
        flag: '🇫🇷',
        normalizedBounds: Rect.fromLTWH(0.40, 0.16, 0.44, 0.13),
        isOwned: false,
        isDrunk: false,
        ownedCount: 0,
        drunkCount: 0,
        description: 'Champagne',
      ),
    ];

    final keyFrance = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: keyFrance,
              child: SizedBox(
                width: 380,
                height: 380,
                child: ScratchMapCanvas(
                  mapMode: 'france',
                  regions: franceRegions,
                  onRegionTapped: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final boundary = keyFrance.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = Directory('/home/flavien-daussy/.gemini/antigravity/brain/317339a5-0319-42fe-82ff-2181e50518fd');
    File('${dir.path}/canvas_france_after.png').writeAsBytesSync(bytes);
    print('Saved ${bytes.length} bytes to canvas_france_after.png');
  });
}
