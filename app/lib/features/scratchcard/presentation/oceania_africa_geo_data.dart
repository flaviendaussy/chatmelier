import 'package:flutter/material.dart';

/// High-Definition Geographic and Viticultural Vector Datasets for Oceania & South Africa 🇦🇺🇳🇿🇿🇦
/// Standard ViewBox: 1000 x 1000.
class OceaniaAfricaGeoData {
  static const Rect viewBox = Rect.fromLTWH(0, 0, 1000, 1000);

  // ===========================================================================
  // 1. OCEANIA OUTLINES (Australia & New Zealand)
  // ===========================================================================
  static const String australiaMainlandSvg = 
      'M 220,240 C 340,210 460,200 580,240 C 650,290 690,380 700,480 '
      'C 705,580 670,680 590,720 C 490,750 390,740 310,700 '
      'C 240,660 190,580 180,490 C 175,400 185,310 220,240 Z';

  static const String newZealandSvg = 
      // North Island
      'M 820,380 C 850,350 880,370 890,410 C 895,450 870,490 840,510 C 815,480 805,420 820,380 Z '
      // South Island
      'M 760,540 C 800,510 835,530 845,580 C 840,640 805,710 765,750 C 735,720 735,640 760,540 Z';

  // ===========================================================================
  // 2. OCEANIA VITICULTURAL REGIONS (Polygons)
  // ===========================================================================

  /// 1. Barossa Valley, Eden Valley & McLaren Vale (Australie du Sud - Shiraz)
  static const String barossaValleySvg = 
      'M 420,530 C 470,515 520,530 535,565 C 540,600 510,640 465,645 '
      'C 425,645 395,610 400,575 C 400,550 410,535 420,530 Z';

  /// 2. Marlborough & Central Otago (Nouvelle-Zélande - Sauvignon Blanc, Pinot Noir)
  static const String marlboroughCentralOtagoSvg = 
      'M 780,535 C 820,520 855,540 860,575 C 865,620 830,670 790,680 '
      'C 755,680 735,645 740,605 C 745,570 760,545 780,535 Z';

  /// 3. Margaret River & Yarra Valley (Chardonnay, Cabernet d'orfèvre)
  static const String margaretRiverSvg = 
      'M 190,560 C 230,550 260,565 270,595 C 275,630 250,665 215,670 '
      'C 185,670 170,640 175,605 C 175,580 180,565 190,560 Z';

  // ===========================================================================
  // 3. SOUTH AFRICA OUTLINE (Western Cape)
  // ===========================================================================
  static const String southAfricaMainlandSvg = 
      'M 240,160 C 380,140 560,150 720,200 C 820,260 880,360 880,480 '
      'C 880,590 820,700 720,780 C 620,850 480,880 360,860 '
      'C 280,840 220,780 195,700 C 170,600 175,480 190,370 '
      'C 200,280 210,210 240,160 Z';

  // ===========================================================================
  // 4. SOUTH AFRICAN VITICULTURAL REGIONS (Polygons)
  // ===========================================================================

  /// 1. Stellenbosch, Franschhoek & Swartland (Western Cape - Chenin, Pinotage, Syrah)
  static const String stellenboschSwartlandSvg = 
      'M 260,650 C 340,630 420,645 455,700 C 465,755 425,820 355,835 '
      'C 285,845 240,795 240,735 C 240,690 245,665 260,650 Z';
}
