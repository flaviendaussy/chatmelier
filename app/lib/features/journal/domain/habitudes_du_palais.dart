import '../../../shared/utils/langue.dart';
import 'tasting_entry.dart';

/// Ce que la personne boit d'habitude, en quelques lignes, pour le sommelier (V2.5 · E3).
///
/// Le 13/10, le sommelier de la carte a couvert d'éloges un vin simple. Flavien : « base-toi
/// aussi un peu sur ce que l'utilisateur boit pour voir si un vin est à son niveau ou pas ».
/// Ses dégustations récentes (vins, domaines, millésimes, notes) le disent. Une bouteille
/// défectueuse n'y entre pas : sa note jugeait un défaut, pas le vin.
class HabitudesDuPalais {
  static const nombreMax = 12;
  static const fenetre = Duration(days: 180);

  /// Vide quand le journal n'a rien de récent : le sommelier ne devine pas un niveau.
  static String resumer(Iterable<TastingEntry> journal, {required bool fr, DateTime? maintenant}) {
    final depuis = (maintenant ?? DateTime.now()).subtract(fenetre);
    final recentes = [
      for (final e in journal)
        if (e.fault == null && e.consumedAt.isAfter(depuis) && (e.wineName ?? '').trim().isNotEmpty) e,
    ]..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    if (recentes.isEmpty) return '';

    final notes = [for (final e in recentes) if (e.displayRating != null) e.displayRating!];
    final moyenne = notes.isEmpty ? null : notes.reduce((a, b) => a + b) / notes.length;
    return [
      trSi(fr, 'Ses dégustations récentes, de la plus récente à la plus ancienne :', 'Recent tastings, most recent first:'),
      for (final e in recentes.take(nombreMax))
        '- ${_vin(e)}${e.displayRating != null ? ' — ${_note(e.displayRating!, fr)}/10' : ''}',
      if (moyenne != null)
        trSi(fr, 'Note moyenne : {moyenne}/10 sur {n} dégustations.', 'Average rating: {moyenne}/10 over {n} tastings.',
            {'moyenne': _note(moyenne, fr), 'n': notes.length}),
    ].join('\n');
  }

  /// « Clos des Grives 2019, Domaine Combier, Crozes-Hermitage » : le domaine et
  /// l'appellation seulement s'ils n'y sont pas déjà.
  static String _vin(TastingEntry e) {
    final nom = [e.wineName!.trim(), if (e.vintage != null) '${e.vintage}'].join(' ');
    final appellation = e.appellation?.trim() ?? '';
    return [
      nom,
      if (e.domaineAffiche != null) e.domaineAffiche!,
      if (appellation.isNotEmpty && !nom.toLowerCase().contains(appellation.toLowerCase())) appellation,
    ].join(', ');
  }

  /// La virgule décimale, sauf en anglais (comme les prix).
  static String _note(double n, bool fr) {
    final t = n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
    return !fr && Langue.code == 'en' ? t : t.replaceAll('.', ',');
  }
}
