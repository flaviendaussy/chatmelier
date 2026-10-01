import 'dart:convert';

import 'package:archive/archive.dart';

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

  /// Un dixième suffit : la précision au centième ne déplace aucun classement et
  /// alourdit la matrice du QR, qu'il faut pouvoir scanner d'un téléphone à travers une
  /// table de restaurant.
  static double _d1(double v) => double.parse(v.toStringAsFixed(1));

  /// Compresse et encode un ScannedMenu dans une charge utile URL-safe compacte et optimisée pour QR code
  static String encodeMenuPayload(ScannedMenu menu, {int? longueurMax}) {
    // Sans plafond : seize vins, commentaires du sommelier compris.
    if (longueurMax == null) return _encoder(menu, _selection(menu.wines, 16), avecCommentaires: true);
    // Avec plafond : les commentaires partent d'abord (ce sont eux qui pèsent), puis des
    // vins, jusqu'à tenir. Une carte partielle vaut mieux qu'un QR illisible ; l'invité
    // qui rejoint la table reçoit de toute façon la carte complète du serveur.
    for (final (n, avecCommentaires) in [
      (16, true), (16, false), (12, false), (10, false), (8, false), (6, false), (4, false), (2, false), (1, false),
    ]) {
      final charge = _encoder(menu, _selection(menu.wines, n), avecCommentaires: avecCommentaires);
      if (charge.isNotEmpty && charge.length <= longueurMax) return charge;
    }
    return '';
  }

  /// Au plus [n] vins, en gardant de chaque couleur (blancs et bulles, rouges, autres)
  /// pour que la table ait de quoi choisir.
  static List<MenuWine> _selection(List<MenuWine> wines, int n) {
    if (wines.length <= n) return wines;
    final choisis = <MenuWine>[
      ...wines.where((w) => w.isWhite || w.isSparkling).take((n * 5) ~/ 16),
      ...wines.where((w) => w.isRed).take((n * 6) ~/ 16),
      ...wines.where((w) => !w.isWhite && !w.isSparkling && !w.isRed).take((n * 5) ~/ 16),
    ];
    for (final w in wines) {
      if (choisis.length >= n) break;
      if (!choisis.contains(w)) choisis.add(w);
    }
    return choisis;
  }

  static String _encoder(ScannedMenu menu, List<MenuWine> vins, {required bool avecCommentaires}) {
    try {
      final compactList = vins.map((w) => [
        w.name,
        w.wineType,
        w.bottlePrice != null ? double.parse(w.bottlePrice!.toStringAsFixed(1)) : 0.0,
        w.vintage ?? '',
        w.appellation ?? '',
        w.region ?? '',
        w.tags.take(3).join(','),
        w.isGem ? 1 : 0,
        w.isDeal ? 1 : 0,
        avecCommentaires ? (w.sommelierComment ?? '') : '',
        // Métriques, arrondies au dixième : la précision au centième ne change aucun
        // classement et alourdit la matrice du QR.
        [
          _d1(w.metrics.tannins),
          _d1(w.metrics.acidity),
          _d1(w.metrics.body),
          _d1(w.metrics.fruit),
          _d1(w.metrics.oak),
          _d1(w.metrics.minerality),
          _d1(w.metrics.butteriness),
          _d1(w.metrics.sweetness),
        ],
        w.grapes.take(4).join(','),
        [for (final g in w.glassPrices.take(3)) [g.format, _d1(g.price)]],
      ]).toList();

      final jsonMap = {
        'r': menu.restaurantName.isNotEmpty ? menu.restaurantName : 'Restaurant',
        'w': compactList,
        // La devise : sans elle, l'invité d'une table d'Édimbourg lisait ses prix en
        // euros (29/09).
        if (menu.currency != null) 'c': menu.currency,
      };

      final jsonStr = jsonEncode(jsonMap);
      final bytes = utf8.encode(jsonStr);
      // GZipEncoder du paquet `archive`, et non `gzip` de dart:io : ce dernier lève
      // UnsupportedError une fois compilé par dart2js. `decodeMenuPayload` renvoyait donc
      // null sur TOUT navigateur, et l'invité basculait en silence sur un menu fictif.
      final compressed = GZipEncoder().encode(bytes);
      return base64Url.encode(compressed);
    } catch (_) {
      // Fallback simple base64 si compression échoue
      try {
        final simpleMap = {
          'r': menu.restaurantName.isNotEmpty ? menu.restaurantName : 'Restaurant',
          'w': menu.wines.take(10).map((w) => [w.name, w.wineType, w.bottlePrice ?? 0.0]).toList(),
          if (menu.currency != null) 'c': menu.currency,
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
      // Une charge peut être compressée (cas normal) ou non (repli d'encodage, et
      // anciennes URL). On le décide sur le NOMBRE MAGIQUE gzip — 0x1f 0x8b — et non en
      // attendant qu'un décodeur lève une exception : selon la plateforme, décompresser
      // des octets qui ne sont pas du gzip lève, ou rend une liste vide. Le second cas
      // passait à travers le `catch` et produisait un JSON illisible.
      final estGzip =
          compressed.length > 2 && compressed[0] == 0x1f && compressed[1] == 0x8b;
      List<int> bytes = compressed;
      if (estGzip) {
        try {
          bytes = GZipDecoder().decodeBytes(compressed);
        } catch (_) {
          bytes = compressed;
        }
      }
      final jsonStr = utf8.decode(bytes);
      final dynamic decoded = jsonDecode(jsonStr);

      if (decoded is Map<String, dynamic>) {
        final restaurantName = decoded['r'] as String? ?? 'Restaurant Partagé';
        final rawWines = decoded['w'] as List<dynamic>? ?? [];
        final devise = ScannedMenu.normaliserDevise(decoded['c']);

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

            // Les champs ajoutés en fin de liste : une charge utile ancienne s'arrête
            // avant, et garde donc les valeurs par défaut sans rien casser.
            final metrics = item.length > 10 && item[10] is List
                ? _metriquesDepuis(item[10] as List)
                : const MenuWineRadarMetrics();
            final grapes = item.length > 11 && item[11]?.toString().isNotEmpty == true
                ? item[11].toString().split(',').where((g) => g.isNotEmpty).toList()
                : <String>[];
            final glassPrices = <MenuWineGlassPrice>[];
            if (item.length > 12 && item[12] is List) {
              for (final g in item[12] as List) {
                if (g is List && g.length >= 2) {
                  final prix = double.tryParse(g[1]?.toString() ?? '');
                  if (prix != null && prix > 0) {
                    glassPrices.add(MenuWineGlassPrice(
                        format: g[0]?.toString() ?? 'Verre', price: prix));
                  }
                }
              }
            }

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
              metrics: metrics,
              grapes: grapes,
              glassPrices: glassPrices,
              devise: devise,
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
            currency: devise,
          );
        }
      }
    } catch (_) {
      // Échec de décodage
    }

    return null;
  }

  /// Relit les huit métriques dans l'ordre où elles ont été écrites.
  ///
  /// Une liste plus courte que prévu — charge utile tronquée, version antérieure — laisse
  /// les axes manquants à leur valeur par défaut plutôt que de faire échouer tout le
  /// décodage : perdre un axe vaut mieux que perdre la carte.
  static MenuWineRadarMetrics _metriquesDepuis(List m) {
    double at(int i, double defaut) =>
        i < m.length ? (double.tryParse(m[i]?.toString() ?? '') ?? defaut) : defaut;
    return MenuWineRadarMetrics(
      tannins: at(0, 0.0),
      acidity: at(1, 5.0),
      body: at(2, 5.0),
      fruit: at(3, 5.5),
      oak: at(4, 3.0),
      minerality: at(5, 5.0),
      butteriness: at(6, 0.0),
      sweetness: at(7, 1.5),
    );
  }

  /// La longueur au-delà de laquelle un QR devient trop dense pour être lu d'un
  /// téléphone à travers une table (version 30 environ, 137 modules de côté).
  static const longueurQrMax = 1200;

  /// L'adresse que porte le QR, et le lien partagé.
  ///
  /// Avec un code serveur ([code]), le code SEUL : l'invité lit la carte sur le serveur
  /// (`lire_carte_de_table`). La carte entière dans l'URL dépassait la capacité d'un QR
  /// dès qu'elle portait les commentaires du sommelier — 35 vins, 19 500 bits pour
  /// 18 672 (30/09) — et l'hôte voyait une zone vide à la place du QR.
  ///
  /// Sans code (hôte hors ligne), la carte voyage dans l'URL, réduite jusqu'à tenir dans
  /// [longueurQrMax] caractères.
  ///
  /// Avec un code, le QR ouvre la page invité légère (`web/table/`, V2.3 · F2) : quelques
  /// dizaines de kilo-octets au lieu des 16,5 Mo de l'app Flutter, au moment où l'invité
  /// attend à table. La page renvoie vers [baseUrl] (`?table=`) pour qui veut son compte.
  /// Sans code, la carte voyagée dans l'URL n'est lisible que par l'app : [baseUrl].
  ///
  /// Jamais `?code=` : sur le web, Supabase le prendrait pour le retour d'une connexion
  /// OAuth (PKCE) et tenterait de l'échanger. D'où `t` pour la page, `table` pour l'app.
  static String buildQrUrl({
    required String sessionId,
    required ScannedMenu menu,
    String? code,
    String baseUrl = 'https://chatmelier.github.io/table-consensus',
    String pageInvite = 'https://chatmelier.github.io/table/',
  }) {
    if (code != null && code.trim().isNotEmpty) {
      return '$pageInvite?t=${code.trim().toUpperCase()}';
    }
    final debut = '$baseUrl?session=${sessionId.toUpperCase().trim()}';
    final payload = encodeMenuPayload(menu, longueurMax: longueurQrMax - debut.length - '&data='.length);
    return payload.isEmpty ? debut : '$debut&data=$payload';
  }
}
