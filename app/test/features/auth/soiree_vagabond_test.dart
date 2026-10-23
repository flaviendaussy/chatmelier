import 'package:chatmelier/features/auth/domain/apprentissage_du_palais.dart';
import 'package:chatmelier/features/auth/domain/palais.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/sommelier/domain/profil_du_vin.dart';
import 'package:flutter_test/flutter_test.dart';

/// La soirée du 22/10 au Vagabond (Londres), rejouée verre par verre : les onze vins de la
/// carte qu'ils ont commandés, la note et les « pour vous » que Caro et Flavien ont donnés ce
/// soir-là (relus dans les journaux et le registre du palais), depuis leur palais d'avant tel
/// que la base le garde.
///
/// Ce qu'on attend, lu par un sommelier : Flavien aime les blancs tendus (Riesling de Moselle
/// 8, Rioja blanc 8,5), trouve le Muscat « trop mou » et « trop léger », et les rosés légers
/// « trop légers » — sa fraîcheur et son corps des blancs ne doivent pas baisser. Caro trouve
/// trois rouges « trop puissants » et deux « trop tanniques » : son corps et ses tanins des
/// rouges doivent baisser. Le 22/10, la règle du jugement faisait l'inverse dès que le palais
/// était déjà du bon côté du vin.
class _Verre {
  final Wine vin;
  final double note;
  final Map<String, String> pourVous;
  final bool defaut;

  const _Verre(this.vin, this.note, [this.pourVous = const {}, this.defaut = false]);
}

Wine _vin(String nom, String producteur, int millesime, String type, String region, String pays) =>
    Wine(id: nom, name: nom, producer: producteur, vintage: millesime, type: type, region: region, country: pays);

final _erdener = _vin('Erdener Treppchen Kabinett', 'Markus Molitor', 2023, 'white', 'Mosel', 'Germany');
final _bernate = _vin('El Bernate Rioja Blanco', 'Exopto', 2024, 'white', 'Rioja', 'Spain');
final _muscat = _vin('Ungrafted - Muscat', 'De Martino', 2024, 'white', 'Maipo Valley', 'Chile');
final _douro = _vin('Douro Rosé', 'Quinta do Crasto', 2025, 'rose', 'Douro', 'Portugal');
final _rosy = _vin('Rosy', 'Pio Cesare', 2025, 'rose', 'Piedmont', 'Italy');
final _rosado = _vin('Rosado', 'Contino', 2022, 'rose', 'Rioja', 'Spain');
final _bioTinto = _vin('Bio Tinto', 'Terrenus', 2024, 'red', 'Alentejo', 'Portugal');
final _cinsault = _vin('Ungrafted Cinsault', 'De Martino', 2025, 'red', 'Maipo Valley', 'Chile');
final _bruja = _vin('La Bruja de Rozas', 'Comando G', 2024, 'red', 'Vinos de Madrid', 'Spain');
final _vinhas = _vin('Vinhas Velhas Reserva Tinto', 'Terrenus', 2019, 'red', 'Alentejo', 'Portugal');
final _tannat = _vin('Finca Notables Tannat', 'El Esteco', 2020, 'red', 'Salta', 'Argentina');

const _f = AxesDuPalais.fraicheur;
const _c = AxesDuPalais.corps;
const _b = AxesDuPalais.boise;
const _t = AxesDuPalais.tanins;
const _d = AxesDuPalais.douceur;

final _soireeDeCaro = [
  _Verre(_erdener, 7.0, {_f: 'juste'}),
  _Verre(_bernate, 4.5, {_b: 'pas_assez', _f: 'trop'}),
  _Verre(_muscat, 9.5, {_d: 'juste'}),
  _Verre(_douro, 2.0, {_f: 'trop'}),
  _Verre(_rosy, 4.5, {_b: 'pas_assez', _f: 'juste', _d: 'juste', _c: 'pas_assez'}),
  _Verre(_rosado, 8.5),
  _Verre(_bioTinto, 4.5, {_c: 'trop', _t: 'trop'}),
  _Verre(_cinsault, 6.5, {_t: 'trop'}),
  _Verre(_bruja, 8.0, {_c: 'trop'}),
  _Verre(_vinhas, 7.5, {_c: 'trop'}),
];

