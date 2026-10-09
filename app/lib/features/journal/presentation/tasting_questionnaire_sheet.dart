import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/domain/taste_profile.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../offline/presentation/sync_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../data/tasting_ai_assistant_service.dart';
import '../domain/questionnaire_de_degustation.dart';
import '../domain/tasting_questionnaire_result.dart';
import '../../cellar/domain/wine.dart';
import '../domain/tasting_pedagogy_engine.dart';
import 'tasting_pedagogy_sheet.dart';
import 'journal_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../offline/data/offline_storage_service.dart';
import '../../../shared/utils/langue.dart';
import '../data/degustations_partagees.dart';

/// A 4-step paginated bottom sheet for structured post-tasting feedback.
///
/// Adapts to wine type (hides tannins for whites, shows effervescence for sparkling).
/// Supports multi-profile: each selected taster answers in turn or shared.
/// Includes completion confirmation and automatic synchronization for friends with the app.
class TastingQuestionnaireSheet extends ConsumerStatefulWidget {
  final String wineName;
  final int? vintage;
  final String? producer;
  final String? region;
  final String? wineType; // 'red', 'white', 'rose', 'sparkling', etc.
  final List<String>? wineGrapes;
  final String? wineId;
  final String? bottleId;
  final String? cellarId;
  final int quantityToConsume;
  final List<String>? preselectedTasters;
  final String? bottleOwnerId;
  final String? bottleOwnerName;
  final VoidCallback? onFinished;
  final bool initialIsExpress;

  /// La dégustation est déjà au journal (vin bu dehors) : le questionnaire n'est qu'un
  /// complément, et « Enregistrer sans noter » le referme (V2.4 · R3, Dimitri, 04/10).
  final bool dejaAuJournal;

  /// Ce que la « Gorgée » de « Noter un vin bu dehors » a déjà demandé à la personne
  /// principale : ni redemandé, ni écrasé (Flavien, 04/10 : « it's asked me twice »).
  final String? racheterDeja;
  final String? textureDeja;
  final String? fruitDeja;

  const TastingQuestionnaireSheet({
    super.key,
    required this.wineName,
    this.vintage,
    this.producer,
    this.region,
    this.wineType,
    this.wineGrapes,
    this.wineId,
    this.bottleId,
    this.cellarId,
    this.quantityToConsume = 1,
    this.preselectedTasters,
    this.bottleOwnerId,
    this.bottleOwnerName,
    this.onFinished,
    this.initialIsExpress = false,
    this.dejaAuJournal = false,
    this.racheterDeja,
    this.textureDeja,
    this.fruitDeja,
  });

  /// Show the questionnaire as a full-screen modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required String wineName,
    int? vintage,
    String? producer,
    String? region,
    String? wineType,
    List<String>? wineGrapes,
    String? wineId,
    String? bottleId,
    String? cellarId,
    int quantityToConsume = 1,
    List<String>? preselectedTasters,
    String? bottleOwnerId,
    String? bottleOwnerName,
    VoidCallback? onFinished,
    bool initialIsExpress = false,
    bool dejaAuJournal = false,
    String? racheterDeja,
    String? textureDeja,
    String? fruitDeja,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => TastingQuestionnaireSheet(
        wineName: wineName,
        vintage: vintage,
        producer: producer,
        region: region,
        wineType: wineType,
        wineGrapes: wineGrapes,
        wineId: wineId,
        bottleId: bottleId,
        cellarId: cellarId,
        quantityToConsume: quantityToConsume,
        preselectedTasters: preselectedTasters,
        bottleOwnerId: bottleOwnerId,
        bottleOwnerName: bottleOwnerName,
        onFinished: onFinished,
        initialIsExpress: initialIsExpress,
        dejaAuJournal: dejaAuJournal,
        racheterDeja: racheterDeja,
        textureDeja: textureDeja,
        fruitDeja: fruitDeja,
      ),
    );
  }

  @override
  ConsumerState<TastingQuestionnaireSheet> createState() => _TastingQuestionnaireSheetState();
}

class _TastingQuestionnaireSheetState extends ConsumerState<TastingQuestionnaireSheet> {
  PageController _pageController = PageController();
  int _currentStep = 0;

  // Profile selection
  List<TasteProfile> _allProfiles = [];
  Set<String> _selectedProfileIds = {};
  bool _profilesLoaded = false;

  // Multi-taster mode
  // Chacun répond pour soi, toujours. Le mode « Ensemble » a été retiré : il recopiait
  // les réponses d'une personne dans les profils des autres convives.
  static const bool _separateTurns = true;

  /// Défaut identifié sur la bouteille. Non nul ⇒ la dégustation est exclue du modèle
  /// de goût : un vin bouchonné n'apprend rien sur le palais, et lui ferait même croire
  /// qu'il déteste une région entière.
  ///
  /// C'est la bouteille qui est bouchonnée, pas le convive : le défaut reste signalé au
  /// suivant (qui peut le retirer), et la ligne de journal le garde même si le dernier à
  /// répondre ne l'a pas vu. La sensibilité au bouchon varie beaucoup d'une personne à
  /// l'autre ; le vin, lui, est le même pour tous.
  String? _defaut;
  bool _isTransitioningToNextTaster = false;
  bool _isCompleted = false;
  final Map<String, TastingQuestionnaireResult> _completedResults = {};

  /// L'identité de cette dégustation, décidée à l'ouverture de la feuille.
  ///
  /// Les réponses alimentent le profil AVANT que la ligne de journal ne soit écrite. Sans
  /// un identifiant fixé d'avance, les traces laissées au registre de goût ne pourraient
  /// pas être rattachées à l'entrée du journal — et supprimer celle-ci ne défairait rien.
  final String _tastingId = const Uuid().v4();
  final Set<String> _syncedFriendNames = {};

  /// Les amis qui notent eux-mêmes, sur leur téléphone (V2.4 · R4, #59) : on ne répond plus
  /// à leur place.
  final Set<String> _invitesANoter = {};
  final Set<String> _invitationsEnCours = {};

  // Current answering profile index (for multi-profile flow)
  int _currentProfileIndex = 0;
  List<TasteProfile> _selectedProfiles = [];

  /// Les réponses du convive dont c'est le tour (domaine : `ReponsesDuConvive`).
  ReponsesDuConvive _r = ReponsesDuConvive();

  late bool _isExpressMode;

  /// Vrai quand le vin a été bu avec un plat ; nul tant que la personne ne l'a pas dit.
  /// Commun à toute la table : il ne change pas d'un convive à l'autre.
  bool? _avecUnPlat;
  final TextEditingController _platCtrl = TextEditingController();

  // Blind Tasting Mode 🙈
  bool _isBlindTasting = false;
  BlindQuizData? _blindQuizData;
  String? _guessedRegion;
  String? _guessedGrape;
  String? _guessedVintage;
  String? _guessedPrice;

  // Occasion & Photo Souvenir 📸
  String _occasion = '';
  XFile? _tastingPhoto;

  // Conclave Consensus 🍷
  String? _conclaveSummary;

  bool _isSaving = false;

  QuestionnaireDuVin get _vin => QuestionnaireDuVin(widget.wineType);
  bool get _isRed => _vin.estRouge;
  bool get _isWhite => _vin.estBlanc;
  bool get _isSparkling => _vin.estEffervescent;
  bool get _isRose => _vin.estRose;
  bool get _showTannins => _vin.demandeLesTanins;

  String _profileDisplayName(TasteProfile profile) {
    if (!profile.isPrimary) return profile.name;
    final user = ref.watch(supabaseProvider).auth.currentUser;
    final userDisplayName = (user?.userMetadata?['display_name'] as String?) ??
        (user?.email?.split('@').firstOrNull) ??
        '';
    return userDisplayName.isNotEmpty ? tr('Moi ({userDisplayName})', 'Me ({userDisplayName})', {'userDisplayName': userDisplayName}) : tr('Moi', 'Me');
  }

