import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/fonctions_ia.dart';
import '../../../shared/utils/langue_du_texte.dart';

/// Une fiche traduite. `null` pour une partie qui n'avait pas à l'être (déjà dans la bonne
/// langue) ou dont la traduction n'a pas été fidèle.
class FicheTraduite {
  final String? notes;
  final List<String>? accords;

  /// La langue d'origine : celle de la description, sinon celle des accords.
  final String depuis;

  const FicheTraduite({this.notes, this.accords, required this.depuis});
}

/// La fiche d'un vin dans la langue de l'app (V2.4 · R6).
///
/// Le catalogue garde la langue de qui a écrit une fiche le premier : Caro, en français,
/// lisait les descriptions écrites pour Flavien, en anglais, et même une description
/// anglaise au-dessus d'accords français (04/10, trois retours). Chaque partie est traduite
/// seulement si sa langue diffère de celle de l'app, par `taches-ia` (Flash-Lite), puis
/// gardée sur le téléphone : un vin ne se traduit qu'une fois.
class TraductionDesFiches {
  final FonctionsIa? _iaInjecte;

  TraductionDesFiches({FonctionsIa? ia}) : _iaInjecte = ia;

  FonctionsIa? get _ia {
    if (_iaInjecte != null) return _iaInjecte;
    try {
      return FonctionsIa(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  /// La langue d'origine de chaque partie, quand elle diffère de [langue] ; nulle sinon (ou
  /// quand le texte est trop court pour le dire).
  static ({String? notes, String? accords}) aTraduire(String? notes, List<String> accords, String langue) {
    final ln = LangueDuTexte.detecter(notes);
    final la = LangueDuTexte.detecter(accords.join(' · '));
    return (notes: ln != null && ln != langue ? ln : null, accords: la != null && la != langue ? la : null);
  }

  Future<FicheTraduite?> traduire({
    required String? notes,
    required List<String> accords,
    required String langue,
  }) async {
    final besoin = aTraduire(notes, accords, langue);
    if (besoin.notes == null && besoin.accords == null) return null;
    final notesAEnvoyer = besoin.notes != null ? notes!.trim() : '';
    final accordsAEnvoyer = besoin.accords != null ? accords : const <String>[];
    final cle = 'fiche_traduite:v1:$langue:${empreinte('$notesAEnvoyer\u0001${accordsAEnvoyer.join('\u0001')}')}';

    try {
      final deja = (await SharedPreferences.getInstance()).getString(cle);
      if (deja != null) {
        final m = jsonDecode(deja);
        if (m is Map) return lire(m, besoin, accordsAttendus: accordsAEnvoyer.length);
      }
    } catch (_) {
      // Cache illisible : on traduit de nouveau.
    }

    final ia = _ia;
    if (ia == null) return null;
    final r = await ia.appeler(
      'taches-ia',
      {'tache': 'traduire_fiche', 'langue': langue, 'notes': notesAEnvoyer, 'accords': accordsAEnvoyer},
      delai: const Duration(seconds: 30),
    );
    if (!r.ok) return null;
    final resultat = r.donnees!['resultat'];
    if (resultat is! Map) return null;
    final traduite = lire(resultat, besoin, accordsAttendus: accordsAEnvoyer.length);
    if (traduite == null) return null;
    try {
      await (await SharedPreferences.getInstance())
          .setString(cle, jsonEncode({'notes': traduite.notes, 'accords': traduite.accords}));
    } catch (_) {}
    return traduite;
  }

  /// Ce que le serveur a rendu, gardé seulement s'il est fidèle : autant d'accords qu'envoyés
  /// (un plat perdu ou ajouté n'est plus une traduction).
  static FicheTraduite? lire(Map m, ({String? notes, String? accords}) besoin, {required int accordsAttendus}) {
    final notesBrutes = m['notes'];
    final notes = besoin.notes != null && notesBrutes is String && notesBrutes.trim().isNotEmpty
        ? notesBrutes.trim()
        : null;
    List<String>? accords;
    final brut = m['accords'];
    if (besoin.accords != null && brut is List) {
      final l = [
        for (final a in brut)
          if (a is String && a.trim().isNotEmpty) a.trim(),
      ];
      if (l.length == accordsAttendus) accords = l;
    }
    if (notes == null && accords == null) return null;
    return FicheTraduite(notes: notes, accords: accords, depuis: besoin.notes ?? besoin.accords!);
  }

  /// FNV-1a sur 32 bits : la même empreinte d'un lancement à l'autre.
  static String empreinte(String texte) {
    var h = 0x811c9dc5;
    for (final u in texte.codeUnits) {
      h ^= u;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }
}
