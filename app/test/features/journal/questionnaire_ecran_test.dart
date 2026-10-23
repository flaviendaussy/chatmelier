import 'dart:async';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/friends/data/friends_repository.dart';
import 'package:chatmelier/features/friends/domain/friend.dart';
import 'package:chatmelier/features/journal/data/degustations_partagees.dart';
import 'package:chatmelier/features/journal/domain/question_pour_vous.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/journal/presentation/tasting_questionnaire_sheet.dart';
import 'package:chatmelier/features/journal/presentation/widgets/pour_vous.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/providers/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le questionnaire de dégustation, parcouru comme à l'écran (V2.3 · I4) : ce que le palais
/// reçoit à la fin. Garde-fou du passage de sa logique dans le domaine.
class _Palais extends Fake implements TasteProfileService {
  final List<TasteProfile> profils;
  final recus = <TastingQuestionnaireResult>[];
  final cepagesRecus = <List<String>?>[];
  final vins = <Wine?>[];
  _Palais(this.profils);

  @override
  Future<List<TasteProfile>> getProfiles() async => profils;

  @override
  Future<void> applyQuestionnaireResult({
    required TastingQuestionnaireResult result,
    String? wineRegion,
    List<String>? wineGrapes,
    String? wineType,
    String? tastingId,
    String? wineName,
    Wine? vin,
    DateTime? le,
  }) async {
    recus.add(result);
    cepagesRecus.add(wineGrapes);
    vins.add(vin);
  }
}

class _SansAmis extends Fake implements FriendsRepository {
  @override
  Future<List<Friend>> getFriends() async => const [];
}

/// L'invitation à noter, sans serveur : on garde à qui elle est partie, et pour quel vin.
class _Partage extends Fake implements DegustationsPartagees {
  final invitations = <(String, String)>[];

  @override
  Future<bool> inviterANoter({
    required String amiId,
    required String nomDuVin,
    int? millesime,
    String? producteur,
    String? couleur,
    String? region,
    String? pays,
    String? lieu,
  }) async {
    invitations.add((amiId, nomDuVin));
    return true;
  }
}

const _moi = TasteProfile(id: 'moi', name: 'Moi', isPrimary: true);
const _caro = TasteProfile(id: 'caro', name: 'Caro');

