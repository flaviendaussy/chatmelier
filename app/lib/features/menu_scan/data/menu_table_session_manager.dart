import 'dart:convert';
import 'dart:io';
import '../domain/menu_wine.dart';

class MenuTableSessionManager {
  static final Map<String, ScannedMenu> _activeSessions = {};

  /// Enregistre une session en mémoire
  static void registerSession(String sessionId, ScannedMenu menu) {
    _activeSessions[sessionId.toUpperCase().trim()] = menu;
  }

  /// Récupère une session en mémoire
  static ScannedMenu? getSession(String sessionId) {
    return _activeSessions[sessionId.toUpperCase().trim()];
  }

  /// Compresse et encode un ScannedMenu dans une charge utile URL-safe compacte et optimisée pour QR code
  static String encodeMenuPayload(ScannedMenu menu) {
    try {
      final wines = menu.wines;
      final selectedWines = <MenuWine>[];
      if (wines.length <= 16) {
        selectedWines.addAll(wines);
      } else {
        // Sélection diversifiée (blancs/bulles, rouges, rosés/autres) pour garantir une matrice QR légère et rapide à scanner
        final whites = wines.where((w) => w.isWhite || w.isSparkling).take(5);
        final reds = wines.where((w) => w.isRed).take(6);
        final others = wines.where((w) => !w.isWhite && !w.isSparkling && !w.isRed).take(5);
        selectedWines.addAll(whites);
        selectedWines.addAll(reds);
        selectedWines.addAll(others);
        for (final w in wines) {
          if (selectedWines.length >= 16) break;
          if (!selectedWines.contains(w)) selectedWines.add(w);
        }
      }

      final compactList = selectedWines.map((w) => [
        w.name,
        w.wineType,
        w.bottlePrice != null ? double.parse(w.bottlePrice!.toStringAsFixed(1)) : 0.0,
        w.vintage ?? '',
        w.appellation ?? '',
        w.region ?? '',
        w.tags.take(3).join(','),
        w.isGem ? 1 : 0,
        w.isDeal ? 1 : 0,
        w.sommelierComment ?? '',
      ]).toList();

      final jsonMap = {
        'r': menu.restaurantName.isNotEmpty ? menu.restaurantName : 'Restaurant',
        'w': compactList,
      };

      final jsonStr = jsonEncode(jsonMap);
      final bytes = utf8.encode(jsonStr);
      final compressed = gzip.encode(bytes);
      return base64Url.encode(compressed);
    } catch (_) {
      // Fallback simple base64 si compression échoue
      try {
        final simpleMap = {
          'r': menu.restaurantName.isNotEmpty ? menu.restaurantName : 'Restaurant',
          'w': menu.wines.take(10).map((w) => [w.name, w.wineType, w.bottlePrice ?? 0.0]).toList(),
        };
        return base64Url.encode(utf8.encode(jsonEncode(simpleMap)));
      } catch (_) {
        return '';
      }
    }
  }

  /// Décode une charge utile URL en ScannedMenu
  static ScannedMenu? decodeMenuPayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) return null;

    try {
      var sanitized = rawPayload.replaceAll(' ', '+').trim();
      final remainder = sanitized.length % 4;
      if (remainder > 0) {
        sanitized += '=' * (4 - remainder);
      }

      // 1. Tenter décompression gzip + base64Url
      List<int> compressed;
      try {
        compressed = base64Url.decode(sanitized);
      } catch (_) {
        compressed = base64.decode(sanitized);
      }
      List<int> bytes;
      try {
        bytes = gzip.decode(compressed);
      } catch (_) {
        bytes = compressed;
      }
      final jsonStr = utf8.decode(bytes);
      final dynamic decoded = jsonDecode(jsonStr);

      if (decoded is Map<String, dynamic>) {
        final restaurantName = decoded['r'] as String? ?? 'Restaurant Partagé';
        final rawWines = decoded['w'] as List<dynamic>? ?? [];

        final wines = <MenuWine>[];
        for (final item in rawWines) {
          if (item is List && item.isNotEmpty) {
            final name = item[0]?.toString() ?? 'Vin';
            final type = item.length > 1 ? item[1]?.toString() ?? 'Rouge' : 'Rouge';
            final price = item.length > 2 ? (double.tryParse(item[2]?.toString() ?? '') ?? 0.0) : 0.0;
            final vintage = item.length > 3 && item[3]?.toString().isNotEmpty == true ? int.tryParse(item[3].toString()) : null;
            final appellation = item.length > 4 && item[4]?.toString().isNotEmpty == true ? item[4].toString() : null;
            final region = item.length > 5 && item[5]?.toString().isNotEmpty == true ? item[5].toString() : null;
            final tags = item.length > 6 && item[6] != null && item[6].toString().isNotEmpty
                ? item[6].toString().split(',').where((t) => t.isNotEmpty).toList()
                : <String>[];
            final isGem = item.length > 7 ? (item[7] == 1 || item[7] == '1' || item[7] == true) : false;
            final isDeal = item.length > 8 ? (item[8] == 1 || item[8] == '1' || item[8] == true) : false;
            final sommelierComment = item.length > 9 && item[9]?.toString().isNotEmpty == true ? item[9].toString() : null;

            wines.add(MenuWine(
              id: 'decoded_${wines.length}',
              name: name,
              producer: region ?? appellation ?? name,
              wineType: type,
              bottlePrice: price > 0 ? price : null,
              vintage: vintage,
              appellation: appellation,
              region: region,
              tags: tags,
              isGem: isGem,
              isDeal: isDeal,
              sommelierComment: sommelierComment,
            ));
          }
        }

        if (wines.isNotEmpty) {
          return ScannedMenu(
            id: 'decoded_${DateTime.now().millisecondsSinceEpoch}',
            restaurantName: restaurantName,
            pagePhotoPaths: const [],
            wines: wines,
            scannedAt: DateTime.now(),
          );
        }
      }
    } catch (_) {
      // Échec de décodage
    }

    return null;
  }

  /// Génère l'URL complète pour le QR Code avec session et données embarquées
  static String buildQrUrl({
    required String sessionId,
    required ScannedMenu menu,
    String baseUrl = 'https://chatmelier.github.io/table-consensus',
  }) {
    final payload = encodeMenuPayload(menu);
    final normSession = sessionId.toUpperCase().trim();
    if (payload.isNotEmpty) {
      return '$baseUrl?session=$normSession&data=$payload';
    }
    return '$baseUrl?session=$normSession';
  }
}