  @override
  void initState() {
    super.initState();
    _isExpressMode = widget.initialIsExpress;
    _loadProfiles();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _platCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final service = ref.read(tasteProfileServiceProvider);
    final profiles = await service.getProfiles();
    List<Friend> friends = [];
    try {
      friends = await ref.read(friendsRepositoryProvider).getFriends();
    } catch (_) {}

    final merged = ConvivesDuQuestionnaire.rassembler(profiles, friends);
    if (mounted) {
      final initialSelected = ConvivesDuQuestionnaire.selectionInitiale(merged, widget.preselectedTasters);
      setState(() {
        _allProfiles = merged;
        _selectedProfileIds = initialSelected;
        _selectedProfiles = merged.where((p) => initialSelected.contains(p.id)).toList();
        _profilesLoaded = true;
      });
    }
  }

  void _resetAnswers() => _r = ReponsesDuConvive();

  /// La personne principale répond en ce moment, et la « Gorgée » lui a déjà demandé si elle
  /// en reprendrait : la question ne revient pas.
  bool get _racheterDejaDit {
    if (widget.racheterDeja == null || _selectedProfiles.isEmpty) return false;
    final i = _currentProfileIndex.clamp(0, _selectedProfiles.length - 1);
    return _selectedProfiles[i].isPrimary;
  }

  /// Les réponses de la « Gorgée », reprises pour la personne principale.
  void _reprendreLaGorgee(TasteProfile profil) {
    if (!profil.isPrimary) return;
    if (widget.racheterDeja != null) _r.racheter = widget.racheterDeja!;
    _r.texture ??= widget.textureDeja;
    _r.fruit ??= widget.fruitDeja;
  }

  /// À qui appartiennent les réponses en cours : un retour au choix des dégustateurs ne les
  /// efface plus (V2.4 · R3 — Caro, 07/10 : « ça a repris depuis le début, Caro doit tout
  /// refaire, c'est très critique »).
  String? _reponsesDe;

