import 'package:flutter/material.dart';
import 'bottle.dart';
import 'wine.dart';
import 'cellar_sort_by.dart';

enum CellarGroupBy {
  none,
  color,
  appellation,
  region,
  country,
  continent,
  maturity,
  vintage;

  String get label {
    switch (this) {
      case CellarGroupBy.none:
        return 'Aucun';
      case CellarGroupBy.color:
        return 'Couleur';
      case CellarGroupBy.appellation:
        return 'Appellation';
      case CellarGroupBy.region:
        return 'Région';
      case CellarGroupBy.country:
        return 'Pays';
      case CellarGroupBy.continent:
        return 'Continent';
      case CellarGroupBy.maturity:
        return 'Maturité / Apogée';
      case CellarGroupBy.vintage:
        return 'Millésime';
    }
  }

  String localizedLabel(dynamic lang) {
    final code = (lang is bool ? (lang ? 'fr' : 'en') : lang?.toString() ?? 'en').toLowerCase();
    if (code == 'fr') return label;
    if (code == 'la') {
      switch (this) {
        case CellarGroupBy.none:
          return 'Nullum';
        case CellarGroupBy.color:
          return 'Color';
        case CellarGroupBy.appellation:
          return 'Appellatio';
        case CellarGroupBy.region:
          return 'Regio';
        case CellarGroupBy.country:
          return 'Terra';
        case CellarGroupBy.continent:
          return 'Continens';
        case CellarGroupBy.maturity:
          return 'Maturitas / Fastigium';
        case CellarGroupBy.vintage:
          return 'Annata';
      }
    }
    if (code == 'es') {
      switch (this) {
        case CellarGroupBy.none:
          return 'Ninguno';
        case CellarGroupBy.color:
          return 'Color';
        case CellarGroupBy.appellation:
          return 'Denominación';
        case CellarGroupBy.region:
          return 'Región';
        case CellarGroupBy.country:
          return 'País';
        case CellarGroupBy.continent:
          return 'Continente';
        case CellarGroupBy.maturity:
          return 'Madurez / Apogeo';
        case CellarGroupBy.vintage:
          return 'Añada';
      }
    }
    if (code == 'ca') {
      switch (this) {
        case CellarGroupBy.none:
          return 'Cap';
        case CellarGroupBy.color:
          return 'Color';
        case CellarGroupBy.appellation:
          return 'Denominació';
        case CellarGroupBy.region:
          return 'Regió';
        case CellarGroupBy.country:
          return 'País';
        case CellarGroupBy.continent:
          return 'Continent';
        case CellarGroupBy.maturity:
          return 'Maduresa / Apogeu';
        case CellarGroupBy.vintage:
          return 'Collita';
      }
    }
    if (code == 'it') {
      switch (this) {
        case CellarGroupBy.none:
          return 'Nessuno';
        case CellarGroupBy.color:
          return 'Colore';
        case CellarGroupBy.appellation:
          return 'Denominazione';
        case CellarGroupBy.region:
          return 'Regione';
        case CellarGroupBy.country:
          return 'Paese';
        case CellarGroupBy.continent:
          return 'Continente';
        case CellarGroupBy.maturity:
          return 'Maturità / Apice';
        case CellarGroupBy.vintage:
          return 'Annata';
      }
    }
    if (code == 'de') {
      switch (this) {
        case CellarGroupBy.none:
          return 'Keine';
        case CellarGroupBy.color:
          return 'Farbe';
        case CellarGroupBy.appellation:
          return 'Appellation';
        case CellarGroupBy.region:
          return 'Region';
        case CellarGroupBy.country:
          return 'Land';
        case CellarGroupBy.continent:
          return 'Kontinent';
        case CellarGroupBy.maturity:
          return 'Trinkreife / Höhepunkt';
        case CellarGroupBy.vintage:
          return 'Jahrgang';
      }
    }
    switch (this) {
      case CellarGroupBy.none:
        return 'None';
      case CellarGroupBy.color:
        return 'Color';
      case CellarGroupBy.appellation:
        return 'Appellation';
      case CellarGroupBy.region:
        return 'Region';
      case CellarGroupBy.country:
        return 'Country';
      case CellarGroupBy.continent:
        return 'Continent';
      case CellarGroupBy.maturity:
        return 'Maturity / Peak';
      case CellarGroupBy.vintage:
        return 'Vintage';
    }
  }

