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

  /// Les axes qu'on peut demander pour une famille, dans l'ordre où ils départagent deux
  /// axes aussi utiles. La douceur d'un rouge ne se demande pas (presque tous sont secs) ;
  /// l'âge non plus, il se lit sur le millésime.
  static List<String> axes(String famille) => famille == FamillesDeVins.rouge
      ? const [AxesDuPalais.tanins, AxesDuPalais.corps, AxesDuPalais.fraicheur, AxesDuPalais.boise]
      : const [AxesDuPalais.douceur, AxesDuPalais.fraicheur, AxesDuPalais.corps, AxesDuPalais.boise];

  /// L'axe à demander d'abord : le moins connu du palais, surtout là où le vin tranche — un
  /// vin très boisé est la bonne occasion de demander le bois, quel qu'en soit le verdict.
  static String aDemander(TasteProfile profil, String famille, ProfilDuVin vin) {
    final candidats = axes(famille);
    double priorite(String axe) {
      final neutre = AxesDuPalais.neutre(famille, axe) / 10;
      final tranche = ((vin.valeur(axe) ?? neutre) - neutre).abs();
      return (1 - profil.confianceSur(famille, axe)) * (1 + 2 * tranche);
    }

    var meilleur = candidats.first;
    for (final axe in candidats.skip(1)) {
      if (priorite(axe) > priorite(meilleur) + 1e-9) meilleur = axe;
    }
    return meilleur;
  }

  /// Les autres axes, à préciser si l'on veut, dans l'ordre de [axes].
  static List<String> autres(String famille, String premier) => [for (final a in axes(famille)) if (a != premier) a];
}
