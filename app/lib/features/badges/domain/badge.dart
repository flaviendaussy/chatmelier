import 'package:flutter/material.dart';

enum BadgeCategory {
  milestones,
  continents,
  countries,
  regions,
  grapes,
  aging,
  cocktails,
  spirits,
  looser,
  chatmelierSavant,
}

extension BadgeCategoryX on BadgeCategory {
  String label(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'fr':
        return labelFr;
      case 'it':
        return labelIt;
      case 'es':
        return labelEs;
      case 'ca':
        return labelCa;
      case 'pt':
        return labelPt;
      case 'nl':
        return labelNl;
      case 'de':
        return labelDe;
      case 'ja':
        return labelJa;
      case 'zh':
        return labelZh;
      case 'ko':
        return labelKo;
      case 'sv':
        return labelSv;
      default:
        return labelEn;
    }
  }

  String get labelFr {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Paliers de Cave';
      case BadgeCategory.continents:
        return 'Continents';
      case BadgeCategory.countries:
        return 'Pays';
      case BadgeCategory.regions:
        return 'Régions';
      case BadgeCategory.grapes:
        return 'Cépages';
      case BadgeCategory.aging:
        return 'Garde & Apogée';
      case BadgeCategory.cocktails:
        return 'Mixologie';
      case BadgeCategory.spirits:
        return 'Spiritueux';
      case BadgeCategory.looser:
        return 'Autodérision 💩';
      case BadgeCategory.chatmelierSavant:
        return 'Le Chatmelier Savant';
    }
  }

  String get labelEn {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Cellar Milestones';
      case BadgeCategory.continents:
        return 'Continents';
      case BadgeCategory.countries:
        return 'Countries';
      case BadgeCategory.regions:
        return 'Regions';
      case BadgeCategory.grapes:
        return 'Grape Varieties';
      case BadgeCategory.aging:
        return 'Aging & Peak';
      case BadgeCategory.cocktails:
        return 'Mixology';
      case BadgeCategory.spirits:
        return 'Spirits';
      case BadgeCategory.looser:
        return 'Self-Deprecation 💩';
      case BadgeCategory.chatmelierSavant:
        return 'The Erudite Chatmelier';
    }
  }

  String get labelIt {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Traguardi Cantina';
      case BadgeCategory.continents:
        return 'Continenti';
      case BadgeCategory.countries:
        return 'Paesi';
      case BadgeCategory.regions:
        return 'Regioni';
      case BadgeCategory.grapes:
        return 'Vitigni';
      case BadgeCategory.aging:
        return 'Affinamento & Apice';
      case BadgeCategory.cocktails:
        return 'Mixology';
      case BadgeCategory.spirits:
        return 'Distillati';
      case BadgeCategory.looser:
        return 'Autoironia 💩';
      case BadgeCategory.chatmelierSavant:
        return 'Il Chatmelier Sapiente';
    }
  }

  String get labelEs {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Hitos de Bodega';
      case BadgeCategory.continents:
        return 'Continentes';
      case BadgeCategory.countries:
        return 'Países';
      case BadgeCategory.regions:
        return 'Regiones';
      case BadgeCategory.grapes:
        return 'Variedades de Uva';
      case BadgeCategory.aging:
        return 'Crianza & Apogeo';
      case BadgeCategory.cocktails:
        return 'Mixología';
      case BadgeCategory.spirits:
        return 'Espirituosos';
      case BadgeCategory.looser:
        return 'Autoironía 💩';
      case BadgeCategory.chatmelierSavant:
        return 'El Chatmelier Erudito';
    }
  }

  String get labelCa {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Fites de Celler';
      case BadgeCategory.continents:
        return 'Continents';
      case BadgeCategory.countries:
        return 'Països';
      case BadgeCategory.regions:
        return 'Regions';
      case BadgeCategory.grapes:
        return 'Varietats de Raïm';
      case BadgeCategory.aging:
        return 'Criança & Apogeu';
      case BadgeCategory.cocktails:
        return 'Mixologia';
      case BadgeCategory.spirits:
        return 'Espirituosos';
      case BadgeCategory.looser:
        return 'Autoironia 💩';
      case BadgeCategory.chatmelierSavant:
        return 'El Chatmelier Savi';
    }
  }

  String get labelPt {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Marcos da Adega';
      case BadgeCategory.continents:
        return 'Continentes';
      case BadgeCategory.countries:
        return 'Países';
      case BadgeCategory.regions:
        return 'Regiões';
      case BadgeCategory.grapes:
        return 'Castas';
      case BadgeCategory.aging:
        return 'Envelhecimento & Apogeu';
      case BadgeCategory.cocktails:
        return 'Mixologia';
      case BadgeCategory.spirits:
        return 'Destilados';
      case BadgeCategory.looser:
        return 'Autoironia 💩';
      case BadgeCategory.chatmelierSavant:
        return 'O Chatmelier Erudito';
    }
  }

  String get labelNl {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Keldermijlpalen';
      case BadgeCategory.continents:
        return 'Continenten';
      case BadgeCategory.countries:
        return 'Landen';
      case BadgeCategory.regions:
        return 'Regio\'s';
      case BadgeCategory.grapes:
        return 'Druivenrassen';
      case BadgeCategory.aging:
        return 'Rijping & Hoogtepunt';
      case BadgeCategory.cocktails:
        return 'Mixologie';
      case BadgeCategory.spirits:
        return 'Gedistilleerd';
      case BadgeCategory.looser:
        return 'Zelfspot 💩';
      case BadgeCategory.chatmelierSavant:
        return 'De Geleerde Chatmelier';
    }
  }

  String get labelDe {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Keller-Meilensteine';
      case BadgeCategory.continents:
        return 'Kontinente';
      case BadgeCategory.countries:
        return 'Länder';
      case BadgeCategory.regions:
        return 'Regionen';
      case BadgeCategory.grapes:
        return 'Rebsorten';
      case BadgeCategory.aging:
        return 'Reifung & Höhepunkt';
      case BadgeCategory.cocktails:
        return 'Mixologie';
      case BadgeCategory.spirits:
        return 'Spirituosen';
      case BadgeCategory.looser:
        return 'Selbstironie 💩';
      case BadgeCategory.chatmelierSavant:
        return 'Der Gelehrte Chatmelier';
    }
  }

  String get labelJa {
    switch (this) {
      case BadgeCategory.milestones:
        return 'セラーのマイルストーン';
      case BadgeCategory.continents:
        return '大陸';
      case BadgeCategory.countries:
        return '国';
      case BadgeCategory.regions:
        return '地域';
      case BadgeCategory.grapes:
        return 'ブドウ品種';
      case BadgeCategory.aging:
        return '熟成と飲み頃';
      case BadgeCategory.cocktails:
        return 'ミクソロジー';
      case BadgeCategory.spirits:
        return 'スピリッツ';
      case BadgeCategory.looser:
        return '自虐 💩';
      case BadgeCategory.chatmelierSavant:
        return '碩学のシャトゥメリエ';
    }
  }

  String get labelZh {
    switch (this) {
      case BadgeCategory.milestones:
        return '酒窖里程碑';
      case BadgeCategory.continents:
        return '大洲';
      case BadgeCategory.countries:
        return '国家';
      case BadgeCategory.regions:
        return '产区';
      case BadgeCategory.grapes:
        return '葡萄品种';
      case BadgeCategory.aging:
        return '陈年与巅峰';
      case BadgeCategory.cocktails:
        return '调酒艺术';
      case BadgeCategory.spirits:
        return '烈酒';
      case BadgeCategory.looser:
        return '自嘲幽默 💩';
      case BadgeCategory.chatmelierSavant:
        return '博学沙特梅利耶';
    }
  }

  String get labelKo {
    switch (this) {
      case BadgeCategory.milestones:
        return '셀러 마일스톤';
      case BadgeCategory.continents:
        return '대륙';
      case BadgeCategory.countries:
        return '국가';
      case BadgeCategory.regions:
        return '지역';
      case BadgeCategory.grapes:
        return '포도 품종';
      case BadgeCategory.aging:
        return '숙성 & 절정기';
      case BadgeCategory.cocktails:
        return '믹솔로지';
      case BadgeCategory.spirits:
        return '증류주';
      case BadgeCategory.looser:
        return '자조 유머 💩';
      case BadgeCategory.chatmelierSavant:
        return '석학 샤트믈리에';
    }
  }

  String get labelSv {
    switch (this) {
      case BadgeCategory.milestones:
        return 'Källarmilstolpar';
      case BadgeCategory.continents:
        return 'Kontinenter';
      case BadgeCategory.countries:
        return 'Länder';
      case BadgeCategory.regions:
        return 'Regioner';
      case BadgeCategory.grapes:
        return 'Druvsorter';
      case BadgeCategory.aging:
        return 'Lagring & Topp';
      case BadgeCategory.cocktails:
        return 'Mixologi';
      case BadgeCategory.spirits:
        return 'Spritdrycker';
      case BadgeCategory.looser:
        return 'Självironi 💩';
      case BadgeCategory.chatmelierSavant:
        return 'Den Lärde Chatmelier';
    }
  }

  IconData get icon {
    switch (this) {
      case BadgeCategory.milestones:
        return Icons.military_tech_outlined;
      case BadgeCategory.continents:
        return Icons.public;
      case BadgeCategory.countries:
        return Icons.flag_outlined;
      case BadgeCategory.regions:
        return Icons.map_outlined;
      case BadgeCategory.grapes:
        return Icons.grain;
      case BadgeCategory.aging:
        return Icons.hourglass_top;
      case BadgeCategory.cocktails:
        return Icons.local_bar;
      case BadgeCategory.spirits:
        return Icons.wine_bar;
      case BadgeCategory.looser:
        return Icons.sentiment_very_dissatisfied;
      case BadgeCategory.chatmelierSavant:
        return Icons.auto_awesome;
    }
  }
}

