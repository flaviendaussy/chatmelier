import '../../cellar/domain/wine.dart';

class CellarStats {
  final int totalBottles;
  final int totalConsumed;
  final double totalPaidValue;
  final double totalEstimatedMarketValue;
  final int bottlesWithPriceCount;
  final double unrealizedGainAmount;
  final double unrealizedGainPct;
  final Map<String, double> paidByCurrency;
  final Map<String, int> byType;
  final Map<String, int> byRegion;
  final Map<int, int> byVintage;
  final Map<DrinkWindowStatus, int> byWindowStatus;
  final Map<String, int> byPriceRange;
  final Map<String, int> byGrape;
  final int drinkSoonCount;
  final int atPeakCount;
  final int pastPeakCount;
  final int? oldestVintage;
  final String? oldestBottleName;
  final String? topRegion;
  final double averageBottlePrice;

  const CellarStats({
    this.totalBottles = 0,
    this.totalConsumed = 0,
    this.totalPaidValue = 0.0,
    this.totalEstimatedMarketValue = 0.0,
    this.bottlesWithPriceCount = 0,
    this.unrealizedGainAmount = 0.0,
    this.unrealizedGainPct = 0.0,
    this.paidByCurrency = const {},
    this.byType = const {},
    this.byRegion = const {},
    this.byVintage = const {},
    this.byWindowStatus = const {},
    this.byPriceRange = const {},
    this.byGrape = const {},
    this.drinkSoonCount = 0,
    this.atPeakCount = 0,
    this.pastPeakCount = 0,
    this.oldestVintage,
    this.oldestBottleName,
    this.topRegion,
    this.averageBottlePrice = 0.0,
  });
}
