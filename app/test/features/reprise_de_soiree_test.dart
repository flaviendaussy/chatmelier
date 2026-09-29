import 'dart:convert';

import 'package:chatmelier/features/auth/data/palais_distant.dart';
import 'package:chatmelier/features/auth/presentation/reprise_de_soiree_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le palais côté serveur et le code de reprise (P6).
void main() {
  group('un palais vierge', () {
    test('rien, une liste vide ou du JSON cassé : vierge', () {
      expect(PalaisDistant.vierge(null), isTrue);
      expect(PalaisDistant.vierge('[]'), isTrue);
      expect(PalaisDistant.vierge('{pas du json'), isTrue);
    });

    test('un profil par défaut, sans questionnaire ni observation : vierge', () {
      final defaut = jsonEncode([
        {'id': 'moi', 'is_primary': true, 'questionnaires_completed': 0, 'axis_observations': {'tannin': 0}},
      ]);
      expect(PalaisDistant.vierge(defaut), isTrue);
    });

    test('une seule observation suffit : on ne l\'écrase jamais', () {
      final goute = jsonEncode([
        {'id': 'moi', 'is_primary': true, 'questionnaires_completed': 0, 'axis_observations': {'acidity': 1}},
      ]);
      final questionne = jsonEncode([
        {'id': 'moi', 'is_primary': true, 'questionnaires_completed': 2, 'axis_observations': {}},
      ]);
      expect(PalaisDistant.vierge(goute), isFalse);
      expect(PalaisDistant.vierge(questionne), isFalse);
    });

    test('les trois mémoires du téléphone sont bien celles qu\'on recopie', () {
      expect(PalaisDistant.colonnes.values, ['profils', 'preuves', 'historique']);
      expect(PalaisDistant.colonnes.keys.first, 'chatmelier_taste_profiles_v2');
    });
  });

  group('la réponse du serveur', () {
    test('succès : ce qui a été retrouvé, dit en toutes lettres', () {
      final r = ResultatDeReprise.depuis({'degustations': 3, 'messages': 0, 'tables': 1, 'palais': true});
      expect(r.reussi, isTrue);
      expect(r.message, 'Soirée retrouvée : 3 dégustations, 1 table, votre palais.');
    });

    test('un code inconnu, expiré ou déjà servi : la même réponse', () {
      final r = ResultatDeReprise.depuis({'erreur': 'code_invalide'});
      expect(r.reussi, isFalse);
      expect(r.message, contains('ne correspond à aucune soirée'));
    });

    test('un compte qui a déjà son histoire n\'est pas fusionné', () {
      expect(ResultatDeReprise.depuis({'erreur': 'compte_deja_utilise'}).message, contains('ne fusionne pas'));
      expect(ResultatDeReprise.depuis({'deja': true}).reussi, isFalse);
      expect(ResultatDeReprise.depuis(null).reussi, isFalse, reason: 'jamais « retrouvée » sans preuve');
    });

    test('la saisie se normalise', () {
      expect(RepriseDeSoireeSheet.normaliser(' abcd-efgh '), 'ABCDEFGH');
      expect(RepriseDeSoireeSheet.normaliser('ABCD EFGH'), 'ABCDEFGH');
    });
  });

  Future<void> monter(WidgetTester tester, Future<ResultatDeReprise> Function(String) reprendre) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: Scaffold(body: RepriseDeSoireeSheet(reprendre: reprendre))),
    ));
  }

  testWidgets('le code saisi en minuscules avec un tiret rend la soirée', (tester) async {
    String? recu;
    await monter(tester, (code) async {
      recu = code;
      return ResultatDeReprise.depuis({'degustations': 2, 'tables': 1, 'palais': true});
    });
    final bouton = find.widgetWithText(FilledButton, 'Retrouver ma soirée');
    expect(tester.widget<FilledButton>(bouton).onPressed, isNull, reason: 'pas de code, pas de bouton');

    await tester.enterText(find.byType(TextField), 'abcd-efgh');
    await tester.pump();
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    expect(recu, 'ABCDEFGH');
    expect(find.text('Soirée retrouvée : 2 dégustations, 1 table, votre palais.'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);
  });

  testWidgets('un code invalide le dit, sans fermer la feuille', (tester) async {
    await monter(tester, (_) async => ResultatDeReprise.depuis({'erreur': 'code_invalide'}));
    await tester.enterText(find.byType(TextField), 'ZZZZZZZZ');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Retrouver ma soirée'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ne correspond à aucune soirée'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('une panne réseau ne plante pas la feuille', (tester) async {
    await monter(tester, (_) async => throw Exception('hors ligne'));
    await tester.enterText(find.byType(TextField), 'ABCDEFGH');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Retrouver ma soirée'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vérifiez votre connexion'), findsOneWidget);
  });
}
