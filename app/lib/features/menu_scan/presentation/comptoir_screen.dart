import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/sondage_espace.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../blind_battle/presentation/widgets/stylized_chatmelier_qr.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import '../data/menu_table_session_manager.dart';
import '../data/table_session_service.dart';
import '../domain/comptoir.dart';
import '../domain/fin_de_soiree.dart';
import '../domain/menu_wine.dart';
import 'note_d_un_geste_sheet.dart';

/// Le comptoir à plusieurs (V2.3 · J4) : autour d'une ardoise, chacun note chaque verre
/// d'un geste sur son téléphone, et le comptoir dit à la fin qui a aimé quoi.
///
/// Même primitive que la table : une session au code court, que les amis rejoignent par
/// le QR (page invité légère) ; les notes voyagent dans le profil de chacun
/// (`GuestProfile.verres`). Chaque note entre aussi au journal de celui qui l'a donnée.
class ComptoirScreen extends ConsumerStatefulWidget {
  final ScannedMenu ardoise;

  const ComptoirScreen({super.key, required this.ardoise});

  @override
  ConsumerState<ComptoirScreen> createState() => _ComptoirScreenState();
}

class _ComptoirScreenState extends ConsumerState<ComptoirScreen> {
  static const _or = Color(0xFFD4AF37);

  String? _code;
  bool _ouverture = true;

