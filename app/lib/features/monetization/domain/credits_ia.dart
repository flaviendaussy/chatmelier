import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'reglages_de_la_pub.dart';

/// Les gestes d'IA qu'une vidéo peut payer (modèle économique, 21/10).
enum GesteIa {
  /// Une question au sommelier (chat d'un vin, chat général).
  chat,

  /// Une question sur une carte de restaurant : libre pendant une soirée ouverte.
  questionCarte,

  /// La cote d'un vin : une recherche Google payante.
  cote,
}

/// Ce que la personne a consommé aujourd'hui, et ce que ses vidéos lui ont ouvert.
///
/// Sur le téléphone : la vraie limite reste le quota du serveur (`quotas_ia`), garde-fou
/// contre l'abus ; ici, c'est le rythme normal — quelques questions offertes chaque jour,
/// puis une vidéo choisie. Une journée commence à minuit, heure du téléphone ; une soirée
/// ouverte au restaurant passe minuit.
class CreditsIa {
  final String jour;
  int chat;
  int chatBonus;
  int questions;
  int cote;
  int coteBonus;
  DateTime? soireeJusquA;

  CreditsIa({
    required this.jour,
    this.chat = 0,
    this.chatBonus = 0,
    this.questions = 0,
    this.cote = 0,
    this.coteBonus = 0,
    this.soireeJusquA,
  });

  static String jourDe(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  bool soireeOuverte(DateTime maintenant) => soireeJusquA != null && maintenant.isBefore(soireeJusquA!);

  /// Ce geste passe-t-il sans vidéo ?
  bool autorise(GesteIa geste, ReglagesDeLaPub r, DateTime maintenant) => switch (geste) {
        GesteIa.chat => chat < r.chatOfferts + chatBonus,
        GesteIa.questionCarte => soireeOuverte(maintenant) || questions < r.questionsCarteOffertes,
        GesteIa.cote => cote < r.coteOffertes + coteBonus,
      };

  /// Un geste fait (la réponse est arrivée).
  void compter(GesteIa geste, DateTime maintenant) {
    switch (geste) {
      case GesteIa.chat:
        chat++;
      case GesteIa.questionCarte:
        if (!soireeOuverte(maintenant)) questions++;
      case GesteIa.cote:
        cote++;
    }
  }

  /// Une vidéo regardée jusqu'au bout.
  void crediter(GesteIa geste, ReglagesDeLaPub r, DateTime maintenant) {
    switch (geste) {
      case GesteIa.chat:
        chatBonus += r.chatParVideo;
      case GesteIa.questionCarte:
        ouvrirLaSoiree(r, maintenant);
      case GesteIa.cote:
        coteBonus += 1;
    }
  }

  void ouvrirLaSoiree(ReglagesDeLaPub r, DateTime maintenant) {
    final fin = maintenant.add(Duration(hours: r.soireeHeures));
    if (soireeJusquA == null || fin.isAfter(soireeJusquA!)) soireeJusquA = fin;
  }

  Map<String, dynamic> toJson() => {
        'jour': jour,
        'chat': chat,
        'chat_bonus': chatBonus,
        'questions': questions,
        'cote': cote,
        'cote_bonus': coteBonus,
        if (soireeJusquA != null) 'soiree': soireeJusquA!.millisecondsSinceEpoch,
      };

  /// Une nouvelle journée remet les compteurs à zéro, pas la soirée en cours.
  factory CreditsIa.depuis(Object? brut, DateTime maintenant) {
    final aujourdhui = jourDe(maintenant);
    if (brut is! Map) return CreditsIa(jour: aujourdhui);
    int n(String cle) => brut[cle] is num ? (brut[cle] as num).toInt().clamp(0, 100000) : 0;
    final soiree = brut['soiree'] is num ? DateTime.fromMillisecondsSinceEpoch((brut['soiree'] as num).toInt()) : null;
    if (brut['jour'] != aujourdhui) return CreditsIa(jour: aujourdhui, soireeJusquA: soiree);
    return CreditsIa(
      jour: aujourdhui,
      chat: n('chat'),
      chatBonus: n('chat_bonus'),
      questions: n('questions'),
      cote: n('cote'),
      coteBonus: n('cote_bonus'),
      soireeJusquA: soiree,
    );
  }

  static String _cle(String? uid) => 'credits_ia_${uid ?? 'appareil'}';

  static Future<CreditsIa> lire(String? uid, {DateTime? maintenant}) async {
    final t = maintenant ?? DateTime.now();
    try {
      final brut = (await SharedPreferences.getInstance()).getString(_cle(uid));
      return CreditsIa.depuis(brut == null ? null : jsonDecode(brut), t);
    } catch (_) {
      return CreditsIa(jour: jourDe(t));
    }
  }

  Future<void> ecrire(String? uid) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_cle(uid), jsonEncode(toJson()));
    } catch (_) {
      // Sans stockage, rien n'est compté : au pire, une vidéo de moins.
    }
  }

  /// La vidéo d'une carte de restaurant ouvre aussi la soirée.
  static Future<void> ouvrirLaSoireeApresUneCarte(String? uid) async {
    final c = await lire(uid);
    c.ouvrirLaSoiree(ReglagesDeLaPub.actuels, DateTime.now());
    await c.ecrire(uid);
  }

  /// Après une réponse de l'IA.
  static Future<void> compterUnGeste(String? uid, GesteIa geste) async {
    final c = await lire(uid);
    c.compter(geste, DateTime.now());
    await c.ecrire(uid);
  }
}
