import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../providers/notification_preferences_provider.dart';

class NotificationPreferencesWidget extends ConsumerWidget {
  final String userId;

  const NotificationPreferencesWidget({
    required this.userId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return preferencesAsync.when(
      data: (preferences) {
        if (preferences == null) {
          return const Center(child: Text('No preferences found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preferencias de Notificaciones',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildToggleTile(
                ref,
                context,
                'Confirmación de Registros',
                'Notificaciones cuando confirmas tu asistencia',
                preferences.registrationNotifications,
                () => ref
                    .read(userNotificationPreferencesProvider.notifier)
                    .togglePreference('registration'),
              ),
              const Divider(),
              _buildToggleTile(
                ref,
                context,
                'Cambios en Eventos',
                'Notificaciones cuando hay cambios en eventos registrados',
                preferences.eventUpdateNotifications,
                () => ref
                    .read(userNotificationPreferencesProvider.notifier)
                    .togglePreference('event_update'),
              ),
              const Divider(),
              _buildToggleTile(
                ref,
                context,
                'Recordatorios de Eventos',
                'Recordatorios antes de eventos que se avecinan',
                preferences.reminderNotifications,
                () => ref
                    .read(userNotificationPreferencesProvider.notifier)
                    .togglePreference('reminder'),
              ),
              if (preferences.reminderNotifications)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildReminderTimePicker(ref, preferences),
                ),
              const Divider(),
              _buildToggleTile(
                ref,
                context,
                'Alertas de Organizador',
                'Notificaciones cuando alguien se registra en tus eventos',
                preferences.organizerNotifications,
                () => ref
                    .read(userNotificationPreferencesProvider.notifier)
                    .togglePreference('organizer'),
              ),
              const Divider(),
              _buildToggleTile(
                ref,
                context,
                'Solicitudes de Administrador',
                'Notificaciones de solicitudes de rol de organizador',
                preferences.adminNotifications,
                () => ref
                    .read(userNotificationPreferencesProvider.notifier)
                    .togglePreference('admin'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showSaveSuccess(context),
                  child: const Text('Guardar Preferencias'),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error cargando preferencias: $error'),
      ),
    );
  }

  Widget _buildToggleTile(
    WidgetRef ref,
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    VoidCallback onToggle,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: (_) => onToggle(),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildReminderTimePicker(
    WidgetRef ref,
    NotificationPreference preferences,
  ) {
    final options = [15, 30, 60, 1440];
    final labels = ['15 minutos', '30 minutos', '1 hora', '1 día'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recordar',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(
              options.length,
              (index) => ChoiceChip(
                label: Text(labels[index]),
                selected: preferences.reminderMinutesBefore == options[index],
                onSelected: (_) {
                  ref
                      .read(userNotificationPreferencesProvider.notifier)
                      .updateReminderTime(options[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferencias guardadas exitosamente'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
