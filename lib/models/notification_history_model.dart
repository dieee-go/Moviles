import 'package:flutter/material.dart';

class NotificationHistoryItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'registration', 'event_update', 'reminder', 'organizer_alert', 'admin_request'
  final String? category;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.category,
    this.relatedEntityId,
    this.relatedEntityType,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationHistoryItem.fromMap(Map<String, dynamic> map) {
    return NotificationHistoryItem(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      category: map['category'] as String?,
      relatedEntityId: map['related_entity_id'] as String?,
      relatedEntityType: map['related_entity_type'] as String?,
      data: map['data'] as Map<String, dynamic>?,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'category': category,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'data': data,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  IconData get iconData {
    switch (type) {
      case 'registration':
        return Icons.how_to_reg_outlined;
      case 'event_update':
        return Icons.edit_outlined;
      case 'reminder':
        return Icons.schedule_outlined;
      case 'organizer_alert':
        return Icons.person_add_outlined;
      case 'admin_request':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'registration':
        return 'Registro';
      case 'event_update':
        return 'Actualización';
      case 'reminder':
        return 'Recordatorio';
      case 'organizer_alert':
        return 'Organizador';
      case 'admin_request':
        return 'Administrador';
      default:
        return 'Notificación';
    }
  }
}
