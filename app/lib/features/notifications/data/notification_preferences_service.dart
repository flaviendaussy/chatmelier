import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User settings for on-device system notifications.
class NotificationPreferences {
  final bool postTastingEnabled;
  final bool apogeeAlertsEnabled;
  final bool sharedCellarActivityEnabled;
  final bool friendRequestsEnabled;
  final bool weekendSuggestionsEnabled;
  final bool lowStockAlertsEnabled;
  final bool quietHoursEnabled;
  final bool batchMultipleTastingsEnabled;
  final int maxAlertsPerDay;

  const NotificationPreferences({
    this.postTastingEnabled = true,
    this.apogeeAlertsEnabled = true,
    this.sharedCellarActivityEnabled = true,
    this.friendRequestsEnabled = true,
    this.weekendSuggestionsEnabled = true,
    this.lowStockAlertsEnabled = false,
    this.quietHoursEnabled = true,
    this.batchMultipleTastingsEnabled = true,
    this.maxAlertsPerDay = 2,
  });

  NotificationPreferences copyWith({
    bool? postTastingEnabled,
    bool? apogeeAlertsEnabled,
    bool? sharedCellarActivityEnabled,
    bool? friendRequestsEnabled,
    bool? weekendSuggestionsEnabled,
    bool? lowStockAlertsEnabled,
    bool? quietHoursEnabled,
    bool? batchMultipleTastingsEnabled,
    int? maxAlertsPerDay,
  }) {
    return NotificationPreferences(
      postTastingEnabled: postTastingEnabled ?? this.postTastingEnabled,
      apogeeAlertsEnabled: apogeeAlertsEnabled ?? this.apogeeAlertsEnabled,
      sharedCellarActivityEnabled: sharedCellarActivityEnabled ?? this.sharedCellarActivityEnabled,
      friendRequestsEnabled: friendRequestsEnabled ?? this.friendRequestsEnabled,
      weekendSuggestionsEnabled: weekendSuggestionsEnabled ?? this.weekendSuggestionsEnabled,
      lowStockAlertsEnabled: lowStockAlertsEnabled ?? this.lowStockAlertsEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      batchMultipleTastingsEnabled: batchMultipleTastingsEnabled ?? this.batchMultipleTastingsEnabled,
      maxAlertsPerDay: maxAlertsPerDay ?? this.maxAlertsPerDay,
    );
  }

  int get activeCount {
    int count = 0;
    if (postTastingEnabled) count++;
    if (apogeeAlertsEnabled) count++;
    if (sharedCellarActivityEnabled) count++;
    if (friendRequestsEnabled) count++;
    if (weekendSuggestionsEnabled) count++;
    if (lowStockAlertsEnabled) count++;
    return count;
  }
}

/// Service managing persistence of notification preferences.
class NotificationPreferencesService {
  static const _keyPrefix = 'notif_pref_';
  static const keyPostTasting = '${_keyPrefix}post_tasting';
  static const keyApogee = '${_keyPrefix}apogee';
  static const keySharedCellar = '${_keyPrefix}shared_cellar';
  static const keyFriends = '${_keyPrefix}friends';
  static const keyWeekend = '${_keyPrefix}weekend';
  static const keyLowStock = '${_keyPrefix}low_stock';
  static const keyQuietHours = '${_keyPrefix}quiet_hours';
  static const keyBatchTastings = '${_keyPrefix}batch_tastings';
  static const keyMaxAlerts = '${_keyPrefix}max_alerts';
  static const keyPermissionPrompted = '${_keyPrefix}permission_prompted';

  final SharedPreferences _prefs;

  NotificationPreferencesService(this._prefs);

