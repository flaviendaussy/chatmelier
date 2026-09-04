import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/providers/premium_provider.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../monetization/admob_service.dart';
import '../../scan/presentation/rewarded_video_ad_sheet.dart';
import '../data/menu_scan_service.dart';

class MenuPhotoCaptureScreen extends ConsumerStatefulWidget {
  const MenuPhotoCaptureScreen({super.key});

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
    final restSuffix = restaurantName != null && restaurantName.isNotEmpty ? ' ($restaurantName)' : '';
    final steps = [
      'Chatmelier analyse le menu$restSuffix...',
      'Déchiffrage optique des cuvées, producteurs et millésimes...',
      'Chatmelier s\'informe sur les domaines et terroirs viticoles...',
      'Extraction des prix à la bouteille et des formats au verre...',
      'Calcul des profils sensoriels (tanins, minéralité, vivacité)...',
      'Vérification dans la cave de connaissances Chatmelier...',
      'Génération des accords mets-vins personnalisés...',
      'Finalisation de votre carte des vins enrichie...',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo : $e')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de photos : $e')),
        );
      }
    }
  }

  void _removePage(int index) {
    setState(() => _capturedPages.removeAt(index));
  }

  Future<void> _startAnalysis() async {
    if (_capturedPages.isEmpty) return;

    final isPremium = ref.read(premiumProvider);

    if (!isPremium) {
      // 1. Mode gratuit : affichage d'une publicité AdMob vidéo récompensée ou fallback web
      final showedAdMob = await AdMobService().showRewardedAd(
        onRewardEarned: () {
          if (mounted) _executeAnalysis();
        },
        onAdDismissed: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Le visionnage de la vidéo est requis pour le scan en mode gratuit.')),
            );
          }
        },
      );

      if (!showedAdMob && mounted) {
        RewardedVideoAdSheet.show(
          context,
          onRewardEarned: () {
            if (mounted) _executeAnalysis();
          },
          onCancel: () {
            // Cancelled by user
          },
        );
      }
    } else {
      // 2. Mode Supporter / Premium : analyse instantanée directe sans publicité
      _executeAnalysis();
    }
  }

  Future<void> _executeAnalysis() async {
    final restName = _restaurantController.text.trim().isNotEmpty ? _restaurantController.text.trim() : null;
    setState(() {
      _isAnalyzing = true;
      _currentStatusStep = 'Chatmelier analyse le menu...';
    });
    _startStatusTimer(restName);

    try {
      final scanService = ref.read(menuScanServiceProvider);
      final paths = _capturedPages.map((f) => f.path).toList();

      final profiles = await ref.read(tasteProfilesListProvider.future);
      final activeProfile = profiles.isNotEmpty ? profiles.first : null;

      final resultMenu = await scanService.analyzeMenuPages(
        imagePaths: paths,
        restaurantNameHint: restName,
        userTasteProfile: activeProfile,
        onStepUpdate: (step) {
          if (mounted) {
            setState(() => _currentStatusStep = step);
          }
        },
      );

      _stopStatusTimer();

      if (mounted) {
        context.pushReplacement('/scan/menu/result', extra: resultMenu);
      }
    } catch (e) {
      _stopStatusTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'analyse du menu : $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner la Carte des Vins'),
        elevation: 0,
        actions: [
          if (_capturedPages.isNotEmpty && !_isAnalyzing)
            TextButton.icon(
              onPressed: _startAnalysis,
              icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
              label: Text(
                'Analyser (${_capturedPages.length})',
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
                              'Capture Multi-Pages',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Prenez toutes les pages de la carte (blancs, rouges, bulles...). Elles seront fusionnées et analysées en une seule fois par l\'IA !',
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
                              const Text(
                                'Aucune page capturée pour le moment',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 36.0),
                                child: Text(
                                  'Prenez la première page de la carte des vins avec l\'appareil photo ou la galerie.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
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
                                    label: const Text('Prendre photo'),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onPressed: _pickFromGallery,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Galerie'),
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
                                              title: const Text('Prendre une autre page en photo'),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _takePhoto();
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.photo_library, color: Color(0xFF8B1E3F)),
                                              title: const Text('Ajouter depuis la galerie'),
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
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_circle_outline, size: 36, color: Color(0xFF8B1E3F)),
                                        SizedBox(height: 8),
                                        Text(
                                          'Ajouter une page',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          'Photo ou Galerie',
                                          style: TextStyle(fontSize: 11, color: Colors.grey),
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
                              'Analyser la carte (${_capturedPages.length} ${_capturedPages.length > 1 ? "pages" : "page"})',
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

class _MenuAnalysisLoadingOverlayState extends State<_MenuAnalysisLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // Animated Pulsing Sommelier Rings
              AnimatedBuilder(
                animation: _animCtrl,
                builder: (ctx, child) {
                  final scale = 1.0 + (_animCtrl.value * 0.12);
                  final opacity = 0.25 + (_animCtrl.value * 0.45);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Golden Pulse
                      Container(
                        width: 96 * scale,
                        height: 96 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD4AF37).withValues(alpha: opacity * 0.3),
                        ),
                      ),
                      // Inner Burgundy Ring
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 2.0,
                          ),
                        ),
                      ),
                      // Core Icon
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF8B1E3F),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // Title: "Analyse du menu par Chatmelier"
              Text(
                'Analyse du menu par Chatmelier',
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
                'Extraction des cuvées, millésimes, prix au verre & bouteille, et profils sensoriels.',
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