enum BadgeTier {
  bronze,
  silver,
  gold,
  diamond,
}

extension BadgeTierX on BadgeTier {
  String label(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'fr':
        return labelFr;
      case 'it':
      case 'es':
        return labelEs;
      case 'ca':
        return labelCa;
      case 'pt':
        return labelPt;
      case 'nl':
        return labelNl;
      case 'de':
        return labelDe;
      case 'ja':
        return labelJa;
      case 'zh':
        return labelZh;
      case 'ko':
        return labelKo;
      case 'sv':
        return labelSv;
      default:
        return labelEn;
    }
  }

  String get labelFr {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Argent';
      case BadgeTier.gold:
        return 'Or';
      case BadgeTier.diamond:
        return 'Diamant';
    }
  }

  String get labelEn {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Gold';
      case BadgeTier.diamond:
        return 'Diamond';
    }
  }

  String get labelEs {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronce';
      case BadgeTier.silver:
        return 'Plata';
      case BadgeTier.gold:
        return 'Oro';
      case BadgeTier.diamond:
        return 'Diamante';
    }
  }

  String get labelCa {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Argent';
      case BadgeTier.gold:
        return 'Or';
      case BadgeTier.diamond:
        return 'Diamant';
    }
  }

  String get labelPt {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Prata';
      case BadgeTier.gold:
        return 'Ouro';
      case BadgeTier.diamond:
        return 'Diamante';
    }
  }

  String get labelNl {
    switch (this) {
      case BadgeTier.bronze:
        return 'Brons';
      case BadgeTier.silver:
        return 'Zilver';
      case BadgeTier.gold:
        return 'Goud';
      case BadgeTier.diamond:
        return 'Diamant';
    }
  }

  String get labelDe {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silber';
      case BadgeTier.gold:
        return 'Gold';
      case BadgeTier.diamond:
        return 'Diamant';
    }
  }

  String get labelJa {
    switch (this) {
      case BadgeTier.bronze:
        return 'ブロンズ';
      case BadgeTier.silver:
        return 'シルバー';
      case BadgeTier.gold:
        return 'ゴールド';
      case BadgeTier.diamond:
        return 'ダイヤ';
    }
  }

  String get labelZh {
    switch (this) {
      case BadgeTier.bronze:
        return '青铜';
      case BadgeTier.silver:
        return '白银';
      case BadgeTier.gold:
        return '黄金';
      case BadgeTier.diamond:
        return '钻石';
    }
  }

  String get labelKo {
    switch (this) {
      case BadgeTier.bronze:
        return '브론즈';
      case BadgeTier.silver:
        return '실버';
      case BadgeTier.gold:
        return '골드';
      case BadgeTier.diamond:
        return '다이아몬드';
    }
  }

  String get labelSv {
    switch (this) {
      case BadgeTier.bronze:
        return 'Brons';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Guld';
      case BadgeTier.diamond:
        return 'Diamant';
    }
  }

  Color get color {
    switch (this) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFD4AF37);
      case BadgeTier.diamond:
        return const Color(0xFF00E5FF);
    }
  }
}

