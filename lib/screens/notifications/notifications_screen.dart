import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_history_model.dart';
import '../../providers/notification_history_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(notificationHistoryListProvider);
    final historyNotifier = ref.read(notificationHistoryListProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final unreadCount = historyAsync.maybeWhen(
      data: (notifications) => notifications.where((n) => !n.isRead).length,
      orElse: () => 0,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: TextStyle(
            color: appBarColor, 
            fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarColor),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todo como leído',
              onPressed: () async {
                final success = await ref
                    .read(notificationHistoryActionsProvider.notifier)
                    .markAllAsRead();
                if (!context.mounted) return;
                if (success) {
                  await historyNotifier.refresh();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Error al marcar notificaciones como leídas')),
                  );
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => historyNotifier.refresh(),
        child: historyAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: scheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay notificaciones',
                      style: TextStyle(
                        fontSize: 18,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aquí aparecerán tus notificaciones',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200 &&
                    historyNotifier.hasMore) {
                  historyNotifier.loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount:
                    notifications.length + (historyNotifier.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final notif = notifications[index];
                  return _buildNotificationCard(context, notif, ref, scheme);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar notificaciones',
                  style: TextStyle(color: scheme.error, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(notificationHistoryListProvider);
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationHistoryItem notif,
    WidgetRef ref,
    ColorScheme scheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 90)
        : const Color(0x0D000000);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: notif.isRead
            ? Theme.of(context).cardColor
            : scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notif.isRead
              ? Colors.transparent
              : scheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isDark ? 14 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (!notif.isRead) {
            ref
                .read(notificationHistoryActionsProvider.notifier)
                .markAsRead(notif.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con icono, tipo y fecha
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      notif.iconData,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              notif.typeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            if (!notif.isRead)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(notif.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        ref
                            .read(notificationHistoryActionsProvider.notifier)
                            .deleteNotification(notif.id);
                      } else if (value == 'read') {
                        ref
                            .read(notificationHistoryActionsProvider.notifier)
                            .markAsRead(notif.id);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      if (!notif.isRead)
                        const PopupMenuItem(
                          value: 'read',
                          child: Row(
                            children: [
                              Icon(Icons.done, size: 18),
                              SizedBox(width: 8),
                              Text('Marcar como leída'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Título
              Text(
                notif.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // Cuerpo
              Text(
                notif.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      final y = date.year;
      return '$d/$m/$y';
    }
  }
}
