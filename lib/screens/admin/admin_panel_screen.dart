import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/skeletons.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';
import '../../utils/translations.dart';

// Función global para traducir roles
String _translateRole(String role) {
  return translateRole(role);
}

// Función global para traducir estados
String _translateStatus(String status) {
  return translateEventStatus(status);
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  static const int _pageSize = 15;

  late final TabController _tabController;

  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _organizers = [];
  final List<Map<String, dynamic>> _events = [];

  bool _loadingUsers = false;
  bool _loadingOrganizers = false;
  bool _loadingEvents = false;
  bool _loadingReports = false;

  bool _hasMoreUsers = true;
  bool _hasMoreOrganizers = true;
  bool _hasMoreEvents = true;

  int _pageUsers = 0;
  int _pageOrganizers = 0;
  int _pageEvents = 0;

  int _totalUsers = 0;
  int _organizersCount = 0;
  int _newToday = 0;
  int _eventsUpcoming = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadUsers(reset: true),
      _loadOrganizers(reset: true),
      _loadEvents(reset: true),
      _loadReports(),
    ]);
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (_loadingUsers && !reset) return;
    setState(() => _loadingUsers = true);
    if (reset) {
      _users.clear();
      _pageUsers = 0;
      _hasMoreUsers = true;
    }
    try {
      if (!_hasMoreUsers) return;
      final from = _pageUsers * _pageSize;
      final to = from + _pageSize - 1;
      final data = await supabase
          .from('profiles')
          .select('id, nombre, primer_apellido, email, role')
          .order('nombre', ascending: true)
          .range(from, to);
      _users.addAll(List<Map<String, dynamic>>.from(data));
      if (data.length < _pageSize) _hasMoreUsers = false;
      _pageUsers++;
    } catch (e) {
      if (mounted) context.showSnackBar('Error cargando usuarios: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadOrganizers({bool reset = false}) async {
    if (_loadingOrganizers && !reset) return;
    setState(() => _loadingOrganizers = true);
    if (reset) {
      _organizers.clear();
      _pageOrganizers = 0;
      _hasMoreOrganizers = true;
    }
    try {
      if (!_hasMoreOrganizers) return;
      final from = _pageOrganizers * _pageSize;
      final to = from + _pageSize - 1;
      final data = await supabase
          .from('profiles')
          .select('id, nombre, primer_apellido, email, role')
          .eq('role', 'organizer')
          .order('nombre', ascending: true)
          .range(from, to);
      _organizers.addAll(List<Map<String, dynamic>>.from(data));
      if (data.length < _pageSize) _hasMoreOrganizers = false;
      _pageOrganizers++;
    } catch (e) {
      if (mounted) context.showSnackBar('Error cargando organizadores: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingOrganizers = false);
    }
  }

  Future<void> _loadEvents({bool reset = false}) async {
    if (_loadingEvents && !reset) return;
    setState(() => _loadingEvents = true);
    if (reset) {
      _events.clear();
      _pageEvents = 0;
      _hasMoreEvents = true;
    }
    try {
      if (!_hasMoreEvents) return;
      final from = _pageEvents * _pageSize;
      final to = from + _pageSize - 1;
      final data = await supabase
          .from('events')
          .select('id, name, event_datetime, status')
          .order('event_datetime', ascending: true)
          .range(from, to);
      _events.addAll(List<Map<String, dynamic>>.from(data));
      if (data.length < _pageSize) _hasMoreEvents = false;
      _pageEvents++;
    } catch (e) {
      if (mounted) context.showSnackBar('Error cargando eventos: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc();
    try {
      final profiles = await supabase.from('profiles').select('id');
      _totalUsers = profiles.length;

      final organizers = await supabase.from('profiles').select('id').eq('role', 'organizer');
      _organizersCount = organizers.length;

      final newTodayResp = await supabase
          .from('profiles')
          .select('id')
          .gte('created_at', todayStart.toIso8601String());
      _newToday = newTodayResp.length;

      final eventsUpcomingResp = await supabase
          .from('events')
          .select('id')
          .gte('event_datetime', now.toUtc().toIso8601String());
      _eventsUpcoming = eventsUpcomingResp.length;
    } catch (e) {
      if (mounted) context.showSnackBar('Error cargando reportes: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingReports = false);
    }
  }

  Future<void> _changeRole(String userId, String newRole) async {
    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      if (mounted) context.showSnackBar('Rol actualizado a $newRole');
      await Future.wait([
        _loadUsers(reset: true),
        _loadOrganizers(reset: true),
      ]);
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar('Error: ${e.message}', isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error inesperado', isError: true);
    }
  }

  Future<void> _loadRequestsBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _RequestsSheet(onApproved: _loadEvents);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: const Text('Panel de Administración'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: scheme.onPrimary,
          unselectedLabelColor: scheme.onPrimary.withValues(alpha: 179),
          indicatorColor: scheme.onPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.badge), text: 'Organizadores'),
            Tab(icon: Icon(Icons.event), text: 'Eventos'),
            Tab(icon: Icon(Icons.analytics), text: 'Reportes'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitial,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersTab(
            data: _users,
            loading: _loadingUsers,
            hasMore: _hasMoreUsers,
            onLoadMore: () => _loadUsers(),
            onRefresh: () => _loadUsers(reset: true),
            onChangeRole: _changeRole,
          ),
          _UsersTab(
            data: _organizers,
            loading: _loadingOrganizers,
            hasMore: _hasMoreOrganizers,
            onLoadMore: () => _loadOrganizers(),
            onRefresh: () => _loadOrganizers(reset: true),
            onChangeRole: (id, _) => _changeRole(id, 'student'),
            titleOverride: 'Organizadores',
            showDemote: true,
            header: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loadRequestsBottomSheet,
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text('Solicitudes organizador'),
              ),
            ),
          ),
          _EventsTab(
            data: _events,
            loading: _loadingEvents,
            hasMore: _hasMoreEvents,
            onLoadMore: () => _loadEvents(),
            onRefresh: () => _loadEvents(reset: true),
          ),
          _ReportsTab(
            loading: _loadingReports,
            totalUsers: _totalUsers,
            organizersCount: _organizersCount,
            newToday: _newToday,
            eventsUpcoming: _eventsUpcoming,
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool loading;
  final bool hasMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String userId, String newRole) onChangeRole;
  final String? titleOverride;
  final bool showDemote;
  final Widget? header;

  const _UsersTab({
    required this.data,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onChangeRole,
    this.titleOverride,
    this.showDemote = false,
    this.header,
  });

  String _fullName(Map<String, dynamic> u) {
    final n = (u['nombre'] as String?) ?? '';
    final a = (u['primer_apellido'] as String?) ?? '';
    final full = '$n $a'.trim();
    return full.isEmpty ? 'Sin nombre' : full;
  }

  @override
  Widget build(BuildContext context) {
    final hasHeader = header != null;
    final itemCount = data.length + 1 + (hasHeader ? 1 : 0);

    if (loading && data.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            if (hasHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: header,
              ),
            Skeletons.listTiles(count: 6, leadingSize: 44),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (hasHeader && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: header,
            );
          }

          final dataIndex = hasHeader ? index - 1 : index;

          if (dataIndex == data.length) {
            if (!hasMore) return const SizedBox.shrink();
            if (!loading) onLoadMore();
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final u = data[dataIndex];
          final role = u['role'] as String? ?? 'sin rol';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(_fullName(u).isNotEmpty ? _fullName(u)[0] : '?'),
              ),
              title: Text(_fullName(u)),
              subtitle: Text(u['email'] as String? ?? ''),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => onChangeRole(u['id'] as String, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'admin', child: Text('Hacer admin')),
                  const PopupMenuItem(value: 'organizer', child: Text('Hacer organizador')),
                  const PopupMenuItem(value: 'student', child: Text('Hacer estudiante')),
                  if (showDemote)
                    const PopupMenuItem(value: 'student', child: Text('Revocar rol')),
                ],
                child: Chip(label: Text(_translateRole(role))),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool loading;
  final bool hasMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;

  const _EventsTab({
    required this.data,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && data.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Skeletons.listTiles(count: 6, leadingSize: 52),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: data.length + 1,
        itemBuilder: (context, index) {
          if (index == data.length) {
            if (!hasMore) return const SizedBox.shrink();
            if (!loading) onLoadMore();
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final e = data[index];
          final name = e['name'] as String? ?? 'Sin título';
          final status = e['status'] as String? ?? '';
          final dtIso = e['event_datetime'] as String?;
          DateTime? dt;
          if (dtIso != null) {
            dt = DateTime.tryParse(dtIso)?.toLocal();
          }
          final dateLabel = dt != null
              ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(name),
              subtitle: Text(dateLabel),
              trailing: Chip(label: Text(_translateStatus(status.isEmpty ? '' : status))),
            ),
          );
        },
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final bool loading;
  final int totalUsers;
  final int organizersCount;
  final int newToday;
  final int eventsUpcoming;

  const _ReportsTab({
    required this.loading,
    required this.totalUsers,
    required this.organizersCount,
    required this.newToday,
    required this.eventsUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Skeletons.kpiGrid(items: 4),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kpi('Total usuarios', totalUsers, Icons.people, Colors.blue),
          const SizedBox(height: 12),
          _kpi('Organizadores', organizersCount, Icons.badge, Colors.teal),
          const SizedBox(height: 12),
          _kpi('Registros hoy', newToday, Icons.today, Colors.orange),
          const SizedBox(height: 12),
          _kpi('Eventos próximos', eventsUpcoming, Icons.event, Colors.green),
        ],
      ),
    );
  }

  Widget _kpi(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsSheet extends StatefulWidget {
  final Future<void> Function() onApproved;
  const _RequestsSheet({required this.onApproved});

  @override
  State<_RequestsSheet> createState() => _RequestsSheetState();
}

class _RequestsSheetState extends State<_RequestsSheet> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('role_requests')
          .select(
              'id, user_id, status, message, reason, created_at, updated_at, profiles!inner(nombre, primer_apellido, email)')
          .order('created_at', ascending: false);
      setState(() {
        _requests = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) context.showSnackBar('Error cargando solicitudes: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handle(String id, bool approve) async {
    try {
      await supabase.rpc('approve_organizer_request', params: {
        'request_id': id,
        'approve': approve,
      });
      if (mounted) context.showSnackBar(approve ? 'Solicitud aprobada' : 'Solicitud rechazada');
      await _loadRequests();
      await widget.onApproved();
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar('Error: ${e.message}', isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error inesperado', isError: true);
    }
  }
  String _name(Map<String, dynamic> r) {
    final p = r['profiles'] as Map<String, dynamic>?;
    final n = p?['nombre'] as String? ?? '';
    final a = p?['primer_apellido'] as String? ?? '';
    final full = '$n $a'.trim();
    return full.isEmpty ? 'Usuario' : full;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.skeletonBackground,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Solicitudes de organizador', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? const Center(child: Text('Sin solicitudes'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final r = _requests[index];
                            final email = (r['profiles'] as Map<String, dynamic>?)?['email'] as String? ?? '';
                            final msg = (r['message'] as String?) ?? (r['reason'] as String?) ?? '';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_name(r), style: const TextStyle(fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            Text(email, style: const TextStyle(color: Colors.grey)),
                                          ],
                                        ),
                                        Chip(label: Text(_translateStatus(r['status'] as String? ?? 'pending'))),
                                      ],
                                    ),
                                    if (msg.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(msg),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _handle(r['id'] as String, false),
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            label: const Text('Rechazar'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _handle(r['id'] as String, true),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Aprobar'),
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
          ],
        ),
      ),
    );
  }
}
