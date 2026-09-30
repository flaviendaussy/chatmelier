import 'package:chatmelier/shared/services/sondage_espace.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le sondage des convives s'espace, se tait et prévient (V2.3 · D1).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Un planificateur d'essai : garde les délais demandés, exécute à la demande.
  late List<Duration> delais;
  late List<void Function()> enAttente;
  SondageEspace sondage(Future<bool> Function() tache, {void Function(bool)? surAlerte}) {
    delais = [];
    enAttente = [];
    return SondageEspace(
      tache: tache,
      etiquette: 'essai',
      surAlerte: surAlerte,
      suivreLeCycleDeVie: false,
      planifier: (d, a) {
        delais.add(d);
        enAttente.add(a);
        return enAttente.length;
      },
      annuler: (_) {},
    );
  }

  Future<void> suivant() async {
    final a = enAttente.removeAt(0);
    a();
    await Future<void>.delayed(Duration.zero);
  }

  test('en bonne santé, toutes les 6 secondes', () async {
    final s = sondage(() async => true);
    s.demarrer();
    await Future<void>.delayed(Duration.zero);
    await suivant();
    expect(delais, [const Duration(seconds: 6), const Duration(seconds: 6)]);
  });

  test('les échecs espacent les essais jusqu\'au plafond, puis tout repart à 6 s', () async {
    var ok = false;
    final s = sondage(() async => ok);
    s.demarrer();
    await Future<void>.delayed(Duration.zero);
    for (var i = 0; i < 5; i++) {
      await suivant();
    }
    expect(delais.map((d) => d.inSeconds), [12, 24, 48, 60, 60, 60]);
    ok = true;
    await suivant();
    expect(delais.last, const Duration(seconds: 6));
    expect(s.echecs, 0);
  });

  test('cinq échecs de suite préviennent l\'écran, le retour aussi', () async {
    var ok = false;
    final alertes = <bool>[];
    final s = sondage(() async => ok, surAlerte: alertes.add);
    s.demarrer();
    await Future<void>.delayed(Duration.zero);
    for (var i = 0; i < 4; i++) {
      await suivant();
    }
    expect(alertes, [true]);
    expect(s.enAlerte, isTrue);
    ok = true;
    s.relancer();
    await Future<void>.delayed(Duration.zero);
    expect(alertes, [true, false]);
  });

  test('une tâche qui lève compte comme un échec, sans rien casser', () async {
    final s = sondage(() async => throw Exception('hors ligne'));
    s.demarrer();
    await Future<void>.delayed(Duration.zero);
    expect(s.echecs, 1);
    expect(delais.single, const Duration(seconds: 12));
  });

  test('arrêté, plus rien ne part', () async {
    var appels = 0;
    final s = sondage(() async {
      appels++;
      return true;
    });
    s.demarrer();
    await Future<void>.delayed(Duration.zero);
    s.arreter();
    await suivant();
    expect(appels, 1);
  });
}
