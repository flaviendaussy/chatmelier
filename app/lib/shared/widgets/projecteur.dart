import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/langue.dart';

/// Un projecteur sur un élément de l'écran (V2.5 · E6) : le reste s'assombrit légèrement,
/// une légende dit quoi regarder, un geste le referme.
///
/// Le 16/10, « Me montrer » sur l'astuce de l'apogée ne montrait rien : il ouvrait la cave,
/// et la personne cherchait seule. « Ça aurait dû […] isoler visuellement la zone (en
/// opacifiant légèrement le reste). »
class Projecteur {
  /// Éclaire [cible] une fois qu'elle est construite et ramenée à l'écran ; se termine quand
  /// la personne referme. Rien ne s'affiche si la cible n'apparaît pas à temps (un autre
  /// onglet, un écran vide) : mieux vaut aucun projecteur qu'un projecteur sur le vide.
  static Future<void> eclairer(
    BuildContext context,
    GlobalKey cible,
    String legende, {
    Duration attenteMax = const Duration(seconds: 3),
  }) async {
    final debut = DateTime.now();
    while (cible.currentContext == null) {
      if (DateTime.now().difference(debut) > attenteMax || !context.mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final contexteCible = cible.currentContext;
    if (contexteCible == null || !contexteCible.mounted) return;
    await Scrollable.ensureVisible(contexteCible,
        duration: const Duration(milliseconds: 450), curve: Curves.easeInOut, alignment: 0.3);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final boite = cible.currentContext?.findRenderObject();
    if (!context.mounted || boite is! RenderBox || !boite.hasSize) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    if (!overlay.mounted) return;
    final repere = overlay.context.findRenderObject();
    final zone = (boite.localToGlobal(Offset.zero, ancestor: repere) & boite.size).inflate(6);

    final fin = Completer<void>();
    late final OverlayEntry entree;
    entree = OverlayEntry(
      builder: (_) => VueDuProjecteur(
        zone: zone,
        legende: legende,
        onFermer: () {
          entree.remove();
          if (!fin.isCompleted) fin.complete();
        },
      ),
    );
    overlay.insert(entree);
    return fin.future;
  }
}

/// Le voile, le halo et la légende. Public pour les essais.
class VueDuProjecteur extends StatelessWidget {
  final Rect zone;
  final String legende;
  final VoidCallback onFermer;

  const VueDuProjecteur({super.key, required this.zone, required this.legende, required this.onFermer});

  @override
  Widget build(BuildContext context) {
    final ecran = MediaQuery.sizeOf(context);
    // La légende sous la zone s'il y a la place, au-dessus sinon.
    final dessous = zone.bottom + 140 < ecran.height;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, t, enfant) => Opacity(opacity: t, child: enfant),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onFermer,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _Voile(zone))),
            Positioned(
              left: 16,
              right: 16,
              top: dessous ? zone.bottom + 12 : null,
              bottom: dessous ? null : ecran.height - zone.top + 12,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1F2D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(legende, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
                      const SizedBox(height: 8),
                      Text(tr('Touchez l\'écran pour continuer', 'Tap the screen to continue'),
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Assombrit tout sauf la zone, entourée d'un liseré doré.
class _Voile extends CustomPainter {
  final Rect zone;
  _Voile(this.zone);

  @override
  void paint(Canvas canvas, Size size) {
    final trou = RRect.fromRectAndRadius(zone, const Radius.circular(14));
    final voile = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(trou),
    );
    canvas.drawPath(voile, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawRRect(
      trou,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_Voile ancien) => ancien.zone != zone;
}
