import 'package:flutter/widgets.dart';

/// Les éléments que « Me montrer » éclaire (V2.5 · E6). Chacun n'existe qu'une fois dans
/// l'app : une clé globale ne se partage pas entre deux écrans vivants.
class CiblesDuProjecteur {
  static final scannerLaCarte = GlobalKey(debugLabel: 'scannerLaCarte');
  static final vinBuDehors = GlobalKey(debugLabel: 'vinBuDehors');
  static final platALaMaison = GlobalKey(debugLabel: 'platALaMaison');
  static final radarDuPalais = GlobalKey(debugLabel: 'radarDuPalais');
}
