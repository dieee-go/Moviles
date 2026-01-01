import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../components/skeletons.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  List<Map<String, dynamic>> _allEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadEvents();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es_ES', null);
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('events')
          .select('id, name, event_datetime, location_id, locations(name), image_url')
          .order('event_datetime');

      setState(() {
        _allEvents = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando eventos: $e', isError: true);
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      final eventDate = DateTime.parse(event['event_datetime'] as String);
      return eventDate.year == day.year &&
          eventDate.month == day.month &&
          eventDate.day == day.day;
    }).toList();
  }

  List<DateTime> _getDaysInMonth(DateTime dateTime) {
    final first = DateTime(dateTime.year, dateTime.month, 1);
    final last = DateTime(dateTime.year, dateTime.month + 1, 0);
    final daysInMonth = last.day;
    final previousMonthDays = first.weekday - 1;

    List<DateTime> days = [];

    // Días del mes anterior
    for (int i = previousMonthDays; i > 0; i--) {
      days.add(first.subtract(Duration(days: i)));
    }

    // Días del mes actual
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(dateTime.year, dateTime.month, i));
    }

    // Días del próximo mes
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(last.add(Duration(days: i)));
    }

    return days;
  }

  void _previousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  Scaffold _buildLoadingSkeleton() {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de Eventos')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeletons.box(width: 200, height: 20, radius: 8),
              const SizedBox(height: 12),
              Skeletons.box(height: 44, radius: 10),
              const SizedBox(height: 12),
              Skeletons.box(height: 36, radius: 10),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 21,
                itemBuilder: (context, _) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 38,
                ),
              ),
              const SizedBox(height: 18),
              Skeletons.box(width: 220, height: 18, radius: 8),
              const SizedBox(height: 12),
              Skeletons.listTiles(count: 3, leadingSize: 70),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingSkeleton();
    }

    final daysInMonth = _getDaysInMonth(_focusedDay);
    final selectedDayEvents = _getEventsForDay(_selectedDay);
    final monthName = DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.alternativeSurface,
      appBar: AppBar(
        title: const Text('Calendario de Eventos'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header del mes
          Container(
            padding: const EdgeInsets.all(16),
            color: scheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  monthName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Días de la semana
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                  .map((day) => Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.secondaryText,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Calendario
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: daysInMonth.length,
              itemBuilder: (context, index) {
                final day = daysInMonth[index];
                final isCurrentMonth = day.month == _focusedDay.month;
                final isSelected = day.year == _selectedDay.year &&
                    day.month == _selectedDay.month &&
                    day.day == _selectedDay.day;
                final isToday = day.year == DateTime.now().year &&
                    day.month == DateTime.now().month &&
                    day.day == DateTime.now().day;
                final dayEvents = _getEventsForDay(day);
                final hasEvents = dayEvents.isNotEmpty;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary
                          : isToday
                              ? scheme.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentMonth && hasEvents
                          ? Border.all(color: scheme.primary, width: 2)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : !isCurrentMonth
                                        ? (isDark ? Colors.grey[600] : Colors.grey[300])
                                        : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            if (hasEvents)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Eventos del día seleccionado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Eventos de ${DateFormat('dd/MM/yyyy').format(_selectedDay)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: selectedDayEvents.isEmpty
                ? Center(
                    child: Text(
                      'No hay eventos este día',
                      style: TextStyle(color: scheme.secondaryText),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedDayEvents[index];
                      final eventName = event['name'] as String? ?? 'Sin título';
                      final eventDateTime =
                          event['event_datetime'] as String? ?? '';
                      final locationData = event['locations'];
                      final location = locationData != null
                          ? locationData['name'] as String?
                          : null;
                      final imageUrl = event['image_url'] as String?;

                      final eventTime = eventDateTime.isNotEmpty
                          ? DateFormat('HH:mm').format(DateTime.parse(eventDateTime))
                          : '';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      final scheme = Theme.of(context).colorScheme;
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: scheme.skeletonBackground,
                                        child: Icon(Icons.event, color: scheme.secondaryText),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Theme.of(context).colorScheme.skeletonBackground,
                                    child: Icon(Icons.event, color: Theme.of(context).colorScheme.secondaryText),
                                  ),
                          ),
                          title: Text(
                            eventName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                eventTime,
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey),
                              ),
                              if (location != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[500] : Colors.grey),
                          onTap: () {
                            final id = event['id'];
                            if (id != null) {
                              Navigator.pushNamed(context, '/event-detail',
                                  arguments: id.toString());
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
