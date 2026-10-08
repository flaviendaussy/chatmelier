import 'package:chatmelier/features/cellar/domain/terroir_geo_data.dart';
import 'package:chatmelier/features/cellar/presentation/terroir_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rien d'affirmé sans preuve, jusque dans la carte des terroirs (V2.4 · R1).
///
/// Sans correspondance, le résolveur retombait sur la première appellation du pays, puis
/// sur Pauillac : la fiche d'un vin marocain montrait le sol, le climat et les cépages de
/// Pauillac comme ceux de son terroir.
void main() {
  test('un terroir hors de l\'atlas n\'est remplacé par aucun autre', () {
    expect(TerroirGeoResolver.trouver(country: 'Maroc', region: 'Ouarzazate', wineName: 'S de Siroua'), isNull);
    expect(TerroirGeoResolver.trouver(country: 'France', region: ''), isNull,
        reason: 'un pays seul ne dit pas le terroir');
    expect(TerroirGeoResolver.trouver(country: 'Spirit', region: '', isSpirit: true, wineName: 'Liqueur maison'), isNull,
        reason: 'pas de Cognac par défaut pour un spiritueux inconnu');
  });

  test('un terroir reconnu l\'est toujours', () {
    expect(TerroirGeoResolver.trouver(country: 'France', region: 'Bordeaux', appellation: 'Pauillac')?.id, 'pauillac');
    expect(TerroirGeoResolver.trouver(country: 'Italie', region: 'Piémont', appellation: 'Barolo'), isNotNull);
    expect(TerroirGeoResolver.resolve(country: 'Maroc', region: 'Ouarzazate'), isNotNull,
        reason: '`resolve` garde son repli pour les usages qui en ont besoin');
  });

  testWidgets('la carte dit qu\'elle ne connaît pas ce terroir', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TerroirMapView(country: 'Maroc', region: 'Ouarzazate', wineName: 'S de Siroua')),
    ));
    await tester.pump();
    expect(find.textContaining('pas encore dans notre atlas'), findsOneWidget);
    expect(find.textContaining('Pauillac'), findsNothing);
  });
}
