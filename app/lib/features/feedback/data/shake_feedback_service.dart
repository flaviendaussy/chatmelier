import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../config/navigator_keys.dart';
import '../presentation/feedback_annotation_sheet.dart';

/// Service detecting physical device shakes to prompt testers for feedback and annotations.
class ShakeFeedbackService {
  static final ShakeFeedbackService instance = ShakeFeedbackService._();
  ShakeFeedbackService._();

  /// Global RepaintBoundary key wrapping the main app interface
  static final GlobalKey rootRepaintBoundaryKey = GlobalKey();

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  bool _isPromptOpen = false;

  // Sensitivity configuration: user acceleration without gravity
  static const double _shakeThreshold = 12.0; // m/s² acceleration magnitude
  static const Duration _cooldown = Duration(seconds: 2);

  /// Initializes the shake listener on supported platforms (Android / iOS)
  void startListening() {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    _accelerometerSubscription?.cancel();
    try {
      _accelerometerSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          final double magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          if (magnitude > _shakeThreshold) {
            final now = DateTime.now();
            if (_lastShakeTime == null || now.difference(_lastShakeTime!) > _cooldown) {
              _lastShakeTime = now;
              if (!_isPromptOpen) {
                triggerFeedback();
              }
            }
          }
        },
        onError: (err) {
          debugPrint('ShakeFeedbackService: Accelerometer error: $err');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('ShakeFeedbackService: Failed to listen to accelerometer: $e');
    }
  }

  /// Stops listening to accelerometer events
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  /// Captures the current visible application screen as PNG bytes
  static Future<Uint8List?> captureScreenshot() async {
    try {
      final boundary = rootRepaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('ShakeFeedbackService: Failed to capture screenshot: $e');
      return null;
    }
  }

  /// Triggers the feedback workflow: captures screenshot and opens the annotation sheet
  Future<void> triggerFeedback([BuildContext? context]) async {
    if (_isPromptOpen) return;
    _isPromptOpen = true;

    try {
      final targetContext = rootNavigatorKey.currentContext ?? context;
      if (targetContext == null || !targetContext.mounted) return;

      final screenshot = await captureScreenshot();
      if (targetContext.mounted) {
        await FeedbackAnnotationSheet.show(targetContext, screenshotBytes: screenshot);
      }
    } finally {
      _isPromptOpen = false;
    }
  }
}
