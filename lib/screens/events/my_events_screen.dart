import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/skeletons.dart';
import '../../main.dart';
import '../../utils/translations.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  // ignore: library_private_types_in_public_api
  static final GlobalKey<_MyEventsScreenState> globalKey = GlobalKey();

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _myEvents = [];
  bool _loading = true;
  final ValueNotifier<String> _filterNotifier = ValueNotifier('all'); // all | active | done | cancelled
  final ValueNotifier<String> _sortNotifier = ValueNotifier('date_asc'); // date_asc | date_desc | name_asc | name_desc

  void reloadEvents() {
    _loadMyEvents();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMyEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _filterNotifier.dispose();
    _sortNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Removido: no actualizar automáticamente cuando se entra a la app
    // if (state == AppLifecycleState.resumed) {
    //   _loadMyEvents();
    // }
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
          .select('id, name, event_date, event_time, status, locations(name)')
          .eq('organizer_id', userId)
          .order('event_date', ascending: false)
          .order('event_time', ascending: false);

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
          .select('id, event_date, event_time')
          .eq('organizer_id', userId)
          .eq('status', 'active');

      // Verificar cuáles han pasado y actualizar
      for (final event in activeEvents) {
        final eventDateStr = event['event_date'] as String?;
        final eventTimeStr = event['event_time'] as String?;
        if (eventDateStr == null || eventTimeStr == null) continue;

        try {
          final eventDate = DateTime.parse(eventDateStr);
          final timeParts = eventTimeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final eventTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour, minute);
          
          if (eventTime.isBefore(now)) {
            // El evento ya pasó, actualizar a 'done'
            await supabase
                .from('events')
                .update({'status': 'done'})
                .eq('id', event['id']);
          }
        } catch (_) {
          // Ignorar errores de parsing
          continue;
        }
      }
    } catch (e) {
      // Silenciar errores de actualización para no interrumpir la carga
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

  String _formatDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return '';
    try {
      final parts = timeStr.split(':');
      final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final date = DateTime.parse(dateStr).toLocal();
      final dt = DateTime(date.year, date.month, date.day, hour, minute);
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      final datePart = '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
      final hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final timePart = '${hour12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
      return '$datePart · $timePart';
    } catch (_) {
      return '';
    }
  }

  List<Map<String, dynamic>> _applySortAndFilter(String sort) {
    List<Map<String, dynamic>> list = List.from(_myEvents);

    list.sort((a, b) {
      final dateA = DateTime.tryParse(a['event_date'] as String? ?? '')?.toLocal() ?? DateTime(1900);
      final timeA = (a['event_time'] as String? ?? '').split(':');
      final hourA = timeA.isNotEmpty ? int.tryParse(timeA[0]) ?? 0 : 0;
      final minA = timeA.length > 1 ? int.tryParse(timeA[1]) ?? 0 : 0;
      final dateTimeA = DateTime(dateA.year, dateA.month, dateA.day, hourA, minA);
      
      final dateB = DateTime.tryParse(b['event_date'] as String? ?? '')?.toLocal() ?? DateTime(1900);
      final timeB = (b['event_time'] as String? ?? '').split(':');
      final hourB = timeB.isNotEmpty ? int.tryParse(timeB[0]) ?? 0 : 0;
      final minB = timeB.length > 1 ? int.tryParse(timeB[1]) ?? 0 : 0;
      final dateTimeB = DateTime(dateB.year, dateB.month, dateB.day, hourB, minB);
      
      final nameA = (a['name'] as String? ?? '').toLowerCase();
      final nameB = (b['name'] as String? ?? '').toLowerCase();

      switch (sort) {
        case 'date_desc':
          return dateTimeB.compareTo(dateTimeA);
        case 'name_asc':
          return nameA.compareTo(nameB);
        case 'name_desc':
          return nameB.compareTo(nameA);
        case 'date_asc':
        default:
          return dateTimeA.compareTo(dateTimeB);
      }
    });

    return list;
  }

  Widget _buildFilterChip({required String label, required String value, required String current}) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _filterNotifier.value = value,
    );
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
                : ValueListenableBuilder<String>(
                    valueListenable: _filterNotifier,
                    builder: (context, filter, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: _sortNotifier,
                        builder: (context, sort, child) {
                          final list = _applySortAndFilter(sort).where((event) {
                            final status = event['status'] as String? ?? 'active';
                            if (filter == 'all') return true;
                            return status == filter;
                          }).toList();
                          
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildFilterChip(label: 'Todos', value: 'all', current: filter),
                                          const SizedBox(width: 8),
                                          _buildFilterChip(label: 'Activos', value: 'active', current: filter),
                                          const SizedBox(width: 8),
                                          _buildFilterChip(label: 'Finalizados', value: 'done', current: filter),
                                          const SizedBox(width: 8),
                                          _buildFilterChip(label: 'Cancelados', value: 'cancelled', current: filter),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  PopupMenuButton<String>(
                                    initialValue: sort,
                                    onSelected: (v) => _sortNotifier.value = v,
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'date_asc', child: Text('Fecha (más próximas)')),
                                      PopupMenuItem(value: 'date_desc', child: Text('Fecha (más lejanas)')),
                                      PopupMenuItem(value: 'name_asc', child: Text('Nombre (A-Z)')),
                                      PopupMenuItem(value: 'name_desc', child: Text('Nombre (Z-A)')),
                                    ],
                                    child: const Icon(Icons.sort, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...list.map((event) {
                            final eventId = event['id'] as String;
                            final name = event['name'] as String? ?? 'Sin título';
                            final eventDate = event['event_date'] as String?;
                            final eventTime = event['event_time'] as String?;
                            final statusStr = event['status'] as String? ?? 'active';
                            final locationData = event['locations'];
                            final location = locationData != null ? locationData['name'] as String? : null;
                            final statusStyle = _getStatusStyle(statusStr);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Chip(
                                            label: Text(
                                              translateEventStatus(statusStr),
                                              style: TextStyle(
                                                color: statusStyle['iconColor'] as Color?,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: (statusStyle['color'] as Color?)?.withValues(alpha: 0.6),
                                            shape: StadiumBorder(
                                              side: BorderSide(
                                                color: (statusStyle['iconColor'] as Color?)?.withValues(alpha: 0.4) ?? Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          await Navigator.pushNamed(
                                            context,
                                            '/edit-event',
                                            arguments: eventId,
                                          );
                                          _loadMyEvents();
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
                                      child: const Icon(Icons.more_vert, size: 20),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatDateTime(eventDate, eventTime),
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
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                    },
                  ),
      ),
    );
  }
}
