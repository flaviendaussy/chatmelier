import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_pedagogy_engine.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';

/// Le débrief œnologique, confronté à ce que les utilisateurs y ont vu.
///
/// Trois remontées du même soir portaient sur la même bouteille — un Margaux 1987 :
/// « tu parles d'élevage en cuve inox (sans bois) pour ce margaux. c'est vrai ???? »,
/// « là ça parle de sous bois, de végétal noble… mais ces choix n'étaient pas là pendant
/// la dégustation, si ? », et une demande de code couleur. Toutes remontent à la même
/// cause : le moteur classait les vins par mots trouvés dans leur nom.
void main() {
  Wine vin({
    required String nom,
    String? producteur,
    String region = '',
    String? appellation,
    String type = 'red',
    int? millesime,
    List<String> cepages = const [],
  }) =>
      Wine(
        id: 'w',
        name: nom,
        producer: producteur,
        region: region,
        appellation: appellation,
        country: 'France',
        type: type,
        vintage: millesime,
        grapes: [for (final c in cepages) Grape(name: c)],
      );

  String? elevageDe(Wine w) {
    final cartes = TastingPedagogyEngine.analyze(wine: w).flavorOrigins;
    for (final c in cartes) {
      if (c.title.startsWith('Élevage')) return c.title;
    }
    return null;
  }

  group('🍷 Un Margaux est un bordeaux, même quand son nom ne le dit pas', () {
    final margaux = vin(
        nom: 'Margaux',
        producteur: 'Alexis Lichine & Cie',
        region: 'Margaux',
        millesime: 1987);

    test('il est élevé en barrique, pas en cuve inox', () {
      expect(elevageDe(margaux), contains('Barrique'),
          reason: 'la table des régions donne le Médoc communal à 18 mois de barrique');
      expect(elevageDe(margaux), isNot(contains('Inox')));
    });

    test('sa signature n\'est plus celle d\'un pinot noir', () {
      final r = TastingPedagogyEngine.analyze(wine: margaux);
      expect(r.archetypeAromas.join(' '), contains('Fruits noirs'));
      expect(r.archetypePalate, contains('tanins denses'),
          reason: 'le moteur lui prêtait des « esters du Pinot Noir »');
    });
  });

  group('🗣️ On ne compare qu\'avec des mots qu\'on a proposés', () {
    test('tout arôme attendu est un choix du questionnaire', () {
      final vocabulaire = {
        for (final o in TastingQuestionnaireResult.aromaOptions)
          '${o.emoji} ${o.label}'
      };
      for (final w in [
        vin(nom: 'Margaux', region: 'Margaux', millesime: 1987),
        vin(nom: 'Gevrey-Chambertin', region: 'Gevrey-Chambertin'),
        vin(nom: 'Chablis', region: 'Chablis', type: 'white'),
        vin(nom: 'Meursault', region: 'Côte de Beaune', type: 'white'),
        vin(nom: 'Champagne Brut', region: 'Champagne', type: 'sparkling'),
        vin(nom: 'Tavel', region: 'Tavel', type: 'rose'),
      ]) {
        for (final a in TastingPedagogyEngine.analyze(wine: w).archetypeAromas) {
          expect(vocabulaire, contains(a),
              reason: '« $a » n\'est proposé nulle part : on demandait de reconnaître '
                  'un mot qu\'on n\'a jamais montré (${w.name})');
        }
      }
    });
  });

  group('🎨 Ce qui est bien vu, à côté, ou manqué', () {
    final margaux = vin(nom: 'Margaux', region: 'Margaux', millesime: 1987);

    test('les trois verdicts sont rendus, plus le plausible', () {
      final r = TastingPedagogyEngine.analyze(
        wine: margaux,
        // fruits_noirs est attendu ; beurre est discordant ; miel n'est ni l'un ni
        // l'autre ; boise est attendu et non coché.
        //
        // Pas « fruits_rouges » : sur un 1987, le moteur l'attend justement — un vieux
        // bordeaux vire au fruit rouge patiné. Le choisir ici aurait testé ma lecture du
        // code plutôt que le code.
        perceivedAromaIds: {'fruits_noirs', 'beurre', 'miel'},
      );
      Set<String> avec(VerdictArome v) => r.comparaisonAromes
          .where((a) => a.verdict == v)
          .map((a) => a.id)
          .toSet();

      expect(avec(VerdictArome.bienVu), contains('fruits_noirs'));
      expect(avec(VerdictArome.aCote), contains('beurre'));
      expect(avec(VerdictArome.plausible), contains('miel'),
          reason: 'sentir le miel sur un bordeaux n\'est ni typique ni contradictoire');
      expect(avec(VerdictArome.manque), contains('boise'));
    });

    test('aucun arôme n\'est compté deux fois', () {
      final r = TastingPedagogyEngine.analyze(
        wine: margaux,
        perceivedAromaIds: {'fruits_noirs', 'boise', 'chocolat'},
      );
      final ids = r.comparaisonAromes.map((a) => a.id).toList();
      expect(ids.length, equals(ids.toSet().length));
    });

    test('sans arômes cochés, rien à comparer plutôt qu\'un bulletin vide', () {
      final r = TastingPedagogyEngine.analyze(wine: margaux);
      expect(r.comparaisonAromes.every((a) => a.verdict == VerdictArome.manque), isTrue,
          reason: 'personne n\'a rien raté : la dégustation était libre');
    });
  });

  group('🤐 Ne pas savoir se dit en se taisant', () {
    test('un vin hors table n\'affirme aucun élevage', () {
      final inconnu = vin(nom: 'Cuvée du Chat', region: 'Autre', millesime: 2022);
      expect(elevageDe(inconnu), isNull,
          reason: 'la branche « sinon » affirmait la cuve inox faute de savoir : '
              'l\'absence de preuve était donnée pour preuve du contraire');
    });

    test('mais un texte d\'élevage explicite est cru', () {
      final w = Wine(
        id: 'w', name: 'Cuvée du Chat', region: 'Autre', country: 'France',
        type: 'red', vintage: 2022, barrelAging: '12 mois en fûts de chêne',
      );
      expect(elevageDe(w), contains('Fût'));
    });
  });

  group('🧭 En savoir plus ne doit jamais dégrader la réponse', () {
    test('les vins que les mots-clés attrapaient déjà restent bien classés', () {
      for (final w in [
        vin(nom: 'Bandol Rouge', producteur: 'Domaine de Terrebrune', region: 'Bandol'),
        vin(nom: 'Rioja Reserva', region: 'Rioja'),
        vin(nom: 'Cahors', region: 'Cahors'),
        vin(nom: 'Madiran', region: 'Madiran'),
      ]) {
        final r = TastingPedagogyEngine.analyze(wine: w);
        expect(r.archetypeAromas.join(' '), contains('Fruits noirs'),
            reason: '${w.name} doit rester un rouge de structure');
      }
    });

    test('un chinon reste un vin de soie', () {
      final r = TastingPedagogyEngine.analyze(wine: vin(nom: 'Chinon', region: 'Chinon'));
      expect(r.archetypePalate, contains('soyeuse'),
          reason: 'un « cabernet » générique rangeait la Loire parmi les bordeaux');
    });
  });
}
