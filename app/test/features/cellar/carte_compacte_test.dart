import 'dart:io';

import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/presentation/cellar_screen.dart';
import 'package:chatmelier/shared/widgets/bottle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 17/10, Flavien, sur la grille de la cave : « il y a pas mal d'espace vide, enlèves-en un
/// peu pour compacter légèrement ». La carte rétrécit, mais la plus chargée (domaine, nom
/// sur deux lignes, lieu, jauge, prix) doit tenir, à toutes les tailles de texte : à 150 %,
/// le prix sortait de la carte (09/10).
void main() {
  testWidgets('la carte la plus chargée tient dans la grille compactée, du texte normal au double', (tester) async {
    // Les vraies mesures de Roboto, la police d'Android : celle des essais est carrée.
    final polices = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
    if (!File('$polices/Roboto-Regular.ttf').existsSync()) {
      markTestSkipped('Roboto introuvable dans le SDK Flutter');
      return;
    }
    await tester.runAsync(() async {
      final roboto = FontLoader('Roboto');
      for (final f in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf', 'Roboto-Medium.ttf', 'Roboto-Italic.ttf']) {
        roboto.addFont(Future.value(ByteData.view(File('$polices/$f').readAsBytesSync().buffer)));
      }
      await roboto.load();
    });
    SharedPreferences.setMockInitialValues({});
    final annee = DateTime.now().year;
    final chargee = Bottle(
      id: 'b',
      cellarId: 'c',
      wineId: 'w',
      addedBy: 'u',
      ownerId: 'u',
      createdAt: DateTime(2026),
      purchasePrice: 160,
      rack: 'B3',
      wine: Wine(
        id: 'w',
        name: 'Chablis Premier Cru Montée de Tonnerre Vieilles Vignes',
        producer: 'Domaine François Raveneau',
        vintage: annee - 4,
        type: 'white',
        country: 'France',
        region: 'Bourgogne',
        appellation: 'Chablis 1er Cru',
        drinkStart: annee - 2,
        peakStart: annee - 1,
        peakEnd: annee + 3,
        drinkEnd: annee + 6,
      ),
    );

    for (final facteur in [1.0, 1.3, 1.5, 2.0]) {
      final hauteur = CellarScreen.hauteurDesCartes(facteur);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(facteur)),
            child: Scaffold(
              body: Center(
                // Une clé par taille : un débordement ne se signale qu'une fois par objet.
                child: SizedBox(key: ValueKey(facteur), width: 180, height: hauteur, child: BottleCard(bottle: chargee)),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'texte à ${(facteur * 100).round()} %, carte de $hauteur');
    }
    // Plus compacte qu'avant le 17/10.
    expect(CellarScreen.hauteurDesCartes(1.0), lessThan(295));
  });
}
