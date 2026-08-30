import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../../../shared/utils/currency_helper.dart';
import '../domain/cellar_stats.dart';

class StatsRepository {
  CellarStats computeStats(List<Bottle> bottles, {String displayCurrency = 'EUR'}) {
    int totalBottles = 0;
    int totalConsumed = 0;
    double totalPaidValue = 0.0;
    double totalEstimatedMarketValue = 0.0;
    int bottlesWithPriceCount = 0;
    double comparablePaidTotal = 0.0;
    double comparableEstTotal = 0.0;

    final Map<String, double> paidByCurrency = {};
    final Map<String, int> byType = {};
    final Map<String, int> byRegion = {};
    final Map<int, int> byVintage = {};
    final Map<DrinkWindowStatus, int> byWindowStatus = {};
    final Map<String, int> byPriceRange = {
      '< 15 €': 0,
      '15 - 30 €': 0,
      '30 - 60 €': 0,
      '60 - 120 €': 0,
      '> 120 €': 0,
    };
    final Map<String, int> byGrape = {};

    int drinkSoonCount = 0;
    int atPeakCount = 0;
    int pastPeakCount = 0;
    int? oldestVintage;
    String? oldestBottleName;

    for (final b in bottles) {
      if (b.isConsumed) {
        totalConsumed += b.quantity;
      } else {
        totalBottles += b.quantity;
        double? bottleValueInDisplay;
        double? bottlePaidInDisplay;

        if (b.purchasePrice != null && b.purchasePrice! > 0) {
          bottlesWithPriceCount += b.quantity;
          final currency = b.currency.toUpperCase();
          final bottleTotal = b.purchasePrice! * b.quantity;
          paidByCurrency[currency] = (paidByCurrency[currency] ?? 0.0) + bottleTotal;
          final convertedPaid = CurrencyHelper.convert(bottleTotal, from: currency, to: displayCurrency);
          totalPaidValue += convertedPaid;
          bottlePaidInDisplay = convertedPaid / b.quantity;
        }

        if (b.wine != null) {
          final wine = b.wine!;
          final type = wine.type;
          byType[type] = (byType[type] ?? 0) + b.quantity;

          // Region
          final reg = wine.region.isNotEmpty ? wine.region : (wine.country.isNotEmpty ? wine.country : 'Autre');
          byRegion[reg] = (byRegion[reg] ?? 0) + b.quantity;

          // Vintage
          if (wine.vintage != null) {
            final v = wine.vintage!;
            byVintage[v] = (byVintage[v] ?? 0) + b.quantity;
            if (oldestVintage == null || v < oldestVintage) {
              oldestVintage = v;
              oldestBottleName = '${wine.name} ($v)';
            }
          }

          // Window Status
          final ws = wine.windowStatus;
          byWindowStatus[ws] = (byWindowStatus[ws] ?? 0) + b.quantity;
          if (ws == DrinkWindowStatus.drinkSoon) {
            drinkSoonCount += b.quantity;
          } else if (ws == DrinkWindowStatus.inPeak) {
            atPeakCount += b.quantity;
          } else if (ws == DrinkWindowStatus.pastPeak) {
            pastPeakCount += b.quantity;
          }

          // Grapes
          for (final g in wine.grapes) {
            if (g.name.isNotEmpty) {
              byGrape[g.name] = (byGrape[g.name] ?? 0) + b.quantity;
            }
          }

          // Robust Valuation: use estimatedMarketValue if present, fallback to purchasePrice
          if (wine.estimatedMarketValue != null && wine.estimatedMarketValue! > 0) {
            final convertedEst = CurrencyHelper.convert(
              wine.estimatedMarketValue! * b.quantity,
              from: 'EUR',
              to: displayCurrency,
            );
            totalEstimatedMarketValue += convertedEst;
            bottleValueInDisplay = convertedEst / b.quantity;

            if (bottlePaidInDisplay != null) {
              comparablePaidTotal += bottlePaidInDisplay * b.quantity;
              comparableEstTotal += convertedEst;
            }
          } else if (bottlePaidInDisplay != null) {
            // Fallback: estimate is at least the purchase price
            totalEstimatedMarketValue += bottlePaidInDisplay * b.quantity;
            bottleValueInDisplay = bottlePaidInDisplay;
          }
        } else if (bottlePaidInDisplay != null) {
          totalEstimatedMarketValue += bottlePaidInDisplay * b.quantity;
          bottleValueInDisplay = bottlePaidInDisplay;
        }

        // Price range binning
        if (bottleValueInDisplay != null) {
          if (bottleValueInDisplay < 15) {
            byPriceRange['< 15 €'] = (byPriceRange['< 15 €'] ?? 0) + b.quantity;
          } else if (bottleValueInDisplay < 30) {
            byPriceRange['15 - 30 €'] = (byPriceRange['15 - 30 €'] ?? 0) + b.quantity;
          } else if (bottleValueInDisplay < 60) {
            byPriceRange['30 - 60 €'] = (byPriceRange['30 - 60 €'] ?? 0) + b.quantity;
          } else if (bottleValueInDisplay < 120) {
            byPriceRange['60 - 120 €'] = (byPriceRange['60 - 120 €'] ?? 0) + b.quantity;
          } else {
            byPriceRange['> 120 €'] = (byPriceRange['> 120 €'] ?? 0) + b.quantity;
          }
        }
      }
    }

    // Compute latent gain
    double unrealizedGainAmount = 0.0;
    double unrealizedGainPct = 0.0;
    if (comparablePaidTotal > 0 && comparableEstTotal > 0) {
      unrealizedGainAmount = comparableEstTotal - comparablePaidTotal;
      unrealizedGainPct = (unrealizedGainAmount / comparablePaidTotal) * 100;
    } else if (totalPaidValue > 0 && totalEstimatedMarketValue > totalPaidValue) {
      unrealizedGainAmount = totalEstimatedMarketValue - totalPaidValue;
      unrealizedGainPct = (unrealizedGainAmount / totalPaidValue) * 100;
    }

    String? topRegion;
    int maxRegionCount = 0;
    byRegion.forEach((k, v) {
      if (v > maxRegionCount) {
        maxRegionCount = v;
        topRegion = k;
      }
    });

    final avgPrice = totalBottles > 0
        ? (totalEstimatedMarketValue > 0 ? totalEstimatedMarketValue / totalBottles : totalPaidValue / totalBottles)
        : 0.0;

    return CellarStats(
      totalBottles: totalBottles,
      totalConsumed: totalConsumed,
      totalPaidValue: totalPaidValue,
      totalEstimatedMarketValue: totalEstimatedMarketValue,
      bottlesWithPriceCount: bottlesWithPriceCount,
      unrealizedGainAmount: unrealizedGainAmount,
      unrealizedGainPct: unrealizedGainPct,
      paidByCurrency: paidByCurrency,
      byType: byType,
      byRegion: byRegion,
      byVintage: byVintage,
      byWindowStatus: byWindowStatus,
      byPriceRange: byPriceRange,
      byGrape: byGrape,
      drinkSoonCount: drinkSoonCount,
      atPeakCount: atPeakCount,
      pastPeakCount: pastPeakCount,
      oldestVintage: oldestVintage,
      oldestBottleName: oldestBottleName,
      topRegion: topRegion,
      averageBottlePrice: avgPrice,
    );
  }
}
