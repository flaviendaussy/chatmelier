import 'dart:math' as math;

class WineServiceAdvice {
  final int minTemp;
  final int maxTemp;
  final String tempLabel;
  final int carafeMinutes;
  final String carafeLabel;
  final String decantingAdvice;
  final String glasswareType;
  final String detailedTip;

  const WineServiceAdvice({
    required this.minTemp,
    required this.maxTemp,
    required this.tempLabel,
    required this.carafeMinutes,
    required this.carafeLabel,
    required this.decantingAdvice,
    required this.glasswareType,
    required this.detailedTip,
  });
}

class WineServiceAdvisor {
  static WineServiceAdvice computeAdvice({
    required String? wineType,
    required int? vintage,
    required String? region,
    required String? appellation,
    required String? producer,
    required String? wineName,
  }) {
    final currentYear = DateTime.now().year;
    final age = vintage != null ? (currentYear - vintage).clamp(0, 100) : null;
    final type = (wineType ?? 'red').toLowerCase();
    final reg = (region ?? '').toLowerCase();
    final app = (appellation ?? '').toLowerCase();
    final name = '${wineName ?? ""} ${producer ?? ""}'.toLowerCase();

    // 1. Red Wines
    if (type.contains('red') || type.contains('rouge')) {
      final isPowerfulRed = reg.contains('bordeaux') ||
          reg.contains('rhône') ||
          reg.contains('rhone') ||
          reg.contains('piémont') ||
          reg.contains('piemonte') ||
          reg.contains('toscane') ||
          reg.contains('tuscany') ||
          reg.contains('rioja') ||
          reg.contains('napa') ||
          app.contains('madiran') ||
          app.contains('cahors') ||
          app.contains('bandol') ||
          app.contains('cornas') ||
          app.contains('hermitage') ||
          app.contains('barolo') ||
          app.contains('barbaresco') ||
          app.contains('brunello') ||
          app.contains('priorat') ||
          name.contains('cabernet') ||
          name.contains('syrah') ||
          name.contains('malbec');

      if (isPowerfulRed) {
        if (age != null && age >= 20) {
          return const WineServiceAdvice(
            minTemp: 17,
            maxTemp: 18,
            tempLabel: '17°C - 18°C',
            carafeMinutes: 0,
            carafeLabel: 'Pas de caravage',
            decantingAdvice: 'Débouchage délicat 30-45 min avant le service. Éviter le caravage pour ne pas épuiser ses arômes tertiaires fragiles.',
            glasswareType: 'Grand verre Bordeaux / Verre tulipe généreux',
            detailedTip: 'Un grand vin ancien a besoin de douceur. Versez lentement en laissant le dépôt au fond de la bouteille.',
          );
        } else if (age != null && age >= 8) {
          return const WineServiceAdvice(
            minTemp: 16,
            maxTemp: 18,
            tempLabel: '16°C - 18°C',
            carafeMinutes: 45,
            carafeLabel: '45 min en carafe',
            decantingAdvice: 'Caravage doux 45 minutes avant le service pour épanouir le bouquet sans brutaliser la texture soyeuse.',
            glasswareType: 'Verre Bordeaux ample',
            detailedTip: 'Laissez respirer à température ambiante fraîche (16-17°C).',
          );
        } else {
          return const WineServiceAdvice(
            minTemp: 16,
            maxTemp: 17,
            tempLabel: '16°C - 17°C',
            carafeMinutes: 120,
            carafeLabel: '2h en carafe évasée',
            decantingAdvice: 'Caravage vigoureux 2 heures avant le repas dans une carafe à large base pour aérer et assouplir les tanins encore serrés.',
            glasswareType: 'Verre Bordeaux grand format',
            detailedTip: 'L\'oxygénation intensive va réveiller les arômes de fruits noirs et fondre la trame tannique.',
          );
        }
      }

      final isDelicateRed = reg.contains('bourgogne') ||
          reg.contains('burgundy') ||
          reg.contains('loire') ||
          reg.contains('beaujolais') ||
          reg.contains('jura') ||
          reg.contains('alsace') ||
          name.contains('pinot') ||
          name.contains('gamay') ||
          name.contains('trouss') ||
          name.contains('plouss');

      if (isDelicateRed) {
        if (age != null && age >= 15) {
          return const WineServiceAdvice(
            minTemp: 15,
            maxTemp: 16,
            tempLabel: '15°C - 16°C',
            carafeMinutes: 0,
            carafeLabel: 'Service direct au verre',
            decantingAdvice: 'Ouvrir 30 min avant sans carafer. Le Pinot Noir âgé révèle sa complexité directement dans un grand calice.',
            glasswareType: 'Grand verre Bourgogne (forme ballon)',
            detailedTip: 'La délicatesse du sous-bois et de la truffe s\'exprime pleinement sans passage en carafe.',
          );
        } else {
          return const WineServiceAdvice(
            minTemp: 14,
            maxTemp: 16,
            tempLabel: '14°C - 16°C',
            carafeMinutes: 30,
            carafeLabel: '30 min d\'aération',
            decantingAdvice: 'Aération douce 30 minutes en bouteille ou carafe étroite pour libérer la pureté du fruit rouge.',
            glasswareType: 'Verre Bourgogne ballon',
            detailedTip: 'Température idéale légèrement fraîche pour préserver l\'éclat et la tension aromatique.',
          );
        }
      }

      return const WineServiceAdvice(
        minTemp: 15,
        maxTemp: 17,
        tempLabel: '15°C - 17°C',
        carafeMinutes: 45,
        carafeLabel: '45 min en carafe',
        decantingAdvice: 'Ouvrir 45 min à 1h avant la dégustation.',
        glasswareType: 'Verre à vin rouge standard ou tulipe',
        detailedTip: 'Servir légèrement rafraîchi pour sublimer l\'équilibre.',
      );
    }

    // 2. White Wines
    if (type.contains('white') || type.contains('blanc')) {
      final isRichWhite = reg.contains('bourgogne') ||
          reg.contains('burgundy') ||
          reg.contains('rhône') ||
          reg.contains('rhone') ||
          app.contains('meursault') ||
          app.contains('montrachet') ||
          app.contains('corton') ||
          app.contains('hermitage') ||
          app.contains('pessac') ||
          name.contains('chardonnay') ||
          name.contains('viognier');

      if (isRichWhite) {
        return const WineServiceAdvice(
          minTemp: 11,
          maxTemp: 13,
          tempLabel: '11°C - 13°C',
          carafeMinutes: 30,
          carafeLabel: '30 min en carafe fraîche',
          decantingAdvice: 'Un passage en carafe fraîche 30 minutes libère les notes de noisette, brioche et fruits mûrs.',
          glasswareType: 'Verre grand blanc / Bourgogne blanc',
          detailedTip: 'Ne servez jamais un grand blanc glacé, le froid anesthésie sa minéralité et sa rondeur.',
        );
      }

      return const WineServiceAdvice(
        minTemp: 9,
        maxTemp: 11,
        tempLabel: '9°C - 11°C',
        carafeMinutes: 0,
        carafeLabel: 'Service direct frais',
        decantingAdvice: 'Déboucher à la minute et maintenir au seau frais.',
        glasswareType: 'Verre à blanc élancé',
        detailedTip: 'Une belle fraîcheur fait ressortir les notes d\'agrumes et la vivacité minérale.',
      );
    }

    // 3. Sparkling / Champagne
    if (type.contains('sparkling') || type.contains('champagne') || type.contains('effervescent') || type.contains('bulles')) {
      return const WineServiceAdvice(
        minTemp: 8,
        maxTemp: 10,
        tempLabel: '8°C - 10°C',
        carafeMinutes: 0,
        carafeLabel: 'Service immédiat au seau',
        decantingAdvice: 'Servir frais dans un verre tulipe pour laisser les bulles fines s\'exprimer sans perdre leur effervescence.',
        glasswareType: 'Verre tulipe à Champagne (éviter les flûtes trop étroites ou coupes)',
        detailedTip: 'Pour un grand millésimé vineux, servez plutôt à 10-11°C pour révéler toute son ampleur.',
      );
    }

    // 4. Rosé
    if (type.contains('rosé') || type.contains('rose')) {
      return const WineServiceAdvice(
        minTemp: 8,
        maxTemp: 10,
        tempLabel: '8°C - 10°C',
        carafeMinutes: 0,
        carafeLabel: 'Service direct',
        decantingAdvice: 'Servir bien frais directement au seau à glace.',
        glasswareType: 'Verre à vin blanc universel',
        detailedTip: 'Idéal pour préserver le croquant du fruit et la vivacité florale.',
      );
    }

    // 5. Sweet / Fortified (Sauternes, Port, Tokaji)
    if (type.contains('sweet') || type.contains('liquoreux') || type.contains('porto') || type.contains('fortified')) {
      return const WineServiceAdvice(
        minTemp: 7,
        maxTemp: 9,
        tempLabel: '7°C - 9°C',
        carafeMinutes: 15,
        carafeLabel: '15 min d\'aération fraîche',
        decantingAdvice: 'Servir très frais. Le froid compense la richesse en sucres et sublime la fraîcheur acidulée.',
        glasswareType: 'Petit verre tulipe ou verre à digestif',
        detailedTip: 'Laissez le vin tempérer lentement dans le verre pour libérer les arômes de miel, d\'abricot et d\'épices.',
      );
    }

    return const WineServiceAdvice(
      minTemp: 14,
      maxTemp: 16,
      tempLabel: '14°C - 16°C',
      carafeMinutes: 30,
      carafeLabel: '30 min de repos',
      decantingAdvice: 'Ouvrir 30 minutes avant le service.',
      glasswareType: 'Verre à vin universel',
      detailedTip: 'Servir à température de cave fraîche.',
    );
  }
}

