import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Depuis la V2.3, toute l'IA passe par les fonctions du serveur (scan-label, scan-menu,
/// menu-chat, chat, taches-ia). La clé Gemini embarquée a été retirée le 14/09 : un appel
/// direct à Google depuis l'app ne peut qu'échouer, en silence, comme le faisaient l'import
/// Excel et le chat jusqu'au 30/09. Ce test garde la porte fermée.
void main() {
  test('aucun appel direct à Google ni clé Gemini dans le code de l\'app', () {
    final fautifs = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final texte = f.readAsStringSync();
      if (texte.contains('generativelanguage.googleapis.com') || texte.contains("'GEMINI_API_KEY'")) {
        fautifs.add(f.path);
      }
    }
    expect(fautifs, isEmpty, reason: 'appel direct ou clé Gemini dans : ${fautifs.join(', ')}');
  });
}
