import 'catalogue_es.g.dart';
import 'catalogue_it.g.dart';

/// Les catalogues des langues autres que le français et l'anglais, indexés par la phrase
/// française (V2.3 · H1). Générés depuis `l10n_catalogues/<langue>.json` par
/// `tool/langues/generer.py` : ne pas les modifier à la main.
const Map<String, Map<String, String>> catalogues = {
  'es': catalogueEs,
  'it': catalogueIt,
};
