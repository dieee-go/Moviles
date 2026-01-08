import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_supabase_service.dart';
import '../services/firebase/firebase_messaging_service.dart';
import 'auth_providers.dart';

part 'notification_preferences_provider.g.dart';

/// Provider para obtener las preferencias de notificación del usuario actual
@riverpod
Future<NotificationPreference?> notificationPreferences(Ref ref) async {
  // Intentar obtener el usuario desde el provider generado
  var user = ref.watch(currentUserProvider);

  // Si aún no hay usuario, esperar al primer estado de authSession
  if (user == null) {
    final authState = await ref.watch(authSessionProvider.future);
    user = authState.session?.user;
    if (user == null) return null;
  }

  // Intentar leer preferencias desde Supabase
  final prefs = await NotificationSupabaseService.getPreferences(user.id);
  if (prefs != null) return prefs;

  // Si no existen, crear preferencias por defecto y devolver una instancia
  await NotificationSupabaseService.createDefaultPreferences(user.id);
  return NotificationPreference(userId: user.id);
}

/// Notifier para actualizar preferencias de notificación
@riverpod
class UserNotificationPreferences extends _$UserNotificationPreferences {
  @override
  Future<NotificationPreference?> build() async {
    return ref.watch(notificationPreferencesProvider.future);
  }

  /// Actualiza una preferencia booleana
  Future<bool> togglePreference(String fieldName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final currentPrefs = state.value;
    if (currentPrefs == null) return false;

    // Crear las preferencias actualizadas
    final updated = switch (fieldName) {
      'registration' => currentPrefs.copyWith(
          registrationNotifications: !currentPrefs.registrationNotifications,
        ),
      'event_update' => currentPrefs.copyWith(
          eventUpdateNotifications: !currentPrefs.eventUpdateNotifications,
        ),
      'reminder' => currentPrefs.copyWith(
          reminderNotifications: !currentPrefs.reminderNotifications,
        ),
      'organizer' => currentPrefs.copyWith(
          organizerNotifications: !currentPrefs.organizerNotifications,
        ),
      'admin' => currentPrefs.copyWith(
          adminNotifications: !currentPrefs.adminNotifications,
        ),
      _ => currentPrefs,
    };

    // Guardar en Supabase
    final success = await NotificationSupabaseService.savePreferences(updated);
    if (success) {
      state = AsyncValue.data(updated);
      // Actualizar suscripciones a topics de FCM
      await FirebaseMessagingService().manageSubscriptions(updated);
      return true;
    }
    return false;
  }

  /// Actualiza el tiempo antes del recordatorio (en minutos)
  Future<bool> updateReminderTime(int minutes) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final currentPrefs = state.value;
    if (currentPrefs == null) return false;

    final updated = currentPrefs.copyWith(reminderMinutesBefore: minutes);
    final success = await NotificationSupabaseService.savePreferences(updated);

    if (success) {
      state = AsyncValue.data(updated);
      // Actualizar suscripciones a topics de FCM
      await FirebaseMessagingService().manageSubscriptions(updated);
      return true;
    }
    return false;
  }

  /// Actualiza horarios silenciosos
  Future<bool> updateSilentHours(
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final currentPrefs = state.value;
    if (currentPrefs == null) return false;

    final updated = currentPrefs.copyWith(
      silentHoursStart: startTime ?? currentPrefs.silentHoursStart,
      silentHoursEnd: endTime ?? currentPrefs.silentHoursEnd,
    );

    final success = await NotificationSupabaseService.savePreferences(updated);
    if (success) {
      state = AsyncValue.data(updated);
      // Actualizar suscripciones a topics de FCM
      await FirebaseMessagingService().manageSubscriptions(updated);
      return true;
    }
    return false;
  }

  /// Actualiza preferencias categorizadas
  Future<bool> updateCategorizedReminders(
    Map<String, bool> categories,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final currentPrefs = state.value;
    if (currentPrefs == null) return false;

    final updated = currentPrefs.copyWith(categorizedReminders: categories);
    final success = await NotificationSupabaseService.savePreferences(updated);

    if (success) {
      state = AsyncValue.data(updated);
      // Actualizar suscripciones a topics de FCM
      await FirebaseMessagingService().manageSubscriptions(updated);
      return true;
    }
    return false;
  }

  /// Bloquea notificaciones para un evento específico
  Future<bool> blockEvent(String eventId, String blockType) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    return NotificationSupabaseService.blockEventNotifications(
      user.id,
      eventId,
      blockType,
    );
  }

  /// Desbloquea notificaciones para un evento específico
  Future<bool> unblockEvent(String eventId, String blockType) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    return NotificationSupabaseService.unblockEventNotifications(
      user.id,
      eventId,
      blockType,
    );
  }
}
