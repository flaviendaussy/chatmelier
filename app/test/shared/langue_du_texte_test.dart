import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/shared/utils/langue_du_texte.dart';

void main() {
  test('les fiches de la cave de Caro (04/10)', () {
    expect(
        LangueDuTexte.detecter('Deep ruby with garnet reflections at the rim. The nose offers an expressive bouquet of '
            'ripe black cherries, plums, and wild blackberries, complemented by refined secondary notes of cedar.'),
        'en');
    expect(
        LangueDuTexte.detecter('Une robe rubis profond. Le nez offre des arômes de cerise noire et de prune, avec des '
            'notes de cèdre ; la bouche est ample, aux tanins fins.'),
        'fr');
    expect(
        LangueDuTexte.detecter('Color rubí intenso. En nariz, aromas de cereza negra y ciruela; en boca es amplio, '
            'con taninos finos y un final largo.'),
        'es');
    expect(
        LangueDuTexte.detecter('Rosso rubino intenso. Al naso profumi di ciliegia nera e prugna; in bocca è ampio, '
            'con tannini fini e un finale lungo.'),
        'it');
  });

  test('les accords seuls', () {
    expect(LangueDuTexte.detecter('Roasted suckling lamb (Lechazo asado) · Charcoal-grilled ribeye with rosemary · '
        'Aged sheep\'s milk cheeses'), 'en');
    expect(LangueDuTexte.detecter('Carré d\'agneau rôti au romarin · Côte de bœuf grillée sauce au poivre · '
        'Fromages affinés à pâte dure'), 'fr');
    expect(LangueDuTexte.detecter('Côte de bœuf · Magret de canard'), isNull,
        reason: 'trop peu d\'indices : on ne traduit pas au hasard');
  });

  test('trop court ou vide : rien', () {
    expect(LangueDuTexte.detecter(''), isNull);
    expect(LangueDuTexte.detecter('Côte de bœuf'), isNull);
    expect(LangueDuTexte.detecter(null), isNull);
  });
}
