import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/skeletons.dart';
import '../../main.dart';

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

      final data = await supabase
          .from('events')
          .select('id, name, event_datetime, locations(name)')
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

  bool _isEventActive(String? dateStr) {
    if (dateStr == null) return false;
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return false;
    return dt.isAfter(DateTime.now());
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
                      final isActive = _isEventActive(dateTime);
                      final locationData = event['locations'];
                      final location = locationData != null ? locationData['name'] as String? : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isActive ? Icons.check_circle : Icons.cancel,
                              color: isActive ? Colors.green : Colors.red,
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
                                isActive ? 'Activo' : 'Finalizado',
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.red,
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
