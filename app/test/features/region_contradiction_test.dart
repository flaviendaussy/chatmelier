import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/scan/domain/grounded_verification_budget.dart';
import 'package:chatmelier/features/scan/domain/region_contradiction.dart';

/// Vérifie que la seconde source groundée reste **rare**.
///
/// Motivé par une remontée : un Crémant du Jura affichait « Pauillac & Haut-Médoc ».
/// Le résolveur de terroir est innocent — c'est la région stockée qui était fausse,
/// écrite par l'enrichissement IA.
///
/// Le `search grounding` coûte 0,035 $ forfaitaires par requête, 119× le coût en jetons
/// de l'appel. Ces tests portent donc autant sur ce qui NE déclenche PAS que sur ce qui
/// déclenche : c'est le silence qui rend la dépense acceptable.
void main() {
  group('🔍 Détection de contradiction — locale et gratuite', () {
    test('le cas signalé est attrapé', () {
      final c = RegionContradictionDetector.detecter(
        nomDuVin: 'Crémant du Jura Brut',
        regionEnrichie: 'Bordeaux',
        appellationEnrichie: 'Pauillac',
      );
      expect(c, isNotNull);
      expect(c!.terroirDuNom.id, contains('jura'));
      expect(c.terroirEnrichi.id, contains('bordeaux'));
    });

    test('un vin cohérent ne déclenche rien', () {
      expect(
        RegionContradictionDetector.detecter(
          nomDuVin: 'Château Margaux',
          regionEnrichie: 'Bordeaux',
          appellationEnrichie: 'Margaux',
        ),
        isNull,
      );
      expect(
        RegionContradictionDetector.detecter(
          nomDuVin: 'Chablis Premier Cru Montée de Tonnerre',
          regionEnrichie: 'Bourgogne',
        ),
        isNull,
      );
    });

    test('un nom qui ne nomme aucune région ne déclenche rien', () {
      // Le cas ÉCRASANTEMENT majoritaire : la plupart des vins portent un nom de
      // domaine ou de cuvée, pas de région.
      for (final nom in [
        'Cuvée des Amoureux',
        'Les Vignes Hautes',
        'Pur Ju',
        'For My Dad',
      ]) {
        expect(
          RegionContradictionDetector.detecter(
              nomDuVin: nom, regionEnrichie: 'Bordeaux'),
          isNull,
          reason: '« $nom » ne nomme aucune région : rien à vérifier.',
        );
      }
    });

    test('sans région enrichie, il n\'y a rien à contredire', () {
      expect(
        RegionContradictionDetector.detecter(nomDuVin: 'Crémant du Jura'),
        isNull,
      );
    });

    test('les fragments de mots ne comptent pas', () {
      // « graves » ne doit pas se déclencher sur « Gravesac », ni « medoc » sur
      // « Médocain ». C'est la correspondance sur mot entier qui tient la rareté.
      expect(
        RegionContradictionDetector.detecter(
          nomDuVin: 'Domaine Gravesac Médocain',
          regionEnrichie: 'Jura',
        ),
        isNull,
      );
    });

    test('un Porto donné pour bordelais EST une contradiction', () {
      // Ce cas figurait d'abord parmi les « ne déclenche rien » de ce fichier : c'était
      // le test qui avait tort. « Porto » nomme bien une région.
      final c = RegionContradictionDetector.detecter(
        nomDuVin: 'Velhotes 10 Anos Tawny Porto',
        regionEnrichie: 'Bordeaux',
      );
      expect(c, isNotNull);
      expect(c!.terroirDuNom.countryCode, equals('PT'));
    });

    test('deux sous-zones d\'une même région ne se contredisent pas', () {
      // Quatre nœuds partagent « Bourgogne ». Sans ce filtre, tout Chablis enrichi
      // « Bourgogne » paierait une vérification pour une simple imprécision.
      expect(
        RegionContradictionDetector.detecter(
          nomDuVin: 'Chablis Premier Cru Montée de Tonnerre',
          regionEnrichie: 'Bourgogne',
        ),
        isNull,
      );
      expect(
        RegionContradictionDetector.detecter(
          nomDuVin: 'Saint-Émilion Grand Cru',
          regionEnrichie: 'Bordeaux',
        ),
        isNull,
      );
    });

    test('l\'alias le plus long l\'emporte', () {
      // « haut medoc » doit primer sur « medoc » : sinon un nom précis se ferait
      // rattacher au nœud du terme le plus générique.
      final c = RegionContradictionDetector.detecter(
        nomDuVin: 'Château du Haut-Médoc',
        regionEnrichie: 'Bordeaux',
      );
      expect(c, isNull, reason: 'Haut-Médoc EST Bordeaux : aucune contradiction.');
    });
  });

  test('un enrichissement correct ne déclenche JAMAIS de vérification', () {
    // C'est la garantie de rareté qui compte : la dépense n'est engagée que sur une
    // erreur réelle. Corpus de vins dont l'origine est correctement renseignée.
    const corpus = <(String, String)>[
      ('Château Margaux', 'Bordeaux'),
      ('Château Chêne-Vieux Cuvée Première', 'Bordeaux'),
      ('Saint-Émilion Grand Cru', 'Bordeaux'),
      ('Sauternes Château Suduiraut', 'Bordeaux'),
      ('Chablis Premier Cru', 'Bourgogne'),
      ('Gevrey-Chambertin Vieilles Vignes', 'Bourgogne'),
      ('Meursault Les Charmes', 'Bourgogne'),
      ('Crémant du Jura Brut', 'Jura'),
      ('Côte-Rôtie La Landonne', 'Vallée du Rhône'),
      ('Châteauneuf-du-Pape', 'Vallée du Rhône'),
      ('Sancerre Les Monts Damnés', 'Loire'),
      ('Pol Roger Réserve Brut', 'Champagne'),
      ('Velhotes 10 Anos Tawny Porto', 'Douro'),
      ('Barolo Cannubi', 'Piemonte'),
      ('Rioja Gran Reserva', 'Rioja'),
      // Noms qui ne nomment aucune région : le cas majoritaire.
      ('Les Vignes Hautes', 'Bourgogne'),
      ('Cuvée des Amoureux', 'Loire'),
      ('Pur Ju', 'Vin de France'),
      ('For My Dad', 'Vin de France'),
      ('Rubi Cerasus Grenache Syrah', 'Vallée du Rhône'),
    ];

    final declenches = <String>[];
    for (final (nom, region) in corpus) {
      if (RegionContradictionDetector.detecter(
              nomDuVin: nom, regionEnrichie: region) !=
          null) {
        declenches.add(nom);
      }
    }
    expect(declenches, isEmpty,
        reason: 'Aucun de ces vins n\'est mal renseigné : chaque déclenchement serait '
            'une dépense de 0,035 \$ pour rien.');
  });

  group('💰 Budget — ce qui garantit que ça reste rare', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('un vin déjà vérifié ne l\'est jamais deux fois', () async {
      final b = await GroundedVerificationBudget.ouvrir();
      expect(b.peutVerifier('Crémant du Jura'), isTrue);

      await b.enregistrerVerification('Crémant du Jura');
      expect(b.peutVerifier('Crémant du Jura'), isFalse,
          reason: 'Rouvrir la fiche d\'un vin ne doit jamais repayer un grounding.');
      expect(b.peutVerifier('Autre vin'), isTrue);
    });

    test('un échec de vérification compte aussi', () async {
      final b = await GroundedVerificationBudget.ouvrir();
      // On enregistre quelle que soit l'issue : sinon un vin dont la vérification ne
      // donne rien la relancerait à chaque ouverture.
      await b.enregistrerVerification('Vin introuvable');
      expect(b.peutVerifier('Vin introuvable'), isFalse);
    });

    test('le plafond quotidien borne le pire cas', () async {
      final b = await GroundedVerificationBudget.ouvrir();
      for (var i = 0; i < GroundedVerificationBudget.plafondQuotidien; i++) {
        expect(b.plafondAtteint, isFalse, reason: 'itération $i');
        await b.enregistrerVerification('vin_$i');
      }
      expect(b.plafondAtteint, isTrue);
      expect(b.peutVerifier('vin encore jamais vu'), isFalse,
          reason: 'Même une contradiction réelle est refusée une fois le plafond atteint : '
              'le plafond existe pour que l\'anormal reste sans conséquence.');
    });

    test('le plafond reste modeste en coût', () {
      const coutGroundingUsd = 0.035;
      final pireCasQuotidien =
          GroundedVerificationBudget.plafondQuotidien * coutGroundingUsd;
      expect(pireCasQuotidien, lessThanOrEqualTo(0.20),
          reason: 'Pire cas par appareil et par jour, à comparer aux 3,25 c€ d\'un seul '
              'scan d\'étiquette groundé.');
    });
  });
}
