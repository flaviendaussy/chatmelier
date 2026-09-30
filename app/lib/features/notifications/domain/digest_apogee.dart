import '../../../shared/utils/langue.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';

/// Le rendez-vous hebdomadaire d'apogée (V2.3 · D5).
///
/// Le canal « Apogée & Maturité » existait, la préférence aussi, et la fonction serveur
/// s'arrêtait sur « brancher ici un service de notifications » : rien ne prévenait jamais
/// qu'un vin arrivait à son moment. Ce que demandaient les caves de 150 bouteilles et plus,
/// c'est précisément ça : « dites-moi quoi boire avant qu'il ne soit trop tard ».
///
/// Une notification par semaine au plus, le dimanche en fin d'après-midi, qui nomme les vins.
/// Le jugement vient de [Wine.windowStatus], le seul calcul de fenêtre de l'app.
class DigestApogee {
  /// Les bouteilles à boire maintenant : d'abord celles dont la fenêtre se referme (ou s'est
  /// refermée), puis celles à leur apogée. Les spiritueux et vins mutés, qu'on suit au niveau
  /// plutôt qu'à l'apogée, n'en font pas partie.
  static List<Bottle> aBoire(List<Bottle> bouteilles) {
    int rang(DrinkWindowStatus s) => switch (s) {
          DrinkWindowStatus.pastPeak => 0,
          DrinkWindowStatus.drinkSoon => 1,
          DrinkWindowStatus.inPeak => 2,
          _ => 9,
        };
    final retenues = <(Bottle, int)>[];
    for (final b in bouteilles) {
      final w = b.wine;
      if (b.isConsumed || b.quantity <= 0 || w == null || w.tracksFillLevel) continue;
      final r = rang(w.windowStatus);
      if (r < 9) retenues.add((b, r));
    }
    retenues.sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final r in retenues) r.$1];
  }

  /// Le titre et le texte de la notification, ou `null` s'il n'y a rien à dire.
  static (String, String)? message(List<Bottle> aBoire) {
    if (aBoire.isEmpty) return null;
    final noms = [
      for (final b in aBoire.take(3))
        [b.wine!.name, if (b.wine!.vintage != null) '${b.wine!.vintage}'].join(' '),
    ];
    final reste = aBoire.length - noms.length;
    final urgent = aBoire.first.wine!.windowStatus != DrinkWindowStatus.inPeak;
    final titre = aBoire.length == 1
        ? tr('🍷 Un vin à ouvrir', '🍷 A wine to open')
        : tr('🍷 {aBoire_length} vins à ouvrir', '🍷 {aBoire_length} wines to open', {'aBoire_length': aBoire.length});
    final liste = reste > 0
        ? (reste > 1
            ? tr('{noms} et {reste} autres', '{noms} and {reste} more', {'noms': noms.join(', '), 'reste': reste})
            : tr('{noms} et 1 autre', '{noms} and 1 more', {'noms': noms.join(', ')}))
        : noms.join(', ');
    final corps = urgent
        ? tr('{liste} : leur fenêtre se referme, c\'est le moment.', '{liste}: their window is closing, now is the time.', {'liste': liste})
        : tr('{liste} : à leur apogée en ce moment.', '{liste}: at their peak right now.', {'liste': liste});
    return (titre, corps);
  }

  /// Le prochain dimanche à 18 h (heure locale), au moins une heure après [maintenant].
  static DateTime prochainRendezVous(DateTime maintenant) {
    var jour = DateTime(maintenant.year, maintenant.month, maintenant.day, 18);
    while (jour.weekday != DateTime.sunday || jour.isBefore(maintenant.add(const Duration(hours: 1)))) {
      jour = DateTime(jour.year, jour.month, jour.day + 1, 18);
    }
    return jour;
  }
}
