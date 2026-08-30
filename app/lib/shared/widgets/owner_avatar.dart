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
      return CircleAvatar(
        radius: effectiveRadius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
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
