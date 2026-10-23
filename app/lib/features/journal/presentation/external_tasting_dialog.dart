import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../config/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/services/cellar_location_service.dart';
import '../../../shared/services/nearby_places_service.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/widgets/bottle_image_view.dart';
import '../../scan/data/scan_service.dart';
import '../../scan/domain/completion_par_le_web.dart';
import '../../../shared/utils/langue.dart';
import '../../scan/domain/scan_result.dart';
import '../domain/fiche_depuis_texte.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/data/taste_profile_service.dart';
import 'journal_screen.dart';
import '../data/format_du_questionnaire.dart';
import '../../sommelier/data/cepages_du_vin.dart';
import '../../notifications/presentation/notification_pre_permission_dialog.dart';
import '../data/degustations_partagees.dart';
import 'tasting_questionnaire_sheet.dart';
import '../data/degustation_rapide.dart';
import '../../../shared/widgets/libere_a_la_fermeture.dart';

class ExternalTastingDialog extends ConsumerStatefulWidget {
  final String? initialWineName;
  final String? initialProducer;
  final int? initialVintage;
  final String? initialRegion;
  final String? initialAppellation;
  final String? initialCountry;
  final String? initialType;
  final String? photoUrl;

  /// Les convives et le lieu déjà connus : ceux d'une invitation à noter (V2.4 · R4, #59).
  final List<String>? initialCoTasters;
  final String? initialPlace;

  const ExternalTastingDialog({
    super.key,
    this.initialWineName,
    this.initialProducer,
    this.initialVintage,
    this.initialRegion,
    this.initialAppellation,
    this.initialCountry,
    this.initialType,
    this.photoUrl,
    this.initialCoTasters,
    this.initialPlace,
  });

  static Future<void> show(
    BuildContext context, {
    String? wineName,
    String? producer,
    int? vintage,
    String? region,
    String? appellation,
    String? country,
    String? wineType,
    String? photoUrl,
    List<String>? coTasters,
    String? place,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExternalTastingDialog(
        initialWineName: wineName,
        initialProducer: producer,
        initialVintage: vintage,
        initialRegion: region,
        initialAppellation: appellation,
        initialCountry: country,
        initialType: wineType,
        photoUrl: photoUrl,
        initialCoTasters: coTasters,
        initialPlace: place,
      ),
    );
  }

  @override
  ConsumerState<ExternalTastingDialog> createState() => _ExternalTastingDialogState();
}

