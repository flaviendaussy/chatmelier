import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Universal high-res bottle and label image view for Chatmelier.
/// Safely renders:
/// - Remote HTTP/HTTPS URLs (Supabase storage / external)
/// - Local File system paths (recent camera / gallery / offline photos)
/// - Base64 Data URIs (web images / thumbnails)
/// - Embedded assets
/// - Rich sommelier fallback badges when no image is available
class BottleImageView extends StatelessWidget {
  final String? imagePath;
  final String? wineType;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  const BottleImageView({
    super.key,
    required this.imagePath,
    this.wineType,
    this.width = 44,
    this.height = 44,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  Color _getWineColor(String? type) {
    final t = (type ?? 'red').toLowerCase();
    if (t.contains('white') || t.contains('blanc')) {
      return const Color(0xFFE8D382);
    } else if (t.contains('rose') || t.contains('rosé')) {
      return const Color(0xFFF4A6B8);
    } else if (t.contains('sparkling') || t.contains('effervescent') || t.contains('champagne') || t.contains('bulles') || t.contains('cremant') || t.contains('crémant')) {
      return const Color(0xFFE5C158);
    } else if (t.contains('sweet') || t.contains('liquoreux') || t.contains('moelleux')) {
      return const Color(0xFFD49E34);
    } else if (t.contains('orange') || t.contains('ambré')) {
      return const Color(0xFFD36F39);
    } else {
      return const Color(0xFF8B1E3F); // Classic Wine Ruby / Rouge
    }
  }

  IconData _getWineIcon(String? type) {
    final t = (type ?? 'red').toLowerCase();
    if (t.contains('sparkling') || t.contains('champagne') || t.contains('bulles') || t.contains('effervescent')) {
      return Icons.celebration;
    } else if (t.contains('sweet') || t.contains('liquoreux')) {
      return Icons.wb_sunny;
    }
    return Icons.wine_bar;
  }

  Widget _buildFallback(BuildContext context) {
    if (placeholder != null) return placeholder!;
    final color = _getWineColor(wineType);
    final icon = _getWineIcon(wineType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: width * 0.52,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = imagePath?.trim();
    if (raw == null || raw.isEmpty) {
      return _buildFallback(context);
    }

    // 1. Remote HTTP / HTTPS URL
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: raw,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: Colors.grey.withValues(alpha: 0.1),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallback(context),
        ),
      );
    }

    // 2. Base64 Data URI
    if (raw.startsWith('data:image')) {
      try {
        final commaIdx = raw.indexOf(',');
        final base64Str = commaIdx != -1 ? raw.substring(commaIdx + 1) : raw;
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildFallback(context),
          ),
        );
      } catch (_) {
        return _buildFallback(context);
      }
    }

    // 3. Embedded Flutter Asset
    if (raw.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          raw,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(context),
        ),
      );
    }

    // 4. Local File System Path (on non-web platforms)
    if (!kIsWeb) {
      try {
        final file = File(raw);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => _buildFallback(context),
            ),
          );
        }
      } catch (_) {
        // Fall through to fallback
      }
    }

    // Fallback if none of the above succeeded
    return _buildFallback(context);
  }
}
