import 'wine_world_model.dart';

/// Allemagne, Autriche, Hongrie, Grèce, Angleterre.
///
/// Le riesling germanique et le Tokaji sont les deux catégories dont la longévité est le
/// plus souvent sous-estimée : on les prend pour des blancs, alors qu'un Riesling Auslese
/// et un Aszú vivent plus longtemps que la plupart des rouges.
const List<RegionVin> regionsEurope = [
  // ═══════════════ ALLEMAGNE ═══════════════
  RegionVin(
    id: 'de_mosel',
    pays: 'Allemagne',
    nom: 'Mosel',
    alias: ['mosel', 'moselle', 'saar', 'ruwer', 'bernkastel', 'piesport',
      'wehlen', 'urzig', 'graach'],
    cepages: ['Riesling'],
    longevites: {
      'white': AgingProfile(id: 'mosel', libelle: 'Riesling de Mosel',
          debut: 1, picDebut: 5, picFin: 18, fin: 30),
      'sweet': AgingProfile(id: 'mosel_doux', libelle: 'Riesling doux',
          debut: 3, picDebut: 10, picFin: 35, fin: 60),
    },
    references: [
      ReferenceVin(nom: 'Egon Müller', alias: ['egon muller', 'scharzhofberger'],
          certitude: Certitude.verifiee,
          longevite: AgingProfile(id: 'egon_muller', libelle: 'Egon Müller',
              debut: 5, picDebut: 15, picFin: 45, fin: 70)),
      ReferenceVin(nom: 'Joh. Jos. Prüm', alias: ['jj prum', 'prum']),
      ReferenceVin(nom: 'Dr. Loosen', alias: ['loosen'],
          raison: RaisonDePresence.lesDeux),
      ReferenceVin(nom: 'Markus Molitor'),
    ],
  ),
  RegionVin(
    id: 'de_rheingau',
    pays: 'Allemagne',
    nom: 'Rheingau, Nahe & Pfalz',
    alias: ['rheingau', 'nahe', 'pfalz', 'rheinhessen', 'johannisberg',
      'rudesheim', 'forst', 'deidesheim'],
    cepages: ['Riesling', 'Spätburgunder'],
    longevites: {
      'white': AgingProfile(id: 'rheingau', libelle: 'Riesling du Rhin',
          debut: 1, picDebut: 5, picFin: 18, fin: 28),
      'red': AgingProfile(id: 'spatburgunder', libelle: 'Spätburgunder',
          debut: 2, picDebut: 5, picFin: 13, fin: 18),
    },
    references: [
      ReferenceVin(nom: 'Robert Weil'),
      ReferenceVin(nom: 'Dönnhoff', alias: ['donnhoff']),
      ReferenceVin(nom: 'Keller'),
      ReferenceVin(nom: 'Müller-Catoir', alias: ['muller catoir']),
      ReferenceVin(nom: 'Blue Nun', raison: RaisonDePresence.grandVolume,
          longevite: AgingProfile(id: 'blue_nun', libelle: 'Blue Nun',
              debut: 0, picDebut: 1, picFin: 3, fin: 4)),
    ],
  ),
  RegionVin(
    id: 'de_baden',
    pays: 'Allemagne',
    nom: 'Baden & Württemberg',
    alias: ['baden', 'wurttemberg', 'kaiserstuhl'],
    cepages: ['Spätburgunder', 'Grauburgunder'],
    longevites: {
      'red': AgingProfile(id: 'baden_rouge', libelle: 'Baden rouge',
          debut: 2, picDebut: 4, picFin: 11, fin: 16),
      'white': AgingProfile(id: 'baden_blanc', libelle: 'Baden blanc',
          debut: 1, picDebut: 2, picFin: 7, fin: 11),
    },
  ),

  // ═══════════════ AUTRICHE ═══════════════
  RegionVin(
    id: 'at_wachau',
    pays: 'Autriche',
    nom: 'Wachau, Kamptal & Kremstal',
    alias: ['wachau', 'kamptal', 'kremstal', 'traisental', 'smaragd',
      'federspiel'],
    cepages: ['Grüner Veltliner', 'Riesling'],
    longevites: {'white': AgingProfile(id: 'wachau', libelle: 'Wachau & Kamptal',
        debut: 1, picDebut: 4, picFin: 14, fin: 22)},
    references: [
      ReferenceVin(nom: 'F.X. Pichler', alias: ['fx pichler']),
      ReferenceVin(nom: 'Emmerich Knoll', alias: ['knoll']),
      ReferenceVin(nom: 'Bründlmayer', alias: ['brundlmayer']),
      ReferenceVin(nom: 'Hirsch'),
    ],
  ),
  RegionVin(
    id: 'at_burgenland',
    pays: 'Autriche',
    nom: 'Burgenland & Styrie',
    alias: ['burgenland', 'neusiedlersee', 'blaufrankisch', 'steiermark',
      'styrie', 'leithaberg'],
    cepages: ['Blaufränkisch', 'Zweigelt', 'Sauvignon Blanc'],
    longevites: {
      'red': AgingProfile(id: 'blaufrankisch', libelle: 'Blaufränkisch',
          debut: 2, picDebut: 5, picFin: 13, fin: 19),
      'sweet': AgingProfile(id: 'burgenland_doux', libelle: 'Liquoreux du Burgenland',
          debut: 3, picDebut: 8, picFin: 25, fin: 40),
    },
    references: [
      ReferenceVin(nom: 'Kracher',
          longevite: AgingProfile(id: 'kracher', libelle: 'Kracher TBA',
              debut: 4, picDebut: 12, picFin: 35, fin: 55)),
      ReferenceVin(nom: 'Moric'),
    ],
  ),

  // ═══════════════ HONGRIE ═══════════════
  RegionVin(
    id: 'hu_tokaj',
    pays: 'Hongrie',
    nom: 'Tokaj',
    alias: ['tokaj', 'tokaji', 'aszu', 'eszencia', 'szamorodni'],
    cepages: ['Furmint', 'Hárslevelű'],
    longevites: {
      'sweet': AgingProfile(id: 'tokaji_aszu', libelle: 'Tokaji Aszú',
          debut: 5, picDebut: 15, picFin: 50, fin: 80),
      'white': AgingProfile(id: 'furmint_sec', libelle: 'Furmint sec',
          debut: 1, picDebut: 3, picFin: 10, fin: 16),
    },
    references: [
      ReferenceVin(nom: 'Royal Tokaji', certitude: Certitude.verifiee),
      ReferenceVin(nom: 'Disznókő', alias: ['disznoko']),
      ReferenceVin(nom: 'Oremus'),
    ],
  ),
  RegionVin(
    id: 'hu_autres',
    pays: 'Hongrie',
    nom: 'Villány, Eger & Balaton',
    alias: ['villany', 'eger', 'bikaver', 'balaton', 'szekszard'],
    cepages: ['Kékfrankos', 'Kadarka'],
    longevites: {
      'red': AgingProfile(id: 'hu_rouge', libelle: 'Rouge hongrois',
          debut: 2, picDebut: 4, picFin: 11, fin: 16),
      'white': AgingProfile(id: 'hu_blanc', libelle: 'Blanc hongrois',
          debut: 1, picDebut: 2, picFin: 6, fin: 9),
    },
  ),

  // ═══════════════ GRÈCE ═══════════════
  RegionVin(
    id: 'gr_santorin',
    pays: 'Grèce',
    nom: 'Santorin',
    alias: ['santorini', 'santorin', 'assyrtiko', 'vinsanto'],
    cepages: ['Assyrtiko'],
    longevites: {
      'white': AgingProfile(id: 'assyrtiko', libelle: 'Assyrtiko de Santorin',
          debut: 1, picDebut: 4, picFin: 14, fin: 20),
      'sweet': AgingProfile(id: 'vinsanto_gr', libelle: 'Vinsanto',
          debut: 3, picDebut: 10, picFin: 35, fin: 55),
    },
    references: [
      ReferenceVin(nom: 'Domaine Sigalas', alias: ['sigalas']),
      ReferenceVin(nom: 'Argyros'),
    ],
  ),
  RegionVin(
    id: 'gr_nord',
    pays: 'Grèce',
    nom: 'Naoussa, Nemea & continent',
    alias: ['naoussa', 'nemea', 'xinomavro', 'agiorgitiko', 'amyndeon',
      'macedoine', 'peloponnese'],
    cepages: ['Xinomavro', 'Agiorgitiko'],
    longevites: {'red': AgingProfile(id: 'xinomavro', libelle: 'Xinomavro & Agiorgitiko',
        debut: 3, picDebut: 7, picFin: 16, fin: 24)},
    references: [
      ReferenceVin(nom: 'Kir-Yianni', alias: ['kir yianni']),
      ReferenceVin(nom: 'Thymiopoulos'),
    ],
  ),
  RegionVin(
    id: 'gr_cretes_iles',
    pays: 'Grèce',
    nom: 'Crète & îles',
    alias: ['crete', 'creta', 'samos', 'rhodes', 'cephalonie', 'robola'],
    cepages: ['Vidiano', 'Liatiko', 'Muscat'],
    longevites: {
      'white': AgingProfile(id: 'gr_iles_blanc', libelle: 'Blanc des îles',
          debut: 0, picDebut: 2, picFin: 6, fin: 9),
      'fortified': AgingProfile(id: 'samos', libelle: 'Muscat de Samos',
          debut: 1, picDebut: 4, picFin: 18, fin: 30),
    },
  ),

  // ═══════════════ ANGLETERRE ═══════════════
  RegionVin(
    id: 'gb_sparkling',
    pays: 'Angleterre',
    nom: 'Effervescent anglais',
    alias: ['sussex', 'kent', 'hampshire', 'england sparkling',
      'english sparkling'],
    cepages: ['Chardonnay', 'Pinot Noir', 'Pinot Meunier'],
    longevites: {'sparkling': AgingProfile(id: 'gb_sparkling',
        libelle: 'Effervescent anglais', debut: 1, picDebut: 3, picFin: 10, fin: 15)},
    references: [
      ReferenceVin(nom: 'Nyetimber', raison: RaisonDePresence.lesDeux),
      ReferenceVin(nom: 'Chapel Down', raison: RaisonDePresence.grandVolume),
      ReferenceVin(nom: 'Gusbourne'),
      ReferenceVin(nom: 'Ridgeview'),
    ],
  ),
  RegionVin(
    id: 'gb_tranquille',
    pays: 'Angleterre',
    nom: 'Vins tranquilles anglais',
    alias: ['england', 'angleterre', 'surrey', 'essex', 'cornwall'],
    cepages: ['Bacchus', 'Chardonnay', 'Pinot Noir'],
    longevites: {
      'white': AgingProfile(id: 'gb_blanc', libelle: 'Blanc anglais',
          debut: 0, picDebut: 1, picFin: 4, fin: 6),
      'red': AgingProfile(id: 'gb_rouge', libelle: 'Rouge anglais',
          debut: 1, picDebut: 2, picFin: 6, fin: 9),
    },
  ),
];
