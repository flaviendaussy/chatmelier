import 'package:chatmelier/features/monetization/domain/credits_ia.dart';
import 'package:chatmelier/features/monetization/domain/reglages_de_la_pub.dart';
import 'package:chatmelier/features/monetization/passer_par_une_video.dart';
import 'package:chatmelier/features/monetization/presentation/annonce_native.dart';
import 'package:chatmelier/features/monetization/proposer_une_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Une vidéo récompensée se choisit (règle d'AdMob, phase 0) ; sans pub possible, rien ne
/// bloque ; sans bloc natif, pas de carte « Annonce ».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BuildContext> ecran(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: Scaffold(body: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      }))),
    ));
    return ctx;
  }

  testWidgets('la feuille dit ce que la vidéo ouvre, et rend le choix', (tester) async {
    final ctx = await ecran(tester);
    final choix = ProposerUneVideo.demander(ctx,
        titre: 'Lire cette étiquette', explication: 'Une courte vidéo finance chaque lecture.', renoncer: 'Saisir à la main');
    await tester.pumpAndSettle();
    expect(find.text('Lire cette étiquette'), findsOneWidget);
    expect(find.text('Une courte vidéo finance chaque lecture.'), findsOneWidget);
    expect(find.text('Chatmelier ne vend rien : ces courtes vidéos paient l\'IA.'), findsOneWidget);
    await tester.tap(find.text('Regarder la vidéo'));
    await tester.pumpAndSettle();
    expect(await choix, isTrue);

    final refus = ProposerUneVideo.demander(ctx, titre: 'T', explication: 'E', renoncer: 'Saisir à la main');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saisir à la main'));
    await tester.pumpAndSettle();
    expect(await refus, isFalse);
  });

  testWidgets('sans pub possible (essais, web), un geste épuisé passe quand même', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final ctx = await ecran(tester);
    final c = CreditsIa(jour: CreditsIa.jourDe(DateTime.now()), chat: 99);
    await c.ecrire('compte');
    expect(await PasserParUneVideo.autoriser(ctx, geste: GesteIa.chat, premium: false, uid: 'compte'), isTrue);
    expect(find.text('Regarder la vidéo'), findsNothing, reason: 'aucune feuille quand aucune vidéo n\'est possible');
  });

  testWidgets('sans bloc natif réglé, aucune carte « Annonce »', (tester) async {
    ReglagesDeLaPub.actuels = const ReglagesDeLaPub();
    expect(AnnonceNative.apres(11), isFalse);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: AnnonceNative(emplacement: 'journal'))),
    ));
    expect(find.textContaining('Annonce'), findsNothing);
  });
}
