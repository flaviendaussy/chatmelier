import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../features/cellar/domain/wine.dart';

class GrapeBlendResolver {
  static List<Grape> resolveGrapes({
    required List<Grape> existingGrapes,
    required String? wineType,
    String? appellation,
    String? region,
    String? wineName,
    String? producer,
    String? cuveeParcel,
  }) {
    // 1. If explicit grapes with valid percentages/names are provided in the wine record
    if (existingGrapes.isNotEmpty) {
      return existingGrapes;
    }

    final name = (wineName ?? '').toLowerCase();
    final prod = (producer ?? '').toLowerCase();
    final cuvee = (cuveeParcel ?? '').toLowerCase();
    final app = (appellation ?? '').toLowerCase();
    final reg = (region ?? '').toLowerCase();
    final type = (wineType ?? '').toLowerCase();

    // 2. SPECIFIC ICONIC ESTATES / DOMAINES

    // Domaine de Terrebrune (Bandol AOC)
    if (prod.contains('terrebrune') || name.contains('terrebrune') || cuvee.contains('terrebrune')) {
      if (type.contains('ros') || type.contains('rose')) {
        return const [
          Grape(name: 'Mourvèdre', pct: 50),
          Grape(name: 'Grenache', pct: 25),
          Grape(name: 'Cinsault', pct: 25),
        ];
      }
      if (type.contains('white') || type.contains('blanc')) {
        return const [
          Grape(name: 'Clairette', pct: 50),
          Grape(name: 'Ugni Blanc', pct: 20),
          Grape(name: 'Bourboulenc', pct: 20),
          Grape(name: 'Marsanne / Rolle', pct: 10),
        ];
      }
      // Terrebrune Rouge (e.g., 2019, 2020, etc.)
      return const [
        Grape(name: 'Mourvèdre', pct: 85),
        Grape(name: 'Grenache Noir', pct: 10),
        Grape(name: 'Cinsault', pct: 5),
      ];
    }

    // Domaine Tempier (Bandol AOC)
    if (prod.contains('tempier') || name.contains('tempier')) {
      if (cuvee.contains('tourtine') || name.contains('tourtine')) {
        return const [
          Grape(name: 'Mourvèdre', pct: 80),
          Grape(name: 'Grenache', pct: 10),
          Grape(name: 'Cinsault', pct: 10),
        ];
      }
      if (cuvee.contains('migoua') || cuvee.contains('miguoua') || name.contains('migoua') || name.contains('miguoua')) {
        return const [
          Grape(name: 'Mourvèdre', pct: 55),
          Grape(name: 'Grenache', pct: 25),
          Grape(name: 'Cinsault', pct: 15),
          Grape(name: 'Syrah', pct: 5),
        ];
      }
      if (cuvee.contains('cabassaou') || name.contains('cabassaou')) {
        return const [
          Grape(name: 'Mourvèdre', pct: 95),
          Grape(name: 'Syrah', pct: 5),
        ];
      }
      if (type.contains('ros') || type.contains('rose')) {
        return const [
          Grape(name: 'Mourvèdre', pct: 50),
          Grape(name: 'Grenache', pct: 28),
          Grape(name: 'Cinsault', pct: 20),
          Grape(name: 'Carignan', pct: 2),
        ];
      }
      if (type.contains('white') || type.contains('blanc')) {
        return const [
          Grape(name: 'Clairette', pct: 60),
          Grape(name: 'Ugni Blanc', pct: 20),
          Grape(name: 'Bourboulenc', pct: 10),
          Grape(name: 'Marsanne', pct: 10),
        ];
      }
      // Domaine Tempier Rouge Classique / Cuvée Spéciale
      return const [
        Grape(name: 'Mourvèdre', pct: 75),
        Grape(name: 'Grenache', pct: 14),
        Grape(name: 'Cinsault', pct: 9),
        Grape(name: 'Carignan', pct: 2),
      ];
    }

    // Château de Pibarnon (Bandol AOC)
    if (prod.contains('pibarnon') || name.contains('pibarnon')) {
      if (type.contains('ros') || type.contains('rose')) {
        return const [
          Grape(name: 'Mourvèdre', pct: 65),
          Grape(name: 'Cinsault', pct: 35),
        ];
      }
      if (type.contains('white') || type.contains('blanc')) {
        return const [
          Grape(name: 'Clairette', pct: 55),
          Grape(name: 'Bourboulenc', pct: 45),
        ];
      }
      return const [
        Grape(name: 'Mourvèdre', pct: 90),
        Grape(name: 'Grenache', pct: 10),
      ];
    }

    // Château Pradeaux / Domaine du Gros' Noré / Domaine de la Bégude / Château Vannières (Bandol)
    if (prod.contains('pradeaux') || prod.contains('gros\' noré') || prod.contains('gros nore') || prod.contains('bégude') || prod.contains('begude') || prod.contains('vannières') || prod.contains('vannieres')) {
      if (type.contains('ros') || type.contains('rose')) {
        return const [
          Grape(name: 'Mourvèdre', pct: 60),
          Grape(name: 'Cinsault', pct: 40),
        ];
      }
      return const [
        Grape(name: 'Mourvèdre', pct: 90),
        Grape(name: 'Grenache', pct: 5),
        Grape(name: 'Cinsault', pct: 5),
      ];
    }

    // 3. BANDOL AOC (General Customary Encépagement)
    if (app.contains('bandol') || name.contains('bandol')) {
      if (type.contains('ros') || type.contains('rose')) {
        return const [
          Grape(name: 'Mourvèdre', pct: 50),
          Grape(name: 'Grenache', pct: 30),
          Grape(name: 'Cinsault', pct: 20),
        ];
      }
      if (type.contains('white') || type.contains('blanc')) {
        return const [
          Grape(name: 'Clairette', pct: 60),
          Grape(name: 'Ugni Blanc', pct: 25),
          Grape(name: 'Bourboulenc', pct: 15),
        ];
      }
      // Bandol Rouge AOC (Legal minimum 50% Mourvèdre, customary 75-85%)
      return const [
        Grape(name: 'Mourvèdre', pct: 75),
        Grape(name: 'Grenache Noir', pct: 15),
        Grape(name: 'Cinsault', pct: 10),
      ];
    }

    // 4. Strict Legal 100% Single-Varietal Appellations (AOC / DOCG)
    // Chablis & White Burgundy (strictly 100% Chardonnay)
    if (app.contains('chablis') ||
        app.contains('meursault') ||
        app.contains('montrachet') ||
        app.contains('corton-charlemagne') ||
        app.contains('mâcon') ||
        app.contains('macon') ||
        app.contains('pouilly-fuissé') ||
        app.contains('pouilly-fuisse') ||
        app.contains('saint-véran') ||
        app.contains('saint-veran') ||
        (reg.contains('bourgogne') && (type.contains('white') || type.contains('blanc')))) {
      if (name.contains('aligoté') || name.contains('aligote') || app.contains('aligoté') || app.contains('aligote')) {
        return const [Grape(name: 'Aligoté', pct: 100)];
      }
      return const [Grape(name: 'Chardonnay', pct: 100)];
    }

    // Red Burgundy (strictly 100% Pinot Noir)
    if ((reg.contains('bourgogne') && (type.contains('red') || type.contains('rouge'))) ||
        app.contains('gevrey') ||
        app.contains('vosne') ||
        app.contains('chambolle') ||
        app.contains('pommard') ||
        app.contains('volnay') ||
        app.contains('nuits-saint-georges') ||
        app.contains('nuits') ||
        app.contains('clos de vougeot') ||
        app.contains('musigny') ||
        app.contains('beaune') ||
        app.contains('corton') ||
        app.contains('morey-saint-denis')) {
      return const [Grape(name: 'Pinot Noir', pct: 100)];
    }

    // Beaujolais (strictly 100% Gamay)
    if (app.contains('beaujolais') ||
        app.contains('morgon') ||
        app.contains('fleurie') ||
        app.contains('brouilly') ||
        app.contains('moulin-à-vent') ||
        app.contains('moulin a vent') ||
        app.contains('juliénas') ||
        app.contains('julienas') ||
        app.contains('chiroubles') ||
        app.contains('régnié') ||
        app.contains('regnie') ||
        app.contains('chénas') ||
        app.contains('chenas') ||
        app.contains('saint-amour')) {
      return const [Grape(name: 'Gamay', pct: 100)];
    }

    // Loire Valley Appellations
    if (app.contains('sancerre') || app.contains('pouilly-fumé') || app.contains('pouilly-fume') || app.contains('menetou-salon')) {
      if (type.contains('red') || type.contains('rouge') || type.contains('ros')) {
        return const [Grape(name: 'Pinot Noir', pct: 100)];
      }
      return const [Grape(name: 'Sauvignon Blanc', pct: 100)];
    }

    if (app.contains('chinon') || app.contains('bourgueil') || app.contains('saumur-champigny') || app.contains('saumur champigny') || app.contains('saint-nicolas-de-bourgueil')) {
      return const [Grape(name: 'Cabernet Franc', pct: 100)];
    }

    if (app.contains('vouvray') || app.contains('montlouis') || app.contains('savennières') || app.contains('savennieres') || app.contains('coteaux du layon') || app.contains('bonnezeaux') || app.contains('quarts de chaume')) {
      return const [Grape(name: 'Chenin Blanc', pct: 100)];
    }

    if (app.contains('muscadet') || app.contains('sèvre et maine') || app.contains('sevre et maine')) {
      return const [Grape(name: 'Melon de Bourgogne', pct: 100)];
    }

    // Northern Rhône (100% Syrah, 100% Viognier, or Syrah/Viognier blend)
    if (app.contains('côte-rôtie') || app.contains('cote-rotie') || app.contains('cote rotie')) {
      return const [
        Grape(name: 'Syrah', pct: 95),
        Grape(name: 'Viognier', pct: 5),
      ];
    }
    if (app.contains('cornas')) {
      return const [Grape(name: 'Syrah', pct: 100)];
    }
    if (app.contains('hermitage') || app.contains('crozes-hermitage') || app.contains('crozes hermitage') || app.contains('saint-joseph') || app.contains('saint joseph')) {
      if (type.contains('white') || type.contains('blanc')) {
        return const [
          Grape(name: 'Marsanne', pct: 70),
          Grape(name: 'Roussanne', pct: 30),
        ];
      }
      return const [Grape(name: 'Syrah', pct: 100)];
    }
    if (app.contains('condrieu') || app.contains('château-grillet') || app.contains('chateau grillet')) {
      return const [Grape(name: 'Viognier', pct: 100)];
    }

    // Southern Rhône (Châteauneuf-du-Pape, Gigondas, Vacqueyras, etc.)
    if (app.contains('châteauneuf') || app.contains('chateauneuf')) {
      if (type.contains('white') || type.contains('blanc')) {
        return const [
          Grape(name: 'Roussanne', pct: 40),
          Grape(name: 'Grenache Blanc', pct: 30),
          Grape(name: 'Clairette', pct: 20),
          Grape(name: 'Bourboulenc', pct: 10),
        ];
      }
      return const [
        Grape(name: 'Grenache Noir', pct: 70),
        Grape(name: 'Syrah', pct: 15),
        Grape(name: 'Mourvèdre', pct: 10),
        Grape(name: 'Cinsault', pct: 5),
      ];
    }
    if (app.contains('gigondas') || app.contains('vacqueyras') || app.contains('cairanne') || app.contains('beaumes de venise') || app.contains('lirac')) {
      return const [
        Grape(name: 'Grenache Noir', pct: 70),
        Grape(name: 'Syrah', pct: 20),
        Grape(name: 'Mourvèdre', pct: 10),
      ];
    }
    if (app.contains('tavel')) {
      return const [
        Grape(name: 'Grenache', pct: 50),
        Grape(name: 'Cinsault', pct: 30),
        Grape(name: 'Clairette', pct: 10),
        Grape(name: 'Syrah', pct: 10),
      ];
    }

    // Sud-Ouest (Cahors, Madiran, Jurançon)
    if (app.contains('cahors')) {
      return const [
        Grape(name: 'Malbec (Cot)', pct: 85),
        Grape(name: 'Merlot', pct: 10),
        Grape(name: 'Tannat', pct: 5),
      ];
    }
    if (app.contains('madiran')) {
      return const [
        Grape(name: 'Tannat', pct: 70),
        Grape(name: 'Cabernet Franc', pct: 20),
        Grape(name: 'Cabernet Sauvignon', pct: 10),
      ];
    }
    if (app.contains('jurançon') || app.contains('jurancon')) {
      return const [
        Grape(name: 'Gros Manseng', pct: 60),
        Grape(name: 'Petit Manseng', pct: 40),
      ];
    }

    // Alsace Single-Varietal AOC
    if (reg.contains('alsace')) {
      if (name.contains('riesling') || app.contains('riesling')) {
        return const [Grape(name: 'Riesling', pct: 100)];
      }
      if (name.contains('gewurztraminer') || app.contains('gewurztraminer')) {
        return const [Grape(name: 'Gewurztraminer', pct: 100)];
      }
      if (name.contains('pinot gris') || app.contains('pinot gris')) {
        return const [Grape(name: 'Pinot Gris', pct: 100)];
      }
      if (name.contains('pinot noir') || app.contains('pinot noir')) {
        return const [Grape(name: 'Pinot Noir', pct: 100)];
      }
      if (name.contains('muscat') || app.contains('muscat')) {
        return const [Grape(name: 'Muscat d\'Alsace', pct: 100)];
      }
      if (name.contains('pinot blanc') || app.contains('pinot blanc') || name.contains('klevner')) {
        return const [Grape(name: 'Pinot Blanc', pct: 100)];
      }
      if (name.contains('sylvaner') || app.contains('sylvaner')) {
        return const [Grape(name: 'Sylvaner', pct: 100)];
      }
    }

    // Bordeaux Blends
    if (app.contains('margaux') ||
        app.contains('pauillac') ||
        app.contains('saint-julien') ||
        app.contains('saint-esteph') ||
        app.contains('saint-estèphe') ||
        app.contains('pessac-léognan') ||
        app.contains('pessac-leognan') ||
        app.contains('graves') ||
        app.contains('haut-médoc') ||
        app.contains('haut-medoc') ||
        app.contains('médoc') ||
        app.contains('medoc')) {
      if (type.contains('white') || type.contains('blanc')) {
        return const [
          Grape(name: 'Sauvignon Blanc', pct: 65),
          Grape(name: 'Sémillon', pct: 30),
          Grape(name: 'Muscadelle', pct: 5),
        ];
      }
      return const [
        Grape(name: 'Cabernet Sauvignon', pct: 65),
        Grape(name: 'Merlot', pct: 28),
        Grape(name: 'Cabernet Franc', pct: 5),
        Grape(name: 'Petit Verdot', pct: 2),
      ];
    }

    if (app.contains('saint-émilion') || app.contains('saint-emilion') || app.contains('pomerol') || app.contains('fronsac')) {
      return const [
        Grape(name: 'Merlot', pct: 75),
        Grape(name: 'Cabernet Franc', pct: 20),
        Grape(name: 'Cabernet Sauvignon', pct: 5),
      ];
    }

    if (app.contains('sauternes') || app.contains('barsac') || app.contains('monbazillac')) {
      return const [
        Grape(name: 'Sémillon', pct: 80),
        Grape(name: 'Sauvignon Blanc', pct: 15),
        Grape(name: 'Muscadelle', pct: 5),
      ];
    }

    // Champagne
    if (app.contains('champagne')) {
      if (name.contains('blanc de blancs') || cuvee.contains('blanc de blancs')) {
        return const [Grape(name: 'Chardonnay', pct: 100)];
      }
      if (name.contains('blanc de noirs') || cuvee.contains('blanc de noirs')) {
        return const [
          Grape(name: 'Pinot Noir', pct: 70),
          Grape(name: 'Pinot Meunier', pct: 30),
        ];
      }
      return const [
        Grape(name: 'Pinot Noir', pct: 40),
        Grape(name: 'Chardonnay', pct: 35),
        Grape(name: 'Pinot Meunier', pct: 25),
      ];
    }

    // Provence (General)
    if (reg.contains('provence') || app.contains('côtes de provence') || app.contains('cotes de provence') || app.contains('coteaux d\'aix')) {
      if (type.contains('white') || type.contains('blanc')) {
        return const [
          Grape(name: 'Rolle (Vermentino)', pct: 60),
          Grape(name: 'Clairette', pct: 25),
          Grape(name: 'Ugni Blanc', pct: 15),
        ];
      }
      return const [
        Grape(name: 'Grenache', pct: 45),
        Grape(name: 'Cinsault', pct: 30),
        Grape(name: 'Syrah', pct: 15),
        Grape(name: 'Mourvèdre', pct: 10),
      ];
    }

    // Italy Single-Varietals & Classics
    if (app.contains('barolo') || app.contains('barbaresco') || app.contains('nebbiolo')) {
      return const [Grape(name: 'Nebbiolo', pct: 100)];
    }
    if (app.contains('brunello di montalcino') || app.contains('rosso di montalcino')) {
      return const [Grape(name: 'Sangiovese Grosso', pct: 100)];
    }
    if (app.contains('chianti')) {
      return const [
        Grape(name: 'Sangiovese', pct: 85),
        Grape(name: 'Canaiolo', pct: 10),
        Grape(name: 'Colorino', pct: 5),
      ];
    }
    if (app.contains('amarone') || app.contains('valpolicella')) {
      return const [
        Grape(name: 'Corvina', pct: 65),
        Grape(name: 'Rondinella', pct: 25),
        Grape(name: 'Molinara', pct: 10),
      ];
    }

    // Spain Classics
    if (app.contains('rioja')) {
      return const [
        Grape(name: 'Tempranillo', pct: 80),
        Grape(name: 'Garnacha', pct: 10),
        Grape(name: 'Graciano', pct: 5),
        Grape(name: 'Mazuelo', pct: 5),
      ];
    }
    if (app.contains('ribera del duero')) {
      return const [
        Grape(name: 'Tempranillo (Tinto Fino)', pct: 90),
        Grape(name: 'Cabernet Sauvignon', pct: 10),
      ];
    }

    return const [];
  }
}

