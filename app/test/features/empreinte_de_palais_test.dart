import 'dart:typed_data';

import 'package:chatmelier/features/auth/domain/empreinte_de_palais.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/presentation/partage_empreinte_sheet.dart';
import 'package:chatmelier/features/auth/presentation/widgets/carte_empreinte.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'empreinte de palais qu'on partage (P5) : rien d'affirmé qui ne soit observé.
/// V2.6 : le palais d'une famille, celle que la personne connaît le mieux.
void main() {
  tearDown(() => Langue.estFr = true);

  // Un amateur de tanins, bien observé sur les tanins et le corps — un palais d'avant,
  // appris toutes couleurs confondues.
  const amateur = TasteProfile(
    id: 'moi',
    name: 'Moi',
    isPrimary: true,
    avgTanninPreference: 0.85,
    avgBodyPreference: 0.75,
    avgMineralityPreference: 0.4,
    axisObservations: {'tannin': 12, 'body': 9, 'acidity': 6, 'oak': 2},
  );

  EmpreinteDePalais lire(TasteProfile p) => EmpreinteDePalais.lire(p);

  test('« j\'aime » ne cite que des axes observés et francs', () {
    final e = lire(amateur);
    expect(e.famille, 'rouge', reason: 'les tanins ne se jugent que sur des rouges : c\'est le palais le mieux connu');
    expect(e.aime, ['tannin', 'body']);
    expect(e.phraseAime, 'J\'aime les tanins fermes et les rouges puissants');
    expect(e.aDecouvrir, ['acidity', 'oak']);
    expect(e.phraseADecouvrir, 'Encore à découvrir : la fraîcheur et le boisé');
    expect(e.degustations, 12);
    expect(e.phraseBase, startsWith('D\'après 12 dégustations'));
  });

  test('un goût du côté bas est un goût aussi ; un axe moyen ne dit rien', () {
    const p = TasteProfile(
      id: 'moi',
      name: 'Moi',
      isPrimary: true,
      palais: {'blanc': {'oak': 0.1, 'acidity': 0.8, 'body': 0.5}},
      observationsPalais: {'blanc': {'oak': 8, 'acidity': 8, 'body': 8}},
    );
    final e = EmpreinteDePalais.lire(p, famille: 'blanc');
    expect(e.phraseAime, 'J\'aime les blancs sans bois et les blancs vifs');
    expect(e.aime, isNot(contains('body')));
  });

  test('un palais déclaré mais jamais goûté n\'aime encore rien', () {
    const declare = TasteProfile(
      id: 'neuf',
      name: 'Moi',
      isPrimary: true,
      palaisDeDepart: {'tannin': 9.0, 'body': 8.5},
    );
    final e = lire(declare);
    expect(e.aime, isEmpty);
    expect(e.phraseAime, 'Mon palais commence à se dessiner');
    expect(e.phraseBase, contains('tout est deviné'));
  });

  test('en anglais', () {
    Langue.estFr = false;
    final e = lire(amateur);
    expect(e.phraseAime, 'I love firm tannins and full-bodied reds');
    expect(e.phraseADecouvrir, startsWith('Still to discover: '));
    expect(e.phraseBase, startsWith('Based on 12 tastings'));
  });

  testWidgets('la carte se capture en PNG 1080 × 1350', (tester) async {
    final cle = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: RepaintBoundary(key: cle, child: const CarteEmpreinte(profil: amateur, nom: 'Flavien')),
      ),
    ));
    await tester.pump();
    expect(find.text('Flavien'), findsOneWidget);
    expect(find.text('J\'aime les tanins fermes et les rouges puissants'), findsOneWidget);

    final png = await tester.runAsync<Uint8List?>(() => PartageEmpreinteSheet.capturer(cle));
    expect(png, isNotNull);
    // Signature PNG, puis largeur et hauteur dans l'en-tête IHDR.
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    final largeur = ByteData.sublistView(png, 16, 20).getUint32(0);
    final hauteur = ByteData.sublistView(png, 20, 24).getUint32(0);
    expect((largeur, hauteur), (1080, 1350));
  });
}
