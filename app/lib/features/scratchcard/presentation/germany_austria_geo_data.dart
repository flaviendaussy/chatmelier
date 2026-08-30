import 'package:flutter/material.dart';

/// High-Definition Geographic and Viticultural Vector Datasets for Germany & Austria 🇩🇪🇦🇹
/// Standard ViewBox: 1000 x 1000.
class GermanyAustriaGeoData {
  static const Rect viewBox = Rect.fromLTWH(0, 0, 1000, 1000);

  // ===========================================================================
  // 1. NATIONAL OUTLINES (Germany & Austria)
  // ===========================================================================
  static const String centralEuropeMainlandSvg = 
      'M 280,60 C 350,40 450,50 540,65 C 600,100 660,160 670,240 '
      'C 675,320 620,380 610,440 C 660,470 760,490 840,520 '
      'C 910,560 930,620 890,670 C 830,710 740,730 650,710 '
      'C 570,690 490,720 420,740 C 360,750 320,700 290,650 '
      'C 260,590 240,510 225,430 C 210,340 215,250 220,180 '
      'C 225,110 240,80 280,60 Z';

  // ===========================================================================
  // 2. HYDROGRAPHY (Rhein, Mosel, Donau/Danube)
  // ===========================================================================
  static const String riversSvg = 
      'M 250,650 C 255,540 270,440 285,350 C 295,270 280,180 260,120 ' // Rhein
      'M 220,360 C 240,350 265,360 285,350 '                             // Mosel
      'M 480,560 C 580,550 700,560 820,580 C 880,590 920,600 950,610 '; // Donau (Danube)

  // ===========================================================================
  // 3. AUTHENTIC GERMAN & AUSTRIAN VITICULTURAL REGIONS (Polygons)
  // ===========================================================================

  /// 1. Moselle / Mosel (Saar, Ruwer, Piesport, Wehlener Sonnenuhr)
  static const String moselSvg = 
      'M 220,320 C 260,310 285,330 295,360 C 300,390 275,415 240,420 '
      'C 210,420 195,390 200,360 C 205,335 210,325 220,320 Z';

  /// 2. Rheingau & Palatinat (Pfalz, Johannisberg, Grosses Gewächs)
  static const String rheingauPfalzSvg = 
      'M 285,340 C 335,330 375,350 385,385 C 390,420 365,460 325,465 '
      'C 285,465 265,430 270,390 C 275,360 280,345 285,340 Z';

  /// 3. Bade (Baden) & Franconie (Kaiserstuhl, Silvaner, Spätburgunder)
  static const String badenFrankenSvg = 
      'M 270,490 C 330,470 410,480 440,530 C 455,590 415,650 355,660 '
      'C 295,665 260,620 255,560 C 250,520 260,495 270,490 Z';

  /// 4. Wachau & Kremstal (Terrasses du Danube, Grüner Veltliner, Smaragd)
  static const String wachauKremstalSvg = 
      'M 680,520 C 740,510 795,525 815,555 C 825,585 795,615 750,620 '
      'C 700,620 665,590 660,560 C 660,535 670,525 680,520 Z';

  /// 5. Burgenland & Terres Pannoniennes (Blaufränkisch, Neusiedlersee, TBA)
  static const String burgenlandSvg = 
      'M 800,580 C 850,565 895,585 910,630 C 920,680 885,730 835,740 '
      'C 785,745 760,705 765,655 C 770,615 785,590 800,580 Z';
}