class _ExternalTastingDialogState extends ConsumerState<ExternalTastingDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _producerController;
  late final TextEditingController _vintageController;
  late final TextEditingController _regionController;
  late final TextEditingController _paysController;
  late final TextEditingController _contextController;
  late final TextEditingController _notesController;

  String _wineType = 'red';
  bool _isSaving = false;

  /// Express (la note et trois questions) ou Sommelier, choisi ici et retenu : le
  /// questionnaire s'ouvre ensuite directement sur les questions, en plein écran (Flavien,
  /// 22/10 : « mets cette sélection sur l'écran précédent »). La note, la « gorgée », le plat
  /// ne sont plus demandés ici : le questionnaire les demande, une seule fois (« vire tout
  /// ça »).
  bool _express = true;

  /// Les cépages lus sur l'étiquette : sans eux, un Cinsault de la Maipo se lisait comme un
  /// cabernet (22/10).
  List<String> _cepages = const [];

  /// Les cépages qui arrivent après la lecture (la description de l'étiquette) : le
  /// questionnaire les attend un instant avant d'apprendre au palais.
  Future<List<String>>? _cepagesAVenir;

  // Friends & Co-tasters
  List<Friend> _friends = [];
  List<TasteProfile> _companionProfiles = [];
  final Set<String> _selectedCoTasters = {};

  Future<void> _showAddCompanionDialog() async {
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => LibereALaFermeture(
        controleurs: [nameCtrl],
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFF8B1E3F)),
              const SizedBox(width: 8),
              Text(l10n.checkoutAddGuest),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.checkoutAddGuestDialogDesc,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.checkoutAddGuestNameLabel,
                  hintText: l10n.checkoutAddGuestHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
              onPressed: () {
                final text = nameCtrl.text.trim();
                if (text.isNotEmpty) Navigator.pop(ctx, text);
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final service = conteneur.read(tasteProfileServiceProvider);
      await service.addOrGetProfileByName(newName);
      final fresh = await service.getProfiles();
      conteneur.invalidate(tasteProfilesListProvider);
      if (mounted) {
        setState(() {
          _companionProfiles = fresh;
          _selectedCoTasters.add(newName);
        });
      }
    }
  }

  // Nearby & Custom Places Discovery
  Position? _currentPosition;
  List<NearbyPlace> _nearbyPlaces = [];
  bool _isLoadingPlaces = true;
  bool _rememberThisPlace = true;
  NearbyPlace? _selectedPlace;
  bool _showCustomPlaceInput = false;
  String? _photoUrl;
  bool _isScanningPhoto = false;
  bool _isQuickAnalyzing = false;

  /// L'étiquette de la photo a été lue : une détection sur le nom ne l'écrase plus (R1).
  bool _etiquetteLue = false;

  /// Les champs que la dernière détection sur le nom a remplis : « à vérifier » (R1).
  Set<String> _remplisParLeTexte = const {};

  /// La description du sommelier, proposée et non imposée : les notes sont celles de la
  /// personne (V2.4 · R3 — Dimitri, 04/10 : « ne pas pré-remplir, c'est à l'utilisateur »).
  String? _notesDuSommelier;
  late final TextEditingController _quickSearchController;

  String _normalizeWineType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('blanc') || lower == 'white') return 'white';
    if (lower.contains('ros') || lower == 'rosé') return 'rose';
    if (lower.contains('sparkling') || lower.contains('champ') || lower.contains('bulles') || lower.contains('effervescent')) return 'sparkling';
    if (lower.contains('dessert') || lower.contains('moelleux') || lower.contains('liquoreux')) return 'dessert';
    return 'red';
  }

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.photoUrl;
    _quickSearchController = TextEditingController();
    _nameController = TextEditingController(text: widget.initialWineName ?? '');
    _producerController = TextEditingController(text: widget.initialProducer ?? '');
    _vintageController = TextEditingController(text: widget.initialVintage != null ? '${widget.initialVintage}' : '');
    _regionController = TextEditingController(text: widget.initialRegion ?? widget.initialAppellation ?? '');
    _paysController = TextEditingController(text: widget.initialCountry ?? '');
    _contextController = TextEditingController(text: widget.initialPlace ?? '');
    _selectedCoTasters.addAll(widget.initialCoTasters ?? const []);
    _notesController = TextEditingController();
    if (widget.initialType != null) {
      _wineType = widget.initialType!;
    }
    FormatDuQuestionnaire.express().then((e) {
      if (mounted) setState(() => _express = e);
    });

    _detectNearbyPlaces();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = Localizations.localeOf(context).languageCode;
    try {
      final picker = ImagePicker();
      // 2048 px suffisent : l'étiquette part recadrée à 1024. L'appareil réduit la photo
      // lui-même, sans faire décoder 12 mégapixels à l'app (22/10 : deux secondes par verre).
      final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 2048, maxHeight: 2048);
      // La fiche a pu être fermée pendant que l'appareil photo était ouvert.
      if (picked == null || !mounted) return;

      setState(() {
        _photoUrl = picked.path;
        _isScanningPhoto = true;
      });

      final supabase = ref.read(supabaseProvider);
      final scanService = ScanService(supabase);
      final bytes = await picked.readAsBytes();

      // La photo part pendant la lecture, pas après : elle n'en dépend pas.
      final envoi = scanService
          .uploadPhoto(
            bottleId: const Uuid().v4(),
            imagePath: picked.path,
            imageBytes: bytes,
            rattacherALaBouteille: false,
          )
          .then<String?>((url) => url, onError: (Object e) {
        debugPrint('Photo upload notice: $e');
        return null;
      });

      // 1. La lecture d'abord (cinq secondes) : le nom, le domaine, le millésime remplissent
      // le formulaire, qui se remplit ensuite de la description (23/10 : quinze secondes
      // d'attente à chaque verre du Vagabond).
      final cepages = Completer<List<String>>();
      _cepagesAVenir = cepages.future;
      try {
        final result = await scanService.analyzeBottleImage(
          imagePath: picked.path,
          imageBytes: bytes,
          languageCode: currentLang,
          onLecture: (lu) {
            if (!mounted) return;
            setState(() {
              _remplirDepuis(lu, ecraser: true);
              _isScanningPhoto = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.externalTastingAiRecognized(lu.name)),
                backgroundColor: const Color(0xFF2E7D32),
              ),
            );
          },
        );
        final noms = [for (final g in result.grapes) if (g.name.trim().isNotEmpty) g.name.trim()];
        if (!cepages.isCompleted) cepages.complete(noms);
        if (mounted) {
          final dejaAnnonce = !_isScanningPhoto;
          setState(() => _remplirDepuis(result, ecraser: !dejaAnnonce));
          if (!dejaAnnonce) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.externalTastingAiRecognized(result.name)),
                backgroundColor: const Color(0xFF2E7D32),
              ),
            );
          }
          // La photo ne dit pas d'où vient le vin : on le cherche sur le web (17/10).
          if (CompletionParLeWeb.aCompleter(result)) unawaited(_completerParLeWeb(scanService, result));
        }
      } catch (scanErr) {
        AppLogger.warning('EXTERNAL_TASTING', 'AI photo scan error: $scanErr');
        if (!cepages.isCompleted) cepages.complete(const []);
      } finally {
        if (mounted) setState(() => _isScanningPhoto = false);
      }

      // 2. La photo envoyée, son adresse remplace le chemin local.
      final publicUrl = await envoi;
      if (publicUrl != null && mounted) setState(() => _photoUrl = publicUrl);
    } catch (e) {
      if (mounted) setState(() => _isScanningPhoto = false);
      debugPrint('Error picking photo: $e');
    }
  }

  /// Ce que l'étiquette a dit, dans le formulaire. La lecture le remplit ([ecraser] : une
  /// nouvelle photo remplace la précédente) ; la description, ensuite, n'ajoute que ce qui
  /// manque — les cépages, la note du sommelier — sans rien effacer de ce que la personne
  /// a pu corriger entre-temps.
  void _remplirDepuis(ScanResult result, {required bool ecraser}) {
    void mettre(TextEditingController c, String? v) {
      if (v == null || v.trim().isEmpty) return;
      if (ecraser || c.text.trim().isEmpty) c.text = v;
    }

    mettre(_nameController, result.name);
    mettre(_producerController, result.producer);
    mettre(_vintageController, result.vintage?.toString());
    mettre(_regionController, (result.appellation ?? '').isNotEmpty ? result.appellation : result.region);
    mettre(_paysController, result.country);
    final cepages = [for (final g in result.grapes) if (g.name.trim().isNotEmpty) g.name.trim()];
    if (cepages.isNotEmpty || ecraser) _cepages = cepages;
    if (ecraser) _wineType = _normalizeWineType(result.wineType);
    if (result.tastingNotes != null && result.tastingNotes!.isNotEmpty) {
      _notesDuSommelier = result.tastingNotes;
    }
    _etiquetteLue = true;
    _remplisParLeTexte = const {};
  }

  /// Le vin de la photo cherché sur le web : seuls les champs vides se remplissent, marqués
  /// « à vérifier » comme ceux trouvés par le nom ; ce que l'étiquette a lu ne bouge pas.
  Future<void> _completerParLeWeb(ScanService scanService, ScanResult lu) async {
    final ({ScanResult fiche, List<String> sources, List<String> completes})? trouve;
    try {
      trouve = await scanService.chercherSurLeWeb(lu,
          requete: CompletionParLeWeb.requete(
            nom: lu.name,
            producteur: lu.producer,
            cuvee: lu.cuveeParcel,
            millesime: lu.vintage,
            appellation: lu.appellation,
            region: lu.region,
            pays: lu.country,
            type: lu.wineType,
          ));
    } catch (e) {
      AppLogger.warning('SCAN_WEB', 'Recherche sur le web interrompue : $e');
      return;
    }
    if (trouve == null || !mounted) return;
    final f = trouve.fiche;
    final champs = {
      'producteur': _producerController,
      'region': _regionController,
      'pays': _paysController,
    };
    // Un domaine recopié du nom n'avait pas été lu : il compte pour vide.
    final domaineRecopie = CompletionParLeWeb.domaineRecopie(_producerController.text, _nameController.text);
    final ecrire = FicheDepuisTexte.aEcrire(
      actuels: {
        for (final e in champs.entries) e.key: e.key == 'producteur' && domaineRecopie ? '' : e.value.text,
      },
      proposes: {
        'producteur': f.producer,
        'region': (f.appellation?.isNotEmpty ?? false) ? f.appellation : f.region,
        'pays': f.country,
      },
      etiquetteLue: true,
      remplisParLeTexte: _remplisParLeTexte,
    );
    setState(() {
      for (final e in ecrire.entries) {
        champs[e.key]!.text = e.value;
      }
      if ((_notesDuSommelier ?? '').isEmpty && (f.tastingNotes?.isNotEmpty ?? false)) _notesDuSommelier = f.tastingNotes;
      _remplisParLeTexte = {
        ..._remplisParLeTexte,
        for (final e in ecrire.entries)
          if (e.value.isNotEmpty) e.key,
      };
    });
  }

  Future<void> _quickAnalyzeFromText() async {
    final text = _quickSearchController.text.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isQuickAnalyzing = true);
    FocusScope.of(context).unfocus();

    try {
      final supabase = ref.read(supabaseProvider);
      final scanService = ScanService(supabase);
      final ScanResult result;
      try {
        result = await scanService.analyzeWineFromText(text);
      } on VinNonReconnu {
        if (mounted) {
          setState(() {
            _isQuickAnalyzing = false;
            if (_nameController.text.trim().isEmpty) _nameController.text = text;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(
              'Vin non reconnu avec certitude : complétez à la main, rien n\'a été inventé.',
              'Wine not recognised with certainty: fill it in by hand, nothing was made up.'))));
        }
        return;
      }

      // Une étiquette lue n'est jamais écrasée par une identification sur le nom (V2.4 · R1,
      // vin marocain de Camille, 07/10) : voir FicheDepuisTexte.
      final champs = {
        'nom': _nameController,
        'producteur': _producerController,
        'millesime': _vintageController,
        'region': _regionController,
        'pays': _paysController,
      };
      final ecrire = FicheDepuisTexte.aEcrire(
        actuels: {for (final e in champs.entries) e.key: e.value.text},
        proposes: {
          'nom': result.name,
          'producteur': result.producer,
          'millesime': result.vintage?.toString(),
          'region': (result.appellation?.isNotEmpty ?? false) ? result.appellation : result.region,
          'pays': result.country,
        },
        etiquetteLue: _etiquetteLue,
        remplisParLeTexte: _remplisParLeTexte,
      );
      if (mounted) {
        setState(() {
          for (final e in ecrire.entries) {
            champs[e.key]!.text = e.value;
          }
          if (!_etiquetteLue && result.wineType.isNotEmpty) _wineType = _normalizeWineType(result.wineType);
          if (result.tastingNotes?.isNotEmpty ?? false) _notesDuSommelier = result.tastingNotes;
          _remplisParLeTexte = {
            if (!_etiquetteLue) ..._remplisParLeTexte,
            for (final e in ecrire.entries)
              if (e.value.isNotEmpty) e.key,
          }..removeWhere((cle) => ecrire[cle] == '');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.externalTastingAiFilled(result.name)),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      AppLogger.warning('EXTERNAL_TASTING', 'Quick text analysis error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.externalTastingAnalysisError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isQuickAnalyzing = false);
    }
  }

  Future<void> _detectNearbyPlaces() async {
    try {
      final friends = await ref.read(friendsRepositoryProvider).getFriends();
      final companionProfiles = await ref.read(tasteProfileServiceProvider).getProfiles();
      if (mounted) {
        setState(() {
          _friends = friends;
          _companionProfiles = companionProfiles;
        });
      }

      final pos = await CellarLocationService.getCurrentPosition();
      if (!mounted) return;
      _currentPosition = pos;

      final places = await ref.read(nearbyPlacesServiceProvider).getNearbyPlaces(
            latitude: pos?.latitude,
            longitude: pos?.longitude,
          );

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places;
        _isLoadingPlaces = false;

        // Auto-select matched custom place or very close place
        if (places.isNotEmpty) {
          final top = places.first;
          if (_contextController.text.trim().isEmpty &&
              (top.isCustom || (top.distanceMeters != null && top.distanceMeters! <= 80))) {
            _selectedPlace = top;
            _contextController.text = top.name;
          }
          // Sinon le champ reste vide : « Au restaurant » écrit par défaut était un lieu
          // inventé à corriger (R3).
        } else {
          _showCustomPlaceInput = true;
        }
      });
    } catch (e) {
      AppLogger.warning('EXTERNAL_TASTING', 'Could not detect nearby places: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
          _showCustomPlaceInput = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _quickSearchController.dispose();
    _nameController.dispose();
    _producerController.dispose();
    _vintageController.dispose();
    _regionController.dispose();
    _paysController.dispose();
    _contextController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Les convives qui ont l'app : ils notent eux-mêmes, sur leur téléphone. Les autres
  /// (un profil local, « Papa ») répondent ici, à leur tour.
  List<Friend> get _amisQuiNotent => _friends.where((f) => _selectedCoTasters.contains(f.displayName)).toList();

  /// Écrire la dégustation, puis — avec [deguster] — ouvrir le questionnaire sur la ligne
  /// écrite, qu'il complétera (note, défaut, arômes). Sans : « Enregistrer sans noter ».
  Future<void> _saveTasting({bool deguster = true}) async {
    final l10n = AppLocalizations.of(context)!;
    final wineName = _nameController.text.trim();
    if (wineName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.externalTastingNameRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final vintage = int.tryParse(_vintageController.text.trim());
    final producer = _producerController.text.trim();
    final region = _regionController.text.trim();
    final pays = _paysController.text.trim();
    final occasion = _contextController.text.trim();
    final notes = _notesController.text.trim();

    // 1. If user checked to remember this place & we have a location, save it!
    if (_rememberThisPlace && occasion.isNotEmpty && _currentPosition != null) {
      try {
        await ref.read(nearbyPlacesServiceProvider).rememberPlace(
              name: occasion,
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
            );
        AppLogger.info('EXTERNAL_TASTING', 'Remembered place: "$occasion"');
      } catch (e) {
        AppLogger.warning('EXTERNAL_TASTING', 'Could not save custom place: $e');
      }
    }

    try {
      // La fiche, la dégustation, la file hors ligne : le même service que la fin de
      // soirée d'une table (V2.3 · E2). La note viendra du questionnaire.
      final ecrite = await ref.read(degustationRapideProvider).enregistrer(VinBuDehors(
            nom: wineName,
            producteur: producer,
            millesime: vintage,
            region: region,
            pays: pays,
            couleur: _wineType,
            lieu: occasion,
            notes: notes,
            photoUrl: _photoUrl,
            convives: _selectedCoTasters.toList(),
            cepages: _cepages,
          ));
      ref.invalidate(tastingLogProvider);

      // Sans cépages (un nom tapé, une étiquette qui ne les disait pas) : on les cherche
      // pendant que la personne répond — le cache commun d'abord, puis le web (080).
      final chercheur = ref.read(cepagesDuVinProvider);
      Future<List<String>> chercher() => chercheur.chercher(
          nom: wineName, producteur: producer, millesime: vintage, region: region, pays: pays, couleur: _wineType);
      final cepagesAVenir = _cepages.isNotEmpty
          ? null
          : (_cepagesAVenir ?? Future.value(const <String>[])).then<List<String>>((c) async => c.isNotEmpty ? c : await chercher());

      // Les amis qui ont l'app reçoivent le vin à noter, sans bouton à trouver (Caro, 22/10 :
      // « je ne comprenais pas que c'était un bouton »). En arrière-plan : le bar capte mal.
      final partages = ref.read(degustationsPartageesProvider);
      for (final ami in _amisQuiNotent) {
        unawaited(partages
            .inviterANoter(
              amiId: ami.friendUserId,
              nomDuVin: wineName,
              millesime: vintage,
              producteur: producer,
              couleur: _wineType,
              region: region,
              pays: pays,
              lieu: occasion,
            )
            .then((_) => AppLogger.info('QUESTIONNAIRE', 'Invitation à noter envoyée à un ami'))
            .catchError((Object e) => AppLogger.warning('QUESTIONNAIRE', 'Invitation à noter non envoyée : $e')));
      }

      if (!mounted) return;
      Navigator.pop(context);
      if (!deguster) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(tr('Enregistré dans votre journal, sans note : vous pourrez la donner plus tard.',
              'Saved to your journal, unrated: you can rate it later.')),
        ));
        return;
      }

      unawaited(FormatDuQuestionnaire.retenir(express: _express));
      final invites = _amisQuiNotent.isNotEmpty;
      final targetCtx = rootNavigatorKey.currentContext;
      // Un ami va noter de son côté : autant recevoir sa réponse (Caro n'avait jamais permis
      // les notifications, 22/10).
      if (invites && targetCtx != null && targetCtx.mounted) await NotificationPrePermissionDialog.auBonMoment(targetCtx);
      if (targetCtx != null && targetCtx.mounted) {
        final locaux = [
          for (final n in _selectedCoTasters)
            if (!_amisQuiNotent.any((f) => f.displayName == n)) n,
        ];
        TastingQuestionnaireSheet.show(
          targetCtx,
          dejaAuJournal: true,
          tastingLogId: ecrite.id,
          notesDeja: notes,
          lieu: occasion,
          wineName: wineName,
          vintage: vintage,
          producer: producer.isNotEmpty ? producer : null,
          region: region.isNotEmpty ? region : null,
          wineType: _wineType,
          wineGrapes: _cepages.isEmpty ? null : _cepages,
          cepagesAVenir: cepagesAVenir,
          preselectedTasters: locaux,
          initialIsExpress: _express,
          demarrerDirectement: true,
        );
      }
    } catch (e, stack) {
      AppLogger.error('EXTERNAL_TASTING', 'Error saving tasting', e, stack);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.externalTastingSaveError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.externalTastingTitle,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.externalTastingSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // =================================================================
            // LIEU & GÉOLOCALISATION INTELLIGENTE (Chez Dimitri, Resto, etc.)
            // =================================================================
            _buildLocationSection(theme, isDark, l10n),
            const SizedBox(height: 16),

            // Convives, Famille & Amis Co-dégustateurs. Texte agrandi du téléphone : le bouton
            // passe sous le titre au lieu de l'écraser en colonne (« qui dég / ustez- », 09/10).
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt, color: Color(0xFF8B1E3F), size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.externalTastingWithWhom,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: _showAddCompanionDialog,
                  icon: const Icon(Icons.person_add, size: 15, color: Color(0xFF8B1E3F)),
                  label: Text(
                    '+ ${l10n.checkoutAddGuest}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.checkoutWhoTastedSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Companion / Family profiles (excluding primary "Moi")
                ..._companionProfiles.where((p) => !p.isPrimary).map((p) {
                  final isSelected = _selectedCoTasters.contains(p.name);
                  return FilterChip(
                    avatar: CircleAvatar(
                      backgroundColor: const Color(0xFFD4AF37),
                      radius: 10,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    label: Text(p.name),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.18),
                    checkmarkColor: const Color(0xFF8B1E3F),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF8B1E3F) : null,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCoTasters.add(p.name);
                        } else {
                          _selectedCoTasters.remove(p.name);
                        }
                      });
                    },
                  );
                }),
                // Registered Friends
                ..._friends.where((f) => !_companionProfiles.any((p) => p.name.toLowerCase() == f.displayName.toLowerCase())).map((f) {
                  final isSelected = _selectedCoTasters.contains(f.displayName);
                  return FilterChip(
                    avatar: const Text('🍷', style: TextStyle(fontSize: 13)),
                    label: Text('${f.displayName} (${f.handle})'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.18),
                    checkmarkColor: const Color(0xFF8B1E3F),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF8B1E3F) : null,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCoTasters.add(f.displayName);
                        } else {
                          _selectedCoTasters.remove(f.displayName);
                        }
                      });
                    },
                  );
                }),
                // Quick add ActionChip
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: Color(0xFF8B1E3F)),
                  label: Text(l10n.checkoutAddGuestHint),
                  onPressed: _showAddCompanionDialog,
                ),
              ],
            ),
            // Ce qui se passera pour eux, dit avant : plus de bouton à deviner (22/10).
            if (_amisQuiNotent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.send_to_mobile, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tr('{noms} recevra ce vin à noter sur son téléphone.', '{noms} will get this wine to rate on their phone.',
                            {'noms': _amisQuiNotent.map((f) => f.displayName).join(', ')}),
                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // =================================================================
            // PHOTO DE LA BOUTEILLE (SCAN / APPAREIL / GALERIE)
            // =================================================================
            _buildPhotoSection(theme, isDark, l10n),
            const SizedBox(height: 16),

            // =================================================================
            // RECONNAISSANCE IA RAPIDE (ARDOISE BAR / TEXTE / LISTE)
            // =================================================================
            _buildQuickAiSearchSection(theme, isDark, l10n),
            const SizedBox(height: 16),

            // Nom du vin & Millésime
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.externalTastingWineNameLabel,
                      hintText: l10n.externalTastingWineNameHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _vintageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.bottleDetailVintage,
                      hintText: '2019',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Domaine, puis région et pays (le pays, demandé le 07/10 : un vin marocain se
            // lisait sans lui comme un vin d'ici).
            TextField(
              controller: _producerController,
              decoration: InputDecoration(
                labelText: l10n.bottleDetailProducer,
                hintText: l10n.externalTastingProducerHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _regionController,
                    decoration: InputDecoration(
                      labelText: l10n.externalTastingRegionLabel,
                      hintText: l10n.externalTastingRegionHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _paysController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: tr('Pays', 'Country'),
                      hintText: tr('ex. Maroc', 'e.g. Morocco'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Type / Couleur de vin
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip(l10n.wineTypeRed, 'red'),
                _buildTypeChip(l10n.wineTypeWhite, 'white'),
                _buildTypeChip(l10n.wineTypeRose, 'rose'),
                _buildTypeChip(l10n.wineTypeSparkling, 'sparkling'),
                _buildTypeChip(l10n.wineTypeDessert, 'dessert'),
              ],
            ),
            const SizedBox(height: 16),

            // Notes & Impressions
            TextField(
              controller: _notesController,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.externalTastingNotesLabel,
                hintText: l10n.externalTastingNotesHint,
                // La description du sommelier, à reprendre d'un geste si on le veut (R3).
                suffixIcon: _notesDuSommelier != null && _notesController.text.trim().isEmpty
                    ? IconButton(
                        tooltip: tr('Reprendre la description du sommelier', 'Use the sommelier\'s description'),
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        onPressed: () => setState(() => _notesController.text = _notesDuSommelier!),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Le format, choisi ici une fois pour toutes (il est retenu) : le questionnaire
            // s'ouvre ensuite directement sur les questions.
            Text(tr('Comment le noter ?', 'How to rate it?'),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _choixDuFormat(
                    express: true,
                    titre: tr('Express', 'Express'),
                    detail: tr('La note et trois questions', 'Rating and three questions'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _choixDuFormat(
                    express: false,
                    titre: tr('Sommelier', 'Sommelier'),
                    detail: tr('Le nez, la bouche, le verdict', 'Nose, palate, verdict'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _saveTasting(deguster: false),
                    child: Text(tr('Enregistrer sans noter', 'Save without rating'), textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(
                      _isSaving ? l10n.tastingSaving : tr('Déguster', 'Taste it'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSaving ? null : _saveTasting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _choixDuFormat({required bool express, required String titre, required String detail}) {
    final choisi = _express == express;
    const bordeaux = Color(0xFF8B1E3F);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _express = express),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: choisi ? bordeaux.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: choisi ? bordeaux : Colors.grey.withValues(alpha: 0.35), width: choisi ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: TextStyle(fontWeight: FontWeight.bold, color: choisi ? bordeaux : null)),
            const SizedBox(height: 2),
            Text(detail, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // LOCATION & NEARBY SUGGESTIONS BUILDER
  // =========================================================================

  Widget _buildLocationSection(ThemeData theme, bool isDark, AppLocalizations l10n) {
    if (_isLoadingPlaces) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B1E3F)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.externalTastingSearchingPlaces,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Detection Status
        Row(
          children: [
            const Icon(Icons.place, color: Color(0xFF8B1E3F), size: 18),
            const SizedBox(width: 6),
            Text(
              l10n.externalTastingWhere,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_currentPosition != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_fixed, size: 10, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(l10n.externalTastingGpsActive, style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Matched Custom Place Highlight (e.g. "Chez Dimitri")
        if (_selectedPlace != null && _selectedPlace!.isCustom)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.externalTastingPlaceGuess(_selectedPlace!.name),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
                      ),
                      Text(
                        l10n.externalTastingFavoritePlaceNote,
                        style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  tooltip: l10n.externalTastingChangePlace,
                  onPressed: () {
                    setState(() {
                      _showCustomPlaceInput = true;
                      _selectedPlace = null;
                      _contextController.clear();
                    });
                  },
                ),
              ],
            ),
          ),

        // Horizontal scrolling chips of nearby restaurants/bars
        if (_nearbyPlaces.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._nearbyPlaces.map((place) {
                  final isSelected = _selectedPlace?.id == place.id ||
                      _contextController.text.trim().toLowerCase() == place.name.trim().toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Text(place.iconEmoji, style: const TextStyle(fontSize: 14)),
                      label: Text(
                        place.distanceMeters != null
                            ? '${place.name} (${place.distanceMeters! < 1000 ? "${place.distanceMeters!.round()}m" : "${(place.distanceMeters! / 1000).toStringAsFixed(1)}km"})'
                            : place.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF8B1E3F) : null,
                        ),
                      ),
                      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedPlace = place;
                            _contextController.text = place.name;
                            _showCustomPlaceInput = false;
                          }
                        });
                      },
                    ),
                  );
                }),
                // Button to enter custom friend place (e.g. Chez Dimitri)
                ActionChip(
                  avatar: const Icon(Icons.add_home, size: 16, color: Color(0xFF8B1E3F)),
                  label: Text(l10n.externalTastingOtherPlace, style: const TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    setState(() {
                      _showCustomPlaceInput = true;
                      _selectedPlace = null;
                      _contextController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Custom Place Input when no resto found or user chooses custom
        if (_showCustomPlaceInput || _nearbyPlaces.isEmpty) ...[
          if (_nearbyPlaces.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l10n.externalTastingNoPlaceFound,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          TextField(
            controller: _contextController,
            decoration: InputDecoration(
              labelText: l10n.externalTastingPlaceLabel,
              hintText: l10n.externalTastingPlaceHint,
              prefixIcon: const Icon(Icons.home_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) => setState(() {}),
          ),
          if (_currentPosition != null && _contextController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: _rememberThisPlace,
                    activeColor: const Color(0xFFD4AF37),
                    checkColor: Colors.black,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) => setState(() => _rememberThisPlace = val ?? true),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _rememberThisPlace = !_rememberThisPlace),
                      child: Text(
                        l10n.externalTastingRememberPlace(_contextController.text.trim()),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildQuickAiSearchSection(ThemeData theme, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201A29) : const Color(0xFFF7F4F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF8B1E3F), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  // Caro, 22/10 : « explique-moi mieux la différence entre la photo et
                  // l'entrée en écriture ». La photo d'abord ; écrire, quand il n'y a pas
                  // d'étiquette.
                  tr('Pas d\'étiquette sous la main ? Tapez son nom', 'No label at hand? Type its name'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              if (_isQuickAnalyzing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B1E3F)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr('Un verre au bar, une ardoise : quelques mots suffisent (« Saint-Joseph Coursodon 2021 »), l\'IA remplit la fiche.',
                'A glass at the bar, a chalkboard: a few words are enough ("Saint-Joseph Coursodon 2021"), the AI fills in the rest.'),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quickSearchController,
                  decoration: InputDecoration(
                    hintText: l10n.externalTastingAiIdentifyHint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (_) => _quickAnalyzeFromText(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _isQuickAnalyzing ? null : _quickAnalyzeFromText,
                icon: const Icon(Icons.bolt, size: 16),
                label: Text(l10n.externalTastingDetect, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_remplisParLeTexte.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tr('Complété d\'après le nom : vérifiez avant d\'enregistrer.',
                  'Filled in from the name: check before saving.'),
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme, bool isDark, AppLocalizations l10n) {
    if (_isScanningPhoto) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF261F30) : const Color(0xFFF9F6F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.scanAnalyzing,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.externalTastingAiScanningSub,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF261F30) : const Color(0xFFF9F6F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37).withAlpha(100)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 65,
                height: 80,
                child: BottleImageView(
                  imagePath: _photoUrl,
                  wineType: _wineType,
                  width: 65,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n.externalTastingPhotoAdded,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.externalTastingPhotoAddedSub,
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showPhotoPickerSheet(context),
                        icon: const Icon(Icons.refresh, size: 14),
                        label: Text(l10n.externalTastingReplacePhoto, style: const TextStyle(fontSize: 11.5)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        tooltip: l10n.externalTastingDeletePhoto,
                        onPressed: () => setState(() {
                          _photoUrl = null;
                          _etiquetteLue = false;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221D2C) : const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B1E3F).withAlpha(60),
          style: BorderStyle.solid,
        ),
      ),
      // Texte agrandi du téléphone : le bouton passe sous les textes (175 px de
      // débordement à 200 %, 09/10).
      child: Builder(builder: (context) {
        final bouton = FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => _showPhotoPickerSheet(context),
          icon: const Icon(Icons.add_a_photo, size: 15),
          label: Text(l10n.externalTastingScanLabelButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        );
        final grandTexte = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Photographier l\'étiquette', 'Photograph the label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        tr('Le plus sûr : l\'IA y lit le vin, le domaine et le millésime.',
                            'The surest way: the AI reads the wine, producer and vintage.'),
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (!grandTexte) bouton,
              ],
            ),
            if (grandTexte) ...[const SizedBox(height: 8), bouton],
          ],
        );
      }),
    );
  }

  void _showPhotoPickerSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF8B1E3F)),
                title: Text(l10n.scanTakePhoto),
                subtitle: Text(l10n.externalTastingTakePhotoSub),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFD4AF37)),
                title: Text(l10n.scanPickGallery),
                subtitle: Text(l10n.externalTastingPickGallerySub),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String type) {
    final isSelected = _wineType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF8B1E3F) : null,
      ),
      onSelected: (val) {
        if (val) setState(() => _wineType = type);
      },
    );
  }
}
