import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

import 'terroir_geo_data.dart';

/// Ce que montrent les deux cartes fixes du terroir (V2.5 · F7).
///
/// Une carte qu'on peut déplacer et zoomer finit par ne plus montrer son sujet : on
/// dézoome, on glisse, et plus rien ne dit où était l'appellation (retour du 16/09). D'où
/// deux cartes figées, sans geste possible : le pays, pour situer ; puis la zone de
/// l'appellation, pour voir — et, quand le vin n'est reconnu que par sa région, environ un
/// département autour du lieu, plutôt qu'un contour d'appellation qui ne serait pas le sien.
class CadrageDuTerroir {
  CadrageDuTerroir._();

  /// Environ un département français (5 800 km² en moyenne) : 90 km de côté.
  static const double demiCoteDepartementKm = 45;

  /// Autour d'un lieu hors de son pays (le rhum de Martinique) : la région, pas le pays.
  static const double demiCoteRegionKm = 300;

  /// Les pays de l'atlas et leurs voisins viticoles, en métropole ou sur le continent : la
  /// Corse oui, les outre-mer non, sans quoi la France tiendrait dans un timbre.
  static final Map<String, LatLngBounds> _pays = {
    'FR': _cadre(41.3, -5.2, 51.1, 9.6),
    'ES': _cadre(35.9, -9.4, 43.8, 4.4),
    'IT': _cadre(36.6, 6.6, 47.1, 18.6),
    'PT': _cadre(36.9, -9.6, 42.2, -6.1),
    'DE': _cadre(47.3, 5.9, 55.1, 15.0),
    'CH': _cadre(45.8, 5.9, 47.8, 10.5),
    'AT': _cadre(46.4, 9.5, 49.0, 17.2),
    'GB': _cadre(49.9, -8.2, 58.7, 1.8),
    'IE': _cadre(51.4, -10.5, 55.4, -5.9),
    'PL': _cadre(49.0, 14.1, 54.9, 24.2),
    'HU': _cadre(45.7, 16.1, 48.6, 22.9),
    'GR': _cadre(34.8, 19.4, 41.8, 28.3),
    'US': _cadre(24.5, -124.8, 49.4, -66.9),
    'MX': _cadre(14.5, -117.1, 32.7, -86.7),
    'AR': _cadre(-55.1, -73.6, -21.8, -53.6),
    'CL': _cadre(-55.9, -75.6, -17.5, -66.4),
    'ZA': _cadre(-34.8, 16.5, -22.1, 32.9),
    'AU': _cadre(-43.7, 113.3, -10.6, 153.6),
    'NZ': _cadre(-47.3, 166.4, -34.4, 178.6),
  };

  static LatLngBounds _cadre(double sud, double ouest, double nord, double est) =>
      LatLngBounds(LatLng(sud, ouest), LatLng(nord, est));

  /// Vrai quand le lieu est dans le cadre de son pays (faux pour la Martinique).
  static bool dansLePays(TerroirGeoProfile p) => _pays[p.countryCode.toUpperCase()]?.contains(p.center) ?? false;

  /// Le pays entier ; à défaut (pays hors de la table, ou lieu outre-mer), la région autour
  /// du lieu.
  static LatLngBounds pays(TerroirGeoProfile p) =>
      dansLePays(p) ? _pays[p.countryCode.toUpperCase()]! : autour(p.center, demiCoteRegionKm);

  /// La zone de l'appellation quand c'est elle qui a été reconnue, avec de l'air autour et
  /// jamais moins qu'un village et ses vignes ; sinon environ un département.
  static LatLngBounds zone(TerroirGeoProfile p, {required bool appellationReconnue}) {
    if (!appellationReconnue) return autour(p.center, demiCoteDepartementKm);
    // Le rayon le plus large du contour (`generateAppellationBoundary` : ±18 %).
    final rayonKm = p.hexRadiusKm * 1.8 * 1.18;
    return autour(p.center, math.max(rayonKm * 1.5, 6));
  }

  /// Un carré de [demiCoteKm] de demi-côté autour de [centre].
  static LatLngBounds autour(LatLng centre, double demiCoteKm) {
    final dLat = demiCoteKm / 111.32;
    final dLon = demiCoteKm / (111.32 * math.cos(centre.latitude * math.pi / 180));
    return LatLngBounds(
      LatLng(centre.latitude - dLat, centre.longitude - dLon),
      LatLng(centre.latitude + dLat, centre.longitude + dLon),
    );
  }
}
