import '../../auth/domain/palais.dart';
import '../../auth/domain/taste_profile.dart';
import '../../sommelier/domain/profil_du_vin.dart';
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
        compter(4.0, aimee);
      } else {
        compter(-10.0, tr('Pas dans vos couleurs préférées', 'Not one of your favourite styles'));
      }
    }

    // 2. La région ou l'appellation.
    final regions = remplies(profile.favoriteRegions);
    final region = (wine.region ?? '').toLowerCase();
    final appellation = (wine.appellation ?? '').toLowerCase();
    for (final r in regions) {
      final cle = r.toLowerCase();
      if (region.contains(cle) || appellation.contains(cle)) {
        compter(4.0, tr('{region}, l\'une de vos régions préférées', '{region}, one of your favourite regions',
            {'region': r.trim()}));
        break;
      }
    }

    // 3. Le cépage.
    for (final g in remplies(profile.favoriteGrapes)) {
      final cle = g.toLowerCase();
      if (wine.grapes.any((wg) => wg.toLowerCase().contains(cle))) {
        compter(4.0, tr('{cepage}, l\'un de vos cépages préférés', '{cepage}, one of your favourite grapes',
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

    // 5. Le palais de la famille du vin, axe par axe (V2.6 · P5) : un rouge se compare au
    // palais des rouges, un blanc à celui des blancs — douceur, fraîcheur, corps, tanins,
    // boisé, évolution. Proche, des points ; loin, on en perd. Un axe dont on ne sait rien
    // ne dit rien ; un axe deviné pèse un tiers, un axe bien établi plein, comme à table.
    // La phrase dit l'écart tel qu'il est, le poids dit ce qu'il coûte : un vin « un peu plus
    // corsé que ce que vous aimez » peut encore gagner un point.
    final famille = TasteProfile.familleDe(wine.wineType);
    if (famille != null) {
      final palais = profile.palaisPour(famille);
      final vin = ProfilDuVin.deLaCarte(wine);
      for (final axe in AxesDuPalais.de(famille)) {
        final v = vin.sur10(axe);
        if (v == null || !palais.connait(axe)) continue;
        final aime = palais.valeur(axe);
        final ecart = (aime - v).abs();
        final confiance = palais.confianceDe(axe);
        final poids = (0.35 + 0.65 * confiance) * (_poidsDesAxes[axe] ?? 1.0);
        // La douceur se sent par paliers : de sec à demi-sec, deux points sur dix changent
        // de vin.
        final sensible = ecart * (axe == AxesDuPalais.douceur ? 1.6 : 1.0);
        var points = (2.0 * poids * (2.5 - sensible)).clamp(-12.0, 5.0);
        // Un axe seulement deviné peut écarter un vin, pas le rapprocher : ne rien savoir ne
        // doit pas flatter (V2.3 · K5).
        if (confiance == 0 && points > 0.5) points = 0.5;
        // Au demi-point : un écart qui ne pèse presque rien ne s'affiche pas, et le total
        // reste la somme de ce qui s'affiche.
        points = (points * 2).round() / 2;
        if (points != 0) compter(points, _phraseDeLAxe(axe, ecart, v > aime));
      }
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

  /// Ce que pèse chaque axe dans le pourcentage : la douceur et les tanins partagent le
  /// plus les gens ; l'élevage et l'âge, moins.
  static const Map<String, double> _poidsDesAxes = {
    AxesDuPalais.douceur: 1.2,
    AxesDuPalais.tanins: 1.1,
    AxesDuPalais.corps: 1.0,
    AxesDuPalais.fraicheur: 1.0,
    AxesDuPalais.boise: 0.8,
    AxesDuPalais.evolution: 0.7,
  };

  /// L'écart d'un vin à vos goûts sur un axe, en une phrase : proche, un peu, plus, bien plus.
  static String _phraseDeLAxe(String axe, double ecart, bool plus) {
    final bande = ecart <= 1.5 ? 0 : (ecart <= 3 ? 1 : (ecart < 5 ? 2 : 3));
    return switch ((axe, bande, plus)) {
      (AxesDuPalais.tanins, 0, _) => tr('Des tanins comme vous les aimez', 'Tannins the way you like them'),
      (AxesDuPalais.tanins, 1, true) => tr('Un peu plus tannique que ce que vous aimez', 'A little more tannic than you like'),
      (AxesDuPalais.tanins, 1, false) => tr('Un peu moins tannique que ce que vous aimez', 'A little less tannic than you like'),
      (AxesDuPalais.tanins, 2, true) => tr('Plus tannique que ce que vous aimez', 'More tannic than you like'),
      (AxesDuPalais.tanins, 2, false) => tr('Moins tannique que ce que vous aimez', 'Less tannic than you like'),
      (AxesDuPalais.tanins, _, true) => tr('Bien plus tannique que ce que vous aimez', 'Much more tannic than you like'),
      (AxesDuPalais.tanins, _, false) => tr('Bien moins tannique que ce que vous aimez', 'Much less tannic than you like'),
      (AxesDuPalais.corps, 0, _) => tr('Un corps comme vous l\'aimez', 'Body the way you like it'),
      (AxesDuPalais.corps, 1, true) => tr('Un peu plus corsé que ce que vous aimez', 'A little fuller-bodied than you like'),
      (AxesDuPalais.corps, 1, false) => tr('Un peu plus léger que ce que vous aimez', 'A little lighter than you like'),
      (AxesDuPalais.corps, 2, true) => tr('Plus corsé que ce que vous aimez', 'Fuller-bodied than you like'),
      (AxesDuPalais.corps, 2, false) => tr('Plus léger que ce que vous aimez', 'Lighter than you like'),
      (AxesDuPalais.corps, _, true) => tr('Bien plus corsé que ce que vous aimez', 'Much fuller-bodied than you like'),
      (AxesDuPalais.corps, _, false) => tr('Bien plus léger que ce que vous aimez', 'Much lighter than you like'),
      (AxesDuPalais.fraicheur, 0, _) => tr('Une fraîcheur comme vous l\'aimez', 'Freshness the way you like it'),
      (AxesDuPalais.fraicheur, 1, true) => tr('Un peu plus vif que ce que vous aimez', 'A little crisper than you like'),
      (AxesDuPalais.fraicheur, 1, false) => tr('Un peu plus rond que ce que vous aimez', 'A little softer than you like'),
      (AxesDuPalais.fraicheur, 2, true) => tr('Plus vif que ce que vous aimez', 'Crisper than you like'),
      (AxesDuPalais.fraicheur, 2, false) => tr('Plus rond que ce que vous aimez', 'Softer than you like'),
      (AxesDuPalais.fraicheur, _, true) => tr('Bien plus vif que ce que vous aimez', 'Much crisper than you like'),
      (AxesDuPalais.fraicheur, _, false) => tr('Bien plus rond que ce que vous aimez', 'Much softer than you like'),
      (AxesDuPalais.douceur, 0, _) => tr('Une douceur comme vous l\'aimez', 'Sweetness the way you like it'),
      (AxesDuPalais.douceur, 1, true) => tr('Un peu plus doux que ce que vous aimez', 'A little sweeter than you like'),
      (AxesDuPalais.douceur, 1, false) => tr('Un peu plus sec que ce que vous aimez', 'A little drier than you like'),
      (AxesDuPalais.douceur, 2, true) => tr('Plus doux que ce que vous aimez', 'Sweeter than you like'),
      (AxesDuPalais.douceur, 2, false) => tr('Plus sec que ce que vous aimez', 'Drier than you like'),
      (AxesDuPalais.douceur, _, true) => tr('Bien plus doux que ce que vous aimez', 'Much sweeter than you like'),
      (AxesDuPalais.douceur, _, false) => tr('Bien plus sec que ce que vous aimez', 'Much drier than you like'),
      (AxesDuPalais.boise, 0, _) => tr('Un boisé comme vous l\'aimez', 'Oak the way you like it'),
      (AxesDuPalais.boise, 1, true) => tr('Un peu plus boisé que ce que vous aimez', 'A little oakier than you like'),
      (AxesDuPalais.boise, 1, false) => tr('Un peu moins boisé que ce que vous aimez', 'A little less oaky than you like'),
      (AxesDuPalais.boise, 2, true) => tr('Plus boisé que ce que vous aimez', 'Oakier than you like'),
      (AxesDuPalais.boise, 2, false) => tr('Moins boisé que ce que vous aimez', 'Less oaky than you like'),
      (AxesDuPalais.boise, _, true) => tr('Bien plus boisé que ce que vous aimez', 'Much oakier than you like'),
      (AxesDuPalais.boise, _, false) => tr('Bien moins boisé que ce que vous aimez', 'Much less oaky than you like'),
      (AxesDuPalais.evolution, 0, _) => tr('À l\'âge où vous l\'aimez', 'At the age you like'),
      (AxesDuPalais.evolution, 1, true) => tr('Un peu plus évolué que ce que vous aimez', 'A little more mature than you like'),
      (AxesDuPalais.evolution, 1, false) => tr('Un peu plus jeune que ce que vous aimez', 'A little younger than you like'),
      (AxesDuPalais.evolution, 2, true) => tr('Plus évolué que ce que vous aimez', 'More mature than you like'),
      (AxesDuPalais.evolution, 2, false) => tr('Plus jeune que ce que vous aimez', 'Younger than you like'),
      (AxesDuPalais.evolution, _, true) => tr('Bien plus évolué que ce que vous aimez', 'Much more mature than you like'),
      (AxesDuPalais.evolution, _, false) => tr('Bien plus jeune que ce que vous aimez', 'Much younger than you like'),
      _ => AxesDuPalais.nom(axe),
    };
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
