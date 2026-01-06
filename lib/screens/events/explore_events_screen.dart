import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/skeletons.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';

class ExploreEventsScreen extends StatefulWidget {
  const ExploreEventsScreen({super.key});

  @override
  ExploreEventsScreenState createState() => ExploreEventsScreenState();
}

class ExploreEventsScreenState extends State<ExploreEventsScreen> {
  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _locations = [];
  final ValueNotifier<String?> _selectedCategoryIdNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>("");
  final ValueNotifier<String?> _selectedLocationIdNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String> _selectedDateFilterNotifier = ValueNotifier<String>('todos');
  final ValueNotifier<String> _sortNotifier = ValueNotifier<String>('date_desc'); // date_desc | date_asc | name_asc | name_desc
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Acceso seguro a InheritedWidgets aquí si es necesario
  }

  @override
  void dispose() {
    _selectedCategoryIdNotifier.dispose();
    _searchNotifier.dispose();
    _selectedLocationIdNotifier.dispose();
    _selectedDateFilterNotifier.dispose();
    _sortNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Cargar categorías
      final cats = await supabase
          .from('interests')
          .select('id, name')
          .order('name');
      _categories = List<Map<String, dynamic>>.from(cats);

      // Cargar ubicaciones
      final locs = await supabase
          .from('locations')
          .select('id, name')
          .order('name');
      _locations = List<Map<String, dynamic>>.from(locs);

      // Cargar todos los eventos (incluye intereses para filtrar localmente)
      final data = await supabase.from('events').select(
        'id, name, image_url, event_date, event_time, created_at, location_id, locations(name), event_interests(interest_id)',
      ).order('event_date', ascending: false);

      setState(() {
        _allEvents = List<Map<String, dynamic>>.from(data);
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error BD: ${e.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando datos', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final parts = timeStr.split(':');
      final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final dt = DateTime(date.year, date.month, date.day, hour, minute);
      const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${dt.day} de ${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  bool _isEventInDateRange(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return false;
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final parts = timeStr.split(':');
      final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final eventDate = DateTime(date.year, date.month, date.day, hour, minute);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (_selectedDateFilterNotifier.value) {
        case 'hoy':
          final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
          return eventDay == today;
        case 'semana':
          final weekEnd = today.add(const Duration(days: 7));
          return eventDate.isAfter(today.subtract(const Duration(days: 1))) && eventDate.isBefore(weekEnd.add(const Duration(days: 1)));
        case 'mes':
          return eventDate.year == now.year && eventDate.month == now.month;
        case 'proximo7':
          final sevenDaysFromNow = now.add(const Duration(days: 7));
          return eventDate.isAfter(now) && eventDate.isBefore(sevenDaysFromNow);
        default:
          return true;
      }
    } catch (_) {
      return false;
    }
  }

  List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> events) {
    final sorted = [...events];
    
    sorted.sort((a, b) {
      switch (_sortNotifier.value) {
        case 'date_asc':
          final dateA = DateTime.tryParse(a['event_date'] as String? ?? '') ?? DateTime(1900);
          final timeA = (a['event_time'] as String? ?? '').split(':');
          final hourA = timeA.isNotEmpty ? int.tryParse(timeA[0]) ?? 0 : 0;
          final minA = timeA.length > 1 ? int.tryParse(timeA[1]) ?? 0 : 0;
          final dateTimeA = DateTime(dateA.year, dateA.month, dateA.day, hourA, minA);
          
          final dateB = DateTime.tryParse(b['event_date'] as String? ?? '') ?? DateTime(1900);
          final timeB = (b['event_time'] as String? ?? '').split(':');
          final hourB = timeB.isNotEmpty ? int.tryParse(timeB[0]) ?? 0 : 0;
          final minB = timeB.length > 1 ? int.tryParse(timeB[1]) ?? 0 : 0;
          final dateTimeB = DateTime(dateB.year, dateB.month, dateB.day, hourB, minB);
          return dateTimeA.compareTo(dateTimeB);
          
        case 'name_asc':
          final nameA = (a['name'] as String? ?? '').toLowerCase();
          final nameB = (b['name'] as String? ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        case 'name_desc':
          final nameA = (a['name'] as String? ?? '').toLowerCase();
          final nameB = (b['name'] as String? ?? '').toLowerCase();
          return nameB.compareTo(nameA);
        case 'date_desc':
        default:
          final dateA = DateTime.tryParse(a['event_date'] as String? ?? '') ?? DateTime(1900);
          final timeA = (a['event_time'] as String? ?? '').split(':');
          final hourA = timeA.isNotEmpty ? int.tryParse(timeA[0]) ?? 0 : 0;
          final minA = timeA.length > 1 ? int.tryParse(timeA[1]) ?? 0 : 0;
          final dateTimeA = DateTime(dateA.year, dateA.month, dateA.day, hourA, minA);
          
          final dateB = DateTime.tryParse(b['event_date'] as String? ?? '') ?? DateTime(1900);
          final timeB = (b['event_time'] as String? ?? '').split(':');
          final hourB = timeB.isNotEmpty ? int.tryParse(timeB[0]) ?? 0 : 0;
          final minB = timeB.length > 1 ? int.tryParse(timeB[1]) ?? 0 : 0;
          final dateTimeB = DateTime(dateB.year, dateB.month, dateB.day, hourB, minB);
          return dateTimeB.compareTo(dateTimeA);
      }
    });
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: _loading
              ? _buildSkeleton()
              : CustomScrollView(
                  slivers: [
                    // Barra de búsqueda - fija en la parte superior
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      toolbarHeight: 70,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            onChanged: (value) => _searchNotifier.value = value,
                            decoration: InputDecoration(
                              hintText: 'Buscar eventos...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Filtros - se deslizan con el contenido
                    if (_categories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Text(
                                'Por categoría:',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            ValueListenableBuilder<String?>(
                              valueListenable: _selectedCategoryIdNotifier,
                              builder: (context, selectedId, _) {
                                return SizedBox(
                                  height: 50,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _categories.length + 1,
                                    itemBuilder: (context, i) {
                                      if (i == 0) {
                                        return _buildCategoryChip('Todos', null);
                                      }
                                      final cat = _categories[i - 1];
                                      final name = cat['name'] as String? ?? 'Sin nombre';
                                      return _buildCategoryChip(name, cat['id'] as String);
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Text(
                                'Por fecha:',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            ValueListenableBuilder<String>(
                              valueListenable: _selectedDateFilterNotifier,
                              builder: (context, selectedFilter, _) {
                                return SizedBox(
                                  height: 50,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    children: [
                                      _buildDateChip('Todos', 'todos'),
                                      _buildDateChip('Hoy', 'hoy'),
                                      _buildDateChip('Esta semana', 'semana'),
                                      _buildDateChip('Este mes', 'mes'),
                                      _buildDateChip('Próximos 7 días', 'proximo7'),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            if (_locations.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Text(
                                  'Por ubicación:',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              ValueListenableBuilder<String?>(
                                valueListenable: _selectedLocationIdNotifier,
                                builder: (context, selectedLocId, _) {
                                  return SizedBox(
                                    height: 50,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _locations.length + 1,
                                      itemBuilder: (context, i) {
                                        if (i == 0) {
                                          return _buildLocationChip('Todas', null);
                                        }
                                        final loc = _locations[i - 1];
                                        final name = loc['name'] as String? ?? 'Sin nombre';
                                        return _buildLocationChip(name, loc['id'] as String);
                                      },
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),

                    // Lista de eventos
                    SliverToBoxAdapter(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _selectedCategoryIdNotifier,
                        builder: (context, selectedId, child) {
                          return ValueListenableBuilder<String>(
                            valueListenable: _searchNotifier,
                            builder: (context, search, child) {
                              return ValueListenableBuilder<String>(
                                valueListenable: _selectedDateFilterNotifier,
                                builder: (context, selectedDateFilter, child) {
                                  return ValueListenableBuilder<String?>(
                                    valueListenable: _selectedLocationIdNotifier,
                                    builder: (context, selectedLocId, child) {
                                      List<Map<String, dynamic>> filteredEvents = _allEvents;

                                      if (selectedId != null) {
                                        filteredEvents = filteredEvents.where((event) {
                                          final interests = event['event_interests'] as List<dynamic>?;
                                          if (interests == null) return false;
                                          return interests.any((i) => (i['interest_id'] as String?) == selectedId);
                                        }).toList();
                                      }

                                      if (search.isNotEmpty) {
                                        filteredEvents = filteredEvents.where((event) {
                                          final name = (event['name'] as String?) ?? '';
                                          return name.toLowerCase().contains(search.toLowerCase());
                                        }).toList();
                                      }

                                      if (selectedDateFilter != 'todos') {
                                        filteredEvents = filteredEvents.where((event) {
                                          return _isEventInDateRange(
                                            event['event_date'] as String?,
                                            event['event_time'] as String?,
                                          );
                                        }).toList();
                                      }

                                      if (selectedLocId != null) {
                                        filteredEvents = filteredEvents.where((event) {
                                          final locId = event['location_id'] as String?;
                                          return locId == selectedLocId;
                                        }).toList();
                                      }

                                      return ValueListenableBuilder<String>(
                                        valueListenable: _sortNotifier,
                                        builder: (context, sort, child) {
                                          final sortedEvents = _applySorting(filteredEvents);

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Contador de eventos y botón de ordenamiento
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${sortedEvents.length} eventos encontrados',
                                                      style: TextStyle(color: Theme.of(context).colorScheme.secondaryText),
                                                    ),
                                                    PopupMenuButton<String>(
                                                      initialValue: sort,
                                                      onSelected: (v) => _sortNotifier.value = v,
                                                      itemBuilder: (context) => const [
                                                        PopupMenuItem(value: 'date_desc', child: Text('Fecha (próximas)')),
                                                        PopupMenuItem(value: 'date_asc', child: Text('Fecha (lejanas)')),
                                                        PopupMenuItem(value: 'name_asc', child: Text('Nombre (A-Z)')),
                                                        PopupMenuItem(value: 'name_desc', child: Text('Nombre (Z-A)')),
                                                      ],
                                                      child: const Icon(Icons.sort, size: 20),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 16),

                                                // Lista de eventos o mensaje vacío
                                                if (sortedEvents.isEmpty)
                                                  SizedBox(
                                                    height: 300,
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.search_off,
                                                            size: 80, color: Theme.of(context).colorScheme.skeletonBackground),
                                                        const SizedBox(height: 20),
                                                        const Text(
                                                          'No se encontraron eventos',
                                                          style: TextStyle(fontSize: 18, color: Colors.grey),
                                                        ),
                                                        const SizedBox(height: 10),
                                                        const Text(
                                                          'Intenta con otra búsqueda',
                                                          style: TextStyle(color: Colors.grey),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else
                                                  ListView.builder(
                                                    shrinkWrap: true,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    itemCount: sortedEvents.length,
                                                    itemBuilder: (context, index) {
                                                      final event = sortedEvents[index];
                                                      return _buildEventCard(context, event);
                                                    },
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Skeletons.box(height: 48, radius: 12),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Skeletons.chips(count: 6, width: 90, height: 34),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Skeletons.box(width: 180, height: 16, radius: 8),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Skeletons.listTiles(count: 4, leadingSize: 80),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final selected = _selectedCategoryIdNotifier.value == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) => _selectedCategoryIdNotifier.value = v ? categoryId : null,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 51),
        labelStyle: TextStyle(
          color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final imageUrl = event['image_url'] as String?;
    final name = event['name'] as String? ?? 'Sin título';
    final dateTime = _formatDateTime(event['event_date'] as String?, event['event_time'] as String?);
    final locationData = event['locations'];
    final location =
        locationData != null ? locationData['name'] as String? : null;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/event-detail',
            arguments: event['id'] as String);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del evento
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          final scheme = Theme.of(context).colorScheme;
                          return Container(
                            width: 80,
                            height: 80,
                            color: scheme.skeletonBackground,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) {
                            debugPrint('Error cargando imagen: $error');
                          }
                          final scheme = Theme.of(context).colorScheme;
                          return Container(
                            width: 80,
                            height: 80,
                            color: scheme.skeletonBackground,
                            child: Icon(Icons.event, color: scheme.secondaryText),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context).colorScheme.skeletonBackground,
                        child: Icon(Icons.event, color: Theme.of(context).colorScheme.secondaryText),
                      ),
              ),
              const SizedBox(width: 16),
              // Información del evento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateTime,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, String filterId) {
    final selected = _selectedDateFilterNotifier.value == filterId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) => _selectedDateFilterNotifier.value = v ? filterId : 'todos',
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 51),
        labelStyle: TextStyle(
          color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationChip(String label, String? locationId) {
    final selected = _selectedLocationIdNotifier.value == locationId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) => _selectedLocationIdNotifier.value = v ? locationId : null,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 51),
        labelStyle: TextStyle(
          color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}