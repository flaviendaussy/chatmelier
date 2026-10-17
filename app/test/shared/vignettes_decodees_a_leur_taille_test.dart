import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/shared/widgets/bottle_image_view.dart';

/// 15/10 : « le Scroll haut/bas saccade légèrement de temps en temps ». Les vignettes de la
/// cave décodaient les photos d'étiquettes en pleine résolution (2 000 pixels pour 180), et
/// chaque carte interrogeait le disque à chaque construction.
void main() {
  Widget ecran(Widget enfant) => MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 2.625),
        child: MaterialApp(home: Scaffold(body: Center(child: enfant))),
      );

  testWidgets('une vignette se décode à sa taille d\'affichage, pas à celle de la photo', (tester) async {
    await tester.pumpWidget(ecran(const BottleImageView(
      imagePath: 'assets/animations/loader_sommelier_square.webp',
      width: 180,
      height: 120,
    )));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    // 180 × 2,625 × 1,25 ≈ 591 pixels, au lieu de la taille de la photo.
    expect((image.image as ResizeImage).width, 591);
  });

  testWidgets('une photo locale disparue rend la vignette de repli, sans planter', (tester) async {
    await tester.pumpWidget(ecran(const BottleImageView(
      imagePath: '/donnees/qui/n/existent/pas.jpg',
      wineType: 'red',
      width: 100,
      height: 100,
    )));
    // La lecture du fichier est une vraie entrée-sortie : elle s'achève hors de l'horloge du test.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(Icon), findsOneWidget, reason: 'l\'icône de la vignette de repli');
  });
}
