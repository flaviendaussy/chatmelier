import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../cellar/domain/wine.dart';
import '../domain/sommelier_storyteller_engine.dart';

class SommelierStorytellerDialog extends StatefulWidget {
  final Wine wine;

  const SommelierStorytellerDialog({super.key, required this.wine});

  static Future<void> show(BuildContext context, {required Wine wine}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SommelierStorytellerDialog(wine: wine),
    );
  }

  @override
  State<SommelierStorytellerDialog> createState() => _SommelierStorytellerDialogState();
}

class _SommelierStorytellerDialogState extends State<SommelierStorytellerDialog>
    with SingleTickerProviderStateMixin {
  late final SommelierStory _story;
  late final FlutterTts _tts;
  late final AnimationController _waveAnimCtrl;

  bool _isPlaying = false;
  int _currentSeconds = 0;
  Timer? _playbackTimer;
  int _activeAct = 1; // 1, 2, or 3
  bool _showScript = true;

  @override
  void initState() {
    super.initState();
    _story = SommelierStorytellerEngine.generateStory(widget.wine);

    _waveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initTts();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.46); // Cadence posée de sommelier
      await _tts.setPitch(0.95); // Voix chaude et chaleureuse

      _tts.setCompletionHandler(() {
        if (mounted) {
          _stopPlayback();
        }
      });
    } catch (e) {
      debugPrint('TTS non supporté sur cette plateforme : $e');
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _waveAnimCtrl.dispose();
    try {
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }

  void _startPlayback() async {
    setState(() => _isPlaying = true);

    try {
      await _tts.speak(_story.fullText);
    } catch (_) {}

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_currentSeconds < _story.estimatedSeconds) {
        setState(() {
          _currentSeconds++;
          if (_currentSeconds < 15) {
            _activeAct = 1;
          } else if (_currentSeconds < 30) {
            _activeAct = 2;
          } else {
            _activeAct = 3;
          }
        });
      } else {
        _stopPlayback();
      }
    });
  }

  void _pausePlayback() async {
    setState(() => _isPlaying = false);
    _playbackTimer?.cancel();
    try {
      await _tts.pause();
    } catch (_) {}
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentSeconds = 0;
      _activeAct = 1;
    });
    try {
      _tts.stop();
    } catch (_) {}
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF140E1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // En-tête
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Capsule Terroir & Récit Sommelier',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _story.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Visualiseur d'onde sonore dynamique
                _buildWaveformVisualizer(),
                const SizedBox(height: 20),

                // Contrôles de lecture audio
                _buildAudioControls(),
                const SizedBox(height: 24),

                // Script immersif en 3 actes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Récit du Sommelier en 3 Actes',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showScript = !_showScript),
                      child: Text(
                        _showScript ? 'Masquer texte' : 'Afficher texte',
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (_showScript) ...[
                  const SizedBox(height: 10),
                  _buildActCard(1, 'Acte I : Terroir & Origine', _story.act1Terroir, Icons.landscape_outlined),
                  const SizedBox(height: 12),
                  _buildActCard(2, 'Acte II : Vinification & Patience', _story.act2Vinification, Icons.science_outlined),
                  const SizedBox(height: 12),
                  _buildActCard(3, 'Acte III : Émotion de Dégustation', _story.act3Degustation, Icons.wine_bar_rounded),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformVisualizer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFF2E1730), Color(0xFF160F1F)],
          radius: 1.1,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: AnimatedBuilder(
              animation: _waveAnimCtrl,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(26, (i) {
                    final factor = _isPlaying
                        ? (0.3 + 0.7 * math.sin((_waveAnimCtrl.value * 2 * math.pi) + (i * 0.4)).abs())
                        : 0.15;
                    final height = (factor * 50.0).clamp(6.0, 50.0);

                    return Container(
                      width: 4,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD4AF37),
                            const Color(0xFF8B1E3F),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isPlaying ? 'Récit sommelier en cours...' : 'Appuyez sur Lecture pour écouter',
            style: TextStyle(
              color: _isPlaying ? const Color(0xFFD4AF37) : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    final progress = (_currentSeconds / _story.estimatedSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        // Barre de progression
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFD4AF37),
            inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFFD4AF37),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 3,
          ),
          child: Slider(
            value: progress,
            onChanged: (val) {
              setState(() {
                _currentSeconds = (val * _story.estimatedSeconds).round();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime(_currentSeconds), style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(_formatTime(_story.estimatedSeconds), style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Boutons Play / Pause / Reset
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.replay_10_rounded, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _currentSeconds = math.max(0, _currentSeconds - 10);
                });
              },
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                if (_isPlaying) {
                  _pausePlayback();
                } else {
                  _startPlayback();
                }
              },
              borderRadius: BorderRadius.circular(36),
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B1E3F), Color(0xFF5B1028)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8B1E3F),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFFD4AF37),
                  size: 38,
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.forward_10_rounded, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _currentSeconds = math.min(_story.estimatedSeconds, _currentSeconds + 10);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActCard(int actNum, String title, String content, IconData icon) {
    final isCurrent = _activeAct == actNum && _isPlaying;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF26182C) : const Color(0xFF1B1422),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? const Color(0xFFD4AF37) : Colors.white10,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isCurrent ? const Color(0xFFD4AF37) : Colors.white60),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isCurrent ? const Color(0xFFD4AF37) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (isCurrent) ...[
                const Spacer(),
                const Text('En lecture 🎙️', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
