import 'package:flutter/material.dart';

import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import 'fil_d_ariane.dart';

/// Ce qu'un retour emporte pour se suffire presque sans capture (16/10, Flavien : « tu
/// devrais avoir assez de metadata lors de la remontée pour presque pouvoir te passer de
/// photo ») : l'écran, les derniers pas, le réseau, les derniers avertissements. Jamais le
/// contenu de ce que la personne a tapé ou lu — des adresses d'écran, des étiquettes, des
/// messages d'erreur tronqués (règle B4).
class ContexteDuRetour {
  const ContexteDuRetour._();

  /// Les avertissements et erreurs des dix dernières minutes, les plus récents en dernier.
  static List<String> erreursRecentes({DateTime? maintenant, int nombre = 6}) {
    final depuis = (maintenant ?? DateTime.now()).subtract(const Duration(minutes: 10));
    final retenues = [
      for (final e in AppLogger.logs)
        if ((e.level == LogLevel.warning || e.level == LogLevel.error) && e.timestamp.isAfter(depuis))
          '${_heure(e.timestamp)} ${e.tag} : ${e.message.length > 140 ? '${e.message.substring(0, 140)}…' : e.message}',
    ];
    return retenues.length > nombre ? retenues.sublist(retenues.length - nombre) : retenues;
  }

  /// Le contexte, sans le réseau : ce qui se lit à l'instant de la secousse. [reseau] est
  /// ajouté par l'appelant, qui seul peut attendre la réponse du serveur.
  static Map<String, dynamic> capturer(BuildContext context, {DateTime? maintenant}) {
    final media = MediaQuery.maybeOf(context);
    return {
      'ecran': FilDAriane.emplacement,
      'fil': [for (final p in FilDAriane.pas) '${_heure(p.quand)} ${p.quoi}'],
      'langue': Langue.code,
      if (media != null) 'texte': double.parse((media.textScaler.scale(14) / 14).toStringAsFixed(2)),
      'theme': Theme.of(context).brightness == Brightness.dark ? 'sombre' : 'clair',
      'erreurs': erreursRecentes(maintenant: maintenant),
    };
  }

  static String _heure(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}
