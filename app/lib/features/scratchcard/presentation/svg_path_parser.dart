import 'package:flutter/material.dart';

/// Lightweight, robust SVG Path parser in pure Dart.
/// Converts standard SVG path `d` strings into Flutter [Path] objects,
/// scaled and translated to fit the given target [Rect] or [Size].
class SvgPathParser {
  static final Map<String, Path> _basePathCache = {};
  static final Map<String, Path> _transformedPathCache = {};

  /// Clears in-memory parsed path caches.
  static void clearCache() {
    _basePathCache.clear();
    _transformedPathCache.clear();
  }

  /// Parses an SVG path `d` attribute string into a Flutter [Path].
  /// Optionally transforms the path from a [viewBox] (e.g. `Rect.fromLTWH(0, 0, 1000, 1000)`)
  /// to fit into [targetRect].
  static Path parse(String d, {Rect? viewBox, Rect? targetRect}) {
    if (d.isEmpty) return Path();

    if (viewBox != null && targetRect != null) {
      final transformKey = '${d.hashCode}_${viewBox.left.round()}_${viewBox.top.round()}_${viewBox.width.round()}_${viewBox.height.round()}_${targetRect.left.round()}_${targetRect.top.round()}_${targetRect.width.round()}_${targetRect.height.round()}';
      final cached = _transformedPathCache[transformKey];
      if (cached != null) return cached;
    }

    Path basePath;
    final baseKey = '${d.hashCode}';
    if (_basePathCache.containsKey(baseKey)) {
      basePath = _basePathCache[baseKey]!;
    } else {
      basePath = _parseRaw(d);
      _basePathCache[baseKey] = basePath;
    }

    if (viewBox != null && targetRect != null) {
      final scaleX = targetRect.width / viewBox.width;
      final scaleY = targetRect.height / viewBox.height;
      final matrix = Matrix4.identity()
        ..multiply(Matrix4.translationValues(targetRect.left, targetRect.top, 0.0))
        ..multiply(Matrix4.diagonal3Values(scaleX, scaleY, 1.0))
        ..multiply(Matrix4.translationValues(-viewBox.left, -viewBox.top, 0.0));
      final transformed = basePath.transform(matrix.storage);
      final transformKey = '${d.hashCode}_${viewBox.left.round()}_${viewBox.top.round()}_${viewBox.width.round()}_${viewBox.height.round()}_${targetRect.left.round()}_${targetRect.top.round()}_${targetRect.width.round()}_${targetRect.height.round()}';
      if (_transformedPathCache.length > 300) {
        _transformedPathCache.clear();
      }
      _transformedPathCache[transformKey] = transformed;
      return transformed;
    }

    return basePath;
  }

