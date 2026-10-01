import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../journal/data/degustation_rapide.dart';
import '../../journal/presentation/journal_screen.dart';
import '../domain/fin_de_soiree.dart';

/// « Notez-le d'un geste » (V2.3 · E2) : la bouteille choisie par la table, notée par
/// chacun sur son téléphone. Un visage suffit ; « vous en reprendriez ? » est facultatif.
///
/// Rend la note donnée, ou `null` si la personne referme sans noter.
class NoteDUnGesteSheet extends ConsumerStatefulWidget {
  final VinChoisi vin;
  final String restaurant;
  final List<String> convives;

  const NoteDUnGesteSheet({super.key, required this.vin, required this.restaurant, this.convives = const []});

  static Future<double?> show(
    BuildContext context, {
    required VinChoisi vin,
    required String restaurant,
    List<String> convives = const [],
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteDUnGesteSheet(vin: vin, restaurant: restaurant, convives: convives),
    );
  }

  @override
  ConsumerState<NoteDUnGesteSheet> createState() => _NoteDUnGesteSheetState();
}

class _NoteDUnGesteSheetState extends ConsumerState<NoteDUnGesteSheet> {
  static const _or = Color(0xFFD4AF37);
  int? _visage;
  String? _racheter;
  bool _enCours = false;

  Future<void> _enregistrer() async {
    final i = _visage;
    if (i == null || _enCours) return;
    setState(() => _enCours = true);
    final note = NoteDUnGeste.notes[i];
    final v = widget.vin;
    try {
      await ref.read(degustationRapideProvider).enregistrer(VinBuDehors(
            nom: v.nom,
            producteur: v.producteur,
            millesime: v.millesime,
            couleur: v.couleur,
            note: note,
            lieu: widget.restaurant,
            convives: widget.convives,
            convivesApprennent: false,
            racheter: _racheter,
          ));
      ref.invalidate(tastingLogProvider);
      ref.invalidate(tasteProfilesListProvider);
      if (mounted) Navigator.pop(context, note);
    } catch (e, pile) {
      AppLogger.error('TABLE', 'Note d\'un geste non enregistrée', e, pile);
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('La note n\'a pas pu être enregistrée : réessayez.', 'The rating could not be saved: try again.')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ('yes', tr('Oui', 'Yes')),
      ('maybe', tr('Peut-être', 'Maybe')),
      ('no', tr('Non', 'No')),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B1622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _or, width: 1.2)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('Le {vin}, ce soir', '{vin}, tonight', {'vin': widget.vin.libelle}),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            tr('Un geste suffit : votre palais en tiendra compte.', 'One tap is enough: your palate will learn from it.'),
            style: const TextStyle(color: Colors.white60, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < NoteDUnGeste.visages.length; i++)
                Semantics(
                  button: true,
                  selected: _visage == i,
                  label: tr('{n} sur 10', '{n} out of 10', {'n': NoteDUnGeste.notes[i]}),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => setState(() => _visage = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _visage == i ? _or.withValues(alpha: 0.25) : Colors.transparent,
                        border: Border.all(color: _visage == i ? _or : Colors.white12, width: 1.5),
                      ),
                      child: Text(NoteDUnGeste.visages[i], style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                ),
            ],
          ),
          if (_visage != null) ...[
            const SizedBox(height: 18),
            Text(
              tr('Vous en reprendriez ?', 'Would you have it again?'),
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (id, libelle) in options)
                  ChoiceChip(
                    label: Text(libelle),
                    selected: _racheter == id,
                    selectedColor: _or.withValues(alpha: 0.3),
                    onSelected: (oui) => setState(() => _racheter = oui ? id : null),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _visage == null || _enCours ? null : _enregistrer,
              icon: _enCours
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: Text(tr('Enregistrer', 'Save')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ce que la table a choisi, et pour chaque vin : le noter d'un geste, ou la note donnée.
class CarteDuChoixDeLaTable extends StatelessWidget {
  final List<VinChoisi> choix;

  /// Clé du vin → note donnée ce soir sur ce téléphone.
  final Map<String, double> notes;
  final ValueChanged<VinChoisi> onNoter;

  const CarteDuChoixDeLaTable({super.key, required this.choix, required this.notes, required this.onNoter});

  @override
  Widget build(BuildContext context) {
    const or = Color(0xFFD4AF37);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: or),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_bar_rounded, color: or, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Ce soir, la table a choisi', 'Tonight, the table chose'),
                  style: const TextStyle(color: or, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final v in choix)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(v.libelle,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  if (notes[v.cle] case final note?)
                    Text(
                      '${NoteDUnGeste.visages[NoteDUnGeste.notes.indexOf(note).clamp(0, 4)]} ${tr('noté', 'rated')}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    )
                  else
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: or),
                      onPressed: () => onNoter(v),
                      icon: const Icon(Icons.touch_app_outlined, size: 16),
                      label: Text(tr('Le noter d\'un geste', 'Rate it in one tap')),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
