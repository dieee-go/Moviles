import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/notification_model.dart';
import '../services/firebase/firebase_messaging_service.dart';

part 'notification_providers.g.dart';

/// Provider para el servicio de Firebase Messaging (singleton)
@riverpod
FirebaseMessagingService firebaseMessagingService(Ref ref) {
  return FirebaseMessagingService();
}

/// Provider para el FCM token del usuario
@riverpod
Future<String?> fcmToken(Ref ref) async {
  final service = ref.watch(firebaseMessagingServiceProvider);
  return service.getToken();
}

/// Notifier para gestionar preferencias de notificaciones del usuario (DEPRECADO - usar notification_preferences_provider)
@riverpod
class NotificationPreferencesLegacy extends _$NotificationPreferencesLegacy {
  @override
  NotificationPreference? build() => null;

  /// Actualiza las preferencias de notificación
  void updatePreferences(NotificationPreference preferences) {
    state = preferences;
  }

  /// Alterna una preferencia específica
  void togglePreference(String preferenceKey) {
    if (state == null) return;

    final updated = switch (preferenceKey) {
      'registrations' =>
        state!.copyWith(registrationNotifications: !state!.registrationNotifications),
      'event_update' =>
        state!.copyWith(eventUpdateNotifications: !state!.eventUpdateNotifications),
      'reminders' =>
        state!.copyWith(reminderNotifications: !state!.reminderNotifications),
      'organizer' =>
        state!.copyWith(organizerNotifications: !state!.organizerNotifications),
      'admin' =>
        state!.copyWith(adminNotifications: !state!.adminNotifications),
      _ => state,
    };

    state = updated;
  }

  /// Actualiza el tiempo de recordatorio
  void setReminderTime(int minutes) {
    if (state == null) return;
    state = state!.copyWith(reminderMinutesBefore: minutes);
  }
}

/// Notifier para gestionar el historial de notificaciones
@riverpod
class NotificationsHistory extends _$NotificationsHistory {
  @override
  List<PushNotification> build() => [];

  /// Agrega una nueva notificación al historial
  void addNotification(PushNotification notification) {
    state = [notification, ...state];
  }

  /// Marca una notificación como leída
  void markAsRead(String notificationId) {
    state = [
      for (final notif in state)
        if (notif.id == notificationId)
          notif.copyWith(readAt: DateTime.now())
        else
          notif,
    ];
  }

  /// Marca todas las notificaciones como leídas
  void markAllAsRead() {
    final now = DateTime.now();
    state = [
      for (final notif in state)
        if (notif.readAt == null) notif.copyWith(readAt: now) else notif,
    ];
  }

  /// Elimina una notificación del historial
  void removeNotification(String notificationId) {
    state = state.where((notif) => notif.id != notificationId).toList();
  }

  /// Limpia todo el historial
  void clearHistory() {
    state = [];
  }

  /// Obtiene solo las notificaciones no leídas
  List<PushNotification> get unreadNotifications =>
      state.where((notif) => !notif.isRead).toList();

  /// Obtiene el conteo de notificaciones no leídas
  int get unreadCount => unreadNotifications.length;
}

/// Provider para obtener el conteo de notificaciones no leídas
@riverpod
int unreadNotificationCount(Ref ref) {
  final notifications = ref.watch(notificationsHistoryProvider);
  return notifications.where((notif) => !notif.isRead).length;
}

/// Provider para obtener notificaciones por categoría
@riverpod
List<PushNotification> notificationsByCategory(
  Ref ref,
  NotificationCategory category,
) {
  final notifications = ref.watch(notificationsHistoryProvider);
  return notifications.where((notif) => notif.category == category).toList();
}

/// Provider para obtener notificaciones no leídas
@riverpod
List<PushNotification> unreadNotifications(Ref ref) {
  final notifications = ref.watch(notificationsHistoryProvider);
  return notifications.where((notif) => !notif.isRead).toList();
}
