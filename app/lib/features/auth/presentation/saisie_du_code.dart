import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../domain/retour_du_lien.dart';

/// Taper le code du même e-mail que le lien (V2.5 · Q11, Camille, 18/10).
///
/// Le code ne dépend pas du navigateur : il connecte là où on le tape, que le lien se soit
/// ouvert dans l'app de messagerie, sur un autre appareil, ou pas du tout. Il demande que
/// le modèle d'e-mail de Supabase contienne `{{ .Token }}` (« Magic Link » et « Confirm
/// signup »).
class SaisieDuCode extends ConsumerStatefulWidget {
  /// L'adresse à laquelle le lien et son code sont partis, lue au moment de valider.
  final String Function() adresse;

  /// Une fois connecté.
  final VoidCallback onConnecte;

  const SaisieDuCode({super.key, required this.adresse, required this.onConnecte});

  @override
  ConsumerState<SaisieDuCode> createState() => _SaisieDuCodeState();
}

class _SaisieDuCodeState extends ConsumerState<SaisieDuCode> {
  final _code = TextEditingController();
  bool _enCours = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final adresse = widget.adresse().trim();
    final code = _code.text.trim();
    final messager = ScaffoldMessenger.of(context);
    if (adresse.isEmpty || !adresse.contains('@')) {
      messager.showSnackBar(SnackBar(
        content: Text(tr('Indiquez d\'abord l\'adresse e-mail à laquelle le code est arrivé.',
            'First enter the email address the code was sent to.')),
      ));
      return;
    }
    // Six chiffres par défaut chez Supabase, jusqu'à dix selon le réglage du projet.
    if (!RegExp(r'^\d{6,10}$').hasMatch(code)) {
      messager.showSnackBar(SnackBar(
        content: Text(tr('Le code ne contient que des chiffres : recopiez-le tel qu\'il figure dans l\'e-mail.',
            'The code is digits only: copy it exactly as it appears in the email.')),
      ));
      return;
    }
    setState(() => _enCours = true);
    try {
      await ref.read(authRepositoryProvider).verifyEmailOtp(adresse, code);
      lienSansEffet.value = null;
      AppLogger.info('AUTH', 'Connexion par le code de l\'e-mail');
      if (mounted) widget.onConnecte();
    } catch (e) {
      // Le motif seulement, jamais le code.
      final motif = e is AuthException ? (e.code ?? e.message) : e.runtimeType.toString();
      AppLogger.warning('AUTH', 'Code de connexion refusé : ${motif.length > 120 ? motif.substring(0, 120) : motif}');
      if (mounted) {
        messager.showSnackBar(SnackBar(
          content: Text(tr('Ce code ne marche pas. Il a peut-être expiré, ou un lien plus récent l\'a remplacé : demandez un nouveau lien.',
              'That code doesn\'t work. It may have expired, or a newer link replaced it: ask for a new link.')),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 7),
        ));
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Le lien ne vous connecte pas ? Tapez ici le code du même e-mail.',
              'Link didn\'t sign you in? Type the code from the same email here.'),
          style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('saisie_du_code'),
                controller: _code,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _enCours ? null : _valider(),
                decoration: InputDecoration(
                  labelText: tr('Code reçu', 'Code'),
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('valider_le_code'),
              onPressed: _enCours ? null : _valider,
              child: _enCours
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(tr('Valider', 'Confirm')),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ce que l'écran de connexion dit d'un lien ouvert sans effet (Q11) : le motif, et quoi
/// faire, au lieu de revenir en silence à l'adresse e-mail.
class AvisLienSansEffet extends StatelessWidget {
  final RetourDuLien retour;

  const AvisLienSansEffet({super.key, required this.retour});

  @override
  Widget build(BuildContext context) {
    final texte = retour.expire
        ? tr('Ce lien a expiré, ou il a déjà servi. Demandez-en un nouveau ci-dessous.',
            'This link has expired or has already been used. Ask for a new one below.')
        : tr('Ce lien n\'a pas pu vous connecter ici : il s\'est sans doute ouvert dans un autre navigateur que celui où vous l\'avez demandé (celui de votre messagerie, par exemple). Tapez plutôt le code du même e-mail, ou demandez un nouveau lien ici.',
            'This link couldn\'t sign you in here: it probably opened in a different browser from the one you asked for it in (your email app\'s, for example). Type the code from the same email instead, or ask for a new link here.');
    return Container(
      key: const Key('avis_lien_sans_effet'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35)),
          ),
        ],
      ),
    );
  }
}
