import '../../../shared/services/fonctions_ia.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/currency_helper.dart';
import '../../../shared/utils/langue.dart';

/// Ce qu'a donné la recherche de la cote d'un vin.
class ResultatDeCote {
  final double? valeur;
  final String? devise;
  final String? source;

  /// Ce qu'on dit à la personne, dans la langue de l'écran.
  final String message;

  const ResultatDeCote._(this.message, {this.valeur, this.devise, this.source});

  bool get trouvee => valeur != null && source != null;
}

/// La cote d'un vin, cherchée à la demande (V2.5 · F8).
///
/// « toucher la valeur (ou « Non cotée ») lance une recherche Google sourcée pour ce vin ;
/// source affichée, quota ; jamais de valeur sans source ». La fonction `update-wine-values`
/// cherche, ne retient qu'un prix relevé sur une page, et l'enregistre avec sa source.
class CoteALaDemande {
  final FonctionsIa _ia;

  CoteALaDemande(this._ia);

  Future<ResultatDeCote> chercher(String wineId) async {
    final r = await _ia.appeler('update-wine-values', {'wine_id': wineId}, delai: const Duration(seconds: 70));
    if (r.limiteAtteinte) return ResultatDeCote._(r.messageDeLimite());
    if (!r.ok) {
      AppLogger.warning('COTE', 'Recherche de cote impossible : ${r.erreur ?? 'réponse vide'}');
      return ResultatDeCote._(tr('La recherche n\'a pas abouti. Réessayez plus tard.',
          'The search didn\'t go through. Please try again later.'));
    }
    final c = r.donnees!['cote'];
    final valeur = c is Map ? (c['valeur'] as num?)?.toDouble() : null;
    final source = c is Map ? c['source'] as String? : null;
    if (valeur == null || valeur <= 0 || source == null || source.isEmpty) {
      AppLogger.info('COTE', 'Aucune cote sourcée');
      return ResultatDeCote._(tr('Aucune cote trouvée avec une source vérifiable : Chatmelier n\'invente pas de prix.',
          'No market price found with a verifiable source: Chatmelier doesn\'t make prices up.'));
    }
    final devise = c is Map ? (c['devise'] as String? ?? 'EUR') : 'EUR';
    final site = Uri.tryParse(source)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? source;
    AppLogger.info('COTE', 'Cote trouvée sur $site');
    return ResultatDeCote._(
      tr('Cote trouvée : {prix}, relevée sur {site}.', 'Market price found: {prix}, from {site}.', {
        'prix': CurrencyHelper.formatPrice(valeur, currency: devise, decimals: valeur % 1 == 0 ? 0 : 2),
        'site': site,
      }),
      valeur: valeur,
      devise: devise,
      source: source,
    );
  }
}
