import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/navigator_keys.dart';
import '../domain/contexte_du_retour.dart';
import '../domain/detecteur_de_secousse.dart';
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

  /// Plusieurs pics francs en moins d'une seconde (voir [DetecteurDeSecousse]).
  final DetecteurDeSecousse _detecteur = DetecteurDeSecousse();
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
      // Une mesure toutes les 20 ms : à 200 ms (le rythme par défaut), les pics d'une
      // secousse passaient entre deux mesures.
      _accelerometerSubscription = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
        (UserAccelerometerEvent event) {
          final double magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          if (_detecteur.ajouter(magnitude, DateTime.now())) {
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

  /// Le serveur répond-il, et en combien de temps ? La même lecture que la version minimale
  /// au démarrage, bornée à trois secondes.
  static Future<String> _etatDuReseau() async {
    final debut = DateTime.now();
    try {
      await Supabase.instance.client
          .from('app_config')
          .select('cle')
          .eq('cle', 'version_minimale_test')
          .maybeSingle()
          .timeout(const Duration(seconds: 3));
      return 'serveur joignable (${DateTime.now().difference(debut).inMilliseconds} ms)';
    } catch (e) {
      final cause = '$e';
      return 'serveur injoignable : ${cause.length > 120 ? cause.substring(0, 120) : cause}';
    }
  }

  /// Triggers the feedback workflow: captures screenshot and opens the annotation sheet
  Future<void> triggerFeedback([BuildContext? context]) async {
    if (_isPromptOpen) return;
    _isPromptOpen = true;

    try {
      final targetContext = rootNavigatorKey.currentContext ?? context;
      if (targetContext == null || !targetContext.mounted) return;

      // Le contexte d'abord, avant que la feuille ne recouvre l'écran : c'est lui qui dira
      // d'où vient le retour si la capture manque (16/10).
      final contexte = ContexteDuRetour.capturer(targetContext);
      final screenshot = await captureScreenshot();
      contexte['reseau'] = await _etatDuReseau();
      if (targetContext.mounted) {
        await FeedbackAnnotationSheet.show(targetContext, screenshotBytes: screenshot, contexte: contexte);
      }
    } finally {
      _isPromptOpen = false;
    }
  }
}
