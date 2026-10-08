import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/sommelier/data/recit_du_vin.dart';
import 'package:chatmelier/features/sommelier/presentation/sommelier_storyteller_dialog.dart';
import 'package:chatmelier/shared/services/fonctions_ia.dart';

const bandol = Wine(
  id: 'w-bandol',
  name: 'Bandol Rouge',
  producer: 'Domaine de Terrebrune',
  type: 'red',
  country: 'France',
  region: 'Provence',
  appellation: 'Bandol',
  vintage: 2019,
);

Map<String, dynamic> reponseDuServeur() => {
      'resultat': {
        'titre': 'Le Bandol de Terrebrune',
        'terroir': 'Le domaine est planté sur des sols de calcaire du Trias, face à la mer.',
        'histoire': 'L\'appellation Bandol date de 1941.',
        'verre': 'Servez-le vers 16 °C, après une heure en carafe.',
      },
      'sources': [
        {'titre': 'terrebrune.fr', 'url': 'https://vertexaisearch.cloud.google.com/grounding-api-redirect/abc'},
        {'titre': 'piège', 'url': 'javascript:alert(1)'},
      ],
      'couts': [],
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le récit et ses sources : seulement des adresses https', () {
    final r = RecitDuVin.lire(reponseDuServeur()['resultat'], reponseDuServeur()['sources'])!;
    expect(r.titre, 'Le Bandol de Terrebrune');
    expect(r.sources.map((s) => s.titre), ['terrebrune.fr']);
    expect(r.texte, contains('calcaire du Trias'));
    expect(RecitDuVin.lire({'titre': 'Vide', 'terroir': ' ', 'histoire': '', 'verre': ''}), isNull);
  });

  test('écrit à la demande, une fois : la seconde lecture vient du téléphone', () async {
    var appels = 0;
    final service = ServiceDuRecit(ia: FonctionsIa.pourEssai((f, corps) async {
      appels++;
      expect(corps['tache'], 'recit_source');
      expect(corps['appellation'], 'Bandol');
      return reponseDuServeur();
    }));
    expect((await service.ecrire(bandol))!.histoire, contains('1941'));
    expect((await service.ecrire(bandol))!.histoire, contains('1941'));
    expect(appels, 1);
  });

  Future<void> ouvrir(WidgetTester tester, ServiceDuRecit service) async {
    await tester.binding.setSurfaceSize(const Size(420, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SommelierStorytellerDialog(wine: bandol, service: service)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('le récit trouvé, avec ses sources', (tester) async {
    await ouvrir(tester, ServiceDuRecit(ia: FonctionsIa.pourEssai((f, c) async => reponseDuServeur())));
    expect(find.textContaining('calcaire du Trias'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pump();
    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('terrebrune.fr'), findsOneWidget);
    expect(find.textContaining('Récit simplifié'), findsNothing);
  });

  testWidgets('sans réseau : le récit simplifié, qui le dit, et « Réessayer »', (tester) async {
    await ouvrir(tester, ServiceDuRecit(ia: FonctionsIa.pourEssai((f, c) async => throw Exception('réseau'))));
    expect(find.textContaining('Récit simplifié'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Sources'), findsNothing);
  });
}
