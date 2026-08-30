import 'package:flutter/material.dart';

/// High-Definition Geographic and Viticultural Vector Datasets for Italy 🇮🇹
/// Standard ViewBox: 1000 x 1000.
class ItalyGeoData {
  static const Rect viewBox = Rect.fromLTWH(0, 0, 1000, 1000);

  // ===========================================================================
  // 1. NATIONAL OUTLINES (Mainland Boot, Sicily & Sardinia)
  // ===========================================================================
  static const String italyMainlandSvg = 
      'M 180,160 C 220,130 290,120 380,135 C 430,120 520,110 590,140 '
      'C 630,160 650,200 620,230 C 580,250 520,240 480,260 '
      'C 490,290 530,330 580,380 C 620,430 670,490 710,540 '
      'C 750,580 810,610 860,630 C 890,650 910,680 880,710 '
      'C 850,730 810,710 780,690 C 760,710 770,750 740,770 '
      'C 700,770 680,730 660,700 C 630,680 610,710 590,750 '
      'C 570,790 580,850 550,880 C 520,890 510,840 500,800 '
      'C 470,760 480,720 460,680 C 440,640 430,590 410,550 '
      'C 370,490 340,430 330,370 C 310,340 280,330 250,330 '
      'C 210,320 180,290 170,250 C 160,210 160,180 180,160 Z';

  static const String sicilySvg = 
      'M 420,860 C 480,840 540,845 580,865 C 600,880 620,910 590,930 '
      'C 550,950 490,960 440,940 C 400,920 380,880 420,860 Z';

  static const String sardiniaSvg = 
      'M 130,480 C 170,470 190,490 195,530 C 200,580 190,640 180,680 '
      'C 160,710 130,710 120,670 C 110,620 115,540 130,480 Z';

  // ===========================================================================
  // 2. HYDROGRAPHY (Po River basin, Arno & Adige)
  // ===========================================================================
  static const String riversSvg = 
      'M 200,240 C 280,250 360,245 440,255 C 500,260 560,250 610,240 ' // Fiume Po
      'M 340,340 C 370,335 410,338 450,345 '                             // Fiume Arno (Toscana)
      'M 460,140 C 470,180 480,210 490,250 ';                            // Fiume Adige

  // ===========================================================================
  // 3. AUTHENTIC ITALIAN VITICULTURAL REGIONS (Polygons)
  // ===========================================================================
  
  /// 1. Piémont (Langhe, Barolo, Barbaresco, Roero, Monferrato)
  static const String piemonteSvg = 
      'M 200,190 C 240,180 270,195 285,220 C 295,245 280,275 265,295 '
      'C 240,310 210,310 195,285 C 180,260 185,220 200,190 Z';

  /// 2. Toscane (Chianti Classico, Montalcino, Montepulciano, Bolgheri)
  static const String toscanaSvg = 
      'M 335,330 C 375,320 420,335 440,365 C 450,400 435,440 405,465 '
      'C 375,475 345,450 330,420 C 320,380 320,350 335,330 Z';

  /// 3. Vénétie (Valpolicella, Amarone, Soave, Prosecco Valdobbiadene)
  static const String venetoSvg = 
      'M 420,180 C 470,175 520,185 550,210 C 560,235 540,260 500,265 '
      'C 460,265 430,245 415,220 C 410,200 415,190 420,180 Z';

  /// 4. Trentin-Haut-Adige & Frioul (Vins alpins, Collio)
  static const String trentinoAltoAdigeSvg = 
      'M 430,130 C 480,125 540,125 590,145 C 610,165 590,190 555,195 '
      'C 515,195 470,180 440,170 C 420,160 425,140 430,130 Z';

  /// 5. Émilie-Romagne, Marches & Abruzzes
  static const String emiliaAbruzzoSvg = 
      'M 350,265 C 440,260 520,270 565,310 C 600,350 635,420 620,470 '
      'C 590,460 550,400 490,360 C 420,315 360,290 350,265 Z';

  /// 6. Pouilles & Campanie (Taurasi, Primitivo di Manduria, Aglianico)
  static const String pugliaCampaniaSvg = 
      'M 540,490 C 600,470 670,510 740,560 C 810,610 860,640 840,680 '
      'C 800,700 730,670 670,620 C 610,580 550,560 520,530 C 520,505 530,495 540,490 Z';

  /// 7. Sicile & Terroirs de l'Etna (Nerello Mascalese, Nero d'Avola)
  static const String siciliaEtnaSvg = 
      'M 440,865 C 500,855 560,865 580,885 C 590,910 565,940 525,945 '
      'C 475,945 435,925 425,895 C 425,875 435,870 440,865 Z';
}
