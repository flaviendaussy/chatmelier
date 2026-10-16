import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:flutter_test/flutter_test.dart';

/// « La phrase "Moi apprécie davantage…" est grammaticalement incorrecte : quand Chatmelier
/// parle à l'utilisateur (affiché "Moi"), il doit le vouvoyer » (Flavien, 13/10).
void main() {
  const moi = TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, avgTanninPreference: 0.9);
  const caro = TasteProfile(id: 'caro', name: 'Caro', avgTanninPreference: 0.2, avgAcidityPreference: 0.9);

  test('le profil principal est « vous », jamais « Moi apprécie »', () {
    final fr = WineTasteRadarCalculator.compare(moi, caro, 'fr').divergencesSummary;
    expect(fr, contains('Vous appréciez davantage'));
    expect(fr, contains('que Caro'));
    expect(fr, isNot(contains('Moi apprécie')));
    expect(fr, isNot(contains('que Moi')));
    // Dans l'autre sens : « Caro apprécie davantage… que vous ».
    expect(fr, contains('Caro apprécie davantage'));
    expect(fr, contains('que vous'));
  });

  test('en anglais, en espagnol et en italien aussi', () {
    final en = WineTasteRadarCalculator.compare(caro, moi, 'en').divergencesSummary;
    expect(en, contains('You appreciate'));
    expect(en, contains('more than you'));
    expect(en, isNot(contains('Moi ')));
    final es = WineTasteRadarCalculator.compare(moi, caro, 'es').divergencesSummary;
    expect(es, contains('Aprecias más'));
    final it = WineTasteRadarCalculator.compare(moi, caro, 'it').divergencesSummary;
    expect(it, contains('Ti piace di più'));
  });

  test('entre deux autres profils, leurs prénoms', () {
    const paul = TasteProfile(id: 'paul', name: 'Paul', avgTanninPreference: 0.9);
    final fr = WineTasteRadarCalculator.compare(paul, caro, 'fr').divergencesSummary;
    expect(fr, contains('Paul apprécie davantage'));
  });
}
