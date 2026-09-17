import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/aging_reference.dart';
import 'package:chatmelier/features/cellar/domain/wine_service_advisor.dart';

/// La fenêtre d'apogée, qui est au centre de la fiche d'un vin.
///
/// Remonté par un utilisateur : un Margaux 1987 affichait une apogée 1989-1991 — deux
/// ans après la vendange — et « PASSÉ L'APOGÉE ». Audit sur une cave réelle de
/// 41 bouteilles : 78 % des fenêtres renvoyées par l'enrichissement étaient plus courtes
/// que ce que la catégorie du vin implique, de 4,3 ans en moyenne.
///
/// Cause : le code acceptait la fenêtre de l'IA dès qu'elle était cohérente AVEC
/// ELLE-MÊME, sans jamais la confronter à l'appellation. La table de savoir métier
/// n'était consultée que si l'IA ne répondait rien — l'inverse de ce qu'il faudrait.
void main() {
  ({int debut, int fin, int picDebut, int picFin}) fenetre({
    required String type,
    required int millesime,
    String? pays,
    String? region,
    String? appellation,
    String? classification,
    String? nom,
    List<String> cepages = const [],
    int? iaDebut,
    int? iaFin,
  }) {
    final w = WineOenologyAdvisor.computeDrinkingWindow(
      wineType: type,
      vintage: millesime,
      country: pays,
      region: region,
      appellation: appellation,
      classification: classification,
      wineName: nom,
      grapes: cepages,
      explicitDrinkStart: iaDebut,
      explicitDrinkEnd: iaFin,
    );
    return (
      debut: w.drinkStart - millesime,
      fin: w.drinkEnd - millesime,
      picDebut: w.peakStart - millesime,
      picFin: w.peakEnd - millesime,
    );
  }

  group('🍷 Le cas signalé', () {
    test('un Margaux ne meurt pas douze ans après la vendange', () {
      final f = fenetre(
        type: 'red', millesime: 1987, region: 'Bordeaux', appellation: 'Margaux',
        nom: 'Château X', iaDebut: 1989, iaFin: 1999,
      );
      expect(f.fin, greaterThanOrEqualTo(20),
          reason: 'L\'IA disait 12 ans. Un Bordeaux du Médoc en tient vingt.');
      expect(f.picDebut, greaterThanOrEqualTo(6),
          reason: 'Un pic à quatre ans est absurde pour un Margaux.');
    });

    test('le rang du vin change la longévité dans la même appellation', () {
      final simple = fenetre(
        type: 'red', millesime: 1987, region: 'Bordeaux', appellation: 'Margaux',
        nom: 'Château X', iaDebut: 1989, iaFin: 1999,
      );
      final premier = fenetre(
        type: 'red', millesime: 1987, region: 'Bordeaux', appellation: 'Margaux',
        nom: 'Château Margaux', classification: 'Premier Grand Cru Classé',
        iaDebut: 1989, iaFin: 1999,
      );
      expect(premier.fin, greaterThan(simple.fin + 10),
          reason: 'Deux Margaux n\'ont pas la même longévité : c\'est la dimension qui '
              'manquait entièrement.');
    });
  });

  group('🍯 La catégorie qui manquait : les vins doux', () {
    test('un Sauternes n\'est pas un Sancerre', () {
      final f = fenetre(
        type: 'Moelleux', millesime: 2022, region: 'Bordeaux',
        appellation: 'Sauternes', iaDebut: 2023, iaFin: 2030,
      );
      expect(f.fin, greaterThanOrEqualTo(30),
          reason: 'Avant, un Sauternes tombait dans « blancs frais » : sept ans. Un '
              'Sauternes se garde vingt à cent ans.');
    });

    test('un Porto Vintage tient des décennies', () {
      final f = fenetre(
        type: 'Fortifié', millesime: 2016, pays: 'Portugal',
        appellation: 'Vintage Port',
      );
      expect(f.fin, greaterThanOrEqualTo(40));
    });
  });

  group('🌍 Hors de France', () {
    test('un Aglianico du Vulture n\'est pas un rouge générique', () {
      final f = fenetre(
        type: 'red', millesime: 2018, pays: 'Italie',
        appellation: 'Aglianico del Vulture', cepages: ['Aglianico'],
      );
      expect(f.fin, greaterThanOrEqualTo(20),
          reason: 'Avant, il tombait dans le générique par couleur : douze ans.');
    });

    test('un Barolo vit plus longtemps qu\'un Chianti', () {
      final barolo = fenetre(
          type: 'red', millesime: 2018, pays: 'Italie', appellation: 'Barolo');
      final chianti = fenetre(
          type: 'red', millesime: 2018, pays: 'Italie', appellation: 'Chianti Classico');
      expect(barolo.fin, greaterThan(chianti.fin));
    });

    test('un chilien, un espagnol et un australien sont reconnus', () {
      expect(fenetre(type: 'red', millesime: 2020, pays: 'Chili',
              appellation: 'Valle del Maipo').fin, greaterThan(12));
      expect(fenetre(type: 'white', millesime: 2024, pays: 'Portugal',
              appellation: 'Vinho Verde').fin, lessThan(12));
      expect(fenetre(type: 'red', millesime: 2020, pays: 'Australie',
              appellation: 'Barossa Valley').fin, greaterThan(15));
    });
  });

  group('🌹 Les rosés ne sont pas une seule catégorie', () {
    test('un Bandol rosé n\'est pas un rosé de soif', () {
      // Porté par le mourvèdre, il tient 5 à 10 ans — et Domaine de Terrebrune en sert
      // couramment des bouteilles de vingt ans. Il tombait dans le rosé générique :
      // trois ans, soit la pire erreur possible sur ce vin.
      final bandol = fenetre(
          type: 'Rosé', millesime: 2022, region: 'Provence', appellation: 'Bandol',
          nom: 'Domaine de Terrebrune');
      final provence = fenetre(
          type: 'Rosé', millesime: 2022, region: 'Provence',
          appellation: 'Côtes de Provence');
      expect(bandol.fin, greaterThanOrEqualTo(10));
      expect(bandol.fin, greaterThan(provence.fin + 5));
    });

    test('un Tavel n\'hérite pas de la garde des crus du Rhône', () {
      // Tavel figurait parmi les crus du Rhône méridional, règle sans contrainte de
      // couleur : ce rosé y recevait vingt ans.
      final f = fenetre(type: 'Rosé', millesime: 2023, appellation: 'Tavel');
      expect(f.fin, lessThanOrEqualTo(10));
    });

    test('un Bandol blanc se garde aussi', () {
      final f = fenetre(
          type: 'Blanc', millesime: 2022, region: 'Provence', appellation: 'Bandol');
      expect(f.fin, greaterThanOrEqualTo(10));
    });
  });

  test('le mourvèdre espagnol vaut le mourvèdre français', () {
    // Jumilla, Yecla, Alicante : même cépage que le Bandol, même aptitude à la garde,
    // et absents de la table — ils tombaient dans le générique espagnol.
    final f = fenetre(
        type: 'red', millesime: 2019, pays: 'Espagne', appellation: 'Jumilla',
        nom: 'Clio', cepages: ['Monastrell']);
    expect(f.fin, greaterThanOrEqualTo(14),
        reason: 'El Nido « Clio » est donné pour 10 à 15 ans.');
  });

  group('🛡️ Ce que l\'enveloppe rejette', () {
    test('une fenêtre qui commence avant la vendange est impossible', () {
      // Constaté en cave : un « Pur Ju 2024 » avec un début en 2023.
      final f = fenetre(
        type: 'red', millesime: 2024, region: 'IGP Méditerranée',
        iaDebut: 2023, iaFin: 2025,
      );
      expect(f.debut, greaterThanOrEqualTo(0),
          reason: 'On ne boit pas un vin avant de l\'avoir vendangé.');
    });

    test('une fenêtre plausible est conservée telle quelle', () {
      // L'IA connaît le domaine et le millésime : quand elle reste dans la fourchette
      // de sa catégorie, elle est plus précise que la table.
      final f = fenetre(
        type: 'red', millesime: 2022, appellation: 'Morgon',
        iaDebut: 2024, iaFin: 2030,
      );
      expect(f.fin, equals(8), reason: 'Morgon : 5 à 12 ans. Huit y tient, on garde.');
    });

    test('une fenêtre absurdement courte est ramenée à la catégorie', () {
      final f = fenetre(
        type: 'red', millesime: 2019, region: 'Bordeaux',
        iaDebut: 2021, iaFin: 2026,
      );
      expect(f.fin, greaterThanOrEqualTo(12),
          reason: 'Sept ans pour un Bordeaux rouge : hors fourchette, on réconcilie. '
              'La base donne 15 ans à une AOC Bordeaux sans appellation précise — moins '
              'que les 22 de l\'ancienne règle, qui appliquait un niveau Médoc à tout.');
    });
  });

  group('🔎 Revue bouteille par bouteille d\'une cave réelle', () {
    test('un champagne sans millésime ne se garde pas vingt-cinq ans', () {
      // Sans millésime, le code en invente un (`année - 3`) puis applique la fenêtre de
      // la catégorie. Un brut non millésimé y récoltait vingt-cinq ans ; il se boit dans
      // les trois à cinq.
      final w = WineOenologyAdvisor.computeDrinkingWindow(
          wineType: 'sparkling', vintage: null, appellation: 'Champagne');
      expect(w.drinkEnd - w.vintage, lessThanOrEqualTo(5));
      expect(w.agingPotentialText, contains('Sans millésime'));
    });

    test('un second vin se boit avant le grand vin', () {
      // « Les Hauts de Lynch-Moussas » héritait des vingt-deux ans d'un Haut-Médoc de
      // garde. Un second vin est vinifié pour être accessible.
      final second = fenetre(
          type: 'red', millesime: 2018, region: 'Bordeaux',
          appellation: 'Haut-Médoc', nom: 'Les Hauts de Lynch-Moussas');
      final grand = fenetre(
          type: 'red', millesime: 2018, region: 'Bordeaux',
          appellation: 'Haut-Médoc', nom: 'Château Lynch-Moussas');
      expect(second.fin, lessThan(grand.fin));
      expect(second.fin, lessThanOrEqualTo(15));
    });

    test('Crianza est le premier échelon espagnol, pas le haut', () {
      // Joven < Crianza < Reserva < Gran Reserva. Classer Crianza en supérieur donnait
      // vingt-sept ans à un Ribera del Duero qui en tient cinq à douze.
      expect(AgingReference.rangDe(nom: 'Tinto Crianza'), WineTier.entree);
      final f = fenetre(
          type: 'red', millesime: 2023, pays: 'Espagne',
          appellation: 'Ribera del Duero', nom: 'Tinto Crianza');
      expect(f.fin, lessThanOrEqualTo(14));
    });

    test('une appellation régionale de Bourgogne n\'est pas un village', () {
      final regional = fenetre(
          type: 'red', millesime: 2022, region: 'Bourgogne',
          appellation: 'Bourgogne Hautes Côtes de Nuits');
      final village = fenetre(
          type: 'red', millesime: 2022, region: 'Bourgogne',
          appellation: 'Gevrey-Chambertin');
      expect(regional.fin, lessThan(village.fin));
      expect(regional.fin, lessThanOrEqualTo(12));
    });
  });

  group('🏅 Les mentions de rang', () {
    test('le sommet prime sur le supérieur', () {
      // « Gran Reserva » contient « reserva » : tester « reserva » d'abord classerait
      // tous les Gran Reserva en supérieur.
      expect(AgingReference.rangDe(nom: 'Rioja Gran Reserva'), WineTier.sommet);
      expect(AgingReference.rangDe(nom: 'Rioja Reserva'), WineTier.superieur);
      // Crianza est le PREMIER échelon de vieillissement espagnol, pas un rang
      // supérieur — voir la revue de cave plus haut.
      expect(AgingReference.rangDe(nom: 'Rioja Crianza'), WineTier.entree);
      expect(AgingReference.rangDe(nom: 'Rioja Joven'), WineTier.entree);
      expect(AgingReference.rangDe(nom: 'Rioja'), WineTier.standard);
    });

    test('les mentions italiennes et allemandes sont reconnues', () {
      expect(AgingReference.rangDe(nom: 'Chianti Classico Riserva'), WineTier.sommet);
      expect(AgingReference.rangDe(nom: 'Valpolicella Classico'), WineTier.superieur);
      expect(AgingReference.rangDe(nom: 'Riesling Auslese'), WineTier.sommet);
    });
  });
}
