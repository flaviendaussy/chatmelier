import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../utils/langue.dart';

/// Un onglet de l'app.
class OngletDeLApp {
  /// Le chemin où mène l'onglet.
  final String chemin;

  /// D'autres chemins qui le sélectionnent (anciens liens).
  final List<String> autresChemins;

  final IconData icone;
  final IconData iconeActive;
  final String Function(BuildContext) libelle;

  const OngletDeLApp(
    this.chemin,
    this.icone,
    this.iconeActive,
    this.libelle, {
    this.autresChemins = const [],
  });

  bool selectionnePar(String emplacement) => chemin == '/'
      ? emplacement == '/'
      : emplacement.startsWith(chemin) || autresChemins.any(emplacement.startsWith);
}

/// Les onglets de l'app, les mêmes pour le téléphone, la tablette et l'ordinateur
/// (V2.3 · E1). Ils étaient écrits trois fois, et avaient divergé ; le chat y tenait la
/// deuxième place quand la table, le différenciant de l'app, était la troisième tuile d'un
/// onglet consacré au passé. Le chat devient un bouton présent partout ([BoutonSommelier]).
///
/// Les statistiques n'ont un onglet que sur grand écran : sur le téléphone, quatre onglets.
List<OngletDeLApp> ongletsDeLApp({required bool grandEcran}) => [
      OngletDeLApp('/ce-soir', Icons.restaurant_outlined, Icons.restaurant,
          (c) => AppLocalizations.of(c)?.navTonight ?? tr('Ce soir', 'Tonight')),
      OngletDeLApp('/', Icons.wine_bar_outlined, Icons.wine_bar,
          (c) => AppLocalizations.of(c)?.navCellar ?? tr('Cave', 'Cellar')),
      OngletDeLApp('/history', Icons.menu_book_outlined, Icons.menu_book,
          (c) => AppLocalizations.of(c)?.navJournal ?? tr('Journal', 'Journal'),
          autresChemins: const ['/journal', '/historique']),
      if (grandEcran)
        OngletDeLApp('/stats', Icons.insights_outlined, Icons.insights,
            (c) => AppLocalizations.of(c)?.navStats ?? tr('Stats', 'Stats')),
      OngletDeLApp('/profile', Icons.person_outline, Icons.person,
          (c) => AppLocalizations.of(c)?.navProfile ?? tr('Profil', 'Profile')),
    ];

/// L'onglet sélectionné par cet emplacement ; la cave par défaut.
int indexDeLOnglet(String emplacement, List<OngletDeLApp> onglets) {
  for (var i = 0; i < onglets.length; i++) {
    if (onglets[i].chemin != '/' && onglets[i].selectionnePar(emplacement)) return i;
  }
  final cave = onglets.indexWhere((o) => o.chemin == '/');
  return cave < 0 ? 0 : cave;
}

/// Le sommelier, présent dans la barre de chaque onglet : il n'a plus d'onglet à lui.
class BoutonSommelier extends StatelessWidget {
  const BoutonSommelier({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
      tooltip: tr('Demander au sommelier', 'Ask the sommelier'),
      onPressed: () => context.push('/chat'),
    );
  }
}
