import '../../auth/domain/taste_profile.dart';
import '../../../shared/utils/langue.dart';
import 'menu_wine.dart';

/// Une raison du pourcentage « pour vous » : ce qu'elle dit, et ce qu'elle a pesé.
class RaisonDuScore {
  final String phrase;
  final double points;
  const RaisonDuScore(this.phrase, this.points);
}

/// Pourquoi un vin de la carte vous va, ou non (V2.5 · F1).
///
/// 13/10, Flavien : « ça m'affiche "taillé pour vous". je devrais pouvoir cliquer sur chaque
/// vin pour savoir pourquoi un vin est taillé pour moi ou pas ». L'explication est le calcul
/// lui-même, pas un récit après coup : chaque raison est un terme de la somme, et le
/// pourcentage affiché en est le total. Une raison qu'on ne pourrait pas compter ne
/// s'affiche pas.
class ExplicationDuScore {
  /// Tout vin part de là ; les raisons l'éloignent ou le rapprochent de vos goûts.
  static const depart = 70.0;
  static const plancher = 35.0;
  static const plafond = 99.0;

  /// Le seuil de « Taillé pour vous », celui du drapeau de la carte.
  static const seuilTaillePourVous = 78.0;

  /// Le pourcentage, borné et arrondi.
  final double score;

  /// La somme avant bornes : au-delà de 99 ou en deçà de 35, le pourcentage est ramené.
  final double brut;

  /// Les raisons, de la plus lourde à la plus légère ; celles qui ne pèsent rien n'y sont pas.
  final List<RaisonDuScore> raisons;

  const ExplicationDuScore({required this.score, required this.brut, required this.raisons});

  bool get borne => brut != score && (brut > plafond || brut < plancher);

  /// Le verdict en quelques mots, du même seuil que le drapeau « Taillé pour vous ».
  static String verdict(double score) {
    if (score >= seuilTaillePourVous) return tr('Taillé pour vous', 'Made for you');
    if (score >= 65) return tr('Proche de vos goûts', 'Close to your taste');
    if (score >= 50) return tr('Un peu loin de vos goûts', 'A little far from your taste');
    return tr('Loin de vos goûts', 'Far from your taste');
  }

