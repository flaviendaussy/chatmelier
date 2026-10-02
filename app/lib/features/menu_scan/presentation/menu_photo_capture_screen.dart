import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/services/fonctions_ia.dart';
import '../../../shared/providers/premium_provider.dart';
import '../../../shared/widgets/chatmelier_loader.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../monetization/admob_service.dart';
import '../data/menu_scan_service.dart';
import '../domain/menu_wine.dart';
import '../../../shared/utils/langue.dart';

class MenuPhotoCaptureScreen extends ConsumerStatefulWidget {
  /// L'ardoise d'un bar (V2.3 · J4) plutôt qu'une carte : les prix au verre d'abord.
  final bool ardoise;

  const MenuPhotoCaptureScreen({super.key, this.ardoise = false});

  @override
  ConsumerState<MenuPhotoCaptureScreen> createState() => _MenuPhotoCaptureScreenState();
}

class _MenuPhotoCaptureScreenState extends ConsumerState<MenuPhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _capturedPages = [];
  bool _isAnalyzing = false;
  final TextEditingController _restaurantController = TextEditingController();

  String _currentStatusStep = 'Chatmelier analyse le menu...';
  Timer? _statusTimer;
  int _statusStepIndex = 0;

  @override
  void dispose() {
    _stopStatusTimer();
    _restaurantController.dispose();
    super.dispose();
  }

  void _startStatusTimer(String? restaurantName) {
    _statusTimer?.cancel();
    _statusStepIndex = 0;
    final isFr = mounted ? (Localizations.localeOf(context).languageCode == 'fr') : true;
    final restSuffix = restaurantName != null && restaurantName.isNotEmpty ? ' ($restaurantName)' : '';
    final steps = [
      trSi(isFr, 'Chatmelier analyse le menu{suffixe}...', 'Chatmelier is analyzing the menu{suffixe}...', {'suffixe': restSuffix}),
      trSi(isFr, 'Déchiffrage optique des cuvées, producteurs et millésimes...', 'Optical recognition of cuvées, producers and vintages...'),
      trSi(isFr, 'Chatmelier s\'informe sur les domaines et terroirs viticoles...', 'Chatmelier explores estates and wine terroirs...'),
      trSi(isFr, 'Extraction des prix à la bouteille et des formats au verre...', 'Extracting bottle and by-the-glass pricing...'),
      trSi(isFr, 'Calcul des profils sensoriels (tanins, minéralité, vivacité)...', 'Computing sensory profiles (tannins, minerality, acidity)...'),
      trSi(isFr, 'Vérification dans la cave de connaissances Chatmelier...', 'Cross-referencing Chatmelier knowledge cellar...'),
      trSi(isFr, 'Génération des accords mets-vins personnalisés...', 'Generating personalized food & wine pairings...'),
      trSi(isFr, 'Finalisation de votre carte des vins enrichie...', 'Finalizing your enriched wine list...'),
    ];
    _currentStatusStep = steps[0];
    _statusTimer = Timer.periodic(const Duration(milliseconds: 2700), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _statusStepIndex = (_statusStepIndex + 1) % steps.length;
      setState(() {
        _currentStatusStep = steps[_statusStepIndex];
      });
    });
  }

  void _stopStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (photo != null) {
        setState(() => _capturedPages.add(photo));
      }
    } catch (e) {
      if (mounted) {
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trSi(isFr, 'Erreur lors de la prise de photo : {e}', 'Error taking photo: {e}', {'e': e}))),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final photos = await _picker.pickMultiImage(
        imageQuality: 88,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (photos.isNotEmpty) {
        setState(() => _capturedPages.addAll(photos));
      }
    } catch (e) {
      if (mounted) {
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trSi(isFr, 'Erreur lors de la sélection de photos : {e}', 'Error selecting photos: {e}', {'e': e}))),
        );
      }
    }
  }

  void _removePage(int index) {
    setState(() => _capturedPages.removeAt(index));
  }

  /// Vrai du premier appui jusqu'à la fin de l'analyse : un second appui ne relance rien.
  /// Le 18/09 à 23:31:10, deux analyses sont parties à la même seconde — la pub n'avait
  /// pas chargé, `showRewardedAd` avait rendu la main aussitôt — et chacune se paie.
  bool _analyseDemandee = false;

  Future<void> _startAnalysis() async {
    if (_capturedPages.isEmpty || _analyseDemandee) return;
    _analyseDemandee = true;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    try {
      // La carte part à l'analyse AVANT la vidéo : le temps de la pub n'est plus du temps
      // perdu. Jusqu'ici l'analyse ne démarrait qu'à la fermeture de la pub (journaux du
      // 23/09 : pub fermée à 19:05:18, analyse lancée à 19:05:18).
      final analyse = _executeAnalysis();

      // Une limite du jour déjà atteinte se sait en moins d'une seconde : on ne montre pas
      // une vidéo pour annoncer ensuite un refus. L'ordre ne change pas : l'analyse est
      // partie avant.
      final dejaRefuse = await Future.any<bool>([
        analyse.then((r) => r.$2 is LimiteIaAtteinte),
        Future<bool>.delayed(const Duration(milliseconds: 1200), () => false),
      ]);

      var videoRegardee = false;
      var recompense = true;
      if (!dejaRefuse && !ref.read(premiumProvider)) {
        final issue = Completer<bool>();
        final pubMontree = await AdMobService().showRewardedAd(
          emplacement: 'scan_carte',
          onRewardEarned: () {
            videoRegardee = true;
            if (!issue.isCompleted) issue.complete(true);
          },
          onAdDismissed: () {
            if (!issue.isCompleted) issue.complete(false);
          },
          // Une pub qui ne s'affiche pas n'est pas la faute de la personne : on laisse passer.
          onAdFailedToShow: () {
            if (!issue.isCompleted) issue.complete(true);
          },
        );
        // Pas de pub disponible (web, hors ligne, pas d'inventaire) : pas de fausse pub,
        // l'analyse continue simplement.
        if (pubMontree) recompense = await issue.future;
      }

      final (menu, erreur) = await analyse;
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      if (erreur is LimiteIaAtteinte) {
        messenger.showSnackBar(SnackBar(
          content: Text(erreur.message()),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 8),
        ));
        return;
      }
      if (!recompense) {
        messenger.showSnackBar(SnackBar(
          content: Text(trSi(isFr, 'Le visionnage de la vidéo est requis pour le scan en mode gratuit.', 'Watching the video is required for scanning in free mode.')),
        ));
        return;
      }
      if (menu == null) {
        messenger.showSnackBar(SnackBar(
          // Sans le préfixe technique « Exception: », que voyait l'utilisateur.
          content: Text(trSi(isFr, 'Erreur d\'analyse du menu : {v1}', 'Menu analysis failed: {v1}', {'v1': '$erreur'.replaceFirst('Exception: ', '')})),
          backgroundColor: Colors.red.shade800,
        ));
        return;
      }

      context.pushReplacement('/scan/menu/result', extra: menu);
      if (videoRegardee) {
        messenger.showSnackBar(SnackBar(
          content: Text(trSi(isFr, 'Pendant la vidéo, Chatmelier a lu votre carte : pas une seconde de perdue.', 'While the video played, Chatmelier read your menu — no time lost.')),
        ));
      }
    } finally {
      _analyseDemandee = false;
    }
  }

  /// Lance l'analyse et rend la carte, ou l'erreur. Ne navigue pas et n'affiche rien :
  /// pendant une pub, un message d'erreur passerait inaperçu sous la vidéo.
  Future<(ScannedMenu?, Object?)> _executeAnalysis() async {
    final restName = _restaurantController.text.trim().isNotEmpty ? _restaurantController.text.trim() : null;
    final currentLang = Localizations.localeOf(context).languageCode;
    setState(() {
      _isAnalyzing = true;
      _currentStatusStep = currentLang == 'fr' ? 'Chatmelier analyse le menu...' : 'Chatmelier is analyzing the menu...';
    });
    _startStatusTimer(restName);

    try {
      final scanService = ref.read(menuScanServiceProvider);
      final paths = _capturedPages.map((f) => f.path).toList();
      final bytesList = await Future.wait(_capturedPages.map((f) => f.readAsBytes()));

      final profiles = await ref.read(tasteProfilesListProvider.future);
      final activeProfile = profiles.isNotEmpty ? profiles.first : null;

      final resultMenu = await scanService.analyzeMenuPages(
        imagePaths: paths,
        imageBytesList: bytesList,
        restaurantNameHint: restName,
        userTasteProfile: activeProfile,
        languageCode: currentLang,
        ardoise: widget.ardoise,
        onStepUpdate: (step) {
          if (mounted) {
            setState(() => _currentStatusStep = step);
          }
        },
      );
      return (resultMenu, null);
    } catch (e) {
      return (null, e);
    } finally {
      _stopStatusTimer();
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ardoise
            ? tr('Scanner l\'ardoise', 'Scan the board')
            : trSi(isFr, 'Scanner la Carte des Vins', 'Scan Wine List')),
        elevation: 0,
        actions: [
          if (_capturedPages.isNotEmpty && !_isAnalyzing)
            TextButton.icon(
              onPressed: _startAnalysis,
              icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
              label: Text(
                trSi(isFr, 'Analyser ({capturedPages_length})', 'Analyze ({capturedPages_length})', {'capturedPages_length': _capturedPages.length}),
                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Explanation Banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1A24) : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B1E3F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ardoise
                                  ? tr('L\'ardoise du bar', 'The bar\'s board')
                                  : trSi(isFr, 'Capture Multi-Pages', 'Multi-Page Capture'),
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.ardoise
                                  ? tr('Photographiez l\'ardoise, en plusieurs fois si elle est grande : les prix au verre passeront en premier.',
                                      'Photograph the board, in several shots if it is large: glass prices will come first.')
                                  : trSi(isFr, 'Prenez toutes les pages de la carte (blancs, rouges, bulles...). Elles seront fusionnées et analysées en une seule fois par l\'IA !', 'Capture all pages of the list (whites, reds, sparkling...). They will be merged and analyzed together by AI!'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages List / Grid
                Expanded(
                  child: _capturedPages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 80,
                                color: isDark ? Colors.white24 : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                trSi(isFr, 'Aucune page capturée pour le moment', 'No pages captured yet'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                                child: Text(
                                  widget.ardoise
                                      ? tr('Prenez l\'ardoise en photo, ou choisissez une photo dans la galerie.',
                                          'Take a photo of the board, or pick one from the gallery.')
                                      : trSi(isFr, 'Prenez la première page de la carte des vins avec l\'appareil photo ou la galerie.', 'Capture the first page of the wine list using the camera or gallery.'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B1E3F),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    onPressed: _takePhoto,
                                    icon: const Icon(Icons.camera_alt),
                                    label: Text(trSi(isFr, 'Prendre photo', 'Take photo')),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onPressed: _pickFromGallery,
                                    icon: const Icon(Icons.photo_library),
                                    label: Text(trSi(isFr, 'Galerie', 'Gallery')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GridView.builder(
                            itemCount: _capturedPages.length + 1,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, index) {
                              if (index == _capturedPages.length) {
                                // Add more card
                                return InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (ctx) => SafeArea(
                                        child: Wrap(
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.camera_alt, color: Color(0xFF8B1E3F)),
                                              title: Text(trSi(isFr, 'Prendre une autre page en photo', 'Take another page photo')),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _takePhoto();
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.photo_library, color: Color(0xFF8B1E3F)),
                                              title: Text(trSi(isFr, 'Ajouter depuis la galerie', 'Add from gallery')),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _pickFromGallery();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_circle_outline, size: 36, color: Color(0xFF8B1E3F)),
                                        const SizedBox(height: 8),
                                        Text(
                                          trSi(isFr, 'Ajouter une page', 'Add a page'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          trSi(isFr, 'Photo ou Galerie', 'Photo or Gallery'),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final file = _capturedPages[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: kIsWeb
                                          ? Image.network(file.path, fit: BoxFit.cover)
                                          : Image.file(File(file.path), fit: BoxFit.cover),
                                    ),
                                  ),
                                  // Page Number Badge
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Page ${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Delete Button
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () => _removePage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),

                // Bottom Action Bar
                if (_capturedPages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('+ Page'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8B1E3F),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _isAnalyzing ? null : _startAnalysis,
                            icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                            label: Text(
                              _capturedPages.length > 1
                                  ? trSi(isFr, 'Analyser la carte ({n} pages)', 'Analyze wine list ({n} pages)', {'n': _capturedPages.length})
                                  : trSi(isFr, 'Analyser la carte ({n} page)', 'Analyze wine list ({n} page)', {'n': _capturedPages.length}),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Loading Overlay: "Analyse du menu par Chatmelier"
          if (_isAnalyzing)
            _MenuAnalysisLoadingOverlay(
              statusMessage: _currentStatusStep,
              restaurantName: _restaurantController.text.trim().isNotEmpty
                  ? _restaurantController.text.trim()
                  : null,
            ),
        ],
      ),
    );
  }
}

class _MenuAnalysisLoadingOverlay extends StatefulWidget {
  final String statusMessage;
  final String? restaurantName;

  const _MenuAnalysisLoadingOverlay({
    required this.statusMessage,
    this.restaurantName,
  });

  @override
  State<_MenuAnalysisLoadingOverlay> createState() => _MenuAnalysisLoadingOverlayState();
}

class _MenuAnalysisLoadingOverlayState extends State<_MenuAnalysisLoadingOverlay> {

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF221A28) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // La mascotte lit la carte pendant que l'IA la lit vraiment.
              const ChatmelierLoader(type: ChatmelierLoaderType.carte, size: 168),

              const SizedBox(height: 22),

              // Title: "Analyse du menu par Chatmelier"
              Text(
                trSi(isFr, 'Analyse du menu par Chatmelier', 'Menu analysis by Chatmelier'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),

              if (widget.restaurantName != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.restaurantName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 240,
                  height: 4,
                  child: LinearProgressIndicator(
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Dynamic Step Message with AnimatedSwitcher
              SizedBox(
                height: 48,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.2),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      widget.statusMessage,
                      key: ValueKey<String>(widget.statusMessage),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtext explanation
              Text(
                trSi(isFr, 'Extraction des cuvées, millésimes, prix au verre & bouteille, et profils sensoriels.', 'Extracting cuvées, vintages, by-the-glass & bottle pricing, and sensory profiles.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
