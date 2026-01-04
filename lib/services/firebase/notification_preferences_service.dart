import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart';

class NotificationPreferencesService {
  static const String _prefsKey = 'notification_preferences_';

  /// Obtiene las preferencias de notificación del almacenamiento local
  static Future<NotificationPreference?> getPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefsKey$userId';

      final jsonString = prefs.getString(key);
      if (jsonString == null) {
        return null;
      }

      return NotificationPreference.fromMap(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  /// Guarda las preferencias de notificación en el almacenamiento local
  static Future<bool> savePreferences(
    String userId,
    NotificationPreference preferences,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefsKey$userId';

      await prefs.setString(key, jsonEncode(preferences.toMap()));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Elimina las preferencias de notificación
  static Future<bool> deletePreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefsKey$userId';
      return await prefs.remove(key);
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el FCM token guardado localmente
  static Future<String?> getFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      return null;
    }
  }

  /// Guarda el FCM token localmente
  static Future<bool> saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('fcm_token', token);
    } catch (e) {
      return false;
    }
  }
}