class OenologyAdvice {
  final String? barrelAgingDuration;
  final String? barrelType;
  final String? vinificationMethod;
  final String? malolacticFermentation;
  final String? harvestMethod;
  final String? terroirSoil;
  final String agingPotential;
  final double? estimatedAlcoholPct;
  final bool hasTechnicalData;

  const OenologyAdvice({
    this.barrelAgingDuration,
    this.barrelType,
    this.vinificationMethod,
    this.malolacticFermentation,
    this.harvestMethod,
    this.terroirSoil,
    required this.agingPotential,
    this.estimatedAlcoholPct,
    this.hasTechnicalData = false,
  });
}

class WineDrinkingWindowData {
  final int vintage;
  final int drinkStart;
  final int drinkEnd;
  final int peakStart;
  final int peakEnd;
  final int maxYear;
  final String agingPotentialText;

  const WineDrinkingWindowData({
    required this.vintage,
    required this.drinkStart,
    required this.drinkEnd,
    required this.peakStart,
    required this.peakEnd,
    required this.maxYear,
    required this.agingPotentialText,
  });
}

class WineOenologyAdvisor {
  static WineDrinkingWindowData computeDrinkingWindow({
    required String? wineType,
    int? vintage,
    String? region,
    String? appellation,
    String? classification,
    String? wineName,
    int? explicitDrinkStart,
    int? explicitDrinkEnd,
    int? explicitPeakStart,
    int? explicitPeakEnd,
  }) {
    final currentYear = DateTime.now().year;
    final v = vintage ?? (currentYear - 3);

    // If explicit start and end are provided in the wine model
    if (explicitDrinkStart != null && explicitDrinkEnd != null) {
      final start = explicitDrinkStart;
      final end = explicitDrinkEnd;
      final span = (end - start).clamp(1, 60);
      final pStart = explicitPeakStart ?? (start + (span * 0.35).round());
      final pEnd = explicitPeakEnd ?? (start + (span * 0.65).round());
      final maxY = math.max(end + 4, currentYear + 2);
      final minYears = math.max(1, start - v);
      final maxYears = math.max(minYears, end - v);

      return WineDrinkingWindowData(
        vintage: v,
        drinkStart: start,
        drinkEnd: end,
        peakStart: pStart,
        peakEnd: pEnd,
        maxYear: maxY,
        agingPotentialText: '$minYears à $maxYears ans (Apogée optimale : $pStart - $pEnd)',
      );
    }

    final normName = (wineName ?? '').toLowerCase();
    final normApp = (appellation ?? '').toLowerCase();
    final normReg = (region ?? '').toLowerCase();
    final type = (wineType ?? 'red').toLowerCase();

    // 1. Grands Crus de Bordeaux Rouges
    if (normApp.contains('margaux') ||
        normApp.contains('pauillac') ||
        normApp.contains('saint-julien') ||
        normApp.contains('saint-estèphe') ||
        normApp.contains('pessac') ||
        normApp.contains('pomerol') ||
        normApp.contains('saint-émilion') ||
        (normReg.contains('bordeaux') && type.contains('red'))) {
      final isPremierOrGrandCru = normName.contains('premier') ||
          normName.contains('grand cru') ||
          normName.contains('château margaux') ||
          normName.contains('lafite') ||
          normName.contains('latour') ||
          normName.contains('mouton') ||
          normName.contains('haut-brion');

      if (isPremierOrGrandCru) {
        final start = v + 10;
        final pStart = v + 15;
        final pEnd = v + 25;
        final end = v + 38;
        return WineDrinkingWindowData(
          vintage: v,
          drinkStart: start,
          drinkEnd: end,
          peakStart: pStart,
          peakEnd: pEnd,
          maxYear: math.max(end + 5, currentYear + 2),
          agingPotentialText: '20 à 40 ans (Apogée optimale : $pStart - $pEnd)',
        );
      } else {
        final start = v + 5;
        final pStart = v + 8;
        final pEnd = v + 14;
        final end = v + 20;
        return WineDrinkingWindowData(
          vintage: v,
          drinkStart: start,
          drinkEnd: end,
          peakStart: pStart,
          peakEnd: pEnd,
          maxYear: math.max(end + 4, currentYear + 2),
          agingPotentialText: '10 à 20 ans (Apogée optimale : $pStart - $pEnd)',
        );
      }
    }

    // 2. Grands Blancs de Bourgogne
    if (normApp.contains('chablis') ||
        normApp.contains('meursault') ||
        normApp.contains('montrachet') ||
        normApp.contains('corton-charlemagne') ||
        (normReg.contains('bourgogne') && type.contains('white'))) {
      final isGrandCru = normName.contains('grand cru') || normName.contains('premier cru') || normApp.contains('grand cru');
      if (isGrandCru) {
        final start = v + 4;
        final pStart = v + 7;
        final pEnd = v + 15;
        final end = v + 25;
        return WineDrinkingWindowData(
          vintage: v,
          drinkStart: start,
          drinkEnd: end,
          peakStart: pStart,
          peakEnd: pEnd,
          maxYear: math.max(end + 4, currentYear + 2),
          agingPotentialText: '10 à 25 ans (Apogée optimale : $pStart - $pEnd)',
        );
      } else {
        final start = v + 2;
        final pStart = v + 4;
        final pEnd = v + 8;
        final end = v + 12;
        return WineDrinkingWindowData(
          vintage: v,
          drinkStart: start,
          drinkEnd: end,
          peakStart: pStart,
          peakEnd: pEnd,
          maxYear: math.max(end + 3, currentYear + 2),
          agingPotentialText: '5 à 12 ans (Apogée optimale : $pStart - $pEnd)',
        );
      }
    }

    // 3. Grands Rouges de Bourgogne
    if ((normReg.contains('bourgogne') && type.contains('red')) ||
        normApp.contains('gevrey') ||
        normApp.contains('vosne') ||
        normApp.contains('chambolle') ||
        normApp.contains('pommard') ||
        normApp.contains('volnay') ||
        normApp.contains('nuits')) {
      final isGrandCru = normName.contains('grand cru') || normName.contains('premier cru');
      if (isGrandCru) {
        final start = v + 6;
        final pStart = v + 10;
        final pEnd = v + 20;
        final end = v + 30;
        return WineDrinkingWindowData(
          vintage: v,
          drinkStart: start,
          drinkEnd: end,
          peakStart: pStart,
          peakEnd: pEnd,
          maxYear: math.max(end + 4, currentYear + 2),
          agingPotentialText: '15 à 30 ans (Apogée optimale : $pStart - $pEnd)',
        );
      } else {
        final start = v + 3;
        final pStart = v + 5;
        final pEnd = v + 10;
        final end = v + 15;
        return WineDrinkingWindowData(
          vintage: v,
          drinkStart: start,
          drinkEnd: end,
          peakStart: pStart,
          peakEnd: pEnd,
          maxYear: math.max(end + 3, currentYear + 2),
          agingPotentialText: '8 à 15 ans (Apogée optimale : $pStart - $pEnd)',
        );
      }
    }

    // 4. Vallée du Rhône
    if (normReg.contains('rhône') ||
        normReg.contains('rhone') ||
        normApp.contains('châteauneuf') ||
        normApp.contains('côte-rôtie') ||
        normApp.contains('hermitage') ||
        normApp.contains('saint-joseph')) {
      final start = v + 5;
      final pStart = v + 8;
      final pEnd = v + 16;
      final end = v + 25;
      return WineDrinkingWindowData(
        vintage: v,
        drinkStart: start,
        drinkEnd: end,
        peakStart: pStart,
        peakEnd: pEnd,
        maxYear: math.max(end + 4, currentYear + 2),
        agingPotentialText: '12 à 25 ans (Apogée optimale : $pStart - $pEnd)',
      );
    }

    // 5. Blancs Frais & Minéraux (Sancerre, Loire, Alsace)
    if (normApp.contains('sancerre') ||
        normApp.contains('pouilly') ||
        normReg.contains('loire') ||
        normReg.contains('alsace')) {
      final start = v + 1;
      final pStart = v + 2;
      final pEnd = v + 5;
      final end = v + 7;
      return WineDrinkingWindowData(
        vintage: v,
        drinkStart: start,
        drinkEnd: end,
        peakStart: pStart,
        peakEnd: pEnd,
        maxYear: math.max(end + 3, currentYear + 2),
        agingPotentialText: '3 à 7 ans (Apogée optimale : $pStart - $pEnd)',
      );
    }

    // 6. Champagne & Effervescents
    if (type.contains('sparkling') || type.contains('effervescent') || normApp.contains('champagne')) {
      final start = v + 3;
      final pStart = v + 5;
      final pEnd = v + 10;
      final end = v + 15;
      return WineDrinkingWindowData(
        vintage: v,
        drinkStart: start,
        drinkEnd: end,
        peakStart: pStart,
        peakEnd: pEnd,
        maxYear: math.max(end + 3, currentYear + 2),
        agingPotentialText: '5 à 15 ans (Apogée optimale : $pStart - $pEnd)',
      );
    }

    // 7. Vins Rouges Internationaux & Nouveaux Mondes
    if (normApp.contains('barolo') || normApp.contains('brunello') || normApp.contains('rioja')) {
      final start = v + 6;
      final pStart = v + 10;
      final pEnd = v + 18;
      final end = v + 30;
      return WineDrinkingWindowData(
        vintage: v,
        drinkStart: start,
        drinkEnd: end,
        peakStart: pStart,
        peakEnd: pEnd,
        maxYear: math.max(end + 4, currentYear + 2),
        agingPotentialText: '15 à 30 ans (Apogée optimale : $pStart - $pEnd)',
      );
    }

    // 8. Générique selon couleur
    if (type.contains('red') || type.contains('rouge')) {
      final start = v + 2;
      final pStart = v + 4;
      final pEnd = v + 8;
      final end = v + 12;
      return WineDrinkingWindowData(
        vintage: v,
        drinkStart: start,
        drinkEnd: end,
        peakStart: pStart,
        peakEnd: pEnd,
        maxYear: math.max(end + 3, currentYear + 2),
        agingPotentialText: '5 à 12 ans (Apogée optimale : $pStart - $pEnd)',
      );
    } else if (type.contains('rose') || type.contains('rosé')) {
      final start = v;
      final pStart = v;
      final pEnd = v + 2;
      final end = v + 3;
      return WineDrinkingWindowData(
        vintage: v,
        drinkStart: start,
        drinkEnd: end,
        peakStart: pStart,
        peakEnd: pEnd,
        maxYear: math.max(end + 2, currentYear + 2),
        agingPotentialText: '2 à 3 ans (Fraîcheur optimale : $v - ${v + 2})',
      );
    } else {
      final start = v + 1;
      final pStart = v + 2;
      final pEnd = v + 4;
      final end = v + 6;
      return WineDrinkingWindowData(
        vintage: v,
        drinkStart: start,
        drinkEnd: end,
        peakStart: pStart,
        peakEnd: pEnd,
        maxYear: math.max(end + 3, currentYear + 2),
        agingPotentialText: '3 à 6 ans (Apogée optimale : $pStart - $pEnd)',
      );
    }
  }

