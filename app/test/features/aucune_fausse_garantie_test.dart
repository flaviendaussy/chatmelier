import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ce que l'app ne doit plus jamais affirmer sans preuve (30/09).
///
/// Le Clio de Flavien (Bodegas El Nido, D.O. Jumilla) s'est affiché « au cœur de France »,
/// sous un badge vert « Vérifié le » daté du jour : la section « Histoire & Terroir du
/// Domaine » était un gabarit rempli dans l'app, jamais vérifié. D'autres garanties du
/// même genre ont été retirées le même jour : le drapeau « vérifié en ligne » posé après
/// chaque enrichissement par l'IA, et un « certificat de valorisation » à transmettre à
/// son assureur, calculé sur des estimations sans source.
///
/// Ce test lit le code : si l'une de ces affirmations revient, il échoue.
void main() {
  final fichiers = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('/langues/'))
      .toList();

  const interdits = <String, String>{
    'Encyclopédie Œnologique': 'une source inventée, présentée comme vérifiée',
    "'Vérifié le {": 'une date de vérification qui n\'est que la date du jour',
    "'is_verified_online': true": 'un enrichissement par l\'IA ne vérifie rien',
    "['is_verified_online'] = true": 'un enrichissement par l\'IA ne vérifie rien',
    'CERTIFICAT DE VALORISATION': 'l\'app n\'est pas un expert',
    'Document certifié': 'l\'app n\'est pas un expert',
    'Rapport d\\\'Assurance Certifié': 'l\'app n\'est pas un expert',
    'vineyardKnowledgeProvider': 'le gabarit « Histoire & Terroir du Domaine »',
    '(IA & Guides)': 'aucun guide n\'est consulté',
  };

  test('aucune garantie inventée dans le code de l\'app', () {
    final trouves = <String>[];
    for (final f in fichiers) {
      final texte = f.readAsStringSync();
      interdits.forEach((motif, raison) {
        if (texte.contains(motif)) trouves.add('${f.path} : « $motif » — $raison');
      });
    }
    expect(trouves, isEmpty, reason: trouves.join('\n'));
  });
}
