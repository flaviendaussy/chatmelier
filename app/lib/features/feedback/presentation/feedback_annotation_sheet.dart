import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/utils/app_logger.dart';

class FeedbackStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  FeedbackStroke({
    required this.points,
    required this.color,
    this.strokeWidth = 3.5,
  });
}

class FeedbackAnnotationSheet extends StatefulWidget {
  final Uint8List? screenshotBytes;

  const FeedbackAnnotationSheet({
    super.key,
    required this.screenshotBytes,
  });

  static Future<void> show(BuildContext context, {Uint8List? screenshotBytes}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FeedbackAnnotationSheet(screenshotBytes: screenshotBytes),
    );
  }

  @override
  State<FeedbackAnnotationSheet> createState() => _FeedbackAnnotationSheetState();
}

class _FeedbackAnnotationSheetState extends State<FeedbackAnnotationSheet> {
  final List<FeedbackStroke> _strokes = [];
  Color _selectedColor = const Color(0xFFE53935); // Bold Red default
  final double _strokeWidth = 4.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  ui.Image? _decodedImage;

  @override
  void initState() {
    super.initState();
    if (widget.screenshotBytes != null) {
      _decodeScreenshot(widget.screenshotBytes!);
    }
  }

  Future<void> _decodeScreenshot(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('Failed to decode screenshot image: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
    });
  }

  Future<Uint8List?> _renderAnnotatedImage() async {
    if (_decodedImage == null) return widget.screenshotBytes;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final width = _decodedImage!.width.toDouble();
      final height = _decodedImage!.height.toDouble();

      // 1. Draw base screenshot
      canvas.drawImage(_decodedImage!, Offset.zero, Paint());

      // 2. Draw user strokes scaled to image coordinates
      for (final stroke in _strokes) {
        final paint = Paint()
          ..color = stroke.color
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = stroke.strokeWidth * (width / 360.0).clamp(1.0, 3.0)
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error rendering annotated image: $e');
      return widget.screenshotBytes;
    }
  }

  Future<void> _submitFeedback() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty && _strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter un commentaire ou entourer un élément.'),
          backgroundColor: Color(0xFF8B1E3F),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final userId = user?.id ?? 'anonymous_tester';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      String? uploadedImageUrl;

      // Render & upload annotated image if present
      final annotatedBytes = await _renderAnnotatedImage();
      if (annotatedBytes != null) {
        final fileName = '$userId/feedback_$timestamp.png';
        try {
          await supabase.storage.from('labels').uploadBinary(
            fileName,
            annotatedBytes,
            fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
          );
          uploadedImageUrl = supabase.storage.from('labels').getPublicUrl(fileName);
        } catch (uploadErr) {
          debugPrint('Storage upload note: $uploadErr');
        }
      }

      // Log to app diagnostic logs for Flavien to inspect
      AppLogger.info(
        'USER_FEEDBACK',
        'Commentaire: ${comment.isNotEmpty ? comment : "Sans commentaire"} | Capture: ${uploadedImageUrl ?? "aucune"} | Annotations: ${_strokes.isNotEmpty ? "oui" : "non"} | Testeur: $userId',
      );
      await AppLogger.flushToServer();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Merci pour votre retour ! 🍷 Le rapport a été transmis.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1815) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vibration, color: Color(0xFF8B1E3F), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Retour Testeur & Annotation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tools toolbar (Color picker, Undo, Clear)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: isDark ? Colors.black26 : Colors.grey.shade100,
            child: Row(
              children: [
                const Text(
                  'Stylet :',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _buildColorDot(const Color(0xFFE53935)), // Red
                const SizedBox(width: 6),
                _buildColorDot(const Color(0xFFFFB300)), // Amber/Gold
                const SizedBox(width: 6),
                _buildColorDot(const Color(0xFF00ACC1)), // Cyan
                const Spacer(),
                IconButton(
                  tooltip: 'Annuler le dernier trait',
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: _strokes.isNotEmpty ? _undo : null,
                ),
                IconButton(
                  tooltip: 'Tout effacer',
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                  onPressed: _strokes.isNotEmpty ? _clear : null,
                ),
              ],
            ),
          ),

          // Interactive Annotation Canvas over Screenshot
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.screenshotBytes != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _strokes.add(
                                FeedbackStroke(
                                  points: [details.localPosition],
                                  color: _selectedColor,
                                  strokeWidth: _strokeWidth,
                                ),
                              );
                            });
                          },
                          onPanUpdate: (details) {
                            if (_strokes.isNotEmpty) {
                              setState(() {
                                _strokes.last.points.add(details.localPosition);
                              });
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                widget.screenshotBytes!,
                                fit: BoxFit.contain,
                              ),
                              CustomPaint(
                                painter: _AnnotationPainter(
                                  strokes: _strokes,
                                ),
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'Aucune capture d\'écran disponible',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),
          ),

          // Comment input
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, media.viewInsets.bottom + 12),
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Entourez la zone et décrivez votre retour ou bug...',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Envoi en cours...' : 'Envoyer le rapport',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _isSubmitting ? null : _submitFeedback,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<FeedbackStroke> strokes;

  _AnnotationPainter({
    required this.strokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw strokes
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
