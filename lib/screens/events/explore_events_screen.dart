import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/skeletons.dart';
import '../../main.dart';

class ExploreEventsScreen extends StatefulWidget {
  const ExploreEventsScreen({super.key});

  @override
  ExploreEventsScreenState createState() => ExploreEventsScreenState();
}

class ExploreEventsScreenState extends State<ExploreEventsScreen> {
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = "";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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

      // Cargar eventos
      await _loadEvents();
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

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
          final query = supabase.from('events').select(
            'id, name, image_url, event_datetime, location_id, locations(name), event_interests!inner(interest_id)');

        // Filtrar por categoría si está seleccionada (inner join para asegurar la relación)
        final data = _selectedCategoryId == null
          ? await query.order('event_datetime', ascending: false)
            : await query
              .eq('event_interests.interest_id', _selectedCategoryId!)
              .order('event_datetime', ascending: false);

      setState(() {
        _events = List<Map<String, dynamic>>.from(data);
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error: ${e.message}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDateTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ];
      return '${dt.day} de ${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredEvents = _events;

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filteredEvents = filteredEvents.where((event) {
        final name = (event['name'] as String?) ?? '';
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Eventos'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? _buildSkeleton()
            : Column(
                children: [
                  // Barra de búsqueda
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar eventos...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  // Categorías
                  if (_categories.isNotEmpty) ...[
                    SizedBox(
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
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Contador de eventos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filteredEvents.length} eventos encontrados',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista de eventos
                  Expanded(
                    child: filteredEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 20),
                                const Text(
                                  'No se encontraron eventos',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Intenta con otra búsqueda',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = filteredEvents[index];
                              return _buildEventCard(context, event);
                            },
                          ),
                  ),
                ],
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
    final selected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) async {
          setState(() {
            _selectedCategoryId = v ? categoryId : null;
            _loading = true;
          });
          await _loadEvents();
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1976D2).withValues(alpha: 51),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? const Color(0xFF1976D2)
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final imageUrl = event['image_url'] as String?;
    final name = event['name'] as String? ?? 'Sin título';
    final dateTime = _formatDateTime(event['event_datetime'] as String?);
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
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
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
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.event, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.event, color: Colors.grey),
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
}