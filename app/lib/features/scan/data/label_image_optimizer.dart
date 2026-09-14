import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import '../../../shared/utils/app_logger.dart';

/// Holds the optimized image bytes, metadata, and deterministic SHA-256 hash.
class OptimizedLabelImage {
  final Uint8List bytes;
  final String sha256Hash;
  final int originalWidth;
  final int originalHeight;
  final int width;
  final int height;
  final int originalSizeBytes;
  final int optimizedSizeBytes;
  final String mimeType;

  const OptimizedLabelImage({
    required this.bytes,
    required this.sha256Hash,
    required this.originalWidth,
    required this.originalHeight,
    required this.width,
    required this.height,
    required this.originalSizeBytes,
    required this.optimizedSizeBytes,
    this.mimeType = 'image/jpeg',
  });

  /// Compression ratio as percentage (e.g. 75.4% saved)
  double get savedSpacePercentage {
    if (originalSizeBytes <= 0) return 0.0;
    final saved = originalSizeBytes - optimizedSizeBytes;
    return (saved / originalSizeBytes * 100).clamp(0.0, 100.0);
  }
}

class LabelImageOptimizer {
  static const int maxDimension = 1024;
  static const int defaultJpegQuality = 84;

  /// Optimizes a raw label photo:
  /// 1. Crops out extraneous borders/background (keeps central 82% width, 78% height ROI).
  /// 2. Scales down to a maximum dimension of 1024px.
  /// 3. Re-encodes to high-clarity JPEG (quality 84).
  /// 4. Generates a deterministic SHA-256 hash for caching.
  static OptimizedLabelImage optimize(
    Uint8List rawBytes, {
    bool autoCrop = true,
    int targetQuality = defaultJpegQuality,
    int? maxDimension,
  }) {
    final originalSize = rawBytes.length;

    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        // Fallback if image cannot be decoded by image package
        final hash = sha256.convert(rawBytes).toString();
        return OptimizedLabelImage(
          bytes: rawBytes,
          sha256Hash: hash,
          originalWidth: 0,
          originalHeight: 0,
          width: 0,
          height: 0,
          originalSizeBytes: originalSize,
          optimizedSizeBytes: originalSize,
        );
      }

      final origW = decoded.width;
      final origH = decoded.height;
      img.Image processed = decoded;

      // 1. Auto-crop central Region of Interest (ROI) if portrait / camera photo
      if (autoCrop && origW > 300 && origH > 300) {
        // Keep 82% width and 78% height centered to remove noisy background / tables
        final cropW = (origW * 0.82).round();
        final cropH = (origH * 0.78).round();
        final cropX = ((origW - cropW) / 2).round();
        final cropY = ((origH - cropH) / 2).round();

        processed = img.copyCrop(
          processed,
          x: cropX,
          y: cropY,
          width: cropW,
          height: cropH,
        );
      }

      // 2. Downscale if exceeding maxDimension (default 1024px, or higher for menus)
      final limit = maxDimension ?? LabelImageOptimizer.maxDimension;
      final curW = processed.width;
      final curH = processed.height;
      if (curW > limit || curH > limit) {
        if (curW >= curH) {
          processed = img.copyResize(processed, width: limit);
        } else {
          processed = img.copyResize(processed, height: limit);
        }
      }

      // 3. Encode to JPEG with optimal quality
      final optimizedBytes = Uint8List.fromList(img.encodeJpg(processed, quality: targetQuality));
      final hash = sha256.convert(optimizedBytes).toString();

      final result = OptimizedLabelImage(
        bytes: optimizedBytes,
        sha256Hash: hash,
        originalWidth: origW,
        originalHeight: origH,
        width: processed.width,
        height: processed.height,
        originalSizeBytes: originalSize,
        optimizedSizeBytes: optimizedBytes.length,
      );

      AppLogger.info('IMAGE_OPT',
          'Optimized label: ${origW}x$origH ($originalSize B) -> ${result.width}x${result.height} (${result.optimizedSizeBytes} B) [Saved: ${result.savedSpacePercentage.toStringAsFixed(1)}%] • Hash: ${hash.substring(0, 10)}...');

      return result;
    } catch (e) {
      AppLogger.warning('IMAGE_OPT', 'Image optimization failed, falling back to raw bytes: $e');
      final hash = sha256.convert(rawBytes).toString();
      return OptimizedLabelImage(
        bytes: rawBytes,
        sha256Hash: hash,
        originalWidth: 0,
        originalHeight: 0,
        width: 0,
        height: 0,
        originalSizeBytes: originalSize,
        optimizedSizeBytes: originalSize,
      );
    }
  }
}
