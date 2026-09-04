import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/utils/app_logger.dart';
import '../../offline/presentation/sync_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});
  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  CameraController? _controller;
  bool _isInit = false;
  bool _hasCameraError = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Strictly prioritize REAR / BACK camera (prevents inverted selfie camera on iPhone / Safari Web)
        final backIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
        final externalIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.external);
        
        if (backIndex != -1) {
          _selectedCameraIndex = backIndex;
        } else if (externalIndex != -1) {
          _selectedCameraIndex = externalIndex;
        } else {
          _selectedCameraIndex = 0;
        }

        await _startCameraController(_cameras[_selectedCameraIndex]);
      } else {
        if (mounted) setState(() => _hasCameraError = true);
      }
    } catch (e) {
      AppLogger.warning('SCAN_SCREEN', 'Camera initialization error: $e');
      if (mounted) setState(() => _hasCameraError = true);
    }
  }

  Future<void> _startCameraController(CameraDescription camera) async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
      }
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();

      try {
        _minZoom = await _controller!.getMinZoomLevel();
        _maxZoom = await _controller!.getMaxZoomLevel();
        _currentZoom = _minZoom;
      } catch (zoomErr) {
        _minZoom = 1.0;
        _maxZoom = 1.0;
        _currentZoom = 1.0;
      }

      if (mounted) {
        setState(() {
          _isInit = true;
          _hasCameraError = false;
          _isFlashOn = false;
        });
      }
    } catch (e) {
      AppLogger.warning('SCAN_SCREEN', 'Failed to start camera controller: $e');
      if (mounted) {
        setState(() {
          _isInit = false;
          _hasCameraError = true;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;
    setState(() => _isInit = false);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final target = zoom.clamp(_minZoom, _maxZoom.clamp(_minZoom, 5.0));
        await _controller!.setZoomLevel(target);
        if (mounted) setState(() => _currentZoom = target);
      } catch (e) {
        AppLogger.warning('SCAN_SCREEN', 'Error setting zoom: $e');
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
        await _controller!.setFlashMode(newMode);
        setState(() => _isFlashOn = !_isFlashOn);
      } catch (e) {
        AppLogger.warning('SCAN_SCREEN', 'Error toggling flash: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_controller != null && _controller!.value.isInitialized && !_isCapturing) {
      setState(() => _isCapturing = true);
      try {
        final file = await _controller!.takePicture();
        final bytes = await file.readAsBytes();
        if (mounted) {
          context.push('/review', extra: {
            'path': file.path,
            'bytes': bytes,
          });
        }
      } catch (e) {
        AppLogger.error('SCAN_SCREEN', 'Error taking picture: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la capture : $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickNativeCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 88,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        context.push('/review', extra: {
          'path': image.path,
          'bytes': bytes,
        });
      }
    } catch (e) {
      AppLogger.warning('SCAN_SCREEN', 'Error picking native camera: $e');
    }
  }

  Future<void> _pickGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 88,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        context.push('/review', extra: {
          'path': image.path,
          'bytes': bytes,
        });
      }
    } catch (e) {
      AppLogger.warning('SCAN_SCREEN', 'Error picking gallery image: $e');
    }
  }

  void _manualEntry() {
    context.push('/review', extra: '');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCameraError) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text('Scanner une bouteille', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera_outlined, size: 80, color: Colors.white70),
                const SizedBox(height: 20),
                const Text(
                  'Ajouter une bouteille',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Prenez une photo de votre étiquette ou choisissez une image depuis votre galerie pour l\'analyse automatique.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _pickNativeCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prendre une photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _pickGallery,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Choisir dans la galerie', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/scan/menu'),
                    icon: const Icon(Icons.restaurant_menu, color: Color(0xFFC2185B)),
                    label: const Text('Scanner une carte des vins (Restaurant)', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC2185B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _manualEntry,
                    icon: const Icon(Icons.edit_note, color: Colors.white70),
                    label: const Text('Saisie manuelle sans photo', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInit || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text('Préparation de la caméra...', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickNativeCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ouvrir l\'appareil photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _manualEntry,
                icon: const Icon(Icons.edit, color: Colors.white70),
                label: const Text('Passer à la saisie manuelle', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    final isFrontCamera = _controller!.description.lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Camera Preview with Pinch-to-Zoom
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) => _baseZoom = _currentZoom,
              onScaleUpdate: (details) => _setZoom(_baseZoom * details.scale),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize?.height ?? 1080,
                  height: _controller!.value.previewSize?.width ?? 1920,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          ),
          
          // Target focus reticle with clear aspect guidance
          Center(
            child: Container(
              width: 290,
              height: 420,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withAlpha(230), width: 2.5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(90),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '🍾 Rapprochez la bouteille',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Icon(Icons.crop_free, size: 64, color: Colors.white38),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: isFrontCamera
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade900.withAlpha(200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '⚠️ Caméra avant active',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        : const Text(
                            'Cadrez l\'étiquette dans le rectangle',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Top action bar
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => context.pop(),
                  ),
                ),
                Row(
                  children: [
                    if (_cameras.length > 1) ...[
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 22),
                          tooltip: 'Changer d\'objectif (Dorsale / Frontale)',
                          onPressed: _switchCamera,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: _isFlashOn ? Colors.amber : Colors.white,
                          size: 22,
                        ),
                        tooltip: 'Torche / Éclairage cave',
                        onPressed: _toggleFlash,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/scan/menu'),
                      icon: const Icon(Icons.restaurant_menu, color: Colors.white, size: 16),
                      label: const Text('Carte Menu', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFC2185B).withAlpha(200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _manualEntry,
                      icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                      label: const Text('Manuel', style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!ref.watch(isOnlineProvider))
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withAlpha(225),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hors-ligne : l\'analyse photo IA nécessite du réseau. La saisie manuelle reste disponible.',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Zoom preset chips (1x, 2x)
          if (_maxZoom > 1.2)
            Positioned(
              bottom: 128,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildZoomButton(1.0, '1x'),
                      const SizedBox(width: 6),
                      _buildZoomButton(2.0, '2x (Recommandé)'),
                      if (_maxZoom >= 3.0) ...[
                        const SizedBox(width: 6),
                        _buildZoomButton(3.0, '3x'),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Bottom control bar
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gallery Picker
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 26),
                        tooltip: 'Galerie photos',
                        onPressed: _pickGallery,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Galerie', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),

                // Shutter Button
                _isCapturing
                    ? const SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF8B1E3F), width: 4.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.camera_alt, color: Color(0xFF8B1E3F), size: 38),
                          ),
                        ),
                      ),

                // Native Camera Trigger
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.camera, color: Colors.white, size: 26),
                        tooltip: 'Appareil photo haute résolution',
                        onPressed: _pickNativeCamera,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Natif', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(double zoom, String label) {
    final isSelected = (_currentZoom - zoom).abs() < 0.3;
    return GestureDetector(
      onTap: () => _setZoom(zoom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B1E3F) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
