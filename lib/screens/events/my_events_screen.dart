import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/skeletons.dart';
import '../../main.dart';
import '../../utils/translations.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  List<Map<String, dynamic>> _myEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyEvents();
  }

  Future<void> _loadMyEvents() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }

      // Primero actualizar eventos que ya han pasado
      await _updateFinishedEvents(userId);

      final data = await supabase
          .from('events')
          .select('id, name, event_datetime, status, locations(name)')
          .eq('organizer_id', userId)
          .order('event_datetime', ascending: false);

      setState(() {
        _myEvents = List<Map<String, dynamic>>.from(data);
      });
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar('Error: ${e.message}', isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateFinishedEvents(String userId) async {
    try {
      final now = DateTime.now().toUtc();

      // Obtener todos los eventos activos del usuario
      final activeEvents = await supabase
          .from('events')
          .select('id, event_datetime')
          .eq('organizer_id', userId)
          .eq('status', 'active');

      // Verificar cuáles han pasado y actualizar
      for (final event in activeEvents) {
        final eventDateTime = event['event_datetime'] as String?;
        if (eventDateTime == null) continue;

        final eventTime = DateTime.parse(eventDateTime).toLocal();
        if (eventTime.isBefore(now)) {
          // El evento ya pasó, actualizar a 'done'
          await supabase
              .from('events')
              .update({'status': 'done'})
              .eq('id', event['id']);
        }
      }
    } catch (e) {
      // Silenciar errores de actualización para no interrumpir la carga
      if (mounted) {
        // Opcionalmente log el error
      }
    }
  }

  Map<String, dynamic> _getStatusStyle(String? status) {
    final statusLower = status?.toLowerCase() ?? 'active';
    switch (statusLower) {
      case 'active':
        return {
          'color': Colors.blue[100],
          'iconColor': Colors.blue,
          'icon': Icons.schedule,
        };
      case 'done':
        return {
          'color': Colors.green[100],
          'iconColor': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'cancelled':
        return {
          'color': Colors.red[100],
          'iconColor': Colors.red,
          'icon': Icons.cancel,
        };
      default:
        return {
          'color': Colors.blue[100],
          'iconColor': Colors.blue,
          'icon': Icons.schedule,
        };
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _showDeleteDialog(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Eliminar "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('events').delete().eq('id', id);
      if (mounted) context.showSnackBar('Evento eliminado');
      await _loadMyEvents();
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar('Error: ${e.message}', isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('No se pudo eliminar', isError: true);
    }
  }

  Widget _buildSkeletonList() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Skeletons.listTiles(count: 5, leadingSize: 64),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Eventos'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.pushNamed(context, '/create-event');
              _loadMyEvents();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyEvents,
        child: _loading
            ? _buildSkeletonList()
            : _myEvents.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy, size: 80, color: Colors.grey),
                          const SizedBox(height: 20),
                          const Text(
                            'No has creado eventos',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.pushNamed(context, '/create-event');
                              _loadMyEvents();
                            },
                            child: const Text('Crear mi primer evento'),
                          ),
                        ],
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _myEvents.length,
                    itemBuilder: (context, index) {
                      final event = _myEvents[index];
                      final eventId = event['id'] as String;
                      final name = event['name'] as String? ?? 'Sin título';
                      final dateTime = event['event_datetime'] as String?;
                      final statusStr = event['status'] as String? ?? 'active';
                      final locationData = event['locations'];
                      final location = locationData != null ? locationData['name'] as String? : null;
                      final statusStyle = _getStatusStyle(statusStr);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/event-detail',
                              arguments: eventId,
                            );
                          },
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: statusStyle['color'] as Color?,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              statusStyle['icon'] as IconData?,
                              color: statusStyle['iconColor'] as Color?,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(dateTime),
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (location != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                translateEventStatus(statusStr),
                                style: TextStyle(
                                  color: statusStyle['iconColor'] as Color?,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.pushNamed(
                                  context,
                                  '/edit-event',
                                  arguments: eventId,
                                );
                              } else if (value == 'delete') {
                                _showDeleteDialog(eventId, name);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
