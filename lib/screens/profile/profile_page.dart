import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/avatar.dart';
import '../../components/skeletons.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';
import '../../pages/settings_page.dart';
import 'edit_profile_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  String? _avatarUrl;
  String _nombre = '';
  String _primerApellido = '';
  String _segundoApellido = '';
  String _email = '';
  String _carrera = '';
  String _departamento = '';
  String _role = '';
  bool _loading = true;
  List<Map<String, dynamic>> _roleHistory = [];
  int _eventsCount = 0;
  int _attendedCount = 0;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _updateStatusBarStyle();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _getProfile();
    _loadRoleHistory();
    // No llamar _loadEventStats aquí - se llama después de cargar el perfil
  }

  void _updateStatusBarStyle() {
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStatusBarStyle();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _getProfile() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentSession?.user.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      final role = ((data['role'] ?? '') as String).trim();

      String carrera = '';
      String departamento = '';

      if (role.toLowerCase() == 'student') {
        final uc = await supabase
            .from('user_carrera')
            .select('carreras(name)')
            .eq('user_id', userId)
            .maybeSingle();
        carrera = (uc?['carreras']?['name'] as String?) ?? '';
      } else if (role.toLowerCase() == 'organizer' || role.toLowerCase() == 'admin') {
        final ud = await supabase
            .from('user_departamento')
            .select('departamentos(name)')
            .eq('user_id', userId)
            .maybeSingle();
        departamento = (ud?['departamentos']?['name'] as String?) ?? '';
      }

      setState(() {
        _nombre = (data['nombre'] ?? '') as String;
        _primerApellido = (data['primer_apellido'] ?? '') as String;
        _segundoApellido = (data['segundo_apellido'] ?? '') as String;
        _email = (data['email'] ?? supabase.auth.currentUser?.email ?? '') as String;
        _carrera = carrera;
        _departamento = departamento;
        _avatarUrl = (data['avatar_url'] ?? '') as String;
        _role = role;
      });
      if (mounted) _fadeController.forward();
      // Cargar estadísticas DESPUÉS de obtener el rol
      if (mounted) await _loadEventStats();
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error cargando perfil', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadEventStats() async {
    try {
      final userId = supabase.auth.currentSession?.user.id;
      if (userId == null) return;
      
      final isStudent = _role.toLowerCase().trim() == 'student' || _role.isEmpty;
      
      int eventsCount = 0;
      int attendedCount = 0;
      
      if (isStudent) {
        // Para estudiantes: eventos próximos a los que están registrados
        final upcoming = await supabase
            .from('event_registrations')
            .select('event_id, events!inner(event_date, event_time)')
            .eq('user_id', userId)
            .gte('events.event_date', DateTime.now().toIso8601String().split('T')[0]);
        
        eventsCount = upcoming.length;
      } else {
        // Para admin/organizadores: eventos creados
        final created = await supabase
            .from('events')
            .select('id')
            .eq('organizer_id', userId);
        
        eventsCount = created.length;
      }
      
      // Asistencias confirmadas (con check-in) - para todos
      final attended = await supabase
          .from('event_registrations')
          .select('id')
          .eq('user_id', userId)
          .not('checked_in_at', 'is', null);
      
      attendedCount = attended.length;
      
      // Actualizar ambas estadísticas en un solo setState
      if (mounted) {
        setState(() {
          _eventsCount = eventsCount;
          _attendedCount = attendedCount;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading event stats: $e');
    }
  }

  Future<void> _loadRoleHistory() async {
    try {
      final userId = supabase.auth.currentSession?.user.id;
      if (userId == null) return;
      
      final data = await supabase
          .from('role_history')
          .select('role, action, changed_at, notes')
          .eq('user_id', userId)
          .order('changed_at', ascending: false)
          .limit(10);
      
      if (mounted) {
        setState(() {
          _roleHistory = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading role history: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
        if (mounted) context.showSnackBar('Error al cerrar sesión', isError: true);
    } finally {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _onUpload(String imageUrl) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase.from('profiles').upsert({'id': userId, 'avatar_url': imageUrl});
      if (mounted) context.showSnackBar('Avatar actualizado');
      if (mounted) setState(() => _avatarUrl = imageUrl);
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error al actualizar avatar', isError: true);
    }
  }

  String get _nombreCompleto {
    final parts = [_nombre, _primerApellido, _segundoApellido].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Usuario' : parts.join(' ');
  }

  String get _roleLabel {
    switch (_role.toLowerCase().trim()) {
      case 'admin':
        return 'Administrador';
      case 'organizer':
        return 'Organizador';
      case 'student':
        return 'Estudiante';
      default:
        return _role.isEmpty ? '' : _role;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase().trim()) {
      case 'admin':
        return Colors.red;
      case 'organizer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase().trim()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'organizer':
        return Icons.event;
      default:
        return Icons.person;
    }
  }

  String _formatDateCompact(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return 'Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'Hace ${diff.inHours} hora${diff.inHours > 1 ? 's' : ''}';
    } else {
      return 'Hace unos minutos';
    }
  }

  Widget _buildHeroHeader() {
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.8),
            scheme.primary.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Avatar(
                  imageUrl: _avatarUrl,
                  onUpload: _onUpload,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              _nombreCompleto,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          if (_roleLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildRoleBadge(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    final wasOrganizer = _roleHistory.any((h) => 
      h['role'] == 'organizer' && h['action'] == 'revoked'
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getRoleColor(_role),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(_role),
            color: _getRoleColor(_role),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _roleLabel,
            style: TextStyle(
              color: _getRoleColor(_role),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (wasOrganizer && _role.toLowerCase() != 'organizer') ...[
            const SizedBox(width: 8),
            Icon(
              Icons.history,
              size: 16,
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final isStudent = _role.toLowerCase().trim() == 'student' || _role.isEmpty;
    
    return Container(
      margin: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: isStudent ? Icons.calendar_month : Icons.event,
              label: isStudent ? 'Próximos' : 'Creados',
              value: '$_eventsCount',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              label: 'Asistencias',
              value: '$_attendedCount',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Personal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.email_outlined,
            label: 'Correo Institucional',
            value: _email,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          if (_role.toLowerCase().trim() == 'student')
            _buildInfoCard(
              icon: Icons.school_outlined,
              label: 'Carrera',
              value: _carrera.isEmpty ? 'No especificada' : _carrera,
              color: Colors.purple,
            )
          else
            _buildInfoCard(
              icon: Icons.business_outlined,
              label: 'Departamento',
              value: _departamento.isEmpty ? 'No especificado' : _departamento,
              color: Colors.blueGrey,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.grey[900]?.withValues(alpha: 0.5)
          : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleHistorySection() {
    if (_roleHistory.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Roles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_roleHistory.length, (index) {
            final entry = _roleHistory[index];
            final role = entry['role'] as String;
            final action = entry['action'] as String;
            final date = DateTime.parse(entry['changed_at'] as String);
            final isLast = index == _roleHistory.length - 1;
            
            String roleLabel;
            switch (role.toLowerCase()) {
              case 'admin':
                roleLabel = 'Administrador';
                break;
              case 'organizer':
                roleLabel = 'Organizador';
                break;
              default:
                roleLabel = role;
            }
            
            final isGranted = action == 'granted';
            final color = isGranted ? Colors.green : Colors.orange;
            
            return Column(
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Icon(
                            isGranted ? Icons.check : Icons.close,
                            color: color,
                            size: 20,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: color.withValues(alpha: 0.3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGranted 
                              ? 'Rol de $roleLabel otorgado'
                              : 'Rol de $roleLabel revocado',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateCompact(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast) const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[200]!],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Skeletons.circle(size: 110),
                const SizedBox(height: 20),
                Skeletons.box(width: 200, height: 24, radius: 10),
                const SizedBox(height: 24),
                Skeletons.box(height: 100, radius: 12),
                const SizedBox(height: 16),
                Skeletons.box(height: 100, radius: 12),
                const SizedBox(height: 24),
                Skeletons.box(height: 60, radius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? Colors.white : Colors.black;
    
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Mi Perfil',
            style: TextStyle(
              color: appBarColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: appBarColor,
          iconTheme: IconThemeData(color: appBarColor),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Configuración',
              onPressed: null,
            ),
          ],
        ),
        body: _buildSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: isDark 
        ? Theme.of(context).colorScheme.surface 
        : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: TextStyle(
            color: appBarColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _getProfile();
          await _loadRoleHistory();
          await _loadEventStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 8),
              _buildStatsSection(),
              const SizedBox(height: 8),
              _buildInfoSection(),
              const SizedBox(height: 24),
              if (_roleHistory.isNotEmpty) _buildRoleHistorySection(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
