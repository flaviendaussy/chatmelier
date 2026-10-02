import 'package:chatmelier/features/menu_scan/domain/comptoir.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le comptoir à plusieurs (V2.3 · J4) : chacun note chaque verre ; à la fin, qui a aimé quoi.
void main() {
  setUp(() => Langue.code = 'fr');

  const morgon = MenuWine(id: 'm', name: 'Morgon', producer: 'Foillard', vintage: 2022, wineType: 'red');
  const muscadet = MenuWine(id: 'u', name: 'Muscadet', producer: 'L\'Écu', vintage: 2023, wineType: 'white');
  const madiran = MenuWine(id: 'd', name: 'Madiran', producer: 'Montus', vintage: 2018, wineType: 'red');
  final ardoise = [morgon, muscadet, madiran];

  GuestProfile convive(String nom, Map<MenuWine, double> notes, {bool neBoitPas = false}) => GuestProfile(
        id: nom,
        name: nom,
        neBoitPas: neBoitPas,
        verres: {for (final e in notes.entries) e.key.cacheKey: e.value},
      );

  test('qui a aimé quoi : le préféré, celui qui divise, le préféré de chacun', () {
    final bilan = BilanDuComptoir.dresser(ardoise, [
      convive('Paul', {morgon: 9.5, muscadet: 6.5, madiran: 9.5}),
      convive('Caro', {morgon: 8.0, muscadet: 9.5, madiran: 4.5}),
      convive('Léa', {morgon: 9.5}),
    ]);

    expect(bilan.prefere?.vin.name, 'Morgon');
    expect(bilan.quiDivise?.vin.name, 'Madiran', reason: '😍 pour Paul, 😕 pour Caro');
    expect(bilan.prefereDeChacun.map((k, v) => MapEntry(k, v.vin.name)),
        {'Paul': 'Morgon', 'Caro': 'Muscadet', 'Léa': 'Morgon'});
    expect(bilan.phrases, [
      'Le préféré du comptoir : Morgon 2022 (😍 Paul, 😍 Léa, 😊 Caro).',
      'Celui qui divise : Madiran 2018 (😍 Paul, 😕 Caro).',
      'Le préféré de chacun : Paul, Morgon 2022 · Caro, Muscadet 2023 · Léa, Morgon 2022.',
    ]);
  });

  test('qui ne boit pas ne note pas ; un verre noté par une seule personne n\'est pas « le préféré »', () {
    final bilan = BilanDuComptoir.dresser(ardoise, [
      convive('Paul', {muscadet: 9.5}),
      convive('Noé', {morgon: 9.5}, neBoitPas: true),
    ]);
    expect(bilan.goutes.map((v) => v.vin.name), ['Muscadet']);
    expect(bilan.prefere, isNull);
    expect(bilan.phrases, isEmpty, reason: 'rien à dire tant qu\'on est seul à noter');
  });

  test('les notes voyagent avec le profil du convive', () {
    final paul = convive('Paul', {morgon: 8.0});
    final relu = GuestProfile.fromJson('paul', paul.toJson());
    expect(relu.verres, {morgon.cacheKey: 8.0});
    expect(GuestProfile.fromJson('x', const {'verres': {'k': 'pas une note'}}).verres, isEmpty);
  });
}
