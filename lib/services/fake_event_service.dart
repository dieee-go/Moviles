import 'package:unieventos/services/fake_user_service.dart';

class FakeEventService {
  static final List<Map<String, dynamic>> _events = [
    {
      "id": 1,
      "title": "Congreso de Ingeniería",
      "description": "Charlas y talleres sobre innovación tecnológica.",
      "date": "2025-01-15",
      "location": "Auditorio Principal",
      "attendees": <String>[],
    },
    {
      "id": 2,
      "title": "Feria de Emprendimiento",
      "description": "Exposición de proyectos de estudiantes y empresas locales.",
      "date": "2025-02-10",
      "location": "Plaza Central",
      "attendees": <String>[],
    },
    {
      "id": 3,
      "title": "Torneo de Programación",
      "description": "Competencia de algoritmos y desarrollo de software.",
      "date": "2025-03-05",
      "location": "Laboratorio de Cómputo",
      "attendees": <String>[],
    },
    {
      "id": 4,
      "title": "Festival Cultural Universitario",
      "description": "Música, danza y teatro presentados por estudiantes.",
      "date": "2025-03-20",
      "location": "Foro Cultural",
      "attendees": <String>[],
    },
    {
      "id": 5,
      "title": "Hackathon Universitario",
      "description": "48 horas de innovación y desarrollo de apps.",
      "date": "2025-04-02",
      "location": "Sala de Innovación",
      "attendees": <String>[],
    },
    {
      "id": 6,
      "title": "Simposio de Ciencias Sociales",
      "description": "Debates y conferencias sobre temas actuales.",
      "date": "2025-04-15",
      "location": "Aula Magna",
      "attendees": <String>[],
    },
    {
      "id": 7,
      "title": "Exposición de Arte Estudiantil",
      "description": "Galería con obras de pintura y escultura.",
      "date": "2025-05-01",
      "location": "Sala de Exposiciones",
      "attendees": <String>[],
    },
    {
      "id": 8,
      "title": "Torneo Deportivo Interfacultades",
      "description": "Competencias de fútbol, básquetbol y voleibol.",
      "date": "2025-05-10",
      "location": "Cancha Principal",
      "attendees": <String>[],
    },
    {
      "id": 9,
      "title": "Semana de la Salud",
      "description": "Charlas y talleres sobre bienestar físico y mental.",
      "date": "2025-05-20",
      "location": "Centro de Salud Universitario",
      "attendees": <String>[],
    },
    {
      "id": 10,
      "title": "Concierto de Primavera",
      "description": "Presentación de la orquesta universitaria.",
      "date": "2025-06-01",
      "location": "Auditorio de Música",
      "attendees": <String>[],
    },
    {
      "id": 11,
      "title": "Foro de Medio Ambiente",
      "description": "Ponencias sobre sostenibilidad y energías renovables.",
      "date": "2025-06-15",
      "location": "Sala Verde",
      "attendees": <String>[],
    },
    {
      "id": 12,
      "title": "Feria del Libro Universitario",
      "description": "Exposición y venta de libros académicos y literarios.",
      "date": "2025-07-01",
      "location": "Biblioteca Central",
      "attendees": <String>[],
    },
    {
      "id": 13,
      "title": "Congreso de Medicina",
      "description": "Actualizaciones en investigación médica y clínica.",
      "date": "2025-07-20",
      "location": "Hospital Universitario",
      "attendees": <String>[],
    },
    {
      "id": 14,
      "title": "Festival de Cine Estudiantil",
      "description": "Proyección de cortometrajes realizados por alumnos.",
      "date": "2025-08-05",
      "location": "Cine Universitario",
      "attendees": <String>[],
    },
    {
      "id": 15,
      "title": "Simposio de Inteligencia Artificial",
      "description": "Conferencias sobre IA y aprendizaje automático.",
      "date": "2025-08-20",
      "location": "Laboratorio de IA",
      "attendees": <String>[],
    },
  ];

static void createEvent(String title, String description, String date, String location, {String? organizer, String? organizerEmail}) {
  final user = FakeUserService.getUser();
  _events.add({
    "id": _events.length + 1,
    "title": title,
    "description": description,
    "date": date,
    "location": location,
    "organizer": organizer ?? user?["name"] ?? "Organizador",
    "organizerEmail": organizerEmail ?? user?["email"] ?? "",
    "imageUrl": "https://picsum.photos/id/${_events.length + 10}/600/300",
    "attendees": <String>[],
    "startTime": "10:00",
    "endTime": "12:00",
  });
}

// Añade un método para obtener eventos por organizador
static List<Map<String, dynamic>> getEventsByOrganizer(String organizerEmail) {
  return _events.where((e) => e["organizerEmail"] == organizerEmail).toList();
}

  static Map<String, dynamic> getEvent(int id) =>
    _events.firstWhere((e) => e["id"] == id, orElse: () => {});

  /*static void editEvent(int id, String title, String description, {required String location, required String organizer, required String imageUrl, required String date, required String startTime, required String endTime}) {
    final event = _events.firstWhere((e) => e["id"] == id);
    event["title"] = title;
    event["description"] = description;
    event["location"] = location;
    event["organizer"] = organizer;
    event["imageUrl"] = imageUrl;
    event["date"] = date;
    event["startTime"] = startTime;
    event["endTime"] = endTime;
  }
*/

  static void editEvent(
      int id,
      String title,
      String description, {
        String? location,
        String? date,
        String? organizer,
        String? imageUrl,
        String? startTime,
        String? endTime,
      }) {
    final event = _events.indexWhere((e) => e["id"] == id);
    if (event != -1) return;
    final e = _events[event];
    e["title"] = title;
    e["description"] = description;
    if (location != null) e["location"] = location;
    if (date != null) e["date"] = date;
    if (organizer != null) e["organizer"] = organizer;
    if (imageUrl != null) e["imageUrl"] = imageUrl;
    if (startTime != null) e["startTime"] = startTime;
    if (endTime != null) e["endTime"] = endTime;
      }

  static void deleteEvent(int id) {
    _events.removeWhere((e) => e["id"] == id);
  }

  static void registerAttendee(int id, String email) {
    final event = _events.firstWhere((e) => e["id"] == id);
    event["attendees"].add(email);
  }

  static List<Map<String, dynamic>> getEvents() => _events;

  static List<String> getAttendees(int id) {
    final event = _events.firstWhere((e) => e["id"] == id);
    return List<String>.from(event["attendees"]);
  }

  static Map<String, dynamic>? getEventById(int eventId) {
    try {
      return _events.firstWhere((e) => e['id'] == eventId);
    } catch (_) {
      return null;
    }
  }
}