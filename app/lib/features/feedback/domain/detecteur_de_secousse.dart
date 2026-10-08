/// Reconnaître une vraie secousse, et non un téléphone posé un peu vite.
///
/// Un seul à-coup au-dessus de 12 m/s² ouvrait l'écran des retours : « on se retrouve dans
/// l'interface de commentaires même sans faire exprès, juste en bougeant le téléphone »
/// (04/10). Une secousse, c'est un va-et-vient : plusieurs pics francs, rapprochés.
class DetecteurDeSecousse {
  /// Accélération (sans la gravité) d'un pic franc, en m/s².
  static const double seuil = 15.0;

  /// Pics nécessaires, et la fenêtre où ils doivent tomber.
  static const int picsNecessaires = 3;
  static const Duration fenetre = Duration(milliseconds: 1000);

  /// Deux mesures d'un même à-coup ne font pas deux pics.
  static const Duration ecartEntrePics = Duration(milliseconds: 90);

  final List<DateTime> _pics = [];

  /// Une mesure ; vrai quand elle complète une secousse (la mémoire repart alors de zéro).
  bool ajouter(double acceleration, DateTime instant) {
    _pics.removeWhere((t) => instant.difference(t) > fenetre);
    if (acceleration < seuil) return false;
    if (_pics.isNotEmpty && instant.difference(_pics.last) < ecartEntrePics) return false;
    _pics.add(instant);
    if (_pics.length >= picsNecessaires) {
      _pics.clear();
      return true;
    }
    return false;
  }
}