  static OenologyAdvice computeAdvice({
    required String? wineType,
    int? vintage,
    String? region,
    String? appellation,
    String? producer,
    String? wineName,
    double? existingAlcoholPct,
    int? explicitDrinkStart,
    int? explicitDrinkEnd,
    int? explicitPeakStart,
    int? explicitPeakEnd,
    String? explicitBarrelAging,
    String? explicitVinification,
    String? explicitMalolactic,
    String? explicitHarvest,
    String? explicitTerroirSoil,
    bool isVerified = false,
  }) {
    final window = computeDrinkingWindow(
      wineType: wineType,
      vintage: vintage,
      region: region,
      appellation: appellation,
      wineName: wineName,
      explicitDrinkStart: explicitDrinkStart,
      explicitDrinkEnd: explicitDrinkEnd,
      explicitPeakStart: explicitPeakStart,
      explicitPeakEnd: explicitPeakEnd,
    );

    final hasData = explicitBarrelAging != null ||
        explicitVinification != null ||
        explicitMalolactic != null ||
        explicitHarvest != null ||
        explicitTerroirSoil != null;

    return OenologyAdvice(
      barrelAgingDuration: explicitBarrelAging,
      barrelType: null,
      vinificationMethod: explicitVinification,
      malolacticFermentation: explicitMalolactic,
      harvestMethod: explicitHarvest,
      terroirSoil: explicitTerroirSoil,
      agingPotential: window.agingPotentialText,
      estimatedAlcoholPct: existingAlcoholPct,
      hasTechnicalData: hasData,
    );
  }
}
