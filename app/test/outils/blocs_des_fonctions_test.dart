import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les fonctions edge et leurs modèles (V2.3 · K8). Le déploiement par le Dashboard demande
/// un fichier unique par fonction : le bloc commun des modèles Gemini y est recopié par
/// `python3 tool/fonctions/synchroniser.py`. Ce test échoue si une copie a divergé, ou si une
/// version de Gemini est réécrite en dur dans le code d'une fonction.
void main() {
  const fonctions = ['chat', 'menu-chat', 'scan-label', 'scan-menu', 'taches-ia', 'update-wine-values'];
  final source = File('../tool/fonctions/bloc_modeles_gemini.ts').readAsStringSync().trim();

  for (final nom in fonctions) {
    final code = File('../supabase/functions/$nom/index.ts').readAsStringSync();

    test('$nom porte la copie à jour du bloc des modèles', () {
      expect(code.contains(source), isTrue,
          reason: 'lancer : python3 tool/fonctions/synchroniser.py');
    });

    test('$nom ne nomme aucune version de Gemini dans son code', () {
      final versions = [
        for (final ligne in code.split('\n'))
          if (!ligne.trimLeft().startsWith('//') && RegExp(r'gemini-\d').hasMatch(ligne)) ligne.trim(),
      ];
      expect(versions, isEmpty, reason: 'le modèle se règle dans app_config.modeles_ia, pas dans le code');
    });
  }
}
