import 'package:flutter/material.dart';

import '../../../shared/utils/langue.dart';
import '../data/preferences_de_prise_en_main.dart';

/// La prise en main (R10, demandée le 08/10) : une minute pour voir l'app, en faisant les
/// vrais gestes sur une fausse cave, une fausse carte et un faux journal. Rien n'est écrit,
/// nulle part. « Passer » est là à chaque étape, en un geste : les pressés ne sont jamais
/// retenus. Relançable depuis Profil → Réglages.
class GuideDePriseEnMain extends StatefulWidget {
  const GuideDePriseEnMain({super.key});

  static Future<void> ouvrir(BuildContext context) => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const GuideDePriseEnMain()),
      );

  @override
  State<GuideDePriseEnMain> createState() => _GuideDePriseEnMainState();
}

class _GuideDePriseEnMainState extends State<GuideDePriseEnMain> {
  static const _bordeaux = Color(0xFF8B1E3F);
  static const _or = Color(0xFFD4AF37);
  static const _nombreDEtapes = 7;

  int _etape = 0;

  /// Le geste de l'étape a été fait, et ce qu'il montre (une phrase).
  String? _reponse;

  /// Ce qui a été touché à l'étape en cours (une bouteille, un vin, une note).
  int? _choix;

  bool get _sansGeste => _etape == 0 || _etape == _nombreDEtapes - 1;

  Future<void> _terminer() async {
    await PreferencesDePriseEnMain.marquerLeGuideVu();
    if (mounted) Navigator.of(context).pop();
  }

  void _suivant() {
    if (_etape == _nombreDEtapes - 1) {
      _terminer();
      return;
    }
    setState(() {
      _etape++;
      _reponse = null;
      _choix = null;
    });
  }

