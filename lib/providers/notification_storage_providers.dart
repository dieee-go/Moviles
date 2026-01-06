import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../services/firebase/notification_preferences_service.dart';

/// Provider para cargar las preferencias de notificación del usuario desde storage
final notificationPreferencesLoaderProvider =
    FutureProvider.family<NotificationPreference?, String>(
  (ref, userId) async {
    // Intenta cargar del almacenamiento local primero
    final cached = await NotificationPreferencesService.getPreferences(userId);
    
    // Si no existe, crea una nueva con valores por defecto
    return cached ??
        NotificationPreference(
          userId: userId,
          registrationNotifications: true,
          eventUpdateNotifications: true,
          reminderNotifications: true,
          organizerNotifications: true,
          adminNotifications: true,
          reminderMinutesBefore: 60,
        );
  },
);

/// Provider para cargar el FCM token guardado
final fcmTokenStorageProvider = FutureProvider<String?>((ref) async {
  return NotificationPreferencesService.getFCMToken();
});