final _soireeDeFlavien = [
  _Verre(_erdener, 8.0, {_f: 'juste'}),
  _Verre(_bernate, 8.5, {_b: 'juste'}),
  _Verre(_muscat, 3.5, {_f: 'pas_assez', _c: 'pas_assez'}),
  _Verre(_douro, 3.0, {_b: 'pas_assez'}),
  _Verre(_rosy, 1.5, {_c: 'pas_assez'}),
  _Verre(_rosado, 9.5, {_b: 'juste'}),
  _Verre(_bioTinto, 1.0, const {}, true),
  _Verre(_cinsault, 7.5, {_b: 'juste'}),
  _Verre(_bruja, 9.0, {_b: 'juste'}),
  _Verre(_vinhas, 9.0),
  _Verre(_tannat, 7.5, {_b: 'juste'}),
];

/// Leur palais d'avant, tel que la base le garde (`palais_utilisateur.profils`, 22/10) :
/// rien d'appris par famille, l'ancien palais toutes couleurs confondues.
const _caroAvant = TasteProfile(
  id: 'caro',
  name: 'Caro',
  isPrimary: true,
  favoriteTypes: ['Rouge', 'Rosé', 'Blanc'],
  avgAcidityPreference: 0.7,
  avgBodyPreference: 0.4,
  axisObservations: {'body': 1, 'acidity': 1},
);

const _flavienAvant = TasteProfile(
  id: 'flavien',
  name: 'Flavien',
  isPrimary: true,
  favoriteTypes: ['Rouge', 'Rosé', 'Blanc'],
  avgAcidityPreference: 0.73,
  avgBodyPreference: 0.69,
  avgTanninPreference: 0.58,
  axisObservations: {'body': 12, 'tannin': 9, 'acidity': 15},
);

final _le22 = DateTime(2026, 10, 22);

/// Rejoue la soirée comme `TasteProfileService._apprendreLePalais` : chaque changement posé
/// sur l'axe, une observation de plus quand il compte. Un vin défectueux n'apprend rien.
({TasteProfile palais, List<String> journal}) _rejouer(TasteProfile depart, List<_Verre> soiree) {
  var p = depart;
  final journal = <String>[];
  for (final verre in soiree) {
    if (verre.defaut) {
      journal.add('${verre.vin.name} : défaut, rien d\'appris');
      continue;
    }
    final famille = TasteProfile.familleDe(verre.vin.type)!;
    final changements = ApprentissageDuPalais.apprendre(
      profil: p,
      famille: famille,
      note: verre.note,
      jugements: verre.pourVous,
      vin: ProfilDuVin.deLaCave(verre.vin, le: _le22),
    );
    for (final c in changements) {
      final n = p.observationsSur(c.famille, c.axe);
      final de = p.valeurPalais(c.famille, c.axe);
      p = p.avecAxeDuPalais(c.famille, c.axe, c.apres, observations: c.compte ? n + 1 : n);
      journal.add('${verre.vin.name} ${verre.note} · ${c.famille}/${c.axe} '
          '${de?.toStringAsFixed(2) ?? '—'} → ${c.apres.toStringAsFixed(2)} (${c.motif}${c.jugement == null ? '' : ' ${c.jugement}'})');
    }
  }
  return (palais: p, journal: journal);
}

double _v(TasteProfile p, String famille, String axe) => p.valeurPalais(famille, axe)!;

