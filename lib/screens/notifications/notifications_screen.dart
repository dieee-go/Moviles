import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, String>> notifications = const [
    {
      "title": "Registro confirmado",
      "message": "Te has registrado en el Congreso de Ingeniería."
    },
    {
      "title": "Nuevo evento disponible",
      "message": "Se ha publicado la Feria de Emprendimiento."
    },
    {
      "title": "Recordatorio",
      "message": "El Torneo de Programación inicia mañana."
    },
    {
      "title": "Actualización de evento",
      "message": "El Festival Cultural cambió de lugar al Foro Principal."
    },
    {
      "title": "Invitación",
      "message": "Participa en el Hackathon Universitario este fin de semana."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notificaciones")),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.notifications),
              title: Text(notif["title"]!),
              subtitle: Text(notif["message"]!),
            ),
          );
        },
      ),
    );
  }
}