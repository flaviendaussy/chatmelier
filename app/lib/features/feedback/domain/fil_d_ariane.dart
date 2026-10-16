import 'package:flutter/widgets.dart';

/// Les derniers pas de la personne dans l'app : les écrans, les feuilles et les dialogues
/// ouverts, avec l'heure. Joints à chaque retour, ils disent d'où il vient quand la capture
/// manque (16/10 : une capture perdue faute de réseau, et rien pour savoir quel écran
/// Flavien regardait). Aucun contenu : des adresses d'écran et des types de fenêtres.
class FilDAriane extends NavigatorObserver {
  FilDAriane._(this._navigateur);

  /// Un observateur ne sert qu'un navigateur : un pour la racine, un pour la coquille des
  /// onglets ; tous deux écrivent dans le même fil.
  static final racine = FilDAriane._('racine');
  static final coquille = FilDAriane._('onglets');

  final String _navigateur;

  static const tailleMax = 12;
  static final List<({DateTime quand, String quoi})> _pas = [];
  static String? _emplacement;

  /// L'écran affiché, tel que le routeur le connaît (« /cellar/abc »).
  static String? get emplacement => _emplacement;

  static List<({DateTime quand, String quoi})> get pas => List.unmodifiable(_pas);

  /// Appelé à chaque changement d'adresse du routeur.
  static void noterEmplacement(String adresse) {
    if (adresse == _emplacement) return;
    _emplacement = adresse;
    _noter('écran $adresse');
  }

  static void _noter(String quoi) {
    _pas.add((quand: DateTime.now(), quoi: quoi));
    if (_pas.length > tailleMax) _pas.removeAt(0);
  }

  @visibleForTesting
  static void vider() {
    _pas.clear();
    _emplacement = null;
  }

  /// Ce que la route est, sans ce qu'elle contient : « feuille », « dialogue », ou son nom.
  static String nature(Route<dynamic> route) {
    final nom = route.settings.name;
    if (nom != null && nom.isNotEmpty) return nom;
    final type = route.runtimeType.toString();
    if (type.contains('BottomSheet')) return 'feuille';
    if (type.contains('Dialog')) return 'dialogue';
    if (type.contains('Popup')) return 'menu';
    return type.replaceAll(RegExp(r'<.*>'), '');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _noter('$_navigateur + ${nature(route)}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _noter('$_navigateur − ${nature(route)}');

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _noter('$_navigateur ⇄ ${nature(newRoute)}');
  }
}
