import 'package:chatmelier/features/cellar/domain/verdict_qualite_prix.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le rapport qualité-prix, seulement face à une cote sourcée (V2.3, « plus tard »).
void main() {
  setUp(() => Langue.code = 'fr');

  test('pas de verdict sans cote sourcée, ni sans prix payé', () {
    expect(VerdictQualitePrix.depuis(prixPaye: 18, cote: 30, coteSourcee: false), isNull,
        reason: 'une valeur devinée ou saisie ne juge pas un achat');
    expect(VerdictQualitePrix.depuis(prixPaye: null, cote: 30, coteSourcee: true), isNull);
    expect(VerdictQualitePrix.depuis(prixPaye: 18, cote: null, coteSourcee: true), isNull);
  });

  test('bonne affaire, juste prix, au-dessus de la cote', () {
    expect(VerdictQualitePrix.depuis(prixPaye: 20, cote: 25, coteSourcee: true), VerdictQualitePrix.bonneAffaire);
    expect(VerdictQualitePrix.depuis(prixPaye: 20, cote: 22, coteSourcee: true), VerdictQualitePrix.justePrix);
    expect(VerdictQualitePrix.depuis(prixPaye: 20, cote: 18, coteSourcee: true), VerdictQualitePrix.justePrix);
    expect(VerdictQualitePrix.depuis(prixPaye: 30, cote: 25, coteSourcee: true), VerdictQualitePrix.auDessus);
  });

  test('la phrase dit les deux montants', () {
    final phrase = VerdictQualitePrix.bonneAffaire.phrase(18, 30, (m) => '${m.round()} €');
    expect(phrase, 'Bonne affaire : payée 18 €, cotée 30 €.');
  });
}
