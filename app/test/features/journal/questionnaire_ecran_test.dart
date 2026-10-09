import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/friends/data/friends_repository.dart';
import 'package:chatmelier/features/friends/domain/friend.dart';
import 'package:chatmelier/features/journal/data/degustations_partagees.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/journal/presentation/tasting_questionnaire_sheet.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/providers/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le questionnaire de dégustation, parcouru comme à l'écran (V2.3 · I4) : ce que le palais
/// reçoit à la fin. Garde-fou du passage de sa logique dans le domaine.
class _Palais extends Fake implements TasteProfileService {
  final List<TasteProfile> profils;
  final recus = <TastingQuestionnaireResult>[];
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
  }) async =>
      recus.add(result);
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
          wineName: 'Chablis',
          wineType: type,
          initialIsExpress: express,
          preselectedTasters: convives,
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
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    // La note, en dernier : le visage le plus heureux.
    await _toucher(tester, find.text('😍').first);
    await _toucher(tester, find.text('Valider & Terminer ✨'));

    final r = palais.recus.single;
    expect(r.profileId, 'moi');
    expect(r.emojiImpression, 4);
    expect(r.noteOutOf10, 9.5);
    expect(r.perceivedAromas, {'agrumes'});
    expect(r.tannins, isNull, reason: 'un blanc n\'a pas de tanins à juger');
    expect(r.effervescence, isNull);
    expect(r.acidity, 0.5);
    expect(r.isExpressMode, isFalse);
  });

  testWidgets('en express, un rouge : le toucher soyeux suppose des tanins fondus', (tester) async {
    final palais = await _ouvrir(tester, type: 'red', express: true);

    // Le visage d'abord : la liste ne garde pas construit ce qui sort de l'écran.
    await _toucher(tester, find.text('😐').first);
    await _toucher(tester, find.textContaining(TastingQuestionnaireResult.textureOptions.first.emoji).first);
    await _toucher(tester, find.text('Valider & Terminer ✨'));

    final r = palais.recus.single;
    expect(r.isExpressMode, isTrue);
    expect(r.mouthfeelTexture, 'silky_lacy');
    expect(r.tannins, 0.40);
    expect(r.emojiImpression, 2);
    expect(TastingQuestionnaireResult.emojiIndexForRating(r.noteOutOf10), 2);
  });

  testWidgets('un ami qui a l\'app note lui-même : on le lui demande, on ne répond plus pour lui (#59)', (tester) async {
    const flavien = TasteProfile(id: 'flavien', name: 'Flavien', friendUserId: 'u-flavien');
    final partage = _Partage();
    final palais = await _ouvrir(tester, type: 'red', profils: const [_moi, flavien], convives: const ['moi', 'flavien'],
        partage: partage);

    expect(find.text('Commencer (2)'), findsOneWidget);
    await _toucher(tester, find.text('Lui demander de noter sur son téléphone'));

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
    await _toucher(tester, find.text('C\'est parti, Moi ! 🍷'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('😍').first);
    await _toucher(tester, find.text('Valider → Dégustateur suivant'));
    await _toucher(tester, find.text('C\'est parti, Caro ! 🍷'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('😕').first);
    await _toucher(tester, find.text('Valider & Terminer ✨'));

    expect(palais.recus.map((r) => (r.profileId, r.emojiImpression)), [('moi', 4), ('caro', 1)]);
  });

  testWidgets('à deux, le retour ne fait plus tout refaire : il ne rouvre pas le choix des dégustateurs', (tester) async {
    await _ouvrir(tester, type: 'red', profils: const [_moi, _caro], convives: ['caro']);

    await _toucher(tester, find.text('Commencer (2)'));
    await _toucher(tester, find.text('C\'est parti, Moi ! 🍷'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('😍').first);
    await _toucher(tester, find.text('Valider → Dégustateur suivant'));
    await _toucher(tester, find.text('C\'est parti, Caro ! 🍷'));

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
    await _toucher(tester, find.text('C\'est parti, Moi ! 🍷'));
    await _jusquA(tester, bouchon);
    await _toucher(tester, bouchon);
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Valider → Dégustateur suivant'));
    await _toucher(tester, find.text('C\'est parti, Caro ! 🍷'));

    await _jusquA(tester, bouchon);
    expect(tester.widget<FilterChip>(bouchon).selected, isTrue, reason: 'le défaut reste signalé au convive suivant');
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Suivant'));
    await _toucher(tester, find.text('Valider & Terminer ✨'));

    expect(palais.recus, isEmpty, reason: 'un vin bouchonné n\'apprend rien sur un palais');
  });
}