class GrapeChart extends StatefulWidget {
  final List<Grape> grapes;
  final Wine? wine;

  const GrapeChart({
    super.key,
    required this.grapes,
    this.wine,
  });

  @override
  State<GrapeChart> createState() => _GrapeChartState();
}

class _GrapeChartState extends State<GrapeChart> {
  int _touchedIndex = -1;

  static const List<Color> _palette = [
    Color(0xFF722F37), // Bordeaux Wine
    Color(0xFF4A154B), // Royal Pinot Noir
    Color(0xFFD4AF37), // Gold Chardonnay
    Color(0xFF2E7D32), // Emerald Sauvignon
    Color(0xFFE57373), // Coral Rosé
    Color(0xFF3F51B5), // Deep Indigo Syrah
    Color(0xFF00796B), // Deep Teal Merlot
    Color(0xFFE65100), // Amber Grenache
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedGrapes = GrapeBlendResolver.resolveGrapes(
      existingGrapes: widget.grapes,
      wineType: widget.wine?.type,
      appellation: widget.wine?.appellation,
      region: widget.wine?.region,
      wineName: widget.wine?.name,
      producer: widget.wine?.producer,
      cuveeParcel: widget.wine?.cuveeParcel,
    );

    if (resolvedGrapes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cépages non renseignés pour cette cuvée.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasExactPercentages = resolvedGrapes.every((g) => g.pct != null && g.pct! > 0);

    // If exact percentages are known (either provided or 100% legal single-varietal AOC)
    if (hasExactPercentages) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Donut Pie Chart with FL Chart
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2.5,
                        centerSpaceRadius: 34,
                        sections: resolvedGrapes.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final grape = entry.value;
                          final isTouched = idx == _touchedIndex;
                          final radius = isTouched ? 32.0 : 26.0;
                          final pct = grape.pct!;

                          return PieChartSectionData(
                            color: _palette[idx % _palette.length],
                            value: pct,
                            title: pct >= 15 ? '${pct.round()}%' : '',
                            radius: radius,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 3),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Center Donut text badge
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pie_chart, size: 14, color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F)),
                        Text(
                          '${resolvedGrapes.length} cépage${resolvedGrapes.length > 1 ? "s" : ""}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Grape Legend with certified percentage pills
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: resolvedGrapes.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final grape = entry.value;
                    final pct = grape.pct!;
                    final color = _palette[idx % _palette.length];
                    final isSelected = idx == _touchedIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withAlpha(50)
                              : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                grape.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${pct.round()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // If grapes are known but exact proportions are not specified by the winery:
    // Truthful presentation as authorized blend grapes without made-up percentages.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resolvedGrapes.asMap().entries.map((entry) {
            final idx = entry.key;
            final grape = entry.value;
            final color = _palette[idx % _palette.length];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    grape.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Cépages typiques de l\'appellation (proportions exactes non renseignées par le domaine).',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