  static Path _parseRaw(String d) {
    final path = Path();
    final tokens = _tokenize(d);
    if (tokens.isEmpty) return path;

    double curX = 0;
    double curY = 0;
    double startX = 0;
    double startY = 0;
    double lastCtrlX = 0;
    double lastCtrlY = 0;
    String lastCmd = '';

    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (_isCommand(token)) {
        lastCmd = token;
        i++;
      }

      switch (lastCmd) {
        case 'M': // moveto absolute
          if (i + 1 < tokens.length) {
            curX = double.parse(tokens[i++]);
            curY = double.parse(tokens[i++]);
            startX = curX;
            startY = curY;
            path.moveTo(curX, curY);
            lastCmd = 'L'; // subsequent coordinate pairs are implicit lineto
          }
          break;

        case 'm': // moveto relative
          if (i + 1 < tokens.length) {
            curX += double.parse(tokens[i++]);
            curY += double.parse(tokens[i++]);
            startX = curX;
            startY = curY;
            path.moveTo(curX, curY);
            lastCmd = 'l';
          }
          break;

        case 'L': // lineto absolute
          if (i + 1 < tokens.length) {
            curX = double.parse(tokens[i++]);
            curY = double.parse(tokens[i++]);
            path.lineTo(curX, curY);
          }
          break;

        case 'l': // lineto relative
          if (i + 1 < tokens.length) {
            curX += double.parse(tokens[i++]);
            curY += double.parse(tokens[i++]);
            path.lineTo(curX, curY);
          }
          break;

        case 'H': // horizontal lineto absolute
          if (i < tokens.length) {
            curX = double.parse(tokens[i++]);
            path.lineTo(curX, curY);
          }
          break;

        case 'h': // horizontal lineto relative
          if (i < tokens.length) {
            curX += double.parse(tokens[i++]);
            path.lineTo(curX, curY);
          }
          break;

        case 'V': // vertical lineto absolute
          if (i < tokens.length) {
            curY = double.parse(tokens[i++]);
            path.lineTo(curX, curY);
          }
          break;

        case 'v': // vertical lineto relative
          if (i < tokens.length) {
            curY += double.parse(tokens[i++]);
            path.lineTo(curX, curY);
          }
          break;

        case 'C': // cubic curveto absolute
          if (i + 5 < tokens.length) {
            final x1 = double.parse(tokens[i++]);
            final y1 = double.parse(tokens[i++]);
            final x2 = double.parse(tokens[i++]);
            final y2 = double.parse(tokens[i++]);
            curX = double.parse(tokens[i++]);
            curY = double.parse(tokens[i++]);
            path.cubicTo(x1, y1, x2, y2, curX, curY);
            lastCtrlX = x2;
            lastCtrlY = y2;
          }
          break;

        case 'c': // cubic curveto relative
          if (i + 5 < tokens.length) {
            final x1 = curX + double.parse(tokens[i++]);
            final y1 = curY + double.parse(tokens[i++]);
            final x2 = curX + double.parse(tokens[i++]);
            final y2 = curY + double.parse(tokens[i++]);
            curX += double.parse(tokens[i++]);
            curY += double.parse(tokens[i++]);
            path.cubicTo(x1, y1, x2, y2, curX, curY);
            lastCtrlX = x2;
            lastCtrlY = y2;
          }
          break;

        case 'S': // smooth cubic curveto absolute
          if (i + 3 < tokens.length) {
            final x1 = (lastCmd == 'C' || lastCmd == 'c' || lastCmd == 'S' || lastCmd == 's')
                ? 2 * curX - lastCtrlX
                : curX;
            final y1 = (lastCmd == 'C' || lastCmd == 'c' || lastCmd == 'S' || lastCmd == 's')
                ? 2 * curY - lastCtrlY
                : curY;
            final x2 = double.parse(tokens[i++]);
            final y2 = double.parse(tokens[i++]);
            curX = double.parse(tokens[i++]);
            curY = double.parse(tokens[i++]);
            path.cubicTo(x1, y1, x2, y2, curX, curY);
            lastCtrlX = x2;
            lastCtrlY = y2;
          }
          break;

        case 's': // smooth cubic curveto relative
          if (i + 3 < tokens.length) {
            final x1 = (lastCmd == 'C' || lastCmd == 'c' || lastCmd == 'S' || lastCmd == 's')
                ? 2 * curX - lastCtrlX
                : curX;
            final y1 = (lastCmd == 'C' || lastCmd == 'c' || lastCmd == 'S' || lastCmd == 's')
                ? 2 * curY - lastCtrlY
                : curY;
            final x2 = curX + double.parse(tokens[i++]);
            final y2 = double.parse(tokens[i++]);
            curX += double.parse(tokens[i++]);
            curY += double.parse(tokens[i++]);
            path.cubicTo(x1, y1, x2, y2, curX, curY);
            lastCtrlX = x2;
            lastCtrlY = y2;
          }
          break;

        case 'Q': // quadratic curveto absolute
          if (i + 3 < tokens.length) {
            final x1 = double.parse(tokens[i++]);
            final y1 = double.parse(tokens[i++]);
            curX = double.parse(tokens[i++]);
            curY = double.parse(tokens[i++]);
            path.quadraticBezierTo(x1, y1, curX, curY);
            lastCtrlX = x1;
            lastCtrlY = y1;
          }
          break;

        case 'q': // quadratic curveto relative
          if (i + 3 < tokens.length) {
            final x1 = curX + double.parse(tokens[i++]);
            final y1 = curY + double.parse(tokens[i++]);
            curX += double.parse(tokens[i++]);
            curY += double.parse(tokens[i++]);
            path.quadraticBezierTo(x1, y1, curX, curY);
            lastCtrlX = x1;
            lastCtrlY = y1;
          }
          break;

        case 'Z':
        case 'z': // closepath
          path.close();
          curX = startX;
          curY = startY;
          break;

        default:
          i++;
      }
    }

    return path;
  }

  static bool _isCommand(String s) {
    if (s.length != 1) return false;
    return 'MmLlHhVvCcSsQqZz'.contains(s);
  }

  static List<String> _tokenize(String d) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < d.length; i++) {
      final char = d[i];

      if (_isCommand(char)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
      } else if (char == ' ' || char == ',' || char == '\t' || char == '\n' || char == '\r') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else if (char == '-') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        buffer.write(char);
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }
}
