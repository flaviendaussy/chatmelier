import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  bool _isInit = false;
  bool _hasCameraError = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
        await _controller!.setFlashMode(newMode);
        setState(() => _isFlashOn = !_isFlashOn);
      } catch (e) {
        debugPrint('Error toggling flash: $e');
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInit = true;
            _hasCameraError = false;
          });
        }
      } else {
        if (mounted) setState(() => _hasCameraError = true);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) setState(() => _hasCameraError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final file = await _controller!.takePicture();
        if (mounted) context.push('/review', extra: file.path);
      } catch (e) {
        debugPrint('Error taking picture: $e');
      }
    }
  }

  Future<void> _pickGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        context.push('/review', extra: image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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
          title: const Text('Ajouter une bouteille', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera_back_outlined, size: 80, color: Colors.white70),
                const SizedBox(height: 24),
                const Text(
                  'Caméra non disponible',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vous pouvez choisir une photo dans votre galerie ou renseigner les informations manuellement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _pickGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choisir dans la galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _manualEntry,
                    icon: const Icon(Icons.edit_note, color: Colors.white),
                    label: const Text('Saisie manuelle sans photo', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInit) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text('Initialisation de la caméra...', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          
          // Target focus reticle
          Center(
            child: Container(
              width: 260,
              height: 360,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withAlpha(200), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.crop_free, size: 48, color: Colors.white38),
                  SizedBox(height: 8),
                  Text(
                    'Cadrez l\'étiquette',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
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
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: _isFlashOn ? Colors.amber : Colors.white,
                        size: 26,
                      ),
                      tooltip: 'Torche / Éclairage cave',
                      onPressed: _toggleFlash,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _manualEntry,
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      label: const Text('Manuel', style: TextStyle(color: Colors.white)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black45,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom control bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                  onPressed: _pickGallery,
                ),
                FloatingActionButton.large(
                  onPressed: _takePhoto,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 36),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.white, size: 32),
                  onPressed: _manualEntry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
