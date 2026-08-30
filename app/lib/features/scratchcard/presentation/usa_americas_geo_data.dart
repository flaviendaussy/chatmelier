import 'package:flutter/material.dart';

/// High-Definition Geographic and Viticultural Vector Datasets for North & South Americas 🇺🇸🇦🇷🇨🇱
/// Standard ViewBox: 1000 x 1000.
class UsaAmericasGeoData {
  static const Rect viewBox = Rect.fromLTWH(0, 0, 1000, 1000);

  // ===========================================================================
  // 1. US PACIFIC COAST OUTLINE (Washington, Oregon, California)
  // ===========================================================================
  static const String usWestCoastMainlandSvg = 
      'M 350,50 C 450,45 650,50 780,60 C 800,220 780,380 770,540 '
      'C 760,680 740,820 680,940 C 580,920 480,850 410,750 '
      'C 360,670 330,580 320,480 C 310,380 290,270 280,180 '
      'C 275,110 300,60 350,50 Z';

  static const String usPacificRiversSvg = 
      'M 760,110 C 620,105 480,115 310,120 '                          // Columbia River
      'M 340,120 C 345,180 340,240 335,310 '                          // Willamette River
      'M 420,530 C 400,560 375,590 355,620 ';                         // Napa & Russian River

  // ===========================================================================
  // 2. US PACIFIC VITICULTURAL REGIONS (Polygons)
  // ===========================================================================

  /// 1. Napa Valley (Oakville, Rutherford, Stag's Leap, Howell Mtn)
  static const String napaValleySvg = 
      'M 370,540 C 395,525 425,540 435,565 C 440,595 420,625 395,630 '
      'C 370,630 350,605 350,575 C 350,555 360,545 370,540 Z';

  /// 2. Sonoma County & Côte Pacifique (Russian River, Sonoma Coast, Alexander Valley)
  static const String sonomaCountySvg = 
      'M 330,550 C 365,540 385,555 390,585 C 395,620 375,655 345,660 '
      'C 320,660 305,630 310,595 C 310,570 320,555 330,550 Z';

  /// 3. Oregon & Willamette Valley (Dundee Hills, Terres volcaniques Jory)
  static const String oregonWillametteSvg = 
      'M 320,170 C 365,160 405,175 415,210 C 420,250 395,295 355,300 '
      'C 320,300 300,265 305,225 C 305,195 310,175 320,170 Z';

  /// 4. Washington State & Columbia Valley (Walla Walla, Red Mountain, Yakima)
  static const String washingtonColumbiaSvg = 
      'M 440,75 C 560,65 670,80 710,120 C 725,170 680,225 600,235 '
      'C 510,240 440,205 425,155 C 420,110 430,85 440,75 Z';

  // ===========================================================================
  // 3. SOUTH AMERICA OUTLINE (Chile & Argentina Southern Cone)
  // ===========================================================================
  static const String southAmericaMainlandSvg = 
      'M 380,80 C 480,75 620,110 740,180 C 820,260 880,360 890,480 '
      'C 895,590 840,700 760,790 C 690,870 590,930 490,960 '
      'C 450,965 420,930 410,870 C 390,770 370,650 360,530 '
      'C 350,410 340,290 350,180 C 355,120 365,90 380,80 Z';

  static const String andesRidgeSvg = 
      'M 410,100 C 415,250 420,400 425,550 C 430,700 435,830 440,940 ';

  // ===========================================================================
  // 4. SOUTH AMERICAN VITICULTURAL REGIONS (Polygons)
  // ===========================================================================

  /// 1. Mendoza & Valle de Uco (Argentine - Malbec d'altitude)
  static const String mendozaUcoSvg = 
      'M 445,460 C 515,445 580,465 605,505 C 615,550 580,605 520,615 '
      'C 460,620 425,580 430,530 C 430,490 435,470 445,460 Z';

  /// 2. Vallée Centrale du Chili (Maipo, Colchagua, Casablanca)
  static const String chileCentralSvg = 
      'M 360,450 C 400,440 420,460 425,495 C 430,540 410,590 375,595 '
      'C 345,595 335,560 340,515 C 340,480 350,455 360,450 Z';

  /// 3. Salta & Patagonie (Torrontés de Cafayate, Pinots de Río Negro)
  static const String saltaPatagoniaSvg = 
      'M 450,220 C 510,210 560,225 580,260 C 590,295 565,335 520,340 '
      'C 475,340 445,310 445,275 C 445,245 445,230 450,220 Z';
}
