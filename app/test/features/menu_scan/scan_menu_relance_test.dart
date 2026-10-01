import 'dart:async';

import 'package:chatmelier/features/menu_scan/data/menu_scan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Le scan de carte lancé pendant la pub (29/09).
///
/// Deux scans sont restés figés jusqu'au délai de 150 s pendant que le reste de l'app
/// parlait au même serveur : une requête perdue, pas un serveur lent. Une page silencieuse
/// est donc relancée sur une connexion neuve, et la première réponse l'emporte — sans
/// jamais rallonger l'attente totale.
void main() {
  const total = Duration(milliseconds: 400);
  const relance = Duration(milliseconds: 60);

  test('une requête perdue est relancée, et la relance répond', () async {
    var appels = 0;
    var relances = 0;
    final debut = DateTime.now();
    final r = await MenuScanService.appelerAvecRelance<String>(
      (delai) {
        appels++;
        // La première se tait jusqu'à son délai ; la seconde répond vite.
        return appels == 1
            ? Completer<String>().future.timeout(delai)
            : Future.delayed(const Duration(milliseconds: 20), () => 'carte');
      },
      total: total,
      relance: relance,
      siRelance: () => relances++,
    );
    expect(r, 'carte');
    expect(appels, 2);
    expect(relances, 1);
    expect(DateTime.now().difference(debut), lessThan(total),
        reason: 'la relance répond avant que la première n\'expire');
  });

  test('une réponse avant le délai de relance : un seul appel', () async {
    var appels = 0;
    final r = await MenuScanService.appelerAvecRelance<String>(
      (delai) {
        appels++;
        return Future.delayed(const Duration(milliseconds: 10), () => 'carte');
      },
      total: total,
      relance: relance,
    );
    expect(r, 'carte');
    await Future<void>.delayed(relance * 2);
    expect(appels, 1, reason: 'pas de second appel facturé quand le premier a répondu');
  });

  test('une réponse d\'erreur du serveur (429, HTTP 5xx) remonte sans relance', () async {
    var appels = 0;
    await expectLater(
      MenuScanService.appelerAvecRelance<String>(
        (delai) {
          appels++;
          return Future.error(http.ClientException('scan-menu HTTP 502 : passerelle'));
        },
        total: total,
        relance: relance,
        estUneCoupure: MenuScanService.estUneCoupure,
        tempsMinimal: Duration.zero,
        pauseApresCoupure: Duration.zero,
      ),
      throwsA(isA<http.ClientException>()),
    );
    await Future<void>.delayed(relance * 2);
    expect(appels, 1);
  });

  // 01/10 : une page morte vingt secondes après le départ, pendant la vidéo.
  test('une coupure de connexion est retentée tout de suite, sur une connexion neuve', () async {
    var appels = 0;
    Object? coupure;
    final debut = DateTime.now();
    final r = await MenuScanService.appelerAvecRelance<String>(
      (delai) {
        appels++;
        return appels == 1
            ? Future.delayed(const Duration(milliseconds: 10),
                () => throw http.ClientException('Software caused connection abort'))
            : Future.delayed(const Duration(milliseconds: 10), () => 'carte');
      },
      total: total,
      relance: relance,
      estUneCoupure: MenuScanService.estUneCoupure,
      siCoupure: (e) => coupure = e,
      tempsMinimal: Duration.zero,
      pauseApresCoupure: Duration.zero,
    );
    expect(r, 'carte');
    expect(appels, 2);
    expect(coupure, isA<http.ClientException>());
    expect(DateTime.now().difference(debut), lessThan(relance),
        reason: 'sans attendre le délai de relance');
    await Future<void>.delayed(relance * 2);
    expect(appels, 2, reason: 'une seule seconde tentative : le minuteur est annulé');
  });

  test('après une coupure, la seconde tentative attend que le réseau se rétablisse', () async {
    final departs = <DateTime>[];
    final r = await MenuScanService.appelerAvecRelance<String>(
      (delai) {
        departs.add(DateTime.now());
        return departs.length == 1
            ? Future.error(http.ClientException('Network is unreachable'))
            : Future.value('carte');
      },
      total: const Duration(seconds: 2),
      relance: const Duration(seconds: 1),
      estUneCoupure: MenuScanService.estUneCoupure,
      tempsMinimal: Duration.zero,
      pauseApresCoupure: const Duration(milliseconds: 120),
    );
    expect(r, 'carte');
    expect(departs[1].difference(departs[0]), greaterThanOrEqualTo(const Duration(milliseconds: 110)));
  });

  test('deux coupures : l\'erreur remonte, sans troisième appel', () async {
    var appels = 0;
    await expectLater(
      MenuScanService.appelerAvecRelance<String>(
        (delai) {
          appels++;
          return Future.error(http.ClientException('Connection reset by peer'));
        },
        total: total,
        relance: relance,
        estUneCoupure: MenuScanService.estUneCoupure,
        tempsMinimal: Duration.zero,
        pauseApresCoupure: Duration.zero,
      ),
      throwsA(isA<http.ClientException>()),
    );
    await Future<void>.delayed(relance * 2);
    expect(appels, 2);
  });

  test('si les deux échouent, l\'erreur remonte au plus tard au délai total', () async {
    final debut = DateTime.now();
    await expectLater(
      MenuScanService.appelerAvecRelance<String>(
        (delai) => Completer<String>().future.timeout(delai),
        total: total,
        relance: relance,
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(DateTime.now().difference(debut), lessThan(total + const Duration(milliseconds: 150)),
        reason: 'la relance s\'arrête avec la première : l\'attente n\'est jamais rallongée');
  });

  test('la première réponse l\'emporte même si l\'autre échoue ensuite', () async {
    var appels = 0;
    final r = await MenuScanService.appelerAvecRelance<String>(
      (delai) {
        appels++;
        return appels == 1
            ? Future.delayed(const Duration(milliseconds: 100), () => 'premiere')
            : Future.delayed(const Duration(milliseconds: 200), () => throw Exception('tardive'));
      },
      total: total,
      relance: relance,
    );
    expect(r, 'premiere');
    // Laisser l'échec tardif arriver : il ne doit rien casser.
    await Future<void>.delayed(const Duration(milliseconds: 250));
  });
}
