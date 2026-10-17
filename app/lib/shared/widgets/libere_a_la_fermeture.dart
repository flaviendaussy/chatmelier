import 'package:flutter/widgets.dart';

/// Les contrôleurs d'une boîte de dialogue, libérés quand la boîte quitte vraiment l'écran.
///
/// Libérés dès le retour de `showDialog`, ils servaient encore aux cases pendant que la
/// boîte s'effaçait : « A TextEditingController was used after being disposed », puis
/// l'écran rouge (17/10, « Annuler » sur un nouveau profil). Placé à la racine de ce que
/// construit la boîte, ce widget est démonté après ses cases : il libère des contrôleurs
/// que plus rien n'écoute.
class LibereALaFermeture extends StatefulWidget {
  final List<ChangeNotifier> controleurs;
  final Widget child;

  const LibereALaFermeture({super.key, required this.controleurs, required this.child});

  @override
  State<LibereALaFermeture> createState() => _LibereALaFermetureState();
}

class _LibereALaFermetureState extends State<LibereALaFermeture> {
  @override
  void dispose() {
    for (final c in widget.controleurs) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
