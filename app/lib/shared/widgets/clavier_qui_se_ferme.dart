import 'package:flutter/material.dart';

/// Le clavier se ferme quand on touche ailleurs (V2.4 · R3, retour du 07/10).
///
/// Sur Android et iPhone, Flutter garde le champ actif quand on touche hors de lui : le
/// clavier restait ouvert et cachait le bouton « Enregistrer ». Posé à la racine de l'app,
/// ce détecteur ne reçoit que les touchers que rien d'autre ne réclame (un bouton, un champ,
/// un défilement gagnent toujours) : toucher un fond, un titre ou un espace vide referme le
/// clavier, sans changer le comportement d'aucun bouton.
class ClavierQuiSeFerme extends StatelessWidget {
  final Widget child;

  const ClavierQuiSeFerme({super.key, required this.child});

  /// Ne referme qu'un champ de saisie : le focus d'un bouton ou d'une liste, utile au
  /// clavier physique et à l'accessibilité, reste où il est.
  static void fermer() {
    final focus = FocusManager.instance.primaryFocus;
    final contexte = focus?.context;
    if (focus == null || contexte == null) return;
    if (contexte.findAncestorWidgetOfExactType<EditableText>() != null) focus.unfocus();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: fermer,
        child: child,
      );
}
