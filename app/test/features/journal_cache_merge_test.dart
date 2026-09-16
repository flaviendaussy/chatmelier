import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/offline/data/offline_storage_service.dart';

/// Vérifie la règle qui distingue « pas encore synchronisée » de « supprimée ailleurs ».
///
/// Constaté sur appareil : une dégustation supprimée en base restait affichée
/// indéfiniment dans le journal. La fusion (`journal_screen.dart`) considérait toute
/// entrée du cache absente du serveur comme locale et non synchronisée, donc à conserver.
/// Combiné à l'absence de suppression dans l'app, une dégustation saisie par erreur
/// devenait définitive.
///
/// Réplique de la règle de fusion : le but n'est pas de tester le provider (qui exige
/// Supabase) mais la PROPRIÉTÉ qu'il doit avoir.
bool _looksLikeUuid(String id) => RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);

bool conserver(Map<String, dynamic> entree, Set<String> idsServeur) {
  final id = entree['id']?.toString();
  if (id == null || id.isEmpty || idsServeur.contains(id)) return false;
  if (entree[OfflineStorageService.pendingSyncKey] == true) return true;
  return !_looksLikeUuid(id);
}

void main() {
  const uuid = '3f2a1b4c-5d6e-4f70-8a91-b2c3d4e5f607';
  const horodate = '1757900000000';

  group('🗑️ Une dégustation supprimée doit disparaître', () {
    test('une entrée venue du serveur, absente du serveur, est supprimée', () {
      expect(conserver({'id': uuid}, <String>{}), isFalse,
          reason: 'C\'est le défaut constaté : elle restait affichée pour toujours.');
    });

    test('une entrée marquée en attente survit à son absence du serveur', () {
      expect(
        conserver({'id': uuid, OfflineStorageService.pendingSyncKey: true}, <String>{}),
        isTrue,
        reason: 'Sinon on perdrait une dégustation saisie hors ligne.',
      );
    });

    test('un identifiant horodaté vaut marqueur pour les caches antérieurs', () {
      expect(conserver({'id': horodate}, <String>{}), isTrue,
          reason: 'Fabriqué par l\'app, jamais passé par la base : à conserver malgré '
              'l\'absence du marqueur, qui n\'existait pas encore.');
    });

    test('une entrée encore présente côté serveur n\'est pas dupliquée', () {
      expect(conserver({'id': uuid}, {uuid}), isFalse);
      expect(
        conserver({'id': uuid, OfflineStorageService.pendingSyncKey: true}, {uuid}),
        isFalse,
        reason: 'Une fois synchronisée, la version serveur fait foi.',
      );
    });

    test('une entrée sans identifiant est ignorée', () {
      expect(conserver({'id': ''}, <String>{}), isFalse);
      expect(conserver(<String, dynamic>{}, <String>{}), isFalse);
    });
  });
}
