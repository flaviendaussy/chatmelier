import 'dart:convert';

import 'package:chatmelier/features/admin/domain/contexte_de_retour.dart';
import 'package:chatmelier/features/feedback/data/retours_en_attente.dart';
import 'package:chatmelier/features/feedback/domain/contexte_du_retour.dart';
import 'package:chatmelier/features/feedback/domain/fil_d_ariane.dart';
import 'package:chatmelier/shared/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un retour doit se suffire presque sans capture (16/10 : une capture perdue faute de
/// réseau, et rien pour dire d'où venait le retour).
void main() {
  setUp(() {
    FilDAriane.vider();
    AppLogger.clear();
  });

  RetourEnAttente retour({String id = 'r1', DateTime? cree, String? capture}) => RetourEnAttente(
        id: id,
        commentaire: 'ceci devrait être la belle animation',
        annotations: true,
        userId: 'u1',
        captureLocale: null,
        captureDistante: capture,
        captureEnvoyee: false,
        contexte: const {'ecran': '/chat', 'reseau': 'serveur injoignable'},
        creeLe: cree ?? DateTime(2026, 10, 16, 18, 11, 33),
      );

  test('le fil d\'Ariane garde les derniers pas, sans répéter un même écran', () {
    FilDAriane.noterEmplacement('/');
    FilDAriane.noterEmplacement('/');
    FilDAriane.noterEmplacement('/cellar/abc');
    expect(FilDAriane.emplacement, '/cellar/abc');
    expect(FilDAriane.pas.map((p) => p.quoi), ['écran /', 'écran /cellar/abc']);
    for (var i = 0; i < 20; i++) {
      FilDAriane.noterEmplacement('/e$i');
    }
    expect(FilDAriane.pas.length, FilDAriane.tailleMax);
    expect(FilDAriane.pas.last.quoi, 'écran /e19');
  });

  testWidgets('une feuille ou un dialogue ouverts entrent dans le fil, sans leur contenu', (tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [FilDAriane.racine],
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => const Text('secret')),
          child: const Text('ouvrir'),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(FilDAriane.pas.map((p) => p.quoi), contains('racine + feuille'));
    expect(FilDAriane.pas.map((p) => p.quoi).join(), isNot(contains('secret')));
  });

  test('les avertissements récents partent avec le retour, tronqués, les anciens non', () {
    AppLogger.info('USAGE', 'rien à signaler');
    AppLogger.warning('FRIENDS', 'Could not fetch notifications: Failed host lookup ${'x' * 200}');
    final erreurs = ContexteDuRetour.erreursRecentes();
    expect(erreurs, hasLength(1));
    expect(erreurs.single, contains('FRIENDS : Could not fetch notifications'));
    expect(erreurs.single.length, lessThan(170));
    expect(ContexteDuRetour.erreursRecentes(maintenant: DateTime.now().add(const Duration(minutes: 11))), isEmpty);
  });

  test('le retour garde le format que lisent la console et « Mes retours »', () {
    final avec = retour(capture: 'u1/r1.png');
    expect(avec.message, 'Commentaire: ceci devrait être la belle animation | Capture: u1/r1.png | Annotations: oui');
    // Les expressions de `admin_retours` (060).
    expect(RegExp(r'Commentaire: (.*?) \| Capture:').firstMatch(avec.message)!.group(1), 'ceci devrait être la belle animation');
    expect(RegExp(r'\| Capture: ([^ |]+)').firstMatch(avec.message)!.group(1), 'u1/r1.png');
    expect(retour().message, contains('| Capture: aucune |'));
    final relu = RetourEnAttente.fromJson(jsonDecode(jsonEncode(avec.toJson())))!;
    expect((relu.id, relu.captureDistante, relu.contexte['ecran'], relu.creeLe), ('r1', 'u1/r1.png', '/chat', avec.creeLe));
  });

  test('la file oublie ce qui a plus de trente jours, et ne lit pas n\'importe quoi', () async {
    SharedPreferences.setMockInitialValues({
      'retours_en_attente_v1': jsonEncode([
        retour(id: 'vieux', cree: DateTime.now().subtract(const Duration(days: 31))).toJson(),
        retour(id: 'recent', cree: DateTime.now().subtract(const Duration(hours: 2))).toJson(),
        {'id': 3},
        'pas un retour',
      ]),
    });
    final attente = await RetoursEnAttente.lire();
    expect(attente.map((r) => r.id), ['recent']);
  });

  test('la console lit le contexte d\'un retour, et reconnaît un retour d\'avant la 1.10', () {
    final c = ContexteDeRetour.fromJson({
      'contexte': {
        'ecran': '/chat',
        'reseau': 'serveur injoignable : Failed host lookup',
        'fil': ['18:10:58 écran /chat'],
        'texte': 1.5,
        'erreurs': ['18:11:03 FRIENDS : Could not fetch notifications'],
      },
      'envoye_le': '2026-10-16T18:20:00',
      'capture': 'capture introuvable sur le téléphone',
      'journaux': [
        {'quand': '2026-10-16T17:11:03Z', 'niveau': 'warning', 'tag': 'FRIENDS', 'message': 'Could not fetch'},
      ],
    });
    expect((c.ecran, c.texte, c.fil.length, c.erreurs.length, c.journaux.single.tag), ('/chat', 1.5, 1, 1, 'FRIENDS'));
    expect(c.envoyeLe, isNotNull);
    expect(c.sansContexte, isFalse);
    expect(ContexteDeRetour.fromJson({'contexte': {}, 'journaux': []}).sansContexte, isTrue);
  });
}
