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
  }) {
    if (groupBy == CellarGroupBy.none) {
      final sorted = sortBy != null ? sortBy.sort(bottles) : bottles;
      return [
        CellarGroupSection(
          key: 'all',
          title: 'Toutes les bouteilles',
          emoji: '🍾',
          bottles: sorted,
        ),
      ];
    }

    final Map<String, List<Bottle>> map = {};
    final Map<String, _GroupMetadata> metaMap = {};

    for (final bottle in bottles) {
      final wine = bottle.wine;
      final key = _extractKey(bottle, wine, groupBy);
      map.putIfAbsent(key, () => []).add(bottle);

      if (!metaMap.containsKey(key)) {
        metaMap[key] = _extractMetadata(bottle, wine, groupBy, key);
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
      // 1. If user explicitly sorted by quantity, order sections by total count
      if (sortBy == CellarSortBy.quantityDesc) {
        final cmp = b.totalBottleCount.compareTo(a.totalBottleCount);
        if (cmp != 0) return cmp;
      } else if (sortBy == CellarSortBy.quantityAsc) {
        final cmp = a.totalBottleCount.compareTo(b.totalBottleCount);
        if (cmp != 0) return cmp;
      } else if (sortBy == CellarSortBy.priceDesc) {
        final cmp = b.totalEstimatedValue.compareTo(a.totalEstimatedValue);
        if (cmp != 0) return cmp;
      } else if (sortBy == CellarSortBy.priceAsc) {
        final cmp = a.totalEstimatedValue.compareTo(b.totalEstimatedValue);
        if (cmp != 0) return cmp;
      }

      if (groupBy == CellarGroupBy.vintage) {
        final vA = int.tryParse(a.key) ?? -1;
        final vB = int.tryParse(b.key) ?? -1;
        return vB.compareTo(vA); // Descending year
      } else if (groupBy == CellarGroupBy.maturity) {
        final order = ['peak', 'drink_soon', 'aging', 'too_young', 'past_peak', 'unknown'];
        final idxA = order.indexOf(a.key);
        final idxB = order.indexOf(b.key);
        return (idxA != -1 ? idxA : 99).compareTo(idxB != -1 ? idxB : 99);
      } else if (groupBy == CellarGroupBy.color) {
        final order = ['red', 'white', 'rosé', 'sparkling', 'dessert', 'orange', 'fortified', 'other'];
        final idxA = order.indexOf(a.key);
        final idxB = order.indexOf(b.key);
        return (idxA != -1 ? idxA : 99).compareTo(idxB != -1 ? idxB : 99);
      }
      return a.title.compareTo(b.title);
    });

    return sections;
  }

  static String _extractKey(Bottle bottle, Wine? wine, CellarGroupBy groupBy) {
    if (wine == null) return 'unknown';

    switch (groupBy) {
      case CellarGroupBy.none:
        return 'all';

      case CellarGroupBy.color:
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
        if (reg.isNotEmpty) return '$reg (Générique)';
        return 'Sans appellation';

      case CellarGroupBy.region:
        final reg = wine.region.trim();
        final c = wine.country.trim().isNotEmpty ? wine.country.trim() : 'France';
        if (reg.isNotEmpty) {
          if (reg.toLowerCase().startsWith(c.toLowerCase())) return reg;
          return '$c - $reg';
        }
        return '$c - Région non renseignée';

      case CellarGroupBy.country:
        final c = wine.country.trim();
        if (c.isNotEmpty) return c;
        return 'France';

      case CellarGroupBy.continent:
        return _getContinent(wine.country);

      case CellarGroupBy.maturity:
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

  static String _getContinent(String country) {
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
      return 'Amériques';
    }
    if (c.contains('austral') || c.contains('zélande') || c.contains('zealand')) {
      return 'Océanie';
    }
    if (c.contains('afrique') || c.contains('africa') || c.contains('maroc') || c.contains('tunis') || c.contains('algér')) {
      return 'Afrique';
    }
    if (c.contains('japon') || c.contains('japan') || c.contains('chine') || c.contains('china') || c.contains('liban') || c.contains('lebanon') || c.contains('isra')) {
      return 'Asie & Moyen-Orient';
    }
    return 'Monde & Autres';
  }

  static _GroupMetadata _extractMetadata(
    Bottle bottle,
    Wine? wine,
    CellarGroupBy groupBy,
    String key,
  ) {
    switch (groupBy) {
      case CellarGroupBy.none:
        return const _GroupMetadata(title: 'Toutes les bouteilles', emoji: '🍾');

      case CellarGroupBy.color:
        switch (key) {
          case 'red':
            return const _GroupMetadata(title: 'Vins Rouges', emoji: '🍷', color: Color(0xFF8B1A2B));
          case 'white':
            return const _GroupMetadata(title: 'Vins Blancs', emoji: '🥂', color: Color(0xFFC2A649));
          case 'rosé':
            return const _GroupMetadata(title: 'Vins Rosés', emoji: '🌸', color: Color(0xFFE8A0BF));
          case 'sparkling':
            return const _GroupMetadata(title: 'Champagnes & Effervescents', emoji: '✨', color: Color(0xFFD4AF37));
          case 'dessert':
            return const _GroupMetadata(title: 'Vins Moelleux & Doux', emoji: '🍯', color: Color(0xFFE5A65D));
          case 'orange':
            return const _GroupMetadata(title: 'Vins Oranges', emoji: '🏺', color: Color(0xFFE67E22));
          case 'fortified':
            return const _GroupMetadata(title: 'Vins Fortifiés & Mutés', emoji: '🍷', color: Color(0xFF78281F));
          default:
            return const _GroupMetadata(title: 'Autres Vins', emoji: '🍾');
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
        if (key == 'Amériques') iconEmoji = '🌎';
        if (key == 'Océanie') iconEmoji = '🌏';
        if (key == 'Afrique') iconEmoji = '☀️';
        if (key.contains('Asie')) iconEmoji = '🏯';
        return _GroupMetadata(title: key, emoji: iconEmoji);

      case CellarGroupBy.maturity:
        switch (key) {
          case 'peak':
            return const _GroupMetadata(
              title: 'À l\'apogée (Idéal à boire)',
              emoji: '🌟',
              color: Color(0xFF2E7D32),
            );
          case 'drink_soon':
            return const _GroupMetadata(
              title: 'À boire prochainement',
              emoji: '⏰',
              color: Color(0xFFEF6C00),
            );
          case 'aging':
            return const _GroupMetadata(
              title: 'En garde / Bon potentiel',
              emoji: '⏳',
              color: Color(0xFF1976D2),
            );
          case 'too_young':
            return const _GroupMetadata(
              title: 'Trop jeune / À conserver',
              emoji: '🌱',
              color: Color(0xFF7B1FA2),
            );
          case 'past_peak':
            return const _GroupMetadata(
              title: 'Apogée dépassée',
              emoji: '⚠️',
              color: Color(0xFFC62828),
            );
          default:
            return const _GroupMetadata(title: 'Maturité indéterminée', emoji: '❓');
        }

      case CellarGroupBy.vintage:
        if (key == 'NM' || key == 'unknown') {
          return const _GroupMetadata(title: 'Non-Millésimé (NM)', emoji: '🏷️');
        }
        return _GroupMetadata(title: 'Millésime $key', emoji: '📅');
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