  /// Les convives dont le palais n'a pas été modifié : bouteille défectueuse (R3).
  final Set<String> _palaisNonModifie = {};

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.selectionClick();
    }
  }

  /// Revenir d'une étape, sans jamais rouvrir le choix des dégustateurs une fois le premier
  /// convive passé : c'est de là que tout repartait de zéro (R3).
  bool get _peutRevenir => _currentStep > 1 || (_currentStep == 1 && _currentProfileIndex == 0);

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  TastingQuestionnaireResult? _resultatDuMaitreDeCave() => resultatDuMaitreDeCave(
        _completedResults,
        (id) => _allProfiles.any((p) => p.id == id && p.isPrimary),
      );

  Future<void> _submitCurrentProfile() async {
    final profile = _selectedProfiles.isNotEmpty
        ? _selectedProfiles[_currentProfileIndex]
        : (_allProfiles.firstOrNull ?? TasteProfile(id: 'me', name: tr('Moi', 'Me'), isPrimary: true));
    _reprendreLaGorgee(profile);
    final result = _r.resultat(
      profileId: profile.id,
      profileName: profile.name,
      vin: _vin,
      express: _isExpressMode,
      avecUnPlat: _avecUnPlat,
      plat: _platCtrl.text,
    );

    setState(() => _isSaving = true);
    try {
      if (_defaut != null) {
        // Bouteille défectueuse : la dégustation est enregistrée dans le journal — elle a
        // bien eu lieu — mais elle n'alimente PAS le profil de goût. Apprendre de ce vin
        // enseignerait à la personne qu'elle déteste une région qu'elle n'a pas goûtée.
        AppLogger.info('QUESTIONNAIRE',
            'Profil non modifié pour ${profile.name} : bouteille défectueuse ($_defaut)');
        _palaisNonModifie.add(profile.id);
      } else {
        final service = ref.read(tasteProfileServiceProvider);
        await service.applyQuestionnaireResult(
          result: result,
          wineRegion: widget.region,
          wineGrapes: widget.wineGrapes,
          wineType: widget.wineType,
          tastingId: _tastingId,
          wineName: widget.wineName,
        );
        AppLogger.info('QUESTIONNAIRE', 'Saved answers for ${profile.name}');
      }
    } catch (e) {
      AppLogger.error('QUESTIONNAIRE', 'Error saving answers', e);
    }

    _completedResults[profile.id] = result;

    // La dégustation faite pour un ami qui a l'app lui est proposée : elle n'entre dans son
    // journal que s'il l'accepte (V2.4 · R4 ; Flavien, 07/10 : « me demander si je suis ok
    // que cette dégustation s'affiche ici »).
    if (profile.friendUserId != null) {
      try {
        await ref.read(degustationsPartageesProvider).proposer(propositionDeDegustation(
              amiId: profile.friendUserId!,
              nomDuVin: widget.wineName,
              millesime: widget.vintage,
              producteur: widget.producer,
              couleur: widget.wineType,
              region: widget.region,
              cepages: widget.wineGrapes ?? const [],
              resultat: result,
              convives: _selectedProfiles.map((p) => p.name).toList(),
              defaut: _defaut,
              proprietaireNom: widget.bottleOwnerName,
            ));
        _syncedFriendNames.add(profile.name);
        AppLogger.info('QUESTIONNAIRE', 'Dégustation proposée à ${profile.name}');
      } catch (e) {
        AppLogger.error('QUESTIONNAIRE', 'Dégustation non proposée à un ami', e);
      }
    }

    // Le mode « Ensemble » recopiait littéralement les réponses d'une personne — note
    // comprise — dans tous les autres profils de la table. Un seul palais en corrompait
    // cinq, et c'était le mode praticable : « Chacun son tour » impose de faire tourner
    // le téléphone sur cinq étapes par convive. Retiré : fabriquer des préférences pour
    // des gens qui n'ont rien répondu est pire que de ne rien enregistrer.
    // La vraie réponse est la dégustation multi-appareils (S4).
    if (_separateTurns && _currentProfileIndex < _selectedProfiles.length - 1) {
      setState(() {
        _isSaving = false;
        _isTransitioningToNextTaster = true;
      });
    } else {
      // All done! Finalize tasting & checkout
      await _finalizeTastingAndCheckout();
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isCompleted = true;
        });
      }
    }
  }

  Future<void> _finalizeTastingAndCheckout() async {
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    // Lu au besoin : sans bouteille ni session, rien ne touche au stockage local.
    OfflineStorageService stockage() => ref.read(offlineStorageServiceProvider);
    final bouteille = (widget.bottleId ?? '').isNotEmpty ? widget.bottleId : null;

    // 1. La bouteille sort de la cave.
    var bouteilleDecomptee = false;
    if (bouteille != null) {
      try {
        final bRes = await supabase.from('bottles').select('quantity, status').eq('id', bouteille).maybeSingle();
        await supabase
            .from('bottles')
            .update(bouteilleApresDegustation(
              quantite: bRes?['quantity'] as int? ?? 1,
              bues: widget.quantityToConsume,
              quand: DateTime.now(),
            ))
            .eq('id', bouteille);
        bouteilleDecomptee = true;
      } catch (e) {
        AppLogger.warning('QUESTIONNAIRE', 'Bouteille non décomptée en ligne, elle partira avec la file : $e');
      }
      // La cave affichée suit tout de suite, en ligne ou non, comme à la sortie de cave.
      if (widget.cellarId != null) {
        try {
          await stockage().applyOfflineConsume(widget.cellarId!, bouteille);
        } catch (e) {
          AppLogger.warning('QUESTIONNAIRE', 'Cave locale non mise à jour : $e');
        }
      }
    }

    // 2. Insert primary tasting log into tasting_log table
    if (user != null && widget.wineId != null) {
      // La ligne de journal est CELLE DU MAÎTRE DE CAVE, pas celle du premier qui a
      // répondu.
      //
      // `_completedResults` est rempli dans l'ordre où les convives remplissent le
      // questionnaire. Prendre la première valeur inscrivait donc la note de quelqu'un
      // d'autre : goûté à trois, noté 7,5, et le journal affichait le 9 de Paul. Les
      // profils de goût, eux, étaient justes — chacun reçoit le sien — d'où un écran qui
      // se contredisait lui-même sans que rien ne le signale.
      final ligne = LigneDuQuestionnaire(
        id: _tastingId,
        wineId: widget.wineId!,
        userId: user.id,
        bottleId: widget.bottleId,
        cellarId: widget.cellarId,
        resultat: _resultatDuMaitreDeCave(),
        convives: _selectedProfiles,
        occasionSaisie: _occasion,
        photo: _tastingPhoto?.path,
        proprietaireId: widget.bottleOwnerId,
        proprietaireNom: widget.bottleOwnerName,
        aLAveugle: _isBlindTasting,
        defaut: _defaut,
        quand: DateTime.now(),
      );
      final localPayload = <String, dynamic>{
        OfflineStorageService.pendingSyncKey: true,
        ...ligne.complete(),
        'wines': {
          'name': widget.wineName,
          'vintage': widget.vintage,
        },
      };

      // La ligne entière, puis le noyau (colonnes récentes absentes), puis l'ancienne
      // échelle sur 5 : chaque base restée en retard garde au moins la dégustation. La
      // ligne relue du serveur va au cache ; sans elle, la ligne locale, marquée en attente.
      Map<String, dynamic>? inseree;
      final essais = [ligne.complete(), ligne.essentielle(), ligne.ancienneEchelle()];
      for (var i = 0; i < essais.length && inseree == null; i++) {
        try {
          inseree = await supabase.from('tasting_log').insert(essais[i]).select('*, wines(*)').maybeSingle() ??
              localPayload;
        } catch (e) {
          AppLogger.warning('QUESTIONNAIRE',
              i < essais.length - 1 ? 'tasting_log refusé ($e), essai suivant' : 'tasting_log refusé, gardé en local : $e');
        }
      }
      final enLigne = inseree != null;
      try {
        await stockage().addCachedTasting(inseree ?? localPayload);
      } catch (e) {
        AppLogger.error('QUESTIONNAIRE', 'Error caching primary tasting log', e);
      }

      // Sans réseau, rien ne se perd : la file rejouera ce qui n'est pas parti — la
      // dégustation, la bouteille, ou les deux. Avant, une dégustation guidée faite hors
      // ligne restait sur le téléphone, et la bouteille dans la cave.
      if (bouteille != null && (!enLigne || !bouteilleDecomptee)) {
        try {
          await stockage().queueAction(sortieDeCaveEnFile(
            ligne: ligne,
            bouteille: bouteille,
            cave: widget.cellarId,
            nomDuVin: widget.wineName,
            millesime: widget.vintage,
            region: widget.region,
            bues: widget.quantityToConsume,
            dejaDecomptee: bouteilleDecomptee,
          ));
        } catch (e) {
          AppLogger.error('QUESTIONNAIRE', 'Sortie de cave non mise en file', e);
        }
      }
    }

    // Generate table conclave summary if multiple tasters
    if (_selectedProfiles.length > 1) {
      try {
        final ai = ref.read(tastingAiAssistantServiceProvider);
        _conclaveSummary = await ai.generateTastingConsensus(
          wineName: widget.wineName,
          results: _completedResults.values.toList(),
        );
      } catch (_) {}
    }

    // 3. Invalidate caches
    notifyCellarChanged(ref, widget.cellarId);
    ref.invalidate(tastingLogProvider);
    ref.invalidate(tasteProfilesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Le retour d'Android revient d'une étape ; il ne referme plus tout le questionnaire
    // en perdant les réponses (R3).
    return PopScope(
      canPop: _isCompleted,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!_isTransitioningToNextTaster && _peutRevenir) {
          _prevStep();
        } else {
          _confirmClose(context);
        }
      },
      child: _construire(context),
    );
  }

  Widget _construire(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final vintageStr = widget.vintage != null ? ' ${widget.vintage}' : '';

    if (_isCompleted) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1520) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(child: _buildCompletionView()),
          ],
        ),
      );
    }

    if (_isTransitioningToNextTaster) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1520) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(child: _buildTransitionView()),
          ],
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Wine name + profile selector or current profile indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('🍷', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tastingHeaderTitle,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _isBlindTasting
                                ? 'Bouteille Mystère 🕵️‍♂️ (Vin ${_isRed ? (l10n.wineTypeRed) : (_isWhite ? (l10n.wineTypeWhite) : (l10n.wineTypeRose))})'
                                : '${widget.wineName}$vintageStr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8B1E3F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.tastingDictateButton,
                      icon: const Icon(Icons.mic, color: Color(0xFF8B1E3F)),
                      onPressed: _showVoiceDictationDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _confirmClose(context),
                    ),
                  ],
                ),

                // Profile indicator for multi-profile flow
                if (_selectedProfiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 16, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 6),
                          Text(
                            l10n.tastingAnswersOf(_profileDisplayName(_selectedProfiles[_currentProfileIndex])) +
                            (_selectedProfiles.length > 1 ? ' (${_currentProfileIndex + 1}/${_selectedProfiles.length})' : ''),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Mode switcher (Express ⚡ vs Sommelier 🎓). Un Wrap, pas une Row : en anglais
                // les deux pastilles débordaient de 51 px sur un téléphone, en espagnol plus
                // encore (01/10) ; elles passent sur deux lignes quand il le faut.
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.bolt, size: 14, color: Color(0xFFF59E0B)),
                        label: Text(l10n.tastingFormatExpress, style: const TextStyle(fontSize: 11.5)),
                        selected: _isExpressMode,
                        onSelected: (val) {
                          if (val) setState(() => _isExpressMode = true);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: const Icon(Icons.school, size: 14, color: Color(0xFFD4AF37)),
                        label: Text(l10n.tastingFormatSommelier, style: const TextStyle(fontSize: 11.5)),
                        selected: !_isExpressMode,
                        onSelected: (val) {
                          if (val) setState(() => _isExpressMode = false);
                        },
                      ),
                      // Pas le temps : la dégustation est déjà au journal, on referme (R3).
                      if (widget.dejaAuJournal) ...[
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF10B981)),
                          label: Text(tr('Enregistrer sans noter', 'Save without rating'), style: const TextStyle(fontSize: 11.5)),
                          onPressed: () {
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                              content: Text(tr('Enregistré dans votre journal, sans note : vous pourrez la donner plus tard.',
                                  'Saved to your journal, unrated: you can rate it later.')),
                            ));
                            Navigator.of(context).pop(false);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isExpressMode)
            Expanded(
              child: _buildExpressForm(),
            )
          else ...[
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: List.generate(5, (i) {
                  final labels = [
                    l10n.tastingStepTasters,
                    l10n.tastingStepNezNav,
                    l10n.tastingStepBoucheNav,
                    l10n.tastingStepVerdictNav,
                    l10n.tastingStepRatingNav,
                  ];
                  final isActive = i == _currentStep;
                  final isDone = i < _currentStep;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFFD4AF37)
                                  : isActive
                                      ? const Color(0xFF8B1E3F)
                                      : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? const Color(0xFF8B1E3F) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProfileSelector(),
                  _buildStep2Nez(),
                  _buildStep3Bouche(),
                  _buildStep4Verdict(),
                  _buildStep1Impression(),
                ],
              ),
            ),

            // Navigation buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    if (_peutRevenir)
                      OutlinedButton.icon(
                        onPressed: _prevStep,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: Text(l10n.tastingBack),
                      ),
                    const Spacer(),
                    if (_currentStep == 0)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E3F),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _selectedProfileIds.isEmpty
                            ? null
                            : () {
                                _selectedProfiles = _allProfiles
                                    .where((p) => _selectedProfileIds.contains(p.id))
                                    .toList();
                                // Reprendre au premier convive qui n'a pas fini, avec ses
                                // réponses déjà données (R3).
                                final aFaire = _selectedProfiles.indexWhere((p) => !_completedResults.containsKey(p.id));
                                final suivant = aFaire < 0 ? 0 : aFaire;
                                if (_reponsesDe != _selectedProfiles[suivant].id) _resetAnswers();
                                _reponsesDe = _selectedProfiles[suivant].id;
                                if (_selectedProfiles.length > 1) {
                                  // À plusieurs, chacun est annoncé avant ses questions, le
                                  // premier aussi (Caro, 07/10).
                                  setState(() {
                                    _currentProfileIndex = suivant - 1;
                                    _isTransitioningToNextTaster = true;
                                  });
                                } else {
                                  _currentProfileIndex = suivant;
                                  _nextStep();
                                }
                              },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          l10n.tastingStartCount(_selectedProfileIds.length),
                        ),
                      ),
                    if (_currentStep > 0 && _currentStep < 4)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E3F),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _nextStep,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(l10n.tastingNext),
                      ),
                    if (_currentStep == 4)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: _isSaving ? null : _submitCurrentProfile,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check, size: 16),
                        label: Text(
                          _isSaving
                              ? (l10n.tastingSaving)
                              : (_separateTurns && _currentProfileIndex < _selectedProfiles.length - 1
                                  ? (l10n.tastingNextTaster)
                                  : (l10n.tastingConfirmAndFinish)),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 0: Profile Selector ("Qui a dégusté ?")
  // ===========================================================================
  /// Caro, 07/10 : « comme Flavien a l'app, ça pourrait lui envoyer une notif pour qu'il
  /// note en même temps sur son tel ». L'ami reçoit le vin à noter (migration 069).
  Future<void> _inviterANoter(TasteProfile profile) async {
    final nom = _profileDisplayName(profile);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _invitationsEnCours.add(profile.id));
    try {
      await ref.read(degustationsPartageesProvider).inviterANoter(
            amiId: profile.friendUserId!,
            nomDuVin: widget.wineName,
            millesime: widget.vintage,
            producteur: widget.producer,
            couleur: widget.wineType,
            region: widget.region,
          );
      if (!mounted) return;
      setState(() {
        _invitesANoter.add(profile.id);
        _selectedProfileIds.remove(profile.id);
      });
      AppLogger.info('QUESTIONNAIRE', 'Invitation à noter envoyée à un ami');
    } catch (e) {
      AppLogger.warning('QUESTIONNAIRE', 'Invitation à noter non envoyée : $e');
      messenger?.showSnackBar(SnackBar(
        content: Text(tr('L\'invitation n\'est pas partie : vous pouvez répondre pour {nom}.',
            'The invitation didn\'t go through: you can answer for {nom}.', {'nom': nom})),
      ));
    } finally {
      if (mounted) setState(() => _invitationsEnCours.remove(profile.id));
    }
  }

  Widget _ligneDInvitation(TasteProfile profile) {
    final nom = _profileDisplayName(profile);
    if (_invitesANoter.contains(profile.id)) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          tr('✓ Demandé : {nom} note sur son téléphone.', '✓ Asked: {nom} rates it on their phone.', {'nom': nom}),
          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
        ),
      );
    }
    final enCours = _invitationsEnCours.contains(profile.id);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          foregroundColor: const Color(0xFF8B1E3F),
        ),
        onPressed: enCours ? null : () => _inviterANoter(profile),
        icon: enCours
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.send_to_mobile, size: 16),
        label: Text(tr('Lui demander de noter sur son téléphone', 'Ask them to rate it on their phone'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildProfileSelector() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (!_profilesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.tastingWhoTastedTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.tastingWhoTastedSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Mode selector when multiple people are tasting
        if (_selectedProfileIds.length > 1)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tastingHowToTaste,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.tastingEachTurnDesc,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

        // Mode Dégustation à l'aveugle
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isBlindTasting
                ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isBlindTasting
                  ? const Color(0xFFD4AF37)
                  : Colors.grey.withValues(alpha: 0.25),
              width: _isBlindTasting ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🙈', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tastingBlindMode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      l10n.tastingBlindModeDesc,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isBlindTasting,
                activeThumbColor: const Color(0xFFD4AF37),
                onChanged: (val) {
                  setState(() => _isBlindTasting = val);
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
        ),

        ..._allProfiles.map((profile) {
          final isSelected = _selectedProfileIds.contains(profile.id);
          final displayName = _profileDisplayName(profile);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? const Color(0xFF8B1E3F) : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedProfileIds.remove(profile.id);
                  } else {
                    _selectedProfileIds.add(profile.id);
                  }
                });
                HapticFeedback.selectionClick();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.person_outline,
                        color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (profile.questionnairesCompleted > 0)
                            Text(
                              l10n.tastingQuestionnairesCompletedCount(profile.questionnairesCompleted),
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (profile.isPrimary)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.tastingPrimaryProfile,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD4AF37),
                                    ),
                                  ),
                                ),
                              if (profile.hasApp)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.smartphone, size: 10, color: Colors.green),
                                      const SizedBox(width: 3),
                                      Text(
                                        l10n.tastingAppInstalled,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (profile.hasApp && !profile.isPrimary) _ligneDInvitation(profile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // Step 4: Note Finale & Impression 🎯
  // ===========================================================================
  Widget _buildStep1Impression() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final emojiDescriptions = TastingQuestionnaireResult.getEmojiDescriptions(l10n);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.tastingStepImpressionTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.tastingStepImpressionSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        if (_isBlindTasting) ...[
          const SizedBox(height: 12),
          _buildBlindQuizCard(theme),
        ],
        const SizedBox(height: 20),

        // Emoji selector
        Text(
          l10n.tastingOverallFeeling,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) {
            final isSelected = _r.visage == i;
            return GestureDetector(
              onTap: () {
                setState(() => _r.choisirLeVisage(i));
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF8B1E3F) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      TastingQuestionnaireResult.emojiLabels[i],
                      style: TextStyle(fontSize: isSelected ? 36 : 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emojiDescriptions[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        // Note slider
        Text(
          l10n.tastingScoreOutOf10,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('😖', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Slider(
                value: _r.note,
                min: 1,
                max: 10,
                divisions: 18,
                activeColor: const Color(0xFF8B1E3F),
                label: _r.note.toStringAsFixed(1),
                onChanged: (v) => setState(() {
                  _r.reglerLaNote(v);
                }),
              ),
            ),
            const Text('😍', style: TextStyle(fontSize: 20)),
          ],
        ),
        Center(
          child: Text(
            '${_r.note.toStringAsFixed(1)} / 10',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B1E3F),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 2: Le Nez (Arômes) 🍇
  // ===========================================================================
  /// Contrôle de défaut, posé **avant** les arômes.
  ///
  /// C'est le moment pédagogique le plus précieux du vin et il n'existait nulle part dans
  /// l'application : aucune notion de bouchon, d'oxydation ni de réduction. Quelqu'un qui
  /// ouvre une bouteille bouchonnée la note 2/10 et en conclut qu'il n'aime pas la région.
  /// L'app lui enseignait quelque chose de faux.
  Widget _buildFaultCheck(ThemeData theme, AppLocalizations l10n) {
    // Les libellés portent leur emoji : ils vivent dans les .arb, comme les arômes.
    final faults = <({String id, String label, String explain})>[
      (
        id: 'cork',
        label: l10n.tastingFaultCorkLabel,
        explain: l10n.tastingFaultCorkExplain,
      ),
      (
        id: 'oxidation',
        label: l10n.tastingFaultOxidationLabel,
        explain: l10n.tastingFaultOxidationExplain,
      ),
      (
        id: 'reduction',
        label: l10n.tastingFaultReductionLabel,
        explain: l10n.tastingFaultReductionExplain,
      ),
    ];

    final selected = faults.where((f) => f.id == _defaut).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _defaut == null
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : const Color(0xFFB3261E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _defaut == null
              ? Colors.grey.withValues(alpha: 0.3)
              : const Color(0xFFB3261E).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tastingFaultTitle,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.tastingFaultSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in faults)
                FilterChip(
                  label: Text(f.label, style: const TextStyle(fontSize: 11.5)),
                  selected: _defaut == f.id,
                  selectedColor: const Color(0xFFB3261E).withValues(alpha: 0.18),
                  checkmarkColor: const Color(0xFFB3261E),
                  onSelected: (v) => setState(() => _defaut = v ? f.id : null),
                ),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: 10),
            Text(
              selected.explain,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.tastingFaultExcluded,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: const Color(0xFFB3261E),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2Nez() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final aromaList = TastingQuestionnaireResult.getAromaOptions(l10n);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.tastingStepNezTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.tastingStepNezSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...aromaList.map((aroma) {
              final isSelected = _r.aromes.contains(aroma.id);
              return FilterChip(
                selected: isSelected,
                label: Text('${aroma.emoji} ${aroma.localizedLabel(l10n)}'),
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _r.aromes.add(aroma.id);
                    } else {
                      _r.aromes.remove(aroma.id);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
              );
            }),
            ..._r.aromesLibres.map((customAroma) {
              return InputChip(
                avatar: const Icon(Icons.star, size: 14, color: Color(0xFFD4AF37)),
                label: Text(customAroma),
                selected: true,
                selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFFD4AF37),
                onDeleted: () {
                  setState(() {
                    _r.aromesLibres.remove(customAroma);
                  });
                },
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16, color: Color(0xFF8B1E3F)),
              label: Text(l10n.tastingAddCustomAroma),
              onPressed: _showAddCustomAromaDialog,
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          l10n.tastingAromaIntensity,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildSliderRow(
          leftLabel: l10n.tastingAromaDiscreet,
          rightLabel: l10n.tastingAromaExplosive,
          value: _r.intensiteAromatique,
          onChanged: (v) => setState(() => _r.intensiteAromatique = v),
        ),

        // Le défaut en bas de la page, après les arômes : on le cherche quand quelque chose
        // cloche, pas avant de sentir le vin (V2.4 · R3, Caro, 07/10).
        const SizedBox(height: 24),
        _buildFaultCheck(theme, l10n),
      ],
    );
  }

  // ===========================================================================
  // Step 3: La Bouche (Équilibre) ⚖️
  // ===========================================================================
  Widget _buildStep3Bouche() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.tastingStepBoucheTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.tastingStepBoucheSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Acidité / Vivacité
        Text(
          _isWhite
              ? (l10n.tastingAcidityFreshness)
              : (l10n.tastingAcidity),
          style: theme.textTheme.titleSmall,
        ),
        _buildSliderRow(
          leftLabel: l10n.tastingAcidityFlat,
          rightLabel: l10n.tastingAciditySharp,
          value: _r.acidite,
          onChanged: (v) => setState(() => _r.acidite = v),
        ),
        const SizedBox(height: 16),

        // Tanins (ONLY for reds — never for whites!)
        if (_showTannins) ...[
          Text(
            l10n.tastingTannins,
            style: theme.textTheme.titleSmall,
          ),
          _buildSliderRow(
            leftLabel: l10n.tastingTanninsSilky,
            rightLabel: l10n.tastingTanninsGrippy,
            value: _r.tanins,
            onChanged: (v) => setState(() => _r.tanins = v),
          ),
          const SizedBox(height: 16),
        ],

        // Minéralité & Fraîcheur (for whites and rosés instead of tannins)
        if (_isWhite || _isRose) ...[
          Text(
            l10n.tastingMinerality,
            style: theme.textTheme.titleSmall,
          ),
          _buildSliderRow(
            leftLabel: l10n.tastingMineralityRound,
            rightLabel: l10n.tastingMineralityCrisp,
            value: _r.mineralite,
            onChanged: (v) => setState(() => _r.mineralite = v),
          ),
          const SizedBox(height: 16),
        ],

        // Effervescence (only for sparkling)
        if (_isSparkling) ...[
          Text(
            l10n.tastingEffervescence,
            style: theme.textTheme.titleSmall,
          ),
          _buildSliderRow(
            leftLabel: l10n.tastingEffervescenceDelicate,
            rightLabel: l10n.tastingEffervescenceVibrant,
            value: _r.effervescence,
            onChanged: (v) => setState(() => _r.effervescence = v),
          ),
          const SizedBox(height: 16),
        ],

        // Corps
        Text(
          l10n.tastingBody,
          style: theme.textTheme.titleSmall,
        ),
        _buildSliderRow(
          leftLabel: l10n.tastingBodyLight,
          rightLabel: l10n.tastingBodyFull,
          value: _r.corps,
          onChanged: (v) => setState(() => _r.corps = v),
        ),
        const SizedBox(height: 16),

        // Longueur (Caudalies)
        Row(
          children: [
            Text(
              l10n.tastingLength,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _showCaudalieTooltip(context),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.help_outline, size: 16, color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
        _buildSliderRow(
          leftLabel: l10n.tastingLengthShort,
          rightLabel: l10n.tastingLengthLong,
          value: _r.longueur,
          onChanged: (v) => setState(() => _r.longueur = v),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 4: Verdict Final ✅
  // ===========================================================================
  Widget _buildStep4Verdict() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final likedList = TastingQuestionnaireResult.getLikedOptions(l10n)
        .where((o) => o.id != 'accord_plat' || _avecUnPlat == true)
        .toList();
    final dislikedList = TastingQuestionnaireResult.getDislikedOptions(l10n);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.tastingStepVerdictTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Would buy again — sauf si la « Gorgée » l'a déjà demandé (« asked me twice », 04/10).
        if (!_racheterDejaDit) ...[
          Text(
            l10n.tastingBuyAgain,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip(
                l10n.tastingBuyAgainYes,
                'yes',
                _r.racheter,
                (v) => setState(() => _r.racheter = v),
              ),
              const SizedBox(width: 8),
              _buildChoiceChip(
                l10n.tastingBuyAgainMaybe,
                'maybe',
                _r.racheter,
                (v) => setState(() => _r.racheter = v),
              ),
              const SizedBox(width: 8),
              _buildChoiceChip(
                l10n.tastingBuyAgainNo,
                'no',
                _r.racheter,
                (v) => setState(() => _r.racheter = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Ideal moment
        Text(
          l10n.tastingIdealMoment,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              l10n.tastingMomentApero,
              'apero',
              _r.moment,
              (v) => setState(() => _r.moment = v),
            ),
            _buildChoiceChip(
              l10n.tastingMomentMeal,
              'repas',
              _r.moment,
              (v) => setState(() => _r.moment = v),
            ),
            _buildChoiceChip(
              l10n.tastingMomentDinner,
              'grand_diner',
              _r.moment,
              (v) => setState(() => _r.moment = v),
            ),
            _buildChoiceChip(
              l10n.tastingMomentRomantic,
              'diner_romantique',
              _r.moment,
              (v) => setState(() => _r.moment = v),
            ),
            _buildChoiceChip(
              l10n.tastingMomentSolo,
              'solo',
              _r.moment,
              (v) => setState(() => _r.moment = v),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Le plat d'abord, puis l'accord : on ne demande pas l'accord avec un plat sans
        // savoir s'il y en avait un (Flavien, 30/09).
        _blocDuPlat(theme, l10n),
        const SizedBox(height: 20),

        // What liked most
        Text(
          l10n.tastingWhatLiked,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: likedList.map((opt) {
            final isSelected = _r.aime.contains(opt.id);
            return FilterChip(
              selected: isSelected,
              label: Text(opt.localizedLabel(l10n), style: const TextStyle(fontSize: 12)),
              selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFFD4AF37),
              onSelected: (val) => setState(() => _r.basculerAime(opt.id, val)),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // What disliked (trop_tannique is hidden for non-red wines)
        Text(
          l10n.tastingWhatDisliked,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: dislikedList
              .where((opt) => _showTannins || opt.id != 'trop_tannique')
              .map((opt) {
            final isSelected = _r.aimePas.contains(opt.id);
            return FilterChip(
              selected: isSelected,
              label: Text(opt.localizedLabel(l10n), style: const TextStyle(fontSize: 12)),
              selectedColor: Colors.red.withValues(alpha: 0.15),
              checkmarkColor: Colors.red,
              onSelected: (val) => setState(() => _r.basculerAimePas(opt.id, val)),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Occasion / Moment partagé
        TextField(
          decoration: InputDecoration(
            labelText: l10n.tastingOccasionLabel,
            hintText: l10n.tastingOccasionHint,
            prefixIcon: const Icon(Icons.celebration_outlined, color: Color(0xFF8B1E3F)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => _occasion = v.trim(),
        ),
        const SizedBox(height: 14),

        // Photo Souvenir
        if (_tastingPhoto == null)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: const Color(0xFF8B1E3F),
              side: BorderSide(color: const Color(0xFF8B1E3F).withValues(alpha: 0.4)),
            ),
            onPressed: _pickTastingPhoto,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(
              l10n.tastingAddPhoto,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.image, color: Color(0xFF8B1E3F)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.tastingPhotoSaved,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => setState(() => _tastingPhoto = null),
                ),
              ],
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ===========================================================================
  // Completion & Transition Views
  // ===========================================================================

  Widget _buildCompletionView() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vintageStr = widget.vintage != null ? ' ${widget.vintage}' : '';

    final wineObj = Wine(
      id: widget.wineId ?? 'temp',
      name: widget.wineName,
      vintage: widget.vintage,
      producer: widget.producer,
      region: widget.region ?? '',
      country: 'France',
      type: widget.wineType ?? 'red',
      grapes: (widget.wineGrapes ?? []).map((g) => Grape(name: g, pct: null)).toList(),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 38)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.tastingCompletedTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8B1E3F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.wineName}$vintageStr',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tastingCompletedSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        if (widget.bottleId != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF8B1E3F)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.tastingBottleRemoved,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Blind Tasting Grand Reveal Card
        if (_isBlindTasting) ...[
          _buildBlindRevealCard(vintageStr, l10n),
          const SizedBox(height: 16),
        ],

        // Table Conclave Consensus Card
        if (_selectedProfiles.length > 1 && _conclaveSummary != null) ...[
          _buildConclaveSummaryCard(l10n),
          const SizedBox(height: 16),
        ],

        // Wine Flavor Origins Section (Cépages, Boisé, Terroir, Âge)
        _buildFlavorOriginsCard(wineObj, l10n),
        const SizedBox(height: 16),

        // Summary cards for each taster
        ..._selectedProfiles.map((profile) {
          final res = _completedResults[profile.id];
          final isSynced = _syncedFriendNames.contains(profile.name);
          final displayName = _profileDisplayName(profile);

          final report = res != null
              ? TastingPedagogyEngine.analyze(
                  wine: wineObj,
                  userRating: res.noteOutOf10,
                  userAromas: res.perceivedAromas.map((aId) {
                    final opt = TastingQuestionnaireResult.aromaOptions.firstWhere(
                      (a) => a.id == aId,
                      orElse: () => AromaOption(id: aId, label: aId, emoji: '🍇'),
                    );
                    return '${opt.emoji} ${opt.localizedLabel(l10n)}';
                  }).toList(),
                  customAromas: res.customAromas,
                  userComment: res.whatLikedMost.join(', '),
                  userAcidity: res.acidity,
                  userTannins: res.tannins,
                  userBody: res.body,
                  userLength: res.length,
                  perceivedAromaIds: res.perceivedAromas.toSet(),
                )
              : null;

          final personaSubtitle = profile.isPrimary
              ? l10n.tastingCellarMaster
              : (profile.favoriteTypes.isNotEmpty
                  ? l10n.tastingProfileTag(profile.favoriteTypes.first + (profile.favoriteRegions.isNotEmpty ? ' • ${profile.favoriteRegions.first}' : ''))
                  : l10n.tastingGuestTaster);

          final emojiDescs = TastingQuestionnaireResult.getEmojiDescriptions(l10n);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF8B1E3F),
                        radius: 18,
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              personaSubtitle,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            if (res != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    emojiDescs[res.emojiImpression],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${res.noteOutOf10.toStringAsFixed(1)} / 10',
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (res != null && (res.perceivedAromas.isNotEmpty || res.customAromas.isNotEmpty)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...res.perceivedAromas.map((aId) {
                          final opt = TastingQuestionnaireResult.aromaOptions.firstWhere(
                            (a) => a.id == aId,
                            orElse: () => AromaOption(id: aId, label: aId, emoji: '🍇'),
                          );
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            label: Text('${opt.emoji} ${opt.localizedLabel(l10n)}', style: const TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                          );
                        }),
                        ...res.customAromas.map((cAroma) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            avatar: const Icon(Icons.star, size: 12, color: Color(0xFFD4AF37)),
                            label: Text(cAroma, style: const TextStyle(fontSize: 11)),
                            backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          );
                        }),
                      ],
                    ),
                  ],
                  if (res != null && res.foodPairingSynergy != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.restaurant, size: 13, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.tastingFoodSynergyTitle}${deuxPoints()}${res.foodPairingSynergy == 'sublime' ? l10n.tastingSynergySublime : (res.foodPairingSynergy == 'harmonious' ? l10n.tastingSynergyHarmonious : (res.foodPairingSynergy == 'neutral' ? l10n.tastingSynergyNeutral : l10n.tastingSynergyClashing))}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                        ),
                      ],
                    ),
                  ],
                  if (report != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school, size: 16, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.tastingAcuityScoreSummary(report.acuityScore, report.sommelierPraise),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => TastingPedagogySheet.show(context, report: report),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_stories_outlined, size: 14, color: Color(0xFF8B1E3F)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.tastingConsultDebrief,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B1E3F),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF8B1E3F)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (_palaisNonModifie.contains(profile.id))
                    // Bouteille défectueuse : rien n'a été appris du palais (R3 — Caro, 07/10 :
                    // « ça dit que le profil de Flavien est mis à jour »).
                    Row(
                      children: [
                        const Icon(Icons.report_gmailerrorred_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tr('Bouteille défectueuse : le palais de {name} n\'a pas été modifié.',
                                'Faulty bottle: {name}\'s palate was not changed.', {'name': displayName}),
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    )
                  else
                  Row(
                    children: [
                      Icon(
                        isSynced ? Icons.cloud_done : Icons.check_circle,
                        size: 16,
                        color: isSynced ? Colors.green : const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          profile.friendUserId == null
                              ? l10n.tastingProfileEnriched
                              : isSynced
                                  ? tr('Envoyée à {name} : elle entrera dans son journal une fois acceptée.',
                                      'Sent to {name}: it goes into their journal once they accept it.',
                                      {'name': displayName})
                                  : tr('Pas envoyée à {name} : vérifiez la connexion.',
                                      'Not sent to {name}: check the connection.', {'name': displayName}),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSynced ? FontWeight.bold : FontWeight.normal,
                            color: isSynced ? Colors.green.shade700 : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            widget.onFinished?.call();
            Navigator.of(context).pop(true);
          },
          icon: const Icon(Icons.celebration, color: Colors.white),
          label: Text(l10n.tastingFinishButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFlavorOriginsCard(Wine wineObj, AppLocalizations l10n) {
    final pedagogy = TastingPedagogyEngine.analyze(wine: wineObj);
    if (pedagogy.flavorOrigins.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B1E3F).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🧬', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tastingFlavorOriginsTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B1E3F),
                      ),
                    ),
                    Text(
                      l10n.tastingFlavorOriginsSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...pedagogy.flavorOrigins.map((origin) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(origin.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          origin.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          origin.badgeText ?? "",
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B1E3F),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    origin.sensoryContribution,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    origin.detailedWhy,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransitionView() {
    final l10n = AppLocalizations.of(context)!;
    final nextProfile = _selectedProfiles[_currentProfileIndex + 1];
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B1E3F), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.phone_android, size: 44, color: Color(0xFF8B1E3F)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tastingPassPhoneTo(nextProfile.name),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tastingAnswersSavedTurn(nextProfile.name),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _pageController.dispose();
                setState(() {
                  _currentProfileIndex++;
                  _isTransitioningToNextTaster = false;
                  _currentStep = 1;
                  _pageController = PageController(initialPage: 1);
                  if (_reponsesDe != nextProfile.id) _resetAnswers();
                  _reponsesDe = nextProfile.id;
                });
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                l10n.tastingStartTaster(nextProfile.name),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Shared widgets
  // ===========================================================================

  Widget _buildSliderRow({
    required String leftLabel,
    required String rightLabel,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(leftLabel, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF8B1E3F),
                inactiveTrackColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                thumbColor: const Color(0xFF8B1E3F),
                overlayColor: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                trackHeight: 5,
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(rightLabel, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  /// « Avec un plat ? », puis le plat (facultatif), puis l'accord. Le 30/09, Flavien se
  /// voyait demander si l'accord était « sublime » sans qu'on lui ait demandé ce qu'il
  /// avait mangé — ni même s'il avait mangé.
  Widget _blocDuPlat(ThemeData theme, AppLocalizations l10n, {bool compact = false}) {
    final titre = compact ? const TextStyle(fontSize: 12, fontWeight: FontWeight.w600) : theme.textTheme.titleSmall;
    final choix = _avecUnPlat == null ? null : (_avecUnPlat! ? 'oui' : 'non');
    final plat = _platCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Vous l\'avez bu avec un plat ?', 'Did you have it with food?'), style: titre),
        SizedBox(height: compact ? 6 : 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChoiceChip(tr('Oui, avec un plat', 'Yes, with food'), 'oui', choix,
                (_) => setState(() => _avecUnPlat = true)),
            _buildChoiceChip(tr('Non, seul', 'No, on its own'), 'non', choix, (_) => setState(() {
                  _avecUnPlat = false;
                  _r.accordAvecLePlat = null;
                })),
          ],
        ),
        if (_avecUnPlat == true) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _platCtrl,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: tr('Quel plat ? (facultatif)', 'Which dish? (optional)'),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            plat.isEmpty ? l10n.tastingFoodSynergyTitle : tr('L\'accord avec « {plat} »', 'The pairing with "{plat}"', {'plat': plat}),
            style: titre,
          ),
          SizedBox(height: compact ? 6 : 8),
          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: [
              for (final (libelle, valeur) in [
                (l10n.tastingSynergySublime, 'sublime'),
                (l10n.tastingSynergyHarmonious, 'harmonious'),
                (l10n.tastingSynergyNeutral, 'neutral'),
                (l10n.tastingSynergyClashing, 'clashing'),
              ])
                _buildChoiceChip(libelle, valeur, _r.accordAvecLePlat,
                    (v) => setState(() => _r.accordAvecLePlat = _r.accordAvecLePlat == v ? null : v)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildChoiceChip(String label, String value, String? currentValue, ValueChanged<String> onChanged) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () {
        onChanged(value);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF8B1E3F) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBlindQuizCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    _blindQuizData ??= ref.read(tastingAiAssistantServiceProvider).generateBlindQuizOptions(
      wineName: widget.wineName,
      wineType: widget.wineType ?? 'red',
      vintage: widget.vintage,
      region: widget.region,
      grapes: widget.wineGrapes,
    );
    final quiz = _blindQuizData!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🙈', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                l10n.tastingBlindQuizTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tastingBlindMakePredictionsPrompt,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          // 1. Région
          Text(l10n.tastingBlindQuizQ1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quiz.regionChoices.map((r) {
              final isSelected = _guessedRegion == r;
              return ChoiceChip(
                label: Text(r, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) => setState(() => _guessedRegion = val ? r : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 2. Cépage
          Text(l10n.tastingBlindQuizQ2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quiz.grapeChoices.map((g) {
              final isSelected = _guessedGrape == g;
              return ChoiceChip(
                label: Text(g, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) => setState(() => _guessedGrape = val ? g : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 3. Millésime / Tranche d'âge
          Text(l10n.tastingBlindQuizQ3, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quiz.vintageBrackets.map((v) {
              final isSelected = _guessedVintage == v;
              return ChoiceChip(
                label: Text(v, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) => setState(() => _guessedVintage = val ? v : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 4. Fourchette de prix
          Text(l10n.tastingBlindQuizQ4, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quiz.priceBrackets.map((p) {
              final isSelected = _guessedPrice == p;
              return ChoiceChip(
                label: Text(p, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF8B1E3F),
                onSelected: (val) => setState(() => _guessedPrice = val ? p : null),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showVoiceDictationDialog() {
    final parentContext = context;
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1622) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Color(0xFF8B1E3F), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tastingDictateButton,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              l10n.tastingDictateHint,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.tastingDictateMicTip,
                            style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.tastingDictateInputHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;

                            setSheetState(() => isProcessing = true);
                            try {
                              final currentTasterName = _selectedProfiles.isNotEmpty
                                  ? _selectedProfiles[_currentProfileIndex].name
                                  : tr('Moi', 'Me');
                              final tasterNames = _selectedProfiles.map((p) => p.name).toList();

                              final ai = ref.read(tastingAiAssistantServiceProvider);
                              final res = await ai.parseNaturalLanguageNotes(
                                spokenText: text,
                                tasterNames: tasterNames.isNotEmpty ? tasterNames : [currentTasterName],
                                wineType: widget.wineType ?? 'red',
                                wineName: widget.wineName,
                              );

                              // Apply parsed notes for current taster
                              final parsed = res.profiles[currentTasterName] ?? res.profiles.values.firstOrNull;
                              if (parsed != null && mounted) {
                                setState(() => _r.appliquerLaDictee(
                                      vin: _vin,
                                      note: parsed.noteOutOf10,
                                      visage: parsed.emojiImpression,
                                      aromes: parsed.perceivedAromas,
                                      acidite: parsed.acidity,
                                      tanins: parsed.tannins,
                                      mineralite: parsed.mineralite,
                                      corps: parsed.body,
                                      longueur: parsed.length,
                                    ));
                              }

                              if (mounted && context.mounted && parentContext.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  SnackBar(
                                    content: Text('${l10n.tastingAromaAppliedByAI} (${parsed?.noteOutOf10.toStringAsFixed(1)}/10) !'),
                                    backgroundColor: const Color(0xFF8B1E3F),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isProcessing = false);
                            }
                          },
                    icon: isProcessing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text(
                      isProcessing ? l10n.tastingDictateAnalyzing : l10n.tastingDictateAnalyzeAndApply,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickTastingPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.tastingTakePhoto),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.tastingChooseGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (choice != null) {
      final photo = await picker.pickImage(source: choice, imageQuality: 85);
      if (photo != null && mounted) {
        setState(() => _tastingPhoto = photo);
      }
    }
  }

  Widget _buildBlindRevealCard(String vintageStr, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFAA820A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍾', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tastingBlindRevealTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.wineName}$vintageStr',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          Text(
            '${widget.producer ?? tr('Domaine', 'Producer')} • ${widget.region ?? tr('Région', 'Region')}',
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          if (widget.wineGrapes != null && widget.wineGrapes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.tastingGrapesLabel(widget.wineGrapes!.join(", ")),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white38),
          const SizedBox(height: 6),
          Text(
            l10n.tastingBlindYourPredictions,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          if (_guessedRegion != null)
            _quizResultRow(
              tr('Région', 'Region'),
              _guessedRegion!,
              _blindQuizData?.correctRegion,
              _blindQuizData?.correctRegion == _guessedRegion,
              l10n,
            ),
          if (_guessedGrape != null)
            _quizResultRow(
              tr('Cépage', 'Grape'),
              _guessedGrape!,
              _blindQuizData?.correctGrape,
              _blindQuizData?.correctGrape == _guessedGrape,
              l10n,
            ),
          if (_guessedVintage != null)
            _quizResultRow(
              tr('Millésime', 'Vintage'),
              _guessedVintage!,
              _blindQuizData?.correctVintageBracket,
              _blindQuizData?.correctVintageBracket == _guessedVintage,
              l10n,
            ),
          if (_guessedPrice != null)
            _quizResultRow(
              tr('Prix', 'Price'),
              _guessedPrice!,
              _blindQuizData?.estimatedPriceBracket,
              _blindQuizData?.estimatedPriceBracket == _guessedPrice,
              l10n,
            ),
        ],
      ),
    );
  }

  Widget _quizResultRow(String label, String guessed, String? correct, bool isCorrect, AppLocalizations l10n) {
    final correctMsg = correct != null ? l10n.tastingQuizWas(correct) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.greenAccent : Colors.white70, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label : $guessed ${isCorrect ? l10n.tastingQuizBravo : correctMsg}',
              style: const TextStyle(fontSize: 11.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConclaveSummaryCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍷', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                l10n.tastingConclaveSummary,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8B1E3F)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _conclaveSummary!,
            style: const TextStyle(fontSize: 13, height: 1.45, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  void _confirmClose(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tastingQuitTitle),
        content: Text(l10n.tastingQuitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.tastingContinue),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.tastingQuit, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressForm() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final aromaList = TastingQuestionnaireResult.getAromaOptions(l10n);
    final emojiDescs = TastingQuestionnaireResult.getEmojiDescriptions(l10n);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Card 1: Note & Impression Globale
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1. ${l10n.tastingStepRatingNav}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_r.note.toStringAsFixed(1)} / 10',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Emojis row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (i) {
                  final isSelected = i == _r.visage;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _r.choisirLeVisage(i));
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF8B1E3F).withValues(alpha: 0.15) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: const Color(0xFF8B1E3F), width: 2) : null,
                      ),
                      child: Text(
                        TastingQuestionnaireResult.emojiLabels[i],
                        style: TextStyle(fontSize: isSelected ? 26 : 22),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  emojiDescs[_r.visage],
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8B1E3F)),
                ),
              ),
              Slider(
                value: _r.note,
                min: 1,
                max: 10,
                divisions: 18,
                activeColor: const Color(0xFF8B1E3F),
                label: _r.note.toStringAsFixed(1),
                onChanged: (v) => setState(() {
                  _r.reglerLaNote(v);
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card: ⚡ 3 Micro-Taps Fast-Tasting (Sensation Express)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 6),
                  Text(
                    TastingQuestionnaireResult.fastTastingTitle(l10n),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Micro-Tap 1: Le Toucher de Bouche
              Text(
                TastingQuestionnaireResult.mouthfeelTitle(l10n),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: TastingQuestionnaireResult.textureOptions.map((opt) {
                  final isSelected = _r.texture == opt.id;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          setState(() => _r.basculerLaTexture(opt.id));
                          HapticFeedback.selectionClick();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF8B1E3F).withValues(alpha: 0.18)
                                : theme.colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF8B1E3F) : theme.dividerColor.withAlpha(40),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(opt.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(
                                opt.localizedLabel(l10n),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF8B1E3F) : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Micro-Tap 2: L'Éclat du Fruit
              Text(
                TastingQuestionnaireResult.fruitProfileTitle(l10n),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: TastingQuestionnaireResult.fruitProfileOptions.map((opt) {
                  final isSelected = _r.fruit == opt.id;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          setState(() => _r.basculerLeFruit(opt.id));
                          HapticFeedback.selectionClick();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.18)
                                : theme.colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFD4AF37) : theme.dividerColor.withAlpha(40),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(opt.emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(
                                opt.localizedLabel(l10n),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFFD4AF37) : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card 2: Arômes express (sélection rapide + sur-mesure)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '2. ${l10n.tastingStepNezNav}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (_r.aromes.isNotEmpty || _r.aromesLibres.isNotEmpty)
                    Text(
                      tr('{v1} sélectionné(s)', '{v1} selected', {'v1': _r.aromes.length + _r.aromesLibres.length}),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8B1E3F), fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...aromaList.map((aroma) {
                    final isSelected = _r.aromes.contains(aroma.id);
                    return FilterChip(
                      selected: isSelected,
                      label: Text('${aroma.emoji} ${aroma.localizedLabel(l10n)}', style: const TextStyle(fontSize: 12)),
                      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                      checkmarkColor: const Color(0xFF8B1E3F),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _r.aromes.add(aroma.id);
                          } else {
                            _r.aromes.remove(aroma.id);
                          }
                        });
                        HapticFeedback.selectionClick();
                      },
                    );
                  }),
                  ..._r.aromesLibres.map((customAroma) {
                    return InputChip(
                      avatar: const Icon(Icons.star, size: 14, color: Color(0xFFD4AF37)),
                      label: Text(customAroma, style: const TextStyle(fontSize: 12)),
                      selected: true,
                      selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFFD4AF37),
                      onDeleted: () {
                        setState(() {
                          _r.aromesLibres.remove(customAroma);
                        });
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16, color: Color(0xFF8B1E3F)),
                    label: Text(l10n.tastingAddCustomAroma, style: const TextStyle(fontSize: 12)),
                    onPressed: _showAddCustomAromaDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card 3: Équilibre en Bouche express
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '3. ${l10n.tastingStepBoucheNav}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Vivacité / Acidité
              Text(_isWhite ? l10n.tastingAcidityFreshness : l10n.tastingAcidity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              _buildSliderRow(
                leftLabel: l10n.tastingAcidityFlat,
                rightLabel: l10n.tastingAciditySharp,
                value: _r.acidite,
                onChanged: (v) => setState(() => _r.acidite = v),
              ),
              // Tanins (reds)
              if (_showTannins) ...[
                const SizedBox(height: 8),
                Text(l10n.tastingTannins, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                _buildSliderRow(
                  leftLabel: l10n.tastingTanninsSilky,
                  rightLabel: l10n.tastingTanninsGrippy,
                  value: _r.tanins,
                  onChanged: (v) => setState(() => _r.tanins = v),
                ),
              ],
              // Minéralité (whites/rosés)
              if (_isWhite || _isRose) ...[
                const SizedBox(height: 8),
                Text(l10n.tastingMinerality, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                _buildSliderRow(
                  leftLabel: l10n.tastingMineralityRound,
                  rightLabel: l10n.tastingMineralityCrisp,
                  value: _r.mineralite,
                  onChanged: (v) => setState(() => _r.mineralite = v),
                ),
              ],
              // Effervescence (sparkling)
              if (_isSparkling) ...[
                const SizedBox(height: 8),
                Text(l10n.tastingEffervescence, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                _buildSliderRow(
                  leftLabel: l10n.tastingEffervescenceDelicate,
                  rightLabel: l10n.tastingEffervescenceVibrant,
                  value: _r.effervescence,
                  onChanged: (v) => setState(() => _r.effervescence = v),
                ),
              ],
              const SizedBox(height: 8),
              // Longueur & Caudalies
              Row(
                children: [
                  Text(l10n.tastingLength, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _showCaudalieTooltip(context),
                    child: const Icon(Icons.help_outline, size: 14, color: Color(0xFFD4AF37)),
                  ),
                ],
              ),
              _buildSliderRow(
                leftLabel: l10n.tastingLengthShort,
                rightLabel: l10n.tastingLengthLong,
                value: _r.longueur,
                onChanged: (v) => setState(() => _r.longueur = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card 4: Accord Mets & Verdict
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '4. ${l10n.tastingStepVerdictNav}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _blocDuPlat(theme, l10n, compact: true),
              const SizedBox(height: 12),
              // Would buy again
              Text(l10n.tastingBuyAgain, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildChoiceChip(
                    l10n.tastingBuyAgainYes,
                    'yes',
                    _r.racheter,
                    (v) => setState(() => _r.racheter = v),
                  ),
                  const SizedBox(width: 6),
                  _buildChoiceChip(
                    l10n.tastingBuyAgainMaybe,
                    'maybe',
                    _r.racheter,
                    (v) => setState(() => _r.racheter = v),
                  ),
                  const SizedBox(width: 6),
                  _buildChoiceChip(
                    l10n.tastingBuyAgainNo,
                    'no',
                    _r.racheter,
                    (v) => setState(() => _r.racheter = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Primary Submit Button
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isSaving ? null : _submitCurrentProfile,
          icon: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline),
          label: Text(
            _isSaving
                ? l10n.tastingSaving
                : l10n.tastingConfirmAndFinish,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showCaudalieTooltip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.tastingCaudalieTooltipTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.tastingCaudalieTooltipBody,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('Compris !', 'Got it!')),
          ),
        ],
      ),
    );
  }

  void _showAddCustomAromaDialog() {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tastingCustomAromaDialogTitle),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.tastingCustomAromaHint,
            prefixIcon: const Icon(Icons.star, color: Color(0xFFD4AF37)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.tastingBack),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  if (!_r.aromesLibres.contains(val)) {
                    _r.aromesLibres.add(val);
                  }
                });
              }
              Navigator.of(ctx).pop();
            },
            child: Text(tr('Ajouter', 'Add')),
          ),
        ],
      ),
    );
  }
}
