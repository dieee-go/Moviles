import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/skeletons.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? _event;
  bool _loading = true;
  bool _isRegistered = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadEventDetail();
  }

  Future<void> _loadEventDetail() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('events')
          .select(
            'id, name, description, image_url, event_datetime, location_id,'
            ' locations(name),'
            ' organizer:organizer_id(nombre, primer_apellido, segundo_apellido, email)'
          )
          .eq('id', widget.eventId)
          .single();

      final userId = supabase.auth.currentUser?.id;
      bool registered = false;
      String? role;
      if (userId != null) {
        final reg = await supabase
            .from('event_registrations')
            .select('user_id')
            .eq('event_id', widget.eventId)
            .eq('user_id', userId)
            .maybeSingle();
        registered = reg != null;

        // Obtener rol del usuario
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();
        role = profile?['role'] as String?;
        if (kDebugMode) {
          debugPrint('DEBUG: User role from database: $role');
        }
      }

      setState(() {
        _event = data;
        _isRegistered = registered;
        _userRole = role;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error: ${e.message}', isError: true);
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando evento', isError: true);
        setState(() => _loading = false);
      }
    }
  }

  String _formatDateTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${dt.day} de ${months[dt.month - 1]}, ${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String? _formatOrganizer(Map<String, dynamic>? data) {
    if (data == null) return null;
    final nombre = (data['nombre'] as String?)?.trim();
    final pa = (data['primer_apellido'] as String?)?.trim();
    final sa = (data['segundo_apellido'] as String?)?.trim();

    final parts = [nombre, pa, sa]
        .whereType<String>()
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');

    final email = (data['email'] as String?)?.trim();
    return email?.isNotEmpty == true ? email : null;
  }

  Future<void> _registerToEvent() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        context.showSnackBar('Debes iniciar sesión', isError: true);
      }
      return;
    }

    try {
      await supabase.from('event_registrations').insert({
        'event_id': widget.eventId,
        'user_id': userId,
        'registration_datetime': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        context.showSnackBar('Registro confirmado');
        _loadEventDetail();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error: ${e.message}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    if (_loading) {
      return _buildDetailSkeleton();
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Evento no encontrado')),
      );
    }

    final name = _event!['name'] as String? ?? 'Sin título';
    final imageUrl = _event!['image_url'] as String?;
    final description = _event!['description'] as String? ?? '';
    final dateTime = _formatDateTime(_event!['event_datetime'] as String?);
    final locationData = _event!['locations'];
    final location = locationData != null ? locationData['name'] as String? : 'Sin ubicación';
    final organizerData = _event!['organizer'] as Map<String, dynamic>?;
    final organizer = _formatOrganizer(organizerData);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen destacada
                if (imageUrl != null && imageUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 5 / 4,
                    child: GestureDetector(
                      onTap: () => _openImageViewer(imageUrl),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: scheme.skeletonBackground,
                                child: Icon(Icons.event, size: 60, color: scheme.secondaryText),
                              );
                            },
                          ),
                          // Gradiente oscuro en la parte superior para visibilidad de iconos
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.center,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  AspectRatio(
                    aspectRatio: 5 / 4,
                    child: Container(
                      color: scheme.skeletonBackground,
                      child: Icon(Icons.event, size: 60, color: scheme.secondaryText),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Contenedor combinado de Fecha y Ubicación
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.infoCardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.infoCardBorder),
                        ),
                        child: Column(
                          children: [
                            // Fecha y hora
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: scheme.iconContainerBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.calendar_today, color: scheme.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha y hora',
                                        style: TextStyle(fontSize: 12, color: scheme.secondaryText),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateTime,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: scheme.dividerColor, thickness: 1),
                            const SizedBox(height: 16),
                            // Ubicación
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: scheme.iconContainerBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.location_on, color: scheme.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ubicación',
                                        style: TextStyle(fontSize: 12, color: scheme.secondaryText),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        location ?? 'Sin ubicación',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sección "Acerca del evento"
                      const Text(
                        'Acerca del evento',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description.isEmpty ? 'No hay descripción disponible' : description,
                        style: TextStyle(fontSize: 15, color: scheme.secondaryText, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Sección "Organizador"
                      if (organizer != null) ...[
                        const Text(
                          'Organizador',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.infoCardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.infoCardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: scheme.iconContainerBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.person, color: scheme.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  organizer,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Botón Registrarse (grande y destacado)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _isRegistered
                            ? ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.check_circle),
                                label: const Text(
                                  'Ya estás registrado',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _registerToEvent,
                                icon: const Icon(Icons.check_circle),
                                label: const Text(
                                  'Registrarse',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                      ),

                      // Botón ver asistentes (solo para organizadores y admins)
                      if (_userRole == 'organizer' || _userRole == 'admin') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/attendees', arguments: widget.eventId);
                            },
                            icon: const Icon(Icons.people),
                            label: const Text(
                              'Ver asistentes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1976D2),
                              side: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botón de atrás flotante
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Hero(
              tag: 'event-image-viewer',
              child: Image.network(
                url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Scaffold _buildDetailSkeleton() {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 5 / 4,
              child: Skeletons.box(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Skeletons.box(width: 240, height: 26, radius: 10),
                  const SizedBox(height: 20),

                  // Card fecha / ubicación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.skeletonBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Skeletons.box(width: 44, height: 44, radius: 10),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Skeletons.box(width: 90, height: 12, radius: 6),
                                  const SizedBox(height: 6),
                                  Skeletons.box(width: 180, height: 16, radius: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Skeletons.box(height: 1, radius: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Skeletons.box(width: 44, height: 44, radius: 10),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Skeletons.box(width: 80, height: 12, radius: 6),
                                  const SizedBox(height: 6),
                                  Skeletons.box(width: 200, height: 16, radius: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Acerca del evento
                  Skeletons.box(width: 160, height: 18, radius: 8),
                  const SizedBox(height: 12),
                  Skeletons.box(height: 14, radius: 6),
                  const SizedBox(height: 8),
                  Skeletons.box(width: double.infinity, height: 14, radius: 6),
                  const SizedBox(height: 8),
                  Skeletons.box(width: 220, height: 14, radius: 6),
                  const SizedBox(height: 24),

                  // Organizador
                  Skeletons.box(width: 140, height: 18, radius: 8),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.skeletonBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Skeletons.box(width: 44, height: 44, radius: 10),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Skeletons.box(width: double.infinity, height: 16, radius: 8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botones
                  Skeletons.box(height: 52, radius: 12),
                  const SizedBox(height: 12),
                  Skeletons.box(height: 52, radius: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
