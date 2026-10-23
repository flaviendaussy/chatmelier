import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/menu_wine.dart';
import '../domain/verres_de_la_soiree.dart';

/// Les verres de chaque carte, gardés sur le téléphone : une soirée dure trois heures, le
/// téléphone s'endort, l'app est tuée — la liste et ce qui a été noté restent.
class VerresDeLaSoireeStore {
  static const _cle = 'chatmelier_verres_de_la_soiree_v1';

  /// Les dix dernières cartes suffisent : au-delà, la soirée est loin.
  static const maximum = 10;

  final SharedPreferences _prefs;
  VerresDeLaSoireeStore(this._prefs);

  Map<String, SoireeDeVerres> _toutes() {
    try {
      final brut = _prefs.getString(_cle);
      if (brut == null) return {};
      final j = jsonDecode(brut);
      if (j is! List) return {};
      return {
        for (final e in j)
          if (SoireeDeVerres.fromJson(e) case final s?) s.menuId: s,
      };
    } catch (_) {
      return {};
    }
  }

  SoireeDeVerres? lire(String menuId) => _toutes()[menuId];

  Future<void> ecrire(SoireeDeVerres soiree) async {
    final toutes = _toutes()..remove(soiree.menuId);
    final gardees = [...toutes.values.toList().reversed.take(maximum - 1).toList().reversed, soiree];
    await _prefs.setString(_cle, jsonEncode([for (final s in gardees) s.toJson()]));
  }
}

final verresDeLaSoireeStoreProvider = FutureProvider<VerresDeLaSoireeStore>(
  (ref) async => VerresDeLaSoireeStore(await SharedPreferences.getInstance()),
);

/// La soirée d'une carte : ses verres, avec qui. Écrite à chaque changement.
class VerresDeLaSoiree extends StateNotifier<SoireeDeVerres> {
  final Ref _ref;

  VerresDeLaSoiree(this._ref, CarteDeLaSoiree carte) : super(SoireeDeVerres(menuId: carte.id, lieu: carte.lieu)) {
    _charger();
  }

  Future<void> _charger() async {
    final store = await _ref.read(verresDeLaSoireeStoreProvider.future);
    final gardee = store.lire(state.menuId);
    if (gardee != null && mounted) state = gardee;
  }

  Future<void> _garder() async {
    final store = await _ref.read(verresDeLaSoireeStoreProvider.future);
    await store.ecrire(state);
  }

  void basculer(MenuWine w) {
    state = state.basculer(w);
    _garder();
  }

  void remplacer(VerreDeLaSoiree v) {
    state = state.remplacer(v);
    _garder();
  }

  void convives(List<String> noms) {
    state = state.avecConvives(noms);
    _garder();
  }
}

/// Une carte, désignée par ce qui ne change pas quand l'écran la recalcule.
typedef CarteDeLaSoiree = ({String id, String lieu});

CarteDeLaSoiree carteDeLaSoiree(ScannedMenu menu) => (id: menu.id, lieu: menu.restaurantName);

final verresDeLaSoireeProvider = StateNotifierProvider.family<VerresDeLaSoiree, SoireeDeVerres, CarteDeLaSoiree>(
    (ref, carte) => VerresDeLaSoiree(ref, carte));
