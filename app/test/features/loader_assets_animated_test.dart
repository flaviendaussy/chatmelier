import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Vérifie que les WebP des loaders sont bien **animés**.
///
/// Contexte : `ChatmelierLoader` affiche un WebP animé et retombe sur un `.gif` via
/// l'`errorBuilder` de `Image.asset` si le WebP échoue. Ces GIF pèsent 11,5 Mo à eux seuls,
/// soit l'essentiel des assets restants de l'application. Ils ne servent à rien si le WebP
/// se décode correctement — ce que ce test établit.
///
/// `instantiateImageCodec` passe par le codec d'image de Flutter (Skia), le même sur Android,
/// iOS et web CanvasKit. Un `frameCount > 1` prouve que l'animation est lue, pas seulement
/// la première image.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String>[
    'assets/animations/loader_detective_square.webp',
    'assets/animations/loader_sommelier_square.webp',
  ];

  group('🎞️ Assets animés des loaders', () {
    for (final path in assets) {
      test('$path se décode comme une animation multi-images', () async {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Asset absent du dépôt : $path');

        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);

        expect(
          codec.frameCount,
          greaterThan(1),
          reason: '$path devrait être animé. S\'il ne contient qu\'une image, le repli GIF '
              'de chatmelier_loader.dart reste nécessaire.',
        );

        // La première image doit se décoder sans erreur et avoir des dimensions plausibles.
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0));
        expect(frame.image.height, greaterThan(0));
      });
    }

    test('aucun GIF de loader ne subsiste dans les assets embarqués', () {
      final dir = Directory('assets/animations');
      expect(dir.existsSync(), isTrue);

      final gifs = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.gif'))
          .toList();

      expect(
        gifs,
        isEmpty,
        reason: 'Les WebP étant animés, les GIF de repli sont du poids mort : '
            '${gifs.map((f) => f.uri.pathSegments.last).join(', ')}',
      );
    });
  });
}
