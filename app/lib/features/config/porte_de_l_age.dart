import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/app_logger.dart';
import '../../shared/utils/langue.dart';
import '../offline/presentation/sync_provider.dart';

/// L'âge légal, demandé une fois à la première ouverture (PROD_MIGRATION.md · Alcool,
/// fait le 08/10) : Chatmelier parle de vin, sur le téléphone comme sur le web.
///
/// Une déclaration, comme sur les sites des maisons de vin : rien n'est vérifié, rien
/// n'est envoyé. La réponse reste sur l'appareil. Un « non » n'est pas retenu : un doigt
/// qui glisse ne ferme pas l'app pour toujours.
class PorteDeLAge extends ConsumerStatefulWidget {
  final Widget child;

  const PorteDeLAge({super.key, required this.child});

  static const cle = 'chatmelier_age_legal_v1';

  @override
  ConsumerState<PorteDeLAge> createState() => _PorteDeLAgeState();
}

class _PorteDeLAgeState extends ConsumerState<PorteDeLAge> {
  late bool _ouverte;
  bool _refus = false;

  @override
  void initState() {
    super.initState();
    try {
      _ouverte = ref.read(sharedPreferencesInstanceProvider).getBool(PorteDeLAge.cle) == true;
    } catch (_) {
      // Sans préférences lisibles (hors de l'app), on ne bloque pas.
      _ouverte = true;
    }
  }

  Future<void> _entrer() async {
    setState(() => _ouverte = true);
    try {
      await ref.read(sharedPreferencesInstanceProvider).setBool(PorteDeLAge.cle, true);
    } catch (_) {}
    AppLogger.info('AGE', 'Âge légal déclaré');
  }

  @override
  Widget build(BuildContext context) {
    if (_ouverte) return widget.child;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo_transparent_64.png', width: 72, height: 72),
                  const SizedBox(height: 18),
                  Text(
                    _refus
                        ? tr('À bientôt', 'See you soon')
                        : tr('Chatmelier parle de vin', 'Chatmelier is about wine'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _refus
                        ? tr('Chatmelier est réservé aux personnes qui ont l\'âge légal de boire de l\'alcool. Il vous attendra.',
                            'Chatmelier is for people of legal drinking age. It will wait for you.')
                        : tr('Il est réservé aux personnes qui ont l\'âge légal de boire de l\'alcool dans leur pays.',
                            'It is for people of legal drinking age in their country.'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 26),
                  if (!_refus) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E3F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _entrer,
                        child: Text(tr('J\'ai l\'âge légal', 'I am of legal drinking age')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _refus = true),
                      child: Text(tr('Je ne l\'ai pas', 'I am not')),
                    ),
                  ] else
                    TextButton(
                      onPressed: () => setState(() => _refus = false),
                      child: Text(tr('Revenir', 'Back')),
                    ),
                  const SizedBox(height: 26),
                  Text(
                    tr('L\'abus d\'alcool est dangereux pour la santé. À consommer avec modération.',
                        'Alcohol abuse is dangerous for your health. Drink responsibly.'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
