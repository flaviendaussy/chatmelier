import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/friends/data/friends_repository.dart';
import '../../features/notifications/presentation/notifications_inbox_sheet.dart';

/// Universal AppBar action button displaying a Notification Bell with live badge counter.
/// Automatically polls for fresh requests & notifications every 15 seconds.
/// Clicking it opens the full NotificationsInboxSheet.
class NotificationBellButton extends ConsumerStatefulWidget {
  final Color? iconColor;

  const NotificationBellButton({
    super.key,
    this.iconColor,
  });

  @override
  ConsumerState<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends ConsumerState<NotificationBellButton> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Periodic polling every 15s to keep friend and cellar requests in sync
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        refreshFriendsAndNotifications(ref);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      tooltip: unreadCount > 0 ? 'Boîte de réception ($unreadCount en attente)' : 'Boîte de réception',
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        backgroundColor: const Color(0xFFD4AF37),
        textColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        label: Text('$unreadCount'),
        child: Icon(
          unreadCount > 0 ? Icons.notifications_active : Icons.notifications_outlined,
          color: unreadCount > 0 ? const Color(0xFFD4AF37) : (widget.iconColor ?? Theme.of(context).iconTheme.color),
          size: 24,
        ),
      ),
      onPressed: () => NotificationsInboxSheet.show(context),
    );
  }
}
