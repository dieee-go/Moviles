import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';
import '../providers/notification_providers.dart';

class NotificationsHistoryWidget extends ConsumerWidget {
  const NotificationsHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsHistoryProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todas como leídas',
              onPressed: () {
                ref
                    .read(notificationsHistoryProvider.notifier)
                    .markAllAsRead();
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay notificaciones',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(
                  context,
                  ref,
                  notification,
                );
              },
            ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    PushNotification notification,
  ) {
    return Dismissible(
      key: Key(notification.id),
      onDismissed: (_) {
        ref
            .read(notificationsHistoryProvider.notifier)
            .removeNotification(notification.id);
      },
      child: Container(
        color: notification.isRead ? Colors.transparent : Colors.blue[50],
        child: ListTile(
          leading: _buildNotificationIcon(notification.type),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.body),
              const SizedBox(height: 4),
              Text(
                _formatDate(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
          onTap: () {
            if (!notification.isRead) {
              ref
                  .read(notificationsHistoryProvider.notifier)
                  .markAsRead(notification.id);
            }
            _showNotificationDetail(context, notification);
          },
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getIconColor(type).withValues(alpha: 0.2),
      ),
      child: Icon(
        _getIconData(type),
        color: _getIconColor(type),
      ),
    );
  }

  IconData _getIconData(NotificationType type) {
    return switch (type) {
      NotificationType.registrationConfirmation => Icons.check_circle,
      NotificationType.attendanceConfirmation => Icons.verified,
      NotificationType.eventReminder => Icons.schedule,
      NotificationType.organizerNotification => Icons.people,
      NotificationType.adminRequest => Icons.admin_panel_settings,
      NotificationType.other => Icons.notifications,
    };
  }

  Color _getIconColor(NotificationType type) {
    return switch (type) {
      NotificationType.registrationConfirmation => Colors.green,
      NotificationType.attendanceConfirmation => Colors.blue,
      NotificationType.eventReminder => Colors.orange,
      NotificationType.organizerNotification => Colors.purple,
      NotificationType.adminRequest => Colors.red,
      NotificationType.other => Colors.grey,
    };
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Justo ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  void _showNotificationDetail(
    BuildContext context,
    PushNotification notification,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(notification.body),
            const SizedBox(height: 12),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (notification.data?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              const Text(
                'Información adicional:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...notification.data!.entries.map(
                (e) => Text('${e.key}: ${e.value}'),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
