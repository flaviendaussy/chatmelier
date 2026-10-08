import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/utils/langue.dart';
import '../../cellar/domain/wine.dart';
import '../data/recit_du_vin.dart';
import '../domain/sommelier_storyteller_engine.dart';

/// Le récit d'un vin, à écouter (V2.4 · R8).
///
/// Écrit à la demande par le sommelier, avec des faits trouvés par la recherche et leurs
/// sources (« generate on request… with some interesting facts », 04/10), puis gardé sur le
/// téléphone. Lu par la voix naturelle de Gemini quand la console l'a allumée, sinon par
/// celle du téléphone, dans la langue de l'app. Sans réseau, le récit simplifié d'avant, qui
/// ne dit que ce que la fiche permet de dire — et qui le dit.
class SommelierStorytellerDialog extends StatefulWidget {
  final Wine wine;
  final ServiceDuRecit? service;
  final VoixDuRecit? voix;

  const SommelierStorytellerDialog({super.key, required this.wine, this.service, this.voix});

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

enum _Voix { aucune, naturelle, telephone }

class _SommelierStorytellerDialogState extends State<SommelierStorytellerDialog> with SingleTickerProviderStateMixin {
  static const _or = Color(0xFFD4AF37);
  static const _bordeaux = Color(0xFF8B1E3F);

  late final AnimationController _onde;
  final FlutterTts _tts = FlutterTts();
  AudioPlayer? _lecteur;
  final List<StreamSubscription<dynamic>> _abonnements = [];

  RecitDuVin? _recit;
  bool _simplifie = false;
  bool _chargement = true;

  _Voix _voix = _Voix.aucune;
  bool _preparation = false;
  bool _enLecture = false;
  Duration _position = Duration.zero;
  Duration _duree = Duration.zero;
  Timer? _minuteur;

  ServiceDuRecit get _service => widget.service ?? ServiceDuRecit();
  VoixDuRecit get _voixDuRecit => widget.voix ?? VoixDuRecit();

  @override
  void initState() {
    super.initState();
    _onde = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _ecrire();
    _preparerLaVoixDuTelephone();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    for (final a in _abonnements) {
      a.cancel();
    }
    _lecteur?.dispose();
    _onde.dispose();
    try {
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _ecrire({bool forcer = false}) async {
    setState(() {
      _chargement = true;
      _simplifie = false;
    });
    RecitDuVin? recit;
    try {
      recit = await _service.ecrire(widget.wine, forcer: forcer);
    } catch (_) {
      recit = null;
    }
    if (!mounted) return;
    if (recit == null) {
      // Le récit d'avant : seulement ce que la fiche permet de dire.
      final s = SommelierStorytellerEngine.generateStory(widget.wine);
      recit = RecitDuVin(titre: s.title, terroir: s.act1Terroir, histoire: s.act2Vinification, verre: s.act3Degustation);
      _simplifie = true;
    }
    setState(() {
      _recit = recit;
      _chargement = false;
    });
  }

  static String _langueDeLaVoix() => switch (Langue.code) {
        'fr' => 'fr-FR',
        'es' => 'es-ES',
        'it' => 'it-IT',
        _ => 'en-GB',
      };

  Future<void> _preparerLaVoixDuTelephone() async {
    try {
      await _tts.setLanguage(_langueDeLaVoix());
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(0.95);
      _tts.setCompletionHandler(() {
        if (mounted) _arreter();
      });
    } catch (e) {
      debugPrint('Voix du téléphone indisponible : $e');
    }
  }

  Future<void> _lire() async {
    final recit = _recit;
    if (recit == null) return;
    // Reprendre la voix naturelle là où elle s'était arrêtée.
    if (_voix == _Voix.naturelle && _lecteur != null && _position > Duration.zero) {
      await _lecteur!.resume();
      setState(() => _enLecture = true);
      return;
    }
    setState(() => _preparation = true);
    final chemin = _simplifie ? null : await _voixDuRecit.fichier(recit, ServiceDuRecit.cleDe(widget.wine));
    if (!mounted) return;
    if (chemin != null) {
      final lecteur = _lecteur ?? AudioPlayer();
      if (_lecteur == null) {
        _lecteur = lecteur;
        _abonnements
          ..add(lecteur.onDurationChanged.listen((d) {
            if (mounted) setState(() => _duree = d);
          }))
          ..add(lecteur.onPositionChanged.listen((p) {
            if (mounted) setState(() => _position = p);
          }))
          ..add(lecteur.onPlayerComplete.listen((_) {
            if (mounted) _arreter();
          }));
      }
      try {
        await lecteur.play(DeviceFileSource(chemin));
        setState(() {
          _voix = _Voix.naturelle;
          _preparation = false;
          _enLecture = true;
        });
        return;
      } catch (e) {
        debugPrint('Lecture du récit impossible : $e');
      }
    }
    // La voix du téléphone : pas de position réelle, une durée estimée à 2,5 mots par seconde.
    final mots = recit.texte.split(RegExp(r'\s+')).length;
    setState(() {
      _voix = _Voix.telephone;
      _preparation = false;
      _enLecture = true;
      _duree = Duration(seconds: math.max(10, (mots / 2.5).round()));
      _position = Duration.zero;
    });
    try {
      await _tts.speak(recit.texte);
    } catch (_) {}
    _minuteur?.cancel();
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_enLecture) return;
      setState(() => _position = Duration(seconds: math.min(_duree.inSeconds, _position.inSeconds + 1)));
    });
  }

