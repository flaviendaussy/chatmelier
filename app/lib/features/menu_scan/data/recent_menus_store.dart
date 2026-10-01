import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/app_logger.dart';
import '../domain/menu_wine.dart';

/// Les dernières cartes scannées.
///
/// **Ce qui manquait.** Une carte scannée ne survivait pas à la fermeture de son écran :
/// les vins reconnus partaient bien au cache de connaissances, mais la CARTE — quel
/// restaurant, quels vins, à quels prix — n'était conservée nulle part. Sortir de l'écran
/// pour prendre un appel, et il fallait rescanner : un nouvel appel IA, de nouvelles
/// photos, et la table ouverte perdue au passage.
///
/// Trois cartes suffisent. Au-delà, on ne rouvre plus, on cherche.
class RecentMenusStore {
  static const String _cle = 'chatmelier_recent_menus_v1';
  static const int maximum = 3;

  final SharedPreferences _prefs;
  RecentMenusStore(this._prefs);

  static Future<RecentMenusStore> ouvrir() async =>
      RecentMenusStore(await SharedPreferences.getInstance());

  List<ScannedMenu> lire() {
    final brut = _prefs.getString(_cle);
    if (brut == null || brut.isEmpty) return const [];
    try {
      final liste = jsonDecode(brut);
      if (liste is! List) return const [];
      return [
        for (final e in liste)
          if (e is Map<String, dynamic>) ScannedMenu.fromJson(e),
      ];
    } catch (e) {
      AppLogger.warning('MENU_RECENT', 'Cartes récentes illisibles: $e');
      return const [];
    }
  }

  ScannedMenu? get derniere {
    final l = lire();
    return l.isEmpty ? null : l.first;
  }

  Future<void> enregistrer(ScannedMenu menu) async {
    if (menu.wines.isEmpty) return;
    // Rescanner la même carte la remonte en tête plutôt que de la dupliquer : on reconnaît
    // un restaurant à son nom, qui est éditable et donc fiable.
    final restantes = lire()
        .where((m) =>
            m.id != menu.id &&
            m.restaurantName.trim().toLowerCase() !=
                menu.restaurantName.trim().toLowerCase())
        .take(maximum - 1);
    final toutes = [menu, ...restantes];
    await _prefs.setString(
        _cle, jsonEncode([for (final m in toutes) m.toJson()]));
  }

  Future<void> oublier(String menuId) async {
    final restantes = lire().where((m) => m.id != menuId);
    await _prefs.setString(
        _cle, jsonEncode([for (final m in restantes) m.toJson()]));
  }

  Future<void> vider() => _prefs.remove(_cle);
}

/// Les cartes récentes, telles que tous les écrans les montrent.
///
/// L'enregistrement passe par ici, et non par le magasin directement : le 30/09, la
/// liste était lue une fois pour toutes, et « Rouvrir » (onglet Dégustation) montrait la
/// carte connue au premier affichage, pas la dernière scannée.
class CartesRecentes extends AsyncNotifier<List<ScannedMenu>> {
  @override
  Future<List<ScannedMenu>> build() async => (await RecentMenusStore.ouvrir()).lire();

  /// Retient une carte, en tête de liste, et met à jour tous les écrans qui la montrent.
  Future<void> retenir(ScannedMenu menu) async {
    final magasin = await RecentMenusStore.ouvrir();
    await magasin.enregistrer(menu);
    state = AsyncData(magasin.lire());
  }
}

final recentMenusProvider =
    AsyncNotifierProvider<CartesRecentes, List<ScannedMenu>>(CartesRecentes.new);
