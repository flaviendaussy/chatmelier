import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/admin_console_service.dart';
import '../data/admin_personnes_service.dart';
import '../domain/admin_console.dart';
import '../domain/capture_de_retour.dart';
import '../domain/admin_personnes.dart';
import 'admin_onglets.dart';

/// Les onglets de la console ajoutés en V2.4 (R9, migration 060) : les retours suivis, les
/// réglages, les versions installées, les occurrences d'une erreur. Réservés au compte
/// administrateur de Flavien.

String _raison(Object e) {
  final texte = e is PostgrestException ? e.message : '$e';
  if (texte.contains('reglage_invalide')) return 'Refusé : ${texte.split('reglage_invalide :').last.trim()}';
  if (texte.contains('reserve_admin')) return 'Réservé au compte administrateur.';
  if (texte.contains('PGRST202') || texte.contains('Could not find the function')) {
    return 'Fonction absente : la migration 060 n\'est pas encore appliquée.';
  }
  return 'Échec : $texte';
}

void _dire(BuildContext context, String texte, {bool erreur = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(texte),
    backgroundColor: erreur ? const Color(0xFFC62828) : null,
  ));
}

Future<bool> _confirmer(BuildContext context, {required String titre, required String detail}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titre),
        content: Text(detail),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Appliquer')),
        ],
      ),
    ) ??
    false;

// =============================================================================
// Retours : ce que les testeurs ont dit, et ce qui en a été fait
// =============================================================================
enum _FiltreDeRetours { aFaire, resolus, ecartes, tous }

class OngletRetours extends ConsumerStatefulWidget {
  const OngletRetours({super.key});

  @override
  ConsumerState<OngletRetours> createState() => _OngletRetoursState();
}

class _OngletRetoursState extends ConsumerState<OngletRetours> {
  _FiltreDeRetours _filtre = _FiltreDeRetours.aFaire;
  String _recherche = '';

  bool _garde(RetourSuivi r) => switch (_filtre) {
        _FiltreDeRetours.aFaire => r.statut.ouvert,
        _FiltreDeRetours.resolus => r.statut == StatutDeRetour.resolu,
        _FiltreDeRetours.ecartes => r.statut == StatutDeRetour.ecarte,
        _FiltreDeRetours.tous => true,
      };

  @override
  Widget build(BuildContext context) {
    return ref.watch(adminRetoursProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessageDEchec(erreur: '$e', migration: '060'),
          data: (tous) {
            final q = _recherche.trim().toLowerCase();
            final liste = [
              for (final r in tous)
                if (_garde(r) &&
                    (q.isEmpty ||
                        r.commentaire.toLowerCase().contains(q) ||
                        r.qui.toLowerCase().contains(q) ||
                        (r.version ?? '').toLowerCase().contains(q)))
                  r,
            ];
            int compte(bool Function(RetourSuivi) f) => tous.where(f).length;
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminRetoursProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 40),
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Chercher dans les retours, une personne, une version',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _recherche = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (f, libelle, n) in [
                        (_FiltreDeRetours.aFaire, 'À faire', compte((r) => r.statut.ouvert)),
                        (_FiltreDeRetours.resolus, 'Résolus', compte((r) => r.statut == StatutDeRetour.resolu)),
                        (_FiltreDeRetours.ecartes, 'Écartés', compte((r) => r.statut == StatutDeRetour.ecarte)),
                        (_FiltreDeRetours.tous, 'Tous', tous.length),
                      ])
                        ChoiceChip(
                          label: Text('$libelle ($n)'),
                          selected: _filtre == f,
                          onSelected: (_) => setState(() => _filtre = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (liste.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Rien ici.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ),
                  for (final r in liste) _CarteDeRetour(retour: r),
                ],
              ),
            );
          },
        );
  }
}

class _CarteDeRetour extends ConsumerWidget {
  final RetourSuivi retour;
  const _CarteDeRetour({required this.retour});

  Future<void> _changer(BuildContext context, WidgetRef ref, StatutDeRetour statut, {String? note}) async {
    try {
      await ref.read(adminConsoleServiceProvider).suivreRetour(retour.id, statut, note: note);
      ref.invalidate(adminRetoursProvider);
    } catch (e) {
      if (context.mounted) _dire(context, _raison(e), erreur: true);
    }
  }

