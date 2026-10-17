import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:chatmelier/features/offline/data/offline_storage_service.dart';

/// Un magasin de préférences qui compte ses écritures.
class _Compteur extends InMemorySharedPreferencesStore {
  _Compteur() : super.empty();
  int ecritures = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    ecritures++;
    return super.setValue(valueType, key, value);
  }
}

/// E7 (17/10) : sur Android, chaque écriture réécrit tout le fichier des préférences
/// (450 Ko) ; la cave et le journal se réenregistraient identiques à chaque rechargement.
void main() {
  test('un cache identique ne se réécrit pas, un cache changé si', () async {
    final compteur = _Compteur();
    SharedPreferencesStorePlatform.instance = compteur;
    SharedPreferences.resetStatic();
    final stockage = OfflineStorageService(await SharedPreferences.getInstance());

    final journal = [
      {'id': 'd1', 'rating': 8.0},
    ];
    await stockage.saveCachedTastings(journal);
    expect(compteur.ecritures, 1);
    await stockage.saveCachedTastings([...journal]);
    expect(compteur.ecritures, 1, reason: 'rien n\'a changé : pas d\'écriture');
    await stockage.saveCachedTastings([...journal, {'id': 'd2', 'rating': 6.0}]);
    expect(compteur.ecritures, 2);
    expect(stockage.getCachedTastings(), hasLength(2));
  });
}
