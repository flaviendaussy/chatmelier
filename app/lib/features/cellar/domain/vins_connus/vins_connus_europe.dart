import 'vins_connus_modele.dart';

/// L'Europe hors France, Italie et péninsule Ibérique ; le Liban, la Géorgie, le Maroc.
///
/// L'Allemagne et l'Autriche écrivent presque toujours le cépage sur l'étiquette ; on y
/// fixe celui des domaines qui n'en font qu'un (Egon Müller, J.J. Prüm : riesling ; Moric :
/// blaufränkisch). Musar a son assemblage, connu depuis cinquante ans.
const _riesling = [Cep.riesling];
const _gruner = [Cep.gruner];
const _tokaji = [Cep.furmint, Cep.harslevelu, Cep.sargamuskotaly];
const _anglais = [Cep.ch, Cep.pn, Cep.meunier];
const _santorin = [Cep.assyrtiko, Cep.athiri, Cep.aidani];

const List<AppellationConnue> appellationsEurope = [
  // ═══════════════ ALLEMAGNE ═══════════════
  AppellationConnue('Mosel', 'Allemagne',
      alias: ['mosel', 'moselle allemande', 'mosel saar ruwer', 'saar', 'ruwer', 'mosella'],
      cepages: {'*': _riesling, 'red': [Cep.pn]},
      vins: [
        VinConnu.blanc('Scharzhofberger', _riesling, alias: ['egon muller']),
        VinConnu.blanc('Joh. Jos. Prüm', _riesling, alias: ['joh jos prum', 'j j prum', 'jj prum']),
        VinConnu.blanc('Wehlener Sonnenuhr', _riesling),
        VinConnu.blanc('Dr. Loosen', _riesling, alias: ['dr loosen', 'dr l']),
        VinConnu.blanc('Markus Molitor', _riesling, alias: ['erdener treppchen', 'zeltinger sonnenuhr']),
        VinConnu.blanc('Fritz Haag', _riesling, alias: ['brauneberger juffer']),
        VinConnu.blanc('Clemens Busch', _riesling),
        VinConnu.blanc('Joh. Jos. Christoffel Erben', _riesling, alias: ['christoffel']),
        VinConnu.blanc('Willi Schaefer', _riesling),
        VinConnu.blanc('Zilliken', _riesling, alias: ['forstmeister geltz zilliken']),
        VinConnu.blanc('Maximin Grünhaus', _riesling, alias: ['maximin grunhaus', 'von schubert']),
        VinConnu.blanc('Selbach-Oster', _riesling),
        VinConnu.blanc('Schloss Lieser', _riesling),
        VinConnu.blanc('Berncasteler Doctor', _riesling, alias: ['bernkasteler doctor', 'dr thanisch']),
        VinConnu.blanc('Karthäuserhof', _riesling, alias: ['karthauserhof']),
        VinConnu.blanc('Van Volxem', _riesling),
        VinConnu.blanc('Heymann-Löwenstein', _riesling, alias: ['heymann lowenstein']),
        VinConnu.blanc('St. Urbans-Hof', _riesling, alias: ['saint urbans hof']),
        VinConnu.blanc('Peter Lauer', _riesling),
      ]),
  AppellationConnue('Rheingau', 'Allemagne', cepages: {'white': _riesling, 'red': [Cep.pn]}, vins: [
    VinConnu.blanc('Robert Weil', _riesling, alias: ['kiedrich grafenberg']),
    VinConnu.blanc('Leitz', _riesling, alias: ['josef leitz', 'dragonstone']),
    VinConnu.blanc('Schloss Johannisberg', _riesling),
    VinConnu.blanc('Künstler', _riesling, alias: ['kunstler']),
    VinConnu.blanc('Georg Breuer', _riesling),
    VinConnu.blanc('Schloss Vollrads', _riesling),
    VinConnu.blanc('Peter Jakob Kühn', _riesling, alias: ['peter jakob kuhn']),
    VinConnu.rouge('August Kesseler', [Cep.pn]),
  ]),
  AppellationConnue('Nahe', 'Allemagne', cepages: {'white': _riesling}, vins: [
    VinConnu.blanc('Dönnhoff', _riesling, alias: ['donnhoff', 'hermannshohle']),
    VinConnu.blanc('Emrich-Schönleber', _riesling, alias: ['emrich schonleber']),
    VinConnu.blanc('Schäfer-Fröhlich', _riesling, alias: ['schafer frohlich']),
  ]),
  AppellationConnue('Pfalz', 'Allemagne', alias: ['palatinat'], cepages: {'white': [Cep.riesling, Cep.scheurebe, Cep.pinotBlanc], 'red': [Cep.pn]}, vins: [
    VinConnu.blanc('Bürklin-Wolf', _riesling, alias: ['burklin wolf', 'dr burklin wolf']),
    VinConnu.blanc('Bassermann-Jordan', _riesling),
    VinConnu.blanc('Von Winning', _riesling),
    VinConnu.blanc('Müller-Catoir', [], alias: ['muller catoir']),
    VinConnu.blanc('Ökonomierat Rebholz', [], alias: ['rebholz']),
    VinConnu.blanc('Christmann', _riesling),
    VinConnu.rouge('Friedrich Becker', [Cep.pn]),
    VinConnu.rouge('Knipser', []),
  ]),
  AppellationConnue('Rheinhessen', 'Allemagne', alias: ['liebfraumilch'], cepages: {'white': [Cep.riesling, Cep.silvaner, Cep.mullerThurgau], 'red': [Cep.pn]}, vins: [
    VinConnu.blanc('Keller', _riesling, alias: ['weingut keller', 'g max', 'abts e']),
    VinConnu.blanc('Wittmann', _riesling),
    VinConnu.blanc('Gunderloch', _riesling),
    VinConnu.blanc('Battenfeld-Spanier', _riesling),
    VinConnu.blanc('Kühling-Gillot', _riesling, alias: ['kuhling gillot']),
    VinConnu.blanc('Blue Nun', [Cep.mullerThurgau, Cep.silvaner, Cep.riesling]),
  ]),
  AppellationConnue('Franken', 'Allemagne', alias: ['franconie'], cepages: {'white': [Cep.silvaner, Cep.mullerThurgau, Cep.riesling], 'red': [Cep.pn]}, vins: [
    VinConnu.rouge('Rudolf Fürst', [Cep.pn], alias: ['rudolf furst']),
    VinConnu.blanc('Horst Sauer', [Cep.silvaner]),
    VinConnu.blanc('Juliusspital', [Cep.silvaner]),
    VinConnu.blanc('Hans Wirsching', [Cep.silvaner]),
  ]),
  AppellationConnue('Baden', 'Allemagne', alias: ['ahr', 'wurttemberg', 'kaiserstuhl'], cepages: {'red': [Cep.pn], 'white': [Cep.pinotGris, Cep.pinotBlanc, Cep.ch]}, vins: [
    VinConnu.rouge('Bernhard Huber', [Cep.pn]),
    VinConnu.rouge('Dr. Heger', [Cep.pn], alias: ['dr heger']),
    VinConnu.rouge('Salwey', [Cep.pn]),
    VinConnu.rouge('Franz Keller', [Cep.pn]),
    VinConnu.rouge('Ziereisen', [Cep.pn]),
    VinConnu.rouge('Meyer-Näkel', [Cep.pn], alias: ['meyer nakel']),
  ]),
  AppellationConnue('Deutscher Sekt', 'Allemagne', alias: ['sekt', 'deutscher sekt'], cepages: {'sparkling': [Cep.riesling, Cep.pinotBlanc, Cep.pn, Cep.ch]}, vins: [
    VinConnu.bulles('Henkell', []),
    VinConnu.bulles('Rotkäppchen', [], alias: ['rotkappchen']),
    VinConnu.bulles('Raumland', []),
  ]),

  // ═══════════════ AUTRICHE ═══════════════
  AppellationConnue('Wachau', 'Autriche', cepages: {'white': [Cep.gruner, Cep.riesling]}, vins: [
    VinConnu.blanc('F.X. Pichler', [], alias: ['f x pichler', 'fx pichler']),
    VinConnu.blanc('Franz Hirtzberger', []),
    VinConnu.blanc('Prager', []),
    VinConnu.blanc('Emmerich Knoll', [], alias: ['knoll']),
    VinConnu.blanc('Domäne Wachau', [], alias: ['domane wachau']),
    VinConnu.blanc('Alzinger', []),
    VinConnu.blanc('Rudi Pichler', []),
    VinConnu.blanc('Nikolaihof', []),
  ]),
  AppellationConnue('Kamptal', 'Autriche', alias: ['kremstal', 'wagram', 'traisental', 'weinviertel'], cepages: {'white': [Cep.gruner, Cep.riesling], 'red': [Cep.zweigelt]}, vins: [
    VinConnu.blanc('Bründlmayer', [], alias: ['brundlmayer']),
    VinConnu.blanc('Hiedler', []),
    VinConnu.blanc('Schloss Gobelsburg', []),
    VinConnu.blanc('Weingut Hirsch', []),
    VinConnu.blanc('Fred Loimer', [], alias: ['loimer']),
    VinConnu.blanc('Nigl', []),
    VinConnu.blanc('Malat', []),
  ]),
  AppellationConnue('Burgenland', 'Autriche',
      alias: ['mittelburgenland', 'leithaberg', 'neusiedlersee', 'eisenberg', 'rust', 'ruster ausbruch'],
      cepages: {'red': [Cep.blaufrankisch, Cep.zweigelt, Cep.stLaurent], 'sweet': [Cep.welschriesling, Cep.ch, Cep.scheurebe]},
      vins: [
        VinConnu.rouge('Moric', [Cep.blaufrankisch], alias: ['roland velich']),
        VinConnu.doux('Kracher', [], alias: ['alois kracher']),
        VinConnu.rouge('Umathum', []),
        VinConnu.rouge('Weninger', [Cep.blaufrankisch]),
        VinConnu.rouge('Paul Achs', []),
        VinConnu.rouge('Uwe Schiefer', [Cep.blaufrankisch]),
        VinConnu.rouge('Prieler', [Cep.blaufrankisch]),
        VinConnu.rouge('Gernot und Heike Heinrich', [], alias: ['gernot heike heinrich']),
        VinConnu.doux('Feiler-Artinger', []),
      ]),
  AppellationConnue('Steiermark', 'Autriche', alias: ['styrie', 'sudsteiermark', 'vulkanland steiermark'], cepages: {'white': [Cep.sb, Cep.ch, Cep.welschriesling]}, vins: [
    VinConnu.blanc('Tement', []),
    VinConnu.blanc('Sattlerhof', []),
    VinConnu.blanc('Polz', []),
    VinConnu.blanc('Neumeister', []),
    VinConnu.blanc('Weingut Gross', []),
  ]),
  AppellationConnue('Österreich', 'Autriche', alias: ['osterreich', 'niederosterreich'], generique: true, cepages: {'white': _gruner, 'red': [Cep.zweigelt, Cep.blaufrankisch]}),

  // ═══════════════ SUISSE ═══════════════
  AppellationConnue('Valais', 'Suisse', alias: ['wallis', 'fendant', 'dole'], cepages: {'white': [Cep.chasselas, Cep.petiteArvine], 'red': [Cep.pn, Cep.gamay, Cep.cornalin, Cep.humagneRouge]}, vins: [
    VinConnu.blanc('Marie-Thérèse Chappaz', [], alias: ['marie therese chappaz']),
    VinConnu.blanc('Jean-René Germanier', [], alias: ['jean rene germanier']),
    VinConnu.blanc('Provins', []),
    VinConnu.blanc('Robert Gilliard', []),
    VinConnu.rouge('Domaine Rouvinez', []),
  ]),
  AppellationConnue('Vaud', 'Suisse', alias: ['lavaux', 'dezaley', 'calamin', 'aigle', 'yvorne', 'epesses', 'la cote', 'chablais'], cepages: {'white': [Cep.chasselas], 'red': [Cep.pn, Cep.gamay]}, vins: [
    VinConnu.blanc('Les Murailles', [Cep.chasselas], de: 'Badoux'),
    VinConnu.blanc('Louis Bovard', [Cep.chasselas]),
    VinConnu.blanc('Blaise Duboux', [Cep.chasselas]),
  ]),
  AppellationConnue('Ticino', 'Suisse', alias: ['tessin'], cepages: {'red': [Cep.merlot], 'white': [Cep.merlot]}, vins: [
    VinConnu.rouge('Gialdi', [Cep.merlot]),
    VinConnu.rouge('Daniel Huber', [Cep.merlot]),
  ]),

  // ═══════════════ HONGRIE ═══════════════
  AppellationConnue('Tokaj', 'Hongrie', alias: ['tokaji', 'tokaji aszu', 'tokaji eszencia', 'tokaj hegyalja', 'szamorodni'], cepages: {'*': _tokaji, 'white': [Cep.furmint, Cep.harslevelu]}, vins: [
    VinConnu.doux('Royal Tokaji', _tokaji),
    VinConnu.doux('Oremus', _tokaji),
    VinConnu.doux('Disznókő', _tokaji, alias: ['disznoko']),
    VinConnu.doux('Szepsy', _tokaji, alias: ['istvan szepsy']),
    VinConnu.doux('Château Pajzos', _tokaji),
    VinConnu.doux('Hétszőlő', _tokaji, alias: ['hetszolo']),
    VinConnu.doux('Királyudvar', _tokaji, alias: ['kiralyudvar']),
    VinConnu.blanc('Dobogó', [Cep.furmint], alias: ['dobogo']),
    VinConnu.doux('Patricius', _tokaji),
  ]),
  AppellationConnue('Eger', 'Hongrie', alias: ['egri bikaver', 'bikaver', 'villany', 'szekszard'], cepages: {'red': [Cep.kekfrankos, Cep.kadarka, Cep.merlot, Cep.cf]}, vins: [
    VinConnu.rouge('St. Andrea', [], alias: ['saint andrea']),
    VinConnu.rouge('Gere Attila', [], alias: ['attila gere']),
    VinConnu.rouge('Bock', [], alias: ['jozsef bock']),
  ]),

  // ═══════════════ GRÈCE ═══════════════
  AppellationConnue('Santorin', 'Grèce', alias: ['santorini', 'santorin', 'vinsanto'], cepages: {'*': _santorin, 'white': [Cep.assyrtiko]}, vins: [
    VinConnu.blanc('Sigalas', [Cep.assyrtiko], alias: ['domaine sigalas']),
    VinConnu.blanc('Thalassitis', [Cep.assyrtiko], de: 'Gaia'),
    VinConnu.blanc('Hatzidakis', [Cep.assyrtiko]),
    VinConnu.blanc('Estate Argyros', [Cep.assyrtiko], alias: ['domaine argyros']),
    VinConnu.blanc('Santo Wines', [Cep.assyrtiko]),
  ]),
  AppellationConnue('Naoussa', 'Grèce', alias: ['amyndeon', 'macedoine'], cepages: {'red': [Cep.xinomavro]}, vins: [
    VinConnu.rouge('Ramnista', [Cep.xinomavro], de: 'Kir-Yianni'),
    VinConnu.rouge('Kir-Yianni', [Cep.xinomavro], alias: ['kir yianni']),
    VinConnu.rouge('Thymiopoulos', [Cep.xinomavro], alias: ['earth sky', 'jeunes vignes']),
    VinConnu.rouge('Dalamara', [Cep.xinomavro]),
  ]),
  AppellationConnue('Nemea', 'Grèce', alias: ['peloponnese', 'mantinia'], cepages: {'red': [Cep.agiorgitiko], 'white': [Cep.moschofilero]}, vins: [
    VinConnu.rouge('Megas Oenos', [Cep.agiorgitiko, Cep.cs], de: 'Skouras'),
    VinConnu.rouge('Gaia Agiorgitiko', [Cep.agiorgitiko]),
    VinConnu.blanc('Tselepos', [Cep.moschofilero]),
  ]),
  AppellationConnue('Épanomi', 'Grèce', alias: ['epanomi', 'grece', 'greece'], generique: true, cepages: {'white': [Cep.malagousia, Cep.assyrtiko]}, vins: [
    VinConnu.blanc('Gerovassiliou', [Cep.malagousia], alias: ['domaine gerovassiliou']),
  ]),

  // ═══════════════ ANGLETERRE ═══════════════
  AppellationConnue('Angleterre', 'Angleterre',
      alias: ['english sparkling wine', 'sussex', 'kent', 'hampshire', 'surrey', 'cornwall', 'england'],
      cepages: {'sparkling': _anglais, 'white': [Cep.bacchus, Cep.ch], 'red': [Cep.pn]},
      vins: [
        VinConnu.bulles('Nyetimber', _anglais),
        VinConnu.bulles('Ridgeview', _anglais),
        VinConnu.blanc('Chapel Down Bacchus', [Cep.bacchus]),
        VinConnu.bulles('Chapel Down', _anglais),
        VinConnu.bulles('Gusbourne', _anglais),
        VinConnu.bulles('Hambledon', _anglais),
        VinConnu.bulles('Camel Valley', [Cep.seyval, Cep.pn, Cep.ch]),
        VinConnu.bulles('Wiston', _anglais),
        VinConnu.bulles('Hattingley Valley', _anglais),
        VinConnu.bulles('Cubitt Blanc de Noirs', [Cep.pn, Cep.meunier], de: 'Denbies'),
        VinConnu.bulles('Denbies', []),
        VinConnu.bulles('Rathfinny', _anglais),
        VinConnu.bulles('Coates & Seely', [Cep.ch, Cep.pn], alias: ['coates seely']),
        VinConnu.bulles('Exton Park', _anglais),
      ]),

  // ═══════════════ MÉDITERRANÉE ORIENTALE, CAUCASE, MAGHREB ═══════════════
  AppellationConnue('Bekaa', 'Liban', alias: ['bekaa valley', 'vallee de la bekaa', 'liban', 'lebanon'], cepages: {'red': [Cep.cs, Cep.cinsault, Cep.syrah, Cep.carignan], 'white': [Cep.obaideh, Cep.merwah]}, vins: [
    VinConnu.rouge('Château Musar', [Cep.cs, Cep.cinsault, Cep.carignan], alias: ['chateau musar', 'musar']),
    VinConnu.blanc('Château Musar', [Cep.obaideh, Cep.merwah], alias: ['chateau musar', 'musar']),
    VinConnu.rouge('Hochar Père et Fils', [Cep.cinsault, Cep.grenache, Cep.cs, Cep.carignan], alias: ['hochar pere fils']),
    VinConnu.rouge('Réserve du Couvent', [], de: 'Ksara', alias: ['reserve du couvent']),
    VinConnu.rouge('Château Ksara', [], alias: ['ksara']),
    VinConnu.rouge('Château Kefraya', [], alias: ['kefraya', 'comte de m']),
    VinConnu.rouge('Ixsir', []),
    VinConnu.rouge('Massaya', []),
    VinConnu.rouge('Domaine des Tourelles', []),
  ]),
  AppellationConnue('Kakheti', 'Géorgie',
      alias: ['kakheti', 'mukuzani', 'kindzmarauli', 'tsinandali', 'napareuli', 'georgie', 'sakartvelo'],
      cepages: {'red': [Cep.saperavi], 'white': [Cep.rkatsiteli, Cep.mtsvane], 'orange': [Cep.rkatsiteli, Cep.mtsvane, Cep.kisi], 'sweet': [Cep.saperavi]},
      vins: [
        VinConnu.orange("Pheasant's Tears", [Cep.rkatsiteli], alias: ['pheasant s tears']),
        VinConnu.rouge('Teliani Valley', [Cep.saperavi]),
        VinConnu.rouge('Tbilvino', [Cep.saperavi]),
        VinConnu.orange('Alaverdi Monastery', [Cep.rkatsiteli], alias: ['alaverdi']),
        VinConnu.orange('Iago', ['Chinuri'], alias: ['iago s wine']),
      ]),
  AppellationConnue('Maroc', 'Maroc',
      alias: ['maroc', 'morocco', 'benslimane', 'zenata', 'guerrouane', 'meknes', 'boulaouane'],
      cepages: {'red': [Cep.syrah, Cep.cs, Cep.grenache, Cep.carignan, Cep.cinsault], 'rose': [Cep.cinsault, Cep.grenache]},
      vins: [
        VinConnu.rose('Gris de Boulaouane', [Cep.cinsault, Cep.grenache]),
        VinConnu.rouge('Domaine Ouled Thaleb', []),
        VinConnu.rouge('Volubilia', []),
      ]),
];