Future<_Palais> _ouvrir(
  WidgetTester tester, {
  required String type,
  bool express = false,
  List<TasteProfile> profils = const [_moi],
  List<String>? convives,
  DegustationsPartagees? partage,
  String nom = 'Chablis',
  Future<List<String>>? cepagesAVenir,
}) async {
  SharedPreferences.setMockInitialValues({});
  // Large : la police des essais (Ahem) est bien plus large qu'une vraie, et l'écran de
  // fin aligne des libellés sur une ligne.
  tester.view.physicalSize = const Size(2400, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final palais = _Palais(profils);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      tasteProfileServiceProvider.overrideWithValue(palais),
      friendsRepositoryProvider.overrideWithValue(_SansAmis()),
      if (partage != null) degustationsPartageesProvider.overrideWithValue(partage),
      // Sans session : rien ne part au serveur, le questionnaire va jusqu'au bout.
      supabaseProvider.overrideWithValue(SupabaseClient('http://localhost:1', 'cle-de-test',
          authOptions: const AuthClientOptions(autoRefreshToken: false))),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TastingQuestionnaireSheet(
          wineName: nom,
          wineType: type,
          initialIsExpress: express,
          preselectedTasters: convives,
          cepagesAVenir: cepagesAVenir,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return palais;
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Fait défiler la page en cours jusqu'à [f] : le défaut est en bas de la page du nez,
/// après les arômes (V2.4 · R3), hors de ce que la liste construit d'emblée.
Future<void> _jusquA(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 250,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un blanc, en entier : le palais reçoit ses réponses, sans tanins', (tester) async {
    final palais = await _ouvrir(tester, type: 'white');

    await _toucher(tester, find.text('Commencer (1)'));
    await _toucher(tester, find.textContaining('Agrumes'));
    await _toucher(tester, find.text('Suivant'));
    // La bouche (V2.6) : une question « pour vous », plus des curseurs à régler.
    expect(find.byType(PourVous), findsOneWidget);
    await _toucher(tester, find.text('Juste').first);
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    // La note, en dernier : le visage le plus heureux.
    await _toucher(tester, find.text('😍').first);
    await _toucher(tester, find.text('Valider & Terminer'));

    final r = palais.recus.single;
    expect(r.profileId, 'moi');
    expect(r.emojiImpression, 4);
    expect(r.noteOutOf10, 9.5);
    expect(r.perceivedAromas, {'agrumes'});
    expect(r.tannins, isNull, reason: 'un blanc n\'a pas de tanins à juger');
    expect(r.effervescence, isNull);
    expect(r.acidity, isNull, reason: 'un curseur qu\'on n\'a pas touché ne dit rien');
    expect(r.jugements.values, ['juste']);
    expect(QuestionPourVous.axes('blanc'), contains(r.jugements.keys.single));
    expect(r.idealMoment, '', reason: 'le moment n\'a pas été choisi');
    expect(r.isExpressMode, isFalse);
  });

  testWidgets('en express, un rouge : une question « pour vous », et rien de supposé (V2.6)', (tester) async {
    final palais = await _ouvrir(tester, type: 'red', express: true);

    // Le départ (22/10) : qui goûte et comment, puis les questions seules.
    await _toucher(tester, find.text('Commencer (1)'));
    // Le visage d'abord : la liste ne garde pas construit ce qui sort de l'écran.
    await _toucher(tester, find.text('😐').first);
    // Ni toucher de bouche ni éclat du fruit : une seule question, trop · juste · pas assez.
    expect(find.textContaining(TastingQuestionnaireResult.textureOptions.first.emoji), findsNothing);
    final trop = find.descendant(of: find.byType(PourVous), matching: find.byType(InkWell)).at(2);
    await _toucher(tester, trop);
    await _toucher(tester, find.text('Valider & Terminer'));

    final r = palais.recus.single;
    expect(r.isExpressMode, isTrue);
    expect(r.mouthfeelTexture, isNull);
    expect(r.tannins, isNull, reason: 'le rouge n\'a pas été décrit : on ne suppose pas ses tanins');
    expect(r.jugements.values, ['trop']);
    expect(QuestionPourVous.axes('rouge'), contains(r.jugements.keys.single));
    expect(r.idealMoment, '', reason: 'l\'express ne demande pas le moment');
    expect(r.emojiImpression, 2);
    expect(TastingQuestionnaireResult.emojiIndexForRating(r.noteOutOf10), 2);
  });

  testWidgets('un ami qui a l\'app note lui-même : on le lui demande, on ne répond plus pour lui (#59)', (tester) async {
    const flavien = TasteProfile(id: 'flavien', name: 'Flavien', friendUserId: 'u-flavien');
    final partage = _Partage();
    final palais = await _ouvrir(tester, type: 'red', profils: const [_moi, flavien], convives: const ['moi', 'flavien'],
        partage: partage);

    expect(find.text('Commencer (2)'), findsOneWidget);
    await _toucher(tester, find.text('Inviter Flavien à noter sur son téléphone'));

    expect(partage.invitations.single, ('u-flavien', 'Chablis'));
    expect(find.text('✓ Demandé : Flavien note sur son téléphone.'), findsOneWidget);
    // Il note lui-même : il n'est plus parmi ceux à qui l'on répond.
    expect(find.text('Commencer (1)'), findsOneWidget);
    expect(palais.recus, isEmpty);
  });

  testWidgets('à deux : chacun son tour, chacun ses réponses', (tester) async {
    final palais = await _ouvrir(tester, type: 'red', profils: const [_moi, _caro], convives: ['caro']);

    await _toucher(tester, find.text('Commencer (2)'));
    // À plusieurs, le premier convive est annoncé lui aussi (V2.4 · R3, Caro, 07/10).
    await _toucher(tester, find.text('C\'est parti, Moi !'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('😍').first);
    await _toucher(tester, find.text('Valider → Dégustateur suivant'));
    await _toucher(tester, find.text('C\'est parti, Caro !'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('😕').first);
    await _toucher(tester, find.text('Valider & Terminer'));

    expect(palais.recus.map((r) => (r.profileId, r.emojiImpression)), [('moi', 4), ('caro', 1)]);
  });

  testWidgets('à deux, le retour ne fait plus tout refaire : il ne rouvre pas le choix des dégustateurs', (tester) async {
    await _ouvrir(tester, type: 'red', profils: const [_moi, _caro], convives: ['caro']);

    await _toucher(tester, find.text('Commencer (2)'));
    await _toucher(tester, find.text('C\'est parti, Moi !'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('😍').first);
    await _toucher(tester, find.text('Valider → Dégustateur suivant'));
    await _toucher(tester, find.text('C\'est parti, Caro !'));

    // Au premier écran de Caro, plus de « Retour » vers le choix des dégustateurs : c'est de
    // là que tout repartait de zéro.
    expect(find.text('Retour'), findsNothing);
    await _toucher(tester, find.text('Suivant'));
    expect(find.text('Retour'), findsOneWidget, reason: 'entre ses propres étapes, Caro peut revenir');
  });

  testWidgets('une bouteille bouchonnée l\'est pour toute la table : personne n\'en apprend rien', (tester) async {
    final palais = await _ouvrir(tester, type: 'red', profils: const [_moi, _caro], convives: ['caro']);
    final bouchon = find.widgetWithText(FilterChip, '📦 Carton mouillé, cave humide');

    await _toucher(tester, find.text('Commencer (2)'));
    await _toucher(tester, find.text('C\'est parti, Moi !'));
    await _jusquA(tester, bouchon);
    await _toucher(tester, bouchon);
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Valider → Dégustateur suivant'));
    await _toucher(tester, find.text('C\'est parti, Caro !'));

    await _jusquA(tester, bouchon);
    expect(tester.widget<FilterChip>(bouchon).selected, isTrue, reason: 'le défaut reste signalé au convive suivant');
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Valider & Terminer'));

    expect(palais.recus, isEmpty, reason: 'un vin bouchonné n\'apprend rien sur un palais');
  });

  testWidgets('22/10 : le format se choisit au départ, il est retenu, et les questions viennent seules', (tester) async {
    await _ouvrir(tester, type: 'white');
    // Au départ : le format et les dégustateurs.
    expect(find.text('Express'), findsOneWidget);
    expect(find.text('Sommelier'), findsOneWidget);
    await _toucher(tester, find.text('Express'));
    await _toucher(tester, find.text('Commencer (1)'));
    // Les questions, sans les pastilles d'avant en tête (« Format Express (1 page) »…).
    expect(find.text('Express'), findsNothing);
    expect(find.textContaining('Format'), findsNothing);
    expect(find.text('Enregistrer sans noter'), findsNothing);
    expect(find.byType(PourVous), findsOneWidget);
    // Trois questions d'emblée sur un blanc (douceur, fraîcheur, corps ou boisé).
    expect(find.text('Juste'), findsNWidgets(3));
  });

  testWidgets('22/10 : sur un rosé, pas de question sur le boisé', (tester) async {
    await _ouvrir(tester, type: 'rose', express: true);
    await _toucher(tester, find.text('Commencer (1)'));
    expect(find.text('Son boisé, pour vous ?'), findsNothing);
    expect(find.text('Aller plus loin'), findsNothing, reason: 'trois axes, trois questions : rien de plus à dérouler');
  });

  testWidgets('22/10 : une bouteille défectueuse, en grand à la fin, et sans note', (tester) async {
    await _ouvrir(tester, type: 'red');
    final oxyde = find.widgetWithText(FilterChip, '🍎 Pomme blette, vinaigre, xérès');
    await _toucher(tester, find.text('Commencer (1)'));
    await _jusquA(tester, oxyde);
    await _toucher(tester, oxyde);
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Valider & Terminer'));
    expect(find.textContaining('Bouteille défectueuse : Pomme blette'), findsOneWidget);
    expect(find.textContaining('/ 10'), findsNothing, reason: 'plus de « Pas aimé 1,0/10 » sous un défaut');
  });

  testWidgets('23/10 : les cépages trouvés pendant qu\'on répond servent au palais', (tester) async {
    final palais = await _ouvrir(tester, type: 'red', express: true, nom: 'Ungrafted Cinsault',
        cepagesAVenir: Future.value(const ['Cinsault']));
    await _toucher(tester, find.text('Commencer (1)'));
    await _toucher(tester, find.text('😊').first);
    await _toucher(tester, find.text('Valider & Terminer'));
    expect(palais.cepagesRecus.single, ['Cinsault']);
    expect(palais.vins.single!.grapes.single.name, 'Cinsault',
        reason: 'le palais apprend un Cinsault, pas un cabernet de sa région');
  });

  testWidgets('23/10 : une recherche qui ne répond pas ne retient pas la fin plus de trois secondes', (tester) async {
    final jamais = Completer<List<String>>();
    final palais = await _ouvrir(tester, type: 'red', express: true, cepagesAVenir: jamais.future);
    await _toucher(tester, find.text('Commencer (1)'));
    await _toucher(tester, find.text('😊').first);
    await tester.tap(find.text('Valider & Terminer'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(palais.recus, hasLength(1));
    expect(palais.cepagesRecus.single, isNull, reason: 'sans cépages, comme avant');
  });
}
