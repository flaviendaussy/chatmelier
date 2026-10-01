import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/menu_scan/domain/fin_de_soiree.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// La fin de soirée (V2.3 · E2, F1).
void main() {
  test('un vin choisi garde ce qu\'il faut pour être noté, et voyage par le serveur', () {
    const w = MenuWine(id: '1', name: 'Morgon', producer: 'Marcel Lapierre', vintage: 2022, wineType: 'Red');
    final v = VinChoisi.depuisLaCarte(w);
    expect(v.cle, w.cacheKey);
    expect(v.couleur, 'red');
    expect(v.libelle, 'Morgon 2022');
    final relu = VinChoisi.fromJson(v.toJson());
    expect([relu.cle, relu.nom, relu.producteur, relu.millesime, relu.couleur],
        [v.cle, v.nom, v.producteur, v.millesime, v.couleur]);
  });

  test('la couleur, comme le journal la range', () {
    String c(String type) => couleurPourLeJournal(MenuWine(id: 'x', name: 'x', producer: '', wineType: type));
    expect(c('Sparkling'), 'sparkling');
    expect(c('Rosé'), 'rose');
    expect(c('White'), 'white');
    expect(c('Sweet'), 'dessert');
    expect(c('Red'), 'red');
  });

  test('chaque visage vaut la note qui le redonne', () {
    for (var i = 0; i < NoteDUnGeste.visages.length; i++) {
      expect(TastingQuestionnaireResult.emojiIndexForRating(NoteDUnGeste.notes[i]), i);
      expect(TastingQuestionnaireResult.emojiLabels[i], NoteDUnGeste.visages[i]);
    }
  });

  test('l\'état de la table se relit tel que le serveur le rend', () {
    final etat = EtatDeTable.fromRow({
      'choix': [
        {'cle': 'k', 'nom': 'Barolo', 'millesime': 2019, 'couleur': 'red'},
      ],
      'resultat': {'podium': []},
      'resultat_publie_le': '2026-10-01T20:00:00Z',
    });
    expect(etat.choix.single.libelle, 'Barolo 2019');
    expect(etat.resultat, isNotNull);
    expect(etat.publieLe, DateTime.utc(2026, 10, 1, 20));
    expect(EtatDeTable.fromRow(const {}).choix, isEmpty);
  });

  test('le résultat publié nomme les convives, jamais par leur identifiant', () {
    const sancerre = MenuWine(id: 's', name: 'Sancerre', producer: 'Vacheron', vintage: 2022, wineType: 'White', bottlePrice: 42);
    final podium = [
      MenuTableMatchResult(
        menuWine: sancerre,
        harmonyScore: 81.4,
        consensusRationale: 'Caro et Paul l\'apprécieront.',
        guestScores: const {'id-caro': 84.2, 'id-paul': 78.6},
      ),
    ];
    final r = ResultatDeTable.publier(
      restaurant: 'The Kitchin',
      langue: 'fr',
      convives: const [
        GuestProfile(id: 'id-caro', name: 'Caro'),
        GuestProfile(id: 'id-paul', name: 'Paul'),
        GuestProfile(id: 'id-lea', name: 'Léa', neBoitPas: true),
      ],
      podium: podium,
    );
    expect(r['restaurant'], 'The Kitchin');
    final premier = (r['podium'] as List).single as Map;
    expect(premier['scores'], {'Caro': 84, 'Paul': 79});
    expect(premier['accord'], 81);
    expect(premier['raison'], 'Caro et Paul l\'apprécieront.');
    expect((r['convives'] as List).last, {'nom': 'Léa', 'ne_boit_pas': true});
    expect(r.containsKey('paire'), isFalse);
  });
}