  /// L'hôte, assis à son propre comptoir, avec ses notes.
  GuestProfile? _moi;
  List<GuestProfile> _convives = const [];
  SondageEspace? _sondage;
  bool _connexionPerdue = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ouvrir());
  }

  @override
  void dispose() {
    _sondage?.arreter();
    super.dispose();
  }

  Future<void> _ouvrir() async {
    final service = ref.read(tableSessionServiceProvider);
    try {
      final t = await service.ouvrir(restaurantName: widget.ardoise.restaurantName, menu: widget.ardoise);
      final moi = await _sAsseoir(t.code);
      if (!mounted) return;
      setState(() {
        _code = t.code;
        _moi = moi;
        _ouverture = false;
      });
      _sondage = SondageEspace(
        etiquette: 'Comptoir ${t.code}',
        tache: _rafraichir,
        surAlerte: (alerte) {
          if (mounted) setState(() => _connexionPerdue = alerte);
        },
      )..demarrer();
    } catch (e) {
      AppLogger.warning('COMPTOIR', 'Ouverture du comptoir impossible : $e');
      if (mounted) setState(() => _ouverture = false);
    }
  }

  /// L'hôte s'assoit sous son prénom et avec son vrai palais, comme à table.
  Future<GuestProfile> _sAsseoir(String code) async {
    final profils = await ref.read(tasteProfilesListProvider.future);
    final principal = profils.firstWhere((p) => p.isPrimary, orElse: () => profils.first);
    final userId = ref.read(currentUserProvider)?.id;
    final compte = userId == null ? null : await ref.read(authRepositoryProvider).getProfile(userId);
    final prenom = (compte?.displayName.trim().isNotEmpty ?? false) ? compte!.displayName.trim() : principal.name;
    final moi = GuestProfile.fromTasteProfile(principal).copie(name: prenom);
    await ref.read(tableSessionServiceProvider).rejoindre(code: code, nom: prenom, profil: moi);
    return moi;
  }

  Future<bool> _rafraichir() async {
    final code = _code;
    if (code == null) return false;
    final lus = await ref.read(tableSessionServiceProvider).lireConvives(code);
    if (lus == null) return false;
    if (mounted) setState(() => _convives = lus);
    return true;
  }

  /// Les convives tels qu'affichés : ceux du serveur, et l'hôte avec ses dernières notes
  /// même avant le prochain passage du sondage.
  List<GuestProfile> get _autour {
    final moi = _moi;
    if (moi == null) return _convives;
    return [
      moi,
      for (final c in _convives)
        if (c.name.toLowerCase() != moi.name.toLowerCase()) c,
    ];
  }

  Future<void> _noter(MenuWine vin) async {
    final moi = _moi;
    final code = _code;
    final note = await NoteDUnGesteSheet.show(
      context,
      vin: VinChoisi.depuisLaCarte(vin),
      restaurant: widget.ardoise.restaurantName,
      convives: [for (final c in _autour) if (c.name != moi?.name) c.name],
    );
    if (note == null || moi == null || !mounted) return;
    final avecLaNote = moi.copie(verres: {...moi.verres, vin.cacheKey: note});
    setState(() => _moi = avecLaNote);
    if (code == null) return;
    try {
      await ref.read(tableSessionServiceProvider).rejoindre(code: code, nom: avecLaNote.name, profil: avecLaNote);
      _sondage?.relancer();
    } catch (e) {
      AppLogger.warning('COMPTOIR', 'Note non transmise au comptoir $code : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bilan = BilanDuComptoir.dresser(widget.ardoise.wines, _autour);
    final phrases = bilan.phrases;
    final code = _code;
    return Scaffold(
      backgroundColor: const Color(0xFF140F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140F1A),
        foregroundColor: Colors.white,
        title: Text(tr('Le comptoir · {bar}', 'The bar · {bar}', {'bar': widget.ardoise.restaurantName})),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_connexionPerdue)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(tr('Connexion perdue avec le comptoir.', 'Lost the connection to the bar.'),
                        style: const TextStyle(color: Colors.orangeAccent)),
                  ),
                  TextButton(onPressed: () => _sondage?.relancer(), child: Text(tr('Réessayer', 'Try again'))),
                ],
              ),
            ),
          if (_ouverture)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (code == null)
            Text(
              tr('Le comptoir n\'a pas pu s\'ouvrir : vérifiez la connexion et réessayez.',
                  'The bar could not be opened: check your connection and try again.'),
              style: const TextStyle(color: Colors.white70),
            )
          else ...[
            Center(
              child: StylizedChatmelierQr(
                sessionId: code,
                title: tr('LE COMPTOIR CHATMELIER', 'CHATMELIER BAR'),
                icon: Icons.local_bar_rounded,
                customUrl: MenuTableSessionManager.buildQrUrl(sessionId: code, menu: widget.ardoise, code: code),
                shareMessage: tr('Rejoins le comptoir sur Chatmelier pour noter les verres avec nous ! Code : {code} — {lien}',
                    'Join the bar on Chatmelier and rate the glasses with us! Code: {code} — {lien}', {
                  'code': code,
                  'lien': MenuTableSessionManager.buildQrUrl(sessionId: code, menu: widget.ardoise, code: code),
                }),
                shareSubject: tr('Comptoir Chatmelier — code {code}', 'Chatmelier bar — code {code}', {'code': code}),
                size: 200,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr('Chacun scanne le code, et note chaque verre d\'un geste.', 'Everyone scans the code and rates each glass in one tap.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 16),
          if (phrases.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _or),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Qui a aimé quoi', 'Who liked what'),
                      style: const TextStyle(color: _or, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  for (final p in phrases)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(p, style: const TextStyle(color: Colors.white, height: 1.35)),
                    ),
                ],
              ),
            ),
          for (final v in bilan.verres) _carteDuVerre(v),
        ],
      ),
    );
  }

  Widget _carteDuVerre(VerreDuComptoir v) {
    final moi = _moi;
    final maNote = moi?.verres[v.vin.cacheKey];
    final autres = {
      for (final e in v.notes.entries)
        if (e.key != moi?.name) e.key: e.value,
    };
    final prix = v.vin.glassPrices.isNotEmpty
        ? '${v.vin.formaterPrix(v.vin.glassPrices.first.price)}/${v.vin.glassPrices.first.format}'
        : (v.vin.bottlePrice != null ? v.vin.formaterPrix(v.vin.bottlePrice!) : '');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _or.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${v.vin.name}${v.vin.vintage != null ? ' ${v.vin.vintage}' : ''}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (prix.isNotEmpty) Text(prix, style: const TextStyle(color: _or, fontWeight: FontWeight.bold)),
            ],
          ),
          if (v.vin.producer.trim().isNotEmpty)
            Text(v.vin.producer, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          if (autres.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in autres.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF2A1E33), borderRadius: BorderRadius.circular(20)),
                    child: Text('${VerreDuComptoir.visage(e.value)} ${e.key}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: maNote != null
                ? TextButton(
                    onPressed: () => _noter(v.vin),
                    child: Text(tr('{visage} noté · changer', '{visage} rated · change', {'visage': VerreDuComptoir.visage(maNote)}),
                        style: const TextStyle(color: _or)),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _or,
                      side: const BorderSide(color: _or),
                    ),
                    onPressed: _code == null ? null : () => _noter(v.vin),
                    child: Text(tr('Le noter d\'un geste', 'Rate it in one tap')),
                  ),
          ),
        ],
      ),
    );
  }
}
