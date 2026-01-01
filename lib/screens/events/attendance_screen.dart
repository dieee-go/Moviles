import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/skeletons.dart';
import '../../main.dart';

class AttendanceScreen extends StatefulWidget {
  final String eventId;

  const AttendanceScreen({super.key, required this.eventId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _allAttendees = [];
  List<Map<String, dynamic>> _checkedInAttendees = [];
  bool _loading = true;
  late TabController _tabController;
  bool _generatingQr = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAttendees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendees() async {
    setState(() => _loading = true);
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: Loading attendees for event ${widget.eventId}');
      }
      final data = await supabase
          .from('event_registrations')
          .select('user_id, checked_in_at, profiles(nombre, primer_apellido, segundo_apellido, email)')
          .eq('event_id', widget.eventId);
      
      if (kDebugMode) {
        debugPrint('DEBUG: Attendees data received: ${data.length} records');
      }

      final allAttendees = List<Map<String, dynamic>>.from(data);
      final checkedIn = allAttendees
          .where((a) => a['checked_in_at'] != null)
          .toList();

      setState(() {
        _allAttendees = allAttendees;
        _checkedInAttendees = checkedIn;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error: ${e.message}', isError: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando asistencia', isError: true);
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateQr() async {
    setState(() => _generatingQr = true);
    try {
      // Generar datos del QR: evento_id|timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final qrData = '${widget.eventId}|$timestamp';

      if (!mounted) return;

      // Mostrar diálogo con el QR
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Código QR del Evento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Los estudiantes pueden escanear este QR para registrar su asistencia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error generando QR: $e', isError: true);
      }
    } finally {
      setState(() => _generatingQr = false);
    }
  }

  Widget _buildAttendeeList(List<Map<String, dynamic>> attendees) {
    if (attendees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay registros aquí',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final attendee = attendees[index];
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
        final isCheckedIn = attendee['checked_in_at'] != null;

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
            trailing: isCheckedIn
                ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingSkeleton();
    }

    final registeredCount = _allAttendees.length;
    final checkedInCount = _checkedInAttendees.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _generatingQr
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.qr_code_2),
                      onPressed: _generateQr,
                      tooltip: 'Generar QR',
                    ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Registrados ($registeredCount)',
              icon: const Icon(Icons.person_add),
            ),
            Tab(
              text: 'Asistieron ($checkedInCount)',
              icon: const Icon(Icons.check_circle),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendeeList(_allAttendees),
          _buildAttendeeList(_checkedInAttendees),
        ],
      ),
    );
  }

  Scaffold _buildLoadingSkeleton() {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
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
