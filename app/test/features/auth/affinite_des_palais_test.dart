import 'package:chatmelier/features/auth/domain/affinite_des_palais.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deux palais face à face (V2.6 · P2) : une famille à la fois, et seulement ce qu'on
/// sait des deux.
void main() {
  setUp(() => Langue.code = 'fr');
  tearDown(() => Langue.code = 'fr');

  TasteProfile palais(String nom, Map<String, Map<String, double>> valeurs, {bool moi = false}) => TasteProfile(
        id: nom,
        name: nom,
        isPrimary: moi,
        palais: valeurs,
        observationsPalais: {
          for (final f in valeurs.entries) f.key: {for (final a in f.value.keys) a: 8},
        },
      );

  final moi = palais('Moi', {
    'rouge': {'body': 0.85, 'tannin': 0.8, 'oak': 0.5},
    'blanc': {'acidity': 0.8, 'oak': 0.1},
  }, moi: true);
  final caro = palais('Caro', {
    'rouge': {'body': 0.3, 'tannin': 0.25, 'oak': 0.5},
    'blanc': {'acidity': 0.85, 'oak': 0.05},
  });
  final paul = palais('Paul', {
    'rouge': {'body': 0.8, 'tannin': 0.75},
  });
  final aude = palais('Aude', {
    'rouge': {'oak': 0.9},
  });

  test('deux palais encore devinés ne se comparent pas : pas de « 99 % » inventé', () {
    const a = TasteProfile(id: 'a', name: 'Moi', isPrimary: true);
    const b = TasteProfile(id: 'b', name: 'Caro');
    final r = AffiniteDesPalais.comparer(a, b, 'rouge');
    expect(r.pourcentage, isNull);
    expect(r.axesCompares, 0);
    expect(r.phraseEnCommun, 'Pas encore assez de dégustations des rouges pour vous comparer.');
  });

  test('un écart franc se dit à la personne, dans la famille où il est', () {
    final rouges = AffiniteDesPalais.comparer(moi, caro, 'rouge');
    expect(rouges.ecarts, containsAll(['Vous aimez les rouges plus puissants que Caro', 'Vous aimez les rouges plus tanniques que Caro']));
    expect(rouges.phraseEcarts, endsWith('.'));

    final blancs = AffiniteDesPalais.comparer(moi, caro, 'blanc');
    expect(blancs.ecarts, isEmpty, reason: 'sur les blancs, les deux aiment les vins vifs et sans bois');
    expect(blancs.phraseEnCommun, 'Vous aimez tous les deux les blancs vifs et les blancs sans bois.');
    expect(blancs.pourcentage!, greaterThan(rouges.pourcentage!));
  });

  test('l\'autre aime plus : « … que vous » ; deux proches entre eux : leurs prénoms', () {
    final r = AffiniteDesPalais.comparer(caro, moi, 'rouge');
    expect(r.ecarts, contains('Vous aimez les rouges plus puissants que Caro'), reason: 'l\'ordre des deux ne change pas qui est « vous »');
    expect(AffiniteDesPalais.comparer(moi, aude, 'rouge').ecarts, ['Aude aime les rouges plus boisés que vous']);
    final entreEux = AffiniteDesPalais.comparer(paul, caro, 'rouge');
    expect(entreEux.ecarts, contains('Paul aime les rouges plus puissants que Caro'));
    final proches = AffiniteDesPalais.comparer(paul, moi, 'rouge');
    expect(proches.phraseEnCommun, 'Vous aimez tous les deux les rouges puissants et les tanins fermes.');
    expect(proches.vinIdeal, startsWith('Un rouge charpenté'));
  });

  test('seuls les axes connus des deux comptent', () {
    // Paul n'a rien dit du boisé : il ne compte ni pour ni contre.
    final r = AffiniteDesPalais.comparer(moi, paul, 'rouge');
    expect(r.axesCompares, 2);
  });

  test('en anglais', () {
    Langue.code = 'en';
    final r = AffiniteDesPalais.comparer(moi, caro, 'rouge');
    expect(r.ecarts, contains('You like fuller reds than Caro'));
    expect(AffiniteDesPalais.comparer(moi, aude, 'rouge').ecarts, ['Aude likes oakier reds than you']);
  });
}
