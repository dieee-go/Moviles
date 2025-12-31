import 'package:flutter/material.dart';
import '../../pages/create_event_page.dart';

// Esta pantalla redirige a CreateEventPage que ya funciona con Supabase
class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateEventPage();
  }
}