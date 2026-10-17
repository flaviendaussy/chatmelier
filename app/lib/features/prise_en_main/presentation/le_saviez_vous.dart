import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/navigator_keys.dart';
import '../../config/garde_de_version.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../feedback/data/shake_feedback_service.dart';
import '../data/preferences_de_prise_en_main.dart';
import '../../../shared/widgets/projecteur.dart';
import '../../cellar/presentation/cellar_export_dialog.dart';
import '../domain/astuces.dart';
import 'cibles_du_projecteur.dart';
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

  /// « Me montrer » montre la chose (V2.5 · E6) : l'apogée sur une cave de démonstration ;
  /// ailleurs, l'élément dont parle l'astuce, sous un projecteur. Le 16/10, « Me montrer »
  /// ouvrait seulement l'onglet, et la personne cherchait seule.
  static Future<void> montrerLaChose(BuildContext context, Astuce astuce) async {
    final (cible, legende) = switch (astuce.id) {
      'a_prix_egal' => (
          CiblesDuProjecteur.scannerLaCarte,
          tr('Photographiez la carte du restaurant : quand deux vins ont le même prix, ⚖️ vous dit lequel prendre.',
              'Take a photo of the wine list: when two wines cost the same, ⚖️ tells you which one to pick.'),
        ),
      'table' => (
          CiblesDuProjecteur.scannerLaCarte,
          tr('Scannez la carte, puis « Choisir en groupe » : chacun vote sur son téléphone, même sans l\'app.',
              'Scan the list, then “Choose as a group”: everyone votes on their own phone, even without the app.'),
        ),
      'vin_dehors' => (
          CiblesDuProjecteur.vinBuDehors,
          tr('Ici, un vin bu chez des amis ou au restaurant entre dans votre journal, sans toucher à votre cave.',
              'Here, a wine had at friends\' or at a restaurant goes into your journal, without touching your cellar.'),
        ),
      'plat' => (
          CiblesDuProjecteur.platALaMaison,
          tr('Dites ce que vous cuisinez : Chatmelier choisit parmi vos propres bouteilles.',
              'Say what you\'re cooking: Chatmelier picks from your own bottles.'),
        ),
      'palais' => (
          CiblesDuProjecteur.radarDuPalais,
          tr('Votre palais : trait plein, ce que l\'app a observé ; pointillés, ce qu\'elle devine encore.',
              'Your palate: solid line, what the app has observed; dotted, what it still guesses.'),
        ),
      _ => (null, ''),
    };
    switch (astuce.id) {
      case 'jauge':
        context.push('/demo/apogee');
      case 'export':
        // La chose elle-même : la fenêtre d'export de la cave.
        context.go('/profile');
        final racine = rootNavigatorKey.currentContext;
        if (racine != null && racine.mounted) await CellarExportDialog.show(racine, tr('Ma cave', 'My cellar'));
      default:
        aller(context, astuce.destination);
        final racine = rootNavigatorKey.currentContext;
        if (cible == null || racine == null) return;
        try {
          await Projecteur.eclairer(racine, cible, legende);
        } catch (e) {
          AppLogger.warning('PRISE_EN_MAIN', 'Projecteur de « ${astuce.id} » impossible : $e');
        }
    }
  }

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
                    if (parent.mounted) LeSaviezVous.montrerLaChose(parent, astuce);
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

/// À l'ouverture de l'app : le guide la première fois, ensuite une nouvelle version s'il y en
/// a une, sinon une astuce. Une fenêtre par lancement, sur l'app installée seulement (le web
/// sert les invités d'une table), jamais par-dessus un scan ou une autre fenêtre.
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
    final disponible = await _versionDisponible();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || !_rienDOuvert || !_surUnOnglet) return;
    // Une nouvelle version passe avant l'astuce, même quand les astuces sont coupées.
    if (await PropositionDeMiseAJour.montrerSiBesoin(context, disponible)) return;
    if (!await PreferencesDePriseEnMain.astucesActives()) return;
    if (!mounted || !_rienDOuvert || !_surUnOnglet) return;
    final astuce = await PreferencesDePriseEnMain.prochaineAstuce();
    if (mounted && _rienDOuvert && _surUnOnglet) await LeSaviezVous.montrer(context, astuce);
  }

  /// La version proposée, sans attendre plus de huit secondes : hors ligne, l'astuce passe.
  Future<ExigenceDeVersion?> _versionDisponible() async {
    try {
      return await ProviderScope.containerOf(context, listen: false)
          .read(versionDisponibleProvider.future)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
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
