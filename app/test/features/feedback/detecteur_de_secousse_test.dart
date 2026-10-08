import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/feedback/domain/detecteur_de_secousse.dart';

void main() {
  final t0 = DateTime(2026, 10, 8, 12);
  DateTime t(int ms) => t0.add(Duration(milliseconds: ms));

  test('un seul à-coup, même fort (téléphone posé vite), n\'ouvre rien', () {
    final d = DetecteurDeSecousse();
    // Le même choc vu par plusieurs mesures rapprochées.
    expect([for (var ms = 0; ms <= 60; ms += 20) d.ajouter(30, t(ms))], everyElement(isFalse));
  });

  test('trois pics francs en moins d\'une seconde : une secousse', () {
    final d = DetecteurDeSecousse();
    expect(d.ajouter(18, t(0)), isFalse);
    expect(d.ajouter(5, t(120)), isFalse);
    expect(d.ajouter(19, t(250)), isFalse);
    expect(d.ajouter(20, t(500)), isTrue);
    // Et la mémoire repart de zéro.
    expect(d.ajouter(20, t(700)), isFalse);
  });

  test('des pics trop espacés, ou trop faibles, ne font pas une secousse', () {
    final d = DetecteurDeSecousse();
    expect(d.ajouter(18, t(0)), isFalse);
    expect(d.ajouter(18, t(700)), isFalse);
    expect(d.ajouter(18, t(1600)), isFalse); // le premier est sorti de la fenêtre
    final faible = DetecteurDeSecousse();
    expect([for (var i = 0; i < 10; i++) faible.ajouter(12, t(i * 150))], everyElement(isFalse));
  });
}
