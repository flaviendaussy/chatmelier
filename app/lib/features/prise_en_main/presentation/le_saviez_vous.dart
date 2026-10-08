import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/navigator_keys.dart';
import '../../../shared/utils/langue.dart';
import '../../feedback/data/shake_feedback_service.dart';
import '../data/preferences_de_prise_en_main.dart';
import '../domain/astuces.dart';
import 'guide_de_prise_en_main.dart';

/// « Le saviez-vous ? » (R10) : à l'ouverture de l'app, une fonction expliquée en deux
/// phrases, avec « Me montrer ». Coupée d'un geste (« Ne plus afficher »), réactivable dans
/// Profil → Réglages.
class LeSaviezVous {
  static Future<void> montrer(BuildContext context, Astuce astuce) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (c) => _Feuille(astuce: astuce, parent: context),
      );

  /// Où « Me montrer » emmène.
  static void aller(BuildContext context, Destination d) {
    switch (d) {
      case Destination.cave:
        context.go('/');
      case Destination.ceSoir:
        context.go('/ce-soir');
      case Destination.journal:
        context.go('/journal');
      case Destination.profil:
        context.go('/profile');
      case Destination.sommelier:
        context.push('/chat');
      case Destination.secouer:
        ShakeFeedbackService.instance.triggerFeedback(context);
    }
  }
}

class _Feuille extends StatelessWidget {
  final Astuce astuce;
  final BuildContext parent;
  const _Feuille({required this.astuce, required this.parent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('💡 Le saviez-vous ?', '💡 Did you know?'),
                style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFFB8860B), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('${astuce.emoji} ${astuce.titre.texte}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(astuce.texte.texte, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Plus tard', 'Later'))),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                  onPressed: () {
                    Navigator.pop(context);
                    if (parent.mounted) LeSaviezVous.aller(parent, astuce.destination);
                  },
                  child: Text(tr('Me montrer', 'Show me')),
                ),
              ],
            ),
            const Divider(height: 20),
            TextButton.icon(
              icon: const Icon(Icons.notifications_off_outlined, size: 18),
              label: Text(tr('Ne plus afficher ces astuces', 'Don\'t show these tips again')),
              onPressed: () async {
                final messenger = ScaffoldMessenger.maybeOf(parent);
                await PreferencesDePriseEnMain.activerLesAstuces(false);
                if (context.mounted) Navigator.pop(context);
                messenger?.showSnackBar(SnackBar(
                  content: Text(tr('Astuces coupées. Profil → Réglages pour les remettre.',
                      'Tips turned off. Profile → Settings to bring them back.')),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// À l'ouverture de l'app : le guide la première fois, ensuite une astuce. Une fois par
/// lancement, sur l'app installée seulement (le web sert les invités d'une table), jamais
/// par-dessus un scan ou une autre fenêtre.
class PriseEnMainAuDemarrage extends StatefulWidget {
  final Widget child;
  const PriseEnMainAuDemarrage({super.key, required this.child});

  @override
  State<PriseEnMainAuDemarrage> createState() => _PriseEnMainAuDemarrageState();
}

class _PriseEnMainAuDemarrageState extends State<PriseEnMainAuDemarrage> {
  static bool _faitCeLancement = false;

  static const _onglets = {'/', '/ce-soir', '/journal', '/profile'};

  static bool get _desactive {
    if (kIsWeb) return true;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifier());
  }

  bool get _rienDOuvert =>
      !(rootNavigatorKey.currentState?.canPop() ?? false) && !(shellNavigatorKey.currentState?.canPop() ?? false);

  bool get _surUnOnglet {
    try {
      return _onglets.contains(GoRouter.of(context).routerDelegate.currentConfiguration.uri.path);
    } catch (_) {
      return false;
    }
  }

  Future<void> _verifier() async {
    if (_faitCeLancement || _desactive) return;
    _faitCeLancement = true;
    if (!await PreferencesDePriseEnMain.guideVu()) {
      if (mounted && _rienDOuvert) await GuideDePriseEnMain.ouvrir(context);
      return; // le jour du guide, pas d'astuce
    }
    if (!await PreferencesDePriseEnMain.astucesActives()) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || !_rienDOuvert || !_surUnOnglet) return;
    final astuce = await PreferencesDePriseEnMain.prochaineAstuce();
    if (mounted && _rienDOuvert && _surUnOnglet) await LeSaviezVous.montrer(context, astuce);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Profil → Réglages : revoir le guide, et couper ou remettre les astuces.
class ReglagesDePriseEnMain extends StatefulWidget {
  const ReglagesDePriseEnMain({super.key});

  @override
  State<ReglagesDePriseEnMain> createState() => _ReglagesDePriseEnMainState();
}

class _ReglagesDePriseEnMainState extends State<ReglagesDePriseEnMain> {
  bool? _astuces;

  @override
  void initState() {
    super.initState();
    PreferencesDePriseEnMain.astucesActives().then((v) {
      if (mounted) setState(() => _astuces = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.school_outlined, color: Color(0xFF8B1E3F)),
          title: Text(tr('Revoir la prise en main', 'See the walkthrough again'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(tr('Une minute, sur de fausses bouteilles', 'One minute, on pretend bottles'),
              style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => GuideDePriseEnMain.ouvrir(context),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.lightbulb_outline, color: Color(0xFFD4AF37)),
          title: Text(tr('« Le saviez-vous ? » à l\'ouverture', '“Did you know?” when opening'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(tr('Une astuce sur une fonction de l\'app, à chaque lancement',
              'A tip about one feature of the app, each time it starts'), style: const TextStyle(fontSize: 12)),
          value: _astuces ?? true,
          onChanged: _astuces == null
              ? null
              : (v) {
                  setState(() => _astuces = v);
                  PreferencesDePriseEnMain.activerLesAstuces(v);
                },
        ),
      ],
    );
  }
}
