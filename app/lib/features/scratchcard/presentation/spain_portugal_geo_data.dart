import 'package:flutter/material.dart';

/// High-Definition Geographic and Viticultural Vector Datasets for Spain & Portugal 🇪🇸🇵🇹
/// Standard ViewBox: 1000 x 1000.
class SpainPortugalGeoData {
  static const Rect viewBox = Rect.fromLTWH(0, 0, 1000, 1000);

  // ===========================================================================
  // 1. NATIONAL OUTLINES (Iberian Peninsula & Islands)
  // ===========================================================================
  static const String iberianMainlandSvg = 
      'M 220,110 C 320,80 480,90 620,95 C 730,120 840,160 880,240 '
      'C 910,290 890,360 850,420 C 820,470 790,530 810,600 '
      'C 820,660 780,720 720,770 C 660,820 580,860 500,890 '
      'C 420,910 350,910 280,870 C 230,830 200,770 190,700 '
      'C 180,630 170,550 160,470 C 150,380 140,290 145,210 '
      'C 150,150 170,120 220,110 Z';

  static const String portugalBorderSvg = 
      'M 220,110 C 200,150 180,220 180,300 C 180,380 240,420 235,500 '
      'C 230,590 220,670 240,750 C 250,790 280,840 280,870 ';

  static const String balearicSvg = 
      'M 860,460 C 890,440 930,450 940,480 C 930,510 890,520 860,490 Z ' // Mallorca
      'M 930,420 C 950,410 970,420 965,440 C 950,450 930,440 930,420 Z ' // Menorca
      'M 820,530 C 840,520 855,535 845,550 C 830,560 815,550 820,530 Z';  // Ibiza

  // ===========================================================================
  // 2. HYDROGRAPHY (Duero/Douro, Ebro, Tajo, Guadalquivir)
  // ===========================================================================
  static const String riversSvg = 
      'M 160,330 C 230,325 340,340 460,335 C 560,330 620,320 660,310 ' // Rio Duero / Douro
      'M 850,380 C 780,330 680,260 580,210 C 520,180 480,160 450,150 ' // Rio Ebro
      'M 180,510 C 260,500 370,490 480,480 C 580,475 660,460 710,440 ' // Rio Tajo / Tejo
      'M 240,760 C 310,740 400,720 490,700 C 550,680 600,670 630,650 '; // Rio Guadalquivir

  // ===========================================================================
  // 3. AUTHENTIC SPANISH VITICULTURAL REGIONS (Polygons)
  // ===========================================================================

  /// 1. La Rioja (Rioja Alta, Alavesa, Oriental le long de l'Èbre)
  static const String riojaSvg = 
      'M 470,160 C 520,145 565,160 595,185 C 605,210 575,235 540,240 '
      'C 495,245 460,225 450,195 C 445,175 455,165 470,160 Z';

  /// 2. Ribera del Duero & Toro (Plateau castillan)
  static const String riberaDelDueroSvg = 
      'M 360,280 C 430,270 510,275 560,295 C 570,325 530,355 480,360 '
      'C 420,365 350,350 335,320 C 330,295 345,285 360,280 Z';

  /// 3. Priorat & Catalogne (Licorella, Montsant, Penedès, Cava)
  static const String prioratCatalunyaSvg = 
      'M 720,240 C 780,225 830,245 855,285 C 865,330 830,380 785,395 '
      'C 745,405 710,370 700,325 C 695,280 705,250 720,240 Z';

  /// 4. Galice & Rías Baixas (Albariño, Ribeira Sacra, Valdeorras)
  static const String galiciaRiasBaixasSvg = 
      'M 160,115 C 220,105 260,125 270,165 C 275,205 250,245 205,250 '
      'C 165,250 145,210 145,165 C 145,135 150,120 160,115 Z';

  /// 5. Rueda, Bierzo & Castille (Verdejo, Mencía)
  static const String castillaRuedaSvg = 
      'M 290,230 C 350,220 390,235 410,265 C 415,295 385,325 345,330 '
      'C 305,330 275,305 270,275 C 270,245 280,235 290,230 Z';

  /// 6. Andalousie & Jerez / Xérès (Fino, Manzanilla, PX)
  static const String andaluciaJerezSvg = 
      'M 300,740 C 370,720 460,730 500,775 C 510,820 460,865 400,875 '
      'C 340,880 280,845 270,800 C 265,765 280,745 300,740 Z';

  /// 7. Levant, Valence & Murcie (Jumilla, Monastrell)
  static const String levanteMurciaSvg = 
      'M 630,510 C 690,490 745,515 765,565 C 775,615 740,670 685,685 '
      'C 635,695 595,655 590,605 C 585,555 605,525 630,510 Z';

  // ===========================================================================
  // 4. AUTHENTIC PORTUGUESE VITICULTURAL REGIONS (Polygons)
  // ===========================================================================

  /// 1. Vallée du Douro & Portos (Cima Corgo, Baixo Corgo, Douro Superior)
  static const String douroPortoSvg = 
      'M 180,260 C 225,250 275,260 305,285 C 315,315 285,340 245,345 '
      'C 205,345 175,320 170,290 C 170,270 175,265 180,260 Z';

  /// 2. Alentejo & Terres du Sud (Évora, Borba, Reguengos)
  static const String alentejoSvg = 
      'M 195,540 C 245,520 290,545 305,595 C 315,655 285,720 240,735 '
      'C 195,745 170,700 170,640 C 170,580 180,550 195,540 Z';

  /// 3. Vinho Verde & Région du Minho (Alvarinho, Loureiro)
  static const String vinhoVerdeSvg = 
      'M 155,140 C 195,130 225,145 235,175 C 240,205 220,235 185,240 '
      'C 155,240 145,210 145,175 C 145,150 150,145 155,140 Z';

  /// 4. Dão & Bairrada (Serra da Estrela, Encruzado, Baga)
  static const String daoBairradaSvg = 
      'M 175,360 C 220,350 255,365 265,395 C 270,430 245,465 210,470 '
      'C 175,470 160,435 160,400 C 160,375 165,365 175,360 Z';

  /// 5. Madère & Îles des Açores (Terroirs volcaniques insulaires)
  static const String madeiraAcoresSvg = 
      'M 80,820 C 110,800 140,810 145,835 C 140,855 110,865 85,850 Z ' // Madère
      'M 50,710 C 70,700 85,710 80,725 C 70,735 50,730 50,710 Z';       // Açores (Pico)
}
