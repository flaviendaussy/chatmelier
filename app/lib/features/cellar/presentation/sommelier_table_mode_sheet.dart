import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../domain/bottle.dart';
import '../domain/wine_service_advisor.dart';
import '../../offline/domain/offline_action.dart';
import '../../offline/presentation/sync_provider.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../journal/domain/tasting_pedagogy_engine.dart';
import '../../journal/presentation/tasting_pedagogy_sheet.dart';

class SommelierTableModeSheet extends ConsumerStatefulWidget {
  final Bottle bottle;

  const SommelierTableModeSheet({super.key, required this.bottle});

  static Future<void> show(BuildContext context, {required Bottle bottle}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SommelierTableModeSheet(bottle: bottle),
    );
  }

  @override
  ConsumerState<SommelierTableModeSheet> createState() => _SommelierTableModeSheetState();
}

class _SommelierTableModeSheetState extends ConsumerState<SommelierTableModeSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Timer State
  Timer? _timer;
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;

  // Guided Tasting State
  String? _selectedAppearance;
  final Set<String> _selectedAromas = {};
  String? _selectedStructure;
  int _caudalies = 6;
  double _userRating = 8.5;
  final _commentController = TextEditingController();
  bool _isSaving = false;

  final List<String> _appearanceOptions = [
    'Rubis brillant', 'Grenat profond', 'Pourpre intense', 'Tuilé / Évolué',
    'Doré éclatant', 'Or pâle', 'Paille', 'Robe ambrée', 'Rosé saumoné'
  ];

  final List<String> _aromaOptions = [
    '🍒 Fruits rouges', '🫐 Fruits noirs', '🪵 Boisé / Chêne', '🌲 Sous-bois / Humus',
    '🪨 Minéral / Craie', '🌸 Floral / Violette', '🌿 Végétal noble', '☕ Cacao / Torréfaction',
    '🍯 Miel / Cire', '🧈 Beurre / Brioche', '🌶️ Poivre / Épices', '🍋 Agrumes / Zeste'
  ];

  final List<String> _structureOptions = [
    'Tanins soyeux et fondus', 'Tanins fermes et structurés', 'Grande rondeur et gras',
    'Vivacité et fraîcheur saline', 'Équilibre parfait', 'Légèreté et fluidité'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final wine = widget.bottle.wine;
    if (wine != null) {
      final advice = WineServiceAdvisor.computeAdvice(
        wineType: wine.type,
        vintage: wine.vintage,
        region: wine.region,
        appellation: wine.appellation,
        producer: wine.producer,
        wineName: wine.name,
      );
      if (advice.carafeMinutes > 0) {
        _totalSeconds = advice.carafeMinutes * 60;
      } else {
        _totalSeconds = 20 * 60; // default 20 min chilling
      }
      _remainingSeconds = _totalSeconds;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.selectionClick();
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          setState(() => _isTimerRunning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔔 Le vin est parfaitement aéré et prêt pour la dégustation !'),
              backgroundColor: Color(0xFFD4AF37),
            ),
          );
        }
      });
    }
  }

  void _resetTimer() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isTimerRunning = false;
    });
  }

  Future<void> _saveTastingNote() async {
    final wine = widget.bottle.wine;
    if (wine == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;

      final notesSummary = StringBuffer();
      if (_selectedAppearance != null) {
        notesSummary.writeln('Robe : $_selectedAppearance');
      }
      if (_selectedAromas.isNotEmpty) {
        notesSummary.writeln('Nez : ${_selectedAromas.join(', ')}');
      }
      if (_selectedStructure != null) {
        notesSummary.writeln('Bouche : $_selectedStructure (Longueur : $_caudalies caudalies)');
      }
      if (_commentController.text.trim().isNotEmpty) {
        notesSummary.writeln('Impression : ${_commentController.text.trim()}');
      }

      if (userId != null) {
        try {
          await supabase.from('tasting_log').insert({
            'wine_id': wine.id,
            'bottle_id': widget.bottle.id,
            'user_id': userId,
            'rating': _userRating,
            'tasting_notes': notesSummary.toString(),
            'occasion': 'Dégustation Sommelier à Table',
            'consumed_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }

      // Record offline action so Journal and Stats update immediately
      final offlineStorage = ref.read(offlineStorageServiceProvider);
      await offlineStorage.queueAction(OfflineAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: OfflineActionType.consumeBottle,
        data: {
          'bottle_id': widget.bottle.id,
          'wine_id': wine.id,
          'wine_name': wine.name,
          'vintage': wine.vintage,
          'region': wine.region,
          'country': wine.country,
          'appellation': wine.appellation,
          'rating': _userRating,
          'tasting_notes': notesSummary.toString(),
          'occasion': 'Dégustation Sommelier à Table',
          'quantity': 0,
        },
        createdAt: DateTime.now(),
      ));

      ref.invalidate(tastingLogProvider);

      final report = TastingPedagogyEngine.analyze(
        wine: wine,
        userAppearance: _selectedAppearance,
        userAromas: _selectedAromas.toList(),
        userStructure: _selectedStructure,
        userCaudalies: _caudalies,
        userRating: _userRating,
        userComment: _commentController.text.trim(),
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Fiche de dégustation enregistrée dans votre Journal !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        // Display educational debriefing sheet immediately
        TastingPedagogySheet.show(context, report: report);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final sec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wine = widget.bottle.wine;
    final advice = wine != null
        ? WineServiceAdvisor.computeAdvice(
            wineType: wine.type,
            vintage: wine.vintage,
            region: wine.region,
            appellation: wine.appellation,
            producer: wine.producer,
            wineName: wine.name,
          )
        : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1718) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF722F37).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🕯️', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sommelier à Table',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Playfair Display',
                        ),
                      ),
                      Text(
                        wine != null ? '${wine.name} (${wine.vintage ?? 'N.V.'})' : 'Service du vin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFD4AF37),
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            tabs: const [
              Tab(icon: Icon(Icons.timer_outlined, size: 18), text: 'Minuteur & Aération'),
              Tab(icon: Icon(Icons.rate_review_outlined, size: 18), text: 'Dégustation Guidée'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Minuteur & Préparation
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Circular Timer Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: CircularProgressIndicator(
                              value: _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds) : 0,
                              strokeWidth: 8,
                              backgroundColor: isDark ? Colors.white12 : Colors.black12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(_remainingSeconds),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                _isTimerRunning ? 'En cours d\'aération' : 'En attente',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Timer Action Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.replay),
                            onPressed: _resetTimer,
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF722F37),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                            label: Text(_isTimerRunning ? 'Pause' : 'Démarrer Minuteur'),
                            onPressed: _toggleTimer,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sommelier Guidelines Card
                      if (advice != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262022) : const Color(0xFFFAF7F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('🍷', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Conseils de Service Idéal',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD4AF37),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildAdviceBullet(Icons.thermostat, 'Température : ${advice.tempLabel}'),
                              _buildAdviceBullet(Icons.air, advice.decantingAdvice),
                              _buildAdviceBullet(Icons.wine_bar, 'Verre conseillé : ${advice.glasswareType}'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // TAB 2: Fiche Express de Dégustation en 3 Étapes
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. L'ŒIL
                      _buildSectionTitle('1. 👁️ L\'Œil (Robe & Reflets)'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _appearanceOptions.map((opt) {
                          final isSelected = _selectedAppearance == opt;
                          return ChoiceChip(
                            label: Text(opt, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedAppearance = selected ? opt : null);
                            },
                            selectedColor: const Color(0xFF722F37),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // 2. LE NEZ
                      _buildSectionTitle('2. 👃 Le Nez (Familles Aromatiques)'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _aromaOptions.map((opt) {
                          final isSelected = _selectedAromas.contains(opt);
                          return FilterChip(
                            label: Text(opt, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (selected) {
                                  _selectedAromas.add(opt);
                                } else {
                                  _selectedAromas.remove(opt);
                                }
                              });
                            },
                            selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            checkmarkColor: const Color(0xFFD4AF37),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // 3. LA BOUCHE
                      _buildSectionTitle('3. 👄 La Bouche & Texture'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _structureOptions.map((opt) {
                          final isSelected = _selectedStructure == opt;
                          return ChoiceChip(
                            label: Text(opt, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedStructure = selected ? opt : null);
                            },
                            selectedColor: const Color(0xFF722F37),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Caudalies (Longueur)
                      Row(
                        children: [
                          const Text('Longueur en bouche : ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('$_caudalies caudalies (secondes)', style: const TextStyle(fontSize: 13, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _caudalies.toDouble(),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        activeColor: const Color(0xFFD4AF37),
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _caudalies = val.round());
                        },
                      ),

                      const SizedBox(height: 12),

                      // Note Globale sur 10
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Note globale :', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_userRating.toStringAsFixed(1)} / 10',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _userRating,
                        min: 1.0,
                        max: 10.0,
                        divisions: 18,
                        activeColor: const Color(0xFFD4AF37),
                        label: '${_userRating.toStringAsFixed(1)} / 10',
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _userRating = val);
                        },
                      ),

                      const SizedBox(height: 8),

                      // Commentaire libre
                      TextField(
                        controller: _commentController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Impression personnelle, accord du repas...',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF262022) : const Color(0xFFFAF7F2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF722F37),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.bookmark_add),
                          label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer dans le Journal'),
                          onPressed: _isSaving ? null : _saveTastingNote,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD4AF37),
        ),
      ),
    );
  }

  Widget _buildAdviceBullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