  IconData get icon {
    switch (this) {
      case CellarGroupBy.none:
        return Icons.view_list_outlined;
      case CellarGroupBy.color:
        return Icons.palette_outlined;
      case CellarGroupBy.appellation:
        return Icons.terrain_outlined;
      case CellarGroupBy.region:
        return Icons.map_outlined;
      case CellarGroupBy.country:
        return Icons.flag_outlined;
      case CellarGroupBy.continent:
        return Icons.public_outlined;
      case CellarGroupBy.maturity:
        return Icons.timelapse_outlined;
      case CellarGroupBy.vintage:
        return Icons.calendar_month_outlined;
    }
  }
}

class CellarGroupSection {
  final String key;
  final String title;
  final String emoji;
  final IconData? icon;
  final Color? color;
  final List<Bottle> bottles;

  const CellarGroupSection({
    required this.key,
    required this.title,
    this.emoji = '',
    this.icon,
    this.color,
    required this.bottles,
  });

  int get totalBottleCount => bottles.fold(0, (sum, b) => sum + b.quantity);

  double get totalEstimatedValue => bottles.fold(0.0, (sum, b) {
        final val = b.wine?.estimatedMarketValue ?? b.purchasePrice ?? 0.0;
        return sum + (val * b.quantity);
      });
}

