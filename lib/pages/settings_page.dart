import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../theme/app_theme_extensions.dart';
import 'change_password_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _eventNotifications = true;
  bool _reminders = false;
  bool _appNotifications = true;
  bool _sendingRequest = false;
  bool _loadingRequestStatus = false;
  String? _requestStatus;
  DateTime? _requestUpdatedAt;
  String? _profileRole;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadRequestStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ThemeController.of(context);
    final mode = controller?.themeMode ?? ThemeMode.light;
    if (_themeMode != mode) {
      setState(() => _themeMode = mode);
    }
  }

  Future<void> _loadUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _profileRole = data['role'] as String?;
        });
      }
    } catch (_) {
      // Silenciar errores de rol
    }
  }

  Future<bool> _confirmRequestDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solicitar rol de organizador'),
          content: const Text(
              'Enviaremos tu solicitud para que un administrador la revise. ¿Quieres continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Solicitar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _requestOrganizerRole() {
    // Validar si puede solicitar
    if (!_canRequestOrganizer()) {
      // Si fue revocado, mostrar mensaje específico
      if (_requestStatus == 'revoked') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes hacer más solicitudes porque tu rol de organizador fue revocado'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      // Si está pendiente, mostrar otro mensaje
      else if (_requestStatus == 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya tienes una solicitud pendiente')),
        );
      }
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para enviar la solicitud')),
      );
      return;
    }

    if (_sendingRequest) return;

    _confirmRequestDialog().then((confirmed) {
      if (!confirmed) return;

      setState(() => _sendingRequest = true);

      () async {
        try {
          // Evita duplicados: si ya hay solicitud pendiente, solo notifica
          final existing = await supabase
              .from('role_requests')
              .select('status')
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (existing != null && existing['status'] == 'pending') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ya tienes una solicitud pendiente')),
              );
            }
            return;
          }

          // Si existe una solicitud anterior (rejected o revoked), elimínala primero
          if (existing != null && (existing['status'] == 'rejected' || existing['status'] == 'revoked')) {
            await supabase
                .from('role_requests')
                .delete()
                .eq('user_id', user.id);
          }

          await supabase.from('role_requests').insert({
            'user_id': user.id,
            'status': 'pending',
            'message': 'Solicitud enviada desde app',
          });

          await _loadRequestStatus();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Solicitud de rol de organizador enviada')),
            );
          }
        } on PostgrestException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.message}')),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error inesperado al enviar solicitud')),
            );
          }
        } finally {
          if (mounted) setState(() => _sendingRequest = false);
        }
      }();
    });
  }

  Future<void> _loadRequestStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _loadingRequestStatus = true;
    });

    try {
      final data = await supabase
          .from('role_requests')
          .select('status, updated_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _requestStatus = data?['status'] as String?;
        _requestUpdatedAt = data?['updated_at'] != null
            ? DateTime.tryParse(data!['updated_at'] as String)
            : null;
      });
    } catch (_) {
      setState(() {
        _requestStatus = null;
        _requestUpdatedAt = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRequestStatus = false;
        });
      }
    }
  }

  Widget _statusBadge() {
    if (_loadingRequestStatus) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      );
    }
    final status = _requestStatus;
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Aprobada';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rechazada';
        break;
      case 'revoked':
        color = Colors.grey;
        label = 'Revocada';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      default:
        color = Colors.grey;
        label = 'Sin solicitud';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _statusSubtitle() {
    String formatDate(DateTime dt) {
      final d = dt.toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString();
      final hh = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return '$dd/$mm/$yyyy $hh:$min';
    }

    if (_requestStatus == null) {
      final roleLabel = _friendlyRole(_profileRole);
      return roleLabel.isEmpty
          ? 'Aún no has enviado una solicitud'
          : 'Rol actual: $roleLabel';
    }

    final updated = _requestUpdatedAt;
    switch (_requestStatus) {
      case 'pending':
        if (updated != null) {
          return 'Tu solicitud está en revisión. Enviada el ${formatDate(updated)}';
        }
        return 'Tu solicitud está en revisión.';
      case 'approved':
        if (updated != null) {
          return 'Solicitud aprobada el ${formatDate(updated)}. Ya cuentas con el rol de organizador.';
        }
        return 'Solicitud aprobada. Ya cuentas con el rol de organizador.';
      case 'rejected':
        if (updated != null) {
          final daysSince = DateTime.now().difference(updated.toLocal()).inDays;
          final remaining = (30 - daysSince).clamp(0, 30);
          if (remaining > 0) {
            return 'Solicitud rechazada el ${formatDate(updated)}. Podrás volver a solicitar en $remaining días.';
          } else {
            return 'Solicitud rechazada el ${formatDate(updated)}. Ya puedes volver a solicitar.';
          }
        }
        return 'Solicitud rechazada.';
      case 'revoked':
        if (updated != null) {
          return 'Tu rol de organizador fue revocado el ${formatDate(updated)}. No puedes solicitar nuevamente.';
        }
        return 'Tu rol de organizador fue revocado. No puedes solicitar nuevamente.';
      default:
        if (updated != null) {
          return 'Último estado: $_requestStatus. Actualizado el ${formatDate(updated)}';
        }
        return 'Último estado: $_requestStatus';
    }
  }

  bool _canRequestOrganizer() {
    final role = _profileRole;
    if (role == 'organizer' || role == 'admin') return false;
    if (_requestStatus == null) return true;
    if (_requestStatus == 'pending') return false;
    if (_requestStatus == 'revoked') return false; // No permitir solicitar si fue revocado
    if (_requestStatus == 'rejected' && _requestUpdatedAt != null) {
      final daysSince = DateTime.now().difference(_requestUpdatedAt!.toLocal()).inDays;
      return daysSince >= 30;
    }
    return true;
  }

  bool _shouldShowStatusTile() {
    final role = _profileRole;
    if (role == 'organizer' || role == 'admin') return false;
    return _requestStatus != null;
  }

  String _friendlyRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'organizer':
        return 'Organizador';
      case 'student':
        return 'Estudiante';
      default:
        return role ?? '';
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
      ? Colors.black.withValues(alpha: 90) // 35% of 255 ≈ 90
      : const Color(0x0D000000);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isDark ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _leadingIcon(IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: scheme.primary),
    );
  }

  ListTile _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: _leadingIcon(icon),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: Switch(
        value: value,
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final scheme = Theme.of(context).colorScheme;
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.grey[400];
        }),
        onChanged: onChanged,
      ),
    );
  }

  ListTile _navigationTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: _leadingIcon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: titleColor ?? scheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: scheme.secondaryText),
      onTap: onTap,
    );
  }

  void _toggleDarkMode(bool value) {
    final controller = ThemeController.of(context);
    final mode = value ? ThemeMode.dark : ThemeMode.light;
    controller?.setThemeMode(mode);
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _sectionTitle('Apariencia'),
          _sectionCard(
            children: [
              _switchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Modo oscuro',
                value: _themeMode == ThemeMode.dark,
                onChanged: _toggleDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle('Notificaciones'),
          _sectionCard(
            children: [
              _switchTile(
                icon: Icons.event_available_outlined,
                title: 'Notificaciones de Eventos',
                value: _eventNotifications,
                onChanged: (v) => setState(() => _eventNotifications = v),
              ),
              const Divider(height: 1),
              _switchTile(
                icon: Icons.alarm_outlined,
                title: 'Recordatorios',
                value: _reminders,
                onChanged: (v) => setState(() => _reminders = v),
              ),
              const Divider(height: 1),
              _switchTile(
                icon: Icons.notifications_none_outlined,
                title: 'Notificaciones de la aplicación',
                value: _appNotifications,
                onChanged: (v) => setState(() => _appNotifications = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle('Cuenta'),
          _sectionCard(
            children: [
              if (_shouldShowStatusTile()) ...[
                ListTile(
                  leading: _leadingIcon(Icons.verified_user_outlined),
                  title: const Text(
                    'Estado de solicitud de organizador',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_statusSubtitle()),
                  trailing: _statusBadge(),
                  onTap: _loadRequestStatus,
                ),
                const Divider(height: 1),
              ],
              _navigationTile(
                icon: Icons.lock_reset_outlined,
                title: 'Cambiar contraseña',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                },
              ),
              const Divider(height: 1),
              if (_profileRole != 'admin' && _profileRole != 'organizer') ...[
                _navigationTile(
                  icon: Icons.badge_outlined,
                  title: 'Solicitar rol de organizador',
                  titleColor: _canRequestOrganizer() ? Colors.black87 : Colors.grey,
                  onTap: _requestOrganizerRole,
                ),
                const Divider(height: 1),
              ],
              _navigationTile(
                icon: Icons.logout,
                title: 'Cerrar sesión',
                titleColor: Colors.red,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cerrar sesión desde la pantalla de perfil')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle('Información'),
          _sectionCard(
            children: [
              _navigationTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Política de privacidad',
                onTap: () {},
              ),
              const Divider(height: 1),
              _navigationTile(
                icon: Icons.description_outlined,
                title: 'Términos de servicio',
                onTap: () {},
              ),
              const Divider(height: 1),
              _navigationTile(
                icon: Icons.info_outline,
                title: 'Acerca de la aplicación',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
