import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/chat/domain/bouteilles_citees.dart';
import 'package:chatmelier/features/chat/presentation/chat_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

/// 13/10, Flavien : « tu me parles de "cette rioja", "ce bourgogne aligoté". il manque la
/// carte de ces bouteilles afin de pouvoir cliquer dessus et arriver sur les détails du vin ».
void main() {
  Bottle bouteille(String id, String nom, {String? domaine, String? appellation, String region = '', int quantite = 1, String? vin}) =>
      Bottle(
        id: id,
        cellarId: 'c',
        wineId: vin ?? 'w$id',
        addedBy: 'u',
        ownerId: 'u',
        quantity: quantite,
        rack: 'B3',
        createdAt: DateTime(2026),
        wine: Wine(
          id: vin ?? 'w$id',
          name: nom,
          producer: domaine,
          vintage: 2019,
          type: 'red',
          country: 'France',
          region: region,
          appellation: appellation,
        ),
      );

  final cave = [
    bouteille('rioja', 'Gran Reserva', domaine: 'Ramón Bilbao', appellation: 'Rioja', region: 'Rioja'),
    bouteille('aligote', 'Bourgogne Aligoté', domaine: 'Domaine Ponsot', appellation: 'Bourgogne Aligoté', region: 'Bourgogne'),
    bouteille('volnay', 'Volnay', domaine: 'Domaine de Montille', appellation: 'Volnay', region: 'Bourgogne'),
    bouteille('crozes1', 'Crozes-Hermitage', domaine: 'Domaine Combier', appellation: 'Crozes-Hermitage', vin: 'crozes'),
    bouteille('crozes2', 'Crozes-Hermitage', domaine: 'Domaine Combier', appellation: 'Crozes-Hermitage', vin: 'crozes'),
    bouteille('bu', 'Bandol', domaine: 'Domaine Tempier', appellation: 'Bandol', quantite: 0),
  ];

  test('« cette rioja », « ce bourgogne aligoté » : les deux bouteilles, avec leur carte', () {
    const reponse = 'Pour ce soir, ouvrez cette Rioja : ses tanins fondus iront bien avec l\'agneau. '
        'En apéritif, ce Bourgogne aligoté, vif et salin.';
    expect(BouteillesCitees.dans(reponse, cave).map((b) => b.id), ['rioja', 'aligote']);
    final avec = BouteillesCitees.avecLeursCartes(reponse, cave);
    // La bulle les affiche comme les cartes que le sommelier pose lui-même.
    final cartes = ChatBubble.cartesDe(avec);
    expect(cartes.map((c) => c.id), ['rioja', 'aligote']);
    expect(cartes.first.name, 'Gran Reserva');
    expect(cartes.first.producer, 'Ramón Bilbao');
    // Nommée, pas forcément recommandée : la carte dit seulement qu'elle est en cave.
    expect(cartes.every((c) => c.citee), isTrue);
  });

  test('dans l\'ordre où la réponse les nomme ; le domaine sans son titre suffit', () {
    expect(BouteillesCitees.dans('L\'aligoté de Ponsot d\'abord, puis le Ramón Bilbao.', cave).map((b) => b.id),
        ['aligote', 'rioja']);
  });

  test('un nom qui désigne plusieurs vins de la cave n\'a pas de carte', () {
    // Deux bourgognes : « ce bourgogne » ne dit pas lequel.
    expect(BouteillesCitees.dans('Ce bourgogne sera parfait.', cave), isEmpty);
    // Deux bouteilles du même crozes, en revanche, sont un seul vin.
    expect(BouteillesCitees.dans('Votre Crozes-Hermitage est prêt.', cave).map((b) => b.wineId), ['crozes']);
  });

  test('ni carte en double, ni bouteille déjà bue, ni mot commun pris pour un vin', () {
    const deja = 'Ouvrez cette Rioja.\n[WINE_CARD: {"id": "rioja", "name": "Gran Reserva", "wine_type": "red"}]';
    expect(BouteillesCitees.dans(deja, cave), isEmpty);
    expect(BouteillesCitees.dans('Un Bandol de Tempier serait idéal.', cave), isEmpty);
    // « Gran Reserva » ne nomme aucun vin en particulier.
    expect(BouteillesCitees.dans('Une gran reserva de dix ans irait bien.', cave), isEmpty);
    expect(BouteillesCitees.avecLeursCartes('Rien de précis.', cave), 'Rien de précis.');
  });
}
