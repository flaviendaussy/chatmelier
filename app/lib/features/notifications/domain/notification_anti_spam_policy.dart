/// Domain engine providing anti-spam, quiet hours, and notification batching rules.
class NotificationAntiSpamPolicy {
  static const int defaultQuietStartHour = 22; // 22:00 (10 PM)
  static const int defaultQuietEndHour = 8;    // 08:00 AM
  static const int defaultQuietEndMinute = 30; // 08:30 AM
  static const Duration sessionBatchingWindow = Duration(hours: 3);
  static const Duration minProactiveCooldown = Duration(hours: 4);

  /// Checks whether a given [dateTime] falls within the quiet hours window.
  /// Handles the overnight span (e.g. 22:00 to 08:30 next morning).
  static bool isWithinQuietHours(
    DateTime dateTime, {
    int startHour = defaultQuietStartHour,
    int endHour = defaultQuietEndHour,
    int endMinute = defaultQuietEndMinute,
  }) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final totalMinutes = hour * 60 + minute;

    final startMinutes = startHour * 60;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes > endMinutes) {
      // Overnight span (e.g. 22:00 to 08:30)
      return totalMinutes >= startMinutes || totalMinutes < endMinutes;
    } else {
      // Same day span
      return totalMinutes >= startMinutes && totalMinutes < endMinutes;
    }
  }

  /// Adjusts a scheduled [targetTime] so that if it falls inside quiet hours,
  /// it is safely deferred to the morning after the quiet period (e.g. 09:00 AM).
  static DateTime adjustForQuietHours(
    DateTime targetTime, {
    bool quietHoursEnabled = true,
    int startHour = defaultQuietStartHour,
    int endHour = defaultQuietEndHour,
    int endMinute = defaultQuietEndMinute,
    int resumeHour = 9,
    int resumeMinute = 0,
  }) {
    if (!quietHoursEnabled) return targetTime;
    if (!isWithinQuietHours(targetTime, startHour: startHour, endHour: endHour, endMinute: endMinute)) {
      return targetTime;
    }

    // Determine target day for resume time
    // If targetTime is late evening (>= startHour), morning is next day
    // If targetTime is early morning (< endHour/endMinute), morning is same day
    DateTime resumeDate;
    if (targetTime.hour >= startHour) {
      final nextDay = targetTime.add(const Duration(days: 1));
      resumeDate = DateTime(nextDay.year, nextDay.month, nextDay.day, resumeHour, resumeMinute);
    } else {
      resumeDate = DateTime(targetTime.year, targetTime.month, targetTime.day, resumeHour, resumeMinute);
    }

    return resumeDate;
  }

  /// Calculates the effective scheduled time after applying base delay and quiet hours protection.
  static DateTime computeScheduledTime({
    required DateTime from,
    required Duration baseDelay,
    required bool quietHoursEnabled,
    int startHour = defaultQuietStartHour,
    int endHour = defaultQuietEndHour,
    int endMinute = defaultQuietEndMinute,
  }) {
    final baseTime = from.add(baseDelay);
    return adjustForQuietHours(
      baseTime,
      quietHoursEnabled: quietHoursEnabled,
      startHour: startHour,
      endHour: endHour,
      endMinute: endMinute,
    );
  }

  /// Formats a consolidated notification message when multiple bottles are checked out in the same session.
  static String buildConsolidatedTitle(int bottleCount) {
    if (bottleCount <= 1) {
      return '🍷 Alors, cette dégustation ?';
    }
    return '🍷 Dégustation de votre soirée ($bottleCount bouteilles)';
  }

  /// Formats the notification body for single or multiple bottles.
  static String buildConsolidatedBody(List<String> wineNames) {
    if (wineNames.isEmpty) {
      return 'Prenez 30 secondes pour noter vos impressions et affiner votre profil œnologique.';
    }
    if (wineNames.length == 1) {
      return 'Vous avez sorti ${wineNames.first}. Prenez 30s pour noter vos impressions tant que le souvenir est frais !';
    }
    final preview = wineNames.take(3).join(', ');
    final remaining = wineNames.length > 3 ? ' et ${wineNames.length - 3} autre(s)' : '';
    return 'Vous avez dégusté $preview$remaining. Partagez vos impressions en un clin d\'œil !';
  }

  /// Verifies whether a proactive notification (apogee, weekend suggestion)
  /// is allowed based on daily limits and cooldown.
  static bool canSendProactiveAlert({
    required DateTime now,
    required DateTime? lastAlertSentAt,
    required int alertsSentToday,
    int maxAlertsPerDay = 2,
    Duration cooldown = minProactiveCooldown,
  }) {
    if (alertsSentToday >= maxAlertsPerDay) return false;
    if (lastAlertSentAt != null) {
      final elapsed = now.difference(lastAlertSentAt);
      if (elapsed < cooldown) return false;
    }
    return true;
  }
}
