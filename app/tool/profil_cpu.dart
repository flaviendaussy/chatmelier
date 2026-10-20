// Profil CPU d'une app Chatmelier en mode profile, par le service VM (revue du 20/10).
//
//   adb forward tcp:8181 tcp:<port du journal « Dart VM service is listening on »>
//   dart run tool/profil_cpu.dart ws://127.0.0.1:8181/<jeton>=/ws <secondes>
//
// Efface les échantillons, attend [secondes] (faire le geste à mesurer pendant ce temps),
// puis classe les fonctions de l'isolat principal par temps propre et par temps inclusif.
// Outil de mesure : rien n'en dépend dans l'app.
// ignore_for_file: avoid_print
import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  final uri = args[0];
  final secondes = int.parse(args.length > 1 ? args[1] : '15');
  final service = await vmServiceConnectUri(uri);
  final vm = await service.getVM();
  final isolats = vm.isolates ?? const [];
  final principal = isolats.firstWhere((i) => (i.name ?? '').contains('main'), orElse: () => isolats.first);
  final id = principal.id!;
  // Comme DevTools : le profileur est éteint par défaut.
  await service.setFlag('profiler', 'true');
  await service.setFlag('profile_period', '250');
  await service.clearCpuSamples(id);
  final debut = (await service.getVMTimelineMicros()).timestamp!;
  print('⏺  ${principal.name} — $secondes s : faites le geste maintenant');
  await Future<void>.delayed(Duration(seconds: secondes));
  final fin = (await service.getVMTimelineMicros()).timestamp!;
  final echantillons = await service.getCpuSamples(id, debut, fin - debut);
  final fonctions = echantillons.functions ?? const [];
  String nom(int i) {
    final f = fonctions[i].function;
    if (f is FuncRef) {
      final owner = f.owner;
      final classe = owner is ClassRef ? '${owner.name}.' : '';
      final lib = (owner is ClassRef ? owner.library?.uri : (owner is LibraryRef ? owner.uri : null)) ?? '';
      final court = lib.contains('chatmelier/') ? lib.substring(lib.indexOf('chatmelier/') + 11) : lib.split('/').last;
      return '$classe${f.name} ($court)';
    }
    if (f is NativeFunction) return '[natif] ${f.name}';
    return '$f';
  }

  final propre = <int, int>{};
  final inclusif = <int, int>{};
  final total = echantillons.samples?.length ?? 0;
  for (final s in echantillons.samples ?? const <CpuSample>[]) {
    final pile = s.stack ?? const <int>[];
    if (pile.isEmpty) continue;
    propre[pile.first] = (propre[pile.first] ?? 0) + 1;
    for (final i in pile.toSet()) {
      inclusif[i] = (inclusif[i] ?? 0) + 1;
    }
  }
  final periode = echantillons.samplePeriod ?? 1000;
  print('$total échantillons (un toutes les $periode µs ≈ ${(total * periode / 1e6).toStringAsFixed(1)} s de CPU)');
  void classer(String titre, Map<int, int> m, int n, {bool seulementApp = false}) {
    print('\n— $titre');
    final tri = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var k = 0;
    for (final e in tri) {
      final libelle = nom(e.key);
      if (seulementApp && !libelle.contains('features/') && !libelle.contains('shared/') && !libelle.contains('config/')) continue;
      print('${(100 * e.value / (total == 0 ? 1 : total)).toStringAsFixed(1).padLeft(5)} %  $libelle');
      if (++k >= n) break;
    }
  }

  classer('temps propre', propre, 25);
  classer('temps inclusif, code de l\'app', inclusif, 40, seulementApp: true);

  // Qui appelle la fonction la plus coûteuse : les dix premiers cadres de l'app et du
  // framework au-dessus d'elle, regroupés.
  if (propre.isNotEmpty) {
    final chaude = (propre.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    final appelants = <String, int>{};
    for (final s in echantillons.samples ?? const <CpuSample>[]) {
      final pile = s.stack ?? const <int>[];
      if (pile.isEmpty || pile.first != chaude) continue;
      final chaine = [for (final i in pile.skip(1).take(6)) nom(i).split(' (').first].join(' ← ');
      // Le premier cadre de l'app dans la pile : le widget qui porte la chose.
      final app = pile.map(nom).firstWhere((n) => n.contains('features/') || n.contains('shared/') || n.contains('config/'), orElse: () => '—');
      final cle = '$chaine   ⟵ app : $app';
      appelants[cle] = (appelants[cle] ?? 0) + 1;
    }
    print('\n— appelants de « ${nom(chaude)} »');
    for (final e in (appelants.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(8)) {
      print('${e.value.toString().padLeft(5)}  ${e.key}');
    }
  }
  await service.dispose();
}
