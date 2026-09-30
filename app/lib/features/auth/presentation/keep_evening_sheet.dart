import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/croissance.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/app_logger.dart';
import 'package:flutter/services.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/palais_distant.dart';
import '../../../shared/utils/langue.dart';

/// Garder la soirée : ajouter une adresse à un compte déjà ouvert.
///
/// **Ce qui se joue.** La personne a un vrai compte depuis son premier geste, mais
/// anonyme : tout ce qu'elle a accumulé ce soir existe côté serveur sous un identifiant
/// qu'elle ne peut pas retrouver depuis un autre appareil, et qui sera purgé au bout de
/// trente jours. Ajouter une adresse ne déplace rien — l'identifiant reste le même, donc
/// l'historique aussi.
///
/// **Et ce qu'on refuse de faire.** Pas d'urgence fabriquée, pas de compte à rebours, pas
/// de « dernière chance ». La perte est réelle et se décrit exactement ; c'est ce qui rend
/// la phrase crédible, et c'est aussi ce qui marche le mieux. Une urgence inventée se
/// sent, et elle abîme la confiance qu'on passe le reste du produit à construire.
class KeepEveningSheet extends ConsumerStatefulWidget {
  /// Ce qui a été accumulé, dit en toutes lettres. Vide si l'on n'a rien à montrer — et
  /// dans ce cas la feuille ne devrait pas s'ouvrir du tout.
  final List<String> cequiSeraGarde;

  const KeepEveningSheet({super.key, required this.cequiSeraGarde});

  static Future<bool?> show(
    BuildContext context, {
    required List<String> cequiSeraGarde,
  }) {
    // Rien à garder, rien à demander. Réclamer une adresse pour sauvegarder le vide est
    // la manière la plus sûre de ne jamais l'obtenir.
    if (cequiSeraGarde.isEmpty) return Future.value(null);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: KeepEveningSheet(cequiSeraGarde: cequiSeraGarde),
      ),
    );
  }

  @override
  ConsumerState<KeepEveningSheet> createState() => _KeepEveningSheetState();
}

class _KeepEveningSheetState extends ConsumerState<KeepEveningSheet> {
  final _email = TextEditingController();
  bool _enCours = false;
  bool _envoye = false;
  String? _erreur;

  /// Le code de reprise, une fois obtenu (P6) : pour qui ne veut pas donner d'adresse.
  String? _codeDeReprise;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _garder({required bool isFr}) async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erreur = trSi(isFr, 'Cette adresse ne ressemble pas à une adresse.', 'That doesn\'t look like an email address.'));
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(authRepositoryProvider).convertirEnCompte(email);
      unawaited(Croissance.noter('soiree_gardee', source: 'email'));
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _envoye = true;
      });
    } catch (e) {
      AppLogger.warning('AUTH', 'Conversion impossible: $e');
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = trSi(isFr, 'L\'envoi a échoué. Vérifiez votre connexion et réessayez.', 'Sending failed. Check your connection and try again.');
      });
    }
  }

  /// Sans adresse : un code de huit signes, valable trente jours, qui rend la soirée sur
  /// n'importe quel appareil. Le palais part d'abord au serveur — sinon le code rendrait
  /// une soirée sans palais.
  Future<void> _obtenirUnCode({required bool isFr}) async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await PalaisDistant.envoyer();
      final code = await ref.read(supabaseProvider).rpc('creer_code_de_reprise');
      unawaited(Croissance.noter('soiree_gardee', source: 'code'));
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _codeDeReprise = code?.toString();
      });
    } catch (e) {
      AppLogger.warning('REPRISE', 'Code de reprise impossible : $e');
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = trSi(isFr, 'Impossible d\'obtenir un code. Vérifiez votre connexion.', 'Couldn\'t get a code. Check your connection.');
      });
    }
  }

  Widget _vueDuCode(ThemeData theme, bool isFr) {
    final code = _codeDeReprise!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(trSi(isFr, 'Votre code de reprise', 'Your recovery code'),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Center(
          child: SelectableText(
            code,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 6),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(trSi(isFr, 'Code copié', 'Code copied'))),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(trSi(isFr, 'Copier', 'Copy')),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          trSi(isFr, 'Sur n\'importe quel appareil, pendant trente jours : « Retrouver ma soirée », ' 'puis ce code. Il ne sert qu\'une fois, et ouvre votre soirée : ne le donnez à personne.', 'On any device, for thirty days: "Recover my evening", then this code. It works ' 'once, and opens your evening: don\'t give it to anyone.'),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(trSi(isFr, 'Je l\'ai noté', 'I\'ve written it down')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_codeDeReprise != null) ...[
              _vueDuCode(theme, isFr),
            ] else if (_envoye) ...[
              const Icon(Icons.mark_email_read_outlined,
                  size: 40, color: Color(0xFF10B981)),
              const SizedBox(height: 12),
              Text(
                trSi(isFr, 'Vérifiez votre boîte mail', 'Check your inbox'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                trSi(isFr, 'Un lien de confirmation part vers {v1}. ' 'Ouvrez-le depuis n\'importe quel appareil : votre soirée y sera.', 'A confirmation link is on its way to {v1}. ' 'Open it from any device: your evening will be there.', {'v1': _email.text.trim()}),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: Text(trSi(isFr, 'Terminé', 'Done')),
              ),
            ] else ...[
              Text(
                trSi(isFr, 'Garder cette soirée', 'Keep this evening'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              for (final ligne in widget.cequiSeraGarde)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                          child: Text(ligne,
                              style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                trSi(isFr, 'Tout est gardé trente jours sur cet appareil. Ajoutez votre ' 'adresse pour le conserver, et le retrouver ailleurs.', 'Everything is kept for thirty days on this device. Add your ' 'email to keep it, and find it elsewhere.'),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: trSi(isFr, 'Votre adresse e-mail', 'Your email'),
                  errorText: _erreur,
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => _garder(isFr: isFr),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _enCours ? null : () => _garder(isFr: isFr),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _enCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(trSi(isFr, 'Garder ma soirée', 'Keep my evening')),
              ),
              Center(
                child: TextButton(
                  onPressed: _enCours ? null : () => _obtenirUnCode(isFr: isFr),
                  child: Text(
                    trSi(isFr, 'Pas d\'adresse ? Obtenir un code de reprise', 'No email? Get a recovery code'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    trSi(isFr, 'Pas maintenant', 'Not now'),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
