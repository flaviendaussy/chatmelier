import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatmelier/features/cellar/presentation/terroir_map_view.dart';

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

  testWidgets('Capture TerroirMapView Pauillac after refactor', skip: true, (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: const SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: TerroirMapView(
                    country: 'France',
                    region: 'Bordeaux',
                    appellation: 'Pauillac',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = Directory('/home/flavien-daussy/.gemini/antigravity/brain/317339a5-0319-42fe-82ff-2181e50518fd');
    File('${dir.path}/test_terroir_pauillac_after.png').writeAsBytesSync(bytes);
    print('Saved ${bytes.length} bytes to test_terroir_pauillac_after.png');
  });
}
