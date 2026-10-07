import 'package:chatmelier/features/journal/domain/fiche_depuis_texte.dart';
import 'package:flutter_test/flutter_test.dart';

/// Zéro hallucination (V2.4 · R1). Le 07/10, l'étiquette d'un vin marocain (« S de Siroua »)
/// était bien lue, puis « Détecter » sur le nom a réécrit la fiche en Côtes du Rhône.
void main() {
  const lue = {'nom': 'S de Siroua', 'producteur': '', 'region': 'Maroc'};

  test('une étiquette lue n\'est jamais écrasée : seuls ses champs vides se complètent', () {
    final ecrire = FicheDepuisTexte.aEcrire(
      actuels: lue,
      proposes: {'nom': 'Côtes du Rhône', 'producteur': 'Domaine X', 'region': 'Vallée du Rhône'},
      etiquetteLue: true,
    );
    expect(ecrire, {'producteur': 'Domaine X'});
  });

  test('sans étiquette, une nouvelle détection remplace la précédente', () {
    final ecrire = FicheDepuisTexte.aEcrire(
      actuels: {'nom': 'Margaux', 'region': 'Bordeaux'},
      proposes: {'nom': 'Pauillac', 'region': 'Bordeaux'},
      etiquetteLue: false,
      remplisParLeTexte: {'nom', 'region'},
    );
    expect(ecrire, {'nom': 'Pauillac', 'region': 'Bordeaux'});
  });

  test('sans étiquette, rien d\'un autre vin ne reste : ce que la détection précédente avait mis s\'efface', () {
    final ecrire = FicheDepuisTexte.aEcrire(
      actuels: {'nom': 'Margaux', 'region': 'Bordeaux', 'producteur': 'Château Palmer'},
      proposes: {'nom': 'S de Siroua', 'region': null, 'producteur': null},
      etiquetteLue: false,
      remplisParLeTexte: {'nom', 'region'},
    );
    expect(ecrire, {'nom': 'S de Siroua', 'region': ''},
        reason: 'le producteur, tapé à la main, reste ; la région de l\'autre vin s\'efface');
  });

  test('une valeur vide ou blanche n\'écrit rien', () {
    expect(
      FicheDepuisTexte.aEcrire(actuels: const {}, proposes: {'nom': '  ', 'region': null}, etiquetteLue: false),
      isEmpty,
    );
  });
}
