import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../main.dart';

class NotificationSupabaseService {
  /// Obtiene las preferencias de notificación del usuario desde Supabase
  static Future<NotificationPreference?> getPreferences(String userId) async {
    try {
      final data = await supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return NotificationPreference.fromMap(data);
    } on PostgrestException catch (e) {
      debugPrint('Error obteniendo preferencias: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return null;
    }
  }

  /// Guarda o actualiza las preferencias de notificación en Supabase
  static Future<bool> savePreferences(NotificationPreference preferences) async {
    try {
      await supabase
          .from('notification_preferences')
          .upsert(preferences.toMap());

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Error guardando preferencias: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return false;
    }
  }

  /// Actualiza un campo específico de las preferencias
  static Future<bool> updatePreference(
    String userId,
    String field,
    dynamic value,
  ) async {
    try {
      await supabase
          .from('notification_preferences')
          .update({field: value})
          .eq('user_id', userId);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Error actualizando $field: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return false;
    }
  }

  /// Obtiene bloques de notificaciones específicas para un evento
  static Future<bool> isEventNotificationBlocked(
    String userId,
    String eventId,
    String blockType, // 'all', 'reminders', 'updates'
  ) async {
    try {
      final data = await supabase
          .from('user_notification_blocks')
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('block_type', blockType)
          .maybeSingle();

      return data != null;
    } on PostgrestException catch (e) {
      debugPrint('Error verificando bloqueo: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return false;
    }
  }

  /// Bloquea notificaciones para un evento específico
  static Future<bool> blockEventNotifications(
    String userId,
    String eventId,
    String blockType, // 'all', 'reminders', 'updates'
  ) async {
    try {
      // Primero verificar si ya existe el bloqueo
      final existing = await supabase
          .from('user_notification_blocks')
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('block_type', blockType)
          .maybeSingle();

      // Si ya existe, no insertar de nuevo
      if (existing != null) {
        return true;
      }

      await supabase.from('user_notification_blocks').insert({
        'user_id': userId,
        'event_id': eventId,
        'block_type': blockType,
      });

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Error bloqueando evento: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return false;
    }
  }

  /// Desbloquea notificaciones para un evento específico
  static Future<bool> unblockEventNotifications(
    String userId,
    String eventId,
    String blockType, // 'all', 'reminders', 'updates'
  ) async {
    try {
      await supabase
          .from('user_notification_blocks')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('block_type', blockType);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Error desbloqueando evento: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return false;
    }
  }

  /// Obtiene todos los eventos bloqueados para un usuario
  static Future<List<Map<String, dynamic>>> getBlockedEvents(
    String userId,
  ) async {
    try {
      final data = await supabase
          .from('user_notification_blocks')
          .select()
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      debugPrint('Error obteniendo eventos bloqueados: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return [];
    }
  }

  /// Crea preferencias predeterminadas para un nuevo usuario
  static Future<bool> createDefaultPreferences(String userId) async {
    try {
      final defaultPrefs = NotificationPreference(userId: userId);
      return await savePreferences(defaultPrefs);
    } on PostgrestException catch (e) {
      debugPrint('Error creando preferencias predeterminadas: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return false;
    }
  }
}
