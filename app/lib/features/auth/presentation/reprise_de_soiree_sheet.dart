import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../data/palais_distant.dart';
import '../../journal/presentation/journal_screen.dart' show tastingLogProvider;

/// Ce que rend le serveur quand on présente un code de reprise (migration 050).
class ResultatDeReprise {
  final String? erreur;
  final bool deja;
  final int degustations;
  final int tables;
  final bool palais;

  const ResultatDeReprise({this.erreur, this.deja = false, this.degustations = 0, this.tables = 0, this.palais = false});

  factory ResultatDeReprise.depuis(Object? json) {
    // Une réponse vide n'est pas un succès : on ne dit jamais « retrouvée » sans preuve.
    if (json is! Map) return const ResultatDeReprise(erreur: 'reponse_vide');
    final m = json;
    int n(Object? v) => v is num ? v.toInt() : 0;
    return ResultatDeReprise(
      erreur: m['erreur']?.toString(),
      deja: m['deja'] == true,
      degustations: n(m['degustations']),
      tables: n(m['tables']),
      palais: m['palais'] == true,
    );
  }

  bool get reussi => erreur == null && !deja;

  /// La phrase à montrer. Les échecs sont dits sans rien révéler : un code inconnu,
  /// expiré ou déjà servi reçoivent la même réponse.
  String get message {
    switch (erreur) {
      case 'code_invalide':
        return tr('Ce code ne correspond à aucune soirée. Il a peut-être expiré (trente jours), ou déjà servi.',
            'This code doesn\'t match any evening. It may have expired (thirty days), or already been used.');
      case 'trop_de_tentatives':
        return tr('Trop d\'essais. Réessayez dans une heure.', 'Too many attempts. Try again in an hour.');
      case 'reprise_suspendue':
        return tr('La reprise est momentanément suspendue. Réessayez plus tard.',
            'Recovery is paused for a moment. Try again later.');
      case 'compte_deja_utilise':
        return tr('Ce compte a déjà sa propre histoire : la reprise ne fusionne pas deux palais.',
            'This account already has its own history: recovery doesn\'t merge two palates.');
      case null:
        break;
      default:
        return tr('Reprise impossible pour le moment. Vérifiez votre connexion.',
            'Recovery isn\'t possible right now. Check your connection.');
    }
    if (deja) return tr('Cette soirée est déjà sur ce compte.', 'This evening is already on this account.');
    final morceaux = [
      if (degustations > 0) tr('$degustations ${degustations > 1 ? 'dégustations' : 'dégustation'}', '$degustations ${degustations > 1 ? 'tastings' : 'tasting'}'),
      if (tables > 0) tr('$tables ${tables > 1 ? 'tables' : 'table'}', '$tables ${tables > 1 ? 'tables' : 'table'}'),
      if (palais) tr('votre palais', 'your palate'),
    ];
    return morceaux.isEmpty
        ? tr('Soirée retrouvée.', 'Evening recovered.')
        : tr('Soirée retrouvée : ${morceaux.join(', ')}.', 'Evening recovered: ${morceaux.join(', ')}.');
  }
}

/// Retrouver sa soirée avec un code de reprise, sur n'importe quel appareil (P6).
class RepriseDeSoireeSheet extends ConsumerStatefulWidget {
  /// Remplaçable dans les tests : présente le code au serveur.
  final Future<ResultatDeReprise> Function(String code)? reprendre;

  const RepriseDeSoireeSheet({super.key, this.reprendre});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: const RepriseDeSoireeSheet(),
        ),
      );

  /// « abcd efgh », « ABCD-EFGH » → « ABCDEFGH ».
  static String normaliser(String saisie) => saisie.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  @override
  ConsumerState<RepriseDeSoireeSheet> createState() => _RepriseDeSoireeSheetState();
}

class _RepriseDeSoireeSheetState extends ConsumerState<RepriseDeSoireeSheet> {
  final _code = TextEditingController();
  bool _enCours = false;
  ResultatDeReprise? _resultat;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<ResultatDeReprise> _reprendreParLeServeur(String code) async {
    // Il faut une session pour recevoir la soirée : anonyme au besoin.
    final auth = ref.read(authRepositoryProvider);
    final moi = await auth.assurerUneSession();
    if (moi == null) return const ResultatDeReprise(erreur: 'non_connecte');
    final reponse = await ref.read(supabaseProvider).rpc('reprendre_avec_code', params: {'p_code': code});
    final resultat = ResultatDeReprise.depuis(reponse);
    if (resultat.reussi) {
      // Le palais repris remplace celui (vierge) de cet appareil, et le journal se recharge
      // avec les dégustations de la soirée.
      await PalaisDistant.recuperer(forcer: true);
      ref.invalidate(tastingLogProvider);
    }
    return resultat;
  }

  Future<void> _reprendre() async {
    final code = RepriseDeSoireeSheet.normaliser(_code.text);
    if (code.length != 8) return;
    setState(() {
      _enCours = true;
      _resultat = null;
    });
    ResultatDeReprise r;
    try {
      r = await (widget.reprendre ?? _reprendreParLeServeur)(code);
    } catch (e) {
      AppLogger.warning('REPRISE', 'Reprise impossible : $e');
      r = const ResultatDeReprise(erreur: 'reseau');
    }
    if (r.reussi) AppLogger.info('REPRISE', 'Soirée reprise (${r.degustations} dégustations, palais : ${r.palais})');
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _resultat = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pret = RepriseDeSoireeSheet.normaliser(_code.text).length == 8;
    final r = _resultat;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Retrouver ma soirée', 'Recover my evening'),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              tr('Le code de reprise à huit signes obtenu en fin de soirée.',
                  'The eight-character recovery code you got at the end of the evening.'),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            if (r != null && r.reussi) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.message, style: theme.textTheme.bodyLarge)),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(tr('Terminé', 'Done')),
              ),
            ] else ...[
              TextField(
                controller: _code,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 5),
                inputFormatters: [
                  // L'alphabet du serveur : ni 0/O ni 1/I, qui se confondent.
                  FilteringTextInputFormatter.allow(RegExp('[ABCDEFGHJKLMNPQRSTUVWXYZ23456789abcdefghjklmnpqrstuvwxyz -]')),
                  LengthLimitingTextInputFormatter(10),
                  TextInputFormatter.withFunction((_, n) => n.copyWith(text: n.text.toUpperCase())),
                ],
                decoration: InputDecoration(
                  hintText: 'ABCD-EFGH',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setState(() => _resultat = null),
                onSubmitted: (_) => pret ? _reprendre() : null,
              ),
              if (r != null) ...[
                const SizedBox(height: 12),
                Text(r.message, style: TextStyle(color: r.deja ? null : theme.colorScheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: (!pret || _enCours) ? null : _reprendre,
                icon: _enCours
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.restore_rounded),
                label: Text(tr('Retrouver ma soirée', 'Recover my evening')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
