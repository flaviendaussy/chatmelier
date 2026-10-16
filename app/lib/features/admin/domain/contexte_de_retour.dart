/// Le contexte d'un retour, tel que la console le montre (migration 070) : où était la
/// personne, ce qu'elle venait de faire, l'état du réseau, et ses journaux des trois minutes
/// d'avant.
class ContexteDeRetour {
  final String? ecran;
  final List<String> fil;
  final String? reseau;
  final String? langue;
  final double? texte;
  final String? theme;
  final List<String> erreurs;

  /// Envoyé plus tard que son heure (resté sans réseau sur le téléphone).
  final DateTime? envoyeLe;

  /// Pourquoi la capture manque, s'il en manque une.
  final String? causeCapture;
  final List<({DateTime? quand, String niveau, String tag, String message})> journaux;

  const ContexteDeRetour({
    this.ecran,
    this.fil = const [],
    this.reseau,
    this.langue,
    this.texte,
    this.theme,
    this.erreurs = const [],
    this.envoyeLe,
    this.causeCapture,
    this.journaux = const [],
  });

  /// Rien de plus que les journaux : un retour d'avant la 83, qui ne portait pas de contexte.
  bool get sansContexte => ecran == null && fil.isEmpty && reseau == null && erreurs.isEmpty;

  static List<String> _textes(Object? v) => v is List ? [for (final x in v) if (x != null) '$x'] : const [];

  factory ContexteDeRetour.fromJson(Map<String, dynamic> j) {
    final c = j['contexte'] is Map ? Map<String, dynamic>.from(j['contexte'] as Map) : const <String, dynamic>{};
    return ContexteDeRetour(
      ecran: c['ecran'] as String?,
      fil: _textes(c['fil']),
      reseau: c['reseau'] as String?,
      langue: c['langue'] as String?,
      texte: (c['texte'] as num?)?.toDouble(),
      theme: c['theme'] as String?,
      erreurs: _textes(c['erreurs']),
      envoyeLe: DateTime.tryParse('${j['envoye_le'] ?? ''}'),
      causeCapture: j['capture'] as String?,
      journaux: [
        if (j['journaux'] is List)
          for (final l in j['journaux'] as List)
            if (l is Map)
              (
                quand: DateTime.tryParse('${l['quand'] ?? ''}')?.toLocal(),
                niveau: '${l['niveau'] ?? ''}',
                tag: '${l['tag'] ?? ''}',
                message: '${l['message'] ?? ''}',
              ),
      ],
    );
  }
}
