import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../cellar/domain/wine.dart';
import '../../offline/data/offline_storage_service.dart';
import '../../offline/domain/offline_action.dart';
import '../../offline/presentation/sync_provider.dart';
import '../domain/tasting_questionnaire_result.dart';

/// Un vin bu hors de sa cave, tel qu'on le retient.
class VinBuDehors {
  final String nom;
  final String? producteur;
  final int? millesime;
  final String? region;

  /// `red`, `white`, `rose`, `sparkling`… comme la colonne `wine_type`.
  final String couleur;

  /// Nulle tant que la personne n'a pas noté : on n'invente pas un avis.
  final double? note;
  final String? lieu;
  final String? plat;
  final String? notes;
  final String? photoUrl;
  final List<String> convives;

  /// Faux à une table : chaque convive note sur son propre téléphone, et ses goûts ne
  /// doivent pas entrer dans un profil local à son nom chez quelqu'un d'autre.
  final bool convivesApprennent;
  final bool coupDeCoeur;

  // Niveau « Gorgée », facultatif.
  final String? texture;
  final String? fruit;
  final String? racheter;

  const VinBuDehors({
    required this.nom,
    this.producteur,
    this.millesime,
    this.region,
    this.couleur = 'red',
    this.note,
    this.lieu,
    this.plat,
    this.notes,
    this.photoUrl,
    this.convives = const [],
    this.convivesApprennent = true,
    this.coupDeCoeur = false,
    this.texture,
    this.fruit,
    this.racheter,
  });

  bool get aUneGorgee => texture != null || fruit != null || racheter != null;
}

/// Enregistrer un vin bu dehors : la base commune à « Déguster ailleurs » et à la fin de
/// soirée d'une table (V2.3 · E2), sortie du dialogue où elle vivait.
///
/// La fiche du vin, la dégustation (avec ses replis pour les bases restées en retard), la
/// file hors ligne si le réseau manque, le cache local pour un affichage immédiat, puis le
/// palais : le principal et chaque convive nommé.
class DegustationRapide {
  final SupabaseClient _supabase;
  final OfflineStorageService _horsLigne;
  final TasteProfileService _gout;

  DegustationRapide(this._supabase, this._horsLigne, this._gout);

  /// L'identifiant de la dégustation, et si elle est partie au serveur.
  Future<({String id, bool enLigne})> enregistrer(VinBuDehors v) async {
    final user = _supabase.auth.currentUser;
    final wineId = const Uuid().v4();
    final tastingId = const Uuid().v4();
    final lieu = (v.lieu ?? '').trim();
    final plat = (v.plat ?? '').trim();
    final notes = (v.notes ?? '').trim();
    final producteur = (v.producteur ?? '').trim();
    final region = (v.region ?? '').trim();
    final occasion = lieu.isNotEmpty ? lieu : 'Dégustation hors cave';
    final maintenant = DateTime.now().toIso8601String();

    var enLigne = false;
    if (user != null) {
      // La colonne s'appelle `wine_type`. Avec `type`, l'insert échouait à chaque fois
      // (PGRST204), la dégustation butait ensuite sur la clé étrangère, et elle finissait
      // dans une file que la synchronisation ne savait pas vider : le Margaux du 16/09.
      var vinCree = false;
      try {
        await _supabase.from('wines').insert({
          'id': wineId,
          'name': v.nom,
          'producer': producteur.isNotEmpty ? producteur : null,
          'vintage': v.millesime,
          'wine_type': v.couleur,
          'region': region.isNotEmpty ? region : 'Autre',
          'image_url': v.photoUrl,
        });
        vinCree = true;
      } catch (e) {
        AppLogger.warning('EXTERNAL_TASTING', 'Could not insert standalone wine, queueing the tasting: $e');
      }

      // Sans le vin, la clé étrangère refuse la dégustation à coup sûr : elle va
      // directement à la file, qui recréera le vin sous le même identifiant.
      if (vinCree) {
        final complet = {
          'id': tastingId,
          'wine_id': wineId,
          'user_id': user.id,
          'rating': v.note,
          'occasion': occasion,
          'food_paired': plat.isNotEmpty ? plat : null,
          'tasting_notes': notes.isNotEmpty ? notes : null,
          'photo_url': v.photoUrl,
          'co_tasters': v.convives,
          'location_name': lieu.isNotEmpty ? lieu : null,
          'is_external': true,
          'rating_scale': 10,
          'is_favorite': v.coupDeCoeur,
          'consumed_at': maintenant,
        };
        // Les replis suivent l'histoire du schéma : sans les colonnes récentes, puis
        // l'ancienne échelle sur 5 (migration 027 jamais appliquée), en divisant sans
        // marquer l'échelle — la relecture la déduit de son absence.
        final essais = <Map<String, dynamic>>[
          complet,
          {
            for (final k in ['id', 'wine_id', 'user_id', 'rating', 'occasion', 'food_paired', 'tasting_notes',
                'photo_url', 'rating_scale', 'consumed_at'])
              k: complet[k],
          },
          {
            for (final k in ['id', 'wine_id', 'user_id', 'occasion', 'food_paired', 'tasting_notes', 'photo_url',
                'consumed_at'])
              k: complet[k],
            'rating': v.note == null ? null : (v.note! / 2.0).clamp(0.0, 5.0),
          },
        ];
        for (var i = 0; i < essais.length && !enLigne; i++) {
          try {
            await _supabase.from('tasting_log').insert(essais[i]);
            enLigne = true;
          } catch (e) {
            AppLogger.warning('EXTERNAL_TASTING',
                i < essais.length - 1 ? 'tasting_log refusé ($e), essai suivant' : 'Could not save online, queueing offline: $e');
          }
        }
      }
    }

    if (!enLigne) {
      await _horsLigne.queueAction(OfflineAction(
        id: tastingId,
        type: OfflineActionType.consumeBottle,
        status: OfflineActionStatus.pending,
        data: {
          'tasting_id': tastingId,
          'wine_id': wineId,
          'wine_name': v.nom,
          'producer': producteur,
          'vintage': v.millesime,
          'region': region,
          'wine_type': v.couleur,
          'rating': v.note,
          'occasion': lieu,
          'food_paired': plat,
          'tasting_notes': notes,
          'photo_url': v.photoUrl,
          'co_tasters': v.convives,
          'location_name': lieu.isNotEmpty ? lieu : null,
          'is_external': true,
          'rating_scale': 10,
          'is_favorite': v.coupDeCoeur,
        },
        createdAt: DateTime.now(),
      ));
    }

    await _horsLigne.addCachedTasting({
      // Marque tant qu'elle n'est pas partie : voir OfflineStorageService.pendingSyncKey.
      if (!enLigne) OfflineStorageService.pendingSyncKey: true,
      'id': tastingId,
      'wine_id': wineId,
      'user_id': user?.id,
      'rating': v.note,
      'occasion': occasion,
      'food_paired': plat.isNotEmpty ? plat : null,
      'tasting_notes': notes.isNotEmpty ? notes : null,
      'photo_url': v.photoUrl,
      'co_tasters': v.convives,
      'location_name': lieu.isNotEmpty ? lieu : null,
      'is_external': true,
      'rating_scale': 10,
      'is_favorite': v.coupDeCoeur,
      'consumed_at': maintenant,
      'wines': {
        'id': wineId,
        'name': v.nom,
        'producer': producteur.isNotEmpty ? producteur : null,
        'vintage': v.millesime,
        'type': v.couleur,
        'region': region.isNotEmpty ? region : 'Autre',
        'image_url': v.photoUrl,
      },
    });

    await _apprendre(v, wineId: wineId, tastingId: tastingId, region: region, producteur: producteur);
    return (id: tastingId, enLigne: enLigne);
  }

