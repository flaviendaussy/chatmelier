import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_notification_service.dart';
import '../data/notification_preferences_service.dart';
import '../../../shared/utils/langue.dart';

/// Modal bottom sheet allowing the user to configure on-device system notifications.
class NotificationSettingsSheet extends ConsumerStatefulWidget {
  const NotificationSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationSettingsSheet(),
    );
  }

  @override
  ConsumerState<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends ConsumerState<NotificationSettingsSheet> {
  bool _isCheckingPermission = false;
  bool _permissionEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _isCheckingPermission = true);
    final service = ref.read(localNotificationServiceProvider);
    final enabled = await service.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _permissionEnabled = enabled;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final service = ref.read(localNotificationServiceProvider);
    final granted = await service.requestPermissions();
    if (mounted) {
      setState(() => _permissionEnabled = granted);
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Notifications activées avec succès !', 'Notifications turned on!')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _sendTest() async {
    final service = ref.read(localNotificationServiceProvider);
    await service.sendTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Notification test envoyée ! Regardez en haut de votre écran 🔔', 'Test notification sent! Look at the top of your screen 🔔')),
          backgroundColor: const Color(0xFF8B1E3F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Notifications Système', 'System notifications'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        tr('Alertes sur votre écran et barre d\'état', 'Alerts on your screen and status bar'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Permission Status Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _permissionEnabled
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _permissionEnabled
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : Colors.amber.shade700,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _permissionEnabled ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: _permissionEnabled ? const Color(0xFF10B981) : Colors.amber.shade800,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _permissionEnabled
                                  ? tr('Autorisation accordée', 'Permission granted')
                                  : tr('Autorisation système requise', 'System permission needed'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _permissionEnabled
                                  ? tr('Les notifications peuvent s\'afficher sur votre écran.', 'Notifications can appear on your screen.')
                                  : tr('Activez l\'accès pour recevoir les alertes même quand l\'application est fermée.', 'Allow access to get alerts even when the app is closed.'),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (!_permissionEnabled) ...[
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: _isCheckingPermission ? null : _requestPermission,
                          child: Text(tr('Autoriser', 'Allow'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Individual notification options
                _buildSwitchTile(
                  icon: Icons.wine_bar,
                  iconColor: const Color(0xFF8B1E3F),
                  title: tr('Rappels post-dégustation', 'After-tasting reminders'),
                  subtitle: tr('Rappel 1h30 après avoir ouvert une bouteille pour noter vos impressions pendant que le souvenir est frais.', 'A reminder 1½ hours after you open a bottle, to note your impressions while they\'re fresh.'),
                  value: prefs.postTastingEnabled,
                  onChanged: (val) => notifier.updatePreference(postTastingEnabled: val),
                ),
                const Divider(),

                _buildSwitchTile(
                  icon: Icons.hourglass_top,
                  iconColor: const Color(0xFFD4AF37),
                  title: tr('Fenêtres d\'apogée & déclin', 'Peak & decline windows'),
                  subtitle: tr('Alerte lorsqu\'un de vos vins atteint son plateau idéal de dégustation ou s\'il risque de dépasser sa maturité.', 'An alert when one of your wines reaches its ideal drinking plateau, or risks going past it.'),
                  value: prefs.apogeeAlertsEnabled,
                  onChanged: (val) => notifier.updatePreference(apogeeAlertsEnabled: val),
                ),
                const Divider(),

                _buildSwitchTile(
                  icon: Icons.sync,
                  iconColor: Colors.blue,
                  title: tr('Activité de cave partagée', 'Shared cellar activity'),
                  subtitle: tr('Savoir quand un membre de votre cave commune ouvre ou dépose une bouteille.', 'Know when someone in your shared cellar opens or adds a bottle.'),
                  value: prefs.sharedCellarActivityEnabled,
                  onChanged: (val) => notifier.updatePreference(sharedCellarActivityEnabled: val),
                ),
                const Divider(),

                _buildSwitchTile(
                  icon: Icons.people_outline,
                  iconColor: const Color(0xFF10B981),
                  title: tr('Amis & Invitations', 'Friends & invitations'),
                  subtitle: tr('Recevoir une alerte lors d\'une demande d\'ami ou d\'une invitation à rejoindre une cave.', 'Get an alert for a friend request or an invitation to join a cellar.'),
                  value: prefs.friendRequestsEnabled,
                  onChanged: (val) => notifier.updatePreference(friendRequestsEnabled: val),
                ),
                const Divider(),

                _buildSwitchTile(
                  icon: Icons.weekend_outlined,
                  iconColor: Colors.purple,
                  title: tr('Sommelier du week-end', 'Weekend sommelier'),
                  subtitle: tr('Inspiration du vendredi soir pour choisir la bouteille idéale de votre cave pour vos dîners.', 'A Friday-evening idea: the ideal bottle from your cellar for your dinners.'),
                  value: prefs.weekendSuggestionsEnabled,
                  onChanged: (val) => notifier.updatePreference(weekendSuggestionsEnabled: val),
                ),
                const Divider(),

                _buildSwitchTile(
                  icon: Icons.production_quantity_limits,
                  iconColor: Colors.orange,
                  title: tr('Alerte dernière bouteille', 'Last-bottle alert'),
                  subtitle: tr('Avertissement discret lorsque vous consommez l\'avant-dernière ou dernière bouteille d\'un cru.', 'A discreet heads-up when you open the last or second-to-last bottle of a wine.'),
                  value: prefs.lowStockAlertsEnabled,
                  onChanged: (val) => notifier.updatePreference(lowStockAlertsEnabled: val),
                ),
                const SizedBox(height: 16),

                // Anti-spam & quiet hours section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF8B1E3F)),
                      const SizedBox(width: 8),
                      Text(
                        tr('PROTECTION ANTI-SPAM & CONFORT', 'NO SPAM, EVER'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSwitchTile(
                  icon: Icons.nightlight_round,
                  iconColor: Colors.indigo,
                  title: tr('Heures de silence (22h00 - 8h30)', 'Quiet hours (10 pm - 8:30 am)'),
                  subtitle: tr('Aucune sonnerie nocturne. Les rappels après dîner sont automatiquement décalés au lendemain matin 9h.', 'Nothing rings at night. After-dinner reminders move to 9 am the next morning.'),
                  value: prefs.quietHoursEnabled,
                  onChanged: (val) => notifier.updatePreference(quietHoursEnabled: val),
                ),
                const Divider(),

                _buildSwitchTile(
                  icon: Icons.layers_outlined,
                  iconColor: const Color(0xFF8B1E3F),
                  title: tr('Regroupement des dégustations', 'Grouped tastings'),
                  subtitle: tr('Si vous débouchez plusieurs bouteilles en soirée, regroupe le rappel en une seule notification.', 'If you open several bottles in one evening, you get a single reminder.'),
                  value: prefs.batchMultipleTastingsEnabled,
                  onChanged: (val) => notifier.updatePreference(batchMultipleTastingsEnabled: val),
                ),

                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('Plafond anti-saturation : Chatmelier bride les alertes proactives à 1 par jour maximum.', 'Cap: Chatmelier sends at most one proactive alert per day.'),
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Test Notification Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  onPressed: _sendTest,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: Text(tr('Envoyer une notification test', 'Send a test notification')),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF8B1E3F),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