class CellarGroupEngine {
  static List<CellarGroupSection> partitionBottles(
    List<Bottle> bottles,
    CellarGroupBy groupBy, {
    CellarSortBy? sortBy,
    dynamic lang = 'fr',
  }) {
    final code = (lang is bool ? (lang ? 'fr' : 'en') : lang?.toString() ?? 'en').toLowerCase();
    final isFr = code == 'fr';

    if (groupBy == CellarGroupBy.none) {
      final sorted = sortBy != null ? sortBy.sort(bottles) : bottles;
      String allTitle = isFr ? 'Toutes les bouteilles' : 'All Bottles';
      if (code == 'la') allTitle = 'Omnes Ampullae';
      if (code == 'es') allTitle = 'Todas las botellas';
      if (code == 'ca') allTitle = 'Totes les ampolles';
      if (code == 'it') allTitle = 'Tutte le bottiglie';
      if (code == 'de') allTitle = 'Alle Flaschen';

      return [
        CellarGroupSection(
          key: 'all',
          title: allTitle,
          emoji: '🍾',
          bottles: sorted,
        ),
      ];
    }

    final Map<String, List<Bottle>> map = {};
    final Map<String, _GroupMetadata> metaMap = {};

    for (final bottle in bottles) {
      final wine = bottle.wine;
      final key = _extractKey(bottle, wine, groupBy, lang: lang);
      map.putIfAbsent(key, () => []).add(bottle);

      if (!metaMap.containsKey(key)) {
        metaMap[key] = _extractMetadata(bottle, wine, groupBy, key, lang: lang);
      }
    }

    final List<CellarGroupSection> sections = [];
    map.forEach((k, bList) {
      final meta = metaMap[k]!;
      // Sort bottles within each section according to sortBy (if provided)
      final sortedBottles = sortBy != null ? sortBy.sort(bList) : bList;
      sections.add(
        CellarGroupSection(
          key: k,
          title: meta.title,
          emoji: meta.emoji,
          icon: meta.icon,
          color: meta.color,
          bottles: sortedBottles,
        ),
      );
    });

    // Sort sections meaningfully based on sortBy and groupBy type
    sections.sort((a, b) {
      if (sortBy != null) {
        switch (sortBy) {
          case CellarSortBy.quantityDesc:
            final cmp = b.totalBottleCount.compareTo(a.totalBottleCount);
            if (cmp != 0) return cmp;
            break;
          case CellarSortBy.quantityAsc:
            final cmp = a.totalBottleCount.compareTo(b.totalBottleCount);
            if (cmp != 0) return cmp;
            break;
          case CellarSortBy.priceDesc:
            final cmp = b.totalEstimatedValue.compareTo(a.totalEstimatedValue);
            if (cmp != 0) return cmp;
            break;
          case CellarSortBy.priceAsc:
            final cmp = a.totalEstimatedValue.compareTo(b.totalEstimatedValue);
            if (cmp != 0) return cmp;
            break;
          case CellarSortBy.vintageDesc:
            if (groupBy == CellarGroupBy.vintage) {
              final vA = int.tryParse(a.key) ?? -1;
              final vB = int.tryParse(b.key) ?? -1;
              final cmp = vB.compareTo(vA);
              if (cmp != 0) return cmp;
            } else {
              int maxVintage(CellarGroupSection s) => s.bottles.fold<int>(
                    -1,
                    (max, b) => (b.wine?.vintage ?? -1) > max ? (b.wine?.vintage ?? -1) : max,
                  );
              final cmp = maxVintage(b).compareTo(maxVintage(a));
              if (cmp != 0) return cmp;
            }
            break;
          case CellarSortBy.vintageAsc:
            if (groupBy == CellarGroupBy.vintage) {
              final vA = int.tryParse(a.key) ?? 99999;
              final vB = int.tryParse(b.key) ?? 99999;
              final cmp = vA.compareTo(vB);
              if (cmp != 0) return cmp;
            } else {
              int minVintage(CellarGroupSection s) => s.bottles.fold<int>(
                    99999,
                    (min, b) => ((b.wine?.vintage ?? 99999) < min && (b.wine?.vintage ?? 0) > 0)
                        ? (b.wine!.vintage!)
                        : min,
                  );
              final cmp = minVintage(a).compareTo(minVintage(b));
              if (cmp != 0) return cmp;
            }
            break;
          case CellarSortBy.recentlyAdded:
            DateTime newestBottleDate(CellarGroupSection s) => s.bottles.fold<DateTime>(
                  DateTime(1970),
                  (latest, b) => b.createdAt.isAfter(latest) ? b.createdAt : latest,
                );
            final cmp = newestBottleDate(b).compareTo(newestBottleDate(a));
            if (cmp != 0) return cmp;
            break;
          case CellarSortBy.nameAsc:
            if (groupBy == CellarGroupBy.appellation ||
                groupBy == CellarGroupBy.region ||
                groupBy == CellarGroupBy.country ||
                groupBy == CellarGroupBy.continent) {
              final cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
              if (cmp != 0) return cmp;
            } else {
              String firstName(CellarGroupSection s) =>
                  s.bottles.isNotEmpty ? (s.bottles.first.wine?.name ?? '') : '';
              final cmp = firstName(a).toLowerCase().compareTo(firstName(b).toLowerCase());
              if (cmp != 0) return cmp;
            }
            break;
          case CellarSortBy.nameDesc:
            if (groupBy == CellarGroupBy.appellation ||
                groupBy == CellarGroupBy.region ||
                groupBy == CellarGroupBy.country ||
                groupBy == CellarGroupBy.continent) {
              final cmp = b.title.toLowerCase().compareTo(a.title.toLowerCase());
              if (cmp != 0) return cmp;
            } else {
              String firstName(CellarGroupSection s) =>
                  s.bottles.isNotEmpty ? (s.bottles.first.wine?.name ?? '') : '';
              final cmp = firstName(b).toLowerCase().compareTo(firstName(a).toLowerCase());
              if (cmp != 0) return cmp;
            }
            break;
          case CellarSortBy.producerAsc:
            String firstProducer(CellarGroupSection s) =>
                s.bottles.isNotEmpty ? (s.bottles.first.wine?.producer ?? '') : '';
            final cmp = firstProducer(a).toLowerCase().compareTo(firstProducer(b).toLowerCase());
            if (cmp != 0) return cmp;
            break;
          case CellarSortBy.producerDesc:
            String firstProducer(CellarGroupSection s) =>
                s.bottles.isNotEmpty ? (s.bottles.first.wine?.producer ?? '') : '';
            final cmp = firstProducer(b).toLowerCase().compareTo(firstProducer(a).toLowerCase());
            if (cmp != 0) return cmp;
            break;
          case CellarSortBy.maturity:
            int sectionMaturityPriority(CellarGroupSection s) {
              if (s.bottles.isEmpty) return 99;
              int best = 99;
              for (final b in s.bottles) {
                final st = b.wine?.windowStatus;
                int p = 6;
                if (st == DrinkWindowStatus.drinkSoon) {
                  p = 1;
                } else if (st == DrinkWindowStatus.inPeak) {
                  p = 2;
                } else if (st == DrinkWindowStatus.aging) {
                  p = 3;
                } else if (st == DrinkWindowStatus.tooYoung) {
                  p = 4;
                } else if (st == DrinkWindowStatus.pastPeak) {
                  p = 5;
                }
                if (p < best) best = p;
              }
              return best;
            }
            final cmp = sectionMaturityPriority(a).compareTo(sectionMaturityPriority(b));
            if (cmp != 0) return cmp;
            break;
          case CellarSortBy.color:
            final order = ['red', 'white', 'rosé', 'sparkling', 'dessert', 'orange', 'fortified', 'other'];
            final idxA = order.indexOf(a.key);
            final idxB = order.indexOf(b.key);
            final cmp = (idxA != -1 ? idxA : 99).compareTo(idxB != -1 ? idxB : 99);
            if (cmp != 0) return cmp;
            break;
        }
      }

      // Default natural order per groupBy when no override was triggered
      if (groupBy == CellarGroupBy.vintage) {
        final vA = int.tryParse(a.key) ?? -1;
        final vB = int.tryParse(b.key) ?? -1;
        return vB.compareTo(vA); // Descending year
      } else if (groupBy == CellarGroupBy.maturity) {
        final order = ['peak', 'drink_soon', 'aging', 'too_young', 'past_peak', 'spirit_no_apogee', 'unknown'];
        final idxA = order.indexOf(a.key);
        final idxB = order.indexOf(b.key);
        return (idxA != -1 ? idxA : 99).compareTo(idxB != -1 ? idxB : 99);
      } else if (groupBy == CellarGroupBy.color) {
        final order = ['red', 'white', 'rosé', 'sparkling', 'dessert', 'orange', 'fortified', 'spirit', 'other'];
        final idxA = order.indexOf(a.key);
        final idxB = order.indexOf(b.key);
        return (idxA != -1 ? idxA : 99).compareTo(idxB != -1 ? idxB : 99);
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return sections;
  }

  static String _extractKey(Bottle bottle, Wine? wine, CellarGroupBy groupBy, {dynamic lang = 'fr'}) {
    if (wine == null) return 'unknown';
    final code = (lang is bool ? (lang ? 'fr' : 'en') : lang?.toString() ?? 'en').toLowerCase();
    final isFr = code == 'fr';

    switch (groupBy) {
      case CellarGroupBy.none:
        return 'all';

      case CellarGroupBy.color:
        if (wine.isSpirit) return 'spirit';
        if (wine.isFortified) return 'fortified';
        final t = wine.type.toLowerCase().trim();
        if (t.contains('red') || t.contains('rouge')) return 'red';
        if (t.contains('white') || t.contains('blanc')) return 'white';
        if (t.contains('ros')) return 'rosé';
        if (t.contains('sparkling') || t.contains('bulles') || t.contains('champagne')) return 'sparkling';
        if (t.contains('dessert') || t.contains('moelleux') || t.contains('liquoreux')) return 'dessert';
        if (t.contains('orange')) return 'orange';
        if (t.contains('fortified') || t.contains('muté') || t.contains('porto')) return 'fortified';
        return 'other';

      case CellarGroupBy.appellation:
        final app = wine.appellation?.trim();
        if (app != null && app.isNotEmpty) return app;
        final reg = wine.region.trim();
        if (reg.isNotEmpty) {
          if (code == 'la') return '$reg (Generale)';
          if (code == 'es') return '$reg (Genérico)';
          if (code == 'ca') return '$reg (Genèric)';
          return isFr ? '$reg (Générique)' : '$reg (Generic)';
        }
        if (code == 'la') return 'Sine appellatione';
        if (code == 'es') return 'Sin denominación';
        if (code == 'ca') return 'Sense denominació';
        return isFr ? 'Sans appellation' : 'No appellation';

      case CellarGroupBy.region:
        final reg = wine.region.trim();
        final c = wine.country.trim().isNotEmpty ? wine.country.trim() : 'France';
        if (reg.isNotEmpty) {
          if (reg.toLowerCase().startsWith(c.toLowerCase())) return reg;
          return '$c - $reg';
        }
        if (code == 'la') return '$c - Regio non descripta';
        if (code == 'es') return '$c - Región no indicada';
        if (code == 'ca') return '$c - Regió no indicada';
        return isFr ? '$c - Région non renseignée' : '$c - Region not specified';

      case CellarGroupBy.country:
        final c = wine.country.trim();
        if (c.isNotEmpty) return c;
        return 'France';

      case CellarGroupBy.continent:
        return _getContinent(wine.country, lang: lang);

      case CellarGroupBy.maturity:
        if (wine.tracksFillLevel) return 'spirit_no_apogee';
        final status = wine.windowStatus;
        switch (status) {
          case DrinkWindowStatus.inPeak:
            return 'peak';
          case DrinkWindowStatus.drinkSoon:
            return 'drink_soon';
          case DrinkWindowStatus.aging:
            return 'aging';
          case DrinkWindowStatus.tooYoung:
            return 'too_young';
          case DrinkWindowStatus.pastPeak:
            return 'past_peak';
        }

      case CellarGroupBy.vintage:
        if (wine.vintage != null && wine.vintage! > 0) {
          return wine.vintage.toString();
        }
        return 'NM';
    }
  }

  static String _getContinent(String country, {dynamic lang = 'fr'}) {
    final code = (lang is bool ? (lang ? 'fr' : 'en') : lang?.toString() ?? 'en').toLowerCase();
    final isFr = code == 'fr';
    final c = country.toLowerCase().trim();
    if (c.contains('france') ||
        c.contains('ital') ||
        c.contains('espag') ||
        c.contains('spain') ||
        c.contains('portug') ||
        c.contains('allemag') ||
        c.contains('german') ||
        c.contains('suisse') ||
        c.contains('switzer') ||
        c.contains('autrich') ||
        c.contains('austria') ||
        c.contains('grèce') ||
        c.contains('greece') ||
        c.contains('hongr') ||
        c.contains('hungar') ||
        c.contains('croat') ||
        c.contains('uk') ||
        c.contains('royaume')) {
      return 'Europe';
    }
    if (c.contains('état') ||
        c.contains('etat') ||
        c.contains('state') ||
        c.contains('usa') ||
        c.contains('calif') ||
        c.contains('argentin') ||
        c.contains('chili') ||
        c.contains('chile') ||
        c.contains('canada') ||
        c.contains('brésil') ||
        c.contains('brazil') ||
        c.contains('mexiq') ||
        c.contains('mexic')) {
      if (code == 'la') return 'Americae';
      if (code == 'es') return 'Américas';
      if (code == 'ca') return 'Amèriques';
      return isFr ? 'Amériques' : 'Americas';
    }
    if (c.contains('austral') || c.contains('zélande') || c.contains('zealand')) {
      if (code == 'la' || code == 'es' || code == 'ca' || code == 'it') return 'Oceania';
      return isFr ? 'Océanie' : 'Oceania';
    }
    if (c.contains('afrique') || c.contains('africa') || c.contains('maroc') || c.contains('tunis') || c.contains('algér')) {
      if (code == 'la' || code == 'it') return 'Africa';
      if (code == 'es') return 'África';
      if (code == 'ca') return 'Àfrica';
      return isFr ? 'Afrique' : 'Africa';
    }
    if (c.contains('japon') || c.contains('japan') || c.contains('chine') || c.contains('china') || c.contains('liban') || c.contains('lebanon') || c.contains('isra')) {
      if (code == 'la') return 'Asia & Oriens Medius';
      if (code == 'es') return 'Asia y Oriente Medio';
      if (code == 'ca') return 'Àsia i Orient Mitjà';
      return isFr ? 'Asie & Moyen-Orient' : 'Asia & Middle East';
    }
    if (code == 'la') return 'Mundus & Alia';
    if (code == 'es') return 'Mundo y Otros';
    if (code == 'ca') return 'Món i Altres';
    return isFr ? 'Monde & Autres' : 'World & Others';
  }

  static _GroupMetadata _extractMetadata(
    Bottle bottle,
    Wine? wine,
    CellarGroupBy groupBy,
    String key, {
    dynamic lang = 'fr',
  }) {
    final code = (lang is bool ? (lang ? 'fr' : 'en') : lang?.toString() ?? 'en').toLowerCase();
    final isFr = code == 'fr';

    switch (groupBy) {
      case CellarGroupBy.none:
        String allTitle = isFr ? 'Toutes les bouteilles' : 'All Bottles';
        if (code == 'la') allTitle = 'Omnes Ampullae';
        if (code == 'es') allTitle = 'Todas las botellas';
        if (code == 'ca') allTitle = 'Totes les ampolles';
        return _GroupMetadata(title: allTitle, emoji: '🍾');

      case CellarGroupBy.color:
        switch (key) {
          case 'red':
            String title = isFr ? 'Vins Rouges' : 'Red Wines';
            if (code == 'la') title = 'Vina Rubra';
            if (code == 'es') title = 'Vinos Tintos';
            if (code == 'ca') title = 'Vins Negres';
            return _GroupMetadata(title: title, emoji: '🍷', color: const Color(0xFF8B1A2B));
          case 'white':
            String title = isFr ? 'Vins Blancs' : 'White Wines';
            if (code == 'la') title = 'Vina Alba';
            if (code == 'es') title = 'Vinos Blancos';
            if (code == 'ca') title = 'Vins Blancs';
            return _GroupMetadata(title: title, emoji: '🥂', color: const Color(0xFFC2A649));
          case 'rosé':
            String title = isFr ? 'Vins Rosés' : 'Rosé Wines';
            if (code == 'la') title = 'Vina Rosea';
            if (code == 'es') title = 'Vinos Rosados';
            if (code == 'ca') title = 'Vins Rosats';
            return _GroupMetadata(title: title, emoji: '🌸', color: const Color(0xFFE8A0BF));
          case 'sparkling':
            String title = isFr ? 'Champagnes & Effervescents' : 'Sparkling & Champagne';
            if (code == 'la') title = 'Campana & Spumantia';
            if (code == 'es') title = 'Champán y Espumosos';
            if (code == 'ca') title = 'Xampany i Escumosos';
            return _GroupMetadata(title: title, emoji: '✨', color: const Color(0xFFD4AF37));
          case 'dessert':
            String title = isFr ? 'Vins Moelleux & Doux' : 'Dessert & Sweet Wines';
            if (code == 'la') title = 'Vina Dulcia';
            if (code == 'es') title = 'Vinos Dulces';
            if (code == 'ca') title = 'Vins Dolços';
            return _GroupMetadata(title: title, emoji: '🍯', color: const Color(0xFFE5A65D));
          case 'orange':
            String title = isFr ? 'Vins Oranges' : 'Orange Wines';
            if (code == 'la') title = 'Vina Aurantia';
            if (code == 'es') title = 'Vinos Naranjas';
            if (code == 'ca') title = 'Vins Taronja';
            return _GroupMetadata(title: title, emoji: '🏺', color: const Color(0xFFE67E22));
          case 'fortified':
            String title = isFr ? 'Vins Fortifiés & Mutés' : 'Fortified Wines';
            if (code == 'la') title = 'Vina Fortificata';
            if (code == 'es') title = 'Vinos Fortificados';
            if (code == 'ca') title = 'Vins Fortificats';
            return _GroupMetadata(title: title, emoji: '🍷', color: const Color(0xFF78281F));
          case 'spirit':
            String title = isFr ? 'Spiritueux' : 'Spirits';
            if (code == 'la') title = 'Spiritus';
            if (code == 'es') title = 'Espirituosos';
            if (code == 'ca') title = 'Destil·lats';
            return _GroupMetadata(title: title, emoji: '🥃', color: const Color(0xFFD35400));
          default:
            String title = isFr ? 'Autres Vins' : 'Other Wines';
            if (code == 'la') title = 'Alia Vina';
            if (code == 'es') title = 'Otros Vinos';
            if (code == 'ca') title = 'Altres Vins';
            return _GroupMetadata(title: title, emoji: '🍾');
        }

      case CellarGroupBy.appellation:
        return _GroupMetadata(
          title: key,
          emoji: '🍇',
          icon: Icons.terrain_outlined,
          color: const Color(0xFF8B1E3F),
        );

      case CellarGroupBy.region:
        String regFlag = '🗺️';
        final k = key.toLowerCase();
        if (k.contains('france')) regFlag = '🇫🇷';
        if (k.contains('ital')) regFlag = '🇮🇹';
        if (k.contains('espag') || k.contains('spain')) regFlag = '🇪🇸';
        if (k.contains('portug')) regFlag = '🇵🇹';
        if (k.contains('allemag') || k.contains('german')) regFlag = '🇩🇪';
        if (k.contains('usa') || k.contains('état') || k.contains('etat') || k.contains('state')) regFlag = '🇺🇸';
        if (k.contains('argentin')) regFlag = '🇦🇷';
        if (k.contains('chili') || k.contains('chile')) regFlag = '🇨🇱';
        if (k.contains('austral')) regFlag = '🇦🇺';
        if (k.contains('zélande') || k.contains('zealand')) regFlag = '🇳🇿';
        if (k.contains('afrique') || k.contains('south africa')) regFlag = '🇿🇦';
        if (k.contains('suisse') || k.contains('switzer')) regFlag = '🇨🇭';
        return _GroupMetadata(
          title: key,
          emoji: regFlag,
          icon: Icons.map_outlined,
          color: const Color(0xFF8B1E3F),
        );

      case CellarGroupBy.country:
        String flag = '🌍';
        final k = key.toLowerCase();
        if (k.contains('france')) flag = '🇫🇷';
        if (k.contains('ital')) flag = '🇮🇹';
        if (k.contains('espag') || k.contains('spain')) flag = '🇪🇸';
        if (k.contains('portug')) flag = '🇵🇹';
        if (k.contains('allemag') || k.contains('german')) flag = '🇩🇪';
        if (k.contains('usa') || k.contains('état') || k.contains('etat') || k.contains('state')) flag = '🇺🇸';
        if (k.contains('argentin')) flag = '🇦🇷';
        if (k.contains('chili') || k.contains('chile')) flag = '🇨🇱';
        if (k.contains('austral')) flag = '🇦🇺';
        if (k.contains('zélande') || k.contains('zealand')) flag = '🇳🇿';
        if (k.contains('afrique') || k.contains('south africa')) flag = '🇿🇦';
        if (k.contains('suisse') || k.contains('switzer')) flag = '🇨🇭';
        return _GroupMetadata(title: key, emoji: flag);

      case CellarGroupBy.continent:
        String iconEmoji = '🌍';
        if (key == 'Europe') iconEmoji = '🏰';
        if (key.contains('Amériq') || key.contains('America')) iconEmoji = '🌎';
        if (key.contains('Océani') || key.contains('Oceania')) iconEmoji = '🌏';
        if (key.contains('Afriq') || key.contains('Africa')) iconEmoji = '☀️';
        if (key.contains('Asie') || key.contains('Asia')) iconEmoji = '🏯';
        return _GroupMetadata(title: key, emoji: iconEmoji);

      case CellarGroupBy.maturity:
        switch (key) {
          case 'peak':
            String title = isFr ? 'À l\'apogée (Idéal à boire)' : 'At Peak (Ready to drink)';
            if (code == 'la') title = 'In Fastigio (Aptum ad bibendum)';
            if (code == 'es') title = 'En el apogeo (Ideal para beber)';
            if (code == 'ca') title = 'En el seu apogeu (Ideal per beure)';
            return _GroupMetadata(
              title: title,
              emoji: '🌟',
              color: const Color(0xFF2E7D32),
            );
          case 'drink_soon':
            String title = isFr ? 'À boire prochainement' : 'Drink Soon';
            if (code == 'la') title = 'Mox Bibendum';
            if (code == 'es') title = 'Beber pronto';
            if (code == 'ca') title = 'Per beure aviat';
            return _GroupMetadata(
              title: title,
              emoji: '⏰',
              color: const Color(0xFFEF6C00),
            );
          case 'aging':
            String title = isFr ? 'En garde / Bon potentiel' : 'Aging / Good potential';
            if (code == 'la') title = 'In Custodia / Servandum';
            if (code == 'es') title = 'En guarda / Buen potencial';
            if (code == 'ca') title = 'En guarda / Bon potencial';
            return _GroupMetadata(
              title: title,
              emoji: '⏳',
              color: const Color(0xFF1976D2),
            );
          case 'too_young':
            String title = isFr ? 'Trop jeune / À conserver' : 'Too Young / Keep';
            if (code == 'la') title = 'Nimis Iuvenis / Custodiendum';
            if (code == 'es') title = 'Demasiado joven / Conservar';
            if (code == 'ca') title = 'Massa jove / Conservar';
            return _GroupMetadata(
              title: title,
              emoji: '🌱',
              color: const Color(0xFF7B1FA2),
            );
          case 'past_peak':
            String title = isFr ? 'Apogée dépassée' : 'Past Peak';
            if (code == 'la') title = 'Post Fastigium';
            if (code == 'es') title = 'Apogeo pasado';
            if (code == 'ca') title = 'Apogeu superat';
            return _GroupMetadata(
              title: title,
              emoji: '⚠️',
              color: const Color(0xFFC62828),
            );
          case 'spirit_no_apogee':
            String title = isFr ? 'Spiritueux & Vins Mutés (Sans apogée)' : 'Spirits & Fortified (No peak)';
            if (code == 'la') title = 'Spiritus (Sine fastigio)';
            if (code == 'es') title = 'Espirituosos (Sin apogeo)';
            if (code == 'ca') title = 'Destil·lats (Sense apogeu)';
            return _GroupMetadata(
              title: title,
              emoji: '🥃',
              color: const Color(0xFFD35400),
            );
          default:
            String title = isFr ? 'Maturité indéterminée' : 'Undetermined maturity';
            if (code == 'la') title = 'Maturitas Incognita';
            if (code == 'es') title = 'Madurez indeterminada';
            if (code == 'ca') title = 'Maduresa indeterminada';
            return _GroupMetadata(title: title, emoji: '❓');
        }

      case CellarGroupBy.vintage:
        if (key == 'NM' || key == 'unknown') {
          String title = isFr ? 'Non-Millésimé (NM)' : 'Non-Vintage (NV)';
          if (code == 'la') title = 'Non-Annata (NM)';
          if (code == 'es') title = 'Sin añada (NV)';
          if (code == 'ca') title = 'Sense anyada (NV)';
          return _GroupMetadata(title: title, emoji: '🏷️');
        }
        String title = isFr ? 'Millésime $key' : 'Vintage $key';
        if (code == 'la') title = 'Annata $key';
        if (code == 'es') title = 'Añada $key';
        if (code == 'ca') title = 'Collita $key';
        return _GroupMetadata(title: title, emoji: '📅');
    }
  }
}

class _GroupMetadata {
  final String title;
  final String emoji;
  final IconData? icon;
  final Color? color;

  const _GroupMetadata({
    required this.title,
    this.emoji = '',
    this.icon,
    this.color,
  });
}
