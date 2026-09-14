import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/badge.dart';
import '../presentation/badge_unlock_celebration_dialog.dart';
import 'badges_provider.dart';

/// Manages persisted history of seen unlocked badges in [SharedPreferences]
/// and coordinates triggering celebration popups when a badge is unlocked.
class BadgeUnlockTracker {
  static const String _keySeenBadges = 'chatmelier_seen_badge_ids';
  static const String _keyTrackerInitialized = 'chatmelier_badge_tracker_initialized';
  static const String keyAnimationsEnabled = 'chatmelier_badge_celebration_animations_enabled';

  /// Returns whether celebration popup animations are enabled by the user.
  /// Defaults to true.
  static Future<bool> areAnimationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyAnimationsEnabled) ?? true;
  }

  /// Sets whether celebration popup animations are enabled.
  static Future<void> setAnimationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAnimationsEnabled, enabled);
  }

  /// Check all unlocked badges against stored seen badges.
  /// If [context] is provided and there are new unlocks, presents the celebration popup
  /// for the highest-tier newly unlocked badge, and marks it as seen.
  /// If animations are disabled in settings, marks badges as seen without showing the popup.
  static Future<List<BadgeProgress>> checkAndCelebrateNewUnlocks(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final allBadges = ref.read(userBadgesProgressProvider);
    final unlockedBadges = allBadges.where((b) => b.isUnlocked).toList();

    final isInitialized = prefs.getBool(_keyTrackerInitialized) ?? false;
    final seenIds = (prefs.getStringList(_keySeenBadges) ?? <String>[]).toSet();

    // First time running with the tracker: mark all existing unlocked badges as seen
    // to avoid overwhelming existing users with 20+ celebration popups.
    if (!isInitialized) {
      final initialIds = unlockedBadges.map((b) => b.badge.id).toList();
      await prefs.setStringList(_keySeenBadges, initialIds);
      await prefs.setBool(_keyTrackerInitialized, true);
      return const [];
    }

    final newlyUnlocked = unlockedBadges.where((b) => !seenIds.contains(b.badge.id)).toList();
    if (newlyUnlocked.isEmpty) return const [];

    final animationsEnabled = await areAnimationsEnabled();

    // If animations are disabled by user preference, silently mark all newly unlocked as seen
    if (!animationsEnabled) {
      seenIds.addAll(newlyUnlocked.map((b) => b.badge.id));
      await prefs.setStringList(_keySeenBadges, seenIds.toList());
      return newlyUnlocked;
    }

    // Prioritize highest tier badge for celebration
    newlyUnlocked.sort((a, b) => b.badge.tier.index.compareTo(a.badge.tier.index));
    final celebratingBadge = newlyUnlocked.first;

    // Mark as seen immediately so it doesn't pop up again
    seenIds.add(celebratingBadge.badge.id);
    await prefs.setStringList(_keySeenBadges, seenIds.toList());

    if (context.mounted) {
      await BadgeUnlockCelebrationDialog.show(context, celebratingBadge);
    }

    return newlyUnlocked;
  }

  /// Mark specific badge ID as seen.
  static Future<void> markBadgeAsSeen(String badgeId) async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = (prefs.getStringList(_keySeenBadges) ?? <String>[]).toSet();
    seenIds.add(badgeId);
    await prefs.setStringList(_keySeenBadges, seenIds.toList());
  }

  /// Reset seen badges (useful for testing or debug).
  static Future<void> resetSeenBadges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySeenBadges);
    await prefs.remove(_keyTrackerInitialized);
  }
}
