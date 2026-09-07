import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier managing the set of favorited wine and bottle IDs
class FavoriteWinesNotifier extends StateNotifier<Set<String>> {
  static const _storageKey = 'chatmelier_favorite_wine_ids';

  FavoriteWinesNotifier() : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      state = list.toSet();
    } catch (_) {}
  }

  Future<void> toggleFavorite(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return;

    final next = Set<String>.from(state);
    if (next.contains(cleanId)) {
      next.remove(cleanId);
    } else {
      next.add(cleanId);
    }
    state = next;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, next.toList());
    } catch (_) {}
  }

  bool isFavorite(String id) => state.contains(id.trim());
}

final favoriteWineIdsProvider =
    StateNotifierProvider<FavoriteWinesNotifier, Set<String>>((ref) {
  return FavoriteWinesNotifier();
});

/// ❤️ Heart toggle button widget for marking wines as favorites
class FavoriteHeartButton extends ConsumerWidget {
  final String wineOrBottleId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onToggled;

  const FavoriteHeartButton({
    super.key,
    required this.wineOrBottleId,
    this.size = 22,
    this.activeColor = const Color(0xFFE91E63),
    this.inactiveColor,
    this.onToggled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoriteWineIdsProvider).contains(wineOrBottleId.trim());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ref.read(favoriteWineIdsProvider.notifier).toggleFavorite(wineOrBottleId);
          onToggled?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              key: ValueKey<bool>(isFav),
              size: size,
              color: isFav ? (activeColor ?? const Color(0xFFE91E63)) : (inactiveColor ?? Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ),
      ),
    );
  }
}
