import 'dart:async';

import 'package:flutter/widgets.dart';

import '../utils/app_logger.dart';

typedef Planifier = Object Function(Duration delai, void Function() action);

/// Un sondage qui s'espace quand il échoue, se tait en arrière-plan, et le dit (V2.3 · D1).
///
/// L'actualisation des convives d'une table tournait toutes les 6 secondes quoi qu'il
/// arrive : le 29/09, un invité web a échoué 381 fois de suite (plus d'une demi-heure), une
/// ligne de journal à chaque fois, sans que l'écran le dise. Ici :
/// - après un échec, l'intervalle double (6, 12, 24… jusqu'à [plafond]) ;
/// - un seul journal au premier échec, un autre au retour ;
/// - après [seuilAlerte] échecs de suite, [surAlerte] prévient l'écran, qui propose de
///   réessayer ;
/// - l'app en arrière-plan (téléphone verrouillé, onglet caché) met le sondage en pause.
class SondageEspace {
  final Future<bool> Function() tache;
  final Duration intervalle;
  final Duration plafond;
  final int seuilAlerte;
  final String etiquette;
  final void Function(bool enAlerte)? surAlerte;
  final Planifier _planifier;
  final void Function(Object minuteur) _annuler;

  AppLifecycleListener? _cycle;
  Object? _minuteur;
  bool _actif = false;
  bool _enPause = false;
  bool _enCours = false;
  int _echecs = 0;

  SondageEspace({
    required this.tache,
    required this.etiquette,
    this.intervalle = const Duration(seconds: 6),
    this.plafond = const Duration(seconds: 60),
    this.seuilAlerte = 5,
    this.surAlerte,
    bool suivreLeCycleDeVie = true,
    Planifier? planifier,
    void Function(Object minuteur)? annuler,
  })  : _planifier = planifier ?? ((d, a) => Timer(d, a)),
        _annuler = annuler ?? ((m) => (m as Timer).cancel()) {
    if (suivreLeCycleDeVie) {
      _cycle = AppLifecycleListener(onHide: _mettreEnPause, onShow: _reprendre);
    }
  }

  int get echecs => _echecs;
  bool get enAlerte => _echecs >= seuilAlerte;

  /// Le délai avant le prochain passage, selon les échecs accumulés.
  Duration get prochainDelai {
    if (_echecs == 0) return intervalle;
    final ms = intervalle.inMilliseconds * (1 << (_echecs.clamp(1, 16)));
    return Duration(milliseconds: ms.clamp(intervalle.inMilliseconds, plafond.inMilliseconds));
  }

  void demarrer({bool immediat = true}) {
    _actif = true;
    if (immediat) {
      _passer();
    } else {
      _programmer();
    }
  }

  /// Réessayer tout de suite, par exemple depuis le bouton « Réessayer » de l'écran.
  void relancer() {
    if (!_actif) return;
    _annulerMinuteur();
    _passer();
  }

  void arreter() {
    _actif = false;
    _annulerMinuteur();
    _cycle?.dispose();
    _cycle = null;
  }

  void _mettreEnPause() {
    _enPause = true;
    _annulerMinuteur();
  }

  void _reprendre() {
    if (!_enPause) return;
    _enPause = false;
    if (_actif) _passer();
  }

  void _annulerMinuteur() {
    final m = _minuteur;
    if (m != null) _annuler(m);
    _minuteur = null;
  }

  void _programmer() {
    if (!_actif || _enPause) return;
    _annulerMinuteur();
    _minuteur = _planifier(prochainDelai, _passer);
  }

  Future<void> _passer() async {
    if (!_actif || _enPause || _enCours) return;
    _enCours = true;
    bool ok;
    try {
      ok = await tache();
    } catch (_) {
      ok = false;
    }
    _enCours = false;
    final etaitEnAlerte = enAlerte;
    if (ok) {
      if (_echecs > 0) AppLogger.info('SONDAGE', '$etiquette : rétabli après $_echecs échec(s)');
      _echecs = 0;
    } else {
      if (_echecs == 0) AppLogger.warning('SONDAGE', '$etiquette : lecture impossible, les essais s\'espacent');
      _echecs++;
    }
    if (enAlerte != etaitEnAlerte) surAlerte?.call(enAlerte);
    _programmer();
  }
}