  /// Le calcul de `MenuWineMatchCalculator`, raison par raison. Nul quand le palais n'est
  /// pas assez renseigné pour juger : on ne devine pas un accord.
  static ExplicationDuScore? expliquer(MenuWine wine, TasteProfile? profile) {
    if (profile == null || !profile.isWellProvided) return null;
    final raisons = <RaisonDuScore>[];
    var score = depart;
    void compter(double points, String phrase) {
      score += points;
      raisons.add(RaisonDuScore(phrase, points));
    }

    // Une préférence vide (« ») contenait tout vin : chaque vin gagnait la région ou le
    // cépage « préféré ». Elle ne compte plus.
    List<String> remplies(List<String> l) => [for (final x in l) if (x.trim().isNotEmpty) x];

    // 1. La couleur.
    final types = remplies(profile.favoriteTypes);
    if (types.isNotEmpty) {
      final aimee = _couleurAimee(wine, types.map((t) => t.toLowerCase()));
      if (aimee != null) {
        compter(15.0, aimee);
      } else {
        compter(-20.0, tr('Pas dans vos couleurs préférées', 'Not one of your favourite styles'));
      }
    }

    // 2. La région ou l'appellation.
    final regions = remplies(profile.favoriteRegions);
    final region = (wine.region ?? '').toLowerCase();
    final appellation = (wine.appellation ?? '').toLowerCase();
    for (final r in regions) {
      final cle = r.toLowerCase();
      if (region.contains(cle) || appellation.contains(cle)) {
        compter(12.0, tr('{region}, l\'une de vos régions préférées', '{region}, one of your favourite regions',
            {'region': r.trim()}));
        break;
      }
    }

    // 3. Le cépage.
    for (final g in remplies(profile.favoriteGrapes)) {
      final cle = g.toLowerCase();
      if (wine.grapes.any((wg) => wg.toLowerCase().contains(cle))) {
        compter(10.0, tr('{cepage}, l\'un de vos cépages préférés', '{cepage}, one of your favourite grapes',
            {'cepage': g.trim()}));
        break;
      }
    }

    // 4. Ce que vous n'aimez pas.
    for (final d in profile.dislikedCharacteristics.map((d) => d.toLowerCase())) {
      if (d.contains('tann') && wine.metrics.tannins > 7.0) {
        compter(-25.0, tr('Des tanins marqués, que vous n\'aimez pas', 'Firm tannins, which you don\'t like'));
      }
      if (d.contains('bois') && wine.metrics.oak > 7.0) {
        compter(-25.0, tr('Un boisé marqué, que vous n\'aimez pas', 'Pronounced oak, which you don\'t like'));
      }
      if (d.contains('acid') && wine.metrics.acidity > 7.5) {
        compter(-20.0, tr('Une acidité vive, que vous n\'aimez pas', 'Sharp acidity, which you don\'t like'));
      }
      if (d.contains('sucr') && wine.metrics.sweetness > 4.0) {
        compter(-20.0, tr('Du sucre, que vous n\'aimez pas', 'Sweetness, which you don\'t like'));
      }
    }

    // 5. Les tanins et le corps que vous aimez : proches, des points ; loin, on en perd.
    // La phrase dit l'écart tel qu'il est, le poids dit ce qu'il coûte : un vin « plus
    // corsé que ce que vous aimez » peut encore gagner un point, s'il reste dans vos goûts.
    if (profile.avgTanninPreference != null && wine.isRed) {
      final aime = profile.avgTanninPreference! * 10;
      final ecart = (aime - wine.metrics.tannins).abs();
      final plus = wine.metrics.tannins > aime;
      compter(
          (5.0 - ecart).clamp(-10.0, 8.0),
          switch (ecart) {
            <= 1.5 => tr('Des tanins comme vous les aimez', 'Tannins the way you like them'),
            <= 3 => plus
                ? tr('Un peu plus tannique que ce que vous aimez', 'A little more tannic than you like')
                : tr('Un peu moins tannique que ce que vous aimez', 'A little less tannic than you like'),
            < 5 => plus
                ? tr('Plus tannique que ce que vous aimez', 'More tannic than you like')
                : tr('Moins tannique que ce que vous aimez', 'Less tannic than you like'),
            _ => plus
                ? tr('Bien plus tannique que ce que vous aimez', 'Much more tannic than you like')
                : tr('Bien moins tannique que ce que vous aimez', 'Much less tannic than you like'),
          });
    }
    if (profile.avgBodyPreference != null) {
      final aime = profile.avgBodyPreference! * 10;
      final ecart = (aime - wine.metrics.body).abs();
      final plus = wine.metrics.body > aime;
      compter(
          (5.0 - ecart).clamp(-10.0, 8.0),
          switch (ecart) {
            <= 1.5 => tr('Un corps comme vous l\'aimez', 'Body the way you like it'),
            <= 3 => plus
                ? tr('Un peu plus corsé que ce que vous aimez', 'A little fuller-bodied than you like')
                : tr('Un peu plus léger que ce que vous aimez', 'A little lighter than you like'),
            < 5 => plus
                ? tr('Plus corsé que ce que vous aimez', 'Fuller-bodied than you like')
                : tr('Plus léger que ce que vous aimez', 'Lighter than you like'),
            _ => plus
                ? tr('Bien plus corsé que ce que vous aimez', 'Much fuller-bodied than you like')
                : tr('Bien plus léger que ce que vous aimez', 'Much lighter than you like'),
          });
    }

    // Une même raison comptée deux fois (deux aversions au tanin) ne s'affiche qu'une fois,
    // avec son poids total.
    final parPhrase = <String, double>{};
    for (final r in raisons) {
      parPhrase[r.phrase] = (parPhrase[r.phrase] ?? 0) + r.points;
    }
    final fusionnees = [
      for (final x in parPhrase.entries)
        if (x.value != 0) RaisonDuScore(x.key, x.value),
    ]..sort((a, b) => b.points.abs().compareTo(a.points.abs()));

    return ExplicationDuScore(
      score: score.clamp(plancher, plafond).roundToDouble(),
      brut: score,
      raisons: fusionnees,
    );
  }

  /// La couleur du vin parmi les préférées, dite comme une raison ; nulle sinon.
  static String? _couleurAimee(MenuWine wine, Iterable<String> types) {
    for (final t in types) {
      if (wine.isRed && t.contains('rouge')) return tr('Vous aimez les rouges', 'You like reds');
      if (wine.isWhite && t.contains('blanc')) return tr('Vous aimez les blancs', 'You like whites');
      if (wine.isRose && t.contains('rosé')) return tr('Vous aimez les rosés', 'You like rosés');
      if (wine.isSparkling && (t.contains('bulles') || t.contains('champ'))) {
        return tr('Vous aimez les bulles', 'You like sparkling wines');
      }
    }
    return null;
  }
}
