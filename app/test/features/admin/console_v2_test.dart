import 'package:chatmelier/features/admin/data/admin_console_service.dart';
import 'package:chatmelier/features/admin/domain/admin_console.dart';
import 'package:chatmelier/features/admin/domain/admin_economie.dart';
import 'package:chatmelier/features/admin/presentation/admin_console_onglets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La console, deuxième version (V2.4 · R9) : réglages, retours suivis, détails.
void main() {
  group('les réglages', () {
    final reglages = ReglagesDeLaConsole.fromJson({
      'reglages': {
        'scan_etiquette_recherche': {'valeur': false, 'maj_le': '2026-10-07T20:00:00Z'},
        'modeles_ia': {
          'valeur': {
            'scan_carte': {'modele': 'gemini-3.5-flash-lite', 'reflexion': 'minimal'},
            'vin_depuis_texte': {'modele': 'flash', 'reflexion': 'low'},
          },
        },
        'version_minimale_test': {'valeur': {'build': 74, 'lien': 'https://play.google.com/x', 'message': 'Mettez à jour'}},
      },
      'modeles_servis': [
        {'modele': 'gemini-3.8-flash', 'appels': 120},
      ],
      'journal': [
        {'cle': 'scan_etiquette_recherche', 'avant': true, 'apres': false, 'le': '2026-10-07T20:00:00Z', 'par': 'Flavien'},
      ],
    });

    test('les valeurs, les modèles servis et le journal se lisent', () {
      expect(reglages.interrupteur('scan_etiquette_recherche'), isFalse);
      expect(reglages.modelesIa['scan_carte']?['modele'], 'gemini-3.5-flash-lite');
      expect(reglages.modelesServis.single.appels, 120);
      expect(reglages.journal.single.resume, 'oui → non');
      expect(reglages.journal.single.par, 'Flavien');
    });

    test('un réglage de modèle se lit en clair, famille comprise', () {
      expect(TachesIa.reglage(reglages.modelesIa['scan_carte']), 'gemini-3.5-flash-lite, réflexion minimale');
      expect(TachesIa.reglage(reglages.modelesIa['vin_depuis_texte']), 'Le plus récent Flash, réflexion basse');
      expect(TachesIa.reglage({'modele': 'pro', 'reflexion': null}), 'Le plus récent Pro, réflexion par défaut');
    });

    test('un changement dit ce qui a changé, et seulement cela', () {
      expect(
        DescriptionDeReglage.difference(
          'modeles_ia',
          {'scan_carte': {'modele': 'gemini-3.8-flash', 'reflexion': 'low'}, 'chat': {'modele': 'flash', 'reflexion': 'low'}},
          {'scan_carte': {'modele': 'gemini-3.5-flash-lite', 'reflexion': 'minimal'}, 'chat': {'modele': 'flash', 'reflexion': 'low'}},
        ),
        'Lire une carte des vins : gemini-3.8-flash, réflexion basse → gemini-3.5-flash-lite, réflexion minimale',
      );
      expect(DescriptionDeReglage.difference('version_minimale_test', {'build': 74}, {'build': 77}), 'build 74 → 77');
      expect(
        DescriptionDeReglage.difference('quotas_ia', {'chat': {'compte': 60, 'anonyme': 10}}, {'chat': {'compte': 80, 'anonyme': 10}}),
        'chat 60/10 → 80/10',
      );
      expect(DescriptionDeReglage.difference('ecpm_eur_estime', {'rewarded': 8.0}, {'rewarded': 6.5}), 'rewarded 8,0 € → 6,5 €');
    });
  });

  group('les retours, les versions, l\'économie', () {
    test('un retour se lit, statut et capture compris', () {
      final r = RetourSuivi.fromJson({
        'id': 'a',
        'quand': '2026-10-07T18:09:00Z',
        'qui': 'Caro',
        'plateforme': 'iOS',
        'version': '1.6.0+76',
        'commentaire': 'ajoute une option neutre',
        'capture': 'u/c.png',
        'annotations': true,
        'statut': 'en_cours',
      });
      expect(r.statut, StatutDeRetour.enCours);
      expect(r.statut.ouvert, isTrue);
      expect(r.capture, 'u/c.png');
      expect(StatutDeRetour.depuis('inconnu'), StatutDeRetour.aTraiter);
      expect(RetourSuivi.fromJson({'id': 'b', 'qui': null, 'commentaire': 'x'}).qui, 'Anonyme');
    });

    test('le coût d\'une tâche de taches-ia se lit en clair, pas sous son code', () {
      expect(const LigneDeCout('vin_depuis_texte', 2, 0.0013).libelle, 'Identifier un vin depuis son nom');
      expect(const LigneDeCout('synthese_table', 3, 0.0013).libelle, 'Synthèse de table');
      expect(const LigneDeCout('menu_scan_vision', 9, 0.17).libelle, 'Scan de carte');
      expect(const LigneDeCout('inconnue', 1, 0).libelle, 'inconnue');
    });

    test('le build d\'une version se lit pour repérer qui est en retard', () {
      VersionInstallee v(String version) =>
          VersionInstallee.fromJson({'plateforme': 'iOS', 'version': version, 'personnes': 1, 'qui': 'Caro'});
      expect(v('1.6.0+76').build, 76);
      expect(v('1.6.0+77-pages').build, 77);
      expect(v('dev').build, isNull);
    });

    test('l\'économie jour par jour garde les trous (pas de scan ce jour-là)', () {
      final d = DetailEconomique.fromJson({
        'par_jour': [
          {'jour': '2026-10-06', 'cout_eur': 0.02, 'appels': 3, 'revenu_eur': 0.008, 'impressions': 1, 'carte_moyen_eur': 0.0076},
          {'jour': '2026-10-07', 'cout_eur': 0, 'appels': 0, 'revenu_eur': 0, 'impressions': 0},
        ],
        'par_modele': [
          {'modele': 'gemini-3.5-flash-lite', 'appels': 2, 'cout_eur': 0.015, 'cout_moyen_eur': 0.0075, 'entree_moyenne': 1600, 'sortie_moyenne': 260},
        ],
        'recherches_du_mois': 12,
        'franchise_mensuelle': 5000,
      });
      expect(d.parJour.first.carteMoyenEur, 0.0076);
      expect(d.parJour.last.carteMoyenEur, isNull);
      expect(d.parModele.single.entreeMoyenne, 1600);
      expect(d.recherchesDuMois, 12);
    });
  });

  group('les écrans', () {
    final retours = [
      const RetourSuivi(id: '1', qui: 'Caro', commentaire: 'préviens que c\'est le tour de Caro', statut: StatutDeRetour.aTraiter),
      const RetourSuivi(id: '2', qui: 'Dimitri', commentaire: 'add a third option to save but not rate', statut: StatutDeRetour.resolu),
      const RetourSuivi(id: '3', qui: 'Flavien', commentaire: 'affiche le pays aussi ici', statut: StatutDeRetour.enCours),
    ];

    Future<void> ouvrir(WidgetTester tester, Widget onglet) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          adminRetoursProvider.overrideWith((ref) async => retours),
          adminReglagesProvider.overrideWith((ref) async => ReglagesDeLaConsole.fromJson({
                'reglages': {
                  'scan_etiquette_recherche': {'valeur': false},
                  'modeles_ia': {
                    'valeur': {'scan_carte': {'modele': 'gemini-3.5-flash-lite', 'reflexion': 'minimal'}},
                  },
                  'quotas_ia': {
                    'valeur': {'chat': {'compte': 60, 'anonyme': 10}},
                  },
                },
                'journal': [],
              })),
        ],
        child: MaterialApp(home: Scaffold(body: onglet)),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('les retours : à faire d\'abord, résolus à part', (tester) async {
      await ouvrir(tester, const OngletRetours());
      expect(find.text('À faire (2)'), findsOneWidget);
      expect(find.textContaining('tour de Caro'), findsOneWidget);
      expect(find.textContaining('affiche le pays'), findsOneWidget);
      expect(find.textContaining('save but not rate'), findsNothing, reason: 'un retour résolu n\'est plus « à faire »');
      await tester.tap(find.text('Résolus (1)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('save but not rate'), findsOneWidget);
      expect(find.textContaining('tour de Caro'), findsNothing);
    });

    testWidgets('les réglages : interrupteurs, modèles d\'IA et quotas se lisent', (tester) async {
      await ouvrir(tester, const OngletReglages());
      expect(find.text('Recherche Google au scan d\'étiquette'), findsOneWidget);
      expect(find.text('Lire une carte des vins'), findsOneWidget);
      expect(find.text('gemini-3.5-flash-lite, réflexion minimale'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('60 par compte · 10 sans compte'), 200);
      expect(find.text('60 par compte · 10 sans compte'), findsOneWidget);
    });
  });
}
