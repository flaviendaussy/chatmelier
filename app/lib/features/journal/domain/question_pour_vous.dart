import '../../auth/domain/palais.dart';
import '../../auth/domain/taste_profile.dart';
import '../../sommelier/domain/profil_du_vin.dart';

/// La question « pour vous » d'une dégustation (V2.6 · P6) : trop, juste ou pas assez, sur
/// l'axe qui apprendrait le plus.
///
/// Elle remplace les curseurs de la bouche. Décrire un vin (« acidité 7 sur 10 ») demande
/// de savoir déguster et ne dit pas si on a aimé ; « trop vif pour moi » se dit sans rien
/// savoir, et place la préférence d'un coup.
class QuestionPourVous {
  QuestionPourVous._();

  /// Combien de questions d'emblée : trois. Une seule n'en apprenait pas assez (Flavien,
  /// 22/10 : « ajoute plus de questions »), quatre en disaient trop (Caro : « 3 questions
  /// c'est suffisant »). Les autres restent à portée, sous « Aller plus loin ».
  static const int dEmblee = 3;

  /// Les axes qu'on peut demander pour une famille, dans l'ordre où ils départagent deux
  /// axes aussi utiles. La douceur d'un rouge ne se demande pas (presque tous sont secs) ;
  /// l'âge non plus, il se lit sur le millésime. Le bois ne se demande pas sur un rosé ni sur
  /// une bulle, qui n'en voient presque jamais (Flavien, 22/10, sur un Douro rosé : « pas très
  /// applicable ici »).
  static List<String> axes(String famille, {bool sansBois = false}) => [
        for (final a in famille == FamillesDeVins.rouge
            ? const [AxesDuPalais.tanins, AxesDuPalais.corps, AxesDuPalais.fraicheur, AxesDuPalais.boise]
            : const [AxesDuPalais.douceur, AxesDuPalais.fraicheur, AxesDuPalais.corps, AxesDuPalais.boise])
          if (!(sansBois && a == AxesDuPalais.boise)) a,
      ];

  /// Le bois se tait pour ces couleurs (`couleurDuQuestionnaire`).
  static bool sansBoisPour(String couleur) => couleur == 'rose' || couleur == 'sparkling';

  /// Les axes du plus utile au moins utile : le moins connu du palais d'abord, surtout là où
  /// le vin tranche — un vin très boisé est la bonne occasion de demander le bois, quel qu'en
  /// soit le verdict.
  static List<String> ordre(TasteProfile profil, String famille, ProfilDuVin vin, {bool sansBois = false}) {
    final candidats = axes(famille, sansBois: sansBois);
    double priorite(String axe) {
      final neutre = AxesDuPalais.neutre(famille, axe) / 10;
      final tranche = ((vin.valeur(axe) ?? neutre) - neutre).abs();
      return (1 - profil.confianceSur(famille, axe)) * (1 + 2 * tranche);
    }

    final rangs = {for (var i = 0; i < candidats.length; i++) candidats[i]: i};
    return [...candidats]..sort((a, b) {
        final d = priorite(b) - priorite(a);
        if (d.abs() > 1e-9) return d > 0 ? 1 : -1;
        return rangs[a]!.compareTo(rangs[b]!);
      });
  }

  /// L'axe à demander d'abord.
  static String aDemander(TasteProfile profil, String famille, ProfilDuVin vin, {bool sansBois = false}) =>
      ordre(profil, famille, vin, sansBois: sansBois).first;

  /// Les autres axes, dans l'ordre de [axes].
  static List<String> autres(String famille, String premier, {bool sansBois = false}) =>
      [for (final a in axes(famille, sansBois: sansBois)) if (a != premier) a];
}
