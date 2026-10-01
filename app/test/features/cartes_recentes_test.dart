import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/menu_scan/data/recent_menus_store.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';

ScannedMenu carte(String id, String restaurant) => ScannedMenu(
      id: id,
      restaurantName: restaurant,
      pagePhotoPaths: const [],
      wines: [MenuWine.fromJson(const {'id': 'v', 'name': 'Bandol', 'wine_type': 'Rouge', 'bottle_price': 42})],
      scannedAt: DateTime(2026, 9, 30),
    );

void main() {
  test('« Rouvrir » montre la dernière carte scannée, pas la première connue (30/09)', () async {
    SharedPreferences.setMockInitialValues({});
    final conteneur = ProviderContainer();
    addTearDown(conteneur.dispose);

    // L'onglet Dégustation lit la liste à son premier affichage…
    await conteneur.read(recentMenusProvider.future);
    await conteneur.read(recentMenusProvider.notifier).retenir(carte('midi', 'Le Comptoir'));
    expect(conteneur.read(recentMenusProvider).valueOrNull?.first.id, 'midi');

    // … puis une nouvelle carte est scannée le soir : c'est elle qui doit se rouvrir.
    await conteneur.read(recentMenusProvider.notifier).retenir(carte('soir', 'The Kitchin'));
    final liste = conteneur.read(recentMenusProvider).valueOrNull!;
    expect(liste.first.id, 'soir');
    expect(liste.map((c) => c.id), ['soir', 'midi']);
  });
}
