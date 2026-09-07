import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_notification_service.dart';
import '../data/notification_preferences_service.dart';

/// Educational dialog displayed BEFORE the OS notification prompt.
/// Explains why permissions are requested to maximize opt-in rate.
class NotificationPrePermissionDialog extends ConsumerWidget {
  const NotificationPrePermissionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const NotificationPrePermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active, color: Color(0xFF8B1E3F), size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Restez informé au bon moment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chatmelier utilise des alertes bien ciblées pour prendre soin de votre cave sans jamais vous spammer :',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
            icon: Icons.wine_bar,
            color: const Color(0xFF8B1E3F),
            title: 'Rappels post-dégustation',
            subtitle: 'Noter vos impressions après le repas tant que le souvenir est frais.',
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            icon: Icons.hourglass_top,
            color: const Color(0xFFD4AF37),
            title: 'Alertes d\'apogée',
            subtitle: 'Ouvrir vos grands crus au sommet de leur maturité, sans les oublier.',
          ),
          const SizedBox(height: 12),
          _buildFeatureRow(
            icon: Icons.people_outline,
            color: const Color(0xFF10B981),
            title: 'Caves partagées & Amis',
            subtitle: 'Être prévenu quand un proche sort un flacon ou vous invite.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous pouvez désactiver chaque type d\'alerte à tout moment dans votre Profil.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(notificationPreferencesProvider.notifier).markPermissionPrompted();
            Navigator.of(context).pop(false);
          },
          child: const Text('Plus tard', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () async {
            await ref.read(notificationPreferencesProvider.notifier).markPermissionPrompted();
            final service = ref.read(localNotificationServiceProvider);
            final granted = await service.requestPermissions();
            if (context.mounted) {
              Navigator.of(context).pop(granted);
            }
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Activer les alertes', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.25),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