void main() {
  group('Soirée du 22/10 au Vagabond, rejouée', () {
    late ({TasteProfile palais, List<String> journal}) caro;
    late ({TasteProfile palais, List<String> journal}) flavien;

    setUpAll(() {
      caro = _rejouer(_caroAvant, _soireeDeCaro);
      flavien = _rejouer(_flavienAvant, _soireeDeFlavien);
      // Lisible dans la sortie du test : le chemin de chaque axe, verre après verre.
      for (final (qui, r) in [('Caro', caro), ('Flavien', flavien)]) {
        // ignore: avoid_print
        print('— $qui —\n${r.journal.join('\n')}');
        for (final famille in [FamillesDeVins.blanc, FamillesDeVins.rouge]) {
          // ignore: avoid_print
          print('$qui $famille : ${{
            for (final a in AxesDuPalais.de(famille))
              if (r.palais.valeurPalais(famille, a) case final v?) a: v.toStringAsFixed(2),
          }}');
        }
      }
    });

    test('« trop mou » et « trop léger » ne font pas baisser la fraîcheur ni le corps des blancs de Flavien', () {
      final apresLeRiesling = _rejouer(_flavienAvant, _soireeDeFlavien.sublist(0, 2)).palais;
      final apresLeMuscat = _rejouer(_flavienAvant, _soireeDeFlavien.sublist(0, 3)).palais;
      expect(_v(apresLeMuscat, FamillesDeVins.blanc, _f), greaterThanOrEqualTo(_v(apresLeRiesling, FamillesDeVins.blanc, _f)));
      expect(_v(apresLeMuscat, FamillesDeVins.blanc, _c), greaterThanOrEqualTo(_v(apresLeRiesling, FamillesDeVins.blanc, _c)));
      // Et le Rosy, « trop léger » à 1,5 : le corps ne descend pas non plus.
      final avantLeRosy = _rejouer(_flavienAvant, _soireeDeFlavien.sublist(0, 4)).palais;
      final apresLeRosy = _rejouer(_flavienAvant, _soireeDeFlavien.sublist(0, 5)).palais;
      expect(_v(apresLeRosy, FamillesDeVins.blanc, _c), greaterThanOrEqualTo(_v(avantLeRosy, FamillesDeVins.blanc, _c)));
    });

    test('trois rouges « trop puissants » : le corps des rouges de Caro baisse, il ne monte pas', () {
      final avantLaBruja = _rejouer(_caroAvant, _soireeDeCaro.sublist(0, 8)).palais;
      final apresLaBruja = _rejouer(_caroAvant, _soireeDeCaro.sublist(0, 9)).palais;
      final aLaFin = caro.palais;
      expect(_v(apresLaBruja, FamillesDeVins.rouge, _c), lessThanOrEqualTo(_v(avantLaBruja, FamillesDeVins.rouge, _c)));
      expect(_v(aLaFin, FamillesDeVins.rouge, _c), lessThanOrEqualTo(_v(apresLaBruja, FamillesDeVins.rouge, _c)));
      // Plus léger que les vins qu'elle a trouvés trop puissants.
      for (final vin in [_bruja, _vinhas]) {
        expect(_v(aLaFin, FamillesDeVins.rouge, _c), lessThan(ProfilDuVin.deLaCave(vin, le: _le22).valeur(_c)!));
      }
    });

    test('« pas assez boisé » sur le Rioja blanc puis sur le Rosy : le boisé des blancs de Caro ne redescend pas', () {
      final apresLeBernate = _rejouer(_caroAvant, _soireeDeCaro.sublist(0, 2)).palais;
      final avantLeRosy = _rejouer(_caroAvant, _soireeDeCaro.sublist(0, 4)).palais;
      final apresLeRosy = _rejouer(_caroAvant, _soireeDeCaro.sublist(0, 5)).palais;
      expect(_v(apresLeBernate, FamillesDeVins.blanc, _b), greaterThan(0.3));
      expect(_v(apresLeRosy, FamillesDeVins.blanc, _b), greaterThanOrEqualTo(_v(avantLeRosy, FamillesDeVins.blanc, _b)));
    });

    test('« trop tannique » deux fois : les tanins des rouges de Caro sous ceux des vins goûtés', () {
      for (final vin in [_bioTinto, _cinsault]) {
        expect(_v(caro.palais, FamillesDeVins.rouge, _t), lessThan(ProfilDuVin.deLaCave(vin, le: _le22).valeur(_t)!));
      }
    });

    test('le Bio Tinto bouchonné de Flavien n\'apprend rien', () {
      expect(flavien.journal.where((l) => l.startsWith('Bio Tinto')), ['Bio Tinto : défaut, rien d\'appris']);
    });
  });
}
