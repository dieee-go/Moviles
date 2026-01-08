import 'package:flutter/material.dart';

enum NotificationType {
  registrationConfirmation,
  attendanceConfirmation,
  eventReminder,
  organizerNotification,
  adminRequest,
  other,
}

enum NotificationCategory {
  registrations,
  reminders,
  organizerAlerts,
  adminAlerts,
  general,
}

class NotificationPreference {
  final String userId;
  final bool registrationNotifications;
  final bool eventUpdateNotifications;
  final bool reminderNotifications;
  final bool organizerNotifications;
  final bool adminNotifications;
  final int reminderMinutesBefore; // 15, 30, 60, 1440 (1 día)
  final Map<String, bool> categorizedReminders; // {"sports": false, "academic": true}
  final TimeOfDay silentHoursStart;
  final TimeOfDay silentHoursEnd;
  final DateTime updatedAt;
  final DateTime createdAt;

  NotificationPreference({
    required this.userId,
    this.registrationNotifications = true,
    this.eventUpdateNotifications = true,
    this.reminderNotifications = true,
    this.organizerNotifications = true,
    this.adminNotifications = true,
    this.reminderMinutesBefore = 60,
    Map<String, bool>? categorizedReminders,
    TimeOfDay? silentHoursStart,
    TimeOfDay? silentHoursEnd,
    DateTime? updatedAt,
    DateTime? createdAt,
  })  : categorizedReminders = categorizedReminders ?? {},
        silentHoursStart = silentHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
        silentHoursEnd = silentHoursEnd ?? const TimeOfDay(hour: 8, minute: 0),
        updatedAt = updatedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'registration_notifications': registrationNotifications,
        'event_update_notifications': eventUpdateNotifications,
        'event_reminder_notifications': reminderNotifications,
        'organizer_notifications': organizerNotifications,
        'admin_notifications': adminNotifications,
        'reminder_minutes_before': reminderMinutesBefore,
        'categorized_reminders': categorizedReminders,
        'silent_hours_start': '${silentHoursStart.hour.toString().padLeft(2, '0')}:${silentHoursStart.minute.toString().padLeft(2, '0')}',
        'silent_hours_end': '${silentHoursEnd.hour.toString().padLeft(2, '0')}:${silentHoursEnd.minute.toString().padLeft(2, '0')}',
        'updated_at': updatedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    // Parsear horarios silenciosos
    TimeOfDay parseTimeOfDay(String? timeStr, TimeOfDay defaultTime) {
      if (timeStr == null) return defaultTime;
      final parts = timeStr.split(':');
      if (parts.length != 2) return defaultTime;
      try {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {
        return defaultTime;
      }
    }

    // Parsear preferencias categorizadas
    Map<String, bool> parseCategorizedReminders(dynamic data) {
      if (data == null) return {};
      if (data is Map) {
        return Map<String, bool>.from(
          data.map((k, v) => MapEntry(k.toString(), v as bool? ?? true)),
        );
      }
      return {};
    }

    return NotificationPreference(
      userId: map['user_id'] ?? '',
      registrationNotifications: map['registration_notifications'] ?? true,
      eventUpdateNotifications: map['event_update_notifications'] ?? true,
      reminderNotifications: map['event_reminder_notifications'] ?? true,
      organizerNotifications: map['organizer_notifications'] ?? true,
      adminNotifications: map['admin_notifications'] ?? true,
      reminderMinutesBefore: map['reminder_minutes_before'] ?? 60,
      categorizedReminders: parseCategorizedReminders(map['categorized_reminders']),
      silentHoursStart: parseTimeOfDay(
        map['silent_hours_start'] as String?,
        const TimeOfDay(hour: 22, minute: 0),
      ),
      silentHoursEnd: parseTimeOfDay(
        map['silent_hours_end'] as String?,
        const TimeOfDay(hour: 8, minute: 0),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  NotificationPreference copyWith({
    String? userId,
    bool? registrationNotifications,
    bool? eventUpdateNotifications,
    bool? reminderNotifications,
    bool? organizerNotifications,
    bool? adminNotifications,
    int? reminderMinutesBefore,
    Map<String, bool>? categorizedReminders,
    TimeOfDay? silentHoursStart,
    TimeOfDay? silentHoursEnd,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) =>
      NotificationPreference(
        userId: userId ?? this.userId,
        registrationNotifications:
            registrationNotifications ?? this.registrationNotifications,
        eventUpdateNotifications:
            eventUpdateNotifications ?? this.eventUpdateNotifications,
        reminderNotifications:
            reminderNotifications ?? this.reminderNotifications,
        organizerNotifications:
            organizerNotifications ?? this.organizerNotifications,
        adminNotifications: adminNotifications ?? this.adminNotifications,
        reminderMinutesBefore:
            reminderMinutesBefore ?? this.reminderMinutesBefore,
        categorizedReminders:
            categorizedReminders ?? this.categorizedReminders,
        silentHoursStart: silentHoursStart ?? this.silentHoursStart,
        silentHoursEnd: silentHoursEnd ?? this.silentHoursEnd,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
      );
}

class PushNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationCategory category;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? relatedEntityId; // ID del evento, usuario, etc.
  final String? relatedEntityType; // "event", "user", etc.

  PushNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.category,
    this.data,
    DateTime? createdAt,
    this.readAt,
    this.relatedEntityId,
    this.relatedEntityType,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isRead => readAt != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.toString().split('.').last,
        'category': category.toString().split('.').last,
        'data': data,
        'created_at': createdAt.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
        'related_entity_id': relatedEntityId,
        'related_entity_type': relatedEntityType,
      };

  factory PushNotification.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] ?? 'other';
    final categoryString = map['category'] ?? 'general';

    return PushNotification(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseNotificationType(typeString),
      category: _parseNotificationCategory(categoryString),
      data: map['data'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      readAt:
          map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      relatedEntityId: map['related_entity_id'],
      relatedEntityType: map['related_entity_type'],
    );
  }

  PushNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationCategory? category,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
    String? relatedEntityId,
    String? relatedEntityType,
  }) =>
      PushNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        category: category ?? this.category,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
        readAt: readAt ?? this.readAt,
        relatedEntityId: relatedEntityId ?? this.relatedEntityId,
        relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      );
}

NotificationType _parseNotificationType(String type) {
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

NotificationCategory _parseNotificationCategory(String category) {
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
