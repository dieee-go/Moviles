import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/notification_model.dart';
import 'fcm_token_service.dart';

/// Callback para mensajes recibidos cuando la app está en foreground
typedef OnMessageCallback = Future<void> Function(RemoteMessage message);

/// Callback para interacción con notificación
typedef OnMessageOpenedAppCallback = Future<void> Function(RemoteMessage message);

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late final FcmTokenService _fcmTokenService;

  OnMessageCallback? _onMessageCallback;
  OnMessageOpenedAppCallback? _onMessageOpenedAppCallback;

  final _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  /// Inicializa Firebase Messaging
  /// Debe llamarse después de que Firebase.initializeApp()
  Future<void> initialize({
    OnMessageCallback? onMessageCallback,
    OnMessageOpenedAppCallback? onMessageOpenedAppCallback,
  }) async {
    _onMessageCallback = onMessageCallback;
    _onMessageOpenedAppCallback = onMessageOpenedAppCallback;
    _fcmTokenService = FcmTokenService();

    // Solicitar permisos (importante para iOS 13+)
    await _requestPermissions();

    // Obtener y registrar el FCM token
    String? token = await getToken();
    if (kDebugMode) {
      developer.log('FCM Token: $token');
    }

    // Escuchar cambios de token
    _listenToTokenRefresh();

    // Configurar handlers para diferentes estados de la app
    _setupForegroundHandler();
    _setupBackgroundHandler();
    _setupTerminatedHandler();
  }

  /// Solicita permisos para notificaciones push
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      developer.log('Notification settings: $settings');
    }
  }

  /// Configura handler para mensajes cuando la app está en foreground
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        developer.log('Mensaje recibido en foreground: ${message.messageId}');
        developer.log('Title: ${message.notification?.title}');
        developer.log('Body: ${message.notification?.body}');
      }

      _messageStreamController.add(message);
      _onMessageCallback?.call(message);
    });
  }

  /// Configura handler para cuando el usuario abre la app desde una notificación
  void _setupTerminatedHandler() {
    // Este handler se ejecuta cuando la app fue terminada
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && _onMessageOpenedAppCallback != null) {
        if (kDebugMode) {
          developer.log('App abierta desde notificación: ${message.messageId}');
        }
        _onMessageOpenedAppCallback!(message);
      }
    });

    // Este handler se ejecuta cuando la app está en background y el usuario abre la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        developer.log(
            'Notificación abierta desde background: ${message.messageId}');
      }
      _messageStreamController.add(message);
      _onMessageOpenedAppCallback?.call(message);
    });
  }

  /// Configura un handler global para mensajes en background
  /// Debe ser una función top-level o static
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    if (kDebugMode) {
      developer.log('Manejando mensaje en background: ${message.messageId}');
    }
  }

  /// Configura el handler de background
  void _setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  /// Obtiene el token FCM actual
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token obtenido: $token');
      if (token != null) {
        // Guardar el token en Supabase
        await _saveTokenToSupabase(token);
      }
      return token;
    } catch (e) {
      debugPrint('❌ Error obteniendo token FCM: $e');
      return null;
    }
  }

  /// Escucha los cambios de token y los guarda automáticamente
  void _listenToTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Token renovado: $newToken');
      _saveTokenToSupabase(newToken);
    });
  }

  /// Guarda el token en Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No hay usuario autenticado, token NO guardado');
        return;
      }

      final platform = Platform.isAndroid ? 'android' : 'ios';

      debugPrint('💾 Guardando token para user: ${user.id}');

      await _fcmTokenService.upsertToken(
        userId: user.id,
        token: token,
        platform: platform,
      );

      debugPrint('✅ Token guardado en Supabase exitosamente');
    } catch (e, stack) {
      debugPrint('❌ Error guardando token en Supabase: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Refresca el token FCM
  Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      return await getToken(); // Esto ya guardará el nuevo token en Supabase
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error refrescando token FCM: $e');
      }
      return null;
    }
  }

  /// Sincroniza el token actual con Supabase (útil después de login)
  Future<void> syncToken() async {
    try {
      debugPrint('🔄 Sincronizando token con Supabase...');
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('🔑 Token obtenido: $token');
        await _saveTokenToSupabase(token);
      } else {
        debugPrint('⚠️ No se pudo obtener el token FCM');
      }
    } catch (e, stack) {
      debugPrint('❌ Error sincronizando token: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Elimina el token FCM (para logout)
  Future<void> deleteToken() async {
    try {
      // Primero obtener el token actual para eliminarlo de Supabase
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('fcm_tokens')
              .delete()
              .eq('user_id', user.id)
              .eq('token', token);
        }
      }
      // Luego eliminar del Firebase
      await _firebaseMessaging.deleteToken();
      if (kDebugMode) {
        developer.log('✅ Token eliminado');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error eliminando token: $e');
      }
    }
  }

  /// Suscribirse a un topic para recibir notificaciones de grupo
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        developer.log('Suscrito al topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error suscribiéndose al topic $topic: $e');
      }
    }
  }

  /// Desuscribirse de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        developer.log('Desuscrito del topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error desuscribiéndose del topic $topic: $e');
      }
    }
  }

  /// Suscribirse a topics dinámicamente basado en preferencias del usuario
  Future<void> manageSubscriptions(NotificationPreference prefs) async {
    try {
      // Recordatorios
      if (prefs.reminderNotifications) {
        await subscribeToTopic('event_reminders');
      } else {
        await unsubscribeFromTopic('event_reminders');
      }

      // Actualizaciones de eventos
      if (prefs.eventUpdateNotifications) {
        await subscribeToTopic('event_updates');
      } else {
        await unsubscribeFromTopic('event_updates');
      }

      // Alertas de organizador
      if (prefs.organizerNotifications) {
        await subscribeToTopic('organizer_alerts');
      } else {
        await unsubscribeFromTopic('organizer_alerts');
      }

      // Alertas de admin
      if (prefs.adminNotifications) {
        await subscribeToTopic('admin_alerts');
      } else {
        await unsubscribeFromTopic('admin_alerts');
      }

      if (kDebugMode) {
        developer.log('Suscripciones a topics actualizadas');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error actualizando suscripciones a topics: $e');
      }
    }
  }

  /// Convierte un RemoteMessage a PushNotification
  static PushNotification remoteMessageToNotification(RemoteMessage message) {
    final type = _parseNotificationType(message.data['type'] ?? 'other');
    final category =
        _parseNotificationCategory(message.data['category'] ?? 'general');

    return PushNotification(
      id: message.messageId ?? 'unknown',
      userId: message.data['user_id'] ?? 'unknown',
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: type,
      category: category,
      data: message.data,
      createdAt: DateTime.now(),
      relatedEntityId: message.data['entity_id'],
      relatedEntityType: message.data['entity_type'],
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'registrationConfirmation':
        return NotificationType.registrationConfirmation;
      case 'attendanceConfirmation':
        return NotificationType.attendanceConfirmation;
      case 'eventReminder':
        return NotificationType.eventReminder;
      case 'organizerNotification':
        return NotificationType.organizerNotification;
      case 'adminRequest':
        return NotificationType.adminRequest;
      default:
        return NotificationType.other;
    }
  }

  static NotificationCategory _parseNotificationCategory(String category) {
    switch (category) {
      case 'registrations':
        return NotificationCategory.registrations;
      case 'reminders':
        return NotificationCategory.reminders;
      case 'organizerAlerts':
        return NotificationCategory.organizerAlerts;
      case 'adminAlerts':
        return NotificationCategory.adminAlerts;
      default:
        return NotificationCategory.general;
    }
  }

  /// Limpia recursos
  void dispose() {
    _messageStreamController.close();
  }
}