  Future<void> _pause() async {
    setState(() => _enLecture = false);
    if (_voix == _Voix.naturelle) {
      await _lecteur?.pause();
    } else {
      _minuteur?.cancel();
      try {
        await _tts.stop();
      } catch (_) {}
      _position = Duration.zero;
    }
  }

  void _arreter() {
    _minuteur?.cancel();
    setState(() {
      _enLecture = false;
      _position = Duration.zero;
    });
    try {
      _tts.stop();
    } catch (_) {}
  }

  Future<void> _deplacer(Duration ecart) async {
    if (_voix != _Voix.naturelle || _lecteur == null) return;
    final cible = _position + ecart;
    await _lecteur!.seek(cible < Duration.zero ? Duration.zero : (cible > _duree ? _duree : cible));
  }

  /// L'acte en cours de lecture, d'après la longueur de chacun.
  int get _acteEnCours {
    final r = _recit;
    if (r == null || !_enLecture || _duree.inMilliseconds == 0) return 0;
    final longueurs = [r.terroir.length, r.histoire.length, r.verre.length];
    final total = longueurs.fold<int>(0, (a, b) => a + b);
    if (total == 0) return 0;
    final avance = _position.inMilliseconds / _duree.inMilliseconds * total;
    var cumul = 0;
    for (var i = 0; i < 3; i++) {
      cumul += longueurs[i];
      if (avance <= cumul) return i + 1;
    }
    return 3;
  }