  NotificationPreferences loadPreferences() {
    return NotificationPreferences(
      postTastingEnabled: _prefs.getBool(keyPostTasting) ?? true,
      apogeeAlertsEnabled: _prefs.getBool(keyApogee) ?? true,
      sharedCellarActivityEnabled: _prefs.getBool(keySharedCellar) ?? true,
      friendRequestsEnabled: _prefs.getBool(keyFriends) ?? true,
      weekendSuggestionsEnabled: _prefs.getBool(keyWeekend) ?? true,
      lowStockAlertsEnabled: _prefs.getBool(keyLowStock) ?? false,
      quietHoursEnabled: _prefs.getBool(keyQuietHours) ?? true,
      batchMultipleTastingsEnabled: _prefs.getBool(keyBatchTastings) ?? true,
      maxAlertsPerDay: _prefs.getInt(keyMaxAlerts) ?? 2,
    );
  }

  Future<void> savePreferences(NotificationPreferences prefs) async {
    await _prefs.setBool(keyPostTasting, prefs.postTastingEnabled);
    await _prefs.setBool(keyApogee, prefs.apogeeAlertsEnabled);
    await _prefs.setBool(keySharedCellar, prefs.sharedCellarActivityEnabled);
    await _prefs.setBool(keyFriends, prefs.friendRequestsEnabled);
    await _prefs.setBool(keyWeekend, prefs.weekendSuggestionsEnabled);
    await _prefs.setBool(keyLowStock, prefs.lowStockAlertsEnabled);
    await _prefs.setBool(keyQuietHours, prefs.quietHoursEnabled);
    await _prefs.setBool(keyBatchTastings, prefs.batchMultipleTastingsEnabled);
    await _prefs.setInt(keyMaxAlerts, prefs.maxAlertsPerDay);
  }

  bool hasPromptedPermission() {
    return _prefs.getBool(keyPermissionPrompted) ?? false;
  }

  Future<void> markPermissionPrompted() async {
    await _prefs.setBool(keyPermissionPrompted, true);
  }
}

/// Provider for NotificationPreferencesService.
final notificationPreferencesServiceProvider = FutureProvider<NotificationPreferencesService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return NotificationPreferencesService(prefs);
});

/// Notifier provider exposing current preferences.
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  SharedPreferences? _prefs;

  NotificationPreferencesNotifier() : super(const NotificationPreferences()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final service = NotificationPreferencesService(_prefs!);
    state = service.loadPreferences();
  }

  Future<void> updatePreference({
    bool? postTastingEnabled,
    bool? apogeeAlertsEnabled,
    bool? sharedCellarActivityEnabled,
    bool? friendRequestsEnabled,
    bool? weekendSuggestionsEnabled,
    bool? lowStockAlertsEnabled,
    bool? quietHoursEnabled,
    bool? batchMultipleTastingsEnabled,
    int? maxAlertsPerDay,
  }) async {
    final updated = state.copyWith(
      postTastingEnabled: postTastingEnabled,
      apogeeAlertsEnabled: apogeeAlertsEnabled,
      sharedCellarActivityEnabled: sharedCellarActivityEnabled,
      friendRequestsEnabled: friendRequestsEnabled,
      weekendSuggestionsEnabled: weekendSuggestionsEnabled,
      lowStockAlertsEnabled: lowStockAlertsEnabled,
      quietHoursEnabled: quietHoursEnabled,
      batchMultipleTastingsEnabled: batchMultipleTastingsEnabled,
      maxAlertsPerDay: maxAlertsPerDay,
    );
    state = updated;
    _prefs ??= await SharedPreferences.getInstance();
    final service = NotificationPreferencesService(_prefs!);
    await service.savePreferences(updated);
  }

  Future<bool> hasPromptedPermission() async {
    _prefs ??= await SharedPreferences.getInstance();
    return NotificationPreferencesService(_prefs!).hasPromptedPermission();
  }

  Future<void> markPermissionPrompted() async {
    _prefs ??= await SharedPreferences.getInstance();
    await NotificationPreferencesService(_prefs!).markPermissionPrompted();
  }
}

/// Riverpod provider for NotificationPreferences.
final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>((ref) {
  return NotificationPreferencesNotifier();
});