class WineBadge {
  final String id;
  final String title;
  final String? titleEn;
  final String emoji;
  final BadgeCategory category;
  final BadgeTier tier;
  final String description;
  final String? descriptionEn;
  final String chatmelierLore;
  final String? chatmelierLoreEn;
  final int requiredCount;
  final String? assetImagePath;

  const WineBadge({
    required this.id,
    required this.title,
    this.titleEn,
    required this.emoji,
    required this.category,
    required this.tier,
    required this.description,
    this.descriptionEn,
    required this.chatmelierLore,
    this.chatmelierLoreEn,
    this.requiredCount = 1,
    this.assetImagePath,
  });

  String localizedTitle(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (code != 'fr' && titleEn != null && titleEn!.isNotEmpty) {
      return titleEn!;
    }
    return title;
  }

  String localizedDescription(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (code != 'fr' && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn!;
    }
    return description;
  }

  String localizedLore(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (code != 'fr' && chatmelierLoreEn != null && chatmelierLoreEn!.isNotEmpty) {
      return chatmelierLoreEn!;
    }
    return chatmelierLore;
  }
}

class BadgeProgress {
  final WineBadge badge;
  final int currentCount;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const BadgeProgress({
    required this.badge,
    required this.currentCount,
    required this.isUnlocked,
    this.unlockedAt,
  });

  double get progressFraction {
    if (badge.requiredCount <= 0) return 1.0;
    final f = currentCount / badge.requiredCount;
    return f.clamp(0.0, 1.0);
  }
}