  /// Le palais du principal et de chaque convive nommé. Sans note, rien à apprendre.
  Future<void> _apprendre(
    VinBuDehors v, {
    required String wineId,
    required String tastingId,
    required String region,
    required String producteur,
  }) async {
    final note = v.note;
    if (note == null) return;
    try {
      final vin = Wine(
        id: wineId,
        name: v.nom,
        producer: producteur,
        vintage: v.millesime,
        region: region,
        country: 'France',
        type: v.couleur,
        imageUrl: v.photoUrl,
      );
      // Avec une gorgée, le même chemin que le questionnaire complet : les micro-touches
      // sont câblées sur les axes du profil. Sans elle, le chemin court, qui n'apprend que
      // la région et le cépage. Les deux incrémentent le compteur : jamais les deux.
      Future<void> apprendre(String profileId, String profileName) async {
        if (!v.aUneGorgee) {
          return _gout.recordTastingExperience(nameOrId: profileId, wine: vin, rating: note, tastingId: tastingId);
        }
        return _gout.applyQuestionnaireResult(
          result: TastingQuestionnaireResult(
            emojiImpression: TastingQuestionnaireResult.emojiIndexForRating(note),
            noteOutOf10: note,
            // La gorgée ne mesure ni les arômes ni la bouche : on ne prétend pas le
            // contraire. Les champs restent nuls ou vides plutôt que neutres.
            perceivedAromas: const {},
            aromaIntensity: 0.5,
            acidity: null,
            body: null,
            length: 0.5,
            wouldBuyAgain: v.racheter ?? 'maybe',
            idealMoment: 'repas',
            whatLikedMost: const {},
            whatDislikedMost: const {},
            mouthfeelTexture: v.texture,
            fruitProfile: v.fruit,
            isExpressMode: true,
            profileId: profileId,
            profileName: profileName,
          ),
          wineRegion: region.isNotEmpty && region != 'Autre' ? region : null,
          wineGrapes: null,
          wineType: v.couleur,
          tastingId: tastingId,
          wineName: v.nom,
        );
      }

      final principal = await _gout.getPrimaryProfile();
      await apprendre(principal.id, principal.name);
      for (final convive in v.convivesApprennent ? v.convives : const <String>[]) {
        // Les convives sont désignés par leur nom : on résout d'abord leur profil.
        final p = await _gout.addOrGetProfileByName(convive);
        await apprendre(p.id, p.name);
      }
    } catch (e) {
      AppLogger.warning('EXTERNAL_TASTING', 'Palais non mis à jour : $e');
    }
  }
}

final degustationRapideProvider = Provider<DegustationRapide>((ref) => DegustationRapide(
      ref.read(supabaseProvider),
      ref.read(offlineStorageServiceProvider),
      ref.read(tasteProfileServiceProvider),
    ));
