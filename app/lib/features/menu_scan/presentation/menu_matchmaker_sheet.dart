import 'package:flutter/material.dart';
import '../domain/menu_wine.dart';

class MenuMatchmakerSheet extends StatefulWidget {
  final List<MenuWine> allWines;

  const MenuMatchmakerSheet({super.key, required this.allWines});

  static Future<void> show(BuildContext context, List<MenuWine> wines) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuMatchmakerSheet(allWines: wines),
    );
  }

  @override
  State<MenuMatchmakerSheet> createState() => _MenuMatchmakerSheetState();
}

class _MatchmakerQuestion {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<MenuWine> Function(List<MenuWine> pool, bool answerYes) filter;
  final String userPreferenceLabel;

  const _MatchmakerQuestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.filter,
    required this.userPreferenceLabel,
  });
}

class _MenuMatchmakerSheetState extends State<MenuMatchmakerSheet> {
  late List<MenuWine> _currentPool;
  int _currentQuestionIndex = 0;
  final List<String> _recordedChoices = [];
  bool _isFinished = false;

  // Swipe offset for interactive card dragging
  double _dragOffset = 0.0;

  late final List<_MatchmakerQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _currentPool = List<MenuWine>.from(widget.allWines);
    _buildQuestions();
  }

  void _buildQuestions() {
    _questions = [
      // Q1: Rouge ou autre ?
      _MatchmakerQuestion(
        title: 'Envie de vin Rouge ce soir ?',
        subtitle: 'Pour accompagner viandes, charcuteries ou plats généreux.',
        icon: Icons.wine_bar,
        iconColor: const Color(0xFF8B1E3F),
        userPreferenceLabel: 'Vin Rouge',
        filter: (pool, answerYes) {
          final filtered = answerYes ? pool.where((w) => w.isRed).toList() : pool.where((w) => !w.isRed).toList();
          return filtered.isNotEmpty ? filtered : pool;
        },
      ),

      // Q2: Bulles ou Blanc ?
      _MatchmakerQuestion(
        title: 'Plutôt Bulles festives / Champagne ?',
        subtitle: 'Pour l\'apéritif, les célébrations ou la fraîcheur pétillante.',
        icon: Icons.celebration,
        iconColor: const Color(0xFFD4AF37),
        userPreferenceLabel: 'Bulles / Champagne',
        filter: (pool, answerYes) {
          final filtered =
              answerYes ? pool.where((w) => w.isSparkling).toList() : pool.where((w) => !w.isSparkling).toList();
          return filtered.isNotEmpty ? filtered : pool;
        },
      ),

      // Q3: Minéralité & Tension
      _MatchmakerQuestion(
        title: 'Recherche de Minéralité & Vivacité ?',
        subtitle: 'Vins tendus, ciselés, salins (ex: Chablis, Sancerre, Riesling sec).',
        icon: Icons.landscape,
        iconColor: const Color(0xFF00897B),
        userPreferenceLabel: 'Minéral & Vif',
        filter: (pool, answerYes) {
          final filtered = answerYes
              ? pool
                  .where((w) =>
                      w.metrics.minerality >= 5.5 ||
                      w.tags.contains('minéral') ||
                      w.metrics.acidity >= 6.0)
                  .toList()
              : pool
                  .where((w) =>
                      w.metrics.minerality < 6.5 &&
                      !w.tags.contains('minéral'))
                  .toList();
          return filtered.isNotEmpty ? filtered : pool;
        },
      ),

      // Q4: Tannique & Puissant
      _MatchmakerQuestion(
        title: 'Amateur de Tannins & Structure ?',
        subtitle: 'Vins charpentés, corsés, matière dense (ex: Bordeaux, Cahors, Syrah).',
        icon: Icons.fitness_center,
        iconColor: const Color(0xFF5D4037),
        userPreferenceLabel: 'Tannique & Structuré',
        filter: (pool, answerYes) {
          final filtered = answerYes
              ? pool
                  .where((w) =>
                      w.metrics.tannins >= 5.5 ||
                      w.tags.contains('tannique') ||
                      w.metrics.body >= 6.0)
                  .toList()
              : pool
                  .where((w) =>
                      w.metrics.tannins < 5.5 ||
                      w.tags.contains('léger') ||
                      w.tags.contains('fruité'))
                  .toList();
          return filtered.isNotEmpty ? filtered : pool;
        },
      ),

      // Q5: Beurré & Rondeur
      _MatchmakerQuestion(
        title: 'Caractère Beurré, Brioché & Gourmand ?',
        subtitle: 'Vins opulents avec élevage soigné (ex: Meursault, grands Chardonnay, viognier).',
        icon: Icons.bakery_dining,
        iconColor: const Color(0xFFF57F17),
        userPreferenceLabel: 'Beurré & Rond',
        filter: (pool, answerYes) {
          final filtered = answerYes
              ? pool
                  .where((w) =>
                      w.metrics.butteriness >= 4.5 ||
                      w.tags.contains('beurré') ||
                      w.tags.contains('rond'))
                  .toList()
              : pool
                  .where((w) =>
                      w.metrics.butteriness < 5.0 &&
                      !w.tags.contains('beurré'))
                  .toList();
          return filtered.isNotEmpty ? filtered : pool;
        },
      ),

      // Q6: Budget sage
      _MatchmakerQuestion(
        title: 'Budget Bouteille maîtrisé (< 45 €) ?',
        subtitle: 'Pour dénicher les pépites au meilleur rapport plaisir/prix.',
        icon: Icons.savings_outlined,
        iconColor: const Color(0xFF2E7D32),
        userPreferenceLabel: 'Budget < 45€',
        filter: (pool, answerYes) {
          if (answerYes) {
            final filtered = pool
                .where((w) =>
                    (w.bottlePrice != null && w.bottlePrice! <= 45.0) ||
                    (w.primaryGlassPrice != null && w.primaryGlassPrice! <= 9.0))
                .toList();
            return filtered.isNotEmpty ? filtered : pool;
          }
          return pool;
        },
      ),
    ];
  }

  void _answer(bool answerYes) {
    if (_isFinished) return;

    final currentQ = _questions[_currentQuestionIndex];
    final nextPool = currentQ.filter(_currentPool, answerYes);

    if (answerYes) {
      _recordedChoices.add(currentQ.userPreferenceLabel);
    }

    setState(() {
      _dragOffset = 0.0;
      _currentPool = nextPool;
      _currentQuestionIndex++;

      // Check if finished: down to <= 2 wines or exhausted questions
      if (_currentPool.length <= 2 || _currentQuestionIndex >= _questions.length) {
        _isFinished = true;
      }
    });
  }

  void _reset() {
    setState(() {
      _currentPool = List<MenuWine>.from(widget.allWines);
      _currentQuestionIndex = 0;
      _recordedChoices.clear();
      _isFinished = false;
      _dragOffset = 0.0;
    });
  }

  String _buildJustification(MenuWine wine) {
    final reasons = <String>[];
    if (wine.isRed && _recordedChoices.contains('Vin Rouge')) {
      reasons.add('parfaitement dans votre registre de vin rouge');
    }
    if (wine.tags.contains('minéral') || _recordedChoices.contains('Minéral & Vif')) {
      reasons.add('avec cette belle trame minérale et vive recherchée');
    }
    if (wine.tags.contains('beurré') || _recordedChoices.contains('Beurré & Rond')) {
      reasons.add('offrant des arômes beurrés et une gourmandise soyeuse');
    }
    if (wine.tags.contains('tannique') || _recordedChoices.contains('Tannique & Structuré')) {
      reasons.add('doté de tanins nobles et d\'une charpente équilibrée');
    }
    if (wine.bottlePrice != null && wine.bottlePrice! <= 45.0) {
      reasons.add('pour un tarif très sage de ${wine.bottlePrice!.toStringAsFixed(0)} €');
    }

    if (reasons.isEmpty) {
      return 'Ce cru se distingue sur cette carte par son équilibre exemplaire et son profil aromatique très harmonieux.';
    }
    return 'Pourquoi ce choix : ${reasons.join(', ')}.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.style_outlined, color: Color(0xFF8B1E3F), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Le Sommelier Matchmaker',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        _isFinished
                            ? '🎉 Vos meilleures bouteilles trouvées !'
                            : 'Swiper pour trouver votre vin idéal en 4 questions',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body: Card Swiper or Winning Podium
          Expanded(
            child: _isFinished ? _buildPodiumView(theme, isDark) : _buildSwiperView(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSwiperView(ThemeData theme, bool isDark) {
    final q = _questions[_currentQuestionIndex];
    final remainingCount = _currentPool.length;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Remaining Badge Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 16, color: Color(0xFFD4AF37)),
                const SizedBox(width: 6),
                Text(
                  '$remainingCount vins en lice sur la carte',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD4AF37)),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Interactive Swipeable Card with gesture detector
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() => _dragOffset += details.delta.dx);
            },
            onHorizontalDragEnd: (details) {
              if (_dragOffset > 70) {
                _answer(true);
              } else if (_dragOffset < -70) {
                _answer(false);
              } else {
                setState(() => _dragOffset = 0.0);
              }
            },
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Transform.rotate(
                angle: _dragOffset * 0.0012,
                child: Container(
                  width: double.infinity,
                  height: 310,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF251F2E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: _dragOffset > 30
                          ? Colors.green.shade400
                          : (_dragOffset < -30 ? Colors.red.shade400 : Colors.grey.withValues(alpha: 0.2)),
                      width: 2.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Swipe Overlay Indicators
                      if (_dragOffset > 30)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('OUI ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      else if (_dragOffset < -30)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('NON ❌', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      else
                        const SizedBox(height: 24),

                      const SizedBox(height: 12),

                      // Question Icon
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: q.iconColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(q.icon, size: 48, color: q.iconColor),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        q.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        q.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Swipe Instructions and Quick Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // NO Button
              SizedBox(
                width: 140,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _answer(false),
                  icon: const Icon(Icons.close),
                  label: const Text('NON', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              // YES Button
              SizedBox(
                width: 140,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _answer(true),
                  icon: const Icon(Icons.check),
                  label: const Text('OUI', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text(
            'Glissez vers la gauche pour NON • Glissez vers la droite pour OUI',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumView(ThemeData theme, bool isDark) {
    final winners = _currentPool.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Winner Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.25),
                  const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vos ${winners.length} Vins Idéaux',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Sélectionnés sur-mesure parmi la carte du restaurant.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Winners Cards with Sommelier Justification
          ...winners.map((wine) {
            final justification = _buildJustification(wine);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF251F2E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: wine.colorIndicator.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Wine Info & Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: wine.colorIndicator.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.wine_bar, color: wine.colorIndicator, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wine.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${wine.producer} • ${wine.vintage ?? "NM"} • ${wine.appellation ?? wine.region ?? ""}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            wine.priceDisplay,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (wine.userMatchScore != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${wine.userMatchScore!.round()}% Match',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Sommelier Justification Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.amber.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            justification,
                            style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Restart Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Recommencer le Matchmaker'),
          ),
        ],
      ),
    );
  }
}
