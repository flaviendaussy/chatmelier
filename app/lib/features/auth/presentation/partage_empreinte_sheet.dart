import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../domain/taste_profile.dart';
import 'widgets/carte_empreinte.dart';

/// Montre l'empreinte telle qu'elle partira, puis la partage en image (P5).
///
/// L'aperçu d'abord : on ne publie pas son palais à l'aveugle. L'image est celle-là même
/// qu'on voit, capturée à la résolution d'export.
class PartageEmpreinteSheet extends StatefulWidget {
  final TasteProfile profil;
  final String? nom;

  const PartageEmpreinteSheet({super.key, required this.profil, this.nom});

  static Future<void> show(BuildContext context, {required TasteProfile profil, String? nom}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PartageEmpreinteSheet(profil: profil, nom: nom),
    );
  }

  /// Rend [cle] (une `RepaintBoundary`) en PNG, à la taille d'export de la carte.
  static Future<Uint8List?> capturer(GlobalKey cle) async {
    final limite = cle.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (limite == null) return null;
    final image = await limite.toImage(pixelRatio: 3);
    final octets = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return octets?.buffer.asUint8List();
  }

  @override
  State<PartageEmpreinteSheet> createState() => _PartageEmpreinteSheetState();
}

class _PartageEmpreinteSheetState extends State<PartageEmpreinteSheet> {
  final _carte = GlobalKey();
  bool _enCours = false;

  Future<void> _partager() async {
    setState(() => _enCours = true);
    try {
      final png = await PartageEmpreinteSheet.capturer(_carte);
      if (png == null) throw StateError('carte non rendue');
      await Share.shareXFiles(
        [XFile.fromData(png, mimeType: 'image/png', name: 'empreinte-de-palais.png')],
        text: tr('Mon empreinte de palais, par Chatmelier : https://chatmelier.github.io',
            'My palate fingerprint, by Chatmelier: https://chatmelier.github.io'),
      );
      // La mesure du viral : combien d'empreintes partent (console, onglet Fonctionnalités).
      AppLogger.info('PARTAGE_EMPREINTE', 'Empreinte partagée (${widget.profil.overallConfidence.toStringAsFixed(2)} connue)');
    } catch (e) {
      AppLogger.warning('PARTAGE_EMPREINTE', 'Partage impossible : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('Impossible de préparer l\'image. Réessayez.', 'Couldn\'t prepare the image. Try again.')),
        ));
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.withAlpha(100), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Text(
            tr('Partager mon empreinte', 'Share my palate'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            tr('Trait plein : ce que Chatmelier a observé. Pointillés : ce qu\'il devine encore.',
                'Solid line: what Chatmelier has observed. Dashed: what it still guesses.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: FittedBox(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  key: _carte,
                  child: CarteEmpreinte(profil: widget.profil, nom: widget.nom),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _enCours ? null : _partager,
              icon: _enCours
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.ios_share, size: 18),
              label: Text(tr('Partager l\'image', 'Share the image')),
            ),
          ),
        ],
      ),
    );
  }
}
