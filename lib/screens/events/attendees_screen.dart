import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/skeletons.dart';
import '../../main.dart';

class AttendeesScreen extends StatefulWidget {
  final String eventId;

  const AttendeesScreen({super.key, required this.eventId});

  @override
  State<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  List<Map<String, dynamic>> _attendees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendees();
  }

  Future<void> _loadAttendees() async {
    setState(() => _loading = true);
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: Loading attendees for event ${widget.eventId}');
      }
      final data = await supabase
          .from('event_registrations')
          .select('user_id, profiles(nombre, primer_apellido, segundo_apellido, email)')
          .eq('event_id', widget.eventId);
      
      if (kDebugMode) {
        debugPrint('DEBUG: Attendees data received: ${data.length} records');
        debugPrint('DEBUG: Raw data: $data');
      }

      setState(() {
        _attendees = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error: ${e.message}', isError: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando asistentes', isError: true);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingSkeleton();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Asistentes (${_attendees.length})')),
      body: _attendees.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Aún no hay asistentes registrados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _attendees.length,
              itemBuilder: (context, index) {
                final attendee = _attendees[index];
                final profileData = attendee['profiles'] as Map<String, dynamic>?;
                final nombre = (profileData?['nombre'] as String?)?.trim() ?? '';
                final pa = (profileData?['primer_apellido'] as String?)?.trim() ?? '';
                final sa = (profileData?['segundo_apellido'] as String?)?.trim() ?? '';
                final name = [nombre, pa, sa]
                    .where((s) => s.isNotEmpty)
                    .join(' ')
                    .trim();
                final displayName = name.isNotEmpty ? name : 'Sin nombre';
                final email = profileData?['email'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1976D2),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(displayName),
                    subtitle: Text(email),
                  ),
                );
              },
            ),
    );
  }

  Scaffold _buildLoadingSkeleton() {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistentes')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Skeletons.listTiles(count: 6, leadingSize: 48),
        ),
      ),
    );
  }
}