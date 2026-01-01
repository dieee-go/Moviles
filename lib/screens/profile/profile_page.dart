import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/avatar.dart';
import '../../components/skeletons.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';
import '../../pages/login_page.dart';
import '../../pages/settings_page.dart';
import 'edit_profile_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarUrl;
  String _nombre = '';
  String _primerApellido = '';
  String _segundoApellido = '';
  String _email = '';
  String _carrera = '';
  String _role = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
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
      setState(() {
        _nombre = (data['nombre'] ?? '') as String;
        _primerApellido = (data['primer_apellido'] ?? '') as String;
        _segundoApellido = (data['segundo_apellido'] ?? '') as String;
        _email = (data['email'] ?? supabase.auth.currentUser?.email ?? '') as String;
        _carrera = (data['carrera'] ?? '') as String;
        _avatarUrl = (data['avatar_url'] ?? '') as String;
        _role = ((data['role'] ?? '') as String).trim();
      });
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error cargando perfil', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
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

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          children: [
            Skeletons.circle(size: 110),
            const SizedBox(height: 20),
            Skeletons.box(width: 200, height: 24, radius: 10),
            const SizedBox(height: 10),
            Skeletons.box(width: 140, height: 16, radius: 8),
            const SizedBox(height: 24),
            Skeletons.box(height: 62, radius: 12),
            const SizedBox(height: 16),
            Skeletons.box(height: 62, radius: 12),
            const SizedBox(height: 28),
            Skeletons.box(height: 48, radius: 12),
            const SizedBox(height: 14),
            Skeletons.box(height: 48, radius: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
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
      body: _loading
          ? _buildSkeleton()
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Avatar(
                    imageUrl: _avatarUrl,
                    onUpload: _onUpload,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _nombreCompleto,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (_roleLabel.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _roleLabel,
                      style: TextStyle(
                        fontSize: 15,
                        color: scheme.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  _ProfileField(label: 'Correo Institucional', value: _email),
                  const SizedBox(height: 20),
                  _ProfileField(
                    label: 'Carrera',
                    value: _carrera.isEmpty ? 'No especificada' : _carrera,
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
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
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                        onPressed: _signOut,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: scheme.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