  Future<void> _noter(BuildContext context, WidgetRef ref) async {
    final champ = TextEditingController(text: retour.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Note'),
        content: TextField(
          controller: champ,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Ce qui a été fait, ou pourquoi c\'est écarté', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, champ.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (note != null && context.mounted) await _changer(context, ref, retour.statut, note: note);
  }

  Future<void> _voirLaCapture(BuildContext context, WidgetRef ref) async {
    final service = ref.read(adminConsoleServiceProvider);
    await showDialog<void>(
      context: context,
      builder: (c) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: _FenetreDeCapture(
          signer: () => service.adresseDeCapture(retour.capture!).timeout(const Duration(seconds: 20)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = retour;
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: r.statut.couleur, borderRadius: BorderRadius.circular(6)),
                  child: Text(r.statut.libelle,
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      r.qui,
                      if (r.plateforme != null) r.plateforme!,
                      if (r.version != null) r.version!,
                    ].join(' · '),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
                if (r.quand != null)
                  Text('${dateCourte(r.quand!)} ${heure(r.quand!)}', style: TextStyle(fontSize: 11, color: gris)),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(r.commentaire, style: const TextStyle(fontSize: 13.5, height: 1.35)),
            if ((r.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note : ${r.note}', style: TextStyle(fontSize: 12, color: gris, fontStyle: FontStyle.italic)),
            ],
            Row(
              children: [
                if (r.capture != null)
                  TextButton.icon(
                    onPressed: () => _voirLaCapture(context, ref),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(r.annotations ? 'Capture annotée' : 'Capture'),
                  ),
                TextButton.icon(
                  onPressed: () => _noter(context, ref),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Note'),
                ),
                const Spacer(),
                PopupMenuButton<StatutDeRetour>(
                  tooltip: 'Changer le statut',
                  onSelected: (s) => _changer(context, ref, s),
                  itemBuilder: (_) => [
                    for (final s in StatutDeRetour.values)
                      PopupMenuItem(
                        value: s,
                        child: Row(children: [
                          Icon(Icons.circle, size: 12, color: s.couleur),
                          const SizedBox(width: 8),
                          Text(s.libelle),
                        ]),
                      ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Statut', style: TextStyle(fontSize: 13)),
                      Icon(Icons.arrow_drop_down),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Réglages : ce qui se changeait au SQL Editor
// =============================================================================
class OngletReglages extends ConsumerWidget {
  const OngletReglages({super.key});

  Future<void> _appliquer(BuildContext context, WidgetRef ref, String cle, Object? avant, Object? apres,
      {String? consequence}) async {
    final ok = await _confirmer(
      context,
      titre: DescriptionDeReglage.libelle(cle),
      detail: '${DescriptionDeReglage.difference(cle, avant, apres)}${consequence == null ? '' : '\n\n$consequence'}',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(adminConsoleServiceProvider).regler(cle, apres);
      ref.invalidate(adminReglagesProvider);
      if (cle == 'admin_detail_nominatif') ref.invalidate(adminNominatifProvider);
      if (context.mounted) _dire(context, 'Enregistré : ${DescriptionDeReglage.libelle(cle)}.');
    } catch (e) {
      if (context.mounted) _dire(context, _raison(e), erreur: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    return ref.watch(adminReglagesProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessageDEchec(erreur: '$e', migration: '060'),
          data: (r) {
            Widget interrupteur(String cle, String detail, {String? consequence}) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(DescriptionDeReglage.libelle(cle), style: const TextStyle(fontSize: 14)),
                  subtitle: Text(detail, style: const TextStyle(fontSize: 12)),
                  value: r.interrupteur(cle),
                  onChanged: (v) => _appliquer(context, ref, cle, r.valeur(cle), v, consequence: consequence),
                );
            final modeles = r.modelesIa;
            final taches = [
              ...TachesIa.libelles.keys.where(modeles.containsKey),
              ...modeles.keys.where((t) => !TachesIa.libelles.containsKey(t)),
            ];
            final version = r.valeur('version_minimale_test');
            final ecpm = r.valeur('ecpm_eur_estime');
            final quotas = r.valeur('quotas_ia');

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminReglagesProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  Text('Chaque changement est vérifié par le serveur, puis journalisé (en bas de page).',
                      style: TextStyle(fontSize: 12, color: gris, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  const _Titre('Interrupteurs'),
                  interrupteur(
                    'scan_etiquette_recherche',
                    'La description d\'une étiquette s\'appuie sur une recherche Google : plus juste, payante au-delà de 5 000 par mois.',
                  ),
                  interrupteur(
                    'ia_session_obligatoire',
                    'Les fonctions d\'IA refusent un appel sans session (mode strict, B2).',
                    consequence:
                        'Les versions antérieures à la 72 ne savent pas ouvrir de session : relevez d\'abord la version minimale.',
                  ),
                  interrupteur(
                    'admin_detail_nominatif',
                    'La console montre les prénoms et les conversations. Éteint : pseudonymes, conversations masquées.',
                  ),
                  const SizedBox(height: 16),
                  const _Titre('Modèles d\'IA'),
                  Text(
                      'Une famille suit toujours le plus récent modèle stable de Google ; un nom exact fige le modèle.',
                      style: TextStyle(fontSize: 12, color: gris)),
                  for (final t in taches)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(TachesIa.libelle(t)),
                      subtitle: Text(TachesIa.reglage(modeles[t])),
                      trailing: const Icon(Icons.tune, size: 20),
                      onTap: () async {
                        final nouveau = await _EditeurDeModele.ouvrir(context, t, modeles[t], r.modelesServis);
                        if (nouveau == null || !context.mounted) return;
                        final apres = {...modeles, t: nouveau};
                        await _appliquer(context, ref, 'modeles_ia', r.valeur('modeles_ia'), apres,
                            consequence: 'Effet immédiat, sans redéploiement.');
                      },
                    ),
                  const SizedBox(height: 16),
                  const _Titre('Version minimale'),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(version is Map && (version['build'] ?? 0) != 0
                        ? 'Build ${version['build']} au moins'
                        : 'Aucune exigence'),
                    subtitle: Text(version is Map ? '${version['message'] ?? ''}' : '',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: () async {
                      final nouvelle = await _EditeurDeVersion.ouvrir(context, ref, version);
                      if (nouvelle == null || !context.mounted) return;
                      await _appliquer(context, ref, 'version_minimale_test', version, nouvelle,
                          consequence: 'Les apps plus anciennes s\'arrêtent sur un écran de mise à jour obligatoire.');
                    },
                  ),
                  const SizedBox(height: 16),
                  const _Titre('eCPM estimés'),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(ecpm is Map
                        ? ecpm.entries.map((e) => '${e.key} ${'${e.value}'.replaceAll('.', ',')} €').join(' · ')
                        : '—'),
                    subtitle: const Text('À remplacer par les eCPM réels de la console AdMob (J7).'),
                    trailing: const Icon(Icons.edit, size: 20),
                    onTap: () async {
                      final nouveaux = await _EditeurDeNombres.ouvrir(
                        context,
                        titre: 'eCPM estimés (€ pour 1 000 affichages)',
                        valeurs: {
                          if (ecpm is Map)
                            for (final e in ecpm.entries) '${e.key}': (e.value as num?)?.toDouble() ?? 0,
                        },
                      );
                      if (nouveaux == null || !context.mounted) return;
                      await _appliquer(context, ref, 'ecpm_eur_estime', ecpm, nouveaux);
                    },
                  ),
                  const SizedBox(height: 16),
                  const _Titre('Quotas d\'IA par jour'),
                  if (quotas is Map)
                    for (final e in quotas.entries)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${e.key}'),
                        subtitle: Text(e.value is Map
                            ? '${(e.value as Map)['compte']} par compte · ${(e.value as Map)['anonyme']} sans compte'
                            : '—'),
                        trailing: const Icon(Icons.edit, size: 20),
                        onTap: () async {
                          final v = e.value is Map ? e.value as Map : const {};
                          final nouveaux = await _EditeurDeNombres.ouvrir(
                            context,
                            titre: 'Quota « ${e.key} » par jour',
                            valeurs: {
                              'compte': (v['compte'] as num?)?.toDouble() ?? 0,
                              'anonyme': (v['anonyme'] as num?)?.toDouble() ?? 0,
                            },
                            entiers: true,
                          );
                          if (nouveaux == null || !context.mounted) return;
                          await _appliquer(context, ref, 'quotas_ia', quotas, {...quotas, e.key: nouveaux});
                        },
                      ),
                  const SizedBox(height: 16),
                  const _Titre('Journal des réglages'),
                  if (r.journal.isEmpty)
                    Text('Aucun changement depuis la console.', style: TextStyle(fontSize: 12.5, color: gris)),
                  for (final c in r.journal)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, size: 20),
                      title: Text(DescriptionDeReglage.libelle(c.cle)),
                      subtitle: Text(
                        [c.resume, if (c.par != null) c.par!, if (c.le != null) '${dateCourte(c.le!)} ${heure(c.le!)}']
                            .join(' · '),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                ],
              ),
            );
          },
        );
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(texte, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
}

/// Le modèle et la réflexion d'une tâche : une famille, un modèle servi récemment, ou un nom
/// exact tapé à la main.
class _EditeurDeModele extends StatefulWidget {
  final String tache;
  final Map<String, dynamic>? actuel;
  final List<ModeleServi> servis;
  const _EditeurDeModele({required this.tache, this.actuel, required this.servis});

  static Future<Map<String, dynamic>?> ouvrir(
          BuildContext context, String tache, Map<String, dynamic>? actuel, List<ModeleServi> servis) =>
      showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _EditeurDeModele(tache: tache, actuel: actuel, servis: servis),
      );

  @override
  State<_EditeurDeModele> createState() => _EditeurDeModeleState();
}

class _EditeurDeModeleState extends State<_EditeurDeModele> {
  late String _modele = '${widget.actuel?['modele'] ?? 'flash'}';
  late String? _reflexion = widget.actuel?['reflexion'] as String?;
  late final _autre = TextEditingController(
      text: TachesIa.familles.containsKey(_modele) || widget.servis.any((s) => s.modele == _modele) ? '' : _modele);

  static final _forme = RegExp(r'^[a-z0-9][a-z0-9.-]{1,60}$');

  @override
  void dispose() {
    _autre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    final valide = _forme.hasMatch(_modele);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TachesIa.libelle(widget.tache), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 12),
            Text('Toujours le plus récent', style: TextStyle(fontSize: 12, color: gris)),
            Wrap(spacing: 6, children: [
              for (final f in TachesIa.familles.entries)
                ChoiceChip(
                  label: Text(f.value),
                  selected: _modele == f.key,
                  onSelected: (_) => setState(() {
                    _modele = f.key;
                    _autre.clear();
                  }),
                ),
            ]),
            if (widget.servis.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Servis ces trente jours', style: TextStyle(fontSize: 12, color: gris)),
              Wrap(spacing: 6, children: [
                for (final s in widget.servis)
                  ChoiceChip(
                    label: Text('${s.modele} (${s.appels})'),
                    selected: _modele == s.modele,
                    onSelected: (_) => setState(() {
                      _modele = s.modele;
                      _autre.clear();
                    }),
                  ),
              ]),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _autre,
              decoration: const InputDecoration(
                labelText: 'Ou un nom exact',
                hintText: 'gemini-3.9-flash',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _modele = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 14),
            Text('Réflexion', style: TextStyle(fontSize: 12, color: gris)),
            Wrap(spacing: 6, children: [
              for (final n in [...TachesIa.reflexions.keys, null])
                ChoiceChip(
                  label: Text(TachesIa.reflexion(n)),
                  selected: _reflexion == n,
                  onSelected: (_) => setState(() => _reflexion = n),
                ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: valide ? () => Navigator.pop(context, {'modele': _modele, 'reflexion': _reflexion}) : null,
                child: const Text('Continuer'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// La version minimale : le build exigé et le message, avec qui devra mettre à jour.
class _EditeurDeVersion extends ConsumerStatefulWidget {
  final Object? actuelle;
  const _EditeurDeVersion({this.actuelle});

  static Future<Map<String, dynamic>?> ouvrir(BuildContext context, WidgetRef ref, Object? actuelle) =>
      showDialog<Map<String, dynamic>>(context: context, builder: (_) => _EditeurDeVersion(actuelle: actuelle));

  @override
  ConsumerState<_EditeurDeVersion> createState() => _EditeurDeVersionState();
}

class _EditeurDeVersionState extends ConsumerState<_EditeurDeVersion> {
  late final Map<String, dynamic> _avant =
      widget.actuelle is Map ? Map<String, dynamic>.from(widget.actuelle as Map) : <String, dynamic>{};
  late final _build = TextEditingController(text: '${_avant['build'] ?? 0}');
  late final _buildIos = TextEditingController(text: _avant['build_ios'] == null ? '' : '${_avant['build_ios']}');
  late final _message = TextEditingController(text: '${_avant['message'] ?? ''}');

  @override
  void dispose() {
    _build.dispose();
    _buildIos.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final build = int.tryParse(_build.text.trim());
    // Vide : aucun iPhone n'est bloqué (TestFlight publie plus tard que le Play Store).
    final buildIos = int.tryParse(_buildIos.text.trim());
    final versions = ref.watch(adminVersionsProvider).valueOrNull ?? const <VersionInstallee>[];
    bool iphone(VersionInstallee v) => v.plateforme.toLowerCase() == 'ios';
    final enRetard = [
      for (final v in versions)
        if (v.plateforme != 'web')
          if (iphone(v)
              ? (buildIos != null && buildIos > 0 && (v.build ?? 0) < buildIos)
              : (build != null && build > 0 && (v.build ?? 0) < build))
            v,
    ];
    return AlertDialog(
      title: const Text('Version minimale'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _build,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Build exigé sur Android (0 : aucune exigence)', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _buildIos,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Build exigé sur iPhone (vide : aucune exigence)',
                helperText: 'Seulement une fois ce build ouvert aux testeurs sur TestFlight.',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _message,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Text(
              build == null || build == 0
                  ? 'Personne n\'est bloqué.'
                  : enRetard.isEmpty
                      ? 'Personne n\'est en retard sur la période.'
                      : 'Devront mettre à jour : ${enRetard.map((v) => '${v.qui} (${v.plateforme} ${v.version})').join(', ')}.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: build == null
              ? null
              : () => Navigator.pop(context, {
                    ..._avant,
                    'build': build,
                    'message': _message.text.trim(),
                    'lien': _avant['lien'] ?? 'https://play.google.com/store/apps/details?id=com.chatmelier.chatmelier',
                  }
                    ..remove('build_ios')
                    ..addAll({if (buildIos != null) 'build_ios': buildIos})),
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}

/// Une petite table de nombres (eCPM par format, quota d'une fonction).
class _EditeurDeNombres extends StatefulWidget {
  final String titre;
  final Map<String, double> valeurs;
  final bool entiers;
  const _EditeurDeNombres({required this.titre, required this.valeurs, this.entiers = false});

  static Future<Map<String, num>?> ouvrir(BuildContext context,
          {required String titre, required Map<String, double> valeurs, bool entiers = false}) =>
      showDialog<Map<String, num>>(
        context: context,
        builder: (_) => _EditeurDeNombres(titre: titre, valeurs: valeurs, entiers: entiers),
      );

  @override
  State<_EditeurDeNombres> createState() => _EditeurDeNombresState();
}

class _EditeurDeNombresState extends State<_EditeurDeNombres> {
  late final _champs = {
    for (final e in widget.valeurs.entries)
      e.key: TextEditingController(
          text: widget.entiers ? e.value.round().toString() : e.value.toString().replaceAll('.', ',')),
  };

  @override
  void dispose() {
    for (final c in _champs.values) {
      c.dispose();
    }
    super.dispose();
  }

  num? _lire(String texte) {
    final t = texte.trim().replaceAll(',', '.');
    return widget.entiers ? int.tryParse(t) : double.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    final lus = {for (final e in _champs.entries) e.key: _lire(e.value.text)};
    final valides = lus.values.every((v) => v != null && v >= 0);
    return AlertDialog(
      title: Text(widget.titre),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in _champs.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: e.value,
                  keyboardType: TextInputType.numberWithOptions(decimal: !widget.entiers),
                  decoration: InputDecoration(labelText: e.key, border: const OutlineInputBorder(), isDense: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: valides ? () => Navigator.pop(context, {for (final e in lus.entries) e.key: e.value!}) : null,
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}

// =============================================================================
// Les versions installées (vue d'ensemble)
// =============================================================================
class SectionVersions extends ConsumerWidget {
  const SectionVersions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    final exigence = ref.watch(adminReglagesProvider).valueOrNull?.valeur('version_minimale_test');
    final minimum = exigence is Map ? (exigence['build'] as num?)?.toInt() ?? 0 : 0;
    return ref.watch(adminVersionsProvider).when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Versions installées : ${_raison(e)}', style: TextStyle(fontSize: 12, color: gris)),
          data: (versions) {
            if (versions.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Versions installées', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  'La dernière version vue de chacun, par plateforme.'
                  '${minimum > 0 ? ' En orange : sous la version minimale ($minimum).' : ''}',
                  style: TextStyle(fontSize: 12, color: gris),
                ),
                const SizedBox(height: 8),
                for (final v in versions)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      switch (v.plateforme.toLowerCase()) {
                        'android' => Icons.android,
                        'ios' => Icons.phone_iphone,
                        'web' => Icons.public,
                        _ => Icons.devices_other,
                      },
                      color: v.plateforme != 'web' && minimum > 0 && (v.build ?? 0) < minimum
                          ? const Color(0xFFEF6C00)
                          : null,
                    ),
                    title: Text('${v.plateforme} · ${v.version}'),
                    subtitle: Text('${v.qui}${v.derniere != null ? ' · ${ilYA(v.derniere)}' : ''}',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text('${v.personnes}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
  }
}

// =============================================================================
// Les occurrences d'une erreur
// =============================================================================
class FeuilleDOccurrences extends ConsumerWidget {
  final ErreurGroupee erreur;
  const FeuilleDOccurrences({super.key, required this.erreur});

  static Future<void> ouvrir(BuildContext context, ErreurGroupee e) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (_, defilement) => FeuilleDOccurrences(erreur: e)._liste(defilement),
        ),
      );

  Widget _liste(ScrollController? defilement) => Consumer(
        builder: (context, ref, _) => ref.watch(adminOccurrencesProvider((erreur.tag, erreur.forme))).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => MessageDEchec(erreur: '$e', migration: '060'),
              data: (occurrences) => ListView(
                controller: defilement,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(erreur.tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(erreur.forme, style: const TextStyle(fontSize: 12.5)),
                  const SizedBox(height: 12),
                  for (final o in occurrences)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(
                          [
                            if (o.quand != null) '${dateCourte(o.quand!)} ${heure(o.quand!)}',
                            if (o.qui != null) o.qui!,
                            if (o.plateforme != null) o.plateforme!,
                            if (o.version != null) o.version!,
                          ].join(' · '),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(o.message,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          SelectableText(o.message, style: const TextStyle(fontSize: 12)),
                          if ((o.details ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SelectableText(o.details!,
                                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.3)),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) => _liste(null);
}

/// La capture d'un retour : signée, téléchargée (30 secondes au plus), puis affichée. Chaque
/// étape se voit, chaque échec dit sa vraie cause et se réessaie (08/10 : réseau coupé,
/// fenêtre vide pendant dix minutes).
class _FenetreDeCapture extends StatefulWidget {
  final Future<String?> Function() signer;
  const _FenetreDeCapture({required this.signer});

  @override
  State<_FenetreDeCapture> createState() => _FenetreDeCaptureState();
}

class _FenetreDeCaptureState extends State<_FenetreDeCapture> {
  String _etape = 'Signature du lien…';
  Uint8List? _image;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _etape = 'Signature du lien…';
      _image = null;
      _erreur = null;
    });
    final String? adresse;
    try {
      adresse = await widget.signer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e is FunctionException
          ? CaptureDeRetour.cause(statut: e.status, details: e.details ?? e.reasonPhrase)
          : CaptureDeRetour.causeDuTelechargement(erreur: e));
      return;
    }
    if (!mounted) return;
    if (adresse == null) {
      setState(() => _erreur = CaptureDeRetour.cause(statut: null));
      return;
    }
    setState(() => _etape = 'Téléchargement de la capture…');
    try {
      final r = await http.get(Uri.parse(adresse)).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (r.statusCode != 200) {
        setState(() => _erreur = CaptureDeRetour.causeDuTelechargement(statut: r.statusCode));
        return;
      }
      setState(() => _image = r.bodyBytes);
    } catch (e) {
      if (mounted) setState(() => _erreur = CaptureDeRetour.causeDuTelechargement(erreur: e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return InteractiveViewer(
        maxScale: 5,
        child: Image.memory(
          _image!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Capture illisible : le fichier reçu n\'est pas une image.', textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (_erreur != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Capture illisible : $_erreur.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: _charger,
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(_etape),
          ],
        ),
      ),
    );
  }
}
