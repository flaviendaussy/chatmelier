import 'package:flutter/material.dart';
import 'bottle.dart';
import 'wine.dart';

enum CellarSortBy {
  nameAsc('name_asc', 'Nom du vin (A → Z)', Icons.sort_by_alpha),
  nameDesc('name_desc', 'Nom du vin (Z → A)', Icons.sort_by_alpha),
  producerAsc('producer_asc', 'Domaine / Producteur (A → Z)', Icons.business),
  producerDesc('producer_desc', 'Domaine / Producteur (Z → A)', Icons.business),
  vintageDesc('vintage_desc', 'Millésime (Plus récent)', Icons.calendar_today),
  vintageAsc('vintage_asc', 'Millésime (Plus ancien)', Icons.history),
  maturity('maturity', 'Prêt à boire (Apogée & Urgence)', Icons.hourglass_top),
  quantityDesc('qty_desc', 'Quantité (Décroissante)', Icons.inventory_2),
  quantityAsc('qty_asc', 'Quantité (Croissante)', Icons.inventory_2_outlined),
  color('color', 'Couleur & Type', Icons.palette),
  priceDesc('price_desc', 'Prix / Valeur (Plus cher)', Icons.trending_up),
  priceAsc('price_asc', 'Prix / Valeur (Moins cher)', Icons.trending_down),
  recentlyAdded('recently_added', 'Date d\'ajout récente', Icons.schedule);

  final String key;
  final String label;
  final IconData icon;

  const CellarSortBy(this.key, this.label, this.icon);

  static CellarSortBy fromKey(String? key) {
    if (key == null) return CellarSortBy.recentlyAdded;
    return CellarSortBy.values.firstWhere(
      (e) => e.key == key,
      orElse: () => CellarSortBy.recentlyAdded,
    );
  }

  /// Sort a list of bottles in-place based on this criterion
  List<Bottle> sort(List<Bottle> bottles) {
    final list = List<Bottle>.from(bottles);
    list.sort((a, b) {
      final wineA = a.wine;
      final wineB = b.wine;

      switch (this) {
        case CellarSortBy.nameAsc:
          final nameA = (wineA?.name ?? '').toLowerCase();
          final nameB = (wineB?.name ?? '').toLowerCase();
          return nameA.compareTo(nameB);

        case CellarSortBy.nameDesc:
          final nameA = (wineA?.name ?? '').toLowerCase();
          final nameB = (wineB?.name ?? '').toLowerCase();
          return nameB.compareTo(nameA);

        case CellarSortBy.producerAsc:
          final prodA = (wineA?.producer ?? '').toLowerCase();
          final prodB = (wineB?.producer ?? '').toLowerCase();
          return prodA.compareTo(prodB);

        case CellarSortBy.producerDesc:
          final prodA = (wineA?.producer ?? '').toLowerCase();
          final prodB = (wineB?.producer ?? '').toLowerCase();
          return prodB.compareTo(prodA);

        case CellarSortBy.vintageDesc:
          final vA = wineA?.vintage ?? 0;
          final vB = wineB?.vintage ?? 0;
          return vB.compareTo(vA);

        case CellarSortBy.vintageAsc:
          final vA = wineA?.vintage ?? 9999;
          final vB = wineB?.vintage ?? 9999;
          return vA.compareTo(vB);

        case CellarSortBy.maturity:
          // Order: drinkSoon (1) -> inPeak (2) -> aging (3) -> tooYoung (4) -> pastPeak (5) -> unknown (6)
          int getMaturityPriority(Bottle b) {
            final s = b.wine?.windowStatus;
            if (s == null) return 6;
            switch (s) {
              case DrinkWindowStatus.drinkSoon:
                return 1;
              case DrinkWindowStatus.inPeak:
                return 2;
              case DrinkWindowStatus.aging:
                return 3;
              case DrinkWindowStatus.tooYoung:
                return 4;
              case DrinkWindowStatus.pastPeak:
                return 5;
            }
          }
          final pA = getMaturityPriority(a);
          final pB = getMaturityPriority(b);
          if (pA != pB) return pA.compareTo(pB);
          // Secondary sort: vintage ascending
          return (a.wine?.vintage ?? 0).compareTo(b.wine?.vintage ?? 0);

        case CellarSortBy.quantityDesc:
          return b.quantity.compareTo(a.quantity);

        case CellarSortBy.quantityAsc:
          return a.quantity.compareTo(b.quantity);

        case CellarSortBy.color:
          int getColorPriority(String? type) {
            final t = (type ?? '').toLowerCase();
            if (t.contains('red') || t.contains('rouge')) return 1;
            if (t.contains('white') || t.contains('blanc')) return 2;
            if (t.contains('rose') || t.contains('rosé')) return 3;
            if (t.contains('sparkling') || t.contains('champagne') || t.contains('bulles') || t.contains('effervescent')) return 4;
            if (t.contains('sweet') || t.contains('liquoreux')) return 5;
            return 6;
          }
          final cA = getColorPriority(wineA?.type);
          final cB = getColorPriority(wineB?.type);
          if (cA != cB) return cA.compareTo(cB);
          return (wineA?.name ?? '').compareTo(wineB?.name ?? '');

        case CellarSortBy.priceDesc:
          final valA = wineA?.estimatedMarketValue ?? a.purchasePrice ?? 0.0;
          final valB = wineB?.estimatedMarketValue ?? b.purchasePrice ?? 0.0;
          return valB.compareTo(valA);

        case CellarSortBy.priceAsc:
          final valA = wineA?.estimatedMarketValue ?? a.purchasePrice ?? 999999.0;
          final valB = wineB?.estimatedMarketValue ?? b.purchasePrice ?? 999999.0;
          return valA.compareTo(valB);

        case CellarSortBy.recentlyAdded:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return list;
  }
}