  static String _temps(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final recit = _recit;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Color(0xFF140E1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _or, width: 1.5)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _bordeaux.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _or.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: _or, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('L\'histoire de ce vin', 'The story of this wine'),
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(
                        (recit?.titre.isNotEmpty ?? false) ? recit!.titre : widget.wine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _or, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _chargement || recit == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: _or),
                        const SizedBox(height: 16),
                        Text(tr('Le sommelier cherche l\'histoire de ce vin…', 'The sommelier is looking up this wine\'s story…'),
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _visualiseur(),
                      const SizedBox(height: 16),
                      _commandes(),
                      const SizedBox(height: 20),
                      if (_simplifie) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Récit simplifié : le sommelier n\'a pas pu chercher l\'histoire de ce vin (réseau ?). Il ne dit que ce que la fiche contient.',
                                    'Simplified story: the sommelier couldn\'t look up this wine\'s history (network?). It only says what the record contains.'),
                                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                              TextButton.icon(
                                onPressed: () => _ecrire(forcer: true),
                                icon: const Icon(Icons.refresh, color: _or, size: 18),
                                label: Text(tr('Réessayer', 'Try again'), style: const TextStyle(color: _or)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _acte(1, tr('Le lieu', 'The place'), recit.terroir, Icons.landscape_outlined),
                      const SizedBox(height: 12),
                      _acte(2, tr('L\'histoire', 'The history'), recit.histoire, Icons.history_edu_outlined),
                      const SizedBox(height: 12),
                      _acte(3, tr('Au verre', 'In the glass'), recit.verre, Icons.wine_bar_rounded),
                      if (recit.sources.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(tr('Sources', 'Sources'),
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        for (final s in recit.sources)
                          InkWell(
                            onTap: () => launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.link, size: 16, color: _or),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(s.titre,
                                        style: const TextStyle(
                                            color: _or, fontSize: 12.5, decoration: TextDecoration.underline)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _visualiseur() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(colors: [Color(0xFF2E1730), Color(0xFF160F1F)], radius: 1.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _or.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 54,
            child: AnimatedBuilder(
              animation: _onde,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(26, (i) {
                  final f = _enLecture ? (0.3 + 0.7 * math.sin((_onde.value * 2 * math.pi) + (i * 0.4)).abs()) : 0.15;
                  return Container(
                    width: 4,
                    height: (f * 46.0).clamp(6.0, 46.0),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_or, _bordeaux], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _preparation
                ? tr('Le sommelier s\'éclaircit la voix…', 'The sommelier is warming up…')
                : _enLecture
                    ? (_voix == _Voix.naturelle
                        ? tr('Voix naturelle', 'Natural voice')
                        : tr('Voix du téléphone', 'Phone voice'))
                    : tr('Appuyez sur Lecture pour écouter', 'Press play to listen'),
            style: TextStyle(color: _enLecture ? _or : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _commandes() {
    final naturelle = _voix == _Voix.naturelle;
    final total = _duree.inMilliseconds;
    final part = total == 0 ? 0.0 : (_position.inMilliseconds / total).clamp(0.0, 1.0);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _or,
            inactiveTrackColor: Colors.white12,
            thumbColor: _or,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 3,
          ),
          child: Slider(
            value: part,
            // Seule la voix naturelle sait où elle en est.
            onChanged: naturelle && total > 0
                ? (v) => _lecteur?.seek(Duration(milliseconds: (v * total).round()))
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_temps(_position), style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(_temps(_duree), style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              tooltip: tr('Reculer de 10 secondes', 'Back 10 seconds'),
              icon: Icon(Icons.replay_10_rounded, color: naturelle ? Colors.white70 : Colors.white24),
              onPressed: naturelle ? () => _deplacer(const Duration(seconds: -10)) : null,
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: _preparation ? null : (_enLecture ? _pause : _lire),
              borderRadius: BorderRadius.circular(36),
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_bordeaux, Color(0xFF5B1028)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _bordeaux, blurRadius: 16, spreadRadius: 1)],
                ),
                child: _preparation
                    ? const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(color: _or, strokeWidth: 3))
                    : Icon(_enLecture ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _or, size: 38),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              iconSize: 32,
              tooltip: tr('Avancer de 10 secondes', 'Forward 10 seconds'),
              icon: Icon(Icons.forward_10_rounded, color: naturelle ? Colors.white70 : Colors.white24),
              onPressed: naturelle ? () => _deplacer(const Duration(seconds: 10)) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _acte(int numero, String titre, String texte, IconData icone) {
    if (texte.trim().isEmpty) return const SizedBox.shrink();
    final enCours = _acteEnCours == numero;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enCours ? const Color(0xFF26182C) : const Color(0xFF1B1422),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: enCours ? _or : Colors.white10, width: enCours ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: enCours ? _or : Colors.white60),
              const SizedBox(width: 8),
              Text(titre,
                  style: TextStyle(color: enCours ? _or : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(texte, style: TextStyle(color: enCours ? Colors.white : Colors.white70, fontSize: 13.5, height: 1.45)),
        ],
      ),
    );
  }
}
