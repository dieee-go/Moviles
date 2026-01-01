import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/skeletons.dart';
import '../main.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  bool _loading = true;
  bool _authzChecked = false;
  bool _isAdmin = false;
  String? _error;
  String? _processingId;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _authzChecked = true;
        _isAdmin = false;
        _loading = false;
        _error = 'Inicia sesión como administrador';
      });
      return;
    }

    try {
      final roleRow = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = roleRow?['role'] as String?;
      _isAdmin = role == 'admin';
      _authzChecked = true;
      if (!_isAdmin) {
        setState(() {
          _loading = false;
          _error = 'Solo los administradores pueden acceder a esta pantalla';
        });
        return;
      }

      final data = await supabase
          .from('role_requests')
          .select('id, user_id, status, created_at, updated_at, profiles(nombre, primer_apellido, email, role)')
          .eq('status', 'pending')
          .order('created_at');

      _requests = List<Map<String, dynamic>>.from(data);
      setState(() => _loading = false);
    } on PostgrestException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error inesperado';
      });
      if (kDebugMode) {
        debugPrint('Admin panel error: $e');
      }
    }
  }

  Future<void> _approve(String requestId) async {
    setState(() => _processingId = requestId);
    try {
      await supabase.rpc('approve_organizer_request', params: {'p_request_id': requestId});
      _requests.removeWhere((r) => r['id'] == requestId);
      if (mounted) {
        setState(() => _processingId = null);
        context.showSnackBar('Solicitud aprobada');
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _processingId = null);
        context.showSnackBar('Error: ${e.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingId = null);
        context.showSnackBar('Error inesperado', isError: true);
      }
    }
  }

  Future<void> _reject(String requestId) async {
    setState(() => _processingId = requestId);
    try {
      await supabase
          .from('role_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);
      _requests.removeWhere((r) => r['id'] == requestId);
      if (mounted) {
        setState(() => _processingId = null);
        context.showSnackBar('Solicitud rechazada');
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _processingId = null);
        context.showSnackBar('Error: ${e.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingId = null);
        context.showSnackBar('Error inesperado', isError: true);
      }
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administradores'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Skeletons.listTiles(count: 4, leadingSize: 54),
      );
    }
    if (!_authzChecked || !_isAdmin) {
      return Center(child: Text(_error ?? 'Acceso restringido'));
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_requests.isEmpty) {
      return const Center(child: Text('No hay solicitudes pendientes'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final r = _requests[index];
        final profile = r['profiles'] as Map<String, dynamic>?;
        final nombre = profile?['nombre'] as String? ?? '';
        final apellido = profile?['primer_apellido'] as String? ?? '';
        final fullName = [nombre, apellido].where((s) => s.isNotEmpty).join(' ').isEmpty ? 'Sin nombre' : [nombre, apellido].where((s) => s.isNotEmpty).join(' ');
        final email = profile?['email'] as String? ?? 'Sin correo';
        final status = r['status'] as String? ?? '';
        final created = _formatDate(r['created_at'] as String?);
        final isBusy = _processingId == r['id'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(email, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(status),
                      backgroundColor: Colors.orange.withValues(alpha: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Solicitado: $created', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isBusy ? null : () => _reject(r['id'] as String),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isBusy ? null : () => _approve(r['id'] as String),
                        icon: isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: Text(isBusy ? 'Procesando...' : 'Aprobar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
