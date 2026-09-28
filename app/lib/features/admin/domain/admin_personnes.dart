/// Les données nominatives de la console (migration 044) — phase de test seulement.
///
/// Tout ce qui vient d'ici peut être opacifié côté serveur d'un seul geste
/// (`app_config.admin_detail_nominatif`) : les prénoms deviennent « Personne a1b2c3 » et
/// les textes ne sortent plus. L'app n'a rien à savoir de ce choix, sinon l'afficher.
library;

int _entier(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
String _texte(Object? v) => v?.toString() ?? '';

class Personne {
  final String userId;
  final String prenom;
  final bool anonyme;
  final DateTime? arriveLe;
  final DateTime? derniereActivite;
  final String? plateforme;
  final String? version;
  final int degustations;
  final int bouteilles;
  final int scansEtiquette;
  final int scansCarte;
  final int messages;
  final int tables;
  final int erreurs;

  const Personne({
    required this.userId,
    required this.prenom,
    this.anonyme = false,
    this.arriveLe,
    this.derniereActivite,
    this.plateforme,
    this.version,
    this.degustations = 0,
    this.bouteilles = 0,
    this.scansEtiquette = 0,
    this.scansCarte = 0,
    this.messages = 0,
    this.tables = 0,
    this.erreurs = 0,
  });

  int get gestes => degustations + bouteilles + scansEtiquette + scansCarte + messages + tables;

  factory Personne.fromJson(Map<String, dynamic> j) => Personne(
        userId: _texte(j['user_id']),
        prenom: _texte(j['prenom']),
        anonyme: j['anonyme'] == true,
        arriveLe: _date(j['arrive_le']),
        derniereActivite: _date(j['derniere_activite']),
        plateforme: j['plateforme'] as String?,
        version: j['version'] as String?,
        degustations: _entier(j['degustations']),
        bouteilles: _entier(j['bouteilles']),
        scansEtiquette: _entier(j['scans_etiquette']),
        scansCarte: _entier(j['scans_carte']),
        messages: _entier(j['messages']),
        tables: _entier(j['tables']),
        erreurs: _entier(j['erreurs']),
      );
}

/// Un événement du fil d'une personne.
class EvenementDuFil {
  final DateTime? quand;

  /// degustation, bouteille, question, table, retour, scan_carte, scan_etiquette,
  /// chat_carte, usage, erreur, alerte.
  final String genre;
  final String titre;
  final String? detail;

  const EvenementDuFil({this.quand, required this.genre, required this.titre, this.detail});

  factory EvenementDuFil.fromJson(Map<String, dynamic> j) => EvenementDuFil(
        quand: _date(j['quand']),
        genre: _texte(j['genre']),
        titre: _texte(j['titre']),
        detail: j['detail'] as String?,
      );
}

class MessageDeConversation {
  final DateTime? quand;
  final bool deLaPersonne;
  final String contenu;
  final String? cave;

  const MessageDeConversation({this.quand, required this.deLaPersonne, required this.contenu, this.cave});

  factory MessageDeConversation.fromJson(Map<String, dynamic> j) => MessageDeConversation(
        quand: _date(j['quand']),
        deLaPersonne: j['role'] == 'user',
        contenu: _texte(j['contenu']),
        cave: j['cave'] as String?,
      );
}

class ErreurGroupee {
  final String niveau;
  final String tag;
  final String forme;
  final int n;
  final String qui;
  final DateTime? derniere;
  final String versions;

  const ErreurGroupee({
    required this.niveau,
    required this.tag,
    required this.forme,
    required this.n,
    this.qui = '',
    this.derniere,
    this.versions = '',
  });

  bool get estErreur => niveau == 'error';

  factory ErreurGroupee.fromJson(Map<String, dynamic> j) => ErreurGroupee(
        niveau: _texte(j['niveau']),
        tag: _texte(j['tag']),
        forme: _texte(j['forme']),
        n: _entier(j['n']),
        qui: _texte(j['qui']),
        derniere: _date(j['derniere']),
        versions: _texte(j['versions']),
      );
}

/// Une ligne brute : tel jour, telle fonctionnalité, telle personne, tant d'usages.
class Usage {
  final DateTime jour;
  final String fonctionnalite;
  final String userId;
  final String prenom;
  final int usages;

  const Usage({
    required this.jour,
    required this.fonctionnalite,
    required this.userId,
    required this.prenom,
    required this.usages,
  });

  factory Usage.fromJson(Map<String, dynamic> j) => Usage(
        jour: DateTime.tryParse('${j['jour']}') ?? DateTime(2000),
        fonctionnalite: _texte(j['fonctionnalite']),
        userId: _texte(j['user_id']),
        prenom: _texte(j['prenom']),
        usages: _entier(j['usages']),
      );
}

/// Une fonctionnalité, agrégée sur la période : combien d'usages, par qui.
class BilanDeFonctionnalite {
  final String nom;
  final int usages;

  /// Prénom → usages, du plus grand au plus petit.
  final List<MapEntry<String, int>> parPersonne;

  const BilanDeFonctionnalite({required this.nom, required this.usages, required this.parPersonne});

  int get personnes => parPersonne.length;

  /// Regroupe les lignes brutes par fonctionnalité, la plus utilisée d'abord.
  static List<BilanDeFonctionnalite> depuis(List<Usage> lignes) {
    final parFonction = <String, Map<String, int>>{};
    for (final l in lignes) {
      final personnes = parFonction.putIfAbsent(l.fonctionnalite, () => {});
      personnes[l.prenom] = (personnes[l.prenom] ?? 0) + l.usages;
    }
    final bilans = [
      for (final e in parFonction.entries)
        BilanDeFonctionnalite(
          nom: e.key,
          usages: e.value.values.fold(0, (a, b) => a + b),
          parPersonne: e.value.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
        ),
    ]..sort((a, b) => b.usages.compareTo(a.usages));
    return bilans;
  }
}
