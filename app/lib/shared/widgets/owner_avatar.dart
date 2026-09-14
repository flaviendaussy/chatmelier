import 'dart:convert';
import 'package:flutter/material.dart';

class OwnerAvatar extends StatelessWidget {
  final String? displayName;
  final String? avatarUrl;
  final String? userId;
  final double size;
  final double? radius;

  const OwnerAvatar({
    super.key,
    this.displayName,
    this.avatarUrl,
    this.userId,
    this.size = 28,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? (size / 2);
    final initial = (displayName != null && displayName!.isNotEmpty)
        ? displayName![0].toUpperCase()
        : 'U';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      // 1. Data URI Base64
      if (avatarUrl!.startsWith('data:image')) {
        try {
          final b64 = avatarUrl!.split(',').last;
          final bytes = base64Decode(b64);
          return CircleAvatar(
            radius: effectiveRadius,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      }

      // 2. Emoji preset avatar
      if (avatarUrl!.startsWith('emoji:')) {
        final emoji = avatarUrl!.substring('emoji:'.length);
        return CircleAvatar(
          radius: effectiveRadius,
          backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
          child: Text(emoji, style: TextStyle(fontSize: effectiveRadius * 1.05)),
        );
      }

      // 3. Network URL
      if (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://')) {
        return CircleAvatar(
          radius: effectiveRadius,
          backgroundImage: NetworkImage(avatarUrl!),
        );
      }
    }

    return CircleAvatar(
      radius: effectiveRadius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: effectiveRadius * 0.9,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
