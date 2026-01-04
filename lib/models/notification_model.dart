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
  final bool attendanceNotifications;
  final bool reminderNotifications;
  final bool organizerNotifications;
  final bool adminNotifications;
  final int reminderMinutesBefore; // 15, 30, 60, 1440 (1 día)
  final DateTime updatedAt;

  NotificationPreference({
    required this.userId,
    this.registrationNotifications = true,
    this.attendanceNotifications = true,
    this.reminderNotifications = true,
    this.organizerNotifications = true,
    this.adminNotifications = true,
    this.reminderMinutesBefore = 60,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'registration_notifications': registrationNotifications,
        'attendance_notifications': attendanceNotifications,
        'reminder_notifications': reminderNotifications,
        'organizer_notifications': organizerNotifications,
        'admin_notifications': adminNotifications,
        'reminder_minutes_before': reminderMinutesBefore,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory NotificationPreference.fromMap(Map<String, dynamic> map) =>
      NotificationPreference(
        userId: map['user_id'] ?? '',
        registrationNotifications: map['registration_notifications'] ?? true,
        attendanceNotifications: map['attendance_notifications'] ?? true,
        reminderNotifications: map['reminder_notifications'] ?? true,
        organizerNotifications: map['organizer_notifications'] ?? true,
        adminNotifications: map['admin_notifications'] ?? true,
        reminderMinutesBefore: map['reminder_minutes_before'] ?? 60,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : DateTime.now(),
      );

  NotificationPreference copyWith({
    String? userId,
    bool? registrationNotifications,
    bool? attendanceNotifications,
    bool? reminderNotifications,
    bool? organizerNotifications,
    bool? adminNotifications,
    int? reminderMinutesBefore,
    DateTime? updatedAt,
  }) =>
      NotificationPreference(
        userId: userId ?? this.userId,
        registrationNotifications:
            registrationNotifications ?? this.registrationNotifications,
        attendanceNotifications:
            attendanceNotifications ?? this.attendanceNotifications,
        reminderNotifications:
            reminderNotifications ?? this.reminderNotifications,
        organizerNotifications:
            organizerNotifications ?? this.organizerNotifications,
        adminNotifications: adminNotifications ?? this.adminNotifications,
        reminderMinutesBefore:
            reminderMinutesBefore ?? this.reminderMinutesBefore,
        updatedAt: updatedAt ?? this.updatedAt,
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
