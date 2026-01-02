import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';

class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({super.key});

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  bool _loading = true;
  List<_RegistrationItem> _items = [];
  final ValueNotifier<String> _filterNotifier = ValueNotifier('all'); // all | registered | attended
  final ValueNotifier<String> _sortNotifier = ValueNotifier('date_desc'); // date_desc | date_asc | name_asc | name_desc

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _filterNotifier.dispose();
    _sortNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _loading = false;
        _items = [];
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await supabase
          .from('event_registrations')
          .select(
            'event_id, registration_datetime, checked_in_at, '
            'events(name, event_datetime, image_url, locations(name))',
          )
          .eq('user_id', userId)
          .order('registration_datetime', ascending: false);

      final mapped = (data as List<dynamic>).map((raw) {
        final map = raw as Map<String, dynamic>;
        final event = map['events'] as Map<String, dynamic>?;
        return _RegistrationItem(
          eventId: map['event_id'] as String? ?? '',
          name: (event?['name'] as String?)?.trim() ?? 'Evento sin título',
          eventDate: event?['event_datetime'] as String?,
          location: (event?['locations']?['name'] as String?)?.trim(),
          imageUrl: event?['image_url'] as String?,
          registrationDate: map['registration_datetime'] as String?,
          checkedInAt: map['checked_in_at'] as String?,
        );
      }).toList();

      setState(() {
        _items = mapped;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando registros: ${e.message}', isError: true);
      }
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        context.showSnackBar('No se pudieron cargar tus registros', isError: true);
      }
      setState(() => _loading = false);
    }
  }

  List<_RegistrationItem> _applySortAndFilter(String filter, String sort) {
    List<_RegistrationItem> list = _items;

    if (filter == 'registered') {
      list = list.where((e) => e.checkedInAt == null).toList();
    } else if (filter == 'attended') {
      list = list.where((e) => e.checkedInAt != null).toList();
    }

    list.sort((a, b) {
      switch (sort) {
        case 'date_asc':
          return (a.eventDateParsed ?? DateTime(1900)).compareTo(b.eventDateParsed ?? DateTime(1900));
        case 'name_asc':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'name_desc':
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case 'date_desc':
        default:
          return (b.eventDateParsed ?? DateTime(1900)).compareTo(a.eventDateParsed ?? DateTime(1900));
      }
    });

    return list;
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      final datePart = '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
      final timePart = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$datePart · $timePart';
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(ColorScheme scheme, bool attended) {
    return attended ? scheme.primary : scheme.outline;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No tienes registros aún.')),
                    ],
                  )
                : ValueListenableBuilder<String>(
                    valueListenable: _filterNotifier,
                    builder: (context, filter, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: _sortNotifier,
                        builder: (context, sort, child) {
                          final list = _applySortAndFilter(filter, sort);
                          return ListView(
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
                                          _buildFilterChip(label: 'Registros', value: 'registered', current: filter),
                                          const SizedBox(width: 8),
                                          _buildFilterChip(label: 'Asistencias', value: 'attended', current: filter),
                                        ],
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    initialValue: sort,
                                    onSelected: (v) => _sortNotifier.value = v,
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'date_desc', child: Text('Fecha (más próximas)')),
                                      PopupMenuItem(value: 'date_asc', child: Text('Fecha (más lejanas)')),
                                      PopupMenuItem(value: 'name_asc', child: Text('Nombre (A-Z)')),
                                      PopupMenuItem(value: 'name_desc', child: Text('Nombre (Z-A)')),
                                    ],
                                    child: const Icon(Icons.sort, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...list.map((item) => _buildItemCard(context, item, scheme)),
                            ],
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value, required String current}) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _filterNotifier.value = value,
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, _RegistrationItem item, ColorScheme scheme) {
    final attended = item.checkedInAt != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/event_detail', arguments: item.eventId);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _placeholderBox(scheme),
                      )
                    : _placeholderBox(scheme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(item.eventDate),
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                    if (item.location?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.place, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(scheme, attended).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            attended ? 'Asistencia confirmada' : 'Registrado',
                            style: TextStyle(
                              color: _statusColor(scheme, attended),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Registro: ${_formatDate(item.registrationDate)}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderBox(ColorScheme scheme) {
    return Container(
      width: 70,
      height: 70,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.event, color: scheme.onSurfaceVariant),
    );
  }
}

class _RegistrationItem {
  final String eventId;
  final String name;
  final String? eventDate;
  final String? location;
  final String? imageUrl;
  final String? registrationDate;
  final String? checkedInAt;

  _RegistrationItem({
    required this.eventId,
    required this.name,
    required this.eventDate,
    required this.location,
    required this.imageUrl,
    required this.registrationDate,
    required this.checkedInAt,
  });

  DateTime? get eventDateParsed => _parseDate(eventDate);

  static DateTime? _parseDate(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return null;
    }
  }
}
