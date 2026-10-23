import 'package:shared_preferences/shared_preferences.dart';

/// Express ou Sommelier, retenu d'une dégustation à l'autre (22/10).
///
/// Caro s'en tient à trois questions, Flavien veut décrire le vin : chacun choisit une fois,
/// et l'app ne repose plus la question à chaque verre — c'était l'une des quatre pastilles
/// empilées en tête du questionnaire, avant la première question.
class FormatDuQuestionnaire {
  FormatDuQuestionnaire._();

  static const _cle = 'questionnaire_format_express_v1';

  /// Express par défaut : la note et trois questions, une minute.
  static Future<bool> express() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_cle) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> retenir({required bool express}) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_cle, express);
    } catch (_) {}
  }
}
