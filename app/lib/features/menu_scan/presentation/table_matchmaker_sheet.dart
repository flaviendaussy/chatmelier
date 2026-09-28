import 'package:flutter/material.dart';

import '../../sommelier/domain/guest_matcher_engine.dart';
import '../domain/menu_wine.dart';
import '../domain/table_matchmaker.dart';

/// Le matchmaker de la table : un vin après l'autre, un avis par vin, rien n'est écarté.
///
/// Rend les avis donnés (clé du vin → avis), même si l'on ferme avant la fin : trois
/// avis aident déjà la table.
class TableMatchmakerSheet extends StatefulWidget {
  final List<MenuWine> candidats;
  final GuestProfile moi;
  final Map<String, AvisDeTable> avisDeja;
  final bool isFr;

  const TableMatchmakerSheet({
    super.key,
    required this.candidats,
    required this.moi,
    required this.isFr,
    this.avisDeja = const {},
  });

  static Future<Map<String, AvisDeTable>?> show(
    BuildContext context, {
    required List<MenuWine> candidats,
    required GuestProfile moi,
    required bool isFr,
    Map<String, AvisDeTable> avisDeja = const {},
  }) =>
      showModalBottomSheet<Map<String, AvisDeTable>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        // Le glissement fermerait la feuille sans rendre les avis déjà donnés : la croix,
        // le retour et « Voir le choix de la table » les rendent tous.
        enableDrag: false,
        builder: (_) => TableMatchmakerSheet(candidats: candidats, moi: moi, isFr: isFr, avisDeja: avisDeja),
      );

  @override
  State<TableMatchmakerSheet> createState() => _TableMatchmakerSheetState();
}

class _TableMatchmakerSheetState extends State<TableMatchmakerSheet> {
  late final Map<String, AvisDeTable> _avis = {...widget.avisDeja};
  int _index = 0;

  static const _or = Color(0xFFD4AF37);
  static const _bordeaux = Color(0xFF8B1E3F);

  void _donner(AvisDeTable? avis) {
    final vin = widget.candidats[_index];
    setState(() {
      if (avis != null) _avis[vin.cacheKey] = avis;
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fr = widget.isFr;
    final total = widget.candidats.length;
    final fini = _index >= total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (aPop, _) {
        if (!aPop) Navigator.of(context).pop(_avis);
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1322),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.how_to_vote_rounded, color: _or),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fr ? 'Le matchmaker de la table' : 'The table matchmaker',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    tooltip: fr ? 'Fermer' : 'Close',
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(_avis),
                  ),
                ],
              ),
              Text(
                fr
                    ? 'Rien n\'est écarté : votre avis sur chaque vin aide la table à trouver celui qui plaira à tous.'
                    : 'Nothing is ruled out: your view on each wine helps the table find the one everyone enjoys.',
                style: const TextStyle(color: Colors.white60, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: total == 0 ? 1 : _index / total,
                color: _or,
                backgroundColor: Colors.white12,
              ),
              const SizedBox(height: 16),
              if (fini) ..._merci(fr) else ..._carteDuVin(widget.candidats[_index], fr, total),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _carteDuVin(MenuWine vin, bool fr, int total) {
    final m = vin.metrics;
    String n(double v) => '${v.round()}/10';
    final traits = [
      if (vin.isRed) '${fr ? 'Tanins' : 'Tannins'} ${n(m.tannins)}',
      '${fr ? 'Fraîcheur' : 'Freshness'} ${n(m.acidity)}',
      '${fr ? 'Corps' : 'Body'} ${n(m.body)}',
      '${fr ? 'Bois' : 'Oak'} ${n(m.oak)}',
    ];
    final horsCouleur = TableMatchmaker.horsDeSesCouleurs(vin, widget.moi);

    return [
      Text(
        fr ? 'Vin ${_index + 1} sur $total' : 'Wine ${_index + 1} of $total',
        style: const TextStyle(color: _or, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF251C30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vin.colorIndicator.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wine_bar, color: vin.colorIndicator),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vin.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(vin.priceDisplay, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${vin.producer} • ${vin.vintage ?? 'NM'} • ${vin.appellation ?? vin.region ?? ''}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(traits.join(' · '), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if ((vin.sommelierComment ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                vin.sommelierComment!,
                style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
      // Au moment où un vin d'une autre couleur arrive, on dit pourquoi on en parle encore.
      if (horsCouleur) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _or.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _or.withValues(alpha: 0.4)),
          ),
          child: Text(
            TableMatchmaker.pourquoiCeVin(vin, widget.moi, fr),
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
        ),
      ],
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.4,
        children: [
          for (final (avis, icone, couleur) in const [
            (AvisDeTable.adore, Icons.favorite, _bordeaux),
            (AvisDeTable.ok, Icons.thumb_up_alt_outlined, Color(0xFF2E7D32)),
            (AvisDeTable.plutotPas, Icons.thumb_down_alt_outlined, Color(0xFF8D6E63)),
            (AvisDeTable.non, Icons.close, Color(0xFF616161)),
          ])
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: couleur,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _donner(avis),
              icon: Icon(icone, size: 18),
              label: Text(avis.libelle(fr), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      Center(
        child: TextButton(
          onPressed: () => _donner(null),
          child: Text(fr ? 'Passer ce vin' : 'Skip this wine', style: const TextStyle(color: Colors.white54)),
        ),
      ),
    ];
  }

  List<Widget> _merci(bool fr) => [
        const Center(child: Icon(Icons.check_circle, color: _or, size: 48)),
        const SizedBox(height: 10),
        Center(
          child: Text(
            fr
                ? 'Merci ! Vos ${_avis.length} avis partent à la table.'
                : 'Thanks! Your ${_avis.length} views are on their way to the table.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            fr
                ? 'Le classement de la table se met à jour avec les avis de chacun.'
                : 'The table\'s ranking updates with everyone\'s views.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _bordeaux, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () => Navigator.of(context).pop(_avis),
            child: Text(fr ? 'Voir le choix de la table' : 'See the table\'s choice'),
          ),
        ),
      ];
}
