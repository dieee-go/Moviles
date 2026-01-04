import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../theme/app_theme_extensions.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _categories = [];
  List<String> _userInterests = [];
  List<String> _registeredEventIds = [];
  String _searchTerm = '';
  final ValueNotifier<String?> _selectedCategoryIdNotifier = ValueNotifier<String?>(null);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _selectedCategoryIdNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cats = await supabase
          .from('interests')
          .select('id, name')
          .order('name');
      _categories = List<Map<String, dynamic>>.from(cats);

      final events = await supabase
          .from('events')
          .select(
            'id, name, image_url, created_at, event_date, event_time, location_id, locations(name), event_interests(interest_id), registrations_count:event_registrations(count)',
          )
          .order('event_date', ascending: false)
          .order('event_time', ascending: false);

      _allEvents = List<Map<String, dynamic>>.from(events);

      // Load current user's interests and registered events
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final userInterstList = await supabase
            .from('user_interests')
            .select('interest_id')
            .eq('user_id', userId);
        _userInterests = (userInterstList as List)
            .map((item) => item['interest_id'] as String)
            .toList();

        // Load user's registered events
        final registeredEvents = await supabase
            .from('event_registrations')
            .select('event_id')
            .eq('user_id', userId);
        _registeredEventIds = (registeredEvents as List)
            .map((item) => item['event_id'] as String)
            .toList();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error BD: ${e.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _categoryLabel(Map<String, dynamic> cat) {
    return (cat['name'] as String?) ?? 'Sin nombre';
  }

  List<Map<String, dynamic>> _filterByCategoryLocal(List<Map<String, dynamic>> source, String? categoryId) {
    if (categoryId == null) return List<Map<String, dynamic>>.from(source);
    return source.where((event) {
      final interests = event['event_interests'] as List<dynamic>?;
      if (interests == null) return false;
      return interests.any((i) => (i['interest_id'] as String?) == categoryId);
    }).toList();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> source, String? categoryId) {
    final byCategory = _filterByCategoryLocal(source, categoryId);
    
    // Exclude registered events
    final notRegistered = byCategory.where((event) {
      final eventId = event['id'] as String?;
      return eventId == null || !_registeredEventIds.contains(eventId);
    }).toList();
    
    if (_searchTerm.isEmpty) return notRegistered;

    final query = _searchTerm.toLowerCase();
    return notRegistered.where((event) {
      final name = (event['name'] as String?) ?? '';
      final locationName = (event['locations']?['name'] as String?) ?? '';
      return name.toLowerCase().contains(query) || locationName.toLowerCase().contains(query);
    }).toList();
  }

  DateTime? _eventDateTime(Map<String, dynamic> event) {
    final dateStr = event['event_date'] as String?;
    final timeStr = event['event_time'] as String?;
    if (dateStr == null || timeStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    final parts = timeStr.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  List<Map<String, dynamic>> _sortedFeatured(List<Map<String, dynamic>> source, String? categoryId) {
    final filtered = _applyFilters(source, categoryId);
    filtered.sort((a, b) {
      final da = _eventDateTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = _eventDateTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return filtered.take(3).toList();
  }

  List<Map<String, dynamic>> _sortedPopular(List<Map<String, dynamic>> source, String? categoryId) {
    final filtered = _applyFilters(source, categoryId);
    filtered.sort((a, b) {
      // 1. Sort by registration count (descending - more registrations first)
      int countA = 0;
      int countB = 0;
      
      final regCountA = a['registrations_count'];
      if (regCountA is List && regCountA.isNotEmpty) {
        countA = (regCountA.first['count'] as int?) ?? 0;
      } else if (regCountA is int) {
        countA = regCountA;
      }
      
      final regCountB = b['registrations_count'];
      if (regCountB is List && regCountB.isNotEmpty) {
        countB = (regCountB.first['count'] as int?) ?? 0;
      } else if (regCountB is int) {
        countB = regCountB;
      }
      
      if (countA != countB) {
        return countB.compareTo(countA);
      }

      // 2. If same registration count, sort by date+time (ascending - closest/next first)
      final eventA = _eventDateTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final eventB = _eventDateTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (eventA.year != eventB.year || eventA.month != eventB.month || eventA.day != eventB.day || eventA.hour != eventB.hour) {
        return eventA.compareTo(eventB);
      }

      // 3. If same date and time, sort by created_at (ascending - oldest/first created first)
      final createdA = DateTime.tryParse((a['created_at'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final createdB = DateTime.tryParse((b['created_at'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return createdA.compareTo(createdB);
    });
    return filtered.take(5).toList();
  }

  int _countMatchingInterests(Map<String, dynamic> event) {
    final eventInterests = event['event_interests'] as List<dynamic>? ?? [];
    int matchCount = 0;
    for (var interest in eventInterests) {
      final interestId = interest['interest_id'] as String?;
      if (interestId != null && _userInterests.contains(interestId)) {
        matchCount++;
      }
    }
    return matchCount;
  }

  List<Map<String, dynamic>> _sortedRecommended(List<Map<String, dynamic>> source, String? categoryId) {
    final filtered = _applyFilters(source, categoryId);
    
    // Filter to only events with at least one matching interest
    final withMatchingInterests = filtered.where((event) {
      return _countMatchingInterests(event) > 0;
    }).toList();

    withMatchingInterests.sort((a, b) {
      // 1. Sort by number of matching interests (descending - most matches first)
      final matchA = _countMatchingInterests(a);
      final matchB = _countMatchingInterests(b);
      if (matchA != matchB) {
        return matchB.compareTo(matchA);
      }

      // 2. If same number of matches, sort by date+time (ascending - next/closest first)
      final eventA = _eventDateTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final eventB = _eventDateTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return eventA.compareTo(eventB);
    });
    
    return withMatchingInterests.take(5).toList();
  }

  String _formatDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return '';
    try {
      final dt = _eventDateTime({'event_date': dateStr, 'event_time': timeStr});
      if (dt == null) return '';
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${dt.day} de ${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.alternativeSurface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? _buildLoadingSkeleton()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar eventos...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchTerm.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchTerm = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchTerm = value.trim());
                        },
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: _selectedCategoryIdNotifier,
                      builder: (context, categoryId, _) {
                        final featured = _sortedFeatured(_allEvents, categoryId);
                        if (featured.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            SizedBox(
                              height: 270,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: featured.length,
                                itemBuilder: (context, i) => _buildFeaturedCard(featured[i]),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Categorías',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String?>(
                      valueListenable: _selectedCategoryIdNotifier,
                      builder: (context, categoryId, _) {
                        final popular = _sortedPopular(_allEvents, categoryId);
                        final recommended = _sortedRecommended(_allEvents, categoryId);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 42,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _categories.length + 1,
                                itemBuilder: (context, i) {
                                  if (i == 0) {
                                    return _buildCategoryChip('Todos', null);
                                  }
                                  final cat = _categories[i - 1];
                                  return _buildCategoryChip(_categoryLabel(cat), cat['id'] as String);
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Eventos Populares',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (popular.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No hay eventos disponibles', style: TextStyle(color: Colors.grey)),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: popular.length,
                                itemBuilder: (context, i) => _buildEventListTile(popular[i]),
                              ),
                            const SizedBox(height: 24),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Recomendados para ti',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (recommended.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No hay eventos disponibles', style: TextStyle(color: Colors.grey)),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: recommended.length,
                                itemBuilder: (context, i) => _buildEventListTile(recommended[i]),
                              ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonBox(height: 48, radius: 12),
            const SizedBox(height: 24),
            _skeletonBox(width: 140, height: 18, radius: 10),
            const SizedBox(height: 12),
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => _featuredSkeletonCard(),
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemCount: 2,
              ),
            ),
            const SizedBox(height: 24),
            _skeletonBox(width: 110, height: 18, radius: 10),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                6,
                (_) => _skeletonBox(width: 90, height: 34, radius: 20),
              ),
            ),
            const SizedBox(height: 24),
            _skeletonBox(width: 170, height: 18, radius: 10),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _eventTileSkeleton(),
              ),
            ),
            _skeletonBox(width: 190, height: 18, radius: 10),
            const SizedBox(height: 12),
            ...List.generate(
              2,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _eventTileSkeleton(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({double width = double.infinity, double height = 14, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _featuredSkeletonCard() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 4),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _skeletonBox(height: 140),
              ),
              const SizedBox(height: 12),
              _skeletonBox(width: 180, height: 16, radius: 8),
              const SizedBox(height: 8),
              _skeletonBox(width: 140, height: 14, radius: 8),
              const SizedBox(height: 12),
              _skeletonBox(height: 36, radius: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventTileSkeleton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _skeletonBox(width: 80, height: 80),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(width: 180, height: 14, radius: 6),
                  const SizedBox(height: 8),
                  _skeletonBox(width: 140, height: 12, radius: 6),
                  const SizedBox(height: 6),
                  _skeletonBox(width: 120, height: 12, radius: 6),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _skeletonBox(width: 24, height: 24, radius: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> event) {
    final imageUrl = event['image_url'] as String?;
    final name = event['name'] as String? ?? 'Sin título';
    final dateTime = _formatDateTime(event['event_date'] as String?, event['event_time'] as String?);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        final scheme = Theme.of(context).colorScheme;
                        return Container(
                          height: 140,
                          color: scheme.skeletonBackground,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        if (kDebugMode) {
                          debugPrint('Error cargando imagen: $error');
                        }
                        final scheme = Theme.of(context).colorScheme;
                        return Container(
                          height: 140,
                          color: scheme.skeletonBackground,
                          child: Icon(Icons.event, size: 48, color: scheme.secondaryText),
                        );
                      },
                    )
                  : Container(
                      height: 140,
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.skeletonBackground,
                      child: Center(
                        child: Icon(Icons.event, size: 48, color: Theme.of(context).colorScheme.secondaryText),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateTime,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final id = event['id'];
                        if (id != null) {
                          Navigator.pushNamed(context, '/event-detail', arguments: id.toString());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Registrarse', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedCategoryIdNotifier.value == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) => _selectedCategoryIdNotifier.value = v ? categoryId : null,
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: selected ? scheme.primary : scheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.secondaryText.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEventListTile(Map<String, dynamic> event) {
    final imageUrl = event['image_url'] as String?;
    final name = event['name'] as String? ?? 'Sin título';
    final dateTime = _formatDateTime(event['event_date'] as String?, event['event_time'] as String?);
    final locationData = event['locations'];
    final location = locationData != null ? locationData['name'] as String? : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                dateTime,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (location != null) ...[
                const SizedBox(height: 2),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            final id = event['id'];
            if (id != null) {
              Navigator.pushNamed(context, '/event-detail', arguments: id.toString());
            }
          },
        ),
      ),
    );
  }
}