  void _repondre(int choix, String reponse) => setState(() {
        _choix = choix;
        _reponse = reponse;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pret = _sansGeste || _reponse != null;
    return PopScope(
      // Le retour du téléphone vaut « Passer » : le guide n'est jamais un piège.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) PreferencesDePriseEnMain.marquerLeGuideVu();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hauteur fixe : à la dernière étape, sans « Passer », rien ne remonte.
                SizedBox(
                  height: 48,
                  child: Row(
                  children: [
                    for (var i = 0; i < _nombreDEtapes; i++)
                      Container(
                        width: i == _etape ? 18 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: i <= _etape ? _bordeaux : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    const Spacer(),
                    if (_etape < _nombreDEtapes - 1)
                      TextButton(
                        onPressed: _terminer,
                        child: Text(tr('Passer', 'Skip'), style: const TextStyle(fontSize: 16)),
                      ),
                  ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(key: ValueKey(_etape), child: _contenu(theme)),
                    ),
                  ),
                ),
                if (_reponse != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _or.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _or.withValues(alpha: 0.6)),
                    ),
                    child: Text(_reponse!, style: theme.textTheme.bodyLarge),
                  ),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _bordeaux,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: pret ? _suivant : null,
                    child: Text(_etape == 0
                        ? tr('Commencer', 'Start')
                        : _etape == _nombreDEtapes - 1
                            ? tr('C\'est parti', 'Let\'s go')
                            : pret
                                ? tr('Suivant', 'Next')
                                : tr('Faites le geste ci-dessus', 'Try the gesture above')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenu(ThemeData theme) => switch (_etape) {
        0 => _page(
            theme,
            emoji: '🍷',
            titre: tr('Bienvenue dans Chatmelier', 'Welcome to Chatmelier'),
            texte: tr(
                'Il vous aide à choisir un vin, au restaurant comme à la maison, et à ouvrir vos bouteilles au bon moment. Voyons comment, en une minute.',
                'It helps you choose a wine, out or at home, and open your bottles at the right time. Let\'s see how, in one minute.'),
          ),
        1 => _page(
            theme,
            emoji: '🏠',
            titre: tr('Votre cave', 'Your cellar'),
            texte: tr('Touchez une bouteille : sa jauge dit quand l\'ouvrir.',
                'Tap a bottle: its gauge tells you when to open it.'),
            enfant: Column(
              children: [
                _bouteille(theme, 0, tr('Champagne brut', 'Champagne brut'), tr('Prêt à boire', 'Ready to drink'),
                    const Color(0xFF2E7D32), 0.55,
                    tr('Prêt à boire : un champagne sans millésime se boit dans les deux ou trois ans.',
                        'Ready to drink: a non-vintage champagne is best within two or three years.')),
                _bouteille(theme, 1, tr('Bandol rouge 2019', 'Bandol red 2019'), tr('En garde', 'Keep for now'),
                    const Color(0xFF1E88E5), 0.2,
                    tr('En garde : un Bandol rouge s\'ouvre plutôt à partir de 2028.',
                        'Keep for now: a red Bandol is better opened from 2028.')),
                _bouteille(theme, 2, tr('Beaujolais-Villages 2021', 'Beaujolais-Villages 2021'),
                    tr('À boire cette année', 'Drink this year'), const Color(0xFFEF6C00), 0.85,
                    tr('À boire cette année : un Beaujolais-Villages se boit jeune, pour son fruit.',
                        'Drink this year: a Beaujolais-Villages is drunk young, for its fruit.')),
              ],
            ),
          ),
        2 => _page(
            theme,
            emoji: '📸',
            titre: tr('Ajouter une bouteille', 'Add a bottle'),
            texte: tr('Touchez le bouton +. Dans l\'app, il ouvre l\'appareil photo : Chatmelier lit l\'étiquette et remplit la fiche.',
                'Tap the + button. In the app it opens the camera: Chatmelier reads the label and fills in the details.'),
            enfant: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _cible(
                  actif: _choix == null,
                  child: FloatingActionButton.large(
                    heroTag: null,
                    backgroundColor: _bordeaux,
                    foregroundColor: Colors.white,
                    onPressed: () => _repondre(
                        0,
                        tr('Ici, l\'appareil photo s\'ouvrirait. Rien n\'est enregistré pendant ce guide.',
                            'This is where the camera would open. Nothing is saved during this guide.')),
                    child: const Icon(Icons.add, size: 40),
                  ),
                ),
              ),
            ),
          ),
        3 => _page(
            theme,
            emoji: '🍽️',
            titre: tr('Au restaurant', 'Eating out'),
            texte: tr(
                'Photographiez la carte des vins : Chatmelier classe chaque vin selon vos goûts. Touchez celui qui vous tente.',
                'Take a photo of the wine list: Chatmelier ranks each wine for your taste. Tap the one you fancy.'),
            enfant: Column(
              children: [
                _vinDeLaCarte(theme, 0, 'Chablis 2022', '48 €', 88, null),
                _vinDeLaCarte(theme, 1, 'Morgon 2021', '42 €', 74, null),
                _vinDeLaCarte(theme, 2, 'Saint-Joseph 2020', '42 €', 91,
                    tr('⚖️ À prix égal, je prendrais celui-ci', '⚖️ At the same price, I\'d pick this one')),
              ],
            ),
          ),
        4 => _page(
            theme,
            emoji: '📓',
            titre: tr('Noter un verre', 'Rate a glass'),
            texte: tr(
                'Après un vin, notez-le d\'un geste : votre palais apprend, et les conseils vous ressemblent de plus en plus.',
                'After a wine, rate it in one tap: your palate learns, and the advice fits you better and better.'),
            enfant: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                for (final (i, emoji) in const ['😖', '😕', '😐', '🙂', '😍'].indexed)
                  _cible(
                    actif: _choix == null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: () => _repondre(
                          i,
                          tr('Noté ! Pour de faux : ce guide n\'écrit rien dans votre journal.',
                              'Rated! Only pretend: this guide writes nothing to your journal.')),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _choix == i ? _or.withValues(alpha: 0.3) : theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        5 => _page(
            theme,
            emoji: '💬',
            titre: tr('Une question ?', 'A question?'),
            texte: tr('La bulle, en haut de chaque écran, ouvre le sommelier. Touchez-la.',
                'The bubble at the top of every screen opens the sommelier. Tap it.'),
            enfant: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _cible(
                  actif: _choix == null,
                  child: IconButton.filledTonal(
                    iconSize: 44,
                    onPressed: () => _repondre(
                        0,
                        tr('« Que boire avec un poulet rôti ? » — « Un blanc ample, comme un Meursault, ou un rouge léger, comme un Fleurie. »',
                            '“What goes with roast chicken?” — “A rich white, like a Meursault, or a light red, like a Fleurie.”')),
                    icon: const Icon(Icons.sms_rounded, color: _or),
                  ),
                ),
              ),
            ),
          ),
        _ => _page(
            theme,
            emoji: '🥂',
            titre: tr('C\'est parti !', 'You\'re all set!'),
            texte: tr(
                'Vous retrouverez ce guide dans Profil → Réglages. Une astuce vous attendra parfois à l\'ouverture : un geste suffit pour les couper.',
                'You\'ll find this guide again in Profile → Settings. A tip will sometimes greet you when the app opens: one tap turns them off.'),
          ),
      };

  Widget _page(ThemeData theme, {required String emoji, required String titre, required String texte, Widget? enfant}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 12),
        Text(titre, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(texte, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4, fontSize: 18)),
        if (enfant != null) ...[const SizedBox(height: 20), enfant],
      ],
    );
  }

  /// Ce qu'il faut toucher, entouré tant qu'on ne l'a pas fait.
  Widget _cible({required bool actif, required Widget child}) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48),
          border: Border.all(color: actif ? _or : Colors.transparent, width: 3),
        ),
        child: child,
      );

  Widget _bouteille(ThemeData theme, int i, String nom, String etat, Color couleur, double curseur, String explication) {
    final choisie = _choix == i;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: choisie ? _or : (_choix == null ? _or.withValues(alpha: 0.5) : Colors.transparent), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _repondre(i, explication),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nom, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(etat, style: TextStyle(color: couleur, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE8D08D), Color(0xFF43A047), Color(0xFF43A047), Color(0xFFEF6C00), Color(0xFFC62828)]),
                      ),
                    ),
                    Positioned(
                      left: (c.maxWidth - 3) * curseur,
                      child: Container(width: 3, height: 6, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vinDeLaCarte(ThemeData theme, int i, String nom, String prix, int pourVous, String? ligne) {
    final choisi = _choix == i;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: choisi ? _or : (_choix == null ? _or.withValues(alpha: 0.5) : Colors.transparent), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _repondre(
            i,
            ligne != null
                ? tr('« À prix égal, je prendrais celui-ci » : plus proche de vos goûts que le Morgon, au même prix.',
                    '“At the same price, I\'d pick this one”: closer to your taste than the Morgon, for the same price.')
                : tr('{n} % pour vous : la part de vos goûts que ce vin coche. Plus vous notez, plus ce chiffre est juste.',
                    '{n}% for you: how much of your taste this wine ticks. The more you rate, the more accurate it gets.',
                    {'n': pourVous})),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(nom, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                Text(prix, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _bordeaux)),
              ]),
              const SizedBox(height: 6),
              Text(tr('{n} % pour vous', '{n}% for you', {'n': pourVous}),
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              if (ligne != null) ...[
                const SizedBox(height: 4),
                Text(ligne, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
