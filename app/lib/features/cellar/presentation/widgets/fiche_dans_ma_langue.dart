import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/utils/langue.dart';
import '../../data/traduction_des_fiches.dart';

/// La description et les accords d'un vin, dans la langue de l'app quand ils ont été écrits
/// dans une autre (V2.4 · R6), avec une mention qui le dit et rend l'original d'un geste.
class FicheDansMaLangue extends StatefulWidget {
  final String? notes;
  final List<String> accords;

  /// Construit la fiche avec le texte à montrer ; [mention] est nulle quand rien n'a été
  /// traduit ni n'est à traduire.
  final Widget Function(BuildContext context, String? notes, List<String> accords, Widget? mention) builder;

  final TraductionDesFiches? service;

  const FicheDansMaLangue({
    super.key,
    required this.notes,
    required this.accords,
    required this.builder,
    this.service,
  });

  @override
  State<FicheDansMaLangue> createState() => _FicheDansMaLangueState();
}

class _FicheDansMaLangueState extends State<FicheDansMaLangue> {
  String? _depuis;
  FicheTraduite? _traduite;
  bool _enCours = false;
  bool _voirLOriginal = false;

  @override
  void initState() {
    super.initState();
    _lancer();
  }

  @override
  void didUpdateWidget(FicheDansMaLangue ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.notes != widget.notes || !listEquals(ancien.accords, widget.accords)) {
      _traduite = null;
      _voirLOriginal = false;
      _lancer();
    }
  }

  void _lancer() {
    final langue = Langue.code;
    final besoin = TraductionDesFiches.aTraduire(widget.notes, widget.accords, langue);
    _depuis = besoin.notes ?? besoin.accords;
    if (_depuis == null) return;
    _enCours = true;
    final notes = widget.notes;
    final accords = widget.accords;
    (widget.service ?? TraductionDesFiches())
        .traduire(notes: notes, accords: accords, langue: langue)
        .then<FicheTraduite?>((t) => t, onError: (_) => null)
        .then((t) {
      if (!mounted || notes != widget.notes || !listEquals(accords, widget.accords)) return;
      setState(() {
        _traduite = t;
        _enCours = false;
      });
    });
  }

  static String _traduitDe(String langue) => switch (langue) {
        'fr' => tr('Traduit du français', 'Translated from French'),
        'es' => tr('Traduit de l\'espagnol', 'Translated from Spanish'),
        'it' => tr('Traduit de l\'italien', 'Translated from Italian'),
        _ => tr('Traduit de l\'anglais', 'Translated from English'),
      };

  static String _ecritEn(String langue) => switch (langue) {
        'fr' => tr('Fiche écrite en français', 'Written in French'),
        'es' => tr('Fiche écrite en espagnol', 'Written in Spanish'),
        'it' => tr('Fiche écrite en italien', 'Written in Italian'),
        _ => tr('Fiche écrite en anglais', 'Written in English'),
      };

  @override
  Widget build(BuildContext context) {
    final depuis = _depuis;
    if (depuis == null) return widget.builder(context, widget.notes, widget.accords, null);
    final t = _traduite;
    final traduit = t != null && !_voirLOriginal;
    final notes = traduit && t.notes != null ? t.notes : widget.notes;
    final accords = traduit && t.accords != null ? t.accords! : widget.accords;
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = TextStyle(fontSize: 11, color: gris);
    final mention = Row(
      children: [
        Icon(Icons.translate, size: 13, color: gris),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            _enCours
                ? tr('Traduction en cours…', 'Translating…')
                : t == null
                    ? _ecritEn(depuis)
                    : _traduitDe(t.depuis),
            style: style,
          ),
        ),
        if (t != null)
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            onPressed: () => setState(() => _voirLOriginal = !_voirLOriginal),
            child: Text(_voirLOriginal ? tr('Voir la traduction', 'See the translation') : tr('Voir l\'original', 'See the original')),
          ),
      ],
    );
    return widget.builder(context, notes, accords, mention);
  }
}
