import 'package:uuid/uuid.dart';

import '../../../shared/services/nearby_places_service.dart';
import '../../../shared/utils/langue.dart';
import '../../auth/domain/taste_profile.dart';
import 'menu_flagging_engine.dart';
import 'menu_wine.dart';

/// Le lieu d'une carte (V2.3 · K6, fait le 08/10) : la clé sous laquelle la carte est
/// partagée, son nom (obligatoire) et sa position.
///
/// Un restaurant trouvé sur OpenStreetMap garde son identifiant : deux personnes qui le
/// choisissent tombent sur la même carte. Un nom tapé à la main est rangé sous ce nom,
/// normalisé, et la position du lieu arrondie au millième de degré (≈ 100 m) : jamais la
/// position exacte de la personne.
class LieuDeLaCarte {
  final String cle;
  final String nom;
  final double latitude;
  final double longitude;

  const LieuDeLaCarte({required this.cle, required this.nom, required this.latitude, required this.longitude});

  /// Un lieu proposé par la recherche des lieux proches. Nul sans position.
  static LieuDeLaCarte? depuisLieuProche(NearbyPlace lieu) {
    final lat = lieu.latitude;
    final lon = lieu.longitude;
    final nom = lieu.name.trim();
    if (lat == null || lon == null || nom.isEmpty) return null;
    final osm = lieu.osmCle;
    if (osm != null) return LieuDeLaCarte(cle: 'osm:$osm', nom: nom, latitude: lat, longitude: lon);
    return tape(nom, lat, lon);
  }

  /// Un nom tapé, à la position (arrondie) où l'on se trouve. Nul si le nom est vide.
  static LieuDeLaCarte? tape(String nom, double latitude, double longitude) {
    final propre = nom.trim();
    if (propre.isEmpty) return null;
    final lat = arrondir(latitude);
    final lon = arrondir(longitude);
    return LieuDeLaCarte(
      cle: 'nom:${normaliser(propre)}@${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}',
      nom: propre,
      latitude: lat,
      longitude: lon,
    );
  }

  static double arrondir(double degres) => (degres * 1000).roundToDouble() / 1000;

  /// « Le Petit Zinc » et « le petit  zinc » sont le même lieu.
  static String normaliser(String nom) {
    const accents = {'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae'};
    final bas = nom.toLowerCase().split('').map((c) => accents[c] ?? c).join();
    return bas.replaceAll(RegExp(r"[^a-z0-9]+"), ' ').trim().replaceAll(' ', '-');
  }
}

/// Une carte récente déposée près d'ici, telle que `cartes_proches` la décrit.
class CarteProche {
  final String lieuCle;
  final String lieuNom;
  final int distanceM;
  final int nbVins;
  final String? devise;
  final bool ardoise;
  final DateTime deposeeLe;

  const CarteProche({
    required this.lieuCle,
    required this.lieuNom,
    required this.distanceM,
    required this.nbVins,
    this.devise,
    this.ardoise = false,
    required this.deposeeLe,
  });

  factory CarteProche.fromJson(Map<String, dynamic> j) => CarteProche(
        lieuCle: j['lieu_cle'].toString(),
        lieuNom: (j['lieu_nom'] ?? '').toString(),
        distanceM: (j['distance_m'] as num?)?.toInt() ?? 0,
        nbVins: (j['nb_vins'] as num?)?.toInt() ?? 0,
        devise: j['devise'] as String?,
        ardoise: j['ardoise'] == true,
        deposeeLe: DateTime.tryParse('${j['deposee_le']}')?.toLocal() ?? DateTime.now(),
      );

  int joursDepuis([DateTime? maintenant]) => (maintenant ?? DateTime.now()).difference(deposeeLe).inDays;

  /// Au-delà d'une semaine, les prix ont pu changer : on le dit, sans cacher la carte.
  bool prixAVerifier([DateTime? maintenant]) => joursDepuis(maintenant) > 7;

  /// « aujourd'hui », « hier », « il y a 3 jours ».
  String age([DateTime? maintenant]) => CarteDuLieu.age(deposeeLe, maintenant);
}

/// Ce qui se partage d'une carte, et ce qu'on en fait en la recevant.
class CarteDuLieu {
  /// La carte telle que le scan l'a lue : sans photos (des chemins de l'appareil), sans
  /// identifiant d'appareil, sans le score ni les badges calculés pour le palais de celui
  /// qui l'a scannée. Le pont avec sa cave n'est jamais sérialisé.
  static Map<String, dynamic> aPartager(ScannedMenu carte) {
    final json = carte.toJson()
      ..remove('page_photo_paths')
      ..remove('id');
    json['wines'] = [
      for (final w in carte.wines)
        w.toJson()
          ..remove('user_match_score')
          ..remove('flag')
          ..remove('id'),
    ];
    return json;
  }

  /// La carte d'un lieu, ouverte par quelqu'un d'autre : nommée comme le lieu, datée du
  /// jour du dépôt, et recalculée pour SON palais.
  static ScannedMenu recue(
    Map<String, dynamic> carte, {
    required String nomDuLieu,
    required DateTime deposeeLe,
    TasteProfile? profil,
  }) {
    const uuid = Uuid();
    final brute = ScannedMenu.fromJson({
      ...carte,
      'id': uuid.v4(),
      'restaurant_name': nomDuLieu,
      'scanned_at': deposeeLe.toIso8601String(),
      'page_photo_paths': const <String>[],
    });
    final vins = [
      for (final w in brute.wines)
        w.copyWith(
          id: w.id.isEmpty ? uuid.v4() : w.id,
          userMatchScore: MenuWineMatchCalculator.computeMatchScore(w, profil),
        ),
    ];
    return brute.copie(wines: MenuFlaggingEngine.applyFlags(vins, profil));
  }

  /// « aujourd'hui », « hier », « il y a 3 jours ».
  static String age(DateTime le, [DateTime? maintenant]) {
    final jours = (maintenant ?? DateTime.now()).difference(le).inDays;
    if (jours <= 0) return tr('aujourd\'hui', 'today');
    if (jours == 1) return tr('hier', 'yesterday');
    return tr('il y a {n} jours', '{n} days ago', {'n': jours});
  }
}
